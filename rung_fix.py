import sys
p='packages/std-avrac/src/features/builder.av'
t=open(p).read()
if 'fn trailed(' in t: sys.exit(0)
anchor="    /// The span from the first statement's start to the last one's end."
assert t.count(anchor)==1
t=t.replace(anchor,"""    /// A head widened by its trailing blocks, at this build's place.
    fn trailed(h: ExprId, blocks: List<ExprId>) -> Result<ExprId, string> {
        self.store.trailed(h, blocks, self.node_span())
    }

"""+anchor)
open(p,'w').write(t)
