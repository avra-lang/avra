; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"feature\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [33 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 32 }, [33 x i8] c"the feature whose rule to attack\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"attack\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [52 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 51 }, [52 x i8] c"Generate a feature's mechanical adversarial classes\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"feature\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [26 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 25 }, [26 x i8] c"avra attack: no feature `\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [40 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 39 }, [40 x i8] c"` \E2\80\94 `avra grammar` lists the language\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra attack: \00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [34 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 33 }, [34 x i8] c" case(s) dropped over the cap of \00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [28 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 27 }, [28 x i8] c" \E2\80\94 the fixture records it\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"survivor\09\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\09\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr)

declare i64 @"av_$40std$2Eprelude$2Eprintln"(ptr)

define ptr @"av_commands$2Eattack_command"() {
entry:
  %0 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push(ptr %0, i64 1)
  call void @avra_array_push(ptr %0, i64 0)
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_commands$2Earg_command"(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr getelementptr inbounds (i8, ptr @.str.3, i64 16), ptr %1)
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_commands$2EAttackCmd$2Erun" to i64))
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %5
}

define i64 @"av_commands$2EAttackCmd$2Erun"(ptr %0, ptr %1) {
entry:
  %slot16 = alloca ptr, align 8
  store ptr null, ptr %slot16, align 8
  %slot15 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %2 = call ptr @"av_$40std$2Ecli$2ECliResult$2Earg"(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eavra"()
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_commands$2Eattack$24l11" to i64))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %3, i64 0)
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
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %10, ptr %2)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %11 = call ptr @avra_str_join(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %11)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 2

else7:                                            ; preds = %lexit
  br label %endif8

endif8:                                           ; preds = %else7, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else7 ]
  %13 = call ptr @avra_insist(ptr %ld4)
  %14 = call i64 @avra_array_get(ptr %13, i64 2)
  %boxed = inttoptr i64 %14 to ptr
  %15 = call i64 @"av_commands$2Eattack_cap"()
  call void @avra_rc_retain(ptr %boxed)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eattacks"(ptr %boxed, i64 %15)
  %17 = call i64 @avra_array_get(ptr %16, i64 1)
  %cmp10 = icmp sgt i64 %17, 0
  br i1 %cmp10, label %then11, label %else12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif8

then11:                                           ; preds = %endif8
  %18 = call i64 @avra_array_get(ptr %16, i64 1)
  %19 = call ptr @avra_int_text(i64 %18)
  %20 = call i64 @avra_array_get(ptr %16, i64 2)
  %21 = call ptr @avra_int_text(i64 %20)
  %22 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr %19)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %23 = call ptr @avra_str_join(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %23)
  %24 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %23)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  br label %endif13

else12:                                           ; preds = %endif8
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  call void @avra_rc_retain(ptr %16)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Esurvivors_of"(ptr %16)
  %26 = call i64 @avra_array_len(ptr %25)
  store i64 0, ptr %slot15, align 8
  br label %lhead17

lhead17:                                          ; preds = %lbody21, %endif13
  %ld19 = load i64, ptr %slot15, align 8
  %cmp20 = icmp slt i64 %ld19, %26
  br i1 %cmp20, label %lbody21, label %lexit18

lexit18:                                          ; preds = %lhead17
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %16)
  %27 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eattack_test_source"(ptr %2, ptr %16)
  call void @avra_rc_retain(ptr %27)
  %28 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr %27)
  call void @avra_cell_release(ptr %slot16)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody21:                                          ; preds = %lhead17
  %ld22 = load i64, ptr %slot15, align 8
  %29 = call ptr @avra_array_get_owned(ptr %25, i64 %ld22)
  call void @avra_rc_retain(ptr %29)
  call void @avra_cell_release(ptr %slot16)
  store ptr %29, ptr %slot16, align 8
  %ld23 = load ptr, ptr %slot16, align 8
  %30 = call i64 @avra_array_get(ptr %ld23, i64 1)
  %boxed24 = inttoptr i64 %30 to ptr
  call void @avra_rc_retain(ptr %boxed24)
  %31 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ebaseline_word"(ptr %boxed24)
  %32 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_array_push_owned(ptr %32, ptr %2)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %32, ptr %31)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %33 = call ptr @avra_str_join(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %33)
  %34 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %33)
  %ld25 = load i64, ptr %slot15, align 8
  %add26 = add i64 %ld25, 1
  store i64 %add26, ptr %slot15, align 8
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %29)
  br label %lhead17
}

define i1 @"av_commands$2Eattack$24l11"(ptr %0, ptr %1) {
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

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eattack_test_source"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Ebaseline_word"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Esurvivors_of"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eavra"()

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eattacks"(ptr, i64)

define i64 @"av_commands$2Eattack_cap"() {
entry:
  ret i64 500
}

declare ptr @"av_$40std$2Ecli$2ECliResult$2Earg"(ptr, ptr)

declare ptr @"av_commands$2Earg_command"(ptr, ptr, ptr)
