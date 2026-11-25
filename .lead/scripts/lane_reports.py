#!/usr/bin/env python3
"""Lane reports the lead's inbox may have dropped: every SendMessage a subagent
addressed to team-lead since HH:MM (UTC), read from the session's transcripts.
    python3 .lead/scripts/lane_reports.py 15:30 [chars]
"""
import glob, json, os, sys
since = sys.argv[1] if len(sys.argv) > 1 else "00:00"
cap = int(sys.argv[2]) if len(sys.argv) > 2 else 1200
root = os.path.expanduser("~/.claude/projects/-Users-tristan-projects-tristanMatthias-avra")
for f in sorted(glob.glob(root + "/*/subagents/agent-a*.jsonl"), key=os.path.getmtime):
    if os.path.getmtime(f) < __import__("time").time() - 86400:
        continue
    name = os.path.basename(f)[7:].rsplit("-", 1)[0]
    for ln in open(f, errors="replace"):
        try:
            o = json.loads(ln)
        except Exception:
            continue
        m = o.get("message") or {}
        c = m.get("content")
        ts = o.get("timestamp", "")[11:16]
        if ts < since or m.get("role") != "assistant" or not isinstance(c, list):
            continue
        for x in c:
            if x.get("type") == "tool_use" and x.get("name") == "SendMessage":
                print(f"\n=== {name} [{ts}] -> {x['input'].get('to')}\n{str(x['input'].get('message',''))[:cap]}")
