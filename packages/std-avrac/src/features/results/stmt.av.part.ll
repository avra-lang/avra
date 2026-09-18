; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"a `fail` without an enclosing fn survived typing\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"type.fail\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [57 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 56 }, [57 x i8] c"a `fail` raises to a caller, and there is none enclosing\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"raised here\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"at the top level there is no failure channel\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"type.fail\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [72 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 71 }, [72 x i8] c"`fail` raises on a `Result`'s failure channel, and this fn promises a `\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"raised here\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"declare the answer fallible \E2\80\94 `-> Result<\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c", E>`\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"type.fail\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"`fail` raises a `\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"`, this is `\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr, i64, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewalk_value"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Ewalk_value"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Elower_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower_fail"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Elower_fail"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_value"(ptr %0, i64 %1)
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
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eenclosing_ret"(ptr %0)
  %cmp1 = icmp ne ptr %3, null
  %not2 = xor i1 %cmp1, true
  br i1 %not2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call ptr @avra_insist(ptr %2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efailed"(ptr %0, ptr %5, i64 %7)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr %0)
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 21)
  call void @avra_array_push(ptr %10, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif5
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efailed"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eenclosing_ret"(ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Etype_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewalk_value"(ptr %1, i64 %2)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Echeck_fail"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Echeck_fail"(ptr %0, i64 %1) {
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
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr %0)
  %cmp2 = icmp ne ptr %7, null
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %9 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr %8, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr getelementptr inbounds (i8, ptr @.str.3, i64 16), ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %11 = call ptr @avra_insist(ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %11)
  br i1 %12, label %then9, label %else10

postret7:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif6

then9:                                            ; preds = %endif6
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else10:                                           ; preds = %endif6
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed14 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed14, i64 5)
  %boxed15 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed15)
  call void @avra_rc_retain(ptr %11)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed15, ptr %11)
  %cmp16 = icmp ne ptr %15, null
  %not17 = xor i1 %cmp16, true
  br i1 %not17, label %then18, label %else19

postret12:                                        ; No predecessors!
  br label %endif11

then18:                                           ; preds = %endif11
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed21 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed21, i64 5)
  %boxed22 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed22)
  call void @avra_rc_retain(ptr %11)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed22, ptr %11)
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  %20 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %20, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %20, ptr %18)
  call void @avra_array_push_owned(ptr %20, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  %21 = call ptr @avra_str_join(ptr %20, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %22 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr %18)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %23 = call ptr @avra_str_join(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %19)
  call void @avra_rc_retain(ptr %21)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %23)
  %24 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %19, ptr %21, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr %23)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %24)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %24)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else19:                                           ; preds = %endif11
  br label %endif20

endif20:                                          ; preds = %else19, %postret23
  %regval24 = phi i64 [ 0, %postret23 ], [ 0, %else19 ]
  call void @avra_rc_retain(ptr %0)
  %26 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %6)
  br i1 %26, label %then25, label %else26

postret23:                                        ; No predecessors!
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %18)
  br label %endif20

then25:                                           ; preds = %endif20
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else26:                                           ; preds = %endif20
  br label %endif27

endif27:                                          ; preds = %else26, %postret28
  %regval29 = phi i64 [ 0, %postret28 ], [ 0, %else26 ]
  %27 = call ptr @avra_insist(ptr %15)
  %28 = call i64 @avra_array_get(ptr %27, i64 1)
  %boxed30 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed30)
  %29 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %6, ptr %boxed30)
  br i1 %29, label %then31, label %else32

postret28:                                        ; No predecessors!
  br label %endif27

then31:                                           ; preds = %endif27
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else32:                                           ; preds = %endif27
  br label %endif33

endif33:                                          ; preds = %else32, %postret34
  %regval35 = phi i64 [ 0, %postret34 ], [ 0, %else32 ]
  call void @avra_rc_retain(ptr %0)
  %30 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %6)
  call void @avra_rc_retain(ptr %0)
  %31 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  %32 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed36 = inttoptr i64 %32 to ptr
  %33 = call i64 @avra_array_get(ptr %boxed36, i64 5)
  %boxed37 = inttoptr i64 %33 to ptr
  %34 = call ptr @avra_insist(ptr %15)
  %35 = call i64 @avra_array_get(ptr %34, i64 1)
  %boxed38 = inttoptr i64 %35 to ptr
  call void @avra_rc_retain(ptr %boxed37)
  call void @avra_rc_retain(ptr %boxed38)
  %36 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed37, ptr %boxed38)
  %37 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_array_push_owned(ptr %37, ptr %36)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_array_push_owned(ptr %37, ptr %30)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  %38 = call ptr @avra_str_join(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_retain(ptr %30)
  %39 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %30)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr %31)
  call void @avra_rc_retain(ptr %38)
  call void @avra_rc_retain(ptr %39)
  %40 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16), ptr %31, ptr %38, ptr %39, ptr null)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %40)
  %41 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %40)
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %41

postret34:                                        ; No predecessors!
  br label %endif33
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2EFailSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Ewalk_value"(ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}
