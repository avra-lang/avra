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
# --key, over a temporary index read from the commit). The standing build/avra
# moves to build/avra.pre, and the fetched one is installed as build/avra. A
# refusal names its one reason and leaves build/avra where it was.
set -eu

if [ "${1:-}" = --self-test ]; then
    # Each fixture runs this script in a scratch build directory with one of its
    # inputs replaced: the platform, the commit, the release tool.
    here=$(cd "$(dirname "$0")/.." && pwd)
    scratch="$here/build/fetch-selftest-$$"
    mkdir -p "$scratch"
    cat > "$scratch/stub-ok.sh" <<'STUB'
#!/bin/sh
printf '#!/bin/sh\necho stub-avra\n' > "$3"
chmod +x "$3"
STUB
    cat > "$scratch/stub-none.sh" <<'STUB'
#!/bin/sh
echo "compiler-release: $2: no release" >&2
exit 1
STUB
    chmod +x "$scratch/stub-ok.sh" "$scratch/stub-none.sh"
    export FETCH_UNAME=Linux
    fails=0
    expect() { # expect <label> <wanted text> <output>
        printf '%s\n' "$3" | grep -qF -- "$2" || { fails=$((fails + 1)); echo "FAIL  $1: wanted '$2', got: $(printf '%s' "$3" | tr '\n' ' ')"; }
    }
    out=$(cd "$here" && FETCH_UNAME=Darwin FETCH_BUILD="$scratch/mac" sh tools/fetch_compiler.sh 2>&1) || true
    expect "macOS refuses" "the published compiler is a linux binary" "$out"
    out=$(cd "$here" && FETCH_BUILD="$scratch/sha" sh tools/fetch_compiler.sh no-such-commit-here 2>&1) || true
    expect "unknown commit refuses" "no commit named no-such-commit-here" "$out"
    out=$(cd "$here" && FETCH_RELEASE_TOOL="$scratch/stub-none.sh" FETCH_BUILD="$scratch/none" sh tools/fetch_compiler.sh HEAD 2>&1) || true
    expect "no published compiler refuses" "no published compiler for" "$out"
    expect "no published compiler names the tool's reason" "no release" "$out"
    mkdir -p "$scratch/ok"
    printf 'standing\n' > "$scratch/ok/avra"
    out=$(cd "$here" && FETCH_RELEASE_TOOL="$scratch/stub-ok.sh" FETCH_BUILD="$scratch/ok" sh tools/fetch_compiler.sh HEAD 2>&1) || true
    expect "install names the key and the bytes" "fetch_compiler: installed $scratch/ok/avra" "$out"
    out=$(cd "$scratch" && FETCH_RELEASE_TOOL="$scratch/stub-ok.sh" FETCH_BUILD="$scratch/keyed" sh "$here/tools/fetch_compiler.sh" --key abc123 2>&1) || true
    expect "a given key installs with no git" "key abc123" "$out"
    out=$(cd "$here" && GH_TOKEN= GITHUB_TOKEN= FETCH_GH=/nonexistent/gh FETCH_RELEASE_TOOL="$scratch/stub-ok.sh" FETCH_BUILD="$scratch/token" sh tools/fetch_compiler.sh HEAD 2>&1) || true
    expect "no token refuses in one line" "no GitHub token on this machine" "$out"
    [ "$(cat "$scratch/ok/avra.pre" 2>/dev/null)" = standing ] || { fails=$((fails + 1)); echo "FAIL  standing compiler moves to avra.pre"; }
    [ "$(cat "$scratch/ok/avra" 2>/dev/null)" = "$(printf '#!/bin/sh\necho stub-avra')" ] || { fails=$((fails + 1)); echo "FAIL  fetched compiler is installed as avra"; }
    if [ "$fails" = 0 ]; then echo "fetch_compiler: self-test clean — 8 case(s)"; exit 0; fi
    echo "fetch_compiler: self-test FAILED — $fails case(s)"
    exit 1
fi

tool=${FETCH_RELEASE_TOOL:-tools/compiler_release.py}
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

if [ -z "${GH_TOKEN:-}" ]; then
    GH_TOKEN=$("${FETCH_GH:-gh}" auth token 2>/dev/null || true)
    export GH_TOKEN
fi
[ -n "${GH_TOKEN:-}" ] || [ -n "${GITHUB_TOKEN:-}" ] ||
    refuse "no GitHub token on this machine; the release asset is private, so set GH_TOKEN (gh auth login) and run again"
fetched="$build/avra.fetch"
reason=$("$tool" fetch "$key" "$fetched" 2>&1) ||
    refuse "no published compiler for $sha (key $key): $reason"
"$fetched" --version >/dev/null 2>&1 || refuse "the compiler published for $sha does not run here"

if [ -e "$build/avra" ]; then
    [ ! -e "$build/avra.pre" ] || mv "$build/avra.pre" "$build/avra.pre.$(date +%s)"
    mv "$build/avra" "$build/avra.pre"
fi
mv "$fetched" "$build/avra"

bytes=$(wc -c < "$build/avra" | tr -d ' ')
digest=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$build/avra")
echo "fetch_compiler: installed $build/avra — key $key from $sha, $bytes bytes, sha256 $digest"
