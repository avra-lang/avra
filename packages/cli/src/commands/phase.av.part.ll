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

declare i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr)

declare i64 @"av_$40std$2Eprelude$2Eprintln"(ptr)

declare i64 @"av_$40std$2Etime$2Enow_ns"()

define i64 @"av_commands$2Ephased"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_commands$2Ephase$24l22" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %0)
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_commands$2Eon_program"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_commands$2Ephase$24l22"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @"av_$40std$2Etime$2Enow_ns"()
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %cast = inttoptr i64 %4 to ptr
  %5 = call ptr %cast(ptr %boxed, ptr %1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call i1 @"av_commands$2Etimed"(ptr %boxed1)
  br i1 %7, label %then, label %else

then:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed2 = inttoptr i64 %8 to ptr
  %9 = call i64 @"av_$40std$2Etime$2Enow_ns"()
  %sub = sub i64 %9, %2
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed2)
  %10 = call ptr @"av_commands$2Etimings"(ptr %1, ptr %boxed2, i64 %sub)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %10)
  call void @avra_rc_release(ptr %10)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %12 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %12, label %arm3 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %endif
  %13 = call i64 @avra_array_get(ptr %5, i64 1)
  br label %endswitch

arm3:                                             ; preds = %endif
  %14 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr %14)
  call void @avra_rc_release(ptr %14)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm
  %regval4 = phi i64 [ %13, %arm ], [ 1, %arm3 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval4
}

declare ptr @"av_commands$2Etimings"(ptr, ptr, i64)

declare i1 @"av_commands$2Etimed"(ptr)

declare i64 @"av_commands$2Eon_program"(ptr, ptr)
