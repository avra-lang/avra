#!/bin/sh
# THE COMPILER-RELEASE TRANSPORT, proved against a local fake of the GitHub
# releases API: fetch before publish is absent, publish lands the bytes once,
# a second publish of the same key never overwrites, and two keys stay apart.
set -eu
exec python3 "$(dirname "$0")/compiler_release.py" --self-test
