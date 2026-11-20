# THE STRING IS A HEADERED BOX — the representation, decided

> **Status:** DECIDED 2026-09-05 by the owner. This document is the
> source of truth for how Avra represents text, and it SUPERSEDES
> sub-decision 9.15 of `../forge-crafting-intepreters/docs/2026_04_18_FULL_SPEC.md`,
> which is a LEGACY tree. Where the two disagree, this file wins.
>
> **Why it exists:** the legacy spec chose small string optimization and
> specified an inline representation. The compiler built something else,
> and every design now standing on the tree — the `Bytes` value category,
> the FFI wall, the memory pass's `rides_pointer` answer — rests on what
> was built rather than on what was written. That contradiction was found
> while reconciling `STRINGS FROM THE FUTURE` against the runtime, and
> resolved in favour of the implementation. This file records the
> decision so no later lane re-opens it as a spec violation.

---

## The decision

**A `string` is a pointer to a refcounted heap box whose header carries
its length. There is no small-string optimization, and none is planned.**

## What was considered

| option | verdict |
|---|---|
| (a) Heap + refcount always, with a length-carrying header | **CHOSEN** |
| (b) Heap + refcount with small string optimization (SSO) — a 24-byte value, `≤ 23` bytes stored inline behind a discriminator bit | REJECTED, and it was the legacy spec's choice |
| (c) Interning for known-static strings | DEFERRED — a backend optimization, no semantic change, ships when profiling justifies it |

## Why (a) and not (b)

**1. SSO's benefit already arrives by another mechanism.** SSO was chosen
to make short strings cheap and `.length` O(1). The 16-byte header
delivers exactly that: `.length` is a LOAD, not a scan. The goal the
legacy spec named is met; only its named method changed. Lane A landed
this, and idiom I27 retired along with the `strlen` it used to ratchet.

**2. AN INLINE STRING HAS NO ADDRESS, AND THE C ABI REQUIRES ONE.** This
is the decisive reason and it is not a performance argument. Avra hands a
`string` to a C function as a pointer to its payload. Under SSO a short
string lives *inside* the value — there is no stable address to pass — so
a language with SSO cannot give a short text to any C library without
copying it first, at every call. FFI is a make-or-break feature, and a
representation that silently taxes every short string crossing the
boundary is the wrong trade.

**3. One mechanism, not a composite with a special case.** Under (b) a
string is a 24-byte value whose heap portion sometimes participates in
refcounting and sometimes does not, and ownership has to move 24 bytes
and conditionally drop a heap portion. Under (a) a string is an ordinary
managed box, participating exactly as a list, a map or a record does. The
memory pass learns nothing new.

## The layout

- A `string` VALUE is a pointer — 8 bytes on 64-bit systems.
- Immediately BEFORE the payload sits a **16-byte header**: `tag`,
  `kind`, `rc`, `len`.
- The **tag** authenticates the box. A pointer that is unaligned, below
  the image base, or not carrying the tag is not ours, and the runtime
  refuses to read a header off it (`hdr`, `runtime/avra_runtime.c:68`).
- The payload is the bytes themselves, followed by a NUL that lies
  **outside** the recorded length. So a `string` is passable to C as a
  `const char*` while still being able to hold a NUL of its own.
- The **kind** distinguishes an owned box from an immortal one
  (`KIND_STR` vs `KIND_STATIC`). An immortal box's refcount is frozen —
  `avra_rc_retain`/`release` return early on a negative kind — so it is
  never freed. Compile-time constants, argv's words and the
  environment's words are immortal.
- **Encoding is UTF-8, always.** No UTF-16, no UCS-4.

## The laws this settles

**A LENGTH IS CARRIED, NEVER MEASURED.** The header records it; nothing
scans for it. An operation that reaches for `strlen` on a value that has
a header is a defect, not an optimization: it truncates silently at the
first NUL, and the value then reads equal to its own prefix. The tree has
been bitten by this three times — `write_text` measuring content with
`strlen`, `str_len` distrusting a legitimately zero header length, and a
blob's length being unrecoverable at the C boundary. It is one law, and
this is where it is written down.

**WHERE THE TREE DOES NOT YET OBEY IT — one place, already assigned.**
The law is held today: `.length` is a header LOAD, not a scan
(`str_len`, `runtime/avra_runtime.c:272`; lane A landed it and idiom I27
retired with the `strlen` it used to ratchet). The single exception is
the fallback in that same line —

```c
return (h && h->len) ? h->len : strlen(s);   //  a ZERO length is not trusted
```

— so a box whose recorded length is legitimately **zero** is measured
after all. For text this is harmless by convention rather than by
construction: `str_box` allocates `n + 1` and callers write a terminator,
so the scan finds the sentinel and answers 0. Probed eight ways (a
literal, `"" + ""`, two empty substrings, `trim` of blanks,
replace-to-empty, `join` of empties, a concat of two empty substrings) —
all answer 0, on both engines.

A `Bytes` box has no terminator to find, so the fallback would measure
whatever follows it in memory, and it would do so **only in the empty
case** — the one a test suite forgets. THE FIX, landing with `Bytes`:
make the header read unconditional, `h ? (size_t)h->len : strlen(s)`, so
a zero length is trusted and only a NON-box is measured. The premise that
makes this behaviour-preserving — that nothing in the tree carries
content behind a zero header length — is the eight-way probe above.

**`.length` IS BYTES.** A byte count, O(1). Codepoint and grapheme counts
are explicit O(n) scans and are spelled as such. This prevents the
Python/JavaScript ambiguity where indexing means three different things.

**EVERY POINTER AVRA HOLDS CARRIES A HEADER.** The string is the
archetype, not an exception. A value that came from anywhere else — a C
library's buffer, a bare `malloc` — is memory the refcounter must never
be handed.

**A FOREIGN POINTER IS NOT A `string`.** It follows from the above, and
it is the law the FFI wall is built on. A foreign `const char*` handed
across as a `string` currently *appears* to work, because `hdr` refuses
an untagged pointer and `str_len` falls back to `strlen` — correct only
for text that is immortal and NUL-terminated, and silently wrong for text
with a lifetime, for bytes, and for text holding a NUL. The refcount
guard cannot see any of it, because an untagged pointer raises no retain
or release events. Foreign text is COPIED at the boundary, into a real
box.

## What still stands from the legacy spec

Unchanged by this decision, and still law: UTF-8 as the only internal
encoding; `.length` as a byte count with explicit `chars()`/`graphemes()`
scans; `s[i]` indexing by byte position and answering `u8`; and interning
deferred as a semantically invisible backend optimization.

## Consequences already depending on this

- **`Bytes`** shares the string box — one layout, one allocator, one
  refcount path, a different kind tag. It is only expressible because a
  string is a pointer.
- **`rides_pointer` answers true for a string**, so a `string?` is
  niche-encoded (the null pointer IS absence) and costs exactly what a
  `string` costs. `features/values.av:229-231`.
- **The FFI wall** can hand C the payload address of any text, of any
  length, with no copy and no special case.

---

## Confidence ledger

| claim | how verified |
|---|---|
| the legacy spec chose SSO and specified an inline 24-byte value | read at `2026_04_18_FULL_SPEC.md` sub-decision 9.15 |
| the tree built a pointer to a headered box | `runtime/avra_runtime.c` — `box_alloc:244`, `str_box:264`, `hdr:68` |
| an immortal box's refcount is frozen | `box_alloc` sets `rc = 1` for every box; `avra_rc_retain:383` and `avra_rc_release:417` return early on `kind < 0` |
| `.length` is a load, not a scan | `str_len:272` reads the header; lane A's measurement, I27 retired with it |
| a foreign `const char*` crosses as `string` and appears to work | RUN: `extern fn sqlite3_libversion() -> string` answers `3.51.0`, `.length` 6, `==` true |
| the refcount guard is blind to that seam | `hdr`'s tag check gates `rc_note`; a known-borrowed foreign pointer reports clean under `AVRA_RC_GUARD=1` |
| a string is niche-encoded as a nullable | `features/values.av:229-231` |
