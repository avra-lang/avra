import sys
R='/work/avra/packages/std-avrac/src/compiler/item_rules.av'
s=open(R).read()
a="""    let alone = item_alone(engine, file, at)
    let source = new_source_file(rule_named(file), alone.text)
    let back = read_back(source.file, [PlacedTape { start: 0, tape: alone.tape }])
    found_kept(
        placed_syntax_findings(
            SyntaxFile { view: SyntaxView { store: back.store, source: source, whole: false } },
            back.stmts,
            reads_its_item,
        ),
    )"""
b="""    let alone = item_alone(engine, file, at)
    engine.kept_times()?.opened("s source", TimedSide.Query)
    let source = new_source_file(rule_named(file), alone.text)
    engine.kept_times()?.closed()
    engine.kept_times()?.opened("s read_back", TimedSide.Query)
    let back = read_back(source.file, [PlacedTape { start: 0, tape: alone.tape }])
    engine.kept_times()?.closed()
    engine.kept_times()?.opened("s rules", TimedSide.Query)
    let found = placed_syntax_findings(
            SyntaxFile { view: SyntaxView { store: back.store, source: source, whole: false } },
            back.stmts,
            reads_its_item,
        )
    engine.kept_times()?.closed()
    engine.kept_times()?.opened("s kept", TimedSide.Query)
    let kept = found_kept(found)
    engine.kept_times()?.closed()
    kept"""
assert a in s, "missing"
s=s.replace(a,b).replace("use ","use @std.program.query_times.{TimedSide}\nuse ",1)
open(R,'w').write(s); print("applied syntax")
