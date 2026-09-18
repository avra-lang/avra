; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"quote\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"quote\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"text\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"hole \00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [25 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 24 }, [25 x i8] c" of a template carrying \00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [71 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 70 }, [71 x i8] c" fill(s) \E2\80\94 the template numbered its holes and its fills differently\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_mutating"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_once"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebody_of"(ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edocument"(ptr, i64, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eplaceholder"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_exported"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Enamed_ref"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotations_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24110"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earms"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24110"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earm"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earm"(ptr %0, ptr %1) {
entry:
  %slot11 = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earm_hole"(ptr %0, ptr %1)
  %x = extractvalue { i1, i64 } %2, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %2, 0
  %x2 = extractvalue { i1, i64 } %2, 1
  %slot = zext i1 %x1 to i64
  %3 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %3, ptr %4)
  %6 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %6, 0
  %not = xor i1 %b, true
  br i1 %not, label %then3, label %else4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else ]
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot11, align 8
  br label %lhead

then3:                                            ; preds = %then
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %10, ptr %1)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else4:                                            ; preds = %then
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else4 ]
  %x6 = extractvalue { i1, i64 } %2, 0
  %x7 = extractvalue { i1, i64 } %2, 1
  %slot8 = zext i1 %x6 to i64
  %11 = call i64 @avra_insist_scalar(i64 %slot8, i64 %x7)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_arms"(ptr %0, i64 %11)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif5

postret9:                                         ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %4)
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot11, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %13 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %13)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %15, ptr %7)
  call void @avra_array_push(ptr %15, i64 %14)
  %16 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

lbody:                                            ; preds = %lhead
  %ld12 = load i64, ptr %slot11, align 8
  %17 = call i64 @avra_array_get(ptr %8, i64 %ld12)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Epat"(ptr %0, i64 %17)
  call void @avra_array_push(ptr %7, i64 %18)
  %ld13 = load i64, ptr %slot11, align 8
  %add = add i64 %ld13, 1
  store i64 %add, ptr %slot11, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed, i64 %1)
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr %boxed1, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %5)
  %x = extractvalue { i1, i64 } %6, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x2 = extractvalue { i1, i64 } %6, 0
  %x3 = extractvalue { i1, i64 } %6, 1
  %slot = zext i1 %x2 to i64
  %7 = call i64 @avra_insist_scalar(i64 %slot, i64 %x3)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %7, ptr %8)
  %10 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %10, 0
  %not = xor i1 %b, true
  br i1 %not, label %then4, label %else5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else ]
  %11 = call ptr @avra_slot_unique(ptr %0, i64 12)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Erebuilt"(ptr %3, ptr %0)
  %13 = call ptr @avra_slot_unique(ptr %0, i64 12)
  %14 = call i64 @avra_array_pop(ptr %13)
  %b12 = icmp ne i64 %14, 0
  %15 = call i64 @avra_array_get(ptr %0, i64 3)
  %b13 = icmp ne i64 %15, 0
  %not14 = xor i1 %b13, true
  br i1 %not14, label %then15, label %else16

then4:                                            ; preds = %then
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %1

else5:                                            ; preds = %then
  br label %endif6

endif6:                                           ; preds = %else5, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else5 ]
  %x7 = extractvalue { i1, i64 } %6, 0
  %x8 = extractvalue { i1, i64 } %6, 1
  %slot9 = zext i1 %x7 to i64
  %16 = call i64 @avra_insist_scalar(i64 %slot9, i64 %x8)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_expr"(ptr %0, i64 %16)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

postret:                                          ; No predecessors!
  br label %endif6

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif

then15:                                           ; preds = %endif
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %1

else16:                                           ; preds = %endif
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %18 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eminted_expr"(ptr %0, i64 %1, ptr %12, i1 %b12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %18

postret18:                                        ; No predecessors!
  br label %endif17
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eminted_expr"(ptr %0, i64 %1, ptr %2, i1 %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr_span"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %4, ptr %2, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %9 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_trailing"(ptr %boxed1, i64 %1)
  br i1 %9, label %then, label %else

then:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %11 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_trailing"(ptr %boxed2, i64 %7)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed3 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %13 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_type_lit"(ptr %boxed3, i64 %1)
  br i1 %13, label %then4, label %else5

then4:                                            ; preds = %endif
  %14 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed7 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed7)
  %15 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_type_lit"(ptr %boxed7, i64 %7)
  br label %endif6

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i64 [ 0, %then4 ], [ 0, %else5 ]
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed9 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %boxed9)
  %17 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_hole"(ptr %boxed9, i64 %1)
  br i1 %17, label %then10, label %else11

then10:                                           ; preds = %endif6
  %18 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed13 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %boxed13)
  %19 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_hole"(ptr %boxed13, i64 %7)
  br label %endif12

else11:                                           ; preds = %endif6
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  call void @avra_rc_retain(ptr %2)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebody_of"(ptr %2)
  %cmp = icmp ne ptr %20, null
  br i1 %cmp, label %then15, label %else16

then15:                                           ; preds = %endif12
  %21 = call ptr @avra_insist(ptr %20)
  %22 = call i64 @avra_array_get(ptr %21, i64 0)
  %boxed18 = inttoptr i64 %22 to ptr
  %23 = call i64 @avra_streq(ptr %boxed18, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %b = icmp ne i64 %23, 0
  br i1 %b, label %then19, label %else20

else16:                                           ; preds = %endif12
  br label %endif17

endif17:                                          ; preds = %else16, %endif35
  %regval38 = phi i64 [ 0, %endif35 ], [ 0, %else16 ]
  %not39 = xor i1 %3, true
  br i1 %not39, label %then40, label %else41

then19:                                           ; preds = %then15
  %24 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed22 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %boxed22)
  %25 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_quote_at"(ptr %boxed22, i64 %7)
  br label %endif21

else20:                                           ; preds = %then15
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval23 = phi i64 [ 0, %then19 ], [ 0, %else20 ]
  %26 = call i64 @avra_array_get(ptr %21, i64 0)
  %boxed24 = inttoptr i64 %26 to ptr
  %27 = call i64 @avra_streq(ptr %boxed24, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %b25 = icmp ne i64 %27, 0
  %not = xor i1 %b25, true
  br i1 %not, label %then26, label %else27

then26:                                           ; preds = %endif21
  %28 = call i64 @avra_array_get(ptr %21, i64 0)
  %boxed29 = inttoptr i64 %28 to ptr
  %29 = call i64 @avra_streq(ptr %boxed29, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %b30 = icmp ne i64 %29, 0
  %not31 = xor i1 %b30, true
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif28

else27:                                           ; preds = %endif21
  br label %endif28

endif28:                                          ; preds = %else27, %then26
  %regval32 = phi i1 [ %not31, %then26 ], [ false, %else27 ]
  br i1 %regval32, label %then33, label %else34

then33:                                           ; preds = %endif28
  %30 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %31 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed36 = inttoptr i64 %31 to ptr
  call void @avra_rc_retain(ptr %boxed36)
  %32 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebody_start"(ptr %boxed36, i64 %1)
  call void @avra_rc_retain(ptr %30)
  %33 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_sublang"(ptr %30, i64 %7, i64 %32)
  call void @avra_rc_release(ptr %30)
  br label %endif35

else34:                                           ; preds = %endif28
  br label %endif35

endif35:                                          ; preds = %else34, %then33
  %regval37 = phi i64 [ 0, %then33 ], [ 0, %else34 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %21)
  br label %endif17

then40:                                           ; preds = %endif17
  %34 = call ptr @avra_slot_unique(ptr %0, i64 6)
  call void @avra_array_push(ptr %34, i64 %7)
  %35 = call ptr @avra_slot_unique(ptr %0, i64 7)
  call void @avra_array_push(ptr %35, i64 %1)
  br label %endif42

else41:                                           ; preds = %endif17
  br label %endif42

endif42:                                          ; preds = %else41, %then40
  %regval43 = phi i64 [ 0, %then40 ], [ 0, %else41 ]
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_sublang"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebody_start"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_quote_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_hole"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_hole"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_type_lit"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_type_lit"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_trailing"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_trailing"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Erebuilt"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_names"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_name"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_name"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %b = icmp ne i64 %2, 0
  %not = xor i1 %b, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr %1)
  %cmp = icmp ne ptr %3, null
  call void @avra_rc_release(ptr %3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp, %then ], [ false, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  %4 = call i64 @avra_array_get(ptr %0, i64 12)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_len(ptr %boxed)
  %cmp4 = icmp eq i64 %5, 0
  %not5 = xor i1 %cmp4, true
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval6 = phi i1 [ %not5, %then1 ], [ false, %else2 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif3
  %6 = call ptr @avra_slot_unique(ptr %0, i64 12)
  %7 = call i64 @avra_array_get(ptr %0, i64 12)
  %boxed10 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_len(ptr %boxed10)
  %sub = sub i64 %8, 1
  call void @avra_slot_set(ptr %6, i64 %sub, i64 1)
  br label %endif9

else8:                                            ; preds = %endif3
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i64 [ 0, %then7 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erewritten"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erewritten"(ptr %0, ptr %1) {
entry:
  %slot28 = alloca ptr, align 8
  store ptr null, ptr %slot28, align 8
  %slot18 = alloca i64, align 8
  %slot6 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret4:                                         ; No predecessors!
  br label %endif3

lhead:                                            ; preds = %lbody, %endif3
  %ld = load i64, ptr %slot, align 8
  %cmp7 = icmp slt i64 %ld, %6
  br i1 %cmp7, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %b11 = icmp ne i64 %7, 0
  %not12 = xor i1 %b11, true
  br i1 %not12, label %then13, label %else14

lbody:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %5, i64 %ld8)
  store i64 %8, ptr %slot6, align 8
  %ld9 = load i64, ptr %slot6, align 8
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %ld9, ptr %9)
  %ld10 = load i64, ptr %slot, align 8
  %add = add i64 %ld10, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead

then13:                                           ; preds = %lexit
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else14:                                           ; preds = %lexit
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %13 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot18, align 8
  br label %lhead19

postret16:                                        ; No predecessors!
  br label %endif15

lhead19:                                          ; preds = %lbody23, %endif15
  %ld21 = load i64, ptr %slot18, align 8
  %cmp22 = icmp slt i64 %ld21, %13
  br i1 %cmp22, label %lbody23, label %lexit20

lexit20:                                          ; preds = %lhead19
  %14 = call ptr @avra_str_join(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %15 = call ptr @avra_array_get_owned(ptr %4, i64 0)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot28)
  store ptr null, ptr %slot28, align 8
  %16 = call i64 @avra_array_len(ptr %15)
  %cmp29 = icmp slt i64 0, %16
  br i1 %cmp29, label %then30, label %else31

lbody23:                                          ; preds = %lhead19
  %ld24 = load i64, ptr %slot18, align 8
  %17 = call i64 @avra_array_get(ptr %12, i64 %ld24)
  %18 = call i64 @avra_array_get(ptr %4, i64 0)
  %boxed = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %boxed, i64 %ld24)
  %boxed25 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %0)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_name"(ptr %0, i64 %17)
  %21 = call ptr @avra_str_concat(ptr %boxed25, ptr %20)
  call void @avra_array_push_owned(ptr %11, ptr %21)
  %ld26 = load i64, ptr %slot18, align 8
  %add27 = add i64 %ld26, 1
  store i64 %add27, ptr %slot18, align 8
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  br label %lhead19

then30:                                           ; preds = %lexit20
  %sub = sub i64 %16, 1
  %22 = call ptr @avra_array_get_owned(ptr %15, i64 %sub)
  call void @avra_rc_retain(ptr %22)
  call void @avra_cell_release(ptr %slot28)
  store ptr %22, ptr %slot28, align 8
  call void @avra_rc_release(ptr %22)
  br label %endif32

else31:                                           ; preds = %lexit20
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval33 = phi i64 [ 0, %then30 ], [ 0, %else31 ]
  %ld34 = load ptr, ptr %slot28, align 8
  %23 = call ptr @avra_insist(ptr %ld34)
  %24 = call ptr @avra_str_concat(ptr %14, ptr %23)
  call void @avra_cell_release(ptr %slot28)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %24
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_name"(ptr %0, i64 %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm4 [
    i64 1, label %arm
    i64 3, label %arm1
    i64 2, label %arm2
    i64 6, label %arm3
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %9 = call i64 @avra_array_len(ptr %8)
  %cmp = icmp slt i64 0, %9
  br i1 %cmp, label %then, label %else

arm3:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced_name"(ptr %0, i64 %1, ptr %boxed)
  br label %endswitch

arm4:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Emisfit"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm4, %arm3, %endif8, %arm1, %arm
  %regval10 = phi ptr [ %5, %arm ], [ %7, %arm1 ], [ %regval9, %endif8 ], [ %11, %arm3 ], [ %12, %arm4 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval10

then:                                             ; preds = %arm2
  %13 = call ptr @avra_array_get_owned(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %13)
  call void @avra_cell_release(ptr %slot)
  store ptr %13, ptr %slot, align 8
  call void @avra_rc_release(ptr %13)
  br label %endif

else:                                             ; preds = %arm2
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp5 = icmp ne ptr %ld, null
  br i1 %cmp5, label %then6, label %else7

then6:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %ld)
  br label %endif8

else7:                                            ; preds = %endif
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %ld, %then6 ], [ getelementptr inbounds (i8, ptr @.str.4, i64 16), %else7 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %8)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Emisfit"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_slot_unique(ptr %0, i64 10)
  call void @avra_array_push(ptr %2, i64 %1)
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %1)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eplaceholder"(ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced_name"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced"(ptr %0, i64 %1, ptr %2)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eplaceholder"(ptr %4, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_slot_unique(ptr %0, i64 11)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 %1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %4
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eno_fill_for"(i64 %1, i64 %6)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 6)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed2, i64 %1)
  %boxed3 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed3, i64 0)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %2)
  %cast = inttoptr i64 %11 to ptr
  %12 = call ptr %cast(ptr %boxed3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eno_fill_for"(i64 %0, i64 %1) {
entry:
  %2 = call ptr @avra_int_text(i64 %0)
  %3 = call ptr @avra_int_text(i64 %1)
  %4 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  ret ptr %5
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %3, 0
  %not = xor i1 %b, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_slot_unique(ptr %0, i64 5)
  call void @avra_slot_set_owned(ptr %4, i64 %1, ptr %2)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eparams"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eparam"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eparam"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_name"(ptr %0, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etref_opt"(ptr %0, ptr %boxed1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr_opt"(ptr %0, ptr %boxed2)
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 3)
  %9 = call ptr @avra_array_get_owned(ptr %1, i64 4)
  %10 = call i64 @avra_array_get(ptr %1, i64 5)
  %boxed3 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %11, ptr %5)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr %8)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %boxed3)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr_opt"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %3)
  call void @avra_rc_release(ptr %2)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etref_opt"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etref"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etref"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %boxed)
  %x = extractvalue { i1, i64 } %3, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %3, 0
  %x2 = extractvalue { i1, i64 } %3, 1
  %slot = zext i1 %x1 to i64
  %4 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %4, ptr %5)
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %7, 0
  %not = xor i1 %b, true
  br i1 %not, label %then3, label %else4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret37
  %regval38 = phi i64 [ 0, %postret37 ], [ 0, %else ]
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed39 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed39)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erewritten"(ptr %0, ptr %boxed39)
  %10 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed40 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed40)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etrefs"(ptr %0, ptr %boxed40)
  %12 = call i64 @avra_array_get(ptr %1, i64 2)
  %b41 = icmp ne i64 %12, 0
  %13 = call i64 @avra_array_get(ptr %1, i64 3)
  %b42 = icmp ne i64 %13, 0
  %14 = call i64 @avra_array_get(ptr %1, i64 4)
  %b43 = icmp ne i64 %14, 0
  %15 = call ptr @avra_array_get_owned(ptr %1, i64 5)
  %16 = call i64 @avra_array_get(ptr %1, i64 6)
  %boxed44 = inttoptr i64 %16 to ptr
  %17 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %17, ptr %9)
  call void @avra_array_push_owned(ptr %17, ptr %11)
  %slot45 = zext i1 %b41 to i64
  call void @avra_array_push(ptr %17, i64 %slot45)
  %slot46 = zext i1 %b42 to i64
  call void @avra_array_push(ptr %17, i64 %slot46)
  %slot47 = zext i1 %b43 to i64
  call void @avra_array_push(ptr %17, i64 %slot47)
  call void @avra_array_push_owned(ptr %17, ptr %15)
  call void @avra_array_push_owned(ptr %17, ptr %boxed44)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

then3:                                            ; preds = %then
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else4:                                            ; preds = %then
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else4 ]
  %x6 = extractvalue { i1, i64 } %3, 0
  %x7 = extractvalue { i1, i64 } %3, 1
  %slot8 = zext i1 %x6 to i64
  %18 = call i64 @avra_insist_scalar(i64 %slot8, i64 %x7)
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_type"(ptr %0, i64 %18)
  %20 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed9 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_len(ptr %boxed9)
  %cmp = icmp eq i64 %21, 0
  br i1 %cmp, label %then10, label %else11

postret:                                          ; No predecessors!
  br label %endif5

then10:                                           ; preds = %endif5
  %22 = call i64 @avra_array_get(ptr %19, i64 2)
  %b13 = icmp ne i64 %22, 0
  br i1 %b13, label %then14, label %else15

else11:                                           ; preds = %endif5
  br label %endif12

endif12:                                          ; preds = %else11, %postret26
  %regval27 = phi i64 [ 0, %postret26 ], [ 0, %else11 ]
  %23 = call i64 @avra_array_get(ptr %19, i64 0)
  %boxed28 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed29 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed29)
  %25 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etrefs"(ptr %0, ptr %boxed29)
  %26 = call i64 @avra_array_get(ptr %1, i64 2)
  %b30 = icmp ne i64 %26, 0
  %27 = call i64 @avra_array_get(ptr %1, i64 3)
  %b31 = icmp ne i64 %27, 0
  %28 = call i64 @avra_array_get(ptr %1, i64 4)
  %b32 = icmp ne i64 %28, 0
  %29 = call ptr @avra_array_get_owned(ptr %1, i64 5)
  %30 = call i64 @avra_array_get(ptr %1, i64 6)
  %boxed33 = inttoptr i64 %30 to ptr
  %31 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %31, ptr %boxed28)
  call void @avra_array_push_owned(ptr %31, ptr %25)
  %slot34 = zext i1 %b30 to i64
  call void @avra_array_push(ptr %31, i64 %slot34)
  %slot35 = zext i1 %b31 to i64
  call void @avra_array_push(ptr %31, i64 %slot35)
  %slot36 = zext i1 %b32 to i64
  call void @avra_array_push(ptr %31, i64 %slot36)
  call void @avra_array_push_owned(ptr %31, ptr %29)
  call void @avra_array_push_owned(ptr %31, ptr %boxed33)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %31

then14:                                           ; preds = %then10
  br label %endif16

else15:                                           ; preds = %then10
  %32 = call i64 @avra_array_get(ptr %1, i64 2)
  %b17 = icmp ne i64 %32, 0
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval18 = phi i1 [ true, %then14 ], [ %b17, %else15 ]
  %33 = call i64 @avra_array_get(ptr %1, i64 5)
  %boxed19 = inttoptr i64 %33 to ptr
  %34 = call ptr @avra_array_get_owned(ptr %19, i64 0)
  %35 = call ptr @avra_array_get_owned(ptr %19, i64 1)
  %36 = call i64 @avra_array_get(ptr %19, i64 3)
  %b20 = icmp ne i64 %36, 0
  %37 = call i64 @avra_array_get(ptr %19, i64 4)
  %b21 = icmp ne i64 %37, 0
  %38 = call i64 @avra_array_get(ptr %19, i64 6)
  %boxed22 = inttoptr i64 %38 to ptr
  %39 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %39, ptr %34)
  call void @avra_array_push_owned(ptr %39, ptr %35)
  %slot23 = zext i1 %regval18 to i64
  call void @avra_array_push(ptr %39, i64 %slot23)
  %slot24 = zext i1 %b20 to i64
  call void @avra_array_push(ptr %39, i64 %slot24)
  %slot25 = zext i1 %b21 to i64
  call void @avra_array_push(ptr %39, i64 %slot25)
  call void @avra_array_push_owned(ptr %39, ptr %boxed19)
  call void @avra_array_push_owned(ptr %39, ptr %boxed22)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %39

postret26:                                        ; No predecessors!
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  br label %endif12

postret37:                                        ; No predecessors!
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %5)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etrefs"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etref"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_type"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm3 [
    i64 3, label %arm
    i64 1, label %arm1
    i64 6, label %arm2
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enamed_ref"(ptr %boxed)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed4 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed4)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced_name"(ptr %0, i64 %1, ptr %boxed4)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enamed_ref"(ptr %9)
  call void @avra_rc_release(ptr %9)
  br label %endswitch

arm3:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Emisfit"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enamed_ref"(ptr %11)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ %12, %arm3 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  %3 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr %3)
  %cmp5 = icmp ne ptr %4, null
  %not6 = xor i1 %cmp5, true
  br i1 %not6, label %then7, label %else8

postret:                                          ; No predecessors!
  br label %endif3

then7:                                            ; preds = %endif3
  br label %endif9

else8:                                            ; preds = %endif3
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %6 = call i1 @"av_$40std$2Eavrac$2Ecore$2EHoleName$2Elone"(ptr %5)
  %not10 = xor i1 %6, true
  call void @avra_rc_release(ptr %5)
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %not10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else13:                                           ; preds = %endif9
  br label %endif14

endif14:                                          ; preds = %else13, %postret15
  %regval16 = phi i64 [ 0, %postret15 ], [ 0, %else13 ]
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 1)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %9, 1
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %pack

postret15:                                        ; No predecessors!
  br label %endif14
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2EHoleName$2Elone"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eplain_names"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eplain_name"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eplain_name"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erewritten"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etype_name"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %1)
  %x = extractvalue { i1, i64 } %2, 0
  %not = xor i1 %x, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erewritten"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %x1 = extractvalue { i1, i64 } %2, 0
  %x2 = extractvalue { i1, i64 } %2, 1
  %slot = zext i1 %x1 to i64
  %4 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %4, ptr %5)
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %7, 0
  %not3 = xor i1 %b, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %3)
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %x9 = extractvalue { i1, i64 } %2, 0
  %x10 = extractvalue { i1, i64 } %2, 1
  %slot11 = zext i1 %x9 to i64
  %8 = call i64 @avra_insist_scalar(i64 %slot11, i64 %x10)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_type"(ptr %0, i64 %8)
  %10 = call ptr @avra_array_get_owned(ptr %9, i64 0)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret7:                                         ; No predecessors!
  br label %endif6
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Estmts"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2491"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Estmt"(ptr %0, i64 %5)
  call void @avra_array_push_owned(ptr %2, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2491"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Estmt"(ptr %0, i64 %1) {
entry:
  %slot17 = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %b = icmp ne i64 %2, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr %boxed, i64 %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ zeroinitializer, %then ], [ %4, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  br i1 %x, label %then1, label %else2

then1:                                            ; preds = %endif
  %x4 = extractvalue { i1, i64 } %regval, 0
  %x5 = extractvalue { i1, i64 } %regval, 1
  %slot = zext i1 %x4 to i64
  %5 = call i64 @avra_insist_scalar(i64 %slot, i64 %x5)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %5, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 3)
  %b6 = icmp ne i64 %8, 0
  %not = xor i1 %b6, true
  br i1 %not, label %then7, label %else8

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret14
  %regval15 = phi i64 [ 0, %postret14 ], [ 0, %else2 ]
  %9 = call ptr @avra_array_sized(i64 0)
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed16 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed16)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotations_of"(ptr %boxed16, i64 %1)
  %12 = call i64 @avra_array_len(ptr %11)
  store i64 0, ptr %slot17, align 8
  br label %lhead

then7:                                            ; preds = %then1
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 %1)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

else8:                                            ; preds = %then1
  br label %endif9

endif9:                                           ; preds = %else8, %postret
  %regval10 = phi i64 [ 0, %postret ], [ 0, %else8 ]
  %x11 = extractvalue { i1, i64 } %regval, 0
  %x12 = extractvalue { i1, i64 } %regval, 1
  %slot13 = zext i1 %x11 to i64
  %14 = call i64 @avra_insist_scalar(i64 %slot13, i64 %x12)
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_stmts"(ptr %0, i64 %14)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %13)
  br label %endif9

postret14:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %6)
  br label %endif3

lhead:                                            ; preds = %lbody, %endif3
  %ld = load i64, ptr %slot17, align 8
  %cmp = icmp slt i64 %ld, %12
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %16 = call ptr @avra_slot_unique(ptr %0, i64 12)
  call void @avra_array_push(ptr %16, i64 0)
  %17 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed21 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed21)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed21, i64 %1)
  call void @avra_rc_retain(ptr %18)
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Ecore$2EStmt$2Erebuilt"(ptr %18, ptr %0)
  %20 = call ptr @avra_slot_unique(ptr %0, i64 12)
  %21 = call i64 @avra_array_pop(ptr %20)
  %b22 = icmp ne i64 %21, 0
  %22 = call i64 @avra_array_get(ptr %0, i64 3)
  %b23 = icmp ne i64 %22, 0
  %not24 = xor i1 %b23, true
  br i1 %not24, label %then25, label %else26

lbody:                                            ; preds = %lhead
  %ld18 = load i64, ptr %slot17, align 8
  %23 = call i64 @avra_array_get(ptr %11, i64 %ld18)
  %boxed19 = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed19)
  %24 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eannotation"(ptr %0, ptr %boxed19)
  call void @avra_array_push_owned(ptr %9, ptr %24)
  %ld20 = load i64, ptr %slot17, align 8
  %add = add i64 %ld20, 1
  store i64 %add, ptr %slot17, align 8
  call void @avra_rc_release(ptr %24)
  br label %lhead

then25:                                           ; preds = %lexit
  %25 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %25, i64 %1)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %0)
  ret ptr %25

else26:                                           ; preds = %lexit
  br label %endif27

endif27:                                          ; preds = %else26, %postret28
  %regval29 = phi i64 [ 0, %postret28 ], [ 0, %else26 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  call void @avra_rc_retain(ptr %9)
  %26 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eminted_stmt"(ptr %0, i64 %1, ptr %19, i1 %b22, ptr %9)
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 %26)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %0)
  ret ptr %27

postret28:                                        ; No predecessors!
  call void @avra_rc_release(ptr %25)
  br label %endif27
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eminted_stmt"(ptr %0, i64 %1, ptr %2, i1 %3, ptr %4) {
entry:
  %slot27 = alloca ptr, align 8
  store ptr null, ptr %slot27, align 8
  %slot = alloca i64, align 8
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %5, ptr %2, ptr %7)
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %10 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_exported"(ptr %boxed1, i64 %1)
  br i1 %10, label %then, label %else

then:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_exported"(ptr %boxed2, i64 %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed3 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %14 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_mutating"(ptr %boxed3, i64 %1)
  br i1 %14, label %then4, label %else5

then4:                                            ; preds = %endif
  %15 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed7 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %boxed7)
  %16 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_mutating"(ptr %boxed7, i64 %8)
  br label %endif6

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i64 [ 0, %then4 ], [ 0, %else5 ]
  %17 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed9 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed9)
  %18 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_once"(ptr %boxed9, i64 %1)
  br i1 %18, label %then10, label %else11

then10:                                           ; preds = %endif6
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed13 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %boxed13)
  %20 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_once"(ptr %boxed13, i64 %8)
  br label %endif12

else11:                                           ; preds = %endif6
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %21 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed15 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr %boxed15)
  %22 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr %boxed15, i64 %1)
  br i1 %22, label %then16, label %else17

then16:                                           ; preds = %endif12
  %23 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed19 = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %boxed19)
  %24 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_static"(ptr %boxed19, i64 %8)
  br label %endif18

else17:                                           ; preds = %endif12
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval20 = phi i64 [ 0, %then16 ], [ 0, %else17 ]
  %25 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed21 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %boxed21)
  %26 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edoc_comment"(ptr %boxed21, i64 %1)
  %cmp = icmp ne ptr %26, null
  br i1 %cmp, label %then22, label %else23

then22:                                           ; preds = %endif18
  %27 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %28 = call ptr @avra_insist(ptr %26)
  %29 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed25 = inttoptr i64 %29 to ptr
  call void @avra_rc_retain(ptr %boxed25)
  %30 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edoc_at"(ptr %boxed25, i64 %1)
  call void @avra_rc_retain(ptr %27)
  call void @avra_rc_retain(ptr %28)
  %31 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edocument"(ptr %27, i64 %8, ptr %28, i64 %30)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  br label %endif24

else23:                                           ; preds = %endif18
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i64 [ 0, %then22 ], [ 0, %else23 ]
  %32 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %endif24
  %ld = load i64, ptr %slot, align 8
  %cmp28 = icmp slt i64 %ld, %32
  br i1 %cmp28, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %not = xor i1 %3, true
  br i1 %not, label %then33, label %else34

lbody:                                            ; preds = %lhead
  %ld29 = load i64, ptr %slot, align 8
  %33 = call ptr @avra_array_get_owned(ptr %4, i64 %ld29)
  call void @avra_rc_retain(ptr %33)
  call void @avra_cell_release(ptr %slot27)
  store ptr %33, ptr %slot27, align 8
  %34 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed30 = inttoptr i64 %34 to ptr
  %ld31 = load ptr, ptr %slot27, align 8
  call void @avra_rc_retain(ptr %boxed30)
  call void @avra_rc_retain(ptr %ld31)
  %35 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotate"(ptr %boxed30, i64 %8, ptr %ld31)
  %ld32 = load i64, ptr %slot, align 8
  %add = add i64 %ld32, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %33)
  br label %lhead

then33:                                           ; preds = %lexit
  %36 = call ptr @avra_slot_unique(ptr %0, i64 8)
  call void @avra_array_push(ptr %36, i64 %8)
  br label %endif35

else34:                                           ; preds = %lexit
  br label %endif35

endif35:                                          ; preds = %else34, %then33
  %regval36 = phi i64 [ 0, %then33 ], [ 0, %else34 ]
  call void @avra_cell_release(ptr %slot27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotate"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edoc_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edoc_comment"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_static"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_once"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_mutating"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emark_exported"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EStmt$2Erebuilt"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Ecases"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Ecase"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Ecase"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %4)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push_owned(ptr %6, ptr %3)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Evariants"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Evariant"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Evariant"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eplain_name"(ptr %0, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eparams"(ptr %0, ptr %boxed1)
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %7 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %8, ptr %3)
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr %boxed2)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_name_opt"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_name"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etype_name_opt"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Etype_name"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eannotation"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %3)
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexprs"(ptr %0, ptr %boxed)
  %7 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_array_push(ptr %8, i64 %4)
  call void @avra_array_push_owned(ptr %8, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr %boxed1)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexprs"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %4)
  call void @avra_array_push(ptr %2, i64 %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_stmts"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm3 [
    i64 4, label %arm
    i64 0, label %arm1
    i64 6, label %arm2
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %3, i64 1)
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 4)
  call void @avra_array_push(ptr %8, i64 %6)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_stmt"(ptr %boxed, ptr %8, ptr null)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 %9)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm2:                                             ; preds = %entry
  %11 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced"(ptr %0, i64 %1, ptr %11)
  %13 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

arm3:                                             ; preds = %entry
  %14 = call ptr @avra_slot_unique(ptr %0, i64 10)
  call void @avra_array_push(ptr %14, i64 %1)
  %15 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ %10, %arm1 ], [ %13, %arm2 ], [ %15, %arm3 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erebuilt_view"(ptr %0, ptr %1) {
entry:
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm2 [
    i64 0, label %arm
    i64 1, label %arm1
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  br label %endswitch

arm1:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %10 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %10, 0
  %11 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 6)
  %13 = call ptr @avra_array_get_owned(ptr %0, i64 7)
  %14 = call ptr @avra_array_get_owned(ptr %0, i64 8)
  %15 = call ptr @avra_array_get_owned(ptr %0, i64 9)
  %16 = call ptr @avra_array_get_owned(ptr %0, i64 10)
  %17 = call i64 @avra_array_get(ptr %0, i64 11)
  %boxed = inttoptr i64 %17 to ptr
  %18 = call ptr @avra_array_sized(i64 13)
  call void @avra_array_push_owned(ptr %18, ptr %7)
  call void @avra_array_push_owned(ptr %18, ptr %8)
  call void @avra_array_push_owned(ptr %18, ptr %9)
  %slot = zext i1 %b to i64
  call void @avra_array_push(ptr %18, i64 %slot)
  call void @avra_array_push(ptr %18, i64 1)
  call void @avra_array_push_owned(ptr %18, ptr %11)
  call void @avra_array_push_owned(ptr %18, ptr %12)
  call void @avra_array_push_owned(ptr %18, ptr %13)
  call void @avra_array_push_owned(ptr %18, ptr %14)
  call void @avra_array_push_owned(ptr %18, ptr %15)
  call void @avra_array_push_owned(ptr %18, ptr %16)
  call void @avra_array_push_owned(ptr %18, ptr %boxed)
  call void @avra_array_push_owned(ptr %18, ptr %6)
  call void @avra_rc_retain(ptr %18)
  call void @avra_cell_release(ptr %slot3)
  store ptr %18, ptr %slot3, align 8
  %ld = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_rc_retain(ptr %4)
  %19 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Estmts"(ptr %ld, ptr %4)
  %ld4 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld4)
  call void @avra_rc_retain(ptr %5)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earms"(ptr %ld4, ptr %5)
  %21 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %21, i64 1)
  call void @avra_array_push_owned(ptr %21, ptr %19)
  call void @avra_array_push_owned(ptr %21, ptr %20)
  %22 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed5 = inttoptr i64 %22 to ptr
  %ld6 = load ptr, ptr %slot3, align 8
  %23 = call i64 @avra_array_get(ptr %ld6, i64 6)
  %boxed7 = inttoptr i64 %23 to ptr
  %24 = call ptr @avra_array_concat(ptr %boxed5, ptr %boxed7)
  call void @avra_slot_set_owned(ptr %0, i64 6, ptr %24)
  %25 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed8 = inttoptr i64 %25 to ptr
  %ld9 = load ptr, ptr %slot3, align 8
  %26 = call i64 @avra_array_get(ptr %ld9, i64 7)
  %boxed10 = inttoptr i64 %26 to ptr
  %27 = call ptr @avra_array_concat(ptr %boxed8, ptr %boxed10)
  call void @avra_slot_set_owned(ptr %0, i64 7, ptr %27)
  %28 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed11 = inttoptr i64 %28 to ptr
  %ld12 = load ptr, ptr %slot3, align 8
  %29 = call i64 @avra_array_get(ptr %ld12, i64 8)
  %boxed13 = inttoptr i64 %29 to ptr
  %30 = call ptr @avra_array_concat(ptr %boxed11, ptr %boxed13)
  call void @avra_slot_set_owned(ptr %0, i64 8, ptr %30)
  %31 = call i64 @avra_array_get(ptr %0, i64 9)
  %boxed14 = inttoptr i64 %31 to ptr
  %ld15 = load ptr, ptr %slot3, align 8
  %32 = call i64 @avra_array_get(ptr %ld15, i64 9)
  %boxed16 = inttoptr i64 %32 to ptr
  %33 = call ptr @avra_array_concat(ptr %boxed14, ptr %boxed16)
  call void @avra_slot_set_owned(ptr %0, i64 9, ptr %33)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm2:                                             ; preds = %entry
  %34 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %35 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eexpr"(ptr %0, i64 %34)
  %36 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %36, i64 2)
  call void @avra_array_push(ptr %36, i64 %35)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %3, %arm ], [ %21, %arm1 ], [ %36, %arm2 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_expr"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm2 [
    i64 0, label %arm
    i64 6, label %arm1
  ]

arm:                                              ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced"(ptr %0, i64 %1, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 33)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %boxed, ptr %9, ptr null)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  %11 = call ptr @avra_slot_unique(ptr %0, i64 10)
  call void @avra_array_push(ptr %11, i64 %1)
  %12 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed3 = inttoptr i64 %12 to ptr
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 33)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_expr"(ptr %boxed3, ptr %13, ptr null)
  call void @avra_rc_release(ptr %13)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi i64 [ %5, %arm ], [ %10, %arm1 ], [ %14, %arm2 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Epat"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebind_name"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %3)
  %x = extractvalue { i1, i64 } %4, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %4, 0
  %x2 = extractvalue { i1, i64 } %4, 1
  %slot = zext i1 %x1 to i64
  %5 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %5, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %8, 0
  %not = xor i1 %b, true
  br i1 %not, label %then3, label %else4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else ]
  %9 = call ptr @avra_slot_unique(ptr %0, i64 12)
  call void @avra_array_push(ptr %9, i64 0)
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed11 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed11)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed11, i64 %1)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2EPat$2Erebuilt"(ptr %11, ptr %0)
  %13 = call ptr @avra_slot_unique(ptr %0, i64 12)
  %14 = call i64 @avra_array_pop(ptr %13)
  %b12 = icmp ne i64 %14, 0
  %15 = call i64 @avra_array_get(ptr %0, i64 3)
  %b13 = icmp ne i64 %15, 0
  %not14 = xor i1 %b13, true
  br i1 %not14, label %then15, label %else16

then3:                                            ; preds = %then
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %1

else4:                                            ; preds = %then
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else4 ]
  %16 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %x6 = extractvalue { i1, i64 } %4, 0
  %x7 = extractvalue { i1, i64 } %4, 1
  %slot8 = zext i1 %x6 to i64
  %17 = call i64 @avra_insist_scalar(i64 %slot8, i64 %x7)
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_name"(ptr %0, i64 %17)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %19, i64 2)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr %16, ptr %19, ptr null)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %20

postret:                                          ; No predecessors!
  br label %endif5

postret9:                                         ; No predecessors!
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %6)
  br label %endif

then15:                                           ; preds = %endif
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %1

else16:                                           ; preds = %endif
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  %21 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %22 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed20 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %boxed20)
  %23 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat_span"(ptr %boxed20, i64 %1)
  call void @avra_rc_retain(ptr %21)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %23)
  %24 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr %21, ptr %12, ptr %23)
  %not21 = xor i1 %b12, true
  br i1 %not21, label %then22, label %else23

postret18:                                        ; No predecessors!
  br label %endif17

then22:                                           ; preds = %endif17
  %25 = call ptr @avra_slot_unique(ptr %0, i64 9)
  call void @avra_array_push(ptr %25, i64 %24)
  br label %endif24

else23:                                           ; preds = %endif17
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval25 = phi i64 [ 0, %then22 ], [ 0, %else23 ]
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %24
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat_span"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EPat$2Erebuilt"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erebuilt_parts"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erebuilt_part"(ptr %0, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %5)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Erebuilt_part"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ebinds"(ptr %boxed)
  %not = xor i1 %3, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Escoped_name"(ptr %0, ptr %6)
  %8 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %9 = call i64 @avra_array_get(ptr %4, i64 2)
  %b = icmp ne i64 %9, 0
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %10, ptr %7)
  call void @avra_array_push_owned(ptr %10, ptr %8)
  %slot = zext i1 %b to i64
  call void @avra_array_push(ptr %10, i64 %slot)
  %11 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %11 to ptr
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %12, ptr %10)
  call void @avra_array_push_owned(ptr %12, ptr %boxed1)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret:                                          ; No predecessors!
  br label %endif
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Ebinds"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Epats"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24103"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Epat_seat"(ptr %0, i64 %5)
  call void @avra_array_push_owned(ptr %2, ptr %6)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24103"(ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Epat_seat"(ptr %0, i64 %1) {
entry:
  %slot12 = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebind_name"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %3)
  %x = extractvalue { i1, i64 } %4, 0
  %not = xor i1 %x, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Epat"(ptr %0, i64 %1)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %x1 = extractvalue { i1, i64 } %4, 0
  %x2 = extractvalue { i1, i64 } %4, 1
  %slot = zext i1 %x1 to i64
  %7 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eclassify"(ptr %0, i64 %7, ptr %8)
  %10 = call i64 @avra_array_get(ptr %0, i64 3)
  %b = icmp ne i64 %10, 0
  %not3 = xor i1 %b, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif

then4:                                            ; preds = %endif
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 %1)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %12 = call ptr @avra_array_sized(i64 0)
  %x9 = extractvalue { i1, i64 } %4, 0
  %x10 = extractvalue { i1, i64 } %4, 1
  %slot11 = zext i1 %x9 to i64
  %13 = call i64 @avra_insist_scalar(i64 %slot11, i64 %x10)
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_names"(ptr %0, i64 %13)
  %15 = call i64 @avra_array_len(ptr %14)
  store i64 0, ptr %slot12, align 8
  br label %lhead

postret7:                                         ; No predecessors!
  call void @avra_rc_release(ptr %11)
  br label %endif6

lhead:                                            ; preds = %lbody, %endif6
  %ld = load i64, ptr %slot12, align 8
  %cmp = icmp slt i64 %ld, %15
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

lbody:                                            ; preds = %lhead
  %ld13 = load i64, ptr %slot12, align 8
  %16 = call ptr @avra_array_get_owned(ptr %14, i64 %ld13)
  %17 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed14 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %16)
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 2)
  call void @avra_array_push_owned(ptr %18, ptr %16)
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr %boxed14, ptr %18, ptr null)
  call void @avra_array_push(ptr %12, i64 %19)
  %ld15 = load i64, ptr %slot12, align 8
  %add = add i64 %ld15, 1
  store i64 %add, ptr %slot12, align 8
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %16)
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ealloc_pat"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_names"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm4 [
    i64 2, label %arm
    i64 1, label %arm1
    i64 3, label %arm2
    i64 6, label %arm3
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %7, ptr %boxed)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed5 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed5, i64 0)
  %boxed6 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %10, ptr %boxed6)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed7 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed7)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced_name"(ptr %0, i64 %1, ptr %boxed7)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_release(ptr %12)
  br label %endswitch

arm4:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Emisfit"(ptr %0, i64 %1)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_release(ptr %14)
  br label %endswitch

endswitch:                                        ; preds = %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ %13, %arm3 ], [ %15, %arm4 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebind_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efill_arms"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Efilled"(ptr %0, i64 %1, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm2 [
    i64 5, label %arm
    i64 6, label %arm1
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Eunplaced"(ptr %0, i64 %1, ptr %6)
  %8 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  %9 = call ptr @avra_slot_unique(ptr %0, i64 10)
  call void @avra_array_push(ptr %9, i64 %1)
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ %8, %arm1 ], [ %10, %arm2 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earm_hole"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp ne i64 %3, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebind_name"(ptr %boxed1, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %7)
  %x = extractvalue { i1, i64 } %8, 0
  %not = xor i1 %x, true
  br i1 %not, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  br label %endif5

else4:                                            ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed6 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %boxed6)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eident_name"(ptr %boxed6, i64 %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Elone_hole"(ptr %0, ptr %11)
  %x7 = extractvalue { i1, i64 } %12, 0
  br i1 %x7, label %then8, label %else9

endif5:                                           ; preds = %endif10, %then3
  %regval23 = phi i1 [ true, %then3 ], [ %not22, %endif10 ]
  br i1 %regval23, label %then24, label %else25

then8:                                            ; preds = %else4
  %x11 = extractvalue { i1, i64 } %12, 1
  %x12 = extractvalue { i1, i64 } %8, 0
  br i1 %x12, label %then13, label %else14

else9:                                            ; preds = %else4
  %x19 = extractvalue { i1, i64 } %8, 0
  %not20 = xor i1 %x19, true
  br label %endif10

endif10:                                          ; preds = %else9, %endif15
  %regval21 = phi i1 [ %regval18, %endif15 ], [ %not20, %else9 ]
  %not22 = xor i1 %regval21, true
  call void @avra_rc_release(ptr %11)
  br label %endif5

then13:                                           ; preds = %then8
  %x16 = extractvalue { i1, i64 } %8, 1
  %cmp17 = icmp eq i64 %x11, %x16
  br label %endif15

else14:                                           ; preds = %then8
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval18 = phi i1 [ %cmp17, %then13 ], [ false, %else14 ]
  br label %endif10

then24:                                           ; preds = %endif5
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else25:                                           ; preds = %endif5
  br label %endif26

endif26:                                          ; preds = %else25, %postret27
  %regval28 = phi i64 [ 0, %postret27 ], [ 0, %else25 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %8

postret27:                                        ; No predecessors!
  br label %endif26
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ecopier"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_sized(i64 0)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call ptr @avra_array_sized(i64 13)
  call void @avra_array_push_owned(ptr %11, ptr %0)
  call void @avra_array_push_owned(ptr %11, ptr %1)
  call void @avra_array_push_owned(ptr %11, ptr %2)
  call void @avra_array_push(ptr %11, i64 1)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push_owned(ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %11, ptr %4)
  call void @avra_array_push_owned(ptr %11, ptr %5)
  call void @avra_array_push_owned(ptr %11, ptr %6)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr %8)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Equote_kind"(ptr %0, i64 %1) {
entry:
  %slot57 = alloca i64, align 8
  %slot56 = alloca i1, align 1
  %slot41 = alloca ptr, align 8
  store ptr null, ptr %slot41, align 8
  %slot30 = alloca ptr, align 8
  store ptr null, ptr %slot30, align 8
  %slot15 = alloca i64, align 8
  %slot = alloca i1, align 1
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebody_of"(ptr %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 3)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm1 [
    i64 1, label %arm
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

arm:                                              ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  %10 = call i64 @avra_array_len(ptr %9)
  %cmp2 = icmp eq i64 %10, 0
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

arm1:                                             ; preds = %endif
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 1)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif75
  %regval78 = phi ptr [ %41, %endif75 ], [ %11, %arm1 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval78

then4:                                            ; preds = %arm
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 2)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else5:                                            ; preds = %arm
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %13 = call i64 @avra_array_len(ptr %8)
  %cmp9 = icmp eq i64 %13, 0
  br i1 %cmp9, label %then10, label %else11

postret7:                                         ; No predecessors!
  call void @avra_rc_release(ptr %12)
  br label %endif6

then10:                                           ; preds = %endif6
  %14 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %14, i64 1)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else11:                                           ; preds = %endif6
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  store i1 true, ptr %slot, align 8
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Erebuild$24l97" to i64))
  call void @avra_array_push_owned(ptr %15, ptr %0)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %17 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot15, align 8
  br label %lhead

postret13:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  br label %endif12

lhead:                                            ; preds = %endif21, %endif12
  %ld = load i64, ptr %slot15, align 8
  %cmp16 = icmp slt i64 %ld, %17
  br i1 %cmp16, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld24 = load i1, ptr %slot, align 8
  br i1 %ld24, label %then25, label %else26

lbody:                                            ; preds = %lhead
  %ld17 = load i64, ptr %slot15, align 8
  %18 = call i64 @avra_array_get(ptr %8, i64 %ld17)
  call void @avra_rc_retain(ptr %15)
  %cast = inttoptr i64 %16 to ptr
  %19 = call i1 %cast(ptr %15, i64 %18)
  %not18 = xor i1 %19, true
  br i1 %not18, label %then19, label %else20

then19:                                           ; preds = %lbody
  store i1 false, ptr %slot, align 8
  store i64 %17, ptr %slot15, align 8
  br label %endif21

else20:                                           ; preds = %lbody
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval22 = phi i64 [ 0, %then19 ], [ 0, %else20 ]
  %ld23 = load i64, ptr %slot15, align 8
  %add = add i64 %ld23, 1
  store i64 %add, ptr %slot15, align 8
  br label %lhead

then25:                                           ; preds = %lexit
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 4)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %20

else26:                                           ; preds = %lexit
  br label %endif27

endif27:                                          ; preds = %else26, %postret28
  %regval29 = phi i64 [ 0, %postret28 ], [ 0, %else26 ]
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot30)
  store ptr null, ptr %slot30, align 8
  %21 = call i64 @avra_array_len(ptr %8)
  %cmp31 = icmp slt i64 0, %21
  br i1 %cmp31, label %then32, label %else33

postret28:                                        ; No predecessors!
  call void @avra_rc_release(ptr %20)
  br label %endif27

then32:                                           ; preds = %endif27
  %sub = sub i64 %21, 1
  %22 = call i64 @avra_array_get(ptr %8, i64 %sub)
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %23, i64 %22)
  call void @avra_rc_retain(ptr %23)
  call void @avra_cell_release(ptr %slot30)
  store ptr %23, ptr %slot30, align 8
  call void @avra_rc_release(ptr %23)
  br label %endif34

else33:                                           ; preds = %endif27
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval35 = phi i64 [ 0, %then32 ], [ 0, %else33 ]
  %ld36 = load ptr, ptr %slot30, align 8
  %24 = call ptr @avra_insist(ptr %ld36)
  %25 = call i64 @avra_array_get(ptr %24, i64 0)
  call void @avra_rc_retain(ptr %0)
  %26 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr %0, i64 %25)
  %x = extractvalue { i1, i64 } %26, 0
  %not37 = xor i1 %x, true
  br i1 %not37, label %then38, label %else39

then38:                                           ; preds = %endif34
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot41)
  store ptr null, ptr %slot41, align 8
  %27 = call i64 @avra_array_len(ptr %8)
  %cmp42 = icmp slt i64 0, %27
  br i1 %cmp42, label %then43, label %else44

else39:                                           ; preds = %endif34
  br label %endif40

endif40:                                          ; preds = %else39, %endif45
  %regval50 = phi i1 [ %cmp49, %endif45 ], [ false, %else39 ]
  br i1 %regval50, label %then51, label %else52

then43:                                           ; preds = %then38
  %sub46 = sub i64 %27, 1
  %28 = call i64 @avra_array_get(ptr %8, i64 %sub46)
  %29 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %29, i64 %28)
  call void @avra_rc_retain(ptr %29)
  call void @avra_cell_release(ptr %slot41)
  store ptr %29, ptr %slot41, align 8
  call void @avra_rc_release(ptr %29)
  br label %endif45

else44:                                           ; preds = %then38
  br label %endif45

endif45:                                          ; preds = %else44, %then43
  %regval47 = phi i64 [ 0, %then43 ], [ 0, %else44 ]
  %ld48 = load ptr, ptr %slot41, align 8
  %30 = call ptr @avra_insist(ptr %ld48)
  %31 = call i64 @avra_array_get(ptr %30, i64 0)
  call void @avra_rc_retain(ptr %0)
  %32 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %0, i64 %31)
  %33 = call i64 @avra_array_get(ptr %32, i64 0)
  %cmp49 = icmp eq i64 %33, 4
  call void @avra_cell_release(ptr %slot41)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %30)
  br label %endif40

then51:                                           ; preds = %endif40
  %34 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %34, i64 0)
  call void @avra_cell_release(ptr %slot30)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %34

else52:                                           ; preds = %endif40
  br label %endif53

endif53:                                          ; preds = %else52, %postret54
  %regval55 = phi i64 [ 0, %postret54 ], [ 0, %else52 ]
  store i1 true, ptr %slot56, align 8
  %35 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Erebuild$24l127" to i64))
  call void @avra_array_push_owned(ptr %35, ptr %0)
  %36 = call i64 @avra_array_get(ptr %35, i64 0)
  %37 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot57, align 8
  br label %lhead58

postret54:                                        ; No predecessors!
  call void @avra_rc_release(ptr %34)
  br label %endif53

lhead58:                                          ; preds = %endif68, %endif53
  %ld60 = load i64, ptr %slot57, align 8
  %cmp61 = icmp slt i64 %ld60, %37
  br i1 %cmp61, label %lbody62, label %lexit59

lexit59:                                          ; preds = %lhead58
  %ld72 = load i1, ptr %slot56, align 8
  br i1 %ld72, label %then73, label %else74

lbody62:                                          ; preds = %lhead58
  %ld63 = load i64, ptr %slot57, align 8
  %38 = call i64 @avra_array_get(ptr %8, i64 %ld63)
  call void @avra_rc_retain(ptr %35)
  %cast64 = inttoptr i64 %36 to ptr
  %39 = call i1 %cast64(ptr %35, i64 %38)
  %not65 = xor i1 %39, true
  br i1 %not65, label %then66, label %else67

then66:                                           ; preds = %lbody62
  store i1 false, ptr %slot56, align 8
  store i64 %37, ptr %slot57, align 8
  br label %endif68

else67:                                           ; preds = %lbody62
  br label %endif68

endif68:                                          ; preds = %else67, %then66
  %regval69 = phi i64 [ 0, %then66 ], [ 0, %else67 ]
  %ld70 = load i64, ptr %slot57, align 8
  %add71 = add i64 %ld70, 1
  store i64 %add71, ptr %slot57, align 8
  br label %lhead58

then73:                                           ; preds = %lexit59
  %40 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %40, i64 3)
  call void @avra_cell_release(ptr %slot30)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %40

else74:                                           ; preds = %lexit59
  br label %endif75

endif75:                                          ; preds = %else74, %postret76
  %regval77 = phi i64 [ 0, %postret76 ], [ 0, %else74 ]
  %41 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %41, i64 1)
  call void @avra_cell_release(ptr %slot30)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

postret76:                                        ; No predecessors!
  call void @avra_rc_release(ptr %40)
  br label %endif75
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Erebuild$24l127"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclares"(ptr %boxed, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr %boxed1, i64 %1)
  %x = extractvalue { i1, i64 } %5, 0
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %x, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Erebuild$24l97"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ehole_stmt"(ptr %boxed, i64 %1)
  %x = extractvalue { i1, i64 } %3, 0
  call void @avra_rc_release(ptr %0)
  ret i1 %x
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclares"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_kinds"(ptr %0, i64 %1) {
entry:
  %slot5 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebody_of"(ptr %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 3)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm2 [
    i64 1, label %arm
    i64 0, label %arm1
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

arm:                                              ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  %10 = call i64 @avra_array_get(ptr %5, i64 2)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_len(ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eclassifier"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot)
  store ptr %12, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_rc_retain(ptr %8)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Estmts"(ptr %ld, ptr %8)
  %ld3 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld3)
  call void @avra_rc_retain(ptr %9)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2ERebuilder$2Earms"(ptr %ld3, ptr %9)
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %15 = call ptr @avra_array_get_owned(ptr %ld4, i64 5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm1:                                             ; preds = %endif
  %16 = call ptr @avra_array_sized(i64 0)
  %17 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %18 = call i64 @avra_array_len(ptr %17)
  store i64 0, ptr %slot5, align 8
  br label %lhead

arm2:                                             ; preds = %endif
  %19 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %lexit, %arm
  %regval10 = phi ptr [ %15, %arm ], [ %16, %lexit ], [ %19, %arm2 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval10

lhead:                                            ; preds = %lbody, %arm1
  %ld6 = load i64, ptr %slot5, align 8
  %cmp7 = icmp slt i64 %ld6, %18
  br i1 %cmp7, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %17)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot5, align 8
  %20 = call i64 @avra_array_get(ptr %17, i64 %ld8)
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %21, i64 0)
  call void @avra_array_push_owned(ptr %16, ptr %21)
  %ld9 = load i64, ptr %slot5, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %21)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eclassifier"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_sized(i64 0)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call ptr @avra_array_sized(i64 13)
  call void @avra_array_push_owned(ptr %11, ptr %0)
  call void @avra_array_push_owned(ptr %11, ptr %0)
  call void @avra_array_push_owned(ptr %11, ptr %2)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push_owned(ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %11, ptr %4)
  call void @avra_array_push_owned(ptr %11, ptr %5)
  call void @avra_array_push_owned(ptr %11, ptr %6)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr %8)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %12)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  br label %lhead
}
