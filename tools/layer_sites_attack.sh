#!/bin/sh
# A TASK'S SITE IS NAMED WHATEVER LAYER HOLDS ITS BODY. A layered program's objects hand their
# image's site table to the scheduler as the image loads; the overlay is linked without a compiler
# driver's crt files, so the constructor must be one the loader runs. Held where every object lands
# in the overlay: a standing world whose kept keys name nothing this build makes, as after the
# compiler changed. Each build's trace names the spawn's site by its file and line.
set -u
. "$(dirname "$0")/lib/attack.sh"
who=layer-sites-attack
. tools/lib/steps.sh
R=build/layer-sites-attack
find "$R" -delete 2>/dev/null
mkdir -p $R/app/src
own_store $R
printf '[package]\nname = "zz-sites"\nversion = "0.0.1"\n' > $R/app/avra.toml
cp tools/flow_trace/traced_fd.av $R/app/src/main.av
layers=$R/app/.avra-cache/tapes-build/layers
# sited <label>: built, run traced, and its spawn named at the line that wrote it
sited() {
    ./avra build $R/app > $R/out 2>&1 || { fail "$1: the build failed: $(head -2 $R/out | tr '\n' ' ')"; return; }
    echo x | AVRA_FLOW_TRACE=$R/t.trace $R/app/src/main > /dev/null 2>&1
    got=$(build/avra trace $R/t.trace 2>&1 | grep -m1 'spawned by')
    case "$got" in
        *"at zz-sites/main.av:"*) say "$1: $(echo "$got" | sed 's/.* at //')" ;;
        *) fail "$1: the spawn is named '$got'" ;;
    esac
}
sited "cold: every object in the world"
for w in $layers/world-*; do echo stale > $w/keys.txt; done
sed -i.was 's/slept(100)/slept(101)/' $R/app/src/main.av
sited "a standing world that names nothing made: every object in the overlay"
sed -i.was 's/slept(101)/slept(102)/' $R/app/src/main.av
sited "edited again"
verdict
