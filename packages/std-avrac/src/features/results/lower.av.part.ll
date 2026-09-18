; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"a catch without a Result survived typing\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"catch arms without variants survived typing\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokness_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatch_reg"(ptr %0, i64 %1) {
entry:
  %slot6 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 31, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %8 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  %9 = call ptr @avra_array_get_owned(ptr %4, i64 4)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %lexit8
  %regval = phi i64 [ %16, %lexit8 ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %11
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot6, align 8
  br label %lhead7

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %15 = call i64 @avra_array_get(ptr %7, i64 %ld3)
  %boxed4 = inttoptr i64 %15 to ptr
  call void @avra_array_push_owned(ptr %10, ptr %boxed4)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead7:                                           ; preds = %lbody11, %lexit
  %ld9 = load i64, ptr %slot6, align 8
  %cmp10 = icmp slt i64 %ld9, %14
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %9)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatched_reg"(ptr %0, i64 %1, i64 %6, ptr %10, ptr %13, ptr %9)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot6, align 8
  %17 = call i64 @avra_array_get(ptr %8, i64 %ld12)
  %boxed13 = inttoptr i64 %17 to ptr
  call void @avra_array_push_owned(ptr %13, ptr %boxed13)
  %ld14 = load i64, ptr %slot6, align 8
  %add15 = add i64 %ld14, 1
  store i64 %add15, ptr %slot6, align 8
  br label %lhead7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatched_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %8 = call i64 @avra_array_get(ptr %7, i64 5)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed, ptr %9)
  %cmp = icmp ne ptr %10, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %12 = call ptr @avra_insist(ptr %10)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokness_of"(ptr %0, i64 %6)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower$24l51" to i64))
  call void @avra_array_push(ptr %14, i64 %6)
  call void @avra_array_push_owned(ptr %14, ptr %12)
  %15 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower$24l60" to i64))
  call void @avra_array_push(ptr %15, i64 %1)
  call void @avra_array_push(ptr %15, i64 %6)
  call void @avra_array_push_owned(ptr %15, ptr %12)
  call void @avra_array_push_owned(ptr %15, ptr %3)
  call void @avra_array_push_owned(ptr %15, ptr %4)
  call void @avra_array_push_owned(ptr %15, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %13, i64 %1, ptr %14, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower$24l60"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  %7 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Efailure_reg"(ptr %1, i64 %2, i64 %3, ptr %4, ptr %5, ptr %6, ptr %boxed)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower$24l51"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr %1, i64 %2, ptr %boxed1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Efailure_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5, ptr %6) {
entry:
  %7 = call i64 @avra_array_len(ptr %4)
  %cmp = icmp eq i64 %7, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %4, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_streq(ptr %boxed, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %b = icmp ne i64 %9, 0
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %b, %then ], [ false, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  %10 = call i64 @avra_array_get(ptr %5, i64 0)
  %boxed4 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %6, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed4)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eall_arm_reg"(ptr %0, i64 %2, ptr %3, ptr %boxed4, i64 %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eswitched_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

postret:                                          ; No predecessors!
  br label %endif3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eswitched_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5, ptr %6) {
entry:
  %slot4 = alloca i64, align 8
  %slot3 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_of"(ptr %0, ptr %boxed)
  %cmp = icmp ne ptr %8, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call ptr @avra_insist(ptr %8)
  %11 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed1 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr %0, i64 %2, ptr %boxed1)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %4)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Etotal"(ptr %10, ptr %4)
  %not2 = xor i1 %13, true
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %4)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_tags"(ptr %10, ptr %4, i1 %not2)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr %0, i64 %12)
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 15)
  call void @avra_array_push(ptr %16, i64 %15)
  call void @avra_array_push_owned(ptr %16, ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %16)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %18 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot3, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif

lhead:                                            ; preds = %endif18, %endif
  %ld = load i64, ptr %slot3, align 8
  %cmp5 = icmp slt i64 %ld, %18
  br i1 %cmp5, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  br i1 %not2, label %then24, label %else25

lbody:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot3, align 8
  %19 = call i64 @avra_array_get(ptr %6, i64 %ld6)
  store i64 %19, ptr %slot4, align 8
  %ld7 = load ptr, ptr %slot, align 8
  %cmp8 = icmp ne ptr %ld7, null
  br i1 %cmp8, label %then9, label %else10

then9:                                            ; preds = %lbody
  %ld12 = load ptr, ptr %slot, align 8
  %20 = call ptr @avra_insist(ptr %ld12)
  %21 = call i64 @avra_array_get(ptr %20, i64 0)
  call void @avra_rc_retain(ptr %0)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %21)
  call void @avra_rc_release(ptr %20)
  br label %endif11

else10:                                           ; preds = %lbody
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval13 = phi i64 [ 0, %then9 ], [ 0, %else10 ]
  %23 = call i64 @avra_array_get(ptr %5, i64 %ld6)
  %boxed14 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_streq(ptr %boxed14, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %b = icmp ne i64 %24, 0
  %not15 = xor i1 %b, true
  br i1 %not15, label %then16, label %else17

then16:                                           ; preds = %endif11
  %25 = call i64 @avra_array_get(ptr %4, i64 %ld6)
  %boxed19 = inttoptr i64 %25 to ptr
  %ld20 = load i64, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %boxed19)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ebind_payload"(ptr %0, i64 %12, ptr %10, ptr %boxed19, i64 %ld20)
  br label %endif18

else17:                                           ; preds = %endif11
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval21 = phi i64 [ 0, %then16 ], [ 0, %else17 ]
  %ld22 = load i64, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %0)
  %27 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %ld22)
  %28 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %28, i64 %27)
  call void @avra_rc_retain(ptr %28)
  call void @avra_cell_release(ptr %slot)
  store ptr %28, ptr %slot, align 8
  %ld23 = load i64, ptr %slot3, align 8
  %add = add i64 %ld23, 1
  store i64 %add, ptr %slot3, align 8
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %lhead

then24:                                           ; preds = %lexit
  %ld27 = load ptr, ptr %slot, align 8
  %29 = call ptr @avra_insist(ptr %ld27)
  %30 = call i64 @avra_array_get(ptr %29, i64 0)
  call void @avra_rc_retain(ptr %0)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %30)
  call void @avra_rc_retain(ptr %0)
  %32 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr %0)
  %33 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %33, i64 21)
  call void @avra_array_push(ptr %33, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %33)
  %34 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %33)
  call void @avra_rc_retain(ptr %0)
  %35 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %35)
  %36 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %0, ptr %35)
  %37 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %37, i64 %36)
  call void @avra_rc_retain(ptr %37)
  call void @avra_cell_release(ptr %slot)
  store ptr %37, ptr %slot, align 8
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %29)
  br label %endif26

else25:                                           ; preds = %lexit
  br label %endif26

endif26:                                          ; preds = %else25, %then24
  %regval28 = phi i64 [ 0, %then24 ], [ 0, %else25 ]
  %ld29 = load ptr, ptr %slot, align 8
  %38 = call ptr @avra_insist(ptr %ld29)
  %39 = call i64 @avra_array_get(ptr %38, i64 0)
  call void @avra_rc_retain(ptr %0)
  %40 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr %0, i64 %1, i64 %39)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %40
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr, i64, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ebind_payload"(ptr %0, i64 %1, ptr %2, ptr %3, i64 %4) {
entry:
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayload_of"(ptr %2, ptr %3)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr %0, i64 %1, ptr %6)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %0, i64 %4, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayload_of"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_tags"(ptr %0, ptr %1, i1 %2) {
entry:
  %slot = alloca i64, align 8
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_len(ptr %1)
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_len(ptr %1)
  %sub = sub i64 %4, 1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %3, %then ], [ %sub, %else ]
  %5 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %regval
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %0, ptr %boxed)
  %x = extractvalue { i1, i64 } %7, 0
  %x2 = extractvalue { i1, i64 } %7, 1
  %slot3 = zext i1 %x to i64
  %8 = call i64 @avra_insist_scalar(i64 %slot3, i64 %x2)
  call void @avra_array_push(ptr %5, i64 %8)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Etotal"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 true, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower$24l214" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call i64 @avra_array_get(ptr %4, i64 %ld2)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %3 to ptr
  %7 = call i1 %cast(ptr %2, ptr %boxed)
  %not = xor i1 %7, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  store i1 false, ptr %slot, align 8
  store i64 %5, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower$24l214"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enamed_in"(ptr %boxed, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enamed_in"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_of"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eall_arm_reg"(ptr %0, i64 %1, ptr %2, ptr %3, i64 %4) {
entry:
  %5 = call i64 @avra_streq(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %b = icmp ne i64 %5, 0
  %not = xor i1 %b, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr %0, i64 %1, ptr %boxed)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %0, i64 %4, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr, i64, i64, ptr, ptr)
