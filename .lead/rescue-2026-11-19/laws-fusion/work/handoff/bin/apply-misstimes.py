import sys
R='/work/avra/packages/std-avrac/src/compiler/item_members.av'
s=open(R).read()
def sub(a,b):
    global s
    if a not in s: sys.exit("MISSING: "+a[:70])
    s=s.replace(a,b,1)
sub("""    let landed = generic_method_miss(engine, t, e)
        .concat(shape_misses(engine, t, e, scope))
        .concat(hash_miss(engine, t, e))
        .concat(call_spread_misses(engine, t, e))
        .concat(variant_read_miss(engine, t, e))
    if (t.type_at)(e.index) != null { return literal_miss(engine, t, e).concat(variadic_miss(engine, t, e)).concat(landed) }""",
"""    let landed = mt(engine, "m generic", () -> generic_method_miss(engine, t, e))
        .concat(mt(engine, "m shape", () -> shape_misses(engine, t, e, scope)))
        .concat(mt(engine, "m hash", () -> hash_miss(engine, t, e)))
        .concat(mt(engine, "m spread", () -> call_spread_misses(engine, t, e)))
        .concat(mt(engine, "m variant", () -> variant_read_miss(engine, t, e)))
    if (t.type_at)(e.index) != null { return mt(engine, "m literal", () -> literal_miss(engine, t, e)).concat(mt(engine, "m variadic", () -> variadic_miss(engine, t, e))).concat(landed) }""")
sub("""    let inferred = indexed(""","""    engine.kept_times()?.opened("m inferred", TimedSide.Query)
    let inferred = indexed(""")
sub("""    let scope = MissScope {""","""    engine.kept_times()?.closed()
    let scope = MissScope {""")
s=s.replace("use compiler.laws.{","use @std.program.query_times.{TimedSide}\nuse compiler.laws.{",1)
s+='''
/// MEASURE
fn mt(engine: QueryEngine, name: string, f: fn() -> List<MissPlaced>) -> List<MissPlaced> {
    engine.kept_times()?.opened(name, TimedSide.Query)
    let r = f()
    engine.kept_times()?.closed()
    r
}
'''
open(R,'w').write(s); print("applied misses")
