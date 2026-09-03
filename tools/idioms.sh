#!/bin/sh
# The idiom bar lives in idioms.py — see its header for the four laws.
# -B: no bytecode cache; the tool leaves nothing behind in tools/.
exec python3 -B "$(dirname "$0")/idioms.py" "$@"
