# bs2 must be invoked by absolute path: it re-invokes itself via argv[0]
# from other working directories. It links against build/runtime.o and
# build/llvm_wrapper.o but does not build them; they are copied from
# the bootstrap tree.

BOOTSTRAP := ../forge-crafting-intepreters/bootstrap
BS2       := $(abspath $(BOOTSTRAP))/build/bs2

RUNTIME_OBJS := build/runtime.o build/llvm_wrapper.o

.PHONY: test clean fresh libfresh corpus gate idioms idioms-accept

# bs2's lib-mode freshness truth is the .avra-sha256 sidecars; they
# go stale against edits. Every bs2-run target clears them first.
fresh:
	@find packages -name "*.avra-sha256" -delete

# Nuclear cache purge — ./avra's stamped entry makes routine runs
# truthful, so this is for salvage, not the workflow.
libfresh: fresh
	@rm -rf packages/*/build

test: $(RUNTIME_OBJS)
	$(BS2) test

build/%.o: $(BOOTSTRAP)/build/%.o
	@mkdir -p build
	cp $< $@

clean:
	rm -rf build
	find packages corpus -name "*.avra-sha256" -delete
	find packages corpus -name "*.av.ll" -delete
	find corpus -type f ! -name "*.av" ! -name "*.expected" -delete
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
# through the evaluator, then through the native binary. A feature's
# end-to-end proof is one tiny program plus one tiny expected file.
corpus: $(RUNTIME_OBJS)
	@for f in corpus/*.av; do \
	  ./avra run $$f > /tmp/avra-corpus-eval.out 2>&1 \
	    || { echo "$$f: eval FAILED"; cat /tmp/avra-corpus-eval.out; exit 1; }; \
	  diff $${f%.av}.expected /tmp/avra-corpus-eval.out \
	    || { echo "$$f: eval != expected"; exit 1; }; \
	  ./avra build $$f > /tmp/avra-bin.path 2>&1 \
	    || { echo "$$f: build FAILED"; cat /tmp/avra-bin.path; exit 1; }; \
	  $$(cat /tmp/avra-bin.path) > /tmp/avra-corpus-native.out; \
	  diff $${f%.av}.expected /tmp/avra-corpus-native.out \
	    || { echo "$$f: native != expected"; exit 1; }; \
	  echo "$$f: eval == native == expected"; \
	done

# The idiom ratchet: mechanical smells may never RISE. Counts are
# pinned in tools/idioms.baseline; falling counts re-pin with
# `make idioms-accept`.
idioms:
	@sh tools/idioms.sh

idioms-accept:
	@sh tools/idioms.sh --accept

# The whole gate: idioms, unit specs, then the corpus end to end.
gate: idioms test corpus

# The differential gate: the compiled binary must say exactly what
# the evaluator says.
native-check: $(RUNTIME_OBJS)
	@./avra run $(FILE) > /tmp/avra-eval.out
	@./avra build $(FILE) > /tmp/avra-bin.path
	@$$(cat /tmp/avra-bin.path) > /tmp/avra-native.out
	@diff /tmp/avra-eval.out /tmp/avra-native.out && echo "native == eval"
