#!/bin/sh
# Timing-only: the scans' input pushes removed (answers are wrong; the cost of the push is what this measures).
f=packages/std-avrac/src/compiler/voices.av
cp $f $f.keep
sed -i '' 's/^    set_scanned_text(ws.decls.rows_db.get(), key, ws.listed_text(path))$/    key/' $f 2>/dev/null || sed -i 's/^    set_scanned_text(ws.decls.rows_db.get(), key, ws.listed_text(path))$/    key/' $f
grep -c "set_scanned_text(ws" $f
