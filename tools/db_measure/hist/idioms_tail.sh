#!/bin/sh
grep -a "new\|baseline\|^warning\[" "$HOME/rm.idioms.log" | sort | uniq -c | sort -rn | head -n 12 | cut -c1-200
tail -n 30 "$HOME/rm.idioms.log" | cut -c1-220
