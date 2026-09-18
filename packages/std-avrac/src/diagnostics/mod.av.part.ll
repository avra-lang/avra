; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"language.defect\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c":\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c": \00" }, align 16

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

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eerror_at"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Epointed"(ptr %5, ptr %3)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  %10 = call ptr @avra_array_get_owned(ptr %6, i64 3)
  %11 = call ptr @avra_array_get_owned(ptr %6, i64 4)
  %12 = call i64 @avra_array_get(ptr %6, i64 6)
  %boxed = inttoptr i64 %12 to ptr
  %13 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %13, ptr %7)
  call void @avra_array_push_owned(ptr %13, ptr %8)
  call void @avra_array_push_owned(ptr %13, ptr %9)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  call void @avra_array_push_owned(ptr %13, ptr %4)
  call void @avra_array_push_owned(ptr %13, ptr %boxed)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Epointed"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr %boxed1)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  %10 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed2 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %11, ptr %5)
  call void @avra_array_push_owned(ptr %11, ptr %6)
  call void @avra_array_push_owned(ptr %11, ptr %4)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr %8)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %boxed2)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eerror_at"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %7, ptr %0)
  call void @avra_array_push_owned(ptr %7, ptr %3)
  call void @avra_array_push_owned(ptr %7, ptr %4)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %2)
  call void @avra_array_push(ptr %7, i64 0)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eloc_at"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_insist(ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 1)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %6, ptr %0)
  call void @avra_array_push(ptr %6, i64 %3)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Ewarning"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %9 = call ptr @avra_array_get_owned(ptr %5, i64 3)
  %10 = call ptr @avra_array_get_owned(ptr %5, i64 4)
  %11 = call ptr @avra_array_get_owned(ptr %5, i64 5)
  %12 = call i64 @avra_array_get(ptr %5, i64 6)
  %boxed = inttoptr i64 %12 to ptr
  %13 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %13, ptr %7)
  call void @avra_array_push_owned(ptr %13, ptr %6)
  call void @avra_array_push_owned(ptr %13, ptr %8)
  call void @avra_array_push_owned(ptr %13, ptr %9)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  call void @avra_array_push_owned(ptr %13, ptr %boxed)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13
}

define i64 @"av_$40std$2Eavrac$2Ediagnostics$2EVoices$2Espeak"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_slot_unique(ptr %0, i64 0)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eno_voices"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define i1 @"av_$40std$2Eavrac$2Ediagnostics$2Ehas_errors"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ediagnostics$2Emod$24l93" to i64))
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %2 to ptr
  %5 = call i1 %cast(ptr %1, ptr %boxed)
  br i1 %5, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %3, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Ediagnostics$2Emod$24l93"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Ediagnostics$2Eis_error"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define i1 @"av_$40std$2Eavrac$2Ediagnostics$2Eis_error"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %cmp = icmp eq i64 %2, 0
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Edefect_at"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eerror_at"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %0, ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Ecode_for"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ediagnostics$2Emod$24l17" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %cast = inttoptr i64 %3 to ptr
  %6 = call i1 %cast(ptr %2, ptr %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead

then6:                                            ; preds = %lexit
  %7 = call ptr @avra_array_get_owned(ptr %ld4, i64 1)
  br label %endif8

else7:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr null)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %7, %then6 ], [ null, %else7 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval9
}

define i1 @"av_$40std$2Eavrac$2Ediagnostics$2Emod$24l17"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eby_position"(ptr %0) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld9 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld9)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld9

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot, align 8
  %ld5 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld5)
  %4 = call i64 @"av_$40std$2Eavrac$2Ediagnostics$2Estart_of"(ptr %ld5)
  call void @avra_rc_retain(ptr %ld4)
  %5 = call i64 @"av_$40std$2Eavrac$2Ediagnostics$2Efirst_after"(ptr %ld4, i64 %4)
  %ld6 = load ptr, ptr %slot, align 8
  %ld7 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld6)
  call void @avra_rc_retain(ptr %ld7)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$24141"(ptr %ld6, i64 %5, ptr %ld7)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  %ld8 = load i64, ptr %slot1, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$24141"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Ediagnostics$2Efirst_after"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %3 = call i64 @avra_array_len(ptr %0)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot1)
  store ptr %4, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld3)
  %5 = call i64 @"av_$40std$2Eavrac$2Ediagnostics$2Estart_of"(ptr %ld3)
  %cmp4 = icmp sgt i64 %5, %1
  br i1 %cmp4, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %ld2

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ediagnostics$2Estart_of"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %2, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %3, 1
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %pack, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  br i1 %x, label %then1, label %else2

then1:                                            ; preds = %endif
  %x4 = extractvalue { i1, i64 } %regval, 1
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval5 = phi i64 [ %x4, %then1 ], [ -1, %else2 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval5
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Euser_code"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_str_replace(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr %0)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}
