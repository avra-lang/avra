; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"when arms and values\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [27 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 26 }, [27 x i8] c"a `when` needs its `_` arm\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [25 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 24 }, [25 x i8] c"a `when` has ONE `_` arm\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [43 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 42 }, [43 x i8] c"the `_` arm ends a `when` \E2\80\94 move it last\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ezip_defect_of"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2Ebuild_when$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2Ebuild_when"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2Ebuild_when"(ptr %0) {
entry:
  %slot31 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 0)
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
  %10 = call i64 @avra_array_len(ptr %regval)
  %11 = call i64 @avra_array_len(ptr %regval6)
  %cmp13 = icmp ne i64 %10, %11
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ezip_defect_of"(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 1)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %14 = call i64 @avra_array_len(ptr %regval12)
  %cmp19 = icmp eq i64 %14, 0
  br i1 %cmp19, label %then20, label %else21

postret17:                                        ; No predecessors!
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif16

then20:                                           ; preds = %endif16
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 1)
  call void @avra_array_push_owned(ptr %15, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

else21:                                           ; preds = %endif16
  br label %endif22

endif22:                                          ; preds = %else21, %postret23
  %regval24 = phi i64 [ 0, %postret23 ], [ 0, %else21 ]
  %16 = call i64 @avra_array_len(ptr %regval12)
  %cmp25 = icmp sgt i64 %16, 1
  br i1 %cmp25, label %then26, label %else27

postret23:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif22

then26:                                           ; preds = %endif22
  %17 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %17, i64 1)
  call void @avra_array_push_owned(ptr %17, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

else27:                                           ; preds = %endif22
  br label %endif28

endif28:                                          ; preds = %else27, %postret29
  %regval30 = phi i64 [ 0, %postret29 ], [ 0, %else27 ]
  %18 = call i64 @avra_array_get(ptr %regval12, i64 0)
  %19 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr %boxed, i64 %18)
  %21 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret29:                                        ; No predecessors!
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif28

lhead:                                            ; preds = %endif49, %endif28
  %ld = load i64, ptr %slot, align 8
  %cmp32 = icmp slt i64 %ld, %21
  br i1 %cmp32, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %22 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %22, i64 15)
  call void @avra_array_push_owned(ptr %22, ptr %regval)
  call void @avra_array_push_owned(ptr %22, ptr %regval6)
  call void @avra_array_push(ptr %22, i64 %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

lbody:                                            ; preds = %lhead
  %ld33 = load i64, ptr %slot, align 8
  %24 = call i64 @avra_array_get(ptr %regval6, i64 %ld33)
  store i64 %24, ptr %slot31, align 8
  %25 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed34 = inttoptr i64 %25 to ptr
  %ld35 = load i64, ptr %slot31, align 8
  call void @avra_rc_retain(ptr %boxed34)
  %26 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr %boxed34, i64 %ld35)
  %cmp36 = icmp ne ptr %20, null
  br i1 %cmp36, label %then37, label %else38

then37:                                           ; preds = %lbody
  %cmp40 = icmp ne ptr %26, null
  br label %endif39

else38:                                           ; preds = %lbody
  br label %endif39

endif39:                                          ; preds = %else38, %then37
  %regval41 = phi i1 [ %cmp40, %then37 ], [ false, %else38 ]
  br i1 %regval41, label %then42, label %else43

then42:                                           ; preds = %endif39
  %27 = call ptr @avra_insist(ptr %26)
  %28 = call i64 @avra_array_get(ptr %27, i64 0)
  %29 = call ptr @avra_insist(ptr %20)
  %30 = call i64 @avra_array_get(ptr %29, i64 0)
  %cmp45 = icmp sgt i64 %28, %30
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %27)
  br label %endif44

else43:                                           ; preds = %endif39
  br label %endif44

endif44:                                          ; preds = %else43, %then42
  %regval46 = phi i1 [ %cmp45, %then42 ], [ false, %else43 ]
  br i1 %regval46, label %then47, label %else48

then47:                                           ; preds = %endif44
  %31 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %31, i64 1)
  call void @avra_array_push_owned(ptr %31, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %31

else48:                                           ; preds = %endif44
  br label %endif49

endif49:                                          ; preds = %else48, %postret50
  %regval51 = phi i64 [ 0, %postret50 ], [ 0, %else48 ]
  %ld52 = load i64, ptr %slot, align 8
  %add = add i64 %ld52, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %26)
  br label %lhead

postret50:                                        ; No predecessors!
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif49
}
