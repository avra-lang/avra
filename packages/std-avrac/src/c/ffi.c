/* THE EXTERN HOST'S FRAME — the evaluator's way to call a linked C
   function by name, so `avra run` answers what `avra build` answers
   for a program that binds C.

   THIS IS THE COMPILER'S C AND NEVER A USER PROGRAM'S. Every binary
   the compiler emits links build/avra_runtime.o, so a symbol
   resolver placed there would ride inside every program anyone
   ships. This object is named only by @std.avrac's [link], and only
   packages/cli depends on that — so the reach lives in build/avra
   alone (docs/2026_09_07_PACKAGE_C_STANDARD.md §5.6.1).

   THE FRAME IS ONE FULLY APPLIED PROTOTYPE, not a table of shapes.
   The integer and floating register files are independent and each is
   filled in class order, so the k-th integer-class value lands in the
   same place whatever the seats interleave, and a callee reads only
   the registers its own prototype declares. So one call with every
   slot filled serves every fixed-arity scalar callee within the
   bounds below. The doubles never reach the stack, which is what
   makes the stacked integers land where an all-integer callee's do.

   IT NEVER MINTS. Every door that mints a managed box is a runtime
   row the evaluator hosts by an arm, so nothing here allocates and
   nothing here frees. `answer_text` CARRIES a pointer the callee
   owns — foreign or immortal text — which `make externs` is what
   proves: a C body that mints an owned box must be a row, and one
   that answers foreign text must not.  */

#include <stdint.h>
#include <string.h>
#include <dlfcn.h>

enum { AVRA_FFI_MAX_I = 10, AVRA_FFI_MAX_F = 8 };

/* THE STAGING AREA IS STATIC, AND THAT IS A CONDITION, NOT A DETAIL:
   it is correct only while an extern cannot call back into Avra.
   Nothing can today — no seat carries a callback. The day one does,
   a nested call overwrites the outer call's slots and the failure is
   a wrong argument rather than a crash, so this becomes a frame or
   the protocol breaks silently. */
static int64_t g_ffi_i[AVRA_FFI_MAX_I];
static double g_ffi_f[AVRA_FFI_MAX_F];

/* Every slot filled, so a stale value from an earlier call can never
   reach a callee that declares more seats than this one staged. */
void avra_ffi_reset(void) {
    memset(g_ffi_i, 0, sizeof g_ffi_i);
    memset(g_ffi_f, 0, sizeof g_ffi_f);
}

int64_t avra_ffi_max_int(void) { return AVRA_FFI_MAX_I; }
int64_t avra_ffi_max_f64(void) { return AVRA_FFI_MAX_F; }

/* A seat staged by index. Out of range is dropped rather than
   trapped: the caller checks the arity against the two maxima above
   and refuses first, so reaching here with a bad index is its defect
   and not a program's. */
void avra_ffi_set_int(int64_t k, int64_t v) {
    if (k >= 0 && k < AVRA_FFI_MAX_I) g_ffi_i[k] = v;
}

/* A double staged as its IEEE-754 BITS, which is how the evaluator
   holds a float — the bits cross, never a double, so no seat of ours
   is an FP register. */
void avra_ffi_set_f64(int64_t k, int64_t bits) {
    if (k >= 0 && k < AVRA_FFI_MAX_F) memcpy(&g_ffi_f[k], &bits, sizeof(double));
}

/* A text seat: the box the caller holds, passed as the pointer C
   reads. Avra hands it over borrowed and C must not keep it. */
void avra_ffi_set_text(int64_t k, const char* s) {
    if (k >= 0 && k < AVRA_FFI_MAX_I) g_ffi_i[k] = (int64_t)(uintptr_t)s;
}

/* The symbol in the running image, or 0 when there is none. Only the
   image: this resolves what build/avra already links, so a package
   whose object the compiler does not carry answers 0 and the caller
   refuses by name. */
int64_t avra_ffi_symbol(const char* name) {
    return (int64_t)(uintptr_t)dlsym(RTLD_DEFAULT, name);
}

#define AVRA_FFI_ARGS \
    g_ffi_i[0], g_ffi_i[1], g_ffi_i[2], g_ffi_i[3], g_ffi_i[4], \
    g_ffi_i[5], g_ffi_i[6], g_ffi_i[7], g_ffi_i[8], g_ffi_i[9], \
    g_ffi_f[0], g_ffi_f[1], g_ffi_f[2], g_ffi_f[3], \
    g_ffi_f[4], g_ffi_f[5], g_ffi_f[6], g_ffi_f[7]

#define AVRA_FFI_SEATS \
    int64_t, int64_t, int64_t, int64_t, int64_t, \
    int64_t, int64_t, int64_t, int64_t, int64_t, \
    double, double, double, double, double, double, double, double

typedef int64_t (*avra_ffi_word)(AVRA_FFI_SEATS);
typedef double (*avra_ffi_real)(AVRA_FFI_SEATS);

/* A word answer — an integer of any width, a pointer, or nothing.
   The WIDTH is the caller's to read back: a C `int` writes 32 bits
   and leaves the rest, so the evaluator extends by the seat's
   declared width exactly as the backend does. */
int64_t avra_ffi_call(int64_t sym) {
    return ((avra_ffi_word)(uintptr_t)sym)(AVRA_FFI_ARGS);
}

/* A double answer, handed back as BITS for the same reason the
   argument arrives as bits. */
int64_t avra_ffi_call_f64(int64_t sym) {
    double d = ((avra_ffi_real)(uintptr_t)sym)(AVRA_FFI_ARGS);
    int64_t bits;
    memcpy(&bits, &d, sizeof bits);
    return bits;
}

/* AN ANSWERED POINTER READ AS THE TEXT IT POINTS AT — a pure cast,
   no second call: the target ran once and its pointer is already in
   hand. Sound only for a body answering foreign or immortal text,
   which is the half of the ownership law `make externs` keeps — a
   body that MINTS an owned box must be a row, and a row is hosted by
   an arm and never reaches here. Nothing is adopted: the callee still
   owns the bytes and the evaluator only reads them. */
const char* avra_ffi_text_at(int64_t p) {
    return (const char*)(uintptr_t)p;
}
