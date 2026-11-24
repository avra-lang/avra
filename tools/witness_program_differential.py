"""The judge tools/witness_program_differential.sh runs: each witness laid out on disk, built on the
program layer, judged against what the old path said of it, and the table printed. The old path's
word is frozen in tools/witness_program_differential.old, one line a witness: it was asked once, at
cbc437f4, before its deletion. A witness written or changed since has no frozen word, and is said
UNFROZEN. Arguments: the compiler, a scratch directory holding witnesses.jsonl, the bar, the jobs,
and the codes to judge (none: every code)."""
import hashlib
import concurrent.futures
import json
import os
import re
import shutil
import subprocess
import sys

TIMEOUT = 600
UNBUILT = "doesn't build this program yet"
ERROR = re.compile(r"^error\[([^\]]+)\]")
WARNING = re.compile(r"^warning\[([^\]]+)\]")

# The lane whose kinds a code is, guessed from the kind: exact kinds first, then prefixes.
OWNERS_EXACT = {
    "type.force": "body-laws", "type.propagate": "body-laws", "type.fail": "body-laws",
    "type.shift_count": "body-laws", "type.mixed_bitwise": "body-laws",
    "type.list_scalar": "body-laws", "type.struct_scalar": "body-laws",
    "type.enum_payload": "body-laws", "type.task_escape": "body-laws", "type.defer": "body-laws",
    "type.defer_inert": "body-laws", "type.errdefer": "body-laws", "flow.yield": "body-laws",
    "const.param": "embed", "const.reach": "embed", "const.trap": "embed",
    "const.budget": "embed", "const.cycle": "embed",
    "type.infer_result": "lowering-rows-b",
    "type.mismatch": "seat-laws", "type.binding": "seat-laws", "type.return": "seat-laws",
    "type.seat": "seat-laws", "type.struct_fields": "seat-laws",
    "type.variant_arity": "seat-laws", "type.method": "seat-laws", "type.applied": "seat-laws",
    "type.map_key": "seat-laws", "type.map_value": "seat-laws", "type.lambda": "seat-laws",
    "type.place": "seat-laws", "type.list_element": "seat-laws",
    "type.operand": "lowering-rows-c", "type.operator": "lowering-rows-c",
    "type.compare": "lowering-rows-c",
}
OWNERS_PREFIX = [
    ("type.match", "type-refusals"), ("type.let_", "type-refusals"), ("type.catch", "type-refusals"),
    ("type.derive", "type-refusals"), ("type.component", "type-refusals"),
    ("type.format", "type-refusals"), ("type.quote", "type-refusals"),
    ("type.interp", "type-refusals"), ("annotation.", "type-refusals"),
    ("parse.", "type-refusals"), ("lex.", "type-refusals"), ("build.", "type-refusals"),
    ("flow.produce", "type-refusals"), ("flow.channel", "type-refusals"),
    ("load.", "type-refusals"), ("manifest.", "type-refusals"), ("module.", "type-refusals"),
    ("type.duplicate", "decl-shape"), ("type.enum_decl", "decl-shape"),
    ("type.tparam", "decl-shape"), ("type.trait", "decl-shape"), ("type.variadic", "decl-shape"),
    ("type.param_default", "decl-shape"), ("type.named", "decl-shape"),
    ("type.alias", "decl-shape"), ("type.orphan", "decl-shape"), ("type.static", "decl-shape"),
    ("type.mut_fn", "decl-shape"), ("type.once_fn", "decl-shape"),
    ("type.struct_targs", "decl-shape"), ("collect", "decl-shape"), ("resolve.nested", "decl-shape"),
    ("resolve.impl", "decl-shape"), ("resolve.builtin", "decl-shape"),
    ("resolve.duplicate", "decl-shape"), ("type.impl", "decl-shape"),
    ("lower.", "whole-program"), ("const.", "embed"),
    ("flow.arm", "select-lowering"), ("flow.spent", "select-lowering"),
    ("flow.no_fate", "select-lowering"), ("flow.select", "select-lowering"),
    ("resolve.", "type-refusals"), ("loop.", "body-laws"), ("flow.", "body-laws"),
    ("type.", "seat-laws"),
]


def owner(code):
    """The lane whose kinds `code` is, by its kind."""
    if code in OWNERS_EXACT:
        return OWNERS_EXACT[code]
    return next((lane for prefix, lane in OWNERS_PREFIX if code.startswith(prefix)), "?")


def run(args, cwd, env):
    """What a run of `args` in `cwd` said and how it ended; a run past its time ends as `timeout`."""
    try:
        done = subprocess.run(args, cwd=cwd, env=env, capture_output=True, text=True, timeout=TIMEOUT)
        return done.returncode, done.stdout + done.stderr
    except subprocess.TimeoutExpired as t:
        out = (t.stdout or b"").decode(errors="replace") + (t.stderr or b"").decode(errors="replace")
        return "timeout", out


FROZEN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "witness_program_differential.old")


def frozen():
    """The old path's word on each witness, by its code: what it said, frozen."""
    with open(FROZEN) as f:
        return {o["code"]: o for o in (json.loads(l) for l in f if l.strip())}


def witnessed(w):
    """The digest of a witness's files: a frozen word stands for the files it was said of."""
    return hashlib.sha256(json.dumps(w["files"], sort_keys=True).encode()).hexdigest()


def first(pattern, said):
    """The first line of `said` that `pattern` opens, and the kind it names; absent where none."""
    for line in said.splitlines():
        m = pattern.match(line)
        if m:
            return line, m.group(1) if m.re.groups else None
    return None, None


def laid_out(case, files):
    """The witness's files written under `case`, `/w/...` at `case/w/...`; the package's root."""
    for path, text in files.items():
        at = os.path.join(case, path.lstrip("/"))
        os.makedirs(os.path.dirname(at), exist_ok=True)
        with open(at, "w") as f:
            f.write(text)
    return os.path.join(case, "w")


def in_test_file(said):
    """Whether the first error `said` stands in a test file — one a build never reads unless its
    entry reaches it, and `check` judges: the program layer is judged by `check` there."""
    lines = said.splitlines()
    at = next((i for i, l in enumerate(lines) if ERROR.match(l)), None)
    if at is None:
        return False
    place = next((l for l in lines[at + 1:at + 3] if "╭─[" in l), "")
    path = place.split("╭─[", 1)[-1].rsplit("]", 1)[0].split(":", 1)[0]
    return path.endswith("_test.av") or "/tests/" in path


def judged(avra, scratch, w, old):
    """One witness's row: its code, its verdict, its owner, and both first lines."""
    code = w["code"]
    row = {"code": code, "owner": owner(code), "old": "", "new": ""}
    if w["shape"] in ("beyond", "absent", "unread"):
        return dict(row, verdict=w["shape"].upper(), old=w["why"])
    if any(p.startswith("/std/") for p in w["files"]):
        return dict(row, verdict="STD-ROOT")
    said = old.get(code)
    case = os.path.join(scratch, "cases", re.sub(r"[^A-Za-z0-9_.-]", "_", code))
    pkg = laid_out(case, w["files"])
    env = dict(os.environ, AVRA_CACHE_DIR=os.path.join(case, "machine"), PWD=pkg)
    in_test = said["in_test"] if said is not None else False
    new_exit, new_said = run([avra, "check" if in_test else "build", pkg], pkg, env)
    shutil.rmtree(case, ignore_errors=True)
    # the witness's own directory, said as the frozen words say it
    new_said = new_said.replace(case, "<case>")
    new_line, new_kind = first(ERROR, new_said)
    if said is None or said["digest"] != witnessed(w):
        return dict(row, verdict="UNFROZEN", new=new_line or f"exit {new_exit}")
    old_line, old_kind = said["line"], said["kind"]
    if old_line is None:
        warned = said["warned"]
        if warned is None:
            return dict(row, verdict="OLD-SILENT", old=f"exit {said['exit']}")
        row["old"] = warned
        heard, _ = first(re.compile(r"^warning\[" + re.escape(code) + r"\]"), new_said)
        return dict(row, verdict="WARNED" if heard == warned else "WARN-MISSING", new=heard or "")
    row["old"] = old_line
    if new_line is not None:
        row["new"] = new_line
        if new_kind != old_kind:
            return dict(row, verdict="OTHER-ERROR")
        return dict(row, verdict="SAME" if new_line == old_line else "DIFFERENT")
    lines = [l for l in new_said.splitlines() if l.strip()]
    if new_exit == 0:
        return dict(row, verdict="ACCEPTED")
    unbuilt = next((l for l in lines if UNBUILT in l), None)
    if new_exit == 1 and unbuilt is not None:
        return dict(row, verdict="UNBUILT", new=unbuilt)
    return dict(row, verdict="COMPILER-DEFECT", new=f"exit {new_exit}: " + (lines[0] if lines else ""))


def main():
    avra, scratch, bar, jobs = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    only = set(sys.argv[5:])
    with open(os.path.join(scratch, "witnesses.jsonl")) as f:
        witnesses = [json.loads(l) for l in f if l.startswith("{")]
    witnesses = [w for w in witnesses if not only or w["code"] in only]
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        old = frozen()
        rows = list(pool.map(lambda w: judged(avra, scratch, w, old), witnesses))
    order = ["COMPILER-DEFECT", "ACCEPTED", "OTHER-ERROR", "DIFFERENT", "UNBUILT", "WARN-MISSING",
             "OLD-SILENT", "STD-ROOT", "UNFROZEN", "BEYOND", "ABSENT", "UNREAD", "WARNED", "SAME"]
    print("| code | verdict | owner (guess) | old first line | program layer first line |")
    print("|---|---|---|---|---|")
    for r in sorted(rows, key=lambda r: (order.index(r["verdict"]), r["owner"], r["code"])):
        if r["verdict"] == "SAME":
            continue
        cells = [r["code"], r["verdict"], r["owner"], r["old"][:140], r["new"][:140]]
        print("| " + " | ".join(c.replace("|", "\\|") for c in cells) + " |")
    counts = {v: sum(1 for r in rows if r["verdict"] == v) for v in order}
    print()
    print("witness_program_differential: " + ", ".join(f"{counts[v]} {v}" for v in order if counts[v]) +
          f" — {len(rows)} codes")
    print(f"witness_program_differential: {counts['UNFROZEN']} UNFROZEN (a witness the old path never judged, or one changed since its word was frozen)")
    same = counts["SAME"]
    if same < bar:
        print(f"witness_program_differential: {same} SAME, under the bar of {bar}")
        sys.exit(1)


main()
