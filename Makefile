# bs2 must be invoked by absolute path: it re-invokes itself via argv[0]
# from other working directories. It links against build/runtime.o and
# build/llvm_wrapper.o but does not build them; they are copied from
# the bootstrap tree.

BOOTSTRAP := ../forge-crafting-intepreters/bootstrap
BS2       := $(abspath $(BOOTSTRAP))/build/bs2

RUNTIME_OBJS := build/runtime.o build/llvm_wrapper.o

.PHONY: test clean

test: $(RUNTIME_OBJS)
	$(BS2) test

build/%.o: $(BOOTSTRAP)/build/%.o
	@mkdir -p build
	cp $< $@

clean:
	rm -rf build
	find packages -name "*.avra-sha256" -delete
	find packages -name "*.av.ll" -delete
	rm -rf packages/*/build

check: $(RUNTIME_OBJS)
	@$(BS2) run packages/cli/src/main.av -- check $(FILE)

run: $(RUNTIME_OBJS)
	@$(BS2) run packages/cli/src/main.av -- run $(FILE)
