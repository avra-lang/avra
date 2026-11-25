#!/bin/sh
# scratch probes for the flat-link defect; removed before landing
set -u
cd "$(dirname "$0")"
d=packages/std-db/src/tests

run() {
    printf '\n== %s ==\n' "$1"
    ./build/avra-try check "$1" > /tmp/probe.out 2>&1
    code=$?
    sed 's/^/   /' /tmp/probe.out
    printf '   [exit %s]\n' "$code"
}

write_a() {
    cat > $d/probe_a.av <<'EOF'
use @std.db.{model}

@model
type P = {
    id: int = 0,
}
EOF
}

write_b() {
    cat > $d/probe_b.av <<'EOF'
use @std.db.{model}

@model
type P = {
    id: int = 0,
    name: string,
}

@model
type C = {
    id: int = 0,
    x: P? = null,
}
EOF
}

write_c() {
    cat > $d/probe_c.av <<'EOF'
use @std.db.{model}

@model
type P = {
    id: int = 0,
}

@model
type C = {
    id: int = 0,
    x: P,
}
EOF
}

write_d() {
    cat > $d/probe_d.av <<'EOF'
use @std.db.{model}

@model
type P = {
    id: int = 0,
}

impl P {
    mut fn bump() {
        self.id = self.id + 1
    }
}
EOF
}

write_a
write_b
write_c
write_d

for f in $d/flat_link_repro.av $d/probe_a.av $d/probe_b.av $d/probe_c.av $d/probe_d.av; do run "$f"; done
rm -f $d/probe_a.av $d/probe_b.av $d/probe_c.av $d/probe_d.av
