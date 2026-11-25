#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
git rm -q packages/std-avrac/src/compiler/tests/witness_fixtures.av packages/std-avrac/src/compiler/tests/witness_test.av
