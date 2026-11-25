"""THE SOURCES A KEEPER READS: one walk over a tree's `.av` files and one cut of a body by
its braces. A keeper that walks its own copy reads a different tree from the one beside it."""
import glob
import os

TESTS = os.sep + "tests" + os.sep


def av_files(roots, at=".", tests=False):
    """Every `.av` file under each of `roots`, relative to `at`, in path order — a module's
    `tests/` left out unless `tests` asks for them."""
    found = (os.path.relpath(p, at) for r in roots
             for p in glob.glob(os.path.join(at, r, "**", "*.av"), recursive=True))
    return sorted(p for p in found if tests or TESTS not in os.sep + p)


def braced_end(text, at):
    """Where the brace that closes the first `{` at or after `at` stands — strings skipped,
    nesting counted — or None when it never closes."""
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
                return i
        i += 1
    return None


if __name__ == "__main__":
    assert braced_end('fn f() { "}" { x } }', 0) == 19, braced_end('fn f() { "}" { x } }', 0)
    assert braced_end("fn f() { x", 0) is None
    assert braced_end("fn f() { a }\nfn g() { b }", 13) == 24
    print("avsrc: self-test passed")
