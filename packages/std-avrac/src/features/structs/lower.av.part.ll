; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"a `with` on a non-struct survived typing\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_array_sized\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"a literal missing a field without a default survived typing\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"a field-less literal survived typing\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_array_sized\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eviewed"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Esymbol_at"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2482"(i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eflat_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr, i64, ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs_reg"(ptr %0, i64 %1) {
entry:
  %slot7 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm3 [
    i64 18, label %arm
    i64 19, label %arm2
  ]

arm:                                              ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm2:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %4, i64 1)
  %11 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %12 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call i64 @avra_array_len(ptr %11)
  store i64 0, ptr %slot7, align 8
  br label %lhead8

arm3:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %lexit9, %lexit
  %regval = phi i64 [ %16, %lexit ], [ %18, %lexit9 ], [ %15, %arm3 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %7)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Elit_reg"(ptr %0, i64 %1, ptr %8, ptr %7)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %17 = call i64 @avra_array_get(ptr %6, i64 %ld4)
  %boxed5 = inttoptr i64 %17 to ptr
  call void @avra_array_push_owned(ptr %8, ptr %boxed5)
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead8:                                           ; preds = %lbody12, %arm2
  %ld10 = load i64, ptr %slot7, align 8
  %cmp11 = icmp slt i64 %ld10, %14
  br i1 %cmp11, label %lbody12, label %lexit9

lexit9:                                           ; preds = %lhead8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %12)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ewith_reg"(ptr %0, i64 %1, i64 %10, ptr %13, ptr %12)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

lbody12:                                          ; preds = %lhead8
  %ld13 = load i64, ptr %slot7, align 8
  %19 = call i64 @avra_array_get(ptr %11, i64 %ld13)
  %boxed14 = inttoptr i64 %19 to ptr
  call void @avra_array_push_owned(ptr %13, ptr %boxed14)
  %ld15 = load i64, ptr %slot7, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot7, align 8
  br label %lhead8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Ewith_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4) {
entry:
  %slot47 = alloca ptr, align 8
  store ptr null, ptr %slot47, align 8
  %slot46 = alloca i64, align 8
  %slot15 = alloca i64, align 8
  %slot13 = alloca i64, align 8
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
  %slot4 = alloca ptr, align 8
  store ptr null, ptr %slot4, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_at"(ptr %0, i64 %1)
  %cmp3 = icmp ne ptr %8, null
  %not = xor i1 %cmp3, true
  br i1 %not, label %then, label %else

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %9)
  call void @avra_array_push(ptr %6, i64 %10)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then:                                             ; preds = %lexit
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else:                                             ; preds = %lexit
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %13 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  %15 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %15)
  call void @avra_cell_release(ptr %slot4)
  store ptr %15, ptr %slot4, align 8
  %16 = call ptr @avra_array_get_owned(ptr %13, i64 0)
  %17 = call i64 @avra_array_len(ptr %16)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif

lhead7:                                           ; preds = %endif32, %endif
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %17
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  call void @avra_rc_retain(ptr %0)
  %18 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eflat_at"(ptr %0, i64 %1)
  br i1 %18, label %then38, label %else39

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %19 = call ptr @avra_array_get_owned(ptr %16, i64 %ld12)
  call void @avra_rc_retain(ptr %19)
  call void @avra_cell_release(ptr %slot6)
  store ptr %19, ptr %slot6, align 8
  store i64 -1, ptr %slot13, align 8
  %ld14 = load ptr, ptr %slot6, align 8
  call void @avra_rc_retain(ptr %ld14)
  %20 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot15, align 8
  br label %lhead16

lhead16:                                          ; preds = %endif24, %lbody11
  %ld18 = load i64, ptr %slot15, align 8
  %cmp19 = icmp slt i64 %ld18, %20
  br i1 %cmp19, label %lbody20, label %lexit17

lexit17:                                          ; preds = %lhead16
  %ld28 = load i64, ptr %slot13, align 8
  %cmp29 = icmp sge i64 %ld28, 0
  br i1 %cmp29, label %then30, label %else31

lbody20:                                          ; preds = %lhead16
  %ld21 = load i64, ptr %slot15, align 8
  %21 = call i64 @avra_array_get(ptr %3, i64 %ld21)
  %boxed = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_streq(ptr %boxed, ptr %ld14)
  %b = icmp ne i64 %22, 0
  br i1 %b, label %then22, label %else23

then22:                                           ; preds = %lbody20
  store i64 %ld21, ptr %slot13, align 8
  store i64 %20, ptr %slot15, align 8
  br label %endif24

else23:                                           ; preds = %lbody20
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval25 = phi i64 [ 0, %then22 ], [ 0, %else23 ]
  %ld26 = load i64, ptr %slot15, align 8
  %add27 = add i64 %ld26, 1
  store i64 %add27, ptr %slot15, align 8
  br label %lhead16

then30:                                           ; preds = %lexit17
  %23 = call ptr @avra_cell_unique(ptr %slot4)
  %24 = call i64 @avra_array_get(ptr %6, i64 %ld28)
  %25 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %25, i64 %24)
  call void @avra_array_push_owned(ptr %23, ptr %25)
  call void @avra_rc_release(ptr %25)
  br label %endif32

else31:                                           ; preds = %lexit17
  %26 = call ptr @avra_cell_unique(ptr %slot4)
  %27 = call i64 @avra_array_get(ptr %13, i64 1)
  %boxed33 = inttoptr i64 %27 to ptr
  %28 = call i64 @avra_array_get(ptr %boxed33, i64 %ld12)
  %boxed34 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %boxed34)
  %29 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr %0, i64 %5, ptr %14, i64 %ld12, ptr %boxed34)
  %30 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %30, i64 %29)
  call void @avra_array_push_owned(ptr %26, ptr %30)
  call void @avra_rc_release(ptr %30)
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval35 = phi i64 [ 0, %then30 ], [ 0, %else31 ]
  %ld36 = load i64, ptr %slot5, align 8
  %add37 = add i64 %ld36, 1
  store i64 %add37, ptr %slot5, align 8
  call void @avra_rc_release(ptr %ld14)
  call void @avra_rc_release(ptr %19)
  br label %lhead7

then38:                                           ; preds = %lexit8
  %ld41 = load ptr, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %ld41)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Epacked_lit"(ptr %0, i64 %1, ptr %13, ptr %ld41)
  call void @avra_cell_release(ptr %slot6)
  call void @avra_cell_release(ptr %slot4)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %31

else39:                                           ; preds = %lexit8
  br label %endif40

endif40:                                          ; preds = %else39, %postret42
  %regval43 = phi i64 [ 0, %postret42 ], [ 0, %else39 ]
  %ld44 = load ptr, ptr %slot4, align 8
  %32 = call i64 @avra_array_len(ptr %ld44)
  call void @avra_rc_retain(ptr %0)
  %33 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %32)
  call void @avra_rc_retain(ptr %0)
  %34 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %35 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %35, i64 %33)
  %36 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %36, i64 7)
  call void @avra_array_push(ptr %36, i64 %34)
  call void @avra_array_push_owned(ptr %36, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %36, ptr %35)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %36)
  %37 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %36)
  %ld45 = load ptr, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %ld45)
  %38 = call i64 @avra_array_len(ptr %ld45)
  store i64 0, ptr %slot46, align 8
  br label %lhead48

postret42:                                        ; No predecessors!
  br label %endif40

lhead48:                                          ; preds = %lbody52, %endif40
  %ld50 = load i64, ptr %slot46, align 8
  %cmp51 = icmp slt i64 %ld50, %38
  br i1 %cmp51, label %lbody52, label %lexit49

lexit49:                                          ; preds = %lhead48
  call void @avra_cell_release(ptr %slot47)
  call void @avra_cell_release(ptr %slot6)
  call void @avra_cell_release(ptr %slot4)
  call void @avra_rc_release(ptr %ld45)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %34

lbody52:                                          ; preds = %lhead48
  %ld53 = load i64, ptr %slot46, align 8
  %39 = call ptr @avra_array_get_owned(ptr %ld45, i64 %ld53)
  call void @avra_rc_retain(ptr %39)
  call void @avra_cell_release(ptr %slot47)
  store ptr %39, ptr %slot47, align 8
  %ld54 = load ptr, ptr %slot47, align 8
  %40 = call ptr @avra_insist(ptr %ld54)
  %41 = call i64 @avra_array_get(ptr %40, i64 0)
  call void @avra_rc_retain(ptr %0)
  %42 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %34, i64 %41)
  %ld55 = load i64, ptr %slot46, align 8
  %add56 = add i64 %ld55, 1
  store i64 %add56, ptr %slot46, align 8
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr %39)
  br label %lhead48
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Epacked_lit"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edefaulted_reg"(ptr %0, i64 %1, ptr %2, i64 0)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %5, %then ], [ %6, %else ]
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epacked"(ptr %0, i64 %1, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epacked"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edefaulted_reg"(ptr %0, i64 %1, ptr %2, i64 %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 %3)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 %3)
  %boxed1 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eviewed"(ptr %0, ptr %boxed1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %9)
  %11 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Esymbol_at"(ptr %0, ptr %11, i64 %1)
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %14, i64 18)
  call void @avra_array_push(ptr %14, i64 %10)
  call void @avra_array_push_owned(ptr %14, ptr %12)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Elit_reg"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot32 = alloca ptr, align 8
  store ptr null, ptr %slot32, align 8
  %slot31 = alloca i64, align 8
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
  %slot4 = alloca ptr, align 8
  store ptr null, ptr %slot4, align 8
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
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efields_at"(ptr %0, i64 %1)
  %cmp3 = icmp ne ptr %6, null
  %not = xor i1 %cmp3, true
  br i1 %not, label %then, label %else

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %7)
  call void @avra_array_push(ptr %4, i64 %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then:                                             ; preds = %lexit
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else:                                             ; preds = %lexit
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call ptr @avra_insist(ptr %6)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_len(ptr %boxed)
  call void @avra_rc_retain(ptr null)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2482"(i64 %12, ptr null)
  call void @avra_rc_retain(ptr %13)
  call void @avra_cell_release(ptr %slot4)
  store ptr %13, ptr %slot4, align 8
  %14 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif

lhead7:                                           ; preds = %endif16, %endif
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %14
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  call void @avra_rc_retain(ptr %0)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eflat_at"(ptr %0, i64 %1)
  br i1 %15, label %then23, label %else24

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %16 = call ptr @avra_array_get_owned(ptr %2, i64 %ld12)
  call void @avra_rc_retain(ptr %16)
  call void @avra_cell_release(ptr %slot6)
  store ptr %16, ptr %slot6, align 8
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %ld13)
  %17 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr %10, ptr %ld13)
  %x = extractvalue { i1, i64 } %17, 0
  br i1 %x, label %then14, label %else15

then14:                                           ; preds = %lbody11
  %18 = call i64 @avra_array_get(ptr %4, i64 %ld12)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 %18)
  %20 = call ptr @avra_cell_unique(ptr %slot4)
  %x17 = extractvalue { i1, i64 } %17, 0
  %x18 = extractvalue { i1, i64 } %17, 1
  %slot19 = zext i1 %x17 to i64
  %21 = call i64 @avra_insist_scalar(i64 %slot19, i64 %x18)
  call void @avra_slot_set_owned(ptr %20, i64 %21, ptr %19)
  call void @avra_rc_release(ptr %19)
  br label %endif16

else15:                                           ; preds = %lbody11
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval20 = phi i64 [ 0, %then14 ], [ 0, %else15 ]
  %ld21 = load i64, ptr %slot5, align 8
  %add22 = add i64 %ld21, 1
  store i64 %add22, ptr %slot5, align 8
  call void @avra_rc_release(ptr %16)
  br label %lhead7

then23:                                           ; preds = %lexit8
  %ld26 = load ptr, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %ld26)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Epacked_lit"(ptr %0, i64 %1, ptr %10, ptr %ld26)
  call void @avra_cell_release(ptr %slot6)
  call void @avra_cell_release(ptr %slot4)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %22

else24:                                           ; preds = %lexit8
  br label %endif25

endif25:                                          ; preds = %else24, %postret27
  %regval28 = phi i64 [ 0, %postret27 ], [ 0, %else24 ]
  %ld29 = load ptr, ptr %slot4, align 8
  %23 = call i64 @avra_array_len(ptr %ld29)
  call void @avra_rc_retain(ptr %0)
  %24 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %23)
  call void @avra_rc_retain(ptr %0)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %26 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %26, i64 %24)
  %27 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %27, i64 7)
  call void @avra_array_push(ptr %27, i64 %25)
  call void @avra_array_push_owned(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %27, ptr %26)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %27)
  %ld30 = load ptr, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %ld30)
  %29 = call i64 @avra_array_len(ptr %ld30)
  store i64 0, ptr %slot31, align 8
  br label %lhead33

postret27:                                        ; No predecessors!
  br label %endif25

lhead33:                                          ; preds = %endif43, %endif25
  %ld35 = load i64, ptr %slot31, align 8
  %cmp36 = icmp slt i64 %ld35, %29
  br i1 %cmp36, label %lbody37, label %lexit34

lexit34:                                          ; preds = %lhead33
  call void @avra_cell_release(ptr %slot32)
  call void @avra_cell_release(ptr %slot6)
  call void @avra_cell_release(ptr %slot4)
  call void @avra_rc_release(ptr %ld30)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %25

lbody37:                                          ; preds = %lhead33
  %ld38 = load i64, ptr %slot31, align 8
  %30 = call ptr @avra_array_get_owned(ptr %ld30, i64 %ld38)
  call void @avra_rc_retain(ptr %30)
  call void @avra_cell_release(ptr %slot32)
  store ptr %30, ptr %slot32, align 8
  %ld39 = load ptr, ptr %slot32, align 8
  %cmp40 = icmp ne ptr %ld39, null
  br i1 %cmp40, label %then41, label %else42

then41:                                           ; preds = %lbody37
  %ld44 = load ptr, ptr %slot32, align 8
  %31 = call ptr @avra_insist(ptr %ld44)
  %32 = call i64 @avra_array_get(ptr %31, i64 0)
  call void @avra_rc_retain(ptr %0)
  %33 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %25, i64 %32)
  call void @avra_rc_release(ptr %31)
  br label %endif43

else42:                                           ; preds = %lbody37
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %34 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Edefaulted_reg"(ptr %0, i64 %1, ptr %10, i64 %ld38)
  call void @avra_rc_retain(ptr %0)
  %35 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %25, i64 %34)
  br label %endif43

endif43:                                          ; preds = %else42, %then41
  %regval45 = phi i64 [ 0, %then41 ], [ 0, %else42 ]
  %ld46 = load i64, ptr %slot31, align 8
  %add47 = add i64 %ld46, 1
  store i64 %add47, ptr %slot31, align 8
  call void @avra_rc_release(ptr %30)
  br label %lhead33
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Elower_named_of$24w"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Elower_named_of"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Elower_named_of"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}
