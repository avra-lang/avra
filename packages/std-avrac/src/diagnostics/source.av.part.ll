; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [48 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 47 }, [48 x i8] c"a span reaches outside its own text \E2\80\94 offset \00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c" of \00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c" in \00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare void @avra_trap(ptr)

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2Enew_source_file"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  %3 = call i64 @avra_str_len(ptr %1)
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld7 = load ptr, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr %ld7)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_str_char_code(ptr %1, i64 %ld2)
  %cmp3 = icmp eq i64 %5, 10
  br i1 %cmp3, label %then, label %else

then:                                             ; preds = %lbody
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, 1
  call void @avra_array_push(ptr %6, i64 %add)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld5 = load i64, ptr %slot1, align 8
  %add6 = add i64 %ld5, 1
  store i64 %add6, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2ESourceFile$2Eline_text"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %sub = sub i64 %1, 1
  %3 = call i64 @avra_array_get(ptr %boxed, i64 %sub)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_len(ptr %boxed1)
  %cmp = icmp slt i64 %1, %5
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 %1)
  %sub3 = sub i64 %7, 1
  br label %endif

else:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed4 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_str_len(ptr %boxed4)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %sub3, %then ], [ %9, %else ]
  %10 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed5 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_str_substring(ptr %boxed5, i64 %3, i64 %regval)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

define ptr @"av_$40std$2Eavrac$2Ediagnostics$2ESourceFile$2Elinecol"(ptr %0, i64 %1) {
entry:
  %slot9 = alloca i64, align 8
  %slot8 = alloca i64, align 8
  %slot = alloca i64, align 8
  %cmp = icmp slt i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_str_len(ptr %boxed)
  %cmp1 = icmp sgt i64 %1, %3
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %4 = call ptr @avra_int_text(i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed5 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_str_len(ptr %boxed5)
  %7 = call ptr @avra_int_text(i64 %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed6 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %boxed6)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %10 = call ptr @avra_str_join(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %11 = call ptr @avra_str_crossing(ptr %10)
  call void @avra_trap(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval7 = phi i64 [ 0, %then2 ], [ 0, %else3 ]
  store i64 0, ptr %slot, align 8
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %13 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot8, align 8
  br label %lhead

lhead:                                            ; preds = %endif16, %endif4
  %ld = load i64, ptr %slot8, align 8
  %cmp10 = icmp slt i64 %ld, %13
  br i1 %cmp10, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld19 = load i64, ptr %slot, align 8
  %add20 = add i64 %ld19, 1
  %14 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed21 = inttoptr i64 %14 to ptr
  %ld22 = load i64, ptr %slot, align 8
  %15 = call i64 @avra_array_get(ptr %boxed21, i64 %ld22)
  %sub = sub i64 %1, %15
  %add23 = add i64 %sub, 1
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 %add20)
  call void @avra_array_push(ptr %16, i64 %add23)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

lbody:                                            ; preds = %lhead
  %ld11 = load i64, ptr %slot8, align 8
  %17 = call i64 @avra_array_get(ptr %12, i64 %ld11)
  store i64 %17, ptr %slot9, align 8
  %ld12 = load i64, ptr %slot9, align 8
  %cmp13 = icmp sle i64 %ld12, %1
  br i1 %cmp13, label %then14, label %else15

then14:                                           ; preds = %lbody
  store i64 %ld11, ptr %slot, align 8
  br label %endif16

else15:                                           ; preds = %lbody
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi i64 [ 0, %then14 ], [ 0, %else15 ]
  %ld18 = load i64, ptr %slot8, align 8
  %add = add i64 %ld18, 1
  store i64 %add, ptr %slot8, align 8
  br label %lhead
}
