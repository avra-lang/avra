#!/usr/bin/env python3
"""The std-avrac witness fixtures vendor std packages: each one's files must
be the files its manifest closure names on disk, no more and no fewer.

The closure of a vendored package is its `[dependencies]` std rows plus the
`use @std.X` lines of its own sources, followed recursively. A fixture file
is an `embed("@std/<pkg>/src/<path>")` constant bound by a `std_file(...)`.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURE = ROOT / "packages/std-avrac/src/testing/mod.av"

EMBED = re.compile(r'^const (\w+): string = embed\("@std/([\w-]+)/src/([\w/.-]+)"\)', re.M)
PKG = re.compile(r'std_pkg\(\s*"([\w-]+)",\s*\[(.*?)\]\s*,?\s*\)', re.S)
FILE = re.compile(r'std_file\(\s*"([\w/.-]+)",\s*(\w+)\s*\)')
USE = re.compile(r"^use @std\.([\w]+)", re.M)
ROW = re.compile(r'^"@std/([\w-]+)"\s*=', re.M)


def package_dir(name):
    return ROOT / "packages" / f"std-{name}"


def sources(name):
    base = package_dir(name) / "src"
    return {
        str(p.relative_to(base))
        for p in base.rglob("*.av")
        if "tests" not in p.relative_to(base).parts
    }


def closure_of(name, seen=None):
    seen = set() if seen is None else seen
    if name in seen:
        return seen
    seen.add(name)
    manifest = package_dir(name) / "avra.toml"
    deps = set(ROW.findall(manifest.read_text())) if manifest.exists() else set()
    base = package_dir(name) / "src"
    for p in base.rglob("*.av"):
        if "tests" not in p.relative_to(base).parts:
            deps |= set(USE.findall(p.read_text()))
    for dep in sorted(deps):
        if package_dir(dep).is_dir():
            closure_of(dep, seen)
    return seen


def fixture_packages(text):
    consts = {name: (pkg, path) for name, pkg, path in EMBED.findall(text)}
    packages = {}
    for pkg_name, body in PKG.findall(text):
        files = packages.setdefault(pkg_name, set())
        for rel, const in FILE.findall(body):
            if const in consts:
                files.add((consts[const][0], consts[const][1]))
    return packages


def problems(text):
    packages = fixture_packages(text)
    wanted = set()
    for name in packages:
        wanted |= closure_of(name)
    out = []
    for name in sorted(wanted):
        if name not in packages:
            out.append(f"the fixture vendors no @std/{name}, which its closure needs")
            continue
        have = {path for pkg, path in packages[name] if pkg == name}
        for rel in sorted(sources(name) - have):
            out.append(f"the fixture lacks @std/{name}/src/{rel}")
    for name, entries in sorted(packages.items()):
        for pkg, path in sorted(entries):
            if pkg == name and not (package_dir(name) / "src" / path).exists():
                out.append(f"the fixture names @std/{name}/src/{path}, which is gone from disk")
    return out


def self_test():
    text = (
        'const a_src: string = embed("@std/alpha/src/a.av")\n'
        'std_pkg("alpha", [std_file("a.av", a_src)])\n'
        'std_pkg("meta", [])\n'
    )
    assert fixture_packages(text) == {"alpha": {("alpha", "a.av")}, "meta": set()}
    lacking = [p for p in problems(text) if "lacks @std/meta/src/rule.av" in p]
    assert lacking, problems(text)
    return ["fixture_packages reads the bound files", "a vendored package missing a source names it"]


def main(argv):
    if "--self-test" in argv:
        for line in self_test():
            print(f"vendored_fixture: self-test {line}")
        return 0
    out = problems(FIXTURE.read_text())
    for line in out:
        print(f"vendored_fixture: {line}")
    if out:
        print(f"vendored_fixture: REFUSED — {len(out)} problem(s): the fixture is not its closure")
        return 1
    print(f"vendored_fixture: clean — {len(fixture_packages(FIXTURE.read_text()))} vendored package(s) match their closure")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
