; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [47 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 46 }, [47 x i8] c"a hole is empty \E2\80\94 `${e}` takes an expression\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"block holes\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"(lexing)\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24275"(ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Egrammar$2EToken$2Eint_value"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24161"(ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_sublang"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2488"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ezip_defect_of"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuild_sublang$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuild_sublang"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuild_syntax_decl$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuild_syntax_decl"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuild_sublang"(ptr %0) {
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
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 1)
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
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexprs"(ptr %0, i64 3)
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
  %16 = call i64 @avra_array_len(ptr %regval12)
  %17 = call i64 @avra_array_len(ptr %regval18)
  %cmp25 = icmp ne i64 %16, %17
  br i1 %cmp25, label %then26, label %else27

postret23:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif22

then26:                                           ; preds = %endif22
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 1)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
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
  ret ptr %18

else27:                                           ; preds = %endif22
  br label %endif28

endif28:                                          ; preds = %else27, %postret29
  %regval30 = phi i64 [ 0, %postret29 ], [ 0, %else27 ]
  %19 = call i64 @avra_array_len(ptr %regval24)
  %20 = call i64 @avra_array_len(ptr %regval18)
  %cmp31 = icmp ne i64 %19, %20
  br i1 %cmp31, label %then32, label %else33

postret29:                                        ; No predecessors!
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif28

then32:                                           ; preds = %endif28
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ezip_defect_of"(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %22 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %22, i64 1)
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
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

else33:                                           ; preds = %endif28
  br label %endif34

endif34:                                          ; preds = %else33, %postret35
  %regval36 = phi i64 [ 0, %postret35 ], [ 0, %else33 ]
  %23 = call i64 @avra_array_get(ptr %regval, i64 1)
  %boxed = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %regval6)
  call void @avra_rc_retain(ptr %regval18)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eexpanded"(ptr %0, ptr %boxed, ptr %regval6, ptr %regval18)
  %25 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed37 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %regval6, i64 2)
  %boxed38 = inttoptr i64 %26 to ptr
  %27 = call i64 @avra_array_get(ptr %boxed38, i64 0)
  %28 = call i64 @avra_array_get(ptr %regval6, i64 2)
  %boxed39 = inttoptr i64 %28 to ptr
  %29 = call i64 @avra_array_get(ptr %boxed39, i64 1)
  call void @avra_rc_retain(ptr %boxed37)
  call void @avra_rc_retain(ptr %regval12)
  call void @avra_rc_retain(ptr %regval24)
  %30 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Eruns"(ptr %boxed37, i64 %27, i64 %29, ptr %regval12, ptr %regval24)
  %cmp40 = icmp ne ptr %24, null
  %not = xor i1 %cmp40, true
  br i1 %not, label %then41, label %else42

postret35:                                        ; No predecessors!
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif34

then41:                                           ; preds = %endif34
  %31 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %31, i64 0)
  br label %endif43

else42:                                           ; preds = %endif34
  %32 = call i64 @avra_array_get(ptr %24, i64 0)
  %33 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %33, i64 2)
  call void @avra_array_push(ptr %33, i64 %32)
  br label %endif43

endif43:                                          ; preds = %else42, %then41
  %regval44 = phi ptr [ %31, %then41 ], [ %33, %else42 ]
  %34 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %35 = call i64 @avra_array_get(ptr %regval, i64 1)
  %boxed45 = inttoptr i64 %35 to ptr
  %36 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %36, i64 13)
  call void @avra_array_push_owned(ptr %36, ptr %boxed45)
  call void @avra_array_push_owned(ptr %36, ptr %30)
  call void @avra_array_push_owned(ptr %36, ptr %regval18)
  call void @avra_array_push_owned(ptr %36, ptr %regval44)
  %37 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed46 = inttoptr i64 %37 to ptr
  call void @avra_rc_retain(ptr %34)
  call void @avra_rc_retain(ptr %36)
  call void @avra_rc_retain(ptr %boxed46)
  %38 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %34, ptr %36, ptr %boxed46)
  %39 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed47 = inttoptr i64 %39 to ptr
  %40 = call i64 @avra_array_get(ptr %regval6, i64 2)
  %boxed48 = inttoptr i64 %40 to ptr
  %41 = call i64 @avra_array_get(ptr %boxed48, i64 0)
  call void @avra_rc_retain(ptr %boxed47)
  %42 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_sublang"(ptr %boxed47, i64 %38, i64 %41)
  %43 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %43, i64 0)
  call void @avra_array_push(ptr %43, i64 %38)
  %44 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %44, i64 0)
  call void @avra_array_push_owned(ptr %44, ptr %43)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %regval44)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %24)
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
  ret ptr %44
}

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Eruns"(ptr, i64, i64, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eexpanded"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot67 = alloca ptr, align 8
  store ptr null, ptr %slot67, align 8
  %slot66 = alloca i64, align 8
  %slot42 = alloca i64, align 8
  %slot12 = alloca ptr, align 8
  store ptr null, ptr %slot12, align 8
  %slot11 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l109" to i64))
  call void @avra_array_push_owned(ptr %4, ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  %not = xor i1 %cmp5, true
  br i1 %not, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %8)
  %cast = inttoptr i64 %5 to ptr
  %9 = call i1 %cast(ptr %4, ptr %8)
  br i1 %9, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot)
  store ptr %8, ptr %slot, align 8
  store i64 %7, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead

then6:                                            ; preds = %lexit
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else7:                                            ; preds = %lexit
  br label %endif8

endif8:                                           ; preds = %else7, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else7 ]
  %10 = call ptr @avra_insist(ptr %ld4)
  %11 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %13 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed10 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed10)
  %14 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_body"(ptr %boxed10)
  %15 = call ptr @avra_array_get_owned(ptr %14, i64 3)
  %16 = call i64 @avra_array_len(ptr %15)
  store i64 0, ptr %slot11, align 8
  br label %lhead13

postret:                                          ; No predecessors!
  br label %endif8

lhead13:                                          ; preds = %lbody17, %endif8
  %ld15 = load i64, ptr %slot11, align 8
  %cmp16 = icmp slt i64 %ld15, %16
  br i1 %cmp16, label %lbody17, label %lexit14

lexit14:                                          ; preds = %lhead13
  %17 = call i64 @avra_array_get(ptr %14, i64 3)
  %boxed30 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_len(ptr %boxed30)
  %cmp31 = icmp eq i64 %18, 0
  %not32 = xor i1 %cmp31, true
  br i1 %not32, label %then33, label %else34

lbody17:                                          ; preds = %lhead13
  %ld18 = load i64, ptr %slot11, align 8
  %19 = call ptr @avra_array_get_owned(ptr %15, i64 %ld18)
  call void @avra_rc_retain(ptr %19)
  call void @avra_cell_release(ptr %slot12)
  store ptr %19, ptr %slot12, align 8
  %20 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed19 = inttoptr i64 %20 to ptr
  %ld20 = load ptr, ptr %slot12, align 8
  %21 = call i64 @avra_array_get(ptr %ld20, i64 0)
  %boxed21 = inttoptr i64 %21 to ptr
  %ld22 = load ptr, ptr %slot12, align 8
  %22 = call i64 @avra_array_get(ptr %ld22, i64 1)
  %boxed23 = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_array_get(ptr %boxed23, i64 0)
  %add24 = add i64 %23, %12
  %ld25 = load ptr, ptr %slot12, align 8
  %24 = call i64 @avra_array_get(ptr %ld25, i64 1)
  %boxed26 = inttoptr i64 %24 to ptr
  %25 = call i64 @avra_array_get(ptr %boxed26, i64 1)
  %add27 = add i64 %25, %12
  %26 = call ptr @avra_array_sized(i64 0)
  %27 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %27, ptr %boxed21)
  call void @avra_array_push(ptr %27, i64 %add24)
  call void @avra_array_push(ptr %27, i64 %add27)
  call void @avra_array_push_owned(ptr %27, ptr %26)
  call void @avra_array_push_owned(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %boxed19)
  call void @avra_rc_retain(ptr %27)
  %28 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Espeak_block"(ptr %boxed19, ptr %27)
  %ld28 = load i64, ptr %slot11, align 8
  %add29 = add i64 %ld28, 1
  store i64 %add29, ptr %slot11, align 8
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %19)
  br label %lhead13

then33:                                           ; preds = %lexit14
  call void @avra_cell_release(ptr %slot12)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else34:                                           ; preds = %lexit14
  br label %endif35

endif35:                                          ; preds = %else34, %postret36
  %regval37 = phi i64 [ 0, %postret36 ], [ 0, %else34 ]
  %29 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed38 = inttoptr i64 %29 to ptr
  %30 = call i64 @avra_array_get(ptr %boxed38, i64 0)
  %boxed39 = inttoptr i64 %30 to ptr
  call void @avra_rc_retain(ptr %boxed39)
  %31 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24275"(ptr %boxed39)
  %32 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %33 = call i64 @avra_array_get(ptr %10, i64 1)
  %boxed40 = inttoptr i64 %33 to ptr
  %34 = call i64 @avra_array_get(ptr %boxed40, i64 0)
  %boxed41 = inttoptr i64 %34 to ptr
  %35 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l169" to i64))
  call void @avra_array_push_owned(ptr %35, ptr %32)
  call void @avra_array_push_owned(ptr %35, ptr %boxed41)
  call void @avra_array_push_owned(ptr %35, ptr %3)
  %36 = call ptr @avra_array_sized(i64 0)
  %37 = call ptr @avra_array_get_owned(ptr %14, i64 0)
  %38 = call i64 @avra_array_len(ptr %37)
  store i64 0, ptr %slot42, align 8
  br label %lhead43

postret36:                                        ; No predecessors!
  br label %endif35

lhead43:                                          ; preds = %endif54, %endif35
  %ld45 = load i64, ptr %slot42, align 8
  %cmp46 = icmp slt i64 %ld45, %38
  br i1 %cmp46, label %lbody47, label %lexit44

lexit44:                                          ; preds = %lhead43
  %39 = call ptr @avra_array_get_owned(ptr %10, i64 1)
  %40 = call i64 @avra_array_get(ptr %10, i64 1)
  %boxed60 = inttoptr i64 %40 to ptr
  %41 = call i64 @avra_array_get(ptr %boxed60, i64 0)
  %boxed61 = inttoptr i64 %41 to ptr
  %42 = call i64 @avra_array_get(ptr %boxed61, i64 1)
  %boxed62 = inttoptr i64 %42 to ptr
  call void @avra_rc_retain(ptr %39)
  call void @avra_rc_retain(ptr %boxed62)
  call void @avra_rc_retain(ptr %36)
  call void @avra_rc_retain(ptr %35)
  %43 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Erun_from$2488"(ptr %39, ptr %boxed62, ptr %36, ptr %35)
  %44 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %45 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed63 = inttoptr i64 %45 to ptr
  %46 = call i64 @avra_array_get(ptr %boxed63, i64 0)
  %boxed64 = inttoptr i64 %46 to ptr
  call void @avra_rc_retain(ptr %boxed64)
  %47 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24275"(ptr %boxed64)
  %48 = call i64 @avra_array_get(ptr %10, i64 2)
  %boxed65 = inttoptr i64 %48 to ptr
  call void @avra_rc_retain(ptr %44)
  call void @avra_rc_retain(ptr %boxed65)
  %49 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Enote_foreign"(ptr %44, i64 %31, i64 %47, ptr %boxed65)
  %50 = call ptr @avra_array_get_owned(ptr %43, i64 1)
  %51 = call i64 @avra_array_len(ptr %50)
  store i64 0, ptr %slot66, align 8
  br label %lhead68

lbody47:                                          ; preds = %lhead43
  %ld48 = load i64, ptr %slot42, align 8
  %52 = call ptr @avra_array_get_owned(ptr %37, i64 %ld48)
  %53 = call i64 @avra_array_get(ptr %52, i64 0)
  %boxed49 = inttoptr i64 %53 to ptr
  %54 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %54, i64 7)
  %55 = call i64 @avra_array_get(ptr %boxed49, i64 0)
  %56 = call i64 @avra_array_get(ptr %54, i64 0)
  %cmp50 = icmp eq i64 %55, %56
  %not51 = xor i1 %cmp50, true
  br i1 %not51, label %then52, label %else53

then52:                                           ; preds = %lbody47
  %57 = call i64 @avra_array_get(ptr %52, i64 2)
  %boxed55 = inttoptr i64 %57 to ptr
  call void @avra_rc_retain(ptr %boxed55)
  %58 = call ptr @"av_$40std$2Eavrac$2Ecore$2ESpan$2Eshifted"(ptr %boxed55, i64 %12)
  %59 = call ptr @avra_array_get_owned(ptr %52, i64 0)
  %60 = call i64 @avra_array_get(ptr %52, i64 1)
  %boxed56 = inttoptr i64 %60 to ptr
  %61 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %61, ptr %59)
  call void @avra_array_push_owned(ptr %61, ptr %boxed56)
  call void @avra_array_push_owned(ptr %61, ptr %58)
  call void @avra_array_push_owned(ptr %36, ptr %61)
  call void @avra_rc_release(ptr %61)
  call void @avra_rc_release(ptr %59)
  call void @avra_rc_release(ptr %58)
  br label %endif54

else53:                                           ; preds = %lbody47
  br label %endif54

endif54:                                          ; preds = %else53, %then52
  %regval57 = phi i64 [ 0, %then52 ], [ 0, %else53 ]
  %ld58 = load i64, ptr %slot42, align 8
  %add59 = add i64 %ld58, 1
  store i64 %add59, ptr %slot42, align 8
  call void @avra_rc_release(ptr %54)
  call void @avra_rc_release(ptr %52)
  br label %lhead43

lhead68:                                          ; preds = %endif96, %lexit44
  %ld70 = load i64, ptr %slot66, align 8
  %cmp71 = icmp slt i64 %ld70, %51
  br i1 %cmp71, label %lbody72, label %lexit69

lexit69:                                          ; preds = %lhead68
  %62 = call i64 @avra_array_get(ptr %43, i64 1)
  %boxed105 = inttoptr i64 %62 to ptr
  %63 = call i64 @avra_array_len(ptr %boxed105)
  %cmp106 = icmp eq i64 %63, 0
  %not107 = xor i1 %cmp106, true
  br i1 %not107, label %then108, label %else109

lbody72:                                          ; preds = %lhead68
  %ld73 = load i64, ptr %slot66, align 8
  %64 = call ptr @avra_array_get_owned(ptr %50, i64 %ld73)
  call void @avra_rc_retain(ptr %64)
  call void @avra_cell_release(ptr %slot67)
  store ptr %64, ptr %slot67, align 8
  %65 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %ld74 = load ptr, ptr %slot67, align 8
  call void @avra_rc_retain(ptr %ld74)
  %66 = call ptr @avra_array_get_owned(ptr %ld74, i64 1)
  %ld75 = load ptr, ptr %slot67, align 8
  call void @avra_rc_retain(ptr %ld75)
  %67 = call ptr @avra_array_get_owned(ptr %ld75, i64 2)
  %cmp76 = icmp ne ptr %67, null
  br i1 %cmp76, label %then77, label %else78

then77:                                           ; preds = %lbody72
  %68 = call i64 @avra_array_get(ptr %67, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %68, 1
  br label %endif79

else78:                                           ; preds = %lbody72
  br label %endif79

endif79:                                          ; preds = %else78, %then77
  %regval80 = phi { i1, i64 } [ %pack, %then77 ], [ zeroinitializer, %else78 ]
  %x = extractvalue { i1, i64 } %regval80, 0
  br i1 %x, label %then81, label %else82

then81:                                           ; preds = %endif79
  %x84 = extractvalue { i1, i64 } %regval80, 1
  br label %endif83

else82:                                           ; preds = %endif79
  br label %endif83

endif83:                                          ; preds = %else82, %then81
  %regval85 = phi i64 [ %x84, %then81 ], [ %12, %else82 ]
  %ld86 = load ptr, ptr %slot67, align 8
  call void @avra_rc_retain(ptr %ld86)
  %69 = call ptr @avra_array_get_owned(ptr %ld86, i64 2)
  %cmp87 = icmp ne ptr %69, null
  br i1 %cmp87, label %then88, label %else89

then88:                                           ; preds = %endif83
  %70 = call i64 @avra_array_get(ptr %69, i64 1)
  %pack91 = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %70, 1
  br label %endif90

else89:                                           ; preds = %endif83
  br label %endif90

endif90:                                          ; preds = %else89, %then88
  %regval92 = phi { i1, i64 } [ %pack91, %then88 ], [ zeroinitializer, %else89 ]
  %x93 = extractvalue { i1, i64 } %regval92, 0
  br i1 %x93, label %then94, label %else95

then94:                                           ; preds = %endif90
  %x97 = extractvalue { i1, i64 } %regval92, 1
  br label %endif96

else95:                                           ; preds = %endif90
  br label %endif96

endif96:                                          ; preds = %else95, %then94
  %regval98 = phi i64 [ %x97, %then94 ], [ %12, %else95 ]
  %ld99 = load ptr, ptr %slot67, align 8
  %71 = call i64 @avra_array_get(ptr %ld99, i64 3)
  %boxed100 = inttoptr i64 %71 to ptr
  %ld101 = load ptr, ptr %slot67, align 8
  %72 = call i64 @avra_array_get(ptr %ld101, i64 4)
  %boxed102 = inttoptr i64 %72 to ptr
  %73 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %73, ptr %66)
  call void @avra_array_push(ptr %73, i64 %regval85)
  call void @avra_array_push(ptr %73, i64 %regval98)
  call void @avra_array_push_owned(ptr %73, ptr %boxed100)
  call void @avra_array_push_owned(ptr %73, ptr %boxed102)
  call void @avra_rc_retain(ptr %65)
  call void @avra_rc_retain(ptr %73)
  %74 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Espeak_block"(ptr %65, ptr %73)
  %ld103 = load i64, ptr %slot66, align 8
  %add104 = add i64 %ld103, 1
  store i64 %add104, ptr %slot66, align 8
  call void @avra_rc_release(ptr %73)
  call void @avra_rc_release(ptr %69)
  call void @avra_rc_release(ptr %ld86)
  call void @avra_rc_release(ptr %67)
  call void @avra_rc_release(ptr %ld75)
  call void @avra_rc_release(ptr %66)
  call void @avra_rc_release(ptr %ld74)
  call void @avra_rc_release(ptr %65)
  call void @avra_rc_release(ptr %64)
  br label %lhead68

then108:                                          ; preds = %lexit69
  br label %endif110

else109:                                          ; preds = %lexit69
  %75 = call i64 @avra_array_get(ptr %43, i64 0)
  %boxed111 = inttoptr i64 %75 to ptr
  %cmp112 = icmp ne ptr %boxed111, null
  %not113 = xor i1 %cmp112, true
  br label %endif110

endif110:                                         ; preds = %else109, %then108
  %regval114 = phi i1 [ true, %then108 ], [ %not113, %else109 ]
  br i1 %regval114, label %then115, label %else116

then115:                                          ; preds = %endif110
  call void @avra_cell_release(ptr %slot67)
  call void @avra_cell_release(ptr %slot12)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else116:                                          ; preds = %endif110
  br label %endif117

endif117:                                         ; preds = %else116, %postret118
  %regval119 = phi i64 [ 0, %postret118 ], [ 0, %else116 ]
  %76 = call i64 @avra_array_get(ptr %43, i64 0)
  %boxed120 = inttoptr i64 %76 to ptr
  %77 = call ptr @avra_insist(ptr %boxed120)
  call void @avra_rc_retain(ptr %32)
  call void @avra_rc_retain(ptr %77)
  call void @avra_rc_retain(ptr %3)
  %78 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Ecaptured_expr"(ptr %32, ptr %77, ptr %3)
  call void @avra_cell_release(ptr %slot67)
  call void @avra_cell_release(ptr %slot12)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %77)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %78

postret118:                                       ; No predecessors!
  br label %endif117
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l169"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Elisted_seats"(ptr %boxed, ptr %1, i64 %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed1 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed1)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Eminted_action"(ptr %4, ptr %1, ptr %7, ptr %2, ptr %3, ptr %boxed1)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l109"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Eminted_action"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot = alloca i64, align 8
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %9, i64 17)
  call void @avra_array_push_owned(ptr %9, ptr %1)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %4)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %9, ptr %4)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 1)
  call void @avra_array_push(ptr %11, i64 %10)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 0)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %13 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  %boxed = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %b = icmp ne i64 %14, 0
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Eseated"(ptr %0, ptr %boxed, i1 %b, ptr %4, ptr %5)
  call void @avra_array_push(ptr %6, i64 %15)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Eseated"(ptr %0, ptr %1, i1 %2, ptr %3, ptr %4) {
entry:
  %not = xor i1 %2, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Ecaptured_expr"(ptr %0, ptr %1, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then1, label %else2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %6, label %arm6 [
    i64 2, label %arm
    i64 3, label %arm5
  ]

then1:                                            ; preds = %then
  %7 = call i64 @avra_array_get(ptr %5, i64 0)
  br label %endif3

else2:                                            ; preds = %then
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 21)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %3)
  %9 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %8, ptr %3)
  call void @avra_rc_release(ptr %8)
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval = phi i64 [ %7, %then1 ], [ %9, %else2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif

arm:                                              ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Ecaptured_expr"(ptr %0, ptr %1, ptr %4)
  %cmp7 = icmp ne ptr %10, null
  br i1 %cmp7, label %then8, label %else9

arm5:                                             ; preds = %endif
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 8)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %3)
  %13 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %12, ptr %3)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

arm6:                                             ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Ecaptured_expr"(ptr %0, ptr %1, ptr %4)
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2488"(ptr %14)
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 8)
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %3)
  %17 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %16, ptr %3)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  br label %endswitch

endswitch:                                        ; preds = %arm6, %arm5, %endif10
  %regval12 = phi i64 [ %regval11, %endif10 ], [ %13, %arm5 ], [ %17, %arm6 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval12

then8:                                            ; preds = %arm
  %18 = call i64 @avra_array_get(ptr %10, i64 0)
  br label %endif10

else9:                                            ; preds = %arm
  %19 = call ptr @avra_array_sized(i64 0)
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %20, i64 8)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %3)
  %21 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %20, ptr %3)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i64 [ %18, %then8 ], [ %21, %else9 ]
  call void @avra_rc_release(ptr %10)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Ecaptured_expr"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %3, label %arm3 [
    i64 1, label %arm
    i64 3, label %arm1
    i64 2, label %arm2
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm3:                                             ; preds = %entry
  %9 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed6 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed6, i64 0)
  switch i64 %11, label %arm9 [
    i64 10, label %arm7
    i64 1, label %arm8
  ]

endswitch:                                        ; preds = %endswitch10, %lexit, %arm1, %arm
  %regval17 = phi ptr [ %5, %arm ], [ null, %arm1 ], [ %15, %lexit ], [ %regval16, %endswitch10 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval17

lhead:                                            ; preds = %lbody, %arm2
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %7)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr %7)
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 8)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %13, ptr null)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %16 = call i64 @avra_array_get(ptr %6, i64 %ld4)
  %boxed = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ENodeStore$2Ecaptured_expr"(ptr %0, ptr %boxed, ptr %2)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2488"(ptr %17)
  call void @avra_array_push_owned(ptr %7, ptr %18)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %lhead

arm7:                                             ; preds = %arm3
  %19 = call i64 @avra_array_get(ptr %9, i64 1)
  %boxed11 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %boxed11)
  call void @avra_rc_retain(ptr %2)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ehole_expr"(ptr %boxed11, ptr %2)
  br label %endswitch10

arm8:                                             ; preds = %arm3
  call void @avra_rc_retain(ptr %9)
  %21 = call { i1, i64 } @"av_$40std$2Eavrac$2Egrammar$2EToken$2Eint_value"(ptr %9)
  %x = extractvalue { i1, i64 } %21, 0
  br i1 %x, label %then, label %else

arm9:                                             ; preds = %arm3
  %22 = call i64 @avra_array_get(ptr %9, i64 1)
  %boxed14 = inttoptr i64 %22 to ptr
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 2)
  call void @avra_array_push_owned(ptr %23, ptr %boxed14)
  %24 = call i64 @avra_array_get(ptr %9, i64 2)
  %boxed15 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  call void @avra_rc_retain(ptr %boxed15)
  %25 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %23, ptr %boxed15)
  %26 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %26, i64 %25)
  call void @avra_rc_release(ptr %23)
  br label %endswitch10

endswitch10:                                      ; preds = %arm9, %endif, %arm7
  %regval16 = phi ptr [ %20, %arm7 ], [ %30, %endif ], [ %26, %arm9 ]
  call void @avra_rc_release(ptr %9)
  br label %endswitch

then:                                             ; preds = %arm8
  %x12 = extractvalue { i1, i64 } %21, 1
  br label %endif

else:                                             ; preds = %arm8
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %x12, %then ], [ 0, %else ]
  %27 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %27, i64 0)
  call void @avra_array_push(ptr %27, i64 %regval)
  %28 = call i64 @avra_array_get(ptr %9, i64 2)
  %boxed13 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  call void @avra_rc_retain(ptr %boxed13)
  %29 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %0, ptr %27, ptr %boxed13)
  %30 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %30, i64 %29)
  call void @avra_rc_release(ptr %27)
  br label %endswitch10
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ehole_expr"(ptr %0, ptr %1) {
entry:
  %slot = alloca { i1, i64 }, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr %0)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  store { i1, i64 } zeroinitializer, ptr %slot, align 8
  %5 = call i64 @avra_array_len(ptr %4)
  %cmp1 = icmp slt i64 0, %5
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %6, 1
  store { i1, i64 } %pack, ptr %slot, align 8
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i64 [ 0, %then2 ], [ 0, %else3 ]
  %ld = load { i1, i64 }, ptr %slot, align 8
  %x = extractvalue { i1, i64 } %ld, 0
  %not6 = xor i1 %x, true
  br i1 %not6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %x10 = extractvalue { i1, i64 } %ld, 0
  %x11 = extractvalue { i1, i64 } %ld, 1
  %slot12 = zext i1 %x10 to i64
  %7 = call i64 @avra_insist_scalar(i64 %slot12, i64 %x11)
  %8 = call i64 @avra_array_len(ptr %1)
  %cmp13 = icmp sge i64 %7, %8
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval14 = phi i1 [ true, %then7 ], [ %cmp13, %else8 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif9
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else16:                                           ; preds = %endif9
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  %x20 = extractvalue { i1, i64 } %ld, 0
  %x21 = extractvalue { i1, i64 } %ld, 1
  %slot22 = zext i1 %x20 to i64
  %9 = call i64 @avra_insist_scalar(i64 %slot22, i64 %x21)
  %10 = call i64 @avra_array_get(ptr %1, i64 %9)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 %10)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

postret18:                                        ; No predecessors!
  br label %endif17
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Elisted_seats"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot31 = alloca i64, align 8
  %slot20 = alloca i64, align 8
  %slot6 = alloca i64, align 8
  %slot5 = alloca ptr, align 8
  store ptr null, ptr %slot5, align 8
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24161"(ptr %3)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot5)
  store ptr null, ptr %slot5, align 8
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l254" to i64))
  call void @avra_array_push_owned(ptr %7, ptr %1)
  call void @avra_array_push(ptr %7, i64 %2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %9 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot6, align 8
  br label %lhead7

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  %boxed3 = inttoptr i64 %12 to ptr
  call void @avra_array_push_owned(ptr %3, ptr %boxed3)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead7:                                           ; preds = %endif, %lexit
  %ld9 = load i64, ptr %slot6, align 8
  %cmp10 = icmp slt i64 %ld9, %9
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load ptr, ptr %slot5, align 8
  call void @avra_rc_retain(ptr %ld15)
  %cmp16 = icmp ne ptr %ld15, null
  %not = xor i1 %cmp16, true
  br i1 %not, label %then17, label %else18

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot6, align 8
  %13 = call ptr @avra_array_get_owned(ptr %6, i64 %ld12)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %13)
  %cast = inttoptr i64 %8 to ptr
  %14 = call i1 %cast(ptr %7, ptr %13)
  br i1 %14, label %then, label %else

then:                                             ; preds = %lbody11
  call void @avra_rc_retain(ptr %13)
  call void @avra_cell_release(ptr %slot5)
  store ptr %13, ptr %slot5, align 8
  store i64 %9, ptr %slot6, align 8
  br label %endif

else:                                             ; preds = %lbody11
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld13 = load i64, ptr %slot6, align 8
  %add14 = add i64 %ld13, 1
  store i64 %add14, ptr %slot6, align 8
  call void @avra_rc_release(ptr %13)
  br label %lhead7

then17:                                           ; preds = %lexit8
  %15 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot20, align 8
  br label %lhead21

else18:                                           ; preds = %lexit8
  br label %endif19

endif19:                                          ; preds = %else18, %postret
  %regval29 = phi i64 [ 0, %postret ], [ 0, %else18 ]
  %16 = call ptr @avra_insist(ptr %ld15)
  %17 = call ptr @avra_array_sized(i64 0)
  %18 = call i64 @avra_array_get(ptr %16, i64 1)
  %boxed30 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %boxed30)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eaction_labels"(ptr %boxed30)
  %20 = call i64 @avra_array_len(ptr %19)
  store i64 0, ptr %slot31, align 8
  br label %lhead32

lhead21:                                          ; preds = %lbody25, %then17
  %ld23 = load i64, ptr %slot20, align 8
  %cmp24 = icmp slt i64 %ld23, %2
  br i1 %cmp24, label %lbody25, label %lexit22

lexit22:                                          ; preds = %lhead21
  call void @avra_cell_release(ptr %slot5)
  call void @avra_rc_release(ptr %ld15)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

lbody25:                                          ; preds = %lhead21
  %ld26 = load i64, ptr %slot20, align 8
  call void @avra_array_push(ptr %15, i64 0)
  %ld27 = load i64, ptr %slot20, align 8
  %add28 = add i64 %ld27, 1
  store i64 %add28, ptr %slot20, align 8
  br label %lhead21

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %15)
  br label %endif19

lhead32:                                          ; preds = %lbody36, %endif19
  %ld34 = load i64, ptr %slot31, align 8
  %cmp35 = icmp slt i64 %ld34, %20
  br i1 %cmp35, label %lbody36, label %lexit33

lexit33:                                          ; preds = %lhead32
  call void @avra_cell_release(ptr %slot5)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %ld15)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

lbody36:                                          ; preds = %lhead32
  %ld37 = load i64, ptr %slot31, align 8
  %21 = call i64 @avra_array_get(ptr %19, i64 %ld37)
  %boxed38 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %16, i64 0)
  %boxed39 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %boxed39)
  call void @avra_rc_retain(ptr %boxed38)
  %23 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eaccumulates"(ptr %boxed39, ptr %boxed38, i1 false)
  %slot40 = zext i1 %23 to i64
  call void @avra_array_push(ptr %17, i64 %slot40)
  %ld41 = load i64, ptr %slot31, align 8
  %add42 = add i64 %ld41, 1
  store i64 %add42, ptr %slot31, align 8
  br label %lhead32
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l254"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ecalls"(ptr %1, ptr %2, i64 %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ecalls"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %boxed1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 1, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %9 = call i64 @avra_streq(ptr %7, ptr %1)
  %b = icmp ne i64 %9, 0
  br i1 %b, label %then3, label %else4

arm2:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif5
  %regval8 = phi i1 [ %regval7, %endif5 ], [ false, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval8

then3:                                            ; preds = %arm
  %10 = call i64 @avra_array_len(ptr %8)
  %cmp6 = icmp eq i64 %10, %2
  br label %endif5

else4:                                            ; preds = %arm
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval7 = phi i1 [ %cmp6, %then3 ], [ false, %else4 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eaccumulates"(ptr %0, ptr %1, i1 %2) {
entry:
  %slot2 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l309" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  %slot1 = zext i1 %2 to i64
  call void @avra_array_push(ptr %3, i64 %slot1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld5

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot2, align 8
  %6 = call i64 @avra_array_get(ptr %0, i64 %ld3)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %4 to ptr
  %7 = call i1 %cast(ptr %3, ptr %boxed)
  br i1 %7, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %5, ptr %slot2, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld4 = load i64, ptr %slot2, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot2, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l309"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %3, 0
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eitem_accumulates"(ptr %1, ptr %2, i1 %b)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eitem_accumulates"(ptr %0, ptr %1, i1 %2) {
entry:
  %slot22 = alloca i64, align 8
  %slot = alloca i1, align 1
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %cmp = icmp eq i64 %4, 1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  br label %endif3

else2:                                            ; preds = %endif
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed4 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %cmp5 = icmp eq i64 %6, 2
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval6 = phi i1 [ true, %then1 ], [ %cmp5, %else2 ]
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %cmp7 = icmp ne ptr %7, null
  br i1 %cmp7, label %then8, label %else9

then8:                                            ; preds = %endif3
  %8 = call i64 @avra_streq(ptr %7, ptr %1)
  %b = icmp ne i64 %8, 0
  br label %endif10

else9:                                            ; preds = %endif3
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i1 [ %b, %then8 ], [ false, %else9 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif10
  br label %endif14

else13:                                           ; preds = %endif10
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi i1 [ %regval6, %then12 ], [ false, %else13 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif14
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else17:                                           ; preds = %endif14
  br label %endif18

endif18:                                          ; preds = %else17, %postret
  %regval19 = phi i64 [ 0, %postret ], [ 0, %else17 ]
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  switch i64 %10, label %arm20 [
    i64 3, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif18

arm:                                              ; preds = %endif18
  %11 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  store i1 false, ptr %slot, align 8
  %12 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %12, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l335" to i64))
  call void @avra_array_push_owned(ptr %12, ptr %1)
  %slot21 = zext i1 %regval6 to i64
  call void @avra_array_push(ptr %12, i64 %slot21)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %14 = call ptr @avra_array_get_owned(ptr %11, i64 0)
  %15 = call i64 @avra_array_len(ptr %14)
  store i64 0, ptr %slot22, align 8
  br label %lhead

arm20:                                            ; preds = %endif18
  br label %endswitch

endswitch:                                        ; preds = %arm20, %lexit
  %regval32 = phi i1 [ %ld31, %lexit ], [ false, %arm20 ]
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval32

lhead:                                            ; preds = %endif28, %arm
  %ld = load i64, ptr %slot22, align 8
  %cmp23 = icmp slt i64 %ld, %15
  br i1 %cmp23, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld31 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld24 = load i64, ptr %slot22, align 8
  %16 = call i64 @avra_array_get(ptr %14, i64 %ld24)
  %boxed25 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %boxed25)
  %cast = inttoptr i64 %13 to ptr
  %17 = call i1 %cast(ptr %12, ptr %boxed25)
  br i1 %17, label %then26, label %else27

then26:                                           ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %15, ptr %slot22, align 8
  br label %endif28

else27:                                           ; preds = %lbody
  br label %endif28

endif28:                                          ; preds = %else27, %then26
  %regval29 = phi i64 [ 0, %then26 ], [ 0, %else27 ]
  %ld30 = load i64, ptr %slot22, align 8
  %add = add i64 %ld30, 1
  store i64 %add, ptr %slot22, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuilders$24l335"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %4, 0
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eaccumulates"(ptr %boxed, ptr %3, i1 %b)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Eaction_labels"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 1, label %arm
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif

arm:                                              ; preds = %endif
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endswitch

arm1:                                             ; preds = %endif
  %5 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval2 = phi ptr [ %4, %arm ], [ %5, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval2
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Enote_foreign"(ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Erun_from$2488"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ESpan$2Eshifted"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Espeak_block"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_body"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Ebuild_syntax_decl"(ptr %0) {
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
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr %0, i64 1)
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
  %8 = call i64 @avra_array_get(ptr %regval6, i64 1)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %9, i64 22)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
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
