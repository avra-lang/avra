#!/usr/bin/env python3
"""EVERY READ OF THE WORLD IS AN INPUT THROUGH ONE DOOR, and this counts
the reads that are not: a call in the compiler or its CLI that asks the
disk, the environment, a tool, a child process, the clock, the process
table or argv, outside the door — the one file that defines the input
verbs (DOOR), never the directory it stands in.

A SITE IS FOUND FROM WHAT ITS FILE IMPORTS, never from a verb's
spelling: a name taken from a world package is looked up in that
package's table and its calls counted, so a local fn that happens to be
called `env` is nobody's site. Beside those: a call through a `Host`
value (`host.read(…)`), and a call of a world runtime row the file
declares itself (`extern fn avra_host_env`).

THE TABLES CANNOT GO STALE QUIETLY. Five refusals hold them:
  - a `use @std.…` line the keeper cannot read is refused, never skipped;
  - a `@std` package a scope file imports is in WORLD or INERT, or the
    keeper refuses naming it;
  - a WORLD package's name classed pure is held to its own source — a
    free fn whose body reaches a world row or a counted name, itself or
    through the package's free fns, is refused (a read reached only
    through a METHOD is not followed);
  - an INERT package is held to its own source — it declares the rows
    pinned here and no other, and imports inert packages alone — so a
    package that starts reading the world stops being inert;
  - a name imported from a WORLD package, and a row a scope file
    declares, is classified or refused.

THE BASELINE LISTS SITES, NEVER COUNTS: tools/inputs.baseline holds a
group, a file and the site's own source line. A site not listed fails,
naming its line. `// LICENSED input.<why>: …` on the line above says a
read is no input (the store's own IO, a program's effects under the
evaluator, timing, a debug flag) and takes it out. The file only falls:

    python3 tools/inputs.py            # the table; refuses a new site
    python3 tools/inputs.py --accept   # prunes what a move made gone
"""
import collections
import glob
import os
import re
import sys

SCOPE = ["packages/std-avrac/src", "packages/cli/src"]
# The door is the FILE that defines the input verbs. A read beside it,
# in the same directory, is outside like any other.
DOOR = {"packages/std-avrac/src/compiler/host/host.av"}
BASELINE = "tools/inputs.baseline"

# What a call asks of the world. A kind in COUNTED is a read; the rest
# classify a name so it is never unclassified.
COUNTED = {"read", "env", "tool", "spawn", "clock", "pid", "argv", "fetch"}
T, P, W, E = "type", "pure", "write", "effect"

# A WORLD package: every name a scope file imports from it is here.
WORLD = {
    "io": {
        "read_text": "read", "read_bytes": "read", "exists": "read", "is_file": "read",
        "is_dir": "read", "list_dir": "read", "stamp": "read", "kind_of": "read",
        "open_beneath": "read", "watch": "read", "env": "env", "env_or": "env", "compile_slot": "env",
        "write_text": W, "write_bytes": W, "append_bytes": W, "synced": W,
        "opened_for_append": W, "truncate_to": W, "make_dirs": W, "remove": W,
        "println": E, "eprintln": E,
        "one_path": P, "refused": P, "enoent": P, "eacces": P, "enotdir": P,
        "IoError": T, "Entry": T, "Opened": T, "AppendFile": T, "Watch": T,
    },
    "process": {
        "tool": "tool", "tool_from_env": "tool", "host": "spawn", "run_through": "spawn",
        "parallel": "spawn", "race": "spawn", "serving": "spawn",
        "minimal": "env", "developer": "env",
        "cmd": P, "inherited": P, "exit_text": P,
        "status_of": P, "scripted": P, "plan": P, "exit": E,
        "Tool": T, "Command": T, "Exit": T, "Output": T, "Outcome": T, "Env": T,
        "EnvPair": T, "Stdin": T, "Streams": T, "Ready": T, "Stream": T,
        "ProcessError": T, "Child": T, "Pipeline": T, "PipeOutcome": T, "Script": T,
        "Runner": T,
    },
    "time": {
        "now_ms": "clock", "now_ns": "clock", "wall_secs": "clock", "sleep": E,
        "ms": P, "secs": P, "mins": P, "duration_text": P, "Duration": T,
    },
    "cli": {
        "argv": "argv", "cli": "argv",
        "command": P, "arg": P, "flag": P, "option": P, "CliResult": T, "Runnable": T,
    },
    "net": {"Bell": T, "Listener": T},
    "http": {
        "get": "fetch", "server": E, "directory": "read", "event_stream": E,
        "compiled": P, "dispatch": P, "fixed": P, "framed": P, "limits": P, "text": P,
        "quiet_default": P,
        "Request": T, "Unrouted": T, "Response": T, "Pulled": T, "Header": T, "Route": T,
        "Event": T, "Next": T, "Source": T, "Resume": T, "Method": T, "Files": T, "Body": T,
    },
}

# A spawn is a METHOD on a command a file built, so a file that imports
# a SPAWNER is read for these too: `@std/process`'s three spawning
# methods and no other. `run` takes nothing, so `.run(` with an argument
# is somebody else's verb.
SPAWNERS = {"cmd", "Command", "Tool", "Pipeline", "Runner"}
SPAWNS = re.compile(r"\.(run(?=\(\))|outcome|start)\(")

# An INERT package reads nothing: the rows it may declare, and the one
# name of it that does read. Held to the package's own source.
INERT = {
    "meta": {"rows": {"avra_embed", "avra_type_named"}, "world": {"embed": "read"}},
    "relation": {"rows": {"avra_trap", "avra_qtrace"}, "world": {}},
    "text": {
        "rows": {"avra_str_from_codepoint", "avra_str_parsed_float", "avra_str_parsed_int",
                 "avra_str_parses_float", "avra_str_parses_int", "avra_bytes_with_room"},
        "world": {},
    },
    "derive": {"rows": set(), "world": {}},
    "errors": {"rows": set(), "world": {}},
    "grammar": {"rows": set(), "world": {}},
    "json": {"rows": set(), "world": {}},
    "math": {"rows": set(), "world": {}},
    "path": {"rows": set(), "world": {}},
    "testing": {"rows": set(), "world": {}},
    "toml": {"rows": set(), "world": {}},
}

# A runtime row a scope file declares for itself.
ROWS = {
    "avra_host_env": "env", "avra_host_is_dir": "read", "avra_io_list": "read",
    "avra_selfhost_file_exists": "read", "avra_selfhost_read_file": "read",
    "avra_fd_read": "read", "avra_ffi_open": "read", "avra_embed": "read",
    "avra_spawn_in": "spawn", "avra_spawn_status": "spawn", "avra_exec_self": "spawn",
    "avra_self_dir": "tool", "avra_now_ns": "clock",
    "avra_own_pid": "pid", "avra_pid_alive": "pid",
    "avra_selfhost_argc": "argv", "avra_selfhost_get_arg_cstr": "argv",
}
INERT_ROWS = re.compile(
    r"^(LLVM\w*|avra_(llvm|float|int|str|bytes|vtask|fiber|ffi|sched)_\w+|avra_(debug|eputs|puts|"
    r"errno_text|ptr_at|qtrace|trap|utf8_bad_at|mem_live|fd_taken|fd_write|type_named|"
    r"vgate_open|vgate_claim|gate_new|rc_release|task_at|task_done|task_cancel)|"
    r"host|println)$")

# A read through the filesystem seam: behind `Host`, not yet an input —
# called as a member, as a field's value (`(host.beneath)(…)`), or on
# the line under a chain that ends in `host`.
HOSTED = re.compile(r"\bhost\.(read|exists|beneath|list|is_dir|stamp)\)?\(")
CHAINED = re.compile(r"^\s*\.(read|exists|beneath|list|is_dir|stamp)\)?\(")

SEG = r"[a-z_][a-z_0-9]*"
USE = re.compile(r"^use\s+@std\.(" + SEG + r")((?:\." + SEG + r")*)\.(\{[^}]*\}|[A-Za-z_][A-Za-z_0-9]*)", re.M | re.S)
EXTERN = re.compile(r"^\s*(?:export\s+)?extern\s+fn\s+([A-Za-z_][A-Za-z_0-9]*)", re.M)
LICENSE = re.compile(r"^\s*//\s*LICENSED\s+input\.[a-z_]+:\s*\S")

Site = collections.namedtuple("Site", "file line text kind verb state")


def imports(text):
    """Every (package, name, local name) a file takes from `@std` — a
    multi-line list joined, an `as` read for both of its names."""
    out = []
    for pkg, _, names in USE.findall(text):
        for n in names.strip("{}").split(","):
            parts = [w.strip() for w in n.split(" as ")]
            if parts[0]:
                out.append((pkg, parts[0], parts[-1]))
    return out


def packages_used(text):
    return {pkg for pkg, _, _ in USE.findall(text)}


def code_of(line):
    """A line without its trailing comment; a comment line is nothing."""
    s = line.strip()
    return "" if s.startswith("//") else line.split(" // ")[0]


def called(name):
    """`name(` as a call, or `name` handed over as a value — never a
    method, a field, a longer name, or its own definition."""
    return re.compile(r"(?<![\w.])%s(?:\(|(?=\s*[,)]))(?<!fn %s\()" % (re.escape(name), re.escape(name)))


def group_of(path, kind, hosted):
    """The subsystem a site is counted under — the design's split."""
    name = os.path.basename(path)
    if hosted:
        return "behind-host"
    if kind == "clock" or "/compiler/store/" in path or "/backend/interp" in path:
        return "not-input"
    if path.endswith("cli/src/commands/shared.av"):
        return "cli-plumbing"
    if path.startswith("packages/cli/"):
        return "commands"
    if name in ("build.av", "db.av", "whole.av"):
        return "build"
    return "compiler"


def use_lines(text):
    """The lines a `use` statement stands on — a list may run over several."""
    out = set()
    for m in re.finditer(r"^use\s[^\n{]*(\{[^}]*\})?", text, re.M):
        first = text.count("\n", 0, m.start())
        out.update(range(first, first + m.group(0).count("\n") + 1))
    return out


def rows_of(text):
    """The world rows a file declares. A module's files share its names,
    so a sibling's row is called here by the same word."""
    return {row for row in EXTERN.findall(text) if row in ROWS}


def sites_in(path, text, module_rows=()):
    """A file's world reads, each with where it stands: through the door,
    licensed as no input, or outside."""
    watched = {}
    spawns = False
    for pkg, name, local in imports(text):
        kind = WORLD.get(pkg, {}).get(name) or INERT.get(pkg, {"world": {}})["world"].get(name)
        if kind in COUNTED:
            watched[local] = kind
        spawns = spawns or (pkg == "process" and name in SPAWNERS)
    for row in rows_of(text) | set(module_rows):
        watched[row] = ROWS[row]
    skipped = use_lines(text)
    patterns = [(called(n), k, n) for n, k in watched.items()]
    out = []
    lines = text.split("\n")
    for i, line in enumerate(lines):
        code = code_of(line)
        if not code or i in skipped or re.match(r"\s*(export\s+)?extern fn ", code):
            continue
        found = [(k, n, False) for pat, k, n in patterns if pat.search(code)]
        found += [("read", "host." + m.group(1), True) for m in HOSTED.finditer(code)]
        if i > 0 and re.search(r"\bhost\s*$", code_of(lines[i - 1])):
            found += [("read", "host." + m.group(1), True) for m in CHAINED.finditer(code)]
        if spawns:
            found += [("spawn", "." + m.group(1), False) for m in SPAWNS.finditer(code)]
        for kind, verb, hosted in found:
            state = ("door" if path in DOOR
                     else "licensed" if i > 0 and LICENSE.match(lines[i - 1])
                     else "outside")
            out.append(Site(path, i + 1, line.strip(), kind, verb, state))
    return out


def unclassified(path, text):
    """What a file names that no table places."""
    out = []
    for m in re.finditer(r"^use\s+@std\b[^\n]*", text, re.M):
        if not USE.match(text, m.start()):
            out.append(f"{path}: `{m.group(0).strip()}` is an import the keeper cannot read — "
                       "name what it takes (`use @std.pkg.{name}`)")
    for pkg in sorted(packages_used(text)):
        if pkg != "avrac" and pkg not in WORLD and pkg not in INERT:
            out.append(f"{path}: `@std.{pkg}` is in neither WORLD nor INERT — say which it is")
    for pkg, name, _ in imports(text):
        if pkg in WORLD and name not in WORLD[pkg]:
            out.append(f"{path}: `{name}` of `@std.{pkg}` is unclassified — add it to WORLD[\"{pkg}\"]")
    for row in EXTERN.findall(text):
        if row not in ROWS and not INERT_ROWS.match(row):
            out.append(f"{path}: the row `{row}` is unclassified — a world read (ROWS) or inert (INERT_ROWS)")
    return out


def inert_faults(pkg, sources):
    """How an INERT package's own source breaks its claim: a row it was
    not pinned to, or an import of a package that reads."""
    out = []
    for path, text in sources:
        for row in EXTERN.findall(text):
            if row not in INERT[pkg]["rows"]:
                out.append(f"{path}: `@std.{pkg}` is INERT and declares `{row}` — pin the row, or the package is WORLD")
        for used in sorted(packages_used(text)):
            if used != pkg and used not in INERT:
                out.append(f"{path}: `@std.{pkg}` is INERT and imports `@std.{used}`, which is not")
    return out


def body_from(text, at):
    """A fn's text from its `fn` to the brace that closes it, by nesting —
    a one-line fn ends on its own line."""
    depth, i, quoted = 0, at, False
    while i < len(text):
        c = text[i]
        if c == "\\":
            i += 1
        elif c == '"':
            quoted = not quoted
        elif not quoted and c == "{":
            depth += 1
        elif not quoted and c == "}":
            depth -= 1
            if depth == 0:
                return text[at:i + 1]
        i += 1
    return text[at:]


FREE_FN = re.compile(r"^(?:export\s+)?(?:mut\s+|once\s+)?fn\s+([A-Za-z_][A-Za-z_0-9]*)", re.M)


def pure_faults(pkg, sources):
    """How a WORLD package's own source breaks a `pure` claim: the fn
    reaches a world row or a counted name of its package, itself or
    through the package's free fns."""
    bodies = collections.defaultdict(str)
    world = {n for n, k in WORLD[pkg].items() if k in COUNTED}
    for _, text in sources:
        code = "\n".join(code_of(l) for l in text.split("\n"))
        world |= {r for r in EXTERN.findall(code) if r in ROWS or not INERT_ROWS.match(r)}
        for m in FREE_FN.finditer(code):
            bodies[m.group(1)] += body_from(code, m.end())
    reach = {}
    for name in bodies:
        hit = next((w for w in sorted(world) if w != name and called(w).search(bodies[name])), None)
        if hit:
            reach[name] = hit
    moved = True
    while moved:
        moved = False
        for name in bodies:
            if name in reach or name in world:
                continue
            hit = next((w for w in sorted(reach) if w != name and called(w).search(bodies[name])), None)
            if hit:
                reach[name], moved = f"{hit} -> {reach[hit]}", True
    return [f"`{n}` of `@std.{pkg}` is classed pure and reaches the world ({n} -> {reach[n]}) — class it by what it reads"
            for n, k in sorted(WORLD[pkg].items()) if k == P and n in reach]


def key(s):
    return (group_of(s.file, s.kind, s.verb.startswith("host.")), s.file, s.text)


def fresh(sites, held):
    """The outside sites the baseline does not list — a line listed
    twice covers two."""
    left = collections.Counter(held)
    out = []
    for s in sites:
        if s.state != "outside":
            continue
        if left[key(s)] > 0:
            left[key(s)] -= 1
        else:
            out.append(s)
    return out


def gone(sites, held):
    """Baseline rows no site answers to any more."""
    left = collections.Counter(held)
    left.subtract(key(s) for s in sites if s.state == "outside")
    return sorted(k for k, n in left.items() for _ in range(max(n, 0)))


def scope_sites(texts):
    """Every site in the scope, a module's rows read by all of its files."""
    rows = collections.defaultdict(set)
    for f, t in texts:
        rows[os.path.dirname(f)] |= rows_of(t)
    return [s for f, t in texts for s in sites_in(f, t, rows[os.path.dirname(f)])]


def scope_files():
    return sorted(f for root in SCOPE for f in glob.glob(root + "/**/*.av", recursive=True)
                  if "/tests/" not in f)


def package_sources(pkg):
    return [(f, open(f).read()) for f in sorted(glob.glob(f"packages/std-{pkg}/src/**/*.av", recursive=True))
            if "/tests/" not in f]


def baseline():
    if not os.path.exists(BASELINE):
        return []
    return [tuple(l.split("\t", 2)) for l in open(BASELINE).read().split("\n")
            if l and not l.startswith("#")]


HEADER = """# WORLD READS OUTSIDE THE INPUT DOOR, one TAB-separated site per line: the
# subsystem it is counted under, its file, and its own source line
# trimmed. This file only ever SHRINKS — `make inputs-accept` prunes what
# a move through the door made gone, and no path through it ADDS a line:
# a new read goes through the door, or is licensed at its site.
"""


def selftest():
    io = "use @std.io.{read_text, env,\n    write_text}\n"
    cases = [
        # refuses: a stray read, an env, a spawn, each naming its line
        ("packages/std-avrac/src/compiler/x.av", io + "fn f() -> string { read_text(\"a\") catch \"\" }\n", [(3, "read", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", io + "fn f() {\n    let v = env(\"HOME\")\n}\n", [(4, "env", "outside")]),
        ("packages/cli/src/commands/x.av", "use @std.process.{tool, cmd}\nfn f() {\n    let t = tool(\"cc\")?\n    cmd(t, []).run()\n}\n",
         [(3, "tool", "outside"), (4, "spawn", "outside")]),
        # every spelling SPAWNS accepts, and every name that turns it on
        ("packages/cli/src/commands/x.av", "use @std.process.{cmd}\nfn f(t: T) { cmd(t, []).outcome() }\n", [(2, "spawn", "outside")]),
        ("packages/cli/src/commands/x.av", "use @std.process.{Command}\nfn f(c: Command) { c.start(r, l) }\n", [(2, "spawn", "outside")]),
        ("packages/cli/src/commands/x.av", "use @std.process.{Tool}\nfn f(c: C) { c.run() }\n", [(2, "spawn", "outside")]),
        ("packages/cli/src/commands/x.av", "use @std.process.{Pipeline}\nfn f(p: Pipeline) { p.outcome() }\n", [(2, "spawn", "outside")]),
        ("packages/cli/src/commands/x.av", "use @std.process.{Runner}\nfn f(r: Runner, c: C) { r.outcome(c) }\n", [(2, "spawn", "outside")]),
        # no spawn: another type's `run`, a reader's verbs, a file that built no command
        ("packages/cli/src/commands/x.av", "use @std.process.{cmd}\nfn f(b: B) { spawn b.run(1) }\n", []),
        ("packages/cli/src/commands/x.av", "use @std.process.{cmd}\nfn f(t: T) { t.lines()\n t.status()\n t.output()\n t.capture()\n t.spawn()\n t.run_in(d) }\n", []),
        ("packages/cli/src/commands/x.av", "use @std.process.{exit}\nfn f(a: A) { a.run() }\n", []),
        # an environment a file asks for is an env read
        ("packages/cli/src/x.av", "use @std.process.{minimal, developer}\nfn f() {\n    minimal()\n    developer()\n}\n",
         [(3, "env", "outside"), (4, "env", "outside")]),
        # a package named with a digit is read like any other
        ("packages/std-avrac/src/compiler/x.av", "use @std.io2.sub3.{env}\nfn f() { env(\"X\") }\n", "IO2"),
        ("packages/std-avrac/src/compiler/x.av", "extern fn avra_host_env(n: string) -> string?\nfn f() { avra_host_env(\"X\") }\n", [(2, "env", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", "fn f(ws: W) { ws.host.read(p) }\n", [(1, "read", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", io + "fn f() { xs.map(read_text) }\n", [(3, "read", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", "fn f(ws: W) { (ws.host.beneath)(root, rel) }\n", [(1, "read", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", "fn f(ws: W) {\n    ws\n        .host\n        .list(dir)\n}\n", [(4, "read", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", "fn f(ws: W) {\n    ws.rows\n        .list(dir)\n}\n", []),
        ("packages/std-avrac/src/compiler/x.av", "use @std.time.{now_ms}\nfn f() -> int { now_ms() }\n", [(2, "clock", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", "use @std.io.{env as os_env}\nfn env(k: string) -> string? { os_env(k) }\n", [(2, "env", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", "fn f() { avra_now_ns() }\n", "ROW"),
        # accepts: the door, a licence, a write, a local fn, a method, a comment, a longer name
        (sorted(DOOR)[0], io + "fn f() { env(\"HOME\") }\n", [(3, "env", "door")]),
        # the door is its file: a neighbour in the directory is outside
        (os.path.dirname(sorted(DOOR)[0]) + "/manifest.av", io + "fn f() { read_text(\"/etc/passwd\") catch \"\" }\n", [(3, "read", "outside")]),
        ("packages/std-avrac/src/compiler/x.av", io + "// LICENSED input.debug_flag: read once, changes no answer\nfn f() { env(\"AVRA_X\") }\n", [(4, "env", "licensed")]),
        ("packages/std-avrac/src/compiler/x.av", io + "fn f() { write_text(\"a\", \"b\") }\n", []),
        ("packages/std-avrac/src/compiler/x.av", "use @std.io.{\n    read_text,\n    env,\n}\nfn f() {}\n", []),
        ("packages/std-avrac/src/compiler/x.av", "fn env(n: string) -> string { n }\nfn f() { env(\"HOME\") }\n", []),
        ("packages/std-avrac/src/compiler/x.av", io + "fn f(c: Cx) { c.env(\"HOME\") }\n", []),
        ("packages/std-avrac/src/compiler/x.av", io + "// env(\"HOME\") is read by the driver\nfn f() {}\n", []),
        ("packages/std-avrac/src/compiler/x.av", io + "fn f() { env_or_else(\"HOME\") }\n", []),
        ("packages/std-avrac/src/compiler/x.av", io + "fn f(env: string) -> T { T { env: env } }\n", []),
    ]
    WORLD["io2"] = {"env": "env"}
    for path, text, want in cases:
        rows, want = ({"avra_now_ns"}, [(1, "clock", "outside")]) if want == "ROW" else ((), want)
        want = [(2, "env", "outside")] if want == "IO2" else want
        got = [(s.line, s.kind, s.state) for s in sites_in(path, text, rows)]
        if got != want:
            sys.exit(f"inputs: self-test failed on {text!r}: {got} != {want}")
    a = sites_in("packages/std-avrac/src/compiler/x.av", io + "fn f() {\n    env(\"A\")\n    env(\"A\")\n}\n")
    held = [key(a[0])]
    if len(fresh(a, held)) != 1 or len(fresh(a, held * 2)) != 0 or len(gone(a[:1], held * 2)) != 1:
        sys.exit("inputs: self-test failed — the baseline is a multiset of sites")
    stale = [
        ("use @std.sockets.{dial}\n", "neither WORLD nor INERT"),
        ("use @std.sha256.{file_digest}\n", "`@std.sha256` is in neither WORLD nor INERT"),
        ("use @std.io\n", "is an import the keeper cannot read"),
        ("use @std.Io.{env}\n", "is an import the keeper cannot read"),
        ("use @std.io.{read_link}\n", "`read_link` of `@std.io` is unclassified"),
        ("extern fn avra_getenv_raw(n: string) -> string\n", "`avra_getenv_raw` is unclassified"),
    ]
    for text, want in stale:
        if not any(want in u for u in unclassified("x.av", text)):
            sys.exit(f"inputs: self-test failed — {text!r} was not refused as {want!r}")
    del WORLD["io2"]
    if unclassified("x.av", "use @std.io.{read_text}\nuse @std.text.{trim}\nuse @std.avrac.core.x9.{A}\nextern fn avra_llvm_x()\n"):
        sys.exit("inputs: self-test failed — a classified file was refused")
    if not inert_faults("path", [("p.av", "extern fn avra_host_env(n: string) -> string?\n")]) \
            or not inert_faults("path", [("p.av", "use @std.io.{env}\n")]) \
            or inert_faults("text", [("t.av", "use @std.text.{trim}\nextern fn avra_str_parses_int(s: string) -> bool\n")]):
        sys.exit("inputs: self-test failed — an inert package is held to its own source")
    WORLD["px"] = {"quiet": P, "one_line": P, "loud": P, "far": P, "named": P, "env": "env"}
    px = [("p.av", "extern fn avra_host_env(n: string) -> string?\n"
                   "export fn env(n: string) -> string? { avra_host_env(n) }\n"
                   "fn held(n: string) -> string? { env(n) }\n"
                   "export fn one_line() -> int { 1 }\n"
                   "export fn loud() -> string? { avra_host_env(\"A\") }\n"
                   "export fn far() -> string? {\n    held(\"A\")\n}\n"
                   "export fn named() -> string? {\n    let s = \"}\"\n    env(s)\n}\n"
                   "export fn quiet(c: C) -> string {\n    // env(\"A\") is the caller's\n    c.env(\"A\")\n}\n")]
    got = [f.split("`")[1] for f in pure_faults("px", px)]
    del WORLD["px"]
    if got != ["far", "loud", "named"]:
        sys.exit(f"inputs: self-test failed — a pure name is held to its own source: {got}")


def main():
    selftest()
    files = scope_files()
    texts = [(f, open(f).read()) for f in files]
    faults = [u for f, t in texts for u in unclassified(f, t)]
    used = {p for _, t in texts for p in packages_used(t)}
    for pkg in sorted(used & set(INERT)):
        sources = package_sources(pkg)
        if not sources:
            faults.append(f"`@std.{pkg}` is INERT and has no source under packages/std-{pkg}/src to hold it to")
        faults += inert_faults(pkg, sources)
    for pkg in sorted(used & set(WORLD)):
        sources = package_sources(pkg)
        if not sources:
            faults.append(f"`@std.{pkg}` is WORLD and has no source under packages/std-{pkg}/src to hold its pure names to")
        faults += [f"{sources[0][0] if sources else pkg}: {f}" for f in pure_faults(pkg, sources)]
    sites = scope_sites(texts)
    if not files or "io" not in used or not sites:
        sys.exit(f"inputs: read {len(files)} file(s) and found {len(sites)} site(s) — nothing was examined")
    held = baseline()
    if "--accept" in sys.argv:
        keep = collections.Counter(held) & collections.Counter(key(s) for s in sites if s.state == "outside")
        with open(BASELINE, "w") as out:
            out.write(HEADER + "".join("\t".join(k) + "\n" for k in sorted(keep.elements())))
        held = sorted(keep.elements())
    new = fresh(sites, held)
    by = collections.Counter((group_of(s.file, s.kind, s.verb.startswith("host.")), s.kind)
                             for s in sites if s.state == "outside")
    states = collections.Counter(s.state for s in sites)
    kinds = sorted({k for _, k in by})
    print(f"inputs: {len(files)} file(s) read, {len(sites)} world read(s): "
          f"{states['door']} through the door, {states['licensed']} licensed, {states['outside']} outside")
    print(f"  {'outside, by subsystem':<24}" + "".join(f"{k:>7}" for k in kinds) + f"{'all':>7}")
    for g in sorted({g for g, _ in by}):
        print(f"  {g:<24}" + "".join(f"{by[(g, k)]:>7}" for k in kinds)
              + f"{sum(by[(g, k)] for k in kinds):>7}")
    for s in new:
        print(f"{s.file}:{s.line}: a world read outside the input door ({s.verb}, {s.kind}) — {s.text}", file=sys.stderr)
    for f in faults:
        print(f"inputs: {f}", file=sys.stderr)
    left = gone(sites, held)
    if left and "--accept" not in sys.argv:
        print(f"inputs: {len(left)} baseline site(s) are gone — `make inputs-accept` prunes them")
    if new or faults:
        sys.exit(f"inputs: refused — {len(new)} new site(s), {len(faults)} unclassified; "
                 "route the read through the door, or license it at the site")


if __name__ == "__main__":
    main()
