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

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Efn_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 6, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 4)
  %8 = call i64 @avra_array_get(ptr %2, i64 5)
  %9 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %9, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etrait_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 13, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr %boxed)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edecl_tparams"(ptr %0, i64 %1) {
entry:
  %slot28 = alloca i64, align 8
  %slot18 = alloca i64, align 8
  %slot8 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm4 [
    i64 6, label %arm
    i64 18, label %arm1
    i64 19, label %arm2
    i64 20, label %arm3
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot8, align 8
  br label %lhead9

arm2:                                             ; preds = %entry
  %10 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call i64 @avra_array_len(ptr %10)
  store i64 0, ptr %slot18, align 8
  br label %lhead19

arm3:                                             ; preds = %entry
  %13 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call i64 @avra_array_len(ptr %13)
  store i64 0, ptr %slot28, align 8
  br label %lhead29

arm4:                                             ; preds = %entry
  %16 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm4, %lexit30, %lexit20, %lexit10, %lexit
  %regval = phi ptr [ %5, %lexit ], [ %8, %lexit10 ], [ %11, %lexit20 ], [ %14, %lexit30 ], [ %16, %arm4 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %4)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot, align 8
  %17 = call i64 @avra_array_get(ptr %4, i64 %ld5)
  %boxed = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed6 = inttoptr i64 %18 to ptr
  call void @avra_array_push_owned(ptr %5, ptr %boxed6)
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead9:                                           ; preds = %lbody13, %arm1
  %ld11 = load i64, ptr %slot8, align 8
  %cmp12 = icmp slt i64 %ld11, %9
  br i1 %cmp12, label %lbody13, label %lexit10

lexit10:                                          ; preds = %lhead9
  call void @avra_rc_release(ptr %7)
  br label %endswitch

lbody13:                                          ; preds = %lhead9
  %ld14 = load i64, ptr %slot8, align 8
  %19 = call i64 @avra_array_get(ptr %7, i64 %ld14)
  %boxed15 = inttoptr i64 %19 to ptr
  call void @avra_array_push_owned(ptr %8, ptr %boxed15)
  %ld16 = load i64, ptr %slot8, align 8
  %add17 = add i64 %ld16, 1
  store i64 %add17, ptr %slot8, align 8
  br label %lhead9

lhead19:                                          ; preds = %lbody23, %arm2
  %ld21 = load i64, ptr %slot18, align 8
  %cmp22 = icmp slt i64 %ld21, %12
  br i1 %cmp22, label %lbody23, label %lexit20

lexit20:                                          ; preds = %lhead19
  call void @avra_rc_release(ptr %10)
  br label %endswitch

lbody23:                                          ; preds = %lhead19
  %ld24 = load i64, ptr %slot18, align 8
  %20 = call i64 @avra_array_get(ptr %10, i64 %ld24)
  %boxed25 = inttoptr i64 %20 to ptr
  call void @avra_array_push_owned(ptr %11, ptr %boxed25)
  %ld26 = load i64, ptr %slot18, align 8
  %add27 = add i64 %ld26, 1
  store i64 %add27, ptr %slot18, align 8
  br label %lhead19

lhead29:                                          ; preds = %lbody33, %arm3
  %ld31 = load i64, ptr %slot28, align 8
  %cmp32 = icmp slt i64 %ld31, %15
  br i1 %cmp32, label %lbody33, label %lexit30

lexit30:                                          ; preds = %lhead29
  call void @avra_rc_release(ptr %13)
  br label %endswitch

lbody33:                                          ; preds = %lhead29
  %ld34 = load i64, ptr %slot28, align 8
  %21 = call i64 @avra_array_get(ptr %13, i64 %ld34)
  %boxed35 = inttoptr i64 %21 to ptr
  call void @avra_array_push_owned(ptr %14, ptr %boxed35)
  %ld36 = load i64, ptr %slot28, align 8
  %add37 = add i64 %ld36, 1
  store i64 %add37, ptr %slot28, align 8
  br label %lhead29
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eimpl_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 12, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif
  %regval2 = phi ptr [ %7, %endif ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval2

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %4)
  br label %endif

else:                                             ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %4, %then ], [ null, %else ]
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr %regval)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eextern_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 7, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call i64 @avra_array_get(ptr %2, i64 3)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr %4)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %7, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eenum_parts"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 20, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi ptr [ %9, %lexit ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etype_decl_name"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm3 [
    i64 18, label %arm
    i64 19, label %arm1
    i64 20, label %arm2
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ], [ %6, %arm2 ], [ null, %arm3 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Enamed_parts"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 19, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi ptr [ %9, %lexit ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_parts"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 18, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi ptr [ %9, %lexit ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 2, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 24, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm10 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 10, label %arm6
    i64 11, label %arm7
    i64 14, label %arm8
    i64 23, label %arm9
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %2, i64 3)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %2, i64 3)
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 %8)
  br label %endswitch

arm3:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %2, i64 2)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 %10)
  br label %endswitch

arm4:                                             ; preds = %entry
  %12 = call i64 @avra_array_get(ptr %2, i64 1)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 %12)
  br label %endswitch

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %2, i64 1)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 %14)
  br label %endswitch

arm6:                                             ; preds = %entry
  %16 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm7:                                             ; preds = %entry
  %17 = call i64 @avra_array_get(ptr %2, i64 1)
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 %17)
  br label %endswitch

arm8:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %2, i64 2)
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 %19)
  br label %endswitch

arm9:                                             ; preds = %entry
  %21 = call i64 @avra_array_get(ptr %2, i64 1)
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 %21)
  br label %endswitch

arm10:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ %7, %arm1 ], [ %9, %arm2 ], [ %11, %arm3 ], [ %13, %arm4 ], [ %15, %arm5 ], [ %16, %arm6 ], [ %18, %arm7 ], [ %20, %arm8 ], [ %22, %arm9 ], [ null, %arm10 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eshown_value"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 4, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_declaration"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_kind"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eimpl_parts"(ptr %0, i64 %1)
  %cmp1 = icmp ne ptr %3, null
  call void @avra_rc_release(ptr %3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Euse_parts"(ptr %0, i64 %1)
  %cmp5 = icmp ne ptr %4, null
  call void @avra_rc_release(ptr %4)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Espec_parts"(ptr %0, i64 %1)
  %cmp10 = icmp ne ptr %5, null
  call void @avra_rc_release(ptr %5)
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr %0, i64 %1)
  %cmp15 = icmp ne ptr %6, null
  call void @avra_rc_release(ptr %6)
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval16
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Espec_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 21, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr %boxed)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Euse_parts"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_kind"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Efn_parts"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eextern_parts"(ptr %0, i64 %1)
  %cmp1 = icmp ne ptr %3, null
  call void @avra_rc_release(ptr %3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eenum_parts"(ptr %0, i64 %1)
  %cmp6 = icmp ne ptr %5, null
  br i1 %cmp6, label %then7, label %else8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif4

then7:                                            ; preds = %endif4
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 4)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else8:                                            ; preds = %endif4
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_parts"(ptr %0, i64 %1)
  %cmp12 = icmp ne ptr %7, null
  br i1 %cmp12, label %then13, label %else14

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif9

then13:                                           ; preds = %endif9
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else14:                                           ; preds = %endif9
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Enamed_parts"(ptr %0, i64 %1)
  %cmp18 = icmp ne ptr %9, null
  br i1 %cmp18, label %then19, label %else20

postret16:                                        ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif15

then19:                                           ; preds = %endif15
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 3)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else20:                                           ; preds = %endif15
  br label %endif21

endif21:                                          ; preds = %else20, %postret22
  %regval23 = phi i64 [ 0, %postret22 ], [ 0, %else20 ]
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etrait_parts"(ptr %0, i64 %1)
  %cmp24 = icmp ne ptr %11, null
  br i1 %cmp24, label %then25, label %else26

postret22:                                        ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif21

then25:                                           ; preds = %endif21
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 5)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else26:                                           ; preds = %endif21
  br label %endif27

endif27:                                          ; preds = %else26, %postret28
  %regval29 = phi i64 [ 0, %postret28 ], [ 0, %else26 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Esyntax_parts"(ptr %0, i64 %1)
  %cmp30 = icmp ne ptr %13, null
  br i1 %cmp30, label %then31, label %else32

postret28:                                        ; No predecessors!
  call void @avra_rc_release(ptr %12)
  br label %endif27

then31:                                           ; preds = %endif27
  %14 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %14, i64 6)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else32:                                           ; preds = %endif27
  br label %endif33

endif33:                                          ; preds = %else32, %postret34
  %regval35 = phi i64 [ 0, %postret34 ], [ 0, %else32 ]
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

postret34:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  br label %endif33
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Esyntax_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 22, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr %boxed)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ediverges"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm2 [
    i64 10, label %arm
    i64 11, label %arm1
  ]

arm:                                              ; preds = %entry
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi i1 [ true, %arm ], [ true, %arm1 ], [ false, %arm2 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_variants"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eenum_parts"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %3, %then ], [ null, %else ]
  %cmp1 = icmp ne ptr %regval, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %regval)
  br label %endif4

else3:                                            ; preds = %endif
  %4 = call ptr @avra_array_sized(i64 0)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %regval, %then2 ], [ %4, %else3 ]
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval5
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_fields"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_parts"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %3, %then ], [ null, %else ]
  %cmp1 = icmp ne ptr %regval, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %regval)
  br label %endif4

else3:                                            ; preds = %endif
  %4 = call ptr @avra_array_sized(i64 0)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %regval, %then2 ], [ %4, %else3 ]
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval5
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_params"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Efn_parts"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %3, %then ], [ null, %else ]
  %cmp1 = icmp ne ptr %regval, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %regval)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eextern_parts"(ptr %0, i64 %1)
  %cmp5 = icmp ne ptr %4, null
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval10 = phi ptr [ %regval, %then2 ], [ %regval9, %endif8 ]
  %cmp11 = icmp ne ptr %regval10, null
  br i1 %cmp11, label %then12, label %else13

then6:                                            ; preds = %else3
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  br label %endif8

else7:                                            ; preds = %else3
  call void @avra_rc_retain(ptr null)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %5, %then6 ], [ null, %else7 ]
  call void @avra_rc_release(ptr %4)
  br label %endif4

then12:                                           ; preds = %endif4
  call void @avra_rc_retain(ptr %regval10)
  br label %endif14

else13:                                           ; preds = %endif4
  %6 = call ptr @avra_array_sized(i64 0)
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi ptr [ %regval10, %then12 ], [ %6, %else13 ]
  call void @avra_rc_release(ptr %regval10)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval15
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emarks_written"(ptr %0, i64 %1) {
entry:
  %slot11 = alloca i64, align 8
  %slot4 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_variants"(ptr %0, i64 %1)
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_fields"(ptr %0, i64 %1)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24486"(ptr %3)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_array_push_owned(ptr %3, ptr %boxed2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead5:                                           ; preds = %lexit13, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %8
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  call void @avra_rc_retain(ptr %7)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24486"(ptr %7)
  %12 = call ptr @avra_array_concat(ptr %6, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %13 = call ptr @avra_array_get_owned(ptr %2, i64 %ld10)
  %14 = call ptr @avra_array_get_owned(ptr %13, i64 3)
  %15 = call ptr @avra_array_sized(i64 0)
  %16 = call ptr @avra_array_get_owned(ptr %13, i64 1)
  %17 = call i64 @avra_array_len(ptr %16)
  store i64 0, ptr %slot11, align 8
  br label %lhead12

lhead12:                                          ; preds = %lbody16, %lbody9
  %ld14 = load i64, ptr %slot11, align 8
  %cmp15 = icmp slt i64 %ld14, %17
  br i1 %cmp15, label %lbody16, label %lexit13

lexit13:                                          ; preds = %lhead12
  call void @avra_rc_retain(ptr %15)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24486"(ptr %15)
  %19 = call ptr @avra_array_concat(ptr %14, ptr %18)
  call void @avra_array_push_owned(ptr %7, ptr %19)
  %ld22 = load i64, ptr %slot4, align 8
  %add23 = add i64 %ld22, 1
  store i64 %add23, ptr %slot4, align 8
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  br label %lhead5

lbody16:                                          ; preds = %lhead12
  %ld17 = load i64, ptr %slot11, align 8
  %20 = call i64 @avra_array_get(ptr %16, i64 %ld17)
  %boxed18 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %boxed18, i64 5)
  %boxed19 = inttoptr i64 %21 to ptr
  call void @avra_array_push_owned(ptr %15, ptr %boxed19)
  %ld20 = load i64, ptr %slot11, align 8
  %add21 = add i64 %ld20, 1
  store i64 %add21, ptr %slot11, align 8
  br label %lhead12
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24486"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm6 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 15, label %arm3
    i64 17, label %arm4
    i64 14, label %arm5
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm3:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm4:                                             ; preds = %entry
  %8 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endswitch

arm5:                                             ; preds = %entry
  %9 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  br label %endswitch

arm6:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ], [ %6, %arm2 ], [ %7, %arm3 ], [ %8, %arm4 ], [ %9, %arm5 ], [ null, %arm6 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_name"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Efn_parts"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 0)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %3, %then ], [ null, %else ]
  %cmp1 = icmp ne ptr %regval, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %regval)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eextern_parts"(ptr %0, i64 %1)
  %cmp5 = icmp ne ptr %4, null
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval10 = phi ptr [ %regval, %then2 ], [ %regval9, %endif8 ]
  %cmp11 = icmp ne ptr %regval10, null
  br i1 %cmp11, label %then12, label %else13

then6:                                            ; preds = %else3
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 0)
  br label %endif8

else7:                                            ; preds = %else3
  call void @avra_rc_retain(ptr null)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %5, %then6 ], [ null, %else7 ]
  call void @avra_rc_release(ptr %4)
  br label %endif4

then12:                                           ; preds = %endif4
  call void @avra_rc_retain(ptr %regval10)
  br label %endif14

else13:                                           ; preds = %endif4
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etype_decl_name"(ptr %0, i64 %1)
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi ptr [ %regval10, %then12 ], [ %6, %else13 ]
  %cmp16 = icmp ne ptr %regval15, null
  br i1 %cmp16, label %then17, label %else18

then17:                                           ; preds = %endif14
  call void @avra_rc_retain(ptr %regval15)
  br label %endif19

else18:                                           ; preds = %endif14
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etrait_parts"(ptr %0, i64 %1)
  %cmp20 = icmp ne ptr %7, null
  br i1 %cmp20, label %then21, label %else22

endif19:                                          ; preds = %endif23, %then17
  %regval25 = phi ptr [ %regval15, %then17 ], [ %regval24, %endif23 ]
  %cmp26 = icmp ne ptr %regval25, null
  br i1 %cmp26, label %then27, label %else28

then21:                                           ; preds = %else18
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 0)
  br label %endif23

else22:                                           ; preds = %else18
  call void @avra_rc_retain(ptr null)
  br label %endif23

endif23:                                          ; preds = %else22, %then21
  %regval24 = phi ptr [ %8, %then21 ], [ null, %else22 ]
  call void @avra_rc_release(ptr %7)
  br label %endif19

then27:                                           ; preds = %endif19
  call void @avra_rc_retain(ptr %regval25)
  br label %endif29

else28:                                           ; preds = %endif19
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Esyntax_parts"(ptr %0, i64 %1)
  %cmp30 = icmp ne ptr %9, null
  br i1 %cmp30, label %then31, label %else32

endif29:                                          ; preds = %endif33, %then27
  %regval35 = phi ptr [ %regval25, %then27 ], [ %regval34, %endif33 ]
  call void @avra_rc_release(ptr %regval25)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %regval10)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval35

then31:                                           ; preds = %else28
  %10 = call ptr @avra_array_get_owned(ptr %9, i64 0)
  br label %endif33

else32:                                           ; preds = %else28
  call void @avra_rc_retain(ptr null)
  br label %endif33

endif33:                                          ; preds = %else32, %then31
  %regval34 = phi ptr [ %10, %then31 ], [ null, %else32 ]
  call void @avra_rc_release(ptr %9)
  br label %endif29
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edecl_tbounds"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 6, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm3 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ], [ %6, %arm2 ], [ null, %arm3 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_lit_name"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 18, label %arm
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

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emethod_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 32, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call i64 @avra_array_get(ptr %2, i64 3)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %7, i64 %4)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  call void @avra_rc_release(ptr %5)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %7, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eapplied_parts"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 25, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %boxed)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 3, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Einert"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp1 = icmp eq i64 %4, 2
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %5 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp5 = icmp eq i64 %5, 3
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %6 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp10 = icmp eq i64 %6, 21
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %7 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp15 = icmp eq i64 %7, 4
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  %8 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp20 = icmp eq i64 %8, 5
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi i1 [ true, %then17 ], [ %cmp20, %else18 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif19
  br label %endif24

else23:                                           ; preds = %endif19
  %9 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp25 = icmp eq i64 %9, 24
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br i1 %regval26, label %then27, label %else28

then27:                                           ; preds = %endif24
  br label %endif29

else28:                                           ; preds = %endif24
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval30 = phi i1 [ true, %then27 ], [ false, %else28 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval30
}

define i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eleaves"(ptr %0, i64 %1) {
entry:
  %slot11 = alloca ptr, align 8
  store ptr null, ptr %slot11, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 16, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %5 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif10
  %regval20 = phi i1 [ %regval19, %endif10 ], [ false, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval20

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %6 = call i64 @avra_array_len(ptr %4)
  %cmp2 = icmp slt i64 0, %6
  br i1 %cmp2, label %then3, label %else4

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %endif5
  %regval7 = phi i1 [ %cmp6, %endif5 ], [ false, %else ]
  br i1 %regval7, label %then8, label %else9

then3:                                            ; preds = %then
  %sub = sub i64 %6, 1
  %7 = call i64 @avra_array_get(ptr %4, i64 %sub)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot)
  store ptr %8, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %endif5

else4:                                            ; preds = %then
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval = phi i64 [ 0, %then3 ], [ 0, %else4 ]
  %ld = load ptr, ptr %slot, align 8
  %cmp6 = icmp ne ptr %ld, null
  call void @avra_cell_release(ptr %slot)
  br label %endif

then8:                                            ; preds = %endif
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot11)
  store ptr null, ptr %slot11, align 8
  %9 = call i64 @avra_array_len(ptr %4)
  %cmp12 = icmp slt i64 0, %9
  br i1 %cmp12, label %then13, label %else14

else9:                                            ; preds = %endif
  br label %endif10

endif10:                                          ; preds = %else9, %endif15
  %regval19 = phi i1 [ %14, %endif15 ], [ false, %else9 ]
  call void @avra_rc_release(ptr %4)
  br label %endswitch

then13:                                           ; preds = %then8
  %sub16 = sub i64 %9, 1
  %10 = call i64 @avra_array_get(ptr %4, i64 %sub16)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 %10)
  call void @avra_rc_retain(ptr %11)
  call void @avra_cell_release(ptr %slot11)
  store ptr %11, ptr %slot11, align 8
  call void @avra_rc_release(ptr %11)
  br label %endif15

else14:                                           ; preds = %then8
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval17 = phi i64 [ 0, %then13 ], [ 0, %else14 ]
  %ld18 = load ptr, ptr %slot11, align 8
  %12 = call ptr @avra_insist(ptr %ld18)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  call void @avra_rc_retain(ptr %0)
  %14 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ediverges"(ptr %0, i64 %13)
  call void @avra_cell_release(ptr %slot11)
  call void @avra_rc_release(ptr %12)
  br label %endif10
}
