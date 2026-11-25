#!/usr/bin/env python3
# Warm re-run counts per edit kind: `tapes --findings packages/cli`, cold once, then each edit
# applied to the original text, run warm, its `worked:` line kept, the text restored and warmed back.
#   python3 count.py <compiler> <tag> [root]
import os, subprocess, sys, re
C = sys.argv[1]; tag = sys.argv[2]; root = sys.argv[3] if len(sys.argv) > 3 else '/work/avra'
F = 'packages/cli/src/commands/cache.av'
edits = [
    ('noop', None, None),
    ('inline', '//! in, its own verbs. The store is a directory of immutable packs, each the',
     '//! in, its own verbs. The store is a folder of immutable packs, each the'),
    ('literal', '    println("avra cache clean: ${compacted_said(dir)}")',
     '    println("avra cache cleaned: ${compacted_said(dir)}")'),
    ('comment', '    let shared? = machine_layer() else { return 0 }',
     '    // a note\n    let shared? = machine_layer() else { return 0 }'),
    ('body', '    let shared? = machine_layer() else { return 0 }',
     '    let shared? = machine_layer() else { return 0 }\n    let _ = cache_dir().length'),
    ('signature', 'fn octets_of(packs: List<PackListed>) -> int {',
     'fn octets_of(packs: List<PackListed>, most: int = 0) -> int {'),
    ('added', 'fn cache_dir() -> string {',
     'fn cache_unused() -> int { 3 }\n\nfn cache_dir() -> string {'),
    ('renamed', 'fn octets_of(packs: List<PackListed>) -> int { packs.fold(0, (sum, p) -> sum + p.octets) }',
     'fn octets_of(packs: List<PackListed>) -> int { packs.fold(0, (sum, p) -> sum + p.octets) }\n\nfn spare_one() -> int { 1 }'),
]
env = dict(os.environ)
for k in ['AVRA_PROGRAM', 'AVRA_QTRACE', 'AVRA_PROGRAM_MODE', 'AVRA_WORK_AHEAD_OFF']: env.pop(k, None)
env.update(AVRA_PROGRAM_NET='0')

def run():
    r = subprocess.run([C, 'tapes', '--findings', 'packages/cli'], cwd=root, env=env, capture_output=True, text=True)
    w = [l for l in r.stderr.splitlines() if l.startswith('worked:')]
    return w[-1] if w else 'worked: ? (rc %d) %s' % (r.returncode, r.stderr[-300:])

subprocess.run('find packages/cli/.avra-cache .avra-cache -delete', shell=True, cwd=root, stderr=subprocess.DEVNULL)
run(); run()
p = os.path.join(root, F); orig = open(p).read()
out = open('/work/meas/ip/count-%s.txt' % tag, 'w')
for name, a, b in edits:
    if a:
        assert orig.count(a) == 1, name
        open(p, 'w').write(orig.replace(a, b, 1))
    try:
        w = run()
    finally:
        open(p, 'w').write(orig)
    out.write('== %s\n%s\n' % (name, w)); out.flush()
    m = re.match(r'worked: (\d+)', w)
    print(tag, name, m.group(1) if m else w[:200], flush=True)
    if a: run()
