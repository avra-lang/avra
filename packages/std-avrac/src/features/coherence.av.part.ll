; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"diagnostic kind is registered more than once\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"diagnostic code is registered more than once\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"builder `\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [38 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 37 }, [38 x i8] c"` is never called by any grammar rule\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c", \00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [31 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 30 }, [31 x i8] c"no feature registers builder `\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"` (searched \00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c")\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"builder `\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [29 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 28 }, [29 x i8] c"` is already registered by `\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2411"(ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2EAlt$2Eseqs"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecode_defects"(ptr %0) {
entry:
  %slot26 = alloca i64, align 8
  %slot23 = alloca i1, align 1
  %slot8 = alloca i64, align 8
  %slot5 = alloca i1, align 1
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot1)
  store ptr %2, ptr %slot1, align 8
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif44, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld54 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld54)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld54

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 %ld4)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot3)
  store ptr %4, ptr %slot3, align 8
  store i1 false, ptr %slot5, align 8
  %ld6 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld6)
  %5 = call ptr @avra_array_get_owned(ptr %ld6, i64 0)
  %ld7 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld7)
  %6 = call i64 @avra_array_len(ptr %ld7)
  store i64 0, ptr %slot8, align 8
  br label %lhead9

lhead9:                                           ; preds = %endif, %lbody
  %ld11 = load i64, ptr %slot8, align 8
  %cmp12 = icmp slt i64 %ld11, %6
  br i1 %cmp12, label %lbody13, label %lexit10

lexit10:                                          ; preds = %lhead9
  %ld16 = load i1, ptr %slot5, align 8
  br i1 %ld16, label %then17, label %else18

lbody13:                                          ; preds = %lhead9
  %ld14 = load i64, ptr %slot8, align 8
  %7 = call i64 @avra_array_get(ptr %ld7, i64 %ld14)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_streq(ptr %boxed, ptr %5)
  %b = icmp ne i64 %8, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody13
  store i1 true, ptr %slot5, align 8
  store i64 %6, ptr %slot8, align 8
  br label %endif

else:                                             ; preds = %lbody13
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld15 = load i64, ptr %slot8, align 8
  %add = add i64 %ld15, 1
  store i64 %add, ptr %slot8, align 8
  br label %lhead9

then17:                                           ; preds = %lexit10
  %9 = call ptr @avra_cell_unique(ptr %slot1)
  %ld20 = load ptr, ptr %slot3, align 8
  %10 = call i64 @avra_array_get(ptr %ld20, i64 0)
  %boxed21 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed21)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %11 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %boxed21, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif19

else18:                                           ; preds = %lexit10
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval22 = phi i64 [ 0, %then17 ], [ 0, %else18 ]
  store i1 false, ptr %slot23, align 8
  %ld24 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld24)
  %12 = call ptr @avra_array_get_owned(ptr %ld24, i64 1)
  %ld25 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld25)
  %13 = call i64 @avra_array_len(ptr %ld25)
  store i64 0, ptr %slot26, align 8
  br label %lhead27

lhead27:                                          ; preds = %endif37, %endif19
  %ld29 = load i64, ptr %slot26, align 8
  %cmp30 = icmp slt i64 %ld29, %13
  br i1 %cmp30, label %lbody31, label %lexit28

lexit28:                                          ; preds = %lhead27
  %ld41 = load i1, ptr %slot23, align 8
  br i1 %ld41, label %then42, label %else43

lbody31:                                          ; preds = %lhead27
  %ld32 = load i64, ptr %slot26, align 8
  %14 = call i64 @avra_array_get(ptr %ld25, i64 %ld32)
  %boxed33 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_streq(ptr %boxed33, ptr %12)
  %b34 = icmp ne i64 %15, 0
  br i1 %b34, label %then35, label %else36

then35:                                           ; preds = %lbody31
  store i1 true, ptr %slot23, align 8
  store i64 %13, ptr %slot26, align 8
  br label %endif37

else36:                                           ; preds = %lbody31
  br label %endif37

endif37:                                          ; preds = %else36, %then35
  %regval38 = phi i64 [ 0, %then35 ], [ 0, %else36 ]
  %ld39 = load i64, ptr %slot26, align 8
  %add40 = add i64 %ld39, 1
  store i64 %add40, ptr %slot26, align 8
  br label %lhead27

then42:                                           ; preds = %lexit28
  %16 = call ptr @avra_cell_unique(ptr %slot1)
  %ld45 = load ptr, ptr %slot3, align 8
  %17 = call i64 @avra_array_get(ptr %ld45, i64 1)
  %boxed46 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed46)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %18 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %boxed46, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif44

else43:                                           ; preds = %lexit28
  br label %endif44

endif44:                                          ; preds = %else43, %then42
  %regval47 = phi i64 [ 0, %then42 ], [ 0, %else43 ]
  %19 = call ptr @avra_cell_unique(ptr %slot)
  %ld48 = load ptr, ptr %slot3, align 8
  %20 = call i64 @avra_array_get(ptr %ld48, i64 0)
  %boxed49 = inttoptr i64 %20 to ptr
  call void @avra_array_push_owned(ptr %19, ptr %boxed49)
  %21 = call ptr @avra_cell_unique(ptr %slot)
  %ld50 = load ptr, ptr %slot3, align 8
  %22 = call i64 @avra_array_get(ptr %ld50, i64 1)
  %boxed51 = inttoptr i64 %22 to ptr
  call void @avra_array_push_owned(ptr %21, ptr %boxed51)
  %ld52 = load i64, ptr %slot2, align 8
  %add53 = add i64 %ld52, 1
  store i64 %add53, ptr %slot2, align 8
  call void @avra_rc_release(ptr %ld25)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %ld24)
  call void @avra_rc_release(ptr %ld7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %ld6)
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuilder_defects"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eduplicate_defects"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eunregistered_defects"(ptr %0, ptr %1)
  %4 = call ptr @avra_array_concat(ptr %2, ptr %3)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ereferenced_names"(ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edead_defects"(ptr %0, ptr %5)
  %7 = call ptr @avra_array_concat(ptr %4, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Edead_defects"(ptr %0, ptr %1) {
entry:
  %slot12 = alloca { i1, i1 }, align 8
  %slot5 = alloca i64, align 8
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lexit7, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld25 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld25)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld25

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot2)
  store ptr %4, ptr %slot2, align 8
  %5 = call ptr @avra_array_sized(i64 0)
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld4)
  %6 = call ptr @avra_array_get_owned(ptr %ld4, i64 3)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot5, align 8
  br label %lhead6

lhead6:                                           ; preds = %endif17, %lbody
  %ld8 = load i64, ptr %slot5, align 8
  %cmp9 = icmp slt i64 %ld8, %7
  br i1 %cmp9, label %lbody10, label %lexit7

lexit7:                                           ; preds = %lhead6
  %ld22 = load ptr, ptr %slot, align 8
  %8 = call ptr @avra_array_concat(ptr %ld22, ptr %5)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot)
  store ptr %8, ptr %slot, align 8
  %ld23 = load i64, ptr %slot1, align 8
  %add24 = add i64 %ld23, 1
  store i64 %add24, ptr %slot1, align 8
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %lhead

lbody10:                                          ; preds = %lhead6
  %ld11 = load i64, ptr %slot5, align 8
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 %ld11)
  %10 = call ptr @avra_array_get_owned(ptr %9, i64 0)
  store { i1, i1 } zeroinitializer, ptr %slot12, align 8
  %11 = call i64 @avra_map_has(ptr %1, ptr %10)
  %b = icmp ne i64 %11, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody10
  %12 = call i64 @avra_map_get(ptr %1, ptr %10)
  %b13 = icmp ne i64 %12, 0
  %pack = insertvalue { i1, i1 } { i1 true, i1 undef }, i1 %b13, 1
  store { i1, i1 } %pack, ptr %slot12, align 8
  br label %endif

else:                                             ; preds = %lbody10
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld14 = load { i1, i1 }, ptr %slot12, align 8
  %x = extractvalue { i1, i1 } %ld14, 0
  %not = xor i1 %x, true
  br i1 %not, label %then15, label %else16

then15:                                           ; preds = %endif
  %ld18 = load ptr, ptr %slot2, align 8
  %13 = call i64 @avra_array_get(ptr %ld18, i64 0)
  %boxed = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed19 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %15, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %15, ptr %boxed19)
  call void @avra_array_push_owned(ptr %15, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %16 = call ptr @avra_str_join(ptr %15, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %16)
  %17 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %boxed, ptr %16)
  call void @avra_array_push_owned(ptr %5, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif17

else16:                                           ; preds = %endif
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval20 = phi i64 [ 0, %then15 ], [ 0, %else16 ]
  %ld21 = load i64, ptr %slot5, align 8
  %add = add i64 %ld21, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %lhead6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ereferenced_names"(ptr %0) {
entry:
  %slot6 = alloca ptr, align 8
  store ptr null, ptr %slot6, align 8
  %slot5 = alloca i64, align 8
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_map_new()
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lexit8, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld17

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot2)
  store ptr %4, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  %5 = call i64 @avra_array_get(ptr %ld4, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecall_names_in_alt"(ptr %boxed)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot5, align 8
  br label %lhead7

lhead7:                                           ; preds = %lbody11, %lbody
  %ld9 = load i64, ptr %slot5, align 8
  %cmp10 = icmp slt i64 %ld9, %7
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %ld15 = load i64, ptr %slot1, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  br label %lhead

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot5, align 8
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 %ld12)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot6)
  store ptr %8, ptr %slot6, align 8
  %9 = call ptr @avra_cell_unique(ptr %slot)
  %ld13 = load ptr, ptr %slot6, align 8
  call void @avra_map_set(ptr %9, ptr %ld13, i64 1)
  %ld14 = load i64, ptr %slot5, align 8
  %add = add i64 %ld14, 1
  store i64 %add, ptr %slot5, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecall_names_in_alt"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Egrammar$2EAlt$2Eseqs"(ptr %0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2411"(ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuild_call_name"(ptr %boxed2)
  call void @avra_array_push_owned(ptr %1, ptr %7)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuild_call_name"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %1 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %0)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 1, label %arm
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %1)
  br label %endif

arm:                                              ; preds = %endif
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %5, ptr %boxed)
  br label %endswitch

arm1:                                             ; preds = %endif
  %6 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval2 = phi ptr [ %5, %arm ], [ %6, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eunregistered_defects"(ptr %0, ptr %1) {
entry:
  %slot14 = alloca i64, align 8
  %slot5 = alloca ptr, align 8
  store ptr null, ptr %slot5, align 8
  %slot4 = alloca i64, align 8
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecoherence$24l68" to i64))
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %7 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot3)
  store ptr %7, ptr %slot3, align 8
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot4, align 8
  br label %lhead6

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %4 to ptr
  %11 = call ptr %cast(ptr %3, ptr %boxed)
  call void @avra_array_push_owned(ptr %2, ptr %11)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %11)
  br label %lhead

lhead6:                                           ; preds = %lexit16, %lexit
  %ld8 = load i64, ptr %slot4, align 8
  %cmp9 = icmp slt i64 %ld8, %9
  br i1 %cmp9, label %lbody10, label %lexit7

lexit7:                                           ; preds = %lhead6
  %ld29 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld29)
  call void @avra_cell_release(ptr %slot5)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld29

lbody10:                                          ; preds = %lhead6
  %ld11 = load i64, ptr %slot4, align 8
  %12 = call ptr @avra_array_get_owned(ptr %8, i64 %ld11)
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot5)
  store ptr %12, ptr %slot5, align 8
  %13 = call ptr @avra_array_sized(i64 0)
  %ld12 = load ptr, ptr %slot5, align 8
  %14 = call i64 @avra_array_get(ptr %ld12, i64 1)
  %boxed13 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed13)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecall_names_in_alt"(ptr %boxed13)
  %16 = call i64 @avra_array_len(ptr %15)
  store i64 0, ptr %slot14, align 8
  br label %lhead15

lhead15:                                          ; preds = %endif, %lbody10
  %ld17 = load i64, ptr %slot14, align 8
  %cmp18 = icmp slt i64 %ld17, %16
  br i1 %cmp18, label %lbody19, label %lexit16

lexit16:                                          ; preds = %lhead15
  %ld26 = load ptr, ptr %slot3, align 8
  %17 = call ptr @avra_array_concat(ptr %ld26, ptr %13)
  call void @avra_rc_retain(ptr %17)
  call void @avra_cell_release(ptr %slot3)
  store ptr %17, ptr %slot3, align 8
  %ld27 = load i64, ptr %slot4, align 8
  %add28 = add i64 %ld27, 1
  store i64 %add28, ptr %slot4, align 8
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  br label %lhead6

lbody19:                                          ; preds = %lhead15
  %ld20 = load i64, ptr %slot14, align 8
  %18 = call ptr @avra_array_get_owned(ptr %15, i64 %ld20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eregistrar_of"(ptr %0, ptr %18)
  %cmp21 = icmp ne ptr %19, null
  %not = xor i1 %cmp21, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody19
  %ld22 = load ptr, ptr %slot5, align 8
  %20 = call i64 @avra_array_get(ptr %ld22, i64 0)
  %boxed23 = inttoptr i64 %20 to ptr
  %21 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %21, ptr %18)
  call void @avra_array_push_owned(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %21, ptr %6)
  call void @avra_array_push_owned(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %22 = call ptr @avra_str_join(ptr %21, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr %boxed23)
  call void @avra_rc_retain(ptr %22)
  %23 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %boxed23, ptr %22)
  call void @avra_array_push_owned(ptr %13, ptr %23)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif

else:                                             ; preds = %lbody19
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld24 = load i64, ptr %slot14, align 8
  %add25 = add i64 %ld24, 1
  store i64 %add25, ptr %slot14, align 8
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  br label %lhead15
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecoherence$24l68"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eregistrar_of"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecoherence$24l20" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %cast = inttoptr i64 %3 to ptr
  %6 = call i1 %cast(ptr %2, ptr %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead

then6:                                            ; preds = %lexit
  %7 = call ptr @avra_array_get_owned(ptr %ld4, i64 0)
  br label %endif8

else7:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr null)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %7, %then6 ], [ null, %else7 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval9
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ecoherence$24l20"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecoherence$24l18" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 3)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed3)
  %cast = inttoptr i64 %4 to ptr
  %8 = call i1 %cast(ptr %3, ptr %boxed3)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ecoherence$24l18"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eduplicate_defects"(ptr %0) {
entry:
  %slot16 = alloca ptr, align 8
  store ptr null, ptr %slot16, align 8
  %slot7 = alloca ptr, align 8
  store ptr null, ptr %slot7, align 8
  %slot6 = alloca i64, align 8
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_map_new()
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot1)
  store ptr %2, ptr %slot1, align 8
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %lexit9, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld33 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld33)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld33

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 %ld4)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot3)
  store ptr %4, ptr %slot3, align 8
  %ld5 = load ptr, ptr %slot3, align 8
  call void @avra_rc_retain(ptr %ld5)
  %5 = call ptr @avra_array_get_owned(ptr %ld5, i64 3)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot6, align 8
  br label %lhead8

lhead8:                                           ; preds = %endif21, %lbody
  %ld10 = load i64, ptr %slot6, align 8
  %cmp11 = icmp slt i64 %ld10, %6
  br i1 %cmp11, label %lbody12, label %lexit9

lexit9:                                           ; preds = %lhead8
  %ld31 = load i64, ptr %slot2, align 8
  %add32 = add i64 %ld31, 1
  store i64 %add32, ptr %slot2, align 8
  call void @avra_cell_release(ptr %slot7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %ld5)
  call void @avra_rc_release(ptr %4)
  br label %lhead

lbody12:                                          ; preds = %lhead8
  %ld13 = load i64, ptr %slot6, align 8
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 %ld13)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot7)
  store ptr %7, ptr %slot7, align 8
  %ld14 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld14)
  %ld15 = load ptr, ptr %slot7, align 8
  call void @avra_rc_retain(ptr %ld15)
  %8 = call ptr @avra_array_get_owned(ptr %ld15, i64 0)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot16)
  store ptr null, ptr %slot16, align 8
  %9 = call i64 @avra_map_has(ptr %ld14, ptr %8)
  %b = icmp ne i64 %9, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody12
  %10 = call ptr @avra_map_get_owned(ptr %ld14, ptr %8)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot16)
  store ptr %10, ptr %slot16, align 8
  call void @avra_rc_release(ptr %10)
  br label %endif

else:                                             ; preds = %lbody12
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld17 = load ptr, ptr %slot16, align 8
  call void @avra_rc_retain(ptr %ld17)
  %cmp18 = icmp ne ptr %ld17, null
  %not = xor i1 %cmp18, true
  br i1 %not, label %then19, label %else20

then19:                                           ; preds = %endif
  %11 = call ptr @avra_cell_unique(ptr %slot)
  %ld22 = load ptr, ptr %slot7, align 8
  %12 = call i64 @avra_array_get(ptr %ld22, i64 0)
  %boxed = inttoptr i64 %12 to ptr
  %ld23 = load ptr, ptr %slot3, align 8
  %13 = call i64 @avra_array_get(ptr %ld23, i64 0)
  %boxed24 = inttoptr i64 %13 to ptr
  call void @avra_map_set_owned(ptr %11, ptr %boxed, ptr %boxed24)
  br label %endif21

else20:                                           ; preds = %endif
  %14 = call ptr @avra_cell_unique(ptr %slot1)
  %ld25 = load ptr, ptr %slot3, align 8
  %15 = call i64 @avra_array_get(ptr %ld25, i64 0)
  %boxed26 = inttoptr i64 %15 to ptr
  %ld27 = load ptr, ptr %slot7, align 8
  %16 = call i64 @avra_array_get(ptr %ld27, i64 0)
  %boxed28 = inttoptr i64 %16 to ptr
  %17 = call ptr @avra_insist(ptr %ld17)
  %18 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %boxed28)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %19 = call ptr @avra_str_join(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr %boxed26)
  call void @avra_rc_retain(ptr %19)
  %20 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Edefect"(ptr %boxed26, ptr %19)
  call void @avra_array_push_owned(ptr %14, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval29 = phi i64 [ 0, %then19 ], [ 0, %else20 ]
  %ld30 = load i64, ptr %slot6, align 8
  %add = add i64 %ld30, 1
  store i64 %add, ptr %slot6, align 8
  call void @avra_cell_release(ptr %slot16)
  call void @avra_rc_release(ptr %ld17)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %ld15)
  call void @avra_rc_release(ptr %ld14)
  call void @avra_rc_release(ptr %7)
  br label %lhead8
}
