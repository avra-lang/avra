"""The keepers' licence families, asked of the compiler (`avra licences
--json`, compiler/licenses.av's `families`): the one definition. A keeper
builds the pattern of its own family's id from here and keeps no regex of
its own, so the compiler and the keeper cannot disagree about which ids a
family holds. The compiler is `$AVRA` or `build/avra`."""
import json
import os
import re
import subprocess

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def avra(*args):
    exe = os.environ.get("AVRA") or os.path.join(ROOT, "build", "avra")
    if not os.access(exe, os.X_OK):
        raise SystemExit("licence_families: no compiler at %s — a keeper that reads the licence table needs one (set AVRA)" % exe)
    done = subprocess.run([exe, "licences", *args], capture_output=True, text=True, cwd=ROOT)
    if done.returncode != 0:
        raise SystemExit("licence_families: `avra licences %s` failed: %s" % (" ".join(args), done.stderr.strip()))
    return done.stdout.strip()


def families():
    """Every family the compiler holds: prefix, shape, keeper."""
    return json.loads(avra("--json"))


def id_pattern(prefix):
    """The regex source of one family's licence id: its prefix, then its shape."""
    shape = {f["prefix"]: f["shape"] for f in families()}[prefix]
    return re.escape(prefix) + ("[a-z_]+" if shape == "snake" else re.escape(shape))


# One licensed line and one near miss per family, and the ids of both kinds.
CASES = [
    ("input.clock", True), ("input.saved_read", True), ("input.Clock", False), ("input.", False), ("input.a1", False),
    ("inputs.x", False), ("whole.cold", True), ("whole.colder", False), ("whole.", False), ("nonsense.x", False),
]


def selftest():
    """Each case's verdict from the compiler's own `--cites` against the keepers' pattern."""
    for id, _ in CASES:
        theirs = any(re.fullmatch(id_pattern(f["prefix"]), id) for f in families())
        ours = avra("--cites", id) == "true"
        assert theirs == ours, "%r: the compiler says %s, the keeper pattern says %s" % (id, ours, theirs)
    assert all((avra("--cites", id) == "true") == want for id, want in CASES), "the cases disagree with the compiler"
