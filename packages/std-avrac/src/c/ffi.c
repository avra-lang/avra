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
#include <signal.h>
#include <unistd.h>

enum { AVRA_FFI_MAX_I = 10, AVRA_FFI_MAX_F = 8 };

/* THE STAGING AREA IS STATIC, AND THAT IS A CONDITION, NOT A DETAIL:
   it is correct only while an extern cannot call back into Avra.
   Nothing can today — no seat carries a callback. The day one does,
   a nested call overwrites the outer call's slots and the failure is
   a wrong argument rather than a crash, so this becomes a frame or
   the protocol breaks silently. */
static int64_t g_ffi_i[AVRA_FFI_MAX_I];

/* THE CELLS A `mut` SEAT POINTS AT. An inout hands C the ADDRESS of
   the caller's cell, so the frame needs storage whose address is
   stable across the call: the staging slot holds that ADDRESS, and
   this holds the value the callee reads and writes. One per integer
   slot, because a `mut` seat's ABI kind is always a pointer and every
   pointer rides the integer file. */
static int64_t g_ffi_cell[AVRA_FFI_MAX_I];
static double g_ffi_f[AVRA_FFI_MAX_F];

/* Every slot filled, so a stale value from an earlier call can never
   reach a callee that declares more seats than this one staged. */
void avra_ffi_reset(void) {
    memset(g_ffi_i, 0, sizeof g_ffi_i);
    memset(g_ffi_f, 0, sizeof g_ffi_f);
    memset(g_ffi_cell, 0, sizeof g_ffi_cell);
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
/* OCTETS AT A SEAT, and NO crossing check on them. A `Bytes` seat says
   the callee was given a length beside the pointer — a prototype that
   carries its own length, which is what the exception is actually
   about — so a NUL inside is DATA and there is nothing ambiguous to
   refuse. `sqlite3_bind_text(stmt, i, text, n, …)` is the shape. */
void avra_ffi_set_bytes(int64_t k, const char* b) {
    if (k >= 0 && k < AVRA_FFI_MAX_I) g_ffi_i[k] = (int64_t)(uintptr_t)b;
}

extern const char* avra_str_crossing(const char* s);

void avra_ffi_set_text(int64_t k, const char* s) {
    /* EVERY CALLEE THAT REACHES THIS FRAME IS A NON-ROW: both engines
       ask the registry first, and a declaration that names a row IS
       the row and dispatches there. A non-row's C is not ours to
       certify and its row is built at the default, so nothing
       arriving here is inert and the check is unconditional — the
       same helper the backend emits at its own seam. */
    if (k >= 0 && k < AVRA_FFI_MAX_I) g_ffi_i[k] = (int64_t)(uintptr_t)avra_str_crossing(s);
}

/* The symbol in the running image, or 0 when there is none. Only the
   image: this resolves what build/avra already links, so a package
   whose object the compiler does not carry answers 0 and the caller
   refuses by name. */
int64_t avra_ffi_symbol(const char* name) {
    return (int64_t)(uintptr_t)dlsym(RTLD_DEFAULT, name);
}

/* A `mut` SEAT: cell k seeded with the caller's value, and slot k
   filled with that cell's ADDRESS. Seeded rather than zeroed because
   an inout is not always an out — a callee may read what it was
   handed before writing. */
void avra_ffi_set_cell(int64_t k, int64_t v) {
    if (k >= 0 && k < AVRA_FFI_MAX_I) {
        g_ffi_cell[k] = v;
        g_ffi_i[k] = (int64_t)(uintptr_t)&g_ffi_cell[k];
    }
}

/* What the callee left in cell k, WHOLE. The caller normalises by the
   width its row declares: a C `int*` writes 32 bits and leaves the
   top half of this stale, so reading it as an `int64_t` and believing
   it is the silent wrong answer this seam exists to avoid. */
int64_t avra_ffi_cell_at(int64_t k) {
    return (k >= 0 && k < AVRA_FFI_MAX_I) ? g_ffi_cell[k] : 0;
}

/* A PACKAGE'S LIBRARY, OPENED RTLD_LOCAL — and the flag is the whole
   design rather than a detail. RTLD_GLOBAL would put the library's
   symbols into the PROCESS's namespace, where `dlsym(RTLD_DEFAULT)`
   finds them for every later lookup by anyone; and `avra corpus` runs
   every program in ONE PROCESS. So under RTLD_GLOBAL the first
   program that depends on a package would open its library and every
   LATER program in that run would reach its symbols, declared
   dependency or not — a program PASSING where it should have been
   refused, with which programs leak decided by the order the corpus
   walks its directories. A green run is what that looks like.

   RTLD_LOCAL is the default when neither flag is given; it is written
   out because a reader must not have to know that.

   THE HANDLE IS AN INTEGER THE CALLER HOLDS. Nothing is remembered
   here: a handle set is per-PROGRAM identity, and C state would
   outlive the program that opened it — RTLD_GLOBAL's leak wearing a
   stale field. The evaluator holds them and hands one over per ask,
   which is also why this takes ONE handle and not a list: an
   aggregate cannot cross an extern seat (F2056), and the loop belongs
   where the identity lives. */
int64_t avra_ffi_open(const char* path) {
    void* h = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    return (int64_t)(uintptr_t)h;
}

/* The symbol in ONE opened library, or 0. A handle of 0 is not a
   library and answers 0 rather than reaching the process. */
int64_t avra_ffi_symbol_in(int64_t handle, const char* name) {
    if (handle == 0) return 0;
    return (int64_t)(uintptr_t)dlsym((void*)(uintptr_t)handle, name);
}

/* THE FRAME'S FAULT GUARD, and the reason it guards the FAULT and not
   the null. A foreign body is not ours to certify: it may read a
   pointer the program handed it and wreck, and under `avra run` that
   wreck lands in the COMPILER's own process — exit 139, no words,
   indistinguishable from a defect of ours. A NULL at a host seat is
   the way a program reaches it, and the null is NOT the fault: C's
   own conventions spend the null pointer as a value, `free(NULL)` is
   defined, and @std/sqlite hands `SQLITE_STATIC` — a null — at every
   bind seat and means it. Refusing the null would refuse those, and
   mint a divergence where the engines agree today. So the verdict is
   raised where the wreck is: a SIGSEGV or SIGBUS taken while the frame
   is inside a callee becomes a TRAP, whose words name the callee and
   every seat that carried absence into it.

   THE HANDLER IS ASYNC-SIGNAL-SAFE BY CONSTRUCTION. The words are
   composed by the caller BEFORE the call and copied here, so the fault
   path is one `write` and one `_exit` — no formatting, no allocation,
   nothing that could fault again. A fault taken OUTSIDE a hosted call
   is none of the frame's business: the disposition goes back to the
   default and the instruction re-faults, so a defect of the compiler's
   own still wrecks exactly as it did, with the same signal. */
enum { AVRA_FFI_WORDS = 512 };
static char g_ffi_words[AVRA_FFI_WORDS];
static volatile sig_atomic_t g_ffi_words_len = 0;
static volatile sig_atomic_t g_ffi_in_call = 0;
static int g_ffi_guarded = 0;

static void ffi_faulted(int sig) {
    if (!g_ffi_in_call) {
        signal(sig, SIG_DFL);
        return;
    }
    (void)write(STDERR_FILENO, "avra: ", 6);
    (void)write(STDERR_FILENO, g_ffi_words, (size_t)g_ffi_words_len);
    (void)write(STDERR_FILENO, "\n", 1);
    _exit(2);
}

/* The verdict a fault inside the NEXT call will wear. Armed per call
   because the callee and the seats it was handed are what the words
   name; the handler is installed on the first one, so a run that hosts
   no extern carries no handler at all. */
void avra_ffi_arm(const char* words) {
    size_t n = 0;
    if (!g_ffi_guarded) {
        signal(SIGSEGV, ffi_faulted);
        signal(SIGBUS, ffi_faulted);
        g_ffi_guarded = 1;
    }
    while (n + 1 < AVRA_FFI_WORDS && words[n]) n++;
    memcpy(g_ffi_words, words, n);
    g_ffi_words[n] = 0;
    g_ffi_words_len = (sig_atomic_t)n;
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
    int64_t answer;
    g_ffi_in_call = 1;
    answer = ((avra_ffi_word)(uintptr_t)sym)(AVRA_FFI_ARGS);
    g_ffi_in_call = 0;
    return answer;
}

/* A double answer, handed back as BITS for the same reason the
   argument arrives as bits. */
int64_t avra_ffi_call_f64(int64_t sym) {
    double d;
    int64_t bits;
    g_ffi_in_call = 1;
    d = ((avra_ffi_real)(uintptr_t)sym)(AVRA_FFI_ARGS);
    g_ffi_in_call = 0;
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
