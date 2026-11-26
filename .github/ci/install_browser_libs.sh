#!/bin/sh
# THE BROWSER LEG'S HOST LIBRARIES (packages-browser.txt, and any packages named after it), installed at
# run time: a mirror mid-sync answers 404 for a version its stale index still names, so each attempt reads
# the index afresh right before it installs, apt retries every fetch, and a failed attempt is tried again —
# three in all, each bounded, 20 s apart — before the step fails with apt's own words.
set -u
here=$(cd "$(dirname "$0")" && pwd)
export DEBIAN_FRONTEND=noninteractive
pkgs="$* $(grep -v '^#' "$here/packages-browser.txt" | tr '\n' ' ')"
# AN ATTEMPT IS BOUNDED AND SAYS ITS SECONDS: a fetch that stalls answers nothing and fails nothing, so
# only a bound turns it into the retry above, and only the seconds say which attempt the time went to
apt_opts="-o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30"
n=1
while :; do
    t0=$(date +%s)
    if timeout 150 apt-get $apt_opts update -qq &&
        timeout 150 apt-get $apt_opts install -y -qq --no-install-recommends $pkgs; then
        echo "install_browser_libs: attempt $n installed in $(( $(date +%s) - t0 ))s"
        exit 0
    fi
    echo "install_browser_libs: attempt $n failed or stalled after $(( $(date +%s) - t0 ))s" >&2
    [ "$n" -lt 3 ] || { echo "install_browser_libs: apt failed $n times — the mirror did not hold the index's versions" >&2; exit 1; }
    echo "install_browser_libs: the index is read again in 20 s" >&2
    n=$((n + 1))
    sleep 20
done
