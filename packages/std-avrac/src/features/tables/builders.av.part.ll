; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"defect: a table row that is not a cell list\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"row \00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c" has \00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [30 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 29 }, [30 x i8] c" cells, and the header names \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c" columns\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eelems_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Ebuild_row$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Ebuild_row"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Ebuild_table$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Ebuild_table"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Ebuild_row"(ptr %0) {
entry:
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
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 8)
  call void @avra_array_push_owned(ptr %4, ptr %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Ebuild_table"(ptr %0) {
entry:
  %slot41 = alloca i64, align 8
  %slot19 = alloca i64, align 8
  %slot18 = alloca i64, align 8
  %slot17 = alloca ptr, align 8
  store ptr null, ptr %slot17, align 8
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
  %10 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

lhead:                                            ; preds = %lbody, %endif10
  %ld = load i64, ptr %slot, align 8
  %cmp13 = icmp slt i64 %ld, %12
  br i1 %cmp13, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %13 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %13)
  call void @avra_cell_release(ptr %slot17)
  store ptr %13, ptr %slot17, align 8
  %14 = call i64 @avra_array_len(ptr %regval12)
  store i64 0, ptr %slot18, align 8
  br label %lhead20

lbody:                                            ; preds = %lhead
  %ld14 = load i64, ptr %slot, align 8
  %15 = call i64 @avra_array_get(ptr %regval6, i64 %ld14)
  %boxed = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed15 = inttoptr i64 %16 to ptr
  call void @avra_array_push_owned(ptr %11, ptr %boxed15)
  %ld16 = load i64, ptr %slot, align 8
  %add = add i64 %ld16, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead20:                                          ; preds = %lexit43, %lexit
  %ld22 = load i64, ptr %slot18, align 8
  %cmp23 = icmp slt i64 %ld22, %14
  br i1 %cmp23, label %lbody24, label %lexit21

lexit21:                                          ; preds = %lhead20
  %ld54 = load ptr, ptr %slot17, align 8
  %17 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %17, i64 8)
  call void @avra_array_push_owned(ptr %17, ptr %ld54)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %17)
  call void @avra_cell_release(ptr %slot17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

lbody24:                                          ; preds = %lhead20
  %ld25 = load i64, ptr %slot18, align 8
  %19 = call i64 @avra_array_get(ptr %regval12, i64 %ld25)
  store i64 %19, ptr %slot19, align 8
  %20 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed26 = inttoptr i64 %20 to ptr
  %ld27 = load i64, ptr %slot19, align 8
  call void @avra_rc_retain(ptr %boxed26)
  %21 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed26, i64 %ld27)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eelems_of"(ptr %21)
  %cmp28 = icmp ne ptr %22, null
  %not = xor i1 %cmp28, true
  br i1 %not, label %then29, label %else30

then29:                                           ; preds = %lbody24
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 1)
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_cell_release(ptr %slot17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

else30:                                           ; preds = %lbody24
  br label %endif31

endif31:                                          ; preds = %else30, %postret32
  %regval33 = phi i64 [ 0, %postret32 ], [ 0, %else30 ]
  %24 = call ptr @avra_insist(ptr %22)
  %25 = call i64 @avra_array_len(ptr %24)
  %26 = call i64 @avra_array_len(ptr %11)
  %cmp34 = icmp ne i64 %25, %26
  br i1 %cmp34, label %then35, label %else36

postret32:                                        ; No predecessors!
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif31

then35:                                           ; preds = %endif31
  %add38 = add i64 %ld25, 1
  %27 = call ptr @avra_int_text(i64 %add38)
  %28 = call i64 @avra_array_len(ptr %24)
  %29 = call ptr @avra_int_text(i64 %28)
  %30 = call i64 @avra_array_len(ptr %11)
  %31 = call ptr @avra_int_text(i64 %30)
  %32 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %32, ptr %27)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %32, ptr %29)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %32, ptr %31)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %33 = call ptr @avra_str_join(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %34 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %34, i64 1)
  call void @avra_array_push_owned(ptr %34, ptr %33)
  call void @avra_cell_release(ptr %slot17)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %34

else36:                                           ; preds = %endif31
  br label %endif37

endif37:                                          ; preds = %else36, %postret39
  %regval40 = phi i64 [ 0, %postret39 ], [ 0, %else36 ]
  %35 = call ptr @avra_cell_unique(ptr %slot17)
  %36 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %10)
  %37 = call ptr @avra_array_sized(i64 0)
  %38 = call i64 @avra_array_len(ptr %11)
  store i64 0, ptr %slot41, align 8
  br label %lhead42

postret39:                                        ; No predecessors!
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif37

lhead42:                                          ; preds = %lbody46, %endif37
  %ld44 = load i64, ptr %slot41, align 8
  %cmp45 = icmp slt i64 %ld44, %38
  br i1 %cmp45, label %lbody46, label %lexit43

lexit43:                                          ; preds = %lhead42
  %39 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %39, i64 18)
  call void @avra_array_push_owned(ptr %39, ptr %10)
  call void @avra_array_push_owned(ptr %39, ptr %37)
  call void @avra_array_push_owned(ptr %39, ptr %24)
  %40 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed50 = inttoptr i64 %40 to ptr
  %ld51 = load i64, ptr %slot19, align 8
  call void @avra_rc_retain(ptr %boxed50)
  %41 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr %boxed50, i64 %ld51)
  call void @avra_rc_retain(ptr %36)
  call void @avra_rc_retain(ptr %39)
  call void @avra_rc_retain(ptr %41)
  %42 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %36, ptr %39, ptr %41)
  call void @avra_array_push(ptr %35, i64 %42)
  %ld52 = load i64, ptr %slot18, align 8
  %add53 = add i64 %ld52, 1
  store i64 %add53, ptr %slot18, align 8
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  br label %lhead20

lbody46:                                          ; preds = %lhead42
  %ld47 = load i64, ptr %slot41, align 8
  %43 = call ptr @avra_array_get_owned(ptr %11, i64 %ld47)
  call void @avra_rc_retain(ptr %43)
  call void @avra_array_push_owned(ptr %37, ptr %43)
  %ld48 = load i64, ptr %slot41, align 8
  %add49 = add i64 %ld48, 1
  store i64 %add49, ptr %slot41, align 8
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %43)
  br label %lhead42
}
