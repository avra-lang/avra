export LLVM_PREFIX=/usr/lib/llvm-22
make -o avra libs >/dev/null 2>&1
R=/tmp/held_chain; rm -rf $R; mkdir -p $R/src $R/vendor/dep/src $R/vendor/deeper/src
printf '[package]\nname = "app"\nversion = "0.1.0"\n\n[dependencies]\n"@acme/dep" = { path = "vendor/dep" }\n' > $R/avra.toml
printf '[package]\nname = "@acme/dep"\nversion = "0.1.0"\n\n[dependencies]\n"@acme/deeper" = { path = "../deeper" }\n' > $R/vendor/dep/avra.toml
printf '[package]\nname = "@acme/deeper"\nversion = "0.1.0"\n' > $R/vendor/deeper/avra.toml
echo 'export fn other() -> int { 1 }' > $R/vendor/deeper/src/deeper.av
echo 'export fn base() -> int { 39 }' > $R/vendor/deeper/src/core.av
echo 'export fn unused() -> int { 1 }' > $R/vendor/dep/src/dep.av
printf 'use @acme.deeper.core.{base}\nexport fn framed() -> int { base() + 1 }\n' > $R/vendor/dep/src/frame.av
printf 'use @acme.dep.frame.{framed}\nexport fn go() -> int { framed() + 1 }\n' > $R/src/lib.av
printf 'use lib.{go}\nprintln("${go()}")\n' > $R/src/entry.av
T=$PWD
( cd $R && $T/build/avra build src/entry.av > /tmp/b1.log 2>&1; echo "build1=$?"; tail -3 /tmp/b1.log; ls src/ )
printf 'use lib.{go}\nprintln("${go() + 1}")\n' > $R/src/entry.av
( cd $R && AVRA_QTRACE=1 $T/build/avra build src/entry.av > /tmp/b2.log 2>&1; echo "build2=$?"; grep -aE "Q.(mint|hold|mint_module|admit_module|package_admitted)|avra:" /tmp/b2.log | head -60 )
echo "answer: $(/tmp/held_chain/src/entry 2>&1 | head -1)"
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
