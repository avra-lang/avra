# THE COMPILER BUILDS ITSELF. `build/avra` is the working binary and
# `make avra` rebuilds it with the binary already there; a cold tree
# bootstraps from the seed (`make bootstrap`, or `./avra` on its own).
# What links what:
#   build/llvm_wrapper.o  OURS — backend/llvm_wrapper.c, the
#                         compiler's LLVM binding; new builders are
#                         added there, never hunted for upstream.
#   build/libavra_runtime.a  OURS — runtime/*.c, the native half of
#                         the LANGUAGE's semantics, one object per
#                         file; the only runtime avra-built programs
#                         link. A LIBRARY, so a program links only the
#                         objects it reaches: one that never spawns
#                         carries no scheduler.
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
# links build/libavra_runtime.a and nothing else here. The compiler
# links every runtime OBJECT whole, since the evaluator hosts every
# row whether or not the compiler's own code calls it.
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
# The runtime's objects are GLOBBED, one per runtime/*.c, so a new
# runtime file joins the library without a line here.
RUNTIME_OBJS = $(patsubst runtime/%.c,build/%.o,$(wildcard runtime/*.c))
RUNTIME_LIB = build/libavra_runtime.a

COMPILER_OBJS = $(TREE_STEM_LAW)$(RUNTIME_OBJS) $(RUNTIME_LIB) build/llvm_wrapper.o \
                build/ffi.o build/std_io.o build/std_process.o build/std_time.o build/std_net.o

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
CFLAGS_ffi := -Iruntime
CFLAGS_sqlite3 = $(SQLITE_FLAGS)
CFLAGS_sqlite_sentinel := -Ipackages/std-sqlite/vendor

# THE VENDORED mbedTLS, ONE OBJECT PER UPSTREAM UNIT: each
# packages/std-tls/vendor/mbedtls_<unit>.c wrapper includes one upstream
# .c, so every unit compiles as upstream compiles it (a unity build lets
# one unit's macros reach the next). They are ARCHIVED with @std/tls's
# own C, so a program links the members it reaches and no more — one
# that only signs links no handshake. The two config headers in src/c
# are the whole mechanism list; @std/tls's own C reads mbedTLS's
# structs, so it compiles under the same words.
MBEDTLS_DIR := packages/std-tls/vendor/mbedtls
MBEDTLS_OBJS := $(patsubst packages/std-tls/vendor/%.c,build/%.o,$(wildcard packages/std-tls/vendor/mbedtls_*.c))
MBEDTLS_FLAGS := -I$(MBEDTLS_DIR)/include -I$(MBEDTLS_DIR)/tf-psa-crypto/include \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/drivers/builtin/include -I$(MBEDTLS_DIR)/library \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/core -I$(MBEDTLS_DIR)/tf-psa-crypto/dispatch \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/drivers/builtin/src -I$(MBEDTLS_DIR)/tf-psa-crypto/extras \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/platform -I$(MBEDTLS_DIR)/tf-psa-crypto/utilities \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/drivers/everest/include \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/drivers/everest/include/tf-psa-crypto/private/everest \
  -I$(MBEDTLS_DIR)/tf-psa-crypto/drivers/everest/include/tf-psa-crypto/private/everest/kremlib \
  -Ipackages/std-tls/src/c '-DTF_PSA_CRYPTO_CONFIG_FILE="std_tls_crypto_config.h"' \
  '-DMBEDTLS_CONFIG_FILE="std_tls_ssl_config.h"'
TLS_OBJS := $(patsubst packages/std-tls/src/c/%.c,build/%.o,$(wildcard packages/std-tls/src/c/*.c)) $(MBEDTLS_OBJS)
$(foreach o,$(TLS_OBJS),$(eval CFLAGS_$(basename $(notdir $(o))) := $(MBEDTLS_FLAGS)))

build/std_tls.a: $(TLS_OBJS)
	@rm -f $@
	ar rcs $@ $^

# THE VENDORED zlib AND brotli, one object per upstream unit
# (packages/std-compress/vendor/import.sh writes the wrappers),
# ARCHIVED with @std/compress's own C as TLS's are: a program links the
# members it reaches, and a program that never compresses links none.
# brotli's units and @std/compress's C read brotli's public headers by
# their installed name.
BROTLI_INCLUDE := -Ipackages/std-compress/vendor/brotli/include
COMPRESS_OBJS := build/std_compress.o $(patsubst packages/std-compress/vendor/%.c,build/%.o,$(wildcard packages/std-compress/vendor/zlib_*.c packages/std-compress/vendor/brotli_*.c))
$(foreach o,$(filter build/brotli_%,$(COMPRESS_OBJS)),$(eval CFLAGS_$(basename $(notdir $(o))) := $(BROTLI_INCLUDE)))
CFLAGS_std_compress := -Ipackages/std-compress/vendor $(BROTLI_INCLUDE)

build/std_compress.a: $(COMPRESS_OBJS)
	@rm -f $@
	ar rcs $@ $^

# A HEADER IS A SOURCE. cc writes each object's dependency list beside
# it and the next make reads it back, so editing a .h rebuilds what
# includes it — without this a package that grows a header links a
# stale object and the defect is attributed to the compiler. The
# include is silent on a cold tree, where no .d exists yet.
# A FRAME NEVER SKIPS A GUARD: code that may run on a task's stack
# probes a frame wider than a page, a page at a time. Apple's clang
# does so by default (___chkstk_darwin); elsewhere it is asked for.
STACK_PROBES := $(if $(filter Darwin,$(shell uname -s)),,-fstack-clash-protection)
# A PROGRAM CARRIES WHAT IT REACHES: every C function and datum stands in a
# section of its own, so a link that drops unreached sections drops it.
SECTIONS := -ffunction-sections -fdata-sections

build/%.o: %.c build/%.sha
	@mkdir -p build
	cc -c -O2 -fPIC -MMD -MP $(STACK_PROBES) $(SECTIONS) $(if $(findstring /vendor/,$<),,-Wall -Werror) $(CFLAGS_$*) -o $@ $<

-include $(patsubst %.o,%.d,$(filter %.o,$(sort $(COMPILER_OBJS) $(PACKAGE_OBJS) $(TLS_OBJS) $(COMPRESS_OBJS))))

# THE HOT LEAVES AS BYTES THE COMPILER CARRIES (runtime/avra_hot.h):
# runtime/avra_hot.c compiled to bitcode by the LLVM the compiler links,
# then written into backend/llvm_wrapper.c's include, so every module can
# inline the leaves and the compiler's own digest covers them — a changed
# leaf retires every cached object. An LLVM without clang carries none,
# and the leaves stay calls.
build/avra_hot.bc: runtime/avra_hot.c runtime/avra_hot.h runtime/avra_box.h
	@mkdir -p build
	@if [ -x $(LLVM_PREFIX)/bin/clang ]; then $(LLVM_PREFIX)/bin/clang -c -emit-llvm -O2 -fPIC -Iruntime -o $@ runtime/avra_hot.c; else rm -f $@; touch $@; fi

build/avra_hot.inc: build/avra_hot.bc
	@python3 -c "import sys; d=open(sys.argv[1],'rb').read(); print('static const unsigned char avra_hot_bc[] = {' + (','.join(str(b) for b in d) or '0') + '};'); print('static const unsigned long avra_hot_bc_len = %d;' % len(d))" $< > $@

build/llvm_wrapper.o: build/avra_hot.inc

# The library is REBUILT WHOLE from its objects, never updated in
# place: a member dropped from runtime/ must not linger in it.
$(RUNTIME_LIB): $(RUNTIME_OBJS)
	@rm -f $@
	@ar rcs $@ $^

# THE RUNTIME AS WEBASSEMBLY, one object per file, MINUS the two that have no
# wasm body: a fiber switches stacks and a core forks, and wasm can do neither
# without the stack-switching proposal. Excluding them HERE makes the law — a
# DOM app must never link them — structural rather than a hope, and a program
# links only the members it reaches in any case.
# THE WASM TOOLCHAIN IS FOUND, by the rule the compiler finds it by
# (packages/cli/src/commands/shared.av, `wasm_tools`): the clang `LLVM_PREFIX`
# names when it has one, else the PATH's; and the first triple that clang has
# a WASI libc for — where it says the target's startup object stands is a file.
# The archiver is that LLVM's too: a host `ar` that does not know a wasm
# object writes an archive with no index, and the link finds nothing in it.
WASM_TRIPLES := wasm32-unknown-wasi wasm32-wasip1
WASM_CC ?= $(firstword $(wildcard $(LLVM_PREFIX)/bin/clang) clang)
WASM_TARGET ?= $(firstword $(foreach t,$(WASM_TRIPLES),$(if $(wildcard $(shell $(WASM_CC) --target=$(t) -print-file-name=crt1.o 2>/dev/null)),$(t))) $(firstword $(WASM_TRIPLES)))
WASM_AR ?= $(firstword $(wildcard $(LLVM_PREFIX)/bin/llvm-ar) ar)
WASI_SYSROOT ?=
WASM_EMULATED := -D_WASI_EMULATED_MMAN -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_GETPID
WASM_RUNTIME_SRCS := $(filter-out runtime/avra_fiber.c runtime/avra_cores.c,$(wildcard runtime/*.c))
WASM_RUNTIME_OBJS := $(patsubst runtime/%.c,build/wasm32/%.o,$(WASM_RUNTIME_SRCS))
WASM_RUNTIME_LIB := build/wasm32/libavra_runtime.a

build/wasm32/%.o: runtime/%.c
	@mkdir -p build/wasm32
	$(WASM_CC) --target=$(WASM_TARGET) $(if $(WASI_SYSROOT),--sysroot=$(WASI_SYSROOT)) $(WASM_EMULATED) -Iruntime -ffunction-sections -fdata-sections -Oz -Wno-deprecated -c -o $@ $<

# A PACKAGE'S C FOR WASM, from the paths its manifest's `wasm_objects` names.
# A package opts in by naming its wasm objects; one that names none is refused
# by the build, never compiled here.
WASM_PACKAGE_OBJS := $(sort $(foreach o,$(shell sed -n 's/.*wasm_objects *= *\[\(.*\)\].*/\1/p' packages/*/avra.toml 2>/dev/null | tr ',' '\n' | tr -d ' "'),build/wasm32/$(notdir $(o))))

build/wasm32/%.o: %.c
	@mkdir -p build/wasm32
	$(WASM_CC) --target=$(WASM_TARGET) $(if $(WASI_SYSROOT),--sysroot=$(WASI_SYSROOT)) $(WASM_EMULATED) -Iruntime -I$(dir $<) -ffunction-sections -fdata-sections -Oz -Wno-deprecated -c -o $@ $<

$(WASM_RUNTIME_LIB): $(WASM_RUNTIME_OBJS)
	@mkdir -p build/wasm32
	@rm -f $@
	@$(WASM_AR) rcs $@ $^

wasm-runtime: $(WASM_RUNTIME_LIB)

# The package objects every wasm build may link — the manifests declare them.
wasm-packages: $(WASM_PACKAGE_OBJS)

# THE WASM PROOF: build the fixtures native and for wasm32 and require
# identical stdout. Skips, spoken, where the wasm toolchain or node is absent.
wasm-check:
	sh tools/wasm-check.sh

# THE HOST SEAM: the avra:rt import and the avra_event export, inspected.
wasm-seam:
	sh tools/wasm-seam-check.sh

# THE REFUSALS: a fiber/core row or a package's C is named, not a linker error.
wasm-refuses:
	sh tools/wasm-refuses.sh

# THE STORE ACROSS TARGETS: a module is its own target's code, and what a
# build keeps is what it published.
wasm-cache:
	sh tools/wasm-cache-attacks.sh

# THE FLOOR: what the smallest wasm program carries, section by section.
wasm-size:
	sh tools/wasm-size.sh

# THE ONE DECLARATION: RtSig.wasm and the archive exclusion agree.
wasm-body:
	sh tools/wasm-body.sh

# THE SIZE RECEIPT: the footprint, printed and capped relative to the baseline.
wasm-size-guard:
	sh tools/wasm-size-guard.sh

# Re-accept the footprint deliberately (the guard prints the rise first).
wasm-size-accept:
	sh tools/wasm-size-guard.sh --accept

# THE ARCHIVE'S LAW: never carries a fiber or a core.
wasm-archive:
	sh tools/wasm-archive.sh

# Every package that carries tests, in dependency order — DERIVED from
# the manifests (tools/suites.py), never listed: a hand-kept list is a
# registry that forgets its next member, and the gate would report
# green over a suite it never ran. `suites` is the keeper that speaks.
SUITES := $(shell python3 tools/suites.py 2>/dev/null)

.PHONY: ui-host ui-host-test ui-board ui-browser h2spec objects census census-types sizes traps compile-slots runtime-tests cache-attacks test tested clean seed-check gate externs idioms cited http-cites fuzz-http soak-http dogfooding-rules idioms-accept bench bench-collections fuzz scaffold-check vocab stems sweep seed recover bootstrap rt-header rt-ns witnesses libs libscope families \
        check run ir emit build-native native-check avra suites install sprite sprite-check codecs wasm-runtime wasm-packages wasm-check wasm-seam wasm-archive wasm-refuses wasm-cache wasm-size wasm-body wasm-size-guard wasm-size-accept
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

# The committed seed is replaced only by an emit that SUCCEEDED AND IS
# WHOLE. A write that runs out of disk mid-stream exits 0, so the exit
# status alone certified a one-line seed as a compiler; the seed is the
# whole cli, and anything short of six figures is a truncated write
# reporting success.
SEED_FLOOR := 100000
# Every C object the compiler and the packages link, built from its source.
objects: $(COMPILER_OBJS) $(PACKAGE_OBJS)

seed: $(COMPILER_OBJS)
	@./avra emit packages/cli > build/seed.ll.new
	@n=$$(wc -l < build/seed.ll.new | tr -d ' '); \
	if [ "$$n" -lt $(SEED_FLOOR) ]; then \
		echo "seed: refused — the emit wrote $$n lines, under $(SEED_FLOOR); the committed seed stands"; \
		rm -f build/seed.ll.new; exit 1; \
	fi; \
	mv build/seed.ll.new bootstrap/seed.ll; \
	sh tools/sources_hash.sh > bootstrap/seed.sources; \
	echo "seed: bootstrap/seed.ll ($$n lines)"

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
	@clang -w -O1 -rdynamic bootstrap/seed.ll $(COMPILER_OBJS) \
	    -L$(LLVM_PREFIX)/lib -lLLVM -o build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@echo "recover: build/avra from the seed — a clean compiler, not rebuilt from source"

# Bootstrap hands out GEN-2. A change to lowering or memory reaches a
# compiler's own body only when a compiler already carrying it compiles
# that body, so the seed's gen-1 rebuilds once more.
bootstrap: recover
	@echo "bootstrap: gen-1, the source compiled by the seed"
	@$(MAKE) -s avra
	@echo "bootstrap: gen-2, the source compiled by gen-1"
	@$(MAKE) -s avra
	@echo "bootstrap: build/avra is gen-2"

# A REFUSAL MUST SPEAK: the build's own words went to /dev/null, so a compiler
# that refused its own source reported only "make: *** Error 2" and the next
# reader ran `./avra build packages/cli` by hand to find out why.
avra: $(COMPILER_OBJS)
	@mkdir -p build
	@# the log is BOUNDED: only its last 200 KB is ever read, and a build failing in a
	@# loop filled the volume twice (tools/capped.sh, which also carries the status).
	@sh tools/capped.sh build/avra-build.out 200000 ./avra build packages/cli || { cat build/avra-build.out; exit 1; }
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
	@cp $(RUNTIME_LIB) $(PREFIX)/lib/avra/libavra_runtime.a
	@for p in packages/std-*; do rm -rf $(PREFIX)/lib/avra/std/$$(basename $$p); cp -R $$p $(PREFIX)/lib/avra/std/; done
	@rm -rf $(PREFIX)/lib/avra/dom && cp -R runtime/dom $(PREFIX)/lib/avra/dom
	@echo "install: $(PREFIX)/bin/avra, $$(ls -d packages/std-* | wc -l | tr -d ' ') std packages under $(PREFIX)/lib/avra/std"

# A Sprite is a stock Ubuntu image; `make sprite` provisions the machine
# it runs on — LLVM 22, the tree's paths, and a compiler. On macOS it is
# a no-op.
sprite:
	@sh tools/sprite-provision.sh

# What a fresh Sprite from THIS tree would do: no build when the tree is
# the source the seed came from, one build once it has moved.
sprite-check:
	@h=$$(sh tools/sources_hash.sh); s=$$(cat bootstrap/seed.sources 2>/dev/null || echo none); \
	 printf 'sprite-check: sources %s\nsprite-check: seed    %s\n' "$$h" "$$s"; \
	 if [ "$$h" = "$$s" ]; then echo "sprite-check: the seed IS this tree — a fresh Sprite needs no build"; \
	 else echo "sprite-check: this tree has moved — a fresh Sprite takes one build; `make seed` restores the seed path"; fi

# Scratch a run leaves behind: the test binaries each package's
# cases were linked into.
sweep:
	@find packages -type d -name build -prune -exec rm -rf {} +
	@rm -rf build/test_shards

# A suite whose package C lives outside the compiler's image evaluates
# through that package's library, so `test` needs `libs`, as `tested` does.
test: $(COMPILER_OBJS) $(PACKAGE_OBJS) suites libs
	@for p in $(SUITES); do \
	  AVRA_SOUND_CHECK=1 ./avra test $$p || exit 1; \
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

# A HEADER RIDES THE CONTENT HASH when a named list says so. The chain
# rule's own prerequisite is the `.c`, and the stamp normally hashes
# it; an object whose behaviour changes with a HEADER names that
# header too, so a stash-and-rebuild inside one second still rebuilds
# it instead of trusting a mtime. AN OBJECT'S FLAGS RIDE ITS STAMP TOO
# (`CFLAGS_<stem>`), so a census build's -DAVRA_CENSUS object is rebuilt
# the moment the flag is dropped, and never ships as the runtime.
build/avra_runtime.sha: SHA_SRC := runtime/avra_runtime.c runtime/avra_box.h runtime/avra_rt.h runtime/avra_runtime.h runtime/avra_fiber.h runtime/avra_hot.h
build/avra_hot.sha: SHA_SRC := runtime/avra_hot.c runtime/avra_hot.h runtime/avra_box.h
build/avra_fiber.sha: SHA_SRC := runtime/avra_fiber.c runtime/avra_box.h runtime/avra_fiber.h runtime/avra_runtime.h
build/llvm_wrapper.sha: SHA_SRC := backend/llvm_wrapper.c runtime/avra_box.h runtime/avra_hot.c runtime/avra_hot.h
build/ffi.sha: SHA_SRC := packages/std-avrac/src/c/ffi.c runtime/avra_rt.h

build/%.sha: %.c FORCE
	@mkdir -p build
	@{ shasum -a 256 $(if $(SHA_SRC),$(SHA_SRC),$<); echo 'flags: $(SECTIONS) $(CFLAGS_$*)'; } | shasum -a 256 | cut -d' ' -f1 > $@.tmp
	@cmp -s $@.tmp $@ 2>/dev/null || mv $@.tmp $@
	@rm -f $@.tmp


# THE RUNTIME'S OWN TESTS: C programs under runtime/tests/, each linked
# against the runtime's objects and run, for what no Avra program can
# reach yet — a row the language does not spell. GLOBBED, so a new test
# file runs without a line here.
RUNTIME_TESTS = $(patsubst runtime/tests/%.c,build/runtime-tests/%,$(wildcard runtime/tests/*.c))
build/runtime-tests/%: runtime/tests/%.c $(RUNTIME_OBJS)
	@mkdir -p build/runtime-tests
	@cc -O2 -Wall -Werror -o $@ $< $(RUNTIME_OBJS)
runtime-tests: $(RUNTIME_TESTS)
	@for t in $(RUNTIME_TESTS); do $$t || exit 1; done

# The runtime's trap contract: the words and the verdict (exit 2).
# No program test can hold it — a suite runs every program in
# one process, and a trap ends it. AFTER `tested`, because a row may
# depend on a package: a broken package should fail its OWN suite
# first, not this keeper, which would name the harness for someone
# else's defect.
traps: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/traps.sh

# THE COMPILE SLOT: a package-scale compile waits for one of
# AVRA_MAX_COMPILES slots, a single file never does.
compile-slots: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/compile_slots.sh

# THE BUILD CACHE, ATTACKED: two programs and a library through ONE store, every edit
# kind a hold must survive, each binary held to the evaluator — and a kept binary held
# to the archive and objects it linked. It CLEARS the store, so it runs last, and it
# refuses a run in which no step held.
cache-attacks: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/cache_attacks.sh
	@sh tools/link_cache_attack.sh

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
# A COMPILER UNDER TEST MUST STAND WHERE A COMPILER STANDS. `@std/*`
# resolves from the BINARY'S OWN DIRECTORY (`<self>/../packages` in a
# checkout), so a seed linked into `build/seed-check/` looked for
# `build/packages`, found no std root, and could resolve a std package
# only through a manifest row. That was invisible for as long as every
# manifest still carried its rows, and it fails the day they go. The
# binary links beside `build/avra`, which is the layout the resolver
# describes; the scratch keeps its own directory.
seed-check: $(COMPILER_OBJS)
	@sh tools/seed_guard.sh
	@mkdir -p build/seed-check
	@cp bootstrap/seed.ll build/seed-check/seed.ll
	@clang -w -O1 -rdynamic build/seed-check/seed.ll $(COMPILER_OBJS) \
	    -L$(LLVM_PREFIX)/lib -lLLVM -o build/avra-seed-check 2> build/seed-check/link.err \
	 || { echo "seed-check: seed links — FAILED"; cat build/seed-check/link.err; rm -rf build/seed-check build/avra-seed-check; exit 1; }
	@sh tools/capped.sh build/seed-check/out 200000 build/avra-seed-check build packages/cli \
	 || { echo "seed-check: the seed cannot compile HEAD — run \`make seed\` (a stale seed is a fossil)"; \
	      printf 'seed-check: codes '; grep -oE 'F[0-9]{4}' build/seed-check/out | sort -u | tr '\n' ' '; echo; \
	      tail -c 2000 build/seed-check/out; rm -rf build/seed-check build/avra-seed-check; exit 1; }
	@rm -rf build/seed-check build/avra-seed-check
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

# The idiom bar is NATIVE now: every idiom the language can state is
# a `rule` (packages/std-avrac's compiler/idioms.av and each
# feature's own idioms.av), found by `avra check` itself.
# `tools/idioms.baseline` lists every currently-accepted site and
# only ever shrinks — `idioms-accept` prunes what a fix made gone,
# and no path here can add a line (the file's own header states the
# law). A new violation is fixed in the code, or a human adds it to
# the baseline, reviewed at adoption and every time after.
# THE NAMES THE DOCTRINE CITES RESOLVE — a third of the rot, and it
# says which third: a count, a line number or an attribution stays
# invisible to it.
cited:
	@python3 tools/cited.py

# THE HTTP DOCS' FIXTURE CITATIONS RESOLVE: every `<suite> › "<then>"`
# in the framing laws and the conformance checklist names a test that
# exists, or the checklist claims coverage the tree does not have.
http-cites:
	@python3 tools/http_cites.py

# DOGFOODING.md's own registry keeps a GENERATED block current
# against `avra rules --markdown` — a rule's doc changes here or the
# block does not, and the compiler's own renderer is what notices.
dogfooding-rules:
	@./build/avra rules --check-markdown DOGFOODING.md

# THE FAMILY ORDINALS ARE APPEND-ONLY. A family ordinal is a durable
# address — rows, kept caches and witnesses key by it — so the enum's
# declared order is a contract. tools/families.order is that contract;
# an inserted, moved or removed variant breaks its prefix and is
# refused before it compiles (the node-variant law, one space over).
families:
	@python3 tools/families.py

idioms:
	@STATUS=0; CHECKED=0; \
	for pkg in packages/*/; do \
	  name=$$(basename "$$pkg"); \
	  [ -d "$${pkg}src" ] || continue; \
	  CHECKED=$$((CHECKED + 1)); \
	  ./build/avra check "packages/$$name" --baseline tools/idioms.baseline || STATUS=1; \
	done; \
	if [ $$STATUS -eq 0 ]; then echo "idioms: no new violations — $$CHECKED package(s) checked against tools/idioms.baseline"; fi; \
	exit $$STATUS

idioms-accept:
	@for pkg in packages/*/; do \
	  name=$$(basename "$$pkg"); \
	  [ -d "$${pkg}src" ] || continue; \
	  ./build/avra check "packages/$$name" --baseline tools/idioms.baseline --baseline_accept; \
	done

# The formatter's real receipt: `fmt(x) == x`, byte-exact, over every
# `.av` file in the tree — never idempotence
# (docs/2026_09_21_FORMATTER_DESIGN.md). GATED: the tree reports 0
# differing (avra-8sb5.25.37), so a NEW one is a regression, not a
# known gap.
fmt-lossless:
	@sh tools/fmt_lossless.sh

# The survivor baseline: a mutant `avra attack` accepts is a decision,
# never a silent pass — a NEW one is refused (tools/attack.baseline).
attack:
	@sh tools/attack.sh

# The IR vocabulary's guarantee: every Ins consumer stays exhaustive,
# so a new instruction cannot ship half-implemented.
vocab:
	@sh tools/vocab.sh

# THE UI HOST'S TABLE IS GENERATED. runtime/dom/wire.gen.js holds the
# numbers a JavaScript host reads the patch wire by; they are declared once,
# in packages/std-ui/src/realize/dom/wire.av, and a copy kept by hand is a
# host reading another wire with nothing failing.
ui-host:
	@sh tools/ui_host.sh

# THE JS HOST IS TESTED BY THE GATE, not by whoever remembers to: a host
# nothing runs is a second implementation nothing checks.
ui-host-test:
	@sh tools/ui_host_test.sh

# THE HOST SEAM, END TO END: the board built as a wasm reactor and run over the
# real page glue, each claim checked (tools/ui-board/demo.mjs). Skips, spoken,
# where node or a wasm toolchain is absent.
ui-board:
	@sh tools/ui_board.sh

# THE BOARD IN A REAL BROWSER: the same module served over an HTTP origin and
# driven in headless Firefox, each claim checked (tools/ui-board/browser.mjs).
# Skips, spoken, where Firefox, node or a wasm toolchain is absent.
ui-browser:
	@sh tools/ui_board_browser.sh

# A fingerprint tag NAMES a node kind: inside one fold space no two
# kinds may wear one number, or they fingerprint alike by construction.
fingerprints:
	@python3 tools/fingerprints.py

# THE CODEC KEEPER: a record's wire ENCODER and its DECODER agree.
# compiler/codecs.av's registry runs every pair over its exemplars,
# decode(encode(x)) compared to x field by field; tools/codecs.py
# refuses any encoder/decoder-shaped pair in the tree the registry
# does not name.
codecs:
	@./build/avra test packages/std-avrac/src/compiler/tests/codecs_test.av
	@python3 tools/codecs.py

# THE ROWS' CLAIM ON THE C. `runtime/avra_rt.h` is generated from
# `rt_sigs()` and included last by the runtime, so a body that answers
# a width its row does not name is a C compiler error at the line that
# implements it. A STALE header asserts the OLD rows and says nothing
# about the new ones — silently, which is the shape a generated
# artifact fails in — so the gate regenerates it and compares.
rt-header:
	@./avra runtime-header > build/avra_rt.h.gen
	@cmp -s build/avra_rt.h.gen runtime/avra_rt.h || { \
	  echo "rt-header: runtime/avra_rt.h is not what the rows say — it is generated, never edited:"; \
	  echo "rt-header:   ./avra runtime-header > runtime/avra_rt.h"; \
	  diff runtime/avra_rt.h build/avra_rt.h.gen 2>/dev/null | head -20; exit 1; }
	@echo "rt-header: $$(grep -c '^_Static_assert' runtime/avra_rt.h) row(s) claim a C body, checked by the C compiler that builds the runtime"

# THE ROWS' CLAIM ON AVRA ITSELF. features/rt.av is generated from
# `rt_sigs()` — one `LowerCx` method per row, so a feature spells a
# typed call (`cx.str_of_bytes(sh, octets)`) instead of
# `Ins.CallRt(dst, "avra_str_of_bytes", [octets])`. A misspelled row
# is then the ordinary "no method" refusal at typing, and a wrong
# seat count the ordinary fn-arity refusal — each row's OWN method IS
# the check, so this keeper only guards the projection: a stale
# namespace asserts the OLD rows and says nothing about the new ones.
rt-ns:
	@./avra runtime-namespace > build/rt.av.gen
	@cmp -s build/rt.av.gen packages/std-avrac/src/features/rt.av || { \
	  echo "rt-ns: packages/std-avrac/src/features/rt.av is not what the rows say — it is generated, never edited:"; \
	  echo "rt-ns:   ./avra runtime-namespace > packages/std-avrac/src/features/rt.av"; \
	  diff packages/std-avrac/src/features/rt.av build/rt.av.gen 2>/dev/null | head -20; exit 1; }
	@echo "rt-ns: $$(grep -c '^    mut fn ' packages/std-avrac/src/features/rt.av) row(s) reach a typed LowerCx method, checked by the compiler that builds itself"

# EVERY REGISTERED CODE'S GOLDEN IS THE COMPILER OVER ITS WITNESS.
# docs/DIAGNOSTICS.md is made by `avra diagnostics` — each entry is a
# source that triggers the code and the compiler's own words over it —
# so a voice whose wording drifts shows up as a diff here rather than
# nowhere. 135 codes are registered and 23 appeared in any test before
# this existed.
# AND A WITNESS THAT NO LONGER TRIGGERS ITS KIND IS REFUSED: the
# compiler moves under it, it starts producing some other code, and a
# green golden of the wrong words is worse than no golden. The command
# exits 1 on one, which fails this target at its first line.
witnesses:
	@./avra diagnostics > build/DIAGNOSTICS.md.gen
	@cmp -s build/DIAGNOSTICS.md.gen docs/DIAGNOSTICS.md || { \
	  echo "witnesses: docs/DIAGNOSTICS.md is not what the compiler says — it is generated, never edited:"; \
	  echo "witnesses:   ./avra diagnostics > docs/DIAGNOSTICS.md"; \
	  diff docs/DIAGNOSTICS.md build/DIAGNOSTICS.md.gen 2>/dev/null | head -30; exit 1; }

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
# THE TWO READINGS ARE NOT CAPPED, AND MUST NOT BE: they are compared,
# and a `tail` over both could make two DIFFERENT outputs equal —
# manufacturing the very agreement this rule exists to test. Their
# producer is one fixed program in this tree whose whole output the
# last line prints. The build's stderr beside them is a log, and is
# capped. (tools/capped.sh carries the rule.)
witness: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/capped.sh build/witness.err 200000 sh -c './avra build packages/width-witness > build/witness.path' \
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
# THE RECEIPT: a green gate names the tree it proved, so an
# integration that takes that exact tree need not prove it again
# (tools/gate_receipt.sh). A dirty tree writes none, and neither does
# one with no git tree to name (a Sprite's synced copy) — `write`
# refuses in that case, which is honest and not a gate failure, so
# its status is discarded here exactly as sprite-build.sh's call does.
gate: seed-check stems vocab fingerprints ui-host ui-host-test ui-board ui-browser families codecs rt-header rt-ns witnesses externs idioms cited dogfooding-rules fmt-lossless attack tested runtime-tests traps compile-slots witness cache-attacks
	@sh tools/gate_receipt.sh --self-test
	@sh tools/watch.sh --self-test
	@sh tools/memcap.sh --self-test
	@sh tools/gate_receipt.sh write || true

tested: $(COMPILER_OBJS) $(PACKAGE_OBJS) libs
	@rm -rf packages/std-avrac/src/features/zz_probe
	@sh tools/capped.sh build/scaffold-new.out 200000 ./avra new feature zz_probe || { cat build/scaffold-new.out; exit 1; }
	@trap 'rm -rf packages/std-avrac/src/features/zz_probe' EXIT INT TERM; $(MAKE) -s test

# The differential gate: the compiled binary must say exactly what
# the evaluator says.
# THE TWO READINGS ARE UNCAPPED for the reason `witness` gives: they
# are compared, and truncating both could make them agree. The build's
# stderr is a log and is capped.
native-check: $(COMPILER_OBJS)
	@./avra run $(FILE) > build/native-check-eval.out
	@sh tools/capped.sh build/native-check-bin.err 200000 sh -c './avra build $(FILE) > build/native-check-bin.path'
	@"$$(cat build/native-check-bin.path)" > build/native-check-native.out
	@diff build/native-check-eval.out build/native-check-native.out && echo "native == eval"

# The measured curve: the suites' wall time.
bench: $(COMPILER_OBJS)
	@sh tools/bench.sh

# The collection vocabulary's bench: C1–C12, each Avra program against
# its Rust twin, median of 5 (tools/bench/collections/run.sh).
bench-collections: build/libavra_runtime.a
	@sh tools/bench/collections/run.sh

# h2spec over std-http's HTTP/2 server, in the clear and over TLS;
# skipped, with a word, when h2spec is not installed.
h2spec: $(COMPILER_OBJS)
	@sh tools/h2spec.sh

# Boxes a program's runtime rows answer, by type, ranked — the
# representation-selection opportunity list.
#   make census-types PROGRAM=tools/bench/request/src/main.av
PROGRAM ?= tools/bench/request/src/main.av
census-types:
	@sh tools/census_types.sh $(PROGRAM)

# Bytes of code per symbol by package: the compiler and a request's
# server, each against BEFORE / REQUEST_BEFORE when given (a saved
# binary), as the tables a slice's size delta is read from; then what
# each reach probe carries (tools/bench/reach) — a program pays for
# what it calls, never for what it imports.
#   make sizes BEFORE=build/avra.pre
REACH := hello limits plain unreached tls sign
sizes:
	@build/avra build tools/bench/request/src/main.av >/dev/null
	@python3 tools/symsize.py build/avra $(BEFORE)
	@echo
	@python3 tools/symsize.py tools/bench/request/src/main $(REQUEST_BEFORE)
	@echo
	@echo '| reach probe | bytes |'
	@echo '|---|---:|'
	@for p in $(REACH); do build/avra build tools/bench/reach/$$p >/dev/null && \
	    echo "| $$p | $$(wc -c < tools/bench/reach/$$p/src/main | tr -d ' ') |"; done

# Mutated program tests through `avra check`: diagnose, never crash.
fuzz: $(COMPILER_OBJS)
	@sh tools/fuzz.sh

# THE HTTP FRAMERS FUZZED in bounded time (FUZZ_HTTP_SECONDS, default
# 180): the corpus and every kept finding replayed, libFuzzer over the
# C rows, then the seeded mutation fuzzer — a trap bisected to its one
# mutant and kept in packages/std-http-fuzz/crashes.
fuzz-http: build/libavra_runtime.a
	@sh tools/fuzz_http.sh

# THE HTTP SERVER SOAKED: 10k keep-alive connections on every core for
# SOAK_HTTP_SECONDS (default 600, ten minutes), the reset law looped 1000x
# under that load; prints the load, memory, descriptors and resets it saw.
soak-http: build/libavra_runtime.a
	@sh tools/soak_http.sh

# The scaffolder's templates must stay compilable: scaffold a
# throwaway feature, run the suite with it in the tree, remove it.
scaffold-check: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@rm -rf packages/std-avrac/src/features/zz_probe
	@sh tools/capped.sh build/scaffold-new.out 200000 ./avra new feature zz_probe || { cat build/scaffold-new.out; exit 1; }
	@sh tools/capped.sh build/scaffold.out 200000 ./avra test packages/std-avrac/src/features/zz_probe/tests/zz_probe_test.av; s=$$?; \
	  rm -rf packages/std-avrac/src/features/zz_probe; \
	  if [ $$s -ne 0 ]; then echo "scaffold-check FAILED"; tail -20 build/scaffold.out; exit 1; fi; \
	  echo "scaffold-check: the templates compile and their test passes"
