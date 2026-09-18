; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"..\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"..\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"..\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"/\00" }, align 16

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

define ptr @"av_$40std$2Epath$2Ejoined_path"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %3 = call i1 @"av_$40std$2Epath$2Eis_absolute"(ptr %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %3, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  %4 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  br label %endif3
}

define i1 @"av_$40std$2Epath$2Eis_absolute"(ptr %0) {
entry:
  %1 = call i64 @avra_str_starts_with(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %b = icmp ne i64 %1, 0
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Epath$2Edir_of"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call i64 @"av_$40std$2Epath$2Elast_slash"(ptr %0)
  %cmp = icmp slt i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.5, i64 16)

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_str_substring(ptr %0, i64 0, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif
}

define i64 @"av_$40std$2Epath$2Elast_slash"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call i64 @avra_str_len(ptr %0)
  %sub = sub i64 %1, 1
  store i64 %sub, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret i64 -1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %2 = call i64 @avra_str_char_code(ptr %0, i64 %ld1)
  %cmp2 = icmp eq i64 %2, 47
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld3

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %sub5 = sub i64 %ld4, 1
  store i64 %sub5, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define i1 @"av_$40std$2Epath$2Eunder_dir"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_str_len(ptr %1)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_str_len(ptr %0)
  %4 = call i64 @avra_str_len(ptr %1)
  %add = add i64 %4, 1
  %cmp1 = icmp sgt i64 %3, %add
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %5 = call i64 @avra_str_len(ptr %1)
  %add5 = add i64 %5, 1
  %6 = call ptr @avra_str_substring(ptr %0, i64 0, i64 %add5)
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %1)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  %8 = call ptr @avra_str_join(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %9 = call i64 @avra_streq(ptr %6, ptr %8)
  %b = icmp ne i64 %9, 0
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %6)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ %b, %then2 ], [ false, %else3 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval6
}

define ptr @"av_$40std$2Epath$2Enormalized"(ptr %0) {
entry:
  %slot25 = alloca ptr, align 8
  store ptr null, ptr %slot25, align 8
  %slot11 = alloca ptr, align 8
  store ptr null, ptr %slot11, align 8
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_str_split(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif38, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld65 = load ptr, ptr %slot, align 8
  %4 = call i64 @avra_array_len(ptr %ld65)
  %cmp66 = icmp eq i64 %4, 1
  br i1 %cmp66, label %then67, label %else68

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot2)
  store ptr %5, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  %6 = call i64 @avra_streq(ptr %ld4, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %b = icmp ne i64 %6, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  %ld5 = load ptr, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %ld5)
  %cmp6 = icmp eq i64 %7, 0
  %not = xor i1 %cmp6, true
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not, %then ], [ false, %else ]
  br i1 %regval, label %then7, label %else8

then7:                                            ; preds = %endif
  %ld10 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld10)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot11)
  store ptr null, ptr %slot11, align 8
  %8 = call i64 @avra_array_len(ptr %ld10)
  %cmp12 = icmp slt i64 0, %8
  br i1 %cmp12, label %then13, label %else14

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %endif15
  %regval20 = phi i1 [ %not19, %endif15 ], [ false, %else8 ]
  br i1 %regval20, label %then21, label %else22

then13:                                           ; preds = %then7
  %sub = sub i64 %8, 1
  %9 = call ptr @avra_array_get_owned(ptr %ld10, i64 %sub)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot11)
  store ptr %9, ptr %slot11, align 8
  call void @avra_rc_release(ptr %9)
  br label %endif15

else14:                                           ; preds = %then7
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval16 = phi i64 [ 0, %then13 ], [ 0, %else14 ]
  %ld17 = load ptr, ptr %slot11, align 8
  %10 = call ptr @avra_insist(ptr %ld17)
  %11 = call i64 @avra_streq(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %b18 = icmp ne i64 %11, 0
  %not19 = xor i1 %b18, true
  call void @avra_cell_release(ptr %slot11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld10)
  br label %endif9

then21:                                           ; preds = %endif9
  %ld24 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld24)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot25)
  store ptr null, ptr %slot25, align 8
  %12 = call i64 @avra_array_len(ptr %ld24)
  %cmp26 = icmp slt i64 0, %12
  br i1 %cmp26, label %then27, label %else28

else22:                                           ; preds = %endif9
  br label %endif23

endif23:                                          ; preds = %else22, %endif29
  %regval35 = phi i1 [ %not34, %endif29 ], [ false, %else22 ]
  br i1 %regval35, label %then36, label %else37

then27:                                           ; preds = %then21
  %sub30 = sub i64 %12, 1
  %13 = call ptr @avra_array_get_owned(ptr %ld24, i64 %sub30)
  call void @avra_rc_retain(ptr %13)
  call void @avra_cell_release(ptr %slot25)
  store ptr %13, ptr %slot25, align 8
  call void @avra_rc_release(ptr %13)
  br label %endif29

else28:                                           ; preds = %then21
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval31 = phi i64 [ 0, %then27 ], [ 0, %else28 ]
  %ld32 = load ptr, ptr %slot25, align 8
  %14 = call ptr @avra_insist(ptr %ld32)
  %15 = call i64 @avra_str_len(ptr %14)
  %cmp33 = icmp eq i64 %15, 0
  %not34 = xor i1 %cmp33, true
  call void @avra_cell_release(ptr %slot25)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %ld24)
  br label %endif23

then36:                                           ; preds = %endif23
  %ld39 = load ptr, ptr %slot, align 8
  %ld40 = load ptr, ptr %slot, align 8
  %16 = call i64 @avra_array_len(ptr %ld40)
  %sub41 = sub i64 %16, 1
  %17 = call ptr @avra_array_slice(ptr %ld39, i64 0, i64 %sub41)
  call void @avra_rc_retain(ptr %17)
  call void @avra_cell_release(ptr %slot)
  store ptr %17, ptr %slot, align 8
  call void @avra_rc_release(ptr %17)
  br label %endif38

else37:                                           ; preds = %endif23
  %ld42 = load ptr, ptr %slot2, align 8
  %18 = call i64 @avra_streq(ptr %ld42, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %b43 = icmp ne i64 %18, 0
  %not44 = xor i1 %b43, true
  br i1 %not44, label %then45, label %else46

endif38:                                          ; preds = %endif60, %then36
  %regval63 = phi i64 [ 0, %then36 ], [ 0, %endif60 ]
  %ld64 = load i64, ptr %slot1, align 8
  %add = add i64 %ld64, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %5)
  br label %lhead

then45:                                           ; preds = %else37
  %ld48 = load ptr, ptr %slot2, align 8
  %19 = call i64 @avra_str_len(ptr %ld48)
  %cmp49 = icmp eq i64 %19, 0
  %not50 = xor i1 %cmp49, true
  br i1 %not50, label %then51, label %else52

else46:                                           ; preds = %else37
  br label %endif47

endif47:                                          ; preds = %else46, %endif53
  %regval57 = phi i1 [ %regval56, %endif53 ], [ false, %else46 ]
  br i1 %regval57, label %then58, label %else59

then51:                                           ; preds = %then45
  br label %endif53

else52:                                           ; preds = %then45
  %ld54 = load ptr, ptr %slot, align 8
  %20 = call i64 @avra_array_len(ptr %ld54)
  %cmp55 = icmp eq i64 %20, 0
  br label %endif53

endif53:                                          ; preds = %else52, %then51
  %regval56 = phi i1 [ true, %then51 ], [ %cmp55, %else52 ]
  br label %endif47

then58:                                           ; preds = %endif47
  %21 = call ptr @avra_cell_unique(ptr %slot)
  %ld61 = load ptr, ptr %slot2, align 8
  call void @avra_array_push_owned(ptr %21, ptr %ld61)
  br label %endif60

else59:                                           ; preds = %endif47
  br label %endif60

endif60:                                          ; preds = %else59, %then58
  %regval62 = phi i64 [ 0, %then58 ], [ 0, %else59 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  br label %endif38

then67:                                           ; preds = %lexit
  %ld70 = load ptr, ptr %slot, align 8
  %22 = call i64 @avra_array_get(ptr %ld70, i64 0)
  %boxed = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_str_len(ptr %boxed)
  %cmp71 = icmp eq i64 %23, 0
  br label %endif69

else68:                                           ; preds = %lexit
  br label %endif69

endif69:                                          ; preds = %else68, %then67
  %regval72 = phi i1 [ %cmp71, %then67 ], [ false, %else68 ]
  br i1 %regval72, label %then73, label %else74

then73:                                           ; preds = %endif69
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.13, i64 16)

else74:                                           ; preds = %endif69
  br label %endif75

endif75:                                          ; preds = %else74, %postret
  %regval76 = phi i64 [ 0, %postret ], [ 0, %else74 ]
  %ld77 = load ptr, ptr %slot, align 8
  %24 = call ptr @avra_str_join(ptr %ld77, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %24

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  br label %endif75
}

define ptr @"av_$40std$2Epath$2Erelative_path"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Epath$2Esegments"(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Epath$2Esegments"(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Epath$2Eshared_prefix"(ptr %2, ptr %3)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %2)
  %7 = call ptr @avra_array_slice(ptr %2, i64 %4, i64 %6)
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call i64 @avra_array_len(ptr %3)
  %10 = call ptr @avra_array_slice(ptr %3, i64 %4, i64 %9)
  %11 = call ptr @avra_array_concat(ptr %5, ptr %10)
  %12 = call ptr @avra_str_join(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %13 = call i64 @avra_array_get(ptr %7, i64 %ld1)
  %boxed = inttoptr i64 %13 to ptr
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  br label %lhead
}

define i64 @"av_$40std$2Epath$2Eshared_prefix"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %3 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp slt i64 %2, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_len(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %5 = call i64 @avra_array_len(ptr %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %4, %then ], [ %5, %else ]
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %regval
  br i1 %cmp1, label %then2, label %else3

lexit:                                            ; preds = %endif4
  %ld10 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %ld10

then2:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %0, i64 %ld5)
  %boxed = inttoptr i64 %6 to ptr
  %ld6 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %1, i64 %ld6)
  %boxed7 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_streq(ptr %boxed, ptr %boxed7)
  %b = icmp ne i64 %8, 0
  br label %endif4

else3:                                            ; preds = %lhead
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval8 = phi i1 [ %b, %then2 ], [ false, %else3 ]
  br i1 %regval8, label %lbody, label %lexit

lbody:                                            ; preds = %endif4
  %ld9 = load i64, ptr %slot, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Epath$2Esegments"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_str_split(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 %ld1)
  %5 = call i64 @avra_str_len(ptr %4)
  %cmp2 = icmp eq i64 %5, 0
  %not = xor i1 %cmp2, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_array_push_owned(ptr %1, ptr %4)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define ptr @"av_$40std$2Epath$2Ehead_segment"(ptr %0) {
entry:
  %1 = call i64 @avra_str_index_of(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  %cmp = icmp slt i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  ret ptr %0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_str_substring(ptr %0, i64 0, i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %2

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Epath$2Estem_of"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Epath$2Efile_name"(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Epath$2Eextension_dot"(ptr %1)
  %cmp = icmp slt i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_str_substring(ptr %1, i64 0, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Epath$2Eextension_dot"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call i64 @avra_str_len(ptr %0)
  %sub = sub i64 %1, 1
  store i64 %sub, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp sgt i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret i64 -1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %2 = call i64 @avra_str_char_code(ptr %0, i64 %ld1)
  %cmp2 = icmp eq i64 %2, 46
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld3

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %sub5 = sub i64 %ld4, 1
  store i64 %sub5, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Epath$2Efile_name"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call i64 @"av_$40std$2Epath$2Elast_slash"(ptr %0)
  %add = add i64 %1, 1
  %2 = call i64 @avra_str_len(ptr %0)
  %3 = call ptr @avra_str_substring(ptr %0, i64 %add, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}
