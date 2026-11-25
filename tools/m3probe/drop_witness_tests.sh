#!/bin/sh
set -eu
cd "$(dirname "$0")/../../packages/std-avrac/src/compiler/tests"
git rm -q witness_test.av witness_fixtures.av witness_adversarial_test.av witness_reads_test.av \
    witness_refusal_test.av witness_stability_test.av witness_stale_manifest_test.av \
    witness_text_test.av witness_written_test.av explain_real_test.av
