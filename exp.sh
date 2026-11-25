#!/bin/sh
# One round on the tree's compiler: cold, unchanged, one-edit checks of the cli.
# Each run keeps its own stderr under the label, so rounds never overwrite each other.
label=$1
F=packages/cli/src/commands/check.av
rm -rf .avra-cache
s=$(date +%s); build/avra check packages/cli --time > x_$label.cold.out 2> x_$label.cold.err; echo "$label cold rc=$? wall=$(( $(date +%s) - s ))s"; grep "time:" x_$label.cold.err | tail -1
s=$(date +%s); build/avra check packages/cli --time > x_$label.same.out 2> x_$label.same.err; echo "$label unchanged rc=$? wall=$(( $(date +%s) - s ))s"; grep "time:" x_$label.same.err | tail -1
cp $F $F.bak; printf '\n// one-edit measurement\n' >> $F
s=$(date +%s); build/avra check packages/cli --time > x_$label.edit.out 2> x_$label.edit.err; echo "$label one-edit rc=$? wall=$(( $(date +%s) - s ))s"; grep "time:" x_$label.edit.err | tail -1
mv $F.bak $F
