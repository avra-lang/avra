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

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24148"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24148"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24148"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24289"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24289"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eat$24251"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24251"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 1, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24251"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24251"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24334"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24453"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24459"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24153"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24153"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24459"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24265"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$2421"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eat$2421"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$2421"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 1, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$2421"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24265"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24145"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24145"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24453"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24341"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24334"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24419"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24419"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24341"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24138"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24138"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eat$24439"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24439"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 1, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24439"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24439"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24139"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24139"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ETable$2Ekeep$24114"(ptr %0, i64 %1, ptr %2) {
entry:
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %4, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_slot_set_owned(ptr %5, i64 %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %7 = call ptr @avra_slot_unique(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ETable$2Eentry$24114"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24459"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24453"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24265"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24439"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24114"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24139"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24251"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24138"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24341"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24419"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24334"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24145"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$2421"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24289"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_table$24153"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}
