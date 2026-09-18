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

define ptr @"av_$40std$2Eavrac$2Egrammar$2EGrammar$2Emerged"(ptr %0) {
entry:
  %slot35 = alloca ptr, align 8
  store ptr null, ptr %slot35, align 8
  %slot27 = alloca i64, align 8
  %slot7 = alloca ptr, align 8
  store ptr null, ptr %slot7, align 8
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_map_new()
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot1)
  store ptr %2, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif12, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_array_sized(i64 0)
  %ld26 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld26)
  %6 = call i64 @avra_array_len(ptr %ld26)
  store i64 0, ptr %slot27, align 8
  br label %lhead28

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %7 = call ptr @avra_array_get_owned(ptr %3, i64 %ld4)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot3)
  store ptr %7, ptr %slot3, align 8
  %ld5 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld5)
  %ld6 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld6)
  %8 = call ptr @avra_array_get_owned(ptr %ld6, i64 0)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot7)
  store ptr null, ptr %slot7, align 8
  %9 = call i64 @avra_map_has(ptr %ld5, ptr %8)
  %b = icmp ne i64 %9, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  %10 = call ptr @avra_map_get_owned(ptr %ld5, ptr %8)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot7)
  store ptr %10, ptr %slot7, align 8
  call void @avra_rc_release(ptr %10)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld8 = load ptr, ptr %slot7, align 8
  call void @avra_rc_retain(ptr %ld8)
  %cmp9 = icmp ne ptr %ld8, null
  %not = xor i1 %cmp9, true
  br i1 %not, label %then10, label %else11

then10:                                           ; preds = %endif
  %11 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot3, align 8
  %12 = call i64 @avra_array_get(ptr %ld13, i64 0)
  %boxed = inttoptr i64 %12 to ptr
  call void @avra_array_push_owned(ptr %11, ptr %boxed)
  %13 = call ptr @avra_cell_unique(ptr %slot1)
  %ld14 = load ptr, ptr %slot3, align 8
  %14 = call i64 @avra_array_get(ptr %ld14, i64 0)
  %boxed15 = inttoptr i64 %14 to ptr
  %ld16 = load ptr, ptr %slot3, align 8
  %15 = call i64 @avra_array_get(ptr %ld16, i64 1)
  %boxed17 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %boxed17, i64 0)
  %boxed18 = inttoptr i64 %16 to ptr
  call void @avra_map_set_owned(ptr %13, ptr %boxed15, ptr %boxed18)
  br label %endif12

else11:                                           ; preds = %endif
  %17 = call ptr @avra_cell_unique(ptr %slot1)
  %ld19 = load ptr, ptr %slot3, align 8
  %18 = call i64 @avra_array_get(ptr %ld19, i64 0)
  %boxed20 = inttoptr i64 %18 to ptr
  %19 = call ptr @avra_insist(ptr %ld8)
  %ld21 = load ptr, ptr %slot3, align 8
  %20 = call i64 @avra_array_get(ptr %ld21, i64 1)
  %boxed22 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %boxed22, i64 0)
  %boxed23 = inttoptr i64 %21 to ptr
  %22 = call ptr @avra_array_concat(ptr %19, ptr %boxed23)
  call void @avra_map_set_owned(ptr %17, ptr %boxed20, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %19)
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval24 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %ld25 = load i64, ptr %slot2, align 8
  %add = add i64 %ld25, 1
  store i64 %add, ptr %slot2, align 8
  call void @avra_cell_release(ptr %slot7)
  call void @avra_rc_release(ptr %ld8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %ld6)
  call void @avra_rc_release(ptr %ld5)
  call void @avra_rc_release(ptr %7)
  br label %lhead

lhead28:                                          ; preds = %endif39, %lexit
  %ld30 = load i64, ptr %slot27, align 8
  %cmp31 = icmp slt i64 %ld30, %6
  br i1 %cmp31, label %lbody32, label %lexit29

lexit29:                                          ; preds = %lhead28
  %23 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed44 = inttoptr i64 %24 to ptr
  %25 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %25, ptr %23)
  call void @avra_array_push_owned(ptr %25, ptr %boxed44)
  call void @avra_array_push_owned(ptr %25, ptr %5)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %ld26)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %25

lbody32:                                          ; preds = %lhead28
  %ld33 = load i64, ptr %slot27, align 8
  %26 = call ptr @avra_array_get_owned(ptr %ld26, i64 %ld33)
  %ld34 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld34)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot35)
  store ptr null, ptr %slot35, align 8
  %27 = call i64 @avra_map_has(ptr %ld34, ptr %26)
  %b36 = icmp ne i64 %27, 0
  br i1 %b36, label %then37, label %else38

then37:                                           ; preds = %lbody32
  %28 = call ptr @avra_map_get_owned(ptr %ld34, ptr %26)
  call void @avra_rc_retain(ptr %28)
  call void @avra_cell_release(ptr %slot35)
  store ptr %28, ptr %slot35, align 8
  call void @avra_rc_release(ptr %28)
  br label %endif39

else38:                                           ; preds = %lbody32
  br label %endif39

endif39:                                          ; preds = %else38, %then37
  %regval40 = phi i64 [ 0, %then37 ], [ 0, %else38 ]
  %ld41 = load ptr, ptr %slot35, align 8
  %29 = call ptr @avra_insist(ptr %ld41)
  %30 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %30, ptr %29)
  %31 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %31, ptr %26)
  call void @avra_array_push_owned(ptr %31, ptr %30)
  call void @avra_array_push_owned(ptr %5, ptr %31)
  %ld42 = load i64, ptr %slot27, align 8
  %add43 = add i64 %ld42, 1
  store i64 %add43, ptr %slot27, align 8
  call void @avra_cell_release(ptr %slot35)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %ld34)
  call void @avra_rc_release(ptr %26)
  br label %lhead28
}
