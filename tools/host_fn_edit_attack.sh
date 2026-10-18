#!/bin/sh
# A HOST FN'S FILE EDITED AND REBUILT WARM BUILDS WHAT A COLD BUILD DOES. A host
# fn is a root: it lowers even where its file is held, beside the held stub of
# the same symbol, so a derivation owing instantiations met one symbol twice and
# the module emitted the empty stub over the real body — "does not have
# terminator", and the wrecked module's text was written over the store's object. @std/ui's web.av declares host fns
# with bodies and its instance_page program owes instantiations from held homes,
# so each edit shape (a comment, a body line, a local's name) is built warm and
# must pass as the cold build of the same edit does. The file is restored on
# every exit. It CLEARS the store, as the attacks beside it do.
set -u
cd "$(dirname "$0")/.."
W=packages/std-ui/src/web/web.av
T=packages/std-ui/src/tests/instance_page
R=build/host-fn-edit-attack; fails=0
rm -rf "$R" && mkdir -p $R
cp $W $R/web.orig
trap 'cp $R/web.orig $W' EXIT INT TERM
unwatched() { grep -v -e '^watch:' -e 'job control turned off'; }
proved() { # proved <label>: the program test, through the store
    ./avra test $T > $R/out 2> $R/err; st=$?
    [ $st -eq 0 ] || { fails=$((fails+1)); echo "FAIL  $1: status $st: $(unwatched < $R/err | grep -v '^$' | head -2 | tr '\n' ' ')"; return 1; }
}
edit() { # edit <label> <sed script>: from the original, one edit shape
    cp $R/web.orig $W
    case "$2" in
        comment) echo "// edited" >> $W ;;
        *) sed "$2" $R/web.orig > $W ;;
    esac
    cmp -s $R/web.orig $W && { fails=$((fails+1)); echo "FAIL  $1: the edit changed nothing"; return 1; }
    return 0
}
rm -rf .avra-cache
proved "the cold build" || { echo "host-fn-edit-attack: the cold build failed"; exit 1; }
steps=0
for shape in "a comment line|comment" \
    "a body line|s/^    held.app.warn()$/    held.app.warn()\\
    swept(held)/" \
    "a local renamed|s/\\bheld\\b/mounted_page/g"; do
    label=${shape%%|*}; script=${shape#*|}
    edit "$label" "$script" || continue
    steps=$((steps + 1))
    proved "$label, built warm"
    grep -l '^; ModuleID' .avra-cache/obj/*.o > /dev/null 2>&1 && { fails=$((fails+1)); echo "FAIL  $label: a wrecked module's text stands in the store as an object"; }
done
echo "host-fn-edit-attack: $steps edit shapes of @std/ui's host-fn file built warm, $fails failed"
[ "$fails" -eq 0 ]
