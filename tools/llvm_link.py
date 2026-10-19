#!/usr/bin/env python3
"""THE COMPILER'S LLVM LINK, named once: `packages/std-avrac/avra.toml`'s `[link]`
rows. The compiler links LLVM statically (docs/2026_10_18_STATIC_LLVM.md), so
that row lists the static component libraries, and the hand-written clang lines
(`make recover`, `make seed-check`) take the SAME words from here instead of a
second spelling.

  llvm_link.py --words    the `-L`/`-l` words, the environment's holes filled
  llvm_link.py --twin     the compiler's platform defaults (whole.av) and this file's agree
  llvm_link.py --check    the row names every component the wrapper needs, as
                          `llvm-config --link-static` lists them, and each is on disk

A component list that lags `llvm-config` is an undefined symbol at the link, which
is loud but far from its cause; this names the missing library.
"""
import os
import subprocess
import sys
import tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "packages", "std-avrac", "avra.toml")
# what llvm_wrapper.c uses: the IR, analysis, bitcode, the linker, the pass
# builder, the host target, WebAssembly, and the target machine
COMPONENTS = ["core", "analysis", "bitwriter", "bitreader", "linker", "passes",
              "native", "webassembly", "target", "irreader"]


def link_row():
    with open(MANIFEST, "rb") as f:
        return tomllib.load(f).get("link", {})


def platform_hole(name):
    """What a hole means on this platform when the environment names nothing: the compiler's
    own `platform_hole` (compiler/whole.av), spelled again because this reader is Python — keep
    the two in step (`make llvm-libs` runs both answers over the same row)."""
    darwin = sys.platform == "darwin"
    if name == "AVRA_CXX_RUNTIME":
        return "c++" if darwin else "stdc++"
    if name == "AVRA_SYS_SEARCH":
        for d in PY_DIRS["darwin" if darwin else "linux"]:
            if any(os.path.exists(os.path.join(d, f"libzstd.{ext}")) for ext in ("a", "so", "dylib")):
                return d
    return ""


def expanded(flag):
    """`${NAME}` filled from the environment, else the platform's answer, as the compiler fills it."""
    out, i = [], 0
    while i < len(flag):
        if flag.startswith("${", i):
            close = flag.find("}", i)
            if close < 0:
                out.append(flag[i:])
                break
            name = flag[i + 2:close]
            out.append(os.environ[name] if name in os.environ else platform_hole(name))
            i = close + 1
        else:
            out.append(flag[i])
            i += 1
    return "".join(out)


WHOLE = os.path.join(ROOT, "packages", "std-avrac", "src", "compiler", "whole.av")
PY_DIRS = {"darwin": ["/opt/homebrew/lib", "/usr/local/lib"],
           "linux": ["/usr/lib/x86_64-linux-gnu", "/usr/lib/aarch64-linux-gnu", "/usr/lib64", "/usr/lib"]}


def twin():
    """The compiler's `platform_hole` (whole.av) and this file's answer the same thing: read the
    compiler's literals out of its source and hold them to this file's. A keeper with no compiler."""
    import re
    src = open(WHOLE).read()
    body = src[src.index("fn platform_hole"):]
    runtime = re.search(r'"AVRA_CXX_RUNTIME" -> if links_with_ld64\(\) \{ "([^"]+)" \} else \{ "([^"]+)" \}', body)
    lists = re.findall(r"\[((?:\s*\"/[^\"]+\",?)+)\s*\]", body[body.index("fn system_library_dir"):])
    got = [re.findall(r'"(/[^"]+)"', x) for x in lists]
    bad = []
    if not runtime or (runtime[1], runtime[2]) != ("c++", "stdc++"):
        bad.append(f"the C++ runtime names differ: compiler {runtime and runtime.groups()} vs c++/stdc++")
    if got != [PY_DIRS["darwin"], PY_DIRS["linux"]]:
        bad.append(f"the system library directories differ: compiler {got} vs {[PY_DIRS['darwin'], PY_DIRS['linux']]}")
    for b in bad:
        print("llvm-link: " + b, file=sys.stderr)
    if not bad:
        print("llvm-link: the compiler's platform defaults and llvm_link.py's agree")
    return 1 if bad else 0


def words():
    link = link_row()
    return [letter + w
            for key, letter in (("search", "-L"), ("libs", "-l"))
            for w in (expanded(r) for r in link.get(key, [])) if w]


def check():
    prefix = os.environ.get("LLVM_PREFIX", "/opt/homebrew/opt/llvm")
    config = os.path.join(prefix, "bin", "llvm-config")
    if not os.path.exists(config):
        config = "llvm-config"
    got = subprocess.run([config, "--link-static", "--libs"] + COMPONENTS,
                         capture_output=True, text=True)
    if got.returncode != 0:
        print(f"llvm-link: `{config} --link-static --libs` failed: {got.stderr.strip()}", file=sys.stderr)
        return 1
    needed = [w[2:] for w in got.stdout.split() if w.startswith("-l")]
    named = set(link_row().get("libs", []))
    libdir = subprocess.run([config, "--libdir"], capture_output=True, text=True).stdout.strip()
    missing = [n for n in needed if n not in named]
    absent = [n for n in needed if not os.path.exists(os.path.join(libdir, f"lib{n}.a"))]
    if missing or absent:
        if missing:
            print(f"llvm-link: packages/std-avrac/avra.toml [link] libs lacks {' '.join(missing)}", file=sys.stderr)
        if absent:
            print(f"llvm-link: no static archive under {libdir} for {' '.join(absent)}", file=sys.stderr)
        return 1
    print(f"llvm-link: {len(needed)} component librar(y|ies) of {len(COMPONENTS)} components named by the manifest, all on disk")
    return 0


if __name__ == "__main__":
    # the platform's answers, as the shim and the Makefile give them
    os.environ.setdefault("LLVM_PREFIX", "/opt/homebrew/opt/llvm")
    mac = sys.platform == "darwin"
    os.environ.setdefault("AVRA_CXX_RUNTIME", "c++" if mac else "stdc++")
    if mac:
        os.environ.setdefault("AVRA_SYS_SEARCH", "/opt/homebrew/lib")
    if len(sys.argv) == 2 and sys.argv[1] == "--words":
        print(" ".join(words()))
        sys.exit(0)
    if len(sys.argv) == 2 and sys.argv[1] == "--twin":
        sys.exit(twin())
    if len(sys.argv) == 2 and sys.argv[1] == "--check":
        sys.exit(check())
    print("usage: llvm_link.py --words | --check | --twin", file=sys.stderr)
    sys.exit(2)
