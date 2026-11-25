#!/bin/sh
grep -a -A14 "✗" "$HOME/rl.log" | cut -c1-1500
