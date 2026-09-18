; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c" \00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"@std.text.nul_needle\00" }, align 16

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

define ptr @"av_$40std$2Etext$2Epad_right"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Etext$2Ecodepoint_count"(ptr %0)
  %sub = sub i64 %1, %2
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %3 = call ptr @"av_$40std$2Etext$2Erepeat"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), i64 %sub)
  %4 = call ptr @avra_str_concat(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Etext$2Erepeat"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @"av_$40std$2Etext$2Ebuilder"()
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %3 = call ptr @"av_$40std$2Etext$2EText$2Ebuilt"(ptr %ld4)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

lbody:                                            ; preds = %lhead
  %ld2 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld2)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Etext$2EText$2Epush"(ptr %ld2, ptr %0)
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Etext$2EText$2Ebuilt"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call ptr @avra_str_join(ptr %boxed, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define i64 @"av_$40std$2Etext$2EText$2Epush"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_slot_unique(ptr %0, i64 0)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Etext$2Ebuilder"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define i64 @"av_$40std$2Etext$2Ecodepoint_count"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Etext$2Esteps"(ptr %0)
  %2 = call i64 @avra_array_len(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define ptr @"av_$40std$2Etext$2Esteps"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call i64 @avra_str_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Etext$2Estep_at"(ptr %0, i64 %ld2, i64 %2)
  %4 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %3, i64 1)
  %add = add i64 %ld3, %5
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %3)
  br label %lhead
}

define ptr @"av_$40std$2Etext$2Estep_at"(ptr %0, i64 %1, i64 %2) {
entry:
  %slot6 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_str_char_code(ptr %0, i64 %1)
  %4 = call i64 @"av_$40std$2Etext$2Elead_width"(i64 %3)
  %cmp = icmp eq i64 %4, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %add = add i64 %1, %4
  %cmp1 = icmp sgt i64 %add, %2
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %5 = call ptr @"av_$40std$2Etext$2Elone_byte"(i64 %1, i64 %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %6 = call i64 @"av_$40std$2Etext$2Elead_mark"(i64 %4)
  %sub = sub i64 %3, %6
  store i64 %sub, ptr %slot, align 8
  store i64 1, ptr %slot6, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif4

lhead:                                            ; preds = %endif18, %endif4
  %ld = load i64, ptr %slot6, align 8
  %cmp7 = icmp slt i64 %ld, %4
  br i1 %cmp7, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld26 = load i64, ptr %slot, align 8
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %7, i64 %1)
  call void @avra_array_push(ptr %7, i64 %4)
  call void @avra_array_push(ptr %7, i64 %ld26)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

lbody:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot6, align 8
  %add9 = add i64 %1, %ld8
  %8 = call i64 @avra_str_char_code(ptr %0, i64 %add9)
  %cmp10 = icmp slt i64 %8, 128
  br i1 %cmp10, label %then11, label %else12

then11:                                           ; preds = %lbody
  br label %endif13

else12:                                           ; preds = %lbody
  %cmp14 = icmp sge i64 %8, 192
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i1 [ true, %then11 ], [ %cmp14, %else12 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif13
  %9 = call ptr @"av_$40std$2Etext$2Elone_byte"(i64 %1, i64 %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else17:                                           ; preds = %endif13
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  %ld21 = load i64, ptr %slot, align 8
  %mul = mul i64 %ld21, 64
  %sub22 = sub i64 %8, 128
  %add23 = add i64 %mul, %sub22
  store i64 %add23, ptr %slot, align 8
  %ld24 = load i64, ptr %slot6, align 8
  %add25 = add i64 %ld24, 1
  store i64 %add25, ptr %slot6, align 8
  br label %lhead

postret19:                                        ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif18
}

define i64 @"av_$40std$2Etext$2Elead_mark"(i64 %0) {
entry:
  %cmp = icmp eq i64 %0, 4
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp eq i64 %0, 3
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval5 = phi i64 [ 240, %then ], [ %regval, %endif4 ]
  ret i64 %regval5

then2:                                            ; preds = %else
  br label %endif4

else3:                                            ; preds = %else
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi i64 [ 224, %then2 ], [ 192, %else3 ]
  br label %endif
}

define ptr @"av_$40std$2Etext$2Elone_byte"(i64 %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %2, i64 %0)
  call void @avra_array_push(ptr %2, i64 1)
  call void @avra_array_push(ptr %2, i64 %1)
  ret ptr %2
}

define i64 @"av_$40std$2Etext$2Elead_width"(i64 %0) {
entry:
  %cmp = icmp slt i64 %0, 128
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp sge i64 %0, 240
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif8, %then
  %regval30 = phi i64 [ 1, %then ], [ %regval29, %endif8 ]
  ret i64 %regval30

then2:                                            ; preds = %else
  %cmp5 = icmp slt i64 %0, 248
  br label %endif4

else3:                                            ; preds = %else
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi i1 [ %cmp5, %then2 ], [ false, %else3 ]
  br i1 %regval, label %then6, label %else7

then6:                                            ; preds = %endif4
  br label %endif8

else7:                                            ; preds = %endif4
  %cmp9 = icmp sge i64 %0, 224
  br i1 %cmp9, label %then10, label %else11

endif8:                                           ; preds = %endif17, %then6
  %regval29 = phi i64 [ 4, %then6 ], [ %regval28, %endif17 ]
  br label %endif

then10:                                           ; preds = %else7
  %cmp13 = icmp slt i64 %0, 240
  br label %endif12

else11:                                           ; preds = %else7
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i1 [ %cmp13, %then10 ], [ false, %else11 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif12
  br label %endif17

else16:                                           ; preds = %endif12
  %cmp18 = icmp sge i64 %0, 192
  br i1 %cmp18, label %then19, label %else20

endif17:                                          ; preds = %endif26, %then15
  %regval28 = phi i64 [ 3, %then15 ], [ %regval27, %endif26 ]
  br label %endif8

then19:                                           ; preds = %else16
  %cmp22 = icmp slt i64 %0, 224
  br label %endif21

else20:                                           ; preds = %else16
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval23 = phi i1 [ %cmp22, %then19 ], [ false, %else20 ]
  br i1 %regval23, label %then24, label %else25

then24:                                           ; preds = %endif21
  br label %endif26

else25:                                           ; preds = %endif21
  br label %endif26

endif26:                                          ; preds = %else25, %then24
  %regval27 = phi i64 [ 2, %then24 ], [ 1, %else25 ]
  br label %endif17
}

define i64 @"av_$40std$2Etext$2Enul_at"(ptr %0) {
entry:
  %1 = call ptr @"av_$40std$2Etext$2Enul_needle"()
  %2 = call i64 @avra_str_index_of(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define ptr @"av_$40std$2Etext$2Enul_needle"() {
entry:
  %0 = call ptr @avra_once_get(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %cmp = icmp ne ptr %0, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %1 = call ptr @"av_$40std$2Etext$2Efrom_codepoint"(i64 0)
  call void @avra_once_set(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %0, %then ], [ %1, %else ]
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  ret ptr %regval
}

define ptr @"av_$40std$2Etext$2Efrom_codepoint"(i64 %0) {
entry:
  %1 = call ptr @avra_str_from_codepoint(i64 %0)
  ret ptr %1
}
