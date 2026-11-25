import subprocess, sys, os, re, time
C=sys.argv[1]; tag=sys.argv[2]; reps=int(sys.argv[3]) if len(sys.argv)>3 else 1
root='/work/avra'
edits=[('noop',None,None,None),
('inline','packages/cli/src/commands/cache.av','//! in, its own verbs. The store is a directory of immutable packs, each the','//! in, its own verbs. The store is a folder of immutable packs, each the'),
('literal','packages/cli/src/commands/cache.av','    println("avra cache clean: ${compacted_said(dir)}")','    println("avra cache cleaned: ${compacted_said(dir)}")'),
('comment','packages/cli/src/commands/cache.av','    let shared? = machine_layer() else { return 0 }','    // a note\n    let shared? = machine_layer() else { return 0 }'),
('body','packages/cli/src/commands/cache.av','    let shared? = machine_layer() else { return 0 }','    let shared? = machine_layer() else { return 0 }\n    let _ = cache_dir().length'),
('signature','packages/cli/src/commands/idiom_baseline.av','    fn news(findings: List<Finding>) -> List<Finding> {','    fn news(findings: List<Finding>, most: int = 0) -> List<Finding> {')]
env=dict(os.environ)
for k in ['AVRA_PROGRAM','AVRA_QTRACE','AVRA_PROGRAM_MODE','AVRA_WORK_AHEAD_OFF']: env.pop(k,None)
env.update(AVRA_PROGRAM_NET='0')
def build(extra={}):
    e=dict(env); e.update(extra)
    t=time.time(); r=subprocess.run(['/usr/bin/time','-f','TIME %e %U %S %M',C,'build','packages/cli'],cwd=root,env=e,capture_output=True,text=True)
    if r.returncode: print('BUILD FAILED', r.stderr[-800:]); sys.exit(1)
    while subprocess.run(['pgrep','-f',C+' build'],capture_output=True).returncode==0: time.sleep(0.2)
    return r.stderr
subprocess.run('find packages/cli/.avra-cache .avra-cache -delete',shell=True,cwd=root,stderr=subprocess.DEVNULL)
build(); build()
out=open('/work/meas/wc/warm4-%s.txt'%tag,'w')
for rep in range(reps):
  for name,path,a,b in edits:
    if path:
        p=os.path.join(root,path); orig=open(p).read(); assert orig.count(a+'\n')==1,(name)
        open(p,'w').write(orig.replace(a+'\n',b+'\n',1))
    try:
        err=build({'AVRA_QUERY_TIMES':'1'})
    finally:
        if path: open(p,'w').write(orig)
    tl=[l for l in err.splitlines() if l.startswith(('TIME','time:','phases:','split:','ahead','cutoff'))]
    out.write('== %s rep%d\n'%(name,rep)+'\n'.join(tl)+'\n')
    tm=[l for l in tl if l.startswith('TIME')][0]
    print(tag,name,rep,tm)
    if path: build()
