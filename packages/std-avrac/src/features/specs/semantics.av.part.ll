; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.nested_spec\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"spec blocks\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [23 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 22 }, [23 x i8] c"resolve.duplicate_case\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c" / \00" }, align 16
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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eduplicate_names"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Especs$2ESpecSemantics$2Eresolve_stmt"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot8 = alloca ptr, align 8
  store ptr null, ptr %slot8, align 8
  %slot7 = alloca i64, align 8
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Erefuses_nested"(ptr %1, i64 %2, ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm2 [
    i64 21, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %1)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %1, i64 %2)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Especs$2Erepeated_cases"(ptr %8, ptr %9, ptr %10)
  %12 = call i64 @avra_array_len(ptr %11)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm2:                                             ; preds = %endif
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %lexit10
  %regval18 = phi i64 [ 0, %lexit10 ], [ %13, %arm2 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval18

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %12
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %14 = call i64 @avra_array_len(ptr %9)
  store i64 0, ptr %slot7, align 8
  br label %lhead9

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %15 = call ptr @avra_array_get_owned(ptr %11, i64 %ld4)
  call void @avra_rc_retain(ptr %15)
  call void @avra_cell_release(ptr %slot3)
  store ptr %15, ptr %slot3, align 8
  %ld5 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %ld5)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %1, ptr %ld5)
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %15)
  br label %lhead

lhead9:                                           ; preds = %lbody13, %lexit
  %ld11 = load i64, ptr %slot7, align 8
  %cmp12 = icmp slt i64 %ld11, %14
  br i1 %cmp12, label %lbody13, label %lexit10

lexit10:                                          ; preds = %lhead9
  call void @avra_cell_release(ptr %slot8)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

lbody13:                                          ; preds = %lhead9
  %ld14 = load i64, ptr %slot7, align 8
  %17 = call ptr @avra_array_get_owned(ptr %9, i64 %ld14)
  call void @avra_rc_retain(ptr %17)
  call void @avra_cell_release(ptr %slot8)
  store ptr %17, ptr %slot8, align 8
  %18 = call ptr @avra_array_sized(i64 0)
  %ld15 = load ptr, ptr %slot8, align 8
  %19 = call i64 @avra_array_get(ptr %ld15, i64 2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %18)
  %20 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_under"(ptr %1, ptr %18, i64 %19)
  %ld16 = load i64, ptr %slot7, align 8
  %add17 = add i64 %ld16, 1
  store i64 %add17, ptr %slot7, align 8
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %lhead9
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_under"(ptr, ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Especs$2Erepeated_cases"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot11 = alloca i64, align 8
  %slot4 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %4)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edistinct"(ptr %4)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed2 = inttoptr i64 %9 to ptr
  call void @avra_array_push_owned(ptr %4, ptr %boxed2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead5:                                           ; preds = %lexit13, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %7
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr %3)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %11 = call ptr @avra_array_get_owned(ptr %6, i64 %ld10)
  %12 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %12, ptr %0)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_array_push_owned(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %13 = call ptr @avra_str_join(ptr %12, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot11, align 8
  br label %lhead12

lhead12:                                          ; preds = %endif, %lbody9
  %ld14 = load i64, ptr %slot11, align 8
  %cmp15 = icmp slt i64 %ld14, %15
  br i1 %cmp15, label %lbody16, label %lexit13

lexit13:                                          ; preds = %lhead12
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %2)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eduplicate_names"(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %13, ptr %14, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %16)
  %ld22 = load i64, ptr %slot4, align 8
  %add23 = add i64 %ld22, 1
  store i64 %add23, ptr %slot4, align 8
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %11)
  br label %lhead5

lbody16:                                          ; preds = %lhead12
  %ld17 = load i64, ptr %slot11, align 8
  %17 = call ptr @avra_array_get_owned(ptr %1, i64 %ld17)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %boxed18 = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_streq(ptr %boxed18, ptr %11)
  %b = icmp ne i64 %19, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody16
  %20 = call i64 @avra_array_get(ptr %17, i64 1)
  %boxed19 = inttoptr i64 %20 to ptr
  call void @avra_array_push_owned(ptr %14, ptr %boxed19)
  br label %endif

else:                                             ; preds = %lbody16
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld20 = load i64, ptr %slot11, align 8
  %add21 = add i64 %ld20, 1
  store i64 %add21, ptr %slot11, align 8
  call void @avra_rc_release(ptr %17)
  br label %lhead12
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EResolveCx$2Erefuses_nested"(ptr, i64, ptr, ptr)
