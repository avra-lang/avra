; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_array_get\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [50 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 49 }, [50 x i8] c"a length on an unmeasurable shape survived typing\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 3)
  call void @avra_array_push(ptr %4, i64 %3)
  %slot = zext i1 %1 to i64
  call void @avra_array_push(ptr %4, i64 %slot)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push(ptr %4, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %1)
  %6 = call i64 @avra_array_get(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %6 to ptr
  %7 = call i64 %cast(ptr %3, ptr %0)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %7)
  %9 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %cast1 = inttoptr i64 %9 to ptr
  %10 = call i64 %cast1(ptr %4, ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %2, i64 %10)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 17)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 16)
  call void @avra_array_push(ptr %2, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 14)
  call void @avra_array_push(ptr %2, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_exit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_close"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_arm"(ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_enter"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 23)
  call void @avra_array_push(ptr %5, i64 %3)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 1)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 0)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %11, i64 4)
  call void @avra_array_push(ptr %11, i64 %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 %3)
  call void @avra_array_push(ptr %11, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %11)
  %13 = call i64 @avra_array_get(ptr %1, i64 2)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 24)
  call void @avra_array_push(ptr %14, i64 %13)
  call void @avra_array_push(ptr %14, i64 %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %14)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr %0)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %16
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr null)
  %1 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_exit"(ptr %0, ptr null)
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 27)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %boxed)
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %boxed1)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_array_push(ptr %8, i64 %2)
  %9 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %9, i64 7)
  call void @avra_array_push(ptr %9, i64 %4)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 23)
  call void @avra_array_push(ptr %5, i64 %3)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %3)
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 23)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 7)
  %11 = call i64 @avra_array_get(ptr %1, i64 1)
  %12 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %12, i64 4)
  call void @avra_array_push(ptr %12, i64 %9)
  call void @avra_array_push_owned(ptr %12, ptr %10)
  call void @avra_array_push(ptr %12, i64 %4)
  call void @avra_array_push(ptr %12, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %12)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr %0, i64 %9)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %14
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 26)
  call void @avra_array_push(ptr %2, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_enter"(ptr %0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 25)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasure_of"(ptr %0, i64 %1, i64 %3, ptr %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %6)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %7, i64 %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 %3)
  %11 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 %5)
  call void @avra_array_push(ptr %11, i64 %9)
  call void @avra_array_push_owned(ptr %11, ptr %2)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %1)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 22)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 24)
  call void @avra_array_push(ptr %6, i64 %3)
  call void @avra_array_push(ptr %6, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasure_of"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed1, ptr %3)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elength_word"(ptr %6)
  %cmp = icmp ne ptr %7, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunmeasurable"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %9)
  %11 = call ptr @avra_insist(ptr %7)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 %2)
  %13 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %13, i64 7)
  call void @avra_array_push(ptr %13, i64 %10)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunmeasurable"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elength_word"(ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_branches"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %1)
  %5 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %5 to ptr
  %6 = call i64 %cast(ptr %2, ptr %0)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_arm"(ptr %0)
  %8 = call i64 @avra_array_get(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %cast1 = inttoptr i64 %8 to ptr
  %9 = call i64 %cast1(ptr %3, ptr %0)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_close"(ptr %0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_str"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 2)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 17)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %1)
  %6 = call i64 @avra_array_get(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %6 to ptr
  %7 = call i64 %cast(ptr %3, ptr %0)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %7)
  %9 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %cast1 = inttoptr i64 %9 to ptr
  %10 = call i64 %cast1(ptr %4, ptr %0)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr %0, i64 %2, i64 %10)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ezero"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_array_push(ptr %3, i64 %2)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %1)
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %4 to ptr
  %5 = call i64 %cast(ptr %2, ptr %0)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_arm"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_close"(ptr %0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecounted"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %4, i64 %6)
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %8, ptr null)
  call void @avra_array_push(ptr %8, i64 %5)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_array_push_owned(ptr %8, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg$24w"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

entry1:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

entry2:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

entry3:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

entry1:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4

entry2:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasure_of"(ptr %0, i64 %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasured_zero"(ptr %0, i64 %2, i64 %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasured_zero"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasure_of"(ptr %0, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 5)
  %9 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %9, i64 4)
  call void @avra_array_push(ptr %9, i64 %7)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push(ptr %9, i64 %5)
  call void @avra_array_push(ptr %9, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 23)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eearly_exit"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 24)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}
