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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Elower_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 17, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 3)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 4)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_for_each"(ptr %1, i64 %2, i64 %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_for_each"(ptr, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Etype_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_for_each"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_for_each"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForEachSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 17, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 3)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 4)
  call void @avra_rc_retain(ptr %1)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %1, i64 %7)
  %10 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %8)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_scope"(ptr %1, i64 %2, ptr %10, ptr %8)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm2:                                             ; preds = %entry
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %11, %arm ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_scope"(ptr, i64, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Escope_stmts"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Elower_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 15, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 2)
  %8 = call i64 @avra_array_get(ptr %5, i64 4)
  %9 = call i64 @avra_array_get(ptr %5, i64 5)
  %10 = call ptr @avra_array_get_owned(ptr %5, i64 6)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_for"(ptr %1, i64 %2, i64 %7, i64 %8, i64 %9, ptr %10)
  call void @avra_rc_release(ptr %10)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_for"(ptr, i64, i64, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Etype_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_for"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_for"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EForSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 15, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 2)
  %8 = call i64 @avra_array_get(ptr %5, i64 3)
  %9 = call i64 @avra_array_get(ptr %5, i64 4)
  %10 = call i64 @avra_array_get(ptr %5, i64 5)
  %11 = call ptr @avra_array_get_owned(ptr %5, i64 6)
  call void @avra_rc_retain(ptr %1)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %1, i64 %7)
  call void @avra_rc_retain(ptr %1)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %1, i64 %8)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 %9)
  call void @avra_array_push(ptr %14, i64 %10)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %11)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_scope"(ptr %1, i64 %2, ptr %14, ptr %11)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

arm2:                                             ; preds = %entry
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %15, %arm ], [ %16, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Elower_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 8, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_while"(ptr %1, i64 %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_while"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Etype_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_while"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_while"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2EWhileSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 8, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %1)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %1, i64 %7)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Escope_stmts"(ptr %1, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm2:                                             ; preds = %entry
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %10, %arm ], [ %11, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}
