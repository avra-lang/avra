#!/bin/sh
make -s try || exit 1
for i in 1 2; do
  find .avra-cache -delete 2>/dev/null
  AVRA_QTRACE=1 build/avra-try check --time packages/std-relation > build/k.out 2> build/k.err
  grep -a "^Q	flush" build/k.err | cut -c1-500
  grep -ah "^time" build/k.out build/k.err | tr ',' '\n' | grep -a "keep\|analyze\|lower" | tr '\n' ' '; echo
done
