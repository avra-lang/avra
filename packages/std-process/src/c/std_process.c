/* @std/process's OWN C. Every entry point answers an int: a token, a
   count, a handle, a descriptor, a tagged status, or a NEGATIVE
   errno. No text and no bytes cross here — a child's output rides the
   runtime's descriptor rows, which are the only door that mints a
   managed box (docs/2026_09_07_PACKAGE_C_STANDARD.md §2.5).  */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>

/* ── The stage ────────────────────────────────────────────────────
   THE WORDS FOR THE NEXT SPAWN, LANDED ONE AT A TIME. A spawn used to
   take `List<string>` argv and envp, which works only while it is a
   runtime ROW: the evaluator holds a list as a HANDLE into its own
   table, never as a box, so a package's extern could not be handed
   one and `corpus/process` would have lost its second engine. Landing
   the words is this tree's land-then-act idiom a fourth time — after
   the descriptor scratch, the io listing and the extern frame's own
   slots.

   TWO PROPERTIES ARE STRUCTURAL HERE, NOT CHECKED, because a stage
   that can be written wrong will be:

   SPARSE IS UNSPELLABLE. There is no index in this API. `word`
   APPENDS and answers the new count, so there is no way to write the
   third word without having written the second — an index-keyed
   `word(i, text)` could be called with 0 and 2 and leave a hole that
   reads as an empty argument.

   STALE IS REFUSED. Every stage carries a GENERATION, and a token
   from an abandoned one is refused by every verb that takes it. A
   caller who stages words and then fails before spawning cannot have
   those words picked up by the next spawn — which is the failure a
   plain "clear on spawn" leaves open, since the abandoned stage is
   never reached by a spawn at all.

   THE EMPTY CASE IS THE FIRST CASE: a stage opened and spawned with
   NO words and NO variables is a child run with argv holding only its
   own name, which is a legitimate spawn and not an error.  */

enum { PROC_WORDS = 4096, PROC_STAGE_BYTES = 1 << 20 };

static char* g_words[PROC_WORDS];
static char* g_vars[PROC_WORDS];
static int64_t g_nwords, g_nvars, g_stage_bytes;

/* 0 means NO STAGE IS OPEN. It only ever rises, so a token from an
   abandoned or spent stage can never name a later one. */
static int64_t g_stage_gen;

static void stage_freed(void) {
    for (int64_t i = 0; i < g_nwords; i++) free(g_words[i]);
    for (int64_t i = 0; i < g_nvars; i++) free(g_vars[i]);
    g_nwords = 0;
    g_nvars = 0;
    g_stage_bytes = 0;
}

/* A stage opened, and any stage still standing abandoned with it — a
   caller who failed between staging and spawning leaves nothing the
   next caller can spend. Answers the token every other verb carries. */
int64_t avra_proc_stage(void) {
    stage_freed();
    return ++g_stage_gen;
}

/* The stage let go without spawning. Idempotent: a token that is
   already spent names no stage and there is nothing to abandon. */
int64_t avra_proc_unstage(int64_t token) {
    if (token != g_stage_gen || g_stage_gen == 0) return 0;
    stage_freed();
    g_stage_gen++;
    return 0;
}

static int64_t staged(int64_t token, char** into, int64_t* n, const char* text) {
    if (token != g_stage_gen || g_stage_gen == 0) return -EINVAL;
    if (*n >= PROC_WORDS) return -E2BIG;
    size_t len = strlen(text);
    if (g_stage_bytes + (int64_t)len + 1 > PROC_STAGE_BYTES) return -E2BIG;
    char* copy = (char*)malloc(len + 1);
    if (!copy) return -ENOMEM;
    memcpy(copy, text, len + 1);
    into[*n] = copy;
    g_stage_bytes += (int64_t)len + 1;
    return ++(*n);
}

/* One argument appended; the new count, or -EINVAL for a token that
   names no open stage. */
int64_t avra_proc_word(int64_t token, const char* text) {
    return staged(token, g_words, &g_nwords, text);
}

/* One `NAME=VALUE` appended. An entry with no `=` names nothing the
   host can set, and it is refused HERE rather than at the spawn, so
   the caller learns which entry was wrong while it still knows. */
int64_t avra_proc_var(int64_t token, const char* text) {
    if (!strchr(text, '=')) return -EINVAL;
    return staged(token, g_vars, &g_nvars, text);
}

/* What the stage holds — the words, or the variables when `which` is
   1. For a caller that wants to check its own staging. */
int64_t avra_proc_staged(int64_t token, int64_t which) {
    if (token != g_stage_gen || g_stage_gen == 0) return -EINVAL;
    return which == 1 ? g_nvars : g_nwords;
}

/* ── Standing facts ───────────────────────────────────────────────*/

/* Whether the path names a file this process may execute: 0 yes,
   -errno otherwise. The `which` search is the LANGUAGE's to walk —
   this answers the one question C can answer and no more, the same
   split as @std/io's environment predicate. */
int64_t avra_proc_executable(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) return -errno;
    if (!S_ISREG(st.st_mode)) return -EACCES;
    return access(path, X_OK) == 0 ? 0 : -errno;
}
