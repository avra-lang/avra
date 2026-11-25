# Quote hygiene: a derive file's imports capture the program's names inside its quotes

Found while landing `@secret` as a declared mark (alloc lane, 2026-11-24). Reproduces on landed 0775dc2b
(compiler h2) and on the lane head alike.

## The defect

A derive's quote spells the program's own type through a hole (`${t}`), and the generated code is read
in the DERIVE FILE's scope first. A name the derive file imports, here `@std.meta`'s `Named`, then
captures the program's own declaration of that name. The program's `Named` resolves to the derive's
`Named`, so `Named { n: 1 }` is judged as `@std.meta.Named { name, at }`.

## Minimal repro (files beside this note in /work/out/quote-hygiene/)

`gen/src/gen.av`, the derive. It imports `Named` and never writes it in the quote:

```avra
use @std.meta.{Type, Directive, Named, beside, name}

export trait Made {
    static fn derive(t: Type) -> List<Directive> {
        let f = t.fields[0].name
        [beside(t, quote { impl ${t} { static fn made() -> ${t} { ${t} { ${f}: 1 } } } })]
    }
}

fn seen(n: Named) -> Named { n }
```

`user/src/main.av`, a program declaring its own `Named`:

```avra
use @std.meta.{derive}
use @probe.qgen.{Made}

@derive(Made)
type Named = { n: int }

println("${Named.made().n}")
```

`ctl/`: the same program with the type named `Thing`.

## What happens

```
$ cd ctl && avra run .
1

$ cd user && avra run .
avra: /work/probe/qh/user/src/main.av: a seat refuses a value here, in a body no law reads yet

$ cd user && avra check .
(no finding: the program layer says nothing)

$ cd user && AVRA_PROGRAM=0 avra run .
error[type.struct_fields]: `Named` needs field `name`
  ╭─[gen/src/gen.av:8:67]
8 │         [beside(t, quote { impl ${t} { static fn made() -> ${t} { ${t} { ${f}: 1 } } } })]
  ·                                                                   ┬
  ·                                                                   ╰── this literal
error[type.struct_fields]: `Named` needs field `at`
  …
```

## Wanted

A name a hole splices from the program (`${t}`, a `Type`'s name) resolves where the PROGRAM declares
it, never in the derive file's scope. Only names the quote's own text writes should read the derive
file's scope, and even those should be hygienic toward the program's declarations. Two voices are
also owed:
- the program layer's `check` is silent;
- its `run` refusal ("a seat refuses a value here, in a body no law reads yet") names neither the
  capture nor the derive.

## Where it bit, and the standing workaround

`packages/std-validate/src/derive.av` (commit "validate: `@secret` is a mark the package declares")
imports `Named as Marked` and `Marker as Unrun`. Importing them bare broke
`std-validate/src/tests/derive_test.av`, whose program declares its own `Named` ("a record literal
leaving a field no declared default fills, at derive_test.av.Named.decoded"). Every derive file's
existing imports (`Type`, `Field`, `Kind`, `Annotation`, `Directive`, …) carry the same risk toward a
program that declares a type of the same name.
