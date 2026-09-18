; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"an `if` condition\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [24 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 23 }, [24 x i8] c"this decides the branch\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.mismatch\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [31 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 30 }, [31 x i8] c"an `if`'s branches disagree: `\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"` vs `\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr, i64, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etypes_disagree"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erequire_bool"(ptr, i64, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ejoin_of"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Eif_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 14, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call i64 @avra_array_get(ptr %4, i64 2)
  %8 = call i64 @avra_array_get(ptr %4, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erequire_bool"(ptr %0, i64 %6, ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Ewalk_branches"(ptr %0, i64 %6, i64 %7, i64 %8)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Ebranch_type"(ptr %0, i64 %7, i64 %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endswitch

arm2:                                             ; preds = %entry
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ %11, %arm ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Ebranch_type"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %2)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %4, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ejoin_of"(ptr %0, ptr %6, ptr %7)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then5, label %else6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif3

then5:                                            ; preds = %endif3
  %9 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %1, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %11 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %2, ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else6:                                            ; preds = %endif3
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %13)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etypes_disagree"(ptr %0, ptr %12, ptr %13)
  br i1 %14, label %then10, label %else11

postret8:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif7

then10:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  %18 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %15)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %19 = call ptr @avra_str_join(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %15)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %15)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %19)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %16, ptr %19, ptr %20, ptr null)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %21)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret ptr %22

else11:                                           ; preds = %endif7
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  call void @avra_rc_retain(ptr %0)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

postret13:                                        ; No predecessors!
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %15)
  br label %endif12
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Ewalk_branches"(ptr %0, i64 %1, i64 %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eask_of"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %3)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 1)
  %b = icmp ne i64 %8, 0
  br i1 %b, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  br label %endif

then1:                                            ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %7, i64 0)
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_narrowed"(ptr %0, i64 %9, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %3)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %2)
  %13 = call i64 @avra_array_get(ptr %7, i64 0)
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_narrowed"(ptr %0, i64 %13, i64 %3)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif3
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_narrowed"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eask_of"(ptr, i64)
