#!/bin/sh
make try > build/try.log 2>&1 || { tail -20 build/try.log; exit 1; }
cp build/avra-try build/avra
R=build/rc; find $R -mindepth 1 -delete 2>/dev/null; mkdir -p $R/p/src
printf '[package]\nname = "sa-p"\nversion = "0.1.0"\n' > $R/p/avra.toml
printf 'use more.{helper}\nfn main() {\n    println("${helper()}")\n}\n' > $R/p/src/main.av
echo 'export fn helper() -> int { 4 }' > $R/p/src/more.av
export AVRA_WATCH_HELD=1 AVRA_MAX_COMPILES=0
find .avra-cache -mindepth 1 -delete 2>/dev/null
AVRA_QTRACE=1 ./avra check $R/p > /dev/null 2> $R/a.err
AVRA_INLINE_RUNTIME=0 AVRA_QTRACE=1 ./avra check $R/p > /dev/null 2> $R/b.err
echo "seed lines:"; grep '^Q	store	kind' $R/a.err | cut -f4-6 | sort | uniq -c
echo "second lines:"; grep '^Q	store	kind' $R/b.err | cut -f4-6 | sort | uniq -c
