H=$1
build/avra fmt --check packages/std-avrac/src/compiler/memory/memory.av packages/std-avrac/src/compiler/tests/lower_test.av packages/std-avrac/src/features/cells/tests/set_at/set_at.av; echo "fmt $?"
cp packages/std-avrac/src/compiler/memory/memory.av /tmp/m.av; build/avra fmt --write /tmp/m.av >/dev/null 2>&1; diff packages/std-avrac/src/compiler/memory/memory.av /tmp/m.av
sh tools/probe-cs/census.sh $H
sh tools/probe-cs/guard.sh 2>&1 | head -12
sh tools/probe-cs/cg.sh $H std-relation
