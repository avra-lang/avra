; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.errdefer\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [59 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 58 }, [59 x i8] c"an `errdefer` runs when this fn fails, and it promises a `\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"` \E2\80\94 it never does\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"deferred here\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"declare the answer fallible \E2\80\94 `-> Result<\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [27 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 26 }, [27 x i8] c", E>` \E2\80\94 or write `defer`\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.errdefer\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [76 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 75 }, [76 x i8] c"an `errdefer` runs when the enclosing fn fails, and there is none enclosing\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"deferred here\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [73 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 72 }, [73 x i8] c"at the top level there is no failure channel \E2\80\94 `defer` runs regardless\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"type.errdefer\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [108 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 107 }, [108 x i8] c"an `errdefer` runs when the enclosing fn fails, and a lambda promises no failure \E2\80\94 its answer is inferred\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"deferred here\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [52 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 51 }, [52 x i8] c"handle failures inside the lambda, or write `defer`\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.defer\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"`defer` drops what its body answers, and this one answers `\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [34 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 33 }, [34 x i8] c"` \E2\80\94 a failure nobody would hear\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.20 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"deferred here\00" }, align 16
@.str.21 = private unnamed_addr constant { { i32, i32, i32, i32 }, [75 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 74 }, [75 x i8] c"recover it with `catch`, or discard it on purpose: `defer { let _ = \E2\80\A6 }`\00" }, align 16
@.str.22 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"type.defer_inert\00" }, align 16
@.str.23 = private unnamed_addr constant { { i32, i32, i32, i32 }, [57 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 56 }, [57 x i8] c"`defer` runs its body later, and this one only names a `\00" }, align 16
@.str.24 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"` \E2\80\94 deferring a value does nothing\00" }, align 16
@.str.25 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.26 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"deferred here\00" }, align 16
@.str.27 = private unnamed_addr constant { { i32, i32, i32, i32 }, [90 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 89 }, [90 x i8] c"call something \E2\80\94 `defer child.stop()` \E2\80\94 or write the work in a block: `defer { \E2\80\A6 }`\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Eruns_on_error"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Echeck_defer"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewalk_value"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_insist(ptr %5)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %boxed3)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr %boxed3, i64 %9)
  %cmp4 = icmp ne ptr %10, null
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  %11 = call i64 @avra_array_get(ptr %10, i64 1)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 %11)
  br label %endif7

else6:                                            ; preds = %endif
  call void @avra_rc_retain(ptr null)
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi ptr [ %12, %then5 ], [ null, %else6 ]
  %cmp9 = icmp ne ptr %regval8, null
  br i1 %cmp9, label %then10, label %else11

then10:                                           ; preds = %endif7
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed13 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed13, i64 1)
  %boxed14 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_insist(ptr %regval8)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  call void @avra_rc_retain(ptr %boxed14)
  %17 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Einert"(ptr %boxed14, i64 %16)
  call void @avra_rc_release(ptr %15)
  br label %endif12

else11:                                           ; preds = %endif7
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval15 = phi i1 [ %17, %then10 ], [ false, %else11 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif12
  %18 = call ptr @avra_insist(ptr %regval8)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  call void @avra_rc_retain(ptr %0)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %19)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edoes_nothing"(ptr %0, i64 %1, ptr %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %21)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %regval8)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else17:                                           ; preds = %endif12
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  %23 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %24 = call i64 @avra_array_get(ptr %23, i64 5)
  %boxed21 = inttoptr i64 %24 to ptr
  %25 = call ptr @avra_insist(ptr %5)
  %26 = call i64 @avra_array_get(ptr %25, i64 0)
  call void @avra_rc_retain(ptr %0)
  %27 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %26)
  call void @avra_rc_retain(ptr %boxed21)
  call void @avra_rc_retain(ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr %boxed21, ptr %27)
  %cmp22 = icmp ne ptr %28, null
  br i1 %cmp22, label %then23, label %else24

postret19:                                        ; No predecessors!
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  br label %endif18

then23:                                           ; preds = %endif18
  %29 = call ptr @avra_array_get_owned(ptr %28, i64 2)
  br label %endif25

else24:                                           ; preds = %endif18
  call void @avra_rc_retain(ptr null)
  br label %endif25

endif25:                                          ; preds = %else24, %then23
  %regval26 = phi ptr [ %29, %then23 ], [ null, %else24 ]
  %cmp27 = icmp ne ptr %regval26, null
  br i1 %cmp27, label %then28, label %else29

then28:                                           ; preds = %endif25
  %30 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed31 = inttoptr i64 %30 to ptr
  %31 = call i64 @avra_array_get(ptr %boxed31, i64 5)
  %boxed32 = inttoptr i64 %31 to ptr
  %32 = call ptr @avra_insist(ptr %regval26)
  call void @avra_rc_retain(ptr %boxed32)
  call void @avra_rc_retain(ptr %32)
  %33 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed32, ptr %32)
  %cmp33 = icmp ne ptr %33, null
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  br label %endif30

else29:                                           ; preds = %endif25
  br label %endif30

endif30:                                          ; preds = %else29, %then28
  %regval34 = phi i1 [ %cmp33, %then28 ], [ false, %else29 ]
  br i1 %regval34, label %then35, label %else36

then35:                                           ; preds = %endif30
  %34 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed38 = inttoptr i64 %34 to ptr
  %35 = call i64 @avra_array_get(ptr %boxed38, i64 5)
  %boxed39 = inttoptr i64 %35 to ptr
  %36 = call ptr @avra_insist(ptr %regval26)
  call void @avra_rc_retain(ptr %boxed39)
  call void @avra_rc_retain(ptr %36)
  %37 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed39, ptr %36)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %37)
  %38 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Eunheard_failure"(ptr %0, i64 %1, ptr %37)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %38)
  %39 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %38)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  br label %endif37

else36:                                           ; preds = %endif30
  br label %endif37

endif37:                                          ; preds = %else36, %then35
  %regval40 = phi i64 [ 0, %then35 ], [ 0, %else36 ]
  %40 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed41 = inttoptr i64 %40 to ptr
  %41 = call i64 @avra_array_get(ptr %boxed41, i64 1)
  %boxed42 = inttoptr i64 %41 to ptr
  call void @avra_rc_retain(ptr %boxed42)
  %42 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Eruns_on_error"(ptr %boxed42, i64 %1)
  br i1 %42, label %then43, label %else44

then43:                                           ; preds = %endif37
  call void @avra_rc_retain(ptr %0)
  %43 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Echeck_channel"(ptr %0, i64 %1)
  br label %endif45

else44:                                           ; preds = %endif37
  br label %endif45

endif45:                                          ; preds = %else44, %then43
  %regval46 = phi i64 [ 0, %then43 ], [ 0, %else44 ]
  call void @avra_rc_release(ptr %regval26)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %regval8)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Echeck_channel"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebehind_lambda"(ptr %0)
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Elambda_channel"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr %0)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Eno_channel"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %8 = call ptr @avra_insist(ptr %5)
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed6 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %8)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed6, ptr %8)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  %cmp7 = icmp eq i64 %12, 22
  br i1 %cmp7, label %then8, label %else9

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif3

then8:                                            ; preds = %endif3
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else9:                                            ; preds = %endif3
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed13 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed13, i64 5)
  %boxed14 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %8)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed14, ptr %8)
  %cmp15 = icmp ne ptr %15, null
  %not16 = xor i1 %cmp15, true
  br i1 %not16, label %then17, label %else18

postret11:                                        ; No predecessors!
  br label %endif10

then17:                                           ; preds = %endif10
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed20 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed20, i64 5)
  %boxed21 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed21)
  call void @avra_rc_retain(ptr %8)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed21, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Enever_fails"(ptr %0, i64 %1, ptr %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  br label %endif19

else18:                                           ; preds = %endif10
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval22 = phi i64 [ 0, %then17 ], [ 0, %else18 ]
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Enever_fails"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %7 = call ptr @avra_str_join(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %3, ptr %5, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16), ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Eno_channel"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %3 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr %2, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr getelementptr inbounds (i8, ptr @.str.10, i64 16), ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr)

declare i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebehind_lambda"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Elambda_channel"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  %3 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16), ptr %2, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16), ptr getelementptr inbounds (i8, ptr @.str.14, i64 16), ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Eunheard_failure"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  %6 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16), ptr %3, ptr %5, ptr getelementptr inbounds (i8, ptr @.str.20, i64 16), ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edoes_nothing"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  %6 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16), ptr %3, ptr %5, ptr getelementptr inbounds (i8, ptr @.str.26, i64 16), ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Einert"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewalk_value"(ptr, i64)
