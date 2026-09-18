; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"type\00" }, align 16

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

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eparse_program"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enew_node_store"()
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot)
  store ptr %3, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eparse_into"(ptr %0, ptr %ld, ptr %1, ptr %2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eparse_into"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot21 = alloca i64, align 8
  %slot11 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %7, ptr %boxed1)
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %8, ptr %1)
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp2 = icmp slt i64 %ld, %11
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %12 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_blocks"(ptr %9, ptr %10)
  %13 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Eprogram$24l80" to i64))
  call void @avra_array_push_owned(ptr %13, ptr %0)
  call void @avra_array_push_owned(ptr %13, ptr %1)
  call void @avra_array_push_owned(ptr %13, ptr %2)
  call void @avra_array_push_owned(ptr %13, ptr %3)
  %14 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed7 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_insist(ptr %boxed7)
  %16 = call i64 @avra_array_get(ptr %12, i64 0)
  %boxed8 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %15)
  call void @avra_rc_retain(ptr %boxed8)
  call void @avra_rc_retain(ptr %13)
  %17 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Erun_grammar$24318"(ptr %15, ptr %boxed8, ptr %13)
  %18 = call i64 @avra_array_get(ptr %12, i64 1)
  %boxed9 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed9)
  %19 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eattach_docs"(ptr %1, ptr %boxed9)
  %20 = call i64 @avra_array_get(ptr %12, i64 2)
  %boxed10 = inttoptr i64 %20 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed10)
  %21 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ekeep_remarks"(ptr %1, ptr %boxed10)
  %22 = call ptr @avra_array_sized(i64 0)
  %23 = call ptr @avra_array_get_owned(ptr %1, i64 22)
  %24 = call i64 @avra_array_len(ptr %23)
  store i64 0, ptr %slot11, align 8
  br label %lhead12

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %25 = call i64 @avra_array_get(ptr %3, i64 %ld3)
  %boxed4 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %boxed5 = inttoptr i64 %26 to ptr
  call void @avra_array_push_owned(ptr %10, ptr %boxed5)
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead12:                                          ; preds = %lbody16, %lexit
  %ld14 = load i64, ptr %slot11, align 8
  %cmp15 = icmp slt i64 %ld14, %24
  br i1 %cmp15, label %lbody16, label %lexit13

lexit13:                                          ; preds = %lhead12
  %27 = call ptr @avra_array_sized(i64 0)
  %28 = call ptr @avra_array_get_owned(ptr %12, i64 3)
  %29 = call i64 @avra_array_len(ptr %28)
  store i64 0, ptr %slot21, align 8
  br label %lhead22

lbody16:                                          ; preds = %lhead12
  %ld17 = load i64, ptr %slot11, align 8
  %30 = call i64 @avra_array_get(ptr %23, i64 %ld17)
  %boxed18 = inttoptr i64 %30 to ptr
  call void @avra_rc_retain(ptr %boxed18)
  %31 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eblock_diagnostic"(ptr %boxed18)
  call void @avra_array_push_owned(ptr %22, ptr %31)
  %ld19 = load i64, ptr %slot11, align 8
  %add20 = add i64 %ld19, 1
  store i64 %add20, ptr %slot11, align 8
  call void @avra_rc_release(ptr %31)
  br label %lhead12

lhead22:                                          ; preds = %lbody26, %lexit13
  %ld24 = load i64, ptr %slot21, align 8
  %cmp25 = icmp slt i64 %ld24, %29
  br i1 %cmp25, label %lbody26, label %lexit23

lexit23:                                          ; preds = %lhead22
  %32 = call i64 @avra_array_get(ptr %17, i64 1)
  %boxed31 = inttoptr i64 %32 to ptr
  %33 = call ptr @avra_array_concat(ptr %27, ptr %boxed31)
  %34 = call ptr @avra_array_concat(ptr %33, ptr %22)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %17)
  %35 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eprogram_stmts"(ptr %1, ptr %17)
  %36 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed32 = inttoptr i64 %36 to ptr
  %37 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed33 = inttoptr i64 %37 to ptr
  %38 = call i64 @avra_array_get(ptr %boxed33, i64 3)
  %boxed34 = inttoptr i64 %38 to ptr
  call void @avra_rc_retain(ptr %34)
  call void @avra_rc_retain(ptr %boxed32)
  call void @avra_rc_retain(ptr %boxed34)
  %39 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eproject_all"(ptr %34, ptr %boxed32, ptr %boxed34)
  %40 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %40, ptr %39)
  %41 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %41, ptr %1)
  call void @avra_array_push_owned(ptr %41, ptr %35)
  call void @avra_array_push_owned(ptr %41, ptr %2)
  call void @avra_array_push_owned(ptr %41, ptr %40)
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %41

lbody26:                                          ; preds = %lhead22
  %ld27 = load i64, ptr %slot21, align 8
  %42 = call i64 @avra_array_get(ptr %28, i64 %ld27)
  %boxed28 = inttoptr i64 %42 to ptr
  call void @avra_rc_retain(ptr %boxed28)
  %43 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_diagnostic"(ptr %boxed28)
  call void @avra_array_push_owned(ptr %27, ptr %43)
  %ld29 = load i64, ptr %slot21, align 8
  %add30 = add i64 %ld29, 1
  store i64 %add30, ptr %slot21, align 8
  call void @avra_rc_release(ptr %43)
  br label %lhead22
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eprogram$24l80"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %8 = call i64 @avra_array_get(ptr %7, i64 1)
  %boxed1 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed2 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %boxed2)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuild_named"(ptr %boxed, ptr %6, ptr %1, ptr %2, ptr %3, ptr %boxed1, ptr %boxed2)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuild_named"(ptr, ptr, ptr, ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eproject_all"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eprogram_stmts"(ptr %0, ptr %1) {
entry:
  %slot2 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %boxed1)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elist_at"(ptr %6, i64 0)
  store i64 0, ptr %slot2, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %ld)
  br label %endif

lhead:                                            ; preds = %endif10, %endif
  %ld3 = load i64, ptr %slot2, align 8
  %8 = call i64 @avra_array_len(ptr %7)
  %cmp4 = icmp slt i64 %ld3, %8
  br i1 %cmp4, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld13 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld13)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eanswered"(ptr %0, ptr %ld13)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

lbody:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %7)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_id_at"(ptr %7, i64 %ld5)
  %cmp6 = icmp ne ptr %10, null
  %not7 = xor i1 %cmp6, true
  br i1 %not7, label %then8, label %else9

then8:                                            ; preds = %lbody
  %11 = call ptr @avra_cell_unique(ptr %slot)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 24)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %0, ptr %12, ptr null)
  call void @avra_array_push(ptr %11, i64 %13)
  call void @avra_rc_release(ptr %12)
  br label %endif10

else9:                                            ; preds = %lbody
  %14 = call ptr @avra_cell_unique(ptr %slot)
  %15 = call ptr @avra_insist(ptr %10)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  call void @avra_array_push(ptr %14, i64 %16)
  call void @avra_rc_release(ptr %15)
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i64 [ 0, %then8 ], [ 0, %else9 ]
  %ld12 = load i64, ptr %slot2, align 8
  %add = add i64 %ld12, 1
  store i64 %add, ptr %slot2, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eanswered"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_id_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elist_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_diagnostic"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eblock_diagnostic"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 5)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 %3)
  call void @avra_array_push(ptr %5, i64 %4)
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %7 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %8, ptr %1)
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr %boxed)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ekeep_remarks"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eattach_docs"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot1)
  store ptr %3, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %ld3, i64 1)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estatement_after"(ptr %0, i64 %4)
  %cmp4 = icmp ne ptr %5, null
  br i1 %cmp4, label %then, label %else

then:                                             ; preds = %lbody
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %ld5 = load ptr, ptr %slot1, align 8
  %8 = call i64 @avra_array_get(ptr %ld5, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %ld6 = load ptr, ptr %slot1, align 8
  %9 = call i64 @avra_array_get(ptr %ld6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edocument"(ptr %0, i64 %7, ptr %boxed, i64 %9)
  call void @avra_rc_release(ptr %6)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edocument"(ptr, i64, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estatement_after"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Erun_grammar$24318"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Erun_from$24318"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_blocks"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Enew_node_store"()

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eparse_type_ref"(ptr %0, ptr %1) {
entry:
  %slot10 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enew_node_store"()
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot)
  store ptr %3, ptr %slot, align 8
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_source"(ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 3)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed1)
  %cmp2 = icmp eq i64 %6, 0
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %ld = load ptr, ptr %slot, align 8
  %7 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Eprogram$24l162" to i64))
  call void @avra_array_push_owned(ptr %7, ptr %0)
  call void @avra_array_push_owned(ptr %7, ptr %ld)
  call void @avra_array_push_owned(ptr %7, ptr %1)
  %8 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed9 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_insist(ptr %boxed9)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call ptr @avra_array_get_owned(ptr %4, i64 0)
  %12 = call i64 @avra_array_len(ptr %11)
  store i64 0, ptr %slot10, align 8
  br label %lhead

postret7:                                         ; No predecessors!
  br label %endif6

lhead:                                            ; preds = %endif19, %endif6
  %ld11 = load i64, ptr %slot10, align 8
  %cmp12 = icmp slt i64 %ld11, %12
  br i1 %cmp12, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %7)
  %13 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Erun_from$24318"(ptr %9, ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %10, ptr %7)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %boxed22 = inttoptr i64 %14 to ptr
  %cmp23 = icmp ne ptr %boxed22, null
  %not24 = xor i1 %cmp23, true
  br i1 %not24, label %then25, label %else26

lbody:                                            ; preds = %lhead
  %ld13 = load i64, ptr %slot10, align 8
  %15 = call ptr @avra_array_get_owned(ptr %11, i64 %ld13)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %boxed14 = inttoptr i64 %16 to ptr
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 7)
  %18 = call i64 @avra_array_get(ptr %boxed14, i64 0)
  %19 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp15 = icmp eq i64 %18, %19
  %not16 = xor i1 %cmp15, true
  br i1 %not16, label %then17, label %else18

then17:                                           ; preds = %lbody
  call void @avra_array_push_owned(ptr %10, ptr %15)
  br label %endif19

else18:                                           ; preds = %lbody
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval20 = phi i64 [ 0, %then17 ], [ 0, %else18 ]
  %ld21 = load i64, ptr %slot10, align 8
  %add = add i64 %ld21, 1
  store i64 %add, ptr %slot10, align 8
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  br label %lhead

then25:                                           ; preds = %lexit
  br label %endif27

else26:                                           ; preds = %lexit
  %20 = call i64 @avra_array_get(ptr %13, i64 1)
  %boxed28 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_len(ptr %boxed28)
  %cmp29 = icmp eq i64 %21, 0
  %not30 = xor i1 %cmp29, true
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval31 = phi i1 [ true, %then25 ], [ %not30, %else26 ]
  br i1 %regval31, label %then32, label %else33

then32:                                           ; preds = %endif27
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else33:                                           ; preds = %endif27
  br label %endif34

endif34:                                          ; preds = %else33, %postret35
  %regval36 = phi i64 [ 0, %postret35 ], [ 0, %else33 ]
  %22 = call i64 @avra_array_get(ptr %13, i64 0)
  %boxed37 = inttoptr i64 %22 to ptr
  %23 = call ptr @avra_insist(ptr %boxed37)
  %24 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %24, ptr %23)
  call void @avra_rc_retain(ptr %24)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_ref_at"(ptr %24, i64 0)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %25

postret35:                                        ; No predecessors!
  br label %endif34
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eprogram$24l162"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuild_named"(ptr %boxed, ptr %6, ptr %1, ptr %2, ptr %3, ptr %boxed1, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_ref_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_source"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Enew_dispatch"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_types" to i64))
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_accepts" to i64))
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_binds" to i64))
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_types" to i64))
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_accepts" to i64))
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_binds" to i64))
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241255" to i64))
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Elower" to i64))
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2EStrSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241267" to i64))
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241267" to i64))
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2EStrSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2EStrSemantics$2Elower" to i64))
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Ekids$241211" to i64))
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241211" to i64))
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241211" to i64))
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2EBoolSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2EBoolSemantics$2Elower" to i64))
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Eheirs" to i64))
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Elower" to i64))
  %12 = call ptr @avra_array_sized(i64 0)
  %13 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Eheirs" to i64))
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241223" to i64))
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Elower" to i64))
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Ekids$241199" to i64))
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Eheirs" to i64))
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Elower" to i64))
  %16 = call ptr @avra_array_sized(i64 0)
  %17 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %17, ptr %16)
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241207" to i64))
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Elower" to i64))
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_array_push(ptr %19, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %19, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Eheirs" to i64))
  call void @avra_array_push(ptr %19, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %19, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %19, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Elower" to i64))
  %20 = call ptr @avra_array_sized(i64 0)
  %21 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %21, ptr %20)
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241224" to i64))
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Elower" to i64))
  %22 = call ptr @avra_array_sized(i64 0)
  %23 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_array_push(ptr %23, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %23, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Eheirs" to i64))
  call void @avra_array_push(ptr %23, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %23, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %23, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Elower" to i64))
  %24 = call ptr @avra_array_sized(i64 0)
  %25 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %25, ptr %24)
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Eheirs" to i64))
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Elower" to i64))
  %26 = call ptr @avra_array_sized(i64 0)
  %27 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %27, ptr %26)
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241246" to i64))
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Elower" to i64))
  %28 = call ptr @avra_array_sized(i64 0)
  %29 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %29, ptr %28)
  call void @avra_array_push(ptr %29, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2EQuoteSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %29, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241213" to i64))
  call void @avra_array_push(ptr %29, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241213" to i64))
  call void @avra_array_push(ptr %29, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2EQuoteSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %29, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2EQuoteSemantics$2Elower" to i64))
  %30 = call ptr @avra_array_sized(i64 0)
  %31 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %31, ptr %30)
  call void @avra_array_push(ptr %31, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESublangSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %31, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241219" to i64))
  call void @avra_array_push(ptr %31, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241219" to i64))
  call void @avra_array_push(ptr %31, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESublangSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %31, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESublangSemantics$2Elower" to i64))
  %32 = call ptr @avra_array_sized(i64 0)
  %33 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %33, ptr %32)
  call void @avra_array_push(ptr %33, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Eresolve_stmt$241220" to i64))
  call void @avra_array_push(ptr %33, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESyntaxSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %33, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241220" to i64))
  %34 = call ptr @avra_array_sized(i64 0)
  %35 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %35, ptr %34)
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2ELetStmtSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2ELetStmtSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2ELetStmtSemantics$2Elower_stmt" to i64))
  %36 = call ptr @avra_array_sized(i64 0)
  %37 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %37, ptr %36)
  call void @avra_array_push(ptr %37, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2EExprStmtSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %37, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2EExprStmtSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %37, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2EExprStmtSemantics$2Elower_stmt" to i64))
  %38 = call ptr @avra_array_sized(i64 0)
  %39 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %39, ptr %38)
  call void @avra_array_push(ptr %39, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnStmtSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %39, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnStmtSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %39, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241208" to i64))
  %40 = call ptr @avra_array_sized(i64 0)
  %41 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %41, ptr %40)
  call void @avra_array_push(ptr %41, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Eresolve_stmt$241198" to i64))
  call void @avra_array_push(ptr %41, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241198" to i64))
  call void @avra_array_push(ptr %41, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_spine$2EHoleSemantics$2Elower_stmt" to i64))
  %42 = call ptr @avra_array_sized(i64 0)
  %43 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %43, ptr %42)
  call void @avra_array_push(ptr %43, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EMutLetSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %43, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EMutLetSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %43, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EMutLetSemantics$2Elower_stmt" to i64))
  %44 = call ptr @avra_array_sized(i64 0)
  %45 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %45, ptr %44)
  call void @avra_array_push(ptr %45, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Econsts$2EConstSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %45, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Econsts$2EConstSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %45, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Econsts$2EConstSemantics$2Elower_stmt" to i64))
  %46 = call ptr @avra_array_sized(i64 0)
  %47 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %47, ptr %46)
  call void @avra_array_push(ptr %47, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EAssignSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %47, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EAssignSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %47, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EAssignSemantics$2Elower_stmt" to i64))
  %48 = call ptr @avra_array_sized(i64 0)
  %49 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %49, ptr %48)
  call void @avra_array_push(ptr %49, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %49, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %49, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Elower_stmt" to i64))
  %50 = call ptr @avra_array_sized(i64 0)
  %51 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %51, ptr %50)
  call void @avra_array_push(ptr %51, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %51, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %51, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Elower_stmt" to i64))
  %52 = call ptr @avra_array_sized(i64 0)
  %53 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %53, ptr %52)
  call void @avra_array_push(ptr %53, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructDeclSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %53, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241225" to i64))
  call void @avra_array_push(ptr %53, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241225" to i64))
  %54 = call ptr @avra_array_sized(i64 0)
  %55 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %55, ptr %54)
  call void @avra_array_push(ptr %55, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2ENamedTypeSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %55, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241226" to i64))
  call void @avra_array_push(ptr %55, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241226" to i64))
  %56 = call ptr @avra_array_sized(i64 0)
  %57 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %57, ptr %56)
  call void @avra_array_push(ptr %57, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumDeclSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %57, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumDeclSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %57, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241234" to i64))
  %58 = call ptr @avra_array_sized(i64 0)
  %59 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %59, ptr %58)
  call void @avra_array_push(ptr %59, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfStmtSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %59, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfStmtSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %59, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfStmtSemantics$2Elower_stmt" to i64))
  %60 = call ptr @avra_array_sized(i64 0)
  %61 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %61, ptr %60)
  call void @avra_array_push(ptr %61, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EReturnSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %61, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EReturnSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %61, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EReturnSemantics$2Elower_stmt" to i64))
  %62 = call ptr @avra_array_sized(i64 0)
  %63 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %63, ptr %62)
  call void @avra_array_push(ptr %63, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ELetElseSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %63, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ELetElseSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %63, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ELetElseSemantics$2Elower_stmt" to i64))
  %64 = call ptr @avra_array_sized(i64 0)
  %65 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %65, ptr %64)
  call void @avra_array_push(ptr %65, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %65, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %65, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Elower_stmt" to i64))
  %66 = call ptr @avra_array_sized(i64 0)
  %67 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %67, ptr %66)
  call void @avra_array_push(ptr %67, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %67, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %67, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Elower_stmt" to i64))
  %68 = call ptr @avra_array_sized(i64 0)
  %69 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %69, ptr %68)
  call void @avra_array_push(ptr %69, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EImplSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %69, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EImplSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %69, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241252" to i64))
  %70 = call ptr @avra_array_sized(i64 0)
  %71 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %71, ptr %70)
  call void @avra_array_push(ptr %71, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %71, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241251" to i64))
  call void @avra_array_push(ptr %71, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %71, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %71, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Elower" to i64))
  %72 = call ptr @avra_array_sized(i64 0)
  %73 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %73, ptr %72)
  call void @avra_array_push(ptr %73, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %73, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241253" to i64))
  call void @avra_array_push(ptr %73, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Eresolve" to i64))
  call void @avra_array_push(ptr %73, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %73, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Elower" to i64))
  %74 = call ptr @avra_array_sized(i64 0)
  %75 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %75, ptr %74)
  call void @avra_array_push(ptr %75, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2EMapsSemantics$2Ekids" to i64))
  call void @avra_array_push(ptr %75, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241262" to i64))
  call void @avra_array_push(ptr %75, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241262" to i64))
  call void @avra_array_push(ptr %75, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2EMapsSemantics$2Etype_of" to i64))
  call void @avra_array_push(ptr %75, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2EMapsSemantics$2Elower" to i64))
  %76 = call ptr @avra_array_sized(i64 0)
  %77 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %77, ptr %76)
  call void @avra_array_push(ptr %77, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2EUseSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %77, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241265" to i64))
  call void @avra_array_push(ptr %77, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241265" to i64))
  %78 = call ptr @avra_array_sized(i64 0)
  %79 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %79, ptr %78)
  call void @avra_array_push(ptr %79, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Especs$2ESpecSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %79, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241266" to i64))
  call void @avra_array_push(ptr %79, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241266" to i64))
  %80 = call ptr @avra_array_sized(i64 0)
  %81 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %81, ptr %80)
  call void @avra_array_push(ptr %81, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2EDeferSemantics$2Eresolve_stmt" to i64))
  call void @avra_array_push(ptr %81, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2EDeferSemantics$2Etype_stmt" to i64))
  call void @avra_array_push(ptr %81, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2EDeferSemantics$2Elower_stmt" to i64))
  %82 = call ptr @avra_array_sized(i64 41)
  call void @avra_array_push_owned(ptr %82, ptr %5)
  call void @avra_array_push_owned(ptr %82, ptr %7)
  call void @avra_array_push_owned(ptr %82, ptr %9)
  call void @avra_array_push_owned(ptr %82, ptr %11)
  call void @avra_array_push_owned(ptr %82, ptr %13)
  call void @avra_array_push_owned(ptr %82, ptr %15)
  call void @avra_array_push_owned(ptr %82, ptr %17)
  call void @avra_array_push_owned(ptr %82, ptr %19)
  call void @avra_array_push_owned(ptr %82, ptr %21)
  call void @avra_array_push_owned(ptr %82, ptr %23)
  call void @avra_array_push_owned(ptr %82, ptr %25)
  call void @avra_array_push_owned(ptr %82, ptr %27)
  call void @avra_array_push_owned(ptr %82, ptr %29)
  call void @avra_array_push_owned(ptr %82, ptr %31)
  call void @avra_array_push_owned(ptr %82, ptr %33)
  call void @avra_array_push_owned(ptr %82, ptr %35)
  call void @avra_array_push_owned(ptr %82, ptr %37)
  call void @avra_array_push_owned(ptr %82, ptr %39)
  call void @avra_array_push_owned(ptr %82, ptr %41)
  call void @avra_array_push_owned(ptr %82, ptr %43)
  call void @avra_array_push_owned(ptr %82, ptr %45)
  call void @avra_array_push_owned(ptr %82, ptr %47)
  call void @avra_array_push_owned(ptr %82, ptr %49)
  call void @avra_array_push_owned(ptr %82, ptr %51)
  call void @avra_array_push_owned(ptr %82, ptr %53)
  call void @avra_array_push_owned(ptr %82, ptr %55)
  call void @avra_array_push_owned(ptr %82, ptr %57)
  call void @avra_array_push_owned(ptr %82, ptr %59)
  call void @avra_array_push_owned(ptr %82, ptr %61)
  call void @avra_array_push_owned(ptr %82, ptr %63)
  call void @avra_array_push_owned(ptr %82, ptr %65)
  call void @avra_array_push_owned(ptr %82, ptr %67)
  call void @avra_array_push_owned(ptr %82, ptr %69)
  call void @avra_array_push_owned(ptr %82, ptr %71)
  call void @avra_array_push_owned(ptr %82, ptr %73)
  call void @avra_array_push_owned(ptr %82, ptr %75)
  call void @avra_array_push_owned(ptr %82, ptr %77)
  call void @avra_array_push_owned(ptr %82, ptr %79)
  call void @avra_array_push_owned(ptr %82, ptr %81)
  call void @avra_array_push_owned(ptr %82, ptr %1)
  call void @avra_array_push_owned(ptr %82, ptr %3)
  call void @avra_rc_release(ptr %81)
  call void @avra_rc_release(ptr %80)
  call void @avra_rc_release(ptr %79)
  call void @avra_rc_release(ptr %78)
  call void @avra_rc_release(ptr %77)
  call void @avra_rc_release(ptr %76)
  call void @avra_rc_release(ptr %75)
  call void @avra_rc_release(ptr %74)
  call void @avra_rc_release(ptr %73)
  call void @avra_rc_release(ptr %72)
  call void @avra_rc_release(ptr %71)
  call void @avra_rc_release(ptr %70)
  call void @avra_rc_release(ptr %69)
  call void @avra_rc_release(ptr %68)
  call void @avra_rc_release(ptr %67)
  call void @avra_rc_release(ptr %66)
  call void @avra_rc_release(ptr %65)
  call void @avra_rc_release(ptr %64)
  call void @avra_rc_release(ptr %63)
  call void @avra_rc_release(ptr %62)
  call void @avra_rc_release(ptr %61)
  call void @avra_rc_release(ptr %60)
  call void @avra_rc_release(ptr %59)
  call void @avra_rc_release(ptr %58)
  call void @avra_rc_release(ptr %57)
  call void @avra_rc_release(ptr %56)
  call void @avra_rc_release(ptr %55)
  call void @avra_rc_release(ptr %54)
  call void @avra_rc_release(ptr %53)
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %51)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %49)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %47)
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %42)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %82
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2EDeferSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2EDeferSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2EDeferSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241266"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241266"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Especs$2ESpecSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241265"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241265"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emodules$2EUseSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emaps$2EMapsSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2EMapsSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241262"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241262"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2EMapsSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241253"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241251"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EMethodSemantics$2Ekids"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241252"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EImplSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2EImplSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ELetElseSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ELetElseSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ELetElseSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EReturnSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Efns$2EReturnSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Efns$2EReturnSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfStmtSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfStmtSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfStmtSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241234"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumDeclSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumDeclSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241226"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241226"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2ENamedTypeSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241225"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241225"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructDeclSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EAssignSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EAssignSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EAssignSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Econsts$2EConstSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2EConstSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2EConstSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EMutLetSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EMutLetSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2EMutLetSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_spine$2EHoleSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Etype_stmt$241198"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Eresolve_stmt$241198"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241208"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnStmtSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnStmtSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2EExprStmtSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2EExprStmtSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2EExprStmtSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2ELetStmtSemantics$2Elower_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2ELetStmtSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2ELetStmtSemantics$2Eresolve_stmt"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Elower_stmt$241220"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESyntaxSemantics$2Etype_stmt"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EStmtSemantics$2Eresolve_stmt$241220"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESublangSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESublangSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241219"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241219"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2ESublangSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Equote$2EQuoteSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2EQuoteSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241213"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241213"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2EQuoteSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241246"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Eheirs"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2ENullableSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Eheirs"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241224"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Eheirs"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241207"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2EFnsSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2EBlockSemantics$2Eheirs"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Ekids$241199"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241223"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Eheirs"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2EWhenSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Eheirs"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2EIfSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2EBoolSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2EBoolSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241211"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241211"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Ekids$241211"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2EStrSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2EStrSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eresolve$241267"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241267"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2EStrSemantics$2Ekids"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Elower"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Etype_of"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Eresolve"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENodeSemantics$2Eheirs$241255"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2ESpineSemantics$2Ekids"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_binds"(ptr, ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_accepts"(ptr, ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_types"(ptr, ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_binds"(ptr, ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_accepts"(ptr, ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_types"(ptr, ptr, i64, ptr)
