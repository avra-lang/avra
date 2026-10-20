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
    int32_t kind_word;
    int32_t rc;
    uint32_t len;
} Header;

// THE KIND WORD holds three fields in its four bytes, low byte first: the
// kind (-8..4, signed), the flags, and a 16-bit STAMP. Every reader asks for
// exactly its field. A box a site has read is OBSERVED (flag bit 0): the
// first write to it in a turn stamps it with the turn's number and logs it
// once, and later writes that turn only compare. A static box carries
// 0xFF in its flags byte, which is not the observed value, so it never logs.
static inline int32_t avra_kind(const Header* h) { return (int8_t)h->kind_word; }
static inline void avra_set_kind(Header* h, int32_t kind) {
    h->kind_word = (int32_t)(((uint32_t)h->kind_word & 0xFFFFFF00u) | ((uint32_t)kind & 0xFFu));
}

#define AVRA_FLAGS_MASK     0x0000FF00u
#define AVRA_OBSERVED       0x00000100u
#define AVRA_STAMP_MASK     0xFFFF0000u
#define AVRA_STAMP_ONE      0x00010000u

// The current turn's stamp, already in place (the stamp field's bits).
extern uint32_t avra_turn_word;
// Out of line: stamp the box and file it in the turn's change log.
void avra_box_changed(void* payload);

// A write to a box: for a box no site has read, a byte compared in place.
// The flags are their own byte, so the test loads and masks nothing and
// clobbers no register; the stamp is read only for an observed box.
#if !defined(__BYTE_ORDER__) || __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error "the kind word's fields are read by byte position, which assumes a little-endian target"
#endif
#define AVRA_FLAGS_AT 5
#define AVRA_STAMP_AT 6
static inline void avra_box_touch(void* payload) {
    const uint8_t* at = (const uint8_t*)((Header*)payload - 1);
    if (__builtin_expect(at[AVRA_FLAGS_AT] == (AVRA_OBSERVED >> 8), 0)) {
        uint16_t stamp;
        __builtin_memcpy(&stamp, at + AVRA_STAMP_AT, sizeof stamp);
        if (stamp != (uint16_t)(avra_turn_word >> 16)) avra_box_changed(payload);
    }
}

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

// A TASK BODY'S SITE is a row of the program's site table: the body's
// entry and where it was written, `file:line` as C text. The backend
// files one row for each task body in the section named here; the
// scheduler names a task by the row whose entry is its body's, and code
// no row names — C's own — by its address. Nothing reads code's bytes.
typedef struct { const void* code; const char* site; } AvraSiteRow;
#define AVRA_SITES_MACHO_SEGMENT "__DATA"
#define AVRA_SITES_MACHO_SECTION "__avra_sites"
#define AVRA_SITES_ELF_SECTION "avra_sites"

#endif
