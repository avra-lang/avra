#!/bin/sh
# One literal edit, then a check under AVRA_QTRACE=1. Usage: probe.sh <std|cli> <tag>
set -u
A=build/avra
R=build/parse
mkdir -p $R
case "$1" in
  std) F=packages/std-avrac/src/compiler/store/pack.av; OLD='clean-sealed\t'; NEW="clean-sealed-$2\\\\t" ;;
  cli) F=packages/cli/src/commands/cache.av; OLD='avra cache clean: bytes'; NEW="avra cache clean: bytes $2" ;;
esac
$A check packages/cli --time --counts > $R/settle-$2.out 2>&1
cp $F $R/orig-$2.av
perl -pi -e "s/\Q$OLD\E/$NEW/" $F
cmp -s $F $R/orig-$2.av && { echo "edit did not change $F"; exit 1; }
AVRA_QTRACE=1 $A check packages/cli --time --counts > $R/edit-$2.out 2>&1
echo "exit=$?"
cp $R/orig-$2.av $F
grep -c 'Q.parse' $R/edit-$2.out
