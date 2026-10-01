// The compiler's LLVM binding — pure C over LLVM's C API, OURS:
// llvm_api.av declares against exactly these symbols, and a builder
// is added HERE when the backend declares it, never hunted for
// elsewhere. Every fn below is named by the tree; one that is not
// is debris. Targets the LLVM 21 C API.

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/Transforms/PassBuilder.h>
#include <llvm-c/Error.h>
#include <llvm-c/BitReader.h>
#include <llvm-c/Linker.h>
#include <llvm-c/Comdat.h>
#include <stdlib.h>
#include <string.h>
void avra_trap(const char* msg);
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <stddef.h>
#include "../runtime/avra_box.h"
#include "../build/avra_hot.inc"

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

LLVMTypeRef avra_llvm_int32_type(LLVMContextRef ctx) {
    return LLVMInt32TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_int64_type(LLVMContextRef ctx) {
    return LLVMInt64TypeInContext(ctx);
}

LLVMTypeRef avra_llvm_void_type(LLVMContextRef ctx) {
    return LLVMVoidTypeInContext(ctx);
}

LLVMTypeRef avra_llvm_pointer_type(LLVMContextRef ctx) {
    return LLVMPointerTypeInContext(ctx, 0);
}

LLVMTypeRef avra_llvm_function_type(LLVMTypeRef ret, LLVMTypeRef* params, int param_count, int is_vararg) {
    return LLVMFunctionType(ret, params, (unsigned)param_count, is_vararg);
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

void avra_llvm_value_array_free(LLVMValueRef* arr) {
    free(arr);
}

// ── Constants ──

LLVMValueRef avra_llvm_const_int(LLVMTypeRef ty, int64_t value, int sign_extend) {
    if (!ty) {
        fprintf(stderr, "[CRASH] avra_llvm_const_int: ty is NULL (value=%lld)\n", (long long)value);
        abort();
    }
    // Safety: the bootstrap sometimes passes null or non-integer types.
    // Default to i64 (matching the everything-is-i64 model).
    if (!ty || LLVMGetTypeKind(ty) != LLVMIntegerTypeKind) {
        // The fallback keeps the context the caller's type was minted in.
        ty = LLVMInt64TypeInContext(LLVMGetTypeContext(ty));
    }
    return LLVMConstInt(ty, (unsigned long long)value, sign_extend);
}

// Whether a value is an integer constant, and that constant read
// sign-extended — two questions, so presence never spends a value.
int64_t avra_llvm_is_const_int(LLVMValueRef v) {
    return LLVMIsAConstantInt(v) != NULL;
}

int64_t avra_llvm_const_int_sext(LLVMValueRef v) {
    return LLVMConstIntGetSExtValue(v);
}

LLVMValueRef avra_llvm_const_pointer_null(LLVMTypeRef ty) {
    return LLVMConstPointerNull(ty);
}

LLVMTypeRef avra_llvm_struct_type(LLVMContextRef ctx, LLVMTypeRef* elems, int count) {
    return LLVMStructTypeInContext(ctx, elems, (unsigned)count, 0);
}

LLVMValueRef avra_llvm_get_undef(LLVMTypeRef ty) {
    return LLVMGetUndef(ty);
}

LLVMValueRef avra_llvm_build_insert_value(LLVMBuilderRef b, LLVMValueRef agg, LLVMValueRef v, int idx, const char* name) {
    return LLVMBuildInsertValue(b, agg, v, (unsigned)idx, name);
}

LLVMValueRef avra_llvm_build_extract_value(LLVMBuilderRef b, LLVMValueRef agg, int idx, const char* name) {
    return LLVMBuildExtractValue(b, agg, (unsigned)idx, name);
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
    // A FRAME NEVER SKIPS A GUARD. A frame wider than a page is probed a
    // page at a time, so a task's overflow lands on its guard page
    // (runtime/avra_fiber.c) and never in a neighbour's stack. Frames
    // under a page are unchanged.
    LLVMAttributeRef probe = LLVMCreateStringAttribute(LLVMGetModuleContext(m), "probe-stack", 11, "inline-asm", 10);
    LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex, probe);
    return fn;
}

void avra_llvm_set_weak_odr(LLVMValueRef fn) {
    LLVMSetLinkage(fn, LLVMWeakODRLinkage);
}

// A body the compiler proved runs at most once (R12, cold_bodies):
// `cold` tells the optimizer it is rarely reached, `minsize` tells it
// to favor fewer bytes over fewer cycles inside it — together, the
// straight-line table-building this marks stops paying for the hot
// leaves' inlined bodies it will only ever execute once.
static LLVMAttributeRef enum_attr(LLVMContextRef ctx, const char* name) {
    unsigned kind = LLVMGetEnumAttributeKindForName(name, strlen(name));
    return LLVMCreateEnumAttribute(ctx, kind, 0);
}

void avra_llvm_set_cold(LLVMValueRef fn) {
    LLVMContextRef ctx = LLVMGetModuleContext(LLVMGetGlobalParent(fn));
    LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex, enum_attr(ctx, "cold"));
    LLVMAddAttributeAtIndex(fn, LLVMAttributeFunctionIndex, enum_attr(ctx, "minsize"));
}

// Whether this build counts the boxes runtime rows mint, by type:
// AVRA_CENSUS_TYPES set and not "0". The census's own build sets it.
int64_t avra_llvm_census_types(void) {
    const char* v = getenv("AVRA_CENSUS_TYPES");
    return v && *v && strcmp(v, "0") != 0;
}

// A call to the census's box counter naming what was minted; `label`
// becomes a private C string in `m`, read only by that counter.
void avra_llvm_build_census_box(LLVMBuilderRef b, LLVMModuleRef m, const char* label) {
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMTypeRef ptr = LLVMPointerTypeInContext(ctx, 0);
    LLVMTypeRef fty = LLVMFunctionType(LLVMVoidTypeInContext(ctx), &ptr, 1, 0);
    LLVMValueRef fn = LLVMGetNamedFunction(m, "avra_census_box");
    if (!fn) fn = LLVMAddFunction(m, "avra_census_box", fty);
    LLVMValueRef text = LLVMBuildGlobalStringPtr(b, label, "census.box");
    LLVMBuildCall2(b, fty, fn, &text, 1, "");
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

LLVMTypeRef avra_llvm_fn_type_of(LLVMValueRef fn_val) {
    if (!fn_val) {
        fprintf(stderr, "[CRASH] avra_llvm_fn_type_of: fn_val is NULL\n");
        abort();
    }
    return LLVMGlobalGetValueType(fn_val);
}

/* the answer type a function was declared with */
LLVMTypeRef avra_llvm_return_type_of(LLVMValueRef fn_val) {
    return LLVMGetReturnType(avra_llvm_fn_type_of(fn_val));
}

// ── Globals ──

// ── Basic blocks ──

LLVMBasicBlockRef avra_llvm_append_basic_block(LLVMContextRef ctx, LLVMValueRef fn_val, const char* name) {
    return LLVMAppendBasicBlockInContext(ctx, fn_val, name);
}

void avra_llvm_position_at_end(LLVMBuilderRef b, LLVMBasicBlockRef bb) {
    LLVMPositionBuilderAtEnd(b, bb);
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

// ── Bitwise ──

LLVMValueRef avra_llvm_build_and(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildAnd(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_or(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildOr(b, lhs, rhs, name);
}

/* ── The FLOAT seam. A double lives in its own register file, so a
   float value never rides an integer instruction — the builders are
   separate on purpose and mixing them is silently wrong. */
LLVMTypeRef avra_llvm_double_type(LLVMContextRef ctx) { return LLVMDoubleTypeInContext(ctx); }

/* A float CONSTANT arrives as its IEEE-754 BIT PATTERN in an int64,
   because the compiler that emits it is written in a language whose
   own source holds no float value. The reinterpretation is exact. */
LLVMValueRef avra_llvm_const_double_bits(LLVMContextRef ctx, int64_t bits) {
    double d;
    memcpy(&d, &bits, sizeof d);
    return LLVMConstReal(LLVMDoubleTypeInContext(ctx), d);
}

LLVMValueRef avra_llvm_build_fadd(LLVMBuilderRef b, LLVMValueRef l, LLVMValueRef r, const char* n) { return LLVMBuildFAdd(b, l, r, n); }
LLVMValueRef avra_llvm_build_fsub(LLVMBuilderRef b, LLVMValueRef l, LLVMValueRef r, const char* n) { return LLVMBuildFSub(b, l, r, n); }
LLVMValueRef avra_llvm_build_fmul(LLVMBuilderRef b, LLVMValueRef l, LLVMValueRef r, const char* n) { return LLVMBuildFMul(b, l, r, n); }
LLVMValueRef avra_llvm_build_fdiv(LLVMBuilderRef b, LLVMValueRef l, LLVMValueRef r, const char* n) { return LLVMBuildFDiv(b, l, r, n); }

/* An ORDERED comparison: NaN answers false to every one, which is
   IEEE-754's rule and not ours to soften. */
LLVMValueRef avra_llvm_build_fcmp(LLVMBuilderRef b, int pred, LLVMValueRef l, LLVMValueRef r, const char* n) {
    return LLVMBuildFCmp(b, (LLVMRealPredicate)pred, l, r, n);
}

LLVMValueRef avra_llvm_build_xor(LLVMBuilderRef b, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildXor(b, lhs, rhs, name);
}

LLVMValueRef avra_llvm_build_not(LLVMBuilderRef b, LLVMValueRef val, const char* name) {
    return LLVMBuildNot(b, val, name);
}

// ── Comparison ──

LLVMValueRef avra_llvm_build_icmp(LLVMBuilderRef b, int pred, LLVMValueRef lhs, LLVMValueRef rhs, const char* name) {
    return LLVMBuildICmp(b, (LLVMIntPredicate)pred, lhs, rhs, name);
}

// ── Float arithmetic ──

// ── Casts ──

LLVMValueRef avra_llvm_build_zext(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildZExt(b, val, dest_ty, name);
}

/* The SIGNED widening. `avra_llvm_cast_to_type` REFUSES to widen at
   all — it traps and names these two builders — because only the
   caller knows the sign. This is the half a caller reaches for when
   its declaration said `i32`; `build_zext` is the `u32` half.

   Neither existed while `cast_to_type` zero-extended everything, and
   that is the whole finding said from the other side: the wrapper was
   written by someone who only ever needed to widen unsigned things,
   and nothing recorded that until a signed width needed the twin. */
LLVMValueRef avra_llvm_build_sext(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildSExt(b, val, dest_ty, name);
}

/* The narrowing an extern's declared width asks for at an argument. */
LLVMValueRef avra_llvm_build_trunc(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildTrunc(b, val, dest_ty, name);
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

/* A REINTERPRETATION, never a conversion: a double and the i64 word a
   container slot keeps it in are the same bits, and a conversion would
   change the number. Its two directions are `worded` and the result
   coercion in `call_rt_value`, and a value that goes in one way and
   comes back the other is the defect that pair exists to prevent. */
LLVMValueRef avra_llvm_build_bitcast(LLVMBuilderRef b, LLVMValueRef val, LLVMTypeRef dest_ty, const char* name) {
    return LLVMBuildBitCast(b, val, dest_ty, safe_name(name, "bc"));
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

    LLVMBuilderRef entry_builder = LLVMCreateBuilderInContext(LLVMGetTypeContext(ty));
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
    // A struct-typed cell needs the same zeroing, whole, padding
    // included: `avra_cell_release` reads the cell's first word raw,
    // and a per-field `LLVMConstNull` store leaves inter-field padding
    // (an i1 tag's alignment gap before the pointer that follows it)
    // untouched — read as that pointer, on a settle before the seed
    // store ever writes it.
    if (LLVMGetTypeKind(ty) == LLVMStructTypeKind) {
        LLVMBuildMemSet(
            entry_builder,
            alloca,
            LLVMConstInt(LLVMInt8TypeInContext(LLVMGetTypeContext(ty)), 0, 0),
            LLVMSizeOf(ty),
            8
        );
    }
    LLVMDisposeBuilder(entry_builder);
    return alloca;
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

// ── Static data ──
// Every pointer a program holds carries the runtime's header
// (runtime/avra_box.h), and data laid out here is no exception: a
// string constant, a settled list, record, enum or map. Each is a
// private global whose first sixteen bytes ARE the header, kind
// immortal — retain and release read it and never write, so a
// string stays constant; an array's marks are read at clone and its
// index built at first lookup, so those globals are writable. The
// layouts mirror avra_box.h's structs field for field, which the
// asserts pin: a field added there fails here rather than shifting
// what the runtime reads.
_Static_assert(sizeof(Header) == 16, "the header is sixteen bytes before every payload");
_Static_assert(offsetof(AvraArray, cap) == 0 && offsetof(AvraArray, len) == 8 && offsetof(AvraArray, data) == 16 &&
               offsetof(AvraArray, marks) == 24 && offsetof(AvraArray, site) == 32 && sizeof(AvraArray) == 40,
               "the static array layout mirrors AvraArray");
_Static_assert(offsetof(AvraMap, keys) == 0 && offsetof(AvraMap, vals) == 8 && offsetof(AvraMap, index) == 16 &&
               offsetof(AvraMap, icap) == 24 && sizeof(AvraMap) == 32,
               "the static map layout mirrors AvraMap");

// The header as constant fields: tag, kind, count, length.
static LLVMValueRef header_const(LLVMContextRef ctx, int32_t kind, uint32_t len) {
    LLVMTypeRef i32 = LLVMInt32TypeInContext(ctx);
    LLVMValueRef fields[4] = {
        LLVMConstInt(i32, AVRA_TAG, 0),
        LLVMConstInt(i32, (unsigned long long)kind, 1),
        LLVMConstInt(i32, 0, 0),
        LLVMConstInt(i32, len, 0),
    };
    return LLVMConstStructInContext(ctx, fields, 4, 0);
}

// A headered global, sixteen-aligned so the payload is too — what
// lets the runtime refuse an unaligned scalar before reading
// anything. Answers the PAYLOAD's address, sixteen bytes in.
static LLVMValueRef headered_global(LLVMModuleRef m, LLVMValueRef init, const char* name, int constant) {
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMValueRef g = LLVMAddGlobal(m, LLVMTypeOf(init), name);
    LLVMSetInitializer(g, init);
    LLVMSetGlobalConstant(g, constant);
    LLVMSetLinkage(g, LLVMPrivateLinkage);
    LLVMSetUnnamedAddress(g, LLVMGlobalUnnamedAddr);
    LLVMSetAlignment(g, 16);
    LLVMValueRef offset = LLVMConstInt(LLVMInt64TypeInContext(ctx), 16, 0);
    return LLVMConstInBoundsGEP2(LLVMInt8TypeInContext(ctx), g, &offset, 1);
}

// A text constant: the header says STATIC and carries the LENGTH,
// so `.length` on a literal is a load. THE LENGTH IS HANDED IN, never
// measured: a settled string holds a NUL all the way, and `strlen`
// would end the constant at it while the evaluator kept the rest.
LLVMValueRef avra_llvm_global_text(LLVMModuleRef m, const char* s, int64_t len, const char* name) {
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMValueRef fields[2] = { header_const(ctx, KIND_STATIC, (uint32_t)len), LLVMConstStringInContext(ctx, s, (unsigned)len, 0) };
    return headered_global(m, LLVMConstStructInContext(ctx, fields, 2, 0), name, 1);
}

LLVMValueRef avra_llvm_build_text(LLVMBuilderRef b, const char* s, int64_t len, const char* name) {
    return avra_llvm_global_text(LLVMGetGlobalParent(LLVMGetBasicBlockParent(LLVMGetInsertBlock(b))), s, len, name);
}

// A slot array laid out whole: the header, the AvraArray, then its
// cells and their marks in one buffer, the way the runtime
// allocates one. A cell arrives as an i64 or as a POINTER constant
// (a string, another static box) — a pointer stored as its word —
// with the mark the compiler gives it, exactly what a pack at run
// time would write. The
// buffer is addressed from the global itself, so one global is the
// whole box.
LLVMValueRef avra_llvm_static_array(LLVMModuleRef m, const char* name, LLVMValueRef* cells, LLVMValueRef* given_marks, int n) {
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMTypeRef i8 = LLVMInt8TypeInContext(ctx);
    LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx);
    LLVMTypeRef ptr = LLVMPointerTypeInContext(ctx, 0);
    LLVMValueRef* words = (LLVMValueRef*)malloc(sizeof(LLVMValueRef) * (size_t)(n > 0 ? n : 1));
    LLVMValueRef* marks = (LLVMValueRef*)malloc(sizeof(LLVMValueRef) * (size_t)(n > 0 ? n : 1));
    // each cell's mark is the compiler's (`slot_mark`), never guessed
    // from the constant's type: an absent nullable int is a plain zero
    for (int i = 0; i < n; i++) {
        int pointer = LLVMGetTypeKind(LLVMTypeOf(cells[i])) == LLVMPointerTypeKind;
        words[i] = pointer ? LLVMConstPtrToInt(cells[i], i64) : cells[i];
        marks[i] = given_marks[i];
    }
    LLVMTypeRef cells_ty = LLVMArrayType2(i64, (uint64_t)n);
    LLVMTypeRef marks_ty = LLVMArrayType2(i8, (uint64_t)n);
    LLVMTypeRef box_ty = LLVMStructTypeInContext(ctx, (LLVMTypeRef[]){ i64, i64, ptr, ptr, ptr }, 5, 0);
    LLVMTypeRef whole_ty = LLVMStructTypeInContext(ctx, (LLVMTypeRef[]){ LLVMTypeOf(header_const(ctx, 0, 0)), box_ty, cells_ty, marks_ty }, 4, 0);
    LLVMValueRef g = LLVMAddGlobal(m, whole_ty, name);
    LLVMValueRef zero = LLVMConstInt(LLVMInt32TypeInContext(ctx), 0, 0);
    LLVMValueRef at_cells[2] = { zero, LLVMConstInt(LLVMInt32TypeInContext(ctx), 2, 0) };
    LLVMValueRef at_marks[2] = { zero, LLVMConstInt(LLVMInt32TypeInContext(ctx), 3, 0) };
    LLVMValueRef box_fields[5] = {
        LLVMConstInt(i64, (unsigned long long)n, 0),
        LLVMConstInt(i64, (unsigned long long)n, 0),
        LLVMConstInBoundsGEP2(whole_ty, g, at_cells, 2),
        LLVMConstInBoundsGEP2(whole_ty, g, at_marks, 2),
        LLVMConstPointerNull(ptr),
    };
    LLVMValueRef fields[4] = {
        header_const(ctx, KIND_IMMORTAL(KIND_ARRAY), (uint32_t)sizeof(AvraArray)),
        LLVMConstStructInContext(ctx, box_fields, 5, 0),
        LLVMConstArray2(i64, words, (uint64_t)n),
        LLVMConstArray2(i8, marks, (uint64_t)n),
    };
    LLVMSetInitializer(g, LLVMConstStructInContext(ctx, fields, 4, 0));
    LLVMSetLinkage(g, LLVMPrivateLinkage);
    LLVMSetAlignment(g, 16);
    free(words);
    free(marks);
    LLVMValueRef offset = LLVMConstInt(i64, 16, 0);
    return LLVMConstInBoundsGEP2(i8, g, &offset, 1);
}

// A map laid out whole over its two static arrays; the index is
// left UNBUILT (capacity zero) for the runtime to hash on first use.
LLVMValueRef avra_llvm_static_map(LLVMModuleRef m, const char* name, LLVMValueRef keys, LLVMValueRef vals) {
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx);
    LLVMTypeRef ptr = LLVMPointerTypeInContext(ctx, 0);
    LLVMValueRef map_fields[4] = { keys, vals, LLVMConstPointerNull(ptr), LLVMConstInt(i64, 0, 0) };
    LLVMValueRef fields[2] = {
        header_const(ctx, KIND_IMMORTAL(KIND_MAP), (uint32_t)sizeof(AvraMap)),
        LLVMConstStructInContext(ctx, map_fields, 4, 0),
    };
    return headered_global(m, LLVMConstStructInContext(ctx, fields, 2, 0), name, 0);
}

// The payload address of a headered global already laid out.
LLVMValueRef avra_llvm_global_payload(LLVMModuleRef m, const char* name) {
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMValueRef g = LLVMGetNamedGlobal(m, name);
    if (!g) { avra_trap("compiler defect: a static read names no data"); }
    LLVMValueRef offset = LLVMConstInt(LLVMInt64TypeInContext(ctx), 16, 0);
    return LLVMConstInBoundsGEP2(LLVMInt8TypeInContext(ctx), g, &offset, 1);
}

// A `once fn`'s OWN SLOT: one raw pointer word, null-initialized,
// private to this module — UNHEADERED, unlike every other global
// here, because nothing walks it as a box; it holds the ADDRESS
// `OnceRead`/`OnceCommit` load and store through. Idempotent by
// name, so a fn's read and its own commit answer the SAME global.
LLVMValueRef avra_llvm_once_slot(LLVMModuleRef m, const char* name) {
    LLVMValueRef g = LLVMGetNamedGlobal(m, name);
    if (g) { return g; }
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMTypeRef ptr_ty = LLVMPointerTypeInContext(ctx, 0);
    g = LLVMAddGlobal(m, ptr_ty, name);
    LLVMSetInitializer(g, LLVMConstPointerNull(ptr_ty));
    LLVMSetLinkage(g, LLVMPrivateLinkage);
    return g;
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

// An N-way branch on an integer selector: the jump table. Cases are
// added one at a time; `default_bb` takes every unlisted value, which
// for a total match is simply the last arm.
LLVMValueRef avra_llvm_build_switch(LLVMBuilderRef b, LLVMValueRef selector,
                                    LLVMBasicBlockRef default_bb, int case_count) {
    return LLVMBuildSwitch(b, selector, default_bb, (unsigned)case_count);
}

void avra_llvm_add_case(LLVMValueRef switch_val, LLVMValueRef on_val, LLVMBasicBlockRef dest) {
    LLVMAddCase(switch_val, on_val, dest);
}

LLVMValueRef avra_llvm_build_ret(LLVMBuilderRef b, LLVMValueRef val) {
    return LLVMBuildRet(b, val);
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
int64_t avra_llvm_print_module_to_file(LLVMModuleRef m, const char* path) {
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

// THE SAME MODULE, AS BITCODE: what clang parses far faster than text, and what the
// build path hands it. Atomic the same way — a temp, then rename.
int64_t avra_llvm_write_bitcode_to_file(LLVMModuleRef m, const char* path) {
    char tmp[4096];
    if (snprintf(tmp, sizeof(tmp), "%s.tmp.%d", path, (int)getpid())
            >= (int)sizeof(tmp)) {
        return 1;
    }
    if (LLVMWriteBitcodeToFile(m, tmp) != 0) {
        remove(tmp);
        return 1;
    }
    if (rename(tmp, path) != 0) {
        remove(tmp);
        return 1;
    }
    return 0;
}

/* The CPU every machine of a triple has — clang's own default, so an object
   made here is tuned as the C beside it is. Unnamed where clang names none. */
static const char* baseline_cpu(const char* triple) {
    return strncmp(triple, "arm64-apple", 11) == 0 ? "apple-m1" : "";
}

/* The native target, registered once — on the program's own thread, before any
   worker reads the registry. 0 when it stands. */
static int native_target_ready(void) {
    static int ready = 0;
    if (!ready && !(LLVMInitializeNativeTarget() || LLVMInitializeNativeAsmPrinter())) ready = 1;
    return ready ? 0 : 1;
}

// THE HOT LEAVES, INLINABLE (runtime/avra_hot.h): the bitcode this
// compiler carries is linked into a module before its passes, every
// KEPT definition AVAILABLE EXTERNALLY — the optimizer may inline it and
// emits none, so a call it keeps resolves to the runtime library's own.
// The leaves take the module's target, never the one clang compiled them
// for, so the inliner finds them compatible. AVRA_INLINE_RUNTIME=0 keeps
// them all calls — a leaf's return address then names its caller exactly.
static int hot_off = 0;

__attribute__((constructor))
static void hot_settled(void) {
    const char* v = getenv("AVRA_INLINE_RUNTIME");
    hot_off = v != NULL && strcmp(v, "0") == 0;
}

// Whether this process's objects carry the hot leaves inlined — a mode of
// the codegen, so a key over what the compiler emits folds it in.
int64_t avra_llvm_inlines_runtime(void) {
    return !hot_off && avra_hot_bc_len != 0;
}

// NOT EVERY HOT LEAF PAYS FOR ITS OWN INLINING: `hot_linked` runs once
// per FILE MODULE, so a kept leaf's body is a cost the optimizer and
// codegen pay again in every module it lands in, not once — the bigger,
// branchier or more COMPOSED a leaf's body, the more that multiplies.
// Which leaves are worth that is a per-leaf question, settled by a
// same-input differential census over `check`'s own instruction count,
// one leaf dropped at a time from the full carried set (perf-notes):
// dropping `avra_array_get`/`avra_array_get_owned` alone costs +8.7
// points — this compiler's own body leans on array reads constantly,
// so losing their inlining anywhere is the whole regression. Dropping
// `avra_box_thawed` or the tagged retain/release wrappers costs under
// 0.1 point each — they buy the smaller module every dropped leaf
// buys, and nothing measurable back, so they stay dropped.
static int hot_keep(const char* name) {
    return strcmp(name, "avra_rc_retain") == 0
        || strcmp(name, "avra_rc_release") == 0
        || strcmp(name, "avra_array_len") == 0
        || strcmp(name, "avra_array_get") == 0
        || strcmp(name, "avra_array_get_owned") == 0
        || strcmp(name, "avra_slot_get") == 0
        || strcmp(name, "avra_slot_get_owned") == 0;
}

static void hot_linked(LLVMModuleRef m) {
    if (hot_off || avra_hot_bc_len == 0) return;
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMMemoryBufferRef buf = LLVMCreateMemoryBufferWithMemoryRange((const char*)avra_hot_bc, (size_t)avra_hot_bc_len, "avra_hot", 0);
    LLVMModuleRef hot;
    int bad = LLVMParseBitcodeInContext2(ctx, buf, &hot);
    LLVMDisposeMemoryBuffer(buf);
    if (bad) return;
    LLVMValueRef f = LLVMGetFirstFunction(hot);
    while (f) {
        LLVMValueRef next = LLVMGetNextFunction(f);
        if (LLVMIsDeclaration(f)) { f = next; continue; }
        // A dropped leaf is ERASED, not left at its own linkage: linking
        // it in as a second External definition of a symbol the caller
        // module already declares would give every module its own copy
        // of the body — worse than before this file existed.
        if (!hot_keep(LLVMGetValueName(f))) { LLVMDeleteFunction(f); f = next; continue; }
        LLVMRemoveStringAttributeAtIndex(f, LLVMAttributeFunctionIndex, "target-cpu", 10);
        LLVMRemoveStringAttributeAtIndex(f, LLVMAttributeFunctionIndex, "target-features", 15);
        if (LLVMGetLinkage(f) == LLVMExternalLinkage) LLVMSetLinkage(f, LLVMAvailableExternallyLinkage);
        f = next;
    }
    LLVMSetTarget(hot, LLVMGetTarget(m));
    LLVMSetDataLayout(hot, LLVMGetDataLayoutStr(m));
    LLVMLinkModules2(m, hot);
}

// WHETHER THE LINKER DROPS UNREACHED CODE BY ATOM (Mach-O, every symbol a
// subsection) or BY SECTION (ELF). The one predicate the link option and
// the emitted sections both read.
int64_t avra_llvm_drops_by_atom(void) {
#ifdef __APPLE__
    return 1;
#else
    return 0;
#endif
}

// Whether a constant's value holds an address — a relocation the loader
// writes, which keeps a datum out of a read-only section.
static int holds_address(LLVMValueRef c) {
    if (LLVMIsAGlobalValue(c) || LLVMIsABlockAddress(c)) return 1;
    int n = LLVMGetNumOperands(c);
    for (int i = 0; i < n; i++) {
        LLVMValueRef op = LLVMGetOperand(c, (unsigned)i);
        if (op && holds_address(op)) return 1;
    }
    return 0;
}

// The section a LOCAL datum stands in, by what the loader does with it:
// written, zeroed, relocated then frozen, or read only. A mergeable
// constant (an unnamed-address one with no address in it) stays where
// the module put it, merged with its equals.
static const char* local_section_kind(LLVMValueRef g) {
    LLVMValueRef init = LLVMGetInitializer(g);
    if (!init || LLVMIsThreadLocal(g)) return NULL;
    if (!LLVMIsGlobalConstant(g)) return LLVMIsNull(init) ? ".bss" : ".data";
    if (holds_address(init)) return ".data.rel.ro";
    return LLVMGetUnnamedAddress(g) == LLVMNoUnnamedAddr ? ".rodata" : NULL;
}

// ELF DROPS BY SECTION, so every definition stands in a section of its
// own and the link's --gc-sections drops the ones nothing reaches — what
// clang's -ffunction-sections -fdata-sections ask of a target, which the
// C API cannot. A named definition takes a group keyed by its own name
// (a comdat), which gets it a section of the right kind and gathers a
// fn's jump tables beside it; the group never deduplicates, so two
// definitions of one name stay a link error. A local one takes a section
// named for its kind and numbered within its module.
static void sectioned(LLVMModuleRef m, LLVMValueRef g, int is_fn, int* nth) {
    const char* held = LLVMGetSection(g);
    if (LLVMIsDeclaration(g) || LLVMGetComdat(g) || (held && *held)) return;
    LLVMLinkage l = LLVMGetLinkage(g);
    if (l == LLVMAvailableExternallyLinkage) return;
    if (l != LLVMInternalLinkage && l != LLVMPrivateLinkage) {
        LLVMComdatRef group = LLVMGetOrInsertComdat(m, LLVMGetValueName(g));
        LLVMSetComdatSelectionKind(group, LLVMNoDeduplicateComdatSelectionKind);
        LLVMSetComdat(g, group);
        return;
    }
    const char* kind = is_fn ? ".text" : local_section_kind(g);
    if (!kind) return;
    char section[48];
    snprintf(section, sizeof(section), "%s.avra.local.%d", kind, (*nth)++);
    LLVMSetSection(g, section);
}

static void sectioned_by_definition(LLVMModuleRef m) {
    if (avra_llvm_drops_by_atom()) return;
    int nth = 0;
    for (LLVMValueRef f = LLVMGetFirstFunction(m); f; f = LLVMGetNextFunction(f)) sectioned(m, f, 1, &nth);
    for (LLVMValueRef g = LLVMGetFirstGlobal(m); g; g = LLVMGetNextGlobal(g)) sectioned(m, g, 0, &nth);
}

// A MODULE AS AN OBJECT: the `default<O1>`-style pipeline clang runs on
// bitcode, then the native target's code generator, at clang's level 0..3.
// Atomic as the writers above — a temp, then rename. Answers 0, or 1 with the
// reason on stderr. It touches its module's context and nothing shared, so a
// worker runs it.
static int object_written(LLVMModuleRef m, const char* path, int64_t level) {
    char tmp[4096];
    if (snprintf(tmp, sizeof(tmp), "%s.tmp.%d", path, (int)getpid()) >= (int)sizeof(tmp)) return 1;
    char* triple = LLVMGetDefaultTargetTriple();
    char* error = NULL;
    LLVMTargetRef target;
    if (LLVMGetTargetFromTriple(triple, &target, &error)) {
        fprintf(stderr, "avra: no native target for %s — %s\n", triple, error ? error : "");
        if (error) LLVMDisposeMessage(error);
        LLVMDisposeMessage(triple);
        return 1;
    }
    LLVMCodeGenOptLevel cg = level <= 0 ? LLVMCodeGenLevelNone : level == 1 ? LLVMCodeGenLevelLess
                           : level == 2 ? LLVMCodeGenLevelDefault : LLVMCodeGenLevelAggressive;
    LLVMTargetMachineRef tm = LLVMCreateTargetMachine(target, triple, baseline_cpu(triple), "", cg, LLVMRelocPIC, LLVMCodeModelDefault);
    LLVMSetTarget(m, triple);
    LLVMTargetDataRef layout = LLVMCreateTargetDataLayout(tm);
    LLVMSetModuleDataLayout(m, layout);
    int failed = 0;
    if (level > 0) {
        hot_linked(m);
        char passes[32];
        snprintf(passes, sizeof(passes), "default<O%d>", level > 3 ? 3 : (int)level);
        LLVMPassBuilderOptionsRef opts = LLVMCreatePassBuilderOptions();
        // Structural duplicates (a pointer-shaped generic's instantiations)
        // fold into thunks. Sound while no fn is `unnamed_addr`: the pass
        // then merges bodies, never addresses.
        LLVMPassBuilderOptionsSetMergeFunctions(opts, 1);
        LLVMErrorRef ran = LLVMRunPasses(m, passes, tm, opts);
        LLVMDisposePassBuilderOptions(opts);
        if (ran) {
            char* why = LLVMGetErrorMessage(ran);
            fprintf(stderr, "avra: the optimizer refused — %s\n", why);
            LLVMDisposeErrorMessage(why);
            failed = 1;
        }
    }
    if (!failed) sectioned_by_definition(m);
    if (!failed && LLVMTargetMachineEmitToFile(tm, m, tmp, LLVMObjectFile, &error)) {
        fprintf(stderr, "avra: no object for %s — %s\n", path, error ? error : "");
        if (error) LLVMDisposeMessage(error);
        failed = 1;
    }
    LLVMDisposeTargetData(layout);
    LLVMDisposeTargetMachine(tm);
    LLVMDisposeMessage(triple);
    if (failed || rename(tmp, path) != 0) { remove(tmp); return 1; }
    return 0;
}

// ── Objects, made by workers ────────────────────────────────────
// A module is built on the program's one thread and HANDED OVER with its
// context; a worker writes its object and disposes the context, the module
// with it. LLVM is safe a context a thread, and a module here has a context of
// its own. The queue is BOUNDED: a builder that outruns the workers waits, so
// the modules alive are the workers' and a few more.

typedef struct EmitJob { LLVMModuleRef m; LLVMContextRef lc; char* path; int64_t level; struct EmitJob* next; } EmitJob;

static pthread_mutex_t emit_mu = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t emit_work = PTHREAD_COND_INITIALIZER;
static pthread_cond_t emit_room = PTHREAD_COND_INITIALIZER;
static pthread_cond_t emit_idle = PTHREAD_COND_INITIALIZER;
static EmitJob* emit_head = NULL;
static EmitJob* emit_tail = NULL;
static int emit_queued = 0, emit_active = 0, emit_workers = 0, emit_failed = 0;

static void* emit_worker(void* unused) {
    (void)unused;
    for (;;) {
        pthread_mutex_lock(&emit_mu);
        while (!emit_head) pthread_cond_wait(&emit_work, &emit_mu);
        EmitJob* j = emit_head;
        emit_head = j->next;
        if (!emit_head) emit_tail = NULL;
        emit_queued--;
        emit_active++;
        pthread_cond_signal(&emit_room);
        pthread_mutex_unlock(&emit_mu);
        int bad = object_written(j->m, j->path, j->level);
        LLVMContextDispose(j->lc);
        free(j->path);
        free(j);
        pthread_mutex_lock(&emit_mu);
        emit_active--;
        emit_failed += bad;
        if (!emit_head && !emit_active) pthread_cond_broadcast(&emit_idle);
        pthread_mutex_unlock(&emit_mu);
    }
    return NULL;
}

// THE MODULE AND ITS CONTEXT ARE THE WORKERS' FROM HERE: the caller touches
// neither again. `workers` is how many may run at once, heard the first time.
// Answers 0, or 1 when the module could not be handed over — it is disposed
// all the same.
int64_t avra_llvm_emit_object_later(LLVMModuleRef m, LLVMContextRef lc, const char* path, int64_t level, int64_t workers) {
    EmitJob* j = native_target_ready() ? NULL : (EmitJob*)malloc(sizeof(EmitJob));
    char* kept = j ? strdup(path) : NULL;
    if (!kept) { free(j); LLVMContextDispose(lc); return 1; }
    *j = (EmitJob){ m, lc, kept, level, NULL };
    pthread_mutex_lock(&emit_mu);
    while (emit_workers < workers) {
        pthread_t t;
        if (pthread_create(&t, NULL, emit_worker, NULL) != 0) break;
        pthread_detach(t);
        emit_workers++;
    }
    if (emit_workers == 0) {
        pthread_mutex_unlock(&emit_mu);
        int bad = object_written(m, kept, level);
        LLVMContextDispose(lc);
        free(kept);
        free(j);
        return bad;
    }
    while (emit_queued >= 2 * emit_workers) pthread_cond_wait(&emit_room, &emit_mu);
    if (emit_tail) emit_tail->next = j; else emit_head = j;
    emit_tail = j;
    emit_queued++;
    pthread_cond_signal(&emit_work);
    pthread_mutex_unlock(&emit_mu);
    return 0;
}

// EVERY MODULE HANDED OVER, WRITTEN: waits for the workers, and answers how
// many objects were NOT written — counted once, so the next build starts at none.
int64_t avra_llvm_objects_unwritten(void) {
    pthread_mutex_lock(&emit_mu);
    while (emit_head || emit_active) pthread_cond_wait(&emit_idle, &emit_mu);
    int64_t failed = emit_failed;
    emit_failed = 0;
    pthread_mutex_unlock(&emit_mu);
    return failed;
}

int64_t avra_llvm_verify_module_print(LLVMModuleRef m) {
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
    // integer → integer. NARROWING is sign-agnostic and safe here.
    // WIDENING is not: only the CALLER knows whether the value is
    // signed, and a helper named "cast to type" must not guess — an
    // unconditional zero-extend is the C-int defect written in C.
    // The one caller that widens says so at its site.
    if (ak == LLVMIntegerTypeKind && ek == LLVMIntegerTypeKind) {
        unsigned aw = LLVMGetIntTypeWidth(actual);
        unsigned ew = LLVMGetIntTypeWidth(expected);
        if (aw > ew) return LLVMBuildTrunc(b, val, expected, "cast");
        if (aw < ew) avra_trap("cast_to_type asked to WIDEN an integer — the sign is the caller's to name: build_zext or build_sext");
        return val;
    }
    // A REINTERPRETATION, never a conversion, settled by R15a: a value
    // enum's word slot is an i64 whichever payload it carries, so a
    // float payload crossing it is the same 64 bits under a different
    // type. i64 -> double is real and exercised — `Ins.Extract`'s
    // destination cast (llvm_emit.av) reads a value enum's Float
    // payload back this way, and the slot it reads from is always i64,
    // so this always bitcasts. double -> i64 is not reached by
    // anything today: the one caller that packs a float INTO the word
    // slot (`pack_value`'s `valued` branch) goes through `worded`,
    // which bitcasts directly rather than asking this general
    // function. Both narrower-width arms (FPToSI/SIToFP) stay a real
    // NUMERIC conversion, for a narrower float value nothing asks for
    // yet.
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
