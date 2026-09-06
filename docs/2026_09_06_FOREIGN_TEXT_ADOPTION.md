# Foreign text adoption — the design pass

The driver can write a string into a database and cannot read one back.
`text` and `blob` are absent from `@std/sqlite`'s face, and the
connection's own error words are degraded to `errstr`'s static table,
because `sqlite3_column_text` answers a BORROWED pointer that dies at
the next step and nothing in the tree copies foreign bytes into a box.

## What was measured

**A SQLITE TEXT VALUE IS A BYTE STRING WITH A TERMINATOR APPENDED, NOT A
C STRING.** Probed against the vendored amalgamation, `build/sqlite3.o`:

    bind_text(st, 1, "ab\0cd", 5, TRANSIENT)   then read it back

    column_type   = 3 (SQLITE_TEXT)      typeof(v) = text
    column_bytes  = 5                    strlen()  = 2
    bytes         = 61 62 00 63 64       buf[5]    = 00

So `strlen` truncates a legal, round-trippable TEXT value to 40% of
itself. **TEXT AND BLOB HAVE THE SAME SHAPE**: both need
`column_bytes`, neither can be copied from the pointer alone. This is
the tree's own NUL law arriving through a database rather than through
`@std/text`.

That kills the seat annotation. A width can ride an extern's answer
type because it is a property of that one declaration; **a LENGTH
cannot, because it arrives from a DIFFERENT CALL** — `column_bytes`,
read AFTER the value — and an annotation on one extern's answer has no
way to reach another extern's result.

**THE BELT CARRIES THE FIVE STRING-ANSWERING EXTERNS THE DRIVER ALREADY
SHIPS, AND ONLY BECAUSE THOSE POINTERS NEVER DIE.** `hdr()` refuses an
unaligned or sub-image address and checks the tag, so retain and release
on SQLite's rodata are no-ops, and `str_len` falls back to `strlen` when
there is no header. Correct for `libversion`, `sourceid`, `errstr`,
`compileoption_get`. Worth nothing for a column read, where the pointer
dies on SQLite's schedule and Avra would be holding it.

**AND ONE THING DELIBERATELY NOT RECORDED AS A FACT.** A pointer read
before a step still printed its old contents after that step. That is a
sample of one arrangement of freed memory, not a guarantee — the API
says the pointer is invalid, and a stable measurement of undefined
behaviour is still undefined behaviour.

## What the premise was, and that it is gone

Adoption was escalated once and argued down on the grounds that it
introduces a DEREFERENCE into a language that has none. That premise is
false as of today. Compiling clean, no diagnostic, no unsafe marker:

    extern fn avra_ptr_at(address: int) -> ptr
    extern fn avra_array_push(arr: ptr, v: int)
    fn poke(a: int, v: int) { avra_array_push(avra_ptr_at(a), v) }

`avra_array_push` casts what it is handed straight to `AvraArray*` and
writes through it — it cannot afford a header check — and the extern
seam accepts any linked symbol at check time. **That is an arbitrary
WRITE, which strictly dominates the arbitrary READ adoption would
grant.**

So the question is no longer *does this open a hole*. The hole is open,
documented, and wider than what is being asked for. The question is
**where the unsafe corner gets NAMED**.

And one fence that does not exist: an exported C symbol IS a language
capability here, because any file may declare an extern for any linked
symbol with nothing central authorising it. "Let the driver's shim have
it" is not a fence.

## The design

**ONE RUNTIME ROW.** `str_owned` at `avra_runtime.c:1271` is already
exactly the copy — `sized_box`, `memcpy`, the NUL — and is `static` with
zero registry rows. It is exported under a name that says what it is,
takes a pointer and a length, and answers a real headered box the
refcounter owns.

**NO BELT IS POSSIBLE ON THE READ, so the name carries the warning.**
The runtime cannot know the extent of a foreign buffer; a wrong length
reads out of bounds and nothing can catch it. The length's provenance is
the whole safety argument, and it belongs to the caller.

**THE EMPTY CASE IS THE FIRST CASE.** `column_blob` answers a NULL
pointer for THREE conditions — SQL NULL, a zero-length value, and an
out-of-memory — so adopting `(null, 0)` must answer an EMPTY BOX and
never touch the pointer. An encoding spends the empty value; this one
spends it three ways.

**THE FACE ASKS THE CLASS FIRST, ALWAYS, AND READS THE LENGTH AFTER THE
VALUE.** Both laws are already written in `c/column.av` and already held
by `int_at`. `text_at` and `blob_at` join them:

    class_at  ->  Mismatch, or
    column_text/column_blob  ->  pointer
    column_bytes             ->  length   (AFTER the value, always)
    adopt(pointer, length)   ->  the box

**AND THE ASYMMETRY THAT FALLS OUT, which is the design's real content.**
The bind side offers a hatch: `bind_text` copies under
`SQLITE_TRANSIENT`, `bind_text_unsafely_borrowed` does not, and the long
verb is offerable because **the caller CAN keep the bytes alive — the
promise is keepable.** The column side has no such twin, and must not
grow one: the lifetime belongs to SQLite's next step, not to the caller,
so a borrowed read is a promise nobody can make. **It is unspellable
rather than discouraged** — the same move `Mode`'s three lawful
combinations made, arrived at from the other direction.

## What is owed

- The runtime seam is lane A's to own and review — the exported
  primitive's shape, its belt behaviour, and whether it can be reached
  in a way that surprises.
- The export is the owner's decision, put with both halves: the
  capability, and that the fence the last refusal protected is down.
- The driver side is this campaign's: `text_at`, `blob_at`, `errmsg`
  restored to the connection's own words, and the corpus programs that
  show a caller what a read looks like.
