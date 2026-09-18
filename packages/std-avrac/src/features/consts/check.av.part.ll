; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"this const\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"this const\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"const.form\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"a computed const needs a compile-time value form\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"` declares \00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [85 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 84 }, [85 x i8] c"use a scalar, text, list, map, record, enum, result, or an optional over one of them\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Erides_pointer"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Edeclared_decl"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare { i1, i1 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebool_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Etext_of"(ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebits_of"(ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eint_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewalk_value"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Echeck_const"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %boxed3, i64 %1)
  %cmp4 = icmp ne ptr %9, null
  %not5 = xor i1 %cmp4, true
  br i1 %not5, label %then6, label %else7

postret:                                          ; No predecessors!
  br label %endif

then6:                                            ; preds = %endif
  br label %endif8

else7:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr %0, i64 %1, ptr %9)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ null, %then6 ], [ %10, %else7 ]
  %cmp10 = icmp ne ptr %regval9, null
  br i1 %cmp10, label %then11, label %else12

then11:                                           ; preds = %endif8
  %11 = call ptr @avra_insist(ptr %regval9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %6, ptr %11)
  call void @avra_rc_release(ptr %11)
  br label %endif13

else12:                                           ; preds = %endif8
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewalk_value"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %6)
  br i1 %14, label %then15, label %else16

then15:                                           ; preds = %endif13
  br label %endif17

else16:                                           ; preds = %endif13
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval9)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Erefused_annotation"(ptr %0, ptr %regval9)
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval18 = phi i1 [ true, %then15 ], [ %15, %else16 ]
  br i1 %regval18, label %then19, label %else20

then19:                                           ; preds = %endif17
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else20:                                           ; preds = %endif17
  br label %endif21

endif21:                                          ; preds = %else20, %postret22
  %regval23 = phi i64 [ 0, %postret22 ], [ 0, %else20 ]
  call void @avra_rc_retain(ptr %0)
  %16 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_void_value"(ptr %0, i64 %6)
  br i1 %16, label %then24, label %else25

postret22:                                        ; No predecessors!
  br label %endif21

then24:                                           ; preds = %endif21
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else25:                                           ; preds = %endif21
  br label %endif26

endif26:                                          ; preds = %else25, %postret27
  %regval28 = phi i64 [ 0, %postret27 ], [ 0, %else25 ]
  %cmp29 = icmp ne ptr %regval9, null
  br i1 %cmp29, label %then30, label %else31

postret27:                                        ; No predecessors!
  br label %endif26

then30:                                           ; preds = %endif26
  call void @avra_rc_retain(ptr %regval9)
  br label %endif32

else31:                                           ; preds = %endif26
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %6)
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval33 = phi ptr [ %regval9, %then30 ], [ %17, %else31 ]
  %18 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed34 = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %boxed34, i64 1)
  %boxed35 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %boxed35)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed35, i64 %6)
  call void @avra_rc_retain(ptr %20)
  %21 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Ewritten"(ptr %20)
  %not36 = xor i1 %21, true
  br i1 %not36, label %then37, label %else38

then37:                                           ; preds = %endif32
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval33)
  %22 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Ematerializable"(ptr %0, ptr %regval33)
  %not40 = xor i1 %22, true
  br label %endif39

else38:                                           ; preds = %endif32
  br label %endif39

endif39:                                          ; preds = %else38, %then37
  %regval41 = phi i1 [ %not40, %then37 ], [ false, %else38 ]
  br i1 %regval41, label %then42, label %else43

then42:                                           ; preds = %endif39
  %23 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed45 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed45, i64 1)
  %boxed46 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %boxed46)
  %25 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %boxed46, i64 %1)
  %cmp47 = icmp ne ptr %25, null
  br i1 %cmp47, label %then48, label %else49

else43:                                           ; preds = %endif39
  br label %endif44

endif44:                                          ; preds = %else43, %postret52
  %regval53 = phi i64 [ 0, %postret52 ], [ 0, %else43 ]
  %cmp54 = icmp ne ptr %regval9, null
  br i1 %cmp54, label %then55, label %else56

then48:                                           ; preds = %then42
  call void @avra_rc_retain(ptr %25)
  br label %endif50

else49:                                           ; preds = %then42
  br label %endif50

endif50:                                          ; preds = %else49, %then48
  %regval51 = phi ptr [ %25, %then48 ], [ getelementptr inbounds (i8, ptr @.str, i64 16), %else49 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval51)
  call void @avra_rc_retain(ptr %regval33)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Eunformed"(ptr %0, i64 %6, ptr %regval51, ptr %regval33)
  call void @avra_rc_release(ptr %regval51)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval33)
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

postret52:                                        ; No predecessors!
  call void @avra_rc_release(ptr %regval51)
  call void @avra_rc_release(ptr %25)
  br label %endif44

then55:                                           ; preds = %endif44
  %27 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed58 = inttoptr i64 %27 to ptr
  %28 = call i64 @avra_array_get(ptr %boxed58, i64 1)
  %boxed59 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %boxed59)
  %29 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %boxed59, i64 %1)
  %cmp60 = icmp ne ptr %29, null
  br i1 %cmp60, label %then61, label %else62

else56:                                           ; preds = %endif44
  br label %endif57

endif57:                                          ; preds = %else56, %endif63
  %regval65 = phi i64 [ 0, %endif63 ], [ 0, %else56 ]
  %30 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %31 = call i64 @avra_array_get(ptr %30, i64 4)
  %boxed66 = inttoptr i64 %31 to ptr
  %32 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed67 = inttoptr i64 %32 to ptr
  %33 = call i64 @avra_array_get(ptr %boxed67, i64 0)
  call void @avra_rc_retain(ptr %boxed66)
  call void @avra_rc_retain(ptr %regval33)
  %34 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Erecord_const_type"(ptr %boxed66, i64 %33, i64 %1, ptr %regval33)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %regval33)
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %34

then61:                                           ; preds = %then55
  call void @avra_rc_retain(ptr %29)
  br label %endif63

else62:                                           ; preds = %then55
  br label %endif63

endif63:                                          ; preds = %else62, %then61
  %regval64 = phi ptr [ %29, %then61 ], [ getelementptr inbounds (i8, ptr @.str.1, i64 16), %else62 ]
  %35 = call ptr @avra_insist(ptr %regval9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval64)
  call void @avra_rc_retain(ptr %35)
  %36 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edeclared_binding"(ptr %0, i64 %6, ptr %regval64, ptr %35)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %regval64)
  call void @avra_rc_release(ptr %29)
  br label %endif57
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Erecord_const_type"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edeclared_binding"(ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Eunformed"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed1, ptr %3)
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %8 = call ptr @avra_str_join(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %10 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %10, ptr %2)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_array_push_owned(ptr %10, ptr %8)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %11 = call ptr @avra_str_join(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %12 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %9, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16), ptr %11, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Ematerializable"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edeclared_decl"(ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 4)
  %boxed3 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed3, ptr %8)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed4 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed4, i64 5)
  %boxed5 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %1)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed5, ptr %1)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp6 = icmp eq i64 %13, 0
  br i1 %cmp6, label %then7, label %else8

then7:                                            ; preds = %endif
  br label %endif9

else8:                                            ; preds = %endif
  %14 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp10 = icmp eq i64 %14, 1
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %15 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp15 = icmp eq i64 %15, 2
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  %16 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp20 = icmp eq i64 %16, 3
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi i1 [ true, %then17 ], [ %cmp20, %else18 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif19
  br label %endif24

else23:                                           ; preds = %endif19
  %17 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp25 = icmp eq i64 %17, 10
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br i1 %regval26, label %then27, label %else28

then27:                                           ; preds = %endif24
  br label %endif29

else28:                                           ; preds = %endif24
  %18 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp30 = icmp eq i64 %18, 12
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval31 = phi i1 [ true, %then27 ], [ %cmp30, %else28 ]
  br i1 %regval31, label %then32, label %else33

then32:                                           ; preds = %endif29
  br label %endif34

else33:                                           ; preds = %endif29
  %19 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp35 = icmp eq i64 %19, 6
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval36 = phi i1 [ true, %then32 ], [ %cmp35, %else33 ]
  br i1 %regval36, label %then37, label %else38

then37:                                           ; preds = %endif34
  br label %endif39

else38:                                           ; preds = %endif34
  %20 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp40 = icmp eq i64 %20, 7
  br label %endif39

endif39:                                          ; preds = %else38, %then37
  %regval41 = phi i1 [ true, %then37 ], [ %cmp40, %else38 ]
  br i1 %regval41, label %then42, label %else43

then42:                                           ; preds = %endif39
  br label %endif44

else43:                                           ; preds = %endif39
  %21 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp45 = icmp eq i64 %21, 13
  br label %endif44

endif44:                                          ; preds = %else43, %then42
  %regval46 = phi i1 [ true, %then42 ], [ %cmp45, %else43 ]
  br i1 %regval46, label %then47, label %else48

then47:                                           ; preds = %endif44
  br label %endif49

else48:                                           ; preds = %endif44
  %22 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp50 = icmp eq i64 %22, 8
  br label %endif49

endif49:                                          ; preds = %else48, %then47
  %regval51 = phi i1 [ true, %then47 ], [ %cmp50, %else48 ]
  br i1 %regval51, label %then52, label %else53

then52:                                           ; preds = %endif49
  br label %endif54

else53:                                           ; preds = %endif49
  %23 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp55 = icmp eq i64 %23, 16
  br i1 %cmp55, label %then56, label %else57

endif54:                                          ; preds = %endif58, %then52
  %regval66 = phi i1 [ true, %then52 ], [ %regval65, %endif58 ]
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval66

then56:                                           ; preds = %else53
  %24 = call ptr @avra_array_get_owned(ptr %12, i64 1)
  %25 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed59 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %boxed59, i64 5)
  %boxed60 = inttoptr i64 %26 to ptr
  call void @avra_rc_retain(ptr %boxed60)
  call void @avra_rc_retain(ptr %1)
  %27 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Erides_pointer"(ptr %boxed60, ptr %1)
  br i1 %27, label %then61, label %else62

else57:                                           ; preds = %else53
  br label %endif58

endif58:                                          ; preds = %else57, %endif63
  %regval65 = phi i1 [ %regval64, %endif63 ], [ false, %else57 ]
  br label %endif54

then61:                                           ; preds = %then56
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %24)
  %28 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Ematerializable"(ptr %0, ptr %24)
  br label %endif63

else62:                                           ; preds = %then56
  br label %endif63

endif63:                                          ; preds = %else62, %then61
  %regval64 = phi i1 [ %28, %then61 ], [ false, %else62 ]
  call void @avra_rc_release(ptr %24)
  br label %endif58
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Ewritten"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eint_of"(ptr %0)
  %x = extractvalue { i1, i64 } %1, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Etext_of"(ptr %0)
  %cmp = icmp ne ptr %2, null
  call void @avra_rc_release(ptr %2)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  br label %endif3

else2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %3 = call { i1, i1 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebool_of"(ptr %0)
  %x4 = extractvalue { i1, i1 } %3, 0
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval5 = phi i1 [ true, %then1 ], [ %x4, %else2 ]
  br i1 %regval5, label %then6, label %else7

then6:                                            ; preds = %endif3
  br label %endif8

else7:                                            ; preds = %endif3
  call void @avra_rc_retain(ptr %0)
  %4 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2EExpr$2Ebits_of"(ptr %0)
  %x9 = extractvalue { i1, i64 } %4, 0
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval10 = phi i1 [ true, %then6 ], [ %x9, %else7 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval10
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_void_value"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Erefused_annotation"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp2 = icmp eq i64 %6, 22
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp2, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr, i64, ptr)
