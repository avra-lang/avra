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
# THE C++ RUNTIME AND THE SYSTEM LIBRARY DIRECTORY the static LLVM link names
# (packages/std-avrac/avra.toml), per platform.
ifeq ($(shell uname -s),Darwin)
export AVRA_CXX_RUNTIME ?= c++
export AVRA_SYS_SEARCH ?= /opt/homebrew/lib
else
export AVRA_CXX_RUNTIME ?= stdc++
endif
# THE COMPILER'S LLVM LINK, one definition: the manifest row, read by the
# hand-written clang lines below so none of them spells the libraries again.
LLVM_LINK := $(shell sh tools/llvm_link.sh --words)

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
TREE_C := $(wildcard packages/*/src/c/*.c packages/*/vendor/*.c backend/*.c runtime/*.c runtime/host/*.c)
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
# program carries, plus every object a manifest names in the cli's
# closure — the cli and each @std package its sources `use`, asked of
# tools/manifest_objects.sh, the one reader of a `[link]` row. The
# bootstrap's clang line takes this same variable, so the two can never
# be a list and its copy. A package object in the compiler's own closure
# (@std/io's: a compiler that cannot open a file cannot compile the tree)
# is BOTH a package object and a compiler one, and joins here the day its
# package's `use` lands. An archive brings its members (MEMBERS_<name>),
# which a seed links in its place.
# The runtime's objects are GLOBBED, one per runtime/*.c, so a new
# runtime file joins the library without a line here.
RUNTIME_OBJS = $(patsubst runtime/%.c,build/%.o,$(wildcard runtime/*.c)) build/avra_tick.o
RUNTIME_LIB = build/libavra_runtime.a

COMPILER_PACKAGE_OBJS := $(shell sh tools/manifest_objects.sh --closure cli)
COMPILER_ARCHIVES = $(filter %.a,$(COMPILER_PACKAGE_OBJS))
COMPILER_OBJS = $(TREE_STEM_LAW)$(RUNTIME_OBJS) $(RUNTIME_LIB) $(COMPILER_PACKAGE_OBJS) \
                $(foreach a,$(COMPILER_ARCHIVES),$(MEMBERS_$(notdir $(a))))

# A seed names an archive's rows itself, so its link takes them once: the members, not also their archive.
SEED_LINK_OBJS = $(filter-out $(COMPILER_ARCHIVES),$(COMPILER_OBJS))

# PACKAGE_OBJS is every object a package's `[link]` row names — what a
# target that RUNS programs may need, since any package's suite or
# program tests can link its own C.
PACKAGE_OBJS := $(TREE_STEM_LAW)$(shell sh tools/manifest_objects.sh)

# PER-OBJECT FLAGS, by stem. The LLVM binding needs its headers; the
# vendored amalgamation takes its author's whole flag set, which its
# own suite asks the LIBRARY to confirm.
CFLAGS_avra_tick := -Iruntime
CFLAGS_llvm_wrapper := -I$(LLVM_PREFIX)/include
CFLAGS_ffi := -Iruntime
CFLAGS_std_io := -Iruntime
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

MEMBERS_std_tls.a = $(TLS_OBJS)
build/std_tls.a: $(MEMBERS_std_tls.a)
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

MEMBERS_std_compress.a = $(COMPRESS_OBJS)
build/std_compress.a: $(MEMBERS_std_compress.a)
	@rm -f $@
	ar rcs $@ $^

# THE VENDORED BLAKE3, one object per upstream unit
# (packages/std-hash/vendor/import.sh writes the wrappers), ARCHIVED
# with @std/hash's own C. Only this machine's SIMD units are built, each
# under the flags its intrinsics need, and blake3_dispatch asks the CPU
# at run time which of them to run; any other machine runs the portable
# unit alone.
HASH_ARCH := $(shell uname -m)
B3_SIMD := $(if $(filter arm64 aarch64,$(HASH_ARCH)),neon,$(if $(filter x86_64 amd64,$(HASH_ARCH)),sse2 sse41 avx2 avx512))
HASH_OBJS := build/std_hash.o $(patsubst %,build/b3_%.o,blake3 blake3_dispatch blake3_portable $(addprefix blake3_,$(B3_SIMD)))
$(foreach o,$(HASH_OBJS),$(eval CFLAGS_$(basename $(notdir $(o))) := -Ipackages/std-hash/vendor))
CFLAGS_b3_blake3_sse2 += -msse2
CFLAGS_b3_blake3_sse41 += -msse4.1
CFLAGS_b3_blake3_avx2 += -mavx2
CFLAGS_b3_blake3_avx512 += -mavx512f -mavx512vl

MEMBERS_std_hash.a = $(HASH_OBJS)
build/std_hash.a: $(MEMBERS_std_hash.a)
	@rm -f $@
	ar rcs $@ $^

# THE HASHER'S DOOR, FORGED: @std/hash takes a hasher's state back as a
# value, so forged states are pushed through it with the package's C
# rebuilt under ASan and UBSan, each unit under its own flags. A machine
# whose compiler carries no sanitizer runtime says so and runs nothing.
HASH_DOOR_SAN := -g -O1 -fsanitize=address,undefined -fno-sanitize-recover=all
hash-door: packages/std-hash/src/c/tests/door_test.c $(HASH_OBJS)
	@mkdir -p build/hash-door
	@if ! { printf 'int main(void) { return 0; }\n' | cc $(HASH_DOOR_SAN) -x c - -o build/hash-door/probe 2>/dev/null && build/hash-door/probe; }; then \
	  echo "hash-door: ASan unavailable — not run"; \
	else \
	  $(foreach o,$(HASH_OBJS),cc -c $(HASH_DOOR_SAN) $(CFLAGS_$(basename $(notdir $(o)))) -o build/hash-door/$(notdir $(o)) $(if $(filter build/std_hash.o,$(o)),packages/std-hash/src/c/std_hash.c,packages/std-hash/vendor/$(basename $(notdir $(o))).c) &&) \
	  cc $(HASH_DOOR_SAN) -Ipackages/std-hash/vendor -o build/hash-door/door_test $< $(addprefix build/hash-door/,$(notdir $(HASH_OBJS))) && \
	  build/hash-door/door_test; \
	fi

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
# AVRA_FRAME_POINTERS=1 keeps frame pointers in the runtime and, read by the backend, in every
# emitted fn, so a sampling profiler can walk Avra stacks. Off, nothing changes.
SECTIONS := -ffunction-sections -fdata-sections $(if $(AVRA_FRAME_POINTERS),-fno-omit-frame-pointer)

build/%.o: %.c build/%.sha
	@mkdir -p build
	cc -c -O2 -fPIC -MMD -MP $(STACK_PROBES) $(SECTIONS) $(if $(findstring /vendor/,$<),,-Wall -Werror) $(CFLAGS_$*) -o $@ $<

-include $(patsubst %.o,%.d,$(filter %.o,$(sort $(COMPILER_OBJS) $(PACKAGE_OBJS) $(TLS_OBJS) $(COMPRESS_OBJS) $(HASH_OBJS))))

# THE HOT LEAVES AS BYTES THE COMPILER CARRIES (runtime/avra_hot.h):
# runtime/avra_hot.c compiled to bitcode by the LLVM the compiler links,
# then written into backend/llvm_wrapper.c's include, so every module can
# inline the leaves and the compiler's own digest covers them — a changed
# leaf retires every cached object. An LLVM without clang carries none,
# and the leaves stay calls. THE LEAVES MAY UNWIND (-fexceptions): a trap inside
# one, inlined under a call with a cleanup region open, reaches that region.
build/avra_hot.bc: runtime/avra_hot.c runtime/avra_hot.h runtime/avra_box.h
	@mkdir -p build
	@if [ -x $(LLVM_PREFIX)/bin/clang ]; then $(LLVM_PREFIX)/bin/clang -c -emit-llvm -O2 -fPIC -fexceptions -Iruntime -o $@ runtime/avra_hot.c; else rm -f $@; touch $@; fi

build/avra_hot.inc: build/avra_hot.bc
	@python3 -c "import sys; d=open(sys.argv[1],'rb').read(); print('static const unsigned char avra_hot_bc[] = {' + (','.join(str(b) for b in d) or '0') + '};'); print('static const unsigned long avra_hot_bc_len = %d;' % len(d))" $< > $@

build/llvm_wrapper.o: build/avra_hot.inc

# The library is REBUILT WHOLE from its objects, never updated in
# place: a member dropped from runtime/ must not linger in it.
$(RUNTIME_LIB): $(RUNTIME_OBJS)
	@rm -f $@
	@ar rcs $@ $^

# THE RUNTIME AS WEBASSEMBLY, one object per file, MINUS the one that has no
# wasm body: a core forks, and wasm cannot. The scheduler is IN, hosted: its
# tasks run on stacks the host makes (JSPI, or asyncify), so its OS halves —
# stacks, poller, signals, the case runner — are compiled out
# (runtime/avra_fiber.c, AVRA_HOSTED). Excluding the core HERE makes the law
# structural rather than a hope, and a program links only the members it
# reaches in any case.
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
# A MODULE CARRIES NO INSTRUMENTS: the page and the node runner hand a module
# no environment to switch one on with, and a wasm frame has no return address
# for one to name a site by. `make -B WASM_INSTRUMENTS=1 wasm-runtime` builds
# the archive with them, for a host that passes an environment.
WASM_INSTRUMENTS ?= 0
# A GUARDED RUN CATCHES A TRAP IN PLACE: the runtime file that holds the
# catch point is built with WebAssembly exception handling, which lowers
# setjmp/longjmp to throw and catch (the module links libsetjmp for the
# rest). No other member is built so, and the exnref encoding is LLVM's default.
WASM_SJLJ_avra_runtime.c := -mllvm -wasm-enable-sjlj -mexception-handling
WASM_RUNTIME_SRCS := $(filter-out runtime/avra_cores.c,$(wildcard runtime/*.c))
WASM_RUNTIME_OBJS := $(patsubst runtime/%.c,build/wasm32/%.o,$(WASM_RUNTIME_SRCS))
WASM_RUNTIME_LIB := build/wasm32/libavra_runtime.a

# A WASM OBJECT FOLLOWS ITS SOURCE'S CONTENT AS A HOST OBJECT DOES: it rides
# the same stamp (`build/<stem>.sha`, the headers it names included) and writes
# its own dependency list, so neither a source older than its object nor an
# edited header links a stale member.
build/wasm32/%.o: runtime/%.c build/%.sha
	@mkdir -p build/wasm32
	$(WASM_CC) --target=$(WASM_TARGET) $(if $(WASI_SYSROOT),--sysroot=$(WASI_SYSROOT)) $(WASM_EMULATED) -DAVRA_INSTRUMENTS=$(WASM_INSTRUMENTS) -Iruntime -MMD -MP -ffunction-sections -fdata-sections -Oz -Wno-deprecated $(WASM_SJLJ_$(notdir $<)) -c -o $@ $<

# A PACKAGE'S C FOR WASM, from the paths its manifest's `wasm_objects` names.
# A package opts in by naming its wasm objects; one that names none is refused
# by the build, never compiled here.
WASM_PACKAGE_OBJS := $(shell sh tools/manifest_objects.sh --wasm)

build/wasm32/%.o: %.c build/%.sha
	@mkdir -p build/wasm32
	$(WASM_CC) --target=$(WASM_TARGET) $(if $(WASI_SYSROOT),--sysroot=$(WASI_SYSROOT)) $(WASM_EMULATED) -Iruntime -I$(dir $<) -MMD -MP -ffunction-sections -fdata-sections -Oz -Wno-deprecated -c -o $@ $<

-include $(patsubst %.o,%.d,$(WASM_RUNTIME_OBJS) $(WASM_PACKAGE_OBJS))

# THE CORE OBJECT IS THE ARCHIVE'S FIRST MEMBER: the program imports every
# runtime row from `avra:rt`, and a member that names one of them plain
# (`env`) while the row is still undefined is a module mismatch at the link.
# The linker takes members in archive order, so the object that DEFINES the
# rows goes first and nothing meets an undefined one.
$(WASM_RUNTIME_LIB): $(WASM_RUNTIME_OBJS)
	@mkdir -p build/wasm32
	@rm -f $@
	@$(WASM_AR) rcs $@ build/wasm32/avra_runtime.o $(filter-out build/wasm32/avra_runtime.o,$^)

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

# THE HOSTED SCHEDULER, BROKEN ON PURPOSE: each break of its wasm port must
# turn the tasks fixture red.
wasm-tasks-mutations:
	sh tools/wasm-tasks-mutations.sh

# THE HOST HALF under JSPI: a plain call that parks is refused in words, an
# entered one runs, the artifact follows what the host can suspend.
wasm-host-check:
	sh tools/wasm-host-check.sh

# THE REFUSALS: a core row, a wait on a descriptor or a package's C is named, not a linker error.
wasm-refuses:
	sh tools/wasm-refuses.sh

# THE STORE ACROSS TARGETS: a module is its own target's code, and what a
# build keeps is what it published.
wasm-cache:
	sh tools/wasm-cache-attacks.sh

# THE FLOOR: what the smallest wasm program carries, section by section.
# not a keeper — report
wasm-size:
	sh tools/wasm-size.sh

# THE ONE DECLARATION: RtSig.wasm and the archive exclusion agree.
# keeper owed by UI/ui-escape — wasm rows guarded by __wasm32__ vs the keeper's law (fiber/cores only)
wasm-body:
	sh tools/wasm-body.sh

# THE SIZE RECEIPT: the footprint, printed and capped relative to the baseline.
wasm-size-guard:
	sh tools/wasm-size-guard.sh

# Re-accept the footprint deliberately (the guard prints the rise first).
# not a keeper — re-accepts the wasm footprint deliberately
wasm-size-accept:
	sh tools/wasm-size-guard.sh --accept

# THE ARCHIVE'S LAW: never carries a fiber or a core.
wasm-archive:
	sh tools/wasm-archive.sh

# Every package that carries tests, in dependency order — DERIVED from
# the manifests (tools/src/commands/suites.av), never listed: a hand-kept list is a
# registry that forgets its next member, and the gate would report
# green over a suite it never ran. `suites` is the keeper that speaks.
# DEFERRED, so only a recipe that reads it pays for the walk — an immediate
# `$(shell)` runs on every make, `try` included.
SUITES = $(shell sh tools/avra_tools.sh suites 2>/dev/null)

.PHONY: tools-suite dev-server census-gate census-accept trap-marks speed-note llvm-libs libs-self-test read-lists db-corpus try edit-loop footprint footprint-accept tick-object no-threads flow-gate flow-gate-accept ui-host ui-host-test ui-fuzz ui-board ui-browser ui-browser-skip host-events layout-oracle wasm-host-check wasm-tasks-mutations h2spec objects census census-types sizes traps compile-slots runtime-tests hash-door cache-attacks cache-attacks-a cache-attacks-b cache-attacks-b1 cache-attacks-b2 store-attacks code-hash-attacks turn-memory-attack test tested clean seed-check gate externs idioms cited http-cites fuzz-http soak-http dogfooding-rules rule-examples idioms-accept bench bench-collections fuzz scaffold-check vocab stems runtime-mutations sweep seed recover bootstrap rt-header rt-ns witnesses libs libscope families-left layers hooks-released inputs inputs-accept whole-reads whole-reads-accept read-cost \
        check run ir emit build-native native-check avra suites install sprite sprite-check codecs codecs-static keepers voices voices-accept defects tool-witnesses pipeline-status pipeline-doc ci-invariants pr-watcher wasm-runtime wasm-packages wasm-check wasm-seam wasm-archive wasm-refuses wasm-cache wasm-size wasm-body wasm-size-guard wasm-size-accept speed-ratchet speed-accept wall-ratchet wall-accept warm-edit warm-accept work-accept
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
	@clang -w -O1 -rdynamic bootstrap/seed.ll $(SEED_LINK_OBJS) \
	    $(LLVM_LINK) -o build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@echo "recover: build/avra from the seed — a clean compiler, not rebuilt from source"

# Bootstrap hands out GEN-2. A change to lowering or memory reaches a
# compiler's own body only when a compiler already carrying it compiles
# that body, so the seed's gen-1 rebuilds once more.
#
# UNLESS THE SEED IS THIS TREE. `make seed` records the source hash it
# emitted from, and when that hash is the tree's own the seed already IS
# the compiler this source emits — linking it (`recover`) is the whole
# build, and a self-compile only rebuilds the same compiler byte for
# byte. A hash that differs means the seed's codegen MAY lag the source,
# and the two builds stand.
bootstrap: recover
	@h=$$(sh tools/sources_hash.sh); s=$$(cat bootstrap/seed.sources 2>/dev/null || echo none); \
	if [ "$$(sh tools/seed_is_tree.sh "$$h" "$$s")" = seed ]; then \
	    echo "bootstrap: the seed IS this tree — no self-compile"; \
	else \
	    echo "bootstrap: gen-1, the source compiled by the seed"; \
	    $(MAKE) -s avra || exit 1; \
	    echo "bootstrap: gen-2, the source compiled by gen-1"; \
	    $(MAKE) -s avra || exit 1; \
	    echo "bootstrap: build/avra is gen-2"; \
	fi

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
	@# what this binary was built from, for a worktree that wants to start from it
	@sh tools/work built-from . > build/.avra-built-from 2>/dev/null || rm -f build/.avra-built-from
	@sh tools/work deposit . || true
	@echo "avra: build/avra"

# WHAT A COMPILER BUILD LEAVES, one path a line: the binary, its hot leaves
# and every object it links with each object's stamp and dependency list.
# A cache of built compilers (tools/sprite-remote.sh) keeps exactly these.
compiler-files:
	@printf '%s\n' build/avra build/avra_hot.bc build/avra_hot.inc $(sort $(COMPILER_OBJS) \
	  $(patsubst %.o,%.sha,$(filter %.o,$(COMPILER_OBJS))) $(patsubst %.o,%.d,$(filter %.o,$(COMPILER_OBJS))))

# THE COMPILER FROM WHATEVER STANDS: the standing binary builds this tree
# GENS times (one `make avra` advances one generation; two reach a fixed point), and where none stands or
# it cannot read the tree — new syntax, a refusal about its own source — the
# seed bootstraps it, a FULL build, so a source wrong for real still dies.
# RUNGS are the tree's `Rung:` commits, oldest first (tools/rungs.sh): each is
# built by the product of the one before (tools/ladder.sh), starting from the
# standing compiler or the seed as linked, and HEAD by the last; a laddered
# tree never falls back to the seed, which cannot read a rung. The last rung's
# product stays at build/avra-ladder. LADDER_BASE is the base each rung is
# replayed on (tools/ladder.sh's AVRA_LADDER_BASE). GEN_BOUND bounds each build in seconds
# (tools/bounded.sh names the cause), LADDER_BOUND the whole ladder; STORE_ASIDE
# is where an older compiler's store goes before the bootstrap, since a store is
# one compiler's.
RUNGS ?=
LADDER_BASE ?=
GEN_BOUND ?=
LADDER_BOUND ?= 900
STORE_ASIDE ?=
GENS ?= 2
BOUNDED = $(if $(GEN_BOUND),sh tools/bounded.sh $(GEN_BOUND) )
compiler:
	@gens() { n=$(GENS); while [ "$$n" -gt 0 ]; do $(BOUNDED)$(MAKE) -s avra || return 1; n=$$((n - 1)); done; }; \
	if [ -n "$(strip $(RUNGS))" ]; then \
	  [ -x build/avra ] || $(MAKE) -s recover || { echo "compiler: the ladder has no start — none stands and the seed did not link"; exit 1; }; \
	  product=$$(AVRA_LADDER_BASE=$(LADDER_BASE) AVRA_LADDER_S=$(LADDER_BOUND) sh tools/ladder.sh build/avra $(RUNGS)) \
	    || { echo "compiler: the ladder failed — a rung did not build with the compiler of the rung before it"; exit 1; }; \
	  cp "$$product" build/avra-ladder && cp "$$product" build/avra; \
	  gens || { echo "compiler: the ladder's product did not build this tree — no seed can read a rung"; exit 1; }; \
	elif [ -x build/avra ] && gens; then :; else \
	  if [ -n "$(STORE_ASIDE)" ] && [ -d .avra-cache ]; then mv .avra-cache "$(STORE_ASIDE)"; fi; \
	  echo "compiler: the standing compiler did not build this tree — bootstrapping from the seed"; \
	  $(BOUNDED)$(MAKE) -s bootstrap; \
	fi

# THE EDIT LOOP: the source built by the STANDING compiler into
# build/avra-try, never over it — so the builder's print, and every row its
# store holds, stands from one edit to the next. `./avra-try` runs it. A
# change the compiler must READ to build itself (codegen, the front end, a
# refusal about its own source) reaches the product only through `make avra`.
try: $(COMPILER_OBJS)
	@sh tools/capped.sh build/avra-try-build.out 200000 ./avra build packages/cli --time || { cat build/avra-try-build.out; exit 1; }
	@grep '^time: ast' build/avra-try-build.out | grep -oE 'held [0-9]+/[0-9]+' || true
	@cp packages/cli/src/main build/avra-try
	@codesign -f -s - build/avra-try 2>/dev/null || true
	@rm -f packages/cli/src/main packages/cli/src/main.av.ll
	@echo "try: build/avra-try — ./avra-try runs it"

# THE WARM EDIT LOOP, measured: a one-edit check and build of the cli, and `make try` on a leaf and a core edit.
edit-loop:
	@sh tools/db_measure/edit_loop.sh

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
# not a keeper — provisions the machine it runs on
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
# definition.

# A STAMP IS NEVER AN INTERMEDIATE: make deletes the middle of a
# pattern chain once its end is built, and a deleted stamp is minted
# afresh next run, rebuilding every object every time — which reads as
# a slow build, never as a wrong rule. Precious keeps the stamps.
.PRECIOUS: build/%.sha

# A HEADER RIDES THE CONTENT HASH when a named list says so. The chain
# rule's own prerequisite is the `.c`, and the stamp normally hashes
# it; an object whose behaviour changes with a HEADER names that
# header too, so a stash-and-rebuild inside one second still rebuilds
# it instead of trusting a mtime. AN OBJECT'S FLAGS RIDE ITS STAMP TOO
# (`CFLAGS_<stem>`), so a census build's -DAVRA_CENSUS object is rebuilt
# the moment the flag is dropped, and never ships as the runtime.
SHA_SRC_avra_runtime := runtime/avra_runtime.c runtime/avra_box.h runtime/avra_rt.h runtime/avra_runtime.h runtime/avra_fiber.h runtime/avra_hot.h runtime/avra_random.h
SHA_SRC_avra_hot := runtime/avra_hot.c runtime/avra_hot.h runtime/avra_box.h
SHA_SRC_avra_fiber := runtime/avra_fiber.c runtime/avra_box.h runtime/avra_fiber.h runtime/avra_runtime.h
SHA_SRC_avra_tick := runtime/host/avra_tick.c runtime/avra_fiber.h
SHA_SRC_llvm_wrapper := backend/llvm_wrapper.c runtime/avra_box.h runtime/avra_hot.c runtime/avra_hot.h
SHA_SRC_ffi := packages/std-avrac/src/c/ffi.c runtime/avra_rt.h

# EVERY STAMP IN ONE PROCESS, SETTLED WHILE MAKE READS THIS FILE:
# tools/stamps.sh is handed every source's stamp — its sources and its
# flags — and rewrites only those whose digest moved, before make looks
# at any object's mtime, so the first build after a change sees it. One
# process where six a stamp ran, and the same content-hash law.
quoted = '$(subst ','\'',$1)'
stamp_args = $(call quoted,build/$1.sha) $(call quoted,$(or $(SHA_SRC_$1),$2)) $(call quoted,$(SECTIONS) $(CFLAGS_$1))
build/%.sha: ;


# THE RUNTIME'S OWN TESTS: C programs under runtime/tests/, each linked
# against the runtime's objects and run, for what no Avra program can
# reach yet — a row the language does not spell. GLOBBED, so a new test
# file runs without a line here. Built with the stack probes every frame
# on a task's stack carries: a test of the guard is a test of them.
RUNTIME_TESTS = $(patsubst runtime/tests/%.c,build/runtime-tests/%,$(wildcard runtime/tests/*.c))
build/runtime-tests/%: runtime/tests/%.c $(RUNTIME_OBJS)
	@mkdir -p build/runtime-tests
	@cc -O2 -Wall -Werror $(STACK_PROBES) -o $@ $< $(RUNTIME_OBJS)
runtime-tests: $(RUNTIME_TESTS)
	@for t in $(RUNTIME_TESTS); do $$t || exit 1; done

# THE TESTS, TESTED: one line of the scheduler broken at a time, and some
# runtime test must fail for each (runtime/tests/mutations.py).
runtime-mutations: $(RUNTIME_OBJS)
	@python3 runtime/tests/mutations.py build/runtime-mutations "$(STACK_PROBES)" $(filter-out build/avra_fiber.o,$(RUNTIME_OBJS))

# A TRACE HAS ONE SHAPE IN BOTH ENGINES: one program traced compiled
# and evaluated, the reader's shape of each held to a committed text.
flow-trace: $(COMPILER_OBJS) $(PACKAGE_OBJS) build/runtime-tests/tasks_door_test
	@sh tools/flow_trace_engines.sh

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
# THE STATIC LLVM LINK'S LIBRARY LIST holds to `llvm-config --link-static`: a lagging
# list is an undefined symbol at the link, far from its cause.
llvm-libs:
	@python3 tools/llvm_link.py --check

# THE EDIT CORPUS: one scripted edit at a time, the warm answers held to a cold copy's.
db-corpus: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/db_corpus.sh

cache-attacks: $(COMPILER_OBJS) $(PACKAGE_OBJS)
# The two shards are one job each on CI, one runner each, so the store they clear
# is their own; locally they run in order.
cache-attacks: cache-attacks-a cache-attacks-b cache-attacks-w
cache-attacks-a: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/cache_attacks.sh

# THE STORE'S CLEAN AND TIME TRAVEL (§6.7): the window, the size and age limits,
# a reader beside clean, a torn frame, a hold, the empty and absent cases — each
# CLEARS the store. `tools/store_attacks.sh` is §6.8's own list (a separate run;
# it holds a stage-1 marker for the S2 per-query rebuild).
store-attacks: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/store_clean_attack.sh

# Shard b is two jobs on CI (b1, b2), each on its own runner and store; b is both, in order.
cache-attacks-b: cache-attacks-b1 cache-attacks-b2
cache-attacks-b1: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/link_cache_attack.sh
	@sh tools/turn_memory_attack.sh
	@sh tools/gathered_cache_attack.sh
	@sh tools/closure_gather_attack.sh
	@sh tools/closure_fold_attack.sh
	@sh tools/impl_held_attack.sh
	@sh tools/store_reads_attack.sh
	@sh tools/cas_attack.sh
	@sh tools/docs_cache_attack.sh
	@sh tools/static_names_attack.sh
	@sh tools/moved_tree_attack.sh
	@sh tools/held_runs_attack.sh

cache-attacks-b2: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/stamp_attack.sh
	@sh tools/expanded_attack.sh
	@sh tools/held_generated_attack.sh
	@sh tools/store_quiet_attack.sh
	@sh tools/store_seal_attack.sh
	@sh tools/store_index_attack.sh
	@sh tools/stale_imports_attack.sh
	@sh tools/fn_add_attack.sh
	@sh tools/host_fn_edit_attack.sh
	@sh tools/suspect_narrow_attack.sh
	@sh tools/store_bound_attack.sh
	@sh tools/obj_gone_attack.sh
	@sh tools/names_attack.sh
	@sh tools/dep_tests_listing_attack.sh
	@sh tools/cancel_cache_attack.sh
	@sh tools/writes_attack.sh
	@sh tools/file_module_attack.sh
	@sh tools/cancel_bits_attack.sh
	@sh tools/readfound_attack.sh
	@sh tools/durable_symbol_attack.sh
	@sh tools/store_clean_attack.sh

# A CODE HASH IS STALE WHEN ITS CODE MOVES, AND ONLY THEN: each case edits what a query
# reaches and must recompute it, edits what it never reaches and must read it back. It
# CLEARS the store it builds through, as the attacks above do.
code-hash-attacks: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/code_hash_attacks.sh

# ONE DERIVATION ALIVE AT A TIME, held by memory: a rebuild that turns once per
# link of a chain of held bodies, under a ceiling one attempt clears and their
# sum trips. It CLEARS the store, as the attacks above do.
turn-memory-attack: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/turn_memory_attack.sh

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
	@clang -w -O1 -rdynamic build/seed-check/seed.ll $(SEED_LINK_OBJS) \
	    $(LLVM_LINK) -o build/avra-seed-check 2> build/seed-check/link.err \
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
	@python3 tools/shards.py --self-test
	@python3 tools/shards.py --check-splits
	@sh tools/suites_links.sh
	@sh tools/avra_tools.sh suites --report

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

# EVERY RULE EXAMPLE IS WALKED WHOLE: a `@fixes`/`@keeps` example that
# leads with a `type` or an `impl` still reaches the fn under test below
# it, and an example whose walk stops short is refused, never counted as
# coverage (compiler/rule_examples.av's `example_gaps`).
rule-examples:
	@./build/avra rules --check-examples

# THE HAND-WRITTEN FAMILIES MAY ONLY FALL. Every `@family` marker is a
# family not yet a `@query`; the count may only fall and the ceiling in
# tools/families.ceiling is lowered as one converts. A family is keyed
# by its NAME, so declaration order is free and no ordinal is durable.
families-left:
	@sh tools/avra_tools.sh families

# NO ANSWER STANDS ON A LONG READ LIST: a cold derivation of the cli, each family's longest
# read list held under 3,000, and the families still over it only shorten (tools/read_lists.py).
read-lists:
	@python3 tools/read_lists.py --self-test
	@python3 tools/read_lists.py

# THE SAVED-ANSWER METER MAY ONLY IMPROVE. A settled answer can be saved only if every
# read it made has a name that outlives the process; tools/leaves.sh counts, per blocking
# family, the answers a read of which cannot be named, and the baseline only falls.
# keeper: nightly (orders) — two cold whole-compiler checks, over 220 s warm for the cli alone, too long for every pull request
leaves:
	@sh tools/leaves.sh --check

# THE LAYERING IS ONE-WAY: no `use` names a layer above its own, and
# `@std/relation` — the engine below them all — never names the compiler.
layers:
	@python3 tools/layers.py

# A HOOK OF `Decls` THAT `let_go` DOES NOT RESET keeps its workspace alive.
# THE LIBRARY ROSTER READS DEFINED SYMBOLS ONLY (tools/libs.py): an undefined reference is what
# the image needs, never what it carries.
# THE CPU BACKSTOP'S OWN FIXTURES: a number carries its cache state and is only compared with the same
# state; a baseline keeps both states.
speed-note:
	@sh tools/speed_note.sh --self-test
	@python3 tools/step_cpu.py --self-test

libs-self-test:
	@python3 tools/libs.py --self-test
	@python3 tools/llvm_link.py --twin

hooks-released:
	@sh tools/avra_tools.sh hooks_released
	@sh tools/hooks_pre_commit_check.sh

# EVERY READ OF THE WORLD IS AN INPUT THROUGH ONE DOOR: the world reads
# outside the door, counted by subsystem; a site the baseline does
# not list is refused, and the baseline only falls.
# THE TOOLS PACKAGE'S OWN SUITE: the Avra ports of tools/*.py, proved on their spec tests.
tools-suite:
	@./avra test tools

inputs:
	@python3 tools/inputs.py

# EVERY BLOCKING CALL IN C HOLDS THE WORLD: a virtual clock flows across
# it, or the call says why it waits on no time (tools/clock_holds.py).
clock-holds:
	@python3 tools/clock_holds.py

inputs-accept:
	@python3 tools/inputs.py --accept

# EVERY WHOLE-PROGRAM READ IS A COUNTED SITE: a call that reads all of a relation's
# rows is licensed cold at its site or listed in tools/whole_reads.baseline, which
# only falls (tools/whole_reads.py). The run's own count is `check --counts`.
whole-reads:
	@python3 tools/whole_reads.py --self-test >/dev/null
	@python3 tools/whole_reads.py

whole-reads-accept:
	@python3 tools/whole_reads.py --accept

# A RECORDED READ HAS A BUDGET: retains, releases and list reads and writes
# per read, counted on the census runtime, never over read_cost.budget.
# Its bench links the tree's own package objects, so it names them.
read-cost: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/db_measure/read_cost.sh

# THE SPEED RATCHET, HARD: each phase of `packages/cli`'s own build and
# check held against a ceiling in tools/speed.budget, refusing past it and
# naming the phase with its before and after ms. The measurement is the
# LEAST of warm one-edit rounds (tools/speed_measure.sh), run on the
# machine the keeper stands on; on macOS it goes to the lane's Sprite
# (`tools/work run`), since a loaded Mac supplies no number. The gate's
# fixtures prove the gate before it judges. `speed-accept` lowers the
# ceilings to what was measured and never raises one.
speed-ratchet:
	@python3 tools/speed_ratchet.py --self-test >/dev/null
	@python3 tools/speed_ratchet.py
speed-accept:
	@python3 tools/speed_ratchet.py --self-test >/dev/null
	@python3 tools/speed_ratchet.py --accept

# THE WALL-CLOCK RATCHET: a PR check's per-job and whole wall time, held in
# the same tools/speed.budget the phase ratchet reads (ONE file, ONE reader),
# measured by tools/ci_wall.sh from a run's own jobs and judged in the `test`
# job of every PR run. A ceiling may only fall: this lowers it to a run's
# measured times and never raises one. Point it at a run's metrics with
# `make wall-accept WALL=<file>`, where the file is
# `sh tools/ci_wall.sh --repo <o/r> --run <id> collect`.
WALL ?= wall.metrics
wall-ratchet:
	@python3 tools/speed_ratchet.py --self-test >/dev/null
	@python3 tools/speed_ratchet.py --wall --raw "$(WALL)"
wall-accept:
	@python3 tools/speed_ratchet.py --self-test >/dev/null
	@python3 tools/speed_ratchet.py --wall --accept --raw "$(WALL)"

# THE DB 07 WARM-EDIT GATE (avra-8sb5.57.176): an unchanged
# `check packages/cli` and one body edit, wall, on a warm store. The
# ticket's GOAL is 60 ms / 300 ms (goal 150), but today's path is far over
# it, so the ENFORCED rows in tools/speed.budget are the MEASURED PRESENT —
# the starting line — with WARM_RATIO's allowance for a shared runner's
# variance. `--accept` may only LOWER a row toward the goal, never raise
# it. tools/warm_edit_bench.sh measures it and judges it through
# tools/speed_ratchet.py --warm, whose rows are the same tools/speed.budget
# the phase ratchet reads — ONE file, ONE reader. A run that CANNOT judge
# FAILS with a named reason (a skip is not a pass); only a hand-set
# WARM_EDIT_SKIP — the workflow's `warm_skip` input — stands it down,
# loudly. In CI the store rides down from prepare and SPEED_HOST is
# `ci-warm`, so a runner's CPU never decides whether the gate is judged.
# On macOS the measurement goes to the lane's Sprite, as speed-ratchet does.
# THE COLD-COMPILE WORK GATE: a cold `check packages/cli` under the census runtime, its exact
# retain/release/list counts held per declaration to tools/census.budget. `SPEED_ACCEPT` (the
# PR body's reason) lets a PR cost more, loudly; see tools/census_ratchet.py. The cold CHECK
# is the gated workload, not the compiler's own build: the build would need a census-built
# builder (one more compiler generation, ~+150 s), and the check runs the same front end,
# lowering and store.
census-gate:
	@python3 tools/census_ratchet.py --self-test >/dev/null
	@sh tools/speed_note.sh --self-test >/dev/null
	@sh tools/census.sh check --counts packages/cli > build/census-gate.out 2>&1 || { tail -20 build/census-gate.out; exit 1; }
	@python3 tools/census_ratchet.py --raw build/census-gate.out --main $${CENSUS_MAIN:-census-main.txt} --main-sites $${CENSUS_SITES_MAIN:-census-sites-main.txt}
census-accept:
	@sh tools/census.sh check --counts packages/cli > build/census-gate.out 2>&1 || { tail -20 build/census-gate.out; exit 1; }
	@python3 tools/census_ratchet.py --accept --raw build/census-gate.out

warm-edit:
	@python3 tools/ratchet_rows.py --self-test >/dev/null
	@python3 tools/speed_ratchet.py --self-test >/dev/null
	@python3 tools/work_ratchet.py --self-test >/dev/null
	@sh tools/warm_edit_bench.sh
warm-accept:
	@python3 tools/speed_ratchet.py --self-test >/dev/null
	@WARM_EDIT_ACCEPT=1 sh tools/warm_edit_bench.sh
# The work-count ceilings only fall: this lowers each to what the compiler counted
# (and seeds a new counter), never raises one. Review the diff of tools/work.budget.
work-accept:
	@python3 tools/work_ratchet.py --self-test >/dev/null
	@WORK_ACCEPT=1 sh tools/warm_edit_bench.sh

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

# NO DEFECT VOICE REACHES A USER PROGRAM: every malformed or edge program
# in tools/defects/corpus.txt, and every mutation of its bases, is checked
# and run, and one answered with a defect voice or a trap refuses. A SEEDED
# SET of mutants of the tree's own program tests rides beside them; more is
# `python3 tools/defects.py --only gen: --generate 500 --seed <n>`. Every program's
# seconds land in build/defects-timings.tsv (the job uploads it), and a timeout names
# the seconds the last green run took (build/defects-timings.prev.tsv, fetched by
# tools/defects_previous.py).
defects:
	@python3 tools/defects.py --self-test
	@python3 tools/defects_previous.py --self-test
	@sh tools/watch.sh 6000 python3 tools/defects.py --generate 40 --seed 0 --timings build/defects-timings.tsv $$([ -f build/defects-timings.prev.tsv ] && echo --previous build/defects-timings.prev.tsv)

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

# THE WEB'S EVENT ENUM IS GENERATED from the pinned webref file: DomEvent is
# what tools/src/commands/host_events.av writes, and a variant kept by hand would be an
# event the platform never fires.
host-events:
	@sh tools/avra_tools.sh host_events

# THE JS HOST IS TESTED BY THE GATE, not by whoever remembers to: a host
# nothing runs is a second implementation nothing checks.
# Its wide corpus is a NATIVE program, so what a native link reads — the
# runtime archive and the packages' C objects — are its prerequisites: a
# tree that has built nothing builds them here, never inside the script.
ui-host-test: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/ui_host_test.sh

# THE DIFF'S LAW, AT LENGTH: trees grown and edited by chance, each repaint
# applied to a modelled host and held to the page its tree is
# (tools/ui_fuzz.sh). UI_FUZZ_SEED, UI_FUZZ_SEEDS and UI_FUZZ_CASES size it.
# keeper: nightly (orders) — 530 s, too long for every pull request
ui-fuzz: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@sh tools/ui_fuzz.sh

# THE HOST SEAM, END TO END: the board built as a wasm reactor and run over the
# real page glue, each claim checked (tools/ui-board/demo.mjs). Skips, spoken,
# where node or a wasm toolchain is absent.
ui-board:
	@sh tools/ui_board.sh

# A PAGE'S SERVER RUNS BESIDE IT UNDER `avra dev`: a page package naming
# `[dev] server` is served with that package's program on one origin, and a
# save to the server's source is served without a restart (tools/dev_server_check.sh).
dev-server:
	@sh tools/bounded.sh 600 sh tools/dev_server_check.sh

# THE BOARD IN A REAL BROWSER: the same module served over an HTTP origin and
# driven in headless Firefox, each claim checked (tools/ui-board/browser.mjs).
# Where Firefox, node or a wasm toolchain is absent it FAILS, unless
# UI_BROWSER_SKIP=<reason> stands it down; ui-browser-skip holds that contract.
ui-browser:
	@sh tools/ui_board_browser.sh

ui-browser-skip:
	@sh tools/ui_board_browser.sh --self-test

# THE LAYOUT SOLVER AGAINST THE WEB TARGET: std-ui's `place` and Firefox running
# the page the real html realizer writes, on the same random trees (fixed seeds),
# every box in agreement (tools/layout-oracle). Fails where Firefox or node is
# absent, unless LAYOUT_ORACLE_SKIP=<reason> stands it down.
layout-oracle:
	@sh tools/layout_oracle.sh
	@sh tools/layout_oracle_absent_test.sh
	@sh tools/layout_oracle_own_term_test.sh
	@sh tools/layout_oracle_boundary_test.sh

# A fingerprint tag NAMES a node kind: inside one fold space no two
# kinds may wear one number, or they fingerprint alike by construction.
fingerprints:
	@python3 tools/fingerprints.py

# THE FOOTPRINT: a program that spawns nothing links no scheduler, and the
# smallest programs' bytes stay under a relative cap (tools/footprint.py).
footprint: $(RUNTIME_LIB)
	@python3 tools/footprint.py --self-test
	@python3 tools/footprint.py

# Re-accept this platform's sizes deliberately.
footprint-accept: $(RUNTIME_LIB)
	@python3 tools/footprint.py --accept

# THE FLOW G1 GATE: the scheduler's transition rows (a gate round trip,
# spawn+join, a cold parked spawn) against tools/flow_bench/gate.baseline,
# refusing past 2x. A change under runtime/ can cost the transition hot
# path without touching a test, so a runtime PR runs this before its own
# checks (the `flow-gate` job in .github/workflows/checks.yml, which fires
# on a diff under runtime/). `--require` makes a machine with no baseline
# row a REFUSAL; a lane measuring a runtime saved elsewhere points
# FLOW_RUNTIME at it.
flow-gate:
	@python3 tools/flow_bench/gate.py --self-test
	@sh tools/flow_bench/run.sh --gate $(FLOW_GATE_ARGS)
# Re-accept this machine's rows deliberately (FLOW_RUNTIME for another tree).
flow-gate-accept:
	@sh tools/flow_bench/run.sh --record

# THE TICK'S TWO KEEPERS. `tick-object` holds the hosted source's
# undefined symbols to the no-lock set a forked child may inherit;
# `no-threads` holds the scheduler's own `runtime/*.c` free of threads
# and thread-locals (D7).
tick-object: $(RUNTIME_LIB)
	@python3 tools/tick.py object --self-test

no-threads:
	@python3 tools/tick.py threads --self-test

# THE KEEPERS, ONE LIST. The train's keepers job and a lane's own
# tools/gate_changed.sh both run `make keepers`, so a keeper named here
# is held on every train, and one left off is held by nobody. A pull
# request's own check runs only those that need no compiler
# (KEEPERS_STATIC); the train runs them all, before anything merges.
# Each names what it links as its own prerequisites.
# Every keeper runs, and each that refuses is named.
# TWO HALVES OF ABOUT EQUAL COST, so the train's one keepers job can run
# them side by side, each in its own copy of the tree (keepers-a,
# keepers-b). KEEPERS is their union and the ones that run alone: a keeper
# joins one of the three, never a list of its own. Each keeper's seconds
# are printed, which is what balances the halves — the second is the
# lighter because the train runs the seed check after it.
# KEEPERS_ALONE are held to a clock (a timer firing within one round of the
# scheduler), so nothing may compete with them for a core. The mutation run
# drives the same clocked tests, so it stands here beside them.
KEEPERS_ALONE = runtime-tests runtime-mutations
# KEEPERS_A is two halves, one CI runner each, balanced by measured seconds
# (speed-ratchet is the longest keeper, alone it is half the set).
KEEPERS_A1 = speed-ratchet census-gate fmt-lossless hash-door stems
KEEPERS_A2 = read-cost read-lists warm-edit codecs traps compile-slots witness flow-trace
KEEPERS_A = $(KEEPERS_A1) $(KEEPERS_A2)
KEEPERS_B = libscope h2spec tools-suite fingerprints vocab families-left layers libs-self-test speed-note hooks-released inputs whole-reads cited http-cites externs trap-marks suites rt-header rt-ns witnesses dogfooding-rules rule-examples attack voices defects \
            ui-host host-events ui-host-test ui-board dev-server ui-browser ui-browser-skip tool-witnesses footprint tick-object no-threads \
            ci-invariants ci-verdict pr-watcher pipeline-doc workflows-yaml tail-status vendored-fixture
# KEEPERS_WASM is the wasm target's proof — the fixtures native and wasm32 alike, the seam,
# the refusals, the hosted scheduler broken on purpose, the store across targets, the
# archive's law and the size receipt — a CI
# runner of its own, so its minutes ride beside the halves rather than after one.
KEEPERS_WASM = wasm-host-check wasm-check wasm-seam wasm-refuses wasm-tasks-mutations wasm-cache wasm-archive wasm-size-guard
KEEPERS = clock-holds $(KEEPERS_ALONE) $(KEEPERS_A) $(KEEPERS_B) $(KEEPERS_WASM)
keepers keepers-alone keepers-a keepers-a1 keepers-a2 keepers-b keepers-wasm:
	@sh tools/keepers_loop.sh "$(MAKE) -s -o avra" $(if $(filter keepers-alone,$@),$(KEEPERS_ALONE),$(if $(filter keepers-a1,$@),$(KEEPERS_A1),$(if $(filter keepers-a2,$@),$(KEEPERS_A2),$(if $(filter keepers-a,$@),$(KEEPERS_A),$(if $(filter keepers-b,$@),$(KEEPERS_B),$(if $(filter keepers-wasm,$@),$(KEEPERS_WASM),$(KEEPERS)))))))

# THE TOOLS' OWN WITNESSES, DERIVED (tools/tool_witnesses.sh): every
# witness_*.sh and *_test.sh, and every tool declaring `# tool-witness:
# --self-test`, that no other keeper declares it runs; a self-test nobody
# runs is refused. None reads the compiler. `sh tools/tool_witnesses.sh list`
# shows who runs each.
tool-witnesses:
	@sh tools/tool_witnesses.sh --self-test
	@sh tools/tool_witnesses.sh run

# THE STORE'S WITNESSES: package builds under the memory cap, each over a cold
# then a warm store, and the edit corpus's warm answers held to a cold copy's —
# a cache-attacks shard of their own (w), since one alone outlasts a minute.
STORE_WITNESSES = $(shell grep -l '^\# tool-witness: run by make store-witnesses' tools/*.sh)
cache-attacks-w: store-witnesses db-corpus
store-witnesses: $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@fail=""; for w in $(STORE_WITNESSES); do MEMCAP=tools/memcap.sh sh $$w || fail="$$fail [$$w]"; done; \
	 [ -z "$$fail" ] || { echo "store-witnesses: refused —$$fail"; exit 1; }

# THE CI STRUCTURE RATCHET: the release path, the compiler-free keepers a
# PR must reach and the watcher's fixtures are held before a green PR can
# break them. It reads the workflow and this Makefile alone, so no compiler.
ci-invariants:
	@python3 tools/ci_invariants.py --self-test
	@python3 tools/ci_invariants.py
	@sh tools/profile.sh --self-test
	@python3 tools/ci_dup_run.py --self-test
	@sh tools/batch_test.sh
	@python3 tools/pr_mode.py --self-test

# THE AGGREGATE VERDICT'S FIXTURES: the `test` job's arithmetic is a script
# (tools/ci_verdict.sh), and these prove it counts what it claims — a skipped
# leg green, a failure named with its count, a job the gate owed but the run
# never reported refused — before it judges a run.
ci-verdict:
	@sh tools/ci_verdict.sh --self-test

# THE WATCHER'S DECISION IS A KEEPER: its fixtures run wherever the gate
# runs, so a change to what the watcher may do refuses before it can land,
# not one schedule pass later.
pr-watcher:
	@python3 tools/pr_watcher.py --self-test

# THE PIPELINE DOCUMENT'S COMMANDS RESOLVE: every `make <target>` and
# `tools/` path in docs/2026_10_11_THE_PIPELINE.md names something the
# tree holds. A command the tree no longer carries is refused here
# rather than read as current. A name kept as a HISTORICAL negative
# example stands in tools/pipeline_doc.allow with its reason.
pipeline-doc:
	@python3 tools/pipeline_doc.py

# The std-avrac fixtures vendor each std package whole: the files the manifest closure
# names, no more and no fewer (tools/vendored_fixture.py).
vendored-fixture:
	@python3 tools/vendored_fixture.py --self-test
	@python3 tools/vendored_fixture.py

# A BUILD'S STATUS NEVER DIES IN A PIPE: no build, run, make or node is
# piped into `tail` outside `tools/capped.sh --last` (tools/tail_status.sh).
tail-status:
	@sh tools/tail_status.sh --self-test
	@sh tools/tail_status.sh

# THE ONE-LINE BLOCKER: why nothing is landing, in a handful of lines.
# Read-only and safe any time — `main`'s SHA and age; the last runs'
# failures COUNTED BY JOB; each open PR's blocker in one word; whether the
# local watchdog driver is loaded and has run recently; and a one-line
# VERDICT naming the single most likely blocker. A signal it cannot read
# prints `unknown` and is skipped, never given a plausible default. The
# verdict is a pure function over a state, proved on synthetic fixtures
# with no network (`--self-test`, held by `make tool-witnesses`);
# `ARGS=--witness` prints each verdict firing.
# not a keeper — a report: why nothing is landing, read-only
pipeline-status:
	@python3 tools/pipeline_status.py $(ARGS)

# THE KEEPERS THAT NEED NO COMPILER, which a pull request's own check runs
# before it builds anything: each reads the tree alone and all of them
# together take half a minute, so a refusal stops on the PR instead of
# failing a train and every PR riding it. Each is one of KEEPERS, which the
# train runs whole.
KEEPERS_STATIC = host-events fingerprints vocab families-left layers libs-self-test speed-note hooks-released cited http-cites externs suites ui-browser-skip ci-invariants ci-verdict pr-watcher pipeline-doc workflows-yaml tail-status vendored-fixture
.PHONY: compiler compiler-files store-witnesses cache-attacks-w keepers keepers-alone keepers-a keepers-a1 keepers-a2 keepers-b keepers-wasm keepers-static keepers-pr pipeline-doc tail-status pipeline-status ci-invariants ci-verdict pr-watcher
keepers-static:
	@left="$(filter-out $(KEEPERS),$(KEEPERS_STATIC))"; [ -z "$$left" ] || { echo "keepers-static: $$left is no keeper — the train would not hold it" >&2; exit 1; }
	@sh tools/keepers_loop.sh "$(MAKE) -s" $(KEEPERS_STATIC)

# THE KEEPERS A PULL REQUEST CAN BREAK ALONE, which its own check runs once
# its compiler is built: each holds a file the tree generates or carries to
# what that compiler says — the runtime header and namespace, the
# diagnostics index, the idiom registry, the runtime's footprint — or
# attacks a feature mechanically, in seconds. A refusal stops on the PR
# instead of failing a train. Each is one of KEEPERS, which the train runs
# whole.
KEEPERS_PR = rt-header rt-ns witnesses dogfooding-rules footprint attack speed-ratchet warm-edit
# not a keeper — a lane's quick subset of KEEPERS before pushing; CI runs every keeper
keepers-pr:
	@left="$(filter-out $(KEEPERS),$(KEEPERS_PR))"; [ -z "$$left" ] || { echo "keepers-pr: $$left is no keeper — the train would not hold it" >&2; exit 1; }
	@sh tools/keepers_loop.sh "$(MAKE) -s -o avra" $(KEEPERS_PR)

# THE CODEC KEEPER: a record's wire ENCODER and its DECODER agree.
# compiler/codecs.av's registry runs every pair over its exemplars,
# decode(encode(x)) compared to x field by field; tools/codecs.py
# refuses any encoder/decoder-shaped pair in the tree the registry
# does not name.
#
# THE SCAN IS ITS OWN TARGET because it needs no compiler: a pull request
# whose diff reaches the compiler's source runs `codecs-static` in seconds
# (it is what names an unregistered pair — the refusal #537 failed a train
# on), so the defect is heard on the PR, not one train later. The
# registry's round trip needs a whole compiler and stays with the train.
codecs: codecs-static $(COMPILER_OBJS) $(PACKAGE_OBJS)
	@./build/avra test packages/std-avrac/src/compiler/tests/codecs_test.av

codecs-static:
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

# WHAT EVERY VOICE CARRIES: a witness, help, and a structured fix where
# its registry row owes one — read from the registry and the compiler's
# own rendering of each witness (`avra voices`). A NEW kind or rule with
# a gap refuses; tools/voices.baseline lists the gaps that stand and only
# shrinks (`make voices-accept` prunes what a fix paid). docs/VOICES.md
# is the generated inventory, never edited.
voices:
	@./avra voices --baseline tools/voices.baseline
	@python3 tools/voices_spoken.py
	@./avra voices --report > build/VOICES.md.gen
	@cmp -s build/VOICES.md.gen docs/VOICES.md || { \
	  echo "voices: docs/VOICES.md is not what the compiler says — it is generated, never edited:"; \
	  echo "voices:   ./avra voices --report > docs/VOICES.md"; \
	  diff docs/VOICES.md build/VOICES.md.gen 2>/dev/null | head -30; exit 1; }

voices-accept:
	@./avra voices --baseline tools/voices.baseline --accept

# THE EXTERN WALL'S WIDTH: Avra's `int` is 64 bits and C's is 32, so a
# C body answering a narrow type writes only the low half and a
# negative value reads as a large positive one. Both engines agree on
# that wrong answer, so a program test cannot catch it.
externs:
	@python3 tools/externs.py

# THE WORKFLOW PARSE KEEPER: every workflow file reads as YAML. A file that does not parse
# runs with no jobs, so the check it was meant to run examines nothing (tools/workflows_yaml.py).
workflows-yaml:
	@python3 tools/workflows_yaml.py --self-test >/dev/null
	@python3 tools/workflows_yaml.py

# THE TRAPS COLUMN'S KEEPER: a row marked `traps: false` reaches no trap the
# language raises (tools/traps.py).
trap-marks:
	@python3 tools/traps.py

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
# its status is discarded here.
# not a keeper — a lane's local union of keepers; CI runs each in its own job
gate: llvm-libs seed-check stems vocab fingerprints ui-host ui-host-test ui-board ui-browser families-left layers hooks-released codecs rt-header rt-ns witnesses externs idioms cited dogfooding-rules fmt-lossless attack tested runtime-tests traps compile-slots witness tool-witnesses cache-attacks
	@sh tools/gate_receipt.sh write || true

tested: $(COMPILER_OBJS) $(PACKAGE_OBJS) libs
	@rm -rf packages/std-avrac/src/features/zz_probe
	@sh tools/capped.sh build/scaffold-new.out 200000 ./avra new feature zz_probe || { cat build/scaffold-new.out; exit 1; }
	@trap 'rm -rf packages/std-avrac/src/features/zz_probe' EXIT INT TERM; $(MAKE) -s test SHARDS_SKIP=std-avrac/src/features/zz_probe

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
# not a keeper — a report: the suites' wall time
bench: $(COMPILER_OBJS)
	@sh tools/bench.sh

# The collection vocabulary's bench: C1–C12, each Avra program against
# its Rust twin, median of 5 (tools/bench/collections/run.sh).
bench-collections: build/libavra_runtime.a
	@sh tools/bench/collections/run.sh

# THE BENCHMARK SUITE, ONE DOOR: `benchmarks/run.sh` measures every
# registered language's twin on this machine and `--g1` prints each Avra
# row beside Go's, with the target verdict (2x time, 3x parked bytes, as
# data in benchmarks/bench.toml's [gate.target]). `flow-g1` is the same
# view, and each Avra row past its target against the recorded Go row
# REFUSES.
#
# `tools/flow_bench/` is the older scheduler-transition harness. Its
# Go-beside-Avra view is the design the suite now carries at scale; what
# it uniquely holds stays here — `flow-gate` is the runtime-only C floor
# a runtime/*.c change answers, and `flow-probes` is the stack
# allocator's own measurements, neither needing a compiler or Go.
.PHONY: flow-bench flow-probes flow-g1 flow-trace
flow-bench: build/libavra_runtime.a
	@sh benchmarks/run.sh --g1 --quiet
flow-g1: build/libavra_runtime.a
	@sh benchmarks/run.sh --g1 --gate --require --quiet
flow-probes:
	@sh tools/flow_bench/run.sh probes

# h2spec over std-http's HTTP/2 server, in the clear and over TLS;
# skipped, with a word, when h2spec is not installed.
h2spec: $(COMPILER_OBJS)
	@sh tools/h2spec.sh

# Boxes a program's runtime rows answer, by type, ranked — the
# representation-selection opportunity list.
#   make census-types PROGRAM=tools/bench/request/src/main.av
PROGRAM ?= tools/bench/request/src/main.av
# not a keeper — a report: one program's representation opportunities
census-types:
	@sh tools/census_types.sh $(PROGRAM)

# Bytes of code per symbol by package: the compiler and a request's
# server, each against BEFORE / REQUEST_BEFORE when given (a saved
# binary), as the tables a slice's size delta is read from; then what
# each reach probe carries (tools/bench/reach) — a program pays for
# what it calls, never for what it imports.
#   make sizes BEFORE=build/avra.pre
REACH := hello limits plain unreached tls sign
# not a keeper — a report: what each reach program carries
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
# keeper: nightly (orders) — 465 s, too long for every pull request
fuzz: $(COMPILER_OBJS)
	@sh tools/fuzz.sh

# THE HTTP FRAMERS FUZZED in bounded time (FUZZ_HTTP_SECONDS, default
# 180): the corpus and every kept finding replayed, libFuzzer over the
# C rows, then the seeded mutation fuzzer — a trap bisected to its one
# mutant and kept in packages/std-http-fuzz/crashes.
# keeper: nightly (orders) — 192 s, too long for every pull request
fuzz-http: build/libavra_runtime.a
	@sh tools/fuzz_http.sh

# THE HTTP SERVER SOAKED: 10k keep-alive connections on every core for
# SOAK_HTTP_SECONDS (default 600, ten minutes), the reset law looped 1000x
# under that load; prints the load, memory, descriptors and resets it saw.
# not a keeper — a ten-minute load report, read by a person
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

# THE STAMPS SETTLE LAST, once every flag they read is defined (see
# `stamp_args`, above): an earlier settling would hash a flag still empty.
STAMPS_SETTLED := $(shell sh tools/stamps.sh $(foreach c,$(TREE_C),$(call stamp_args,$(basename $(notdir $(c))),$(c))))
