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

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotate"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmt"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Ebuild_mark$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Ebuild_mark"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Ebuild_annotated$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Ebuild_annotated"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Ebuild_mark"(ptr %0) {
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
  %4 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  %5 = call i64 @avra_array_get(ptr %regval, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_str_len(ptr %boxed)
  %7 = call ptr @avra_str_substring(ptr %4, i64 1, i64 %6)
  %8 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 1)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp1 = icmp eq i64 %10, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %11 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %11, %then2 ], [ null, %postret5 ]
  %12 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

lhead:                                            ; preds = %lbody, %endif4
  %ld = load i64, ptr %slot, align 8
  %cmp7 = icmp slt i64 %ld, %12
  br i1 %cmp7, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %13 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %cmp12 = icmp ne ptr %13, null
  br i1 %cmp12, label %then13, label %else14

lbody:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot, align 8
  %14 = call i64 @avra_array_get(ptr %regval6, i64 %ld8)
  %boxed9 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed9, i64 1)
  %boxed10 = inttoptr i64 %15 to ptr
  call void @avra_array_push_owned(ptr %8, ptr %boxed10)
  %ld11 = load i64, ptr %slot, align 8
  %add = add i64 %ld11, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then13:                                           ; preds = %lexit
  call void @avra_rc_retain(ptr %13)
  br label %endif15

else14:                                           ; preds = %lexit
  %16 = call ptr @avra_array_get_owned(ptr %regval, i64 2)
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval16 = phi ptr [ %13, %then13 ], [ %16, %else14 ]
  %17 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %17, ptr %7)
  call void @avra_array_push_owned(ptr %17, ptr %8)
  call void @avra_array_push_owned(ptr %17, ptr %regval16)
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 6)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  %19 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %19, i64 0)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval16)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %19
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Ebuild_annotated"(ptr %0) {
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
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmt"(ptr %0, i64 2)
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
  %11 = call i64 @avra_array_get(ptr %regval, i64 1)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_str_len(ptr %boxed)
  %13 = call ptr @avra_str_substring(ptr %10, i64 1, i64 %12)
  %14 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed13 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %13)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 4)
  call void @avra_array_push_owned(ptr %15, ptr %13)
  %16 = call i64 @avra_array_get(ptr %regval, i64 2)
  %boxed14 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %boxed13)
  call void @avra_rc_retain(ptr %15)
  call void @avra_rc_retain(ptr %boxed14)
  %17 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %boxed13, ptr %15, ptr %boxed14)
  %18 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %19 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed15 = inttoptr i64 %19 to ptr
  %20 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %20, ptr %13)
  call void @avra_array_push(ptr %20, i64 %17)
  call void @avra_array_push_owned(ptr %20, ptr %regval6)
  call void @avra_array_push_owned(ptr %20, ptr %boxed15)
  call void @avra_rc_retain(ptr %18)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotate"(ptr %18, i64 %regval12, ptr %20)
  %22 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %22, i64 1)
  call void @avra_array_push(ptr %22, i64 %regval12)
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 0)
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

postret11:                                        ; No predecessors!
  br label %endif10
}
