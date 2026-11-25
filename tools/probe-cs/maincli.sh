cp /home/sprite/avra-compilers/$1/avra /tmp/mt/build/avra
cd /tmp/mt && rm -rf .avra-cache && build/avra test packages/cli 2>&1 | grep -E "✗|tests passed"
