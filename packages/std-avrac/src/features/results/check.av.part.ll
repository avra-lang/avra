; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.catch\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [80 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 79 }, [80 x i8] c"a selective `catch` lets the other failures pass, and this fn cannot carry them\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"the rest propagate\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [87 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 86 }, [87 x i8] c"name every variant (a total catch), add a catch-all arm `e ->`, or promise `Result<_, \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c">`\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.catch\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"a `catch` arm answers the ok side: `\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"`, this is `\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.catch\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"`.\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [24 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 23 }, [24 x i8] c"` carries nothing, so `\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [22 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 21 }, [22 x i8] c"` has nothing to hold\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.20 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"in this arm\00" }, align 16
@.str.21 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"drop the parentheses\00" }, align 16
@.str.22 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.catch\00" }, align 16
@.str.23 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.24 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"` has no variant `\00" }, align 16
@.str.25 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.26 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.27 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"in this arm\00" }, align 16
@.str.28 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.catch\00" }, align 16
@.str.29 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"`.\00" }, align 16
@.str.30 = private unnamed_addr constant { { i32, i32, i32, i32 }, [25 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 24 }, [25 x i8] c"` names a variant, but `\00" }, align 16
@.str.31 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"` has none\00" }, align 16
@.str.32 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.33 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"in this arm\00" }, align 16
@.str.34 = private unnamed_addr constant { { i32, i32, i32, i32 }, [46 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 45 }, [46 x i8] c"bind the whole error instead \E2\80\94 `catch e ->`\00" }, align 16
@.str.35 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"type.catch\00" }, align 16
@.str.36 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"`catch` recovers a `Result`, this is `\00" }, align 16
@.str.37 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.38 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.39 = private unnamed_addr constant { { i32, i32, i32, i32 }, [52 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 51 }, [52 x i8] c"only a fallible value has a failure to recover from\00" }, align 16

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

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eres_enum_sig"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr, i64, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Evariants_are"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evariants_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayload_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Etotal"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enamed_in"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %2, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatch_type"(ptr %0, i64 %1) {
entry:
  %slot6 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 31, label %arm
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  %8 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  %9 = call ptr @avra_array_get_owned(ptr %4, i64 4)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm2:                                             ; preds = %entry
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %lexit8
  %regval = phi ptr [ %16, %lexit8 ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %11
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot6, align 8
  br label %lhead7

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %15 = call i64 @avra_array_get(ptr %7, i64 %ld3)
  %boxed4 = inttoptr i64 %15 to ptr
  call void @avra_array_push_owned(ptr %10, ptr %boxed4)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead7:                                           ; preds = %lbody11, %lexit
  %ld9 = load i64, ptr %slot6, align 8
  %cmp10 = icmp slt i64 %ld9, %14
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %9)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatched_type"(ptr %0, i64 %1, i64 %6, ptr %10, ptr %13, ptr %9)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot6, align 8
  %17 = call i64 @avra_array_get(ptr %8, i64 %ld12)
  %boxed13 = inttoptr i64 %17 to ptr
  call void @avra_array_push_owned(ptr %13, ptr %boxed13)
  %ld14 = load i64, ptr %slot6, align 8
  %add15 = add i64 %ld14, 1
  store i64 %add15, ptr %slot6, align 8
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecatched_type"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot13 = alloca i64, align 8
  %slot12 = alloca i64, align 8
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored"(ptr %0, i64 %2)
  br i1 %6, label %then, label %else

then:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %9 = call i64 @avra_array_get(ptr %8, i64 5)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed, ptr %10)
  %cmp = icmp ne ptr %11, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %7)
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enot_a_result"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %13 = call ptr @avra_insist(ptr %11)
  %14 = call ptr @avra_array_get_owned(ptr %13, i64 0)
  %15 = call ptr @avra_insist(ptr %11)
  %16 = call ptr @avra_array_get_owned(ptr %15, i64 1)
  %17 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %12)
  br label %endif3

lhead:                                            ; preds = %lbody, %endif3
  %ld = load i64, ptr %slot, align 8
  %cmp7 = icmp slt i64 %ld, %17
  br i1 %cmp7, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %18 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot12, align 8
  br label %lhead14

lbody:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot, align 8
  %19 = call ptr @avra_array_get_owned(ptr %3, i64 %ld8)
  call void @avra_rc_retain(ptr %19)
  call void @avra_cell_release(ptr %slot6)
  store ptr %19, ptr %slot6, align 8
  %ld9 = load ptr, ptr %slot6, align 8
  %20 = call i64 @avra_array_get(ptr %4, i64 %ld8)
  %boxed10 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %5, i64 %ld8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %ld9)
  call void @avra_rc_retain(ptr %boxed10)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_bind"(ptr %0, i64 %1, ptr %16, ptr %ld9, ptr %boxed10, i64 %21)
  %ld11 = load i64, ptr %slot, align 8
  %add = add i64 %ld11, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %19)
  br label %lhead

lhead14:                                          ; preds = %lbody18, %lexit
  %ld16 = load i64, ptr %slot12, align 8
  %cmp17 = icmp slt i64 %ld16, %18
  br i1 %cmp17, label %lbody18, label %lexit15

lexit15:                                          ; preds = %lhead14
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %3)
  %23 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecovers"(ptr %0, ptr %16, ptr %3)
  br i1 %23, label %then23, label %else24

lbody18:                                          ; preds = %lhead14
  %ld19 = load i64, ptr %slot12, align 8
  %24 = call i64 @avra_array_get(ptr %5, i64 %ld19)
  store i64 %24, ptr %slot13, align 8
  %ld20 = load i64, ptr %slot13, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_answer"(ptr %0, ptr %14, i64 %ld20)
  %ld21 = load i64, ptr %slot12, align 8
  %add22 = add i64 %ld21, 1
  store i64 %add22, ptr %slot12, align 8
  br label %lhead14

then23:                                           ; preds = %lexit15
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else24:                                           ; preds = %lexit15
  br label %endif25

endif25:                                          ; preds = %else24, %postret26
  %regval27 = phi i64 [ 0, %postret26 ], [ 0, %else24 ]
  call void @avra_rc_retain(ptr %0)
  %26 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr %0)
  %cmp28 = icmp ne ptr %26, null
  br i1 %cmp28, label %then29, label %else30

postret26:                                        ; No predecessors!
  br label %endif25

then29:                                           ; preds = %endif25
  %27 = call ptr @avra_insist(ptr %26)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %27)
  call void @avra_rc_release(ptr %27)
  br label %endif31

else30:                                           ; preds = %endif25
  br label %endif31

endif31:                                          ; preds = %else30, %then29
  %regval32 = phi i1 [ %28, %then29 ], [ false, %else30 ]
  br i1 %regval32, label %then33, label %else34

then33:                                           ; preds = %endif31
  %29 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %29

else34:                                           ; preds = %endif31
  br label %endif35

endif35:                                          ; preds = %else34, %postret36
  %regval37 = phi i64 [ 0, %postret36 ], [ 0, %else34 ]
  %cmp38 = icmp ne ptr %26, null
  %not39 = xor i1 %cmp38, true
  br i1 %not39, label %then40, label %else41

postret36:                                        ; No predecessors!
  call void @avra_rc_release(ptr %29)
  br label %endif35

then40:                                           ; preds = %endif35
  br label %endif42

else41:                                           ; preds = %endif35
  %30 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed43 = inttoptr i64 %30 to ptr
  %31 = call i64 @avra_array_get(ptr %boxed43, i64 5)
  %boxed44 = inttoptr i64 %31 to ptr
  call void @avra_rc_retain(ptr %boxed44)
  call void @avra_rc_retain(ptr %26)
  %32 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed44, ptr %26)
  br label %endif42

endif42:                                          ; preds = %else41, %then40
  %regval45 = phi ptr [ null, %then40 ], [ %32, %else41 ]
  %cmp46 = icmp ne ptr %regval45, null
  %not47 = xor i1 %cmp46, true
  br i1 %not47, label %then48, label %else49

then48:                                           ; preds = %endif42
  br label %endif50

else49:                                           ; preds = %endif42
  %33 = call ptr @avra_insist(ptr %regval45)
  %34 = call i64 @avra_array_get(ptr %33, i64 1)
  %boxed51 = inttoptr i64 %34 to ptr
  %35 = call i64 @avra_array_get(ptr %boxed51, i64 0)
  %36 = call i64 @avra_array_get(ptr %16, i64 0)
  %cmp52 = icmp ne i64 %35, %36
  call void @avra_rc_release(ptr %33)
  br label %endif50

endif50:                                          ; preds = %else49, %then48
  %regval53 = phi i1 [ true, %then48 ], [ %cmp52, %else49 ]
  br i1 %regval53, label %then54, label %else55

then54:                                           ; preds = %endif50
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %37 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Euncarried_rest"(ptr %0, i64 %1, ptr %16)
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %regval45)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %37

else55:                                           ; preds = %endif50
  br label %endif56

endif56:                                          ; preds = %else55, %postret57
  %regval58 = phi i64 [ 0, %postret57 ], [ 0, %else55 ]
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %regval45)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret57:                                        ; No predecessors!
  call void @avra_rc_release(ptr %37)
  br label %endif56
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Euncarried_rest"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed1, ptr %2)
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %8 = call ptr @avra_str_join(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %3, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %10
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Ecovers"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Echeck$24l186" to i64))
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  br i1 %ld4, label %then5, label %else6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call i64 @avra_array_get(ptr %2, i64 %ld2)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %4 to ptr
  %7 = call i1 %cast(ptr %3, ptr %boxed)
  br i1 %7, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %5, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

then5:                                            ; preds = %lexit
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else6:                                            ; preds = %lexit
  br label %endif7

endif7:                                           ; preds = %else6, %postret
  %regval8 = phi i64 [ 0, %postret ], [ 0, %else6 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evariants_of"(ptr %0, ptr %1)
  %cmp9 = icmp ne ptr %8, null
  %not = xor i1 %cmp9, true
  br i1 %not, label %then10, label %else11

postret:                                          ; No predecessors!
  br label %endif7

then10:                                           ; preds = %endif7
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else11:                                           ; preds = %endif7
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  %9 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %2)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Etotal"(ptr %9, ptr %2)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %10

postret13:                                        ; No predecessors!
  br label %endif12
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Echeck$24l186"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_streq(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %b = icmp ne i64 %2, 0
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_answer"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %3)
  br i1 %4, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eaccepts"(ptr %0, i64 %2, ptr %1)
  br i1 %5, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_not_ok"(ptr %0, i64 %2, ptr %1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

postret4:                                         ; No predecessors!
  br label %endif3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_not_ok"(ptr %0, i64 %1, ptr %2) {
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
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %11)
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
  ret i64 %12
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Earm_bind"(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4, i64 %5) {
entry:
  %6 = call i64 @avra_streq(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %b = icmp ne i64 %6, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %7 = call i64 @avra_streq(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  %b1 = icmp ne i64 %7, 0
  %not = xor i1 %b1, true
  br i1 %not, label %then2, label %else3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evariants_of"(ptr %0, ptr %2)
  %cmp = icmp ne ptr %8, null
  %not6 = xor i1 %cmp, true
  br i1 %not6, label %then7, label %else8

then2:                                            ; preds = %then
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %9, ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebind_types"(ptr %0, i64 %5, ptr %9)
  call void @avra_rc_release(ptr %9)
  br label %endif4

else3:                                            ; preds = %then
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi i64 [ 0, %then2 ], [ 0, %else3 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  br label %endif

then7:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %2)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eno_variants_to_name"(ptr %0, i64 %1, ptr %3, ptr %2)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  %12 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %3)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayload_of"(ptr %12, ptr %3)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %3)
  %14 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %12, ptr %3)
  %x = extractvalue { i1, i64 } %14, 0
  %not12 = xor i1 %x, true
  br i1 %not12, label %then13, label %else14

postret10:                                        ; No predecessors!
  br label %endif9

then13:                                           ; preds = %endif9
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %12)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eno_such_failure"(ptr %0, i64 %1, ptr %2, ptr %3, ptr %12)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else14:                                           ; preds = %endif9
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  %cmp18 = icmp ne ptr %13, null
  %not19 = xor i1 %cmp18, true
  br i1 %not19, label %then20, label %else21

postret16:                                        ; No predecessors!
  br label %endif15

then20:                                           ; preds = %endif15
  %16 = call i64 @avra_streq(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %b23 = icmp ne i64 %16, 0
  %not24 = xor i1 %b23, true
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  br label %endif22

else21:                                           ; preds = %endif15
  br label %endif22

endif22:                                          ; preds = %else21, %then20
  %regval25 = phi i1 [ %not24, %then20 ], [ false, %else21 ]
  br i1 %regval25, label %then26, label %else27

then26:                                           ; preds = %endif22
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enothing_to_hold"(ptr %0, i64 %1, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else27:                                           ; preds = %endif22
  br label %endif28

endif28:                                          ; preds = %else27, %postret29
  %regval30 = phi i64 [ 0, %postret29 ], [ 0, %else27 ]
  %cmp31 = icmp ne ptr %13, null
  br i1 %cmp31, label %then32, label %else33

postret29:                                        ; No predecessors!
  br label %endif28

then32:                                           ; preds = %endif28
  %18 = call ptr @avra_insist(ptr %13)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebind_types"(ptr %0, i64 %5, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  br label %endif34

else33:                                           ; preds = %endif28
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval35 = phi i64 [ 0, %then32 ], [ 0, %else33 ]
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enothing_to_hold"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %5 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %3)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  %6 = call ptr @avra_str_join(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16), ptr %4, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.20, i64 16), ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eno_such_failure"(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed1, ptr %2)
  %9 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %3)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  %10 = call ptr @avra_str_join(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_retain(ptr %4)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Evariants_are"(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16), ptr %5, ptr %10, ptr getelementptr inbounds (i8, ptr @.str.27, i64 16), ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %13
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eno_variants_to_name"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed1, ptr %3)
  %8 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.29, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.30, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.31, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.32, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.33, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  %10 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16), ptr %4, ptr %9, ptr getelementptr inbounds (i8, ptr @.str.33, i64 16), ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eemit"(ptr %0, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.33, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.32, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.31, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.30, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.29, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %11
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebind_types"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Enot_a_result"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ename_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eloc_of"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.36, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.37, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  call void @avra_rc_retain(ptr %2)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ethis_is"(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.35, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.35, i64 16), ptr %3, ptr %5, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Espoken"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.37, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.36, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.35, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eres_variants$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eres_variants"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eres_shape$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eres_shape"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eres_variants"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eres_enum_sig"(ptr %boxed, ptr %boxed2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eres_shape"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 13)
  call void @avra_array_push_owned(ptr %5, ptr %boxed)
  call void @avra_array_push_owned(ptr %5, ptr %boxed2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}
