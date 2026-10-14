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
