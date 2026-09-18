; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c" \00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"s\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

define ptr @"av_$40std$2Eavrac$2Ecore$2Esorted_texts"(ptr %0) {
entry:
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

lhead:                                            ; preds = %lexit7, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld20 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld20)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld20

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot, align 8
  %4 = call i64 @avra_array_len(ptr %ld4)
  store i64 %4, ptr %slot5, align 8
  br label %lhead6

lhead6:                                           ; preds = %lbody13, %lbody
  %ld8 = load i64, ptr %slot5, align 8
  %cmp9 = icmp sgt i64 %ld8, 0
  br i1 %cmp9, label %then, label %else

lexit7:                                           ; preds = %endif
  %ld16 = load ptr, ptr %slot, align 8
  %ld17 = load i64, ptr %slot5, align 8
  %ld18 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld16)
  call void @avra_rc_retain(ptr %ld18)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$2411"(ptr %ld16, i64 %ld17, ptr %ld18)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  %ld19 = load i64, ptr %slot1, align 8
  %add = add i64 %ld19, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  br label %lhead

then:                                             ; preds = %lhead6
  %ld10 = load ptr, ptr %slot2, align 8
  %ld11 = load ptr, ptr %slot, align 8
  %ld12 = load i64, ptr %slot5, align 8
  %sub = sub i64 %ld12, 1
  %6 = call i64 @avra_array_get(ptr %ld11, i64 %sub)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %ld10)
  call void @avra_rc_retain(ptr %boxed)
  %7 = call i1 @"av_$40std$2Eavrac$2Ecore$2Etext_before"(ptr %ld10, ptr %boxed)
  br label %endif

else:                                             ; preds = %lhead6
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %7, %then ], [ false, %else ]
  br i1 %regval, label %lbody13, label %lexit7

lbody13:                                          ; preds = %endif
  %ld14 = load i64, ptr %slot5, align 8
  %sub15 = sub i64 %ld14, 1
  store i64 %sub15, ptr %slot5, align 8
  br label %lhead6
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Einserted$2411"(ptr, i64, ptr)

define i1 @"av_$40std$2Eavrac$2Ecore$2Etext_before"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_str_len(ptr %0)
  %3 = call i64 @avra_str_len(ptr %1)
  %cmp = icmp slt i64 %2, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_str_len(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %5 = call i64 @avra_str_len(ptr %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %4, %then ], [ %5, %else ]
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif7, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %regval
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %6 = call i64 @avra_str_len(ptr %0)
  %7 = call i64 @avra_str_len(ptr %1)
  %cmp11 = icmp slt i64 %6, %7
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp11

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_str_char_code(ptr %0, i64 %ld2)
  %ld3 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_str_char_code(ptr %1, i64 %ld3)
  %cmp4 = icmp ne i64 %8, %9
  br i1 %cmp4, label %then5, label %else6

then5:                                            ; preds = %lbody
  %cmp8 = icmp slt i64 %8, %9
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp8

else6:                                            ; preds = %lbody
  br label %endif7

endif7:                                           ; preds = %else6, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else6 ]
  %ld10 = load i64, ptr %slot, align 8
  %add = add i64 %ld10, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif7
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eclosest"(ptr %0, ptr %1) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif11, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld15 = load ptr, ptr %slot, align 8
  %cmp16 = icmp ne ptr %ld15, null
  br i1 %cmp16, label %then17, label %else18

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 %ld3)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot2)
  store ptr %3, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld4)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2Eedit_distance"(ptr %0, ptr %ld4)
  %ld5 = load ptr, ptr %slot, align 8
  %cmp6 = icmp ne ptr %ld5, null
  %not = xor i1 %cmp6, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  br label %endif

else:                                             ; preds = %lbody
  %ld7 = load ptr, ptr %slot, align 8
  %5 = call ptr @avra_insist(ptr %ld7)
  %6 = call i64 @avra_array_get(ptr %5, i64 1)
  %cmp8 = icmp slt i64 %4, %6
  call void @avra_rc_release(ptr %5)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp8, %else ]
  br i1 %regval, label %then9, label %else10

then9:                                            ; preds = %endif
  %ld12 = load ptr, ptr %slot2, align 8
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %7, ptr %ld12)
  call void @avra_array_push(ptr %7, i64 %4)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  br label %endif11

else10:                                           ; preds = %endif
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval13 = phi i64 [ 0, %then9 ], [ 0, %else10 ]
  %ld14 = load i64, ptr %slot1, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %3)
  br label %lhead

then17:                                           ; preds = %lexit
  %ld20 = load ptr, ptr %slot, align 8
  %8 = call ptr @avra_insist(ptr %ld20)
  %9 = call i64 @avra_array_get(ptr %8, i64 1)
  %cmp21 = icmp sge i64 %9, 1
  call void @avra_rc_release(ptr %8)
  br label %endif19

else18:                                           ; preds = %lexit
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval22 = phi i1 [ %cmp21, %then17 ], [ false, %else18 ]
  br i1 %regval22, label %then23, label %else24

then23:                                           ; preds = %endif19
  %ld26 = load ptr, ptr %slot, align 8
  %10 = call ptr @avra_insist(ptr %ld26)
  %11 = call i64 @avra_array_get(ptr %10, i64 1)
  %cmp27 = icmp sle i64 %11, 2
  call void @avra_rc_release(ptr %10)
  br label %endif25

else24:                                           ; preds = %endif19
  br label %endif25

endif25:                                          ; preds = %else24, %then23
  %regval28 = phi i1 [ %cmp27, %then23 ], [ false, %else24 ]
  br i1 %regval28, label %then29, label %else30

then29:                                           ; preds = %endif25
  %ld32 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld32)
  br label %endif31

else30:                                           ; preds = %endif25
  br label %endif31

endif31:                                          ; preds = %else30, %then29
  %regval33 = phi ptr [ %ld32, %then29 ], [ null, %else30 ]
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval33
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Eedit_distance"(ptr %0, ptr %1) {
entry:
  %slot36 = alloca i64, align 8
  %slot19 = alloca i64, align 8
  %slot18 = alloca ptr, align 8
  store ptr null, ptr %slot18, align 8
  %slot11 = alloca i64, align 8
  %slot7 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_str_len(ptr %0)
  %3 = call i64 @avra_str_len(ptr %1)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %cmp1 = icmp eq i64 %3, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  store i64 0, ptr %slot7, align 8
  br label %lhead

postret5:                                         ; No predecessors!
  br label %endif4

lhead:                                            ; preds = %lbody, %endif4
  %ld = load i64, ptr %slot7, align 8
  %cmp8 = icmp sle i64 %ld, %3
  br i1 %cmp8, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  store i64 1, ptr %slot11, align 8
  br label %lhead12

lbody:                                            ; preds = %lhead
  %5 = call ptr @avra_cell_unique(ptr %slot)
  %ld9 = load i64, ptr %slot7, align 8
  call void @avra_array_push(ptr %5, i64 %ld9)
  %ld10 = load i64, ptr %slot7, align 8
  %add = add i64 %ld10, 1
  store i64 %add, ptr %slot7, align 8
  br label %lhead

lhead12:                                          ; preds = %lexit21, %lexit
  %ld14 = load i64, ptr %slot11, align 8
  %cmp15 = icmp sle i64 %ld14, %2
  br i1 %cmp15, label %lbody16, label %lexit13

lexit13:                                          ; preds = %lhead12
  %ld71 = load ptr, ptr %slot, align 8
  %6 = call i64 @avra_str_len(ptr %1)
  %7 = call i64 @avra_array_get(ptr %ld71, i64 %6)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

lbody16:                                          ; preds = %lhead12
  %ld17 = load i64, ptr %slot11, align 8
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %ld17)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot18)
  store ptr %8, ptr %slot18, align 8
  store i64 1, ptr %slot19, align 8
  br label %lhead20

lhead20:                                          ; preds = %endif59, %lbody16
  %ld22 = load i64, ptr %slot19, align 8
  %cmp23 = icmp sle i64 %ld22, %3
  br i1 %cmp23, label %lbody24, label %lexit21

lexit21:                                          ; preds = %lhead20
  %ld68 = load ptr, ptr %slot18, align 8
  call void @avra_rc_retain(ptr %ld68)
  call void @avra_rc_retain(ptr %ld68)
  call void @avra_cell_release(ptr %slot)
  store ptr %ld68, ptr %slot, align 8
  %ld69 = load i64, ptr %slot11, align 8
  %add70 = add i64 %ld69, 1
  store i64 %add70, ptr %slot11, align 8
  call void @avra_cell_release(ptr %slot18)
  call void @avra_rc_release(ptr %ld68)
  call void @avra_rc_release(ptr %8)
  br label %lhead12

lbody24:                                          ; preds = %lhead20
  %ld25 = load i64, ptr %slot11, align 8
  %sub = sub i64 %ld25, 1
  %9 = call i64 @avra_str_char_code(ptr %0, i64 %sub)
  %ld26 = load i64, ptr %slot19, align 8
  %sub27 = sub i64 %ld26, 1
  %10 = call i64 @avra_str_char_code(ptr %1, i64 %sub27)
  %cmp28 = icmp eq i64 %9, %10
  br i1 %cmp28, label %then29, label %else30

then29:                                           ; preds = %lbody24
  br label %endif31

else30:                                           ; preds = %lbody24
  br label %endif31

endif31:                                          ; preds = %else30, %then29
  %regval32 = phi i64 [ 0, %then29 ], [ 1, %else30 ]
  %ld33 = load ptr, ptr %slot, align 8
  %ld34 = load i64, ptr %slot19, align 8
  %11 = call i64 @avra_array_get(ptr %ld33, i64 %ld34)
  %add35 = add i64 %11, 1
  store i64 %add35, ptr %slot36, align 8
  %ld37 = load ptr, ptr %slot18, align 8
  %ld38 = load i64, ptr %slot19, align 8
  %sub39 = sub i64 %ld38, 1
  %12 = call i64 @avra_array_get(ptr %ld37, i64 %sub39)
  %add40 = add i64 %12, 1
  %ld41 = load i64, ptr %slot36, align 8
  %cmp42 = icmp slt i64 %add40, %ld41
  br i1 %cmp42, label %then43, label %else44

then43:                                           ; preds = %endif31
  %ld46 = load ptr, ptr %slot18, align 8
  %ld47 = load i64, ptr %slot19, align 8
  %sub48 = sub i64 %ld47, 1
  %13 = call i64 @avra_array_get(ptr %ld46, i64 %sub48)
  %add49 = add i64 %13, 1
  store i64 %add49, ptr %slot36, align 8
  br label %endif45

else44:                                           ; preds = %endif31
  br label %endif45

endif45:                                          ; preds = %else44, %then43
  %regval50 = phi i64 [ 0, %then43 ], [ 0, %else44 ]
  %ld51 = load ptr, ptr %slot, align 8
  %ld52 = load i64, ptr %slot19, align 8
  %sub53 = sub i64 %ld52, 1
  %14 = call i64 @avra_array_get(ptr %ld51, i64 %sub53)
  %add54 = add i64 %14, %regval32
  %ld55 = load i64, ptr %slot36, align 8
  %cmp56 = icmp slt i64 %add54, %ld55
  br i1 %cmp56, label %then57, label %else58

then57:                                           ; preds = %endif45
  %ld60 = load ptr, ptr %slot, align 8
  %ld61 = load i64, ptr %slot19, align 8
  %sub62 = sub i64 %ld61, 1
  %15 = call i64 @avra_array_get(ptr %ld60, i64 %sub62)
  %add63 = add i64 %15, %regval32
  store i64 %add63, ptr %slot36, align 8
  br label %endif59

else58:                                           ; preds = %endif45
  br label %endif59

endif59:                                          ; preds = %else58, %then57
  %regval64 = phi i64 [ 0, %then57 ], [ 0, %else58 ]
  %16 = call ptr @avra_cell_unique(ptr %slot18)
  %ld65 = load i64, ptr %slot36, align 8
  call void @avra_array_push(ptr %16, i64 %ld65)
  %ld66 = load i64, ptr %slot19, align 8
  %add67 = add i64 %ld66, 1
  store i64 %add67, ptr %slot19, align 8
  br label %lhead20
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ecounted"(i64 %0, ptr %1) {
entry:
  %2 = call ptr @avra_int_text(i64 %0)
  %cmp = icmp eq i64 %0, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.3, i64 16), %then ], [ getelementptr inbounds (i8, ptr @.str.4, i64 16), %else ]
  %3 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %regval)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %4 = call ptr @avra_str_join(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  ret ptr %4
}
