#!/bin/sh
# The idiom bar lives in idioms.py — see its header for the four laws.
exec python3 "$(dirname "$0")/idioms.py" "$@"
