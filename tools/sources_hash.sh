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

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

find Makefile backend runtime packages \
     -type f \( -name '*.av' -o -name '*.c' -o -name '*.h' -o -name '*.toml' \) \
     ! -path '*/build/*' ! -path '*/vendor/*' 2>/dev/null \
  | LC_ALL=C sort \
  | while IFS= read -r f; do
        printf '%s %s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$f"
    done \
  | shasum -a 256 | cut -d' ' -f1
