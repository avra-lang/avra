#!/usr/bin/env python3
"""THE SUITE'S SHARED VOCABULARY: the registry, a benchmark's spec, this
machine, one language run, and the row contract.

A language program prints one row per line, tab-separated:

    <name>\t<value>\t<unit>\t<samples>

and any `# ...` line as a note. The harness wraps a language's rows into
ONE JSON row (the fixed schema in `benchmarks/README.md`); a language
therefore knows nothing of JSON, versions or machines.
"""
import os
import platform
import subprocess
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
BENCH = os.path.dirname(HERE)
ROOT = os.path.dirname(BENCH)

# Directories under benchmarks/ that are not families.
NOT_FAMILIES = {"lib", "results", "report", "build"}
RUN_TIMEOUT = int(os.environ.get("BENCH_TIMEOUT", "300"))


class Skip(Exception):
    """A language or benchmark that cannot run here, with the reason."""


class Fail(Exception):
    """A run that ran and did not do what the contract says."""


def load_toml(path):
    with open(path, "rb") as f:
        return tomllib.load(f)


def registry():
    return load_toml(os.path.join(BENCH, "bench.toml"))


def spec_of(bench_dir):
    return load_toml(os.path.join(bench_dir, "spec.toml"))


def bench_dirs(only=None):
    """Every `<family>/<benchmark>` holding a spec, in name order. `only`
    is a set of `family/benchmark` keys, or None for all."""
    found = []
    for fam in sorted(os.listdir(BENCH)):
        fdir = os.path.join(BENCH, fam)
        if fam in NOT_FAMILIES or fam.startswith(".") or not os.path.isdir(fdir):
            continue
        for name in sorted(os.listdir(fdir)):
            bdir = os.path.join(fdir, name)
            if os.path.isfile(os.path.join(bdir, "spec.toml")):
                key = f"{fam}/{name}"
                if only is None or key in only:
                    found.append((key, bdir))
    return found


def languages_for(spec):
    """The languages a benchmark lists, or every registered language."""
    return spec.get("languages")


# ── this machine ─────────────────────────────────────────────────────

def machine_id():
    """A stable key for the machine, so two machines are never compared.
    It names the platform AND the machine, so a report says what it was
    measured on."""
    return f"{platform.system().lower()}-{platform.machine().lower()}: {machine_desc()}"


def machine_desc():
    if platform.system() == "Linux":
        model = "unknown CPU"
        try:
            for line in open("/proc/cpuinfo"):
                if line.startswith("model name"):
                    model = line.split(":", 1)[1].strip()
                    break
        except OSError:
            pass
        n = platform.os.cpu_count() or "?"
        return f"{model}, {n} cores, Linux {platform.release()}"
    if platform.system() == "Darwin":
        try:
            model = subprocess.run(
                ["sysctl", "-n", "machdep.cpu.brand_string"],
                capture_output=True, text=True,
            ).stdout.strip()
        except OSError:
            model = "unknown CPU"
        n = platform.os.cpu_count() or "?"
        return f"{model}, {n} cores, macOS {platform.mac_ver()[0]}"
    return f"{platform.platform()}, {platform.os.cpu_count() or '?'} cores"


# ── one language run ─────────────────────────────────────────────────

def _placeholders(text, *, d, src, out):
    return {
        "{dir}": d,
        "{src}": src or "",
        "{out}": out,
        "{avra}": os.path.join(ROOT, "build", "avra"),
        "{root}": ROOT,
    }.get(text, text)


def _sub(argv, ctx):
    return [_placeholders(tok, **ctx) for tok in argv]


def _present(cfg, ctx):
    if "present" not in cfg:
        return True
    try:
        return subprocess.run(_sub(cfg["present"], ctx), capture_output=True, timeout=30).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def lang_version(cfg, ctx):
    if "version" not in cfg:
        return "unknown"
    try:
        p = subprocess.run(_sub(cfg["version"], ctx), capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return "unknown"
    line = (p.stdout or p.stderr).strip().splitlines()
    return line[0].strip() if line else "unknown"


def parse_rows(text):
    """The row contract: `name<TAB>value<TAB>unit<TAB>samples`. A `#`
    line is a note; an empty line is nothing; anything else is a Fail, so
    a program that drifts from the contract is refused rather than
    silently missing a row."""
    rows, notes = {}, []
    for raw in text.splitlines():
        line = raw.rstrip()
        if not line:
            continue
        if line.startswith("#"):
            notes.append(line.lstrip("#").strip())
            continue
        parts = line.split("\t")
        if len(parts) != 4:
            raise Fail(f"a row is not `name<TAB>value<TAB>unit<TAB>samples`: {line!r}")
        name, value, unit, samples = parts
        try:
            rows[name] = {"unit": unit, "value": float(value), "samples": int(samples)}
        except ValueError as e:
            raise Fail(f"row {name}: {e}")
    return rows, notes


def run_language(key, bench_dir, lang, cfg, workload, only_rows=None):
    """Build and run one language's twin for one benchmark. Answers
    (version, rows, notes). Raises Skip when the toolchain or the twin is
    absent, Fail when it ran wrong."""
    d = os.path.join(bench_dir, lang)
    if not os.path.isdir(d):
        raise Skip(f"no {lang}/ directory in {key}")
    out = os.path.join(BENCH, "build", f"{key.replace('/', '-')}-{lang}")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    src = os.path.join(d, cfg["source"]) if cfg.get("source") else None
    ctx = {"d": d, "src": src, "out": out}
    if not _present(cfg, ctx):
        raise Skip(f"{lang} toolchain absent: {' '.join(_sub(cfg['present'], ctx))}")
    version = lang_version(cfg, ctx)
    cwd = _placeholders(cfg.get("cwd", "{dir}"), **ctx)
    env = dict(os.environ)
    for name, value in (workload or {}).items():
        env[f"BENCH_{name.upper()}"] = str(value)
    if cfg.get("build"):
        try:
            p = subprocess.run(_sub(cfg["build"], ctx), cwd=cwd, capture_output=True, text=True, timeout=RUN_TIMEOUT, env=env)
        except subprocess.TimeoutExpired:
            raise Fail(f"{lang} build timed out after {RUN_TIMEOUT}s")
        if p.returncode != 0:
            raise Fail(f"{lang} build exited {p.returncode}: {(p.stderr or p.stdout).strip().splitlines()[-1] if (p.stderr or p.stdout).strip() else 'no words'}")
    try:
        p = subprocess.run(_sub(cfg["run"], ctx), cwd=cwd, capture_output=True, text=True, timeout=RUN_TIMEOUT, env=env)
    except subprocess.TimeoutExpired:
        raise Fail(f"{lang} run timed out after {RUN_TIMEOUT}s")
    if p.returncode != 0:
        tail = (p.stderr or p.stdout).strip().splitlines()
        raise Fail(f"{lang} run exited {p.returncode}: {tail[-1] if tail else 'no words'}")
    rows, notes = parse_rows(p.stdout)
    if not rows:
        raise Fail(f"{lang} printed no rows")
    return version, rows, notes


def row_of(key, lang, version, machine, when, rows, notes):
    """The fixed JSON schema: one row per (benchmark, language, machine)."""
    text = "; ".join(notes) if notes else ""
    return {
        "benchmark": key,
        "language": lang,
        "version": version,
        "machine": machine,
        "when": when,
        "rows": rows,
        "notes": text,
    }


def skipped_row(key, lang, machine, when, reason):
    return row_of(key, lang, "unknown", machine, when, {}, [f"SKIPPED: {reason}"])
