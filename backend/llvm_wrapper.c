// The compiler's LLVM binding — pure C over LLVM's C API, OURS:
// llvm_api.av declares against exactly these symbols, and new
// builders are added HERE, never hunted for elsewhere. Targets the
// LLVM 21 C API. (Origin: the bootstrap tree's wrapper, adopted
// whole; it serves the backend through self-host and beyond.)

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

// All functions use the avra_llvm_* naming convention matching
// the extern fn declarations in src/core/llvm.fg.

// ── Context / Module / Builder ──

LLVMContextRef avra_llvm_context_create(void) {
    return LLVMContextCreate();
}

void avra_llvm_context_dispose(LLVMContextRef ctx) {
    LLVMContextDispose(ctx);
}

LLVMModuleRef avra_llvm_module_create(const char* name, LLVMContextRef ctx) {
    return LLVMModuleCreateWithNameInContext(name, ctx);
}

void avra_llvm_module_dispose(LLVMModuleRef m) {
    LLVMDisposeModule(m);
}

LLVMBuilderRef avra_llvm_create_builder(LLVMContextRef ctx) {
    return LLVMCreateBuilderInContext(ctx);
}

void avra_llvm_dispose_builder(LLVMBuilderRef b) {
    LLVMDisposeBuilder(b);
}

// ── Types ──

LLVMTypeRef avra_llvm_int1_type(LLVMContextRef ctx) {
    return LLVMInt1TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_int8_type(LLVMContextRef ctx) {
    return LLVMInt8TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_int16_type(LLVMContextRef ctx) {
    return LLVMInt16TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_int32_type(LLVMContextRef ctx) {
    return LLVMInt32TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_int64_type(LLVMContextRef ctx) {
    return LLVMInt64TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_double_type(LLVMContextRef ctx) {
    return LLVMDoubleTypeInContext(ctx);
}

LLVMTypeRef avra_llvm_void_type(LLVMContextRef ctx) {
    return LLVMVoidTypeInContext(ctx);
}

LLVMTypeRef avra_llvm_pointer_type(LLVMContextRef ctx) {
    return LLVMPointerTypeInContext(ctx, 0);
}

LLVMValueRef avra_llvm_const_null(LLVMTypeRef ty) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_const_null: ty is NULL\n");
        abort();
    }
    return LLVMConstNull(ty);
}

LLVMTypeRef avra_llvm_function_type(LLVMTypeRef ret, LLVMTypeRef* params, int param_count, int is_vararg) {
    return LLVMFunctionType(ret, params, (unsigned)param_count, is_vararg);
}

LLVMTypeRef avra_llvm_struct_create_named(LLVMContextRef ctx, const char* name) {
    return LLVMStructCreateNamed(ctx, name);
}

LLVMTypeRef avra_llvm_struct_set_body(LLVMTypeRef st, LLVMTypeRef* elems, int count, int packed) {
    if (!st) {
        fprintf(stderr, "[CRASH] avra_llvm_struct_set_body: st is NULL\n");
        abort();
    }
    for (int i = 0; i < count; i++) {
        if (!elems[i]) {
            fprintf(stderr, "[CRASH] avra_llvm_struct_set_body: elems[%d] is NULL (struct=%s)\n",
                    i, LLVMGetStructName(st));
            abort();
        }
    }
    LLVMStructSetBody(st, elems, (unsigned)count, packed);
    return st;
}

LLVMTypeRef avra_llvm_get_type_by_name(LLVMContextRef ctx, const char* name) {
    return LLVMGetTypeByName2(ctx, name);
}

// ── Type/Value arrays (heap-allocated) ──

LLVMTypeRef* avra_llvm_type_array_new(int count) {
    if (count <= 0) return (LLVMTypeRef*)calloc(1, sizeof(LLVMTypeRef));
    return (LLVMTypeRef*)calloc(count, sizeof(LLVMTypeRef));
}

void avra_llvm_type_array_set(LLVMTypeRef* arr, int idx, LLVMTypeRef ty) {
    arr[idx] = ty;
}

void avra_llvm_type_array_free(LLVMTypeRef* arr) {
    free(arr);
}

LLVMValueRef* avra_llvm_value_array_new(int count) {
    if (count <= 0) return (LLVMValueRef*)calloc(1, sizeof(LLVMValueRef));
    return (LLVMValueRef*)calloc(count, sizeof(LLVMValueRef));
}

void avra_llvm_value_array_set(LLVMValueRef* arr, int idx, LLVMValueRef val) {
    arr[idx] = val;
}

LLVMValueRef avra_llvm_value_array_get(LLVMValueRef* arr, int idx) {
    return arr[idx];
}

void avra_llvm_value_array_free(LLVMValueRef* arr) {
    free(arr);
}

// ── Constants ──

LLVMValueRef avra_llvm_const_int(LLVMTypeRef ty, int64_t value, int sign_extend) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_const_int: ty is NULL (value=%lld)\n", value);
        abort();
    }
    // Safety: the bootstrap sometimes passes null or non-integer types.
    // Default to i64 (matching the everything-is-i64 model).
    if (!ty || LLVMGetTypeKind(ty) != LLVMIntegerTypeKind) {
        // Can't get context from a null type; use a global fallback.
        // This only happens in edge cases where the bootstrap's type
        // tracking loses the correct LLVM type.
        ty = LLVMInt64Type();
    }
    return LLVMConstInt(ty, (unsigned long long)value, sign_extend);
}

// ── Functions ──

// Mangle a logical Avra symbol name into a valid object-file symbol.
// Logical names carry module qualifiers (`@pkg::mod::Type__method`) and
// generic instantiations (`Foo<int, Bar>`), so they contain '@', ':',
// '<', '>', ',', spaces, etc. GNU ld in particular reads a leading '@'
// as the ELF symbol-version separator and rejects the whole object
// ("multiple definition of `no symbol'"). Map every byte outside
// [A-Za-z0-9_] to a "$HH" hex escape. The escape is unambiguous (source
// identifiers never contain '$', so '$' in the output always introduces
// an escape), so distinct logical names can never collide. The result
// uses only '$', hex digits and identifier chars — accepted unquoted by
// LLVM IR and as symbols by ELF, Mach-O, GNU ld and LLD alike (Swift
// likewise prefixes its Mach-O symbols with '$'). Pure-identifier names
// — every C runtime symbol, `main`, `__bs_top_level` — pass through
// unchanged. Returns a malloc'd string the caller must free.
//
// This is THE single boundary between the compiler's logical name space
// and the linker's: every symbol definition (avra_llvm_add_function /
// _add_global) and every reference (avra_llvm_get_named_function) routes
// through it, so definitions and references always agree.
static char* avra_mangle_symbol(const char* name) {
    if (!name) return NULL;
    static const char hex[] = "0123456789ABCDEF";
    size_t n = strlen(name);
    char* out = (char*)malloc(n * 3 + 1); // worst case: every byte → "$HH"
    size_t j = 0;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)name[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') {
            out[j++] = (char)c;
        } else {
            out[j++] = '$';
            out[j++] = hex[(c >> 4) & 0xF];
            out[j++] = hex[c & 0xF];
        }
    }
    out[j] = '\0';
    return out;
}

LLVMValueRef avra_llvm_add_function(LLVMModuleRef m, const char* name, LLVMTypeRef fn_type) {
    if (!fn_type) {
        fprintf(stderr, "[CRASH] avra_llvm_add_function: fn_type is NULL (name=%s)\n", name);
        abort();
    }
    char* sym = avra_mangle_symbol(name);
    // Get-or-create. Raw LLVMAddFunction silently RENAMES on collision
    // (`name.1`), so a forward declaration (extern fn) followed by the
    // definition would split into two symbols — calls bind the empty
    // declaration and the body lands in an orphan. That's a silent
    // failure; the declare-then-define pattern (e.g. the test
    // assembler's `extern fn __init_<mod>` + the module's emitted
    // init) is legitimate and must converge on ONE function.
    LLVMValueRef existing = LLVMGetNamedFunction(m, sym ? sym : name);
    if (existing) {
        LLVMTypeRef existing_ty = LLVMGlobalGetValueType(existing);
        if (existing_ty != fn_type) {
            // Bootstrap tolerance: when the EXISTING function is a
            // pure declaration (no body), the mismatch is declaration-vs-
            // declaration drift — in practice the stage binary's baked
            // predeclare table vs the (newer) source's extern decl, since
            // source-vs-source conflicts are rejected upstream by typeck
            // (F3105) before codegen runs. Under opaque pointers this ABI
            // drift is benign (proven 2026-06-11); aborting here is what
            // forced manual IR surgery during seed merges. Warn and let the
            // SOURCE's signature win: build the new declaration, repoint
            // existing uses at it (functions are ptr-typed values, so RAUW
            // is type-legal; already-emitted calls keep their own call-site
            // fn types), drop the stale declaration, take over the name.
            //
            // A mismatch where the existing function HAS a body stays
            // fatal: that's the declare-then-define pattern diverging,
            // which is a genuine compiler bug. AVRA_STRICT_EXTERN_GUARD=1
            // restores the abort for declaration drift too (forensics).
            static int strict_guard = -1;
            if (strict_guard < 0) {
                const char* env = getenv("AVRA_STRICT_EXTERN_GUARD");
                strict_guard = (env && env[0] == '1') ? 1 : 0;
            }
            int has_body = LLVMCountBasicBlocks(existing) > 0;
            if (!has_body && !strict_guard) {
                char* have = LLVMPrintTypeToString(existing_ty);
                char* want = LLVMPrintTypeToString(fn_type);
                fprintf(stderr,
                    "[warn] avra_llvm_add_function: `%s` redeclared with a different type — "
                    "tolerating declaration drift (stale predeclare vs source extern; "
                    "expected while a previous-generation seed compiles newer source)\n"
                    "       stale:  %s\n"
                    "       source: %s\n",
                    name, have ? have : "?", want ? want : "?");
                LLVMDisposeMessage(have);
                LLVMDisposeMessage(want);
                LLVMValueRef neu = LLVMAddFunction(m, "__avra_redecl_staging", fn_type);
                LLVMReplaceAllUsesWith(existing, neu);
                LLVMDeleteFunction(existing);
                LLVMSetValueName2(neu, sym ? sym : name, strlen(sym ? sym : name));
                free(sym);
                return neu;
            }
            char* have = LLVMPrintTypeToString(existing_ty);
            char* want = LLVMPrintTypeToString(fn_type);
            fprintf(stderr,
                "[CRASH] avra_llvm_add_function: `%s` redeclared with a different type\n"
                "        existing%s: %s\n"
                "        new:      %s\n",
                name, has_body ? " (defined)" : "", have ? have : "?", want ? want : "?");
            LLVMDisposeMessage(have);
            LLVMDisposeMessage(want);
            abort();
        }
        free(sym);
        return existing;
    }
    LLVMValueRef fn = LLVMAddFunction(m, sym ? sym : name, fn_type);
    free(sym);
    return fn;
}

LLVMValueRef avra_llvm_get_named_function(LLVMModuleRef m, const char* name) {
    char* sym = avra_mangle_symbol(name);
    LLVMValueRef fn = LLVMGetNamedFunction(m, sym ? sym : name);
    free(sym);
    return fn;
}

LLVMValueRef avra_llvm_get_param(LLVMValueRef f, int index) {
    return LLVMGetParam(f, (unsigned)index);
}

int64_t avra_llvm_count_params(LLVMValueRef f) {
    if (!f) {
        fprintf(stderr, "[CRASH] avra_llvm_count_params: fn is NULL\n");
        abort();
    }
    return (int64_t)LLVMCountParams(f);
}

LLVMTypeRef avra_llvm_fn_type_of(LLVMValueRef fn_val) {
    if (!fn_val) {
        fprintf(stderr, "[CRASH] avra_llvm_fn_type_of: fn_val is NULL\n");
        abort();
    }
    return LLVMGlobalGetValueType(fn_val);
}

// ── Globals ──

LLVMValueRef avra_llvm_add_global(LLVMModuleRef m, LLVMTypeRef ty, const char* name) {
    char* sym = avra_mangle_symbol(name);
    LLVMValueRef g = LLVMAddGlobal(m, ty, sym ? sym : name);
    free(sym);
    return g;
}

void avra_llvm_set_initializer(LLVMValueRef g, LLVMValueRef val) {
    LLVMSetInitializer(g, val);
}

// Mark a fn / global as linkonce_odr — the linker dedupes
// multiple definitions of the same symbol across translation
// units, keeping a single copy. Required by library-mode for
// auto-generated helpers (per-monomorphization __release_<T>,
// __init_<mod>, public consts) so a shard's .o + producer's .o
// don't fight over them at link time.
void avra_llvm_set_linkonce_odr(LLVMValueRef v) {
    if (v) LLVMSetLinkage(v, LLVMLinkOnceODRLinkage);
}

// ── Basic blocks ──

LLVMBasicBlockRef avra_llvm_append_basic_block(LLVMContextRef ctx, LLVMValueRef fn_val, const char* name) {
    return LLVMAppendBasicBlockInContext(ctx, fn_val, name);
}

void avra_llvm_position_at_end(LLVMBuilderRef b, LLVMBasicBlockRef bb) {
    LLVMPositionBuilderAtEnd(b, bb);
}

int avra_llvm_block_has_terminator(LLVMBuilderRef b) {
    LLVMBasicBlockRef bb = LLVMGetInsertBlock(b);
    if (!bb) return 0;
    return LLVMGetBasicBlockTerminator(bb) != NULL ? 1 : 0;
}

LLVMBasicBlockRef avra_llvm_get_insert_block(LLVMBuilderRef b) {
    return LLVMGetInsertBlock(b);
}

// ── Integer arithmetic ──

LLVMValueRef avra_llvm_build_add(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildAdd(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_sub(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildSub(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_mul(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildMul(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_sdiv(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildSDiv(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_srem(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildSRem(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_udiv(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildUDiv(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_urem(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildURem(b, lhs, rhs, name);
}

// ── Bitwise ──

LLVMValueRef avra_llvm_build_and(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildAnd(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_or(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildOr(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_xor(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildXor(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_shl(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildShl(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_lshr(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildLShr(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_ashr(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildAShr(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_not(LLVMBuilderRef b, LLVMValueRef val, const char* name) {
    return LLVMBuildNot(b, val, name);
}

// ── Comparison ──

LLVMValueRef avra_llvm_build_icmp(LLVMBuilderRef b, int pred, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildICmp(b, (LLVMIntPredicate)pred, lhs, rhs, name);
}

// ── Float arithmetic ──

LLVMValueRef avra_llvm_build_fadd(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildFAdd(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_fsub(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildFSub(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_fmul(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildFMul(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_fdiv(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildFDiv(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_frem(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildFRem(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_fneg(LLVMBuilderRef b, LLVMValueRef val, const char* name) {
    return LLVMBuildFNeg(b, val, name);
}

LLVMValueRef avra_llvm_build_fcmp(LLVMBuilderRef b, int pred, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildFCmp(b, (LLVMRealPredicate)pred, lhs, rhs, name);
}

// ── Casts ──

LLVMValueRef avra_llvm_build_zext(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildZExt(b, val, dest_ty, name);
}

LLVMValueRef avra_llvm_build_sext(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildSExt(b, val, dest_ty, name);
}

// Validate name: if it doesn't start with a letter or underscore, it's a
// corrupted pointer value being used as a name. Use a deterministic fallback.
static const char* safe_name(const char* name, const char* fallback) {
    if (!name) return fallback;
    char c = name[0];
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '.') return name;
    return fallback;
}

LLVMValueRef avra_llvm_build_ptr_to_int(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildPtrToInt(b, val, dest_ty, safe_name(name, "p2i"));
}

LLVMValueRef avra_llvm_build_int_to_ptr(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildIntToPtr(b, val, dest_ty, safe_name(name, "i2p"));
}

LLVMValueRef avra_llvm_build_si_to_fp(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildSIToFP(b, val, dest_ty, name);
}

LLVMValueRef avra_llvm_build_fp_to_si(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildFPToSI(b, val, dest_ty, name);
}

LLVMValueRef avra_llvm_build_bitcast(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildBitCast(b, val, dest_ty, name);
}

// ── Memory ──

LLVMValueRef avra_llvm_build_alloca(LLVMBuilderRef b, LLVMTypeRef ty, const char* name) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_build_alloca: ty is NULL (name=%s)\n", name);
        abort();
    }
    // Always place allocas in the entry block for correctness.
    LLVMBasicBlockRef current_bb = LLVMGetInsertBlock(b);
    LLVMValueRef fn = LLVMGetBasicBlockParent(current_bb);
    LLVMBasicBlockRef entry = LLVMGetEntryBasicBlock(fn);
    LLVMValueRef first_inst = LLVMGetFirstInstruction(entry);

    LLVMBuilderRef entry_builder = LLVMCreateBuilder();
    if (first_inst) {
        LLVMPositionBuilderBefore(entry_builder, first_inst);
    } else {
        LLVMPositionBuilderAtEnd(entry_builder, entry);
    }
    LLVMValueRef alloca = LLVMBuildAlloca(entry_builder, ty, name);
    // Zero-init every pointer-typed local at creation (zm77 + merge
    // follow-up). The declaration-site store may sit in a loop or
    // conditional block that never executes at runtime; any later read
    // of the slot (scope-exit RC cleanup, a binding consumed on a path
    // that skipped its init) would otherwise see stack garbage — which
    // surfaced as phantom releases freeing live AST nodes and as
    // garbage pointers stored into AST fields (layout-sensitive
    // "unmatched tag" crashes). The store lands immediately after the
    // alloca at the top of the entry block, provably before every
    // value store on every path. Definite-initialization analysis
    // (rcsf.5) is the long-term replacement for this blanket guard.
    if (LLVMGetTypeKind(ty) == LLVMPointerTypeKind) {
        LLVMBuildStore(entry_builder, LLVMConstNull(ty), alloca);
    }
    LLVMDisposeBuilder(entry_builder);
    return alloca;
}

// rcsf.2: machine-check the zero-init invariant on the finished module.
// Every pointer-typed alloca's NEXT instruction must be a `store ptr
// null` into it (all allocas route through avra_llvm_build_alloca,
// which emits exactly that pair). If a future refactor bypasses the
// guard, this catches it at compile time instead of as a
// layout-sensitive use-of-garbage crash (zm77 class). Gated by
// AVRA_VERIFY_RC=1 at the call site (codegen_program tail).
// Returns the number of violations; prints each to stderr.
int64_t avra_llvm_verify_rc_init(LLVMModuleRef m) {
    int64_t checked = 0, bad = 0;
    for (LLVMValueRef fn = LLVMGetFirstFunction(m); fn; fn = LLVMGetNextFunction(fn)) {
        for (LLVMBasicBlockRef bb = LLVMGetFirstBasicBlock(fn); bb; bb = LLVMGetNextBasicBlock(bb)) {
            for (LLVMValueRef in = LLVMGetFirstInstruction(bb); in; in = LLVMGetNextInstruction(in)) {
                if (!LLVMIsAAllocaInst(in)) continue;
                if (LLVMGetTypeKind(LLVMGetAllocatedType(in)) != LLVMPointerTypeKind) continue;
                checked++;
                int ok = 0;
                LLVMValueRef next = LLVMGetNextInstruction(in);
                if (next && LLVMIsAStoreInst(next)
                    && LLVMGetOperand(next, 1) == in) {
                    LLVMValueRef val = LLVMGetOperand(next, 0);
                    if (LLVMIsConstant(val) && LLVMIsNull(val)) ok = 1;
                }
                if (!ok) {
                    size_t fl, al;
                    const char* fname = LLVMGetValueName2(fn, &fl);
                    const char* aname = LLVMGetValueName2(in, &al);
                    fprintf(stderr, "[verify-rc] VIOLATION: fn %.*s — alloca %%%.*s lacks an immediate null store\n",
                            (int)fl, fname, (int)al, aname);
                    bad++;
                }
            }
        }
    }
    fprintf(stderr, "[verify-rc] %s — %lld ptr alloca(s) checked, %lld violation(s)\n",
            bad ? "FAIL" : "ok", (long long)checked, (long long)bad);
    return bad;
}

LLVMValueRef avra_llvm_build_load(LLVMBuilderRef b, LLVMTypeRef ty, LLVMValueRef ptr_val, const char* name) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_build_load: ty is NULL (name=%s)\n", name);
        abort();
    }
    LLVMValueRef load = LLVMBuildLoad2(b, ty, ptr_val, name);
    // Force align 8 for i64 loads to avoid optimizer miscompiles.
    LLVMSetAlignment(load, 8);
    return load;
}

// Emit a CALL to avra_track_store_i64/ptr that logs and performs the store.
// Falls back to raw store if the tracking function isn't available.
static LLVMValueRef tracked_store_or_raw(LLVMBuilderRef b, LLVMValueRef val, LLVMValueRef ptr_val) {
    if (!getenv("FORGE_TRACK_STORES")) {
        LLVMValueRef store = LLVMBuildStore(b, val, ptr_val);
        LLVMSetAlignment(store, 8);
        return store;
    }
    LLVMBasicBlockRef bb = LLVMGetInsertBlock(b);
    LLVMValueRef fn = LLVMGetBasicBlockParent(bb);
    LLVMModuleRef mod = LLVMGetGlobalParent(fn);
    LLVMContextRef lc = LLVMGetModuleContext(mod);
    LLVMTypeRef i64t = LLVMInt64TypeInContext(lc);
    LLVMTypeRef pt = LLVMPointerTypeInContext(lc, 0);
    LLVMTypeRef val_ty = LLVMTypeOf(val);
    LLVMTypeKind kind = LLVMGetTypeKind(val_ty);
    const char* fn_name;
    LLVMTypeRef arg1_ty;
    if (kind == LLVMPointerTypeKind) {
        fn_name = "avra_track_store_ptr";
        arg1_ty = pt;
    } else if (kind == LLVMIntegerTypeKind && LLVMGetIntTypeWidth(val_ty) == 64) {
        fn_name = "avra_track_store_i64";
        arg1_ty = i64t;
    } else {
        // Types we don't track (i1, f64, etc.) — raw store
        LLVMValueRef store = LLVMBuildStore(b, val, ptr_val);
        LLVMSetAlignment(store, 8);
        return store;
    }
    LLVMValueRef tracker = LLVMGetNamedFunction(mod, fn_name);
    if (!tracker) {
        LLVMTypeRef params[] = { pt, arg1_ty };
        LLVMTypeRef ft = LLVMFunctionType(LLVMVoidTypeInContext(lc), params, 2, 0);
        tracker = LLVMAddFunction(mod, fn_name, ft);
    }
    LLVMTypeRef params[] = { pt, arg1_ty };
    LLVMTypeRef ft = LLVMFunctionType(LLVMVoidTypeInContext(lc), params, 2, 0);
    LLVMValueRef args[] = { ptr_val, val };
    LLVMBuildCall2(b, ft, tracker, args, 2, "");
    return NULL;
}

LLVMValueRef avra_llvm_build_store(LLVMBuilderRef b, LLVMValueRef val, LLVMValueRef ptr_val) {
    LLVMValueRef r = tracked_store_or_raw(b, val, ptr_val);
    return r;
}

LLVMValueRef avra_llvm_build_struct_gep2(LLVMBuilderRef b, LLVMTypeRef ty, LLVMValueRef ptr_val, int idx, const char* name) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_build_struct_gep2: ty is NULL (idx=%d, name=%s)\n", idx, name);
        abort();
    }
    return LLVMBuildStructGEP2(b, ty, ptr_val, (unsigned)idx, name);
}

LLVMValueRef avra_llvm_build_global_string_ptr(LLVMBuilderRef b, const char* s, const char* name) {
    return LLVMBuildGlobalStringPtr(b, s, name);
}

// ── Calls ──

LLVMValueRef avra_llvm_build_call(LLVMBuilderRef b, LLVMTypeRef fn_type, LLVMValueRef fn_val, LLVMValueRef* args, int count, const char* name) {
    if (!fn_type) {
        fprintf(stderr, "[CRASH] avra_llvm_build_call: fn_type is NULL (name=%s)\n", name ? name : "(null)");
        abort();
    }
    LLVMTypeRef ret_type = LLVMGetReturnType(fn_type);
    int is_void = (LLVMGetTypeKind(ret_type) == LLVMVoidTypeKind);
    const char* call_name = is_void ? "" : (name ? name : "");
    LLVMValueRef result = LLVMBuildCall2(b, fn_type, fn_val, args, (unsigned)count, call_name);
    if (is_void) {
        LLVMContextRef ctx = LLVMGetModuleContext(LLVMGetGlobalParent(fn_val));
        return LLVMConstInt(LLVMInt64TypeInContext(ctx), 0, 0);
    }
    return result;
}

// ── Control flow ──

LLVMValueRef avra_llvm_build_br(LLVMBuilderRef b, LLVMBasicBlockRef bb) {
    return LLVMBuildBr(b, bb);
}

LLVMValueRef avra_llvm_build_cond_br(LLVMBuilderRef b, LLVMValueRef cond, LLVMBasicBlockRef then_bb, LLVMBasicBlockRef else_bb) {
    return LLVMBuildCondBr(b, cond, then_bb, else_bb);
}

LLVMValueRef avra_llvm_build_ret(LLVMBuilderRef b, LLVMValueRef val) {
    return LLVMBuildRet(b, val);
}

LLVMValueRef avra_llvm_build_unreachable(LLVMBuilderRef b) {
    return LLVMBuildUnreachable(b);
}

// ── PHI nodes ──

LLVMValueRef avra_llvm_build_phi(LLVMBuilderRef b, LLVMTypeRef ty, const char* name) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_build_phi: ty is NULL (name=%s)\n", name);
        abort();
    }
    return LLVMBuildPhi(b, ty, name);
}

void avra_llvm_add_incoming(LLVMValueRef phi, LLVMValueRef value, LLVMBasicBlockRef block) {
    LLVMValueRef vals[1] = { value };
    LLVMBasicBlockRef blocks[1] = { block };
    LLVMAddIncoming(phi, vals, blocks, 1);
}

// ── Module output ──

// pdme.7: emit ATOMICALLY (print to a pid-scoped temp, then rename).
// LLVMPrintModuleToFile truncates the destination in place and streams
// the IR out over milliseconds; a concurrent reader of the same .ll —
// exactly the shard/pre-build contention shape, where several bs2
// processes compile one entry — caught it at 0/partial bytes (found by
// --cache-fuzz-parallel). rename() gives readers whole-old or
// whole-new, never mid-stream.
int avra_llvm_print_module_to_file(LLVMModuleRef m, const char* path) {
    char tmp[4096];
    if (snprintf(tmp, sizeof(tmp), "%s.tmp.%d", path, (int)getpid())
            >= (int)sizeof(tmp)) {
        return 1;
    }
    char* error = NULL;
    int result = LLVMPrintModuleToFile(m, tmp, &error);
    if (error) {
        fprintf(stderr, "LLVM error: %s\n", error);
        LLVMDisposeMessage(error);
    }
    if (result != 0) {
        remove(tmp);
        return result;
    }
    if (rename(tmp, path) != 0) {
        remove(tmp);
        return 1;
    }
    return 0;
}

// Per-function IR extraction. Print ONE function's textual IR
// to `path`, atomically (pid-scoped temp + rename — same discipline as
// avra_llvm_print_module_to_file above, same reason: a concurrent reader
// must see whole-old or whole-new, never mid-stream). Text IR is the v1
// per-fn cache artifact; bitcode slots in behind the same seam later.
// Returns 1 on success, 0 on failure (runtime wrapper convention).
int64_t avra_llvm_fn_print_to_file(LLVMValueRef fn, const char* path) {
    if (!fn || !path) return 0;
    char* ir = LLVMPrintValueToString(fn);
    if (!ir) return 0;
    char tmp[4096];
    if (snprintf(tmp, sizeof(tmp), "%s.tmp.%d", path, (int)getpid())
            >= (int)sizeof(tmp)) {
        LLVMDisposeMessage(ir);
        return 0;
    }
    FILE* f = fopen(tmp, "w");
    if (!f) {
        LLVMDisposeMessage(ir);
        return 0;
    }
    size_t len = strlen(ir);
    size_t wrote = fwrite(ir, 1, len, f);
    int close_err = fclose(f);
    LLVMDisposeMessage(ir);
    if (wrote != len || close_err != 0) {
        remove(tmp);
        return 0;
    }
    if (rename(tmp, path) != 0) {
        remove(tmp);
        return 0;
    }
    return 1;
}

// Record separator between per-function units in the packed string that
// avra_llvm_module_split_defines returns. \x1e (ASCII RS) never occurs in
// LLVM's printable-ASCII textual IR, so splitting on it is unambiguous.
const char* avra_llvm_unit_sep(void) { return "\x1e"; }

// The raw (unescaped) name of an LLVM value — the SAME string
// avra_llvm_module_split_defines emits per block. The Avra caller keys its
// cache-key map by this so blocks match regardless of how codegen mangled
// the source name. Heap copy (Avra copies at the FFI boundary).
const char* avra_llvm_value_name(LLVMValueRef v) {
    if (!v) return "";
    size_t len = 0;
    const char* name = LLVMGetValueName2(v, &len);
    if (!name || len == 0) return "";
    char* copy = (char*)malloc(len + 1);
    if (!copy) return "";
    memcpy(copy, name, len);
    copy[len] = '\0';
    return copy;
}

// Hex nibble for LLVM's `\XX` quoted-name escapes; -1 if not a hex digit.
static int avra_hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

// Whole-module per-function IR extraction — the O(n) replacement for
// calling LLVMPrintValueToString once per function (which is O(module)
// EACH, because it rebuilds a module SlotTracker per call: ~3.8k fns ×
// O(module) = quadratic, ~80s on @std/avrac). Here the module is printed
// ONCE (one SlotTracker), then split into `define … }` blocks.
//
// Returns the defined functions as `name\n<function-ir>\x1e` records
// (record sep = \x1e; name/ir split at the first \n). Each block SELF-
// IDENTIFIES: its name is parsed from its own `define … @<name>(` line —
// the first `@` after "define " (return type / linkage / attrs carry no
// `@`), unescaped from LLVM's `@"…"` quoting (`\XX` -> byte). No reliance
// on print-order matching any external iteration order, so a parse miss
// yields a cache MISS (recompute), never a mis-keyed unit. The name equals
// LLVMGetValueName2, which the Avra caller keys its cache map by.
//
// v1 handles textual IR; a bitcode artifact slots in behind the same seam.
const char* avra_llvm_module_split_defines(LLVMModuleRef m) {
    if (!m) return "";
    char* ir = LLVMPrintModuleToString(m);
    if (!ir) return "";
    size_t n = strlen(ir);
    size_t cap = n + 65536, outlen = 0;
    char* out = (char*)malloc(cap);
    if (!out) { LLVMDisposeMessage(ir); return ""; }

    size_t i = 0;
    while (i < n) {
        int at_line_start = (i == 0) || (ir[i - 1] == '\n');
        if (at_line_start && strncmp(ir + i, "define ", 7) == 0) {
            size_t start = i;
            // Block ends at a line that is exactly "}" (then \n or EOF).
            size_t j = i, end = 0;
            while (j < n) {
                if (ir[j] == '\n' && ir[j + 1] == '}' &&
                    (j + 2 >= n || ir[j + 2] == '\n')) {
                    end = j + 2;   // include the closing brace
                    break;
                }
                j++;
            }
            if (end == 0) break;   // malformed — stop rather than emit garbage

            // Parse the function name from the `define` line (first '@').
            char namebuf[8192];
            size_t nl = 0;
            size_t p = start + 7;
            while (p < end && ir[p] != '@' && ir[p] != '\n') p++;
            if (p < end && ir[p] == '@') {
                p++;
                if (p < end && ir[p] == '"') {              // quoted name
                    p++;
                    while (p < end && ir[p] != '"' && nl < sizeof(namebuf) - 1) {
                        int h1, h2;
                        if (ir[p] == '\\' && p + 2 < end &&
                            (h1 = avra_hexval(ir[p + 1])) >= 0 &&
                            (h2 = avra_hexval(ir[p + 2])) >= 0) {
                            namebuf[nl++] = (char)((h1 << 4) | h2);
                            p += 3;
                        } else {
                            namebuf[nl++] = ir[p++];
                        }
                    }
                } else {                                     // bareword name
                    while (p < end && ir[p] != '(' && ir[p] != ' ' &&
                           nl < sizeof(namebuf) - 1) {
                        namebuf[nl++] = ir[p++];
                    }
                }
            }

            size_t blocklen = end - start;
            size_t need = outlen + nl + 1 + blocklen + 1;
            if (need > cap) {
                while (need > cap) cap *= 2;
                char* grown = (char*)realloc(out, cap);
                if (!grown) { free(out); LLVMDisposeMessage(ir); return ""; }
                out = grown;
            }
            memcpy(out + outlen, namebuf, nl); outlen += nl;
            out[outlen++] = '\n';
            memcpy(out + outlen, ir + start, blocklen); outlen += blocklen;
            out[outlen++] = '\x1e';
            i = end;
        } else {
            i++;
        }
    }
    out[outlen] = '\0';
    LLVMDisposeMessage(ir);
    return out;
}

int avra_llvm_verify_module_print(LLVMModuleRef m) {
    char* error = NULL;
    int result = LLVMVerifyModule(m, LLVMPrintMessageAction, &error);
    if (error) LLVMDisposeMessage(error);
    return result;
}

// Verify a single function. Returns 0 if valid, 1 if invalid.
// Prints the error to stderr with the function name for easy debugging.
int64_t avra_llvm_verify_function(LLVMValueRef fn_val) {
    int result = LLVMVerifyFunction(fn_val, LLVMPrintMessageAction);
    if (result) {
        const char* name = LLVMGetValueName(fn_val);
        fprintf(stderr, "FATAL: LLVM verification failed for function `%s`\n", name ? name : "<unknown>");
    }
    return result;
}

// ── Type introspection ──

// Returns 1 if the LLVM value's type is a pointer type, 0 otherwise.
// Used by the codegen to avoid redundant ptrtoint/inttoptr casts.
int64_t avra_llvm_is_ptr_value(LLVMValueRef val) {
    return LLVMGetTypeKind(LLVMTypeOf(val)) == LLVMPointerTypeKind ? 1 : 0;
}

// Returns the LLVM type of a value (LLVMTypeOf wrapper).
LLVMTypeRef avra_llvm_typeof(LLVMValueRef val) {
    return LLVMTypeOf(val);
}

// Returns 1 if the LLVM value has void type, 0 otherwise.
int64_t avra_llvm_is_void_value(LLVMValueRef val) {
    if (!val) return 1;
    return LLVMGetTypeKind(LLVMTypeOf(val)) == LLVMVoidTypeKind ? 1 : 0;
}

// Cast a value to match an expected type. Handles all combinations:
//   ptr ↔ integer: ptrtoint / inttoptr
//   integer ↔ integer (different widths): zext / trunc
//   double ↔ i64: bitcast (bit reinterpretation)
//   smaller int → double: sitofp
//   double → smaller int: fptosi
// Returns val unchanged if types already match.
LLVMValueRef avra_llvm_cast_to_type(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef expected) {
    LLVMTypeRef actual = LLVMTypeOf(val);
    if (actual == expected) return val;
    LLVMTypeKind ak = LLVMGetTypeKind(actual);
    LLVMTypeKind ek = LLVMGetTypeKind(expected);

    // ptr → integer
    if (ak == LLVMPointerTypeKind && ek == LLVMIntegerTypeKind)
        return LLVMBuildPtrToInt(b, val, expected, "cast");
    // integer → ptr
    if (ak == LLVMIntegerTypeKind && ek == LLVMPointerTypeKind)
        return LLVMBuildIntToPtr(b, val, expected, "cast");
    // integer → integer (i1↔i64, i32↔i64, etc.)
    if (ak == LLVMIntegerTypeKind && ek == LLVMIntegerTypeKind) {
        unsigned aw = LLVMGetIntTypeWidth(actual);
        unsigned ew = LLVMGetIntTypeWidth(expected);
        if (aw < ew) return LLVMBuildZExt(b, val, expected, "cast");
        if (aw > ew) return LLVMBuildTrunc(b, val, expected, "cast");
        return val;
    }
    // double ↔ i64: bitcast (preserves bits)
    if (ak == LLVMDoubleTypeKind && ek == LLVMIntegerTypeKind) {
        unsigned ew = LLVMGetIntTypeWidth(expected);
        if (ew == 64) return LLVMBuildBitCast(b, val, expected, "cast");
        return LLVMBuildFPToSI(b, val, expected, "cast");
    }
    if (ak == LLVMIntegerTypeKind && ek == LLVMDoubleTypeKind) {
        unsigned aw = LLVMGetIntTypeWidth(actual);
        if (aw == 64) return LLVMBuildBitCast(b, val, expected, "cast");
        return LLVMBuildSIToFP(b, val, expected, "cast");
    }
    // ptr ↔ double: chain through i64
    if (ak == LLVMPointerTypeKind && ek == LLVMDoubleTypeKind) {
        LLVMContextRef ctx = LLVMGetTypeContext(expected);
        LLVMValueRef i = LLVMBuildPtrToInt(b, val, LLVMInt64TypeInContext(ctx), "cast");
        return LLVMBuildBitCast(b, i, expected, "cast");
    }
    if (ak == LLVMDoubleTypeKind && ek == LLVMPointerTypeKind) {
        LLVMContextRef ctx = LLVMGetTypeContext(actual);
        LLVMValueRef i = LLVMBuildBitCast(b, val, LLVMInt64TypeInContext(ctx), "cast");
        return LLVMBuildIntToPtr(b, i, expected, "cast");
    }
    return val;
}

// Type-safe store for alloca destinations: casts the value to match
// the alloca's allocated type. For non-alloca destinations (GEPs),
// performs a raw store — the caller MUST use store_field with an
// explicit type for struct field stores.
void avra_llvm_build_store_cast(LLVMBuilderRef b, LLVMValueRef val, LLVMValueRef dest) {
    // LLVMGetAllocatedType is only defined for alloca instructions; on a
    // non-alloca dest (e.g. a GEP) it reinterprets the value as an
    // AllocaInst and returns a garbage type pointer rather than null, so
    // the `if (dest_ty)` guard alone is unsound (it crashed LLVMGetTypeKind
    // on Linux; macOS happened to return something benign). Gate on a real
    // isa<AllocaInst> check and fall through to a raw store otherwise —
    // matching this function's documented contract.
    LLVMValueRef dest_alloca = LLVMIsAAllocaInst(dest);
    if (dest_alloca) {
        LLVMTypeRef dest_ty = LLVMGetAllocatedType(dest_alloca);
        if (dest_ty) {
            val = avra_llvm_cast_to_type(b, val, dest_ty);
        }
    }
    tracked_store_or_raw(b, val, dest);
}

// Type introspection helpers for the Avra codegen.
int64_t avra_llvm_type_kind(LLVMTypeRef ty) {
    return (int64_t)LLVMGetTypeKind(ty);
}
int64_t avra_llvm_int_type_width(LLVMTypeRef ty) {
    return (int64_t)LLVMGetIntTypeWidth(ty);
}

// Build a call with automatic argument type coercion.
// For each argument, if the value type doesn't match the function's
// expected parameter type, insert a cast (ptr↔i64).
LLVMValueRef avra_llvm_build_call_coerce(LLVMBuilderRef b,
    LLVMTypeRef fn_type, LLVMValueRef fn_val,
    LLVMValueRef* args, int64_t count, const char* name) {
    if (!fn_type) {
        fprintf(stderr, "[CRASH] avra_llvm_build_call_coerce: fn_type is NULL (name=%s)\n", name ? name : "(null)");
        abort();
    }
    unsigned param_count = LLVMCountParamTypes(fn_type);
    LLVMTypeRef* param_types = NULL;
    if (param_count > 0) {
        param_types = (LLVMTypeRef*)malloc(param_count * sizeof(LLVMTypeRef));
        LLVMGetParamTypes(fn_type, param_types);
    }
    for (int i = 0; i < count && i < (int)param_count; i++) {
        args[i] = avra_llvm_cast_to_type(b, args[i], param_types[i]);
    }
    if (param_types) free(param_types);
    // Void-returning calls must not have a name (LLVM requirement).
    LLVMTypeRef ret_type = LLVMGetReturnType(fn_type);
    int is_void = (LLVMGetTypeKind(ret_type) == LLVMVoidTypeKind);
    const char* call_name = is_void ? "" : (name ? name : "");
    LLVMValueRef result = LLVMBuildCall2(b, fn_type, fn_val, args, (unsigned)count, call_name);
    // Void values cannot be stored, returned, or used in the value pipeline.
    // Replace with i64 0 so callers don't need to handle void specially.
    if (is_void) {
        LLVMContextRef ctx = LLVMGetModuleContext(LLVMGetGlobalParent(fn_val));
        return LLVMConstInt(LLVMInt64TypeInContext(ctx), 0, 0);
    }
    // If the return type is a smaller integer (i32, i8, i1), widen to i64.
    // i1 uses zext (bool is unsigned), others use sext (C int is signed).
    if (LLVMGetTypeKind(ret_type) == LLVMIntegerTypeKind) {
        unsigned width = LLVMGetIntTypeWidth(ret_type);
        if (width < 64) {
            LLVMContextRef ctx = LLVMGetModuleContext(LLVMGetGlobalParent(fn_val));
            LLVMTypeRef i64_type = LLVMInt64TypeInContext(ctx);
            if (width == 1) return LLVMBuildZExt(b, result, i64_type, "widen");
            return LLVMBuildSExt(b, result, i64_type, "widen");
        }
    }
    return result;
}

// ── Coverage instrumentation ──
// Declares @llvm.instrprof.increment and provides helpers for emitting
// coverage region counters. The LLVM InstrProfiling pass lowers these
// intrinsic calls into __profc_* counter arrays and __profd_* data records.

static int32_t coverage_region_counter = 0;
static int32_t coverage_fn_region_count = 0;

#define AVRA_INSTRPROF_INCREMENT "llvm.instrprof.increment"

// The intrinsic FOR THIS MODULE, declared on first use.
//
// This used to be a process-wide `static LLVMValueRef coverage_intrinsic`,
// guarded by `if (coverage_intrinsic) return;` and documented as "idempotent —
// safe to call multiple times". That is true WITHIN one module and false
// ACROSS modules: the static held the FIRST module's Function, so a second
// compile in the same process skipped the declaration and then built calls
// against a function belonging to a different (by then possibly disposed)
// module. The result was a SIGSEGV inside llvm::CallInst::init, surfaced as an
// F9999 that named an unrelated Avra frame (`Arena__Expr__ExprId__add`) — so
// the report pointed away from the cause.
//
// Keyed off the module instead, exactly as avra_coverage_name_global already
// does for `__profn_` globals: LLVM is the single source of truth for what
// this module contains, which is the rule a cached ref quietly broke.
static LLVMValueRef avra_coverage_intrinsic(LLVMModuleRef m) {
    LLVMValueRef existing = LLVMGetNamedFunction(m, AVRA_INSTRPROF_INCREMENT);
    if (existing) return existing;
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMTypeRef param_types[] = {
        LLVMPointerType(LLVMInt8TypeInContext(ctx), 0),
        LLVMInt64TypeInContext(ctx),
        LLVMInt32TypeInContext(ctx),
        LLVMInt32TypeInContext(ctx)
    };
    LLVMTypeRef fn_type = LLVMFunctionType(LLVMVoidTypeInContext(ctx), param_types, 4, 0);
    return LLVMAddFunction(m, AVRA_INSTRPROF_INCREMENT, fn_type);
}

// Declare @llvm.instrprof.increment(ptr, i64, i32, i32) in the module.
// Idempotent per MODULE — and now genuinely so across modules too.
void avra_coverage_declare(LLVMModuleRef m) {
    (void)avra_coverage_intrinsic(m);
}

// Create @__profn_<name> = private constant [N x i8] c"<name>"
// Returns the global value for use in instrprof.increment calls.
LLVMValueRef avra_coverage_name_global(LLVMModuleRef m, const char* fn_name) {
    // Check if already created
    char buf[512];
    snprintf(buf, sizeof(buf), "__profn_%s", fn_name);
    LLVMValueRef existing = LLVMGetNamedGlobal(m, buf);
    if (existing) return existing;

    LLVMContextRef ctx = LLVMGetModuleContext(m);
    size_t len = strlen(fn_name);
    LLVMValueRef str = LLVMConstStringInContext(ctx, fn_name, (unsigned)len, 1);
    LLVMValueRef global = LLVMAddGlobal(m, LLVMTypeOf(str), buf);
    LLVMSetInitializer(global, str);
    LLVMSetLinkage(global, LLVMPrivateLinkage);
    LLVMSetGlobalConstant(global, 1);
    return global;
}

// Emit: call void @llvm.instrprof.increment(ptr @__profn_<name>, i64 <hash>, i32 <num_counters>, i32 <idx>)
// num_counters is set to a placeholder (0) during codegen, then patched to
// the actual count by avra_coverage_finalize_fn at function end.
void avra_coverage_emit_hit(LLVMBuilderRef builder, LLVMModuleRef m,
                              const char* fn_name, int64_t fn_hash_unused,
                              int32_t num_counters_unused, int32_t counter_idx) {
    // Resolved from the module being built, not a cached ref — see
    // avra_coverage_intrinsic. Absent means coverage was never declared for
    // this module, which is the same "nothing to emit" case as before.
    LLVMValueRef intrinsic = LLVMGetNamedFunction(m, AVRA_INSTRPROF_INCREMENT);
    if (!intrinsic) return;
    // Compute unique hash from function name (djb2)
    uint64_t hash = 5381;
    for (const char* p = fn_name; *p; p++)
        hash = ((hash << 5) + hash) + (uint64_t)*p;
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMValueRef name_global = avra_coverage_name_global(m, fn_name);
    // Use 0 as placeholder for num_counters — patched by finalize_fn
    LLVMValueRef args[] = {
        name_global,
        LLVMConstInt(LLVMInt64TypeInContext(ctx), hash, 0),
        LLVMConstInt(LLVMInt32TypeInContext(ctx), 0, 0),
        LLVMConstInt(LLVMInt32TypeInContext(ctx), (uint32_t)counter_idx, 0)
    };
    LLVMTypeRef param_types[] = {
        LLVMPointerType(LLVMInt8TypeInContext(ctx), 0),
        LLVMInt64TypeInContext(ctx),
        LLVMInt32TypeInContext(ctx),
        LLVMInt32TypeInContext(ctx)
    };
    LLVMTypeRef fn_type = LLVMFunctionType(LLVMVoidTypeInContext(ctx), param_types, 4, 0);
    LLVMBuildCall2(builder, fn_type, intrinsic, args, 4, "");
}

// Patch all llvm.instrprof.increment calls in fn_val to use actual_count
// as the num_counters argument (arg index 2).
void avra_coverage_finalize_fn(LLVMValueRef fn_val, int32_t actual_count) {
    if (actual_count <= 0) return;
    // The module comes from the FUNCTION being patched, so the callee compared
    // below is this module's intrinsic. Comparing against a cached ref from an
    // earlier module matched nothing, so the num_counters operand silently kept
    // its 0 placeholder — wrong counts rather than a crash.
    LLVMModuleRef m = LLVMGetGlobalParent(fn_val);
    if (!m) return;
    LLVMValueRef intrinsic = LLVMGetNamedFunction(m, AVRA_INSTRPROF_INCREMENT);
    if (!intrinsic) return;
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    if (!ctx) return;
    LLVMValueRef count_val = LLVMConstInt(LLVMInt32TypeInContext(ctx),
                                           (uint32_t)actual_count, 0);
    LLVMBasicBlockRef bb = LLVMGetFirstBasicBlock(fn_val);
    while (bb) {
        LLVMValueRef inst = LLVMGetFirstInstruction(bb);
        while (inst) {
            if (LLVMIsACallInst(inst)) {
                LLVMValueRef callee = LLVMGetCalledValue(inst);
                if (callee == intrinsic) {
                    // Replace arg 2 (num_counters) with actual count
                    LLVMSetOperand(inst, 2, count_val);
                }
            }
            inst = LLVMGetNextInstruction(inst);
        }
        bb = LLVMGetNextBasicBlock(bb);
    }
}

// ── Coverage mapping (counter allocation + TSV covmap) ──
//
// Output format (line-oriented, one entry per line, tab-separated):
//   # file=<source_file>
//   <id>\t<type>\t<fn>\t<line>\t<col>\t<branch>
//   ...
//
// TSV (not JSON) because the Avra-side parser was previously hitting
// O(N) `strlen` per character on a 2.4 MB JSON buffer. Splitting by `\n`
// gives ~50-byte per-line strings whose `.length` is cheap.

#include <stdio.h>

#define COV_MAX_COUNTERS 65536

typedef struct {
    const char* type;       // "line", "branch_then", "branch_else", "fn_entry", "match_arm"
    const char* fn_name;
    int32_t line;
    int32_t col;
    int32_t branch_id;      // for grouping then/else pairs
} CovCounterInfo;

static CovCounterInfo cov_counters[COV_MAX_COUNTERS];
static int32_t cov_next_id = 0;
static int32_t cov_branch_id = 0;
static int32_t cov_decision_id = 0;
static const char* cov_source_file = NULL;
static FILE* cov_map_file = NULL;

void avra_covmap_begin(const char* source_file, const char* covmap_path) {
    cov_next_id = 0;
    cov_branch_id = 0;
    cov_decision_id = 0;
    cov_source_file = source_file;
    cov_map_file = fopen(covmap_path, "w");
    if (cov_map_file) {
        fprintf(cov_map_file, "# file=%s\n", source_file);
    }
}

int32_t avra_covmap_alloc(const char* type, const char* fn_name, int32_t line, int32_t col, int32_t branch_id) {
    if (cov_next_id >= COV_MAX_COUNTERS) return -1;
    int32_t id = cov_next_id++;
    cov_counters[id].type = type;
    cov_counters[id].fn_name = fn_name;
    cov_counters[id].line = line;
    cov_counters[id].col = col;
    cov_counters[id].branch_id = branch_id;

    if (cov_map_file) {
        fprintf(cov_map_file, "%d\t%s\t%s\t%d\t%d\t%d\n",
                id, type, fn_name, line, col, branch_id);
    }
    return id;
}

void avra_covmap_reset_fn(void) {
    cov_next_id = 0;
}

// Returns the number of counters allocated for the current function.
int32_t avra_covmap_counter_count(void) {
    return cov_next_id;
}

int32_t avra_covmap_next_branch_id(void) {
    return cov_branch_id++;
}

int32_t avra_covmap_next_decision_id(void) {
    return cov_decision_id++;
}

void avra_covmap_end(void) {
    if (cov_map_file) {
        fclose(cov_map_file);
        cov_map_file = NULL;
    }
}

// ── Basic block / instruction helpers ──

LLVMBasicBlockRef avra_llvm_get_entry_basic_block(LLVMValueRef fn) {
    return LLVMGetEntryBasicBlock(fn);
}

LLVMValueRef avra_llvm_get_first_instruction(LLVMBasicBlockRef bb) {
    return LLVMGetFirstInstruction(bb);
}

void avra_llvm_position_before(LLVMBuilderRef builder, LLVMValueRef instr) {
    LLVMPositionBuilderBefore(builder, instr);
}

void avra_llvm_build_call_void(LLVMBuilderRef builder, LLVMModuleRef mod, const char* fn_name, LLVMValueRef* args, int arg_count) {
    LLVMValueRef fn = LLVMGetNamedFunction(mod, fn_name);
    if (!fn) return;
    LLVMTypeRef fn_ty = LLVMGlobalGetValueType(fn);
    LLVMBuildCall2(builder, fn_ty, fn, args, arg_count, "");
}

// ── JIT Execution ──
// Execute an LLVM module's main() function in-process via MCJIT.
// Returns the exit code from main(), or -1 on error.

int64_t avra_llvm_jit_run(LLVMModuleRef module) {
    // Initialize native target for JIT
    LLVMLinkInMCJIT();
    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();
    LLVMInitializeNativeAsmParser();

    char* error = NULL;
    LLVMExecutionEngineRef engine;
    struct LLVMMCJITCompilerOptions options;
    LLVMInitializeMCJITCompilerOptions(&options, sizeof(options));
    options.OptLevel = 2;

    if (LLVMCreateMCJITCompilerForModule(&engine, module, &options, sizeof(options), &error)) {
        fprintf(stderr, "JIT error: %s\n", error);
        LLVMDisposeMessage(error);
        return -1;
    }

    // Look up main
    uint64_t main_addr = LLVMGetFunctionAddress(engine, "main");
    if (!main_addr) {
        fprintf(stderr, "JIT error: main() not found\n");
        LLVMDisposeExecutionEngine(engine);
        return -1;
    }

    // Call main() — it takes no args and returns void in our convention
    typedef void (*MainFn)(void);
    MainFn main_fn = (MainFn)main_addr;
    main_fn();

    LLVMDisposeExecutionEngine(engine);
    return 0;
}

// Shared MCJIT setup for the JIT-call primitives: build an execution engine for
// `module` and resolve `fn_name` to a callable address, handing the engine back
// (via `engine_out`) for the caller to dispose after the call. Returns 0 — and
// disposes any engine it created — on any error, so callers just check for a
// null address. Factored out so the int-return and float-return callers below
// share one engine-lifecycle path (their only real difference is the ABI of the
// return register they read).
// A JIT'd @comptime body reaches back into the host for any runtime symbol its
// codegen emits — e.g. a float literal lowers to `avra_float_parse(<str>)`.
// MCJIT resolves such symbols through dlsym(RTLD_DEFAULT, …) against bs2's own
// dynamic symbol table, so bs2 MUST be linked `-rdynamic`/`--export-dynamic`
// (see scripts/diagnose.sh); without it the reference resolves to null and the
// JIT'd code segfaults on the first call. Int/bool bodies never tripped this —
// their literals lower to LLVM constants, needing no host symbol.
static uint64_t avra_jit_resolve(LLVMModuleRef module, const char* fn_name,
                                 LLVMExecutionEngineRef* engine_out) {
    LLVMLinkInMCJIT();
    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();
    LLVMInitializeNativeAsmParser();

    char* error = NULL;
    LLVMExecutionEngineRef engine;
    struct LLVMMCJITCompilerOptions options;
    LLVMInitializeMCJITCompilerOptions(&options, sizeof(options));
    options.OptLevel = 2;

    if (LLVMCreateMCJITCompilerForModule(&engine, module, &options, sizeof(options), &error)) {
        fprintf(stderr, "JIT-call error: %s\n", error);
        LLVMDisposeMessage(error);
        return 0;
    }

    uint64_t addr = LLVMGetFunctionAddress(engine, fn_name);
    if (!addr) {
        fprintf(stderr, "JIT-call error: fn `%s` not found\n", fn_name);
        LLVMDisposeExecutionEngine(engine);
        return 0;
    }
    *engine_out = engine;
    return addr;
}

// Compiled-comptime (ps3t.5, Slice A): MCJIT the module and CALL a NAMED
// function with `argc` i64 arguments, returning its i64 result. Where
// `avra_llvm_jit_run` runs `main()`, this runs an arbitrary fn — the primitive
// that lets the compiler evaluate a `@comptime` fn by compiling+running it
// instead of tree-walking it. Arguments and result are i64: int/bool pass
// directly; float is bit-cast by the Avra marshal layer; a pointer result
// (string/enum) must be consumed BEFORE the engine is disposed (the JIT'd code
// + its allocations live in the engine) — Slice A gates on scalar returns, so
// dispose-after-read is safe here. Arity is dispatched by a switch because C
// cannot call through a runtime-arity function pointer.
int64_t avra_llvm_jit_call(LLVMModuleRef module, const char* fn_name,
                           int64_t argc, int64_t* argv) {
    LLVMExecutionEngineRef engine = NULL;
    uint64_t addr = avra_jit_resolve(module, fn_name, &engine);
    if (!addr) return 0;

    int64_t result = 0;
    switch (argc) {
        case 0: result = ((int64_t(*)(void))addr)(); break;
        case 1: result = ((int64_t(*)(int64_t))addr)(argv[0]); break;
        case 2: result = ((int64_t(*)(int64_t, int64_t))addr)(argv[0], argv[1]); break;
        case 3: result = ((int64_t(*)(int64_t, int64_t, int64_t))addr)(argv[0], argv[1], argv[2]); break;
        case 4: result = ((int64_t(*)(int64_t, int64_t, int64_t, int64_t))addr)(argv[0], argv[1], argv[2], argv[3]); break;
        default:
            fprintf(stderr, "JIT-call error: arity %lld unsupported (max 4)\n", (long long)argc);
            LLVMDisposeExecutionEngine(engine);
            return 0;
    }

    LLVMDisposeExecutionEngine(engine);
    return result;
}

// Float-return sibling of avra_llvm_jit_call (ps3t.5.2.1.1, part a). A @comptime
// fn declared `-> float` hands its result back in an FP register (xmm0/d0), which
// the int64 caller above cannot read — it would return whatever garbage sits in
// rax. Casting the JIT'd address to a `double`-returning fn pointer makes the ABI
// read the FP return register. Arguments stay i64 (int params ride the integer
// registers exactly as before); only the RETURN ABI differs. Float PARAMS would
// additionally need their args in FP registers, so a fn WITH float params stays
// interpreter-folded (the Avra-side gate keeps params int-only).
double avra_llvm_jit_call_f64(LLVMModuleRef module, const char* fn_name,
                              int64_t argc, int64_t* argv) {
    LLVMExecutionEngineRef engine = NULL;
    uint64_t addr = avra_jit_resolve(module, fn_name, &engine);
    if (!addr) return 0.0;

    double result = 0.0;
    switch (argc) {
        case 0: result = ((double(*)(void))addr)(); break;
        case 1: result = ((double(*)(int64_t))addr)(argv[0]); break;
        case 2: result = ((double(*)(int64_t, int64_t))addr)(argv[0], argv[1]); break;
        case 3: result = ((double(*)(int64_t, int64_t, int64_t))addr)(argv[0], argv[1], argv[2]); break;
        case 4: result = ((double(*)(int64_t, int64_t, int64_t, int64_t))addr)(argv[0], argv[1], argv[2], argv[3]); break;
        default:
            fprintf(stderr, "JIT-call error: arity %lld unsupported (max 4)\n", (long long)argc);
            LLVMDisposeExecutionEngine(engine);
            return 0.0;
    }

    LLVMDisposeExecutionEngine(engine);
    return result;
}

// String-return sibling of avra_llvm_jit_call (ps3t.5.2.1.1, part b). A @comptime
// fn declared `-> string` returns a `const char*`, but that pointer may reference
// the JIT module's own data section (a string literal is a module constant),
// which LLVMDisposeExecutionEngine frees along with the engine. So the result is
// COPIED into RC-managed host memory (avra_rc_alloc — the compiler's own
// allocator) BEFORE the dispose, and the copy, not the soon-to-dangle original,
// is returned. Args stay i64 (int params only, like the int/float variants).
extern void* avra_rc_alloc(int64_t payload_size);
const char* avra_llvm_jit_call_str(LLVMModuleRef module, const char* fn_name,
                                   int64_t argc, int64_t* argv) {
    LLVMExecutionEngineRef engine = NULL;
    uint64_t addr = avra_jit_resolve(module, fn_name, &engine);
    if (!addr) return NULL;

    const char* raw = NULL;
    switch (argc) {
        case 0: raw = ((const char*(*)(void))addr)(); break;
        case 1: raw = ((const char*(*)(int64_t))addr)(argv[0]); break;
        case 2: raw = ((const char*(*)(int64_t, int64_t))addr)(argv[0], argv[1]); break;
        case 3: raw = ((const char*(*)(int64_t, int64_t, int64_t))addr)(argv[0], argv[1], argv[2]); break;
        case 4: raw = ((const char*(*)(int64_t, int64_t, int64_t, int64_t))addr)(argv[0], argv[1], argv[2], argv[3]); break;
        default:
            fprintf(stderr, "JIT-call error: arity %lld unsupported (max 4)\n", (long long)argc);
            LLVMDisposeExecutionEngine(engine);
            return NULL;
    }

    // Copy out BEFORE dispose — `raw` may point into the engine's memory.
    const char* copy = NULL;
    if (raw) {
        size_t len = strlen(raw);
        char* buf = (char*)avra_rc_alloc((int64_t)len + 1);
        memcpy(buf, raw, len + 1);
        copy = buf;
    }

    LLVMDisposeExecutionEngine(engine);
    return copy;
}

// ── i64 argument-vector marshalling (ps3t.5, Slice A) ──
// A flat `int64_t[]` for `avra_llvm_jit_call`'s argv. The Avra marshal layer
// lowers a List<Value> into one of these — int/bool go in directly, float is
// bit-cast to its i64 pattern, string/enum pass their pointer as an integer.
// (The LLVM value/type array helpers above hold `LLVMValueRef`/`LLVMTypeRef`,
// not raw operands, so they can't serve here.)
int64_t* avra_i64_buf_new(int64_t n) {
    if (n <= 0) return NULL;
    return (int64_t*)calloc((size_t)n, sizeof(int64_t));
}
void avra_i64_buf_set(int64_t* buf, int64_t i, int64_t v) { buf[i] = v; }
void avra_i64_buf_free(int64_t* buf) { free(buf); }

// ── Object File Emission ──
// Emit an LLVM module as an object file. Returns 0 on success, -1 on error.

int64_t avra_llvm_emit_object(LLVMModuleRef module, const char* output_path) {
    LLVMInitializeNativeTarget();
    LLVMInitializeNativeAsmPrinter();

    char* triple = LLVMGetDefaultTargetTriple();
    LLVMTargetRef target;
    char* error = NULL;

    if (LLVMGetTargetFromTriple(triple, &target, &error)) {
        fprintf(stderr, "target error: %s\n", error);
        LLVMDisposeMessage(error);
        LLVMDisposeMessage(triple);
        return -1;
    }

    // Emit position-independent code. macOS already defaults to PIC, but
    // LLVMRelocDefault on Linux/x86-64 selects the static model, whose
    // absolute relocations (R_X86_64_32) can't be linked into the PIE
    // executables modern toolchains produce by default. PIC is correct on
    // every supported target, so request it explicitly.
    LLVMTargetMachineRef tm = LLVMCreateTargetMachine(
        target, triple, "generic", "",
        LLVMCodeGenLevelDefault, LLVMRelocPIC, LLVMCodeModelDefault);
    LLVMDisposeMessage(triple);

    if (LLVMTargetMachineEmitToFile(tm, module, (char*)output_path, LLVMObjectFile, &error)) {
        fprintf(stderr, "emit error: %s\n", error);
        LLVMDisposeMessage(error);
        LLVMDisposeTargetMachine(tm);
        return -1;
    }

    LLVMDisposeTargetMachine(tm);
    return 0;
}
