; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"a chain's member wears a type its lift does not expect\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [35 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 34 }, [35 x i8] c"a memberless chain survived typing\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [54 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 53 }, [54 x i8] c"a propagation without an enclosing fn survived typing\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr, ptr, i1, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr, i64, ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokness_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eenclosing_ret"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elet_else_reg"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed1, i64 %1)
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
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %6)
  %8 = call ptr @avra_insist(ptr %4)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %7, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr %0, ptr %10)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l250" to i64))
  call void @avra_array_push(ptr %13, i64 %7)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l265" to i64))
  call void @avra_array_push(ptr %14, i64 %1)
  call void @avra_array_push_owned(ptr %14, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %11, ptr %12, ptr %13, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  %16 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %16, i64 %15)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l265"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Eelse_stmts_of"(ptr %5)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Earm_stmts"(ptr %1, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed2)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr %1, ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %1, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l250"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %1, i64 %2, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Earm_stmts"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Eelse_stmts_of"(ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eleaving"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr, i64, ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr, i64, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Enullable_reg"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm7 [
    i64 21, label %arm
    i64 22, label %arm2
    i64 27, label %arm3
    i64 30, label %arm4
    i64 23, label %arm5
    i64 26, label %arm6
  ]

arm:                                              ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Enull_reg"(ptr %0, i64 %1)
  br label %endswitch

arm2:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %4, i64 1)
  %8 = call i64 @avra_array_get(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ecoalesce_reg"(ptr %0, i64 %1, i64 %7, i64 %8)
  br label %endswitch

arm3:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Eforced_reg"(ptr %0, i64 %1, i64 %10)
  br label %endswitch

arm4:                                             ; preds = %entry
  %12 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Epropagate_reg"(ptr %0, i64 %1, i64 %12)
  br label %endswitch

arm5:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %4, i64 1)
  %15 = call i64 @avra_array_get(ptr %4, i64 3)
  %16 = call i64 @avra_array_get(ptr %4, i64 4)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ematch_opt_reg"(ptr %0, i64 %1, i64 %14, i64 %15, i64 %16)
  br label %endswitch

arm6:                                             ; preds = %entry
  %18 = call i64 @avra_array_get(ptr %4, i64 1)
  %19 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed8 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed8)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Echain_reg"(ptr %0, i64 %1, i64 %18, ptr %boxed8)
  br label %endswitch

arm7:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm
  %regval = phi i64 [ %6, %arm ], [ %9, %arm2 ], [ %11, %arm3 ], [ %13, %arm4 ], [ %17, %arm5 ], [ %20, %arm6 ], [ %21, %arm7 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Echain_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %4, ptr %5)
  %8 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %8, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l291" to i64))
  call void @avra_array_push(ptr %8, i64 %1)
  call void @avra_array_push(ptr %8, i64 %4)
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr %3)
  call void @avra_array_push_owned(ptr %8, ptr %6)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l295" to i64))
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %7, i64 %1, ptr %8, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l295"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l291"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %6 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elifted_member"(ptr %1, i64 %2, i64 %3, ptr %4, ptr %5, ptr %boxed)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elifted_member"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %0, i64 %2, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Emember_reg"(ptr %0, i64 %1, i64 %6, ptr %7, ptr %4, ptr %5)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Emember_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_of"(ptr %0, ptr %3)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Echained_row"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %0, ptr %5, i1 false, i64 %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_insist(ptr %6)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %4)
  %10 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr %9, ptr %4)
  %x = extractvalue { i1, i64 } %10, 0
  %not1 = xor i1 %x, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ememberless_chain"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %x7 = extractvalue { i1, i64 } %10, 0
  %x8 = extractvalue { i1, i64 } %10, 1
  %slot = zext i1 %x7 to i64
  %12 = call i64 @avra_insist_scalar(i64 %slot, i64 %x8)
  %13 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  %14 = call ptr @avra_array_get_owned(ptr %13, i64 %12)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %5)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Etypes_differ"(ptr %14, ptr %5)
  %not9 = xor i1 %15, true
  br i1 %not9, label %then10, label %else11

postret5:                                         ; No predecessors!
  br label %endif4

then10:                                           ; preds = %endif4
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %14)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr %0, i64 %2, ptr %3, i64 %12, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

else11:                                           ; preds = %endif4
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %17)
  %18 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Etypes_differ"(ptr %14, ptr %17)
  br i1 %18, label %then15, label %else16

postret13:                                        ; No predecessors!
  br label %endif12

then15:                                           ; preds = %endif12
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %19

else16:                                           ; preds = %endif12
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %14)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr %0, i64 %2, ptr %3, i64 %12, ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %0, ptr %5, i1 false, i64 %20)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %21

postret18:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif17
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Etypes_differ"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp ne i64 %2, %3
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ememberless_chain"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Echained_row"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4) {
entry:
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call i64 @avra_array_get(ptr %5, i64 5)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 6)
  %boxed2 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed2, i64 2)
  %boxed3 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_of"(ptr %boxed, ptr %boxed3, ptr %4, ptr %3)
  %cmp = icmp ne ptr %10, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ememberless_chain"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %10)
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
  %13 = call i64 @avra_array_get(ptr %12, i64 3)
  %boxed4 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  call void @avra_rc_retain(ptr %boxed4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %14 to ptr
  %15 = call i64 %cast(ptr %boxed4, ptr %0, i64 %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %15

postret:                                          ; No predecessors!
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_of"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_of"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ematch_opt_reg"(ptr %0, i64 %1, i64 %2, i64 %3, i64 %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %5, ptr %6)
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %8, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l130" to i64))
  call void @avra_array_push(ptr %8, i64 %3)
  call void @avra_array_push(ptr %8, i64 %5)
  call void @avra_array_push_owned(ptr %8, ptr %6)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l134" to i64))
  call void @avra_array_push(ptr %9, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %7, i64 %1, ptr %8, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret i64 %10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l134"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l130"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %1, i64 %3, ptr %boxed)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %1, i64 %2, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %9
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Epropagate_reg"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %4)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp = icmp eq i64 %8, 13
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Epropagate_res_reg"(ptr %0, i64 %1, i64 %3)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l159" to i64))
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l163" to i64))
  call void @avra_array_push(ptr %11, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence"(ptr %0, i64 %3, ptr %4, i64 %1, ptr %10, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l163"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Edeparted"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l159"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Edeparted"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eenclosing_ret"(ptr %0)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr null)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eleaving"(ptr %0, ptr null)
  %5 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %0, ptr %5)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 21)
  call void @avra_array_push(ptr %7, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence"(ptr, i64, ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Epropagate_res_reg"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokness_of"(ptr %0, i64 %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l178" to i64))
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_array_push(ptr %4, i64 %1)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l192" to i64))
  call void @avra_array_push(ptr %5, i64 %2)
  call void @avra_array_push(ptr %5, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %3, i64 %1, ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l192"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 21)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %1, ptr %4)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %1, i64 %6)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %1, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l178"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %1, i64 %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_of"(ptr %1, i64 %2, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Eforced_reg"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %3, i64 5)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed, ptr %5)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einsisted"(ptr %0, i64 %1, i64 %8, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einsisted"(ptr, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Ecoalesce_reg"(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %5)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed1, ptr %5)
  %cmp = icmp ne ptr %8, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %10 = call i64 @avra_array_get(ptr %9, i64 5)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed2, ptr %11)
  %cmp3 = icmp ne ptr %12, null
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %4, ptr %5)
  %14 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %14, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l76" to i64))
  %slot = zext i1 %cmp3 to i64
  call void @avra_array_push(ptr %14, i64 %slot)
  call void @avra_array_push(ptr %14, i64 %4)
  call void @avra_array_push_owned(ptr %14, ptr %5)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l80" to i64))
  call void @avra_array_push(ptr %15, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %13, i64 %1, ptr %14, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l80"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Elower$24l76"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %5 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %1, i64 %4, ptr %boxed)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %3, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Enull_reg"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ezero"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ezero"(ptr, i64)
