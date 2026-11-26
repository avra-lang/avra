#!/bin/sh
# THE BROWSER LEG'S HOST LIBRARIES (packages-browser.txt, and any packages named after it), installed at
# run time: a mirror mid-sync answers 404 for a version its stale index still names, so each attempt reads
# the index afresh right before it installs, apt retries every fetch, and a failed attempt is tried again —
# three in all, each bounded, 20 s apart — before the step fails with apt's own words.
set -u
here=$(cd "$(dirname "$0")" && pwd)
export DEBIAN_FRONTEND=noninteractive
pkgs="$* $(grep -v '^#' "$here/packages-browser.txt" | tr '\n' ' ')"
# BAKED INTO THE IMAGE: avra-ci:llvm22-browser (Dockerfile.browser) installs this list when it is built and
# stamps the list's digest at /etc/avra-browser-libs, so where the stamp is this list's and every package
# named after it stands, nothing is fetched; a list that moved since the image was built installs as below.
list_key=$(grep -v '^#' "$here/packages-browser.txt" | sha256sum | cut -c1-64)
if [ "$(cat /etc/avra-browser-libs 2>/dev/null)" = "$list_key" ] && { [ $# -eq 0 ] || dpkg -s "$@" >/dev/null 2>&1; }; then
    echo "install_browser_libs: baked into this image (list $(printf '%.12s' "$list_key")) — nothing installed"
    exit 0
fi
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
