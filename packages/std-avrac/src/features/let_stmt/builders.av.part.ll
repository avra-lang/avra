; ModuleID = 'avra'
source_filename = "avra"

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2488"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etrailed"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_discard$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_discard"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_let_else$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_let_else"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_let$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_let"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_discard"(ptr %0) {
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
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 5)
  call void @avra_array_push(ptr %4, i64 %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_let_else"(ptr %0) {
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
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp1 = icmp eq i64 %5, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi i64 [ %6, %then2 ], [ 0, %postret5 ]
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr %boxed, i64 2)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2488"(ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etrailed"(ptr %0, i64 %regval6, ptr %9)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp7 = icmp eq i64 %11, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  br label %endif4

then8:                                            ; preds = %endif4
  %12 = call i64 @avra_array_get(ptr %10, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi i64 [ %12, %then8 ], [ 0, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmts"(ptr %0, i64 3)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %cmp13 = icmp eq i64 %14, 0
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  br label %endif10

then14:                                           ; preds = %endif10
  %15 = call ptr @avra_array_get_owned(ptr %13, i64 1)
  br label %endif16

else15:                                           ; preds = %endif10
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

endif16:                                          ; preds = %postret17, %then14
  %regval18 = phi ptr [ %15, %then14 ], [ null, %postret17 ]
  %16 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %16)
  %17 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %17, i64 14)
  call void @avra_array_push_owned(ptr %17, ptr %16)
  call void @avra_array_push(ptr %17, i64 %regval12)
  call void @avra_array_push_owned(ptr %17, ptr %regval18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

postret17:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif16
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Ebuild_let"(ptr %0) {
entry:
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
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %9 = call i64 @avra_array_get(ptr %7, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi i64 [ %9, %then8 ], [ 0, %postret11 ]
  %10 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %11 = call i64 @avra_array_len(ptr %regval6)
  %cmp13 = icmp slt i64 0, %11
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  br label %endif10

then14:                                           ; preds = %endif10
  %12 = call ptr @avra_array_get_owned(ptr %regval6, i64 0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot)
  store ptr %12, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  br label %endif16

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi i64 [ 0, %then14 ], [ 0, %else15 ]
  %ld = load ptr, ptr %slot, align 8
  %13 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %13, i64 0)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  call void @avra_array_push_owned(ptr %13, ptr %ld)
  call void @avra_array_push(ptr %13, i64 %regval12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %13)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14
}
