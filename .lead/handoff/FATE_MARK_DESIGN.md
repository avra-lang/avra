# `flow.no_fate` keyed by marks, not by a field named `dead` — design note

Status: proposal only. Nothing is built. The fate pair (f49a0160 here, a86951ac on my branch) is held out of every bundle.

Disclosure: `const fate_field = "dead"` (old path) and `FATE_FIELD` (layer) were already in the tree before the pair (71e734ea has both). The pair deepened the problem by also reading a *queue's* `dead`. Its fate-raising and help text name `dead:` literally as well. This design removes all of it.

## 1. The marks

Three markers in `@std/meta`, declared like `@unbroken` and `@bracket`. The compiler recognises each one by resolving the annotation to its `@std.meta` declaration (`is_meta_fn`: package plus declared name), never by what the user's field is called:

```avra
/// The field is where the failures of the handler field `_handler`, of the same component, go.
export fn fate_for(_f: Field, _handler: string) {}

/// The field holds a component whose `@fate` field takes the failures of the handler `_handler`:
/// the handler's fate may be borrowed from what this field holds.
export fn fate_from(_f: Field, _handler: string) {}

/// The field is this component's fate: the destination that a component holding this one may
/// borrow through `@fate_from`. It names no handler, because the component holding it brings the
/// handler.
export fn fate(_f: Field) {}
```

Spelling on a component (component fields already take marks: `cfield = ( marks:mark )* …`):

```avra
export component worker<T, R, E> {
    @fate_from(each) reads: queue<T>?
    each: fn(Delivery<T>) -> Result<R, E>
    @fate_for(each) dead: queue<Dead<T, E>>? = null
}
```

The argument `each` is a bare name. It resolves against the component's *own* fields, so the only name involved is the author's own declaration. Precedent (`@bracket("decls")`, `plain_field`) writes it as a string. I'd take whichever the owner prefers; bare is the lead's spelling.

## 2. What the law reads (both paths)

At the declaration, each component field gets a fate seat: `Own` (`@fate`), `For(h)`, `From(h)`, or none.
- Layer: on `FieldSeat` / `RecordShape`, beside the existing `valued`.
- Old path: read off `component_parts_of(d).fields()` marks through `decls.is_meta_annotation`.

An instance of component C owes a fate for handler field `h` only when:
- some field of C is marked `@fate_for(h)` or `@fate_from(h)`; and
- the value written for `h` can fail (a fn answering `Result`).

A component with no marks owes nothing, as one with no `dead` owes nothing today.

The fate is named when **any** of these holds:
- **Direct.** A `@fate_for(h)` field is written non-`null`, or left to a default that is a value (today's `valued` / `defaults_to_value`).
- **Borrowed.** A `@fate_from(h)` field's value traces, through the name (`instance_named` follows the `let` / named instance, as now), to an instance whose `@fate` field is named in the direct sense.
- **Borrowed, untraced.** The value traces to no instance (a parameter, a call's answer). It is taken as named, as now: only a fate known to be missing is refused.

Otherwise the law refuses at `h`'s value, with the same code and message as today. The help names the field **from the mark**, never a constant:
- with only `@fate_for` fields: "name a fate for it — `<field>: …`", where `<field>` is the `@fate_for(h)` field's declared name;
- with a `@fate_from` field: "name the fate on what it reads — `<own field>: …` on `<instance>`", where `<own field>` is the borrowed component's `@fate` field name and `<instance>` is the traced name.

That is the pair's logic unchanged (own first, then queue, then trace through the `let`). Only the key changes: "a field called `dead`" becomes "the field that wears the mark".

## 3. What refuses a mark (new law at the declaration, e.g. `component.fate_mark`; both paths, with witnesses)

1. `@fate_for(h)` or `@fate_from(h)` where `h` names no field of the component: "`h` is no field of `C`".
2. `h` names a field that is not a handler that can fail (not a fn answering `Result`): "a fate is for a handler that can fail; `h` cannot".
3. `@fate_for(h)`, `@fate_from(h)` or `@fate` on a fn-typed field: a handler cannot be a destination.
4. `@fate_from(h)` on a field whose type (with `?` stripped) is not a component declaring a `@fate` field: "`reads` holds a `box`, which marks no `@fate` field to borrow".
5. Two `@fate` fields on one component, or two `@fate_for(h)` fields for the same `h`: ambiguous destination.
6. Any of the three marks outside a component field (a plain record or a fn): refused as misplaced. They mean nothing there.

No field type is required of a direct destination beyond "not a fn". The destination's type is the author's (a `queue<Dead<…>>`, a `Sink`, a `string` name): the compiler doesn't know what a letter is, and that's the point.

## 4. Migration

**std-queue as it stands**
- `worker`: add `@fate_for(each)` on `dead`. That is the only field the law reads today.
- `queue` has **no** `dead` field today, so it has nothing to mark. `@fate_from(each) reads` is added only if and when services move the letter onto the queue: the `queue` then declares `@fate <letter field>`, the `worker` marks `reads`, and the `worker`'s `dead` stays as its own override. Marking `reads` before that refuses under rule 4, deliberately: a borrow from something that has no fate is a mistake.
- `job`: stays unmarked. It always builds its worker with a fate (`buries_in ?? letter_made()`), so it owes nothing at the instance, as today.

**Compiler**
- Delete `fate_field` / `FATE_FIELD`.
- The help strings stop spelling `dead:`, and `fate_unqueued`'s help takes the field names.
- Remedy and witness rows (`remedies.av` around lines 609 and 798, `witnesses.av` around 1453) mark their toy `work` component's `dead`.
- `components_fate_test.av` cases mark their components.
- `tools/program-refusals/fate_*`: the toy `box` gets `@fate dead`, `crew` gets `@fate_from(each) reads` / `@fate_for(each) dead`, and `job` gets `@fate_for(each) dead`. Expectations are unchanged, except that the help names the field from the mark.
- New witnesses: one per refusal in §3, plus a component whose fate field is named something other than `dead` (e.g. `@fate_for(run) graveyard`), to prove nothing keys on the spelling.

**Users.** A user component with a `dead:` field and no mark stops owing a fate. That is a silent loosening, so it needs a note in the release text. Inside the tree the only such components are the toys and std-queue's `worker`, all migrated above.

## Open for the owner
- Bare name or string argument (`@fate_for(each)` vs `@fate_for("each")`).
- Whether `@fate` / `@fate_from` land now (as general machinery, with only the witnesses using them) or with services' move of the letter onto the queue. `@fate_for` alone covers std-queue today.
