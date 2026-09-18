; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
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

define ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %0, ptr %1) {
entry:
  %slot3 = alloca i64, align 8
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str, i64 16)

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_cell_release(ptr %slot)
  store ptr %0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif

lhead:                                            ; preds = %lexit5, %endif
  %ld = load ptr, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %ld)
  %cmp1 = icmp sgt i64 %3, 1
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld29 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld29)
  %4 = call ptr @avra_array_get_owned(ptr %ld29, i64 0)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld29)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %5 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot2)
  store ptr %5, ptr %slot2, align 8
  store i64 0, ptr %slot3, align 8
  br label %lhead4

lhead4:                                           ; preds = %endif15, %lbody
  %ld6 = load i64, ptr %slot3, align 8
  %ld7 = load ptr, ptr %slot, align 8
  %6 = call i64 @avra_array_len(ptr %ld7)
  %cmp8 = icmp slt i64 %ld6, %6
  br i1 %cmp8, label %lbody9, label %lexit5

lexit5:                                           ; preds = %lhead4
  %ld28 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld28)
  call void @avra_rc_retain(ptr %ld28)
  call void @avra_cell_release(ptr %slot)
  store ptr %ld28, ptr %slot, align 8
  call void @avra_cell_release(ptr %slot2)
  call void @avra_rc_release(ptr %ld28)
  call void @avra_rc_release(ptr %5)
  br label %lhead

lbody9:                                           ; preds = %lhead4
  %ld10 = load i64, ptr %slot3, align 8
  %add = add i64 %ld10, 1
  %ld11 = load ptr, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %ld11)
  %cmp12 = icmp slt i64 %add, %7
  br i1 %cmp12, label %then13, label %else14

then13:                                           ; preds = %lbody9
  %8 = call ptr @avra_cell_unique(ptr %slot2)
  %ld16 = load ptr, ptr %slot, align 8
  %ld17 = load i64, ptr %slot3, align 8
  %9 = call i64 @avra_array_get(ptr %ld16, i64 %ld17)
  %boxed = inttoptr i64 %9 to ptr
  %ld18 = load ptr, ptr %slot, align 8
  %ld19 = load i64, ptr %slot3, align 8
  %add20 = add i64 %ld19, 1
  %10 = call i64 @avra_array_get(ptr %ld18, i64 %add20)
  %boxed21 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %boxed)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %1)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %boxed21)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %12 = call ptr @avra_str_join(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif15

else14:                                           ; preds = %lbody9
  %13 = call ptr @avra_cell_unique(ptr %slot2)
  %ld22 = load ptr, ptr %slot, align 8
  %ld23 = load i64, ptr %slot3, align 8
  %14 = call i64 @avra_array_get(ptr %ld22, i64 %ld23)
  %boxed24 = inttoptr i64 %14 to ptr
  call void @avra_array_push_owned(ptr %13, ptr %boxed24)
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval25 = phi i64 [ 0, %then13 ], [ 0, %else14 ]
  %ld26 = load i64, ptr %slot3, align 8
  %add27 = add i64 %ld26, 2
  store i64 %add27, ptr %slot3, align 8
  br label %lhead4
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24480"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2Efound_at"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 -1, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %cmp5 = icmp slt i64 %ld4, 0
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i64 %ld2, ptr %slot, align 8
  store i64 %2, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

then6:                                            ; preds = %lexit
  br label %endif8

else7:                                            ; preds = %lexit
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %ld4, 1
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi { i1, i64 } [ zeroinitializer, %then6 ], [ %pack, %else7 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %regval9
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24114"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2415"(i64 %0, i1 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %slot2 = zext i1 %1 to i64
  call void @avra_array_push(ptr %2, i64 %slot2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24114"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241137"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241133"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241130"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24257"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241048"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24255"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$2411"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_slice(ptr %0, i64 0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  %5 = call ptr @avra_array_concat(ptr %3, ptr %4)
  %6 = call i64 @avra_array_len(ptr %0)
  %7 = call ptr @avra_array_slice(ptr %0, i64 %1, i64 %6)
  %8 = call ptr @avra_array_concat(ptr %5, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2411"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24153"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24278"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2413"(ptr %0) {
entry:
  %slot6 = alloca i64, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call i64 @avra_array_get(ptr %ld4, i64 %ld12)
  store i64 %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load i64, ptr %slot6, align 8
  call void @avra_array_push(ptr %6, i64 %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ecopied$24195"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_cell_release(ptr %slot)
  store ptr %0, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld7 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld7)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld7

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 %ld3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot2)
  store ptr %4, ptr %slot2, align 8
  %5 = call ptr @avra_cell_unique(ptr %slot)
  %add = add i64 %2, %ld3
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_slot_set_owned(ptr %5, i64 %add, ptr %ld4)
  %ld5 = load i64, ptr %slot1, align 8
  %add6 = add i64 %ld5, 1
  store i64 %add6, ptr %slot1, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24196"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$2411"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld5

lbody:                                            ; preds = %lhead
  %3 = call ptr @avra_cell_unique(ptr %slot)
  %ld2 = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_array_push_owned(ptr %3, ptr %boxed)
  %ld3 = load i64, ptr %slot1, align 8
  %sub4 = sub i64 %ld3, 1
  store i64 %sub4, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2477"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$2477"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld5

lbody:                                            ; preds = %lhead
  %3 = call ptr @avra_cell_unique(ptr %slot)
  %ld2 = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  call void @avra_array_push(ptr %3, i64 %4)
  %ld3 = load i64, ptr %slot1, align 8
  %sub4 = sub i64 %ld3, 1
  store i64 %sub4, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241171"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2482"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$24280"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld5

lbody:                                            ; preds = %lhead
  %3 = call ptr @avra_cell_unique(ptr %slot)
  %ld2 = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_array_push_owned(ptr %3, ptr %boxed)
  %ld3 = load i64, ptr %slot1, align 8
  %sub4 = sub i64 %ld3, 1
  store i64 %sub4, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2434"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2434"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24113"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr %0) {
entry:
  %slot7 = alloca { i1, i1 }, align 8
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_map_new()
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot1)
  store ptr %2, ptr %slot1, align 8
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif12, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 %ld4)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot3)
  store ptr %4, ptr %slot3, align 8
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  %ld6 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld6)
  store { i1, i1 } zeroinitializer, ptr %slot7, align 8
  %5 = call i64 @avra_map_has(ptr %ld5, ptr %ld6)
  %b = icmp ne i64 %5, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  %6 = call i64 @avra_map_get(ptr %ld5, ptr %ld6)
  %b8 = icmp ne i64 %6, 0
  %pack = insertvalue { i1, i1 } { i1 true, i1 undef }, i1 %b8, 1
  store { i1, i1 } %pack, ptr %slot7, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld9 = load { i1, i1 }, ptr %slot7, align 8
  %x = extractvalue { i1, i1 } %ld9, 0
  %not = xor i1 %x, true
  br i1 %not, label %then10, label %else11

then10:                                           ; preds = %endif
  %7 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot3, align 8
  call void @avra_map_set(ptr %7, ptr %ld13, i64 1)
  %8 = call ptr @avra_cell_unique(ptr %slot1)
  %ld14 = load ptr, ptr %slot3, align 8
  call void @avra_array_push_owned(ptr %8, ptr %ld14)
  br label %endif12

else11:                                           ; preds = %endif
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval15 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %ld16 = load i64, ptr %slot2, align 8
  %add = add i64 %ld16, 1
  store i64 %add, ptr %slot2, align 8
  call void @avra_rc_release(ptr %ld6)
  call void @avra_rc_release(ptr %ld5)
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2413"(i64 %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push(ptr %2, i64 %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24313"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$24313"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2411"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24163"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24161"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24167"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24486"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24110"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2491"(ptr %0) {
entry:
  %slot6 = alloca i64, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call i64 @avra_array_get(ptr %ld4, i64 %ld12)
  store i64 %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load i64, ptr %slot6, align 8
  call void @avra_array_push(ptr %6, i64 %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24103"(ptr %0) {
entry:
  %slot6 = alloca i64, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call i64 @avra_array_get(ptr %ld4, i64 %ld12)
  store i64 %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load i64, ptr %slot6, align 8
  call void @avra_array_push(ptr %6, i64 %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2430"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr %0) {
entry:
  %slot6 = alloca i64, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call i64 @avra_array_get(ptr %ld4, i64 %ld12)
  store i64 %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load i64, ptr %slot6, align 8
  call void @avra_array_push(ptr %6, i64 %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241120"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24150"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24334"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$24113"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_slice(ptr %0, i64 0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  %5 = call ptr @avra_array_concat(ptr %3, ptr %4)
  %6 = call i64 @avra_array_len(ptr %0)
  %7 = call ptr @avra_array_slice(ptr %0, i64 %1, i64 %6)
  %8 = call ptr @avra_array_concat(ptr %5, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$24141"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_slice(ptr %0, i64 0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  %5 = call ptr @avra_array_concat(ptr %3, ptr %4)
  %6 = call i64 @avra_array_len(ptr %0)
  %7 = call ptr @avra_array_slice(ptr %0, i64 %1, i64 %6)
  %8 = call ptr @avra_array_concat(ptr %5, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$24113"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$2413"(i64 %0) {
entry:
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24289"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24223"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24265"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24218"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24148"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$2415"(i1 %0) {
entry:
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24139"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24138"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24341"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24419"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24145"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2429"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2488"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2410"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241217"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$241021"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24352"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241114"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241112"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24372"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241110"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24180"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24160"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$24103"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$24110"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$24486"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24101"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24156"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24162"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24249"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2411"(i64 %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24483"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
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

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %4
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %3)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %5 = call ptr @avra_array_get_owned(ptr %ld4, i64 %ld12)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot6)
  store ptr %5, ptr %slot6, align 8
  %6 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_array_push_owned(ptr %6, ptr %ld13)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead7
}
