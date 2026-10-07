// The box layouts the runtime reads and the backend LAYS OUT. Every
// pointer a program holds carries the Header; a list, a record and
// an enum's box are an AvraArray; a map is an AvraMap. The runtime
// mints these at run time and the backend mints them as static data
// (a string constant, a settled aggregate), so the shapes are ONE
// definition shared by both — a field added here reaches the layout
// the backend emits only by hand, which the static asserts in
// backend/llvm_wrapper.c pin.
#ifndef AVRA_BOX_H
#define AVRA_BOX_H

#include <stdint.h>

// A box's KIND decides how it reclaims and clones: 0 a plain
// allocation, 1 an array, 2 a map, 3 a string, 4 octets. Below zero it is not
// counted: STATIC is immortal, DEAD is the guard's mark on a
// reclaimed box.
enum { KIND_DEAD = -2, KIND_STATIC = -1, KIND_PLAIN = 0, KIND_ARRAY = 1, KIND_MAP = 2, KIND_STR = 3, KIND_BYTES = 4 };

// AN IMMORTAL BOX KEEPS ITS SHAPE. A `once` answer and a static
// aggregate live for the process, so retain and release must no-op
// on them — which the `kind < 0` test already gives free — but
// `box_clone` still has to know whether one is a MAP, because a
// write through a shared value CLONES it, and a map cloned as an
// array is memory corruption. Overwriting the kind with KIND_STATIC
// loses exactly that. So immortality is a REFLECTION of the kind and
// never a replacement: negative for every shape, and it decodes back.
#define KIND_IMMORTAL(k) (-((k) + 4))
#define IS_IMMORTAL(k)   ((k) <= -4)
#define KIND_SHAPE(k)    (IS_IMMORTAL(k) ? -(k) - 4 : (k))

// A cell's mark bits (AvraArray.marks).
enum { MARK_OWNED = 1, MARK_ABSENT = 2 };

// "AVRA" — the bytes that say a header is this runtime's.
#define AVRA_TAG 0x41565241u

// Sixteen bytes before every payload: the tag, the kind, the count,
// and a LENGTH — a string's text length, a record's payload bytes.
typedef struct {
    uint32_t tag;
    int32_t kind;
    int32_t rc;
    uint32_t len;
} Header;

// A slot array: `cap` cells at `data`, `len` of them written, and
// one MARK byte per cell after the cells: `MARK_OWNED` when the cell
// holds a managed value the reclaim releases, `MARK_ABSENT` when it
// holds a nullable scalar that is not there — so a nullable int lives
// in one word and one bit, with no box.
typedef struct {
    int64_t cap;
    int64_t len;
    int64_t* data;
    uint8_t* marks;
    // where it was made — the accounting's return address, else NULL
    void* site;
} AvraArray;

// A string-keyed, insertion-ordered map: keys and values as two
// arrays, and an open-addressing index over key hashes. An index of
// ZERO capacity is UNBUILT — static data arrives so, and the first
// lookup builds it. The word BEFORE a built index says which hash
// filed it (nonzero: the keyed fallback).
typedef struct {
    AvraArray* keys;
    AvraArray* vals;
    int64_t* index;   // slot + 1 in the low half, 0 when empty; the hash's high half above
    int64_t icap;
} AvraMap;

// A TASK BODY'S SITE rides in the sixteen bytes before its code: this
// mark, then how far from the code its `file:line` stands, as C text —
// a distance, so the loader rewrites nothing. The backend lays it there
// for a task's body; the scheduler reads it when a trace or a listing
// names the task. Code that carries none — C's own — is known by the
// mark's absence.
#define AVRA_SITE_MARK 0x4554495361727661ULL
typedef struct { uint64_t mark; int32_t away; int32_t spare; } AvraSite;

#endif
