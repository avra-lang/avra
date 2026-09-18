; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"this place\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"this place\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"a slot of \00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.mismatch\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"assignment changes \00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c": `\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"` to `\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"this binding\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr, i64, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_root"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_type_value"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Echeck_assign"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr %boxed3, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp4 = icmp ne ptr %7, null
  %not5 = xor i1 %cmp4, true
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not5, %else ]
  br i1 %regval, label %then6, label %else7

then6:                                            ; preds = %endif
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else7:                                            ; preds = %endif
  br label %endif8

endif8:                                           ; preds = %else7, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else7 ]
  %8 = call ptr @avra_insist(ptr %4)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %10 = call ptr @avra_insist(ptr %7)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %13)
  br i1 %14, label %then10, label %else11

postret:                                          ; No predecessors!
  br label %endif8

then10:                                           ; preds = %endif8
  br label %endif12

else11:                                           ; preds = %endif8
  call void @avra_rc_retain(ptr %0)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eplace_lawful"(ptr %0, i64 %11)
  %not13 = xor i1 %15, true
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i1 [ true, %then10 ], [ %not13, %else11 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif12
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %9)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else16:                                           ; preds = %endif12
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %9, ptr %13)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %9, ptr %13)
  %not20 = xor i1 %19, true
  br i1 %not20, label %then21, label %else22

postret18:                                        ; No predecessors!
  br label %endif17

then21:                                           ; preds = %endif17
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Eslot_refused"(ptr %0, i64 %1, i64 %11, ptr %13, i64 %9)
  br label %endif23

else22:                                           ; preds = %endif17
  br label %endif23

endif23:                                          ; preds = %else22, %then21
  %regval24 = phi i64 [ 0, %then21 ], [ 0, %else22 ]
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Eslot_refused"(ptr %0, i64 %1, i64 %2, ptr %3, i64 %4) {
entry:
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call i64 @avra_array_get(ptr %5, i64 5)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed, ptr %7)
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_root"(ptr %boxed2, i64 %2)
  %cmp = icmp ne ptr %11, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed3 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed3, i64 1)
  %boxed4 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %boxed4)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr %boxed4, i64 %14)
  %cmp5 = icmp ne ptr %15, null
  br i1 %cmp5, label %then6, label %else7

endif:                                            ; preds = %endif8, %then
  %regval9 = phi ptr [ getelementptr inbounds (i8, ptr @.str, i64 16), %then ], [ %20, %endif8 ]
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed10 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed10, i64 1)
  %boxed11 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed11)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr %boxed11, i64 %2)
  %cmp12 = icmp ne ptr %18, null
  %not13 = xor i1 %cmp12, true
  br i1 %not13, label %then14, label %else15

then6:                                            ; preds = %else
  call void @avra_rc_retain(ptr %15)
  br label %endif8

else7:                                            ; preds = %else
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval = phi ptr [ %15, %then6 ], [ getelementptr inbounds (i8, ptr @.str.2, i64 16), %else7 ]
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %19, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %19, ptr %regval)
  call void @avra_array_push_owned(ptr %19, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %20 = call ptr @avra_str_join(ptr %19, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif

then14:                                           ; preds = %endif
  %21 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %21, ptr %regval9)
  call void @avra_array_push_owned(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %22 = call ptr @avra_str_join(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif16

else15:                                           ; preds = %endif
  call void @avra_rc_retain(ptr %regval9)
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi ptr [ %22, %then14 ], [ %regval9, %else15 ]
  call void @avra_rc_retain(ptr %0)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  %24 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed18 = inttoptr i64 %24 to ptr
  %25 = call i64 @avra_array_get(ptr %boxed18, i64 5)
  %boxed19 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %boxed19)
  call void @avra_rc_retain(ptr %3)
  %26 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed19, ptr %3)
  %27 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_array_push_owned(ptr %27, ptr %regval17)
  call void @avra_array_push_owned(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %27, ptr %26)
  call void @avra_array_push_owned(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %27, ptr %8)
  call void @avra_array_push_owned(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %28 = call ptr @avra_str_join(ptr %27, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr %8)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %8)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr %23)
  call void @avra_rc_retain(ptr %28)
  call void @avra_rc_retain(ptr %29)
  %30 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr %23, ptr %28, ptr %29, ptr null)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %30)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %30)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %31
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eplace_lawful"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edeclared_binding"(ptr, i64, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_void_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Echeck_mut"(ptr %0, i64 %1) {
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
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %boxed3, i64 %1)
  %cmp4 = icmp ne ptr %9, null
  %not5 = xor i1 %cmp4, true
  br i1 %not5, label %then6, label %else7

postret:                                          ; No predecessors!
  br label %endif

then6:                                            ; preds = %endif
  br label %endif8

else7:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr %0, i64 %1, ptr %9)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ null, %then6 ], [ %10, %else7 ]
  %cmp10 = icmp ne ptr %regval9, null
  br i1 %cmp10, label %then11, label %else12

then11:                                           ; preds = %endif8
  %11 = call ptr @avra_insist(ptr %regval9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %6, ptr %11)
  call void @avra_rc_release(ptr %11)
  br label %endif13

else12:                                           ; preds = %endif8
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %6)
  call void @avra_rc_retain(ptr %0)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_type_value"(ptr %0, i64 %6)
  br i1 %14, label %then15, label %else16

then15:                                           ; preds = %endif13
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else16:                                           ; preds = %endif13
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  call void @avra_rc_retain(ptr %0)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_void_value"(ptr %0, i64 %6)
  br i1 %15, label %then20, label %else21

postret18:                                        ; No predecessors!
  br label %endif17

then20:                                           ; preds = %endif17
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else21:                                           ; preds = %endif17
  br label %endif22

endif22:                                          ; preds = %else21, %postret23
  %regval24 = phi i64 [ 0, %postret23 ], [ 0, %else21 ]
  %cmp25 = icmp ne ptr %regval9, null
  br i1 %cmp25, label %then26, label %else27

postret23:                                        ; No predecessors!
  br label %endif22

then26:                                           ; preds = %endif22
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed29 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed29, i64 1)
  %boxed30 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed30)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %boxed30, i64 %1)
  %cmp31 = icmp ne ptr %18, null
  br i1 %cmp31, label %then32, label %else33

else27:                                           ; preds = %endif22
  br label %endif28

endif28:                                          ; preds = %else27, %endif34
  %regval36 = phi i64 [ 0, %endif34 ], [ 0, %else27 ]
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

then32:                                           ; preds = %then26
  call void @avra_rc_retain(ptr %18)
  br label %endif34

else33:                                           ; preds = %then26
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval35 = phi ptr [ %18, %then32 ], [ getelementptr inbounds (i8, ptr @.str.14, i64 16), %else33 ]
  %19 = call ptr @avra_insist(ptr %regval9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval35)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edeclared_binding"(ptr %0, i64 %6, ptr %regval35, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %regval35)
  call void @avra_rc_release(ptr %18)
  br label %endif28
}
