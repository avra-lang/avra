cd /work/wt-t
export AVRA_PROGRAM_NET=0
C=build/avra-trace
F=packages/cli/src/commands/cache.av
find packages/cli/.avra-cache .avra-cache -delete 2>/dev/null
$C tapes --findings packages/cli >/dev/null 2>&1; $C tapes --findings packages/cli >/dev/null 2>&1
cp $F /tmp/claude-0/-home-user/ad3c4af4-7a80-56a8-91c1-4dbb22fe5b6b/scratchpad/cache.av.orig
python3 - <<'PY'
p='packages/cli/src/commands/cache.av'
s=open(p).read()
a=open('/work/meas/ip/edit_a.txt').read()
s=s.replace(a, open('/work/meas/ip/edit_b.txt').read(),1)
open(p,'w').write(s)
PY
AVRA_STOP_ASKER=law_findings AVRA_STOP_READ="file_declares(" AVRA_TRAP_TRACE=1 $C tapes --findings packages/cli > /work/meas/ip/stop-edit.txt 2>&1
cp /tmp/claude-0/-home-user/ad3c4af4-7a80-56a8-91c1-4dbb22fe5b6b/scratchpad/cache.av.orig $F
git diff --stat -- $F
