; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_ieq_at\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_bytes_eq_at\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_bytes_run\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_index_of\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_concat\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_bytes_slice\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_bytes_at\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_str_of_bytes\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_gathered\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"avra_bytes_of_list\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_of_str\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr, ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_ieq_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_ieq_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_eq_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_eq_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_run$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_run"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_index_of$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_index_of"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_concat$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_concat"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_slice$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_slice"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_text$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_text"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_list$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_list"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_str$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_str"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_ieq_at"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_eq_at"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_run"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_index_of"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_concat"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_slice"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_at"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_text"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_list"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %5)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Egathers"(ptr %boxed, ptr %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.8, i64 16), %then ], [ getelementptr inbounds (i8, ptr @.str.9, i64 16), %else ]
  %7 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr %regval, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Egathers"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_str"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}
