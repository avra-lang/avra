#!/bin/sh
# avra-8sb5.57.195/198: the gate and the targeted suites, one run.
cd "$(dirname "$0")/../.." || exit 1
sh tools/db_measure/assign_roots_gate2.sh
echo "==================== targeted suites ===================="
sh tools/db_measure/assign_roots_tests.sh
