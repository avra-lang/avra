#!/usr/bin/env python3
"""THE FOOTPRINT KEEPER: a program that spawns nothing links no scheduler.

The runtime is an archive, one object per `runtime/*.c`, and a link takes
only the members a program reaches. This holds that to account on real
binaries, and prints what the smallest programs weigh.

  THE SCHEDULER is the archive's SCHEDULER members: every global one of
  them defines is banned from a program that never spawns. The list is
  read from the archive the programs link, never from a list of names.
  WHAT A TASK CARRIES (TASK_STATE) wears the scheduler's prefix and is the
  core runtime's by design: main's own slots and id, read where no
  scheduler is linked. Any OTHER scheduler-named global outside the
  scheduler members is refused, so a moved fn or a new object asks here.
  THE SIZE is the stripped file and its code, per platform, against
  tools/footprint.baseline. The cap is RELATIVE (CEILING): a tenth of the
  floor is one small fn family and the toolchain's own drift between
  machines, and a fifteenth of what linking the scheduler adds.

  python3 tools/footprint.py              # the gate
  python3 tools/footprint.py --accept     # re-accept this platform's sizes
  python3 tools/footprint.py --self-test  # the rules on fixtures, no compiler
"""
import os, platform, re, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tools", "footprint")
BASELINE = os.environ.get("FOOTPRINT_BASELINE", os.path.join(ROOT, "tools", "footprint.baseline"))
SCHEDULER = ("avra_fiber.o", "avra_cores.o")
SCHEDULER_NAMED = re.compile(r"avra_(fiber|wait_|gate_|vgate_|vtask|task_|tasks_|sched_|cores)")
TASK_STATE = {"avra_task_slot", "avra_task_slot_set", "avra_task_id", "avra_task_local"}
# Programs that spawn nothing, and the one that must be refused.
CLEAN = ("hello", "data", "slot")
SPAWNING = "spawns"
SIZED = ("hello", "data")
CEILING = 10


def say(words):
    print(f"footprint: {words}")


def plain(name):
    """A symbol as C spells it: Mach-O leads every one with an underscore."""
    return name[1:] if platform.system() == "Darwin" and name.startswith("_") else name


def members_of(listing):
    """`nm` over an archive -> {member: (defined globals, undefined)}."""
    members, at = {}, None
    for line in listing.splitlines():
        line = line.strip()
        head = re.match(r"(?:.*\()?([\w.-]+\.o)\)?:$", line)
        if head:
            at = members.setdefault(head.group(1), (set(), set()))
            continue
        parts = line.split()
        if at is None or len(parts) < 2:
            continue
        kind, name = parts[-2], plain(parts[-1])
        if kind == "U":
            at[1].add(name)
        elif kind.isupper():
            at[0].add(name)
    return members


def symbols_of(listing):
    """`nm` over a binary -> every name it carries."""
    return {plain(parts[-1]) for parts in (l.split() for l in listing.splitlines()) if len(parts) >= 2}


def banned_of(members):
    """The scheduler's globals, by the member that defines each."""
    return {name: m for m in SCHEDULER if m in members for name in members[m][0]}


def strays(members):
    """Scheduler-named globals that live outside the scheduler and are not what a task carries."""
    return sorted((name, m) for m, (defined, _) in members.items() if m not in SCHEDULER
                  for name in defined if SCHEDULER_NAMED.match(name) and name not in TASK_STATE)


def carried(symbols, banned):
    return sorted(symbols & set(banned))


def pulled_by(found, banned, members, ir):
    """Who reaches the scheduler: the program's own calls, else the linked members that name it."""
    own = sorted(n for n in banned if re.search(r"\bcall\b[^\n]*@" + re.escape(n) + r"\(", ir))
    if own:
        return f"the program's own code calls `{'`, `'.join(own[:3])}`{' …' if len(own) > 3 else ''}"
    by = sorted({m for m, (_, wants) in members.items() if wants & set(found)})
    return f"reached from {', '.join(by)}" if by else "reached from an object outside the runtime archive"


def shown(found, banned):
    """Carried scheduler symbols as words: the count, the first three, their members."""
    some = ", ".join(f"`{n}` ({banned[n]})" for n in found[:3])
    return f"{len(found)} scheduler symbol(s): {some}{' …' if len(found) > 3 else ''}"


def cap(base):
    return base + base * CEILING // 100


def baseline_rows(text):
    """`<platform> <program> <bytes> <text>` lines -> {(platform, program): (bytes, text)}."""
    rows = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) == 4 and not line.startswith("#"):
            rows[(parts[0], parts[1])] = (int(parts[2]), int(parts[3]))
    return rows


def over(now, base):
    """The quantities past their cap, as words."""
    return [f"{what} {n} > cap {cap(b)} (accepted {b}, +{CEILING}%)"
            for what, n, b in (("bytes", now[0], base[0]), ("text", now[1], base[1])) if n > cap(b)]


# ── The machine ──

def ran(*words):
    return subprocess.run(words, capture_output=True, text=True)


def host():
    return f"{platform.system().lower()}-{platform.machine().lower()}"


def code_size(binary):
    """Bytes of code: ELF's text column, Mach-O's `__text` section."""
    if platform.system() == "Darwin":
        found = re.search(r"Section __text: (\d+)", ran("size", "-m", binary).stdout)
        return int(found.group(1)) if found else 0
    rows = ran("size", binary).stdout.splitlines()
    return int(rows[1].split()[0]) if len(rows) > 1 else 0


def stripped_size(binary):
    """The file with no symbol table: a symbol spells the path it was built at."""
    bare = binary + ".stripped"
    if ran("strip", "-o", bare, binary).returncode != 0:
        return 0
    return os.path.getsize(bare)


def built(avra, name, work):
    """A fixture built in `work` -> (binary, its IR), or the build's own words."""
    at = os.path.join(work, name)
    shutil.copytree(os.path.join(FIXTURES, name), at, ignore=shutil.ignore_patterns("main", ".avra-cache"))
    made = ran(avra, "build", at)
    binary = os.path.join(at, "src", "main")
    if made.returncode != 0 or not os.path.isfile(binary):
        return None, (made.stdout + made.stderr).strip()
    return binary, ran(avra, "emit", at).stdout


def gate(accept):
    avra = os.environ.get("AVRA", os.path.join(ROOT, "build", "avra"))
    archive = os.path.join(os.path.dirname(avra), "libavra_runtime.a")
    for need in (avra, archive):
        if not os.path.isfile(need):
            say(f"nothing at {need} — build it first")
            return 1
    members = members_of(ran("nm", archive).stdout)
    banned = banned_of(members)
    absent = [m for m in SCHEDULER if m not in members]
    if absent or not banned:
        say(f"the archive names no scheduler ({', '.join(absent) or 'no globals'}) — nothing would be refused")
        return 1
    fail = 0
    for name, m in strays(members):
        say(f"`{name}` wears the scheduler's name in {m} — move it, or name it in TASK_STATE")
        fail = 1
    say(f"{len(members)} runtime member(s), {len(banned)} scheduler global(s) in {' + '.join(SCHEDULER)}; "
        f"what a task carries ({len(TASK_STATE)} name(s)) is the core runtime's")

    accepted = baseline_rows(open(BASELINE).read()) if os.path.isfile(BASELINE) else {}
    sizes, read = {}, 0
    with tempfile.TemporaryDirectory(prefix="avra-footprint.") as work:
        for name in CLEAN + (SPAWNING,):
            binary, ir = built(avra, name, work)
            if binary is None:
                say(f"{name} did not build:\n{ir}")
                fail = 1
                continue
            symbols = symbols_of(ran("nm", binary).stdout)
            read += len(symbols)
            if not symbols:
                say(f"{name} names no symbol — a stripped binary proves nothing")
                fail = 1
                continue
            found = carried(symbols, banned)
            if name == SPAWNING:
                if not found:
                    say(f"{name} spawns a task and carries no scheduler symbol — the gate cannot see one")
                    fail = 1
                else:
                    say(f"witness: {name} is refused — it carries {shown(found, banned)}; "
                        f"{pulled_by(found, banned, members, ir)}")
                continue
            if found:
                say(f"{name} spawns nothing and carries {shown(found, banned)}; "
                    f"{pulled_by(found, banned, members, ir)}")
                fail = 1
            if name in SIZED:
                sizes[name] = (stripped_size(binary), code_size(binary))

    for name, now in sizes.items():
        base = accepted.get((host(), name))
        if 0 in now:
            say(f"{name} could not be sized here (`strip` or `size` answered nothing)")
            fail = 1
        elif accept or base is None:
            say(f"{name} {now[0]} bytes, text {now[1]} — {'accepted' if accept else f'no baseline for {host()}, uncapped'}")
        else:
            say(f"{name} {now[0]} bytes (accepted {base[0]}), text {now[1]} (accepted {base[1]}), cap +{CEILING}%")
            for words in over(now, base):
                say(f"{name} GREW: {words} — a floor that creeps is every program's cost; "
                    f"`make footprint-accept` if it is meant")
                fail = 1
    if accept and not fail:
        kept = {k: v for k, v in accepted.items() if k[0] != host()}
        kept.update({(host(), name): now for name, now in sizes.items()})
        with open(BASELINE, "w") as out:
            out.write("# THE LAST ACCEPTED FOOTPRINT, written by `make footprint-accept`:\n"
                      "# <platform> <program> <stripped bytes> <code bytes>. A platform with no row is uncapped.\n")
            for (plat, name), (size, code) in sorted(kept.items()):
                out.write(f"{plat} {name} {size} {code}\n")
    if fail:
        say("REFUSED")
        return 1
    say(f"clean — {len(CLEAN)} program(s) carry no scheduler, 1 witness refused, {read} symbol(s) read, "
        f"{len(sizes)} sized on {host()}")
    return 0


# ── The rules, on fixtures ──

def self_test():
    elf = "avra_fiber.o:\n0000 T avra_task_spawn\n0000 t park\n     U malloc\n\navra_runtime.o:\n0000 T avra_task_id\n0000 T avra_str_len\n     U avra_rc_retain\n\navra_cores.o:\n0000 T avra_cores_fork\n     U avra_task_spawn\n"
    members = members_of(elf)
    banned = banned_of(members)
    checks = [
        ("an ELF archive's members", sorted(members) == ["avra_cores.o", "avra_fiber.o", "avra_runtime.o"]),
        ("a Mach-O member head", list(members_of("lib.a(avra_fiber.o):\n0000 T avra_task_spawn\n")) == ["avra_fiber.o"]),
        ("globals are banned, statics are not", banned == {"avra_task_spawn": "avra_fiber.o", "avra_cores_fork": "avra_cores.o"}),
        ("a program without them is clean", carried({"main", "avra_str_len", "avra_task_id"}, banned) == []),
        ("a program with one is refused by name", carried({"main", "avra_task_spawn"}, banned) == ["avra_task_spawn"]),
        ("what a task carries is no stray", strays(members) == []),
        ("a scheduler name in the core runtime is a stray",
         strays(members_of(elf + "\navra_hot.o:\n0000 T avra_wait_fd\n")) == [("avra_wait_fd", "avra_hot.o")]),
        ("each scheduler prefix is read", all(SCHEDULER_NAMED.match(n) for n in (
            "avra_fiber_yield", "avra_wait_fd", "avra_gate_new", "avra_vgate_open", "avra_vtask_new",
            "avra_task_join", "avra_tasks_push", "avra_sched_polls", "avra_cores_fork"))),
        ("a core name is not the scheduler's", not SCHEDULER_NAMED.match("avra_array_push")),
        ("the program's own call is named",
         pulled_by(["avra_task_spawn"], banned, members, "call ptr @avra_task_spawn(ptr %f)")
         == "the program's own code calls `avra_task_spawn`"),
        ("a longer name is not that call",
         "own code" not in pulled_by(["avra_task_spawn"], banned, members, "call ptr @avra_task_spawn_all()")),
        ("a declaration is not a call", "own code" not in pulled_by(["avra_task_spawn"], banned, members, "declare ptr @avra_task_spawn(ptr)")),
        ("a member that reaches it is named", pulled_by(["avra_task_spawn"], banned, members, "") == "reached from avra_cores.o"),
        ("three are shown, the rest counted", shown(["a", "b", "c", "d"], dict.fromkeys("abcd", "m.o")).endswith("`c` (m.o) …")),
        ("the cap is a tenth", cap(1000) == 1100),
        ("at the cap is accepted", over((1100, 1100), (1000, 1000)) == []),
        ("past it names the quantity", [w.split()[0] for w in over((1101, 900), (1000, 1000))] == ["bytes"]),
        ("code past it is named too", [w.split()[0] for w in over((900, 1101), (1000, 1000))] == ["text"]),
        ("a baseline row is read, a comment is not",
         baseline_rows("# linux-x86_64 hello 1 2\nlinux-x86_64 hello 10 20\n") == {("linux-x86_64", "hello"): (10, 20)}),
        ("a binary's names are read", symbols_of("0000 T main\n     U malloc\n") == {"main", "malloc"}),
    ]
    failed = [what for what, held in checks if not held]
    for what in failed:
        say(f"self-test failed: {what}")
    if not failed:
        say(f"self-test: {len(checks)} rule(s) hold")
    return 1 if failed else 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    sys.exit(gate("--accept" in sys.argv))
