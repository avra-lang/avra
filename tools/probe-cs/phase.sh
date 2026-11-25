cp /home/sprite/avra-compilers/$1/avra build/avra.main
for who in avra.main avra avra.main avra; do
  rm -rf /tmp/mt/.avra-cache /tmp/mt/packages/cli/.avra-cache .avra-cache
  echo "== $who"; build/$who check --time /tmp/mt/packages/cli 2>&1 | grep -iE "^ *(time|[a-z_+ ]+:? +[0-9.]+ ?m?s)" | head -30
done
