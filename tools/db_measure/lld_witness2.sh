# lld witness on an ELF host: the link that runs, two clean builds
# byte-identical, and the difference the other linker leaves.
cd "$(dirname "$0")/../.." || exit 1
D=/tmp/lldw.$$
mkdir -p "$D/src"
printf '[package]\nname = "lldw"\nversion = "0.1.0"\n' > "$D/avra.toml"
printf 'println("lld witness")\n' > "$D/src/main.av"

REAL=$(readlink -f "$(command -v clang)")
echo "== env"
echo "clang:      $REAL"
"$REAL" --version | head -1
REAL_LLD=$(dirname "$REAL")/ld.lld
[ -x "$REAL_LLD" ] || REAL_LLD=/usr/lib/llvm-22/bin/ld.lld
[ -x "$REAL_LLD" ] || REAL_LLD=$(command -v ld.lld)
echo "ld.lld:     $REAL_LLD $( [ -x "$REAL_LLD" ] && echo present || echo absent)"
readelf --version | head -1

# a clang wrapper that logs its words; one dir carries ld.lld, one does not
mkcc() {
  W=$D/$1
  mkdir -p "$W"
  printf '#!/bin/sh\nprintf "%%s\\n" "$@" >> %s/args\n' "$W" > "$W/clang"
  printf 'exec %s "$@"\n' "$REAL" >> "$W/clang"
  chmod +x "$W/clang"
  [ "$2" = lld ] && ln -s "$REAL_LLD" "$W/ld.lld"
  echo "$W/clang"
}
CC_LLD=$(mkcc cc-lld lld)
CC_DEF=$(mkcc cc-def def)

build() {
  rm -rf "$D/.avra-cache"
  CC=$1 ./avra build "$D" > "$D/$2.out" 2>&1
  echo "build $2 exit $?"
}

echo "== lld link (ld.lld beside the linking clang)"
build "$CC_LLD" lld.1
cp "$D/src/main" "$D/lld.1"
echo "ld-path word: $(grep -o -- '--ld-path=[^ ]*' "$D/cc-lld/args" | head -1)"
build "$CC_LLD" lld.2
cp "$D/src/main" "$D/lld.2"
cmp -s "$D/lld.1" "$D/lld.2" &&
  echo "lld: two clean builds SAME ($(wc -c < "$D/lld.1") bytes)" ||
  echo "lld: two clean builds DIFFER"
readelf -p .comment "$D/lld.1" 2>/dev/null | grep -i "Linker:" | head -1
readelf -n "$D/lld.1" 2>/dev/null | grep -i "build id" | head -1

echo "== default link (the same clang, no ld.lld beside it)"
build "$CC_DEF" def
cp "$D/src/main" "$D/def"
echo "ld-path word: $(grep -o -- '--ld-path=[^ ]*' "$D/cc-def/args" | head -1)"
readelf -p .comment "$D/def" 2>/dev/null | grep -i "Linker:" | head -1
cmp -s "$D/lld.1" "$D/def" &&
  echo "lld vs default: BINARY IDENTICAL" ||
  echo "lld vs default: DIFFER ($(wc -c < "$D/lld.1") vs $(wc -c < "$D/def") bytes)"
"$D/lld.1" > "$D/out.lld" 2>&1; "$D/def" > "$D/out.def" 2>&1
cmp -s "$D/out.lld" "$D/out.def" &&
  echo "program output: IDENTICAL ($(cat "$D/out.lld"))" ||
  echo "program output: DIFFER"
echo "first byte they differ at: $(cmp "$D/lld.1" "$D/def" 2>&1 | head -1)"

echo "== link time (warm, --time)"
for cc in "$CC_LLD" "$CC_DEF"; do
  for i in 1 2; do CC=$cc ./avra build --time "$D" 2>&1 | grep -oE 'link [0-9]+ms' | tail -1; done
done
echo "D=$D"
