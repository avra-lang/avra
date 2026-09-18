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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Elower"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 25, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call i64 @avra_array_get(ptr %5, i64 2)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed3)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ecall_value_reg"(ptr %1, i64 %2, i64 %7, ptr %boxed3)
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Elambda_reg"(ptr %1, i64 %2)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %9, %arm ], [ %10, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Elambda_reg"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ecall_value_reg"(ptr, i64, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Etype_of"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 25, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call i64 @avra_array_get(ptr %5, i64 2)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed3)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ecall_value_type"(ptr %1, i64 %2, i64 %7, ptr %boxed3)
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Elambda_type"(ptr %1, i64 %2)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ %9, %arm ], [ %10, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Elambda_type"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ecall_value_type"(ptr, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Eresolve"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 24, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  %8 = call i64 @avra_array_get(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elambda_scope"(ptr %1, i64 %2, ptr %7, i64 %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

arm2:                                             ; preds = %entry
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %9, %arm ], [ %10, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elambda_scope"(ptr, i64, ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2EClosureSemantics$2Ekids"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 25, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %3)
  %6 = call ptr @avra_array_concat(ptr %5, ptr %boxed)
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
