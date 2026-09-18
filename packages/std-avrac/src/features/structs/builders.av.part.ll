; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [35 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 34 }, [35 x i8] c"names and values disagree in count\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emarks_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Efields_zipped"(ptr, ptr, ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ebuild_struct_lit$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ebuild_struct_lit"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ebuild_type_decl$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ebuild_type_decl"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ebuild_struct_lit"(ptr %0) {
entry:
  %slot23 = alloca i64, align 8
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
  %10 = call i64 @avra_array_len(ptr %regval6)
  %11 = call i64 @avra_array_len(ptr %regval12)
  %cmp13 = icmp ne i64 %10, %11
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 1)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret17:                                        ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif16

lhead:                                            ; preds = %lbody, %endif16
  %ld = load i64, ptr %slot, align 8
  %cmp19 = icmp slt i64 %ld, %14
  br i1 %cmp19, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %15 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @avra_array_sized(i64 0)
  %17 = call i64 @avra_array_len(ptr %13)
  store i64 0, ptr %slot23, align 8
  br label %lhead24

lbody:                                            ; preds = %lhead
  %ld20 = load i64, ptr %slot, align 8
  %18 = call i64 @avra_array_get(ptr %regval6, i64 %ld20)
  %boxed = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed21 = inttoptr i64 %19 to ptr
  call void @avra_array_push_owned(ptr %13, ptr %boxed21)
  %ld22 = load i64, ptr %slot, align 8
  %add = add i64 %ld22, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead24:                                          ; preds = %lbody28, %lexit
  %ld26 = load i64, ptr %slot23, align 8
  %cmp27 = icmp slt i64 %ld26, %17
  br i1 %cmp27, label %lbody28, label %lexit25

lexit25:                                          ; preds = %lhead24
  %20 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %20, i64 18)
  call void @avra_array_push_owned(ptr %20, ptr %15)
  call void @avra_array_push_owned(ptr %20, ptr %16)
  call void @avra_array_push_owned(ptr %20, ptr %regval12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %21

lbody28:                                          ; preds = %lhead24
  %ld29 = load i64, ptr %slot23, align 8
  %22 = call ptr @avra_array_get_owned(ptr %13, i64 %ld29)
  call void @avra_rc_retain(ptr %22)
  call void @avra_array_push_owned(ptr %16, ptr %22)
  %ld30 = load i64, ptr %slot23, align 8
  %add31 = add i64 %ld30, 1
  store i64 %add31, ptr %slot23, align 8
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %22)
  br label %lhead24
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ebuild_type_decl"(ptr %0) {
entry:
  %slot58 = alloca i64, align 8
  %slot39 = alloca i64, align 8
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
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 3)
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
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 4)
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
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 5)
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
  %19 = call ptr @avra_array_sized(i64 0)
  %20 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret29:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif28

lhead:                                            ; preds = %lbody, %endif28
  %ld = load i64, ptr %slot, align 8
  %cmp31 = icmp slt i64 %ld, %20
  br i1 %cmp31, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %21 = call i64 @avra_array_len(ptr %regval30)
  %cmp35 = icmp eq i64 %21, 0
  %not = xor i1 %cmp35, true
  br i1 %not, label %then36, label %else37

lbody:                                            ; preds = %lhead
  %ld32 = load i64, ptr %slot, align 8
  %22 = call i64 @avra_array_get(ptr %regval6, i64 %ld32)
  %boxed = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed33 = inttoptr i64 %23 to ptr
  call void @avra_array_push_owned(ptr %19, ptr %boxed33)
  %ld34 = load i64, ptr %slot, align 8
  %add = add i64 %ld34, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then36:                                           ; preds = %lexit
  %24 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %24)
  %25 = call ptr @avra_array_sized(i64 0)
  %26 = call i64 @avra_array_len(ptr %19)
  store i64 0, ptr %slot39, align 8
  br label %lhead40

else37:                                           ; preds = %lexit
  br label %endif38

endif38:                                          ; preds = %else37, %postret49
  %regval50 = phi i64 [ 0, %postret49 ], [ 0, %else37 ]
  %27 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed51 = inttoptr i64 %27 to ptr
  call void @avra_rc_retain(ptr %boxed51)
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarks_at"(ptr %boxed51, i64 6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval12)
  call void @avra_rc_retain(ptr %regval18)
  call void @avra_rc_retain(ptr %regval24)
  call void @avra_rc_retain(ptr %28)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Efields_zipped"(ptr %0, ptr %regval12, ptr %regval18, ptr %regval24, ptr %28)
  %30 = call i64 @avra_array_get(ptr %29, i64 0)
  %cmp52 = icmp eq i64 %30, 0
  br i1 %cmp52, label %then53, label %else54

lhead40:                                          ; preds = %lbody44, %then36
  %ld42 = load i64, ptr %slot39, align 8
  %cmp43 = icmp slt i64 %ld42, %26
  br i1 %cmp43, label %lbody44, label %lexit41

lexit41:                                          ; preds = %lhead40
  %31 = call i64 @avra_array_get(ptr %regval30, i64 0)
  %boxed48 = inttoptr i64 %31 to ptr
  %32 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %32, i64 19)
  call void @avra_array_push_owned(ptr %32, ptr %24)
  call void @avra_array_push_owned(ptr %32, ptr %25)
  call void @avra_array_push_owned(ptr %32, ptr %boxed48)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %32)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %32)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %24)
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
  ret ptr %33

lbody44:                                          ; preds = %lhead40
  %ld45 = load i64, ptr %slot39, align 8
  %34 = call ptr @avra_array_get_owned(ptr %19, i64 %ld45)
  call void @avra_rc_retain(ptr %34)
  call void @avra_array_push_owned(ptr %25, ptr %34)
  %ld46 = load i64, ptr %slot39, align 8
  %add47 = add i64 %ld46, 1
  store i64 %add47, ptr %slot39, align 8
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %34)
  br label %lhead40

postret49:                                        ; No predecessors!
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %24)
  br label %endif38

then53:                                           ; preds = %endif38
  %35 = call ptr @avra_array_get_owned(ptr %29, i64 1)
  br label %endif55

else54:                                           ; preds = %endif38
  call void @avra_rc_release(ptr %28)
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
  ret ptr %29

endif55:                                          ; preds = %postret56, %then53
  %regval57 = phi ptr [ %35, %then53 ], [ null, %postret56 ]
  %36 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  call void @avra_rc_retain(ptr %36)
  %37 = call ptr @avra_array_sized(i64 0)
  %38 = call i64 @avra_array_len(ptr %19)
  store i64 0, ptr %slot58, align 8
  br label %lhead59

postret56:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif55

lhead59:                                          ; preds = %lbody63, %endif55
  %ld61 = load i64, ptr %slot58, align 8
  %cmp62 = icmp slt i64 %ld61, %38
  br i1 %cmp62, label %lbody63, label %lexit60

lexit60:                                          ; preds = %lhead59
  %39 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %39, i64 18)
  call void @avra_array_push_owned(ptr %39, ptr %36)
  call void @avra_array_push_owned(ptr %39, ptr %37)
  call void @avra_array_push_owned(ptr %39, ptr %regval57)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %39)
  %40 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %39)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %regval57)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
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
  ret ptr %40

lbody63:                                          ; preds = %lhead59
  %ld64 = load i64, ptr %slot58, align 8
  %41 = call ptr @avra_array_get_owned(ptr %19, i64 %ld64)
  call void @avra_rc_retain(ptr %41)
  call void @avra_array_push_owned(ptr %37, ptr %41)
  %ld65 = load i64, ptr %slot58, align 8
  %add66 = add i64 %ld65, 1
  store i64 %add66, ptr %slot58, align 8
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %41)
  br label %lhead59
}
