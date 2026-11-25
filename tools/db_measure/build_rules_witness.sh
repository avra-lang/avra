# Cold build of packages/cli, then a check over its records: the check's held count, and the build's time line.
cd "$(dirname "$0")/../.."
S=build/br
mkdir -p $S
i=0
find . -name .avra-cache -type d -prune | while read -r d; do
  i=$((i + 1)); mv "$d" "build/aside.br.$$.$i"
done
s=$(date +%s); ./avra build --time packages/cli > $S/build.out 2> $S/build.err; echo "build exit $? wall $(( $(date +%s) - s )) s"
grep -h "^time:" $S/build.out $S/build.err | tail -n 1 | cut -c1-400
s=$(date +%s); ./avra check --time packages/cli > $S/check.out 2> $S/check.err; echo "check exit $? wall $(( $(date +%s) - s )) s"
grep -h "^time:" $S/check.out $S/check.err | tail -n 1 | cut -c1-400
echo "check printed warnings: $(grep -c '^warning' $S/check.out $S/check.err | paste -sd' ' -)"
