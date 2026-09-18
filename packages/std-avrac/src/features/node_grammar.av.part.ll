; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"string\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"int\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"bool\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"Scoped\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"Plain\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"Nominal\00" }, align 16
@"av_const$111$67" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [6 x i64], [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 6, i64 6, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [6 x i64], [6 x i8] }, ptr @"av_const$111$67", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [6 x i64], [6 x i8] }, ptr @"av_const$111$67", i32 0, i32 3), ptr null }, [6 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.1, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.2, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.3, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.4, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.5, i64 16) to i64)], [6 x i8] c"\01\01\01\01\01\01" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"rule `\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"` \00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"gives `\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"`'s `\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c": \00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"` \00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c", and it holds \00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"List<\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"?\00" }, align 16
@.str.20 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"a built node\00" }, align 16
@.str.21 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"a token's text\00" }, align 16
@.str.22 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"builds `\00" }, align 16
@.str.23 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.24 = private unnamed_addr constant { { i32, i32, i32, i32 }, [22 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 21 }, [22 x i8] c"` and nothing fills `\00" }, align 16
@.str.25 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c": \00" }, align 16
@.str.26 = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"` \E2\80\94 only a list or a nullable payload may go unnamed\00" }, align 16
@.str.27 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.28 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"List<\00" }, align 16
@.str.29 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"?\00" }, align 16
@.str.30 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"names `\00" }, align 16
@.str.31 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"`, and `\00" }, align 16
@.str.32 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.33 = private unnamed_addr constant { { i32, i32, i32, i32 }, [38 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 37 }, [38 x i8] c"` has no such payload \E2\80\94 it carries \00" }, align 16
@.str.34 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.35 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.36 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"nothing\00" }, align 16
@.str.37 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.38 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"`, `\00" }, align 16
@.str.39 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.40 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.41 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"builds `\00" }, align 16
@.str.42 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c".\00" }, align 16
@.str.43 = private unnamed_addr constant { { i32, i32, i32, i32 }, [35 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 34 }, [35 x i8] c"`, and no such variant is declared\00" }, align 16
@.str.44 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Elabels"(ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Edeep_items"(ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Eseqs"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebind_nodes"(ptr %0, ptr %1) {
entry:
  %slot6 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed5 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %boxed5)
  call void @avra_array_push_owned(ptr %7, ptr %2)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %10 = call i64 @avra_array_len(ptr %9)
  store i64 0, ptr %slot6, align 8
  br label %lhead7

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %11 = call i64 @avra_array_get(ptr %3, i64 %ld1)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call ptr @avra_array_get_owned(ptr %boxed, i64 0)
  %13 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_alt"(ptr %12, ptr %boxed2, ptr %1)
  %15 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed3 = inttoptr i64 %15 to ptr
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %16, ptr %boxed3)
  call void @avra_array_push_owned(ptr %16, ptr %14)
  call void @avra_array_push_owned(ptr %2, ptr %16)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  br label %lhead

lhead7:                                           ; preds = %lbody11, %lexit
  %ld9 = load i64, ptr %slot6, align 8
  %cmp10 = icmp slt i64 %ld9, %10
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  call void @avra_rc_retain(ptr %8)
  %17 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr %8)
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %18, ptr %7)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot6, align 8
  %19 = call i64 @avra_array_get(ptr %9, i64 %ld12)
  %boxed13 = inttoptr i64 %19 to ptr
  %20 = call ptr @avra_array_get_owned(ptr %boxed13, i64 0)
  %21 = call i64 @avra_array_get(ptr %boxed13, i64 1)
  %boxed14 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %1)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealt_defects"(ptr %20, ptr %boxed14, ptr %1)
  call void @avra_array_push_owned(ptr %8, ptr %22)
  %ld15 = load i64, ptr %slot6, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot6, align 8
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %20)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ealt_defects"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebranch_defects"(ptr %0, ptr %boxed, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebranch_defects"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Eseqs"(ptr %1)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eseq_defects"(ptr %0, ptr %boxed, ptr %1, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eseq_defects"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_insist(ptr %boxed1)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm2 [
    i64 2, label %arm
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif

arm:                                              ; preds = %endif
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  %10 = call ptr @avra_array_get_owned(ptr %7, i64 2)
  %11 = call i64 @avra_array_get(ptr %7, i64 3)
  %boxed3 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %3)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_defects"(ptr %0, ptr %2, ptr %9, ptr %10, ptr %boxed3, ptr %3)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endswitch

arm2:                                             ; preds = %endif
  %13 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval4 = phi ptr [ %12, %arm ], [ %13, %arm2 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_defects"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Erow_for"(ptr %5, ptr %2, ptr %3)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_such_variant"(ptr %2, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_refusal"(ptr %0, ptr %7)
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call ptr @avra_insist(ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %4)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ejudged"(ptr %0, ptr %1, ptr %10, ptr %4)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ejudged"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estranger_defects"(ptr %0, ptr %1, ptr %2, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eunfilled_defects"(ptr %0, ptr %1, ptr %2, ptr %3)
  %6 = call ptr @avra_array_concat(ptr %4, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eshape_defects"(ptr %0, ptr %1, ptr %2)
  %8 = call ptr @avra_array_concat(ptr %6, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eshape_defects"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epayload_shape"(ptr %0, ptr %1, ptr %2, ptr %boxed)
  call void @avra_array_push_owned(ptr %3, ptr %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Epayload_shape"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_grammar$24l282" to i64))
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Edeep_items"(ptr %1)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  %not = xor i1 %cmp5, true
  br i1 %not, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %8)
  %cast = inttoptr i64 %5 to ptr
  %9 = call i1 %cast(ptr %4, ptr %8)
  br i1 %9, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot)
  store ptr %8, ptr %slot, align 8
  store i64 %7, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead

then6:                                            ; preds = %lexit
  %10 = call ptr @avra_array_sized(i64 0)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else7:                                            ; preds = %lexit
  br label %endif8

endif8:                                           ; preds = %else7, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else7 ]
  %11 = call ptr @avra_insist(ptr %ld4)
  %12 = call i64 @avra_array_get(ptr %11, i64 1)
  %boxed = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecarrier_of"(ptr %boxed)
  %cmp10 = icmp ne ptr %13, null
  %not11 = xor i1 %cmp10, true
  br i1 %not11, label %then12, label %else13

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif8

then12:                                           ; preds = %endif8
  br label %endif14

else13:                                           ; preds = %endif8
  %14 = call ptr @avra_insist(ptr %13)
  %15 = call i64 @avra_array_get(ptr %3, i64 1)
  %boxed15 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %boxed15)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ewanted_carrier"(ptr %boxed15)
  %17 = call i64 @avra_array_get(ptr %14, i64 0)
  %18 = call i64 @avra_array_get(ptr %16, i64 0)
  %cmp16 = icmp eq i64 %17, %18
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval17 = phi i1 [ true, %then12 ], [ %cmp16, %else13 ]
  br i1 %regval17, label %then18, label %else19

then18:                                           ; preds = %endif14
  %19 = call ptr @avra_array_sized(i64 0)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %19

else19:                                           ; preds = %endif14
  br label %endif20

endif20:                                          ; preds = %else19, %postret21
  %regval22 = phi i64 [ 0, %postret21 ], [ 0, %else19 ]
  %20 = call ptr @avra_insist(ptr %13)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ewrong_shape"(ptr %2, ptr %3, ptr %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_refusal"(ptr %0, ptr %21)
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

postret21:                                        ; No predecessors!
  call void @avra_rc_release(ptr %19)
  br label %endif20
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Enode_grammar$24l282"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Elabelled"(ptr %1, ptr %boxed1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %4
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Elabelled"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %cmp = icmp ne ptr %boxed, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %boxed1)
  %5 = call i64 @avra_streq(ptr %4, ptr %1)
  %b = icmp ne i64 %5, 0
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %b, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_refusal"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %3 = call ptr @avra_str_join(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ewrong_shape"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecarrier_word"(ptr %2)
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ewanted_carrier"(ptr %boxed1)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecarrier_word"(ptr %9)
  %11 = call ptr @avra_array_sized(i64 13)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %boxed)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %5)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %6)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  %12 = call ptr @avra_str_join(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ewanted_carrier"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Etexted"(ptr %0)
  br i1 %1, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %2)
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Etexted"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eelement_of"(ptr %0)
  %2 = call i64 @avra_array_len(ptr getelementptr inbounds (i8, ptr @"av_const$111$67", i64 16))
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
  %3 = call i64 @avra_array_get(ptr getelementptr inbounds (i8, ptr @"av_const$111$67", i64 16), i64 %ld2)
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eelement_of"(ptr %0) {
entry:
  %1 = call i64 @avra_str_starts_with(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  %b = icmp ne i64 %1, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %2 = call i64 @avra_str_len(ptr %0)
  %sub = sub i64 %2, 1
  %3 = call ptr @avra_str_substring(ptr %0, i64 5, i64 %sub)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eelement_of"(ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call i64 @avra_str_ends_with(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  %b1 = icmp ne i64 %5, 0
  br i1 %b1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  br label %endif

then2:                                            ; preds = %endif
  %6 = call i64 @avra_str_len(ptr %0)
  %sub5 = sub i64 %6, 1
  %7 = call ptr @avra_str_substring(ptr %0, i64 0, i64 %sub5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %7

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else3 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %0

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %7)
  br label %endif4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecarrier_word"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.20, i64 16), %arm ], [ getelementptr inbounds (i8, ptr @.str.21, i64 16), %arm1 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecarrier_of"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm2 [
    i64 0, label %arm
    i64 2, label %arm1
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  br label %endswitch

arm1:                                             ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ %3, %arm1 ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eunfilled_defects"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot16 = alloca i64, align 8
  %slot15 = alloca i1, align 1
  %slot3 = alloca i64, align 8
  %slot2 = alloca i1, align 1
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Elabels"(ptr %1)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif41, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 %ld1)
  store i1 false, ptr %slot2, align 8
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 0)
  %10 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot3, align 8
  br label %lhead4

lhead4:                                           ; preds = %endif, %lbody
  %ld6 = load i64, ptr %slot3, align 8
  %cmp7 = icmp slt i64 %ld6, %10
  br i1 %cmp7, label %lbody8, label %lexit5

lexit5:                                           ; preds = %lhead4
  %ld11 = load i1, ptr %slot2, align 8
  %not = xor i1 %ld11, true
  br i1 %not, label %then12, label %else13

lbody8:                                           ; preds = %lhead4
  %ld9 = load i64, ptr %slot3, align 8
  %11 = call i64 @avra_array_get(ptr %4, i64 %ld9)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_streq(ptr %boxed, ptr %9)
  %b = icmp ne i64 %12, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody8
  store i1 true, ptr %slot2, align 8
  store i64 %10, ptr %slot3, align 8
  br label %endif

else:                                             ; preds = %lbody8
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld10 = load i64, ptr %slot3, align 8
  %add = add i64 %ld10, 1
  store i64 %add, ptr %slot3, align 8
  br label %lhead4

then12:                                           ; preds = %lexit5
  store i1 false, ptr %slot15, align 8
  %13 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_grammar$24l249" to i64))
  call void @avra_array_push_owned(ptr %13, ptr %8)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %15 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot16, align 8
  br label %lhead17

else13:                                           ; preds = %lexit5
  br label %endif14

endif14:                                          ; preds = %else13, %lexit18
  %regval32 = phi i1 [ %not31, %lexit18 ], [ false, %else13 ]
  br i1 %regval32, label %then33, label %else34

lhead17:                                          ; preds = %endif26, %then12
  %ld19 = load i64, ptr %slot16, align 8
  %cmp20 = icmp slt i64 %ld19, %15
  br i1 %cmp20, label %lbody21, label %lexit18

lexit18:                                          ; preds = %lhead17
  %ld30 = load i1, ptr %slot15, align 8
  %not31 = xor i1 %ld30, true
  call void @avra_rc_release(ptr %13)
  br label %endif14

lbody21:                                          ; preds = %lhead17
  %ld22 = load i64, ptr %slot16, align 8
  %16 = call i64 @avra_array_get(ptr %3, i64 %ld22)
  %boxed23 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %boxed23)
  %cast = inttoptr i64 %14 to ptr
  %17 = call i1 %cast(ptr %13, ptr %boxed23)
  br i1 %17, label %then24, label %else25

then24:                                           ; preds = %lbody21
  store i1 true, ptr %slot15, align 8
  store i64 %15, ptr %slot16, align 8
  br label %endif26

else25:                                           ; preds = %lbody21
  br label %endif26

endif26:                                          ; preds = %else25, %then24
  %regval27 = phi i64 [ 0, %then24 ], [ 0, %else25 ]
  %ld28 = load i64, ptr %slot16, align 8
  %add29 = add i64 %ld28, 1
  store i64 %add29, ptr %slot16, align 8
  br label %lhead17

then33:                                           ; preds = %endif14
  %18 = call i64 @avra_array_get(ptr %8, i64 1)
  %boxed36 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %boxed36)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eabsence_is_a_value"(ptr %boxed36)
  %not37 = xor i1 %19, true
  br label %endif35

else34:                                           ; preds = %endif14
  br label %endif35

endif35:                                          ; preds = %else34, %then33
  %regval38 = phi i1 [ %not37, %then33 ], [ false, %else34 ]
  br i1 %regval38, label %then39, label %else40

then39:                                           ; preds = %endif35
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %8)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enothing_fills"(ptr %2, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_refusal"(ptr %0, ptr %20)
  call void @avra_array_push_owned(ptr %5, ptr %21)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  br label %endif41

else40:                                           ; preds = %endif35
  br label %endif41

endif41:                                          ; preds = %else40, %then39
  %regval42 = phi i64 [ 0, %then39 ], [ 0, %else40 ]
  %ld43 = load i64, ptr %slot, align 8
  %add44 = add i64 %ld43, 1
  store i64 %add44, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Enode_grammar$24l249"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_streq(ptr %boxed, ptr %boxed2)
  %b = icmp ne i64 %5, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Enothing_fills"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %boxed)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %boxed1)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  %7 = call ptr @avra_str_join(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eabsence_is_a_value"(ptr %0) {
entry:
  %1 = call i64 @avra_str_starts_with(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  %b = icmp ne i64 %1, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %2 = call i64 @avra_str_ends_with(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.29, i64 16))
  %b1 = icmp ne i64 %2, 0
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.29, i64 16))
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %b1, %else ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estranger_defects"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot23 = alloca i64, align 8
  %slot22 = alloca i1, align 1
  %slot15 = alloca i64, align 8
  %slot4 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 2)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %7 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  %8 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Elabels"(ptr %1)
  %9 = call ptr @avra_array_sized(i64 0)
  %10 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %11 = call i64 @avra_array_get(ptr %5, i64 %ld1)
  %boxed = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed2 = inttoptr i64 %12 to ptr
  call void @avra_array_push_owned(ptr %4, ptr %boxed2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead5:                                           ; preds = %lbody9, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %10
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  %13 = call ptr @avra_array_concat(ptr %8, ptr %9)
  %14 = call i64 @avra_array_len(ptr %13)
  store i64 0, ptr %slot15, align 8
  br label %lhead16

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %15 = call i64 @avra_array_get(ptr %3, i64 %ld10)
  %boxed11 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %boxed11, i64 0)
  %boxed12 = inttoptr i64 %16 to ptr
  call void @avra_array_push_owned(ptr %9, ptr %boxed12)
  %ld13 = load i64, ptr %slot4, align 8
  %add14 = add i64 %ld13, 1
  store i64 %add14, ptr %slot4, align 8
  br label %lhead5

lhead16:                                          ; preds = %endif36, %lexit6
  %ld18 = load i64, ptr %slot15, align 8
  %cmp19 = icmp slt i64 %ld18, %14
  br i1 %cmp19, label %lbody20, label %lexit17

lexit17:                                          ; preds = %lhead16
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

lbody20:                                          ; preds = %lhead16
  %ld21 = load i64, ptr %slot15, align 8
  %17 = call ptr @avra_array_get_owned(ptr %13, i64 %ld21)
  store i1 false, ptr %slot22, align 8
  %18 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot23, align 8
  br label %lhead24

lhead24:                                          ; preds = %endif, %lbody20
  %ld26 = load i64, ptr %slot23, align 8
  %cmp27 = icmp slt i64 %ld26, %18
  br i1 %cmp27, label %lbody28, label %lexit25

lexit25:                                          ; preds = %lhead24
  %ld33 = load i1, ptr %slot22, align 8
  %not = xor i1 %ld33, true
  br i1 %not, label %then34, label %else35

lbody28:                                          ; preds = %lhead24
  %ld29 = load i64, ptr %slot23, align 8
  %19 = call i64 @avra_array_get(ptr %4, i64 %ld29)
  %boxed30 = inttoptr i64 %19 to ptr
  %20 = call i64 @avra_streq(ptr %boxed30, ptr %17)
  %b = icmp ne i64 %20, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody28
  store i1 true, ptr %slot22, align 8
  store i64 %18, ptr %slot23, align 8
  br label %endif

else:                                             ; preds = %lbody28
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld31 = load i64, ptr %slot23, align 8
  %add32 = add i64 %ld31, 1
  store i64 %add32, ptr %slot23, align 8
  br label %lhead24

then34:                                           ; preds = %lexit25
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %17)
  call void @avra_rc_retain(ptr %4)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_such_payload"(ptr %2, ptr %17, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_refusal"(ptr %0, ptr %21)
  call void @avra_array_push_owned(ptr %7, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  br label %endif36

else35:                                           ; preds = %lexit25
  br label %endif36

endif36:                                          ; preds = %else35, %then34
  %regval37 = phi i64 [ 0, %then34 ], [ 0, %else35 ]
  %ld38 = load i64, ptr %slot15, align 8
  %add39 = add i64 %ld38, 1
  store i64 %add39, ptr %slot15, align 8
  call void @avra_rc_release(ptr %17)
  br label %lhead16
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_such_payload"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elisted"(ptr %2)
  %6 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.30, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %1)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.31, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %3)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.32, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %boxed)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.33, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  %7 = call ptr @avra_str_join(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.35, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.35, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.33, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.32, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.31, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.30, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elisted"(ptr %0) {
entry:
  %1 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp eq i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.36, i64 16)

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.37, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  %4 = call ptr @avra_str_join(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.40, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.40, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.37, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.36, i64 16))
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_such_variant"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.41, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.42, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.43, i64 16))
  %3 = call ptr @avra_str_join(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.44, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.44, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.43, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.42, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.41, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Erow_for"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_alt"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %4, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_seq"(ptr %0, ptr %boxed, ptr %boxed, ptr %2)
  call void @avra_array_push_owned(ptr %3, ptr %8)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_seq"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot = alloca i64, align 8
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_build"(ptr %1, ptr %2, ptr %3)
  %8 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed9 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr %4)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %boxed9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %5, i64 %ld1)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_prim"(ptr %0, ptr %boxed2, ptr %2, ptr %3)
  %13 = call ptr @avra_array_get_owned(ptr %boxed, i64 0)
  %14 = call ptr @avra_array_get_owned(ptr %boxed, i64 2)
  %15 = call ptr @avra_array_get_owned(ptr %boxed, i64 3)
  %16 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %b = icmp ne i64 %16, 0
  %17 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %b3 = icmp ne i64 %17, 0
  %18 = call i64 @avra_array_get(ptr %boxed, i64 6)
  %b4 = icmp ne i64 %18, 0
  %19 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %19, ptr %13)
  call void @avra_array_push_owned(ptr %19, ptr %12)
  call void @avra_array_push_owned(ptr %19, ptr %14)
  call void @avra_array_push_owned(ptr %19, ptr %15)
  %slot5 = zext i1 %b to i64
  call void @avra_array_push(ptr %19, i64 %slot5)
  %slot6 = zext i1 %b3 to i64
  call void @avra_array_push(ptr %19, i64 %slot6)
  %slot7 = zext i1 %b4 to i64
  call void @avra_array_push(ptr %19, i64 %slot7)
  call void @avra_array_push_owned(ptr %4, ptr %19)
  %ld8 = load i64, ptr %slot, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_build"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %boxed1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 2, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %9 = call i64 @avra_array_get(ptr %5, i64 3)
  %boxed3 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %2)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efilled_slots"(ptr %1, ptr %7, ptr %8, ptr %boxed3, ptr %2)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %11, i64 2)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr %8)
  call void @avra_array_push_owned(ptr %11, ptr %boxed3)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

arm2:                                             ; preds = %endif
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval4 = phi ptr [ %11, %arm ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efilled_slots"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Erow_for"(ptr %4, ptr %1, ptr %2)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_insist(ptr %5)
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 2)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %9
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %8, i64 %ld2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Egrammar$2ESeq$2Elabels"(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %3)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efilling"(ptr %boxed, ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %6, ptr %12)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Efilling"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot11 = alloca i64, align 8
  %slot10 = alloca ptr, align 8
  store ptr null, ptr %slot10, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  br i1 %ld4, label %then5, label %else6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_streq(ptr %boxed, ptr %3)
  %b = icmp ne i64 %6, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
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
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed8 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %8, ptr %boxed8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else6:                                            ; preds = %lexit
  br label %endif7

endif7:                                           ; preds = %else6, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else6 ]
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot10)
  store ptr null, ptr %slot10, align 8
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_grammar$24l121" to i64))
  call void @avra_array_push_owned(ptr %9, ptr %0)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %11 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot11, align 8
  br label %lhead12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif7

lhead12:                                          ; preds = %endif20, %endif7
  %ld14 = load i64, ptr %slot11, align 8
  %cmp15 = icmp slt i64 %ld14, %11
  br i1 %cmp15, label %lbody16, label %lexit13

lexit13:                                          ; preds = %lhead12
  %ld24 = load ptr, ptr %slot10, align 8
  call void @avra_rc_retain(ptr %ld24)
  %cmp25 = icmp ne ptr %ld24, null
  br i1 %cmp25, label %then26, label %else27

lbody16:                                          ; preds = %lhead12
  %ld17 = load i64, ptr %slot11, align 8
  %12 = call ptr @avra_array_get_owned(ptr %2, i64 %ld17)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %12)
  %cast = inttoptr i64 %10 to ptr
  %13 = call i1 %cast(ptr %9, ptr %12)
  br i1 %13, label %then18, label %else19

then18:                                           ; preds = %lbody16
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot10)
  store ptr %12, ptr %slot10, align 8
  store i64 %11, ptr %slot11, align 8
  br label %endif20

else19:                                           ; preds = %lbody16
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval21 = phi i64 [ 0, %then18 ], [ 0, %else19 ]
  %ld22 = load i64, ptr %slot11, align 8
  %add23 = add i64 %ld22, 1
  store i64 %add23, ptr %slot11, align 8
  call void @avra_rc_release(ptr %12)
  br label %lhead12

then26:                                           ; preds = %lexit13
  %14 = call ptr @avra_insist(ptr %ld24)
  %15 = call i64 @avra_array_get(ptr %14, i64 1)
  %boxed29 = inttoptr i64 %15 to ptr
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 1)
  call void @avra_array_push_owned(ptr %16, ptr %boxed29)
  call void @avra_cell_release(ptr %slot10)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %ld24)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else27:                                           ; preds = %lexit13
  br label %endif28

endif28:                                          ; preds = %else27, %postret30
  %regval31 = phi i64 [ 0, %postret30 ], [ 0, %else27 ]
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 2)
  call void @avra_cell_release(ptr %slot10)
  call void @avra_rc_release(ptr %ld24)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

postret30:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  br label %endif28
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Enode_grammar$24l121"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_streq(ptr %boxed, ptr %boxed2)
  %b = icmp ne i64 %5, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_prim"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %4, label %arm1 [
    i64 3, label %arm
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 0)
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot, align 8
  br label %lhead

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %lexit
  %regval = phi ptr [ %10, %lexit ], [ %1, %arm1 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval

lhead:                                            ; preds = %lbody, %arm
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 3)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %11 = call i64 @avra_array_get(ptr %7, i64 %ld2)
  %boxed = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_seq"(ptr %0, ptr %boxed, ptr %2, ptr %3)
  call void @avra_array_push_owned(ptr %6, ptr %12)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  br label %lhead
}
