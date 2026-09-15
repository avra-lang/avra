"""THE GATE'S SUITES, DERIVED. Every package under `packages/` whose
tree holds a spec file (`*_test.av`) or a program test (an `.av`
beside its `.expected`) is a suite, and its manifest's
`[dependencies]` order it after what it depends on. A hand-kept list
is a registry that silently forgets its next member: a package that
joined the tree with a suite would run none of it while the gate
reported green.

Prints the suites in dependency order, one per line; `--report`
counts them on one line; `--self-test` runs the fixtures. Exit 1
names a cycle, a dependency path that is not a package, a directory
holding tests with no manifest, or a symlinked package.
"""
import glob, os, re, shutil, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SECTION = re.compile(r"^\[([^\]]+)\]", re.M)
DEP = re.compile(r'^\s*"(@[^"]+)"\s*=\s*\{\s*path\s*=\s*"([^"]+)"', re.M)


def has_tests(pkg):
    return any(path.endswith(("_test.av", ".expected"))
               for path in glob.glob(os.path.join(pkg, "**", "*"), recursive=True))


def deps(pkg):
    """The `[dependencies]` rows alone: a dev-dependency may point UP
    (a text package's tests print through io), so it orders nothing."""
    parts = SECTION.split(open(os.path.join(pkg, "avra.toml")).read())
    body = "".join(parts[i + 1] for i in range(1, len(parts), 2) if parts[i] == "dependencies")
    return [os.path.normpath(os.path.join(pkg, rel)) for _, rel in DEP.findall(body)]


def ordered(packages, root):
    """Every package after what it depends on; ties keep name order."""
    done, out = set(), []

    def visit(pkg, trail):
        if pkg in done:
            return
        if pkg in trail:
            sys.exit("suites: a cycle — " + " -> ".join(os.path.relpath(p, root) for p in trail + [pkg]))
        if not os.path.exists(os.path.join(pkg, "avra.toml")):
            sys.exit(f"suites: {os.path.relpath(pkg, root)} is named as a dependency and is not a package")
        for d in sorted(deps(pkg)):
            visit(d, trail + [pkg])
        done.add(pkg)
        out.append(pkg)

    for pkg in sorted(packages):
        visit(pkg, [])
    return out


def suites(root):
    dirs = sorted(d for d in glob.glob(os.path.join(root, "packages", "*")) if os.path.isdir(d))
    for d in dirs:
        if os.path.islink(d):
            sys.exit(f"suites: {os.path.relpath(d, root)} is a symlink — a package is a real directory, or its suite runs under two names")
        if has_tests(d) and not os.path.exists(os.path.join(d, "avra.toml")):
            sys.exit(f"suites: {os.path.relpath(d, root)} holds tests and no avra.toml — nothing would ever run them")
    carrying = {d for d in dirs if has_tests(d)}
    return [os.path.relpath(p, root) for p in ordered(carrying, root) if p in carrying]


# ── The fixtures: the tool run against trees built to break it ──

def tree(made, spec):
    """A tree from {name: (deps, dev_deps, has_test)}, on the list of
    trees to remove; answers its root."""
    root = tempfile.mkdtemp()
    made.append(root)
    for name, (ds, dev, tested) in spec.items():
        pkg = os.path.join(root, "packages", name)
        os.makedirs(os.path.join(pkg, "src", "tests"))
        rows = lambda names: "".join(f'"@t/{n}" = {{ path = "../{n}" }}\n' for n in names)
        with open(os.path.join(pkg, "avra.toml"), "w") as f:
            f.write(f'[package]\nname = "@t/{name}"\n[dependencies]\n{rows(ds)}[dev-dependencies]\n{rows(dev)}')
        if tested:
            open(os.path.join(pkg, "src", "tests", f"{name}_test.av"), "w").close()
    return root


def refuses(root, words):
    try:
        suites(root)
    except SystemExit as e:
        assert words in str(e), str(e)
        return
    raise AssertionError(f"accepted a tree that should refuse: {words}")


def self_test():
    made = []
    try:
        fixtures(lambda spec: tree(made, spec))
    finally:
        for root in made:
            shutil.rmtree(root)


def fixtures(tree):
    root = tree({"a": ([], [], True), "b": (["a"], [], True), "c": (["b"], [], False), "d": (["c"], [], True)})
    assert suites(root) == ["packages/a", "packages/b", "packages/d"], suites(root)
    root = tree({"io": (["text"], [], True), "text": ([], ["io"], True)})
    assert suites(root) == ["packages/text", "packages/io"], "a dev edge orders nothing"
    refuses(tree({"a": (["b"], [], True), "b": (["a"], [], False)}), "a cycle")
    refuses(tree({"a": (["ghost"], [], True)}), "ghost is named as a dependency")
    assert suites(tree({"quiet": ([], [], False)})) == [], "a package without tests is no suite"
    root = tree({"a": ([], [], True)})
    os.makedirs(os.path.join(root, "packages", "loose", "src", "tests"))
    open(os.path.join(root, "packages", "loose", "src", "tests", "loose_test.av"), "w").close()
    refuses(root, "loose holds tests and no avra.toml")
    root = tree({"a": ([], [], True)})
    os.symlink(os.path.join(root, "packages", "a"), os.path.join(root, "packages", "alias"))
    refuses(root, "alias is a symlink")
    print("suites: self-test passed — 7 fixtures")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    found = suites(ROOT)
    if "--report" in sys.argv:
        print(f"suites: {len(found)} package(s) carry tests, ordered by their manifests — {' '.join(found)}")
        return
    print("\n".join(found))


if __name__ == "__main__":
    main()
