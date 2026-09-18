; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [33 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 32 }, [33 x i8] c"a bounded receiver survived mono\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [48 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 47 }, [48 x i8] c"a method on a nameless receiver survived typing\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [40 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 39 }, [40 x i8] c"a method with no symbol survived typing\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [47 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 46 }, [47 x i8] c"a dyn method outside its trait survived typing\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"a variant built without an enum type\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [38 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 37 }, [38 x i8] c"an undeclared variant survived typing\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"a receiver outside a method survived resolve\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr, ptr, ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Emethod_symbol"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_method_names"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etagged_value"(ptr, i64, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecalled_through"(ptr, i64, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Emethod_call_reg"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 32, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %8 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %6)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %7)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ecallee_of"(ptr %9, ptr %10, ptr %7)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  switch i64 %12, label %arm10 [
    i64 0, label %arm3
    i64 1, label %arm4
    i64 2, label %arm5
    i64 3, label %arm6
    i64 4, label %arm7
    i64 5, label %arm8
    i64 6, label %arm9
  ]

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endswitch11
  %regval18 = phi i64 [ %regval, %endswitch11 ], [ %13, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval18

arm3:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilt_variant"(ptr %0, i64 %1, ptr %7, ptr %8)
  br label %endswitch11

arm4:                                             ; preds = %arm
  %15 = call i64 @avra_array_get(ptr %11, i64 1)
  %boxed12 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed12)
  call void @avra_rc_retain(ptr %8)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estatic_dispatch"(ptr %0, i64 %1, ptr %boxed12, ptr %8)
  br label %endswitch11

arm5:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endswitch11

arm6:                                             ; preds = %arm
  %18 = call i64 @avra_array_get(ptr %11, i64 1)
  %boxed13 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed13)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Edyn_dispatch"(ptr %0, i64 %1, i64 %6, ptr %boxed13, ptr %7, ptr %8)
  br label %endswitch11

arm7:                                             ; preds = %arm
  %20 = call i64 @avra_array_get(ptr %11, i64 1)
  %21 = call i64 @avra_array_get(ptr %11, i64 2)
  %boxed14 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %8)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Efielded_dispatch"(ptr %0, i64 %1, i64 %6, i64 %20, ptr %boxed14, ptr %8)
  br label %endswitch11

arm8:                                             ; preds = %arm
  %23 = call i64 @avra_array_get(ptr %11, i64 1)
  %boxed15 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed15, i64 3)
  %boxed16 = inttoptr i64 %24 to ptr
  %25 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %25, i64 %1)
  call void @avra_array_push(ptr %25, i64 %6)
  call void @avra_array_push_owned(ptr %25, ptr %8)
  %26 = call i64 @avra_array_get(ptr %boxed16, i64 0)
  call void @avra_rc_retain(ptr %boxed16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %25)
  %cast = inttoptr i64 %26 to ptr
  %27 = call i64 %cast(ptr %boxed16, ptr %0, ptr %25)
  call void @avra_rc_release(ptr %25)
  br label %endswitch11

arm9:                                             ; preds = %arm
  %28 = call i64 @avra_array_get(ptr %11, i64 1)
  %boxed17 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed17)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %29 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Edeclared_dispatch"(ptr %0, i64 %1, i64 %6, ptr %boxed17, ptr %7, ptr %8)
  br label %endswitch11

arm10:                                            ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %30 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endswitch11

endswitch11:                                      ; preds = %arm10, %arm9, %arm8, %arm7, %arm6, %arm5, %arm4, %arm3
  %regval = phi i64 [ %14, %arm3 ], [ %16, %arm4 ], [ %17, %arm5 ], [ %19, %arm6 ], [ %22, %arm7 ], [ %27, %arm8 ], [ %29, %arm9 ], [ %30, %arm10 ]
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Edeclared_dispatch"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed3 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %boxed3, ptr %3, ptr %4)
  %cmp4 = icmp ne ptr %11, null
  %not = xor i1 %cmp4, true
  br i1 %not, label %then, label %else

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %12 = call i64 @avra_array_get(ptr %5, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %12)
  call void @avra_array_push(ptr %7, i64 %13)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then:                                             ; preds = %lexit
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %14

else:                                             ; preds = %lexit
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %16 = call ptr @avra_insist(ptr %11)
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %17)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Emethod_symbol"(ptr %0, ptr %16, ptr %17, ptr %18)
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 %6)
  %21 = call ptr @avra_array_concat(ptr %20, ptr %7)
  %22 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %22, i64 18)
  call void @avra_array_push(ptr %22, i64 %15)
  call void @avra_array_push_owned(ptr %22, ptr %19)
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %15

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Efielded_dispatch"(ptr %0, i64 %1, i64 %2, i64 %3, ptr %4, ptr %5) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %6, i64 %3, ptr %4)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecalled_through"(ptr %0, i64 %1, i64 %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %11 = call i64 @avra_array_get(ptr %5, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %11)
  call void @avra_array_push(ptr %8, i64 %12)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Edyn_dispatch"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot12 = alloca i64, align 8
  %slot2 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 -1, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_method_names"(ptr %boxed1, ptr %3)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot, align 8
  %cmp7 = icmp slt i64 %ld6, 0
  br i1 %cmp7, label %then8, label %else9

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot2, align 8
  %10 = call i64 @avra_array_get(ptr %8, i64 %ld3)
  %boxed4 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_streq(ptr %boxed4, ptr %4)
  %b = icmp ne i64 %11, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i64 %ld3, ptr %slot, align 8
  store i64 %9, ptr %slot2, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld5 = load i64, ptr %slot2, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot2, align 8
  br label %lhead

then8:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else9:                                            ; preds = %lexit
  br label %endif10

endif10:                                          ; preds = %else9, %postret
  %regval11 = phi i64 [ 0, %postret ], [ 0, %else9 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot12, align 8
  br label %lhead13

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif10

lhead13:                                          ; preds = %lbody17, %endif10
  %ld15 = load i64, ptr %slot12, align 8
  %cmp16 = icmp slt i64 %ld15, %15
  br i1 %cmp16, label %lbody17, label %lexit14

lexit14:                                          ; preds = %lhead13
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %13, i64 0, ptr %16)
  %add21 = add i64 1, %ld6
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %13, i64 %add21, ptr null)
  call void @avra_rc_retain(ptr %0)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 %17)
  %21 = call ptr @avra_array_concat(ptr %20, ptr %14)
  %22 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %22, i64 19)
  call void @avra_array_push(ptr %22, i64 %19)
  call void @avra_array_push(ptr %22, i64 %18)
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %19

lbody17:                                          ; preds = %lhead13
  %ld18 = load i64, ptr %slot12, align 8
  %24 = call i64 @avra_array_get(ptr %5, i64 %ld18)
  call void @avra_rc_retain(ptr %0)
  %25 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %24)
  call void @avra_array_push(ptr %14, i64 %25)
  %ld19 = load i64, ptr %slot12, align 8
  %add20 = add i64 %ld19, 1
  store i64 %add20, ptr %slot12, align 8
  br label %lhead13
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estatic_dispatch"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot = alloca i64, align 8
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Emethod_symbol"(ptr %0, ptr %2, ptr %7, ptr %8)
  %10 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %10, i64 18)
  call void @avra_array_push(ptr %10, i64 %6)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_array_push_owned(ptr %10, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %12 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %12)
  call void @avra_array_push(ptr %4, i64 %13)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuilt_variant"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %2)
  %7 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %6, ptr %2)
  %x = extractvalue { i1, i64 } %7, 0
  %not1 = xor i1 %x, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  br label %endif

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %8 = call i64 @avra_array_len(ptr %3)
  %cmp5 = icmp eq i64 %8, 0
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else8:                                            ; preds = %endif4
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif9

lhead:                                            ; preds = %lbody, %endif9
  %ld = load i64, ptr %slot, align 8
  %cmp12 = icmp slt i64 %ld, %11
  br i1 %cmp12, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %12 = call i64 @avra_array_len(ptr %10)
  %add15 = add i64 1, %12
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %add15)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %x16 = extractvalue { i1, i64 } %7, 0
  %x17 = extractvalue { i1, i64 } %7, 1
  %slot18 = zext i1 %x16 to i64
  %15 = call i64 @avra_insist_scalar(i64 %slot18, i64 %x17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etagged_value"(ptr %0, i64 %14, i64 %13, i64 %15, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %14

lbody:                                            ; preds = %lhead
  %ld13 = load i64, ptr %slot, align 8
  %17 = call i64 @avra_array_get(ptr %3, i64 %ld13)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %17)
  call void @avra_array_push(ptr %10, i64 %18)
  %ld14 = load i64, ptr %slot, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ecallee_of"(ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ereceiver_reg"(ptr %0, i64 %1) {
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

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Edef_reg"(ptr, i64)
