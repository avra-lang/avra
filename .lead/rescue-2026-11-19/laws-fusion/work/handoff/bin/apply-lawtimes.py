# Measurement only: each law timed as its own family on the engine's query clock; tapes dumps every family.
import sys
R='/work/avra/packages/'
def sub(p,a,b):
    s=open(R+p).read()
    if a not in s: sys.exit("MISSING in "+p+": "+a[:70])
    open(R+p,'w').write(s.replace(a,b,1))
p='std-avrac/src/compiler/law_findings.av'
sub(p,"for s in law_found(engine, file, at, view, l)]","for s in law_timed(engine, file, at, view, l)]")
sub(p,"use @std.program.query_engine.{","use @std.program.query_times.{TimedSide}\nuse @std.program.query_engine.{")
s=open(R+p).read()+'''
/// MEASURE: a law timed as its own family.
fn law_timed(engine: QueryEngine, file: SourceFileAddress, at: int, view: ItemView?, l: LawEntry) -> List<Found> {
    engine.kept_times()?.opened("law " + l.name, TimedSide.Query)
    let found = law_found(engine, file, at, view, l)
    engine.kept_times()?.closed()
    found
}
'''
open(R+p,'w').write(s)
T='cli/src/commands/tapes.av'
sub(T,"""    if !said.is_empty() { println([s! for s in said].join("\\n\\n")) }
    0
}""","""    if !said.is_empty() { println([s! for s in said].join("\\n\\n")) }
    if env("AVRA_LAW_TALLY") == "1" { for f in engine.kept_times()?.by_own_time() ?? [] { eprintln("fam ${f.family} ${f.own / 1000000} ${f.whole / 1000000} ${f.asks}") } }
    0
}""")
print("applied")
