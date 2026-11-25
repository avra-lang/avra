h=$1; shift
exec "${AVRA_SPRITE_CLI:-sprite}" -s "$h" exec --no-port-forward -- "$@"
