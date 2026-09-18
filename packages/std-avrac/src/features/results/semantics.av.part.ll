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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Elower"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatch_reg"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatch_reg"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Etype_of"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatch_type"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatch_type"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Eresolve"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot3 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 31, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 3)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 4)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm2:                                             ; preds = %entry
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %lexit
  %regval = phi i64 [ 0, %lexit ], [ %10, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %11 = call i64 @avra_array_get(ptr %8, i64 %ld4)
  store i64 %11, ptr %slot3, align 8
  %12 = call i64 @avra_array_get(ptr %7, i64 %ld4)
  %boxed5 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enamed_bind"(ptr %boxed5)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_at"(ptr %1, i64 %2, ptr %13)
  %ld6 = load i64, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr %1, ptr %14, i64 %ld6)
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_at"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enamed_bind"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2ECatchSemantics$2Ekids"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 31, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %3)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}
