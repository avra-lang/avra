; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [47 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 46 }, [47 x i8] c"a hole is empty \E2\80\94 `${e}` takes an expression\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"quote holes\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [43 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 42 }, [43 x i8] c"a quote holds arms or statements, not both\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"quote\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eanswer_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_quote_at"(ptr, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat_span"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Earms_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ezip_defect_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Eruns"(ptr, i64, i64, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ebuild_quote$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ebuild_quote"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ebuild_quote"(ptr %0) {
entry:
  %slot50 = alloca i64, align 8
  %slot = alloca i1, align 1
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
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Earms_at"(ptr %boxed, i64 1)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmts"(ptr %0, i64 2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp1 = icmp eq i64 %7, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %8, %then2 ], [ null, %postret5 ]
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 3)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp7 = icmp eq i64 %10, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %11 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi ptr [ %11, %then8 ], [ null, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 4)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp13 = icmp eq i64 %13, 0
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  %14 = call ptr @avra_array_get_owned(ptr %12, i64 1)
  br label %endif16

else15:                                           ; preds = %endif10
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

endif16:                                          ; preds = %postret17, %then14
  %regval18 = phi ptr [ %14, %then14 ], [ null, %postret17 ]
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 5)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %cmp19 = icmp eq i64 %16, 0
  br i1 %cmp19, label %then20, label %else21

postret17:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif16

then20:                                           ; preds = %endif16
  %17 = call ptr @avra_array_get_owned(ptr %15, i64 1)
  br label %endif22

else21:                                           ; preds = %endif16
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

endif22:                                          ; preds = %postret23, %then20
  %regval24 = phi ptr [ %17, %then20 ], [ null, %postret23 ]
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 6)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp25 = icmp eq i64 %19, 0
  br i1 %cmp25, label %then26, label %else27

postret23:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif22

then26:                                           ; preds = %endif22
  %20 = call ptr @avra_array_get_owned(ptr %18, i64 1)
  br label %endif28

else27:                                           ; preds = %endif22
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

endif28:                                          ; preds = %postret29, %then26
  %regval30 = phi ptr [ %20, %then26 ], [ null, %postret29 ]
  %21 = call i64 @avra_array_len(ptr %regval18)
  %22 = call i64 @avra_array_len(ptr %regval24)
  %cmp31 = icmp ne i64 %21, %22
  br i1 %cmp31, label %then32, label %else33

postret29:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif28

then32:                                           ; preds = %endif28
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 1)
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %regval30)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

else33:                                           ; preds = %endif28
  br label %endif34

endif34:                                          ; preds = %else33, %postret35
  %regval36 = phi i64 [ 0, %postret35 ], [ 0, %else33 ]
  %24 = call i64 @avra_array_len(ptr %regval30)
  %25 = call i64 @avra_array_len(ptr %regval24)
  %cmp37 = icmp ne i64 %24, %25
  br i1 %cmp37, label %then38, label %else39

postret35:                                        ; No predecessors!
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif34

then38:                                           ; preds = %endif34
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ezip_defect_of"(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %27 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %27, i64 1)
  call void @avra_array_push_owned(ptr %27, ptr %26)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %regval30)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %27

else39:                                           ; preds = %endif34
  br label %endif40

endif40:                                          ; preds = %else39, %postret41
  %regval42 = phi i64 [ 0, %postret41 ], [ 0, %else39 ]
  %28 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed43 = inttoptr i64 %28 to ptr
  %29 = call i64 @avra_array_get(ptr %regval, i64 2)
  %boxed44 = inttoptr i64 %29 to ptr
  %30 = call i64 @avra_array_get(ptr %boxed44, i64 1)
  %31 = call i64 @avra_array_get(ptr %regval12, i64 2)
  %boxed45 = inttoptr i64 %31 to ptr
  %32 = call i64 @avra_array_get(ptr %boxed45, i64 0)
  call void @avra_rc_retain(ptr %boxed43)
  call void @avra_rc_retain(ptr %regval18)
  call void @avra_rc_retain(ptr %regval30)
  %33 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Eruns"(ptr %boxed43, i64 %30, i64 %32, ptr %regval18, ptr %regval30)
  %34 = call i64 @avra_array_len(ptr %5)
  %cmp46 = icmp eq i64 %34, 0
  %not = xor i1 %cmp46, true
  br i1 %not, label %then47, label %else48

postret41:                                        ; No predecessors!
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif40

then47:                                           ; preds = %endif40
  store i1 true, ptr %slot, align 8
  %35 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ebuilders$24l64" to i64))
  call void @avra_array_push_owned(ptr %35, ptr %0)
  %36 = call i64 @avra_array_get(ptr %35, i64 0)
  %37 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot50, align 8
  br label %lhead

else48:                                           ; preds = %endif40
  br label %endif49

endif49:                                          ; preds = %else48, %lexit
  %regval61 = phi i1 [ %not60, %lexit ], [ false, %else48 ]
  br i1 %regval61, label %then62, label %else63

lhead:                                            ; preds = %endif56, %then47
  %ld = load i64, ptr %slot50, align 8
  %cmp51 = icmp slt i64 %ld, %37
  br i1 %cmp51, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld59 = load i1, ptr %slot, align 8
  %not60 = xor i1 %ld59, true
  call void @avra_rc_release(ptr %35)
  br label %endif49

lbody:                                            ; preds = %lhead
  %ld52 = load i64, ptr %slot50, align 8
  %38 = call i64 @avra_array_get(ptr %regval6, i64 %ld52)
  call void @avra_rc_retain(ptr %35)
  %cast = inttoptr i64 %36 to ptr
  %39 = call i1 %cast(ptr %35, i64 %38)
  %not53 = xor i1 %39, true
  br i1 %not53, label %then54, label %else55

then54:                                           ; preds = %lbody
  store i1 false, ptr %slot, align 8
  store i64 %37, ptr %slot50, align 8
  br label %endif56

else55:                                           ; preds = %lbody
  br label %endif56

endif56:                                          ; preds = %else55, %then54
  %regval57 = phi i64 [ 0, %then54 ], [ 0, %else55 ]
  %ld58 = load i64, ptr %slot50, align 8
  %add = add i64 %ld58, 1
  store i64 %add, ptr %slot50, align 8
  br label %lhead

then62:                                           ; preds = %endif49
  %40 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %40, i64 1)
  call void @avra_array_push_owned(ptr %40, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %regval30)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %40

else63:                                           ; preds = %endif49
  br label %endif64

endif64:                                          ; preds = %else63, %postret65
  %regval66 = phi i64 [ 0, %postret65 ], [ 0, %else63 ]
  %41 = call i64 @avra_array_len(ptr %5)
  %cmp67 = icmp eq i64 %41, 0
  br i1 %cmp67, label %then68, label %else69

postret65:                                        ; No predecessors!
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif64

then68:                                           ; preds = %endif64
  call void @avra_rc_retain(ptr %regval6)
  br label %endif70

else69:                                           ; preds = %endif64
  %42 = call ptr @avra_array_sized(i64 0)
  br label %endif70

endif70:                                          ; preds = %else69, %then68
  %regval71 = phi ptr [ %regval6, %then68 ], [ %42, %else69 ]
  %43 = call i64 @avra_array_len(ptr %5)
  %cmp72 = icmp eq i64 %43, 0
  br i1 %cmp72, label %then73, label %else74

then73:                                           ; preds = %endif70
  %44 = call ptr @avra_array_sized(i64 0)
  br label %endif75

else74:                                           ; preds = %endif70
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %regval6)
  %45 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Emerged"(ptr %0, ptr %5, ptr %regval6)
  br label %endif75

endif75:                                          ; preds = %else74, %then73
  %regval76 = phi ptr [ %44, %then73 ], [ %45, %else74 ]
  %46 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %47 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %47, i64 1)
  call void @avra_array_push_owned(ptr %47, ptr %regval71)
  call void @avra_array_push_owned(ptr %47, ptr %regval76)
  %48 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %48, i64 13)
  call void @avra_array_push_owned(ptr %48, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %48, ptr %33)
  call void @avra_array_push_owned(ptr %48, ptr %regval24)
  call void @avra_array_push_owned(ptr %48, ptr %47)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed77 = inttoptr i64 %49 to ptr
  call void @avra_rc_retain(ptr %46)
  call void @avra_rc_retain(ptr %48)
  call void @avra_rc_retain(ptr %boxed77)
  %50 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %46, ptr %48, ptr %boxed77)
  %51 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed78 = inttoptr i64 %51 to ptr
  call void @avra_rc_retain(ptr %boxed78)
  %52 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_quote_at"(ptr %boxed78, i64 %50)
  %53 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %53, i64 0)
  call void @avra_array_push(ptr %53, i64 %50)
  %54 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %54, i64 0)
  call void @avra_array_push_owned(ptr %54, ptr %53)
  call void @avra_rc_release(ptr %53)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %47)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %regval76)
  call void @avra_rc_release(ptr %regval71)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %regval30)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %54
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ebuilders$24l64"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr %boxed1, i64 %1)
  %x = extractvalue { i1, i64 } %4, 0
  call void @avra_rc_release(ptr %0)
  ret i1 %x
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Emerged"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot)
  store ptr %3, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif22, %entry
  %ld = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %then, label %else

lexit:                                            ; preds = %endif
  %ld30 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld30)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld30

then:                                             ; preds = %lhead
  br label %endif

else:                                             ; preds = %lhead
  %ld3 = load i64, ptr %slot2, align 8
  %5 = call i64 @avra_array_len(ptr %2)
  %cmp4 = icmp slt i64 %ld3, %5
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp4, %else ]
  br i1 %regval, label %lbody, label %lexit

lbody:                                            ; preds = %endif
  %ld5 = load i64, ptr %slot2, align 8
  %6 = call i64 @avra_array_len(ptr %2)
  %cmp6 = icmp sge i64 %ld5, %6
  br i1 %cmp6, label %then7, label %else8

then7:                                            ; preds = %lbody
  br label %endif9

else8:                                            ; preds = %lbody
  %ld10 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_len(ptr %1)
  %cmp11 = icmp slt i64 %ld10, %7
  br i1 %cmp11, label %then12, label %else13

endif9:                                           ; preds = %endif14, %then7
  %regval19 = phi i1 [ true, %then7 ], [ %regval18, %endif14 ]
  br i1 %regval19, label %then20, label %else21

then12:                                           ; preds = %else8
  %ld15 = load i64, ptr %slot1, align 8
  %8 = call i64 @avra_array_get(ptr %1, i64 %ld15)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Equote$2Earm_start"(ptr %0, ptr %boxed)
  %ld16 = load i64, ptr %slot2, align 8
  %10 = call i64 @avra_array_get(ptr %2, i64 %ld16)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Equote$2Estmt_start"(ptr %0, i64 %10)
  %cmp17 = icmp sle i64 %9, %11
  br label %endif14

else13:                                           ; preds = %else8
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval18 = phi i1 [ %cmp17, %then12 ], [ false, %else13 ]
  br label %endif9

then20:                                           ; preds = %endif9
  %12 = call ptr @avra_cell_unique(ptr %slot)
  %ld23 = load i64, ptr %slot1, align 8
  %13 = call i64 @avra_array_get(ptr %1, i64 %ld23)
  %boxed24 = inttoptr i64 %13 to ptr
  call void @avra_array_push_owned(ptr %12, ptr %boxed24)
  %ld25 = load i64, ptr %slot1, align 8
  %add = add i64 %ld25, 1
  store i64 %add, ptr %slot1, align 8
  br label %endif22

else21:                                           ; preds = %endif9
  %14 = call ptr @avra_cell_unique(ptr %slot)
  %ld26 = load i64, ptr %slot2, align 8
  %15 = call i64 @avra_array_get(ptr %2, i64 %ld26)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ehole_arm"(ptr %0, i64 %15)
  call void @avra_array_push_owned(ptr %14, ptr %16)
  %ld27 = load i64, ptr %slot2, align 8
  %add28 = add i64 %ld27, 1
  store i64 %add28, ptr %slot2, align 8
  call void @avra_rc_release(ptr %16)
  br label %endif22

endif22:                                          ; preds = %else21, %then20
  %regval29 = phi i64 [ 0, %then20 ], [ 0, %else21 ]
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Ehole_arm"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eanswer_of"(ptr %boxed, i64 %1)
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr %boxed1, i64 %5)
  %cmp = icmp ne ptr %7, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %7)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %7, %then ], [ getelementptr inbounds (i8, ptr @.str.4, i64 16), %else ]
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %regval)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 2)
  call void @avra_array_push_owned(ptr %9, ptr %regval)
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr %boxed2, i64 %1)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr %8, ptr %9, ptr %11)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 %12)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_array_push(ptr %14, i64 %5)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %14
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Equote$2Estmt_start"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr %boxed, i64 %1)
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
  %regval5 = phi i64 [ %x4, %then1 ], [ 0, %else2 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Equote$2Earm_start"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat_span"(ptr %boxed, i64 %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %6, 1
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %pack, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  br i1 %x, label %then2, label %else3

then2:                                            ; preds = %endif
  %x5 = extractvalue { i1, i64 } %regval, 1
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i64 [ %x5, %then2 ], [ 0, %else3 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval6
}
