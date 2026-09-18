; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.nested_type\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"type declarations\00" }, align 16

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

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Erefuses_nested"(ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumDeclSemantics$2Etype_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Echeck_enum_decl"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Echeck_enum_decl"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumDeclSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
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

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr, ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Elower"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums_reg"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums_reg"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eall_irrefutable"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %3, ptr %slot1, align 8
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eirrefutable"(ptr %0, i64 %ld3)
  %not = xor i1 %4, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eirrefutable"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Etype_of"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums_type"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums_type"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ehole_of"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %3, ptr %slot1, align 8
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eirrefutable"(ptr %0, i64 %ld3)
  br i1 %4, label %then, label %else

then:                                             ; preds = %lbody
  %ld4 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %ld4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Eresolve"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 20, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 2)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eresolve_arms"(ptr %1, ptr %boxed3)
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eresolve_arms"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot1)
  store ptr %3, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed3 = inttoptr i64 %5 to ptr
  %ld4 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %ld4)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_binds"(ptr %boxed3, ptr %ld4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_pats"(ptr %0, ptr %6)
  %ld5 = load ptr, ptr %slot1, align 8
  %8 = call i64 @avra_array_get(ptr %ld5, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr %0, ptr %7, i64 %8)
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_pats"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_binds"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 0, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %ld, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

then2:                                            ; preds = %endif
  %6 = call ptr @avra_array_sized(i64 0)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %7 = call ptr @avra_insist(ptr %ld)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epattern_binds"(ptr %0, i64 %8)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif4
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epattern_binds"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Eheirs"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 20, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  %6 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi ptr [ %4, %lexit ], [ %6, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %3)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 %ld2)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 1)
  call void @avra_array_push(ptr %4, i64 %8)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumsSemantics$2Ekids"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm3 [
    i64 20, label %arm
    i64 28, label %arm1
    i64 29, label %arm2
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %3)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %5)
  br label %endswitch

arm2:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  br label %endswitch

arm3:                                             ; preds = %entry
  %8 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %6, %arm1 ], [ %7, %arm2 ], [ %8, %arm3 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_binds"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebind_regs"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebind_regs"(ptr, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_accepts"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_reg"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_reg"(ptr, i64, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2EEnumPatSemantics$2Epat_types"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebind_types"(ptr %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebind_types"(ptr, i64, ptr)
