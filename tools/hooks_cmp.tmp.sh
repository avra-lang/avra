b=$(build/avra build tools | tail -n 1)
$b hooks_released; echo "rc=$?"
cp packages/std-avrac/src/features/decls.av /tmp/decls.orig
python3 - <<'P'
p="packages/std-avrac/src/features/decls.av"
t=open(p).read()
open(p,"w").write(t.replace("self.ensure_named.set(","self.__x.set("))
P
$b hooks_released > /tmp/hooks_mut.out; echo "rc=$?" >> /tmp/hooks_mut.out
cp /tmp/decls.orig packages/std-avrac/src/features/decls.av
cat /tmp/hooks_mut.out
make tools-suite 2>&1 | tail -3
