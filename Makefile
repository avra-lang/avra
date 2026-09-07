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
# own C. The targets below depend on TREE_OBJS for that reason: every
# object this tree compiles, so no link can want one that is absent.
# The cost is one vendored amalgamation compiled on a cold tree that
# the compiler does not link; the gate builds it anyway.
# @std/io's object is here because the SEED-BUILT compiler links it:
# the bootstrap's clang line takes this list, and a compiler that
# cannot open a file cannot compile the tree it was built to compile.
# Every package whose C the compiler's own closure links belongs here
# the day it lands — S4 adds @std/process's.
COMPILER_OBJS := build/llvm_wrapper.o build/avra_runtime.o build/ffi.o build/std_io.o

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
# these three lines with synthetic sources; there is no second copy.
TREE_STEMS = $(basename $(notdir $(TREE_C)))
TREE_CLASH = $(strip $(foreach s,$(sort $(TREE_STEMS)),\
               $(if $(word 2,$(filter $(s),$(TREE_STEMS))),$(s))))
TREE_STEM_LAW = $(if $(TREE_CLASH),$(error A STEM NAMES ITS OBJECT, \
  so a stem is unique tree-wide — rename one of: \
  $(foreach s,$(TREE_CLASH),$(filter %/$(s).c,$(TREE_C)))))
TREE_OBJS = $(TREE_STEM_LAW)$(patsubst %.c,build/%.o,$(notdir $(TREE_C)))
CFLAGS_llvm_wrapper := -I$(LLVM_PREFIX)/include
CFLAGS_sqlite3 = $(SQLITE_FLAGS)

# A HEADER IS A SOURCE. cc writes each object's dependency list beside
# it and the next make reads it back, so editing a .h rebuilds what
# includes it — without this a package that grows a header links a
# stale object and the defect is attributed to the compiler. The
# include is silent on a cold tree, where no .d exists yet.
build/%.o: %.c
	@mkdir -p build
	cc -c -O2 -MMD -MP $(if $(findstring /vendor/,$<),,-Wall -Werror) $(CFLAGS_$*) -o $@ $<

-include $(TREE_OBJS:.o=.d)

# Every package that carries spec cases, in dependency order.
SUITES := packages/std-errors packages/std-testing packages/std-text packages/std-path packages/std-time packages/std-io packages/std-toml packages/std-process packages/std-cli packages/std-json packages/std-avrac packages/cli packages/std-sqlite

.PHONY: census traps test tested clean corpus gate externs idioms idioms-accept bench fuzz scaffold-check vocab stems sweep seed bootstrap \
        check run ir emit build-native native-check avra

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

seed: $(TREE_OBJS)
	@./avra emit packages/cli > bootstrap/seed.ll
	@echo "seed: bootstrap/seed.ll ($$(wc -l < bootstrap/seed.ll | tr -d ' ') lines)"

bootstrap: $(TREE_OBJS)
	@mkdir -p build
	@clang -w -O1 bootstrap/seed.ll $(COMPILER_OBJS) \
	    -L$(LLVM_PREFIX)/lib -lLLVM -o build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@echo "bootstrap: build/avra from the seed — rebuilding from source"
	@$(MAKE) -s avra

# A REFUSAL MUST SPEAK: the build's own words went to /dev/null, so a compiler
# that refused its own source reported only "make: *** Error 2" and the next
# reader ran `./avra build packages/cli` by hand to find out why.
avra: $(TREE_OBJS)
	@./avra build packages/cli > /tmp/avra-build.out 2>&1 || { cat /tmp/avra-build.out; exit 1; }
	@mkdir -p build
	@cp packages/cli/src/main build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@rm -f packages/cli/src/main packages/cli/src/main.av.ll
	@echo "avra: build/avra"

# Scratch a run leaves behind: the test binaries each package's
# cases were linked into.
sweep:
	@rm -rf packages/*/build build/test_shards

test: $(TREE_OBJS)
	@for p in $(SUITES); do \
	  ./avra test $$p || exit 1; \
	done

# The runtime's trap contract: the words and the verdict (exit 2).
# No corpus program can hold it — the corpus runs every program in
# one process, and a trap ends it. AFTER `tested`, because a row may
# depend on a package: a broken package should fail its OWN suite
# first, not this keeper, which would name the harness for someone
# else's defect.
traps: $(TREE_OBJS)
	@sh tools/traps.sh

# Exact refcount and list-write counts; the shipping runtime is put
# back on every exit.   make census CMD="check packages/std-avrac"
census:
	@sh tools/census.sh $(CMD)

# THE STEM LAW's keeper — the Makefile's own TREE_STEM_LAW driven
# with synthetic sources, both the clashes it must refuse and the
# distinct sets it must accept.
stems:
	@sh tools/stems.sh

clean:
	rm -rf build scratch packages/cli/src/main_stamped.av
	find packages corpus -name "*.av.ll" -delete
	find corpus -type f ! -name "*.av" ! -name "*.expected" ! -name "expected" ! -name "avra.toml" ! -name "native-only" -delete
	rm -rf packages/*/build

check: $(TREE_OBJS)
	@./avra check $(FILE)

run: $(TREE_OBJS)
	@./avra run $(FILE)

ir: $(TREE_OBJS)
	@./avra ir $(FILE)

emit: $(TREE_OBJS)
	@./avra emit $(FILE)

build-native: $(TREE_OBJS)
	@./avra build $(FILE)

# The corpus gate: every corpus/*.av must say its .expected — first
# through the evaluator, then through ONE native binary holding them
# all (`avra corpus`). A feature's end-to-end proof is one tiny
# program plus one tiny expected file.
# A PACKAGE proves the same as corpus/<name>/main.av (its avra.toml
# marks the root) beside corpus/<name>/expected. corpus/native/ holds
# programs the evaluator cannot run — extern fns — proved native only.
#
# A PACKAGE corpus may be native-only too, and it needs its own mark:
# corpus/native/ takes LOOSE files, which cannot `use` a package at all
# ("this file is not in a package — `use` needs a root"), so a driver
# built ON a package can only be proved in the package form. A `native-only`
# file beside `expected` drops the evaluator leg, and the gate's own line
# then SAYS "native == expected" rather than claiming a differential it
# never ran. The label travels with the artifact: a reader of the gate's
# output learns the program is single-engine without opening a document.
corpus: $(TREE_OBJS)
	@./avra corpus corpus
	@./avra corpus --native-only corpus/native
	@for d in corpus/*/; do \
	  d=$${d%/}; [ -f $$d/src/main.av ] || continue; \
	  if [ -f $$d/native-only ]; then legs="native"; else \
	    ./avra run $$d/src/main.av > /tmp/avra-corpus-eval.out 2>&1 \
	      || { echo "$$d: eval FAILED"; cat /tmp/avra-corpus-eval.out; exit 1; }; \
	    diff $$d/expected /tmp/avra-corpus-eval.out \
	      || { echo "$$d: eval != expected"; exit 1; }; \
	    legs="eval == native"; \
	  fi; \
	  ./avra build $$d/src/main.av > /tmp/avra-bin.path 2>&1 \
	    || { echo "$$d: build FAILED"; cat /tmp/avra-bin.path; exit 1; }; \
	  $$(cat /tmp/avra-bin.path) > /tmp/avra-corpus-native.out; \
	  diff $$d/expected /tmp/avra-corpus-native.out \
	    || { echo "$$d: native != expected"; exit 1; }; \
	  echo "$$d: $$legs == expected"; \
	done

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

# THE EXTERN WALL'S WIDTH: Avra's `int` is 64 bits and C's is 32, so a
# C body answering a narrow type writes only the low half and a
# negative value reads as a large positive one. Both engines agree on
# that wrong answer, so the corpus cannot catch it.
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

witness: $(TREE_OBJS)
	@./avra build packages/width-witness > /tmp/avra-witness.path 2>&1 \
	  || { echo "witness: build FAILED"; cat /tmp/avra-witness.path; exit 1; }
	@$$(tail -1 /tmp/avra-witness.path) > /tmp/avra-witness-avra.out
	@cc -O2 -o /tmp/avra-witness-c packages/width-witness/src/reader.c build/width_witness.o
	@/tmp/avra-witness-c > /tmp/avra-witness-c.out
	@diff /tmp/avra-witness-c.out /tmp/avra-witness-avra.out \
	  || { echo "witness: Avra and C disagree on the same object — the extern seam lost a width"; exit 1; }
	@echo "witness: Avra == C on the same object — $$(cat /tmp/avra-witness-avra.out)"

# The whole gate: the vocabulary's guarantee, idioms, unit specs,
# then the corpus end to end.
# THE GATE: the suites run with the scaffolder's template in place —
# scaffolded into std-avrac before, removed after, however the suites
# end — so the templates' own test is one case of that suite, not a
# second compile of the whole compiler for one case.
gate: stems vocab externs idioms tested traps corpus witness

tested: $(TREE_OBJS)
	@rm -rf packages/std-avrac/src/features/zz_probe
	@./avra new feature zz_probe > /tmp/avra-scaffold-new.out 2>&1 || { cat /tmp/avra-scaffold-new.out; exit 1; }
	@trap 'rm -rf packages/std-avrac/src/features/zz_probe' EXIT INT TERM; $(MAKE) -s test

# The differential gate: the compiled binary must say exactly what
# the evaluator says.
native-check: $(TREE_OBJS)
	@./avra run $(FILE) > /tmp/avra-eval.out
	@./avra build $(FILE) > /tmp/avra-bin.path
	@$$(cat /tmp/avra-bin.path) > /tmp/avra-native.out
	@diff /tmp/avra-eval.out /tmp/avra-native.out && echo "native == eval"

# The measured curve: suite + native corpus wall times.
bench: $(COMPILER_OBJS)
	@sh tools/bench.sh

# Mutated corpus through `avra check`: diagnose, never crash.
fuzz: $(COMPILER_OBJS)
	@sh tools/fuzz.sh

# The scaffolder's templates must stay compilable: scaffold a
# throwaway feature, run the suite with it in the tree, remove it.
scaffold-check: $(TREE_OBJS)
	@rm -rf packages/std-avrac/src/features/zz_probe
	@./avra new feature zz_probe > /tmp/avra-scaffold-new.out 2>&1 || { cat /tmp/avra-scaffold-new.out; exit 1; }
	@./avra test packages/std-avrac/src/features/zz_probe/tests/zz_probe_test.av > /tmp/avra-scaffold.out 2>&1; s=$$?; \
	  rm -rf packages/std-avrac/src/features/zz_probe; \
	  if [ $$s -ne 0 ]; then echo "scaffold-check FAILED"; tail -20 /tmp/avra-scaffold.out; exit 1; fi; \
	  echo "scaffold-check: the templates compile and their test passes"
