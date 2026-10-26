#!/bin/sh
# THE PUBLISHED COMPILER, INSTALLED: the compiler main published for a commit,
# from the same release asset the checks restore, in place of the first
# generation a lane would build (the standing compiler building new source).
#
#   sh tools/fetch_compiler.sh [<sha>]        # default origin/main
#   sh tools/fetch_compiler.sh --key <key>    # a key read elsewhere (a tree with no .git)
#   sh tools/fetch_compiler.sh --key-of <rev> # the key a commit's compiler source has
#   sh tools/fetch_compiler.sh --probe <key>  # 0 when a compiler is published for the key
#   sh tools/fetch_compiler.sh --route <dirty> <head-key> <base-key>
#                                             # how a run's compiler is got: published:<key>,
#                                             # mergebase:<key> (fetch it, then one generation),
#                                             # or build
#   sh tools/fetch_compiler.sh --self-test
#
# The key is the compiler's source digest at the commit (tools/compiler_paths.sh
# --key, over a temporary index read from the commit). The asset is downloaded
# anonymously from the repository's public release, so no token is needed. The
# standing build/avra moves to build/avra.pre, and the fetched one is installed
# as build/avra. A refusal names its one reason and leaves build/avra where it was.
set -eu

if [ "${1:-}" = --self-test ]; then
    # Each fixture runs this script in a scratch build directory. FETCH_URL points
    # the download at a local file, so the fixtures need no network.
    here=$(cd "$(dirname "$0")/.." && pwd)
    scratch="$here/build/fetch-selftest-$$"
    mkdir -p "$scratch"
    printf '#!/bin/sh\necho stub-avra\n' > "$scratch/published"
    chmod +x "$scratch/published"
    printf 'x' > "$scratch/pub-hk"
    printf 'x' > "$scratch/pub-mk"
    export FETCH_UNAME=Linux
    fails=0
    expect() { # expect <label> <wanted text> <output>
        printf '%s\n' "$3" | grep -qF -- "$2" || { fails=$((fails + 1)); echo "FAIL  $1: wanted '$2', got: $(printf '%s' "$3" | tr '\n' ' ')"; }
    }
    out=$(cd "$here" && FETCH_UNAME=Darwin FETCH_BUILD="$scratch/mac" sh tools/fetch_compiler.sh 2>&1) || true
    expect "macOS refuses" "the published compiler is a linux binary" "$out"
    out=$(cd "$here" && FETCH_BUILD="$scratch/sha" sh tools/fetch_compiler.sh no-such-commit-here 2>&1) || true
    expect "unknown commit refuses" "no commit named no-such-commit-here" "$out"
    out=$(cd "$here" && FETCH_URL="file://$scratch/absent" FETCH_BUILD="$scratch/none" sh tools/fetch_compiler.sh --key abc123 2>&1) || true
    expect "no published compiler refuses" "no published compiler for a key given on the command line (key abc123)" "$out"
    out=$(cd "$here" && FETCH_URL="http://127.0.0.1:9/none" FETCH_TRIES=2 FETCH_BUILD="$scratch/retry" sh tools/fetch_compiler.sh --key abc123 2>&1) || true
    expect "an unreachable asset is asked again and the answer named" "after 2 attempt(s)" "$out"
    mkdir -p "$scratch/ok"
    printf 'standing\n' > "$scratch/ok/avra"
    out=$(cd "$here" && FETCH_URL="file://$scratch/published" FETCH_BUILD="$scratch/ok" sh tools/fetch_compiler.sh HEAD 2>&1) || true
    expect "install names the key and the bytes" "fetch_compiler: installed $scratch/ok/avra" "$out"
    [ "$(cat "$scratch/ok/avra.pre" 2>/dev/null)" = standing ] || { fails=$((fails + 1)); echo "FAIL  standing compiler moves to avra.pre"; }
    [ "$(cat "$scratch/ok/avra" 2>/dev/null)" = "$(printf '#!/bin/sh\necho stub-avra')" ] || { fails=$((fails + 1)); echo "FAIL  fetched compiler is installed as avra"; }
    out=$(cd "$here" && FETCH_URL="file://$scratch/published" FETCH_BUILD="$scratch/keyed" sh tools/fetch_compiler.sh --key abc123 2>&1) || true
    expect "a given key installs with no git" "key abc123" "$out"
    route_of() { (cd "$here" && FETCH_URL="file://$scratch/pub-KEY" sh tools/fetch_compiler.sh --route "$@" 2>&1); }
    expect "published key takes the published path" "published:hk" "$(route_of 0 hk mk)"
    expect "a dirty tree takes the merge-base path" "mergebase:mk" "$(route_of 1 hk mk)"
    expect "an unpublished head takes the merge-base path" "mergebase:mk" "$(route_of 0 hkabs mk)"
    expect "nothing published builds" "build" "$(route_of 0 hkabs mkabs)"
    expect "a probe finds a published key" "found" "$(cd "$here" && FETCH_URL="file://$scratch/pub-KEY" sh tools/fetch_compiler.sh --probe hk && echo found)"
    if [ "$fails" = 0 ]; then echo "fetch_compiler: self-test clean — 13 case(s)"; exit 0; fi
    echo "fetch_compiler: self-test FAILED — $fails case(s)"
    exit 1
fi

build=${FETCH_BUILD:-build}

# The asset for a key: the public release, or FETCH_URL with KEY standing for it.
url_for() {
    printf '%s' "${FETCH_URL:-https://github.com/${GITHUB_REPOSITORY:-avra-lang/avra}/releases/download/avrac-KEY/avra}" | sed "s|KEY|$1|"
}

# A file:// asset is a local copy (the fixtures); any other URL is downloaded or probed.
# fetch_asset <url> <dest>: the asset, asked up to FETCH_TRIES (5) times with a doubling pause (2 s first),
# each answer's HTTP status kept in $fetch_why; a `file://` url is a copy.
fetch_asset() {
    case "$1" in
        file://*) cp "${1#file://}" "$2" 2>/dev/null && return 0; fetch_why="$1 is not a file"; return 1 ;;
    esac
    tries=0
    pause=2
    while :; do
        tries=$((tries + 1))
        code=$(curl -sSL -o "$2" -w '%{http_code}' --max-time "${FETCH_MAX_S:-600}" "$1" 2>"$build/fetch.err") && [ "$code" = 200 ] && return 0
        fetch_why="HTTP ${code:-none} after $tries attempt(s): $(head -c 160 "$build/fetch.err" 2>/dev/null | tr '\n' ' ')"
        [ "$tries" -lt "${FETCH_TRIES:-5}" ] || return 1
        sleep "$pause"
        pause=$((pause * 2))
    done
}
asset_there() {
    case "$1" in
        file://*) [ -f "${1#file://}" ] ;;
        *) curl -fsI --retry 2 "$1" >/dev/null 2>&1 ;;
    esac
}

# The key a commit's compiler source has: its files as the index of that commit holds them.
key_of() {
    index="$build/fetch.index"
    mkdir -p "$build"
    GIT_INDEX_FILE="$index" git read-tree "$1" || return 1
    GIT_INDEX_FILE="$index" sh tools/compiler_paths.sh --key
}

refuse() {
    echo "fetch_compiler: REFUSED — $*" >&2
    exit 1
}

if [ "${1:-}" = --probe ]; then
    asset_there "$(url_for "${2:?fetch_compiler: --probe takes the key}")"
    exit $?
fi
if [ "${1:-}" = --key-of ]; then
    key_of "$(git rev-parse --verify --quiet "${2:?fetch_compiler: --key-of takes a commit}^{commit}")"
    exit $?
fi
if [ "${1:-}" = --route ]; then
    # A dirty compiler source has no published key: the merge-base's is the one to fetch.
    dirty=${2:?}; hk=${3:-}; mk=${4:-}
    if [ "$dirty" = 0 ] && [ -n "$hk" ] && asset_there "$(url_for "$hk")"; then
        echo "published:$hk"
    elif [ -n "$mk" ] && asset_there "$(url_for "$mk")"; then
        echo "mergebase:$mk"
    else
        echo build
    fi
    exit 0
fi

platform=${FETCH_UNAME:-$(uname -s)}
[ "$platform" = Linux ] || refuse "the published compiler is a linux binary; this machine is $platform (run it on a Sprite)"

if [ "${1:-}" = --key ]; then
    key=${2:?fetch_compiler: --key takes the key}
    sha="a key given on the command line"
else
    rev=${1:-origin/main}
    git rev-parse --git-dir >/dev/null 2>&1 ||
        refuse "no git repository here; read the key where git is (sh tools/compiler_paths.sh --key at the commit) and pass it with --key"
    sha=$(git rev-parse --verify --quiet "$rev^{commit}") || refuse "no commit named $rev"
    mkdir -p "$build"
    index="$build/fetch.index"
    GIT_INDEX_FILE="$index" git read-tree "$sha" || refuse "cannot read the tree of $sha"
    key=$(GIT_INDEX_FILE="$index" sh tools/compiler_paths.sh --key) ||
        refuse "the compiler source of $sha is not listed"
fi

url=$(url_for "$key")
fetched="$build/avra.fetch"
mkdir -p "$build"
fetch_asset "$url" "$fetched" || {
    # the anonymous door failed: the releases API, with the run's token when it has one, is the second
    if [ -z "${FETCH_URL:-}" ] && [ -f tools/compiler_release.py ] && python3 tools/compiler_release.py fetch "avrac-$key" "$fetched" >/dev/null 2>&1; then
        echo "fetch_compiler: the anonymous asset failed ($fetch_why); the releases API answered" >&2
    else
        refuse "no published compiler for $sha (key $key): $url did not answer — last answer $fetch_why"
    fi
}
chmod +x "$fetched"
"$fetched" --version >/dev/null 2>&1 || refuse "the compiler published for $sha does not run here"

if [ -e "$build/avra" ]; then
    [ ! -e "$build/avra.pre" ] || mv "$build/avra.pre" "$build/avra.pre.$(date +%s)"
    mv "$build/avra" "$build/avra.pre"
fi
mv "$fetched" "$build/avra"

bytes=$(wc -c < "$build/avra" | tr -d ' ')
digest=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$build/avra")
echo "fetch_compiler: installed $build/avra — key $key from $sha, $bytes bytes, sha256 $digest"
