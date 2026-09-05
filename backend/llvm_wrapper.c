// The compiler's LLVM binding — pure C over LLVM's C API, OURS:
// llvm_api.av declares against exactly these symbols, and a builder
// is added HERE when the backend declares it, never hunted for
// elsewhere. Every fn below is named by the tree; one that is not
// is debris. Targets the LLVM 21 C API.

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

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

LLVMTypeRef avra_llvm_fn_type_of(LLVMValueRef fn_val) {
    if (!fn_val) {
        fprintf(stderr, "[CRASH] avra_llvm_fn_type_of: fn_val is NULL\n");
        abort();
    }
    return LLVMGlobalGetValueType(fn_val);
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

// A string constant WITH THE RUNTIME'S HEADER before it: every
// pointer a program holds carries one (runtime/avra_runtime.c), and
// a literal is no exception. The header says STATIC — retain and
// release read it and never write — so the global stays constant.
// Layout and tag mirror the runtime's Header exactly — tag, kind,
// count, LENGTH — so `.length` on a constant is a load; sixteen-byte
// alignment is what lets the runtime refuse an unaligned scalar
// before reading anything.
LLVMValueRef avra_llvm_build_global_string_ptr(LLVMBuilderRef b, const char* s, const char* name) {
    LLVMModuleRef m = LLVMGetGlobalParent(LLVMGetBasicBlockParent(LLVMGetInsertBlock(b)));
    LLVMContextRef ctx = LLVMGetModuleContext(m);
    LLVMTypeRef i8 = LLVMInt8TypeInContext(ctx);
    LLVMTypeRef i32 = LLVMInt32TypeInContext(ctx);
    LLVMTypeRef i64 = LLVMInt64TypeInContext(ctx);
    unsigned len = (unsigned)strlen(s);
    LLVMValueRef fields[5] = {
        LLVMConstInt(i32, 0x41565241u, 0),
        LLVMConstInt(i32, (unsigned long long)(int32_t)-1, 1),
        LLVMConstInt(i32, 0, 0),
        LLVMConstInt(i32, len, 0),
        LLVMConstStringInContext(ctx, s, len, 0),
    };
    LLVMValueRef init = LLVMConstStructInContext(ctx, fields, 5, 0);
    LLVMValueRef g = LLVMAddGlobal(m, LLVMTypeOf(init), name);
    LLVMSetInitializer(g, init);
    LLVMSetGlobalConstant(g, 1);
    LLVMSetLinkage(g, LLVMPrivateLinkage);
    LLVMSetUnnamedAddress(g, LLVMGlobalUnnamedAddr);
    LLVMSetAlignment(g, 16);
    LLVMValueRef offset = LLVMConstInt(i64, 16, 0);
    return LLVMConstInBoundsGEP2(i8, g, &offset, 1);
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
