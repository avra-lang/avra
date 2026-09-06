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

LLVM_PREFIX ?= /opt/homebrew/opt/llvm
# a manifest's link flags name it as ${LLVM_PREFIX}
export LLVM_PREFIX

RUNTIME_OBJS := build/llvm_wrapper.o build/avra_runtime.o

# Every package that carries spec cases, in dependency order.
SUITES := packages/std-errors packages/std-testing packages/std-text packages/std-path packages/std-time packages/std-io packages/std-toml packages/std-process packages/std-cli packages/std-json packages/std-avrac packages/cli

.PHONY: census traps test tested clean corpus gate externs idioms idioms-accept bench fuzz scaffold-check vocab sweep seed bootstrap \
        check run ir emit build-native native-check avra

# THE COMPILER, BUILT BY ITSELF: the binary in build/ compiles the
# tree into the next one. `./avra` prefers it and bootstraps a cold
# tree only.
# THE SEED: the compiler, emitted, so the chain cannot be lost.
# `make bootstrap` builds a compiler from it and then rebuilds from
# source; `make seed` refreshes it. bootstrap/README.md holds the rule.
seed: $(RUNTIME_OBJS)
	@./avra emit packages/cli > bootstrap/seed.ll
	@echo "seed: bootstrap/seed.ll ($$(wc -l < bootstrap/seed.ll | tr -d ' ') lines)"

bootstrap: $(RUNTIME_OBJS)
	@mkdir -p build
	@clang -w -O1 bootstrap/seed.ll build/avra_runtime.o build/llvm_wrapper.o \
	    -L$(LLVM_PREFIX)/lib -lLLVM -o build/avra
	@codesign -f -s - build/avra 2>/dev/null || true
	@echo "bootstrap: build/avra from the seed — rebuilding from source"
	@$(MAKE) -s avra

# A REFUSAL MUST SPEAK: the build's own words went to /dev/null, so a compiler
# that refused its own source reported only "make: *** Error 2" and the next
# reader ran `./avra build packages/cli` by hand to find out why.
avra: $(RUNTIME_OBJS)
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

test: $(RUNTIME_OBJS)
	@for p in $(SUITES); do \
	  ./avra test $$p || exit 1; \
	done

build/avra_runtime.o: runtime/avra_runtime.c
	@mkdir -p build
	cc -O2 -Wall -Werror -c runtime/avra_runtime.c -o build/avra_runtime.o

# The runtime's trap contract: the words and the verdict (exit 2).
# No corpus program can hold it — the corpus runs every program in
# one process, and a trap ends it.
traps: $(RUNTIME_OBJS)
	@sh tools/traps.sh

# Exact refcount and list-write counts; the shipping runtime is put
# back on every exit.   make census CMD="check packages/std-avrac"
census:
	@sh tools/census.sh $(CMD)

build/llvm_wrapper.o: backend/llvm_wrapper.c
	@mkdir -p build
	cc -c -O2 -I$(LLVM_PREFIX)/include -o build/llvm_wrapper.o backend/llvm_wrapper.c

clean:
	rm -rf build scratch packages/cli/src/main_stamped.av
	find packages corpus -name "*.av.ll" -delete
	find corpus -type f ! -name "*.av" ! -name "*.expected" ! -name "expected" ! -name "avra.toml" -delete
	rm -rf packages/*/build

check: $(RUNTIME_OBJS)
	@./avra check $(FILE)

run: $(RUNTIME_OBJS)
	@./avra run $(FILE)

ir: $(RUNTIME_OBJS)
	@./avra ir $(FILE)

emit: $(RUNTIME_OBJS)
	@./avra emit $(FILE)

build-native: $(RUNTIME_OBJS)
	@./avra build $(FILE)

# The corpus gate: every corpus/*.av must say its .expected — first
# through the evaluator, then through ONE native binary holding them
# all (`avra corpus`). A feature's end-to-end proof is one tiny
# program plus one tiny expected file.
# A PACKAGE proves the same as corpus/<name>/main.av (its avra.toml
# marks the root) beside corpus/<name>/expected. corpus/native/ holds
# programs the evaluator cannot run — extern fns — proved native only.
corpus: $(RUNTIME_OBJS)
	@./avra corpus corpus
	@./avra corpus --native-only corpus/native
	@for d in corpus/*/; do \
	  d=$${d%/}; [ -f $$d/src/main.av ] || continue; \
	  ./avra run $$d/src/main.av > /tmp/avra-corpus-eval.out 2>&1 \
	    || { echo "$$d: eval FAILED"; cat /tmp/avra-corpus-eval.out; exit 1; }; \
	  diff $$d/expected /tmp/avra-corpus-eval.out \
	    || { echo "$$d: eval != expected"; exit 1; }; \
	  ./avra build $$d/src/main.av > /tmp/avra-bin.path 2>&1 \
	    || { echo "$$d: build FAILED"; cat /tmp/avra-bin.path; exit 1; }; \
	  $$(cat /tmp/avra-bin.path) > /tmp/avra-corpus-native.out; \
	  diff $$d/expected /tmp/avra-corpus-native.out \
	    || { echo "$$d: native != expected"; exit 1; }; \
	  echo "$$d: eval == native == expected"; \
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
# test is C someone else compiled. When a package can build its own
# native sources (ROADMAP: B7) this rule dies and the manifest's
# `sources` does the work.
build/width_witness.o: packages/width-witness/src/witness.c
	@mkdir -p build
	cc -c -O2 -o build/width_witness.o packages/width-witness/src/witness.c

witness: $(RUNTIME_OBJS) build/width_witness.o
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
gate: vocab externs idioms traps tested corpus witness

tested: $(RUNTIME_OBJS)
	@rm -rf packages/std-avrac/src/features/zz_probe
	@./avra new feature zz_probe > /tmp/avra-scaffold-new.out 2>&1 || { cat /tmp/avra-scaffold-new.out; exit 1; }
	@trap 'rm -rf packages/std-avrac/src/features/zz_probe' EXIT INT TERM; $(MAKE) -s test

# The differential gate: the compiled binary must say exactly what
# the evaluator says.
native-check: $(RUNTIME_OBJS)
	@./avra run $(FILE) > /tmp/avra-eval.out
	@./avra build $(FILE) > /tmp/avra-bin.path
	@$$(cat /tmp/avra-bin.path) > /tmp/avra-native.out
	@diff /tmp/avra-eval.out /tmp/avra-native.out && echo "native == eval"

# The measured curve: suite + native corpus wall times.
bench: $(RUNTIME_OBJS)
	@sh tools/bench.sh

# Mutated corpus through `avra check`: diagnose, never crash.
fuzz: $(RUNTIME_OBJS)
	@sh tools/fuzz.sh

# The scaffolder's templates must stay compilable: scaffold a
# throwaway feature, run the suite with it in the tree, remove it.
scaffold-check: $(RUNTIME_OBJS)
	@rm -rf packages/std-avrac/src/features/zz_probe
	@./avra new feature zz_probe > /tmp/avra-scaffold-new.out 2>&1 || { cat /tmp/avra-scaffold-new.out; exit 1; }
	@./avra test packages/std-avrac/src/features/zz_probe/tests/zz_probe_test.av > /tmp/avra-scaffold.out 2>&1; s=$$?; \
	  rm -rf packages/std-avrac/src/features/zz_probe; \
	  if [ $$s -ne 0 ]; then echo "scaffold-check FAILED"; tail -20 /tmp/avra-scaffold.out; exit 1; fi; \
	  echo "scaffold-check: the templates compile and their test passes"
