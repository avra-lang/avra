# Measurement only: the parts of reading an item to its tape, and of reading a tape back, timed.
import sys
R='/work/avra/packages/'
def sub(p,a,b):
    s=open(R+p).read()
    if a not in s: sys.exit("MISSING in "+p+": "+a[:70])
    open(R+p,'w').write(s.replace(a,b,1))
p='std-avrac/src/compiler/item_tapes.av'
sub(p,"""    let parsed = parse_program(avra(), new_source_file("<item>", item_text), context_words(context))
    tape_of_item(parsed.store, [s for s in parsed.stmts if !parsed.store.is_hoisted(s)])""","""    let t0 = now_ns()
    let words = context_words(context)
    let t1 = now_ns()
    let parsed = parse_program(avra(), new_source_file("<item>", item_text), words)
    let t2 = now_ns()
    let tape = tape_of_item(parsed.store, [s for s in parsed.stmts if !parsed.store.is_hoisted(s)])
    let t3 = now_ns()
    tape_tallied("context", t1 - t0, context.length)
    tape_tallied("parse", t2 - t1, item_text.length)
    tape_tallied("tape", t3 - t2, parsed.store.expr_count())
    tape""")
sub(p,"""    let since = store.marks()
    let reader = tape_reader(p.tape, p.start)
    let stmts = [Stmt.untaped_id(store, reader) for _s in 0..reader.count()]
    SyntaxArena.untape_item_tables(store, reader)
    store.settled_since(since)
    stmts""","""    let t0 = now_ns()
    let since = store.marks()
    let reader = tape_reader(p.tape, p.start)
    let stmts = [Stmt.untaped_id(store, reader) for _s in 0..reader.count()]
    SyntaxArena.untape_item_tables(store, reader)
    store.settled_since(since)
    tape_tallied("readback", now_ns() - t0, 0)
    stmts""")
s=open(R+p).read()+'''
/// MEASURE
once fn tape_tally() -> Cell<Map<string, List<int>>> {
    let c: Cell<Map<string, List<int>>> = Cell.new({})
    c
}

/// MEASURE
fn tape_tallied(key: string, ns: int, size: int) {
    let row = tape_tally().get().get(key) ?? [0, 0, 0]
    tape_tally().put(key, [row[0] + ns, row[1] + 1, row[2] + size])
}

/// MEASURE
export fn tape_tally_said() -> string {
    [\"tape ${k} ${(tape_tally().get().get(k) ?? [0, 0, 0])[0] / 1000000} ms ${(tape_tally().get().get(k) ?? [0, 0, 0])[1]} calls ${(tape_tally().get().get(k) ?? [0, 0, 0])[2]} size\" for k in tape_tally().get().keys()].join(\"\\n\")
}
'''
s=s.replace("use ","use @std.time.{now_ns}\nuse ",1)
open(R+p,'w').write(s)
T='cli/src/commands/tapes.av'
sub(T,"""    if env("AVRA_LAW_TALLY") == "1" { for f in""","""    if env("AVRA_LAW_TALLY") == "1" { eprintln(tape_tally_said()) }
    if env("AVRA_LAW_TALLY") == "1" { for f in""")
s=open(R+T).read()
s=s.replace("use @std.avrac.compiler.{\n","use @std.avrac.compiler.{\n    tape_tally_said,\n",1)
open(R+T,'w').write(s)
print("applied tapes")
