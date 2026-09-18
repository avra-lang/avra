; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"a mutation through a value survived resolve\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_cell_unique\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [54 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 53 }, [54 x i8] c"a mutation rooted outside a mut cell survived resolve\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_slot_unique\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [34 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 33 }, [34 x i8] c"a fieldless place survived typing\00" }, align 16

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

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_step"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Edef_reg"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened_place"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_step"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm3 [
    i64 0, label %arm
    i64 1, label %arm2
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecell_place"(ptr %0, i64 %1)
  br label %endswitch

arm2:                                             ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %5, i64 1)
  %9 = call i64 @avra_array_get(ptr %5, i64 2)
  %boxed4 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed4)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_place"(ptr %0, i64 %8, ptr %boxed4)
  br label %endswitch

arm3:                                             ; preds = %endif
  %11 = call i64 @avra_array_get(ptr %5, i64 1)
  %12 = call i64 @avra_array_get(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %12)
  %15 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %15, i64 1)
  call void @avra_array_push(ptr %15, i64 %13)
  call void @avra_array_push(ptr %15, i64 %14)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm
  %regval5 = phi ptr [ %7, %arm ], [ %10, %arm2 ], [ %15, %arm3 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_step"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm3 [
    i64 0, label %arm
    i64 1, label %arm2
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif

arm:                                              ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecell_of"(ptr %0, i64 %1)
  %cmp4 = icmp ne ptr %8, null
  br i1 %cmp4, label %then5, label %else6

arm2:                                             ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %6, i64 1)
  %10 = call i64 @avra_array_get(ptr %6, i64 2)
  %boxed15 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed15)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_slot"(ptr %0, i64 %9, ptr %boxed15)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_opened"(ptr %0, i64 %1, i64 %11, i64 %12)
  br label %endswitch

arm3:                                             ; preds = %endif
  %14 = call i64 @avra_array_get(ptr %6, i64 1)
  %15 = call i64 @avra_array_get(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %14)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %15)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_opened"(ptr %0, i64 %1, i64 %16, i64 %17)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %endif13
  %regval16 = phi i64 [ %regval14, %endif13 ], [ %13, %arm2 ], [ %18, %arm3 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval16

then5:                                            ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %19)
  %21 = call ptr @avra_insist(ptr %8)
  %22 = call i64 @avra_array_get(ptr %21, i64 0)
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %23, i64 %22)
  %24 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %24, i64 7)
  call void @avra_array_push(ptr %24, i64 %20)
  call void @avra_array_push_owned(ptr %24, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %24, ptr %23)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %24)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %24)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %20

else6:                                            ; preds = %arm
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  call void @avra_rc_retain(ptr %0)
  %26 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Edef_reg"(ptr %0, i64 %1)
  %cmp10 = icmp ne ptr %26, null
  br i1 %cmp10, label %then11, label %else12

postret8:                                         ; No predecessors!
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %19)
  br label %endif7

then11:                                           ; preds = %endif7
  %27 = call i64 @avra_array_get(ptr %26, i64 0)
  br label %endif13

else12:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %28 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i64 [ %27, %then11 ], [ %28, %else12 ]
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %8)
  br label %endswitch
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_opened"(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %4)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 %2)
  call void @avra_array_push(ptr %6, i64 %3)
  %7 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %7, i64 7)
  call void @avra_array_push(ptr %7, i64 %5)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_slot"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_at"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %2)
  %4 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr %3, ptr %2)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %4, %then ], [ zeroinitializer, %else ]
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %5)
  %x = extractvalue { i1, i64 } %regval, 0
  %not = xor i1 %x, true
  br i1 %not, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  %x5 = extractvalue { i1, i64 } %regval, 0
  %x6 = extractvalue { i1, i64 } %regval, 1
  %slot = zext i1 %x5 to i64
  %8 = call i64 @avra_insist_scalar(i64 %slot, i64 %x6)
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %9, i64 0)
  call void @avra_array_push(ptr %9, i64 %6)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  br label %endif3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecell_of"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_place"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eflat_at"(ptr %0, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened_place"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_slot"(ptr %0, i64 %1, ptr %2)
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %7, i64 1)
  call void @avra_array_push(ptr %7, i64 %5)
  call void @avra_array_push(ptr %7, i64 %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eflat_at"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecell_place"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecell_of"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  br label %endif
}
