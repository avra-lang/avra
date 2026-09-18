; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\0A\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [36 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 35 }, [36 x i8] c"avra: could not read the link plan \00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c" \E2\80\94 \00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [74 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 73 }, [74 x i8] c"the binary could not start \E2\80\94 the link answered a path that does not run\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [87 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 86 }, [87 x i8] c"STOPPED \E2\80\94 the case or program named above trapped, and everything after it never ran\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"avra: \00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [61 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 60 }, [61 x i8] c" is not a link plan \E2\80\94 clang's words, the binary after `-o`\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i64 @"av_$40std$2Eprocess$2Estatus_of"(ptr)

declare i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr)

declare i64 @"av_$40std$2Eprelude$2Eprintln"(ptr)

define { i1, i64 } @av_light_phase(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Estaged_plans"(ptr %0)
  %cmp = icmp ne ptr %1, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %1, %then ], [ null, %postret ]
  call void @avra_rc_retain(ptr %regval)
  %2 = call i64 @av_first_red(ptr %regval)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %2, 1
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %pack

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif
}

define i64 @av_first_red(ptr %0) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot1)
  store ptr %2, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld3)
  %3 = call i64 @av_plan_ran(ptr %ld3)
  %cmp4 = icmp ne i64 %3, 0
  br i1 %cmp4, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %2)
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @av_plan_ran(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eio$2Eread_text"(ptr %0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_str_split(ptr %boxed, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @av_words_ran(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eio$2EIoError$2Edescribe"(ptr %boxed2)
  %8 = call i64 @avra_array_get(ptr %7, i64 1)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed3)
  %9 = call i64 @av_unreadable_plan(ptr %0, ptr %boxed3)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi i64 [ %5, %arm ], [ %9, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @av_unreadable_plan(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %3 = call ptr @avra_str_join(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 2
}

declare ptr @"av_$40std$2Eio$2EIoError$2Edescribe"(ptr)

define i64 @av_words_ran(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eplan_binary"(ptr %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %2)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @av_not_a_plan(ptr %0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %2, %then ], [ null, %postret ]
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_commands$2Eclang_ran"(ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm1 [
    i64 0, label %arm
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

arm:                                              ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %regval)
  %7 = call i64 @"av_commands$2Ejudged_link"(ptr %boxed, ptr %regval)
  br label %endswitch

arm1:                                             ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %9 = call i64 @"av_commands$2Erefused_by_host"(ptr %boxed2)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval3 = phi i64 [ %7, %arm ], [ %9, %arm1 ]
  %cmp4 = icmp ne i64 %regval3, 0
  br i1 %cmp4, label %then5, label %else6

then5:                                            ; preds = %endswitch
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 1

else6:                                            ; preds = %endswitch
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  call void @avra_rc_retain(ptr %regval)
  %10 = call ptr @"av_commands$2Erun_binary"(ptr %regval)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  switch i64 %11, label %arm11 [
    i64 0, label %arm10
  ]

postret8:                                         ; No predecessors!
  br label %endif7

arm10:                                            ; preds = %endif7
  %12 = call i64 @avra_array_get(ptr %10, i64 1)
  %boxed13 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed13)
  %13 = call i64 @"av_$40std$2Eprocess$2Estatus_of"(ptr %boxed13)
  %14 = call i64 @av_judged(i64 %13)
  br label %endswitch12

arm11:                                            ; preds = %endif7
  %15 = call i64 @avra_array_get(ptr %10, i64 1)
  %boxed14 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %boxed14)
  %16 = call i64 @"av_commands$2Erefused_by_host"(ptr %boxed14)
  br label %endswitch12

endswitch12:                                      ; preds = %arm11, %arm10
  %regval15 = phi i64 [ %14, %arm10 ], [ %16, %arm11 ]
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval15
}

define i64 @av_judged(i64 %0) {
entry:
  %1 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Everdict_of"(i64 %0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm3 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
  ]

arm:                                              ; preds = %entry
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %3 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endswitch

arm3:                                             ; preds = %entry
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %4 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi i64 [ 0, %arm ], [ 1, %arm1 ], [ 1, %arm2 ], [ 1, %arm3 ]
  call void @avra_rc_release(ptr %1)
  ret i64 %regval
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Everdict_of"(i64)

declare ptr @"av_commands$2Erun_binary"(ptr)

declare i64 @"av_commands$2Erefused_by_host"(ptr)

declare i64 @"av_commands$2Ejudged_link"(ptr, ptr)

declare ptr @"av_commands$2Eclang_ran"(ptr)

define i64 @av_not_a_plan(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %2 = call ptr @avra_str_join(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 2
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eplan_binary"(ptr)

declare ptr @"av_$40std$2Eio$2Eread_text"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Estaged_plans"(ptr)
