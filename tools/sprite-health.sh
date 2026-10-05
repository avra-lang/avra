# `sp --health` and `sp --repair`, sourced by tools/sp with its verb in $1.
#
# HEALTH asks every Sprite once, all at once, for AVRA_SP_HEALTH_S (25)
# seconds, and prints one row each beside this machine's leases. It
# changes nothing and exits 1 when anything is unwell.
#
# REPAIR reaps the leases and locks whose owner is gone, then on every
# Sprite that answers within AVRA_SP_WAKE_S (90): installs what the
# checks' toolchain lacks, stops the runs this machine began and no
# longer owns, and prunes old compilers, trees and scratch. It says what
# it did, then prints health.
health_s=${AVRA_SP_HEALTH_S:-25}
hd=$(mktemp -d "${TMPDIR:-/tmp}/avra-sp-health.XXXXXX")
trap 'rm -rf "$hd"' EXIT

everyone() {
    if [ -n "${AVRA_SPRITES:-}" ]; then echo "$AVRA_SPRITES"; return 0; fi
    AVRA_SP_EXCLUDE="web-terminal avra-bench" exclude="web-terminal avra-bench" pool
}
api_states() {
    [ -z "${AVRA_SPRITES:-}" ] || return 0
    timeout -k 1 15 "$sprite_cli" api /sprites 2>/dev/null | python3 -c '
import json, sys
for r in json.load(sys.stdin)["data"]: print(r["name"], r["status"])' 2>/dev/null || :
}
val() { sed -n "s/^$2=//p" "$hd/$1.status" | head -n 1; }

repair() {
    echo "repair: this machine"
    reap
    leases sweep | sed 's/^/  /'
    for l in /tmp/avra-sp-hash-*; do
        [ -d "$l" ] || continue
        { read -r lp lb < "$l/owner"; } 2>/dev/null || { lp=$(cat "$l/pid" 2>/dev/null || echo); lb=; }
        if [ -n "$lb" ]; then owner_live "$lp" "$lb"; else [ -n "$lp" ] && kill -0 "$lp" 2>/dev/null; fi && continue
        rm -rf "$l"
        echo "  reaped ${l##*/}"
    done
    rm -f "$dead_dir"/*
    for s in $(everyone); do
        (
            if ! info=$(woken "$s" "${AVRA_SP_WAKE_S:-90}" ready - $ci_packages 2>&1); then
                echo "repair: $s did not answer within ${AVRA_SP_WAKE_S:-90}s — nothing done"
                exit 0
            fi
            did=$(printf '%s\n' "$info" | sed -n 's/^installed=/installed /p; s/^unprovisioned=/COULD NOT INSTALL /p')
            gone=$(printf '%s\n' "$info" | sed -n 's/^run=//p' | orphaned)
            [ -z "$gone" ] || { remote "$s" 60 stop $gone >/dev/null 2>&1 && did="$did; stopped runs $gone"; }
            remote "$s" 30 prune "${AVRA_SP_KEEP_COMPILERS:-6}" "${AVRA_SP_KEEP_DAYS:-2}" >/dev/null 2>&1 && did="$did; pruning"
            echo "repair: $s: ${did#; }"
        ) &
    done
    wait
}

health() {
    api_states > "$hd/api"
    for s in $(everyone); do
        (
            t=$(date +%s)
            if remote "$s" "$health_s" status - $ci_packages > "$hd/$s.status" 2>/dev/null; then
                echo $(($(date +%s) - t)) > "$hd/$s.secs"
            fi
        ) &
    done
    wait
    leases table > "$hd/leases"
    unwell=0
    printf '%-18s %-8s %-8s %-5s %-10s %-9s %-9s %-10s %-8s %-6s %s\n' \
        sprite api answer home toolchain compilers trees disk-free tmp-used mem-MB runs
    for s in $(everyone); do
        api=$(awk -v s="$s" '$1 == s { print $2 }' "$hd/api")
        if [ ! -f "$hd/$s.secs" ]; then
            printf '%-18s %-8s %s\n' "$s" "${api:--}" "NO ANSWER in ${health_s}s"
            unwell=1
            continue
        fi
        note=
        missing=$(val "$s" missing)
        tools=ok
        [ -z "$missing" ] || { tools="lacks $(echo $missing | wc -w | tr -d ' ')"; note="$note toolchain($(echo $missing | tr ' ' ','))"; }
        [ "$(val "$s" home)" = yes ] || note="$note home"
        [ "$(val "$s" disk_used_pct)" -lt 85 ] || note="$note disk"
        [ "$(val "$s" tmp_used_pct)" -lt 95 ] || note="$note tmp"
        live=$(sed -n 's/^run=//p' "$hd/$s.status" | grep -c ' live ' || :)
        gone=$(sed -n 's/^run=//p' "$hd/$s.status" | orphaned | wc -w | tr -d ' ')
        [ "$gone" = 0 ] || note="$note orphans"
        [ "$(val "$s" pruning)" = no ] || tools="$tools,pruning"
        printf '%-18s %-8s %-8s %-5s %-10s %-9s %-9s %-10s %-8s %-6s %s%s\n' "$s" "${api:--}" "$(cat "$hd/$s.secs")s" \
            "$(val "$s" home)" "$tools" "$(val "$s" compilers)" "$(val "$s" trees)" \
            "$(($(val "$s" disk_free_mb) / 1024))G/$(val "$s" disk_used_pct)%" "$(val "$s" tmp_used_pct)%" \
            "$(val "$s" mem_avail_mb)" "$live live, $gone orphaned" "${note:+  UNWELL:$note}"
        [ -z "$note" ] || unwell=1
    done
    echo
    if [ -s "$hd/leases" ]; then
        echo "leases under $slots:"
        while read -r s l p state; do
            printf '  %-18s %-32s %-7s %-5s %s\n' "$s" "$l" "$p" "$state" "$(ps -o command= -p "$p" 2>/dev/null | cut -c1-70)"
            [ "$state" = live ] || unwell=1
        done < "$hd/leases"
    else
        echo "leases under $slots: none"
    fi
    waiting=$(find "$queue" -type f ! -name '.*' 2>/dev/null | wc -l | tr -d ' ')
    out=$(for s in $(everyone); do ! is_dead "$s" || printf '%s ' "$s"; done)
    echo "waiting for a slot: $waiting; left out for now: ${out:-none}"
    return "$unwell"
}

[ "$1" != --repair ] || repair
health
