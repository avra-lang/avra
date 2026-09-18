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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Etoken_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebuild_comp$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebuild_comp"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebuild_list$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebuild_list"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebuild_comp"(ptr %0) {
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
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etoken_at"(ptr %boxed, i64 1)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp1 = icmp eq i64 %7, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %8, %then2 ], [ null, %postret5 ]
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 3)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp7 = icmp eq i64 %10, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %11 = call i64 @avra_array_get(ptr %9, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi i64 [ %11, %then8 ], [ 0, %postret11 ]
  call void @avra_rc_retain(ptr %5)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Escoped_at"(ptr %5)
  %13 = call ptr @avra_array_get_owned(ptr %regval6, i64 1)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed13 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed13)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr %boxed13, i64 4)
  %16 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed14 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %boxed14)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr %boxed14, i64 5)
  %18 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %18, i64 9)
  call void @avra_array_push(ptr %18, i64 %regval)
  call void @avra_array_push_owned(ptr %18, ptr %12)
  call void @avra_array_push_owned(ptr %18, ptr %13)
  call void @avra_array_push(ptr %18, i64 %regval12)
  call void @avra_array_push_owned(ptr %18, ptr %15)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %19

postret11:                                        ; No predecessors!
  br label %endif10
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Escoped_at"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebuild_list"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %1 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_id_at"(ptr %boxed, i64 0)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 8)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 1)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp1 = icmp eq i64 %10, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  br label %endif

then2:                                            ; preds = %endif
  %11 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %11, %then2 ], [ null, %postret5 ]
  %12 = call ptr @avra_array_concat(ptr %8, ptr %regval6)
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 8)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4
}
