; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_cell_release\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eis_flat"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eflat_fields"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %6, i64 5)
  %boxed5 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed6 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed6, i64 4)
  %boxed7 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %boxed7)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory_ins"(ptr %5, ptr %boxed5, ptr %boxed7, ptr %10)
  %12 = call ptr @avra_array_get_owned(ptr %4, i64 0)
  %13 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %14 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %15 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  %16 = call ptr @avra_array_get_owned(ptr %4, i64 5)
  %17 = call i64 @avra_array_get(ptr %4, i64 6)
  %boxed8 = inttoptr i64 %17 to ptr
  %18 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %18, ptr %12)
  call void @avra_array_push_owned(ptr %18, ptr %13)
  call void @avra_array_push_owned(ptr %18, ptr %14)
  call void @avra_array_push_owned(ptr %18, ptr %15)
  call void @avra_array_push_owned(ptr %18, ptr %11)
  call void @avra_array_push_owned(ptr %18, ptr %16)
  call void @avra_array_push_owned(ptr %18, ptr %boxed8)
  %19 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %20 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %21 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %22 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  %23 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed9 = inttoptr i64 %23 to ptr
  %24 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %24, ptr %1)
  call void @avra_array_push_owned(ptr %24, ptr %18)
  call void @avra_array_push_owned(ptr %24, ptr %19)
  call void @avra_array_push_owned(ptr %24, ptr %20)
  call void @avra_array_push_owned(ptr %24, ptr %21)
  call void @avra_array_push_owned(ptr %24, ptr %22)
  call void @avra_array_push_owned(ptr %24, ptr %boxed9)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %24

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %25 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %25 to ptr
  %26 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %27 = call ptr @avra_array_get_owned(ptr %boxed, i64 5)
  %28 = call ptr @avra_array_get_owned(ptr %boxed, i64 4)
  %29 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %29 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %boxed)
  %30 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Emanaged_params"(ptr %boxed2, ptr %boxed)
  call void @avra_rc_retain(ptr %26)
  call void @avra_rc_retain(ptr %27)
  call void @avra_rc_retain(ptr %28)
  call void @avra_rc_retain(ptr %30)
  %31 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory_ins"(ptr %26, ptr %27, ptr %28, ptr %30)
  %32 = call ptr @avra_array_get_owned(ptr %boxed, i64 0)
  %33 = call ptr @avra_array_get_owned(ptr %boxed, i64 1)
  %34 = call ptr @avra_array_get_owned(ptr %boxed, i64 2)
  %35 = call ptr @avra_array_get_owned(ptr %boxed, i64 3)
  %36 = call ptr @avra_array_get_owned(ptr %boxed, i64 5)
  %37 = call i64 @avra_array_get(ptr %boxed, i64 6)
  %boxed3 = inttoptr i64 %37 to ptr
  %38 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %38, ptr %32)
  call void @avra_array_push_owned(ptr %38, ptr %33)
  call void @avra_array_push_owned(ptr %38, ptr %34)
  call void @avra_array_push_owned(ptr %38, ptr %35)
  call void @avra_array_push_owned(ptr %38, ptr %31)
  call void @avra_array_push_owned(ptr %38, ptr %36)
  call void @avra_array_push_owned(ptr %38, ptr %boxed3)
  call void @avra_array_push_owned(ptr %1, ptr %38)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory_ins"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot260 = alloca ptr, align 8
  store ptr null, ptr %slot260, align 8
  %slot259 = alloca i64, align 8
  %slot190 = alloca i64, align 8
  %slot189 = alloca i64, align 8
  %slot178 = alloca i64, align 8
  %slot177 = alloca i64, align 8
  %slot161 = alloca ptr, align 8
  store ptr null, ptr %slot161, align 8
  %slot160 = alloca i64, align 8
  %slot145 = alloca ptr, align 8
  store ptr null, ptr %slot145, align 8
  %slot144 = alloca i64, align 8
  %slot129 = alloca ptr, align 8
  store ptr null, ptr %slot129, align 8
  %slot128 = alloca i64, align 8
  %slot118 = alloca ptr, align 8
  store ptr null, ptr %slot118, align 8
  %slot117 = alloca i64, align 8
  %slot95 = alloca ptr, align 8
  store ptr null, ptr %slot95, align 8
  %slot94 = alloca i64, align 8
  %slot84 = alloca ptr, align 8
  store ptr null, ptr %slot84, align 8
  %slot83 = alloca i64, align 8
  %slot50 = alloca ptr, align 8
  store ptr null, ptr %slot50, align 8
  %slot49 = alloca i64, align 8
  %slot35 = alloca ptr, align 8
  store ptr null, ptr %slot35, align 8
  %slot34 = alloca i64, align 8
  %slot14 = alloca i64, align 8
  %slot13 = alloca i64, align 8
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enew_stack$24296"()
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot1)
  store ptr %5, ptr %slot1, align 8
  %6 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld297 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld297)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld297

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 %ld4)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot3)
  store ptr %7, ptr %slot3, align 8
  %ld5 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %ld5)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eowned_form"(ptr %0, ptr %1, ptr %2, i64 %ld4, ptr %ld5)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp6 = icmp eq i64 %9, 12
  br i1 %cmp6, label %then, label %else

then:                                             ; preds = %lbody
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  %ld7 = load ptr, ptr %slot1, align 8
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call ptr @avra_array_sized(i64 0)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %ld7)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Epush$24296"(ptr %ld7, ptr %13)
  %ld8 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld8)
  %15 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Edepth$24296"(ptr %ld8)
  %cmp9 = icmp eq i64 %15, 1
  br i1 %cmp9, label %then10, label %else11

else:                                             ; preds = %lbody
  %16 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp24 = icmp eq i64 %16, 13
  br i1 %cmp24, label %then25, label %else26

endif:                                            ; preds = %endif27, %endif12
  %regval294 = phi i64 [ 0, %endif12 ], [ %regval293, %endif27 ]
  %ld295 = load i64, ptr %slot2, align 8
  %add296 = add i64 %ld295, 1
  store i64 %add296, ptr %slot2, align 8
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %lhead

then10:                                           ; preds = %then
  %17 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot13, align 8
  br label %lhead15

else11:                                           ; preds = %then
  br label %endif12

endif12:                                          ; preds = %else11, %lexit16
  %regval = phi i64 [ 0, %lexit16 ], [ 0, %else11 ]
  %18 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %18, ptr %8)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif

lhead15:                                          ; preds = %lbody19, %then10
  %ld17 = load i64, ptr %slot13, align 8
  %cmp18 = icmp slt i64 %ld17, %17
  br i1 %cmp18, label %lbody19, label %lexit16

lexit16:                                          ; preds = %lhead15
  br label %endif12

lbody19:                                          ; preds = %lhead15
  %ld20 = load i64, ptr %slot13, align 8
  %19 = call i64 @avra_array_get(ptr %3, i64 %ld20)
  store i64 %19, ptr %slot14, align 8
  %ld21 = load ptr, ptr %slot1, align 8
  %ld22 = load i64, ptr %slot14, align 8
  call void @avra_rc_retain(ptr %ld21)
  %20 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Etakes"(ptr %ld21, i64 %ld22)
  %ld23 = load i64, ptr %slot13, align 8
  %add = add i64 %ld23, 1
  store i64 %add, ptr %slot13, align 8
  br label %lhead15

then25:                                           ; preds = %else
  %21 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  %ld28 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld28)
  %22 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Epop$24296"(ptr %ld28)
  %cmp29 = icmp ne ptr %22, null
  br i1 %cmp29, label %then30, label %else31

else26:                                           ; preds = %else
  %23 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp62 = icmp eq i64 %23, 14
  br i1 %cmp62, label %then63, label %else64

endif27:                                          ; preds = %endif70, %endif48
  %regval293 = phi i64 [ 0, %endif48 ], [ %regval292, %endif70 ]
  br label %endif

then30:                                           ; preds = %then25
  call void @avra_rc_retain(ptr %22)
  br label %endif32

else31:                                           ; preds = %then25
  %24 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eempty_scope"()
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval33 = phi ptr [ %22, %then30 ], [ %24, %else31 ]
  call void @avra_rc_retain(ptr %regval33)
  call void @avra_rc_retain(ptr %21)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Esettled"(ptr %regval33, ptr %21)
  %26 = call i64 @avra_array_len(ptr %25)
  store i64 0, ptr %slot34, align 8
  br label %lhead36

lhead36:                                          ; preds = %lbody40, %endif32
  %ld38 = load i64, ptr %slot34, align 8
  %cmp39 = icmp slt i64 %ld38, %26
  br i1 %cmp39, label %lbody40, label %lexit37

lexit37:                                          ; preds = %lhead36
  %ld45 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld45)
  %27 = call i1 @"av_$40std$2Eavrac$2Ecore$2EStack$2Eis_empty$24296"(ptr %ld45)
  %not = xor i1 %27, true
  br i1 %not, label %then46, label %else47

lbody40:                                          ; preds = %lhead36
  %ld41 = load i64, ptr %slot34, align 8
  %28 = call ptr @avra_array_get_owned(ptr %25, i64 %ld41)
  call void @avra_rc_retain(ptr %28)
  call void @avra_cell_release(ptr %slot35)
  store ptr %28, ptr %slot35, align 8
  %29 = call ptr @avra_cell_unique(ptr %slot)
  %ld42 = load ptr, ptr %slot35, align 8
  call void @avra_array_push_owned(ptr %29, ptr %ld42)
  %ld43 = load i64, ptr %slot34, align 8
  %add44 = add i64 %ld43, 1
  store i64 %add44, ptr %slot34, align 8
  call void @avra_rc_release(ptr %28)
  br label %lhead36

then46:                                           ; preds = %lexit37
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval33)
  call void @avra_rc_retain(ptr %21)
  %30 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Emoved_out"(ptr %0, ptr %1, ptr %regval33, ptr %21)
  %31 = call i64 @avra_array_len(ptr %30)
  store i64 0, ptr %slot49, align 8
  br label %lhead51

else47:                                           ; preds = %lexit37
  br label %endif48

endif48:                                          ; preds = %else47, %lexit52
  %regval61 = phi i64 [ 0, %lexit52 ], [ 0, %else47 ]
  %32 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %32, ptr %8)
  call void @avra_cell_release(ptr %slot35)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %regval33)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  br label %endif27

lhead51:                                          ; preds = %lbody55, %then46
  %ld53 = load i64, ptr %slot49, align 8
  %cmp54 = icmp slt i64 %ld53, %31
  br i1 %cmp54, label %lbody55, label %lexit52

lexit52:                                          ; preds = %lhead51
  %ld60 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld60)
  call void @avra_rc_retain(ptr %21)
  %33 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eadopts"(ptr %0, ptr %1, ptr %ld60, ptr %21)
  call void @avra_cell_release(ptr %slot50)
  call void @avra_rc_release(ptr %30)
  br label %endif48

lbody55:                                          ; preds = %lhead51
  %ld56 = load i64, ptr %slot49, align 8
  %34 = call ptr @avra_array_get_owned(ptr %30, i64 %ld56)
  call void @avra_rc_retain(ptr %34)
  call void @avra_cell_release(ptr %slot50)
  store ptr %34, ptr %slot50, align 8
  %35 = call ptr @avra_cell_unique(ptr %slot)
  %ld57 = load ptr, ptr %slot50, align 8
  call void @avra_array_push_owned(ptr %35, ptr %ld57)
  %ld58 = load i64, ptr %slot49, align 8
  %add59 = add i64 %ld58, 1
  store i64 %add59, ptr %slot49, align 8
  call void @avra_rc_release(ptr %34)
  br label %lhead51

then63:                                           ; preds = %else26
  br label %endif65

else64:                                           ; preds = %else26
  %36 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp66 = icmp eq i64 %36, 15
  br label %endif65

endif65:                                          ; preds = %else64, %then63
  %regval67 = phi i1 [ true, %then63 ], [ %cmp66, %else64 ]
  br i1 %regval67, label %then68, label %else69

then68:                                           ; preds = %endif65
  %ld71 = load ptr, ptr %slot1, align 8
  %ld72 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld72)
  %37 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Enested_scope"(ptr %ld72)
  call void @avra_rc_retain(ptr %ld71)
  call void @avra_rc_retain(ptr %37)
  %38 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Epush$24296"(ptr %ld71, ptr %37)
  %39 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %39, ptr %8)
  call void @avra_rc_release(ptr %37)
  br label %endif70

else69:                                           ; preds = %endif65
  %40 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp73 = icmp eq i64 %40, 16
  br i1 %cmp73, label %then74, label %else75

endif70:                                          ; preds = %endif76, %then68
  %regval292 = phi i64 [ 0, %then68 ], [ %regval291, %endif76 ]
  br label %endif27

then74:                                           ; preds = %else69
  %41 = call i64 @avra_array_get(ptr %8, i64 1)
  %ld77 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld77)
  %42 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Epop$24296"(ptr %ld77)
  %cmp78 = icmp ne ptr %42, null
  br i1 %cmp78, label %then79, label %else80

else75:                                           ; preds = %else69
  %43 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp107 = icmp eq i64 %43, 17
  br i1 %cmp107, label %then108, label %else109

endif76:                                          ; preds = %endif110, %lexit97
  %regval291 = phi i64 [ 0, %lexit97 ], [ %regval290, %endif110 ]
  br label %endif70

then79:                                           ; preds = %then74
  call void @avra_rc_retain(ptr %42)
  br label %endif81

else80:                                           ; preds = %then74
  %44 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eempty_scope"()
  br label %endif81

endif81:                                          ; preds = %else80, %then79
  %regval82 = phi ptr [ %42, %then79 ], [ %44, %else80 ]
  %45 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %45, i64 %41)
  call void @avra_rc_retain(ptr %regval82)
  call void @avra_rc_retain(ptr %45)
  %46 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Esettled"(ptr %regval82, ptr %45)
  %47 = call i64 @avra_array_len(ptr %46)
  store i64 0, ptr %slot83, align 8
  br label %lhead85

lhead85:                                          ; preds = %lbody89, %endif81
  %ld87 = load i64, ptr %slot83, align 8
  %cmp88 = icmp slt i64 %ld87, %47
  br i1 %cmp88, label %lbody89, label %lexit86

lexit86:                                          ; preds = %lhead85
  %48 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %48, i64 %41)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval82)
  call void @avra_rc_retain(ptr %48)
  %49 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Emoved_out"(ptr %0, ptr %1, ptr %regval82, ptr %48)
  %50 = call i64 @avra_array_len(ptr %49)
  store i64 0, ptr %slot94, align 8
  br label %lhead96

lbody89:                                          ; preds = %lhead85
  %ld90 = load i64, ptr %slot83, align 8
  %51 = call ptr @avra_array_get_owned(ptr %46, i64 %ld90)
  call void @avra_rc_retain(ptr %51)
  call void @avra_cell_release(ptr %slot84)
  store ptr %51, ptr %slot84, align 8
  %52 = call ptr @avra_cell_unique(ptr %slot)
  %ld91 = load ptr, ptr %slot84, align 8
  call void @avra_array_push_owned(ptr %52, ptr %ld91)
  %ld92 = load i64, ptr %slot83, align 8
  %add93 = add i64 %ld92, 1
  store i64 %add93, ptr %slot83, align 8
  call void @avra_rc_release(ptr %51)
  br label %lhead85

lhead96:                                          ; preds = %lbody100, %lexit86
  %ld98 = load i64, ptr %slot94, align 8
  %cmp99 = icmp slt i64 %ld98, %50
  br i1 %cmp99, label %lbody100, label %lexit97

lexit97:                                          ; preds = %lhead96
  %ld105 = load ptr, ptr %slot1, align 8
  %ld106 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld106)
  %53 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Enested_scope"(ptr %ld106)
  call void @avra_rc_retain(ptr %ld105)
  call void @avra_rc_retain(ptr %53)
  %54 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Epush$24296"(ptr %ld105, ptr %53)
  %55 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %55, ptr %8)
  call void @avra_cell_release(ptr %slot95)
  call void @avra_cell_release(ptr %slot84)
  call void @avra_rc_release(ptr %53)
  call void @avra_rc_release(ptr %49)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %regval82)
  call void @avra_rc_release(ptr %42)
  br label %endif76

lbody100:                                         ; preds = %lhead96
  %ld101 = load i64, ptr %slot94, align 8
  %56 = call ptr @avra_array_get_owned(ptr %49, i64 %ld101)
  call void @avra_rc_retain(ptr %56)
  call void @avra_cell_release(ptr %slot95)
  store ptr %56, ptr %slot95, align 8
  %57 = call ptr @avra_cell_unique(ptr %slot)
  %ld102 = load ptr, ptr %slot95, align 8
  call void @avra_array_push_owned(ptr %57, ptr %ld102)
  %ld103 = load i64, ptr %slot94, align 8
  %add104 = add i64 %ld103, 1
  store i64 %add104, ptr %slot94, align 8
  call void @avra_rc_release(ptr %56)
  br label %lhead96

then108:                                          ; preds = %else75
  %58 = call i64 @avra_array_get(ptr %8, i64 2)
  %ld111 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld111)
  %59 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Epop$24296"(ptr %ld111)
  %cmp112 = icmp ne ptr %59, null
  br i1 %cmp112, label %then113, label %else114

else109:                                          ; preds = %else75
  %60 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp140 = icmp eq i64 %60, 18
  br i1 %cmp140, label %then141, label %else142

endif110:                                         ; preds = %endif143, %lexit131
  %regval290 = phi i64 [ 0, %lexit131 ], [ %regval289, %endif143 ]
  br label %endif76

then113:                                          ; preds = %then108
  call void @avra_rc_retain(ptr %59)
  br label %endif115

else114:                                          ; preds = %then108
  %61 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eempty_scope"()
  br label %endif115

endif115:                                         ; preds = %else114, %then113
  %regval116 = phi ptr [ %59, %then113 ], [ %61, %else114 ]
  %62 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %62, i64 %58)
  call void @avra_rc_retain(ptr %regval116)
  call void @avra_rc_retain(ptr %62)
  %63 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Esettled"(ptr %regval116, ptr %62)
  %64 = call i64 @avra_array_len(ptr %63)
  store i64 0, ptr %slot117, align 8
  br label %lhead119

lhead119:                                         ; preds = %lbody123, %endif115
  %ld121 = load i64, ptr %slot117, align 8
  %cmp122 = icmp slt i64 %ld121, %64
  br i1 %cmp122, label %lbody123, label %lexit120

lexit120:                                         ; preds = %lhead119
  %65 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %65, i64 %58)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval116)
  call void @avra_rc_retain(ptr %65)
  %66 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Emoved_out"(ptr %0, ptr %1, ptr %regval116, ptr %65)
  %67 = call i64 @avra_array_len(ptr %66)
  store i64 0, ptr %slot128, align 8
  br label %lhead130

lbody123:                                         ; preds = %lhead119
  %ld124 = load i64, ptr %slot117, align 8
  %68 = call ptr @avra_array_get_owned(ptr %63, i64 %ld124)
  call void @avra_rc_retain(ptr %68)
  call void @avra_cell_release(ptr %slot118)
  store ptr %68, ptr %slot118, align 8
  %69 = call ptr @avra_cell_unique(ptr %slot)
  %ld125 = load ptr, ptr %slot118, align 8
  call void @avra_array_push_owned(ptr %69, ptr %ld125)
  %ld126 = load i64, ptr %slot117, align 8
  %add127 = add i64 %ld126, 1
  store i64 %add127, ptr %slot117, align 8
  call void @avra_rc_release(ptr %68)
  br label %lhead119

lhead130:                                         ; preds = %lbody134, %lexit120
  %ld132 = load i64, ptr %slot128, align 8
  %cmp133 = icmp slt i64 %ld132, %67
  br i1 %cmp133, label %lbody134, label %lexit131

lexit131:                                         ; preds = %lhead130
  %ld139 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld139)
  call void @avra_rc_retain(ptr %8)
  %70 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %ld139, ptr %8)
  %71 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %71, ptr %8)
  call void @avra_cell_release(ptr %slot129)
  call void @avra_cell_release(ptr %slot118)
  call void @avra_rc_release(ptr %66)
  call void @avra_rc_release(ptr %65)
  call void @avra_rc_release(ptr %63)
  call void @avra_rc_release(ptr %62)
  call void @avra_rc_release(ptr %regval116)
  call void @avra_rc_release(ptr %59)
  br label %endif110

lbody134:                                         ; preds = %lhead130
  %ld135 = load i64, ptr %slot128, align 8
  %72 = call ptr @avra_array_get_owned(ptr %66, i64 %ld135)
  call void @avra_rc_retain(ptr %72)
  call void @avra_cell_release(ptr %slot129)
  store ptr %72, ptr %slot129, align 8
  %73 = call ptr @avra_cell_unique(ptr %slot)
  %ld136 = load ptr, ptr %slot129, align 8
  call void @avra_array_push_owned(ptr %73, ptr %ld136)
  %ld137 = load i64, ptr %slot128, align 8
  %add138 = add i64 %ld137, 1
  store i64 %add138, ptr %slot128, align 8
  call void @avra_rc_release(ptr %72)
  br label %lhead130

then141:                                          ; preds = %else109
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  %74 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eretained_args"(ptr %0, ptr %1, ptr %8)
  %75 = call i64 @avra_array_len(ptr %74)
  store i64 0, ptr %slot144, align 8
  br label %lhead146

else142:                                          ; preds = %else109
  %76 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp156 = icmp eq i64 %76, 19
  br i1 %cmp156, label %then157, label %else158

endif143:                                         ; preds = %endif159, %lexit147
  %regval289 = phi i64 [ 0, %lexit147 ], [ %regval288, %endif159 ]
  br label %endif110

lhead146:                                         ; preds = %lbody150, %then141
  %ld148 = load i64, ptr %slot144, align 8
  %cmp149 = icmp slt i64 %ld148, %75
  br i1 %cmp149, label %lbody150, label %lexit147

lexit147:                                         ; preds = %lhead146
  %ld155 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld155)
  call void @avra_rc_retain(ptr %8)
  %77 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %ld155, ptr %8)
  %78 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %78, ptr %8)
  call void @avra_cell_release(ptr %slot145)
  call void @avra_rc_release(ptr %74)
  br label %endif143

lbody150:                                         ; preds = %lhead146
  %ld151 = load i64, ptr %slot144, align 8
  %79 = call ptr @avra_array_get_owned(ptr %74, i64 %ld151)
  call void @avra_rc_retain(ptr %79)
  call void @avra_cell_release(ptr %slot145)
  store ptr %79, ptr %slot145, align 8
  %80 = call ptr @avra_cell_unique(ptr %slot)
  %ld152 = load ptr, ptr %slot145, align 8
  call void @avra_array_push_owned(ptr %80, ptr %ld152)
  %ld153 = load i64, ptr %slot144, align 8
  %add154 = add i64 %ld153, 1
  store i64 %add154, ptr %slot144, align 8
  call void @avra_rc_release(ptr %79)
  br label %lhead146

then157:                                          ; preds = %else142
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  %81 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eretained_args"(ptr %0, ptr %1, ptr %8)
  %82 = call i64 @avra_array_len(ptr %81)
  store i64 0, ptr %slot160, align 8
  br label %lhead162

else158:                                          ; preds = %else142
  %83 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp172 = icmp eq i64 %83, 21
  br i1 %cmp172, label %then173, label %else174

endif159:                                         ; preds = %endif175, %lexit163
  %regval288 = phi i64 [ 0, %lexit163 ], [ %regval287, %endif175 ]
  br label %endif143

lhead162:                                         ; preds = %lbody166, %then157
  %ld164 = load i64, ptr %slot160, align 8
  %cmp165 = icmp slt i64 %ld164, %82
  br i1 %cmp165, label %lbody166, label %lexit163

lexit163:                                         ; preds = %lhead162
  %ld171 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld171)
  call void @avra_rc_retain(ptr %8)
  %84 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %ld171, ptr %8)
  %85 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %85, ptr %8)
  call void @avra_cell_release(ptr %slot161)
  call void @avra_rc_release(ptr %81)
  br label %endif159

lbody166:                                         ; preds = %lhead162
  %ld167 = load i64, ptr %slot160, align 8
  %86 = call ptr @avra_array_get_owned(ptr %81, i64 %ld167)
  call void @avra_rc_retain(ptr %86)
  call void @avra_cell_release(ptr %slot161)
  store ptr %86, ptr %slot161, align 8
  %87 = call ptr @avra_cell_unique(ptr %slot)
  %ld168 = load ptr, ptr %slot161, align 8
  call void @avra_array_push_owned(ptr %87, ptr %ld168)
  %ld169 = load i64, ptr %slot160, align 8
  %add170 = add i64 %ld169, 1
  store i64 %add170, ptr %slot160, align 8
  call void @avra_rc_release(ptr %86)
  br label %lhead162

then173:                                          ; preds = %else158
  %88 = call i64 @avra_array_get(ptr %8, i64 1)
  %ld176 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld176)
  %89 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eexit_cells"(ptr %ld176)
  %90 = call i64 @avra_array_len(ptr %89)
  store i64 0, ptr %slot177, align 8
  br label %lhead179

else174:                                          ; preds = %else158
  %91 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp200 = icmp eq i64 %91, 22
  br i1 %cmp200, label %then201, label %else202

endif175:                                         ; preds = %endif203, %lexit192
  %regval287 = phi i64 [ 0, %lexit192 ], [ %regval286, %endif203 ]
  br label %endif159

lhead179:                                         ; preds = %lbody183, %then173
  %ld181 = load i64, ptr %slot177, align 8
  %cmp182 = icmp slt i64 %ld181, %90
  br i1 %cmp182, label %lbody183, label %lexit180

lexit180:                                         ; preds = %lhead179
  %ld188 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld188)
  %92 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eexit_releases"(ptr %ld188, i64 %88)
  %93 = call i64 @avra_array_len(ptr %92)
  store i64 0, ptr %slot189, align 8
  br label %lhead191

lbody183:                                         ; preds = %lhead179
  %ld184 = load i64, ptr %slot177, align 8
  %94 = call i64 @avra_array_get(ptr %89, i64 %ld184)
  store i64 %94, ptr %slot178, align 8
  %95 = call ptr @avra_cell_unique(ptr %slot)
  %ld185 = load i64, ptr %slot178, align 8
  %96 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ecell_settle"(i64 %ld185)
  call void @avra_array_push_owned(ptr %95, ptr %96)
  %ld186 = load i64, ptr %slot177, align 8
  %add187 = add i64 %ld186, 1
  store i64 %add187, ptr %slot177, align 8
  call void @avra_rc_release(ptr %96)
  br label %lhead179

lhead191:                                         ; preds = %lbody195, %lexit180
  %ld193 = load i64, ptr %slot189, align 8
  %cmp194 = icmp slt i64 %ld193, %93
  br i1 %cmp194, label %lbody195, label %lexit192

lexit192:                                         ; preds = %lhead191
  %97 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %97, ptr %8)
  call void @avra_rc_release(ptr %92)
  call void @avra_rc_release(ptr %89)
  br label %endif175

lbody195:                                         ; preds = %lhead191
  %ld196 = load i64, ptr %slot189, align 8
  %98 = call i64 @avra_array_get(ptr %92, i64 %ld196)
  store i64 %98, ptr %slot190, align 8
  %99 = call ptr @avra_cell_unique(ptr %slot)
  %ld197 = load i64, ptr %slot190, align 8
  %100 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %100, i64 29)
  call void @avra_array_push(ptr %100, i64 %ld197)
  call void @avra_array_push_owned(ptr %99, ptr %100)
  %ld198 = load i64, ptr %slot189, align 8
  %add199 = add i64 %ld198, 1
  store i64 %add199, ptr %slot189, align 8
  call void @avra_rc_release(ptr %100)
  br label %lhead191

then201:                                          ; preds = %else174
  %101 = call i64 @avra_array_get(ptr %8, i64 1)
  %102 = call i64 @avra_array_get(ptr %1, i64 %101)
  %boxed = inttoptr i64 %102 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %103 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  br i1 %103, label %then204, label %else205

else202:                                          ; preds = %else174
  %104 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp215 = icmp eq i64 %104, 24
  br i1 %cmp215, label %then216, label %else217

endif203:                                         ; preds = %endif218, %endif212
  %regval286 = phi i64 [ 0, %endif212 ], [ %regval285, %endif218 ]
  br label %endif175

then204:                                          ; preds = %then201
  %ld207 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld207)
  %105 = call i1 @"av_$40std$2Eavrac$2Ecore$2EStack$2Eis_empty$24296"(ptr %ld207)
  %not208 = xor i1 %105, true
  br label %endif206

else205:                                          ; preds = %then201
  br label %endif206

endif206:                                         ; preds = %else205, %then204
  %regval209 = phi i1 [ %not208, %then204 ], [ false, %else205 ]
  br i1 %regval209, label %then210, label %else211

then210:                                          ; preds = %endif206
  %ld213 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld213)
  %106 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eholds_cell"(ptr %ld213, i64 %101)
  br label %endif212

else211:                                          ; preds = %endif206
  br label %endif212

endif212:                                         ; preds = %else211, %then210
  %regval214 = phi i64 [ 0, %then210 ], [ 0, %else211 ]
  %107 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %107, ptr %8)
  br label %endif203

then216:                                          ; preds = %else202
  %108 = call i64 @avra_array_get(ptr %8, i64 1)
  %109 = call i64 @avra_array_get(ptr %8, i64 2)
  %110 = call i64 @avra_array_get(ptr %1, i64 %108)
  %boxed219 = inttoptr i64 %110 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed219)
  %111 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed219)
  br i1 %111, label %then220, label %else221

else217:                                          ; preds = %else202
  %112 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp229 = icmp eq i64 %112, 23
  br i1 %cmp229, label %then230, label %else231

endif218:                                         ; preds = %endif232, %endif222
  %regval285 = phi i64 [ 0, %endif222 ], [ %regval284, %endif232 ]
  br label %endif203

then220:                                          ; preds = %then216
  %113 = call i64 @avra_array_get(ptr %1, i64 %109)
  %boxed223 = inttoptr i64 %113 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed223)
  %114 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed223)
  br i1 %114, label %then224, label %else225

else221:                                          ; preds = %then216
  br label %endif222

endif222:                                         ; preds = %else221, %endif226
  %regval228 = phi i64 [ 0, %endif226 ], [ 0, %else221 ]
  %115 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %115, ptr %8)
  br label %endif218

then224:                                          ; preds = %then220
  %116 = call ptr @avra_cell_unique(ptr %slot)
  %117 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %117, i64 28)
  call void @avra_array_push(ptr %117, i64 %109)
  call void @avra_array_push_owned(ptr %116, ptr %117)
  call void @avra_rc_release(ptr %117)
  br label %endif226

else225:                                          ; preds = %then220
  br label %endif226

endif226:                                         ; preds = %else225, %then224
  %regval227 = phi i64 [ 0, %then224 ], [ 0, %else225 ]
  %118 = call ptr @avra_cell_unique(ptr %slot)
  %119 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ecell_settle"(i64 %108)
  call void @avra_array_push_owned(ptr %118, ptr %119)
  call void @avra_rc_release(ptr %119)
  br label %endif222

then230:                                          ; preds = %else217
  %120 = call i64 @avra_array_get(ptr %8, i64 1)
  %121 = call i64 @avra_array_get(ptr %8, i64 2)
  %122 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %122, ptr %8)
  %123 = call i64 @avra_array_get(ptr %1, i64 %120)
  %boxed233 = inttoptr i64 %123 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed233)
  %124 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed233)
  br i1 %124, label %then234, label %else235

else231:                                          ; preds = %else217
  %125 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp243 = icmp eq i64 %125, 25
  br i1 %cmp243, label %then244, label %else245

endif232:                                         ; preds = %endif246, %endif240
  %regval284 = phi i64 [ 0, %endif240 ], [ %regval283, %endif246 ]
  br label %endif218

then234:                                          ; preds = %then230
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %126 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eborrow_outlives"(ptr %0, ptr %1, ptr %2, i64 %ld4, i64 %120, i64 %121)
  br label %endif236

else235:                                          ; preds = %then230
  br label %endif236

endif236:                                         ; preds = %else235, %then234
  %regval237 = phi i1 [ %126, %then234 ], [ false, %else235 ]
  br i1 %regval237, label %then238, label %else239

then238:                                          ; preds = %endif236
  %127 = call ptr @avra_cell_unique(ptr %slot)
  %128 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %128, i64 28)
  call void @avra_array_push(ptr %128, i64 %120)
  call void @avra_array_push_owned(ptr %127, ptr %128)
  %ld241 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld241)
  call void @avra_rc_retain(ptr %8)
  %129 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %ld241, ptr %8)
  call void @avra_rc_release(ptr %128)
  br label %endif240

else239:                                          ; preds = %endif236
  br label %endif240

endif240:                                         ; preds = %else239, %then238
  %regval242 = phi i64 [ 0, %then238 ], [ 0, %else239 ]
  br label %endif232

then244:                                          ; preds = %else231
  %ld247 = load ptr, ptr %slot1, align 8
  %ld248 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld248)
  %130 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Enested_scope"(ptr %ld248)
  call void @avra_rc_retain(ptr %ld247)
  call void @avra_rc_retain(ptr %130)
  %131 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Epush$24296"(ptr %ld247, ptr %130)
  %132 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %132, ptr %8)
  call void @avra_rc_release(ptr %130)
  br label %endif246

else245:                                          ; preds = %else231
  %133 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp249 = icmp eq i64 %133, 26
  br i1 %cmp249, label %then250, label %else251

endif246:                                         ; preds = %endif252, %then244
  %regval283 = phi i64 [ 0, %then244 ], [ %regval282, %endif252 ]
  br label %endif232

then250:                                          ; preds = %else245
  %ld253 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld253)
  %134 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Epop$24296"(ptr %ld253)
  %cmp254 = icmp ne ptr %134, null
  br i1 %cmp254, label %then255, label %else256

else251:                                          ; preds = %else245
  %135 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp270 = icmp eq i64 %135, 8
  br i1 %cmp270, label %then271, label %else272

endif252:                                         ; preds = %endif273, %lexit262
  %regval282 = phi i64 [ 0, %lexit262 ], [ %regval281, %endif273 ]
  br label %endif246

then255:                                          ; preds = %then250
  call void @avra_rc_retain(ptr %134)
  br label %endif257

else256:                                          ; preds = %then250
  %136 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eempty_scope"()
  br label %endif257

endif257:                                         ; preds = %else256, %then255
  %regval258 = phi ptr [ %134, %then255 ], [ %136, %else256 ]
  call void @avra_rc_retain(ptr %regval258)
  call void @avra_rc_retain(ptr null)
  %137 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Esettled"(ptr %regval258, ptr null)
  %138 = call i64 @avra_array_len(ptr %137)
  store i64 0, ptr %slot259, align 8
  br label %lhead261

lhead261:                                         ; preds = %lbody265, %endif257
  %ld263 = load i64, ptr %slot259, align 8
  %cmp264 = icmp slt i64 %ld263, %138
  br i1 %cmp264, label %lbody265, label %lexit262

lexit262:                                         ; preds = %lhead261
  %139 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %139, ptr %8)
  call void @avra_cell_release(ptr %slot260)
  call void @avra_rc_release(ptr %137)
  call void @avra_rc_release(ptr %regval258)
  call void @avra_rc_release(ptr %134)
  br label %endif252

lbody265:                                         ; preds = %lhead261
  %ld266 = load i64, ptr %slot259, align 8
  %140 = call ptr @avra_array_get_owned(ptr %137, i64 %ld266)
  call void @avra_rc_retain(ptr %140)
  call void @avra_cell_release(ptr %slot260)
  store ptr %140, ptr %slot260, align 8
  %141 = call ptr @avra_cell_unique(ptr %slot)
  %ld267 = load ptr, ptr %slot260, align 8
  call void @avra_array_push_owned(ptr %141, ptr %ld267)
  %ld268 = load i64, ptr %slot259, align 8
  %add269 = add i64 %ld268, 1
  store i64 %add269, ptr %slot259, align 8
  call void @avra_rc_release(ptr %140)
  br label %lhead261

then271:                                          ; preds = %else251
  %142 = call i64 @avra_array_get(ptr %8, i64 1)
  %143 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %143, ptr %8)
  %144 = call i64 @avra_array_get(ptr %1, i64 %142)
  %boxed274 = inttoptr i64 %144 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed274)
  %145 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed274)
  br i1 %145, label %then275, label %else276

else272:                                          ; preds = %else251
  %ld280 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld280)
  call void @avra_rc_retain(ptr %8)
  %146 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %ld280, ptr %8)
  %147 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %147, ptr %8)
  br label %endif273

endif273:                                         ; preds = %else272, %endif277
  %regval281 = phi i64 [ %150, %endif277 ], [ 0, %else272 ]
  br label %endif252

then275:                                          ; preds = %then271
  %148 = call ptr @avra_cell_unique(ptr %slot)
  %149 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %149, i64 28)
  call void @avra_array_push(ptr %149, i64 %142)
  call void @avra_array_push_owned(ptr %148, ptr %149)
  call void @avra_rc_release(ptr %149)
  br label %endif277

else276:                                          ; preds = %then271
  br label %endif277

endif277:                                         ; preds = %else276, %then275
  %regval278 = phi i64 [ 0, %then275 ], [ 0, %else276 ]
  %ld279 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld279)
  call void @avra_rc_retain(ptr %8)
  %150 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %ld279, ptr %8)
  br label %endif273
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eborrow_outlives"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4, i64 %5) {
entry:
  %slot37 = alloca i64, align 8
  %slot6 = alloca i64, align 8
  %slot4 = alloca i1, align 1
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  store i64 %3, ptr %slot1, align 8
  %add = add i64 %3, 1
  store i64 %add, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif18, %entry
  %ld = load i64, ptr %slot2, align 8
  %7 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %add36 = add i64 %3, 1
  store i64 %add36, ptr %slot37, align 8
  br label %lhead38

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot2, align 8
  %8 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  store i1 false, ptr %slot4, align 8
  %ld5 = load ptr, ptr %slot, align 8
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l397" to i64))
  call void @avra_array_push_owned(ptr %9, ptr %ld5)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  call void @avra_rc_retain(ptr %8)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereads_of"(ptr %8)
  %12 = call i64 @avra_array_len(ptr %11)
  store i64 0, ptr %slot6, align 8
  br label %lhead7

lhead7:                                           ; preds = %endif, %lbody
  %ld9 = load i64, ptr %slot6, align 8
  %cmp10 = icmp slt i64 %ld9, %12
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i1, ptr %slot4, align 8
  br i1 %ld15, label %then16, label %else17

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot6, align 8
  %13 = call i64 @avra_array_get(ptr %11, i64 %ld12)
  call void @avra_rc_retain(ptr %9)
  %cast = inttoptr i64 %10 to ptr
  %14 = call i1 %cast(ptr %9, i64 %13)
  br i1 %14, label %then, label %else

then:                                             ; preds = %lbody11
  store i1 true, ptr %slot4, align 8
  store i64 %12, ptr %slot6, align 8
  br label %endif

else:                                             ; preds = %lbody11
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld13 = load i64, ptr %slot6, align 8
  %add14 = add i64 %ld13, 1
  store i64 %add14, ptr %slot6, align 8
  br label %lhead7

then16:                                           ; preds = %lexit8
  call void @avra_rc_retain(ptr %8)
  %15 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Egives_upward"(ptr %8)
  br i1 %15, label %then19, label %else20

else17:                                           ; preds = %lexit8
  br label %endif18

endif18:                                          ; preds = %else17, %endif31
  %regval33 = phi i64 [ 0, %endif31 ], [ 0, %else17 ]
  %ld34 = load i64, ptr %slot2, align 8
  %add35 = add i64 %ld34, 1
  store i64 %add35, ptr %slot2, align 8
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %lhead

then19:                                           ; preds = %then16
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else20:                                           ; preds = %then16
  br label %endif21

endif21:                                          ; preds = %else20, %postret
  %regval22 = phi i64 [ 0, %postret ], [ 0, %else20 ]
  %ld23 = load i64, ptr %slot2, align 8
  store i64 %ld23, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %8)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eview_of"(ptr %8)
  %cmp24 = icmp ne ptr %16, null
  br i1 %cmp24, label %then25, label %else26

postret:                                          ; No predecessors!
  br label %endif21

then25:                                           ; preds = %endif21
  %17 = call ptr @avra_insist(ptr %16)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %19 = call i64 @avra_array_get(ptr %1, i64 %18)
  %boxed = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %20 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  call void @avra_rc_release(ptr %17)
  br label %endif27

else26:                                           ; preds = %endif21
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval28 = phi i1 [ %20, %then25 ], [ false, %else26 ]
  br i1 %regval28, label %then29, label %else30

then29:                                           ; preds = %endif27
  %21 = call ptr @avra_cell_unique(ptr %slot)
  %22 = call ptr @avra_insist(ptr %16)
  %23 = call i64 @avra_array_get(ptr %22, i64 0)
  call void @avra_array_push(ptr %21, i64 %23)
  call void @avra_rc_release(ptr %22)
  br label %endif31

else30:                                           ; preds = %endif27
  br label %endif31

endif31:                                          ; preds = %else30, %then29
  %regval32 = phi i64 [ 0, %then29 ], [ 0, %else30 ]
  call void @avra_rc_release(ptr %16)
  br label %endif18

lhead38:                                          ; preds = %endif54, %lexit
  %ld40 = load i64, ptr %slot37, align 8
  %ld41 = load i64, ptr %slot1, align 8
  %cmp42 = icmp sle i64 %ld40, %ld41
  br i1 %cmp42, label %lbody43, label %lexit39

lexit39:                                          ; preds = %lhead38
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

lbody43:                                          ; preds = %lhead38
  %ld44 = load i64, ptr %slot37, align 8
  %24 = call i64 @avra_array_get(ptr %2, i64 %ld44)
  %boxed45 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %boxed45)
  %25 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Ebrackets"(ptr %boxed45)
  br i1 %25, label %then46, label %else47

then46:                                           ; preds = %lbody43
  br label %endif48

else47:                                           ; preds = %lbody43
  %ld49 = load i64, ptr %slot37, align 8
  %26 = call i64 @avra_array_get(ptr %2, i64 %ld49)
  %boxed50 = inttoptr i64 %26 to ptr
  call void @avra_rc_retain(ptr %boxed50)
  %27 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Echanges_cell"(ptr %boxed50, i64 %5)
  br label %endif48

endif48:                                          ; preds = %else47, %then46
  %regval51 = phi i1 [ true, %then46 ], [ %27, %else47 ]
  br i1 %regval51, label %then52, label %else53

then52:                                           ; preds = %endif48
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else53:                                           ; preds = %endif48
  br label %endif54

endif54:                                          ; preds = %else53, %postret55
  %regval56 = phi i64 [ 0, %postret55 ], [ 0, %else53 ]
  %ld57 = load i64, ptr %slot37, align 8
  %add58 = add i64 %ld57, 1
  store i64 %add58, ptr %slot37, align 8
  br label %lhead38

postret55:                                        ; No predecessors!
  br label %endif54
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l397"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eheld_by"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eheld_by"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l452" to i64))
  call void @avra_array_push(ptr %2, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  %cast = inttoptr i64 %3 to ptr
  %6 = call i1 %cast(ptr %2, i64 %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l452"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Echanges_cell"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %2, 23
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l462" to i64))
  call void @avra_array_push(ptr %3, i64 %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereads_of"(ptr %0)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot1, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %endif6, %endif
  %ld = load i64, ptr %slot1, align 8
  %cmp2 = icmp slt i64 %ld, %6
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld9 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld9

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %4 to ptr
  %8 = call i1 %cast(ptr %3, i64 %7)
  br i1 %8, label %then4, label %else5

then4:                                            ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  br label %endif6

else5:                                            ; preds = %lbody
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval7 = phi i64 [ 0, %then4 ], [ 0, %else5 ]
  %ld8 = load i64, ptr %slot1, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l462"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ereads_of"(ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ebrackets"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 12
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %2, 13
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp5 = icmp eq i64 %3, 14
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp10 = icmp eq i64 %4, 15
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp15 = icmp eq i64 %5, 16
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp20 = icmp eq i64 %6, 17
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi i1 [ true, %then17 ], [ %cmp20, %else18 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif19
  br label %endif24

else23:                                           ; preds = %endif19
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp25 = icmp eq i64 %7, 25
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br i1 %regval26, label %then27, label %else28

then27:                                           ; preds = %endif24
  br label %endif29

else28:                                           ; preds = %endif24
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp30 = icmp eq i64 %8, 26
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval31 = phi i1 [ true, %then27 ], [ %cmp30, %else28 ]
  br i1 %regval31, label %then32, label %else33

then32:                                           ; preds = %endif29
  br label %endif34

else33:                                           ; preds = %endif29
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp35 = icmp eq i64 %9, 27
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval36 = phi i1 [ true, %then32 ], [ %cmp35, %else33 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval36
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %3, 3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp1 = icmp eq i64 %4, 4
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %5 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp5 = icmp eq i64 %5, 6
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval69 = phi i1 [ true, %then2 ], [ %regval68, %endif8 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval69

then6:                                            ; preds = %else3
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %6 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eflat_managed"(ptr %0, ptr %1)
  br label %endif8

else7:                                            ; preds = %else3
  %7 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp9 = icmp eq i64 %7, 10
  br i1 %cmp9, label %then10, label %else11

endif8:                                           ; preds = %endif57, %then6
  %regval68 = phi i1 [ %6, %then6 ], [ %regval67, %endif57 ]
  br label %endif4

then10:                                           ; preds = %else7
  br label %endif12

else11:                                           ; preds = %else7
  %8 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp13 = icmp eq i64 %8, 11
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i1 [ true, %then10 ], [ %cmp13, %else11 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif12
  br label %endif17

else16:                                           ; preds = %endif12
  %9 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp18 = icmp eq i64 %9, 7
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval19 = phi i1 [ true, %then15 ], [ %cmp18, %else16 ]
  br i1 %regval19, label %then20, label %else21

then20:                                           ; preds = %endif17
  br label %endif22

else21:                                           ; preds = %endif17
  %10 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp23 = icmp eq i64 %10, 18
  br label %endif22

endif22:                                          ; preds = %else21, %then20
  %regval24 = phi i1 [ true, %then20 ], [ %cmp23, %else21 ]
  br i1 %regval24, label %then25, label %else26

then25:                                           ; preds = %endif22
  br label %endif27

else26:                                           ; preds = %endif22
  %11 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp28 = icmp eq i64 %11, 12
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval29 = phi i1 [ true, %then25 ], [ %cmp28, %else26 ]
  br i1 %regval29, label %then30, label %else31

then30:                                           ; preds = %endif27
  br label %endif32

else31:                                           ; preds = %endif27
  %12 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp33 = icmp eq i64 %12, 19
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval34 = phi i1 [ true, %then30 ], [ %cmp33, %else31 ]
  br i1 %regval34, label %then35, label %else36

then35:                                           ; preds = %endif32
  br label %endif37

else36:                                           ; preds = %endif32
  %13 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp38 = icmp eq i64 %13, 13
  br label %endif37

endif37:                                          ; preds = %else36, %then35
  %regval39 = phi i1 [ true, %then35 ], [ %cmp38, %else36 ]
  br i1 %regval39, label %then40, label %else41

then40:                                           ; preds = %endif37
  br label %endif42

else41:                                           ; preds = %endif37
  %14 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp43 = icmp eq i64 %14, 8
  br label %endif42

endif42:                                          ; preds = %else41, %then40
  %regval44 = phi i1 [ true, %then40 ], [ %cmp43, %else41 ]
  br i1 %regval44, label %then45, label %else46

then45:                                           ; preds = %endif42
  br label %endif47

else46:                                           ; preds = %endif42
  %15 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp48 = icmp eq i64 %15, 9
  br label %endif47

endif47:                                          ; preds = %else46, %then45
  %regval49 = phi i1 [ true, %then45 ], [ %cmp48, %else46 ]
  br i1 %regval49, label %then50, label %else51

then50:                                           ; preds = %endif47
  br label %endif52

else51:                                           ; preds = %endif47
  %16 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp53 = icmp eq i64 %16, 14
  br label %endif52

endif52:                                          ; preds = %else51, %then50
  %regval54 = phi i1 [ true, %then50 ], [ %cmp53, %else51 ]
  br i1 %regval54, label %then55, label %else56

then55:                                           ; preds = %endif52
  br label %endif57

else56:                                           ; preds = %endif52
  %17 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp58 = icmp eq i64 %17, 16
  br i1 %cmp58, label %then59, label %else60

endif57:                                          ; preds = %endif61, %then55
  %regval67 = phi i1 [ true, %then55 ], [ %regval66, %endif61 ]
  br label %endif8

then59:                                           ; preds = %else56
  %18 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eis_flat"(ptr %0, ptr %18)
  br i1 %19, label %then62, label %else63

else60:                                           ; preds = %else56
  br label %endif61

endif61:                                          ; preds = %else60, %endif64
  %regval66 = phi i1 [ %regval65, %endif64 ], [ false, %else60 ]
  br label %endif57

then62:                                           ; preds = %then59
  br label %endif64

else63:                                           ; preds = %then59
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %20 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %18)
  br label %endif64

endif64:                                          ; preds = %else63, %then62
  %regval65 = phi i1 [ true, %then62 ], [ %20, %else63 ]
  call void @avra_rc_release(ptr %18)
  br label %endif61
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eflat_managed"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eis_flat"(ptr %0, ptr %1)
  %not = xor i1 %2, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eflat_fields"(ptr %0, ptr %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %5

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eview_of"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm1 [
    i64 7, label %arm
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ert_owns"(ptr %boxed)
  br i1 %4, label %then, label %else

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eviewed_dst"(ptr %0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif
  %regval2 = phi ptr [ %regval, %endif ], [ %5, %arm1 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval2

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif

else:                                             ; preds = %arm
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %2)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ null, %then ], [ %6, %else ]
  br label %endswitch
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eviewed_dst"(ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2Ert_owns"(ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Egives_upward"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 13
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %2, 16
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp5 = icmp eq i64 %3, 17
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp10 = icmp eq i64 %4, 20
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp15 = icmp eq i64 %5, 21
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp20 = icmp eq i64 %6, 24
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi i1 [ true, %then17 ], [ %cmp20, %else18 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif19
  br label %endif24

else23:                                           ; preds = %endif19
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp25 = icmp eq i64 %7, 8
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval26
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eholds_cell"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Etop$24296"(ptr %0)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  %6 = call i64 @avra_array_get(ptr %3, i64 2)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %1)
  %8 = call ptr @avra_array_concat(ptr %boxed, ptr %7)
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Erewrite_top$24296"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Erewrite_top$24296"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Etop$24296"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eexit_releases"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Edepth$24296"(ptr %0)
  %sub = sub i64 %3, 1
  store i64 %sub, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld6 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld6)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Eat$24296"(ptr %0, i64 %ld2)
  %ld3 = load ptr, ptr %slot, align 8
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Ereleases_for"(ptr %4, ptr %5)
  %7 = call ptr @avra_array_concat(ptr %ld3, ptr %6)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  %ld4 = load i64, ptr %slot1, align 8
  %sub5 = sub i64 %ld4, 1
  store i64 %sub5, ptr %slot1, align 8
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Ereleases_for"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  switch i64 %3, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$2477"(ptr %boxed2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekept_out"(ptr %5, ptr %1)
  call void @avra_rc_release(ptr %5)
  br label %endswitch

arm1:                                             ; preds = %entry
  %7 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ %7, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ekept_out"(ptr %0, ptr %1) {
entry:
  %slot3 = alloca i64, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca i1, align 1
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  store i1 false, ptr %slot1, align 8
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif10, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld14 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld14)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld14

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 %ld4)
  store i64 %4, ptr %slot3, align 8
  %ld5 = load i1, ptr %slot1, align 8
  %not = xor i1 %ld5, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  %ld6 = load i64, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %1)
  %5 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Estays"(i64 %ld6, ptr %1)
  %not7 = xor i1 %5, true
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not7, %then ], [ false, %else ]
  br i1 %regval, label %then8, label %else9

then8:                                            ; preds = %endif
  store i1 true, ptr %slot1, align 8
  br label %endif10

else9:                                            ; preds = %endif
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld11 = load i64, ptr %slot3, align 8
  call void @avra_array_push(ptr %6, i64 %ld11)
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval12 = phi i64 [ 0, %then8 ], [ 0, %else9 ]
  %ld13 = load i64, ptr %slot2, align 8
  %add = add i64 %ld13, 1
  store i64 %add, ptr %slot2, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Estays"(i64 %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call ptr @avra_insist(ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp1 = icmp ne i64 %0, %3
  call void @avra_rc_release(ptr %2)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  call void @avra_rc_release(ptr %1)
  ret i1 %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$2477"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Eat$24296"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Edepth$24296"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ecell_settle"(i64 %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 %0)
  %2 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %2, i64 6)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eexit_cells"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Edepth$24296"(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld6 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld6)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Eat$24296"(ptr %0, i64 %ld2)
  %ld3 = load ptr, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %3, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$2477"(ptr %boxed)
  %6 = call ptr @avra_array_concat(ptr %ld3, ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  %ld4 = load i64, ptr %slot1, align 8
  %sub5 = sub i64 %ld4, 1
  store i64 %sub5, ptr %slot1, align 8
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eretained_args"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args"(ptr %2)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %7 = call i64 @avra_array_get(ptr %1, i64 %6)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 28)
  call void @avra_array_push(ptr %9, i64 %6)
  call void @avra_array_push_owned(ptr %3, ptr %9)
  call void @avra_rc_release(ptr %9)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args"(ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2Emanages"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Emanaged_dst"(ptr %0, ptr %1, ptr %3)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %2)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Etakes"(ptr %2, i64 %6)
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Etakes"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Etop$24296"(ptr %0)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  %5 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %1)
  %7 = call ptr @avra_array_concat(ptr %boxed, ptr %6)
  %8 = call i64 @avra_array_get(ptr %3, i64 2)
  %boxed1 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %boxed1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Erewrite_top$24296"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Emanaged_dst"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eowned_dst"(ptr %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call i64 @avra_array_get(ptr %1, i64 %5)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  %not1 = xor i1 %7, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %8 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %8, label %arm7 [
    i64 7, label %arm
  ]

postret5:                                         ; No predecessors!
  br label %endif4

arm:                                              ; preds = %endif4
  %9 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed8 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  %10 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ert_owns"(ptr %boxed8)
  br i1 %10, label %then9, label %else10

arm7:                                             ; preds = %endif4
  call void @avra_rc_retain(ptr %3)
  br label %endswitch

endswitch:                                        ; preds = %arm7, %endif11
  %regval13 = phi ptr [ %regval12, %endif11 ], [ %3, %arm7 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval13

then9:                                            ; preds = %arm
  call void @avra_rc_retain(ptr %3)
  br label %endif11

else10:                                           ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval12 = phi ptr [ %3, %then9 ], [ null, %else10 ]
  br label %endswitch
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eowned_dst"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Enested_scope"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eenclosing_tier"(ptr %0)
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eenclosing_tier"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Etop$24296"(ptr %0)
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %1)
  %4 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %2)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eadopts"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %2)
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2EStack$2Eis_empty$24296"(ptr %2)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %4, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %7 = call i64 @avra_array_get(ptr %1, i64 %6)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  br i1 %8, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif3

then5:                                            ; preds = %endif3
  %9 = call ptr @avra_insist(ptr %3)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  call void @avra_rc_retain(ptr %2)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Etakes"(ptr %2, i64 %10)
  call void @avra_rc_release(ptr %9)
  br label %endif7

else6:                                            ; preds = %endif3
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2EStack$2Eis_empty$24296"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Emoved_out"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot7 = alloca i64, align 8
  %slot = alloca i1, align 1
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %7 = call i64 @avra_array_get(ptr %1, i64 %6)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  %not1 = xor i1 %8, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

then2:                                            ; preds = %endif
  %9 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  store i1 false, ptr %slot, align 8
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l578" to i64))
  call void @avra_array_push(ptr %10, i64 %6)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %12 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %13 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot7, align 8
  br label %lhead

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif4

lhead:                                            ; preds = %endif12, %endif4
  %ld = load i64, ptr %slot7, align 8
  %cmp8 = icmp slt i64 %ld, %13
  br i1 %cmp8, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld15 = load i1, ptr %slot, align 8
  br i1 %ld15, label %then16, label %else17

lbody:                                            ; preds = %lhead
  %ld9 = load i64, ptr %slot7, align 8
  %14 = call i64 @avra_array_get(ptr %12, i64 %ld9)
  call void @avra_rc_retain(ptr %10)
  %cast = inttoptr i64 %11 to ptr
  %15 = call i1 %cast(ptr %10, i64 %14)
  br i1 %15, label %then10, label %else11

then10:                                           ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %13, ptr %slot7, align 8
  br label %endif12

else11:                                           ; preds = %lbody
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %ld14 = load i64, ptr %slot7, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot7, align 8
  br label %lhead

then16:                                           ; preds = %lexit
  %16 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else17:                                           ; preds = %lexit
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  %17 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %17, i64 28)
  call void @avra_array_push(ptr %17, i64 %6)
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

postret19:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  br label %endif18
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ememory$24l578"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Esettled"(ptr %0, ptr %1) {
entry:
  %slot3 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$2477"(ptr %boxed)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %6 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EScope$2Ereleases_for"(ptr %0, ptr %1)
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot3, align 8
  br label %lhead4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ecell_settle"(i64 %9)
  call void @avra_array_push_owned(ptr %2, ptr %10)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead

lhead4:                                           ; preds = %lbody8, %lexit
  %ld6 = load i64, ptr %slot3, align 8
  %cmp7 = icmp slt i64 %ld6, %8
  br i1 %cmp7, label %lbody8, label %lexit5

lexit5:                                           ; preds = %lhead4
  %11 = call ptr @avra_array_concat(ptr %2, ptr %6)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

lbody8:                                           ; preds = %lhead4
  %ld9 = load i64, ptr %slot3, align 8
  %12 = call i64 @avra_array_get(ptr %7, i64 %ld9)
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 29)
  call void @avra_array_push(ptr %13, i64 %12)
  call void @avra_array_push_owned(ptr %6, ptr %13)
  %ld10 = load i64, ptr %slot3, align 8
  %add11 = add i64 %ld10, 1
  store i64 %add11, ptr %slot3, align 8
  call void @avra_rc_release(ptr %13)
  br label %lhead4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eempty_scope"() {
entry:
  %0 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %0, i64 0)
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr %0)
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2EStack$2Epop$24296"(ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2EStack$2Epush$24296"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eowned_form"(ptr %0, ptr %1, ptr %2, i64 %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 6, label %arm
    i64 7, label %arm1
  ]

arm:                                              ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %6)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ert_owned_twin"(ptr %6)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

arm1:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %4, i64 1)
  %10 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %11 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  call void @avra_rc_retain(ptr %10)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ert_owned_twin"(ptr %10)
  %cmp7 = icmp ne ptr %12, null
  br i1 %cmp7, label %then8, label %else9

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %4)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif22, %endif5
  %regval24 = phi ptr [ %regval6, %endif5 ], [ %regval23, %endif22 ], [ %4, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval24

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  %13 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Epushes_managed"(ptr %0, ptr %1, ptr %7)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %13, %then ], [ false, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  %14 = call ptr @avra_insist(ptr %8)
  %15 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %15, i64 6)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_array_push_owned(ptr %15, ptr %7)
  call void @avra_rc_release(ptr %14)
  br label %endif5

else4:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %4)
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval6 = phi ptr [ %15, %then3 ], [ %4, %else4 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

then8:                                            ; preds = %arm1
  %16 = call i64 @avra_array_get(ptr %1, i64 %9)
  %boxed = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %17 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  br label %endif10

else9:                                            ; preds = %arm1
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i1 [ %17, %then8 ], [ false, %else9 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif10
  call void @avra_rc_retain(ptr %10)
  %18 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ert_lends"(ptr %10)
  %not = xor i1 %18, true
  br i1 %not, label %then15, label %else16

else13:                                           ; preds = %endif10
  br label %endif14

endif14:                                          ; preds = %else13, %endif17
  %regval19 = phi i1 [ %regval18, %endif17 ], [ false, %else13 ]
  br i1 %regval19, label %then20, label %else21

then15:                                           ; preds = %then12
  br label %endif17

else16:                                           ; preds = %then12
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %11)
  %19 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eread_outlives"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %9, ptr %11)
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval18 = phi i1 [ true, %then15 ], [ %19, %else16 ]
  br label %endif14

then20:                                           ; preds = %endif14
  %20 = call ptr @avra_insist(ptr %12)
  %21 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %21, i64 7)
  call void @avra_array_push(ptr %21, i64 %9)
  call void @avra_array_push_owned(ptr %21, ptr %20)
  call void @avra_array_push_owned(ptr %21, ptr %11)
  call void @avra_rc_release(ptr %20)
  br label %endif22

else21:                                           ; preds = %endif14
  call void @avra_rc_retain(ptr %4)
  br label %endif22

endif22:                                          ; preds = %else21, %then20
  %regval23 = phi ptr [ %21, %then20 ], [ %4, %else21 ]
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eread_outlives"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4, ptr %5) {
entry:
  %6 = call i64 @avra_array_len(ptr %5)
  %cmp = icmp eq i64 %6, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call i64 @avra_array_get(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eborrow_outlives"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4, i64 %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %8

postret:                                          ; No predecessors!
  br label %endif
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Ert_lends"(ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Epushes_managed"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 0, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %sub = sub i64 %3, 1
  %4 = call i64 @avra_array_get(ptr %2, i64 %sub)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %ld, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  %6 = call ptr @avra_insist(ptr %ld)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %8 = call i64 @avra_array_get(ptr %1, i64 %7)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %9 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %boxed)
  call void @avra_rc_release(ptr %6)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i1 [ %9, %then2 ], [ false, %else3 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval5
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ert_owned_twin"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Enew_stack$24296"()

define ptr @"av_$40std$2Eavrac$2Elanguage$2Emanaged_params"(ptr %0, ptr %1) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld6 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld6)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld6

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 %ld3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot2)
  store ptr %5, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld4)
  %6 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eis_managed"(ptr %0, ptr %ld4)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  %7 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push(ptr %7, i64 %ld3)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld5 = load i64, ptr %slot1, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}
