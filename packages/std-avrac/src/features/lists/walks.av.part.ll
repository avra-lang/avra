; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_str_join\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_array_slice\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_array_concat\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_array_get\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_slot_set\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_array_pop\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"a push without its value survived typing\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"avra_array_push\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"a row without its seat survived typing\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr, ptr, i1, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr, i1)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasure_of"(ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ezero"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr, ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_join$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_join"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_enumerate$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_enumerate"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_slice$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_slice"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_concat$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_concat"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_last$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_last"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_first$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_first"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_set$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_set"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_pop$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_pop"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_push$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_push"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_index_of$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_index_of"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_contains$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_contains"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_all$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_all"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_any$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_any"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_find$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_find"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_filter$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_filter"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_map$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_map"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_join"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_enumerate"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_slice"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_concat"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_last"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eedge"(ptr %0, ptr %1, i1 true)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eedge"(ptr %0, ptr %1, i1 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %3)
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eabsent_cell"(ptr %0, ptr %4)
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  %9 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %9)
  %11 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emeasure_of"(ptr %0, i64 %8, i64 %10, ptr %12)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %15)
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 7)
  %18 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %18, i64 4)
  call void @avra_array_push(ptr %18, i64 %16)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_array_push(ptr %18, i64 %14)
  call void @avra_array_push(ptr %18, i64 %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %18)
  %20 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %20, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l631" to i64))
  %slot = zext i1 %2 to i64
  call void @avra_array_push(ptr %20, i64 %slot)
  call void @avra_array_push(ptr %20, i64 %13)
  call void @avra_array_push(ptr %20, i64 %14)
  call void @avra_array_push_owned(ptr %20, ptr %4)
  call void @avra_array_push(ptr %20, i64 %6)
  call void @avra_array_push(ptr %20, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %16, ptr %20)
  %22 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr %0, i64 %22, i64 %7)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %23
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l631"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Edecremented"(ptr %1, i64 %3)
  br label %endif

else:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %4, %then ], [ %5, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr %1, ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %1, ptr %7)
  %9 = call i64 @avra_array_get(ptr %0, i64 5)
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 %9)
  call void @avra_array_push(ptr %10, i64 %regval)
  %11 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %11, i64 7)
  call void @avra_array_push(ptr %11, i64 %8)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %1, ptr %11)
  %13 = call i64 @avra_array_get(ptr %0, i64 6)
  %14 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed1)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %1, ptr %boxed1, i1 false, i64 %8)
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 24)
  call void @avra_array_push(ptr %16, i64 %13)
  call void @avra_array_push(ptr %16, i64 %15)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %1, ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %17
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Edecremented"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 1)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 1)
  %6 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %6, i64 4)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 %1)
  call void @avra_array_push(ptr %6, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr, i64, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eabsent_cell"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %1, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_first"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eedge"(ptr %0, ptr %1, i1 false)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_set"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %5)
  %7 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %8)
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 %3)
  call void @avra_array_push(ptr %10, i64 %6)
  call void @avra_array_push(ptr %10, i64 %9)
  %11 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %11, i64 6)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %11)
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Enothing_reg"(ptr %0, i64 %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %14
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Enothing_reg"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ezero"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_pop"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %3)
  %7 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %7, i64 7)
  call void @avra_array_push(ptr %7, i64 %5)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_push"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 0, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %ld, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

then2:                                            ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %6, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eunique_box"(ptr %0, i64 %8)
  %10 = call ptr @avra_insist(ptr %ld)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %11)
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 %9)
  call void @avra_array_push(ptr %13, i64 %12)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 6)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %14)
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Enothing_reg"(ptr %0, i64 %16)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_index_of"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eposition"(ptr %0, ptr %1, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eposition"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 -1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %4, i64 %5)
  %7 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %7)
  %9 = call i64 @avra_array_get(ptr %1, i64 1)
  %10 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %9, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %11, i64 %13)
  %15 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed1 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr %0, i64 %14, i64 %8, ptr %boxed1)
  %17 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l547" to i64))
  call void @avra_array_push(ptr %17, i64 %6)
  call void @avra_array_push(ptr %17, i64 %13)
  call void @avra_array_push_owned(ptr %17, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %16, ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %11)
  %20 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr %0, i64 %20, i64 %6)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %21
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l547"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 24)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %1, ptr %4)
  %6 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eearly_exit"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eearly_exit"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %2, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed, ptr %5)
  %7 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %8 = call i64 @avra_array_len(ptr %7)
  %cmp = icmp slt i64 0, %8
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %7, i64 0)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 %9)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot)
  store ptr %10, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %6, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %cmp5 = icmp ne ptr %ld, null
  %not6 = xor i1 %cmp5, true
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval7 = phi i1 [ true, %then2 ], [ %not6, %else3 ]
  br i1 %regval7, label %then8, label %else9

then8:                                            ; preds = %endif4
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret
  %regval11 = phi i64 [ 0, %postret ], [ 0, %else9 ]
  %11 = call ptr @avra_insist(ptr %6)
  %12 = call ptr @avra_insist(ptr %ld)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %14, ptr %11)
  call void @avra_array_push(ptr %14, i64 %13)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret:                                          ; No predecessors!
  br label %endif10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_contains"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eheld"(ptr %0, ptr %1, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eheld"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_cell"(ptr %0, i1 false)
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %4)
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  %7 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %6, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %8, i64 %10)
  %12 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed1 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr %0, i64 %11, i64 %5, ptr %boxed1)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l489" to i64))
  call void @avra_array_push(ptr %14, i64 %3)
  call void @avra_array_push_owned(ptr %14, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %13, ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %8)
  %17 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr %0, i64 %17, i64 %3)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %18
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l489"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Estore_bool"(ptr %1, i64 %2, i1 true)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eearly_exit"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Estore_bool"(ptr %0, i64 %1, i1 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 24)
  call void @avra_array_push(ptr %4, i64 %1)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_cell"(ptr %0, i1 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_ty"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %2, i64 %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_ty"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_all"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ejudged"(ptr %0, ptr %1, ptr %4, i1 true)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ejudged"(ptr %0, ptr %1, ptr %2, i1 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_cell"(ptr %0, i1 %3)
  %5 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eboxed"(ptr %0, i64 %5)
  %7 = call i64 @avra_array_get(ptr %1, i64 1)
  %8 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %7, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %9, i64 %11)
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_ty"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eturn_call"(ptr %0, ptr %6, i64 %12, ptr %13)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eflipping"(ptr %0, i64 %14, i1 %3)
  %16 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %16, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l440" to i64))
  call void @avra_array_push(ptr %16, i64 %4)
  %slot = zext i1 %3 to i64
  call void @avra_array_push(ptr %16, i64 %slot)
  call void @avra_array_push_owned(ptr %16, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %15, ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %9)
  %19 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr %0, i64 %19, i64 %4)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %20
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l440"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %b = icmp ne i64 %3, 0
  %not = xor i1 %b, true
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Estore_bool"(ptr %1, i64 %2, i1 %not)
  %5 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eearly_exit"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eflipping"(ptr %0, i64 %1, i1 %2) {
entry:
  %not = xor i1 %2, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i64 %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  %6 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %6, i64 5)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %4

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eturn_call"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %3)
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 %6)
  call void @avra_array_push(ptr %7, i64 %2)
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %8, i64 19)
  call void @avra_array_push(ptr %8, i64 %4)
  call void @avra_array_push(ptr %8, i64 %5)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eboxed"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %2, i64 0, ptr null)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 %2)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_any"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ejudged"(ptr %0, ptr %1, ptr %4, i1 false)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_find"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Efound"(ptr %0, ptr %1, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Efound"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eabsent_cell"(ptr %0, ptr %4)
  %6 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eboxed"(ptr %0, i64 %6)
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  %9 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %8, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %10, i64 %12)
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_ty"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eturn_call"(ptr %0, ptr %7, i64 %13, ptr %14)
  %16 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %16, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l386" to i64))
  call void @avra_array_push(ptr %16, i64 %5)
  call void @avra_array_push_owned(ptr %16, ptr %4)
  call void @avra_array_push(ptr %16, i64 %13)
  call void @avra_array_push_owned(ptr %16, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %15, ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %10)
  %19 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloaded"(ptr %0, i64 %19, i64 %5)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %20
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l386"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %1, ptr %3, i1 false, i64 %4)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 24)
  call void @avra_array_push(ptr %6, i64 %2)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %1, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eearly_exit"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %9
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_filter"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ekept"(ptr %0, ptr %1, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ekept"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %4)
  %6 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %5, i64 %3, ptr %6)
  %8 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eboxed"(ptr %0, i64 %8)
  %10 = call i64 @avra_array_get(ptr %1, i64 1)
  %11 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %10, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %12, i64 %14)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ebool_ty"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eturn_call"(ptr %0, ptr %9, i64 %15, ptr %16)
  %18 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %18, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l331" to i64))
  call void @avra_array_push(ptr %18, i64 %5)
  call void @avra_array_push(ptr %18, i64 %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %17, ptr %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ewalks$24l331"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %1, i64 %2, i64 %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower_map"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseat_of"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eseatless"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Emapped"(ptr %0, ptr %1, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Emapped"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %4)
  %6 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %5, i64 %3, ptr %6)
  %8 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eboxed"(ptr %0, i64 %8)
  %10 = call i64 @avra_array_get(ptr %1, i64 1)
  %11 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %10, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %12, i64 %14)
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Emapped_to"(ptr %0, i64 %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eturn_call"(ptr %0, ptr %9, i64 %15, ptr %17)
  call void @avra_rc_retain(ptr %0)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %5, i64 %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Emapped_to"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}
