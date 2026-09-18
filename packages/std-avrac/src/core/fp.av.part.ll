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

define i64 @"av_$40std$2Eavrac$2Ecore$2Efp_str"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  %1 = call i64 @avra_str_len(ptr %0)
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot, align 8
  %2 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp_mix"(i64 %ld5, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call i64 @avra_str_char_code(ptr %0, i64 %ld3)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp_mix"(i64 %ld2, i64 %3)
  store i64 %4, ptr %slot, align 8
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Efp_mix"(i64 %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_int_mod(i64 %1, i64 1000000007)
  store i64 %2, ptr %slot, align 8
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %ld1 = load i64, ptr %slot, align 8
  %add = add i64 %ld1, 1000000007
  store i64 %add, ptr %slot, align 8
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %mul = mul i64 %0, 131
  %ld2 = load i64, ptr %slot, align 8
  %add3 = add i64 %mul, %ld2
  %add4 = add i64 %add3, 7
  %3 = call i64 @avra_int_mod(i64 %add4, i64 1000000007)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Efp"(i64 %0, ptr %1) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp_mix"(i64 %0, i64 %2)
  store i64 %3, ptr %slot, align 8
  %4 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld7 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %1)
  ret i64 %ld7

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 %ld3)
  store i64 %5, ptr %slot2, align 8
  %ld4 = load i64, ptr %slot, align 8
  %ld5 = load i64, ptr %slot2, align 8
  %6 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp_mix"(i64 %ld4, i64 %ld5)
  store i64 %6, ptr %slot, align 8
  %ld6 = load i64, ptr %slot1, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Efp_list"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp"(i64 105, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret i64 %1
}
