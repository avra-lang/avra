; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [28 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 27 }, [28 x i8] c"a non-list reached a gather\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [43 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 42 }, [43 x i8] c"a non-Bytes value reached a byte operation\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"slice \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"..\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [27 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 26 }, [27 x i8] c" is out of bounds (length \00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c")\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"a class table holds 256 bytes (length \00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c")\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"a non-list reached byte construction\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Etrapped"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eutf8_text"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eutf8_bad_at"(ptr %0)
  %cmp = icmp sge i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ecodepoints"(ptr %0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %4
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %2, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %3, i64 %ld2)
  %7 = call ptr @avra_str_from_codepoint(i64 %6)
  call void @avra_array_push_owned(ptr %2, ptr %7)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ecodepoints"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld6 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld6)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Elead_need"(i64 %3)
  %5 = call ptr @avra_cell_unique(ptr %slot)
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Ecodepoint_at"(ptr %0, i64 %ld3, i64 %4)
  call void @avra_array_push(ptr %5, i64 %6)
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, %4
  %add5 = add i64 %add, 1
  store i64 %add5, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Ecodepoint_at"(ptr %0, i64 %1, i64 %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 %1)
  %add = add i64 %2, 2
  %5 = call i64 @avra_int_shr(i64 255, i64 %add)
  %band = and i64 %4, %5
  store i64 %band, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot1, align 8
  %cmp2 = icmp slt i64 %ld, %2
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld10 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld10

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_int_shl(i64 %ld3, i64 6)
  %ld4 = load i64, ptr %slot1, align 8
  %add5 = add i64 %1, %ld4
  %add6 = add i64 %add5, 1
  %7 = call i64 @avra_array_get(ptr %0, i64 %add6)
  %band7 = and i64 %7, 63
  %bor = or i64 %6, %band7
  store i64 %bor, ptr %slot, align 8
  %ld8 = load i64, ptr %slot1, align 8
  %add9 = add i64 %ld8, 1
  store i64 %add9, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Elead_need"(i64 %0) {
entry:
  %cmp = icmp slt i64 %0, 128
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp sge i64 %0, 194
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif8, %then
  %regval30 = phi i64 [ 0, %then ], [ %regval29, %endif8 ]
  ret i64 %regval30

then2:                                            ; preds = %else
  %cmp5 = icmp sle i64 %0, 223
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
  %regval29 = phi i64 [ 1, %then6 ], [ %regval28, %endif17 ]
  br label %endif

then10:                                           ; preds = %else7
  %cmp13 = icmp sle i64 %0, 239
  br label %endif12

else11:                                           ; preds = %else7
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i1 [ %cmp13, %then10 ], [ false, %else11 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif12
  br label %endif17

else16:                                           ; preds = %endif12
  %cmp18 = icmp sge i64 %0, 240
  br i1 %cmp18, label %then19, label %else20

endif17:                                          ; preds = %endif26, %then15
  %regval28 = phi i64 [ 2, %then15 ], [ %regval27, %endif26 ]
  br label %endif8

then19:                                           ; preds = %else16
  %cmp22 = icmp sle i64 %0, 244
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
  %regval27 = phi i64 [ 3, %then24 ], [ -1, %else25 ]
  br label %endif17
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eutf8_bad_at"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif12, %entry
  %ld = load i64, ptr %slot, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret i64 -1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Elead_need"(i64 %2)
  %cmp2 = icmp slt i64 %3, 0
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  br label %endif

else:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, %3
  %4 = call i64 @avra_array_len(ptr %0)
  %cmp4 = icmp sge i64 %add, %4
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp4, %else ]
  br i1 %regval, label %then5, label %else6

then5:                                            ; preds = %endif
  br label %endif7

else6:                                            ; preds = %endif
  %ld8 = load i64, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %5 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Econtinues"(ptr %0, i64 %ld8, i64 %3)
  %not = xor i1 %5, true
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval9 = phi i1 [ true, %then5 ], [ %not, %else6 ]
  br i1 %regval9, label %then10, label %else11

then10:                                           ; preds = %endif7
  %ld13 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld13

else11:                                           ; preds = %endif7
  br label %endif12

endif12:                                          ; preds = %else11, %postret
  %regval14 = phi i64 [ 0, %postret ], [ 0, %else11 ]
  %ld15 = load i64, ptr %slot, align 8
  %add16 = add i64 %ld15, %3
  %add17 = add i64 %add16, 1
  store i64 %add17, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif12
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Econtinues"(ptr %0, i64 %1, i64 %2) {
entry:
  %slot26 = alloca i64, align 8
  %slot10 = alloca i64, align 8
  %slot = alloca i1, align 1
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %add = add i64 %1, 1
  %3 = call i64 @avra_array_get(ptr %0, i64 %add)
  %4 = call i64 @avra_array_get(ptr %0, i64 %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Efirst_lo"(i64 %4)
  %cmp1 = icmp sge i64 %3, %5
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %0, i64 %1)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Efirst_hi"(i64 %6)
  %cmp5 = icmp sle i64 %3, %7
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ %cmp5, %then2 ], [ false, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  store i1 true, ptr %slot, align 8
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l521" to i64))
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %10 = call ptr @avra_array_sized(i64 0)
  store i64 1, ptr %slot10, align 8
  br label %lhead

else8:                                            ; preds = %endif4
  br label %endif9

endif9:                                           ; preds = %else8, %lexit28
  %regval40 = phi i1 [ %ld39, %lexit28 ], [ false, %else8 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval40

lhead:                                            ; preds = %endif18, %then7
  %ld = load i64, ptr %slot10, align 8
  %cmp11 = icmp slt i64 %ld, %2
  br i1 %cmp11, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %11 = call i64 @avra_array_len(ptr %10)
  store i64 0, ptr %slot26, align 8
  br label %lhead27

lbody:                                            ; preds = %lhead
  %ld12 = load i64, ptr %slot10, align 8
  %add13 = add i64 %1, %ld12
  %add14 = add i64 %add13, 1
  %12 = call i64 @avra_array_get(ptr %0, i64 %add14)
  %cmp15 = icmp sge i64 %12, 128
  br i1 %cmp15, label %then16, label %else17

then16:                                           ; preds = %lbody
  %add19 = add i64 %1, %ld12
  %add20 = add i64 %add19, 1
  %13 = call i64 @avra_array_get(ptr %0, i64 %add20)
  %cmp21 = icmp sle i64 %13, 191
  br label %endif18

else17:                                           ; preds = %lbody
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval22 = phi i1 [ %cmp21, %then16 ], [ false, %else17 ]
  %slot23 = zext i1 %regval22 to i64
  call void @avra_array_push(ptr %10, i64 %slot23)
  %ld24 = load i64, ptr %slot10, align 8
  %add25 = add i64 %ld24, 1
  store i64 %add25, ptr %slot10, align 8
  br label %lhead

lhead27:                                          ; preds = %endif35, %lexit
  %ld29 = load i64, ptr %slot26, align 8
  %cmp30 = icmp slt i64 %ld29, %11
  br i1 %cmp30, label %lbody31, label %lexit28

lexit28:                                          ; preds = %lhead27
  %ld39 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  br label %endif9

lbody31:                                          ; preds = %lhead27
  %ld32 = load i64, ptr %slot26, align 8
  %14 = call i64 @avra_array_get(ptr %10, i64 %ld32)
  %b = icmp ne i64 %14, 0
  call void @avra_rc_retain(ptr %8)
  %cast = inttoptr i64 %9 to ptr
  %15 = call i1 %cast(ptr %8, i1 %b)
  %not = xor i1 %15, true
  br i1 %not, label %then33, label %else34

then33:                                           ; preds = %lbody31
  store i1 false, ptr %slot, align 8
  store i64 %11, ptr %slot26, align 8
  br label %endif35

else34:                                           ; preds = %lbody31
  br label %endif35

endif35:                                          ; preds = %else34, %then33
  %regval36 = phi i64 [ 0, %then33 ], [ 0, %else34 ]
  %ld37 = load i64, ptr %slot26, align 8
  %add38 = add i64 %ld37, 1
  store i64 %add38, ptr %slot26, align 8
  br label %lhead27
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l521"(ptr %0, i1 %1) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i1 %1
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Efirst_hi"(i64 %0) {
entry:
  %cmp = icmp eq i64 %0, 237
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp eq i64 %0, 244
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval5 = phi i64 [ 159, %then ], [ %regval, %endif4 ]
  ret i64 %regval5

then2:                                            ; preds = %else
  br label %endif4

else3:                                            ; preds = %else
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi i64 [ 143, %then2 ], [ 191, %else3 ]
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Efirst_lo"(i64 %0) {
entry:
  %cmp = icmp eq i64 %0, 224
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp eq i64 %0, 240
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval5 = phi i64 [ 160, %then ], [ %regval, %endif4 ]
  ret i64 %regval5

then2:                                            ; preds = %else
  br label %endif4

else3:                                            ; preds = %else
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi i64 [ 144, %then2 ], [ 128, %else3 ]
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Edefect_val"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eoctets_of_box"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call i64 @avra_bytes_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret ptr %1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_bytes_at(ptr %0, i64 %ld1)
  call void @avra_array_push(ptr %1, i64 %3)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_gathered_val"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %1)
  %2 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Earray_id"(ptr %1)
  %x = extractvalue { i1, i64 } %2, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %2, 1
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Edefect_val"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

endif:                                            ; preds = %postret, %then
  %regval = phi i64 [ %x1, %then ], [ 0, %postret ]
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %regval)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %4)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2413"(ptr %4)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 4)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %6, i64 %ld2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %4, ptr %11)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %11)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2413"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm2 [
    i64 4, label %arm
    i64 3, label %arm1
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eoctets_of"(ptr %boxed)
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %7 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %3, %arm ], [ %5, %arm1 ], [ %7, %arm2 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eoctets_of"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call i64 @avra_str_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret ptr %1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_str_char_code(ptr %0, i64 %ld1)
  call void @avra_array_push(ptr %1, i64 %3)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Earray_id"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_eq_at_val"(ptr %0, ptr %1, i1 %2) {
entry:
  %slot24 = alloca i64, align 8
  %slot18 = alloca i64, align 8
  %slot = alloca i1, align 1
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed)
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed1)
  %7 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed2)
  %cmp = icmp slt i64 %6, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp3 = icmp slt i64 %8, %6
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp3, %else ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif
  br label %endif6

else5:                                            ; preds = %endif
  %9 = call i64 @avra_array_len(ptr %4)
  %cmp7 = icmp sgt i64 %8, %9
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i1 [ true, %then4 ], [ %cmp7, %else5 ]
  br i1 %regval8, label %then9, label %else10

then9:                                            ; preds = %endif6
  %10 = call i64 @avra_array_len(ptr %4)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eslice_out_of_bounds"(ptr %0, i64 %6, i64 %8, i64 %10, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else10:                                           ; preds = %endif6
  br label %endif11

endif11:                                          ; preds = %else10, %postret
  %regval12 = phi i64 [ 0, %postret ], [ 0, %else10 ]
  %13 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed13 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed13)
  %14 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed13)
  %sub = sub i64 %8, %6
  %15 = call i64 @avra_array_len(ptr %14)
  %cmp14 = icmp eq i64 %sub, %15
  br i1 %cmp14, label %then15, label %else16

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %endif11

then15:                                           ; preds = %endif11
  store i1 true, ptr %slot, align 8
  %16 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %16, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l246" to i64))
  %17 = call i64 @avra_array_get(ptr %16, i64 0)
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call i64 @avra_array_len(ptr %14)
  store i64 0, ptr %slot18, align 8
  br label %lhead

else16:                                           ; preds = %endif11
  br label %endif17

endif17:                                          ; preds = %else16, %lexit26
  %regval38 = phi i1 [ %ld37, %lexit26 ], [ false, %else16 ]
  %20 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Everdict"(i1 %regval38)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %20

lhead:                                            ; preds = %lbody, %then15
  %ld = load i64, ptr %slot18, align 8
  %cmp19 = icmp slt i64 %ld, %19
  br i1 %cmp19, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %21 = call i64 @avra_array_len(ptr %18)
  store i64 0, ptr %slot24, align 8
  br label %lhead25

lbody:                                            ; preds = %lhead
  %ld20 = load i64, ptr %slot18, align 8
  %add = add i64 %6, %ld20
  %22 = call i64 @avra_array_get(ptr %4, i64 %add)
  %23 = call i64 @avra_array_get(ptr %14, i64 %ld20)
  %24 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Esame_byte"(i64 %22, i64 %23, i1 %2)
  %slot21 = zext i1 %24 to i64
  call void @avra_array_push(ptr %18, i64 %slot21)
  %ld22 = load i64, ptr %slot18, align 8
  %add23 = add i64 %ld22, 1
  store i64 %add23, ptr %slot18, align 8
  br label %lhead

lhead25:                                          ; preds = %endif33, %lexit
  %ld27 = load i64, ptr %slot24, align 8
  %cmp28 = icmp slt i64 %ld27, %21
  br i1 %cmp28, label %lbody29, label %lexit26

lexit26:                                          ; preds = %lhead25
  %ld37 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  br label %endif17

lbody29:                                          ; preds = %lhead25
  %ld30 = load i64, ptr %slot24, align 8
  %25 = call i64 @avra_array_get(ptr %18, i64 %ld30)
  %b = icmp ne i64 %25, 0
  call void @avra_rc_retain(ptr %16)
  %cast = inttoptr i64 %17 to ptr
  %26 = call i1 %cast(ptr %16, i1 %b)
  %not = xor i1 %26, true
  br i1 %not, label %then31, label %else32

then31:                                           ; preds = %lbody29
  store i1 false, ptr %slot, align 8
  store i64 %21, ptr %slot24, align 8
  br label %endif33

else32:                                           ; preds = %lbody29
  br label %endif33

endif33:                                          ; preds = %else32, %then31
  %regval34 = phi i64 [ 0, %then31 ], [ 0, %else32 ]
  %ld35 = load i64, ptr %slot24, align 8
  %add36 = add i64 %ld35, 1
  store i64 %add36, ptr %slot24, align 8
  br label %lhead25
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l246"(ptr %0, i1 %1) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i1 %1
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Everdict"(i1)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Esame_byte"(i64 %0, i64 %1, i1 %2) {
entry:
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eascii_lower"(i64 %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eascii_lower"(i64 %1)
  %cmp = icmp eq i64 %3, %4
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp eq i64 %0, %1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp, %then ], [ %cmp1, %else ]
  ret i1 %regval
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eascii_lower"(i64 %0) {
entry:
  %cmp = icmp sge i64 %0, 65
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %cmp1 = icmp sle i64 %0, 90
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %add = add i64 %0, 32
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i64 [ %add, %then2 ], [ %0, %else3 ]
  ret i64 %regval5
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eslice_out_of_bounds"(ptr %0, i64 %1, i64 %2, i64 %3, ptr %4) {
entry:
  %5 = call ptr @avra_int_text(i64 %1)
  %6 = call ptr @avra_int_text(i64 %2)
  %7 = call ptr @avra_int_text(i64 %3)
  %8 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Etrapped"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_run_val"(ptr %0, ptr %1) {
entry:
  %slot18 = alloca i64, align 8
  %slot14 = alloca i64, align 8
  %slot = alloca { i1, i64 }, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed2)
  %cmp = icmp slt i64 %5, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %8 = call i64 @avra_array_len(ptr %3)
  %cmp3 = icmp sgt i64 %5, %8
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp3, %else ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif
  %9 = call i64 @avra_array_len(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eout_of_bounds"(ptr %0, i64 %5, i64 %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret
  %regval7 = phi i64 [ 0, %postret ], [ 0, %else5 ]
  %11 = call i64 @avra_array_len(ptr %7)
  %cmp8 = icmp ne i64 %11, 256
  br i1 %cmp8, label %then9, label %else10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif6

then9:                                            ; preds = %endif6
  %12 = call i64 @avra_array_len(ptr %7)
  %13 = call ptr @avra_int_text(i64 %12)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %15 = call ptr @avra_str_join(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Etrapped"(ptr %0, ptr %15)
  %17 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %17, i64 0)
  call void @avra_array_push(ptr %17, i64 0)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

else10:                                           ; preds = %endif6
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  store { i1, i64 } zeroinitializer, ptr %slot, align 8
  %18 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %18, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l177" to i64))
  call void @avra_array_push_owned(ptr %18, ptr %7)
  call void @avra_array_push_owned(ptr %18, ptr %3)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  %20 = call ptr @avra_array_sized(i64 0)
  %21 = call i64 @avra_array_len(ptr %3)
  store i64 %5, ptr %slot14, align 8
  br label %lhead

postret12:                                        ; No predecessors!
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  br label %endif11

lhead:                                            ; preds = %lbody, %endif11
  %ld = load i64, ptr %slot14, align 8
  %cmp15 = icmp slt i64 %ld, %21
  br i1 %cmp15, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %22 = call i64 @avra_array_len(ptr %20)
  store i64 0, ptr %slot18, align 8
  br label %lhead19

lbody:                                            ; preds = %lhead
  %ld16 = load i64, ptr %slot14, align 8
  call void @avra_array_push(ptr %20, i64 %ld16)
  %ld17 = load i64, ptr %slot14, align 8
  %add = add i64 %ld17, 1
  store i64 %add, ptr %slot14, align 8
  br label %lhead

lhead19:                                          ; preds = %endif27, %lexit
  %ld21 = load i64, ptr %slot18, align 8
  %cmp22 = icmp slt i64 %ld21, %22
  br i1 %cmp22, label %lbody23, label %lexit20

lexit20:                                          ; preds = %lhead19
  %ld31 = load { i1, i64 }, ptr %slot, align 8
  %x = extractvalue { i1, i64 } %ld31, 0
  br i1 %x, label %then32, label %else33

lbody23:                                          ; preds = %lhead19
  %ld24 = load i64, ptr %slot18, align 8
  %23 = call i64 @avra_array_get(ptr %20, i64 %ld24)
  call void @avra_rc_retain(ptr %18)
  %cast = inttoptr i64 %19 to ptr
  %24 = call i1 %cast(ptr %18, i64 %23)
  br i1 %24, label %then25, label %else26

then25:                                           ; preds = %lbody23
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %23, 1
  store { i1, i64 } %pack, ptr %slot, align 8
  store i64 %22, ptr %slot18, align 8
  br label %endif27

else26:                                           ; preds = %lbody23
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval28 = phi i64 [ 0, %then25 ], [ 0, %else26 ]
  %ld29 = load i64, ptr %slot18, align 8
  %add30 = add i64 %ld29, 1
  store i64 %add30, ptr %slot18, align 8
  br label %lhead19

then32:                                           ; preds = %lexit20
  %x35 = extractvalue { i1, i64 } %ld31, 1
  br label %endif34

else33:                                           ; preds = %lexit20
  %25 = call i64 @avra_array_len(ptr %3)
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval36 = phi i64 [ %x35, %then32 ], [ %25, %else33 ]
  %26 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %26, i64 0)
  call void @avra_array_push(ptr %26, i64 %regval36)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %26
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l177"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 %1)
  %5 = call i64 @avra_array_get(ptr %2, i64 %4)
  %cmp = icmp eq i64 %5, 0
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eout_of_bounds"(ptr, i64, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Etext_of_octets"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eutf8_text"(ptr %0)
  %cmp = icmp ne ptr %1, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  br label %endif

else:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 8)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %1, %then ], [ null, %postret ]
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 3)
  call void @avra_array_push_owned(ptr %3, ptr %regval)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_retain(ptr null)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_of_list_val"(ptr %0, ptr %1) {
entry:
  %slot5 = alloca i64, align 8
  %slot4 = alloca i1, align 1
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %1)
  %2 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Earray_id"(ptr %1)
  %x = extractvalue { i1, i64 } %2, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %2, 1
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Edefect_val"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

endif:                                            ; preds = %postret, %then
  %regval = phi i64 [ %x1, %then ], [ 0, %postret ]
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %regval)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  store i1 false, ptr %slot4, align 8
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l289" to i64))
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %10 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot5, align 8
  br label %lhead6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %11 = call i64 @avra_array_get(ptr %6, i64 %ld2)
  %boxed = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed)
  call void @avra_array_push(ptr %4, i64 %12)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead6:                                           ; preds = %endif14, %lexit
  %ld8 = load i64, ptr %slot5, align 8
  %cmp9 = icmp slt i64 %ld8, %10
  br i1 %cmp9, label %lbody10, label %lexit7

lexit7:                                           ; preds = %lhead6
  %ld18 = load i1, ptr %slot4, align 8
  br i1 %ld18, label %then19, label %else20

lbody10:                                          ; preds = %lhead6
  %ld11 = load i64, ptr %slot5, align 8
  %13 = call i64 @avra_array_get(ptr %4, i64 %ld11)
  call void @avra_rc_retain(ptr %8)
  %cast = inttoptr i64 %9 to ptr
  %14 = call i1 %cast(ptr %8, i64 %13)
  br i1 %14, label %then12, label %else13

then12:                                           ; preds = %lbody10
  store i1 true, ptr %slot4, align 8
  store i64 %10, ptr %slot5, align 8
  br label %endif14

else13:                                           ; preds = %lbody10
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi i64 [ 0, %then12 ], [ 0, %else13 ]
  %ld16 = load i64, ptr %slot5, align 8
  %add17 = add i64 %ld16, 1
  store i64 %add17, ptr %slot5, align 8
  br label %lhead6

then19:                                           ; preds = %lexit7
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

else20:                                           ; preds = %lexit7
  br label %endif21

endif21:                                          ; preds = %else20, %postret22
  %regval23 = phi i64 [ 0, %postret22 ], [ 0, %else20 ]
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 4)
  call void @avra_array_push_owned(ptr %16, ptr %4)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

postret22:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  br label %endif21
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l289"(ptr %0, i64 %1) {
entry:
  %cmp = icmp slt i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp sgt i64 %1, 255
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_index_of_val"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed1)
  %cmp = icmp slt i64 %5, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %6 = call i64 @avra_array_len(ptr %3)
  %cmp2 = icmp sgt i64 %5, %6
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp2, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  %7 = call i64 @avra_array_len(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eout_of_bounds"(ptr %0, i64 %5, i64 %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval6 = phi i64 [ 0, %postret ], [ 0, %else4 ]
  %9 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed7 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed7)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed7)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eindex_of_octets"(ptr %3, ptr %10, i64 %5)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 0)
  call void @avra_array_push(ptr %12, i64 %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eindex_of_octets"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot5 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca { i1, i64 }, align 8
  %3 = call i64 @avra_array_len(ptr %0)
  %4 = call i64 @avra_array_len(ptr %1)
  %sub = sub i64 %3, %4
  %add = add i64 %sub, 1
  store { i1, i64 } zeroinitializer, ptr %slot, align 8
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l368" to i64))
  call void @avra_array_push_owned(ptr %5, ptr %0)
  call void @avra_array_push_owned(ptr %5, ptr %1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %7 = call ptr @avra_array_sized(i64 0)
  store i64 %2, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %add
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot5, align 8
  br label %lhead6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  call void @avra_array_push(ptr %7, i64 %ld2)
  %ld3 = load i64, ptr %slot1, align 8
  %add4 = add i64 %ld3, 1
  store i64 %add4, ptr %slot1, align 8
  br label %lhead

lhead6:                                           ; preds = %endif, %lexit
  %ld8 = load i64, ptr %slot5, align 8
  %cmp9 = icmp slt i64 %ld8, %8
  br i1 %cmp9, label %lbody10, label %lexit7

lexit7:                                           ; preds = %lhead6
  %ld14 = load { i1, i64 }, ptr %slot, align 8
  %x = extractvalue { i1, i64 } %ld14, 0
  br i1 %x, label %then15, label %else16

lbody10:                                          ; preds = %lhead6
  %ld11 = load i64, ptr %slot5, align 8
  %9 = call i64 @avra_array_get(ptr %7, i64 %ld11)
  call void @avra_rc_retain(ptr %5)
  %cast = inttoptr i64 %6 to ptr
  %10 = call i1 %cast(ptr %5, i64 %9)
  br i1 %10, label %then, label %else

then:                                             ; preds = %lbody10
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %9, 1
  store { i1, i64 } %pack, ptr %slot, align 8
  store i64 %8, ptr %slot5, align 8
  br label %endif

else:                                             ; preds = %lbody10
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld12 = load i64, ptr %slot5, align 8
  %add13 = add i64 %ld12, 1
  store i64 %add13, ptr %slot5, align 8
  br label %lhead6

then15:                                           ; preds = %lexit7
  %x18 = extractvalue { i1, i64 } %ld14, 1
  br label %endif17

else16:                                           ; preds = %lexit7
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval19 = phi i64 [ %x18, %then15 ], [ -1, %else16 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval19
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l368"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Ebegins_at"(ptr %2, ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ebegins_at"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot7 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 true, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l388" to i64))
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %7 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot7, align 8
  br label %lhead8

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %add = add i64 %2, %ld2
  %8 = call i64 @avra_array_get(ptr %0, i64 %add)
  %9 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  %cmp3 = icmp eq i64 %8, %9
  %slot4 = zext i1 %cmp3 to i64
  call void @avra_array_push(ptr %5, i64 %slot4)
  %ld5 = load i64, ptr %slot1, align 8
  %add6 = add i64 %ld5, 1
  store i64 %add6, ptr %slot1, align 8
  br label %lhead

lhead8:                                           ; preds = %endif, %lexit
  %ld10 = load i64, ptr %slot7, align 8
  %cmp11 = icmp slt i64 %ld10, %7
  br i1 %cmp11, label %lbody12, label %lexit9

lexit9:                                           ; preds = %lhead8
  %ld16 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld16

lbody12:                                          ; preds = %lhead8
  %ld13 = load i64, ptr %slot7, align 8
  %10 = call i64 @avra_array_get(ptr %5, i64 %ld13)
  %b = icmp ne i64 %10, 0
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %4 to ptr
  %11 = call i1 %cast(ptr %3, i1 %b)
  %not = xor i1 %11, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody12
  store i1 false, ptr %slot, align 8
  store i64 %7, ptr %slot7, align 8
  br label %endif

else:                                             ; preds = %lbody12
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld14 = load i64, ptr %slot7, align 8
  %add15 = add i64 %ld14, 1
  store i64 %add15, ptr %slot7, align 8
  br label %lhead8
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l388"(ptr %0, i1 %1) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i1 %1
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_slice_val"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed2)
  %cmp = icmp slt i64 %5, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp3 = icmp slt i64 %7, %5
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp3, %else ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif
  br label %endif6

else5:                                            ; preds = %endif
  %8 = call i64 @avra_array_len(ptr %3)
  %cmp7 = icmp sgt i64 %7, %8
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i1 [ true, %then4 ], [ %cmp7, %else5 ]
  br i1 %regval8, label %then9, label %else10

then9:                                            ; preds = %endif6
  %9 = call i64 @avra_array_len(ptr %3)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 4)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eslice_out_of_bounds"(ptr %0, i64 %5, i64 %7, i64 %9, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else10:                                           ; preds = %endif6
  br label %endif11

endif11:                                          ; preds = %else10, %postret
  %regval12 = phi i64 [ 0, %postret ], [ 0, %else10 ]
  %13 = call ptr @avra_array_slice(ptr %3, i64 %5, i64 %7)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 4)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif11
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ebytes_at_val"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eoctets"(ptr %0, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Ewhole"(ptr %0, ptr %boxed1)
  %cmp = icmp slt i64 %5, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %6 = call i64 @avra_array_len(ptr %3)
  %cmp2 = icmp sge i64 %5, %6
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp2, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  %7 = call i64 @avra_array_len(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EMachine$2Eout_of_bounds"(ptr %0, i64 %5, i64 %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval6 = phi i64 [ 0, %postret ], [ 0, %else4 ]
  %9 = call i64 @avra_array_get(ptr %3, i64 %5)
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_array_push(ptr %10, i64 %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif5
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Esame_octets"(ptr %0, ptr %1) {
entry:
  %slot7 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  %2 = call i64 @avra_array_len(ptr %0)
  %3 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp eq i64 %2, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  store i1 true, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l336" to i64))
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %lexit9
  %regval20 = phi i1 [ %ld19, %lexit9 ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval20

lhead:                                            ; preds = %lbody, %then
  %ld = load i64, ptr %slot1, align 8
  %cmp2 = icmp slt i64 %ld, %7
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %8 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot7, align 8
  br label %lhead8

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %9 = call i64 @avra_array_get(ptr %0, i64 %ld3)
  %10 = call i64 @avra_array_get(ptr %1, i64 %ld3)
  %cmp4 = icmp eq i64 %9, %10
  %slot5 = zext i1 %cmp4 to i64
  call void @avra_array_push(ptr %6, i64 %slot5)
  %ld6 = load i64, ptr %slot1, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

lhead8:                                           ; preds = %endif16, %lexit
  %ld10 = load i64, ptr %slot7, align 8
  %cmp11 = icmp slt i64 %ld10, %8
  br i1 %cmp11, label %lbody12, label %lexit9

lexit9:                                           ; preds = %lhead8
  %ld19 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  br label %endif

lbody12:                                          ; preds = %lhead8
  %ld13 = load i64, ptr %slot7, align 8
  %11 = call i64 @avra_array_get(ptr %6, i64 %ld13)
  %b = icmp ne i64 %11, 0
  call void @avra_rc_retain(ptr %4)
  %cast = inttoptr i64 %5 to ptr
  %12 = call i1 %cast(ptr %4, i1 %b)
  %not = xor i1 %12, true
  br i1 %not, label %then14, label %else15

then14:                                           ; preds = %lbody12
  store i1 false, ptr %slot, align 8
  store i64 %8, ptr %slot7, align 8
  br label %endif16

else15:                                           ; preds = %lbody12
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval = phi i64 [ 0, %then14 ], [ 0, %else15 ]
  %ld17 = load i64, ptr %slot7, align 8
  %add18 = add i64 %ld17, 1
  store i64 %add18, ptr %slot7, align 8
  br label %lhead8
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Einterp_bytes$24l336"(ptr %0, i1 %1) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i1 %1
}
