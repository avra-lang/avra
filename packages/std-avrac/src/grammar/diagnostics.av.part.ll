; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"(lexing)\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"input\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c", \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c" or \00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"a \00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"one of the group\00" }, align 16

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

define ptr @"av_$40std$2Eavrac$2Egrammar$2Elex_diagnostic"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 4)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %5, ptr %1)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_array_push_owned(ptr %5, ptr %boxed)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Ejoin_expected"(ptr %0) {
entry:
  %slot13 = alloca ptr, align 8
  store ptr null, ptr %slot13, align 8
  %slot7 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp eq i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.1, i64 16)

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call i64 @avra_array_len(ptr %0)
  %cmp1 = icmp eq i64 %2, 1
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif

then2:                                            ; preds = %endif
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  store i64 1, ptr %slot7, align 8
  br label %lhead

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %3)
  br label %endif4

lhead:                                            ; preds = %lbody, %endif4
  %ld = load i64, ptr %slot7, align 8
  %5 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %5, 1
  %cmp8 = icmp slt i64 %ld, %sub
  br i1 %cmp8, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld12 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld12)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot13)
  store ptr null, ptr %slot13, align 8
  %6 = call i64 @avra_array_len(ptr %0)
  %cmp14 = icmp slt i64 0, %6
  br i1 %cmp14, label %then15, label %else16

lbody:                                            ; preds = %lhead
  %ld9 = load ptr, ptr %slot, align 8
  %ld10 = load i64, ptr %slot7, align 8
  %7 = call i64 @avra_array_get(ptr %0, i64 %ld10)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %ld9)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %boxed)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  %ld11 = load i64, ptr %slot7, align 8
  %add = add i64 %ld11, 1
  store i64 %add, ptr %slot7, align 8
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %lhead

then15:                                           ; preds = %lexit
  %sub18 = sub i64 %6, 1
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 %sub18)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot13)
  store ptr %10, ptr %slot13, align 8
  call void @avra_rc_release(ptr %10)
  br label %endif17

else16:                                           ; preds = %lexit
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval19 = phi i64 [ 0, %then15 ], [ 0, %else16 ]
  %ld20 = load ptr, ptr %slot13, align 8
  %11 = call ptr @avra_insist(ptr %ld20)
  %12 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %12, ptr %ld12)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %13 = call ptr @avra_str_join(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_cell_release(ptr %slot13)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %ld12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %13
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Eshown_expected"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr)

define ptr @"av_$40std$2Eavrac$2Egrammar$2Eappended_expected"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_array_len(ptr %1)
  %cmp1 = icmp eq i64 %3, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %1)
  ret ptr %0

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %4 = call ptr @avra_array_concat(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret5:                                         ; No predecessors!
  br label %endif4
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Edescribe_prim"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm3 [
    i64 1, label %arm
    i64 2, label %arm1
    i64 0, label %arm2
  ]

arm:                                              ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %boxed)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %4 = call ptr @avra_str_join(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed4 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %boxed4)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %8 = call ptr @avra_str_join(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ], [ %8, %arm2 ], [ getelementptr inbounds (i8, ptr @.str.16, i64 16), %arm3 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}
