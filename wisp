#!/bin/sh
# THE wisp COMMAND — the repo's internal CLI (packages/wisp), run.
#
#   ./wisp <command> [args…]               stdin and the status pass through
#   ./wisp --path                          where the binary stands, built if need be
#   ./wisp --key                           the package's key: a hash of its manifest and src/, tests aside, as
#                                          the tree holds them (git's where the tree is the index)
#   ./wisp --compiler <avra> <command> …   build with that compiler when no binary stands for the key
#   ./wisp release <fetch|latest|install|key-of|probe|route> …
#                                          a published compiler or wisp got (below); `release publish` is the binary's
#
# A KEEPER IS NEVER JUDGED BY THE COMPILER UNDER TEST. The binary is main's:
# built by main's compiler from the package's source and published beside the
# compiler as the `wisp` asset under `wisp-<key>` (`wisp release publish`).
# One key is one source, so a published binary under it is immutable, and a PR
# that does not touch the package has main's key. Resolved in order:
#   1. build/wisp/<key>/wisp, already here;
#   1b. in a tree of program's, the wisp the landing publishes beside the gate's builder for the key, else one
#      built by `--compiler` or this tree's own standing compiler, else a refusal saying why — never steps 2-4,
#      whose compilers predate program's source;
#   2. the published asset for the key, fetched — on Linux x86-64 only, the one platform CI
#      publishes for; any other machine builds its own;
#   3. built here by `--compiler`, else by main's published compiler (Linux x86-64) or
#      the standing build/avra (any other machine);
#   4. the Python tool of the same name (tools/<command with _>.py), while no
#      binary answers — said on stderr, so a fallback is never silent.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cd "$here"
package=packages/wisp

# THE KEY IS WHAT A BUILD READS. Where the working tree is git's index, it is what git holds, so a clean tree's
# key is the one published for its commit. Where it is not — a file edited or deleted and not staged, or a new
# one git does not track — the index no longer says what a build reads, so the key is the bytes the tree
# holds, said on stderr: no published or cached binary was built from them, and wisp is built again rather
# than served from an older source.
key() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        set -- "$package/avra.toml" "$package/src" ":(exclude,glob)$package/**/tests/**"
        files=$(git ls-files -s -- "$@")
        [ -n "$files" ] || { echo "wisp: git lists no $package here" >&2; exit 1; }
        moved=$(git diff --name-only -- "$@"; git ls-files -o --exclude-standard -- "$@")
        if [ -z "$moved" ]; then
            printf '%s\n' "$files" | git hash-object --stdin
            return 0
        fi
        echo "wisp: $package holds $(printf '%s\n' "$moved" | grep -c .) file(s) git's index does not — keyed by the bytes the tree holds" >&2
        git ls-files -co --exclude-standard -- "$@" | LC_ALL=C sort -u | while IFS= read -r f; do
            [ ! -f "$f" ] || printf '%s %s\n' "$(git hash-object -- "$f")" "$f"
        done | { echo "the working tree"; cat; } | git hash-object --stdin
    else
        files=$(find "$package/avra.toml" "$package/src" -type f -not -path '*/tests/*' | sort)
        [ -n "$files" ] || { echo "wisp: no $package here" >&2; exit 1; }
        for f in $files; do printf '%s ' "$f"; cksum < "$f"; done | cksum | tr -d ' '
    fi
}

want_path=0 compiler=
if [ -n "${AVRA_TOOLS_COMPILER:-}" ]; then
    echo "wisp: AVRA_TOOLS_COMPILER is deprecated — pass ./wisp --compiler <avra>" >&2
    compiler=$AVRA_TOOLS_COMPILER
fi
while :; do
    case "${1:-}" in
        --key) key; exit 0 ;;
        --path) want_path=1; shift ;;
        --compiler) compiler=${2:?wisp: --compiler takes a path}; shift 2 ;;
        *) break ;;
    esac
done

# THE PUBLISHED COMPILER AND WISP, GOT. Every reader of a release runs before a compiler stands to build
# wisp — this shim fetching wisp, the CI compiler step, a lane's `work`, the pre-commit hook — so the reads
# are shell here, and only `wisp release publish`, which runs after a build, is the binary's. A release is
# named by its key, so one key is one binary and an asset is never replaced.
#
#   ./wisp release fetch  <key> <dest> [--asset <name>]   the key's release asset at dest, or 1 and why
#   ./wisp release latest <dest>                           the newest release carrying the compiler
#   ./wisp release install [<rev> | --key <key>] [--into <dir>]
#                                                          the compiler published for a commit's source (default
#                                                          origin/main) or a key, as <dir>/avra, the standing one
#                                                          kept as avra.pre; Linux only
#   ./wisp release key-of <rev>                            the key a commit's compiler source has
#   ./wisp release probe <key>                             0 when a compiler is published for the key
#   ./wisp release route <dirty> <head-key> <base-key>     published:<key>, mergebase:<key> or build
#
# The releases API (`fetch`, `latest`) takes the run's token when it has one (GH_TOKEN, GITHUB_TOKEN);
# `install`, `probe` and `route` read the public asset (FETCH_URL, `KEY` its slot), so they need none. A
# `file://` API or FETCH_URL points every read at local files, which is how the witness runs them.
rel_repo=${GITHUB_REPOSITORY:-avra-lang/avra}
rel_api=${AVRA_RELEASE_API:-https://api.github.com/repos/$rel_repo}
rel_token=${GH_TOKEN:-${GITHUB_TOKEN:-}}

# rel_get <url> <out> [<accept>]: the answer at url into out; prints its HTTP status (200 for a local file,
# 404 for a missing one, 000 when nothing answered).
rel_get() {
    case $1 in
        (file://*) if cp "${1#file://}" "$2" 2>/dev/null; then echo 200; else echo 404; fi; return 0 ;;
    esac
    if [ -n "$rel_token" ]; then
        code=$(curl -sS -L -m 120 -o "$2" -w '%{http_code}' -H "Accept: ${3:-application/vnd.github+json}" \
            -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: avra-compiler-release" \
            -H "Authorization: Bearer $rel_token" "$1" 2>"$2.err") || :
    else
        code=$(curl -sS -L -m 120 -o "$2" -w '%{http_code}' -H "Accept: ${3:-application/vnd.github+json}" \
            -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: avra-compiler-release" "$1" 2>"$2.err") || :
    fi
    find "$2.err" -delete 2>/dev/null || :
    echo "$code"
}

# rel_place <url> <dest> <what>: an asset at url placed at dest, executable; 1 and why when it did not come.
rel_place() {
    code=$(rel_get "$1" "$2.part" application/octet-stream)
    case $code in
        (2*) mv "$2.part" "$2" && chmod 755 "$2" ;;
        (*) find "$2.part" -delete 2>/dev/null || :; echo "compiler-release: $3: asset unreachable (HTTP $code)" >&2; return 1 ;;
    esac
}

rel_fetch() {
    t=$(mktemp "${TMPDIR:-/tmp}/wisp-release.XXXXXX")
    code=$(rel_get "$rel_api/releases/tags/$1" "$t")
    case $code in
        (2*) ;;
        (404) find "$t" -delete; echo "compiler-release: $1: no release" >&2; return 1 ;;
        (000) find "$t" -delete; echo "compiler-release: $1: release API unreachable" >&2; return 1 ;;
        (*) find "$t" -delete; echo "compiler-release: $1: release API answered HTTP $code" >&2; return 1 ;;
    esac
    url=$(jq -r --arg n "$3" '[.assets[]? | select(.name == $n) | .url] | first // empty' "$t")
    find "$t" -delete
    [ -n "$url" ] || { echo "compiler-release: $1: release has no $3 asset" >&2; return 1; }
    rel_place "$url" "$2" "$1" || return 1
    echo "compiler-release: $1: fetched $(wc -c < "$2" | tr -d ' ') bytes from release"
}

# The newest published release carrying the compiler, by its creation time: the data decides, the API's
# order only among releases created in the same second. Only main publishes, so it is main's latest — a starting point a build reads, never the tree's.
rel_latest() {
    t=$(mktemp "${TMPDIR:-/tmp}/wisp-release.XXXXXX")
    code=$(rel_get "$rel_api/releases?per_page=100" "$t")
    case $code in
        (2*) ;;
        (*) find "$t" -delete; echo "compiler-release: latest: release API unreachable (HTTP $code)" >&2; return 1 ;;
    esac
    pick=$(jq -r '[.[] | select((.draft | not) and ([.assets[]?.name] | index("avra")))]
        | (map(.created_at // "") | max) as $newest | map(select((.created_at // "") == $newest)) | first
        | if . == null then empty else "\(.tag_name // "?") \([.assets[] | select(.name == "avra") | .url] | first)" end' "$t")
    find "$t" -delete
    [ -n "$pick" ] || { echo "compiler-release: latest: no published release carries an avra asset" >&2; return 1; }
    tag=${pick%% *}
    rel_place "${pick#* }" "$1" "latest $tag" || return 1
    echo "compiler-release: latest $tag: fetched $(wc -c < "$1" | tr -d ' ') bytes from release"
}

rel_asset_url() {
    printf '%s\n' "${FETCH_URL:-https://github.com/$rel_repo/releases/download/avrac-KEY/avra}" | sed "s/KEY/$1/"
}

rel_there() {
    case $1 in
        (file://*) [ -f "${1#file://}" ] ;;
        (*) curl -fsSI -L -m 30 "$1" >/dev/null 2>&1 ;;
    esac
}

# The anonymous asset, asked up to FETCH_TRIES (5) times with a doubling pause, 2 s first; why on failure.
rel_asset_fetch() {
    case $1 in
        (file://*) cp "${1#file://}" "$2" 2>/dev/null && return 0; why="$1 is not a file"; return 1 ;;
    esac
    tries=${FETCH_TRIES:-5} pause=2 n=1
    while :; do
        code=$(curl -sS -L -m "${FETCH_MAX_S:-600}" -o "$2" -w '%{http_code}' "$1" 2>/dev/null) || :
        case $code in (2*) return 0 ;; (000) why="no HTTP answer after $n attempt(s)" ;; (*) why="HTTP $code after $n attempt(s)" ;; esac
        [ "$n" -lt "$tries" ] || return 1
        sleep "$pause"
        pause=$((pause * 2)) n=$((n + 1))
    done
}

# The compiler-source key of a commit, read from a temporary index of its tree.
rel_key_of() {
    mkdir -p "${2:-build}"
    GIT_INDEX_FILE="${2:-build}/fetch.index" git read-tree "$1" 2>/dev/null || return 1
    key=$(GIT_INDEX_FILE="${2:-build}/fetch.index" sh tools/compiler_paths.sh --key 2>/dev/null) || return 1
    [ -n "$key" ] && echo "$key"
}

rel_refuse() { echo "compiler-release: REFUSED — $1" >&2; return 1; }

rel_install() {
    rev= key= into=${FETCH_BUILD:-build}
    while [ $# -gt 0 ]; do
        case $1 in
            (--key) key=$2; shift 2 ;;
            (--into) into=$2; shift 2 ;;
            (*) rev=$1; shift ;;
        esac
    done
    platform=${FETCH_UNAME:-$(uname -s)}
    [ "$platform" = Linux ] || { rel_refuse "the published compiler is a linux binary; this machine is $platform"; return 1; }
    if [ -n "$key" ]; then
        names="a key given on the command line"
    else
        git rev-parse --git-dir >/dev/null 2>&1 || { rel_refuse "no git repository here; read the key where git is (sh tools/compiler_paths.sh --key at the commit) and pass it with --key"; return 1; }
        names=$(git rev-parse --verify --quiet "${rev:-origin/main}^{commit}") || { rel_refuse "no commit named ${rev:-origin/main}"; return 1; }
        key=$(rel_key_of "$names" "$into") || { rel_refuse "the compiler source of $names is not listed"; return 1; }
    fi
    url=$(rel_asset_url "$key")
    mkdir -p "$into"
    fetched=$into/avra.fetch why=
    if ! rel_asset_fetch "$url" "$fetched"; then
        if [ -z "${FETCH_URL:-}" ] && rel_fetch "avrac-$key" "$fetched" avra >/dev/null; then
            echo "compiler-release: the anonymous asset failed ($why); the releases API answered" >&2
        else
            find "$fetched" -delete 2>/dev/null || :
            rel_refuse "no published compiler for $names (key $key): $url did not answer — last answer $why"
            return 1
        fi
    fi
    chmod 755 "$fetched"
    "$fetched" --version >/dev/null 2>&1 || { rel_refuse "the compiler published for $names does not run here"; return 1; }
    if [ -e "$into/avra" ]; then
        [ ! -e "$into/avra.pre" ] || mv "$into/avra.pre" "$into/avra.pre.$(date +%s)"
        mv "$into/avra" "$into/avra.pre"
    fi
    mv "$fetched" "$into/avra"
    echo "compiler-release: installed $into/avra — key $key from $names, $(wc -c < "$into/avra" | tr -d ' ') bytes, sha256 $( (sha256sum "$into/avra" 2>/dev/null || shasum -a 256 "$into/avra") | cut -d' ' -f1)"
}

rel_route() {
    if [ "$1" = 0 ] && [ -n "${2:-}" ] && rel_there "$(rel_asset_url "$2")"; then
        echo "published:$2"
    elif [ -n "${3:-}" ] && rel_there "$(rel_asset_url "$3")"; then
        echo "mergebase:$3"
    else
        echo build
    fi
}

if [ "${1:-}" = release ]; then
    case ${2:-} in
        (fetch) shift 2; asset=avra; [ "${3:-}" != --asset ] || asset=$4; rel_fetch "$1" "$2" "$asset"; exit $? ;;
        (latest) rel_latest "$3"; exit $? ;;
        (install) shift 2; rel_install "$@"; exit $? ;;
        (key-of) c=$(git rev-parse --verify --quiet "$3^{commit}") || exit 1; rel_key_of "$c"; exit $? ;;
        (probe) rel_there "$(rel_asset_url "$3")" || exit 1; exit 0 ;;
        (route) rel_route "$3" "${4:-}" "${5:-}"; exit 0 ;;
    esac
fi

# A COMPILER FINDS ITS STD ROOT AND ITS TOOLCHAIN BESIDE ITSELF (`<self>/../packages`),
# so it builds from a copy standing in the tree's build/, after the runtime library
# and the reached packages' objects it links. A failed build says why, on stderr.
build_wisp() {
    cp "$1" build/wisp-compiler
    make -s build/libavra_runtime.a build/libavra_runtime_uninstrumented.a $(sh tools/manifest_objects.sh --closure "$package") >&2 || { echo "wisp: the runtime library or a std object did not build" >&2; return 1; }
    if out=$(AVRA_PROGRAM_MODE=release build/wisp-compiler build "$package" 2>&1); then
        cp "$(printf '%s\n' "$out" | tail -n 1)" "$bin" && chmod +x "$bin"
    else
        printf '%s\n' "$out" | tail -n 20 >&2
        echo "wisp: $package did not build" >&2
        return 1
    fi
}

# Main's compiler, installed beside (never over) the standing build/avra: main's own
# key, else the newest published (main's key is unpublished until its run proves it).
# A checkout of the PR's ref alone holds no origin/main, so it is fetched first.
main_compiler() {
    git rev-parse -q --verify origin/main >/dev/null 2>&1 ||
        git fetch -q --depth 1 origin main:refs/remotes/origin/main >&2 || true
    rel_install --into "$dir/compiler" >&2 && return 0
    mkdir -p "$dir/compiler"
    rel_latest "$dir/compiler/avra" >&2
}

k=$(key)
dir=build/wisp/$k
bin=$dir/wisp
# A TREE OF PROGRAM'S (tools/work program-base) takes the wisp each landing publishes beside the gate's
# builder (.github/workflows/tools-release.yml) where its key is this tree's, else builds it with this tree's
# own compiler — never with main's or the newest published, which predate program's source and build a tool
# that refuses it. Where neither gives one, it says so here and runs nothing older instead.
if [ ! -x "$bin" ] && pb=$(sh tools/work program-base . 2>/dev/null); then
    mkdir -p "$dir"
    t=$(mktemp -d "${TMPDIR:-/tmp}/wisp.XXXXXX")
    # ONE ASSET A PLATFORM, both keyed alike: Linux x86-64's ELF (tools-release.yml) and Darwin arm64's Mach-O
    # (compiler-macos.yml); any other machine builds its own with its standing compiler
    case $(uname -s)-$(uname -m) in
        (Linux-x86_64) asset=wisp.tar.gz ;;
        (Darwin-arm64) asset=wisp-macos.tar.gz ;;
        (*) asset= ;;
    esac
    url=https://github.com/avra-lang/avra/releases/download/gate-builder/$asset
    if [ -z "$asset" ]; then
        fetched="no fetch: the gate's builder publishes wisp for Linux x86-64 and Darwin arm64, and this is $(uname -s)-$(uname -m)"
    elif ! curl -fsSL --retry 2 -m 120 -o "$t/wisp.tar.gz" "$url" 2>/dev/null; then
        fetched="$url did not download"
    elif ! tar -xzf "$t/wisp.tar.gz" -C "$t" "build/wisp/$k/wisp" 2>/dev/null; then
        fetched="$url holds no wisp of this key (it carries the last landing's)"
    else
        fetched=""
    fi
    if [ -z "$fetched" ]; then
        cp "$t/build/wisp/$k/wisp" "$bin" && chmod +x "$bin"
        echo "wisp: the wisp of key $(printf '%.12s' "$k") published beside the gate's builder ($asset)" >&2
    fi
    find "$t" -delete
    c=$compiler
    if [ ! -x "$bin" ] && [ -z "$c" ] && [ -x build/avra ] &&
        [ "$(cut -d' ' -f1 build/.avra-built-from 2>/dev/null)" = "$(sh tools/work built-from . | cut -d' ' -f1)" ]; then
        c=build/avra
    fi
    if [ ! -x "$bin" ] && [ -n "$c" ] && [ -x "$c" ]; then
        build_wisp "$c" && echo "wisp: wisp of key $(printf '%.12s' "$k") built by $c" >&2 || :
    fi
    if [ ! -x "$bin" ]; then
        if [ -n "$c" ]; then why="$c did not build it (above)"; else why="no compiler of this tree's source stands here to build it"; fi
        echo "wisp: a tree of program's (merge-base $(printf '%.8s' "$pb")): no wisp of key $(printf '%.12s' "$k") — $fetched, and $why; nothing older is run instead" >&2
        exit 1
    fi
fi
# THE PUBLISHED BINARIES ARE LINUX X86-64 ELFs: another machine cannot run them, so it builds its own.
published=0
[ "$(uname -s)-$(uname -m)" = Linux-x86_64 ] && published=1
if [ ! -x "$bin" ] && [ "$published" = 1 ]; then
    mkdir -p "$dir"
    rel_fetch "wisp-$k" "$bin" wisp >&2 || true
fi
if [ ! -x "$bin" ] && [ -z "$compiler" ]; then
    if [ "$published" = 1 ]; then
        main_compiler && compiler="$dir/compiler/avra" || true
    elif [ -x build/avra ]; then
        mkdir -p "$dir"
        compiler=build/avra
    fi
fi
if [ ! -x "$bin" ] && [ -n "$compiler" ] && [ -x "$compiler" ]; then
    mkdir -p "$dir"
    build_wisp "$compiler" || true
fi
if [ "$want_path" = 1 ]; then [ -x "$bin" ] && echo "$bin" || exit 1; exit 0; fi
if [ -x "$bin" ]; then exec "$bin" "$@"; fi
cmd=$(printf '%s' "${1:?wisp: a command}" | tr - _)
shift
[ -f "tools/$cmd.py" ] || { echo "wisp: no binary for key $k, and no Python $cmd to answer — the reasons are above" >&2; exit 1; }
echo "wisp: no binary for key $k — the Python $cmd answers" >&2
exec python3 "tools/$cmd.py" "$@"
