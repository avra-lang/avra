# DB 01 · P4a2 — an owner's rows are a value

Lane note for the REVIEW9 repair of P4a2. It folds into
`2026_10_06_DB_01_ONE_ENGINE.md` when that note lands.

## 1. The law

Rows are a named owner's or no one's. An owner's rows are handed over as
a VALUE:

    Raised.replaced(db, "solve", rows)

files `rows` as the owner's and removes every row that owner held which
they do not name. Nothing is open between two statements: there is no
run to leave open, to open twice, or to adopt another writer's insert.

| Verb | Who | What |
|---|---|---|
| `Rel.replaced(db, owner, rows)` | every relation without `@unique` | generated; the one way an owner writes |
| `Rel.insert(db, …)` | anyone outside a `@query` body | the row is no one's |
| `Db.owner_named`, `Rows.put_owned`, `Rows.kept_of` | the declaration table ALONE | file by id; LICENSED in `tools/layers.py`, retired by `avra-8sb5.57.214` |

## 2. What carries each thing the mid-run read law refused

The law "a relation an open run wrote is read by no one until the run
closes" is deleted with the run. Nothing it refused is dropped:

| It refused | Carried now by | Held by |
|---|---|---|
| a read between an owner's first write and its last | CONSTRUCTION: `replaced` runs no caller code between them | the bracket has no spelling (`Db` has no method `opened_run`) |
| a query reading a relation, then replacing it (the self-read law's write half) | THE TORN-READ LAW: a write to a cell a query STILL RUNNING read this revision is refused on every Db, whatever it does with late writes, and does not land | `query/` (`looping`, heard, a plain Db), `quiet_torn_read/` (trap), `kernel_relation_hooks_test` |
| a settled reader left stale by a later write | THE LATE-WRITE LAW, unchanged in rule; a refused write now does not land, so the reader's rows are the rows it read | `owner_rows/`, `named_owner/` (`late`), `accessors/` (`hooked`) |
| two writers of one row | THE ONE-OWNER LAW; the voice names both sides, "no one's" among them | `owner_rows/`, `query/` (`rival`) |
| a query writing a row of its own | D4, now unconditional in a `@query` body: no open run can adopt it | `query/` (`ownerless`) |

A refused row ENDS a replacement: the rows after it are not filed and
nothing is removed.

## 3. The declaration table's window

`Decls.admit` cannot hand its rows over: `mint` answers an id at once,
later mints take it as parent, and some fifteen `set_decl` writes land
after admit returned. So it files by id and then says what it keeps.
Between its first `put_owned` and its `kept_of`, the file's rows are new
and stale together. Two things hold that today:

1. **Admit is synchronous and has one caller.** `Workspace.items(f)`
   calls it between `Items.start(f)` and `.finish`, with the file's
   `rows_state` at 0: `Decls.rows_read` records nothing for a file that
   is minting, and only admit's own callees run in between — they read
   `Decl` raw, by id.
2. **The late-write law.** `decl_rows` refuses late writes and traps. A
   put or a removal that moves a bucket a query read this revision is
   refused and does not land — the fifteen late `set_decl` writes are
   under it one by one. Held by `readmit_test`, "admitted again in the
   revision a settled query read a dropped name's bucket".

Rule 1 is a CONDITION, not a law: nothing refuses a reader that arrives
mid-admit. It expires the day admission can yield. `avra-8sb5.57.214`
carries it as a deadline.

## 4. Counted

- The graph counts a repeated read again (`Kernel.repeated`): one query
  reading two keys twice counts 4, as before P4a2. The one repeat in a
  cold `check packages/cli` is `Receivers` reading `Decl` whole, twice.
- Un-owned inserts under an open kernel query: `File` and `Module`,
  counted on `avra-8sb5.57.206`.
- A keyless owned relation leaves a tombstone per row per replacement:
  `avra-8sb5.57.211`.
