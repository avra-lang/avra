; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"type.interp_hole\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"an interpolation hole prints as a scalar or string, found `\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [47 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 46 }, [47 x i8] c"interpolate an element or the `length` instead\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"is_empty\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"trim\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"char_code\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"replace\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"split\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"substring\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"index_of\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"ends_with\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"starts_with\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"contains\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseen_at"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Einterp_type"(ptr %0, ptr %1) {
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
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %5, ptr %slot1, align 8
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseen_at"(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %6)
  %7 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Eprintable"(ptr %6)
  %not = xor i1 %7, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %ld4)
  %ld5 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %ld5)
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %10, ptr %8)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %11 = call ptr @avra_str_join(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %8)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %8)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %13 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %9, ptr %11, ptr %12, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %8)
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Eprintable"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %2, 1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp5 = icmp eq i64 %3, 2
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp10 = icmp eq i64 %4, 3
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp15 = icmp eq i64 %5, 22
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval20 = phi i1 [ true, %then17 ], [ false, %else18 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval20
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_str_length$24w"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_str_length"(ptr %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_is_empty$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_is_empty"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_trim$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_trim"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_char_code$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_char_code"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_replace$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_replace"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_split$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_split"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_substring$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_substring"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_index_of$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_index_of"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_ends_with$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_ends_with"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_starts_with$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_starts_with"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_contains$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_contains"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Eon_str$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Eon_str"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_str_length"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_is_empty"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr, ptr, ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_trim"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16), ptr %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_char_code"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 0)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr %7, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_replace"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 3)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_split"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %4)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 10)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr %3, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_substring"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16), ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_index_of"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16), ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_ends_with"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16), ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_starts_with"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16), ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Echeck_contains"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16), ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Eon_str"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 3
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}
