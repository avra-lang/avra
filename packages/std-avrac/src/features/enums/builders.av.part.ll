; ModuleID = 'avra'
source_filename = "avra"

@"av_const$90$115" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 2, i64 2, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] }, ptr @"av_const$90$115", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] }, ptr @"av_const$90$115", i32 0, i32 3), ptr null }, [2 x i64] zeroinitializer, [2 x i8] zeroinitializer }, align 16
@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"rest\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [82 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 81 }, [82 x i8] c"defect: an enum declaration without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Egrammar$2EToken$2Eint_value"(ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr_node"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ewindow_end"(ptr, i64, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eref_within"(ptr, i64, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_variant_lit$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_variant_lit"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_false_pat$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_false_pat"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_true_pat$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_true_pat"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_num_pat$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_num_pat"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_bind_pat$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_bind_pat"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_wild_pat$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_wild_pat"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_variant_pat$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_variant_pat"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_hole_arm$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_hole_arm"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_arm$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_arm"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_match$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_match"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_enum_decl$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_enum_decl"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_variant_lit"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  %4 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp1 = icmp eq i64 %6, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %7, %then2 ], [ null, %postret5 ]
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 29)
  call void @avra_array_push_owned(ptr %8, ptr %4)
  call void @avra_array_push_owned(ptr %8, ptr %regval6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_false_pat"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 3)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %1, ptr %2, ptr %boxed)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 4)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_true_pat"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 3)
  call void @avra_array_push(ptr %2, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %1, ptr %2, ptr %boxed)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 4)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_num_pat"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %regval)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Egrammar$2EToken$2Eint_value"(ptr %regval)
  %x = extractvalue { i1, i64 } %5, 0
  br i1 %x, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then1:                                            ; preds = %endif
  %x4 = extractvalue { i1, i64 } %5, 1
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval5 = phi i64 [ %x4, %then1 ], [ 0, %else2 ]
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 0)
  call void @avra_array_push(ptr %6, i64 %regval5)
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %4, ptr %6, ptr %boxed)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 4)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_bind_pat"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  %4 = call i64 @avra_array_get(ptr %regval, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_streq(ptr %boxed, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %b = icmp ne i64 %5, 0
  br i1 %b, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then1:                                            ; preds = %endif
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %8 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 2)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endif3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_wild_pat"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_variant_pat"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  %4 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_ids_at"(ptr %boxed, i64 1)
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %7, i64 3)
  call void @avra_array_push_owned(ptr %7, ptr %4)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_pat"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_ids_at"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_hole_arm"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  %4 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 4)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr_node"(ptr %0, ptr %5)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 2)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  %10 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %boxed)
  %11 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr %7, ptr %9, ptr %boxed)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_arm"(ptr %0, ptr %12, i64 %6)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_arm"(ptr, ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_arm"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 1)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi i64 [ %3, %then ], [ 0, %postret ]
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_ids_at"(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_arm"(ptr %0, ptr %5, i64 %regval)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_match"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi i64 [ %3, %then ], [ 0, %postret ]
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Earms_at"(ptr %boxed, i64 1)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 20)
  call void @avra_array_push(ptr %6, i64 %regval)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Earms_at"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebuild_enum_decl"(ptr %0) {
entry:
  %slot78 = alloca i64, align 8
  %slot59 = alloca ptr, align 8
  store ptr null, ptr %slot59, align 8
  %slot58 = alloca i64, align 8
  %slot57 = alloca ptr, align 8
  store ptr null, ptr %slot57, align 8
  %slot34 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp1 = icmp eq i64 %5, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %6, %then2 ], [ null, %postret5 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %7, 0
  %not = xor i1 %x, true
  br i1 %not, label %then7, label %else8

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then7:                                            ; preds = %endif4
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 1)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else8:                                            ; preds = %endif4
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 2)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp12 = icmp eq i64 %10, 0
  br i1 %cmp12, label %then13, label %else14

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif9

then13:                                           ; preds = %endif9
  %11 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  br label %endif15

else14:                                           ; preds = %endif9
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endif15:                                          ; preds = %postret16, %then13
  %regval17 = phi ptr [ %11, %then13 ], [ null, %postret16 ]
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 4)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp18 = icmp eq i64 %13, 0
  br i1 %cmp18, label %then19, label %else20

postret16:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif15

then19:                                           ; preds = %endif15
  %14 = call ptr @avra_array_get_owned(ptr %12, i64 1)
  br label %endif21

else20:                                           ; preds = %endif15
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

endif21:                                          ; preds = %postret22, %then19
  %regval23 = phi ptr [ %14, %then19 ], [ null, %postret22 ]
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 5)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %cmp24 = icmp eq i64 %16, 0
  br i1 %cmp24, label %then25, label %else26

postret22:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif21

then25:                                           ; preds = %endif21
  %17 = call ptr @avra_array_get_owned(ptr %15, i64 1)
  br label %endif27

else26:                                           ; preds = %endif21
  call void @avra_rc_release(ptr %regval23)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

endif27:                                          ; preds = %postret28, %then25
  %regval29 = phi ptr [ %17, %then25 ], [ null, %postret28 ]
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call i64 @avra_array_len(ptr %regval17)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret28:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif27

lhead:                                            ; preds = %lbody, %endif27
  %ld = load i64, ptr %slot, align 8
  %cmp30 = icmp slt i64 %ld, %19
  br i1 %cmp30, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %20 = call ptr @avra_array_sized(i64 0)
  %21 = call i64 @avra_array_len(ptr %regval29)
  store i64 0, ptr %slot34, align 8
  br label %lhead35

lbody:                                            ; preds = %lhead
  %ld31 = load i64, ptr %slot, align 8
  %22 = call i64 @avra_array_get(ptr %regval17, i64 %ld31)
  %boxed = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_array_get(ptr %boxed, i64 2)
  %boxed32 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed32, i64 0)
  call void @avra_array_push(ptr %18, i64 %24)
  %ld33 = load i64, ptr %slot, align 8
  %add = add i64 %ld33, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead35:                                          ; preds = %lbody39, %lexit
  %ld37 = load i64, ptr %slot34, align 8
  %cmp38 = icmp slt i64 %ld37, %21
  br i1 %cmp38, label %lbody39, label %lexit36

lexit36:                                          ; preds = %lhead35
  %25 = call ptr @avra_array_concat(ptr %18, ptr %20)
  %26 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed44 = inttoptr i64 %26 to ptr
  call void @avra_rc_retain(ptr %boxed44)
  %27 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarks_at"(ptr %boxed44, i64 6)
  %28 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed45 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %boxed45)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarks_at"(ptr %boxed45, i64 7)
  %30 = call ptr @avra_array_concat(ptr %27, ptr %29)
  %31 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %cmp46 = icmp ne ptr %31, null
  br i1 %cmp46, label %then47, label %else48

lbody39:                                          ; preds = %lhead35
  %ld40 = load i64, ptr %slot34, align 8
  %32 = call i64 @avra_array_get(ptr %regval29, i64 %ld40)
  %boxed41 = inttoptr i64 %32 to ptr
  call void @avra_rc_retain(ptr %boxed41)
  %33 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Etype_lo"(ptr %boxed41)
  call void @avra_array_push(ptr %20, i64 %33)
  %ld42 = load i64, ptr %slot34, align 8
  %add43 = add i64 %ld42, 1
  store i64 %add43, ptr %slot34, align 8
  br label %lhead35

then47:                                           ; preds = %lexit36
  %34 = call i64 @avra_array_get(ptr %31, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %34, 1
  br label %endif49

else48:                                           ; preds = %lexit36
  br label %endif49

endif49:                                          ; preds = %else48, %then47
  %regval50 = phi { i1, i64 } [ %pack, %then47 ], [ zeroinitializer, %else48 ]
  %x51 = extractvalue { i1, i64 } %regval50, 0
  br i1 %x51, label %then52, label %else53

then52:                                           ; preds = %endif49
  %x55 = extractvalue { i1, i64 } %regval50, 1
  br label %endif54

else53:                                           ; preds = %endif49
  br label %endif54

endif54:                                          ; preds = %else53, %then52
  %regval56 = phi i64 [ %x55, %then52 ], [ 0, %else53 ]
  %35 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %35, ptr %25)
  call void @avra_array_push_owned(ptr %35, ptr %30)
  call void @avra_array_push(ptr %35, i64 %regval56)
  %36 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %36)
  call void @avra_cell_release(ptr %slot57)
  store ptr %36, ptr %slot57, align 8
  %37 = call i64 @avra_array_len(ptr %regval17)
  store i64 0, ptr %slot58, align 8
  br label %lhead60

lhead60:                                          ; preds = %lbody64, %endif54
  %ld62 = load i64, ptr %slot58, align 8
  %cmp63 = icmp slt i64 %ld62, %37
  br i1 %cmp63, label %lbody64, label %lexit61

lexit61:                                          ; preds = %lhead60
  %38 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %38)
  %39 = call ptr @avra_array_sized(i64 0)
  %40 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot78, align 8
  br label %lhead79

lbody64:                                          ; preds = %lhead60
  %ld65 = load i64, ptr %slot58, align 8
  %41 = call ptr @avra_array_get_owned(ptr %regval17, i64 %ld65)
  call void @avra_rc_retain(ptr %41)
  call void @avra_cell_release(ptr %slot59)
  store ptr %41, ptr %slot59, align 8
  %x66 = extractvalue { i1, i64 } %7, 0
  %x67 = extractvalue { i1, i64 } %7, 1
  %slot68 = zext i1 %x66 to i64
  %42 = call i64 @avra_insist_scalar(i64 %slot68, i64 %x67)
  call void @avra_rc_retain(ptr %regval17)
  %43 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ewindow_end"(ptr %regval17, i64 %ld65, i64 %42)
  %44 = call ptr @avra_cell_unique(ptr %slot57)
  %ld69 = load ptr, ptr %slot59, align 8
  call void @avra_rc_retain(ptr %ld69)
  %45 = call ptr @avra_array_get_owned(ptr %ld69, i64 1)
  call void @avra_rc_retain(ptr %45)
  %ld70 = load ptr, ptr %slot59, align 8
  %46 = call i64 @avra_array_get(ptr %ld70, i64 2)
  %boxed71 = inttoptr i64 %46 to ptr
  %47 = call i64 @avra_array_get(ptr %boxed71, i64 0)
  call void @avra_rc_retain(ptr %regval23)
  call void @avra_rc_retain(ptr %regval29)
  call void @avra_rc_retain(ptr %35)
  %48 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epayloads_between"(ptr %regval23, ptr %regval29, ptr %35, i64 %47, i64 %43)
  %ld72 = load ptr, ptr %slot59, align 8
  %49 = call i64 @avra_array_get(ptr %ld72, i64 2)
  %boxed73 = inttoptr i64 %49 to ptr
  %ld74 = load ptr, ptr %slot59, align 8
  %50 = call i64 @avra_array_get(ptr %ld74, i64 2)
  %boxed75 = inttoptr i64 %50 to ptr
  %51 = call i64 @avra_array_get(ptr %boxed75, i64 0)
  call void @avra_rc_retain(ptr %35)
  %52 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EMarkWindows$2Eat"(ptr %35, i64 %51)
  %53 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %53, ptr %45)
  call void @avra_array_push_owned(ptr %53, ptr %48)
  call void @avra_array_push_owned(ptr %53, ptr %boxed73)
  call void @avra_array_push_owned(ptr %53, ptr %52)
  call void @avra_array_push_owned(ptr %44, ptr %53)
  %ld76 = load i64, ptr %slot58, align 8
  %add77 = add i64 %ld76, 1
  store i64 %add77, ptr %slot58, align 8
  call void @avra_rc_release(ptr %53)
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %ld69)
  call void @avra_rc_release(ptr %41)
  br label %lhead60

lhead79:                                          ; preds = %lbody83, %lexit61
  %ld81 = load i64, ptr %slot78, align 8
  %cmp82 = icmp slt i64 %ld81, %40
  br i1 %cmp82, label %lbody83, label %lexit80

lexit80:                                          ; preds = %lhead79
  %ld87 = load ptr, ptr %slot57, align 8
  %54 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %54, i64 20)
  call void @avra_array_push_owned(ptr %54, ptr %38)
  call void @avra_array_push_owned(ptr %54, ptr %39)
  call void @avra_array_push_owned(ptr %54, ptr %ld87)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %54)
  %55 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %54)
  call void @avra_cell_release(ptr %slot59)
  call void @avra_cell_release(ptr %slot57)
  call void @avra_rc_release(ptr %54)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval29)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval23)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %55

lbody83:                                          ; preds = %lhead79
  %ld84 = load i64, ptr %slot78, align 8
  %56 = call ptr @avra_array_get_owned(ptr %regval6, i64 %ld84)
  %57 = call ptr @avra_array_get_owned(ptr %56, i64 1)
  call void @avra_rc_retain(ptr %57)
  call void @avra_array_push_owned(ptr %39, ptr %57)
  %ld85 = load i64, ptr %slot78, align 8
  %add86 = add i64 %ld85, 1
  store i64 %add86, ptr %slot78, align 8
  call void @avra_rc_release(ptr %57)
  call void @avra_rc_release(ptr %57)
  call void @avra_rc_release(ptr %56)
  br label %lhead79
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EMarkWindows$2Eat"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epayloads_between"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4) {
entry:
  %slot = alloca i64, align 8
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call ptr @avra_array_get_owned(ptr %1, i64 %ld1)
  call void @avra_rc_retain(ptr %7)
  %8 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eref_within"(ptr %7, i64 %3, i64 %4)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ename_before"(ptr %0, ptr %7, i64 %3)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @avra_array_get_owned(ptr %7, i64 5)
  call void @avra_rc_retain(ptr %7)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Etype_lo"(ptr %7)
  call void @avra_rc_retain(ptr %2)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EMarkWindows$2Eat"(ptr %2, i64 %11)
  %13 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %13, ptr %9)
  call void @avra_array_push_owned(ptr %13, ptr %7)
  call void @avra_array_push_owned(ptr %13, ptr null)
  call void @avra_array_push_owned(ptr %13, ptr getelementptr inbounds (i8, ptr @"av_const$90$115", i64 16))
  call void @avra_array_push_owned(ptr %13, ptr %10)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_array_push_owned(ptr %5, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %9)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Etype_lo"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ename_before"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot7 = alloca ptr, align 8
  store ptr null, ptr %slot7, align 8
  %slot6 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 5)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %4, 1
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %pack, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  br i1 %x, label %then1, label %else2

then1:                                            ; preds = %endif
  %x4 = extractvalue { i1, i64 } %regval, 1
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval5 = phi i64 [ %x4, %then1 ], [ %2, %else2 ]
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_cell_release(ptr %slot)
  store ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %slot, align 8
  %5 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot6, align 8
  br label %lhead

lhead:                                            ; preds = %endif13, %endif3
  %ld = load i64, ptr %slot6, align 8
  %cmp8 = icmp slt i64 %ld, %5
  br i1 %cmp8, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot7)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld9 = load i64, ptr %slot6, align 8
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 %ld9)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot7)
  store ptr %6, ptr %slot7, align 8
  %ld10 = load ptr, ptr %slot7, align 8
  %7 = call i64 @avra_array_get(ptr %ld10, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %8, i64 %2, i64 %regval5)
  br i1 %9, label %then11, label %else12

then11:                                           ; preds = %lbody
  %ld14 = load ptr, ptr %slot7, align 8
  call void @avra_rc_retain(ptr %ld14)
  %10 = call ptr @avra_array_get_owned(ptr %ld14, i64 1)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot)
  store ptr %10, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld14)
  br label %endif13

else12:                                           ; preds = %lbody
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  %ld16 = load i64, ptr %slot6, align 8
  %add = add i64 %ld16, 1
  store i64 %add, ptr %slot6, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emarks_at"(ptr, i64)
