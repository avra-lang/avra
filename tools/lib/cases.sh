# A CASE IS A PACKAGE: a directory under a witness's cases that holds its manifest, `avra.toml`.
# Sourced by every witness that walks a directory of cases, and by the gate that deals them, so
# the three agree on what a case is. A directory holding no manifest — a build's `.avra-cache` left
# where a case's sources were taken away — is no case: it is never judged, and each is named.
#
#   cases_in <dir>       each case's name, one a line, in name order
#   leftovers_in <dir>   each directory that is no case, and what it holds, one a line
cases_in() {
    for d in "$1"/*/; do
        [ -f "$d/avra.toml" ] && basename "$d"
    done
    return 0
}
leftovers_in() {
    for d in "$1"/*/; do
        [ -d "$d" ] && [ ! -f "$d/avra.toml" ] && echo "$(basename "$d") — no avra.toml, so no case; it holds: $(ls -A "$d" | tr '\n' ' ')"
    done
    return 0
}
