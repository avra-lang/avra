; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"int\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"float\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"string\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"bool\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"List\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"Map\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"string\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"type.lambda\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"a generic fn is not a value \E2\80\94 no single signature to wear\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"declared here\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [25 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 24 }, [25 x i8] c"wrap it \E2\80\94 `(x: T0) -> \00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"f\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [27 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 26 }, [27 x i8] c"(x)` with the types pinned\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"const.cycle\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [38 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 37 }, [38 x i8] c"a const's value asks for its own type\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"` reads itself here\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [86 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 85 }, [86 x i8] c"a const settles from what is written and from other consts \E2\80\94 not from its own value\00" }, align 16

declare void @avra_puts(ptr)

declare i64 @avra_streq(ptr, ptr)

declare void @avra_rc_release(ptr)

declare void @avra_rc_retain(ptr)

declare ptr @avra_array_new()

declare ptr @avra_array_sized(i64)

declare void @avra_array_push(ptr, i64)

declare void @avra_array_push_owned(ptr, ptr)

declare i64 @avra_array_get(ptr, i64)

declare ptr @avra_array_get_owned(ptr, i64)

declare void @avra_cell_release(ptr)

declare ptr @avra_cell_unique(ptr)

declare ptr @avra_map_new()

declare i64 @avra_map_len(ptr)

declare i64 @avra_map_has(ptr, ptr)

declare i64 @avra_map_get(ptr, ptr)

declare ptr @avra_map_get_owned(ptr, ptr)

declare void @avra_map_set(ptr, ptr, i64)

declare void @avra_map_set_owned(ptr, ptr, ptr)

declare ptr @avra_slot_unique(ptr, i64)

declare void @avra_slot_set(ptr, i64, i64)

declare void @avra_slot_set_owned(ptr, i64, ptr)

declare i64 @avra_array_len(ptr)

declare ptr @avra_once_get(ptr)

declare void @avra_once_set(ptr, ptr)

declare ptr @avra_str_join(ptr, ptr)

declare ptr @avra_insist(ptr)

declare i64 @avra_insist_scalar(i64, i64)

declare ptr @avra_str_crossing(ptr)

declare i64 @avra_int_div(i64, i64)

declare i64 @avra_int_mod(i64, i64)

declare ptr @avra_float_text(double)

declare ptr @avra_float_text_bits(i64)

declare i64 @avra_int_and(i64, i64)

declare i64 @avra_int_or(i64, i64)

declare i64 @avra_int_xor(i64, i64)

declare i64 @avra_int_not(i64)

declare i64 @avra_int_shl(i64, i64)

declare i64 @avra_int_shr(i64, i64)

declare ptr @avra_int_text(i64)

declare ptr @avra_bool_text(i64)

declare ptr @avra_ints_text(ptr)

declare ptr @avra_bools_text(ptr)

declare ptr @avra_strs_text(ptr)

declare i64 @avra_str_len(ptr)

declare i64 @avra_array_pop(ptr)

declare ptr @avra_array_pop_owned(ptr)

declare ptr @avra_array_concat(ptr, ptr)

declare ptr @avra_array_slice(ptr, i64, i64)

declare i64 @avra_str_contains(ptr, ptr)

declare i64 @avra_str_starts_with(ptr, ptr)

declare i64 @avra_str_ends_with(ptr, ptr)

declare i64 @avra_str_index_of(ptr, ptr)

declare ptr @avra_str_substring(ptr, i64, i64)

declare ptr @avra_str_split(ptr, ptr)

declare ptr @avra_str_replace(ptr, ptr, ptr)

declare i64 @avra_str_char_code(ptr, i64)

declare ptr @avra_str_trim(ptr)

declare i64 @avra_bytes_len(ptr)

declare i64 @avra_bytes_eq(ptr, ptr)

declare i64 @avra_bytes_at(ptr, i64)

declare ptr @avra_bytes_slice(ptr, i64, i64)

declare ptr @avra_bytes_concat(ptr, ptr)

declare i64 @avra_bytes_index_of(ptr, ptr, i64)

declare ptr @avra_bytes_of_str(ptr)

declare ptr @avra_bytes_of_list(ptr)

declare ptr @avra_str_of_bytes(ptr)

declare i64 @avra_utf8_bad_at(ptr)

declare i64 @avra_bytes_run(ptr, i64, ptr)

declare i64 @avra_bytes_eq_at(ptr, i64, i64, ptr)

declare i64 @avra_bytes_ieq_at(ptr, i64, i64, ptr)

declare ptr @avra_bytes_gathered(ptr)

declare ptr @avra_bytes_adopted(ptr, i64)

declare i64 @avra_fd_read(i64, i64)

declare ptr @avra_fd_taken(i64)

declare i64 @avra_fd_write(i64, ptr, i64)

declare ptr @avra_str_concat(ptr, ptr)

declare ptr @avra_errno_text(i64)

declare i64 @avra_now_ns()

declare ptr @avra_host_env(ptr)

declare ptr @avra_selfhost_read_file(ptr)

declare void @avra_eputs(ptr)

declare i64 @avra_io_list(ptr)

declare ptr @avra_str_from_codepoint(i64)

declare ptr @avra_embed(ptr)

declare i64 @avra_exec_self(ptr)

declare i64 @avra_spawn_status(ptr, ptr)

declare i64 @avra_spawn_in(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Espeak"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Espeak"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ediagnostics$2EVoices$2Espeak"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Estmt_loc"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Estmt_loc"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2Esame_decl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_fns"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_of"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Estore_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efn_name"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_named"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr %boxed, ptr %2)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_trait"(ptr %0, ptr %5)
  %not1 = xor i1 %6, true
  call void @avra_rc_release(ptr %5)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  br label %endif4
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_trait"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Eenum_sig"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eself_type_of"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %0, ptr %1)
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Einstance_vars"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_trait"(ptr %0, ptr %1)
  br i1 %5, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 0)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call i64 @avra_array_len(ptr %4)
  %cmp = icmp eq i64 %7, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif

then1:                                            ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %9, i64 8)
  call void @avra_array_push_owned(ptr %9, ptr %1)
  call void @avra_array_push_owned(ptr %9, ptr %3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %11 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_enum"(ptr %0, ptr %1)
  br i1 %11, label %then6, label %else7

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endif3

then6:                                            ; preds = %endif3
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed9 = inttoptr i64 %12 to ptr
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 7)
  call void @avra_array_push_owned(ptr %13, ptr %1)
  call void @avra_array_push_owned(ptr %13, ptr %3)
  call void @avra_rc_retain(ptr %boxed9)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed9, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else7:                                            ; preds = %endif3
  br label %endif8

endif8:                                           ; preds = %else7, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else7 ]
  %15 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed12 = inttoptr i64 %15 to ptr
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 6)
  call void @avra_array_push_owned(ptr %16, ptr %1)
  call void @avra_array_push_owned(ptr %16, ptr %3)
  call void @avra_rc_retain(ptr %boxed12)
  call void @avra_rc_retain(ptr %16)
  %17 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed12, ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  br label %endif8
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_enum"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Einstance_vars"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etparams"(ptr %0, ptr %1)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %7, i64 21)
  call void @avra_array_push_owned(ptr %7, ptr %1)
  call void @avra_array_push(ptr %7, i64 %ld1)
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed2, ptr %7)
  call void @avra_array_push_owned(ptr %2, ptr %8)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etparams"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_named"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Erecord_sig"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Erides_pointer"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Esubstituted"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eloc"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Escalar_named"(ptr %0) {
entry:
  %1 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %b = icmp ne i64 %1, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %b1 = icmp ne i64 %3, 0
  br i1 %b1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval15 = phi ptr [ %2, %then ], [ %regval14, %endif4 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %regval15

then2:                                            ; preds = %else
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 1)
  br label %endif4

else3:                                            ; preds = %else
  %5 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %b5 = icmp ne i64 %5, 0
  br i1 %b5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval14 = phi ptr [ %4, %then2 ], [ %regval13, %endif8 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif

then6:                                            ; preds = %else3
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 3)
  br label %endif8

else7:                                            ; preds = %else3
  %7 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %b9 = icmp ne i64 %7, 0
  br i1 %b9, label %then10, label %else11

endif8:                                           ; preds = %endif12, %then6
  %regval13 = phi ptr [ %6, %then6 ], [ %regval, %endif12 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif4

then10:                                           ; preds = %else7
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  br label %endif12

else11:                                           ; preds = %else7
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval = phi ptr [ %8, %then10 ], [ null, %else11 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif8
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ewritten_seats"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Etakes_a_seat"(ptr %0, ptr %4)
  br i1 %5, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_array_push_owned(ptr %2, ptr %4)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Etakes_a_seat"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %cmp = icmp ne ptr %boxed, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

endif:                                            ; preds = %lexit, %then
  %regval10 = phi i1 [ true, %then ], [ %not, %lexit ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval10

lhead:                                            ; preds = %endif7, %else
  %ld = load i64, ptr %slot1, align 8
  %cmp2 = icmp slt i64 %ld, %4
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld9 = load i1, ptr %slot, align 8
  %not = xor i1 %ld9, true
  call void @avra_rc_release(ptr %3)
  br label %endif

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %0, i64 %ld3)
  %boxed4 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_streq(ptr %boxed4, ptr %3)
  %b = icmp ne i64 %6, 0
  br i1 %b, label %then5, label %else6

then5:                                            ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif7

else6:                                            ; preds = %lbody
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  %ld8 = load i64, ptr %slot1, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edeclared_decl"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm2 [
    i64 6, label %arm
    i64 7, label %arm1
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ %3, %arm1 ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Esame_stmt"(i64, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Einterned"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esymbol"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_extern"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Edefect"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed1, ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %2, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_through"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eshape_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Etype_at"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eviewed"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eviewed"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eviewed"(ptr %boxed, ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eviewed"(ptr %0, ptr %1, ptr %2) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %1)
  %6 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Esubstituted"(ptr %0, ptr %2, ptr %boxed, ptr %boxed1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Esymbol_at"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emarks_of"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Evariants_of_type"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm3 [
    i64 7, label %arm
    i64 13, label %arm1
    i64 8, label %arm2
  ]

arm:                                              ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed4 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed4)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %0, ptr %boxed4)
  %cmp = icmp ne ptr %6, null
  br i1 %cmp, label %then, label %else

arm1:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  %8 = call i64 @avra_array_get(ptr %3, i64 2)
  %boxed5 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %boxed5)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eres_enum_sig"(ptr %7, ptr %boxed5)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

arm2:                                             ; preds = %entry
  %10 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  %11 = call ptr @avra_array_get_owned(ptr %3, i64 3)
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %0, ptr %10)
  %cmp6 = icmp ne ptr %13, null
  br i1 %cmp6, label %then7, label %else8

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %endif9, %arm1, %endif
  %regval11 = phi ptr [ %regval, %endif ], [ %9, %arm1 ], [ %16, %endif9 ], [ null, %arm3 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval11

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %6)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Eenum_sig"(ptr %6)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %14, %then ], [ null, %else ]
  call void @avra_rc_release(ptr %6)
  br label %endswitch

then7:                                            ; preds = %arm2
  call void @avra_rc_retain(ptr %13)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Eenum_sig"(ptr %13)
  br label %endif9

else8:                                            ; preds = %arm2
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval10 = phi ptr [ %15, %then7 ], [ null, %else8 ]
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %regval10)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %11)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esubbed_variants"(ptr %12, ptr %regval10, ptr %10, ptr %11)
  call void @avra_rc_release(ptr %regval10)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endswitch
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esubbed_variants"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eres_enum_sig"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm2 [
    i64 6, label %arm
    i64 8, label %arm1
  ]

arm:                                              ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed3 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed3)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %0, ptr %boxed3)
  %cmp = icmp ne ptr %6, null
  br i1 %cmp, label %then, label %else

arm1:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %3, i64 3)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %0, ptr %7)
  %cmp4 = icmp ne ptr %10, null
  br i1 %cmp4, label %then5, label %else6

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif7, %endif
  %regval9 = phi ptr [ %regval, %endif ], [ %13, %endif7 ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval9

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %6)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Erecord_sig"(ptr %6)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %11, %then ], [ null, %else ]
  call void @avra_rc_release(ptr %6)
  br label %endswitch

then5:                                            ; preds = %arm1
  call void @avra_rc_retain(ptr %10)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Erecord_sig"(ptr %10)
  br label %endif7

else6:                                            ; preds = %arm1
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi ptr [ %12, %then5 ], [ null, %else6 ]
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %regval8)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esubbed_fields"(ptr %9, ptr %regval8, ptr %7, ptr %8)
  call void @avra_rc_release(ptr %regval8)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esubbed_fields"(ptr, ptr, ptr, ptr)

declare { i1, i1 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebool_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Etext_of"(ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebits_of"(ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eint_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Esubst_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Edefect"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Enarrowed_at"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eslot_of"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Espelled_type"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Espelled_plain"(ptr %0, ptr %2)
  %cmp1 = icmp ne ptr %3, null
  %not2 = xor i1 %cmp1, true
  br i1 %not2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %b = icmp ne i64 %5, 0
  %not8 = xor i1 %b, true
  br i1 %not8, label %then9, label %else10

postret6:                                         ; No predecessors!
  br label %endif5

then9:                                            ; preds = %endif5
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else10:                                           ; preds = %endif5
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %6 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Erides_pointer"(ptr %0, ptr %4)
  %not14 = xor i1 %6, true
  br i1 %not14, label %then15, label %else16

postret12:                                        ; No predecessors!
  br label %endif11

then15:                                           ; preds = %endif11
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else16:                                           ; preds = %endif11
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 13)
  call void @avra_array_push_owned(ptr %7, ptr %4)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 7)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret18:                                        ; No predecessors!
  br label %endif17
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Espelled_plain"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Escalar_named"(ptr %boxed1)
  %cmp2 = icmp ne ptr %5, null
  %not = xor i1 %cmp2, true
  br i1 %not, label %then3, label %else4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval6 = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %6)
  %cmp7 = icmp slt i64 0, %7
  br i1 %cmp7, label %then8, label %else9

then3:                                            ; preds = %then
  br label %endif5

else4:                                            ; preds = %then
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %0, ptr %5)
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval = phi ptr [ null, %then3 ], [ %8, %else4 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %5)
  br label %endif

then8:                                            ; preds = %endif
  %sub = sub i64 %7, 1
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 %sub)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  br label %endif10

else9:                                            ; preds = %endif
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i64 [ 0, %then8 ], [ 0, %else9 ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Espelled_type"(ptr %0, ptr %ld)
  %cmp12 = icmp ne ptr %10, null
  %not13 = xor i1 %cmp12, true
  br i1 %not13, label %then14, label %else15

then14:                                           ; preds = %endif10
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %11 = call ptr @avra_insist(ptr %10)
  %12 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %13 = call i64 @avra_streq(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %b = icmp ne i64 %13, 0
  br i1 %b, label %then19, label %else20

postret17:                                        ; No predecessors!
  br label %endif16

then19:                                           ; preds = %endif16
  %14 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed22 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_len(ptr %boxed22)
  %cmp23 = icmp eq i64 %15, 1
  br i1 %cmp23, label %then24, label %else25

else20:                                           ; preds = %endif16
  %16 = call i64 @avra_streq(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %b28 = icmp ne i64 %16, 0
  br i1 %b28, label %then29, label %else30

endif21:                                          ; preds = %endif31, %endif26
  %regval45 = phi ptr [ %regval27, %endif26 ], [ %regval44, %endif31 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval45

then24:                                           ; preds = %then19
  %17 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %17, i64 13)
  call void @avra_array_push_owned(ptr %17, ptr %11)
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 8)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %0, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %endif26

else25:                                           ; preds = %then19
  br label %endif26

endif26:                                          ; preds = %else25, %then24
  %regval27 = phi ptr [ %19, %then24 ], [ null, %else25 ]
  br label %endif21

then29:                                           ; preds = %else20
  %20 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed32 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_len(ptr %boxed32)
  %cmp33 = icmp eq i64 %21, 2
  br i1 %cmp33, label %then34, label %else35

else30:                                           ; preds = %else20
  br label %endif31

endif31:                                          ; preds = %else30, %endif42
  %regval44 = phi ptr [ %regval43, %endif42 ], [ null, %else30 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif21

then34:                                           ; preds = %then29
  %22 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed37 = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_array_get(ptr %boxed37, i64 0)
  %boxed38 = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %boxed38)
  %24 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ekeyed_by_text"(ptr %boxed38)
  br label %endif36

else35:                                           ; preds = %then29
  br label %endif36

endif36:                                          ; preds = %else35, %then34
  %regval39 = phi i1 [ %24, %then34 ], [ false, %else35 ]
  br i1 %regval39, label %then40, label %else41

then40:                                           ; preds = %endif36
  %25 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %25, i64 3)
  %26 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %26, i64 13)
  call void @avra_array_push_owned(ptr %26, ptr %11)
  %27 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %27, i64 10)
  call void @avra_array_push_owned(ptr %27, ptr %25)
  call void @avra_array_push_owned(ptr %27, ptr %26)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %0, ptr %27)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  br label %endif42

else41:                                           ; preds = %endif36
  br label %endif42

endif42:                                          ; preds = %else41, %then40
  %regval43 = phi ptr [ %28, %then40 ], [ null, %else41 ]
  br label %endif31
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ekeyed_by_text"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_streq(ptr %boxed, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed1)
  %cmp = icmp eq i64 %4, 0
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %b5 = icmp ne i64 %5, 0
  %not = xor i1 %b5, true
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ %not, %then2 ], [ false, %else3 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i1 %regval6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm2 [
    i64 7, label %arm
    i64 2, label %arm1
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %endif
  br label %endswitch

arm2:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval3 = phi ptr [ %5, %arm ], [ null, %arm1 ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ego_hungry"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Etype_at"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewiden"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ewiden"(ptr %boxed, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ewiden"(ptr, i64, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp = icmp eq i64 %5, 22
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etbounds"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eimplements"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %3, i64 5)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call i64 @avra_array_get(ptr %5, i64 4)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %8 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eimplements_of"(ptr %boxed, ptr %boxed1, ptr %boxed2, ptr %1, ptr %2)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %8
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimplements_of"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edyn_contract"(ptr %5)
  %cmp = icmp ne ptr %6, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %7 = call ptr @avra_insist(ptr %6)
  %8 = call i64 @avra_streq(ptr %7, ptr %4)
  %b = icmp ne i64 %8, 0
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edeclared_decl"(ptr %9)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_named"(ptr %1, ptr %2, ptr %4)
  %cmp1 = icmp ne ptr %10, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %7)
  br label %endif

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %cmp5 = icmp ne ptr %11, null
  %not6 = xor i1 %cmp5, true
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval7 = phi i1 [ true, %then2 ], [ %not6, %else3 ]
  br i1 %regval7, label %then8, label %else9

then8:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  %12 = call ptr @avra_insist(ptr %10)
  %13 = call ptr @avra_insist(ptr %11)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %13)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eimplements"(ptr %1, ptr %12, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %14

postret11:                                        ; No predecessors!
  br label %endif10
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eimplements"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edyn_contract"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm1 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estarve"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Estarve"(ptr %boxed, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Estarve"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eabsorb_hunger"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_type_of"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %0, ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 4)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %cmp = icmp eq i64 %6, 12
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edeclared_const_type"(ptr %0, ptr %1, ptr %2, ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etype_name"(ptr %0, ptr %3)
  %cmp1 = icmp ne ptr %8, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %7)
  br label %endif

then2:                                            ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed5 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_insist(ptr %8)
  %11 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %11, i64 20)
  call void @avra_array_push_owned(ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed5, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etparams"(ptr %0, ptr %3)
  %14 = call i64 @avra_array_len(ptr %13)
  %cmp8 = icmp eq i64 %14, 0
  %not = xor i1 %cmp8, true
  br i1 %not, label %then9, label %else10

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif4

then9:                                            ; preds = %endif4
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Enot_a_value"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Ediagnostics$2EVoices$2Espeak"(ptr %1, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else10:                                           ; preds = %endif4
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %0, ptr %3)
  %cmp14 = icmp ne ptr %17, null
  br i1 %cmp14, label %then15, label %else16

postret12:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  br label %endif11

then15:                                           ; preds = %endif11
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %17)
  br label %endif17

else16:                                           ; preds = %endif11
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval18 = phi ptr [ %18, %then15 ], [ null, %else16 ]
  %cmp19 = icmp ne ptr %regval18, null
  %not20 = xor i1 %cmp19, true
  br i1 %not20, label %then21, label %else22

then21:                                           ; preds = %endif17
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else22:                                           ; preds = %endif17
  br label %endif23

endif23:                                          ; preds = %else22, %postret24
  %regval25 = phi i64 [ 0, %postret24 ], [ 0, %else22 ]
  %19 = call ptr @avra_insist(ptr %regval18)
  %20 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %21 = call ptr @avra_array_get_owned(ptr %19, i64 0)
  %22 = call i64 @avra_array_get(ptr %19, i64 0)
  %boxed26 = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_array_len(ptr %boxed26)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emarks_of"(ptr %0, ptr %3, i64 %23)
  %25 = call i64 @avra_array_get(ptr %19, i64 1)
  %boxed27 = inttoptr i64 %25 to ptr
  %26 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %26, i64 14)
  call void @avra_array_push_owned(ptr %26, ptr %21)
  call void @avra_array_push_owned(ptr %26, ptr %24)
  call void @avra_array_push_owned(ptr %26, ptr %boxed27)
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %26)
  %27 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %20, ptr %26)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %27

postret24:                                        ; No predecessors!
  br label %endif23
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Enot_a_value"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eloc"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efn_name"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %3, %then ], [ getelementptr inbounds (i8, ptr @.str.11, i64 16), %else ]
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %regval)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr %2, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etype_name"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edeclared_const_type"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %0, ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 1)
  %6 = call i64 @avra_array_get(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Econst_answer"(ptr %0, i64 %5, i64 %6)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm2 [
    i64 0, label %arm
    i64 1, label %arm1
  ]

arm:                                              ; preds = %entry
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %2)
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eself_referent"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Ediagnostics$2EVoices$2Espeak"(ptr %1, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_retain(ptr %2)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %9, %arm ], [ %2, %arm1 ], [ %2, %arm2 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eself_referent"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eloc"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %0, ptr %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %boxed)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  %6 = call ptr @avra_str_join(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16), ptr %2, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16), ptr %6, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Econst_answer"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Estore_of"(ptr %0, i64 %1)
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esettled_type"(ptr %3, ptr %boxed, i64 %2)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Econst_type"(ptr %0, i64 %1, i64 %2)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Econst_type"(ptr, i64, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esettled_type"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eliteral_shape"(ptr %6)
  %cmp1 = icmp ne ptr %7, null
  %not2 = xor i1 %cmp1, true
  br i1 %not2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Espelled_type"(ptr %1, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %10 = call ptr @avra_insist(ptr %7)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %1, ptr %10)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %0, i64 %2)
  %cmp8 = icmp ne ptr %12, null
  br i1 %cmp8, label %then9, label %else10

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endif5

then9:                                            ; preds = %endif5
  %13 = call i64 @avra_array_get(ptr %12, i64 2)
  %b = icmp ne i64 %13, 0
  %pack = insertvalue { i1, i1 } { i1 true, i1 undef }, i1 %b, 1
  br label %endif11

else10:                                           ; preds = %endif5
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval12 = phi { i1, i1 } [ %pack, %then9 ], [ zeroinitializer, %else10 ]
  %x = extractvalue { i1, i1 } %regval12, 0
  br i1 %x, label %then13, label %else14

then13:                                           ; preds = %endif11
  %x16 = extractvalue { i1, i1 } %regval12, 1
  br label %endif15

else14:                                           ; preds = %endif11
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval17 = phi i1 [ %x16, %then13 ], [ false, %else14 ]
  br i1 %regval17, label %then18, label %else19

then18:                                           ; preds = %endif15
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 13)
  call void @avra_array_push_owned(ptr %14, ptr %11)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 7)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %1, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else19:                                           ; preds = %endif15
  br label %endif20

endif20:                                          ; preds = %else19, %postret21
  %regval22 = phi i64 [ 0, %postret21 ], [ 0, %else19 ]
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

postret21:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  br label %endif20
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eliteral_shape"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eint_of"(ptr %0)
  %x = extractvalue { i1, i64 } %1, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Etext_of"(ptr %0)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %2)
  br label %endif

then1:                                            ; preds = %endif
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  %5 = call { i1, i1 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebool_of"(ptr %0)
  %x6 = extractvalue { i1, i1 } %5, 0
  br i1 %x6, label %then7, label %else8

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif3

then7:                                            ; preds = %endif3
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else8:                                            ; preds = %endif3
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebits_of"(ptr %0)
  %x12 = extractvalue { i1, i64 } %7, 0
  br i1 %x12, label %then13, label %else14

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif9

then13:                                           ; preds = %endif9
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else14:                                           ; preds = %endif9
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

postret16:                                        ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif15
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edef_type_of"(ptr %2, ptr %3, ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edef_type_of"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr %boxed, i64 %3)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 4)
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %6)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etype_of_const"(ptr %6, i64 %7, i64 %3)
  %cmp1 = icmp ne ptr %8, null
  br i1 %cmp1, label %then2, label %else3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Edeclared_binding"(ptr %0, i64 %3)
  %cmp6 = icmp ne ptr %9, null
  br i1 %cmp6, label %then7, label %else8

then2:                                            ; preds = %then
  call void @avra_rc_retain(ptr %8)
  br label %endif4

else3:                                            ; preds = %then
  call void @avra_rc_retain(ptr %2)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi ptr [ %8, %then2 ], [ %2, %else3 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  br label %endif

then7:                                            ; preds = %endif
  %10 = call ptr @avra_insist(ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  %11 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed12 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed12)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed12, i64 %3)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp13 = icmp eq i64 %13, 15
  br i1 %cmp13, label %then14, label %else15

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif9

then14:                                           ; preds = %endif9
  %14 = call i64 @avra_array_get(ptr %1, i64 5)
  %boxed17 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 0)
  call void @avra_rc_retain(ptr %boxed17)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed17, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else15:                                           ; preds = %endif9
  br label %endif16

endif16:                                          ; preds = %else15, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else15 ]
  %17 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed20 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed20)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed20, i64 %3)
  %cmp21 = icmp ne ptr %18, null
  %not = xor i1 %cmp21, true
  br i1 %not, label %then22, label %else23

postret18:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  br label %endif16

then22:                                           ; preds = %endif16
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else23:                                           ; preds = %endif16
  br label %endif24

endif24:                                          ; preds = %else23, %postret25
  %regval26 = phi i64 [ 0, %postret25 ], [ 0, %else23 ]
  %19 = call ptr @avra_insist(ptr %18)
  %20 = call i64 @avra_array_get(ptr %19, i64 0)
  call void @avra_rc_retain(ptr %0)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Etype_at"(ptr %0, i64 %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %21

postret25:                                        ; No predecessors!
  br label %endif24
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Edeclared_binding"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etype_of_const"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Econst_answer"(ptr %0, i64 %1, i64 %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_member"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Econtexts$24l145" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %0)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_fns"(ptr %0, ptr %1)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %7)
  %cast = inttoptr i64 %4 to ptr
  %8 = call i1 %cast(ptr %3, ptr %7)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Econtexts$24l145"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_named"(ptr %2, ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_named"(ptr, ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eshape_at"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %3, 22
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eshape_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebound_decl"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efield_type_named"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr %4, ptr %2)
  %x = extractvalue { i1, i64 } %5, 0
  %not1 = xor i1 %x, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %6 = call ptr @avra_insist(ptr %3)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %x7 = extractvalue { i1, i64 } %5, 0
  %x8 = extractvalue { i1, i64 } %5, 1
  %slot = zext i1 %x7 to i64
  %8 = call i64 @avra_insist_scalar(i64 %slot, i64 %x8)
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret5:                                         ; No predecessors!
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewant_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ewant_at"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ewant_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eis_boxed"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ego_hungry"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ego_hungry"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estarved_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Estarved_at"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Estarved_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eabsorb_hunger"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eabsorb_hunger"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esame_binding"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %2, label %arm7 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %4, label %arm9 [
    i64 0, label %arm8
  ]

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp11 = icmp eq i64 %5, 1
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %7, label %arm13 [
    i64 2, label %arm12
  ]

arm3:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %10 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %10, label %arm17 [
    i64 3, label %arm16
  ]

arm4:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %13, label %arm23 [
    i64 4, label %arm22
  ]

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %16, label %arm32 [
    i64 5, label %arm31
  ]

arm6:                                             ; preds = %entry
  %17 = call i64 @avra_array_get(ptr %0, i64 1)
  %18 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %18, label %arm41 [
    i64 6, label %arm40
  ]

arm7:                                             ; preds = %entry
  %19 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %20, label %arm45 [
    i64 7, label %arm44
  ]

endswitch:                                        ; preds = %endswitch46, %endswitch42, %endswitch33, %endswitch24, %endswitch18, %endswitch14, %arm1, %endswitch10
  %regval48 = phi i1 [ %regval, %endswitch10 ], [ %cmp11, %arm1 ], [ %regval15, %endswitch14 ], [ %regval21, %endswitch18 ], [ %regval30, %endswitch24 ], [ %regval39, %endswitch33 ], [ %regval43, %endswitch42 ], [ %regval47, %endswitch46 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval48

arm8:                                             ; preds = %arm
  %21 = call i64 @avra_array_get(ptr %1, i64 1)
  %cmp = icmp eq i64 %3, %21
  br label %endswitch10

arm9:                                             ; preds = %arm
  br label %endswitch10

endswitch10:                                      ; preds = %arm9, %arm8
  %regval = phi i1 [ %cmp, %arm8 ], [ false, %arm9 ]
  br label %endswitch

arm12:                                            ; preds = %arm2
  %22 = call i64 @avra_array_get(ptr %1, i64 1)
  %23 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_stmt"(i64 %6, i64 %22)
  br label %endswitch14

arm13:                                            ; preds = %arm2
  br label %endswitch14

endswitch14:                                      ; preds = %arm13, %arm12
  %regval15 = phi i1 [ %23, %arm12 ], [ false, %arm13 ]
  br label %endswitch

arm16:                                            ; preds = %arm3
  %24 = call i64 @avra_array_get(ptr %1, i64 1)
  %25 = call i64 @avra_array_get(ptr %1, i64 2)
  %26 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_expr"(i64 %8, i64 %24)
  br i1 %26, label %then, label %else

arm17:                                            ; preds = %arm3
  br label %endswitch18

endswitch18:                                      ; preds = %arm17, %endif
  %regval21 = phi i1 [ %regval20, %endif ], [ false, %arm17 ]
  br label %endswitch

then:                                             ; preds = %arm16
  %cmp19 = icmp eq i64 %9, %25
  br label %endif

else:                                             ; preds = %arm16
  br label %endif

endif:                                            ; preds = %else, %then
  %regval20 = phi i1 [ %cmp19, %then ], [ false, %else ]
  br label %endswitch18

arm22:                                            ; preds = %arm4
  %27 = call i64 @avra_array_get(ptr %1, i64 1)
  %28 = call i64 @avra_array_get(ptr %1, i64 2)
  %29 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_expr"(i64 %11, i64 %27)
  br i1 %29, label %then25, label %else26

arm23:                                            ; preds = %arm4
  br label %endswitch24

endswitch24:                                      ; preds = %arm23, %endif27
  %regval30 = phi i1 [ %regval29, %endif27 ], [ false, %arm23 ]
  br label %endswitch

then25:                                           ; preds = %arm22
  %cmp28 = icmp eq i64 %12, %28
  br label %endif27

else26:                                           ; preds = %arm22
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval29 = phi i1 [ %cmp28, %then25 ], [ false, %else26 ]
  br label %endswitch24

arm31:                                            ; preds = %arm5
  %30 = call i64 @avra_array_get(ptr %1, i64 1)
  %31 = call i64 @avra_array_get(ptr %1, i64 2)
  %32 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_expr"(i64 %14, i64 %30)
  br i1 %32, label %then34, label %else35

arm32:                                            ; preds = %arm5
  br label %endswitch33

endswitch33:                                      ; preds = %arm32, %endif36
  %regval39 = phi i1 [ %regval38, %endif36 ], [ false, %arm32 ]
  br label %endswitch

then34:                                           ; preds = %arm31
  %cmp37 = icmp eq i64 %15, %31
  br label %endif36

else35:                                           ; preds = %arm31
  br label %endif36

endif36:                                          ; preds = %else35, %then34
  %regval38 = phi i1 [ %cmp37, %then34 ], [ false, %else35 ]
  br label %endswitch33

arm40:                                            ; preds = %arm6
  %33 = call i64 @avra_array_get(ptr %1, i64 1)
  %34 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_stmt"(i64 %17, i64 %33)
  br label %endswitch42

arm41:                                            ; preds = %arm6
  br label %endswitch42

endswitch42:                                      ; preds = %arm41, %arm40
  %regval43 = phi i1 [ %34, %arm40 ], [ false, %arm41 ]
  br label %endswitch

arm44:                                            ; preds = %arm7
  %35 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %35 to ptr
  call void @avra_rc_retain(ptr %19)
  call void @avra_rc_retain(ptr %boxed)
  %36 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_decl"(ptr %19, ptr %boxed)
  br label %endswitch46

arm45:                                            ; preds = %arm7
  br label %endswitch46

endswitch46:                                      ; preds = %arm45, %arm44
  %regval47 = phi i1 [ %36, %arm44 ], [ false, %arm45 ]
  call void @avra_rc_release(ptr %19)
  br label %endswitch
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Esame_expr"(i64, i64)

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eis_mut"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eis_mut_at"(ptr %2, ptr %boxed1, i64 %1)
  br i1 %5, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eheard_mut_at"(ptr %0, i64 %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eheard_mut_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm1 [
    i64 4, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call i64 @avra_array_get(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eheard_mut"(ptr %0, i64 %6, i64 %7)
  br label %endswitch

arm1:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval2 = phi i1 [ %8, %arm ], [ false, %arm1 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval2
}

declare i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eheard_mut"(ptr, i64, i64)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eis_mut_at"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp1 = icmp eq i64 %5, 2
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %1, i64 %6)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp5 = icmp eq i64 %8, 1
  call void @avra_rc_release(ptr %7)
  br label %endif4

else3:                                            ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp6 = icmp eq i64 %9, 1
  br i1 %cmp6, label %then7, label %else8

endif4:                                           ; preds = %endif9, %then2
  %regval21 = phi i1 [ %cmp5, %then2 ], [ %regval20, %endif9 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval21

then7:                                            ; preds = %else3
  br label %endif9

else8:                                            ; preds = %else3
  %10 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp10 = icmp eq i64 %10, 0
  br i1 %cmp10, label %then11, label %else12

endif9:                                           ; preds = %endif18, %then7
  %regval20 = phi i1 [ true, %then7 ], [ %regval19, %endif18 ]
  br label %endif4

then11:                                           ; preds = %else8
  br label %endif13

else12:                                           ; preds = %else8
  %11 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp14 = icmp eq i64 %11, 4
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i1 [ true, %then11 ], [ %cmp14, %else12 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif13
  call void @avra_rc_retain(ptr %0)
  %12 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ereads_mut_seat"(ptr %0, i64 %2)
  br label %endif18

else17:                                           ; preds = %endif13
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval19 = phi i1 [ %12, %then16 ], [ false, %else17 ]
  br label %endif9
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ereads_mut_seat"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Evariants_of_type"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_subst"(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Erecord_subst"(ptr %boxed, i64 %1, ptr %2, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Erecord_subst"(ptr, i64, ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Emethod_sig"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod_sig_of"(ptr %boxed1, ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod_sig_of"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %0, ptr %1, ptr %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %0, ptr %4)
  %cmp1 = icmp ne ptr %5, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %5)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %6, %then2 ], [ null, %else3 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evariants_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Evariants_of_type"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_index"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_index"(ptr %boxed, i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_index"(ptr, i64, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_slot"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_slot"(ptr %boxed, i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_slot"(ptr, i64, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_binding"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Erecord_binding"(ptr %boxed, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Erecord_binding"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseen_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eenclosing_ret"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 10)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecell_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm1 [
    i64 2, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %8 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eis_boxed"(ptr %boxed2, i64 %6)
  br i1 %8, label %then3, label %else4

arm1:                                             ; preds = %endif
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif5
  %regval8 = phi ptr [ %regval7, %endif5 ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval8

then3:                                            ; preds = %arm
  %9 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed6 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eslot_of"(ptr %boxed6, i64 %6)
  br label %endif5

else4:                                            ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval7 = phi ptr [ %10, %then3 ], [ null, %else4 ]
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efields_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_like"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Etype_of_reg"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %2, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Etype_of_reg"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_sig"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_of"(ptr %boxed, i64 %5, i64 %1)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 4)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_insist(ptr %6)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed3, ptr %9)
  %cmp4 = icmp ne ptr %10, null
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %10)
  br label %endif7

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi ptr [ %11, %then5 ], [ null, %else6 ]
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_patterns"(ptr %boxed, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_patterns"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Evariants_of_type"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebind_types"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ebind_types"(ptr %boxed, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ebind_types"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Enarrowed_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Enarrowed_at"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Epat_loc"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Epat_loc"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Epat_loc"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etparams"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etparams"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecallee_of"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Esymbol_at"(ptr %0, ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eextern_callee"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %6)
  %7 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_extern"(ptr %boxed2, ptr %6)
  %not3 = xor i1 %7, true
  call void @avra_rc_release(ptr %6)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not3, %else ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret
  %regval7 = phi i64 [ 0, %postret ], [ 0, %else5 ]
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed8 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed8, i64 4)
  %boxed9 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %boxed9)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esymbol"(ptr %boxed9, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

postret:                                          ; No predecessors!
  br label %endif6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Esubst_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Esubst_at"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etbounds"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etbounds"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_name_decl"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm1 [
    i64 20, label %arm
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Esig_of"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esig_of_at"(ptr %2, ptr %boxed1, i64 %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esig_of_at"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %1, ptr %4)
  %cmp1 = icmp ne ptr %5, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %5)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %6, %then2 ], [ null, %else3 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eask_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eask_of"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eask_of"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_through"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseen"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_through"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_ask"(ptr %0, i64 %1, i64 %2, i1 %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Erecord_ask"(ptr %boxed, i64 %1, i64 %2, i1 %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Erecord_ask"(ptr, i64, i64, i1)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etest_regs_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Etest_regs_of"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Etest_regs_of"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_test"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_test"(ptr %boxed, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ebind_test"(ptr, i64, ptr)
