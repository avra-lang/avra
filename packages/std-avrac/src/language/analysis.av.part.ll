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

define ptr @"av_$40std$2Eavrac$2Elanguage$2ELanguage$2Eanalyze"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Elone_workspace"(ptr %2, ptr %boxed, ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  %ld1 = load ptr, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed2 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %ld1)
  call void @avra_rc_retain(ptr %boxed2)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Efile_id"(ptr %ld1, ptr %boxed2)
  call void @avra_rc_retain(ptr %ld)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Eanalysis"(ptr %ld, i64 %6)
  %ld3 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld3)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Edisarmed"(ptr %ld3)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Edisarmed"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Eanalysis"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Efile_id"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ediagnostics$2Ehas_errors"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Efile_view"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 0)
  %8 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %9, i64 %3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %boxed)
  call void @avra_array_push_owned(ptr %9, ptr %2)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %boxed1)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Elone_workspace"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ELanguage$2Echeck"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELanguage$2Eanalyze"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EAnalysis$2Echeck"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EAnalysis$2Echeck"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %2 to ptr
  %3 = call ptr %cast(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EProgram$2Echeck"(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ %7, %arm1 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EProgram$2Echeck"(ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2EAnalysis$2Eclean"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %1 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %2 = call i1 @"av_$40std$2Eavrac$2Ediagnostics$2Ehas_errors"(ptr %boxed)
  %not = xor i1 %2, true
  call void @avra_rc_release(ptr %0)
  ret i1 %not
}
