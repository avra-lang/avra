#!/bin/sh
# The timeline reader, held to its own cases.
exec python3 "$(dirname "$0")/flow_trace.py" --self-test
