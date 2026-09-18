; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.nested_type\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"type declarations\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.nested_type\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"type declarations\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_under"(ptr, ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Erefuses_nested"(ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2ENamedTypeSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Erefuses_nested"(ptr %1, i64 %2, ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructDeclSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot2 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edecl_resolve"(ptr %1, i64 %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edefault_exprs"(ptr %boxed1, i64 %2)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %6, i64 %ld3)
  store i64 %8, ptr %slot2, align 8
  %9 = call ptr @avra_array_sized(i64 0)
  %ld4 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_under"(ptr %1, ptr %9, i64 %ld4)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edefault_exprs"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_parts"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_insist(ptr %2)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  br label %endif

lhead:                                            ; preds = %endif6, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %7
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 %ld2)
  %9 = call i64 @avra_array_get(ptr %8, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %cmp3 = icmp ne ptr %boxed, null
  br i1 %cmp3, label %then4, label %else5

then4:                                            ; preds = %lbody
  %10 = call i64 @avra_array_get(ptr %8, i64 2)
  %boxed7 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_insist(ptr %boxed7)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  call void @avra_array_push(ptr %4, i64 %12)
  call void @avra_rc_release(ptr %11)
  br label %endif6

else5:                                            ; preds = %lbody
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i64 [ 0, %then4 ], [ 0, %else5 ]
  %ld9 = load i64, ptr %slot, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edecl_resolve"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Erefuses_nested"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 18, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %7 = call i64 @avra_array_get(ptr %5, i64 3)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echeck_params"(ptr %0, ptr %boxed3, i64 %1)
  br label %endswitch

arm2:                                             ; preds = %endif
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval4 = phi i64 [ %8, %arm ], [ %9, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %regval4
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echeck_params"(ptr, ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Elower"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs_reg"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs_reg"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Etype_of"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs_type"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs_type"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Eresolve"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 18, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Euse_type"(ptr %1, i64 %2, ptr %boxed3)
  br label %endswitch

arm2:                                             ; preds = %entry
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %8, %arm ], [ %9, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Euse_type"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2EStructsSemantics$2Ekids"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm2 [
    i64 18, label %arm
    i64 19, label %arm1
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 3)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %5 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %4)
  %7 = call ptr @avra_array_concat(ptr %6, ptr %boxed)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %3, %arm ], [ %7, %arm1 ], [ %8, %arm2 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}
