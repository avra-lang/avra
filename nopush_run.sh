#!/bin/sh
f=packages/std-avrac/src/compiler/voices.av
cp $f voices.keep
awk '{ if ($0 == "    set_scanned_text(ws.decls.rows_db.get(), key, ws.listed_text(path))") print "    key"; else print }' voices.keep > $f
echo "set calls left: $(grep -c 'set_scanned_text(ws' $f)"
sh exp.sh NP1
cp voices.keep $f
