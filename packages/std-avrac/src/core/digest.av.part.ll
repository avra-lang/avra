; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

define ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_of"(ptr %0) {
entry:
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enew_digest"()
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_text"(ptr %1, ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_key"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_key"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %2 = call ptr @avra_int_text(i64 %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %4 = call ptr @avra_int_text(i64 %3)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %6 = call ptr @avra_int_text(i64 %5)
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %8 = call ptr @avra_int_text(i64 %7)
  %9 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %2)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %10 = call ptr @avra_str_join(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %10
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_text"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_cell_release(ptr %slot)
  store ptr %0, ptr %slot, align 8
  %2 = call i64 @avra_str_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_int"(ptr %ld5, i64 %2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

lbody:                                            ; preds = %lhead
  %ld2 = load ptr, ptr %slot, align 8
  %ld3 = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_str_char_code(ptr %1, i64 %ld3)
  call void @avra_rc_retain(ptr %ld2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_int"(ptr %ld2, i64 %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_int"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %3 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %2, i64 %1, i64 1000000007)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %3, i64 %1, i64 1000000021)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %6 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %5, i64 %1, i64 1000000009)
  %7 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %6, i64 %1, i64 1000000033)
  %8 = call i64 @avra_array_get(ptr %0, i64 2)
  %9 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %8, i64 %1, i64 1000000021)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %9, i64 %1, i64 1000000007)
  %11 = call i64 @avra_array_get(ptr %0, i64 3)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %11, i64 %1, i64 1000000033)
  %13 = call i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %12, i64 %1, i64 1000000009)
  %14 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %14, i64 %4)
  call void @avra_array_push(ptr %14, i64 %7)
  call void @avra_array_push(ptr %14, i64 %10)
  call void @avra_array_push(ptr %14, i64 %13)
  call void @avra_rc_release(ptr %0)
  ret ptr %14
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Elane"(i64 %0, i64 %1, i64 %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call i64 @avra_int_mod(i64 %1, i64 %2)
  store i64 %3, ptr %slot, align 8
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %ld1 = load i64, ptr %slot, align 8
  %add = add i64 %ld1, %2
  store i64 %add, ptr %slot, align 8
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %mul = mul i64 %0, 131
  %ld2 = load i64, ptr %slot, align 8
  %add3 = add i64 %mul, %ld2
  %add4 = add i64 %add3, 7
  %4 = call i64 @avra_int_mod(i64 %add4, i64 %2)
  ret i64 %4
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Enew_digest"() {
entry:
  %0 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %0, i64 7919)
  call void @avra_array_push(ptr %0, i64 104729)
  call void @avra_array_push(ptr %0, i64 1299709)
  call void @avra_array_push(ptr %0, i64 15485863)
  ret ptr %0
}
