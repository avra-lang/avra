cat > /tmp/b3.av <<'P'
use @std.hash.{blake3_hex}
use @std.io.{read_bytes}
println(blake3_hex(read_bytes("packages/std-ui/assets/webref_events.json") catch "".bytes()))
P
build/avra run /tmp/b3.av
