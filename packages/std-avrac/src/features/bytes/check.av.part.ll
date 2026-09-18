; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"ieq_at\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"eq_at\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"run\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"is_empty\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"index_of\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"concat\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"slice\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"at\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"text\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"bytes\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.mismatch\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [58 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 57 }, [58 x i8] c"`bytes` reads a `List<int>` or a `List<Bytes>`, this is `\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [53 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 52 }, [53 x i8] c"an element is one byte, 0..255, or a Bytes to gather\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"bytes\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr, ptr, ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr, ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_length$24w"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_length"(ptr %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_ieq_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_ieq_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_eq_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_eq_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_run$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_run"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_is_empty$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_is_empty"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_index_of$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_index_of"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_concat$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_concat"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_slice$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_slice"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_text$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_text"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_list$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_list"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_ints$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_ints"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_str$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_str"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_str$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_str"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_length"(ptr %0, i64 %1, ptr %2) {
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_ieq_at"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 4)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_array_push_owned(ptr %5, ptr %3)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %5, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_eq_at"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 4)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_array_push_owned(ptr %5, ptr %3)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr %5, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_run"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 4)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_is_empty"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16), ptr %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_index_of"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 4)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16), ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_concat"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 4)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_slice"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16), ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_at"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_text"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %3)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 16)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr %2, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 4
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Egathers"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 10, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %boxed)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp = icmp eq i64 %6, 4
  call void @avra_rc_release(ptr %5)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi i1 [ %cmp, %arm ], [ false, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_list"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr %2)
  %not = xor i1 %3, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call i64 @avra_array_get(ptr %5, i64 5)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %7)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %8)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Egathers"(ptr %boxed, ptr %8)
  br i1 %9, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

then1:                                            ; preds = %endif
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed4 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed4, i64 5)
  %boxed5 = inttoptr i64 %11 to ptr
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 4)
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed5, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else2 ]
  %14 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eint_elements"(ptr %0, ptr %15)
  %not8 = xor i1 %16, true
  br i1 %not8, label %then9, label %else10

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  br label %endif3

then9:                                            ; preds = %endif3
  %17 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Enot_octets"(ptr %0, i64 %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

else10:                                           ; preds = %endif3
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 4)
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %20, i64 7)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %21

postret12:                                        ; No predecessors!
  call void @avra_rc_release(ptr %18)
  br label %endif11
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Enot_octets"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr %2)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16), ptr %3, ptr %5, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eint_elements"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm3 [
    i64 10, label %arm
    i64 18, label %arm2
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed4 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed5 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed5, i64 5)
  %boxed6 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %boxed4)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed6, ptr %boxed4)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %cmp = icmp eq i64 %10, 0
  call void @avra_rc_release(ptr %9)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm
  %regval = phi i1 [ %cmp, %arm ], [ true, %arm2 ], [ false, %arm3 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_ints"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 10
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %2, 18
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_str"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eworded"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16), ptr %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_str"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 3
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}
