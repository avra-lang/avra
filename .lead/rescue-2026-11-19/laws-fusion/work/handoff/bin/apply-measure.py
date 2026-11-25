# Applies the measurement patch (fetch tally, per-law time, reach probe) to the working tree.
import re, sys
R='/work/avra/packages/std-avrac/src/'
def sub(p, a, b, n=1):
    s=open(R+p).read()
    if a not in s: sys.exit(f"MISSING in {p}: {a[:60]}")
    s=s.replace(a,b,n); open(R+p,'w').write(s)
sub('core/arena.av', "    fn node_at(i: int) -> N { self.nodes.get()[i] }", """    fn node_at(i: int) -> N {
        if fetch_on().get() { fetch_count().set(fetch_count().get() + 1) }
        self.nodes.get()[i]
    }""")
s=open(R+'core/arena.av').read()+"""
/// MEASURE: node fetches, counted while on.
export once fn fetch_count() -> Cell<int> {
    let c: Cell<int> = Cell.new(0)
    c
}

/// MEASURE: whether node fetches are counted.
export once fn fetch_on() -> Cell<bool> {
    let c: Cell<bool> = Cell.new(false)
    c
}
"""
open(R+'core/arena.av','w').write(s)
names=open('/work/avra/packages/std-avrac/src/core/node_kind.av').read()
arms=re.findall(r'NodeKind\.(\w+),', names)
s=open(R+'core/node_kind.av').read()+"\n/// MEASURE\nexport fn kind_word(k: NodeKind) -> string {\n    match k {\n"+"".join(f'        .{a} -> "{a}",\n' for a in sorted(set(arms)))+"    }\n}\n"
open(R+'core/node_kind.av','w').write(s)
sub('compiler/item_typed.av', """    written: bool = false,
) -> Checking {
    let signing = Signing {""","""    written: bool = false,
) -> Checking {
    let counting = fetch_on().get()
    fetch_on().set(false)
    let signing = Signing {""")
sub('compiler/item_typed.av', """                signed.seat ?? Seating.Body(signed.item.store.fn_parts(signed.stmt)?.name ?? ""),
            )
    }
    cx
}""","""                signed.seat ?? Seating.Body(signed.item.store.fn_parts(signed.stmt)?.name ?? ""),
            )
    }
    fetch_on().set(counting)
    cx
}""")
sub('compiler/item_typed.av', "use ", "use core.{fetch_on}\nuse ")
p='compiler/law_findings.av'
sub(p, "fn law_found(engine: QueryEngine, file: SourceFileAddress, at: int, view: ItemView?, l: LawEntry) -> List<", "fn law_found_measured(engine: QueryEngine, file: SourceFileAddress, at: int, view: ItemView?, l: LawEntry) -> List<")
sub(p, "for s in law_found(engine, file, at, view, l)]", "for s in law_found(engine, file, at, view, l)]")

sub(p, "use core.{", "use core.{fetch_on, fetch_count, kind_word, kind_of_expr, kind_of_stmt, kind_of_pat, ExprId, StmtId, PatId, ")
sub(p, "use @std.program.address", "use @std.time.{now_ns}\nuse @std.program.address")
s=open(R+p).read()+r'''
/// MEASURE: what one law finds, its fetches and time tallied.
fn law_found(engine: QueryEngine, file: SourceFileAddress, at: int, view: ItemView?, l: LawEntry) -> List<Found> {
    let was = fetch_on().get()
    fetch_on().set(true)
    let n0 = fetch_count().get()
    let t0 = now_ns()
    let found = law_found_measured(engine, file, at, view, l)
    tallied(l.name, [fetch_count().get() - n0, now_ns() - t0, 1])
    fetch_on().set(was)
    found
}

/// MEASURE
fn tallied(key: string, add: List<int>) {
    let row = law_tally().get().get(key) ?? [0 for _x in add]
    law_tally().put(key, [row[i] + add[i] for i in 0..add.length])
}

/// MEASURE: per law, its fetches, its nanoseconds and its calls.
once fn law_tally() -> Cell<Map<string, List<int>>> {
    let c: Cell<Map<string, List<int>>> = Cell.new({})
    c
}

/// MEASURE: the tally, a line a key, and the total.
export fn law_tally_said() -> string {
    let t = law_tally().get()
    let rows = [(t.get(l.name) ?? [0, 0, 0]).concat([i]) for i, l in held_laws()]
    let lines = ["law ${held_laws()[r[3]].name} ${r[0]} ${r[1] / 1000000} ${r[2]}" for r in rows]
    let others = ["tally ${k} ${row_said(t.get(k) ?? [])}" for k in t.keys() if held_laws().find(it.name == k) == null]
    lines.concat(others).join("\n") + "\nlaw TOTAL ${rows.fold(0, (a, r) -> a + r[0])} ${rows.fold(0, (a, r) -> a + r[1]) / 1000000} ${rows.fold(0, (a, r) -> a + r[2])}"
}

/// MEASURE: the law walk's reach against the item's arenas, and the kinds it leaves.
fn reach_probe(engine: QueryEngine, file: SourceFileAddress, at: int) {
    if at >= item_count(engine, file) { return }
    let item = read_item(engine, file, at)
    let store = item.store
    let walked = flatten([under(store, At.Stmt(s)) for s in item.stmts])
    mut seen: Map<string, bool> = {}
    for k in walked {
        let key = match k { .Expr(x) -> "e${x.index}", .Stmt(x) -> "s${x.index}", .Pat(x) -> "p${x.index}", .Field(o, i) -> "f${o.index}.${i}", .Param(o, i) -> "q${o.index}.${i}" }
        seen.set(key, true)
    }
    for i in 0..store.expr_count() { if !seen.has("e${i}") { tallied("~unreached ${kind_word(kind_of_expr(store.expr(ExprId { index: i })))} ${if store.home_of(ExprId { index: i }) == null { "own" } else { "homed" }}", [1]) } }
    for i in 0..store.stmts.count() { if !seen.has("s${i}") { tallied("~unreached ${kind_word(kind_of_stmt(store.stmt(StmtId { index: i })))} ${if store.stmt_origins.at(i) == null { "own" } else { "made" }}", [1]) } }
    for i in 0..store.pats.get().length { if !seen.has("p${i}") { tallied("~unreached ${kind_word(kind_of_pat(store.pat(PatId { index: i })))}", [1]) } }
}

/// MEASURE
fn row_said(r: List<int>) -> string { ["${x}" for x in r].join(" ") }
'''
open(R+p,'w').write(s)
T='/work/avra/packages/cli/src/commands/tapes.av'
s=open(T).read()
s=s.replace("""    if !said.is_empty() { println([s! for s in said].join("\\n\\n")) }
    0
}""","""    if !said.is_empty() { println([s! for s in said].join("\\n\\n")) }
    if env("AVRA_LAW_TALLY") == "1" { eprintln(law_tally_said()) }
    0
}""",1)
s=s.replace("    law_findings,\n","    law_findings,\n    law_tally_said,\n",1)
open(T,'w').write(s)
Q='/work/avra/packages/std-program/src/query_engine.av'
q=open(Q).read()
a="    fn hash_of_answer_to(asked: Question) -> ContentHash {\n"
assert a in q
q=q.replace(a, a+"        ask_count().set(ask_count().get() + 1)\n",1)
q+='''
/// MEASURE: asks answered.
export once fn ask_count() -> Cell<int> {
    let c: Cell<int> = Cell.new(0)
    c
}
'''
open(Q,'w').write(q)
L=R+'compiler/law_findings.av'
l=open(L).read()
l=l.replace("use @std.program.query_engine.{QueryDefinition, QueryEngine}","use @std.program.query_engine.{QueryDefinition, QueryEngine, ask_count}")
l=l.replace("    let n0 = fetch_count().get()\n    let t0 = now_ns()\n    let found = law_found_measured(engine, file, at, view, l)\n    tallied(l.name, [fetch_count().get() - n0, now_ns() - t0, 1])",
 "    let n0 = fetch_count().get()\n    let a0 = ask_count().get()\n    let t0 = now_ns()\n    let found = law_found_measured(engine, file, at, view, l)\n    tallied(l.name, [fetch_count().get() - n0, now_ns() - t0, 1, ask_count().get() - a0])")
l=l.replace('    let rows = [(t.get(l.name) ?? [0, 0, 0]).concat([i]) for i, l in held_laws()]\n    let lines = ["law ${held_laws()[r[3]].name} ${r[0]} ${r[1] / 1000000} ${r[2]}" for r in rows]',
 '    let rows = [(t.get(l.name) ?? [0, 0, 0, 0]).concat([i]) for i, l in held_laws()]\n    let lines = ["law ${held_laws()[r[4]].name} ${r[0]} ${r[1] / 1000000} ${r[2]} ${r[3]}" for r in rows]')
l=l.replace("+ \"\\nlaw TOTAL ${rows.fold(0, (a, r) -> a + r[0])} ${rows.fold(0, (a, r) -> a + r[1]) / 1000000} ${rows.fold(0, (a, r) -> a + r[2])}\"",
 "+ \"\\nlaw TOTAL ${rows.fold(0, (a, r) -> a + r[0])} ${rows.fold(0, (a, r) -> a + r[1]) / 1000000} ${rows.fold(0, (a, r) -> a + r[2])} ${rows.fold(0, (a, r) -> a + r[3])}\"")
a2="    let view = if at < item_count(engine, file) { item_view(engine, file, at) } else { null }\n"
assert a2 in l
l=l.replace(a2, a2+"    walk_timed(view)\n",1)
l+='''
/// MEASURE: the item's walk, timed apart.
fn walk_timed(view: ItemView?) {
    let v? = view else { return }
    let n0 = fetch_count().get()
    let was = fetch_on().get()
    fetch_on().set(true)
    let t0 = now_ns()
    let _w = v.walked()
    tallied("~walk", [fetch_count().get() - n0, now_ns() - t0, 1])
    fetch_on().set(was)
}
'''
open(L,'w').write(l)
print("applied")
