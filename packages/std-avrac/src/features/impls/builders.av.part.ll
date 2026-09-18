; ModuleID = 'avra'
source_filename = "avra"

@"av_const$90$115" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 2, i64 2, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] }, ptr @"av_const$90$115", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [2 x i64], [2 x i8] }, ptr @"av_const$90$115", i32 0, i32 3), ptr null }, [2 x i64] zeroinitializer, [2 x i8] zeroinitializer }, align 16
@"av_const$98$91$0" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [0 x i64], [0 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 0, i64 0, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [0 x i64], [0 x i8] }, ptr @"av_const$98$91$0", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [0 x i64], [0 x i8] }, ptr @"av_const$98$91$0", i32 0, i32 3), ptr null }, [0 x i64] zeroinitializer, [0 x i8] zeroinitializer }, align 16
@"av_const$98$91$1" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [0 x i64], [0 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 0, i64 0, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [0 x i64], [0 x i8] }, ptr @"av_const$98$91$1", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [0 x i64], [0 x i8] }, ptr @"av_const$98$91$1", i32 0, i32 3), ptr null }, [0 x i64] zeroinitializer, [0 x i8] zeroinitializer }, align 16
@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"void\00" }, align 16
@"av_const$98$91" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [7 x i64], [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 7, i64 7, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [7 x i64], [7 x i8] }, ptr @"av_const$98$91", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [7 x i64], [7 x i8] }, ptr @"av_const$98$91", i32 0, i32 3), ptr null }, [7 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$98$91$0", i64 16) to i64), i64 0, i64 0, i64 0, i64 0, i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$98$91$1", i64 16) to i64)], [7 x i8] c"\01\01\00\00\00\01\01" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [79 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 78 }, [79 x i8] c"defect: a fn declaration without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [82 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 81 }, [82 x i8] c"defect: a trait declaration without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"an `impl` block holds `fn` declarations only\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_static"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_mutating"(ptr, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EParam$2Emarks"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr, ptr, ptr, ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmts"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ewindow_end"(ptr, i64, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr, ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eref_within"(ptr, i64, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_receiver$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_receiver"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_static_fn$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_static_fn"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_mut_fn$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_mut_fn"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_trait$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_trait"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_impl$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_impl"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_receiver"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_static_fn"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Emarked_fn"(ptr %0)
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
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_static"(ptr %boxed, i64 %regval)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push(ptr %6, i64 %regval)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Emarked_fn"(ptr %0) {
entry:
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
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 1)
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
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %7, %then2 ], [ null, %postret5 ]
  %8 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

lhead:                                            ; preds = %lbody, %endif4
  %ld = load i64, ptr %slot, align 8
  %cmp7 = icmp slt i64 %ld, %8
  br i1 %cmp7, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 2)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp10 = icmp eq i64 %10, 0
  br i1 %cmp10, label %then11, label %else12

lbody:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot, align 8
  %11 = call ptr @avra_array_get_owned(ptr %regval6, i64 %ld8)
  %12 = call ptr @avra_array_get_owned(ptr %11, i64 1)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @avra_array_get(ptr %11, i64 2)
  %boxed = inttoptr i64 %13 to ptr
  %14 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %14, ptr %12)
  call void @avra_array_push(ptr %14, i64 0)
  call void @avra_array_push_owned(ptr %14, ptr null)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @"av_const$90$115", i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %boxed)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2EParam$2Emarks"()
  call void @avra_array_push_owned(ptr %14, ptr %15)
  call void @avra_array_push_owned(ptr %4, ptr %14)
  %ld9 = load i64, ptr %slot, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %lhead

then11:                                           ; preds = %lexit
  %16 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  br label %endif13

else12:                                           ; preds = %lexit
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endif13:                                          ; preds = %postret14, %then11
  %regval15 = phi ptr [ %16, %then11 ], [ null, %postret14 ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 3)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp16 = icmp eq i64 %18, 0
  br i1 %cmp16, label %then17, label %else18

postret14:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif13

then17:                                           ; preds = %endif13
  %19 = call ptr @avra_array_get_owned(ptr %17, i64 1)
  br label %endif19

else18:                                           ; preds = %endif13
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

endif19:                                          ; preds = %postret20, %then17
  %regval21 = phi ptr [ %19, %then17 ], [ null, %postret20 ]
  call void @avra_rc_retain(ptr %0)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 4)
  %21 = call i64 @avra_array_get(ptr %20, i64 0)
  %cmp22 = icmp eq i64 %21, 0
  br i1 %cmp22, label %then23, label %else24

postret20:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif19

then23:                                           ; preds = %endif19
  %22 = call ptr @avra_array_get_owned(ptr %20, i64 1)
  br label %endif25

else24:                                           ; preds = %endif19
  call void @avra_rc_release(ptr %regval21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %20

endif25:                                          ; preds = %postret26, %then23
  %regval27 = phi ptr [ %22, %then23 ], [ null, %postret26 ]
  call void @avra_rc_retain(ptr %0)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr %0, i64 6)
  call void @avra_rc_retain(ptr %0)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 7)
  %25 = call i64 @avra_array_get(ptr %24, i64 0)
  %cmp28 = icmp eq i64 %25, 0
  br i1 %cmp28, label %then29, label %else30

postret26:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif25

then29:                                           ; preds = %endif25
  %26 = call i64 @avra_array_get(ptr %24, i64 1)
  br label %endif31

else30:                                           ; preds = %endif25
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %regval27)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %24

endif31:                                          ; preds = %postret32, %then29
  %regval33 = phi i64 [ %26, %then29 ], [ 0, %postret32 ]
  call void @avra_rc_retain(ptr %0)
  %27 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %27, 0
  %not = xor i1 %x, true
  br i1 %not, label %then34, label %else35

postret32:                                        ; No predecessors!
  br label %endif31

then34:                                           ; preds = %endif31
  %28 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %28, i64 1)
  call void @avra_array_push_owned(ptr %28, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %regval27)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %28

else35:                                           ; preds = %endif31
  br label %endif36

endif36:                                          ; preds = %else35, %postret37
  %regval38 = phi i64 [ 0, %postret37 ], [ 0, %else35 ]
  call void @avra_rc_retain(ptr %0)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 5)
  %30 = call i64 @avra_array_get(ptr %29, i64 0)
  %cmp39 = icmp eq i64 %30, 0
  br i1 %cmp39, label %then40, label %else41

postret37:                                        ; No predecessors!
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif36

then40:                                           ; preds = %endif36
  %31 = call ptr @avra_array_get_owned(ptr %29, i64 1)
  br label %endif42

else41:                                           ; preds = %endif36
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %regval27)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %29

endif42:                                          ; preds = %postret43, %then40
  %regval44 = phi ptr [ %31, %then40 ], [ null, %postret43 ]
  %x45 = extractvalue { i1, i64 } %27, 0
  %x46 = extractvalue { i1, i64 } %27, 1
  %slot47 = zext i1 %x45 to i64
  %32 = call i64 @avra_insist_scalar(i64 %slot47, i64 %x46)
  call void @avra_rc_retain(ptr %regval27)
  call void @avra_rc_retain(ptr %regval44)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr %regval27, ptr %regval44, i64 %32)
  %34 = call i64 @avra_array_get(ptr %regval, i64 2)
  %boxed48 = inttoptr i64 %34 to ptr
  %35 = call i64 @avra_array_get(ptr %boxed48, i64 0)
  call void @avra_rc_retain(ptr %regval27)
  call void @avra_rc_retain(ptr %33)
  call void @avra_rc_retain(ptr %regval21)
  call void @avra_rc_retain(ptr %regval15)
  %36 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr %regval27, ptr %33, ptr %regval21, ptr %regval15, i64 %35)
  %37 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %38 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %38)
  %39 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %39, i64 6)
  call void @avra_array_push_owned(ptr %39, ptr %38)
  call void @avra_array_push_owned(ptr %39, ptr %4)
  call void @avra_array_push_owned(ptr %39, ptr %36)
  call void @avra_array_push_owned(ptr %39, ptr %23)
  call void @avra_array_push(ptr %39, i64 %regval33)
  %40 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed49 = inttoptr i64 %40 to ptr
  call void @avra_rc_retain(ptr %37)
  call void @avra_rc_retain(ptr %39)
  call void @avra_rc_retain(ptr %boxed49)
  %41 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %37, ptr %39, ptr %boxed49)
  %42 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %42, i64 0)
  call void @avra_array_push(ptr %42, i64 %41)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %regval44)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %regval27)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %42

postret43:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif42
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_mut_fn"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Emarked_fn"(ptr %0)
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
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_mutating"(ptr %boxed, i64 %regval)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push(ptr %6, i64 %regval)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_trait"(ptr %0) {
entry:
  %slot105 = alloca i64, align 8
  %slot103 = alloca i1, align 1
  %slot84 = alloca i64, align 8
  %slot82 = alloca i1, align 1
  %slot61 = alloca ptr, align 8
  store ptr null, ptr %slot61, align 8
  %slot60 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
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
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 4)
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
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 5)
  %17 = call i64 @avra_array_get(ptr %16, i64 0)
  %cmp25 = icmp eq i64 %17, 0
  br i1 %cmp25, label %then26, label %else27

postret23:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif22

then26:                                           ; preds = %endif22
  %18 = call ptr @avra_array_get_owned(ptr %16, i64 1)
  br label %endif28

else27:                                           ; preds = %endif22
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
  ret ptr %16

endif28:                                          ; preds = %postret29, %then26
  %regval30 = phi ptr [ %18, %then26 ], [ null, %postret29 ]
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 6)
  %20 = call i64 @avra_array_get(ptr %19, i64 0)
  %cmp31 = icmp eq i64 %20, 0
  br i1 %cmp31, label %then32, label %else33

postret29:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif28

then32:                                           ; preds = %endif28
  %21 = call ptr @avra_array_get_owned(ptr %19, i64 1)
  br label %endif34

else33:                                           ; preds = %endif28
  call void @avra_rc_release(ptr %regval30)
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
  ret ptr %19

endif34:                                          ; preds = %postret35, %then32
  %regval36 = phi ptr [ %21, %then32 ], [ null, %postret35 ]
  call void @avra_rc_retain(ptr %0)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 7)
  %23 = call i64 @avra_array_get(ptr %22, i64 0)
  %cmp37 = icmp eq i64 %23, 0
  br i1 %cmp37, label %then38, label %else39

postret35:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif34

then38:                                           ; preds = %endif34
  %24 = call ptr @avra_array_get_owned(ptr %22, i64 1)
  br label %endif40

else39:                                           ; preds = %endif34
  call void @avra_rc_release(ptr %regval36)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval30)
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

endif40:                                          ; preds = %postret41, %then38
  %regval42 = phi ptr [ %24, %then38 ], [ null, %postret41 ]
  call void @avra_rc_retain(ptr %0)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 8)
  %26 = call i64 @avra_array_get(ptr %25, i64 0)
  %cmp43 = icmp eq i64 %26, 0
  br i1 %cmp43, label %then44, label %else45

postret41:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif40

then44:                                           ; preds = %endif40
  %27 = call ptr @avra_array_get_owned(ptr %25, i64 1)
  br label %endif46

else45:                                           ; preds = %endif40
  call void @avra_rc_release(ptr %regval42)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %regval36)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval30)
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
  ret ptr %25

endif46:                                          ; preds = %postret47, %then44
  %regval48 = phi ptr [ %27, %then44 ], [ null, %postret47 ]
  call void @avra_rc_retain(ptr %0)
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 9)
  %29 = call i64 @avra_array_get(ptr %28, i64 0)
  %cmp49 = icmp eq i64 %29, 0
  br i1 %cmp49, label %then50, label %else51

postret47:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif46

then50:                                           ; preds = %endif46
  %30 = call ptr @avra_array_get_owned(ptr %28, i64 1)
  br label %endif52

else51:                                           ; preds = %endif46
  call void @avra_rc_release(ptr %regval48)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %regval42)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %regval36)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval30)
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
  ret ptr %28

endif52:                                          ; preds = %postret53, %then50
  %regval54 = phi ptr [ %30, %then50 ], [ null, %postret53 ]
  call void @avra_rc_retain(ptr %0)
  %31 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %31, 0
  %not = xor i1 %x, true
  br i1 %not, label %then55, label %else56

postret53:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif52

then55:                                           ; preds = %endif52
  %32 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %32, i64 1)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %regval54)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %regval48)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %regval42)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %regval36)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval30)
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
  ret ptr %32

else56:                                           ; preds = %endif52
  br label %endif57

endif57:                                          ; preds = %else56, %postret58
  %regval59 = phi i64 [ 0, %postret58 ], [ 0, %else56 ]
  %33 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %33)
  call void @avra_cell_release(ptr %slot)
  store ptr %33, ptr %slot, align 8
  %34 = call i64 @avra_array_len(ptr %regval18)
  store i64 0, ptr %slot60, align 8
  br label %lhead

postret58:                                        ; No predecessors!
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif57

lhead:                                            ; preds = %endif123, %endif57
  %ld = load i64, ptr %slot60, align 8
  %cmp62 = icmp slt i64 %ld, %34
  br i1 %cmp62, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %35 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %35)
  %ld128 = load ptr, ptr %slot, align 8
  %36 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %36, i64 13)
  call void @avra_array_push_owned(ptr %36, ptr %35)
  call void @avra_array_push_owned(ptr %36, ptr %ld128)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %36)
  %37 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %36)
  call void @avra_cell_release(ptr %slot61)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %regval54)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %regval48)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %regval42)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %regval36)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval30)
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
  ret ptr %37

lbody:                                            ; preds = %lhead
  %ld63 = load i64, ptr %slot60, align 8
  %38 = call ptr @avra_array_get_owned(ptr %regval18, i64 %ld63)
  call void @avra_rc_retain(ptr %38)
  call void @avra_cell_release(ptr %slot61)
  store ptr %38, ptr %slot61, align 8
  %x64 = extractvalue { i1, i64 } %31, 0
  %x65 = extractvalue { i1, i64 } %31, 1
  %slot66 = zext i1 %x64 to i64
  %39 = call i64 @avra_insist_scalar(i64 %slot66, i64 %x65)
  call void @avra_rc_retain(ptr %regval18)
  %40 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ewindow_end"(ptr %regval18, i64 %ld63, i64 %39)
  %ld67 = load ptr, ptr %slot61, align 8
  %ld68 = load ptr, ptr %slot61, align 8
  %41 = call i64 @avra_array_get(ptr %ld68, i64 2)
  %boxed = inttoptr i64 %41 to ptr
  %42 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %regval36)
  call void @avra_rc_retain(ptr %regval42)
  call void @avra_rc_retain(ptr %regval30)
  call void @avra_rc_retain(ptr %regval24)
  %43 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eparams_between"(ptr %regval36, ptr %regval42, ptr %regval30, ptr %regval24, i64 %42, i64 %40)
  %ld69 = load ptr, ptr %slot61, align 8
  %44 = call i64 @avra_array_get(ptr %ld69, i64 2)
  %boxed70 = inttoptr i64 %44 to ptr
  %45 = call i64 @avra_array_get(ptr %boxed70, i64 0)
  call void @avra_rc_retain(ptr %regval48)
  %46 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eret_between"(ptr %regval48, i64 %45, i64 %40)
  %47 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed71 = inttoptr i64 %47 to ptr
  %ld72 = load ptr, ptr %slot61, align 8
  %48 = call i64 @avra_array_get(ptr %ld72, i64 2)
  %boxed73 = inttoptr i64 %48 to ptr
  %49 = call i64 @avra_array_get(ptr %boxed73, i64 0)
  call void @avra_rc_retain(ptr %boxed71)
  call void @avra_rc_retain(ptr %regval54)
  %50 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebody_between"(ptr %boxed71, ptr %regval54, i64 %49, i64 %40)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld67)
  call void @avra_rc_retain(ptr %43)
  call void @avra_rc_retain(ptr %46)
  call void @avra_rc_retain(ptr %50)
  %51 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Emember_stmt"(ptr %0, ptr %ld67, ptr %43, ptr %46, ptr %50)
  %cmp74 = icmp eq i64 %ld63, 0
  br i1 %cmp74, label %then75, label %else76

then75:                                           ; preds = %lbody
  %52 = call i64 @avra_array_get(ptr %regval, i64 2)
  %boxed78 = inttoptr i64 %52 to ptr
  %53 = call i64 @avra_array_get(ptr %boxed78, i64 0)
  br label %endif77

else76:                                           ; preds = %lbody
  %sub = sub i64 %ld63, 1
  %54 = call i64 @avra_array_get(ptr %regval18, i64 %sub)
  %boxed79 = inttoptr i64 %54 to ptr
  %55 = call i64 @avra_array_get(ptr %boxed79, i64 2)
  %boxed80 = inttoptr i64 %55 to ptr
  %56 = call i64 @avra_array_get(ptr %boxed80, i64 0)
  br label %endif77

endif77:                                          ; preds = %else76, %then75
  %regval81 = phi i64 [ %53, %then75 ], [ %56, %else76 ]
  store i1 false, ptr %slot82, align 8
  %ld83 = load ptr, ptr %slot61, align 8
  %57 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %57, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l264" to i64))
  call void @avra_array_push(ptr %57, i64 %regval81)
  call void @avra_array_push_owned(ptr %57, ptr %ld83)
  %58 = call i64 @avra_array_get(ptr %57, i64 0)
  %59 = call i64 @avra_array_len(ptr %regval12)
  store i64 0, ptr %slot84, align 8
  br label %lhead85

lhead85:                                          ; preds = %endif94, %endif77
  %ld87 = load i64, ptr %slot84, align 8
  %cmp88 = icmp slt i64 %ld87, %59
  br i1 %cmp88, label %lbody89, label %lexit86

lexit86:                                          ; preds = %lhead85
  %ld97 = load i1, ptr %slot82, align 8
  br i1 %ld97, label %then98, label %else99

lbody89:                                          ; preds = %lhead85
  %ld90 = load i64, ptr %slot84, align 8
  %60 = call i64 @avra_array_get(ptr %regval12, i64 %ld90)
  %boxed91 = inttoptr i64 %60 to ptr
  call void @avra_rc_retain(ptr %57)
  call void @avra_rc_retain(ptr %boxed91)
  %cast = inttoptr i64 %58 to ptr
  %61 = call i1 %cast(ptr %57, ptr %boxed91)
  br i1 %61, label %then92, label %else93

then92:                                           ; preds = %lbody89
  store i1 true, ptr %slot82, align 8
  store i64 %59, ptr %slot84, align 8
  br label %endif94

else93:                                           ; preds = %lbody89
  br label %endif94

endif94:                                          ; preds = %else93, %then92
  %regval95 = phi i64 [ 0, %then92 ], [ 0, %else93 ]
  %ld96 = load i64, ptr %slot84, align 8
  %add = add i64 %ld96, 1
  store i64 %add, ptr %slot84, align 8
  br label %lhead85

then98:                                           ; preds = %lexit86
  %62 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed101 = inttoptr i64 %62 to ptr
  call void @avra_rc_retain(ptr %boxed101)
  %63 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_mutating"(ptr %boxed101, i64 %51)
  br label %endif100

else99:                                           ; preds = %lexit86
  br label %endif100

endif100:                                         ; preds = %else99, %then98
  %regval102 = phi i64 [ 0, %then98 ], [ 0, %else99 ]
  store i1 false, ptr %slot103, align 8
  %ld104 = load ptr, ptr %slot61, align 8
  %64 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %64, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l279" to i64))
  call void @avra_array_push(ptr %64, i64 %regval81)
  call void @avra_array_push_owned(ptr %64, ptr %ld104)
  %65 = call i64 @avra_array_get(ptr %64, i64 0)
  %66 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot105, align 8
  br label %lhead106

lhead106:                                         ; preds = %endif116, %endif100
  %ld108 = load i64, ptr %slot105, align 8
  %cmp109 = icmp slt i64 %ld108, %66
  br i1 %cmp109, label %lbody110, label %lexit107

lexit107:                                         ; preds = %lhead106
  %ld120 = load i1, ptr %slot103, align 8
  br i1 %ld120, label %then121, label %else122

lbody110:                                         ; preds = %lhead106
  %ld111 = load i64, ptr %slot105, align 8
  %67 = call i64 @avra_array_get(ptr %regval6, i64 %ld111)
  %boxed112 = inttoptr i64 %67 to ptr
  call void @avra_rc_retain(ptr %64)
  call void @avra_rc_retain(ptr %boxed112)
  %cast113 = inttoptr i64 %65 to ptr
  %68 = call i1 %cast113(ptr %64, ptr %boxed112)
  br i1 %68, label %then114, label %else115

then114:                                          ; preds = %lbody110
  store i1 true, ptr %slot103, align 8
  store i64 %66, ptr %slot105, align 8
  br label %endif116

else115:                                          ; preds = %lbody110
  br label %endif116

endif116:                                         ; preds = %else115, %then114
  %regval117 = phi i64 [ 0, %then114 ], [ 0, %else115 ]
  %ld118 = load i64, ptr %slot105, align 8
  %add119 = add i64 %ld118, 1
  store i64 %add119, ptr %slot105, align 8
  br label %lhead106

then121:                                          ; preds = %lexit107
  %69 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed124 = inttoptr i64 %69 to ptr
  call void @avra_rc_retain(ptr %boxed124)
  %70 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_static"(ptr %boxed124, i64 %51)
  br label %endif123

else122:                                          ; preds = %lexit107
  br label %endif123

endif123:                                         ; preds = %else122, %then121
  %regval125 = phi i64 [ 0, %then121 ], [ 0, %else122 ]
  %71 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push(ptr %71, i64 %51)
  %ld126 = load i64, ptr %slot60, align 8
  %add127 = add i64 %ld126, 1
  store i64 %add127, ptr %slot60, align 8
  call void @avra_rc_release(ptr %64)
  call void @avra_rc_release(ptr %57)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %38)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l279"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  %8 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %3, i64 %4, i64 %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %8
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l264"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  %8 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %3, i64 %4, i64 %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Emember_stmt"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Esig_stmt"(ptr %0, ptr %1, ptr %2, ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  call void @avra_rc_retain(ptr %boxed)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr %boxed, i64 %8)
  %10 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %cmp2 = icmp ne ptr %9, null
  br i1 %cmp2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  %12 = call i64 @avra_array_get(ptr %9, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %12, 1
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval6 = phi { i1, i64 } [ %pack, %then3 ], [ zeroinitializer, %else4 ]
  %x = extractvalue { i1, i64 } %regval6, 0
  br i1 %x, label %then7, label %else8

then7:                                            ; preds = %endif5
  %x10 = extractvalue { i1, i64 } %regval6, 1
  br label %endif9

else8:                                            ; preds = %endif5
  %13 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed11 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed11, i64 1)
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval12 = phi i64 [ %x10, %then7 ], [ %14, %else8 ]
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 %11)
  call void @avra_array_push(ptr %15, i64 %regval12)
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed13 = inttoptr i64 %16 to ptr
  %17 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call ptr @avra_insist(ptr %4)
  %20 = call i64 @avra_array_get(ptr %19, i64 0)
  %21 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %21, i64 6)
  call void @avra_array_push_owned(ptr %21, ptr %17)
  call void @avra_array_push_owned(ptr %21, ptr %18)
  call void @avra_array_push_owned(ptr %21, ptr %2)
  call void @avra_array_push_owned(ptr %21, ptr %3)
  call void @avra_array_push(ptr %21, i64 %20)
  call void @avra_rc_retain(ptr %boxed13)
  call void @avra_rc_retain(ptr %21)
  call void @avra_rc_retain(ptr %15)
  %22 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %boxed13, ptr %21, ptr %15)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %22
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Esig_stmt"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 33)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %boxed, ptr %5, ptr null)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @avra_array_sized(i64 0)
  %10 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %10, i64 6)
  call void @avra_array_push_owned(ptr %10, ptr %8)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_array_push_owned(ptr %10, ptr %2)
  call void @avra_array_push_owned(ptr %10, ptr %3)
  call void @avra_array_push(ptr %10, i64 %6)
  %11 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed2 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %boxed2)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %boxed1, ptr %10, ptr %boxed2)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %12
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebody_between"(ptr %0, ptr %1, i64 %2, i64 %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l381" to i64))
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_array_push(ptr %4, i64 %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call i64 @avra_array_len(ptr %1)
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
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  %cast = inttoptr i64 %5 to ptr
  %8 = call i1 %cast(ptr %4, i64 %7)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 %7)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  call void @avra_rc_release(ptr %9)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l381"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  call void @avra_rc_retain(ptr %2)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eexpr_within"(ptr %2, i64 %1, i64 %3, i64 %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %5
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eexpr_within"(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp1 = icmp sgt i64 %6, %2
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp5 = icmp slt i64 %8, %3
  call void @avra_rc_release(ptr %7)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ %cmp5, %then2 ], [ false, %else3 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eret_between"(ptr %0, i64 %1, i64 %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l407" to i64))
  call void @avra_array_push(ptr %3, i64 %1)
  call void @avra_array_push(ptr %3, i64 %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %6)
  %cast = inttoptr i64 %4 to ptr
  %7 = call i1 %cast(ptr %3, ptr %6)
  br i1 %7, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  store i64 %5, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead

then6:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr %ld4)
  br label %endif8

else7:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @"av_const$98$91", i64 16))
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %ld4, %then6 ], [ getelementptr inbounds (i8, ptr @"av_const$98$91", i64 16), %else7 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval9
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilders$24l407"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eref_within"(ptr %1, i64 %2, i64 %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eparams_between"(ptr %0, ptr %1, ptr %2, ptr %3, i64 %4, i64 %5) {
entry:
  %slot = alloca i64, align 8
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %1)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr %6, ptr %1, i64 %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr %6, ptr %8, ptr %2, ptr %3, i64 %4)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 %ld1)
  %11 = call i64 @avra_array_get(ptr %10, i64 2)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %12, i64 %4, i64 %5)
  br i1 %13, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_array_push_owned(ptr %6, ptr %10)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuild_impl"(ptr %0) {
entry:
  %slot29 = alloca ptr, align 8
  store ptr null, ptr %slot29, align 8
  %slot13 = alloca i64, align 8
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
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 2)
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
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmts"(ptr %0, i64 4)
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
  %10 = call i64 @avra_array_len(ptr %regval12)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

lhead:                                            ; preds = %endif25, %endif10
  %ld = load i64, ptr %slot, align 8
  %cmp14 = icmp slt i64 %ld, %10
  br i1 %cmp14, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot29)
  store ptr null, ptr %slot29, align 8
  %11 = call i64 @avra_array_len(ptr %regval6)
  %cmp30 = icmp slt i64 0, %11
  br i1 %cmp30, label %then31, label %else32

lbody:                                            ; preds = %lhead
  %ld15 = load i64, ptr %slot, align 8
  %12 = call i64 @avra_array_get(ptr %regval12, i64 %ld15)
  store i64 %12, ptr %slot13, align 8
  %ld16 = load i64, ptr %slot13, align 8
  call void @avra_rc_retain(ptr %0)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eis_fn"(ptr %0, i64 %ld16)
  %not = xor i1 %13, true
  br i1 %not, label %then17, label %else18

then17:                                           ; preds = %lbody
  %14 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %14 to ptr
  %ld20 = load i64, ptr %slot13, align 8
  call void @avra_rc_retain(ptr %boxed)
  %15 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr %boxed, i64 %ld20)
  %x = extractvalue { i1, i64 } %15, 0
  %not21 = xor i1 %x, true
  br label %endif19

else18:                                           ; preds = %lbody
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval22 = phi i1 [ %not21, %then17 ], [ false, %else18 ]
  br i1 %regval22, label %then23, label %else24

then23:                                           ; preds = %endif19
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 1)
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else24:                                           ; preds = %endif19
  br label %endif25

endif25:                                          ; preds = %else24, %postret26
  %regval27 = phi i64 [ 0, %postret26 ], [ 0, %else24 ]
  %ld28 = load i64, ptr %slot, align 8
  %add = add i64 %ld28, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret26:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif25

then31:                                           ; preds = %lexit
  %17 = call ptr @avra_array_get_owned(ptr %regval6, i64 0)
  call void @avra_rc_retain(ptr %17)
  call void @avra_cell_release(ptr %slot29)
  store ptr %17, ptr %slot29, align 8
  call void @avra_rc_release(ptr %17)
  br label %endif33

else32:                                           ; preds = %lexit
  br label %endif33

endif33:                                          ; preds = %else32, %then31
  %regval34 = phi i64 [ 0, %then31 ], [ 0, %else32 ]
  %ld35 = load ptr, ptr %slot29, align 8
  call void @avra_rc_retain(ptr %ld35)
  %cmp36 = icmp ne ptr %ld35, null
  %not37 = xor i1 %cmp36, true
  br i1 %not37, label %then38, label %else39

then38:                                           ; preds = %endif33
  %18 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %19, i64 12)
  call void @avra_array_push(ptr %19, i64 0)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_array_push_owned(ptr %19, ptr %regval12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %19)
  call void @avra_cell_release(ptr %slot29)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %ld35)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %20

else39:                                           ; preds = %endif33
  br label %endif40

endif40:                                          ; preds = %else39, %postret41
  %regval42 = phi i64 [ 0, %postret41 ], [ 0, %else39 ]
  %21 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @avra_insist(ptr %ld35)
  %23 = call ptr @avra_array_get_owned(ptr %22, i64 1)
  call void @avra_rc_retain(ptr %23)
  %24 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %24, i64 12)
  call void @avra_array_push_owned(ptr %24, ptr %21)
  call void @avra_array_push_owned(ptr %24, ptr %23)
  call void @avra_array_push_owned(ptr %24, ptr %regval12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %24)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %24)
  call void @avra_cell_release(ptr %slot29)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %ld35)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %25

postret41:                                        ; No predecessors!
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %18)
  br label %endif40
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eis_fn"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed, i64 %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %cmp = icmp eq i64 %4, 6
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}
