# A PINNED RELEASE, FETCHED AND CHECKED: the one door every install script
# here takes, sourced. `fetch_pinned <name> <url> <sha256>` downloads the
# archive, refuses it unless its digest is the pinned one, and unpacks it into
# $pinned, removed when the caller exits; a fetch that stalls under 10 kB/s
# for a minute is tried again. Call it in the caller's own shell, never in a
# `$(…)`, whose exit would remove what it unpacked.
fetch_pinned() {
    # LICENSED scratch_law: this runs inside the CI image's build, whose context is .github/ci alone,
    # so tools/lib/scratch.sh is not there to source
    work=$(mktemp -d)
    # LICENSED scratch_law: the image's build, as above — nothing bounds it by a signal
    trap 'find "$work" -delete' EXIT
    archive="$work/archive"
    curl -fsSL --connect-timeout 20 --speed-limit 10000 --speed-time 60 --retry 3 -o "$archive" "$2"
    sum=$( { sha256sum "$archive" 2>/dev/null || shasum -a 256 "$archive"; } | awk '{print $1}')
    [ "$sum" = "$3" ] \
        || { echo "$1: the archive at $2 is not the one pinned" >&2; exit 1; }
    pinned="$work/out"
    mkdir "$pinned"
    tar -xf "$archive" -C "$pinned"
}
