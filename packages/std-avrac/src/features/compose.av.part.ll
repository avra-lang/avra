; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [26 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 25 }, [26 x i8] c"no feature owns builder `\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuild_named"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5, ptr %6) {
entry:
  %slot5 = alloca ptr, align 8
  store ptr null, ptr %slot5, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %7 = call i64 @avra_map_has(ptr %0, ptr %2)
  %b = icmp ne i64 %7, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %8 = call ptr @avra_map_get_owned(ptr %0, ptr %2)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot)
  store ptr %8, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp = icmp ne ptr %ld, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then1, label %else2

then1:                                            ; preds = %endif
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %2)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %10 = call ptr @avra_str_join(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 1)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  %12 = call ptr @avra_insist(ptr %ld)
  %13 = call i64 @avra_array_get(ptr %12, i64 2)
  %boxed = inttoptr i64 %13 to ptr
  %14 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %14, ptr %1)
  call void @avra_array_push_owned(ptr %14, ptr %3)
  call void @avra_array_push_owned(ptr %14, ptr %4)
  call void @avra_array_push_owned(ptr %14, ptr %5)
  call void @avra_array_push_owned(ptr %14, ptr %6)
  call void @avra_array_push_owned(ptr %14, ptr %boxed)
  call void @avra_rc_retain(ptr %14)
  call void @avra_cell_release(ptr %slot5)
  store ptr %14, ptr %slot5, align 8
  %15 = call ptr @avra_insist(ptr %ld)
  %16 = call i64 @avra_array_get(ptr %15, i64 1)
  %boxed6 = inttoptr i64 %16 to ptr
  %ld7 = load ptr, ptr %slot5, align 8
  %17 = call i64 @avra_array_get(ptr %boxed6, i64 0)
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %ld7)
  %cast = inttoptr i64 %17 to ptr
  %18 = call ptr %cast(ptr %boxed6, ptr %ld7)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  %cmp8 = icmp eq i64 %19, 0
  br i1 %cmp8, label %then9, label %else10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif3

then9:                                            ; preds = %endif3
  %20 = call ptr @avra_array_get_owned(ptr %18, i64 1)
  br label %endif11

else10:                                           ; preds = %endif3
  call void @avra_cell_release(ptr %slot5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

endif11:                                          ; preds = %postret12, %then9
  %regval13 = phi ptr [ %20, %then9 ], [ null, %postret12 ]
  %21 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %21, i64 1)
  call void @avra_array_push_owned(ptr %21, ptr %regval13)
  %22 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %22, i64 0)
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_cell_release(ptr %slot5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %regval13)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %22

postret12:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif11
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuilder_index"(ptr %0) {
entry:
  %slot15 = alloca ptr, align 8
  store ptr null, ptr %slot15, align 8
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_map_new()
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld27 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld27)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld27

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call ptr @avra_array_get_owned(ptr %ld4, i64 3)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %endif20, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %5
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld25 = load i64, ptr %slot1, align 8
  %add26 = add i64 %ld25, 1
  store i64 %add26, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 %ld12)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot6)
  store ptr %6, ptr %slot6, align 8
  %ld13 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld13)
  %ld14 = load ptr, ptr %slot6, align 8
  call void @avra_rc_retain(ptr %ld14)
  %7 = call ptr @avra_array_get_owned(ptr %ld14, i64 0)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot15)
  store ptr null, ptr %slot15, align 8
  %8 = call i64 @avra_map_has(ptr %ld13, ptr %7)
  %b = icmp ne i64 %8, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody11
  %9 = call ptr @avra_map_get_owned(ptr %ld13, ptr %7)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot15)
  store ptr %9, ptr %slot15, align 8
  call void @avra_rc_release(ptr %9)
  br label %endif

else:                                             ; preds = %lbody11
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld16 = load ptr, ptr %slot15, align 8
  %cmp17 = icmp ne ptr %ld16, null
  %not = xor i1 %cmp17, true
  br i1 %not, label %then18, label %else19

then18:                                           ; preds = %endif
  %10 = call ptr @avra_cell_unique(ptr %slot)
  %ld21 = load ptr, ptr %slot6, align 8
  %11 = call i64 @avra_array_get(ptr %ld21, i64 0)
  %boxed = inttoptr i64 %11 to ptr
  %ld22 = load ptr, ptr %slot6, align 8
  call void @avra_map_set_owned(ptr %10, ptr %boxed, ptr %ld22)
  br label %endif20

else19:                                           ; preds = %endif
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval23 = phi i64 [ 0, %then18 ], [ 0, %else19 ]
  %ld24 = load i64, ptr %slot5, align 8
  %add = add i64 %ld24, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_cell_release(ptr %slot15)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %ld14)
  call void @avra_rc_release(ptr %ld13)
  call void @avra_rc_release(ptr %6)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecompose_grammar"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24160"(ptr %1)
  %4 = call i64 @avra_array_len(ptr %3)
  %cmp5 = icmp eq i64 %4, 0
  br i1 %cmp5, label %then, label %else

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 2)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_array_push_owned(ptr %1, ptr %boxed3)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then:                                             ; preds = %lexit
  br label %endif

else:                                             ; preds = %lexit
  %8 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 0)
  call void @avra_rc_release(ptr %8)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.3, i64 16), %then ], [ %9, %else ]
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %10, ptr %regval)
  call void @avra_array_push_owned(ptr %10, ptr %regval)
  call void @avra_array_push_owned(ptr %10, ptr %3)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24160"(ptr)
