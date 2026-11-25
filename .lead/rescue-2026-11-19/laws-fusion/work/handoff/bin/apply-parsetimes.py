# Measurement only: a parse's lexing, grammar run (its node builds apart), the rest, and its settle. Needs apply-tapetimes.
import sys
R='/work/avra/packages/std-avrac/src/compiler/program.av'
s=open(R).read()
def sub(a,b):
    global s
    if a not in s: sys.exit("MISSING: "+a[:70])
    s=s.replace(a,b,1)
sub("""    let p = if quiet.voices.list.is_empty() { quiet } else { parsed_fresh(lang, src, words, true) }""",
"""    let p = if quiet.voices.list.is_empty() { quiet } else {
        tape_tallied("p told again", 0, src.text.length)
        parsed_fresh(lang, src, words, true)
    }""")
sub("""    let lexed = lexed_under(src.text, words_lexed(words), lang.keywords)""","""    let tl = now_ns()
    let lexed = lexed_under(src.text, words_lexed(words), lang.keywords)
    tape_tallied("p lex", now_ns() - tl, lexed.tokens.length)""")
sub("""    let build = (name: string, args: List<Captured<Token, LangNode>>, loc: Loc?) -> build_named(""","""    let build = (name: string, args: List<Captured<Token, LangNode>>, loc: Loc?) -> built_timed(() -> build_named(""")
sub("""        src.text,
        door,
    )
    let o = if telling""","""        src.text,
        door,
    ))
    let tg = now_ns()
    let o = if telling""")
sub("""    // a remark means nothing to any pass; it rides the store so the""","""    tape_tallied("p grammar+build", now_ns() - tg, store.exprs.count())
    let tr = now_ns()
    // a remark means nothing to any pass; it rides the store so the""")
sub("""        .concat(store.hoisted_decls())
    store.settle_prints()""","""        .concat(store.hoisted_decls())
    tape_tallied("p after", now_ns() - tr, 0)
    let ts = now_ns()
    store.settle_prints()
    tape_tallied("p settle", now_ns() - ts, 0)""")
s=s.replace("use ","use @std.time.{now_ns}\nuse ",1)
s+='''
/// MEASURE
fn built_timed<T>(f: fn() -> T) -> T {
    let t = now_ns()
    let r = f()
    tape_tallied("p build", now_ns() - t, 1)
    r
}
'''
open(R,'w').write(s); print("applied parse")
s=open(R).read()
a="""    ) -> build_row(generated.rows[ix], avra_builders[ix], store, args, loc_span(loc), text, door)
    avra_untold(
        tokens,
        avra_lexeme(),
        avra_token_tables(tokens, avra_lits(), generated.kinds, generated.worn),
        generated.kinds,
        by_index,
    )"""
b="""    ) -> built_row_timed(() -> build_row(generated.rows[ix], avra_builders[ix], store, args, loc_span(loc), text, door))
    let tt = now_ns()
    let tables = avra_token_tables(tokens, avra_lits(), generated.kinds, generated.worn)
    tape_tallied("p token tables", now_ns() - tt, tokens.length)
    let tu = now_ns()
    let run = avra_untold(tokens, avra_lexeme(), tables, generated.kinds, by_index)
    tape_tallied("p untold run (with rows)", now_ns() - tu, tokens.length)
    run"""
assert a in s, "quietly missing"
s=s.replace(a,b,1)
s+='''
/// MEASURE
fn built_row_timed<T>(f: fn() -> T) -> T {
    let t = now_ns()
    let r = f()
    tape_tallied("p build_row", now_ns() - t, 1)
    r
}
'''
open(R,'w').write(s); print("applied quietly split")
