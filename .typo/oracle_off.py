p='packages/std-avrac/src/compiler/derive.av'
s=open(p).read()
a="        if held is .Ok || !first.held { return held }\n"
assert a in s
open(p,'w').write(s.replace(a,"        if true { return held }\n"+a,1))
