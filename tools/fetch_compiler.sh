#!/bin/sh
# THE PUBLISHED COMPILER, INSTALLED: the compiler main published for a commit,
# from the same release asset the checks restore, in place of the first
# generation a lane would build (the standing compiler building new source).
#
#   sh tools/fetch_compiler.sh [<sha>]        # default origin/main
#   sh tools/fetch_compiler.sh --key <key>    # a key read elsewhere (a tree with no .git)
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
    mkdir -p "$scratch/ok"
    printf 'standing\n' > "$scratch/ok/avra"
    out=$(cd "$here" && FETCH_URL="file://$scratch/published" FETCH_BUILD="$scratch/ok" sh tools/fetch_compiler.sh HEAD 2>&1) || true
    expect "install names the key and the bytes" "fetch_compiler: installed $scratch/ok/avra" "$out"
    [ "$(cat "$scratch/ok/avra.pre" 2>/dev/null)" = standing ] || { fails=$((fails + 1)); echo "FAIL  standing compiler moves to avra.pre"; }
    [ "$(cat "$scratch/ok/avra" 2>/dev/null)" = "$(printf '#!/bin/sh\necho stub-avra')" ] || { fails=$((fails + 1)); echo "FAIL  fetched compiler is installed as avra"; }
    out=$(cd "$here" && FETCH_URL="file://$scratch/published" FETCH_BUILD="$scratch/keyed" sh tools/fetch_compiler.sh --key abc123 2>&1) || true
    expect "a given key installs with no git" "key abc123" "$out"
    if [ "$fails" = 0 ]; then echo "fetch_compiler: self-test clean — 7 case(s)"; exit 0; fi
    echo "fetch_compiler: self-test FAILED — $fails case(s)"
    exit 1
fi

build=${FETCH_BUILD:-build}

refuse() {
    echo "fetch_compiler: REFUSED — $*" >&2
    exit 1
}

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

repo=${GITHUB_REPOSITORY:-avra-lang/avra}
url=${FETCH_URL:-https://github.com/$repo/releases/download/avrac-$key/avra}
fetched="$build/avra.fetch"
curl -fsSL --retry 2 -o "$fetched" "$url" 2>/dev/null ||
    refuse "no published compiler for $sha (key $key): $url did not answer"
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
