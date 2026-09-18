; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.mismatch\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"`for \E2\80\A6 in` walks a `List`, this is `\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [31 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 30 }, [31 x i8] c"ranges spell `for i in lo..hi`\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.mismatch\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"`for` walks an empty literal \E2\80\94 nothing to bind\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"always empty\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [56 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 55 }, [56 x i8] c"the loop would never run; drop it, or walk a named list\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"starts\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"ends\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.mismatch\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"a `for` range \00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [22 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 21 }, [22 x i8] c" at an `int`, found `\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"a `while` condition\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [22 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 21 }, [22 x i8] c"this decides the loop\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eshape_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_for_each"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 17, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %7 = call i64 @avra_array_get(ptr %4, i64 3)
  %8 = call ptr @avra_array_get_owned(ptr %4, i64 4)
  %cmp = icmp ne ptr %6, null
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif
  %regval3 = phi i64 [ %14, %endif ], [ %9, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval3

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epair"(ptr %0, i64 %7)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %7)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Ewalked_elem"(ptr %0, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_binding"(ptr %0, i64 %1, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  br label %endswitch
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_binding"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Ewalked_elem"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Enot_a_walk"(ptr %0, i64 %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Enot_a_walk"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseen_at"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %3, 22
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp1 = icmp eq i64 %5, 18
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Enothing_to_walk"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Enot_walkable"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Enot_walkable"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %2)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %3, ptr %5, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Enothing_to_walk"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %3 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %2, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16), ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseen_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epair"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erequire_bool"(ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_for"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 15, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 2)
  %7 = call i64 @avra_array_get(ptr %4, i64 3)
  %8 = call i64 @avra_array_get(ptr %4, i64 4)
  %9 = call i64 @avra_array_get(ptr %4, i64 5)
  %10 = call ptr @avra_array_get_owned(ptr %4, i64 6)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %6)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Erange_bound"(ptr %0, i64 %6, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  br i1 %13, label %then, label %else

arm2:                                             ; preds = %entry
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif5
  %regval7 = phi i64 [ %18, %endif5 ], [ %14, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval7

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Erange_bound"(ptr %0, i64 %7, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %15, %then ], [ false, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %8)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %9)
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval6 = phi i64 [ 0, %then3 ], [ 0, %else4 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %10)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Erange_bound"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eshape_at"(ptr %0, i64 %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call i64 @avra_array_get(ptr %3, i64 0)
  %cmp1 = icmp eq i64 %5, 22
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %8 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %6)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16), ptr %7, ptr %9, ptr %10, ptr null)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 false

postret5:                                         ; No predecessors!
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Echeck_while"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 8, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erequire_bool"(ptr %0, i64 %6, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16), ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %7)
  br label %endswitch

arm2:                                             ; preds = %entry
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi i64 [ %10, %arm ], [ %11, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}
