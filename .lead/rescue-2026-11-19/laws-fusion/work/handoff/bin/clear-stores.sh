#!/bin/sh
# Clear every store a compiler writes.
cd /work/avra
for d in packages/*/.avra-cache .avra-cache /root/.avra/cache; do [ -d "$d" ] && find "$d" -delete; done
true
