; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"a fieldless property on a struct survived typing\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"a property without a row survived typing\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"a variant construction without an enum type\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [38 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 37 }, [38 x i8] c"an undeclared variant survived typing\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_array_get\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"avra_str_concat\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"an unresolved name survived a clean analysis\00" }, align 16

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

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr, i1)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eshape_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etagged_value"(ptr, i64, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Edef_reg"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr, i64, ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr, i64, i64, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_of"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence"(ptr, i64, ptr, i64, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Espine_lower"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm8 [
    i64 0, label %arm
    i64 1, label %arm2
    i64 4, label %arm3
    i64 6, label %arm4
    i64 7, label %arm5
    i64 11, label %arm6
    i64 12, label %arm7
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_array_push(ptr %8, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm2:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %12 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %12, i64 1)
  call void @avra_array_push(ptr %12, i64 %11)
  call void @avra_array_push(ptr %12, i64 %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %12)
  br label %endswitch

arm3:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eident_reg"(ptr %0, i64 %1)
  br label %endswitch

arm4:                                             ; preds = %entry
  %15 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %16 = call i64 @avra_array_get(ptr %4, i64 2)
  %17 = call i64 @avra_array_get(ptr %4, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Ebinary_reg"(ptr %0, i64 %1, ptr %15, i64 %16, i64 %17)
  call void @avra_rc_release(ptr %15)
  br label %endswitch

arm5:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Enot_reg"(ptr %0, i64 %1, i64 %19)
  br label %endswitch

arm6:                                             ; preds = %entry
  %21 = call i64 @avra_array_get(ptr %4, i64 1)
  %22 = call i64 @avra_array_get(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eindex_reg"(ptr %0, i64 %1, i64 %21, i64 %22)
  br label %endswitch

arm7:                                             ; preds = %entry
  %24 = call i64 @avra_array_get(ptr %4, i64 1)
  %25 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed9 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed9)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eprop_reg"(ptr %0, i64 %1, i64 %24, ptr %boxed9)
  br label %endswitch

arm8:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %27 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm8, %arm7, %arm6, %arm5, %arm4, %arm3, %arm2, %arm
  %regval = phi i64 [ %7, %arm ], [ %11, %arm2 ], [ %14, %arm3 ], [ %18, %arm4 ], [ %20, %arm5 ], [ %23, %arm6 ], [ %26, %arm7 ], [ %27, %arm8 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eprop_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eshape_at"(ptr %0, i64 %2)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp = icmp eq i64 %5, 20
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Evariant_reg"(ptr %0, i64 %1, ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen"(ptr %0, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_of"(ptr %0, ptr %8)
  %cmp1 = icmp ne ptr %9, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eproperty_reg"(ptr %0, i64 %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %11 = call ptr @avra_insist(ptr %9)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %3)
  %12 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr %11, ptr %3)
  %x = extractvalue { i1, i64 } %12, 0
  %not7 = xor i1 %x, true
  br i1 %not7, label %then8, label %else9

postret5:                                         ; No predecessors!
  br label %endif4

then8:                                            ; preds = %endif4
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  %x13 = extractvalue { i1, i64 } %12, 0
  %x14 = extractvalue { i1, i64 } %12, 1
  %slot = zext i1 %x13 to i64
  %15 = call i64 @avra_insist_scalar(i64 %slot, i64 %x14)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr %0, i64 %14, ptr %8, i64 %15, ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

postret11:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eproperty_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %5 = call i64 @avra_array_get(ptr %4, i64 5)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %7 = call i64 @avra_array_get(ptr %6, i64 6)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 2)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_of"(ptr %boxed, ptr %boxed2, ptr %3, ptr %9)
  %cmp = icmp ne ptr %10, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
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
  %boxed3 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  %16 = call i64 @avra_array_get(ptr %boxed3, i64 0)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %cast = inttoptr i64 %16 to ptr
  %17 = call i64 %cast(ptr %boxed3, ptr %0, i64 %1, i64 %14, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Evariant_reg"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %2)
  %6 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %5, ptr %2)
  %x = extractvalue { i1, i64 } %6, 0
  %not1 = xor i1 %x, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %x7 = extractvalue { i1, i64 } %6, 0
  %x8 = extractvalue { i1, i64 } %6, 1
  %slot = zext i1 %x7 to i64
  %10 = call i64 @avra_insist_scalar(i64 %slot, i64 %x8)
  %11 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etagged_value"(ptr %0, i64 %9, i64 %8, i64 %10, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eindex_reg"(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 %4)
  call void @avra_array_push(ptr %7, i64 %5)
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %8, i64 7)
  call void @avra_array_push(ptr %8, i64 %6)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Enot_reg"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  %6 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %6, i64 5)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Ebinary_reg"(ptr %0, i64 %1, ptr %2, i64 %3, i64 %4) {
entry:
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 11)
  %6 = call i64 @avra_array_get(ptr %2, i64 0)
  %7 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp = icmp eq i64 %6, %7
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 12)
  %9 = call i64 @avra_array_get(ptr %2, i64 0)
  %10 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp1 = icmp eq i64 %9, %10
  call void @avra_rc_release(ptr %8)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elazy_reg"(ptr %0, i64 %1, ptr %2, i64 %3, i64 %4)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Easked_subject"(ptr %0, ptr %2, i64 %3, i64 %4)
  %cmp6 = icmp ne ptr %12, null
  br i1 %cmp6, label %then7, label %else8

postret:                                          ; No predecessors!
  br label %endif4

then7:                                            ; preds = %endif4
  %13 = call ptr @avra_insist(ptr %12)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Epresence_reg"(ptr %0, i64 %1, ptr %2, i64 %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %15

else8:                                            ; preds = %endif4
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %3)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 5)
  %20 = call i64 @avra_array_get(ptr %2, i64 0)
  %21 = call i64 @avra_array_get(ptr %19, i64 0)
  %cmp12 = icmp eq i64 %20, %21
  br i1 %cmp12, label %then13, label %else14

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %13)
  br label %endif9

then13:                                           ; preds = %endif9
  br label %endif15

else14:                                           ; preds = %endif9
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 6)
  %23 = call i64 @avra_array_get(ptr %2, i64 0)
  %24 = call i64 @avra_array_get(ptr %22, i64 0)
  %cmp16 = icmp eq i64 %23, %24
  call void @avra_rc_release(ptr %22)
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval17 = phi i1 [ true, %then13 ], [ %cmp16, %else14 ]
  br i1 %regval17, label %then18, label %else19

then18:                                           ; preds = %endif15
  %25 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp21 = icmp eq i64 %25, 16
  br i1 %cmp21, label %then22, label %else23

else19:                                           ; preds = %endif15
  br label %endif20

endif20:                                          ; preds = %else19, %endif24
  %regval27 = phi i1 [ %regval26, %endif24 ], [ false, %else19 ]
  br i1 %regval27, label %then28, label %else29

then22:                                           ; preds = %then18
  br label %endif24

else23:                                           ; preds = %then18
  call void @avra_rc_retain(ptr %0)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %4)
  %27 = call i64 @avra_array_get(ptr %26, i64 0)
  %cmp25 = icmp eq i64 %27, 16
  call void @avra_rc_release(ptr %26)
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br label %endif20

then28:                                           ; preds = %endif20
  %28 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %28, i64 6)
  %29 = call i64 @avra_array_get(ptr %2, i64 0)
  %30 = call i64 @avra_array_get(ptr %28, i64 0)
  %cmp31 = icmp eq i64 %29, %30
  call void @avra_rc_retain(ptr %0)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Enullable_eq_reg"(ptr %0, i64 %1, i64 %3, i64 %4)
  call void @avra_rc_retain(ptr %0)
  %32 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Enegated_when"(ptr %0, i64 %1, i1 %cmp31, i64 %31)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %32

else29:                                           ; preds = %endif20
  br label %endif30

endif30:                                          ; preds = %else29, %postret32
  %regval33 = phi i64 [ 0, %postret32 ], [ 0, %else29 ]
  %33 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %33, i64 0)
  %34 = call i64 @avra_array_get(ptr %2, i64 0)
  %35 = call i64 @avra_array_get(ptr %33, i64 0)
  %cmp34 = icmp eq i64 %34, %35
  br i1 %cmp34, label %then35, label %else36

postret32:                                        ; No predecessors!
  call void @avra_rc_release(ptr %28)
  br label %endif30

then35:                                           ; preds = %endif30
  %36 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp38 = icmp eq i64 %36, 3
  br label %endif37

else36:                                           ; preds = %endif30
  br label %endif37

endif37:                                          ; preds = %else36, %then35
  %regval39 = phi i1 [ %cmp38, %then35 ], [ false, %else36 ]
  br i1 %regval39, label %then40, label %else41

then40:                                           ; preds = %endif37
  call void @avra_rc_retain(ptr %0)
  %37 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %38 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %38, i64 %16)
  call void @avra_array_push(ptr %38, i64 %17)
  %39 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %39, i64 7)
  call void @avra_array_push(ptr %39, i64 %37)
  call void @avra_array_push_owned(ptr %39, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %39, ptr %38)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %39)
  %40 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %39)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %37

else41:                                           ; preds = %endif37
  br label %endif42

endif42:                                          ; preds = %else41, %postret43
  %regval44 = phi i64 [ 0, %postret43 ], [ 0, %else41 ]
  %41 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %41, i64 5)
  %42 = call i64 @avra_array_get(ptr %2, i64 0)
  %43 = call i64 @avra_array_get(ptr %41, i64 0)
  %cmp45 = icmp eq i64 %42, %43
  br i1 %cmp45, label %then46, label %else47

postret43:                                        ; No predecessors!
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif42

then46:                                           ; preds = %endif42
  br label %endif48

else47:                                           ; preds = %endif42
  %44 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %44, i64 6)
  %45 = call i64 @avra_array_get(ptr %2, i64 0)
  %46 = call i64 @avra_array_get(ptr %44, i64 0)
  %cmp49 = icmp eq i64 %45, %46
  call void @avra_rc_release(ptr %44)
  br label %endif48

endif48:                                          ; preds = %else47, %then46
  %regval50 = phi i1 [ true, %then46 ], [ %cmp49, %else47 ]
  br i1 %regval50, label %then51, label %else52

then51:                                           ; preds = %endif48
  %47 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp54 = icmp eq i64 %47, 3
  br i1 %cmp54, label %then55, label %else56

else52:                                           ; preds = %endif48
  br label %endif53

endif53:                                          ; preds = %else52, %endif62
  %regval65 = phi i1 [ %regval64, %endif62 ], [ false, %else52 ]
  br i1 %regval65, label %then66, label %else67

then55:                                           ; preds = %then51
  br label %endif57

else56:                                           ; preds = %then51
  %48 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp58 = icmp eq i64 %48, 4
  br label %endif57

endif57:                                          ; preds = %else56, %then55
  %regval59 = phi i1 [ true, %then55 ], [ %cmp58, %else56 ]
  br i1 %regval59, label %then60, label %else61

then60:                                           ; preds = %endif57
  br label %endif62

else61:                                           ; preds = %endif57
  %49 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp63 = icmp eq i64 %49, 7
  br label %endif62

endif62:                                          ; preds = %else61, %then60
  %regval64 = phi i1 [ true, %then60 ], [ %cmp63, %else61 ]
  br label %endif53

then66:                                           ; preds = %endif53
  call void @avra_rc_retain(ptr %0)
  %50 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %50)
  %51 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr %0, i64 %16, i64 %17, ptr %50)
  %52 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %52, i64 5)
  %53 = call i64 @avra_array_get(ptr %2, i64 0)
  %54 = call i64 @avra_array_get(ptr %52, i64 0)
  %cmp69 = icmp eq i64 %53, %54
  br i1 %cmp69, label %then70, label %else71

else67:                                           ; preds = %endif53
  br label %endif68

endif68:                                          ; preds = %else67, %postret75
  %regval76 = phi i64 [ 0, %postret75 ], [ 0, %else67 ]
  call void @avra_rc_retain(ptr %0)
  %55 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %56 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %56, i64 4)
  call void @avra_array_push(ptr %56, i64 %55)
  call void @avra_array_push_owned(ptr %56, ptr %2)
  call void @avra_array_push(ptr %56, i64 %16)
  call void @avra_array_push(ptr %56, i64 %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %56)
  %57 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %56)
  call void @avra_rc_release(ptr %56)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %55

then70:                                           ; preds = %then66
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %51

else71:                                           ; preds = %then66
  br label %endif72

endif72:                                          ; preds = %else71, %postret73
  %regval74 = phi i64 [ 0, %postret73 ], [ 0, %else71 ]
  call void @avra_rc_retain(ptr %0)
  %58 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %59 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %59, i64 0)
  %60 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %60, i64 5)
  call void @avra_array_push(ptr %60, i64 %58)
  call void @avra_array_push_owned(ptr %60, ptr %59)
  call void @avra_array_push(ptr %60, i64 %51)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %60)
  %61 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %60)
  call void @avra_rc_release(ptr %60)
  call void @avra_rc_release(ptr %59)
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %58

postret73:                                        ; No predecessors!
  br label %endif72

postret75:                                        ; No predecessors!
  call void @avra_rc_release(ptr %60)
  call void @avra_rc_release(ptr %59)
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %50)
  br label %endif68
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Enegated_when"(ptr %0, i64 %1, i1 %2, i64 %3) {
entry:
  %not = xor i1 %2, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  %6 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %6, i64 5)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %4

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Enullable_eq_reg"(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %3)
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %6)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed1, ptr %6)
  %cmp = icmp ne ptr %10, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %6)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eled_by"(ptr %0, i64 %1, i64 %5, ptr %7, i64 %4, ptr %6)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %7)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eled_by"(ptr %0, i64 %1, i64 %4, ptr %6, i64 %5, ptr %7)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eled_by"(ptr %0, i64 %1, i64 %2, ptr %3, i64 %4, ptr %5) {
entry:
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed1, ptr %3)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %8, %then ], [ %3, %else ]
  %9 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l423" to i64))
  call void @avra_array_push(ptr %9, i64 %1)
  call void @avra_array_push(ptr %9, i64 %4)
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %regval)
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l428" to i64))
  call void @avra_array_push(ptr %10, i64 %4)
  call void @avra_array_push_owned(ptr %10, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence"(ptr %0, i64 %2, ptr %3, i64 %1, ptr %9, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l428"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eabsent_beside"(ptr %1, i64 %2, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l423"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %6 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Epresent_beside"(ptr %1, i64 %3, i64 %2, i64 %4, ptr %5, ptr %boxed)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Epresent_beside"(ptr %0, i64 %1, i64 %2, i64 %3, ptr %4, ptr %5) {
entry:
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %4)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed1, ptr %4)
  %cmp = icmp ne ptr %8, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr %0, i64 %2, i64 %3, ptr %5)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l453" to i64))
  call void @avra_array_push(ptr %10, i64 %2)
  call void @avra_array_push_owned(ptr %10, ptr %5)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l457" to i64))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence"(ptr %0, i64 %3, ptr %4, i64 %1, ptr %10, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l457"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %1, i1 false)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l453"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr %1, i64 %3, i64 %2, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eabsent_beside"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed1, ptr %2)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %1, ptr %2)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 0)
  %11 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %11, i64 5)
  call void @avra_array_push(ptr %11, i64 %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Epresence_reg"(ptr %0, i64 %1, ptr %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %4, ptr %5)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 6)
  %8 = call i64 @avra_array_get(ptr %2, i64 0)
  %9 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp = icmp eq i64 %8, %9
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 0)
  %12 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %12, i64 5)
  call void @avra_array_push(ptr %12, i64 %10)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_array_push(ptr %12, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Easked_subject"(ptr %0, ptr %1, i64 %2, i64 %3) {
entry:
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 5)
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %6 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp = icmp eq i64 %5, %6
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 6)
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  %9 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp1 = icmp eq i64 %8, %9
  %not2 = xor i1 %cmp1, true
  call void @avra_rc_release(ptr %7)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not2, %then ], [ false, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval6 = phi i64 [ 0, %postret ], [ 0, %else4 ]
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %2)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp7 = icmp eq i64 %11, 16
  br i1 %cmp7, label %then8, label %else9

postret:                                          ; No predecessors!
  br label %endif5

then8:                                            ; preds = %endif5
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %3)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp11 = icmp eq i64 %13, 17
  call void @avra_rc_release(ptr %12)
  br label %endif10

else9:                                            ; preds = %endif5
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval12 = phi i1 [ %cmp11, %then8 ], [ false, %else9 ]
  br i1 %regval12, label %then13, label %else14

then13:                                           ; preds = %endif10
  %14 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %14, i64 %2)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else14:                                           ; preds = %endif10
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %3)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %cmp18 = icmp eq i64 %16, 16
  br i1 %cmp18, label %then19, label %else20

postret16:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  br label %endif15

then19:                                           ; preds = %endif15
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %2)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp22 = icmp eq i64 %18, 17
  call void @avra_rc_release(ptr %17)
  br label %endif21

else20:                                           ; preds = %endif15
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval23 = phi i1 [ %cmp22, %then19 ], [ false, %else20 ]
  br i1 %regval23, label %then24, label %else25

then24:                                           ; preds = %endif21
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 %3)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %19

else25:                                           ; preds = %endif21
  br label %endif26

endif26:                                          ; preds = %else25, %postret27
  %regval28 = phi i64 [ 0, %postret27 ], [ 0, %else25 ]
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

postret27:                                        ; No predecessors!
  call void @avra_rc_release(ptr %19)
  br label %endif26
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elazy_reg"(ptr %0, i64 %1, ptr %2, i64 %3, i64 %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %3)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 11)
  %7 = call i64 @avra_array_get(ptr %2, i64 0)
  %8 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp = icmp eq i64 %7, %8
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l518" to i64))
  call void @avra_array_push(ptr %9, i64 %4)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l522" to i64))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %5, i64 %1, ptr %9, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l531" to i64))
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l535" to i64))
  call void @avra_array_push(ptr %13, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %5, i64 %1, ptr %12, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %14

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l535"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l531"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %1, i1 true)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l522"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %1, i1 false)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Elower$24l518"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eident_reg"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Edef_reg"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %3, %then ], [ %4, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}
