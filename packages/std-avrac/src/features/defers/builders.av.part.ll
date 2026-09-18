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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr_node"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Ebuild_errdefer$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Ebuild_errdefer"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Ebuild_defer$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Ebuild_defer"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Ebuild_errdefer"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edeferred"(ptr %0, i1 true)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edeferred"(ptr %0, i1 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %3, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

endif:                                            ; preds = %postret, %then
  %regval = phi i64 [ %5, %then ], [ 0, %postret ]
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 24)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push(ptr %6, i64 %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr_node"(ptr %0, ptr %6)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 23)
  call void @avra_array_push(ptr %8, i64 %7)
  %slot = zext i1 %1 to i64
  call void @avra_array_push(ptr %8, i64 %slot)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_stmt"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Ebuild_defer"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edeferred"(ptr %0, i1 false)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}
