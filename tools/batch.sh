#!/bin/sh
# THE AUTO-BATCHER: approved PR branches, one integration PR.
#
#   sh tools/work batch [--n N] [--attacks-ran N=EVIDENCE]… [--suites-ran N=EVIDENCE]… <pr>…
#   sh tools/work batch close <N>
#
# `batch` builds batch-<N> off origin/main and merges each member's head in
# the order given, pushes it, opens ONE PR, arms auto-merge, and retitles each
# member "DO NOT MERGE (lands via batch #N) — <its title>". A READY member is
# refused when its `test` check is not SUCCESS. A DRAFT member's run is the
# light gate, so it is judged by its `gate`, `keepers-static` and `codecs`
# checks, and its heavy legs did not run: each needs its evidence from the
# Sprite, --attacks-ran / --attacks-na for cache-attacks and --suites-ran for
# the suites. A member whose `cache-attacks` job is FAILURE is refused either
# way. The batch PR is a ready PR, so its own run is the full gate. A merge
# that conflicts is aborted and named; nothing is resolved here.
#
# `batch close <N>` runs once the batch PR has merged: it closes each member
# with a pointer to the batch PR. A batch that did not merge closes nothing,
# and names the members whose files its failing job's log names.
#
# THE BATCH PR'S BODY CARRIES ITS MEMBERS, as `<!-- batch-members: … -->`, so
# `close` needs no state of its own. `gh` is AVRA_GH (a test stands in for it).
set -u
gh_=${AVRA_GH:-gh}
die() { echo "batch: $*" >&2; exit 1; }

# One member's facts, tab-separated: number, state, draft, title, head branch,
# the `test` check, the `cache-attacks` check, its before/after line, and the
# light gate's checks (`gate`, `keepers-static`, `codecs`). A check is the NEWEST
# run of its name on the PR's CURRENT head: a run on an older head is no verdict
# on what the batch would land.
member_facts() {
    $gh_ pr view "$1" --json number,title,headRefName,headRefOid,isDraft,state,body,statusCheckRollup |
        GH_BIN=$gh_ python3 -c '
import json, os, re, subprocess, sys
pr = json.load(sys.stdin)
head = pr.get("headRefOid") or ""
def run_head(rid):
    out = subprocess.run([os.environ["GH_BIN"], "api", "repos/:owner/:repo/actions/runs/" + rid,
                          "--jq", ".head_sha"], capture_output=True, text=True)
    return out.stdout.strip()
newest = {}
for c in pr.get("statusCheckRollup") or []:
    name = c.get("name") or c.get("context") or ""
    m = re.search(r"/runs/([0-9]+)", c.get("detailsUrl") or c.get("targetUrl") or "")
    if m and head:
        on = run_head(m.group(1))
        if on and on != head:
            continue
    started = c.get("startedAt") or c.get("completedAt") or ""
    if name not in newest or started >= newest[name][0]:
        newest[name] = (started, (c.get("conclusion") or c.get("state") or c.get("status") or "").upper())
checks = {name: verdict for name, (_, verdict) in newest.items()}
before = ""
for line in (pr.get("body") or "").splitlines():
    if line.strip().lower().lstrip("-* ").startswith(("before/after", "before:", "after:", "before →", "before ->")):
        before = line.strip()
        break
row = [str(pr["number"]), pr["state"], "draft" if pr.get("isDraft") else "ready",
       pr["title"], pr["headRefName"], checks.get("test", "ABSENT"),
       checks.get("cache-attacks", "ABSENT"), before,
       checks.get("gate", "ABSENT"), checks.get("keepers-static", "ABSENT"), checks.get("codecs", "ABSENT")]
print("\t".join(x.replace("\t", " ").replace("\n", " ") for x in row))'
}

# A title without its own "DO NOT MERGE" lead, nor any "(lands via batch #N) —"
# an earlier batch already put there, for the retitle.
strip_dnm() {
    printf '%s' "$1" | sed -E 's/^(DO NOT MERGE[:—-]* *|\(lands via batch #[0-9]+\) *— *)+//'
}

# The evidence given for member $1 by a list of N=TEXT lines ($2).
evidence_from() {
    printf '%s\n' "$2" | sed -n "s/^$1=//p" | head -n 1
}

# The members named by a batch PR's body.
members_in() {
    python3 -c '
import json, re, sys
pr = json.load(sys.stdin)
pr = pr[0] if isinstance(pr, list) else pr
m = re.search(r"<!-- batch-members: ([0-9 ]+) -->", pr.get("body") or "")
print(" ".join(m.group(1).split()) if m else "")'
}

# A refusal stops a real batch. A plan names every refusal and goes on.
refuse() {
    if [ -n "$plan" ]; then
        echo "plan: would refuse: $*"
        refused=1
    else
        die "$*"
    fi
}

# The batch the members would make, merged in memory: each step is a
# merge-tree over commits made with commit-tree, so no ref and no remote moves.
# A step carries the member's head as its second parent, as the build's merge
# does, so every later step resolves against the ancestry the build will have.
plan_merges() {
    pn=$1; shift
    base=$(git rev-parse origin/main)
    conflicted=
    for pr in "$@"; do
        head=$(member_facts "$pr" | cut -f5)
        git fetch -q origin "+refs/heads/$head:refs/remotes/origin/$head" || die "fetch of $head failed"
        if out=$(git merge-tree --write-tree --name-only "$base" "origin/$head" 2>/dev/null); then
            tree=$(printf '%s\n' "$out" | head -n 1)
            base=$(git commit-tree "$tree" -p "$base" -p "origin/$head" -m "plan: batch-$pn with #$pr")
            echo "plan: #$pr ($head) merges cleanly"
        else
            files=$(printf '%s\n' "$out" | tail -n +2 | grep -v '^$' | tr '\n' ' ')
            echo "plan: #$pr ($head) would CONFLICT; conflicting files: ${files:-(none named)}"
            conflicted=1
        fi
    done
    echo "plan: batch-$pn would be: PR title \"batch #$pn:$titles\", members in order:$titles"
    echo "plan: the batch PR body would be:"
    printf '%s\n' "$body" | sed 's/^/plan: body | /'
    for pr in "$@"; do
        title=$(member_facts "$pr" | cut -f4)
        echo "plan: would retitle #$pr: DO NOT MERGE (lands via batch #$pn) — $(strip_dnm "$title")"
    done
    echo "plan: it would arm auto-merge (squash) on the batch PR"
    [ -z "$conflicted" ] && [ -z "$refused" ] || { echo "plan: NOT BUILDABLE as given"; exit 1; }
    echo "plan: buildable — nothing was pushed, opened, merged or retitled"
}

# The files of member $1 whose content on main (BATCH_MAIN_REF, origin/main) is not
# its content on its head $2. Printed, one per line; none when the member is on main.
off_main() {
    main_ref=${BATCH_MAIN_REF:-origin/main}
    $gh_ pr view "$1" --json files | python3 -c 'import json,sys
for f in json.load(sys.stdin)["files"]: print(f["path"])' | while IFS= read -r f; do
        a=$(git rev-parse --verify -q "$main_ref:$f" || echo gone)
        b=$(git rev-parse --verify -q "origin/$2:$f" || echo gone)
        [ "$a" = "$b" ] || echo "$f"
    done
}

batch_close() {
    [ "$#" -eq 1 ] || [ "$#" -eq 2 ] || die "usage: batch close <N> | batch close --pr <batch PR>"
    if [ "$1" = --pr ]; then
        listing=$($gh_ pr view "$2" --json number,state,body,statusCheckRollup,headRefName) ||
            die "could not read PR #$2"
        bn=$2
        listing="[$listing]"
        n=$(printf '%s' "$listing" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["headRefName"].rsplit("-",1)[-1])')
    else
        n=$1
        listing=$($gh_ pr list --head "batch-$n" --state all --json number,state,body,statusCheckRollup) ||
            die "could not list PRs for batch-$n"
        bn=$(printf '%s' "$listing" | python3 -c 'import json,sys
prs = json.load(sys.stdin)
print(prs[0]["number"] if prs else "")')
        [ -n "$bn" ] || die "no PR for batch-$n"
    fi
    bstate=$(printf '%s' "$listing" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["state"])')
    members=$(printf '%s' "$listing" | members_in)
    case "$bstate" in
        MERGED)
            sha=$(git rev-parse --short "${BATCH_MAIN_REF:-origin/main}" 2>/dev/null || echo "?")
            for m in $members; do
                head=$(member_facts "$m" | cut -f5)
                git fetch -q origin "+refs/heads/$head:refs/remotes/origin/$head" 2>/dev/null ||
                    { echo "batch: #$m left open — its head $head could not be fetched" >&2; continue; }
                differing=$(off_main "$m" "$head" | tr '\n' ' ')
                if [ -n "$differing" ]; then
                    echo "batch: #$m left open — not fully on main; its files that differ: $differing" >&2
                    continue
                fi
                $gh_ pr comment "$m" --body "landed via #$bn (main $sha)" >/dev/null
                $gh_ pr close "$m" >/dev/null
                echo "batch: closed #$m — landed via #$bn (main $sha)"
            done
            return 0 ;;
    esac
    echo "batch: batch #$n (PR #$bn) is $bstate, not merged — no member is closed" >&2
    failing=$(printf '%s' "$listing" | python3 -c 'import json,sys
for c in json.load(sys.stdin)[0].get("statusCheckRollup") or []:
    if (c.get("conclusion") or "").upper() == "FAILURE":
        print((c.get("name") or c.get("context") or "") + " " + (c.get("detailsUrl") or ""))')
    [ -n "$failing" ] || { echo "batch: no failing check named on PR #$bn" >&2; exit 1; }
    echo "$failing" | while read -r job url; do
        echo "batch: failing job: $job" >&2
        run=$(printf '%s' "$url" | sed -n 's#.*/runs/\([0-9][0-9]*\).*#\1#p')
        log=$([ -n "$run" ] && $gh_ run view "$run" --log-failed 2>/dev/null || true)
        for m in $members; do
            for f in $($gh_ pr view "$m" --json files | python3 -c 'import json,sys
print(" ".join(x["path"] for x in json.load(sys.stdin)["files"]))'); do
                case "$log" in
                    *"$f"*) echo "batch: #$m's file $f is named by $job" >&2 ;;
                esac
            done
        done
    done
    exit 1
}

batch_build() {
    n=
    attacks=
    na=
    suites=
    plan=
    draft=
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --plan) plan=1; shift ;;
            --draft) draft=1; shift ;;
            --n) n=$2; shift 2 ;;
            --attacks-ran) attacks="$attacks$2
"; shift 2 ;;
            --attacks-na) na="$na$2
"; shift 2 ;;
            --suites-ran) suites="$suites$2
"; shift 2 ;;
            --) shift; break ;;
            -*) die "unknown flag $1" ;;
            *) break ;;
        esac
    done
    [ "$#" -ge 1 ] || die "usage: batch [--n N] [--attacks-ran N=EVIDENCE]… [--suites-ran N=EVIDENCE]… <pr>…"
    [ -n "$plan" ] || [ -z "$(git status --porcelain --untracked-files=no)" ] || die "commit or drop your changes first"
    git fetch -q origin main || die "fetch of main failed"
    if [ -z "$n" ]; then
        last=$(git ls-remote --heads origin 'batch-*' | sed -n 's#.*refs/heads/batch-\([0-9][0-9]*\)$#\1#p' | sort -n | tail -n 1)
        n=$(( ${last:-0} + 1 ))
    fi
    git ls-remote --exit-code --heads origin "batch-$n" >/dev/null 2>&1 && die "batch-$n already exists on origin — pass --n"

    members=
    titles=
    rows=
    needs=
    refused=
    for pr in "$@"; do
        row=$(member_facts "$pr") || die "no PR #$pr"
        num=$(printf '%s' "$row" | cut -f1)
        state=$(printf '%s' "$row" | cut -f2)
        title=$(printf '%s' "$row" | cut -f4)
        head=$(printf '%s' "$row" | cut -f5)
        mdraft=$(printf '%s' "$row" | cut -f3)
        test=$(printf '%s' "$row" | cut -f6)
        attacks_state=$(printf '%s' "$row" | cut -f7)
        before=$(printf '%s' "$row" | cut -f8)
        gate=$(printf '%s' "$row" | cut -f9)
        kstatic=$(printf '%s' "$row" | cut -f10)
        codecs=$(printf '%s' "$row" | cut -f11)
        [ "$state" = OPEN ] || refuse "#$num is $state, not open"
        if [ "$mdraft" = draft ]; then
            # A light gate SKIPPED is the compiler-not-published skip: the member's
            # gate verdict is the batch PR's own full run, so it needs the evidence
            # for both halves (cache-attacks below, and the suites here).
            case "$gate" in
                SUCCESS) ;;
                SKIPPED) ;;
                *) refuse "#$num refused: its light gate check is $gate, not SUCCESS or SKIPPED" ;;
            esac
            [ "$kstatic" = SUCCESS ] || refuse "#$num refused: its keepers-static check is $kstatic, not SUCCESS"
            case "$codecs" in SUCCESS | SKIPPED | ABSENT) ;; *) refuse "#$num refused: its codecs check is $codecs" ;; esac
            ev=$(evidence_from "$num" "$suites")
            [ -n "$ev" ] || refuse "#$num is a draft: its suites did not run on the light gate — pass --suites-ran $num=\"<the Sprite result>\""
            needs="$needs
#$num: suites ran — $ev"
        else
            [ "$test" = SUCCESS ] || refuse "#$num refused: its test check is $test, not SUCCESS"
        fi
        case "$attacks_state" in
            SUCCESS) ;;
            FAILURE | ERROR | TIMED_OUT) refuse "#$num refused: its cache-attacks job is $attacks_state" ;;
            *)
                ev=$(evidence_from "$num" "$attacks")
                reason=$(evidence_from "$num" "$na")
                if [ -n "$ev" ]; then
                    needs="$needs
#$num: ran — $ev"
                elif [ -n "$reason" ]; then
                    needs="$needs
#$num: not applicable — $reason"
                else
                    refuse "#$num: cache-attacks is $attacks_state, so it did not run — pass --attacks-ran $num=\"<the Sprite result>\", or --attacks-na $num=\"<why it does not apply>\""
                fi ;;
        esac
        members="$members $num"
        titles="$titles #$num"
        rows="$rows
- #$num $(strip_dnm "$title")"
        [ -n "$before" ] && rows="$rows
  $before"
    done

    body="Integration of the members below (\`sh tools/work batch\`).

<!-- batch-members:$members -->

Members, in merge order:$rows"
    if [ -n "$needs" ]; then
        body="$body

Cache-attacks did not run for these members; the evidence given for each:$needs"
    fi
    if [ -n "$plan" ]; then
        plan_merges "$n" $members
        return
    fi
    git checkout -q -B "batch-$n" origin/main || die "could not create batch-$n"
    for pr in $members; do
        head=$(member_facts "$pr" | cut -f5)
        git fetch -q origin "+refs/heads/$head:refs/remotes/origin/$head" || die "fetch of $head failed"
        if ! git merge -q --no-edit "origin/$head" >/dev/null 2>&1; then
            files=$(git diff --name-only --diff-filter=U | tr '\n' ' ')
            git merge --abort >/dev/null 2>&1
            die "#$pr ($head) conflicts with batch-$n; conflicting files: ${files:-(none named)}. Nothing was pushed and nothing was resolved."
        fi
        echo "batch: merged #$pr ($head)"
    done

    git push -q -u origin "batch-$n" || die "push of batch-$n failed"
    if [ -n "$draft" ]; then
        url=$($gh_ pr create --draft --base main --head "batch-$n" --title "DO NOT MERGE: batch #$n:$titles" --body "$body") ||
            die "could not open the batch PR"
        bpr=${url##*/}
        echo "batch: #$bpr is a draft; it is not armed — ready it with gh pr ready $bpr when it may land"
    else
        url=$($gh_ pr create --base main --head "batch-$n" --title "batch #$n:$titles" --body "$body") ||
            die "could not open the batch PR"
        bpr=${url##*/}
        if $gh_ pr merge "$bpr" --auto --squash >/dev/null 2>&1; then
            echo "batch: #$bpr armed for auto-merge (squash)"
        else
            echo "batch: could not arm auto-merge on #$bpr yet — the watcher will arm it" >&2
        fi
    fi
    for pr in $members; do
        title=$(member_facts "$pr" | cut -f4)
        $gh_ api -X PATCH "repos/:owner/:repo/pulls/$pr" \
            -f title="DO NOT MERGE (lands via batch #$n) — $(strip_dnm "$title")" >/dev/null &&
            echo "batch: retitled #$pr"
    done
    echo "batch: batch #$n is $url"
}

case "${1:-}" in
    close) shift; batch_close "$@" ;;
    "") die "usage: batch [--n N] [--attacks-ran N=EVIDENCE]… <pr>… | batch close <N>" ;;
    *) batch_build "$@" ;;
esac
