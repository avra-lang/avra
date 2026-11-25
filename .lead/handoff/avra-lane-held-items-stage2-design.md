# STAGE 2: the program step composed from per-package pure parts (design, no code)

All numbers are for the 4-core box, -O1. Stage 1 leaves a fresh copy of the cli at **83.5–87.3 s**:

| Part | Wall |
|---|---|
| emit (step 4, with emit-speed) | ≈ 47 s |
| ahead phases over the project's own files | ≈ 9 s |
| **parent alone** | **≈ 16 s** |
| link + store save | ≈ 11 s |

The parent alone, from its own timers:

| Query | Time |
|---|---|
| refusals | 12.2 s inclusive |
| `program_reached` | 6.3 s inclusive, 2.4 s own |
| buckets asked | 3.8 s |
| `program_binary` | 5.8 s inclusive |
| code hashes | 1.2 s |
| `unit_facts` (reused) | 1.4 s over 46 318 asks |
| start-up / verify | 3.9 s |

## 1. What exists, and what this builds on

- **`program_reached`** (item_program.av) walks the entry's reach body by body (`walked_from`). Then it builds program-wide tables: `named` (`placed_names` per unit), `opens`, `called_shapes`, `program_seen` → each unit's `sees`, `declared`, stand-ins, hashed calls, and `unit_keys`.
  - On a warm edit it is FOLDED: `@folded_query(program_reached_again)` works through moved `unit_facts` / `placed_names` reads and redoes only the units they name.
  - A cold project has no earlier answer to fold from, so it walks all 46 k units, asking several queries per unit. Every one is reused from the machine store, but each ask is a lookup plus a record check plus a decode.
- **`program_refused`** (code-hash's eee83558 / 4bec2def) is already a FOLD over files: the union of `file_refused(file, entry, units, unlowered)` over `refusal_shape(file)`, plus `program_erring(package)`.
  - `file_refused` takes the REACHED units of the file, so its answer is per program even for a std file. Only its parts are pure (each body's own refusal, each file's law findings).
- **`program_code_hashes`** folds node digests over the moved nodes (`HashFold`, `node_moves`, rows of which targets reach each node).
- **`unit_facts`, `placed_code`, `placed_names`** are per unit and already machine-pure: the stage-1 trace kept them in the shared layer.
- **`ShapeAt`** reads the shape where it lies.
- **The stage-1 layer, the package-set table** (`packages_read`) and noop-speed's frontier (standing answers settled with no record walk) complete the picture.

**The rule this design keeps:** reach stays EXACT. It never becomes "every body of a touched package". A refusal, a stand-in and a code hash all mean "what this program reaches", so the per-package part must let the program step compute exact reach cheaply. It must not replace exact reach.

## 2. The units of reuse (each a pure question, kept in the machine store when its package set is machine)

### PACKAGE REACH TABLE: `package_reach(P)`
One answer per package, laid out as columns and read in place. It covers every non-generic body P declares that lowers without the program (`Package(P)` by the package-set rule), and holds per body:
- its symbol;
- its internal callees (body indices in P), and its external callees: (package, symbol), or a generic at type arguments;
- the facts the program step needs: the `declared` row (`BodySeen`), wrappers, extern rows, whether it is unlowered (a stand-in) and why, and its `sees` inputs (the names it reads, whose `BodySeen` decide its `sees`);
- its OWN refusal: `body_refuses` over its lowering, a bit plus a reason index;
- its code-hash node digest;
- its placement row (what `placed_names` / `placed_code` answer for it).

Plus, per file of P: the file's law findings (the `program_erring` part; a law refuses the file wherever it is reached).

Built from per-body queries that already exist and are already pure. Asked once per package per binary, then read where it lies.

### INSTANCE ROWS: `instance_reach(generic, type arguments)`
- One small answer per generic instance: the same columns for one body.
- Pure (machine) when every type argument is std, by the package-set rule; owned by the generic's package.
- At project types it is the project's own.
- The cli reaches 1 158 generic units.

### A project's own units
Today's per-unit queries, exactly as now.

## 3. What the program step joins, and its cost

`program_reached(file)` becomes:
1. **Walk.** A breadth-first walk from the entry over the project's own units. Each external edge into package P enters P's table at that body's index. Inside a table the walk follows column indices, with no query asked: the edges are numbers read in place. Generic edges ask `instance_reach` once per distinct instance.
2. **Reach.** The exact reach comes out as one bitset per touched package over its table, plus a list of instances, plus the project's units.
3. **The rest, all from the same rows:**
   - `declared`: concatenated by reference — a package's rows by its table's answer hash and the bitset, not copied;
   - `opens`, `called_shapes`, `sees`: from the table columns of the reached rows only;
   - stand-ins: the reached unlowered rows;
   - hashed calls: the reached rows whose callee is a code-hash target.

**The other program-level queries:**
- **`program_refused`** = the files a law refuses among the reached files (a file is reached iff a bit of its range is set) ∪ the reached bodies whose own refusal bit is set. The first-reached order comes from the walk, so the answer is exactly today's set and order. `file_refused` stays the per-file fold for the project's files and for a warm edit.
- **`program_code_hashes`** = for each target (few), fold the node digests over the target's sub-reach, inside tables, by bitset. Edges across packages are explicit columns.
- **Placement / bucket keys:**
  - Package buckets' keys come from the table (sorted symbol, lowering answer hash, sees) for the Package rows the program reaches. With step 4's reach-independent package objects, they come from the table alone.
  - Program buckets come from the project's units, as now.
- **`bucket_asked`** only for Program buckets.

**Cost for a project that is 3.5 % of the reach:**

| Part | Size | Cost |
|---|---|---|
| tables touched | ≈ 25 packages (+ 1 158 instance rows) | ≈ 1 200 asks, each reused and verified |
| walk | 46 k nodes at ~100 ns of column reads | ≈ 5 ms |
| project's own per-unit asks (3.5 %) | ≈ 1 600 units | ≈ 0.15 s, by stage-1 per-ask cost |
| refusals, code hashes, placement | per reached row by column | ≈ 0.1 s |
| **program step total** | | **≈ 0.3–0.5 s, vs ≈ 16 s today** |

**Start-up / verify (≈ 4 s today):** the machine segment gets a FRONTIER of its own (noop-speed's open side). Its inputs are the std files' stamps, and its answers are the shared ones. A project opens its own frontier and the machine's. If no std input moved, which is one stamp per std file (~700 stats), every machine answer STANDS with no record walk. That leaves ≈ 0.1–0.3 s, like the no-op build noop-speed measured. Needed from noop-speed: a frontier that can be read from a second store, and "kept" by many processes; the fold of the machine frontier happens in the layer.

## 4. Validation

- **`AVRA_REACH_CHECK=1`** (the shape of `AVRA_FOLD_CHECK`) computes the composed `program_reached` and the walked one, and DEFECTS where they differ: units, kept, sees, declared, refusals, code hashes, buckets.
  - It runs over every program test the `--ran` driver finds (606 in std-avrac), the refusal suite, and the cli.
  - The legacy walk stays as the check's reference until the switch.
- **`witness_machine_store.sh` gains (g):** a program whose reach changes, where an edit moves one std body's callee across a package edge. Its build over the warm machine store must equal cold.
- **The edit witness** runs with the store on, emptied and warm, as in stage 1. A signature edit inside a std package must refold that package's table, and only that.
- **Refusal suite:** unchanged counts; the composed `program_refused` must equal today's set and order, compared under `AVRA_REACH_CHECK`.

## 5. Cost on disk, memory, and the number

**Disk and memory:**
- A table is ≈ 100 B per body: 46 k bodies ≈ 5 MB per binary, plus instance rows ≈ 0.2 MB. Next to the 0.95 GB segment, this is nothing.
- The walk holds one bitset per touched package (46 k bits ≈ 6 KB).
- The machine frontier is ≈ 90 MB, the same order as the cli's own frontier today.

**THE NUMBER: a fresh project that is 3.5 % of the reach, 4 cores, -O1, over a warm machine store with step 4's package objects.**

| Part | Wall |
|---|---|
| start-up / verify, machine frontier | ≈ 0.3 s |
| the project's own front end (≈ 5 CPU-s over 4 workers) | ≈ 1.5 s |
| program step | ≈ 0.5 s |
| emit of Program objects (≈ 3.5 % of 177 CPU-s) | ≈ 1.6 s |
| link (lld, today) | ≈ 3 s, or 0.04 s with emit-speed's dev layered link (Linux) |
| own store save | ≈ 0.5 s |
| **TOTAL** | **≈ 7.4 s here with today's link (≈ 3.7 s on the Mac); ≈ 4.5 s here with the dev link (≈ 2.3 s Mac)** |

The target is 10 s here, 5 s on the Mac.

**Order of work:**
1. `package_reach` / `instance_reach` and the composed walk, under `AVRA_REACH_CHECK`.
2. `program_refused` and code hashes from the reached rows.
3. Placement and keys, with emit-speed's (B) and step 4.
4. The machine frontier, with noop-speed.

Each step lands behind `AVRA_MACHINE_STORE=1` and leaves the default product byte-identical.
