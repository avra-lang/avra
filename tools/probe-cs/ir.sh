mkdir -p /tmp/cs && cp tools/probe-cs/*.av /tmp/cs/
for f in "$@"; do build/avra ir /tmp/cs/$f; build/avra run /tmp/cs/$f; done
