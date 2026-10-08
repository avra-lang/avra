"""THE CONTENT STAMPS, ONE PROCESS FOR A MAKE. Make hands every stamp
as three words — the stamp, the sources it hashes, the flags it was
asked to compile under; the stamp's file is the digest of all three, and
it is WRITTEN ONLY WHEN IT DIFFERS — an unchanged stamp keeps its mtime,
so nothing downstream of it rebuilds. A stamp that moves takes its object
with it: make compares mtimes to the second, so an object built in the
same second as the stamp that retires it would otherwise read current."""
import hashlib, os, sys

def digest(sources, flags):
    h = hashlib.sha256()
    for path in sources:
        try:
            with open(path, 'rb') as f:
                body = hashlib.sha256(f.read()).hexdigest()
        except OSError:
            body = '-'
        h.update(f'{body}  {path}\n'.encode())
    h.update(f'flags: {flags}\n'.encode())
    return h.hexdigest() + '\n'

def stamped(stamp, sources, flags):
    now = digest(sources, flags)
    try:
        with open(stamp) as f:
            if f.read() == now:
                return
    except OSError:
        pass
    os.makedirs(os.path.dirname(stamp), exist_ok=True)
    with open(stamp + '.tmp', 'w') as f:
        f.write(now)
    os.replace(stamp + '.tmp', stamp)
    try:
        os.remove(stamp[:-len('.sha')] + '.o')
    except OSError:
        pass

words = sys.argv[1:]
for at in range(0, len(words), 3):
    stamp, sources, flags = words[at:at + 3]
    stamped(stamp, sources.split(), flags)
