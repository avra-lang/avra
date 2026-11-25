# which host clang the compiler resolves, and whether lld stands beside it.
cd "$(dirname "$0")/../.." || exit 1
D=/tmp/lldact.$$
mkdir -p "$D/src"
printf '[package]\nname = "llda"\nversion = "0.1.0"\n' > "$D/avra.toml"
printf 'println("activate")\n' > "$D/src/main.av"
echo "PATH clang: $(command -v clang)"
echo "realpath:   $(readlink -f "$(command -v clang)")"
echo "ld.lld beside PATH clang:     $([ -x "$(dirname "$(command -v clang)")/ld.lld" ] && echo yes || echo no)"
echo "ld.lld beside realpath clang: $([ -x "$(dirname "$(readlink -f "$(command -v clang)")")/ld.lld" ] && echo yes || echo no)"
for cc in UNSET /usr/local/bin/clang /usr/lib/llvm-22/bin/clang; do
  rm -rf "$D/.avra-cache"
  if [ "$cc" = UNSET ]; then
    env -u CC ./avra build "$D" > "$D/out" 2>&1
  else
    CC=$cc ./avra build "$D" > "$D/out" 2>&1
  fi
  s=$?
  echo "CC=$cc exit $s comment: $(readelf -p .comment "$D/src/main" 2>/dev/null | grep -io 'Linker: [^]]*' | head -1)"
done
echo "D=$D"
