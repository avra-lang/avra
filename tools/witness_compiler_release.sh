#!/bin/sh
# THE RELEASE READS, proved against local files (`./wisp release …`, the shim's own shell): a key with no
# release is absent and leaves no file, a key's asset is fetched whole and executable, a release without
# the asset says so, the newest release wins and a tie keeps the API's order, and `install`, `probe` and
# `route` decide as the published asset says. The publish half is `wisp release publish`'s spec tests.
. "$(dirname "$0")/lib/scratch.sh"
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
scratch_dir d
fails=0
check() { if [ "$2" = "$3" ]; then echo "compiler_release: ok $1"; else echo "compiler_release: FAIL $1 — got [$2], want [$3]"; fails=$((fails + 1)); fi; }
w() { (cd "$root" && env -u GH_TOKEN -u GITHUB_TOKEN AVRA_RELEASE_API="file://$d/api" "$@") }

mkdir -p "$d/api/releases/tags"
printf 'compiler-A' > "$d/a.bin"
printf 'compiler-B' > "$d/b.bin"
printf '{"tag_name":"avrac-aa","assets":[{"name":"avra","url":"file://%s/a.bin"}]}' "$d" > "$d/api/releases/tags/avrac-aa"
printf '{"tag_name":"avrac-cc","assets":[]}' > "$d/api/releases/tags/avrac-cc"
printf '[{"tag_name":"avrac-aa","created_at":"2026-01-01T00:00:00Z","assets":[{"name":"avra","url":"file://%s/a.bin"}]},
{"tag_name":"avrac-bb","created_at":"2026-01-02T00:00:00Z","assets":[{"name":"avra","url":"file://%s/b.bin"}]},
{"tag_name":"avrac-tie","created_at":"2026-01-02T00:00:00Z","assets":[{"name":"avra","url":"file://%s/a.bin"}]},
{"tag_name":"avrac-dd","created_at":"2026-01-03T00:00:00Z","draft":true,"assets":[{"name":"avra","url":"file://%s/a.bin"}]}]' \
    "$d" "$d" "$d" "$d" > "$d/api/releases?per_page=100"

out=$(w sh wisp release fetch zz "$d/got" 2>&1) && rc=0 || rc=$?
check "a key with no release is absent" "$rc $out" "1 compiler-release: avrac-zz: no release"
check "no file is left behind" "$(ls "$d" | grep -c '^got' || :)" 0
out=$(w sh wisp release fetch avrac-aa "$d/got" 2>&1) && rc=0 || rc=$?
check "a tag where the key belongs is refused, saying so" "$rc $out" '2 wisp release: `avrac-aa` is a tag — pass the key; the tag is formed from it and the asset'
w sh wisp release fetch aa "$d/got" >/dev/null
check "fetch returns the bytes" "$(cat "$d/got")" compiler-A
check "the file is executable" "$([ -x "$d/got" ] && echo yes)" yes
out=$(w sh wisp release fetch cc "$d/none" 2>&1) && rc=0 || rc=$?
check "a release without the asset says so" "$rc $out" "1 compiler-release: avrac-cc: release has no avra asset"
out=$(w sh wisp release fetch aa "$d/none" --asset wisp 2>&1) && rc=0 || rc=$?
check "an asset is asked by its name" "$rc" 1
w sh wisp release latest "$d/latest" >/dev/null
check "latest is the newest undrafted release, the API's first of a tie" "$(cat "$d/latest")" compiler-B

printf '#!/bin/sh\necho stub-avra\n' > "$d/published"
chmod 755 "$d/published"
: > "$d/pub-hk"
: > "$d/pub-mk"
out=$(w env FETCH_UNAME=Darwin sh wisp release install --key abc123 --into "$d/mac" 2>&1) && rc=0 || rc=$?
check "macOS refuses" "$rc $(printf '%s' "$out" | grep -c 'is a linux binary')" "1 1"
out=$(w env FETCH_UNAME=Linux FETCH_URL="file://$d/absent" sh wisp release install --key abc123 --into "$d/none" 2>&1) && rc=0 || rc=$?
check "no published compiler refuses" "$rc $(printf '%s' "$out" | grep -c 'no published compiler for a key given on the command line (key abc123)')" "1 1"
out=$(w env FETCH_UNAME=Linux sh wisp release install no-such-commit-here --into "$d/sha" 2>&1) && rc=0 || rc=$?
check "an unknown commit refuses" "$rc $(printf '%s' "$out" | grep -c 'no commit named no-such-commit-here')" "1 1"
mkdir -p "$d/ok"
echo standing > "$d/ok/avra"
out=$(w env FETCH_UNAME=Linux FETCH_URL="file://$d/published" sh wisp release install --key abc123 --into "$d/ok" 2>&1) && rc=0 || rc=$?
check "install names the key" "$rc $(printf '%s' "$out" | grep -c 'key abc123')" "0 1"
check "the standing compiler moves to avra.pre" "$(cat "$d/ok/avra.pre")" standing
check "the fetched compiler is installed as avra" "$("$d/ok/avra")" stub-avra
out=$(w env FETCH_UNAME=Linux FETCH_URL=http://127.0.0.1:9/none FETCH_TRIES=2 sh wisp release install --key abc123 --into "$d/retry" 2>&1) && rc=0 || rc=$?
check "an unreachable asset is asked again and the answer named" "$rc $(printf '%s' "$out" | grep -c 'after 2 attempt(s)')" "1 1"
fu="file://$d/pub-KEY"
w env FETCH_URL="$fu" sh wisp release probe hk && rc=0 || rc=$?
check "a probe finds a published key" "$rc" 0
w env FETCH_URL="$fu" sh wisp release probe gone && rc=0 || rc=$?
check "a probe misses an unpublished key" "$rc" 1
check "a published key takes the published path" "$(w env FETCH_URL="$fu" sh wisp release route 0 hk mk)" published:hk
check "a dirty tree takes the merge-base path" "$(w env FETCH_URL="$fu" sh wisp release route 1 hk mk)" mergebase:mk
check "an unpublished head takes the merge-base path" "$(w env FETCH_URL="$fu" sh wisp release route 0 hkabs mk)" mergebase:mk
check "nothing published builds" "$(w env FETCH_URL="$fu" sh wisp release route 0 hkabs mkabs)" build

[ "$fails" = 0 ] || { echo "compiler_release: WITNESS FAILED — $fails case(s)" >&2; exit 1; }
echo "compiler_release: witness clean"
