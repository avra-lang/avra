# @std/sqlite

SQLite, vendored and compiled into the binary. No daemon, no server, no
container: the database is a file and the driver is in the program (P14).

The design is `docs/2026_09_05_STD_SQLITE_VISION.md`: the WALL declares
`sqlite3_*` entry points by their own names, and the FACE is curated and
written in the wall's terms, so dropping from one to the other is a
continuation rather than an escape.

**The wall is not total yet, and this line says how far it is.** 84 of the
357 entry points the object exports are declared — the library, connection,
statement, column and binding families. The door to most of the rest is one
declaration that cannot be written: `sqlite3_open_v2` answers its handle
through a `sqlite3**`, an `extern fn` refuses a `mut` seat, and 59
entry points wait behind it. `src/c/CENSUS.md` counts them exactly and says
what each remaining class needs.

## What this package's boundary is (P9)

**A program that hands `@std/sqlite` arbitrary SQL has handed it the
filesystem.** SQL can `ATTACH` a database file anywhere the process can
write, creating it if absent, and no compile flag, pragma or bindable
entry point turns that off — `SQLITE_DBCONFIG_ENABLE_ATTACH_CREATE` and
`_ATTACH_WRITE` are settable only through `sqlite3_db_config`, which is
variadic and permanently unbindable (`src/c/CENSUS.md` §19).

This is stated, not apologised for. The mechanism that will close it is
`sqlite3_set_authorizer`, which refuses `SQLITE_ATTACH` semantically at
prepare time — from the parser, so it sees the statement rather than its
spelling. That is a scheduled requirement, arriving with the driver's
callback support, and it is tracked as one.

**Nothing here text-scans SQL.** Matching `ATTACH` in text the driver
does not parse is a blocklist on a language it cannot read, and it would
refuse legitimate cross-database work besides.

Keep it in proportion: arbitrary SQL against a fixed database was already
a write primitive for that database, and `ATTACH` escalates it to the
filesystem. Both are why this driver's answer to untrusted input is BOUND
PARAMETERS and never SQL filtering.

The general rule the same section states: **the header is not a statement
of what the library exports; `nm` is.** 362 entry points are declared
under our flags and 357 are in the object.

## The vendored source

SQLite is vendored, not linked from the system. Apple's build omits
`SQLITE_ENABLE_COLUMN_METADATA`, `DESERIALIZE` and `SESSION`, so "full
surface" is literally unreachable on it — and a driver whose behaviour
depends on the OS release cannot be tested.

| | |
|---|---|
| version | **3.53.4** (`SQLITE_VERSION_NUMBER` 3053004) |
| source id | `2026-07-24 19:02:57 bf7c7f30031888f4e796e429ab3978879485813aaca6f641c7b33e4e09459bcc` |
| downloaded from | `https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip` |
| downloaded on | 2026-09-05 |
| zip size | 2 946 650 bytes |

The two version encodings are different and must not be confused: the
DOWNLOAD filename is `X*1000000 + Y*10000 + Z*100` (3.53.4 → `3530400`), and
`SQLITE_VERSION_NUMBER` is `X*1000000 + Y*1000 + Z` (3.53.4 → `3053004`).
The URL carries the YEAR OF RELEASE, not the current year.

### Checksums, verified on download

The zip's SHA3-256 matches the one sqlite.org publishes on its download
page — that is the check that makes the download trustworthy, and it is the
one to repeat when the version moves.

```
zip   sha3-256  628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e   (matches sqlite.org)
zip   sha256    1e71ddf93849c6a6ecf58b827c0692073d2dd7ee40196158068f7b29f422e87d

vendor/sqlite3.c     sha256  b1dd5d74ec7f29055a6684fa06fb3c2f6821c87dd38f9a458dfd2e8a1db28189   9 515 341 bytes
vendor/sqlite3.h     sha256  919e7f2e8ed1d8f56ac17b412b8971c76aa5d1a879752cc6058f75e7d5910e1d     690 838 bytes
vendor/sqlite3ext.h  sha256  ac9645e5c9ff0cf176efdd6e75cb5e98f46295d38e02db5c4d208826a39ab4be      39 175 bytes
```

To re-verify what is in the tree:

```
shasum -a 256 packages/std-sqlite/vendor/sqlite3.c
openssl dgst -sha3-256 sqlite-amalgamation-3530400.zip    # against sqlite.org's published digest
```

`shell.c` ships in the zip and is not vendored: it is the `sqlite3`
command-line tool, a separate program with its own dependencies.

`vendor/sqlite3.c` is ~9 MB of C. It is not Avra source and must not be
walked by `make idioms`, the gate, or any tool that globs the tree.

## The flags

`vendor/FLAGS.md` carries the set and a reason for each flag, the two
places it diverges from sqlite.org's recommended set (each divergence
measured, each because the recommended flag turns a caller's mistake into a
segmentation fault), and the compile's measured cost.

Every flag is observable at runtime through `sqlite3_compileoption_used`, so
the flag set is asserted by a test rather than claimed by a build file.
