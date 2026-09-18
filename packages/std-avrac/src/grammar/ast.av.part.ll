; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2411"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr)

define ptr @"av_$40std$2Eavrac$2Egrammar$2Enode_builder_name"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %3 = call ptr @avra_str_join(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_start"(i64)

define ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Edeep_items"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Eseqs"(ptr %0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24163"(ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_array_push_owned(ptr %1, ptr %boxed2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24163"(ptr)

define ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Eseqs"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24161"(ptr %2)
  %6 = call ptr @avra_array_concat(ptr %1, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %9 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Egroup_seqs"(ptr %boxed2)
  call void @avra_array_push_owned(ptr %2, ptr %9)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24161"(ptr)

define ptr @"av_$40std$2Eavrac$2Egrammar$2Egroup_seqs"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm1 [
    i64 3, label %arm
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Egrammar$2EAlt$2Eseqs"(ptr %boxed)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %3, %arm ], [ %4, %arm1 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2EAlt$2Eseqs"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24161"(ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Eseqs"(ptr %boxed)
  call void @avra_array_push_owned(ptr %1, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_grammar"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed5 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr %boxed5)
  call void @avra_array_push_owned(ptr %6, ptr %1)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %9 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_alt"(ptr %boxed2)
  %10 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed3 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %11, ptr %boxed3)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %1, ptr %11)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_alt"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_seq"(ptr %boxed)
  call void @avra_array_push_owned(ptr %1, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_seq"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed3 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %6, ptr %1)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr %boxed3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_item"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %1, ptr %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_item"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %cmp = icmp ne ptr %boxed, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %boxed1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i1 @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Ebinds_many"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %5, %then ], [ false, %else ]
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_prim"(ptr %0, ptr %boxed2)
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %9 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %10 = call ptr @avra_array_get_owned(ptr %1, i64 3)
  %11 = call i64 @avra_array_get(ptr %1, i64 4)
  %b = icmp ne i64 %11, 0
  %12 = call i64 @avra_array_get(ptr %1, i64 5)
  %b3 = icmp ne i64 %12, 0
  %13 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %13, ptr %8)
  call void @avra_array_push_owned(ptr %13, ptr %7)
  call void @avra_array_push_owned(ptr %13, ptr %9)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  %slot = zext i1 %b to i64
  call void @avra_array_push(ptr %13, i64 %slot)
  %slot4 = zext i1 %b3 to i64
  call void @avra_array_push(ptr %13, i64 %slot4)
  %slot5 = zext i1 %regval to i64
  call void @avra_array_push(ptr %13, i64 %slot5)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_prim"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 3, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi ptr [ %8, %lexit ], [ %1, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %7, ptr %4)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 3)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %10 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Enested_seq"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %4, ptr %10)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Enested_seq"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr %2)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %boxed3)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %9 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Elisted_item"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %9)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Ebinds_many"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Ebinding_count"(ptr %0, ptr %1)
  %cmp = icmp sgt i64 %2, 1
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Ebinding_count"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  %5 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Esum_of"(ptr %2)
  %6 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Ecapped"(i64 %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %8 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Eitem_bindings"(ptr %boxed, ptr %1)
  call void @avra_array_push(ptr %2, i64 %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2Ecapped"(i64 %0) {
entry:
  %cmp = icmp sgt i64 %0, 2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 2, %then ], [ %0, %else ]
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2Esum_of"(ptr %0) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld8

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 %ld3)
  store i64 %2, ptr %slot2, align 8
  %ld4 = load i64, ptr %slot, align 8
  %ld5 = load i64, ptr %slot2, align 8
  %add = add i64 %ld4, %ld5
  store i64 %add, ptr %slot, align 8
  %ld6 = load i64, ptr %slot1, align 8
  %add7 = add i64 %ld6, 1
  store i64 %add7, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2Eitem_bindings"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Eown_binding"(ptr %0, ptr %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Egroup_bindings"(ptr %boxed, ptr %1)
  %add = add i64 %2, %4
  %5 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Ecapped"(i64 %add)
  %cmp = icmp sgt i64 %5, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call i1 @"av_$40std$2Eavrac$2Egrammar$2Erepeats"(ptr %boxed1)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %7, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 2

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

postret:                                          ; No predecessors!
  br label %endif4
}

define i1 @"av_$40std$2Eavrac$2Egrammar$2Erepeats"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %2, 2
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i1 [ true, %then2 ], [ false, %else3 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval5
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2Egroup_bindings"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %2, label %arm1 [
    i64 3, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi i64 [ %7, %lexit ], [ 0, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Egrammar$2Emost_of"(ptr %4)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %9 = call i64 @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Ebinding_count"(ptr %boxed, ptr %1)
  call void @avra_array_push(ptr %4, i64 %9)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2Emost_of"(ptr %0) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld9 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld9

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 %ld3)
  store i64 %2, ptr %slot2, align 8
  %ld4 = load i64, ptr %slot2, align 8
  %ld5 = load i64, ptr %slot, align 8
  %cmp6 = icmp sgt i64 %ld4, %ld5
  br i1 %cmp6, label %then, label %else

then:                                             ; preds = %lbody
  %ld7 = load i64, ptr %slot2, align 8
  store i64 %ld7, ptr %slot, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld8 = load i64, ptr %slot1, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Egrammar$2Eown_binding"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %cmp = icmp ne ptr %boxed, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %boxed1)
  %5 = call i64 @avra_streq(ptr %4, ptr %1)
  %b = icmp ne i64 %5, 0
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %b, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i64 [ 1, %then2 ], [ 0, %else3 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval5
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2EAlt$2Eitems"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24163"(ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Edeep_items"(ptr %boxed)
  call void @avra_array_push_owned(ptr %1, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"() {
entry:
  ret i1 false
}

define i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Etrailer"() {
entry:
  ret i1 false
}

define i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Ehead"() {
entry:
  ret i1 false
}

define i1 @"av_$40std$2Eavrac$2Egrammar$2EPrim$2Eanswers_to"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Egrammar$2EPrim$2Etoken_name"(ptr %0)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call i64 @avra_streq(ptr %3, ptr %1)
  %b = icmp ne i64 %4, 0
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2EPrim$2Etoken_name"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm2 [
    i64 1, label %arm
    i64 2, label %arm1
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ %3, %arm1 ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2EGrammar$2Ekeywords"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2411"(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %8 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Ealt_words"(ptr %boxed2)
  call void @avra_array_push_owned(ptr %1, ptr %8)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Ealt_words"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Egrammar$2EAlt$2Eitems"(ptr %0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2411"(ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Eitem_words"(ptr %boxed)
  call void @avra_array_push_owned(ptr %1, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Eitem_words"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 1, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %4 = call i64 @avra_str_len(ptr %3)
  %cmp = icmp eq i64 %4, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif4
  %regval6 = phi ptr [ %regval5, %endif4 ], [ %5, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval6

then:                                             ; preds = %arm
  %6 = call i64 @avra_str_char_code(ptr %3, i64 0)
  %7 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_start"(i64 %6)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %7, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %8, ptr %3)
  br label %endif4

else3:                                            ; preds = %endif
  %9 = call ptr @avra_array_sized(i64 0)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %8, %then2 ], [ %9, %else3 ]
  call void @avra_rc_release(ptr %3)
  br label %endswitch
}
