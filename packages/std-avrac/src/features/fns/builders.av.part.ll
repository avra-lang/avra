; ModuleID = 'avra'
source_filename = "avra"

@"av_const$90$115" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 2, i64 2, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] }, ptr @"av_const$90$115", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] }, ptr @"av_const$90$115", i32 0, i32 3), ptr null }, [2 x i64] zeroinitializer, [2 x i8] zeroinitializer }, align 16
@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [84 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 83 }, [84 x i8] c"defect: an extern declaration without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [81 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 80 }, [81 x i8] c"defect: a once declaration without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [79 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 78 }, [79 x i8] c"defect: a fn declaration without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRef$2Emarks"()

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_once"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EParam$2Emarks"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr, ptr, ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_binds"(ptr, ptr, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_return$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_return"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_pinned_call$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_pinned_call"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_call$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_call"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_extern$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_extern"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_once_fn$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_once_fn"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_fn$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_fn"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_return"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %1 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr %boxed, i64 0)
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 10)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_pinned_call"(ptr %0) {
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
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 1)
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
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi ptr [ %9, %then8 ], [ null, %postret11 ]
  %10 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %11, i64 17)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push_owned(ptr %11, ptr %regval6)
  call void @avra_array_push_owned(ptr %11, ptr %regval12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_call"(ptr %0) {
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
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 1)
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
  %7 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %9, i64 17)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push_owned(ptr %9, ptr %regval6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_extern"(ptr %0) {
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
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi ptr [ %9, %then8 ], [ null, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 3)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp13 = icmp eq i64 %11, 0
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  %12 = call ptr @avra_array_get_owned(ptr %10, i64 1)
  br label %endif16

else15:                                           ; preds = %endif10
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

endif16:                                          ; preds = %postret17, %then14
  %regval18 = phi ptr [ %12, %then14 ], [ null, %postret17 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %13, 0
  %not = xor i1 %x, true
  br i1 %not, label %then19, label %else20

postret17:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif16

then19:                                           ; preds = %endif16
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 1)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else20:                                           ; preds = %endif16
  br label %endif21

endif21:                                          ; preds = %else20, %postret22
  %regval23 = phi i64 [ 0, %postret22 ], [ 0, %else20 ]
  %15 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %15)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 4)
  %17 = call i64 @avra_array_get(ptr %16, i64 0)
  %cmp24 = icmp eq i64 %17, 0
  br i1 %cmp24, label %then25, label %else26

postret22:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif21

then25:                                           ; preds = %endif21
  %18 = call ptr @avra_array_get_owned(ptr %16, i64 1)
  br label %endif27

else26:                                           ; preds = %endif21
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

endif27:                                          ; preds = %postret28, %then25
  %regval29 = phi ptr [ %18, %then25 ], [ null, %postret28 ]
  %x30 = extractvalue { i1, i64 } %13, 0
  %x31 = extractvalue { i1, i64 } %13, 1
  %slot = zext i1 %x30 to i64
  %19 = call i64 @avra_insist_scalar(i64 %slot, i64 %x31)
  call void @avra_rc_retain(ptr %regval18)
  call void @avra_rc_retain(ptr %regval29)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr %regval18, ptr %regval29, i64 %19)
  %21 = call i64 @avra_array_get(ptr %regval, i64 2)
  %boxed = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %regval18)
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %regval12)
  call void @avra_rc_retain(ptr %regval6)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr %regval18, ptr %20, ptr %regval12, ptr %regval6, i64 %22)
  call void @avra_rc_retain(ptr %0)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr %0, i64 5)
  %25 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %25, i64 7)
  call void @avra_array_push_owned(ptr %25, ptr %15)
  call void @avra_array_push_owned(ptr %25, ptr %23)
  call void @avra_array_push_owned(ptr %25, ptr %24)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %25)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %25)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval29)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %26

postret28:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif27
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr, ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_once_fn"(ptr %0) {
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
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 3)
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
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr %0, i64 5)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 6)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp7 = icmp eq i64 %9, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %10 = call i64 @avra_array_get(ptr %8, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi i64 [ %10, %then8 ], [ 0, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %11 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %11, 0
  %not = xor i1 %x, true
  br i1 %not, label %then13, label %else14

postret11:                                        ; No predecessors!
  br label %endif10

then13:                                           ; preds = %endif10
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 1)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else14:                                           ; preds = %endif10
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  %13 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %14 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 4)
  %17 = call i64 @avra_array_get(ptr %16, i64 0)
  %cmp18 = icmp eq i64 %17, 0
  br i1 %cmp18, label %then19, label %else20

postret16:                                        ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif15

then19:                                           ; preds = %endif15
  %18 = call ptr @avra_array_get_owned(ptr %16, i64 1)
  br label %endif21

else20:                                           ; preds = %endif15
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

endif21:                                          ; preds = %postret22, %then19
  %regval23 = phi ptr [ %18, %then19 ], [ null, %postret22 ]
  %x24 = extractvalue { i1, i64 } %11, 0
  %x25 = extractvalue { i1, i64 } %11, 1
  %slot = zext i1 %x24 to i64
  %19 = call i64 @avra_insist_scalar(i64 %slot, i64 %x25)
  call void @avra_rc_retain(ptr %regval6)
  call void @avra_rc_retain(ptr %regval23)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr %regval6, ptr %regval23, i64 %19)
  call void @avra_rc_retain(ptr %regval6)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eseats"(ptr %regval6, ptr %20)
  %22 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %22, i64 6)
  call void @avra_array_push_owned(ptr %22, ptr %14)
  call void @avra_array_push_owned(ptr %22, ptr %15)
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_array_push_owned(ptr %22, ptr %7)
  call void @avra_array_push(ptr %22, i64 %regval12)
  %23 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %22)
  call void @avra_rc_retain(ptr %boxed)
  %24 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %13, ptr %22, ptr %boxed)
  %25 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed26 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %boxed26)
  %26 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_once"(ptr %boxed26, i64 %24)
  %27 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %27, i64 1)
  call void @avra_array_push(ptr %27, i64 %24)
  %28 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %28, i64 0)
  call void @avra_array_push_owned(ptr %28, ptr %27)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval23)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %28

postret22:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif21
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eseats"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebuild_fn"(ptr %0) {
entry:
  %slot44 = alloca i64, align 8
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
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 3)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi ptr [ %9, %then8 ], [ null, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 4)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp13 = icmp eq i64 %11, 0
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  %12 = call ptr @avra_array_get_owned(ptr %10, i64 1)
  br label %endif16

else15:                                           ; preds = %endif10
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

endif16:                                          ; preds = %postret17, %then14
  %regval18 = phi ptr [ %12, %then14 ], [ null, %postret17 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 5)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %cmp19 = icmp eq i64 %14, 0
  br i1 %cmp19, label %then20, label %else21

postret17:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif16

then20:                                           ; preds = %endif16
  %15 = call ptr @avra_array_get_owned(ptr %13, i64 1)
  br label %endif22

else21:                                           ; preds = %endif16
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

endif22:                                          ; preds = %postret23, %then20
  %regval24 = phi ptr [ %15, %then20 ], [ null, %postret23 ]
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr %0, i64 7)
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 8)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp25 = icmp eq i64 %18, 0
  br i1 %cmp25, label %then26, label %else27

postret23:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif22

then26:                                           ; preds = %endif22
  %19 = call i64 @avra_array_get(ptr %17, i64 1)
  br label %endif28

else27:                                           ; preds = %endif22
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

endif28:                                          ; preds = %postret29, %then26
  %regval30 = phi i64 [ %19, %then26 ], [ 0, %postret29 ]
  call void @avra_rc_retain(ptr %0)
  %20 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %20, 0
  %not = xor i1 %x, true
  br i1 %not, label %then31, label %else32

postret29:                                        ; No predecessors!
  br label %endif28

then31:                                           ; preds = %endif28
  %21 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %21, i64 1)
  call void @avra_array_push_owned(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %21

else32:                                           ; preds = %endif28
  br label %endif33

endif33:                                          ; preds = %else32, %postret34
  %regval35 = phi i64 [ 0, %postret34 ], [ 0, %else32 ]
  call void @avra_rc_retain(ptr %0)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 2)
  %23 = call i64 @avra_array_get(ptr %22, i64 0)
  %cmp36 = icmp eq i64 %23, 0
  br i1 %cmp36, label %then37, label %else38

postret34:                                        ; No predecessors!
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif33

then37:                                           ; preds = %endif33
  %24 = call ptr @avra_array_get_owned(ptr %22, i64 1)
  br label %endif39

else38:                                           ; preds = %endif33
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %22

endif39:                                          ; preds = %postret40, %then37
  %regval41 = phi ptr [ %24, %then37 ], [ null, %postret40 ]
  %x42 = extractvalue { i1, i64 } %20, 0
  %x43 = extractvalue { i1, i64 } %20, 1
  %slot = zext i1 %x42 to i64
  %25 = call i64 @avra_insist_scalar(i64 %slot, i64 %x43)
  call void @avra_rc_retain(ptr %regval6)
  call void @avra_rc_retain(ptr %regval41)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_binds"(ptr %regval6, ptr %regval41, i64 %25)
  %27 = call ptr @avra_array_sized(i64 0)
  %28 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot44, align 8
  br label %lhead

postret40:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif39

lhead:                                            ; preds = %lbody, %endif39
  %ld = load i64, ptr %slot44, align 8
  %cmp45 = icmp slt i64 %ld, %28
  br i1 %cmp45, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %29 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %29)
  call void @avra_rc_retain(ptr %0)
  %30 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 6)
  %31 = call i64 @avra_array_get(ptr %30, i64 0)
  %cmp49 = icmp eq i64 %31, 0
  br i1 %cmp49, label %then50, label %else51

lbody:                                            ; preds = %lhead
  %ld46 = load i64, ptr %slot44, align 8
  %32 = call ptr @avra_array_get_owned(ptr %regval6, i64 %ld46)
  %33 = call ptr @avra_array_get_owned(ptr %32, i64 1)
  call void @avra_rc_retain(ptr %33)
  %34 = call i64 @avra_array_get(ptr %26, i64 %ld46)
  %boxed = inttoptr i64 %34 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %32)
  %35 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebound_ref"(ptr %boxed, ptr %32)
  %36 = call i64 @avra_array_get(ptr %32, i64 2)
  %boxed47 = inttoptr i64 %36 to ptr
  %37 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %37, ptr %33)
  call void @avra_array_push_owned(ptr %37, ptr %35)
  call void @avra_array_push_owned(ptr %37, ptr null)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @"av_const$90$115", i64 16))
  call void @avra_array_push_owned(ptr %37, ptr %boxed47)
  %38 = call ptr @"av_$40std$2Eavrac$2Ecore$2EParam$2Emarks"()
  call void @avra_array_push_owned(ptr %37, ptr %38)
  call void @avra_array_push_owned(ptr %27, ptr %37)
  %ld48 = load i64, ptr %slot44, align 8
  %add = add i64 %ld48, 1
  store i64 %add, ptr %slot44, align 8
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  br label %lhead

then50:                                           ; preds = %lexit
  %39 = call ptr @avra_array_get_owned(ptr %30, i64 1)
  br label %endif52

else51:                                           ; preds = %lexit
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %regval41)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %30

endif52:                                          ; preds = %postret53, %then50
  %regval54 = phi ptr [ %39, %then50 ], [ null, %postret53 ]
  %x55 = extractvalue { i1, i64 } %20, 0
  %x56 = extractvalue { i1, i64 } %20, 1
  %slot57 = zext i1 %x55 to i64
  %40 = call i64 @avra_insist_scalar(i64 %slot57, i64 %x56)
  call void @avra_rc_retain(ptr %regval24)
  call void @avra_rc_retain(ptr %regval54)
  %41 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr %regval24, ptr %regval54, i64 %40)
  %42 = call i64 @avra_array_get(ptr %regval, i64 2)
  %boxed58 = inttoptr i64 %42 to ptr
  %43 = call i64 @avra_array_get(ptr %boxed58, i64 0)
  call void @avra_rc_retain(ptr %regval24)
  call void @avra_rc_retain(ptr %41)
  call void @avra_rc_retain(ptr %regval18)
  call void @avra_rc_retain(ptr %regval12)
  %44 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr %regval24, ptr %41, ptr %regval18, ptr %regval12, i64 %43)
  %45 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %45, i64 6)
  call void @avra_array_push_owned(ptr %45, ptr %29)
  call void @avra_array_push_owned(ptr %45, ptr %27)
  call void @avra_array_push_owned(ptr %45, ptr %44)
  call void @avra_array_push_owned(ptr %45, ptr %16)
  call void @avra_array_push(ptr %45, i64 %regval30)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %45)
  %46 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %45)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %regval54)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %regval41)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %46

postret53:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif52
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Ebound_ref"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %5, ptr %0)
  call void @avra_array_push_owned(ptr %5, ptr %3)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_array_push_owned(ptr %5, ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRef$2Emarks"()
  call void @avra_array_push_owned(ptr %5, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  br label %endif
}
