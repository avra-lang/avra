#!/bin/sh
# `type_named`'s DEPENDENCY, ATTACKED — the same shape as
# tools/cache_attacks.sh: one package, built through the SAME
# `.avra-cache` across separate `avra` invocations (a `Workspace` is
# single-shot per process, CLAUDE.md's "A ONE-SHOT WORKSPACE ENDS ITS
# OWN CYCLES"), so the memo kernel's own dependency tracking is what
# is on trial, never an in-process re-ask. `Post`'s generated
# `relations()` reads `User`'s CURRENT declared fields through
# `type_named`; editing `User` must change what it prints, and an
# edit nothing reads must not.
set -u
cd "$(dirname "$0")/.."
R=build/type-named-cache-attack; fails=0; steps=0
rm -rf "$R" .avra-cache && mkdir -p $R/src
cat > $R/avra.toml <<'TOML'
[package]
name = "tn-cache-attack"
version = "0.1.0"
TOML
cat > $R/src/provider.av <<'AV'
use @std.meta.{Type, Directive, literal, type_named}
export trait Relations {
    static fn derive(t: Type) -> List<Directive> {
        let joins = [join_of(f.ty) for f in t.fields]
        [Directive { twin: "", name: t.name, at: t.at, source: quote { impl ${t} { fn relations() -> string { ${literal(joins.join("|"))} } } } }]
    }
}
fn join_of(ty: string) -> string {
    let target? = type_named(ty) else { return "absent(${ty})" }
    "found(${ty})=[${[f.name for f in target.fields].join(",")}]"
}
AV
cat > $R/src/main.av <<'AV'
use @std.meta.{derive}
use provider.{Relations}

type User = { id: int }

@derive(Relations)
type Post = { author: User }

Post { author: User { id: 1 } }.relations()
AV
ed() { python3 - "$@" <<'PY' || { fails=$((fails+1)); echo "FAIL  a fixture edit found nothing to edit: $1 <- $2"; }
import sys
p,old,new=sys.argv[1:4]; t=open(p).read(); assert old in t,(p,old); open(p,'w').write(t.replace(old,new,1))
PY
}

steps=$((steps+1)); before=$(./avra run $R 2>&1 | grep -v '^watch:')
[ "$before" = "found(User)=[id]" ] || { fails=$((fails+1)); echo "FAIL  cold build: got '$before'"; }

ed $R/src/main.av 'type User = { id: int }' 'type User = { id: int, name: string }'
ed $R/src/main.av 'User { id: 1 }' 'User { id: 1, name: "a" }'
steps=$((steps+1)); after=$(./avra run $R 2>&1 | grep -v '^watch:')
[ "$after" = "found(User)=[id,name]" ] || { fails=$((fails+1)); echo "FAIL  after widening User: got '$after' (a stale read of the crossing would still answer '$before')"; }

ed $R/src/main.av 'type Post = { author: User }' 'type Post = { author: User }
fn nobody_calls_this() -> int { 42 }'
steps=$((steps+1)); unrelated=$(./avra run $R 2>&1 | grep -v '^watch:')
[ "$unrelated" = "$after" ] || { fails=$((fails+1)); echo "FAIL  an unrelated edit changed the answer: got '$unrelated', want '$after'"; }

echo "type-named-cache-attack: $steps runs through one store, $fails failed"
[ $fails -eq 0 ]
