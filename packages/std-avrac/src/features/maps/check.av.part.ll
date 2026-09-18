; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"a map value\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"type.map_value\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"this map holds `\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"`, this is `\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"a map value\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"type.map_value\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"this map holds `\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"`, this is `\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"type.map_key\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [36 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 35 }, [36 x i8] c"a map's keys are strings, this is `\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"other key types are recorded \E2\80\94 spell the key as text\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr, i64, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etypes_disagree"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eshape_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Emap_type"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot37 = alloca i64, align 8
  %slot36 = alloca i64, align 8
  %slot2 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 19)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed1, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %9)
  %11 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

lhead:                                            ; preds = %endif8, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp3 = icmp slt i64 %ld, %11
  br i1 %cmp3, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  %12 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewant_refused"(ptr %0, i64 %1)
  br i1 %12, label %then13, label %else14

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %13 = call i64 @avra_array_get(ptr %2, i64 %ld4)
  store i64 %13, ptr %slot2, align 8
  %ld5 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %ld5, ptr %10)
  %not = xor i1 %14, true
  br i1 %not, label %then6, label %else7

then6:                                            ; preds = %lbody
  %ld9 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Ekey_not_string"(ptr %0, i64 %ld9)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

else7:                                            ; preds = %lbody
  br label %endif8

endif8:                                           ; preds = %else7, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else7 ]
  %ld12 = load i64, ptr %slot, align 8
  %add = add i64 %ld12, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  br label %endif8

then13:                                           ; preds = %lexit
  %16 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else14:                                           ; preds = %lexit
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Ewanted_value"(ptr %0, i64 %1)
  %cmp18 = icmp ne ptr %17, null
  br i1 %cmp18, label %then19, label %else20

postret16:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  br label %endif15

then19:                                           ; preds = %endif15
  %18 = call ptr @avra_insist(ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Eheard_map"(ptr %0, i64 %1, ptr %3, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %19

else20:                                           ; preds = %endif15
  br label %endif21

endif21:                                          ; preds = %else20, %postret22
  %regval23 = phi i64 [ 0, %postret22 ], [ 0, %else20 ]
  %20 = call i64 @avra_array_get(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %20)
  call void @avra_rc_retain(ptr %0)
  %22 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %20)
  br i1 %22, label %then24, label %else25

postret22:                                        ; No predecessors!
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  br label %endif21

then24:                                           ; preds = %endif21
  %23 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

else25:                                           ; preds = %endif21
  br label %endif26

endif26:                                          ; preds = %else25, %postret27
  %regval28 = phi i64 [ 0, %postret27 ], [ 0, %else25 ]
  %24 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %25 = call i64 @avra_array_get(ptr %24, i64 5)
  %boxed29 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %0)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eshape_at"(ptr %0, i64 %20)
  call void @avra_rc_retain(ptr %boxed29)
  call void @avra_rc_retain(ptr %26)
  %27 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr %boxed29, ptr %26)
  %not30 = xor i1 %27, true
  br i1 %not30, label %then31, label %else32

postret27:                                        ; No predecessors!
  call void @avra_rc_release(ptr %23)
  br label %endif26

then31:                                           ; preds = %endif26
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunslottable"(ptr %0, i64 %20, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %28

else32:                                           ; preds = %endif26
  br label %endif33

endif33:                                          ; preds = %else32, %postret34
  %regval35 = phi i64 [ 0, %postret34 ], [ 0, %else32 ]
  %29 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot36, align 8
  br label %lhead38

postret34:                                        ; No predecessors!
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif33

lhead38:                                          ; preds = %endif47, %endif33
  %ld40 = load i64, ptr %slot36, align 8
  %cmp41 = icmp slt i64 %ld40, %29
  br i1 %cmp41, label %lbody42, label %lexit39

lexit39:                                          ; preds = %lhead38
  %30 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %30, i64 13)
  call void @avra_array_push_owned(ptr %30, ptr %10)
  %31 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %31, i64 13)
  call void @avra_array_push_owned(ptr %31, ptr %21)
  %32 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %32, i64 10)
  call void @avra_array_push_owned(ptr %32, ptr %30)
  call void @avra_array_push_owned(ptr %32, ptr %31)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %32)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %32)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %33

lbody42:                                          ; preds = %lhead38
  %ld43 = load i64, ptr %slot36, align 8
  %34 = call i64 @avra_array_get(ptr %3, i64 %ld43)
  store i64 %34, ptr %slot37, align 8
  %ld44 = load i64, ptr %slot37, align 8
  call void @avra_rc_retain(ptr %0)
  %35 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %ld44)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %35)
  call void @avra_rc_retain(ptr %21)
  %36 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etypes_disagree"(ptr %0, ptr %35, ptr %21)
  br i1 %36, label %then45, label %else46

then45:                                           ; preds = %lbody42
  %ld48 = load i64, ptr %slot37, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %37 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Edisagreeing_value"(ptr %0, i64 %ld48, ptr %21)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %37

else46:                                           ; preds = %lbody42
  br label %endif47

endif47:                                          ; preds = %else46, %postret49
  %regval50 = phi i64 [ 0, %postret49 ], [ 0, %else46 ]
  %ld51 = load i64, ptr %slot36, align 8
  %add52 = add i64 %ld51, 1
  store i64 %add52, ptr %slot36, align 8
  call void @avra_rc_release(ptr %35)
  br label %lhead38

postret49:                                        ; No predecessors!
  call void @avra_rc_release(ptr %37)
  br label %endif47
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Edisagreeing_value"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed1, ptr %2)
  %8 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %3)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %3)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr %4, ptr %9, ptr %10, ptr null)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %12
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunslottable"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Eheard_map"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot3 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %5 = call i64 @avra_array_get(ptr %4, i64 5)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed1, i64 5)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed2, ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %8)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr %boxed, ptr %8)
  %not = xor i1 %9, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunslottable_want"(ptr %0, i64 %1, ptr %3, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %11 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif

lhead:                                            ; preds = %endif9, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %11
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 3)
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 13)
  call void @avra_array_push_owned(ptr %13, ptr %3)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 10)
  call void @avra_array_push_owned(ptr %14, ptr %12)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %16 = call i64 @avra_array_get(ptr %2, i64 %ld4)
  store i64 %16, ptr %slot3, align 8
  %ld5 = load i64, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %17 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %ld5, ptr %3)
  %not6 = xor i1 %17, true
  br i1 %not6, label %then7, label %else8

then7:                                            ; preds = %lbody
  %ld10 = load i64, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Eunwanted_value"(ptr %0, i64 %ld10, ptr %3)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

else8:                                            ; preds = %lbody
  br label %endif9

endif9:                                           ; preds = %else8, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else8 ]
  %ld13 = load i64, ptr %slot, align 8
  %add = add i64 %ld13, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret11:                                        ; No predecessors!
  call void @avra_rc_release(ptr %18)
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Eunwanted_value"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed1, ptr %2)
  %8 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %3)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %3)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr %4, ptr %9, ptr %10, ptr null)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %12
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunslottable_want"(ptr, i64, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Ewanted_value"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewant_at"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm2 [
    i64 12, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  br label %endswitch

arm2:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval3 = phi ptr [ %8, %arm ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewant_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewant_refused"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Ekey_not_string"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %2)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16), ptr %3, ptr %5, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}
