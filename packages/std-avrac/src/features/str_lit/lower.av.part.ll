; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_str_join\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_str_trim\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"avra_str_char_code\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"avra_str_char_code\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_str_replace\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_str_split\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"avra_str_substring\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_str_index_of\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"avra_str_ends_with\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"avra_str_starts_with\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_str_contains\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_str"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Einterp_reg"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_str"(ptr %0, ptr %boxed)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld8 = load ptr, ptr %slot, align 8
  %8 = call i64 @avra_array_len(ptr %ld8)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %8)
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %10)
  %ld9 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld9)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %11, i64 %9, ptr %ld9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_str"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 %11)
  call void @avra_array_push(ptr %15, i64 %13)
  %16 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %16, i64 7)
  call void @avra_array_push(ptr %16, i64 %14)
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %16)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %14

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %18 = call i64 @avra_array_get(ptr %3, i64 %ld3)
  store i64 %18, ptr %slot2, align 8
  %19 = call ptr @avra_cell_unique(ptr %slot)
  %ld4 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etexted"(ptr %0, i64 %ld4)
  call void @avra_array_push(ptr %19, i64 %20)
  %21 = call ptr @avra_cell_unique(ptr %slot)
  %add = add i64 %ld3, 1
  %22 = call i64 @avra_array_get(ptr %2, i64 %add)
  %boxed5 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed5)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_str"(ptr %0, ptr %boxed5)
  call void @avra_array_push(ptr %21, i64 %23)
  %ld6 = load i64, ptr %slot1, align 8
  %add7 = add i64 %ld6, 1
  store i64 %add7, ptr %slot1, align 8
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etexted"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_trim$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_trim"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_char_code$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_char_code"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_replace$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_replace"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_split$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_split"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_substring$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_substring"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_index_of$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_index_of"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_ends_with$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_ends_with"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_starts_with$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_starts_with"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_contains$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_contains"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_trim"(ptr %0, ptr %1) {
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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr, ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_char_code"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %3, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16), ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16), ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_replace"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_split"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_substring"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_index_of"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_ends_with"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_starts_with"(ptr %0, ptr %1) {
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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Elower_contains"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ert_method"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16), ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}
