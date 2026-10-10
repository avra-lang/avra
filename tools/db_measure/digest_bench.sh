#!/bin/sh
# THE DIGEST'S THROUGHPUT, as the compiler runs it. From a tree's root:
#   sh tools/db_measure/digest_bench.sh
# Builds a one-file program around THIS TREE's core/digest.av (copied whole,
# never retyped) and times it natively: one 8 MB text digested whole, and
# 200 000 texts of 64, 256 and 2048 bytes each digested to a key, the shape
# a digest per saved answer has.
set -eu
A=${AVRA_BIN:-$(pwd)/build/avra}
at=${TMPDIR:-/tmp}/dbm_digest.$$
mkdir -p "$at/src"
cp packages/std-avrac/src/core/digest.av "$at/src/digest.av"
printf '[package]\nname = "dbm-digest"\nversion = "0.0.1"\n' > "$at/avra.toml"
cat > "$at/src/main.av" <<'AV'
use @std.time.{now_ns}
use digest.{digest_of, digest_text, new_digest}

fn grown(seed: string, bytes: int) -> string {
    mut out = seed
    while out.length < bytes { out = out + out }
    out
}

fn whole(bytes: int) {
    let text = grown("the quick brown fox jumps over 13 lazy dogs; ", bytes)
    let t = now_ns()
    let d = digest_text(new_digest(), text)
    let ns = now_ns() - t
    println("whole	bytes=${text.length}	ns=${ns}	MB_per_s=${text.length * 1000 / (ns + 1)}	lane=${d.a & 255}")
}

fn many(count: int, bytes: int) {
    let texts = [grown("answer ${i} ", bytes) for i in 0..1000]
    let t = now_ns()
    mut seen = 0
    for i in 0..count { seen = seen + digest_of(texts[i % 1000]).length }
    let ns = now_ns() - t
    println("keyed	count=${count}	bytes_each=${texts[0].length}	ns_each=${ns / count}	key_chars=${seen / count}")
}

whole(8000000)
many(200000, 64)
many(200000, 256)
many(200000, 2048)
AV
(cd "$at" && AVRA_MEM_CEILING_MB=5000 "$A" build . > build.log 2>&1) || { tail -n 20 "$at/build.log"; exit 1; }
bin=$(find "$at" -maxdepth 3 -type f -perm -u+x ! -name '*.av' | head -n 1)
[ -n "$bin" ] || { echo "no binary under $at"; ls -R "$at" | head -n 30; exit 1; }
"$bin"
"$bin"
rm -rf "$at"
