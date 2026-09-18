; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"diagnostics\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"Print the error index, made from every registered code\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"diagnostics: \00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [22 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 21 }, [22 x i8] c" code(s) registered, \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [23 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 22 }, [23 x i8] c" witnessed and fired, \00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c" with no witness yet\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"diagnostics: `\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [61 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 60 }, [61 x i8] c"` carries more than one witness \E2\80\94 only the first ever runs\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [31 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 30 }, [31 x i8] c"diagnostics: a witness names `\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [50 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 49 }, [50 x i8] c"`, which no feature registers \E2\80\94 nothing runs it\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"diagnostics: \00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [52 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 51 }, [52 x i8] c"'s witness no longer produces it \E2\80\94 a witness that\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [74 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 73 }, [74 x i8] c"diagnostics:   triggers some other code makes a green golden of the wrong\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [64 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 63 }, [64 x i8] c"diagnostics:   words. Fix the witness, or the voice that moved.\00" }, align 16

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

define ptr @"av_commands$2Ediagnostics_command"() {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %0 = call ptr @"av_commands$2Ebare_command"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_commands$2EDiagnosticsCmd$2Erun" to i64))
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %3, ptr %0)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %3
}

define i64 @"av_commands$2EDiagnosticsCmd$2Erun"(ptr %0, ptr %1) {
entry:
  %slot28 = alloca i64, align 8
  %slot18 = alloca ptr, align 8
  store ptr null, ptr %slot18, align 8
  %slot17 = alloca i64, align 8
  %slot7 = alloca ptr, align 8
  store ptr null, ptr %slot7, align 8
  %slot6 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eshown_codes"()
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ediagnostics_index"(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr %3)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Esilent_witnesses"(ptr %2)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Estray_witnesses"()
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot6, align 8
  br label %lhead8

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %9 = call ptr @avra_array_get_owned(ptr %5, i64 %ld2)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot1)
  store ptr %9, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  %10 = call i64 @avra_array_get(ptr %ld3, i64 0)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed4 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed4)
  %12 = call i64 @"av_commands$2Edrifted"(ptr %boxed4)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead

lhead8:                                           ; preds = %lbody12, %lexit
  %ld10 = load i64, ptr %slot6, align 8
  %cmp11 = icmp slt i64 %ld10, %8
  br i1 %cmp11, label %lbody12, label %lexit9

lexit9:                                           ; preds = %lhead8
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eshadowed_witnesses"()
  %14 = call i64 @avra_array_len(ptr %13)
  store i64 0, ptr %slot17, align 8
  br label %lhead19

lbody12:                                          ; preds = %lhead8
  %ld13 = load i64, ptr %slot6, align 8
  %15 = call ptr @avra_array_get_owned(ptr %7, i64 %ld13)
  call void @avra_rc_retain(ptr %15)
  call void @avra_cell_release(ptr %slot7)
  store ptr %15, ptr %slot7, align 8
  %ld14 = load ptr, ptr %slot7, align 8
  call void @avra_rc_retain(ptr %ld14)
  %16 = call i64 @"av_commands$2Estray"(ptr %ld14)
  %ld15 = load i64, ptr %slot6, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot6, align 8
  call void @avra_rc_release(ptr %15)
  br label %lhead8

lhead19:                                          ; preds = %lbody23, %lexit9
  %ld21 = load i64, ptr %slot17, align 8
  %cmp22 = icmp slt i64 %ld21, %14
  br i1 %cmp22, label %lbody23, label %lexit20

lexit20:                                          ; preds = %lhead19
  %17 = call i64 @avra_array_len(ptr %2)
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot28, align 8
  br label %lhead29

lbody23:                                          ; preds = %lhead19
  %ld24 = load i64, ptr %slot17, align 8
  %20 = call ptr @avra_array_get_owned(ptr %13, i64 %ld24)
  call void @avra_rc_retain(ptr %20)
  call void @avra_cell_release(ptr %slot18)
  store ptr %20, ptr %slot18, align 8
  %ld25 = load ptr, ptr %slot18, align 8
  call void @avra_rc_retain(ptr %ld25)
  %21 = call i64 @"av_commands$2Eshadowed"(ptr %ld25)
  %ld26 = load i64, ptr %slot17, align 8
  %add27 = add i64 %ld26, 1
  store i64 %add27, ptr %slot17, align 8
  call void @avra_rc_release(ptr %20)
  br label %lhead19

lhead29:                                          ; preds = %endif, %lexit20
  %ld31 = load i64, ptr %slot28, align 8
  %cmp32 = icmp slt i64 %ld31, %19
  br i1 %cmp32, label %lbody33, label %lexit30

lexit30:                                          ; preds = %lhead29
  %22 = call i64 @avra_array_len(ptr %18)
  call void @avra_rc_retain(ptr %2)
  %23 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eunwitnessed"(ptr %2)
  %24 = call i64 @avra_array_len(ptr %23)
  %25 = call i64 @"av_commands$2Ecounted"(i64 %17, i64 %22, i64 %24)
  %26 = call i64 @avra_array_len(ptr %5)
  %cmp37 = icmp eq i64 %26, 0
  br i1 %cmp37, label %then38, label %else39

lbody33:                                          ; preds = %lhead29
  %ld34 = load i64, ptr %slot28, align 8
  %27 = call ptr @avra_array_get_owned(ptr %2, i64 %ld34)
  %28 = call i64 @avra_array_get(ptr %27, i64 3)
  %b = icmp ne i64 %28, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody33
  call void @avra_array_push_owned(ptr %18, ptr %27)
  br label %endif

else:                                             ; preds = %lbody33
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld35 = load i64, ptr %slot28, align 8
  %add36 = add i64 %ld35, 1
  store i64 %add36, ptr %slot28, align 8
  call void @avra_rc_release(ptr %27)
  br label %lhead29

then38:                                           ; preds = %lexit30
  %29 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Estray_witnesses"()
  %30 = call i64 @avra_array_len(ptr %29)
  %cmp41 = icmp eq i64 %30, 0
  call void @avra_rc_release(ptr %29)
  br label %endif40

else39:                                           ; preds = %lexit30
  br label %endif40

endif40:                                          ; preds = %else39, %then38
  %regval42 = phi i1 [ %cmp41, %then38 ], [ false, %else39 ]
  br i1 %regval42, label %then43, label %else44

then43:                                           ; preds = %endif40
  %31 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eshadowed_witnesses"()
  %32 = call i64 @avra_array_len(ptr %31)
  %cmp46 = icmp eq i64 %32, 0
  call void @avra_rc_release(ptr %31)
  br label %endif45

else44:                                           ; preds = %endif40
  br label %endif45

endif45:                                          ; preds = %else44, %then43
  %regval47 = phi i1 [ %cmp46, %then43 ], [ false, %else44 ]
  br i1 %regval47, label %then48, label %else49

then48:                                           ; preds = %endif45
  br label %endif50

else49:                                           ; preds = %endif45
  br label %endif50

endif50:                                          ; preds = %else49, %then48
  %regval51 = phi i64 [ 0, %then48 ], [ 1, %else49 ]
  call void @avra_cell_release(ptr %slot18)
  call void @avra_cell_release(ptr %slot7)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval51
}

define i64 @"av_commands$2Ecounted"(i64 %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_int_text(i64 %0)
  %4 = call ptr @avra_int_text(i64 %1)
  %5 = call ptr @avra_int_text(i64 %2)
  %6 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %3)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %7 = call ptr @avra_str_join(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  ret i64 %8
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eunwitnessed"(ptr)

define i64 @"av_commands$2Eshadowed"(ptr %0) {
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
  ret i64 %3
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eshadowed_witnesses"()

define i64 @"av_commands$2Estray"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %2 = call ptr @avra_str_join(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Estray_witnesses"()

define i64 @"av_commands$2Edrifted"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %2 = call ptr @avra_str_join(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  %4 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  %5 = call i64 @"av_$40std$2Eprelude$2Eeprintln"(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Esilent_witnesses"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Ediagnostics_index"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eshown_codes"()

declare ptr @"av_commands$2Ebare_command"(ptr, ptr)
