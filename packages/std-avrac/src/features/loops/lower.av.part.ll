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

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_for_each"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Eelem_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %2, ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 3)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %boxed)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 22)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_slot"(ptr %0, i64 %1, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_index"(ptr %0, i64 %1, i64 %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %5, i64 %12)
  %15 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %15, i64 24)
  call void @avra_array_push(ptr %15, i64 %7)
  call void @avra_array_push(ptr %15, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %5)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %18
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_index"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_slot"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Eelem_of"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_for"(ptr %0, i64 %1, i64 %2, i64 %3, i64 %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %7)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 22)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  %11 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %11, i64 24)
  call void @avra_array_push(ptr %11, i64 %8)
  call void @avra_array_push(ptr %11, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %11)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_slot"(ptr %0, i64 %1, i64 %8)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr %0, i64 %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %4)
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %19, i64 24)
  call void @avra_array_push(ptr %19, i64 %8)
  call void @avra_array_push(ptr %19, i64 %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %19)
  call void @avra_rc_retain(ptr %0)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr %0)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %21
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Elower_while"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr %0, ptr %2)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr %0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}
