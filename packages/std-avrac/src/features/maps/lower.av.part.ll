; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"avra_map_new\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"avra_map_set\00" }, align 16

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

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Emap_reg"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot13 = alloca i64, align 8
  %slot12 = alloca i64, align 8
  %slot3 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot3, align 8
  br label %lhead4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %8)
  call void @avra_array_push(ptr %4, i64 %9)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead4:                                           ; preds = %lbody8, %lexit
  %ld6 = load i64, ptr %slot3, align 8
  %cmp7 = icmp slt i64 %ld6, %7
  br i1 %cmp7, label %lbody8, label %lexit5

lexit5:                                           ; preds = %lhead4
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %12, i64 7)
  call void @avra_array_push(ptr %12, i64 %10)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %12)
  %14 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot12, align 8
  br label %lhead14

lbody8:                                           ; preds = %lhead4
  %ld9 = load i64, ptr %slot3, align 8
  %15 = call i64 @avra_array_get(ptr %3, i64 %ld9)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %15)
  call void @avra_array_push(ptr %6, i64 %16)
  %ld10 = load i64, ptr %slot3, align 8
  %add11 = add i64 %ld10, 1
  store i64 %add11, ptr %slot3, align 8
  br label %lhead4

lhead14:                                          ; preds = %lbody18, %lexit5
  %ld16 = load i64, ptr %slot12, align 8
  %cmp17 = icmp slt i64 %ld16, %14
  br i1 %cmp17, label %lbody18, label %lexit15

lexit15:                                          ; preds = %lhead14
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

lbody18:                                          ; preds = %lhead14
  %ld19 = load i64, ptr %slot12, align 8
  %17 = call i64 @avra_array_get(ptr %4, i64 %ld19)
  store i64 %17, ptr %slot13, align 8
  %ld20 = load i64, ptr %slot13, align 8
  %18 = call i64 @avra_array_get(ptr %6, i64 %ld19)
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %19, i64 %10)
  call void @avra_array_push(ptr %19, i64 %ld20)
  call void @avra_array_push(ptr %19, i64 %18)
  %20 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %20, i64 6)
  call void @avra_array_push_owned(ptr %20, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %20)
  %ld21 = load i64, ptr %slot12, align 8
  %add22 = add i64 %ld21, 1
  store i64 %add22, ptr %slot12, align 8
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %lhead14
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)
