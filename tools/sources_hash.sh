#!/bin/sh
# The identity of the inputs the compiler's own build reads: the
# Makefile's flags, our C, and every package source and manifest, hashed
# in one deterministic order.
#
# `make seed` records this beside the seed, so a fresh checkout can ask
# whether the seed already IS its compiler and take the 20-second
# `recover` path instead of a full build. A mismatch only costs a
# build — it can never be read as "up to date" when it is not, because
# the same function computes both sides.
set -eu

mode=work
case "${1:-}" in
    --head) mode=head ;;
    "") ;;
    *) echo "sources_hash: unknown argument '$1' (want --head or nothing)" >&2; exit 2 ;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

# ONE PREDICATE, TWO SOURCES. The committed mode must select EXACTLY the
# set the working mode selects on a clean tree — the extensions and the
# build/ and vendor/ exclusions — or the two hashes can never agree and
# the guard that compares them fires forever. `Makefile` is NOT in the
# working set (it matches no listed extension), so it is not in this one:
# a second predicate that looks right is how the two sides diverge.
if [ "$mode" = head ]; then
    git rev-parse --git-dir >/dev/null 2>&1 \
      || { echo "sources_hash: --head needs a git work tree" >&2; exit 2; }
    listing() {
        git ls-tree -r --name-only HEAD \
          | grep -E '^(backend/|runtime/|packages/)' \
          | grep -E '\.(av|c|h|toml)$' \
          | grep -vE '(^|/)(build|vendor)/' \
          | LC_ALL=C sort
    }
    digest() { git show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }
else
    listing() {
        find Makefile backend runtime packages \
             -type f \( -name '*.av' -o -name '*.c' -o -name '*.h' -o -name '*.toml' \) \
             ! -path '*/build/*' ! -path '*/vendor/*' 2>/dev/null \
          | LC_ALL=C sort
    }
    digest() { shasum -a 256 "$1" | cut -d' ' -f1; }
fi

listing \
  | while IFS= read -r f; do
        printf '%s %s\n' "$(digest "$f")" "$f"
    done \
  | shasum -a 256 | cut -d' ' -f1
