# `Bytes` — THE RUNTIME HALF, as a diff for lane A

> **Status:** a diff to review, not applied. Written against **main at
> `271559d`** — not this lane's base — and every line number below was
> read there. `runtime/avra_runtime.c`, `core/runtime_api.av` and
> `core/ir.av` are lane A's; nothing here has been written into them.
>
> Each hunk carries the reason it exists, as asked. The design behind it
> is `2026_09_05_BYTES_SHAPE.md`; this is only the runtime half —
> the type, the typing rules, the interpreter arms and the value
> protocol are lane C's and are not here.

---

## HUNK 1 — the kind (`:48`)

```c
-enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3 };
+enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3, KIND_BYTES = 4 };
```

**Why:** appended, never inserted. Nothing serialises a kind today, so
insertion would be safe — but appending costs nothing and keeps it safe
if anything ever does.

## HUNK 2 — the accounting category (`:98`, `:102-106`)

```c
-enum { ACC_RECORD, ACC_STR, ACC_LIST, ACC_BUF, ACC_MAP, ACC_INDEX, ACC_KINDS };
+enum { ACC_RECORD, ACC_STR, ACC_BYTES, ACC_LIST, ACC_BUF, ACC_MAP, ACC_INDEX, ACC_KINDS };

 static const char* g_acc_name[ACC_KINDS] = {
     [ACC_RECORD] = "records",    [ACC_STR]   = "strings",
+    [ACC_BYTES]  = "blobs",
     [ACC_LIST]   = "list boxes", [ACC_BUF]   = "list buffers",
     [ACC_MAP]    = "map boxes",  [ACC_INDEX] = "map indexes",
 };
```

**Why:** inserted directly after `ACC_STR`, as you chose, so text and
blobs sit adjacent — that is the comparison someone under memory
pressure with a database in front of them actually wants. **Safe to
insert only because you made the name table KEYED**; under the previous
positional initialiser this hunk would have silently relabelled every
category after `ACC_STR`. Recorded because the next person inserting a
category will want to know why it is safe.

Its own category rather than a reuse of `ACC_STR`: text and blobs are
exactly the two things worth telling apart when a database is what is
under pressure.

## HUNK 3 — `acc_kind_of` (`:245`)

```c
     switch (kind) {
         case KIND_ARRAY:  return ACC_LIST;
         case KIND_MAP:    return ACC_MAP;
         case KIND_STR:    return ACC_STR;
         case KIND_STATIC: return ACC_STR;
+        case KIND_BYTES:  return ACC_BYTES;
         case KIND_PLAIN:  return ACC_RECORD;
         case KIND_DEAD:   return ACC_RECORD;
         default:          return ACC_RECORD;
     }
```

**Why:** one arm, in the shape you rebuilt this function into. Without
it a blob is filed as a RECORD — the defect you found already live here
for `KIND_STATIC`, arriving a second time for a kind that did not exist
when the chain was written.

## HUNK 4 — `box_bytes`, THE SIZE-CLASS WITNESS (`:303`)

```c
-static size_t box_bytes(Header* h) {
-    return h->kind == KIND_STR ? (size_t)h->len + 1 : (size_t)h->len;
-}
+// THE ALLOCATION SIZE, recovered so `box_free` can name the size class.
+// A SIZED box allocated n+1 and recorded n, so its allocation is len+1;
+// every other box recorded its allocation directly. The sized kinds are
+// LISTED, never defaulted: `sized_box` is the one constructor that makes
+// them, and a new sized kind belongs in both places or in neither.
+static size_t box_bytes(Header* h) {
+    switch (h->kind) {
+        case KIND_STR:
+        case KIND_STATIC:
+        case KIND_BYTES:  return (size_t)h->len + 1;
+        default:          return (size_t)h->len;
+    }
+}
```

**Why, and this is the hunk that corrupts the heap if it is wrong:**
`sized_box` allocates `n + 1` and records `len = n`, so the allocation
must be recovered as `len + 1`. Miss it and `class_of` is given the
wrong size, the buffer is filed on the wrong free list, and the next
allocation of that class gets a short buffer — **no diagnostic, and not
reproducible until the class is reused.**

**Written as a LIST of kinds rather than a chain ending in a default**,
as you asked, so the next sized kind is visible at the site rather than
absorbed by the fall-through. C cannot demand it; the arms are the
record.

**`KIND_STATIC` IS ADDED HERE AS A CORRECTNESS FIX, NOT AS SCAFFOLDING
FOR BYTES — please review it as its own change.** `str_static` calls
`sized_box(n, KIND_STATIC)` (`:327`), so a static box allocates `n + 1`
and records `n`, and today `box_bytes` under-reports it by one. It is
harmless *only because a static box is immortal*: `avra_rc_release`
returns early on `kind < 0`, so `box_free` never sees one. That is safe
by immortality, not by arithmetic — your phrase — and the arithmetic
should be right regardless, because the day a borrowed-but-mortal kind
appears the asymmetry is waiting. **If you would rather keep this hunk
separate from the Bytes slice, split it; it stands alone.**

## HUNK 5 — `str_len` (`:293`)

```c
-static size_t str_len(const char* s) {
-    Header* h = hdr((void*)s);
-    return (h && h->len) ? h->len : strlen(s);
-}
+// A string's length in O(1) — the header's, or measured when the text
+// is not a box of ours. The predicate is the KIND, never the length: a
+// list's or map's `len` is its PAYLOAD BYTE SIZE, so trusting any box's
+// `len` here would answer tens of bytes for a list. And a legitimately
+// EMPTY string is trusted rather than measured, which is what a `Bytes`
+// box — which has no terminator to find — would otherwise depend on.
+static size_t str_len(const char* s) {
+    Header* h = hdr((void*)s);
+    if (h && (h->kind == KIND_STR || h->kind == KIND_STATIC)) return h->len;
+    return strlen(s);
+}
```

**Why:** two fixes in one line, and the second is the one this lane got
wrong first. The zero-length fallback is a wart for text — a real string
of length 0 is measured instead of trusted, correct today only because
`sized_box` writes a terminator and every caller relies on it. **And
this lane's earlier proposal, `h ? h->len : strlen(s)`, was WRONG**: it
would trust `h->len` for an array or map box, whose `len` is its payload
byte size. The predicate has to be the kind.

**Premise, measured before proposing:** eight ways of producing an empty
string — a literal, `"" + ""`, `substring(1,1)`, `substring(3,3)` at the
end, `trim` of blanks, replace-to-empty, `join` of empties, and a concat
of two empty substrings — all answer 0, on both engines. So the change
is behaviour-preserving for every text in the tree today.

**`Bytes` does not appear in this function** and must not be added to
it: it gets its own accessor (hunk 7.1) with no fallback at all.

## HUNK 6 — the constructor

```c
+// A blob of `n` bytes. The terminator `sized_box` writes is OUTSIDE the
+// recorded length and is never read — a blob's length is the header's,
+// always. It is there so the size-class arithmetic is identical to a
+// string's and the EMPTY blob needs no special case.
+static char* bytes_box(size_t n) { return sized_box(n, KIND_BYTES); }
```

**Why one line and not a second constructor:** because you removed the
translation. `sized_box` now honours the kind it is given, so there is
nothing a separate constructor could do differently, and the `n + 1`
shape arrives with it rather than being a decision this hunk makes.

**The empty case is why the shape matters** and it is worth stating at
the site: `box_alloc(0, …)` allocates 1 and records 1. A `Bytes` that
allocated exactly `n` and then corrected its length to 0 would carry
`len = 0` against an allocation of 1, and hunk 4's default arm would
answer 0 while `class_of` was given 1 — **the empty blob would free into
the wrong class.**

## HUNK 7 — the bodies

```c
+// ── Bytes ───────────────────────────────────────────────────────
+
+// 7.1 The length. The header's, with NO fallback: a Bytes box always
+// has an authoritative length, and a pointer that is not one of ours
+// is not a Bytes.
+int64_t avra_bytes_len(const char* b) {
+    Header* h = hdr((void*)b);
+    return h ? (int64_t)h->len : 0;
+}
+
+// 7.2 BYTE equality — the whole reason the type exists. Lengths first,
+// then memcmp. `==` on a string is strcmp and stops at the first NUL,
+// so a blob compares equal to its own truncated prefix; this does not.
+int64_t avra_bytes_eq(const char* a, const char* b) {
+    size_t la = (size_t)avra_bytes_len(a), lb = (size_t)avra_bytes_len(b);
+    if (la != lb) return 0;
+    return memcmp(a, b, la) == 0 ? 1 : 0;
+}
+
+// 7.3 One byte, unsigned. Out of range answers -1 — the convention the
+// integer rows already keep (`avra_str_index_of` on a miss).
+int64_t avra_bytes_at(const char* b, int64_t i) {
+    size_t n = (size_t)avra_bytes_len(b);
+    if (i < 0 || (size_t)i >= n) return -1;
+    return (int64_t)(unsigned char)b[i];
+}
+
+// 7.4 A slice, owned. Bounds clamp rather than trap, as substring does.
+const char* avra_bytes_slice(const char* b, int64_t lo, int64_t hi) {
+    size_t n = (size_t)avra_bytes_len(b);
+    if (lo < 0) lo = 0;
+    if (hi > (int64_t)n) hi = (int64_t)n;
+    if (lo >= hi) return bytes_owned("", 0);
+    return bytes_owned(b + lo, (size_t)(hi - lo));
+}
+
+// 7.5 Concatenation, owned.
+const char* avra_bytes_concat(const char* a, const char* b) {
+    size_t la = (size_t)avra_bytes_len(a), lb = (size_t)avra_bytes_len(b);
+    char* buf = bytes_box(la + lb);
+    memcpy(buf, a, la);
+    memcpy(buf + la, b, lb);
+    buf[la + lb] = '\0';
+    return buf;
+}
+
+// 7.6 Text to bytes — TOTAL. A string is always valid bytes.
+const char* avra_bytes_of_str(const char* s) {
+    return bytes_owned(s, str_len(s));
+}
+
+// 7.7 Bytes to text — FALLIBLE, and the failure is the NULL POINTER.
+// A pointer row answers null on a miss and a reason is a SECOND ROW
+// (7.8) — the convention `avra_map_get_owned` and `avra_errno_text`
+// already keep. A `Result` is NOT built here: it is a tagged box, and a
+// C body constructing one would have to know Avra's enum layout, which
+// is the coupling this boundary exists to prevent. Avra turns the null
+// into `.Err(…)` itself.
+const char* avra_str_of_bytes(const char* b) {
+    size_t n = (size_t)avra_bytes_len(b);
+    if (utf8_bad_at(b, n) >= 0) return NULL;
+    return str_owned(b, n);
+}
+
+// 7.8 WHERE it is not UTF-8 — the byte offset, or -1 when it is valid.
+// Total, and separate, so 7.7 answers a value and this answers a reason.
+int64_t avra_utf8_bad_at(const char* b) {
+    return (int64_t)utf8_bad_at(b, (size_t)avra_bytes_len(b));
+}
```

Plus `bytes_owned(s, n)`, mirroring `str_owned` (`:1145`) but through
`bytes_box`.

### 7.9 — the validator, written out for adversarial reading

```c
+// The offset of the first byte that is not valid UTF-8, or -1 when the
+// whole buffer is. THE LEAD BYTE'S RANGE DECIDES EVERYTHING: how many
+// continuations follow, and the range the FIRST continuation must fall
+// in — which is where overlongs and surrogates are refused, at the lead,
+// rather than by decoding a code point and judging it afterwards.
+//
+// U+0000 IS VALID, and is one byte: a NUL inside a text is legal UTF-8.
+// Its overlong two-byte spelling C0 80 is not, and C0 is refused as a
+// lead — which is the same refusal, arriving one byte earlier.
+static int64_t utf8_bad_at(const char* p, size_t n) {
+    const unsigned char* b = (const unsigned char*)p;
+    size_t i = 0;
+    while (i < n) {
+        unsigned char c = b[i];
+        size_t need;           /* continuation bytes after the lead */
+        unsigned char lo, hi;  /* the range the FIRST continuation must be in */
+
+        if (c <= 0x7F)                   { i += 1; continue; }              /* ASCII, U+0000 included */
+        else if (c >= 0xC2 && c <= 0xDF) { need = 1; lo = 0x80; hi = 0xBF; }
+        else if (c == 0xE0)              { need = 2; lo = 0xA0; hi = 0xBF; } /* no overlong 3-byte */
+        else if (c >= 0xE1 && c <= 0xEC) { need = 2; lo = 0x80; hi = 0xBF; }
+        else if (c == 0xED)              { need = 2; lo = 0x80; hi = 0x9F; } /* no surrogate */
+        else if (c >= 0xEE && c <= 0xEF) { need = 2; lo = 0x80; hi = 0xBF; }
+        else if (c == 0xF0)              { need = 3; lo = 0x90; hi = 0xBF; } /* no overlong 4-byte */
+        else if (c >= 0xF1 && c <= 0xF3) { need = 3; lo = 0x80; hi = 0xBF; }
+        else if (c == 0xF4)              { need = 3; lo = 0x80; hi = 0x8F; } /* stops at U+10FFFF */
+        else                             { return (int64_t)i; }              /* 80-BF stray, C0/C1
+                                                                                overlong, F5-FF gone */
+        /* TRUNCATION IS A DEFECT AT THE LEAD, never at the buffer's end:
+           the sequence that is wrong is the one that STARTED and cannot
+           finish. Continuations occupy i+1 .. i+need, so the sequence
+           fits only while i + need < n. */
+        if (i + need >= n) return (int64_t)i;
+        if (b[i + 1] < lo || b[i + 1] > hi) return (int64_t)i;
+        for (size_t k = 2; k <= need; k++)
+            if (b[i + k] < 0x80 || b[i + k] > 0xBF) return (int64_t)i;
+        i += need + 1;
+    }
+    return -1;
+}
```

**THE TABLE CONSTRAINS THE FIRST CONTINUATION ONLY — THE REST ARE
CHECKED SEPARATELY, AND THAT MUST BE SAID HERE RATHER THAN LEFT TO THE
CODE.** Each row names the range of the byte at `i+1`, because that is
where overlongs and surrogates are cut. Bytes `i+2` and `i+3` of a
three- or four-byte sequence carry no such refinement, but they are
still continuations and are range-checked against `80..BF` by the loop.
**If they were taken on trust, `E1 80 41` would pass and it is not
UTF-8.** The loop is the second half of the rule and the table is
incomplete without it:

```c
if (b[i + 1] < lo || b[i + 1] > hi) return (int64_t)i;   /* the row's range  */
for (size_t k = 2; k <= need; k++)                        /* every other one  */
    if (b[i + k] < 0x80 || b[i + k] > 0xBF) return (int64_t)i;
```

**Why the lead-range table rather than decode-then-check.** Every
invalid form is refused by the lead byte's own row, so no code point is
ever assembled from bytes that do not encode one. Walking the named
attacks:

| attack | refused by |
|---|---|
| five- and six-byte forms (`F8`–`FD`) | not a lead — the `else` |
| overlong NUL (`C0 80`) | `C0` is not a lead; the range starts at `C2` |
| overlong two-byte (`C1 …`) | same row |
| overlong three-byte (`E0 80 …`) | `E0`'s first continuation must be `A0`–`BF` |
| overlong four-byte (`F0 80 …`) | `F0`'s must be `90`–`BF` |
| lone surrogate (`ED A0 80` = U+D800) | `ED`'s must be `80`–`9F`; `A0` fails |
| above U+10FFFF (`F4 90 80 80`) | `F4`'s must be `80`–`8F`; `90` fails |
| exactly U+10FFFF (`F4 8F BF BF`) | **accepted** — the boundary is inclusive |
| stray continuation as a lead (`80`–`BF`) | the `else` |
| truncated sequence at the buffer's end | `i + need >= n`, reported **at the lead** |

An empty buffer returns `-1`: **the empty blob is valid UTF-8 and
converts to the empty string.** The loop does not run, which is the
fourth place in this campaign where the empty case had to be checked
rather than assumed.

### 7.10 — THE HAZARD A CORRECT VALIDATOR MINTS, and why it is not fixed here

U+0000 is valid UTF-8 and is one byte. So a blob holding a NUL converts
cleanly, and **`avra_str_of_bytes` can produce a perfectly valid Avra
`string` with an embedded NUL** — length `n` in its header, correct by
every rule above.

That string is a trap at the C boundary. Hand it to any extern taking
`string` and C receives a bare `const char*` that **stops at the NUL**.
So a correct conversion manufactures, from the honest direction, exactly
the value this campaign has been chasing since the first probe.

**IT IS NOT FIXED BY REFUSING NUL.** Refusing it would make
`str_of_bytes` lie about what it validates — U+0000 is text, SQLite
permits it in a TEXT value, and a validator that rejects valid input to
protect a downstream boundary has moved the defect rather than closed
it.

**THE CONSTRAINT IT IMPOSES ON THE DRIVER INSTEAD** — and the driver
inherits this *because* the validator is correct, which is the
interesting kind of constraint:

> **TEXT CROSSING TO C CARRIES A LENGTH, NEVER A TERMINATOR.** Every
> extern in the wall that takes text FROM Avra takes it as `Bytes` with
> an explicit length, never as `string`. The reason is not caution: the
> `string` path *cannot represent* what our own validator accepts.

This lands neatly, because SQLite's own text-taking entry points all
carry an explicit length already — `sqlite3_bind_text(…, int nByte, …)`,
`sqlite3_prepare_v2(…, int nByte, …)` — and the `-1` sentinel meaning
"measure it with strlen" is the one form the driver must never use.
(Lane A's finding, reviewing this validator adversarially.)

## HUNK 8 — the registry (`core/runtime_api.av`, `core/ir.av`)

One `rt_sigs` row and one `RtHost` variant per body. `owns_result`
honestly: `len`, `eq`, `at` and `utf8_bad_at` own nothing; `slice`,
`concat`, `of_str` and `of_bytes` own their answer.

**`RtKind` is untouched** — a `Bytes` crosses as `Ptr`.

---

## What this diff does NOT contain, deliberately

- **The interpreter arms** — one per `RtHost` variant, lane C's file.
- **The type, `rides_pointer`, `is_managed`, the typing rules and the
  grammar assertion** that keeps `box_clone` unreachable — lane C's.
- **The value protocol's `bytes_of`** — at the second reader, never the
  first.
- **`box_clone`** — no arm, deliberately. `Bytes` has no assignable path
  syntax, so it can never be an intermediate place step and never
  reaches it. §1 of the shape has the measurement and the trigger.
- **`avra_rc_release`'s reclaim dispatch** — no edit. Its `else →
  box_free` arm is correct for a box with no children.

## One thing spotted while reading, not mine to fix

`sized_box` (`:280-290`) carries **two stacked doc comments** — the old
two-line one ("A string box of `n` bytes plus its terminator… An owned
string wears KIND_STR so its class can be read back") is still above the
new one, and the first is now false: it no longer wears `KIND_STR`, the
caller names the kind. Probably a leftover from the rename.
