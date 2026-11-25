#!/bin/sh
make -s try || exit 1
for i in 1 2 3; do
  find .avra-cache -delete 2>/dev/null
  build/avra-try check --time packages/std-relation > build/k.out 2> build/k.err
  grep -ah "^time" build/k.out build/k.err | tr ',' '\n' | grep -a "keep\|analyze\|lower" | tr '\n' ' '; echo
done
