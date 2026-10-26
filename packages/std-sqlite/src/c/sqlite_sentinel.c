/* THE DESTRUCTOR SENTINEL, AS ITSELF.
 *
 * `SQLITE_TRANSIENT` is a POINTER VALUE rather than a pointer to
 * anything: sqlite3 COMPARES the destructor seat against it and never
 * calls through it (sqlite3.h:6430). It is the only such constant this
 * driver needs — `SQLITE_STATIC` is a null pointer, which Avra spells
 * `null`.
 *
 * IT IS A DOOR OF ITS OWN SO THAT AVRA NEEDS NO WAY TO BUILD A POINTER
 * FROM AN INTEGER. A general `ptr_at(address)` would answer this
 * constant and every other address besides, and a capability that wide
 * cannot be made safe by any check the runtime can write — it can only
 * be made unnecessary. This body is what makes it unnecessary.
 *
 * The value comes FROM THE HEADER rather than being written as -1, so a
 * library that ever respells its sentinel takes this with it. The cast
 * is function-pointer to object-pointer, which sqlite3 itself performs
 * at every call site of this macro.
 */
#include "sqlite3.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void* avra_sqlite_transient(void) { return (void*)SQLITE_TRANSIENT; }

/* A BORROWED, NUL-TERMINATED BUFFER'S LENGTH.
 *
 * `sqlite3_column_name` answers "a zero-terminated UTF-8 string"
 * (sqlite3.h) with no companion length function the way
 * `sqlite3_column_text`/`sqlite3_column_blob` pair with
 * `sqlite3_column_bytes` — so this measures it, the one wall answer
 * where the length is not already a call away.
 */
int64_t avra_sqlite_cstr_len(const void* p) { return p ? (int64_t)strlen((const char*)p) : 0; }

/* EVERY SLEEP SQLITE TAKES HOLDS THE WORLD.
 *
 * SQLite sleeps through one door, its VFS's `xSleep`: a busy handler's
 * backoff, WAL's read retry and `sqlite3_sleep` alike. The default VFS
 * is therefore the platform's own with that one method wrapped in a
 * hold on the clock, so a virtual clock flows across the wait and stands
 * still everywhere else — a step that never sleeps pays nothing.
 *
 * A CONNECTION KEEPS THE VFS IT WAS OPENED UNDER, so this stands before
 * the first open. The copy keeps the platform's name: its methods read
 * the name and the data they are handed, never the address.
 */
void avra_clock_hold(int64_t by);
void avra_trap(const char* message) __attribute__((noreturn));

static sqlite3_vfs* g_platform = NULL;
static sqlite3_vfs g_held;

static int held_sleep(sqlite3_vfs* vfs, int micros) {
    (void)vfs;
    avra_clock_hold(1);
    int slept = g_platform->xSleep(g_platform, micros);
    avra_clock_hold(-1);
    return slept;
}

void avra_sqlite_sleeps_held(void) {
    if (g_platform) return;
    sqlite3_vfs* platform = sqlite3_vfs_find(NULL);
    if (!platform) avra_trap("SQLite names no file system to hold its sleeps under");
    g_held = *platform;
    g_held.pNext = NULL;
    g_held.xSleep = held_sleep;
    g_platform = platform;
    if (sqlite3_vfs_register(&g_held, 1) != SQLITE_OK) avra_trap("SQLite refused the file system that holds its sleeps");
}

/* THE CONNECTIONS THIS PROCESS HAS OPEN, PARKED BEFORE A FORK.
 *
 * SQLite keeps per-file state per PROCESS — a connection's locks, a WAL's shared-memory node
 * naming the descriptors that were open when it was made — and a fork copies that state while the
 * cores' fork closes the descriptors it names. A connection carried over would hand its stale state
 * to the child's own, whose locks then fail or land on whatever file reused the number. So before
 * the cores fork, every file-backed connection is CLOSED FOR REAL, in the parent, while its
 * descriptors are valid; each process opens its own again the first time it uses it (`Db.live`
 * and `Stmt` compare the epoch they were made under with this one).
 *
 * A connection that holds a transaction, or a statement mid-run, is not the driver's to roll back:
 * the fork is refused and nothing is closed. The verdict is made over every connection before any
 * is touched, so a refusal leaves the process exactly as it was.
 */
extern void avra_fork_hook(int (*prepare)(const char** why));

static sqlite3** g_open = NULL;
static int g_open_count = 0, g_open_cap = 0;
static int64_t g_epoch = 0;

void avra_sqlite_opened(void* db) {
    if (g_open_count == g_open_cap) {
        int cap = g_open_cap ? g_open_cap * 2 : 8;
        sqlite3** grown = (sqlite3**)realloc(g_open, (size_t)cap * sizeof(sqlite3*));
        if (!grown) return;
        g_open = grown;
        g_open_cap = cap;
    }
    g_open[g_open_count++] = (sqlite3*)db;
}

void avra_sqlite_closed(void* db) {
    for (int i = 0; i < g_open_count; i++) {
        if (g_open[i] == (sqlite3*)db) { g_open[i] = g_open[--g_open_count]; return; }
    }
}

int64_t avra_sqlite_epoch(void) { return g_epoch; }

/* Why a connection cannot be closed for a fork, in words the fork's refusal carries; null when it can. */
static char g_why[256];
static const char* holds_work(sqlite3* db) {
    if (sqlite3_get_autocommit(db) == 0) {
        const char* file = sqlite3_db_filename(db, "main");
        snprintf(g_why, sizeof g_why, "a database connection holds a transaction open (%.100s) — commit or roll it back before serving across cores", file ? file : "?");
        return g_why;
    }
    for (sqlite3_stmt* s = sqlite3_next_stmt(db, NULL); s; s = sqlite3_next_stmt(db, s)) {
        if (sqlite3_stmt_busy(s)) {
            snprintf(g_why, sizeof g_why, "a database statement is mid-run (%.120s) — finish or reset it before serving across cores", sqlite3_sql(s));
            return g_why;
        }
    }
    return NULL;
}

static int parked(const char** why) {
    for (int i = 0; i < g_open_count; i++) {
        const char* held = holds_work(g_open[i]);
        if (held) { *why = held; return 1; }
    }
    for (int i = 0; i < g_open_count; i++) {
        for (sqlite3_stmt* s; (s = sqlite3_next_stmt(g_open[i], NULL));) sqlite3_finalize(s);
        sqlite3_close_v2(g_open[i]);
    }
    g_open_count = 0;
    g_epoch++;
    return 0;
}

__attribute__((constructor)) static void registered(void) { avra_fork_hook(parked); }
