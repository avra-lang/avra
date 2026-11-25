# A COUNTED CHECKLIST, sourced by the `*_test.sh` suites that prove fixtures:
#
#   ok <words>                  a check that held
#   bad <words> [<log file>]    a check that did not, the file's lines shown beside it
#   check <got> <want> <words> [<log file>]
#   checks_done <name>          the counts, and a status that is 0 iff none failed
total=0
failed=0
ok() { total=$((total + 1)); echo "ok    $1"; }
bad() { total=$((total + 1)); failed=$((failed + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && sed 's/^/      | /' "$2" 2>/dev/null; }
check() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3 (got '$1', wanted '$2')" "${4:-}"; fi; }
checks_done() {
    echo "----------------------------------------"
    echo "$1: $total checks, $failed failed"
    [ "$failed" -eq 0 ]
}
