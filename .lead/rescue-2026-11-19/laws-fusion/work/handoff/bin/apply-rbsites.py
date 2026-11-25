# Measurement only: every read-back site timed apart (needs apply-tapetimes first).
import sys
R='/work/avra/packages/std-avrac/src/compiler/'
sites=[('item_signatures.av',"    let stmts = item_read_back(store, placed)","    let stmts = rb_at(\"item_whole\", store, placed)"),
('item_signatures.av',"    item_read_back(store, placed_item(engine, file, item_under(engine, file, at), start))","    rb_at(\"read_into\", store, placed_item(engine, file, item_under(engine, file, at), start))"),
('item_expanded.av',"    let stmts = item_read_back(store, PlacedTape { start: 0, tape: tape })","    let stmts = rb_at(\"expanded\", store, PlacedTape { start: 0, tape: tape })"),
('item_generated.av',"    let stmts = item_read_back(store, PlacedTape { start: 0, tape: tape })","    let stmts = rb_at(\"generated\", store, PlacedTape { start: 0, tape: tape })"),
('item_generators.av',"    let stmts = item_read_back(store, PlacedTape { start: 0, tape: tape })","    let stmts = rb_at(\"generators\", store, PlacedTape { start: 0, tape: tape })"),
('item_tapes.av',"    let stmts = [s for p in placed for s in item_read_back(store, p)]","    let stmts = [s for p in placed for s in rb_at(if placed.length > 1 { \"read_back file\" } else { \"read_back item\" }, store, p)]"),
('item_expansions.av',"    item_read_back(store, PlacedTape { start: 0, tape: item_tape(engine, item_text, context) })","    rb_at(\"written_back\", store, PlacedTape { start: 0, tape: item_tape(engine, item_text, context) })"),
('item_expansions.av',"    let stmts = item_read_back(store, p)\n    MarkedItem","    let stmts = rb_at(\"marked\", store, p)\n    MarkedItem"),
('item_expansions.av',"    let stmts = item_read_back(store, PlacedTape { start: 0, tape: tape })","    let stmts = rb_at(\"generated_expanded\", store, PlacedTape { start: 0, tape: tape })")]
for f,a,b in sites:
    s=open(R+f).read()
    if a not in s: sys.exit("MISSING "+f+": "+a[:60])
    open(R+f,'w').write(s.replace(a,b,1))
s=open(R+'item_tapes.av').read()+'''
/// MEASURE
export fn rb_at(site: string, store: SyntaxArena, p: PlacedTape) -> List<StmtId> {
    let t0 = now_ns()
    let stmts = item_read_back(store, p)
    tape_tallied("rb " + site, now_ns() - t0, 0)
    stmts
}
'''
open(R+'item_tapes.av','w').write(s)
print("applied rb sites")
