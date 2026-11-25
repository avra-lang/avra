# A PINNED RELEASE, FETCHED AND CHECKED: the one door every install script
# here takes, sourced. `fetch_pinned <name> <url> <sha256>` downloads the
# archive, refuses it unless its digest is the pinned one, and unpacks it into
# $pinned, removed when the caller exits. Call it in the caller's own shell,
# never in a `$(…)`, whose exit would remove what it unpacked.
fetch_pinned() {
    work=$(mktemp -d)
    trap 'find "$work" -delete' EXIT
    archive="$work/archive"
    curl -fsSL -o "$archive" "$2"
    sum=$( { sha256sum "$archive" 2>/dev/null || shasum -a 256 "$archive"; } | awk '{print $1}')
    [ "$sum" = "$3" ] \
        || { echo "$1: the archive at $2 is not the one pinned" >&2; exit 1; }
    pinned="$work/out"
    mkdir "$pinned"
    tar -xf "$archive" -C "$pinned"
}
