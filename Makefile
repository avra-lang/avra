# THE COMPILER BUILDS ITSELF. `build/avra` is the working binary and
# `make avra` rebuilds it with the binary already there; a cold tree
# bootstraps from the seed (`make bootstrap`, or `./avra` on its own).
# What links what:
#   build/llvm_wrapper.o  OURS — backend/llvm_wrapper.c, the
#                         compiler's LLVM binding; new builders are
#                         added there, never hunted for upstream.
#   build/avra_runtime.o  OURS — runtime/avra_runtime.c, the native
#                         half of the LANGUAGE's semantics; the only
#                         runtime avra-built programs link.
#   build/<stem>.o        A PACKAGE'S — its C under src/c/, or a
#                         vendored unit under vendor/, named by its
#                         manifest's [link].
# ONE RULE builds all of them, the two above included: every object in
# this tree comes from `build/%.o: %.c` and from nowhere else.

LLVM_PREFIX ?= /opt/homebrew/opt/llvm
# a manifest's link flags name it as ${LLVM_PREFIX}
export LLVM_PREFIX

# The objects the COMPILER itself links: the runtime every program
# carries, and the compiler's own foreign machinery (the LLVM wrapper,
# the evaluator's extern trampoline), which no user program does. The
# name says COMPILER because that is what it is — a user's binary
# links build/avra_runtime.o and nothing else here.
#
# ONE LIST, NOT TWO. The bootstrap's clang line spells its inputs, and
# spelling them twice is a law waiting to disagree with itself: the
# trampoline was added to one and not the other, and the seed-built
# compiler would have failed to link the day the seed was refreshed.
#
# THIS IS WHAT THE BOOTSTRAP LINKS BY HAND, NOT WHAT THE COMPILER'S
# BUILD NEEDS ON DISK. `make avra` runs `./avra build packages/cli`,
# which links every `[link]` object in that package's dependency
# closure — @std/io's among them — so a build that depended on this
# list alone fails on a tree where the package's object was never
# made. It did, twice: once for the trampoline and once for @std/io's
# own C. So each target depends on WHAT IT LINKS, and the two lists
# below are that split.

# EVERY OBJECT THIS TREE COMPILES, ONE RULE. The language's own C
# (runtime/, and the compiler's LLVM binding in backend/) and a
# package's C — its own under src/c/, a vendored translation unit
# under vendor/ — all compile to build/<stem>.o, and a package's
# manifest names that object in its [link]: A MANIFEST SAYS WHAT TO
# LINK, NEVER HOW TO BUILD IT, and this rule is the how
# (docs/2026_09_07_PACKAGE_C_STANDARD.md). The sources are GLOBBED,
# never listed — a hand-written list forgets its next member, and
# build/sqlite3.o had no rule at all for a day — so a new package's C
# is built without a line here. ONE HOW FOR EVERY OBJECT is the point:
# a hand-written rule beside the pattern SHADOWS it (make prefers the
# explicit one), so a package source named avra_runtime.c was compiled
# by nobody while its manifest linked the runtime. Our own C is held
# to -Wall -Werror; a vendored unit takes its author's flags
# (CFLAGS_<stem>) and no warning of ours.
TREE_C := $(wildcard packages/*/src/c/*.c packages/*/vendor/*.c backend/*.c runtime/*.c)
vpath %.c $(sort $(dir $(TREE_C)))

# A STEM NAMES ITS OBJECT, so a stem is UNIQUE TREE-WIDE. One flat
# build/ holds every object and vpath answers the FIRST directory
# carrying a name, so two packages with a src/c/util.c compile ONE of
# them and the other's manifest links an object built from someone
# else's source. The law is named HERE because the link cannot name
# it: it fails on a symbol that does exist in the tree, in a file
# nothing ever compiled. Make expands a rule's prerequisites as it
# READS them, so a clash refuses every target, `clean` included —
# nothing but renaming a file fixes it anyway. tools/stems.sh drives
# these lines with synthetic sources; there is no second copy.
#
# AND THE COMPARISON FOLDS CASE, because `build/` is a DIRECTORY and
# not a set of names: on the volumes this tree builds on it does not
# tell `util.o` from `Util.o`, so `a/util.c` beside `b/Util.c` has
# distinct spellings and ONE object. Proved rather than argued — both
# compiled, `build/Casestem.o` was never a separate file, and
# `build/casestem.o` carried the other package's symbol, with the law
# reporting the tree fine. The clash is read in ONE pass that answers
# the FILES, so nothing has to search a folded stem back to its
# spelling; groups come out ordered by that stem, since an awk map's
# own order must never reach output.
TREE_CLASH := $(strip $(shell printf '%s\n' $(TREE_C) \
  | awk -F/ '{ s = tolower($$NF); sub(/\.c$$/, "", s); n[s]++; f[s] = f[s] " " $$0 } \
              END { for (s in n) if (n[s] > 1) print s "\t" f[s] }' \
  | sort | cut -f2))
TREE_STEM_LAW = $(if $(TREE_CLASH),$(error A STEM NAMES ITS OBJECT, \
  so a stem is unique tree-wide — one flat `build/` holds every object \
  and does not tell `u.c` from `U.c` — rename one of: $(TREE_CLASH)))

# A TARGET DEPENDS ON WHAT IT LINKS, AND ON NOTHING ELSE. Two lists,
# because there are two kinds of link and one list served neither
# well: depending on every object made `make avra` compile the 9.5 MB
# vendored amalgamation for a binary that never links it, and
# depending on a hand-kept list let `make avra` link an object it had
# never built — twice, the trampoline and then @std/io's own C.
#
# COMPILER_OBJS is what `build/avra` itself links: the runtime every
# program carries, plus the compiler's own foreign machinery, plus
# every package in the cli's dependency closure whose manifest names
# an object. The bootstrap's clang line takes this same variable, so
# the two can never be a list and its copy. @std/io's object is here
# because the SEED-BUILT compiler links it — a compiler that cannot
# open a file cannot compile the tree it was built for — so a package
# object in the compiler's own closure is BOTH a package object and a
# compiler one, and belongs here the day its package lands.
COMPILER_OBJS = $(TREE_STEM_LAW)build/avra_runtime.o build/llvm_wrapper.o \
                build/ffi.o build/std_io.o build/std_process.o

# PACKAGE_OBJS is every object a package's `[link]` row names — what a
# target that RUNS programs may need, since any package's suite or
# program tests can link its own C.
PACKAGE_OBJS = $(TREE_STEM_LAW)$(sort $(foreach o,$(shell sed -n \
  's/.*objects *= *\[\(.*\)\].*/\1/p' packages/*/avra.toml | tr ',' '\n' \
  | tr -d ' "'),build/$(notdir $(o))))

# PER-OBJECT FLAGS, by stem. The LLVM binding needs its headers; the
# vendored amalgamation takes its author's whole flag set, which its
# own suite asks the LIBRARY to confirm.
CFLAGS_llvm_wrapper := -I$(LLVM_PREFIX)/include
CFLAGS_sqlite3 = $(SQLITE_FLAGS)
CFLAGS_sqlite_sentinel := -Ipackages/std-sqlite/vendor

# A HEADER IS A SOURCE. cc writes each object's dependency list beside
# it and the next make reads it back, so editing a .h rebuilds what
# includes it — without this a package that grows a header links a
# stale object and the defect is attributed to the compiler. The
# include is silent on a cold tree, where no .d exists yet.
build/%.o: %.c build/%.sha
	@mkdir -p build
	cc -c -O2 -MMD -MP $(if $(findstring /vendor/,$<),,-Wall -Werror) $(CFLAGS_$*) -o $@ $<

-include $(patsubst %.o,%.d,$(sort $(COMPILER_OBJS) $(PACKAGE_OBJS)))

# Every package that carries tests, in dependency order — DERIVED from
# the manifests (tools/suites.py), never listed: a hand-kept list is a
# registry that forgets its next member, and the gate would report
# green over a suite it never ran. `suites` is the keeper that speaks.
SUITES := $(shell python3 tools/suites.py 2>/dev/null)

.PHONY: census traps test tested clean seed-check gate externs idioms idioms-accept bench fuzz scaffold-check vocab stems sweep seed recover bootstrap libs libscope \
        check run ir emit build-native native-check avra suites install

# THE COMPILER, BUILT BY ITSELF: the binary in build/ compiles the
# tree into the next one. `./avra` prefers it and bootstraps a cold
# tree only.
# THE SEED: the compiler, emitted, so the chain cannot be lost.
# `make bootstrap` builds a compiler from it and then rebuilds from
# source; `make seed` refreshes it. bootstrap/README.md holds the rule.
#
# THE DEFAULT GOAL IS NAMED, because make's own default is the FIRST
# TARGET and that is `seed` — so a bare `make`, or `make -p` to read a
# variable, silently rewrote the committed 9.5 MB bootstrap with
# whatever the standing binary emitted. A seed regenerated by accident
# is a seed nobody chose, and it is large enough to ride into a commit
# unread.
.DEFAULT_GOAL := avra

seed: $(COMPILER_OBJS)
	@./avra emit packages/cli > bootstrap/seed.ll
	@echo "seed: bootstrap/seed.ll ($$(wc -l < bootstrap/seed.ll | tr -d ' ') lines)"

# THE ONLY RULE THAT LINKS BY HAND, and the one a cold tree and every
# recovery must take — `seed` and `avra` link through the compiler.
# So the object list is named ONCE: a prerequisite and a link line
# spelling it twice were two definitions nothing kept in step, and the
# gap opens silently the instant the variable grows.
#
# AND RECOVERY STOPS HERE. `make bootstrap` continues into `make avra`,
# which overwrites this clean compiler with one built from the CURRENT
# source — so a source that traps while compiling itself (a probe in an
# analysis path, a broken pass) has no way back: every rebuild traps
# again. `make recover` is that way back.
recover: $(COMPILER_OBJS)
	@mkdir -p build
	@clang -w -O1 bootstrap/seed.ll $(COMPILER_OBJS) \
	    -L$(LLVM_PREFIX)/lib -lLLVM -o build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@echo "recover: build/avra from the seed — a clean compiler, not rebuilt from source"

bootstrap: recover
	@echo "bootstrap: rebuilding build/avra from source"
	@$(MAKE) -s avra

# A REFUSAL MUST SPEAK: the build's own words went to /dev/null, so a compiler
# that refused its own source reported only "make: *** Error 2" and the next
# reader ran `./avra build packages/cli` by hand to find out why.
avra: $(COMPILER_OBJS)
	@mkdir -p build
	@: > build/avra-build.out
	@./avra build packages/cli >> build/avra-build.out 2>&1 || { tail -c 200000 build/avra-build.out; exit 1; }
	@mkdir -p build
	@cp packages/cli/src/main build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@rm -f packages/cli/src/main packages/cli/src/main.av.ll
	@echo "avra: build/avra"

# THE INSTALL: the binary under bin/, and what it finds from its own
# directory — the runtime's object and every std package — under
# lib/avra/. A program anywhere then says `use @std.io` with no
# manifest row, and links.
PREFIX ?= /usr/local
install: avra
	@mkdir -p $(PREFIX)/bin $(PREFIX)/lib/avra/std
	@cp build/avra $(PREFIX)/bin/avra
	@cp build/avra_runtime.o $(PREFIX)/lib/avra/avra_runtime.o
	@for p in packages/std-*; do rm -rf $(PREFIX)/lib/avra/std/$$(basename $$p); cp -R $$p $(PREFIX)/lib/avra/std/; done
	@echo "install: $(PREFIX)/bin/avra, $$(ls -d packages/std-* | wc -l | tr -d ' ') std packages under $(PREFIX)/lib/avra/std"

# Scratch a run leaves behind: the test binaries each package's
# cases were linked into.
sweep:
	@find packages -type d -name build -prune -exec rm -rf {} +
	@rm -rf build/test_shards

test: $(COMPILER_OBJS) $(PACKAGE_OBJS) suites
	@for p in $(SUITES); do \
	  ./avra test $$p || exit 1; \
	done

# THE OBJECT FOLLOWS THE SOURCE'S CONTENT, NOT ITS TIMESTAMP. make
# compares mtimes at ONE-SECOND granularity, so a stash-and-rebuild
# cycle that lands inside one second leaves the object looking current
# while the source has changed under it — and `make gate` then reports
# the PARENT's behaviour over a tree that carries the change. That
# happened landing f57372a: 39/46 in std-text with the fix on disk,
# and it read as "my change is broken" rather than "the object is
# stale". Reproduced deterministically with `touch -r`.
# THE GATE IS THE RECEIPT, and a receipt for a tree nobody has is
# worse than no receipt. The stamp is rewritten only when the hash
# CHANGES, so its mtime moves on content and nothing else, and a
# repeated build recompiles nothing. ONE RULE FOR EVERY OBJECT: the
# stem resolves the source through vpath exactly as `build/%.o` does,
# so a named-object copy of this rule would be the stem law's second
# definition. One cost, stated: the stamp depends on FORCE, so
# `make -q` always reports work pending for these objects even when
# none is — nothing here reads `make -q`, and the alternative is to
# trust the timestamps again.
.PHONY: FORCE
FORCE:

# THE STAMP IS A LINK IN A CHAIN — `a.c -> a.sha -> a.o`, made by one
# pattern rule and consumed by another — and make deletes the middle
# of a chain as an intermediate file once the end is built. A stamp
# rule with no source prerequisite (`%.sha: FORCE`, hashing a named
# path) never joins a chain and needs none of this; the generic form
# does, and without it every stamp is minted afresh on the next run
# and every object rebuilds every time — which reads as a slow build,
# never as a wrong rule. Precious keeps the stamps.
.PRECIOUS: build/%.sha

build/%.sha: %.c FORCE
	@mkdir -p build
	@shasum -a 256 $< | cut -d' ' -f1 > $@.tmp
	@cmp -s $@.tmp $@ 2>/dev/null || mv $@.tmp $@
	@rm -f $@.tmp

# The runtime's trap contract: the words and the verdict (exit 2).
# No program test can hold it — a suite runs every program in
# one process, and a trap ends it. AFTER `tested`, because a row may
# depend on a package: a broken package should fail its OWN suite
# first, not this keeper, which would name the harness for someone
# else's defect.
traps: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/traps.sh

# Exact refcount and list-write counts; the shipping runtime is put
# back on every exit.   make census CMD="check packages/std-avrac"
census:
	@sh tools/census.sh $(CMD)

# THE STEM LAW's keeper — the Makefile's own TREE_STEM_LAW driven
# with synthetic sources, both the clashes it must refuse and the
# distinct sets it must accept.
stems: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/stems.sh

clean:
	@mkdir -p build
	@cp build/avra /tmp/avra_clean_save 2>/dev/null || true
	rm -rf build scratch packages/cli/src/main_stamped.av
	find packages -name "*.av.ll" -delete
	find packages -type d -name build -prune -exec rm -rf {} +
	@mkdir -p build
	# THE WORKING COMPILER SURVIVES A CLEAN: `build/avra` is the
	# compiler itself, not build debris — deleting it strands the tree
	# (its seed may predate HEAD), and it rebuilds from itself on the
	# next `make avra`. Rescue it before the build directory goes, and
	# restore it after.
	@mv /tmp/avra_clean_save build/avra 2>/dev/null || true

# THE SEED MUST COMPILE HEAD — a seed that cannot is a fossil, and a
# fossil is discovered only on the day it is needed (bootstrap/README.md).
# This gate step cold-bootstraps into a throwaway BUILD and refuses a
# latent drift: a seed that fails here fails the gate, not a future
# `make clean` + `make bootstrap`.
# THE OBJECTS ARE PREREQUISITES, and the link's words are kept: a
# born-clean worktree once failed here on missing build/*.o with the
# reason sent to /dev/null, and the gate read red for a green tree.
seed-check: $(COMPILER_OBJS)
	@mkdir -p build/seed-check
	@cp bootstrap/seed.ll build/seed-check/seed.ll
	@clang -w -O1 build/seed-check/seed.ll $(COMPILER_OBJS) \
	    -L$(LLVM_PREFIX)/lib -lLLVM -o build/seed-check/avra 2> build/seed-check/link.err \
	 || { echo "seed-check: seed links — FAILED"; cat build/seed-check/link.err; rm -rf build/seed-check; exit 1; }
	@build/seed-check/avra build packages/cli >> build/seed-check/out 2>&1 \
	 || { echo "seed-check: the seed cannot compile HEAD — run \`make seed\` (a stale seed is a fossil)"; tail -c 2000 build/seed-check/out; rm -rf build/seed-check; exit 1; }
	@rm -rf build/seed-check
	@echo "seed-check: the seed compiles HEAD"

check: $(COMPILER_OBJS)
	@./avra check $(FILE)

run: $(COMPILER_OBJS)
	@./avra run $(FILE)

ir: $(COMPILER_OBJS)
	@./avra ir $(FILE)

emit: $(COMPILER_OBJS)
	@./avra emit $(FILE)

build-native: $(COMPILER_OBJS)
	@./avra build $(FILE)

# THE PACKAGE LIBRARIES the evaluator opens, one per package that
# owns native code and is not already inside `build/avra`.
# `tools/libs.py` is the ONE definition of what each is made of —
# `tools/stems.sh` consumes that answer rather than re-deriving it;
# the manifests it reads beside it are the DECLARATION the answer is
# held to. The roster needs the compiler built first and says so.
# THE LIBRARY SCOPE, KEPT — a package's library is reached by its
# dependents and by nobody else (`tools/libscope.sh`).
libscope: avra libs
	@sh tools/libscope.sh

libs: avra $(PACKAGE_OBJS)
	@for n in `python3 tools/libs.py --names`; do \
	  python3 tools/libs.py --build $$n || exit 1; \
	done
	@echo "libs: `python3 tools/libs.py --names | wc -w | tr -d ' '` package librar(y|ies) built"

# The suites, derived and counted: a cycle or a dependency that is no
# package refuses here, before a silent empty list runs nothing.
suites:
	@python3 tools/suites.py --self-test
	@python3 tools/suites.py --report

# The idiom bar: the baseline LISTS sites and only ever shrinks —
# `idioms-accept` prunes what is fixed and can never add. A new
# violation is written idiomatically or licensed AT the site.
idioms:
	@sh tools/idioms.sh

idioms-accept:
	@sh tools/idioms.sh --accept

# The IR vocabulary's guarantee: every Ins consumer stays exhaustive,
# so a new instruction cannot ship half-implemented.
vocab:
	@sh tools/vocab.sh

# A fingerprint tag NAMES a node kind: inside one fold space no two
# kinds may wear one number, or they fingerprint alike by construction.
fingerprints:
	@python3 tools/fingerprints.py

# THE EXTERN WALL'S WIDTH: Avra's `int` is 64 bits and C's is 32, so a
# C body answering a narrow type writes only the low half and a
# negative value reads as a large positive one. Both engines agree on
# that wrong answer, so a program test cannot catch it.
externs:
	@python3 tools/externs.py

# THE WIDTH WITNESS. C bodies that answer NARROWER than 64 bits, read
# twice from ONE object — by Avra through the extern seam, and by a C
# main. Identical output means the seam honours every declared width;
# a difference names the BOUNDARY rather than the object, which a
# single reader cannot do. It lives outside runtime/ because `make
# externs` refuses a narrow body WE own, and rightly: the defect under
# test is C someone else compiled. Its object is a package's, built by
# the one rule above.
# THE VENDORED SQLITE's FLAGS. `@std/sqlite`'s manifest names
# build/sqlite3.o in its `[link]`, so the package cannot be checked,
# tested or linked without it; the package rule builds it, under these
# words — once the recipe lived in `vendor/FLAGS.md` as prose, main
# carried no object, and the package's whole suite sat outside `make
# gate` because nothing could build what it links.
#
# THE FLAG SET LIVES HERE, and the suite is what keeps it honest:
# `sqlite_test.av`'s `promised()` asks the LIBRARY for every flag below
# through `sqlite3_compileoption_used`, so the document, this rule and
# the object cannot drift without a red test. `vendor/FLAGS.md` carries
# the REASON for each; this carries the flag.
SQLITE_FLAGS := \
  -DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_ENABLE_PREUPDATE_HOOK=1 \
  -DSQLITE_ENABLE_SESSION=1 -DSQLITE_ENABLE_SNAPSHOT=1 \
  -DSQLITE_ENABLE_NORMALIZE=1 -DSQLITE_ENABLE_STMT_SCANSTATUS=1 \
  -DSQLITE_ENABLE_UNLOCK_NOTIFY=1 -DSQLITE_ENABLE_FTS5=1 \
  -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_GEOPOLY=1 \
  -DSQLITE_ENABLE_MATH_FUNCTIONS=1 -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
  -DSQLITE_ENABLE_DBPAGE_VTAB=1 -DSQLITE_ENABLE_BYTECODE_VTAB=1 \
  -DSQLITE_ENABLE_STAT4=1 -DSQLITE_ENABLE_EXPLAIN_COMMENTS=1 \
  -DSQLITE_ENABLE_OFFSET_SQL_FUNC=1 -DSQLITE_DQS=0 \
  -DSQLITE_ENABLE_API_ARMOR=1 -DSQLITE_LIKE_DOESNT_MATCH_BLOBS=1 \
  -DSQLITE_STRICT_SUBTYPE=1 -DSQLITE_DEFAULT_FOREIGN_KEYS=1 \
  -DSQLITE_THREADSAFE=1 -DSQLITE_MAX_EXPR_DEPTH=1000 \
  -DSQLITE_DEFAULT_MEMSTATUS=0 -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 \
  -DSQLITE_DEFAULT_MMAP_SIZE=268435456 -DSQLITE_MAX_MMAP_SIZE=1099511627776 \
  -DSQLITE_DEFAULT_CACHE_SIZE=-8000 -DSQLITE_DEFAULT_WORKER_THREADS=0 \
  -DNDEBUG=1

# EVERY WORKING FILE LIVES IN `build/`, WHICH IS PER-WORKTREE. A
# shared `/tmp` path is written by one lane and read by another: the
# `.out` files here are DIFFED, and every worktree runs the same
# witness, so a clobber between two lanes comparing the same program
# is a false PASS rather than a noisy failure. `build/witness-c` was
# the sharpest — a BINARY one lane compiled and another could run,
# under a rule whose whole claim is "Avra == C on the SAME object".
# The build LOCK stays in /tmp by design: it is machine-wide.
witness: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@./avra build packages/width-witness > build/witness.path 2> build/witness.err \
	  || { echo "witness: build FAILED"; cat build/witness.err; cat build/witness.path; exit 1; }
	@$$(tail -1 build/witness.path) > build/witness-avra.out
	@cc -O2 -o build/witness-c packages/width-witness/src/reader.c build/width_witness.o
	@build/witness-c > build/witness-c.out
	@diff build/witness-c.out build/witness-avra.out \
	  || { echo "witness: Avra and C disagree on the same object — the extern seam lost a width"; exit 1; }
	@echo "witness: Avra == C on the same object — $$(cat build/witness-avra.out)"

# The whole gate: the vocabulary's guarantee, idioms, then every
# proof a package carries — its spec cases and its program tests,
# both inside its own suite.
# THE GATE: the suites run with the scaffolder's template in place —
# scaffolded into std-avrac before, removed after, however the suites
# end — so the templates' own test is one case of that suite, not a
# second compile of the whole compiler for one case.
gate: seed-check stems vocab fingerprints externs idioms tested traps witness

tested: $(COMPILER_OBJS) $(PACKAGE_OBJS) libs
	@rm -rf packages/std-avrac/src/features/zz_probe
	@./avra new feature zz_probe > build/scaffold-new.out 2>&1 || { cat build/scaffold-new.out; exit 1; }
	@trap 'rm -rf packages/std-avrac/src/features/zz_probe' EXIT INT TERM; $(MAKE) -s test

# The differential gate: the compiled binary must say exactly what
# the evaluator says.
native-check: $(COMPILER_OBJS)
	@./avra run $(FILE) > build/native-check-eval.out
	@./avra build $(FILE) > build/native-check-bin.path 2> build/native-check-bin.err
	@"$$(cat build/native-check-bin.path)" > build/native-check-native.out
	@diff build/native-check-eval.out build/native-check-native.out && echo "native == eval"

# The measured curve: the suites' wall time.
bench: $(COMPILER_OBJS)
	@sh tools/bench.sh

# Mutated program tests through `avra check`: diagnose, never crash.
fuzz: $(COMPILER_OBJS)
	@sh tools/fuzz.sh

# The scaffolder's templates must stay compilable: scaffold a
# throwaway feature, run the suite with it in the tree, remove it.
scaffold-check: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@rm -rf packages/std-avrac/src/features/zz_probe
	@./avra new feature zz_probe > build/scaffold-new.out 2>&1 || { cat build/scaffold-new.out; exit 1; }
	@./avra test packages/std-avrac/src/features/zz_probe/tests/zz_probe_test.av > build/scaffold.out 2>&1; s=$$?; \
	  rm -rf packages/std-avrac/src/features/zz_probe; \
	  if [ $$s -ne 0 ]; then echo "scaffold-check FAILED"; tail -20 build/scaffold.out; exit 1; fi; \
	  echo "scaffold-check: the templates compile and their test passes"
