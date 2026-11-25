# avra-lane-spec-harness — first hand-back (group 1: lone-source helpers on the program layer)

Base: program 9b45b993. Branch avra-lane-spec-harness, 1 commit.

## What changed
- `packages/std-avrac/src/compiler/item_said.av` (new): `ProgramFile`, `file_refusals`, `file_law_diags` — the diagnostics of a refused file, moved out of cli/tapes.av; tapes.av and check_program.av call it.
- `packages/std-avrac/src/testing/held.av` (new): `Held` (files by path, package roots, in-memory SourceWorld, StoreInMemory) -> `judged(entry)` -> `Judged { diagnostics }` with report/clean/run/ran/check/made. `held_alone(source)`: a package of one file said as `<source>`, the whole prelude package (src + verbs/**) embedded beside it.
- `testing/mod.av`: shown / refusals / refused_with / refused_at_run answer on the layer; `judged(source)` added. `ir_of` and the package helpers (provided, floored, test_workspace, said, refused_in/_n, answered) are still on the old path — groups 2 and 3.
- 70 spec files: `analyze_source` -> `judged` (import + call; nothing else). `testing/tests/held_test.av` (new, 12 cases).
- refused_at_run: the layer has no "analysis clean, lowering refuses" stage (a const trapping while settling is `const.trap` among the build's diagnostics). It is now "at most one diagnostic, and the run refuses saying the phrase".

## Running table (per spec directory, layer harness, no net; the differential ran old and new on every program)
Format: directory, failing cases, passed/total. "TRAP" = the suite process died inside the layer at that case, the rest of that directory never ran.
src/compiler/tests  2 failing  1867/1869
src/core/tests  0 failing  357/357
src/features/annotations/tests  10 failing  181/191
src/features/block/tests  0 failing  29/29
src/features/bool_lit/tests  0 failing  9/9
src/features/bytes/tests  25 failing  121/146
src/features/cells/tests  8 failing  15/23
src/features/closures/tests  45 failing  411/456
src/features/collects/tests  0 failing  105/105
src/features/components/tests  4 failing  1
src/features/consts/tests  13 failing  1
src/features/defers/tests  2 failing  104/106
src/features/enums/tests  34 failing  445/479
src/features/expr_spine/tests  24 failing  725/749
src/features/expr_stmt/tests  0 failing  14/14
src/features/floats/tests  0 failing  0
src/features/fns/tests  44 failing  786/830
src/features/formats/tests  18 failing  185/203
src/features/grammar_lit/tests  0 failing  35/35
src/features/if_expr/tests  2 failing  20/22
src/features/impls/tests  69 failing  645/714
src/features/ints/tests  0 failing  0
src/features/let_stmt/tests  2 failing  109/111
src/features/lists/tests  34 failing  1
src/features/loops/tests  6 failing  75/81
src/features/maps/tests  16 failing  1
src/features/modules/tests  0 failing  86/86
src/features/mutation/tests  11 failing  80/91
src/features/narrows/tests  0 failing  14/14
src/features/nullable/tests  34 failing  387/421
src/features/quote/tests  1 failing  149/150
src/features/ranges/tests  3 failing  11/14
src/features/results/tests  25 failing  60/85
src/features/select_expr/tests  2 failing  75/77
src/features/specs/tests  0 failing  79/79
src/features/stmt_spine/tests  2 failing  37/39
src/features/str_lit/tests  4 failing  53/57
src/features/structs/tests  37 failing  0
src/features/sublang/tests  0 failing  67/67
src/features/tables/tests  7 failing  91/98
src/features/tasks/tests  8 failing  60/68
src/features/tests  8 failing  337/345
src/features/type_expr/tests  3 failing  45/48
src/features/when_expr/tests  2 failing  25/27
src/testing/tests  0 failing  12/12

Totals over the directories that reported: 7910 / 8307 cases pass on the layer; 505+ fail (structs 37 more, no total printed). Before the move every one of these passed on the old path.

## TRAPS — the layer kills the process (each stops a whole suite)
1. `component component ( x : x , x : x , ) { x : x = x }` (components_mechanical_test.av:168): "`record_signature` (…component) was asked while it was being answered, under program_refused -> file_erring -> law_findings -> item_refusals -> record_signature -> resolved -> generated_names -> file_generated".
2. `const X: int = X` read through a fn (consts_adversarial_test.av:232): "`const_settlement` (…X) was asked while it was being answered, under program_refused -> file_erring -> law_findings -> const_settlement -> unit_facts -> lowered_under".
3. `[1].get()` (lists/fold_get_adversarial_test.av:88): "index 0 is out of bounds (length 0)" — a layer law indexes a call's arguments unguarded.
4. `let m = { "a": 1 }\nm.entries(1)\n0` (maps_test.av:224): "index 1 is out of bounds (length 1)".

## WRONG ANSWERS — the layer builds and runs the program to a different value (old value first)
- `type C = { n: int }\nlet set: fn(mut C) -> int = (mut c: C) -> { c.n = 5\n c.n }\nmut c = C { n: 1 }\n"${set(c)} ${c.n}"` : `5 5` vs layer `5 1` (a `mut` seat through a fn value does not write back).
- index evaluated twice under a `mut fn` call through an indexed place: `7 0 i v` vs `7 0 i v i`; `7 0 a b v` vs `7 0 a b v a b` (impls tests).
- `mut n = 0\nfor x in [1, 2, 3] { while if x == 2 { break } else { false } { n = n + 100 }\n n = n + x }\nn` : `1` vs layer `6` (a `break` in a `while` condition leaves the inner loop, not the outer).
- `type Maybe = string?\nlet m: Maybe = "hi"\nm ?? "none"` : `hi` vs layer empty text.
- `match C.red { .red -> 1  .green -> true  .blue -> 3 }` : old type.match; layer builds it and LLVM verification fails (PHI operands).

781 distinct differing programs

## OLD SAYS, LAYER SILENT (kind, distinct programs)
 169 type.mismatch   e.g. 'let b = [1].bytes()!\nb.at("0")'
  71 resolve.unresolved   e.g. '@std ( x , ) \n x'
  54 type.lambda   e.g. '[1].map(it(3))\n2'
  25 type.unknown_prop   e.g. 'enum Slot<T> { Gone, Here(T) }\nenum Other<T> { None, Some(T) }\nlet c: Cell<Slot<int>> = Cell.new(Other.None)\n1'
  24 type.variant_lit   e.g. 'enum T { A, B }\ntype M = T\nlet m: M = M(T.B)\nm == .B'
  24 resolve.unpackaged   e.g. 'use @std . { \n x as x , \n x as x , \n } \n'
  18 type.method   e.g. 'type C = { n: int }\nimpl C {\n    fn go(f: fn(int) -> int) -> int { f(self.n) }\n    fn use_self() -> int { self.go { self -> self } }\n}\
  16 type.struct_fields   e.g. 'type B<T> = { v: T = 1 }\n2'
  16 type.trait   e.g. 'type Text = { content: string }\ntype Button = { label: string }\ntype Html = { tag: string = "" }\ntrait Realize<T> {\n    fn draw(t: T) -
  13 type.list_element   e.g. 'fn f(xs: List<int>) -> int {\n    let c: List<int?> = [null, ..xs]\n    1\n}\n'
  13 type.propagate   e.g. 'type U = { n: int }\nfn g(u: U) -> U? {\n    u\n}\nfn f(us: List<U>) -> U? {\n    us.map(g(it)?)[0]\n}\nf([U { n: 1 }])'
  11 type.catch   e.g. '! x * ! x + ! x * ! x | ! x * ! x + ! x * ! x ?? ! x * ! x + ! x * ! x | ! x * ! x + ! x * ! x == ! x * ! x + ! x * ! x | ! x * ! x + ! x *
  10 resolve.receiver   e.g. 'type P = { x: int }\nimpl P { fn m(k: int = self.x) -> int { k } }\nP { x: 3 }.m()'
   9 type.match   e.g. 'enum R {\n    Ok(v: int)\n    Bad\n}\nfn f(xs: List<R>) -> List<int> {\n    xs.map { .Ok(v) -> v }\n}\n1'
   8 type.seat   e.g. 'fn writes(mut xs: List<int>, v: int) -> int {\n    xs.push(v)\n    xs.length\n}\nlet g: fn(mut List<int>, int) -> int = writes\nlet ys = [1
   8 type.defer_inert   e.g. 'defer x'
   7 type.pattern   e.g. 'fn f(r: Bytes?) -> int {\n    match r {\n        "a" -> 1\n        _ -> 0\n    }\n}\nf(null)'
   7 type.binding   e.g. 'let f: fn(int) -> bool = (x) -> x + 1\n2'
   7 type.fail   e.g. 'fn res(f: fn() -> Result<int, string>) -> Result<int, string> { f() }\nfn body() -> Result<int, string> { res { fail "no" } }\nbody()'
   6 type.place   e.g. 'mut b = [1].bytes()!\nb.length = 3\nb.length'
   6 type.alias_copy   e.g. 'let c = Cell.new([1])\nmut snapshot = c.get()\nsnapshot.push(2)\nc.get().length'
   6 type.unknown   e.g. '( const mut x : fn ( const mut x , const mut x , ) -> x , ) -> x'
   6 resolve.reserved   e.g. 'fn run(f: fn() -> int) -> int { f() }\nfn apply(v: int, f: fn(int) -> int) -> int { f(v) }\nfn both(a: int, b: int, f: fn(int, int) -> int)
   4 type.named_arg   e.g. 'x ( x : x , x : x , ) { x : x = x } \n'
   4 resolve.immutable   e.g. 'type P = { x: int }\nconst K = P { x: 1 }\nK.x = 2\nK.x'
   4 type.type_value   e.g. 'enum Sp { Int, Str, Bool, Opt(inner: Sp), List(elem: Sp), Map(k: Sp, v: Sp), Res(ok: Sp, err: Sp), Fn(ps: List<Sp>, muts: List<bool>, const
   3 type.list_scalar   e.g. 'let c = Cell.new(null)\n1'
   3 type.spread_field   e.g. 'type Z = { w: int, z: int }\nfn f(w: int) -> int { w }\nf(..Z { w: 1, z: 2 })'
   3 type.impl   e.g. 'trait Show {\n    fn show() -> int\n}\ntype Box<T> = { v: T }\nimpl Show for Box<int> {\n    fn show() -> int { 1 }\n}\n2'
   3 type.applied   e.g. 'enum E {\n    boom\n}\nfn f() -> Result<void, E> {\n    fail E.boom\n}\n2'
   2 type.return   e.g. 'fn f() -> int {\n    let g = (v: int) -> if v > 0 {\n        return v\n    } else {\n        0\n    }\n    g(1)\n}\nf()'
   2 type.component_event   e.g. 'component C {\n    on x(a)\n}\n1'
   2 build.failed   e.g. 'component x ( x : x , x : x , ) { x x : x = x } \n'
   2 type.interp_hole   e.g. 'enum E {\n    a(int)\n    b\n}\nlet v = E.a(1)\n"x${v}"'
   2 type.with_struct   e.g. 'enum E {\n    a(int)\n    b\n}\nE.b with { x: 1 }'
   2 type.tparam   e.g. 'enum Bad<int> {\n    a(int)\n}\n1'
   2 type.trait_member   e.g. 'trait T {\n    fn m(a: int = 1) -> int\n}\ntype P = { x: int }\nimpl T for P {\n    fn m(a: int = 5) -> int { self.x + a }\n}\nP { x: 2 }.m
   2 type.variadic   e.g. 'fn f(a: int, ..r: List<int>) -> int {\n    a * 1000 + r.length * 100 + r.fold(0, (s, x) -> s + x)\n}\nf(a: 1, 2)'
   2 type.map_entry   e.g. 'let m = { "a": 1 }\nm.any(it.value > 0)'
   2 type.match_opt   e.g. 'type User = { age: int }\nfn find_user(id: int) -> User? { if id == 7 { User { age: 30 } } else { null } }\nif let u? = find_user(7) {\n   
   2 type.coalesce   e.g. 'fn some(v: int) -> int? { v }\nfn none() -> int? { null }\nnone() ?? none() ?? "z"'
   2 type.alias   e.g. 'alias A = List<A>\n1'
   2 type.named   e.g. 'type X = X\nlet x: X = 1\nx.of'
   2 type.within   e.g. 'type Lim = { ms: int }\nfn spin() {\n    let _n = 1\n}\nlet x = within Lim { ms: 5 } { spin() }\n0'
   1 annotation.unread_mark   e.g. 'enum E { @@m A(x: int) }\n0'
   1 type.component_body   e.g. 'component x ( x : x , x : x , ) { { x : x = x } \n'
   1 type.enum_all   e.g. 'enum P { A, B(int) }\nlet p = P.A\np.all().length'
   1 type.or_binds   e.g. 'enum Q {\n    A(v: int)\n    B(v: string)\n}\nmatch Q.A(1) {\n    .A(v) or .B(v) -> 1\n}'
   1 resolve.runtime_binding   e.g. 'type P = { x: int }\nlet k = 3\nimpl P {\n    fn m() -> int {\n        k\n    }\n}\nP { x: 1 }.m()'
   1 type.const_seat   e.g. 'fn takes(const x: int) -> int {\n    x + 1\n}\nlet g: fn(const int) -> int = takes\nlet v = 5\ng(v)'
   1 type.isolated   e.g. 'fn run(isolated make: fn() -> int) -> int { make() }\nfn f() -> int { 1 }\nlet g = f\nrun(() -> g())'
   1 type.spread_dead   e.g. 'type O = { w: int, h: int }\nfn area(w: int, h: int = 1) -> int { w * h }\narea(2, ..O { w: 3, h: 4 })'
   1 type.spread_value   e.g. 'type O = { w: int, h: int }\nfn area(w: int, h: int = 1) -> int { w * h }\narea(..5)'
   1 type.spread_nullable   e.g. 'type O = { w: int, h: int }\nfn area(w: int, h: int = 1) -> int { w * h }\nlet o: O? = null\narea(..o)'
   1 type.binds_twice   e.g. 'enum S {\n    A(int, int)\n    B\n}\nfn f(s: S) -> int {\n    if s is .A(w, w) { 1 } else { 0 }\n}\nf(S.B)'
   1 type.param_default   e.g. 'trait Grows {\n    fn grown(by: int = "x") -> int\n}\n1'
   1 type.variant_arity   e.g. 'enum E { all, B }\nlet x = [c.ordinal for c in E.all()]\nx.length'
   1 resolve.paired   e.g. '[x for a in [1, 2] for x, x in [3, 4]]'
   1 type.list   e.g. '[i for j, i in 0..3]'
   1 type.record_pattern   e.g. 'type P = { x: int, y: int }\nfn f(p: P) -> int {\n    let P { x } = p\n    x\n}\n1'
   1 type.list_pattern   e.g. 'fn f(n: int) -> int {\n    let [h, ..] = n else { return 0 }\n    h\n}\n1'
   1 loop.label   e.g. 'for x in [1] {\n    let f = () -> {\n        for y in [2] {\n            break x\n        }\n    }\n}\n1'
   1 loop.jump   e.g. 'while if true { break } else { false } {\n    1\n}\n1'
   1 type.map_value   e.g. 'let m = {}\nm.keys()\n0'
   1 type.coalesce_never   e.g. 'let n = 3\nn ?? 4'
   1 type.chain   e.g. 'null?.age'
   1 type.spread_seat   e.g. 'enum E {\n    P(int, int)\n}\nlet xs = [1, 2]\nlet e: E = .P(..xs)\n1'
   1 type.infer_result   e.g. 'type E = { msg: string }\nfn f(xs: List<E>) -> Result<int, _> {\n    fail xs.first()!\n}'
   1 flow.spent_arm   e.g. 'fn one() -> int {\n    1\n}\nfn hush() {\n}\nlet job = spawn one()\nlet mute = spawn hush()\nlet jobs = [spawn one(), spawn one()]\nlet all
   1 flow.select   e.g. 'fn one() -> int {\n    1\n}\nfn hush() {\n}\nlet job = spawn one()\nlet mute = spawn hush()\nlet jobs = [spawn one(), spawn one()]\nlet v =
   1 type.task_escape   e.g. 'let t = spawn { spawn 1 }\n1'
   1 type.when_arms   e.g. 'when {\n    _ -> 9\n    2 < 3 -> 1\n}'

## LAYER SAYS, OLD SILENT
  52 lower.no_projection   e.g. '"ab".bytes()'
  39 type.method   e.g. 'let b = [1].bytes()!\nb.at("0")'
  22 resolve.not_a_dependency   e.g. 'use @std . x . { \n x as x , \n x as x , \n } \n'
  18 type.mismatch   e.g. 'let f: fn(int) -> bool = (x) -> x + 1\n2'
  12 type.binding   e.g. 'fn f(xs: List<int>) -> int {\n    let c: List<int?> = [null, ..xs]\n    1\n}\n'
  10 annotation.callee   e.g. '@std ( x , ) \n x'
   4 resolve.unresolved   e.g. '( @std x , x , ) \n x'
   4 type.duplicate_field   e.g. 'component x ( x : x , x : x , ) { x x = x } \n'
   4 type.const_pattern   e.g. 'const tab = 9\nconst escape = 27\nfn f(c: int, tab: int) -> int {\n    match c {\n        tab -> tab\n    }\n}\nf(5, 1)'
   3 parse.expected   e.g. '@std @std ( x , x , ) \n x'
   2 type.unreachable_arm   e.g. 'const tab = 9\nconst escape = 27\nfn f(c: int) -> int {\n    const bell = 7\n    match c {\n        bell -> 1\n        _ -> 0\n    }\n}\nf(
   2 type.format   e.g. 'type Id = string\nlet i: Id = "k-1"\nmatch i {\n    "k-{n}" -> n\n    _ -> "none"\n}'
   1 const.budget   e.g. 'fn d(n: int) -> int { 1 + d(n + 1) }\nconst D: int = d(0)\nD'
   1 const.reach   e.g. 'extern fn avra_puts(s: string)\nfn g() -> int {\n    avra_puts("x")\n    1\n}\nfn f() -> int {\n    g() + 1\n}\nconst X = f()\nX'
   1 flow.unbounded_cleanup   e.g. 'extern fn avra_puts(s: string)\nextern fn avra_fiber_sleep(ms: int)\nfn clean() {\n    defer avra_fiber_sleep(1)\n}\nclean()'
   1 type.variant_arity   e.g. 'enum E {\n    a(int or string), b\n}\nmatch E.a(3) {\n    .a(v) -> 1\n    .b -> 0\n}'
   1 type.match   e.g. 'enum E {\n    a(int)\n    b\n}\nmatch E.a(1) {\n    .a(n) -> match n { .a(m) -> m, .b -> 0 }\n    .b -> 0\n}'
   1 type.place   e.g. 'let xs = [1]\nxs.push(v: 2)\n0'
   1 resolve.use_before_def   e.g. 'type P = { x: int }\nlet k = 3\nimpl P {\n    fn m() -> int {\n        k\n    }\n}\nP { x: 1 }.m()'
   1 type.host_seat   e.g. 'extern fn g(xs: List<i32>) -> int\ng([1])'
   1 const.param   e.g. 'fn f(x: int) -> int {\n    const y = x + 1\n    y\n}\nf(3)'
   1 type.list_element   e.g. 'fn f(a: int, ..r: List<int>) -> int {\n    a * 1000 + r.length * 100 + r.fold(0, (s, x) -> s + x)\n}\nf(1, ..["s"])'
   1 type.seat_unused   e.g. 'type C = { n: int }\nimpl C {\n    mut fn bump(mut self) { self.n = 1 }\n}\n2'
   1 type.unknown   e.g. 'trait Realize<T> {\n    fn draw(t: T) -> string\n}\ntype Text = { content: string }\ntype Button = { label: string }\ntype Plain = { tag: s
   1 loop.label   e.g. 'for x in [1] {\n    break nope\n}\n1'
   1 loop.jump   e.g. 'for x in [1] {\n    let f = () -> {\n        for y in [2] {\n            break x\n        }\n    }\n}\n1'
   1 resolve.package_form   e.g. 'use @std . { \n x as x , \n x as x , \n } \n'
   1 resolve.no_module   e.g. 'use use . x . { \n x as x , \n x as x , \n } \n'
   1 type.force   e.g. 'fn some(v: int) -> int? { v }\nfn none() -> int? { null }\nsome(7)!!!!!'
   1 flow.select   e.g. 'fn one() -> int {\n    1\n}\nfn hush() {\n}\nlet job = spawn one()\nlet mute = spawn hush()\nlet jobs = [spawn one(), spawn one()]\n@fair s
   1 type.type_value   e.g. 'type A = int\nlet A = 5\nA'
   1 const.trap   e.g. 'fn boom(n: int) -> int {\n    n / 0\n}\nconst Z: int = boom(1)\nZ'

## SAME KINDS, WORDS DIFFER
  28 type.mismatch   e.g. 'fn f() -> string { if true { 7 } else { "a" } }\nf()'
  14 type.duplicate_param   e.g. 'extern fn x ( const mut x : x , const mut x : x , ) -> x \n'
  14 type.host_seat   e.g. 'extern fn x ( const mut x : x , const mut x : x , ) -> x \n'
  14 type.unknown   e.g. 'extern fn x ( const mut x : x , const mut x : x , ) -> x \n'
   8 type.method   e.g. 'enum Sp { Int, Str, Bool, Opt(inner: Sp), List(elem: Sp), Map(k: Sp, v: Sp), Res(ok: Sp, err: Sp), Fn(ps: List<Sp>, muts: List<bool>, const
   2 type.const_seat   e.g. 'trait T { fn val(const x: int) -> int }\ntype A = { n: int }\nimpl T for A {\n    fn val(const x: int) -> int {\n        x + self.n\n    }\
   1 parse.expected   e.g. 'fn some(v: int) -> int? { v }\nfn none() -> int? { null }\n?? 3'
   1 type.binding   e.g. 'alias F = fn() -> int\nlet f: F? = null\nlet n: int = f?.()\nn'
   1 type.task_escape   e.g. 'type B<T> = { v: T }\nfn g(t: Task<int>) -> int {\n    let b: B<Task<int>> = B { v: t }\n    1\n}\n1'

## NOT MADE (old runs; layer: "not made on the program layer: <reason>")
  17 a file that runs no statement   e.g. '\n'
   6 a shown `{}`, which no text spells yet   e.g. '{ }'
   5 a const read as `int?`, written as `int`   e.g. 'const A: int? = 1\nA! + 1'
   2 a chain into a property that isn't a field   e.g. 'mut ts = [spawn 1]\nts.push(spawn 2)\nlet f = ts.first()\n(f?.await ?? 0) + ts.length'
   1 a const read as `bool?`, written as `bool`   e.g. 'const A: bool? = true\nA ?? false'
   1 a const read as `string?`, written as `string`   e.g. 'const A: string? = "x"\nA!'
   1 a const whose value reads itself   e.g. 'const X: int = X\nX'
   1 a match on a nullable whose patterns aren't `null`, a name or `_`, or whose unguarded arms leave a value to no   e.g. 'const one: int? = 1\nfn f(o: int?) -> int {\n    match o {\n        one -> 1\n        _ -> 2\n    }\n}\n"${f(
   1 a write under an unwrap   e.g. 'type R = { x: int }\ntype H = { r: R? }\nfn f() -> int {\n    mut h = H { r: R { x: 1 } }\n    let before = h
   1 a `dyn` box over `string`   e.g. 'trait Show {\n    fn show() -> string\n}\nimpl Show for string {\n    fn show() -> string { "<" + self + ">" 
   1 `Collect`   e.g. 'let k = 2\nlet xs = collect {\n    match k {\n        2 -> 7,\n        _ -> 8,\n    }\n}\nxs[0] + xs.length'
   1 the layout of `never`   e.g. 'let xs = [1, 2, 3]\nlet a = collect {\n    0\n    [x * 10 for x in xs if x != 2]\n    xs\n    []\n    99\n}\n
   1 a call of a fn value through a seat that promises or by name   e.g. 'let m = { "f": (x: int) -> x * 2 }\nlet f = m.get("f")\nif f == null { 0 } else { f(21) }'
   1 an untyped `MatchOpt`   e.g. 'type T = string\nlet m: Map<string, T> = { "k": "v" }\nm.get("k") ?? "?"'
   1 `Lambda`   e.g. 'type F = fn(int) -> int\nlet f: F = (n) -> n * 2\nf(3)'
   1 a shown `[]`, which no text spells yet   e.g. 'table < x > { \n x | x \n }'

## RUN DIFFERS otherwise 6
    'fn f(c: int) -> int {\n    match c {\n        gone -> 1,\n        0 -> 2,\n    }\n}\n' | OLD OK: | NEW ERR
    'type C = { n: int }\nlet set: fn(mut C) -> int = (mut c: C) -> {\n    c.n = 5\n    c.n\n}\nmut c = C { n: 1 }\n"${set(c)} ${c.n}"' | OLD OK:5 5 | NEW OK:5 1
    'type R = { n: int }\nimpl R { mut fn set(v: int) { self.n = v } }\nfn at(log: Cell<List<string>>, i: int) -> int {\n    log.set(log.get().concat(["i" | OLD OK:7 0 i v | NEW OK:7 0 i v i
    'type R = { n: int }\nimpl R { mut fn set(v: int) { self.n = v } }\nfn at(log: Cell<List<string>>, w: string, i: int) -> int {\n    log.set(log.get(). | OLD OK:7 0 a b v | NEW OK:7 0 a b v a b
    'mut n = 0\nfor x in [1, 2, 3] {\n    while if x == 2 { break } else { false } {\n        n = n + 100\n    }\n    n = n + x\n}\nn' | OLD OK:1 | NEW OK:6
    'type Maybe = string?\nlet m: Maybe = "hi"\nm ?? "none"' | OLD OK:hi | NEW OK:
