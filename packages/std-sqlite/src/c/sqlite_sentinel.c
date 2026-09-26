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
