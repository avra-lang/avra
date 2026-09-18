; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\22\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\22\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"\\\22\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"\\\\\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"\\$\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"\\n\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"\\t\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"\\r\00" }, align 16

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

define ptr @"av_$40std$2Eavrac$2Ecore$2Equoted_text"(ptr %0) {
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
  %3 = call ptr @avra_str_join(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %4 = call ptr @avra_str_concat(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %3)
  %5 = call ptr @avra_str_concat(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_str_char_code(ptr %0, i64 %ld1)
  %add = add i64 %ld1, 1
  %7 = call ptr @avra_str_substring(ptr %0, i64 %ld1, i64 %add)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eescaped_char"(i64 %6, ptr %7)
  call void @avra_array_push_owned(ptr %1, ptr %8)
  %ld2 = load i64, ptr %slot, align 8
  %add3 = add i64 %ld2, 1
  store i64 %add3, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eescaped_char"(i64 %0, ptr %1) {
entry:
  %cmp = icmp eq i64 %0, 34
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp eq i64 %0, 92
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval25 = phi ptr [ getelementptr inbounds (i8, ptr @.str.3, i64 16), %then ], [ %regval24, %endif4 ]
  call void @avra_rc_release(ptr %1)
  ret ptr %regval25

then2:                                            ; preds = %else
  br label %endif4

else3:                                            ; preds = %else
  %cmp5 = icmp eq i64 %0, 36
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval24 = phi ptr [ getelementptr inbounds (i8, ptr @.str.4, i64 16), %then2 ], [ %regval23, %endif8 ]
  br label %endif

then6:                                            ; preds = %else3
  br label %endif8

else7:                                            ; preds = %else3
  %cmp9 = icmp eq i64 %0, 10
  br i1 %cmp9, label %then10, label %else11

endif8:                                           ; preds = %endif12, %then6
  %regval23 = phi ptr [ getelementptr inbounds (i8, ptr @.str.5, i64 16), %then6 ], [ %regval22, %endif12 ]
  br label %endif4

then10:                                           ; preds = %else7
  br label %endif12

else11:                                           ; preds = %else7
  %cmp13 = icmp eq i64 %0, 9
  br i1 %cmp13, label %then14, label %else15

endif12:                                          ; preds = %endif16, %then10
  %regval22 = phi ptr [ getelementptr inbounds (i8, ptr @.str.6, i64 16), %then10 ], [ %regval21, %endif16 ]
  br label %endif8

then14:                                           ; preds = %else11
  br label %endif16

else15:                                           ; preds = %else11
  %cmp17 = icmp eq i64 %0, 13
  br i1 %cmp17, label %then18, label %else19

endif16:                                          ; preds = %endif20, %then14
  %regval21 = phi ptr [ getelementptr inbounds (i8, ptr @.str.7, i64 16), %then14 ], [ %regval, %endif20 ]
  br label %endif12

then18:                                           ; preds = %else15
  br label %endif20

else19:                                           ; preds = %else15
  call void @avra_rc_retain(ptr %1)
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.8, i64 16), %then18 ], [ %1, %else19 ]
  br label %endif16
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eall_codes"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %2 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_str_char_code(ptr %0, i64 %ld1)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %1)
  %cast = inttoptr i64 %4 to ptr
  %5 = call i1 %cast(ptr %1, i64 %3)
  %not = xor i1 %5, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit$24w"(ptr %0, i64 %1) {
entry:
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2

entry1:                                           ; No predecessors!
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3

entry2:                                           ; No predecessors!
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4

entry3:                                           ; No predecessors!
  %5 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %5
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %0) {
entry:
  %cmp = icmp sge i64 %0, 48
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %cmp1 = icmp sle i64 %0, 57
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_cont$24w"(ptr %0, i64 %1) {
entry:
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_cont"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2

entry1:                                           ; No predecessors!
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_cont"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3

entry2:                                           ; No predecessors!
  %4 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_cont"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_cont"(i64 %0) {
entry:
  %1 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_start"(i64 %0)
  br i1 %1, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %0)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %2, %else ]
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_name_start"(i64 %0) {
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
  br label %endif4

else3:                                            ; preds = %endif
  %cmp5 = icmp sge i64 %0, 97
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval11 = phi i1 [ true, %then2 ], [ %regval10, %endif8 ]
  br i1 %regval11, label %then12, label %else13

then6:                                            ; preds = %else3
  %cmp9 = icmp sle i64 %0, 122
  br label %endif8

else7:                                            ; preds = %else3
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval10 = phi i1 [ %cmp9, %then6 ], [ false, %else7 ]
  br label %endif4

then12:                                           ; preds = %endif4
  br label %endif14

else13:                                           ; preds = %endif4
  %cmp15 = icmp eq i64 %0, 95
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  ret i1 %regval16
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_space"(i64 %0) {
entry:
  %cmp = icmp eq i64 %0, 32
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp eq i64 %0, 9
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %cmp5 = icmp eq i64 %0, 13
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  ret i1 %regval6
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_upper_name_cont$24w"(ptr %0, i64 %1) {
entry:
  %2 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_upper_name_cont"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eis_upper_name_cont"(i64 %0) {
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
  br label %endif4

else3:                                            ; preds = %endif
  %cmp5 = icmp eq i64 %0, 95
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %1 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eis_digit"(i64 %0)
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval10 = phi i1 [ true, %then7 ], [ %1, %else8 ]
  ret i1 %regval10
}
