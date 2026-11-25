# gen1 from the Sprite's known-good compiler, then gen2; report which survives.
mkdir -p build; cp /home/sprite/avra-build/avra-rule-kind/tree/build/avra build/avra
find . -name .avra-cache -type d -prune -exec rm -rf {} + 2>/dev/null
for g in 1 2; do make avra > /tmp/bis$g.log 2>&1 || { echo "gen$g FAILED"; grep -E "status|^error" /tmp/bis$g.log | head -4; exit 1; }; echo "gen$g ok"; done
