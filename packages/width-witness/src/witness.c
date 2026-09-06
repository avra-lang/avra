/* THE WIDTH WITNESS — C bodies that answer NARROWER than 64 bits, so
   the extern seam can be held to what it promises.

   These live OUTSIDE the runtime on purpose. `make externs` refuses a
   C body WE OWN that answers narrow while being read as `int`, and it
   is right to: a deliberate witness in our own runtime IS that defect,
   and carving it an exemption would put a hole in the only tool that
   closes our half. The defect under test is precisely "a C body
   someone ELSE compiled answers narrower than we declared", and our
   runtime is by construction not that.

   THE DEFECT IS CALLEE-DEPENDENT AND SILENT, which is why these are
   hand-written and not borrowed from libc. This platform's `atoi` is
   `(int)strtol(...)`, so it answers correctly through a narrow extern
   and would give a FALSE GREEN; `witness_i32_neg` below, at -O2,
   answers 4294967295 from the same prototype. No test that runs a
   callee it happens to have can tell those apart — only the
   declaration can. */
#include <stdint.h>

/* ── narrow ANSWERS ── */
int      witness_i32_neg(void)  { return -1; }
int      witness_i32_min(void)  { return -2147483647 - 1; }
unsigned witness_u32_max(void)  { return 4294967295u; }
int64_t  witness_i64_neg(void)  { return -1; }

/* ── a narrow SEAT: the callee reads 32 bits of what it was handed ── */
int witness_seat32(int v) { return v + 1; }

/* ── narrow OUT-PARAMETERS: sqlite3_wal_checkpoint_v2's exact shape,
      a status and two `int*` the callee writes. Nineteen of SQLite's
      twenty-two scalar out-params are this; three are int64_t*. ── */
int witness_out_i32(int *a, int *b)      { *a = -1; *b = -2; return 0; }
int witness_out_u32(unsigned *out)       { *out = 4294967295u; return 0; }
int witness_out_i64(int64_t *out)        { *out = -42; return 0; }

/* ── a pointer out-parameter: sqlite3_open_v2's shape ── */
static char the_handle[8] = "HANDLE";
int         witness_open(const char *name, void **out) { *out = the_handle; return name ? 0 : 1; }
const char *witness_name(void *h)                      { return (const char *)h; }
void       *witness_null(void)                         { return 0; }
