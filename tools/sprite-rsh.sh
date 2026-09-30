h=$1; shift
exec sprite -s "$h" exec --no-port-forward -- "$@"
