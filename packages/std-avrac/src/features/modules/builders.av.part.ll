; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [23 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 22 }, [23 x i8] c"`export` written twice\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_exported"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_exported"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etoken"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64, i64, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ebuild_export$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ebuild_export"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ebuild_use$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ebuild_use"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ebuild_export"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmt"(ptr %0, i64 0)
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
  %5 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_exported"(ptr %boxed, i64 %regval)
  br i1 %5, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed6 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  %8 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_exported"(ptr %boxed6, i64 %regval)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 1)
  call void @avra_array_push(ptr %9, i64 %regval)
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Estmt"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ebuild_use"(ptr %0) {
entry:
  %slot40 = alloca i64, align 8
  %slot29 = alloca i64, align 8
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
  %13 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %13, 0
  br i1 %x, label %then19, label %else20

postret17:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif16

then19:                                           ; preds = %endif16
  %x22 = extractvalue { i1, i64 } %13, 1
  br label %endif21

else20:                                           ; preds = %endif16
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval23 = phi i64 [ %x22, %then19 ], [ 0, %else20 ]
  %14 = call i64 @avra_array_get(ptr %regval, i64 1)
  %boxed = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %15, ptr %boxed)
  %16 = call ptr @avra_array_sized(i64 0)
  %17 = call i64 @avra_array_len(ptr %regval6)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %endif21
  %ld = load i64, ptr %slot, align 8
  %cmp24 = icmp slt i64 %ld, %17
  br i1 %cmp24, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %18 = call ptr @avra_array_concat(ptr %15, ptr %16)
  %19 = call ptr @avra_array_sized(i64 0)
  %20 = call i64 @avra_array_len(ptr %regval12)
  store i64 0, ptr %slot29, align 8
  br label %lhead30

lbody:                                            ; preds = %lhead
  %ld25 = load i64, ptr %slot, align 8
  %21 = call i64 @avra_array_get(ptr %regval6, i64 %ld25)
  %boxed26 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %boxed26, i64 1)
  %boxed27 = inttoptr i64 %22 to ptr
  call void @avra_array_push_owned(ptr %16, ptr %boxed27)
  %ld28 = load i64, ptr %slot, align 8
  %add = add i64 %ld28, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead30:                                          ; preds = %lbody34, %lexit
  %ld32 = load i64, ptr %slot29, align 8
  %cmp33 = icmp slt i64 %ld32, %20
  br i1 %cmp33, label %lbody34, label %lexit31

lexit31:                                          ; preds = %lhead30
  %23 = call ptr @avra_array_sized(i64 0)
  %24 = call i64 @avra_array_len(ptr %regval12)
  store i64 0, ptr %slot40, align 8
  br label %lhead41

lbody34:                                          ; preds = %lhead30
  %ld35 = load i64, ptr %slot29, align 8
  %25 = call i64 @avra_array_get(ptr %regval12, i64 %ld35)
  %boxed36 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %boxed36, i64 1)
  %boxed37 = inttoptr i64 %26 to ptr
  call void @avra_array_push_owned(ptr %19, ptr %boxed37)
  %ld38 = load i64, ptr %slot29, align 8
  %add39 = add i64 %ld38, 1
  store i64 %add39, ptr %slot29, align 8
  br label %lhead30

lhead41:                                          ; preds = %lbody45, %lexit31
  %ld43 = load i64, ptr %slot40, align 8
  %cmp44 = icmp slt i64 %ld43, %24
  br i1 %cmp44, label %lbody45, label %lexit42

lexit42:                                          ; preds = %lhead41
  %27 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %27, i64 16)
  call void @avra_array_push_owned(ptr %27, ptr %18)
  call void @avra_array_push_owned(ptr %27, ptr %19)
  call void @avra_array_push_owned(ptr %27, ptr %23)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %27)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
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

lbody45:                                          ; preds = %lhead41
  %ld46 = load i64, ptr %slot40, align 8
  call void @avra_rc_retain(ptr %regval18)
  call void @avra_rc_retain(ptr %regval12)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ealias_between"(ptr %regval18, ptr %regval12, i64 %ld46, i64 %regval23)
  call void @avra_array_push_owned(ptr %23, ptr %29)
  %ld47 = load i64, ptr %slot40, align 8
  %add48 = add i64 %ld47, 1
  store i64 %add48, ptr %slot40, align 8
  call void @avra_rc_release(ptr %29)
  br label %lhead41
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Ealias_between"(ptr %0, ptr %1, i64 %2, i64 %3) {
entry:
  %slot5 = alloca ptr, align 8
  store ptr null, ptr %slot5, align 8
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 2)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %add = add i64 %2, 1
  %7 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp slt i64 %add, %7
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %add2 = add i64 %2, 1
  %8 = call i64 @avra_array_get(ptr %1, i64 %add2)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed3, i64 2)
  %boxed4 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %10, %then ], [ %3, %else ]
  %11 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif12, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp6 = icmp slt i64 %ld, %11
  br i1 %cmp6, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.1, i64 16)

lbody:                                            ; preds = %lhead
  %ld7 = load i64, ptr %slot, align 8
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 %ld7)
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot5)
  store ptr %12, ptr %slot5, align 8
  %ld8 = load ptr, ptr %slot5, align 8
  %13 = call i64 @avra_array_get(ptr %ld8, i64 2)
  %boxed9 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed9, i64 0)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %14, i64 %6, i64 %regval)
  br i1 %15, label %then10, label %else11

then10:                                           ; preds = %lbody
  %ld13 = load ptr, ptr %slot5, align 8
  call void @avra_rc_retain(ptr %ld13)
  %16 = call ptr @avra_array_get_owned(ptr %ld13, i64 1)
  call void @avra_cell_release(ptr %slot5)
  call void @avra_rc_release(ptr %ld13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else11:                                           ; preds = %lbody
  br label %endif12

endif12:                                          ; preds = %else11, %postret
  %regval14 = phi i64 [ 0, %postret ], [ 0, %else11 ]
  %ld15 = load i64, ptr %slot, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %ld13)
  br label %endif12
}
