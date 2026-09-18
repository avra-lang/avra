; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [53 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 52 }, [53 x i8] c"a pattern that is no format reached the format binds\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [52 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 51 }, [52 x i8] c"a pattern that is no format reached the format test\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr, i1)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_binds"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm2 [
    i64 5, label %arm
  ]

arm:                                              ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %7, i64 2)
  %boxed3 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %4)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_binds"(ptr %1, i64 %2, ptr %boxed3, i64 %3, ptr %4)
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %12 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ %10, %arm ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_binds"(ptr, i64, ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_accepts"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm2 [
    i64 5, label %arm
  ]

arm:                                              ; preds = %entry
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  %10 = call i64 @avra_array_get(ptr %7, i64 2)
  %boxed3 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %4)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_accepts"(ptr %1, i64 %2, ptr %9, ptr %boxed3, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %9)
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ereached_wrongly"(ptr %1)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %11, %arm ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ereached_wrongly"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %1 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_accepts"(ptr, i64, ptr, ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2EFormatPatSemantics$2Epat_types"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm2 [
    i64 5, label %arm
  ]

arm:                                              ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %6, i64 2)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %3)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_types"(ptr %1, i64 %2, ptr %boxed3, ptr %3)
  br label %endswitch

arm2:                                             ; preds = %entry
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ %9, %arm ], [ %10, %arm2 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_types"(ptr, i64, ptr, ptr)
