; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"!\00" }, align 16

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

define i1 @"av_$40std$2Eavrac$2Ecore$2Ecloses_region$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ecloses_region"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2

entry1:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ecloses_region"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3

entry2:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ecloses_region"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eopens_region$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eopens_region"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2

entry1:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eopens_region"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3

entry2:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eopens_region"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Ecloses_region"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 17
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eopens_region"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 14
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %2, 15
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Einert"() {
entry:
  ret i1 false
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Eboxes"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Ereach"() {
entry:
  %0 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %0, i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Eanswer"() {
entry:
  %0 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %0, i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Ecells"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Ekeeps"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define i1 @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Elends"() {
entry:
  ret i1 false
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ehosted_symbol"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ehosted_symbol_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ehosted_symbol_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  br label %endswitch

arm3:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %9, 0
  br label %endswitch

arm4:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %0, i64 1)
  %11 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 3)
  %13 = call i64 @avra_array_get(ptr %0, i64 4)
  br label %endswitch

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endswitch

arm6:                                             ; preds = %entry
  %17 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %18 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed33 = inttoptr i64 %18 to ptr
  br label %endswitch

arm7:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed34 = inttoptr i64 %21 to ptr
  br label %endswitch

arm8:                                             ; preds = %entry
  %22 = call i64 @avra_array_get(ptr %0, i64 1)
  %23 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %23 to ptr
  br label %endswitch

arm9:                                             ; preds = %entry
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %25 = call i64 @avra_array_get(ptr %0, i64 2)
  %26 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endswitch

arm10:                                            ; preds = %entry
  %27 = call i64 @avra_array_get(ptr %0, i64 1)
  %28 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed36 = inttoptr i64 %28 to ptr
  br label %endswitch

arm11:                                            ; preds = %entry
  %29 = call i64 @avra_array_get(ptr %0, i64 1)
  %30 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %30 to ptr
  br label %endswitch

arm12:                                            ; preds = %entry
  %31 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed38 = inttoptr i64 %31 to ptr
  br label %endswitch

arm13:                                            ; preds = %entry
  %32 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed39 = inttoptr i64 %32 to ptr
  br label %endswitch

arm14:                                            ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm15:                                            ; preds = %entry
  %34 = call i64 @avra_array_get(ptr %0, i64 1)
  %35 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed40 = inttoptr i64 %35 to ptr
  br label %endswitch

arm16:                                            ; preds = %entry
  %36 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm17:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  %38 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm18:                                            ; preds = %entry
  %39 = call i64 @avra_array_get(ptr %0, i64 1)
  %40 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed41 = inttoptr i64 %40 to ptr
  %41 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed42 = inttoptr i64 %41 to ptr
  br label %endswitch

arm19:                                            ; preds = %entry
  %42 = call i64 @avra_array_get(ptr %0, i64 1)
  %43 = call i64 @avra_array_get(ptr %0, i64 2)
  %44 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed43 = inttoptr i64 %44 to ptr
  br label %endswitch

arm20:                                            ; preds = %entry
  %45 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm21:                                            ; preds = %entry
  %46 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm22:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm23:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm24:                                            ; preds = %entry
  %50 = call i64 @avra_array_get(ptr %0, i64 1)
  %51 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm25:                                            ; preds = %entry
  br label %endswitch

arm26:                                            ; preds = %entry
  %52 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm27:                                            ; preds = %entry
  br label %endswitch

arm28:                                            ; preds = %entry
  %53 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm29:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm30:                                            ; preds = %entry
  %55 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm1 ], [ null, %arm2 ], [ null, %arm3 ], [ null, %arm4 ], [ null, %arm5 ], [ %17, %arm6 ], [ %20, %arm7 ], [ null, %arm8 ], [ null, %arm9 ], [ null, %arm10 ], [ null, %arm11 ], [ null, %arm12 ], [ null, %arm13 ], [ null, %arm14 ], [ null, %arm15 ], [ null, %arm16 ], [ null, %arm17 ], [ null, %arm18 ], [ null, %arm19 ], [ null, %arm20 ], [ null, %arm21 ], [ null, %arm22 ], [ null, %arm23 ], [ null, %arm24 ], [ null, %arm25 ], [ null, %arm26 ], [ null, %arm27 ], [ null, %arm28 ], [ null, %arm29 ], [ null, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %0, i64 %1) {
entry:
  %cmp = icmp eq i64 %0, %1
  ret i1 %cmp
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ereads_of"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereads_of_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ereads_of_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %7 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %12, 0
  %13 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm4:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  %17 = call i64 @avra_array_get(ptr %0, i64 4)
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 %16)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 %17)
  %20 = call ptr @avra_array_concat(ptr %18, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  br label %endswitch

arm5:                                             ; preds = %entry
  %21 = call i64 @avra_array_get(ptr %0, i64 1)
  %22 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_array_get(ptr %0, i64 3)
  %24 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %24, i64 %23)
  br label %endswitch

arm6:                                             ; preds = %entry
  %25 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %25 to ptr
  %26 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  br label %endswitch

arm7:                                             ; preds = %entry
  %27 = call i64 @avra_array_get(ptr %0, i64 1)
  %28 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %28 to ptr
  %29 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

arm8:                                             ; preds = %entry
  %30 = call i64 @avra_array_get(ptr %0, i64 1)
  %31 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  br label %endswitch

arm9:                                             ; preds = %entry
  %32 = call i64 @avra_array_get(ptr %0, i64 1)
  %33 = call i64 @avra_array_get(ptr %0, i64 2)
  %34 = call i64 @avra_array_get(ptr %0, i64 3)
  %35 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %35, i64 %33)
  br label %endswitch

arm10:                                            ; preds = %entry
  %36 = call i64 @avra_array_get(ptr %0, i64 1)
  %37 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %37 to ptr
  %38 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm11:                                            ; preds = %entry
  %39 = call i64 @avra_array_get(ptr %0, i64 1)
  %40 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed36 = inttoptr i64 %40 to ptr
  %41 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm12:                                            ; preds = %entry
  %42 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed37 = inttoptr i64 %42 to ptr
  %43 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm13:                                            ; preds = %entry
  %44 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed38 = inttoptr i64 %44 to ptr
  call void @avra_rc_retain(ptr %boxed38)
  %45 = call ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2477"(ptr %boxed38)
  br label %endswitch

arm14:                                            ; preds = %entry
  %46 = call i64 @avra_array_get(ptr %0, i64 1)
  %47 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %47, i64 %46)
  br label %endswitch

arm15:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %49 to ptr
  %50 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %50, i64 %48)
  br label %endswitch

arm16:                                            ; preds = %entry
  %51 = call i64 @avra_array_get(ptr %0, i64 1)
  %52 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %52, i64 %51)
  br label %endswitch

arm17:                                            ; preds = %entry
  %53 = call i64 @avra_array_get(ptr %0, i64 1)
  %54 = call i64 @avra_array_get(ptr %0, i64 2)
  %55 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %55, i64 %54)
  br label %endswitch

arm18:                                            ; preds = %entry
  %56 = call i64 @avra_array_get(ptr %0, i64 1)
  %57 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed40 = inttoptr i64 %57 to ptr
  %58 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

arm19:                                            ; preds = %entry
  %59 = call i64 @avra_array_get(ptr %0, i64 1)
  %60 = call i64 @avra_array_get(ptr %0, i64 2)
  %61 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed41 = inttoptr i64 %61 to ptr
  %62 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %62, i64 %60)
  %63 = call ptr @avra_array_concat(ptr %62, ptr %boxed41)
  call void @avra_rc_release(ptr %62)
  br label %endswitch

arm20:                                            ; preds = %entry
  %64 = call i64 @avra_array_get(ptr %0, i64 1)
  %65 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %65, i64 %64)
  br label %endswitch

arm21:                                            ; preds = %entry
  %66 = call i64 @avra_array_get(ptr %0, i64 1)
  %67 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %67, i64 %66)
  br label %endswitch

arm22:                                            ; preds = %entry
  %68 = call i64 @avra_array_get(ptr %0, i64 1)
  %69 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm23:                                            ; preds = %entry
  %70 = call i64 @avra_array_get(ptr %0, i64 1)
  %71 = call i64 @avra_array_get(ptr %0, i64 2)
  %72 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %72, i64 %71)
  br label %endswitch

arm24:                                            ; preds = %entry
  %73 = call i64 @avra_array_get(ptr %0, i64 1)
  %74 = call i64 @avra_array_get(ptr %0, i64 2)
  %75 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %75, i64 %73)
  %76 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %76, i64 %74)
  %77 = call ptr @avra_array_concat(ptr %75, ptr %76)
  call void @avra_rc_release(ptr %76)
  call void @avra_rc_release(ptr %75)
  br label %endswitch

arm25:                                            ; preds = %entry
  %78 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm26:                                            ; preds = %entry
  %79 = call i64 @avra_array_get(ptr %0, i64 1)
  %80 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %80, i64 %79)
  br label %endswitch

arm27:                                            ; preds = %entry
  %81 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm28:                                            ; preds = %entry
  %82 = call i64 @avra_array_get(ptr %0, i64 1)
  %83 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %83, i64 %82)
  br label %endswitch

arm29:                                            ; preds = %entry
  %84 = call i64 @avra_array_get(ptr %0, i64 1)
  %85 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %85, i64 %84)
  br label %endswitch

arm30:                                            ; preds = %entry
  %86 = call i64 @avra_array_get(ptr %0, i64 1)
  %87 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ %13, %arm3 ], [ %20, %arm4 ], [ %24, %arm5 ], [ %26, %arm6 ], [ %29, %arm7 ], [ %31, %arm8 ], [ %35, %arm9 ], [ %38, %arm10 ], [ %41, %arm11 ], [ %43, %arm12 ], [ %45, %arm13 ], [ %47, %arm14 ], [ %50, %arm15 ], [ %52, %arm16 ], [ %55, %arm17 ], [ %58, %arm18 ], [ %63, %arm19 ], [ %65, %arm20 ], [ %67, %arm21 ], [ %69, %arm22 ], [ %72, %arm23 ], [ %77, %arm24 ], [ %78, %arm25 ], [ %80, %arm26 ], [ %81, %arm27 ], [ %83, %arm28 ], [ %85, %arm29 ], [ %87, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2477"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2Eviewed_dst"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eviewed_dst_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eviewed_dst_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm3:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %9, 0
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm4:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %0, i64 1)
  %11 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 3)
  %13 = call i64 @avra_array_get(ptr %0, i64 4)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm6:                                             ; preds = %entry
  %17 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm7:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm8:                                             ; preds = %entry
  %22 = call i64 @avra_array_get(ptr %0, i64 1)
  %23 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm9:                                             ; preds = %entry
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %25 = call i64 @avra_array_get(ptr %0, i64 2)
  %26 = call i64 @avra_array_get(ptr %0, i64 3)
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 %24)
  br label %endswitch

arm10:                                            ; preds = %entry
  %28 = call i64 @avra_array_get(ptr %0, i64 1)
  %29 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %29 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm11:                                            ; preds = %entry
  %30 = call i64 @avra_array_get(ptr %0, i64 1)
  %31 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %31 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm12:                                            ; preds = %entry
  %32 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %32 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm13:                                            ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed41 = inttoptr i64 %33 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm14:                                            ; preds = %entry
  %34 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm15:                                            ; preds = %entry
  %35 = call i64 @avra_array_get(ptr %0, i64 1)
  %36 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed42 = inttoptr i64 %36 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm16:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm17:                                            ; preds = %entry
  %38 = call i64 @avra_array_get(ptr %0, i64 1)
  %39 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm18:                                            ; preds = %entry
  %40 = call i64 @avra_array_get(ptr %0, i64 1)
  %41 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed43 = inttoptr i64 %41 to ptr
  %42 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed44 = inttoptr i64 %42 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm19:                                            ; preds = %entry
  %43 = call i64 @avra_array_get(ptr %0, i64 1)
  %44 = call i64 @avra_array_get(ptr %0, i64 2)
  %45 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed45 = inttoptr i64 %45 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm20:                                            ; preds = %entry
  %46 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm21:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm22:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm23:                                            ; preds = %entry
  %49 = call i64 @avra_array_get(ptr %0, i64 1)
  %50 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm24:                                            ; preds = %entry
  %51 = call i64 @avra_array_get(ptr %0, i64 1)
  %52 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm25:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm26:                                            ; preds = %entry
  %53 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm27:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm28:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm29:                                            ; preds = %entry
  %55 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm30:                                            ; preds = %entry
  %56 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm1 ], [ null, %arm2 ], [ null, %arm3 ], [ null, %arm4 ], [ null, %arm5 ], [ null, %arm6 ], [ null, %arm7 ], [ null, %arm8 ], [ %27, %arm9 ], [ null, %arm10 ], [ null, %arm11 ], [ null, %arm12 ], [ null, %arm13 ], [ null, %arm14 ], [ null, %arm15 ], [ null, %arm16 ], [ null, %arm17 ], [ null, %arm18 ], [ null, %arm19 ], [ null, %arm20 ], [ null, %arm21 ], [ null, %arm22 ], [ null, %arm23 ], [ null, %arm24 ], [ null, %arm25 ], [ null, %arm26 ], [ null, %arm27 ], [ null, %arm28 ], [ null, %arm29 ], [ null, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %7 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %12, 0
  %13 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm4:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  %17 = call i64 @avra_array_get(ptr %0, i64 4)
  %18 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm5:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %22 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm6:                                             ; preds = %entry
  %23 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %24 to ptr
  %25 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm7:                                             ; preds = %entry
  %26 = call i64 @avra_array_get(ptr %0, i64 1)
  %27 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %27 to ptr
  %28 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %28 to ptr
  %29 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm8:                                             ; preds = %entry
  %30 = call i64 @avra_array_get(ptr %0, i64 1)
  %31 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %31 to ptr
  %32 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm9:                                             ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  %34 = call i64 @avra_array_get(ptr %0, i64 2)
  %35 = call i64 @avra_array_get(ptr %0, i64 3)
  %36 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm10:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  %38 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %38 to ptr
  %39 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm11:                                            ; preds = %entry
  %40 = call i64 @avra_array_get(ptr %0, i64 1)
  %41 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %41 to ptr
  %42 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm12:                                            ; preds = %entry
  %43 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %43 to ptr
  %44 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm13:                                            ; preds = %entry
  %45 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed41 = inttoptr i64 %45 to ptr
  %46 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm14:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  %48 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm15:                                            ; preds = %entry
  %49 = call i64 @avra_array_get(ptr %0, i64 1)
  %50 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed42 = inttoptr i64 %50 to ptr
  %51 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm16:                                            ; preds = %entry
  %52 = call i64 @avra_array_get(ptr %0, i64 1)
  %53 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm17:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  %55 = call i64 @avra_array_get(ptr %0, i64 2)
  %56 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm18:                                            ; preds = %entry
  %57 = call i64 @avra_array_get(ptr %0, i64 1)
  %58 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed43 = inttoptr i64 %58 to ptr
  %59 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

arm19:                                            ; preds = %entry
  %60 = call i64 @avra_array_get(ptr %0, i64 1)
  %61 = call i64 @avra_array_get(ptr %0, i64 2)
  %62 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

arm20:                                            ; preds = %entry
  %63 = call i64 @avra_array_get(ptr %0, i64 1)
  %64 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm21:                                            ; preds = %entry
  %65 = call i64 @avra_array_get(ptr %0, i64 1)
  %66 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm22:                                            ; preds = %entry
  %67 = call i64 @avra_array_get(ptr %0, i64 1)
  %68 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm23:                                            ; preds = %entry
  %69 = call i64 @avra_array_get(ptr %0, i64 1)
  %70 = call i64 @avra_array_get(ptr %0, i64 2)
  %71 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm24:                                            ; preds = %entry
  %72 = call i64 @avra_array_get(ptr %0, i64 1)
  %73 = call i64 @avra_array_get(ptr %0, i64 2)
  %74 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm25:                                            ; preds = %entry
  %75 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm26:                                            ; preds = %entry
  %76 = call i64 @avra_array_get(ptr %0, i64 1)
  %77 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm27:                                            ; preds = %entry
  %78 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm28:                                            ; preds = %entry
  %79 = call i64 @avra_array_get(ptr %0, i64 1)
  %80 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm29:                                            ; preds = %entry
  %81 = call i64 @avra_array_get(ptr %0, i64 1)
  %82 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm30:                                            ; preds = %entry
  %83 = call i64 @avra_array_get(ptr %0, i64 1)
  %84 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ %13, %arm3 ], [ %18, %arm4 ], [ %22, %arm5 ], [ %25, %arm6 ], [ %29, %arm7 ], [ %32, %arm8 ], [ %36, %arm9 ], [ %39, %arm10 ], [ %42, %arm11 ], [ %44, %arm12 ], [ %46, %arm13 ], [ %48, %arm14 ], [ %51, %arm15 ], [ %53, %arm16 ], [ %56, %arm17 ], [ %59, %arm18 ], [ %62, %arm19 ], [ %64, %arm20 ], [ %66, %arm21 ], [ %68, %arm22 ], [ %71, %arm23 ], [ %74, %arm24 ], [ %75, %arm25 ], [ %77, %arm26 ], [ %78, %arm27 ], [ %80, %arm28 ], [ %82, %arm29 ], [ %84, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eowned_dst"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eowned_dst_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eowned_dst_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %6)
  br label %endswitch

arm3:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %0, i64 1)
  %10 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %10, 0
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm4:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %0, i64 3)
  %14 = call i64 @avra_array_get(ptr %0, i64 4)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm5:                                             ; preds = %entry
  %15 = call i64 @avra_array_get(ptr %0, i64 1)
  %16 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %0, i64 3)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm6:                                             ; preds = %entry
  %18 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm7:                                             ; preds = %entry
  %20 = call i64 @avra_array_get(ptr %0, i64 1)
  %21 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %22 to ptr
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %23, i64 %20)
  br label %endswitch

arm8:                                             ; preds = %entry
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %25 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %25 to ptr
  %26 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %26, i64 %24)
  br label %endswitch

arm9:                                             ; preds = %entry
  %27 = call i64 @avra_array_get(ptr %0, i64 1)
  %28 = call i64 @avra_array_get(ptr %0, i64 2)
  %29 = call i64 @avra_array_get(ptr %0, i64 3)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm10:                                            ; preds = %entry
  %30 = call i64 @avra_array_get(ptr %0, i64 1)
  %31 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %31 to ptr
  %32 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %32, i64 %30)
  br label %endswitch

arm11:                                            ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  %34 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %34 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm12:                                            ; preds = %entry
  %35 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %35 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm13:                                            ; preds = %entry
  %36 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed41 = inttoptr i64 %36 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm14:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm15:                                            ; preds = %entry
  %38 = call i64 @avra_array_get(ptr %0, i64 1)
  %39 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed42 = inttoptr i64 %39 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm16:                                            ; preds = %entry
  %40 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm17:                                            ; preds = %entry
  %41 = call i64 @avra_array_get(ptr %0, i64 1)
  %42 = call i64 @avra_array_get(ptr %0, i64 2)
  %43 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %43, i64 %41)
  br label %endswitch

arm18:                                            ; preds = %entry
  %44 = call i64 @avra_array_get(ptr %0, i64 1)
  %45 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed43 = inttoptr i64 %45 to ptr
  %46 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed44 = inttoptr i64 %46 to ptr
  %47 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %47, i64 %44)
  br label %endswitch

arm19:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  %50 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed45 = inttoptr i64 %50 to ptr
  %51 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %51, i64 %48)
  br label %endswitch

arm20:                                            ; preds = %entry
  %52 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm21:                                            ; preds = %entry
  %53 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm22:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm23:                                            ; preds = %entry
  %55 = call i64 @avra_array_get(ptr %0, i64 1)
  %56 = call i64 @avra_array_get(ptr %0, i64 2)
  %57 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %57, i64 %55)
  br label %endswitch

arm24:                                            ; preds = %entry
  %58 = call i64 @avra_array_get(ptr %0, i64 1)
  %59 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm25:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm26:                                            ; preds = %entry
  %60 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm27:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm28:                                            ; preds = %entry
  %61 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm29:                                            ; preds = %entry
  %62 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm30:                                            ; preds = %entry
  %63 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm1 ], [ %8, %arm2 ], [ null, %arm3 ], [ null, %arm4 ], [ null, %arm5 ], [ null, %arm6 ], [ %23, %arm7 ], [ %26, %arm8 ], [ null, %arm9 ], [ %32, %arm10 ], [ null, %arm11 ], [ null, %arm12 ], [ null, %arm13 ], [ null, %arm14 ], [ null, %arm15 ], [ null, %arm16 ], [ %43, %arm17 ], [ %47, %arm18 ], [ %51, %arm19 ], [ null, %arm20 ], [ null, %arm21 ], [ null, %arm22 ], [ %57, %arm23 ], [ null, %arm24 ], [ null, %arm25 ], [ null, %arm26 ], [ null, %arm27 ], [ null, %arm28 ], [ null, %arm29 ], [ null, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Edst_of"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edst_of_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Edst_of_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %5)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 %8)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %12, 0
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 %11)
  br label %endswitch

arm4:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  %17 = call i64 @avra_array_get(ptr %0, i64 4)
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 %14)
  br label %endswitch

arm5:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 %19)
  br label %endswitch

arm6:                                             ; preds = %entry
  %23 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm7:                                             ; preds = %entry
  %25 = call i64 @avra_array_get(ptr %0, i64 1)
  %26 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %26 to ptr
  %27 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %27 to ptr
  %28 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %28, i64 %25)
  br label %endswitch

arm8:                                             ; preds = %entry
  %29 = call i64 @avra_array_get(ptr %0, i64 1)
  %30 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %30 to ptr
  %31 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %31, i64 %29)
  br label %endswitch

arm9:                                             ; preds = %entry
  %32 = call i64 @avra_array_get(ptr %0, i64 1)
  %33 = call i64 @avra_array_get(ptr %0, i64 2)
  %34 = call i64 @avra_array_get(ptr %0, i64 3)
  %35 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %35, i64 %32)
  br label %endswitch

arm10:                                            ; preds = %entry
  %36 = call i64 @avra_array_get(ptr %0, i64 1)
  %37 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %37 to ptr
  %38 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %38, i64 %36)
  br label %endswitch

arm11:                                            ; preds = %entry
  %39 = call i64 @avra_array_get(ptr %0, i64 1)
  %40 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %40 to ptr
  %41 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %41, i64 %39)
  br label %endswitch

arm12:                                            ; preds = %entry
  %42 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %42 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm13:                                            ; preds = %entry
  %43 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed41 = inttoptr i64 %43 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm14:                                            ; preds = %entry
  %44 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm15:                                            ; preds = %entry
  %45 = call i64 @avra_array_get(ptr %0, i64 1)
  %46 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed42 = inttoptr i64 %46 to ptr
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm16:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm17:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  %50 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %50, i64 %48)
  br label %endswitch

arm18:                                            ; preds = %entry
  %51 = call i64 @avra_array_get(ptr %0, i64 1)
  %52 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed43 = inttoptr i64 %52 to ptr
  %53 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed44 = inttoptr i64 %53 to ptr
  %54 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %54, i64 %51)
  br label %endswitch

arm19:                                            ; preds = %entry
  %55 = call i64 @avra_array_get(ptr %0, i64 1)
  %56 = call i64 @avra_array_get(ptr %0, i64 2)
  %57 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed45 = inttoptr i64 %57 to ptr
  %58 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %58, i64 %55)
  br label %endswitch

arm20:                                            ; preds = %entry
  %59 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm21:                                            ; preds = %entry
  %60 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm22:                                            ; preds = %entry
  %61 = call i64 @avra_array_get(ptr %0, i64 1)
  %62 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %62, i64 %61)
  br label %endswitch

arm23:                                            ; preds = %entry
  %63 = call i64 @avra_array_get(ptr %0, i64 1)
  %64 = call i64 @avra_array_get(ptr %0, i64 2)
  %65 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %65, i64 %63)
  br label %endswitch

arm24:                                            ; preds = %entry
  %66 = call i64 @avra_array_get(ptr %0, i64 1)
  %67 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm25:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm26:                                            ; preds = %entry
  %68 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm27:                                            ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm28:                                            ; preds = %entry
  %69 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm29:                                            ; preds = %entry
  %70 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

arm30:                                            ; preds = %entry
  %71 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr null)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ %13, %arm3 ], [ %18, %arm4 ], [ %22, %arm5 ], [ null, %arm6 ], [ %28, %arm7 ], [ %31, %arm8 ], [ %35, %arm9 ], [ %38, %arm10 ], [ %41, %arm11 ], [ null, %arm12 ], [ null, %arm13 ], [ null, %arm14 ], [ null, %arm15 ], [ null, %arm16 ], [ %50, %arm17 ], [ %54, %arm18 ], [ %58, %arm19 ], [ null, %arm20 ], [ null, %arm21 ], [ %62, %arm22 ], [ %65, %arm23 ], [ null, %arm24 ], [ null, %arm25 ], [ null, %arm26 ], [ null, %arm27 ], [ null, %arm28 ], [ null, %arm29 ], [ null, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERtSig$2Ebox_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 10)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp slt i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 10)
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 %1)
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 0)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Estatic_symbol"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm1 [
    i64 11, label %arm
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ebody_symbol"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ebody_symbol_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ebody_symbol_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  br label %endswitch

arm3:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %9, 0
  br label %endswitch

arm4:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %0, i64 1)
  %11 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 3)
  %13 = call i64 @avra_array_get(ptr %0, i64 4)
  br label %endswitch

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endswitch

arm6:                                             ; preds = %entry
  %17 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %18 to ptr
  br label %endswitch

arm7:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %21 to ptr
  br label %endswitch

arm8:                                             ; preds = %entry
  %22 = call i64 @avra_array_get(ptr %0, i64 1)
  %23 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %23 to ptr
  br label %endswitch

arm9:                                             ; preds = %entry
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %25 = call i64 @avra_array_get(ptr %0, i64 2)
  %26 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endswitch

arm10:                                            ; preds = %entry
  %27 = call i64 @avra_array_get(ptr %0, i64 1)
  %28 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  br label %endswitch

arm11:                                            ; preds = %entry
  %29 = call i64 @avra_array_get(ptr %0, i64 1)
  %30 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %30 to ptr
  br label %endswitch

arm12:                                            ; preds = %entry
  %31 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed39 = inttoptr i64 %31 to ptr
  br label %endswitch

arm13:                                            ; preds = %entry
  %32 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %32 to ptr
  br label %endswitch

arm14:                                            ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm15:                                            ; preds = %entry
  %34 = call i64 @avra_array_get(ptr %0, i64 1)
  %35 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed41 = inttoptr i64 %35 to ptr
  br label %endswitch

arm16:                                            ; preds = %entry
  %36 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm17:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  %38 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm18:                                            ; preds = %entry
  %39 = call i64 @avra_array_get(ptr %0, i64 1)
  %40 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %41 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed42 = inttoptr i64 %41 to ptr
  br label %endswitch

arm19:                                            ; preds = %entry
  %42 = call i64 @avra_array_get(ptr %0, i64 1)
  %43 = call i64 @avra_array_get(ptr %0, i64 2)
  %44 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed43 = inttoptr i64 %44 to ptr
  br label %endswitch

arm20:                                            ; preds = %entry
  %45 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm21:                                            ; preds = %entry
  %46 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm22:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm23:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm24:                                            ; preds = %entry
  %50 = call i64 @avra_array_get(ptr %0, i64 1)
  %51 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm25:                                            ; preds = %entry
  br label %endswitch

arm26:                                            ; preds = %entry
  %52 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm27:                                            ; preds = %entry
  br label %endswitch

arm28:                                            ; preds = %entry
  %53 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm29:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm30:                                            ; preds = %entry
  %55 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm1 ], [ null, %arm2 ], [ null, %arm3 ], [ null, %arm4 ], [ null, %arm5 ], [ null, %arm6 ], [ null, %arm7 ], [ null, %arm8 ], [ null, %arm9 ], [ %28, %arm10 ], [ null, %arm11 ], [ null, %arm12 ], [ null, %arm13 ], [ null, %arm14 ], [ null, %arm15 ], [ null, %arm16 ], [ null, %arm17 ], [ %40, %arm18 ], [ null, %arm19 ], [ null, %arm20 ], [ null, %arm21 ], [ null, %arm22 ], [ null, %arm23 ], [ null, %arm24 ], [ null, %arm25 ], [ null, %arm26 ], [ null, %arm27 ], [ null, %arm28 ], [ null, %arm29 ], [ null, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eseat_regs"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eseat_regs_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eseat_regs_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %7 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %12, 0
  %13 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm4:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  %17 = call i64 @avra_array_get(ptr %0, i64 4)
  %18 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm5:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %22 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm6:                                             ; preds = %entry
  %23 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %24 to ptr
  %25 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm7:                                             ; preds = %entry
  %26 = call i64 @avra_array_get(ptr %0, i64 1)
  %27 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %27 to ptr
  %28 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %28 to ptr
  %29 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm8:                                             ; preds = %entry
  %30 = call i64 @avra_array_get(ptr %0, i64 1)
  %31 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %31 to ptr
  %32 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm9:                                             ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  %34 = call i64 @avra_array_get(ptr %0, i64 2)
  %35 = call i64 @avra_array_get(ptr %0, i64 3)
  %36 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm10:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  %38 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %38 to ptr
  %39 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm11:                                            ; preds = %entry
  %40 = call i64 @avra_array_get(ptr %0, i64 1)
  %41 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %41 to ptr
  %42 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm12:                                            ; preds = %entry
  %43 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %43 to ptr
  %44 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm13:                                            ; preds = %entry
  %45 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed41 = inttoptr i64 %45 to ptr
  %46 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm14:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  %48 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm15:                                            ; preds = %entry
  %49 = call i64 @avra_array_get(ptr %0, i64 1)
  %50 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed42 = inttoptr i64 %50 to ptr
  %51 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm16:                                            ; preds = %entry
  %52 = call i64 @avra_array_get(ptr %0, i64 1)
  %53 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm17:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  %55 = call i64 @avra_array_get(ptr %0, i64 2)
  %56 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm18:                                            ; preds = %entry
  %57 = call i64 @avra_array_get(ptr %0, i64 1)
  %58 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed43 = inttoptr i64 %58 to ptr
  %59 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

arm19:                                            ; preds = %entry
  %60 = call i64 @avra_array_get(ptr %0, i64 1)
  %61 = call i64 @avra_array_get(ptr %0, i64 2)
  %62 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

arm20:                                            ; preds = %entry
  %63 = call i64 @avra_array_get(ptr %0, i64 1)
  %64 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm21:                                            ; preds = %entry
  %65 = call i64 @avra_array_get(ptr %0, i64 1)
  %66 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm22:                                            ; preds = %entry
  %67 = call i64 @avra_array_get(ptr %0, i64 1)
  %68 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm23:                                            ; preds = %entry
  %69 = call i64 @avra_array_get(ptr %0, i64 1)
  %70 = call i64 @avra_array_get(ptr %0, i64 2)
  %71 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm24:                                            ; preds = %entry
  %72 = call i64 @avra_array_get(ptr %0, i64 1)
  %73 = call i64 @avra_array_get(ptr %0, i64 2)
  %74 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm25:                                            ; preds = %entry
  %75 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm26:                                            ; preds = %entry
  %76 = call i64 @avra_array_get(ptr %0, i64 1)
  %77 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm27:                                            ; preds = %entry
  %78 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm28:                                            ; preds = %entry
  %79 = call i64 @avra_array_get(ptr %0, i64 1)
  %80 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm29:                                            ; preds = %entry
  %81 = call i64 @avra_array_get(ptr %0, i64 1)
  %82 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

arm30:                                            ; preds = %entry
  %83 = call i64 @avra_array_get(ptr %0, i64 1)
  %84 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ %13, %arm3 ], [ %18, %arm4 ], [ %22, %arm5 ], [ %25, %arm6 ], [ %29, %arm7 ], [ %32, %arm8 ], [ %36, %arm9 ], [ %39, %arm10 ], [ %42, %arm11 ], [ %44, %arm12 ], [ %46, %arm13 ], [ %48, %arm14 ], [ %51, %arm15 ], [ %53, %arm16 ], [ %56, %arm17 ], [ %59, %arm18 ], [ %62, %arm19 ], [ %64, %arm20 ], [ %66, %arm21 ], [ %68, %arm22 ], [ %71, %arm23 ], [ %74, %arm24 ], [ %75, %arm25 ], [ %77, %arm26 ], [ %78, %arm27 ], [ %80, %arm28 ], [ %82, %arm29 ], [ %84, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ecall_symbol"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ecall_symbol_role"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ecall_symbol_role"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm30 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
    i64 7, label %arm7
    i64 8, label %arm8
    i64 9, label %arm9
    i64 10, label %arm10
    i64 11, label %arm11
    i64 12, label %arm12
    i64 13, label %arm13
    i64 14, label %arm14
    i64 15, label %arm15
    i64 16, label %arm16
    i64 17, label %arm17
    i64 18, label %arm18
    i64 19, label %arm19
    i64 20, label %arm20
    i64 21, label %arm21
    i64 22, label %arm22
    i64 23, label %arm23
    i64 24, label %arm24
    i64 25, label %arm25
    i64 26, label %arm26
    i64 27, label %arm27
    i64 28, label %arm28
    i64 29, label %arm29
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  br label %endswitch

arm3:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %9, 0
  br label %endswitch

arm4:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %0, i64 1)
  %11 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed31 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 3)
  %13 = call i64 @avra_array_get(ptr %0, i64 4)
  br label %endswitch

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed32 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endswitch

arm6:                                             ; preds = %entry
  %17 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed33 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed34 = inttoptr i64 %18 to ptr
  br label %endswitch

arm7:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed35 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed36 = inttoptr i64 %21 to ptr
  br label %endswitch

arm8:                                             ; preds = %entry
  %22 = call i64 @avra_array_get(ptr %0, i64 1)
  %23 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed37 = inttoptr i64 %23 to ptr
  br label %endswitch

arm9:                                             ; preds = %entry
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %25 = call i64 @avra_array_get(ptr %0, i64 2)
  %26 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endswitch

arm10:                                            ; preds = %entry
  %27 = call i64 @avra_array_get(ptr %0, i64 1)
  %28 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed38 = inttoptr i64 %28 to ptr
  br label %endswitch

arm11:                                            ; preds = %entry
  %29 = call i64 @avra_array_get(ptr %0, i64 1)
  %30 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed39 = inttoptr i64 %30 to ptr
  br label %endswitch

arm12:                                            ; preds = %entry
  %31 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed40 = inttoptr i64 %31 to ptr
  br label %endswitch

arm13:                                            ; preds = %entry
  %32 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed41 = inttoptr i64 %32 to ptr
  br label %endswitch

arm14:                                            ; preds = %entry
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm15:                                            ; preds = %entry
  %34 = call i64 @avra_array_get(ptr %0, i64 1)
  %35 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed42 = inttoptr i64 %35 to ptr
  br label %endswitch

arm16:                                            ; preds = %entry
  %36 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm17:                                            ; preds = %entry
  %37 = call i64 @avra_array_get(ptr %0, i64 1)
  %38 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm18:                                            ; preds = %entry
  %39 = call i64 @avra_array_get(ptr %0, i64 1)
  %40 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %41 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed43 = inttoptr i64 %41 to ptr
  br label %endswitch

arm19:                                            ; preds = %entry
  %42 = call i64 @avra_array_get(ptr %0, i64 1)
  %43 = call i64 @avra_array_get(ptr %0, i64 2)
  %44 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed44 = inttoptr i64 %44 to ptr
  br label %endswitch

arm20:                                            ; preds = %entry
  %45 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm21:                                            ; preds = %entry
  %46 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm22:                                            ; preds = %entry
  %47 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm23:                                            ; preds = %entry
  %48 = call i64 @avra_array_get(ptr %0, i64 1)
  %49 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm24:                                            ; preds = %entry
  %50 = call i64 @avra_array_get(ptr %0, i64 1)
  %51 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endswitch

arm25:                                            ; preds = %entry
  br label %endswitch

arm26:                                            ; preds = %entry
  %52 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm27:                                            ; preds = %entry
  br label %endswitch

arm28:                                            ; preds = %entry
  %53 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm29:                                            ; preds = %entry
  %54 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

arm30:                                            ; preds = %entry
  %55 = call i64 @avra_array_get(ptr %0, i64 1)
  br label %endswitch

endswitch:                                        ; preds = %arm30, %arm29, %arm28, %arm27, %arm26, %arm25, %arm24, %arm23, %arm22, %arm21, %arm20, %arm19, %arm18, %arm17, %arm16, %arm15, %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ null, %arm ], [ null, %arm1 ], [ null, %arm2 ], [ null, %arm3 ], [ null, %arm4 ], [ null, %arm5 ], [ null, %arm6 ], [ null, %arm7 ], [ null, %arm8 ], [ null, %arm9 ], [ null, %arm10 ], [ null, %arm11 ], [ null, %arm12 ], [ null, %arm13 ], [ null, %arm14 ], [ null, %arm15 ], [ null, %arm16 ], [ null, %arm17 ], [ %40, %arm18 ], [ null, %arm19 ], [ null, %arm20 ], [ null, %arm21 ], [ null, %arm22 ], [ null, %arm23 ], [ null, %arm24 ], [ null, %arm25 ], [ null, %arm26 ], [ null, %arm27 ], [ null, %arm28 ], [ null, %arm29 ], [ null, %arm30 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eescapes_in"(ptr %0, i64 %1) {
entry:
  %slot41 = alloca i64, align 8
  %slot40 = alloca i1, align 1
  %slot22 = alloca i64, align 8
  %slot21 = alloca i1, align 1
  %slot12 = alloca i64, align 8
  %slot = alloca i1, align 1
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %2, label %arm11 [
    i64 8, label %arm
    i64 24, label %arm1
    i64 20, label %arm2
    i64 21, label %arm3
    i64 16, label %arm4
    i64 17, label %arm5
    i64 13, label %arm6
    i64 18, label %arm7
    i64 19, label %arm8
    i64 7, label %arm9
    i64 6, label %arm10
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  store i1 false, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Eir$24l23" to i64))
  call void @avra_array_push(ptr %4, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot12, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %8 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %7, i64 %1)
  br label %endswitch

arm2:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %0, i64 1)
  %10 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %9, i64 %1)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %12 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %11, i64 %1)
  br label %endswitch

arm4:                                             ; preds = %entry
  %13 = call i64 @avra_array_get(ptr %0, i64 1)
  %14 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %13, i64 %1)
  br label %endswitch

arm5:                                             ; preds = %entry
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %16 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %15, i64 %1)
  br label %endswitch

arm6:                                             ; preds = %entry
  %17 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %cmp16 = icmp ne ptr %17, null
  br i1 %cmp16, label %then17, label %else18

arm7:                                             ; preds = %entry
  store i1 false, ptr %slot21, align 8
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Eir$24l53" to i64))
  call void @avra_array_push(ptr %18, i64 %1)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  call void @avra_rc_retain(ptr %0)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args"(ptr %0)
  %21 = call i64 @avra_array_len(ptr %20)
  store i64 0, ptr %slot22, align 8
  br label %lhead23

arm8:                                             ; preds = %entry
  %22 = call i64 @avra_array_get(ptr %0, i64 2)
  %23 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %22, i64 %1)
  br i1 %23, label %then37, label %else38

arm9:                                             ; preds = %entry
  %24 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %25 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %24)
  call void @avra_rc_retain(ptr %boxed)
  %26 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ekept_seat"(ptr %24, ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %24)
  br label %endswitch

arm10:                                            ; preds = %entry
  %27 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %28 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed57 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %27)
  call void @avra_rc_retain(ptr %boxed57)
  %29 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ekept_seat"(ptr %27, ptr %boxed57, i64 %1)
  call void @avra_rc_release(ptr %27)
  br label %endswitch

arm11:                                            ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm11, %arm10, %arm9, %endif39, %lexit24, %endif19, %arm5, %arm4, %arm3, %arm2, %arm1, %lexit
  %regval58 = phi i1 [ %ld15, %lexit ], [ %8, %arm1 ], [ %10, %arm2 ], [ %12, %arm3 ], [ %14, %arm4 ], [ %16, %arm5 ], [ %regval20, %endif19 ], [ %ld36, %lexit24 ], [ %regval56, %endif39 ], [ %26, %arm9 ], [ %29, %arm10 ], [ false, %arm11 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval58

lhead:                                            ; preds = %endif, %arm
  %ld = load i64, ptr %slot12, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld15 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld13 = load i64, ptr %slot12, align 8
  %30 = call i64 @avra_array_get(ptr %3, i64 %ld13)
  call void @avra_rc_retain(ptr %4)
  %cast = inttoptr i64 %5 to ptr
  %31 = call i1 %cast(ptr %4, i64 %30)
  br i1 %31, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %6, ptr %slot12, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld14 = load i64, ptr %slot12, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot12, align 8
  br label %lhead

then17:                                           ; preds = %arm6
  %32 = call ptr @avra_insist(ptr %17)
  %33 = call i64 @avra_array_get(ptr %32, i64 0)
  %34 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %33, i64 %1)
  call void @avra_rc_release(ptr %32)
  br label %endif19

else18:                                           ; preds = %arm6
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval20 = phi i1 [ %34, %then17 ], [ false, %else18 ]
  call void @avra_rc_release(ptr %17)
  br label %endswitch

lhead23:                                          ; preds = %endif32, %arm7
  %ld25 = load i64, ptr %slot22, align 8
  %cmp26 = icmp slt i64 %ld25, %21
  br i1 %cmp26, label %lbody27, label %lexit24

lexit24:                                          ; preds = %lhead23
  %ld36 = load i1, ptr %slot21, align 8
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  br label %endswitch

lbody27:                                          ; preds = %lhead23
  %ld28 = load i64, ptr %slot22, align 8
  %35 = call i64 @avra_array_get(ptr %20, i64 %ld28)
  call void @avra_rc_retain(ptr %18)
  %cast29 = inttoptr i64 %19 to ptr
  %36 = call i1 %cast29(ptr %18, i64 %35)
  br i1 %36, label %then30, label %else31

then30:                                           ; preds = %lbody27
  store i1 true, ptr %slot21, align 8
  store i64 %21, ptr %slot22, align 8
  br label %endif32

else31:                                           ; preds = %lbody27
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval33 = phi i64 [ 0, %then30 ], [ 0, %else31 ]
  %ld34 = load i64, ptr %slot22, align 8
  %add35 = add i64 %ld34, 1
  store i64 %add35, ptr %slot22, align 8
  br label %lhead23

then37:                                           ; preds = %arm8
  br label %endif39

else38:                                           ; preds = %arm8
  store i1 false, ptr %slot40, align 8
  %37 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %37, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Eir$24l63" to i64))
  call void @avra_array_push(ptr %37, i64 %1)
  %38 = call i64 @avra_array_get(ptr %37, i64 0)
  call void @avra_rc_retain(ptr %0)
  %39 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emoved_args"(ptr %0)
  %40 = call i64 @avra_array_len(ptr %39)
  store i64 0, ptr %slot41, align 8
  br label %lhead42

endif39:                                          ; preds = %lexit43, %then37
  %regval56 = phi i1 [ true, %then37 ], [ %ld55, %lexit43 ]
  br label %endswitch

lhead42:                                          ; preds = %endif51, %else38
  %ld44 = load i64, ptr %slot41, align 8
  %cmp45 = icmp slt i64 %ld44, %40
  br i1 %cmp45, label %lbody46, label %lexit43

lexit43:                                          ; preds = %lhead42
  %ld55 = load i1, ptr %slot40, align 8
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %37)
  br label %endif39

lbody46:                                          ; preds = %lhead42
  %ld47 = load i64, ptr %slot41, align 8
  %41 = call i64 @avra_array_get(ptr %39, i64 %ld47)
  call void @avra_rc_retain(ptr %37)
  %cast48 = inttoptr i64 %38 to ptr
  %42 = call i1 %cast48(ptr %37, i64 %41)
  br i1 %42, label %then49, label %else50

then49:                                           ; preds = %lbody46
  store i1 true, ptr %slot40, align 8
  store i64 %40, ptr %slot41, align 8
  br label %endif51

else50:                                           ; preds = %lbody46
  br label %endif51

endif51:                                          ; preds = %else50, %then49
  %regval52 = phi i64 [ 0, %then49 ], [ 0, %else50 ]
  %ld53 = load i64, ptr %slot41, align 8
  %add54 = add i64 %ld53, 1
  store i64 %add54, ptr %slot41, align 8
  br label %lhead42
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eir$24l63"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eir$24l53"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eir$24l23"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Ekept_seat"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot4 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Eir$24l85" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %0)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %7 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %8 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  %9 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_reg"(i64 %8, i64 %2)
  br i1 %9, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_array_push(ptr %5, i64 %ld2)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

lhead5:                                           ; preds = %endif13, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %7
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  %ld17 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld17

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %10 = call i64 @avra_array_get(ptr %5, i64 %ld10)
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %4 to ptr
  %11 = call i1 %cast(ptr %3, i64 %10)
  br i1 %11, label %then11, label %else12

then11:                                           ; preds = %lbody9
  store i1 true, ptr %slot, align 8
  store i64 %7, ptr %slot4, align 8
  br label %endif13

else12:                                           ; preds = %lbody9
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  %ld15 = load i64, ptr %slot4, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot4, align 8
  br label %lhead5
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eir$24l85"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ert_keeps"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Ert_keeps"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2Eun_symbol"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str, i64 16)
}
