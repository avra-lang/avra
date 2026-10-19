# One constant appended to a leaf file of the cli: the smallest edit a warm check re-reads.
cd "$(dirname "$0")/../.."
printf '\nconst census_edit: int = 7\n' >> packages/cli/src/commands/shared.av
