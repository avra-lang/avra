; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"a dyn lift from an unnamed shape survived typing\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_array_new\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [43 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 42 }, [43 x i8] c"an unanswered trait method survived typing\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_once_get\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_once_set\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"a deferred box without a fn type survived typing\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"[]\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_int_text\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"avra_float_text\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_bool_text\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"avra_puts\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"avra_bools_text\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_strs_text\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_ints_text\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"lower.no_projection\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [28 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 27 }, [28 x i8] c"the program's answer is a `\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [36 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 35 }, [36 x i8] c"`, which has no text projection yet\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"this is the answer\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"project a field instead \E2\80\94 `p.x` prints\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eseats_exit"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 13)
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ereg_at"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed2, i64 %1)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %6, ptr %9)
  %11 = call ptr @avra_array_get_owned(ptr %10, i64 0)
  %12 = call i64 @avra_array_get(ptr %10, i64 5)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %12 to ptr
  %13 = call i64 %cast(ptr %11, ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Enarrowed"(ptr %0, i64 %1, i64 %13)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ewidened"(ptr %0, i64 %1, i64 %14)
  %16 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed3 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eset_reg"(ptr %boxed3, i64 %1, i64 %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %15

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eset_reg"(ptr, i64, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ewidened"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ewidened_at"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Econcrete"(ptr %0, ptr %5)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 4)
  %boxed2 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  %boxed3 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %6)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed3, ptr %6)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp4 = icmp eq i64 %11, 13
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokayed"(ptr %0, ptr %6, i64 %2)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  %13 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp10 = icmp eq i64 %13, 10
  br i1 %cmp10, label %then11, label %else12

postret8:                                         ; No predecessors!
  br label %endif7

then11:                                           ; preds = %endif7
  br label %endif13

else12:                                           ; preds = %endif7
  %14 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp14 = icmp eq i64 %14, 12
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i1 [ true, %then11 ], [ %cmp14, %else12 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif13
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else17:                                           ; preds = %endif13
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  %15 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp21 = icmp eq i64 %15, 9
  br i1 %cmp21, label %then22, label %else23

postret19:                                        ; No predecessors!
  br label %endif18

then22:                                           ; preds = %endif18
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eboxed_into"(ptr %0, ptr %6, i64 %2)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

else23:                                           ; preds = %endif18
  br label %endif24

endif24:                                          ; preds = %else23, %postret25
  %regval26 = phi i64 [ 0, %postret25 ], [ 0, %else23 ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eshape_at"(ptr %0, i64 %1)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp27 = icmp eq i64 %18, 17
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %0, ptr %6, i1 %cmp27, i64 %2)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %19

postret25:                                        ; No predecessors!
  br label %endif24
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr, ptr, i1, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eshape_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eboxed_into"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot26 = alloca ptr, align 8
  store ptr null, ptr %slot26, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed2, ptr %1)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm3 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm
  %regval = phi ptr [ %8, %arm ], [ null, %arm3 ]
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %10 = call i64 @avra_array_get(ptr %9, i64 4)
  %boxed4 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %boxed5 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed6 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed6, i64 1)
  %boxed7 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed7, i64 %2)
  %boxed8 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %boxed8)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed5, ptr %boxed8)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %cmp = icmp eq i64 %16, 9
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %endswitch
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else:                                             ; preds = %endswitch
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eboxed_decl"(ptr %0, i64 %2)
  %cmp10 = icmp ne ptr %regval, null
  %not = xor i1 %cmp10, true
  br i1 %not, label %then11, label %else12

postret:                                          ; No predecessors!
  br label %endif

then11:                                           ; preds = %endif
  br label %endif13

else12:                                           ; preds = %endif
  %cmp14 = icmp ne ptr %17, null
  %not15 = xor i1 %cmp14, true
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval16 = phi i1 [ true, %then11 ], [ %not15, %else12 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif13
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else18:                                           ; preds = %endif13
  br label %endif19

endif19:                                          ; preds = %else18, %postret20
  %regval21 = phi i64 [ 0, %postret20 ], [ 0, %else18 ]
  %19 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed22 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %boxed22)
  call void @avra_rc_retain(ptr %1)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %boxed22, ptr %1)
  %21 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed23 = inttoptr i64 %21 to ptr
  %22 = call ptr @avra_array_sized(i64 0)
  %23 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %23, i64 7)
  call void @avra_array_push(ptr %23, i64 %20)
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_rc_retain(ptr %boxed23)
  call void @avra_rc_retain(ptr %23)
  %24 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed23, ptr %23)
  call void @avra_rc_retain(ptr %0)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %20, i64 %2)
  %26 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed24 = inttoptr i64 %26 to ptr
  %27 = call i64 @avra_array_get(ptr %boxed24, i64 4)
  %boxed25 = inttoptr i64 %27 to ptr
  %28 = call ptr @avra_insist(ptr %regval)
  call void @avra_rc_retain(ptr %boxed25)
  call void @avra_rc_retain(ptr %28)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_method_names"(ptr %boxed25, ptr %28)
  %30 = call i64 @avra_array_len(ptr %29)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret20:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif19

lhead:                                            ; preds = %endif36, %endif19
  %ld = load i64, ptr %slot, align 8
  %cmp27 = icmp slt i64 %ld, %30
  br i1 %cmp27, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot26)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %20

lbody:                                            ; preds = %lhead
  %ld28 = load i64, ptr %slot, align 8
  %31 = call ptr @avra_array_get_owned(ptr %29, i64 %ld28)
  call void @avra_rc_retain(ptr %31)
  call void @avra_cell_release(ptr %slot26)
  store ptr %31, ptr %slot26, align 8
  %32 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed29 = inttoptr i64 %32 to ptr
  %33 = call i64 @avra_array_get(ptr %boxed29, i64 4)
  %boxed30 = inttoptr i64 %33 to ptr
  %34 = call ptr @avra_insist(ptr %17)
  %ld31 = load ptr, ptr %slot26, align 8
  call void @avra_rc_retain(ptr %boxed30)
  call void @avra_rc_retain(ptr %34)
  call void @avra_rc_retain(ptr %ld31)
  %35 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %boxed30, ptr %34, ptr %ld31)
  %cmp32 = icmp ne ptr %35, null
  %not33 = xor i1 %cmp32, true
  br i1 %not33, label %then34, label %else35

then34:                                           ; preds = %lbody
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %36 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_cell_release(ptr %slot26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else35:                                           ; preds = %lbody
  br label %endif36

endif36:                                          ; preds = %else35, %postret37
  %regval38 = phi i64 [ 0, %postret37 ], [ 0, %else35 ]
  %37 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %38 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed39 = inttoptr i64 %38 to ptr
  %39 = call i64 @avra_array_get(ptr %boxed39, i64 4)
  %boxed40 = inttoptr i64 %39 to ptr
  %40 = call i64 @avra_array_get(ptr %boxed40, i64 0)
  %boxed41 = inttoptr i64 %40 to ptr
  %41 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %41, i64 0)
  call void @avra_rc_retain(ptr %boxed41)
  call void @avra_rc_retain(ptr %41)
  %42 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed41, ptr %41)
  call void @avra_rc_retain(ptr %37)
  call void @avra_rc_retain(ptr %42)
  %43 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %37, ptr %42)
  %44 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %45 = call ptr @avra_insist(ptr %35)
  %46 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %47 = call i64 @avra_array_get(ptr %46, i64 1)
  %boxed42 = inttoptr i64 %47 to ptr
  %48 = call i64 @avra_array_get(ptr %boxed42, i64 %2)
  %boxed43 = inttoptr i64 %48 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %45)
  call void @avra_rc_retain(ptr null)
  call void @avra_rc_retain(ptr %boxed43)
  %49 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Emethod_symbol"(ptr %0, ptr %45, ptr null, ptr %boxed43)
  %50 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %50, i64 10)
  call void @avra_array_push(ptr %50, i64 %43)
  call void @avra_array_push_owned(ptr %50, ptr %49)
  call void @avra_rc_retain(ptr %44)
  call void @avra_rc_retain(ptr %50)
  %51 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %44, ptr %50)
  call void @avra_rc_retain(ptr %0)
  %52 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %20, i64 %43)
  %ld44 = load i64, ptr %slot, align 8
  %add = add i64 %ld44, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %49)
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %42)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %31)
  br label %lhead

postret37:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif36
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Emethod_symbol"(ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Econcrete"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_method_names"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eboxed_decl"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed3, i64 %1)
  %boxed4 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %boxed4)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %boxed4)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  switch i64 %9, label %arm6 [
    i64 6, label %arm
    i64 7, label %arm5
  ]

arm:                                              ; preds = %entry
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  br label %endswitch

arm5:                                             ; preds = %entry
  %11 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  br label %endswitch

arm6:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm6, %arm5, %arm
  %regval = phi ptr [ %10, %arm ], [ %11, %arm5 ], [ null, %arm6 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokayed"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ewidened_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Enarrowed"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Enarrowed_at"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Econcrete"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %0, i64 %2, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Enarrowed_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Ereg_at"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eseats_enter"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 12)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eonce_body"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %4)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 2)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_array_push_owned(ptr %6, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 13)
  call void @avra_array_push_owned(ptr %11, ptr %3)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 7)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed2, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %13)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 %5)
  %16 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %16, i64 7)
  call void @avra_array_push(ptr %16, i64 %14)
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr %0, i64 %14, ptr %13)
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %19, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Elower_walk$24l253" to i64))
  call void @avra_array_push(ptr %19, i64 %14)
  call void @avra_array_push_owned(ptr %19, ptr %13)
  %20 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %20, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Elower_walk$24l267" to i64))
  call void @avra_array_push(ptr %20, i64 %2)
  call void @avra_array_push(ptr %20, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %19)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %18, ptr %3, ptr %19, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %21
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Elower_walk$24l267"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %2)
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_array_push(ptr %5, i64 %3)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 6)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %1, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Elower_walk$24l253"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %1, i64 %2, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr, i64, ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epresence_of"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_exit"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eclose_frame"(ptr %0, ptr %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 13)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eclose_frame"(ptr %0, ptr %1) {
entry:
  %slot20 = alloca i64, align 8
  %slot10 = alloca ptr, align 8
  store ptr null, ptr %slot10, align 8
  %slot9 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 13)
  %cmp = icmp eq i64 %2, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %1, %then ], [ null, %else ]
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 12)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif6, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %5
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$24280"(ptr %3)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot9, align 8
  br label %lhead11

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %8 = call ptr @avra_array_get_owned(ptr %4, i64 %ld2)
  %9 = call i64 @avra_array_get(ptr %8, i64 1)
  %10 = call i64 @avra_array_get(ptr %0, i64 13)
  %cmp3 = icmp eq i64 %9, %10
  br i1 %cmp3, label %then4, label %else5

then4:                                            ; preds = %lbody
  call void @avra_array_push_owned(ptr %3, ptr %8)
  br label %endif6

else5:                                            ; preds = %lbody
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval7 = phi i64 [ 0, %then4 ], [ 0, %else5 ]
  %ld8 = load i64, ptr %slot, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead

lhead11:                                          ; preds = %lbody15, %lexit
  %ld13 = load i64, ptr %slot9, align 8
  %cmp14 = icmp slt i64 %ld13, %7
  br i1 %cmp14, label %lbody15, label %lexit12

lexit12:                                          ; preds = %lhead11
  %11 = call ptr @avra_array_sized(i64 0)
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 12)
  %13 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot20, align 8
  br label %lhead21

lbody15:                                          ; preds = %lhead11
  %ld16 = load i64, ptr %slot9, align 8
  %14 = call ptr @avra_array_get_owned(ptr %6, i64 %ld16)
  call void @avra_rc_retain(ptr %14)
  call void @avra_cell_release(ptr %slot10)
  store ptr %14, ptr %slot10, align 8
  %ld17 = load ptr, ptr %slot10, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_rc_retain(ptr %regval)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_entry"(ptr %0, ptr %ld17, ptr %regval)
  %ld18 = load i64, ptr %slot9, align 8
  %add19 = add i64 %ld18, 1
  store i64 %add19, ptr %slot9, align 8
  call void @avra_rc_release(ptr %14)
  br label %lhead11

lhead21:                                          ; preds = %endif30, %lexit12
  %ld23 = load i64, ptr %slot20, align 8
  %cmp24 = icmp slt i64 %ld23, %13
  br i1 %cmp24, label %lbody25, label %lexit22

lexit22:                                          ; preds = %lhead21
  call void @avra_slot_set_owned(ptr %0, i64 12, ptr %11)
  %16 = call i64 @avra_array_get(ptr %0, i64 13)
  %sub = sub i64 %16, 1
  call void @avra_slot_set(ptr %0, i64 13, i64 %sub)
  call void @avra_cell_release(ptr %slot10)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody25:                                          ; preds = %lhead21
  %ld26 = load i64, ptr %slot20, align 8
  %17 = call ptr @avra_array_get_owned(ptr %12, i64 %ld26)
  %18 = call i64 @avra_array_get(ptr %17, i64 1)
  %19 = call i64 @avra_array_get(ptr %0, i64 13)
  %cmp27 = icmp slt i64 %18, %19
  br i1 %cmp27, label %then28, label %else29

then28:                                           ; preds = %lbody25
  call void @avra_array_push_owned(ptr %11, ptr %17)
  br label %endif30

else29:                                           ; preds = %lbody25
  br label %endif30

endif30:                                          ; preds = %else29, %then28
  %regval31 = phi i64 [ 0, %then28 ], [ 0, %else29 ]
  %ld32 = load i64, ptr %slot20, align 8
  %add33 = add i64 %ld32, 1
  store i64 %add33, ptr %slot20, align 8
  call void @avra_rc_release(ptr %17)
  br label %lhead21
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_entry"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 2)
  %b = icmp ne i64 %3, 0
  %not = xor i1 %b, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_deferred"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  %5 = call ptr @avra_insist(ptr %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_if_failed"(ptr %0, ptr %1, i64 %6)
  call void @avra_rc_release(ptr %5)
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval4 = phi i64 [ 0, %then1 ], [ 0, %else2 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_if_failed"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %3, i64 5)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 %2)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %boxed3)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp = icmp eq i64 %9, 13
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokness_of"(ptr %0, i64 %2)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 14)
  call void @avra_array_push(ptr %12, i64 %11)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %10, ptr %12)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_arm"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_deferred"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_close"(ptr %0)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_close"(ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_deferred"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 %6)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr %boxed, ptr %boxed3)
  %cmp = icmp ne ptr %8, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %10, i64 0, ptr null)
  %12 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed4 = inttoptr i64 %12 to ptr
  %13 = call ptr @avra_insist(ptr %8)
  %14 = call i64 @avra_array_get(ptr %13, i64 2)
  %boxed5 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed4)
  call void @avra_rc_retain(ptr %boxed5)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %boxed4, ptr %boxed5)
  %16 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed6 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %1, i64 0)
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 %17)
  %19 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %19, i64 19)
  call void @avra_array_push(ptr %19, i64 %15)
  call void @avra_array_push(ptr %19, i64 %11)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed6, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %20

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_arm"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eokness_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$24280"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eprint_lowering"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed3, i64 %1)
  %boxed4 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %boxed4)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed1, ptr %boxed4)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp = icmp eq i64 %9, 6
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 2)
  br label %endif

else:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp5 = icmp eq i64 %11, 7
  br i1 %cmp5, label %then6, label %else7

endif:                                            ; preds = %endif8, %then
  %regval84 = phi ptr [ %10, %then ], [ %regval83, %endif8 ]
  %cmp85 = icmp ne ptr %regval84, null
  br i1 %cmp85, label %then86, label %else87

then6:                                            ; preds = %else
  %12 = call ptr @avra_array_get_owned(ptr %8, i64 2)
  br label %endif8

else7:                                            ; preds = %else
  %13 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp9 = icmp eq i64 %13, 13
  br i1 %cmp9, label %then10, label %else11

endif8:                                           ; preds = %endif12, %then6
  %regval83 = phi ptr [ %12, %then6 ], [ %regval82, %endif12 ]
  br label %endif

then10:                                           ; preds = %else7
  %14 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %15 = call i64 @avra_array_get(ptr %14, i64 4)
  %boxed13 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %boxed13, i64 0)
  %boxed14 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed15 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %boxed15, i64 1)
  %boxed16 = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %boxed16, i64 %1)
  %boxed17 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %boxed17)
  %20 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed14, ptr %boxed17)
  call void @avra_rc_release(ptr %14)
  br label %endif12

else11:                                           ; preds = %else7
  %21 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp18 = icmp eq i64 %21, 8
  br i1 %cmp18, label %then19, label %else20

endif12:                                          ; preds = %endif21, %then10
  %regval82 = phi ptr [ %20, %then10 ], [ %regval81, %endif21 ]
  br label %endif8

then19:                                           ; preds = %else11
  %22 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %23 = call i64 @avra_array_get(ptr %22, i64 4)
  %boxed22 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed22, i64 0)
  %boxed23 = inttoptr i64 %24 to ptr
  %25 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed24 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %boxed24, i64 1)
  %boxed25 = inttoptr i64 %26 to ptr
  %27 = call i64 @avra_array_get(ptr %boxed25, i64 %1)
  %boxed26 = inttoptr i64 %27 to ptr
  call void @avra_rc_retain(ptr %boxed23)
  call void @avra_rc_retain(ptr %boxed26)
  %28 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed23, ptr %boxed26)
  call void @avra_rc_release(ptr %22)
  br label %endif21

else20:                                           ; preds = %else11
  %29 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp27 = icmp eq i64 %29, 20
  br i1 %cmp27, label %then28, label %else29

endif21:                                          ; preds = %endif30, %then19
  %regval81 = phi ptr [ %28, %then19 ], [ %regval80, %endif30 ]
  br label %endif12

then28:                                           ; preds = %else20
  %30 = call ptr @avra_array_get_owned(ptr %8, i64 2)
  br label %endif30

else29:                                           ; preds = %else20
  %31 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp31 = icmp eq i64 %31, 21
  br i1 %cmp31, label %then32, label %else33

endif30:                                          ; preds = %endif34, %then28
  %regval80 = phi ptr [ %30, %then28 ], [ %regval79, %endif34 ]
  br label %endif21

then32:                                           ; preds = %else29
  %32 = call ptr @avra_array_get_owned(ptr %8, i64 3)
  br label %endif34

else33:                                           ; preds = %else29
  %33 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp35 = icmp eq i64 %33, 18
  br i1 %cmp35, label %then36, label %else37

endif34:                                          ; preds = %endif38, %then32
  %regval79 = phi ptr [ %32, %then32 ], [ %regval78, %endif38 ]
  br label %endif30

then36:                                           ; preds = %else33
  br label %endif38

else37:                                           ; preds = %else33
  %34 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp39 = icmp eq i64 %34, 16
  br i1 %cmp39, label %then40, label %else41

endif38:                                          ; preds = %endif71, %then36
  %regval78 = phi ptr [ getelementptr inbounds (i8, ptr @.str.6, i64 16), %then36 ], [ %regval77, %endif71 ]
  br label %endif34

then40:                                           ; preds = %else37
  br label %endif42

else41:                                           ; preds = %else37
  %35 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp43 = icmp eq i64 %35, 11
  br label %endif42

endif42:                                          ; preds = %else41, %then40
  %regval = phi i1 [ true, %then40 ], [ %cmp43, %else41 ]
  br i1 %regval, label %then44, label %else45

then44:                                           ; preds = %endif42
  br label %endif46

else45:                                           ; preds = %endif42
  %36 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp47 = icmp eq i64 %36, 17
  br label %endif46

endif46:                                          ; preds = %else45, %then44
  %regval48 = phi i1 [ true, %then44 ], [ %cmp47, %else45 ]
  br i1 %regval48, label %then49, label %else50

then49:                                           ; preds = %endif46
  br label %endif51

else50:                                           ; preds = %endif46
  %37 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp52 = icmp eq i64 %37, 9
  br label %endif51

endif51:                                          ; preds = %else50, %then49
  %regval53 = phi i1 [ true, %then49 ], [ %cmp52, %else50 ]
  br i1 %regval53, label %then54, label %else55

then54:                                           ; preds = %endif51
  br label %endif56

else55:                                           ; preds = %endif51
  %38 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp57 = icmp eq i64 %38, 14
  br label %endif56

endif56:                                          ; preds = %else55, %then54
  %regval58 = phi i1 [ true, %then54 ], [ %cmp57, %else55 ]
  br i1 %regval58, label %then59, label %else60

then59:                                           ; preds = %endif56
  br label %endif61

else60:                                           ; preds = %endif56
  %39 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp62 = icmp eq i64 %39, 5
  br label %endif61

endif61:                                          ; preds = %else60, %then59
  %regval63 = phi i1 [ true, %then59 ], [ %cmp62, %else60 ]
  br i1 %regval63, label %then64, label %else65

then64:                                           ; preds = %endif61
  br label %endif66

else65:                                           ; preds = %endif61
  %40 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp67 = icmp eq i64 %40, 4
  br label %endif66

endif66:                                          ; preds = %else65, %then64
  %regval68 = phi i1 [ true, %then64 ], [ %cmp67, %else65 ]
  br i1 %regval68, label %then69, label %else70

then69:                                           ; preds = %endif66
  %41 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %42 = call i64 @avra_array_get(ptr %41, i64 4)
  %boxed72 = inttoptr i64 %42 to ptr
  %43 = call i64 @avra_array_get(ptr %boxed72, i64 0)
  %boxed73 = inttoptr i64 %43 to ptr
  %44 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed74 = inttoptr i64 %44 to ptr
  %45 = call i64 @avra_array_get(ptr %boxed74, i64 1)
  %boxed75 = inttoptr i64 %45 to ptr
  %46 = call i64 @avra_array_get(ptr %boxed75, i64 %1)
  %boxed76 = inttoptr i64 %46 to ptr
  call void @avra_rc_retain(ptr %boxed73)
  call void @avra_rc_retain(ptr %boxed76)
  %47 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ename_of"(ptr %boxed73, ptr %boxed76)
  call void @avra_rc_release(ptr %41)
  br label %endif71

else70:                                           ; preds = %endif66
  br label %endif71

endif71:                                          ; preds = %else70, %then69
  %regval77 = phi ptr [ %47, %then69 ], [ null, %else70 ]
  br label %endif38

then86:                                           ; preds = %endif
  %48 = call ptr @avra_insist(ptr %regval84)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %48)
  %49 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eno_projection"(ptr %0, ptr %48)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %regval84)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %49

else87:                                           ; preds = %endif
  br label %endif88

endif88:                                          ; preds = %else87, %postret
  %regval89 = phi i64 [ 0, %postret ], [ 0, %else87 ]
  %50 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp90 = icmp eq i64 %50, 3
  br i1 %cmp90, label %then91, label %else92

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %49)
  call void @avra_rc_release(ptr %48)
  br label %endif88

then91:                                           ; preds = %endif88
  %51 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %51, i64 %1)
  br label %endif93

else92:                                           ; preds = %endif88
  %52 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp94 = icmp eq i64 %52, 0
  br i1 %cmp94, label %then95, label %else96

endif93:                                          ; preds = %endif97, %then91
  %regval185 = phi ptr [ %51, %then91 ], [ %regval184, %endif97 ]
  %cmp186 = icmp ne ptr %regval185, null
  br i1 %cmp186, label %then187, label %else188

then95:                                           ; preds = %else92
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  %53 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Etext_call"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), i64 %1)
  %54 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %54, i64 %53)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  br label %endif97

else96:                                           ; preds = %else92
  %55 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp98 = icmp eq i64 %55, 1
  br i1 %cmp98, label %then99, label %else100

endif97:                                          ; preds = %endif101, %then95
  %regval184 = phi ptr [ %54, %then95 ], [ %regval183, %endif101 ]
  br label %endif93

then99:                                           ; preds = %else96
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %56 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Etext_call"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), i64 %1)
  %57 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %57, i64 %56)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  br label %endif101

else100:                                          ; preds = %else96
  %58 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp102 = icmp eq i64 %58, 2
  br i1 %cmp102, label %then103, label %else104

endif101:                                         ; preds = %endif105, %then99
  %regval183 = phi ptr [ %57, %then99 ], [ %regval182, %endif105 ]
  br label %endif97

then103:                                          ; preds = %else100
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %59 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Etext_call"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), i64 %1)
  %60 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %60, i64 %59)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  br label %endif105

else104:                                          ; preds = %else100
  %61 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp106 = icmp eq i64 %61, 10
  br i1 %cmp106, label %then107, label %else108

endif105:                                         ; preds = %endif109, %then103
  %regval182 = phi ptr [ %60, %then103 ], [ %regval181, %endif109 ]
  br label %endif101

then107:                                          ; preds = %else104
  %62 = call i64 @avra_array_get(ptr %8, i64 1)
  %boxed110 = inttoptr i64 %62 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed110)
  %63 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elist_text_callee"(ptr %0, ptr %boxed110)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %63)
  %64 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Etext_call"(ptr %0, ptr %63, i64 %1)
  %65 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %65, i64 %64)
  call void @avra_rc_release(ptr %63)
  br label %endif109

else108:                                          ; preds = %else104
  %66 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp111 = icmp eq i64 %66, 5
  br i1 %cmp111, label %then112, label %else113

endif109:                                         ; preds = %endif164, %then107
  %regval181 = phi ptr [ %65, %then107 ], [ %regval180, %endif164 ]
  br label %endif105

then112:                                          ; preds = %else108
  br label %endif114

else113:                                          ; preds = %else108
  %67 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp115 = icmp eq i64 %67, 4
  br label %endif114

endif114:                                         ; preds = %else113, %then112
  %regval116 = phi i1 [ true, %then112 ], [ %cmp115, %else113 ]
  br i1 %regval116, label %then117, label %else118

then117:                                          ; preds = %endif114
  br label %endif119

else118:                                          ; preds = %endif114
  %68 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp120 = icmp eq i64 %68, 11
  br label %endif119

endif119:                                         ; preds = %else118, %then117
  %regval121 = phi i1 [ true, %then117 ], [ %cmp120, %else118 ]
  br i1 %regval121, label %then122, label %else123

then122:                                          ; preds = %endif119
  br label %endif124

else123:                                          ; preds = %endif119
  %69 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp125 = icmp eq i64 %69, 6
  br label %endif124

endif124:                                         ; preds = %else123, %then122
  %regval126 = phi i1 [ true, %then122 ], [ %cmp125, %else123 ]
  br i1 %regval126, label %then127, label %else128

then127:                                          ; preds = %endif124
  br label %endif129

else128:                                          ; preds = %endif124
  %70 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp130 = icmp eq i64 %70, 7
  br label %endif129

endif129:                                         ; preds = %else128, %then127
  %regval131 = phi i1 [ true, %then127 ], [ %cmp130, %else128 ]
  br i1 %regval131, label %then132, label %else133

then132:                                          ; preds = %endif129
  br label %endif134

else133:                                          ; preds = %endif129
  %71 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp135 = icmp eq i64 %71, 13
  br label %endif134

endif134:                                         ; preds = %else133, %then132
  %regval136 = phi i1 [ true, %then132 ], [ %cmp135, %else133 ]
  br i1 %regval136, label %then137, label %else138

then137:                                          ; preds = %endif134
  br label %endif139

else138:                                          ; preds = %endif134
  %72 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp140 = icmp eq i64 %72, 8
  br label %endif139

endif139:                                         ; preds = %else138, %then137
  %regval141 = phi i1 [ true, %then137 ], [ %cmp140, %else138 ]
  br i1 %regval141, label %then142, label %else143

then142:                                          ; preds = %endif139
  br label %endif144

else143:                                          ; preds = %endif139
  %73 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp145 = icmp eq i64 %73, 20
  br label %endif144

endif144:                                         ; preds = %else143, %then142
  %regval146 = phi i1 [ true, %then142 ], [ %cmp145, %else143 ]
  br i1 %regval146, label %then147, label %else148

then147:                                          ; preds = %endif144
  br label %endif149

else148:                                          ; preds = %endif144
  %74 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp150 = icmp eq i64 %74, 21
  br label %endif149

endif149:                                         ; preds = %else148, %then147
  %regval151 = phi i1 [ true, %then147 ], [ %cmp150, %else148 ]
  br i1 %regval151, label %then152, label %else153

then152:                                          ; preds = %endif149
  br label %endif154

else153:                                          ; preds = %endif149
  %75 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp155 = icmp eq i64 %75, 9
  br label %endif154

endif154:                                         ; preds = %else153, %then152
  %regval156 = phi i1 [ true, %then152 ], [ %cmp155, %else153 ]
  br i1 %regval156, label %then157, label %else158

then157:                                          ; preds = %endif154
  br label %endif159

else158:                                          ; preds = %endif154
  %76 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp160 = icmp eq i64 %76, 14
  br label %endif159

endif159:                                         ; preds = %else158, %then157
  %regval161 = phi i1 [ true, %then157 ], [ %cmp160, %else158 ]
  br i1 %regval161, label %then162, label %else163

then162:                                          ; preds = %endif159
  call void @avra_rc_retain(ptr null)
  br label %endif164

else163:                                          ; preds = %endif159
  %77 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp165 = icmp eq i64 %77, 16
  br i1 %cmp165, label %then166, label %else167

endif164:                                         ; preds = %endif178, %then162
  %regval180 = phi ptr [ null, %then162 ], [ %regval179, %endif178 ]
  br label %endif109

then166:                                          ; preds = %else163
  br label %endif168

else167:                                          ; preds = %else163
  %78 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp169 = icmp eq i64 %78, 17
  br label %endif168

endif168:                                         ; preds = %else167, %then166
  %regval170 = phi i1 [ true, %then166 ], [ %cmp169, %else167 ]
  br i1 %regval170, label %then171, label %else172

then171:                                          ; preds = %endif168
  br label %endif173

else172:                                          ; preds = %endif168
  %79 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp174 = icmp eq i64 %79, 18
  br label %endif173

endif173:                                         ; preds = %else172, %then171
  %regval175 = phi i1 [ true, %then171 ], [ %cmp174, %else172 ]
  br i1 %regval175, label %then176, label %else177

then176:                                          ; preds = %endif173
  call void @avra_rc_retain(ptr null)
  br label %endif178

else177:                                          ; preds = %endif173
  call void @avra_rc_retain(ptr null)
  br label %endif178

endif178:                                         ; preds = %else177, %then176
  %regval179 = phi ptr [ null, %then176 ], [ null, %else177 ]
  br label %endif164

then187:                                          ; preds = %endif93
  %80 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed190 = inttoptr i64 %80 to ptr
  %81 = call ptr @avra_insist(ptr %regval185)
  %82 = call i64 @avra_array_get(ptr %81, i64 0)
  %83 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %83, i64 %82)
  %84 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %84, i64 6)
  call void @avra_array_push_owned(ptr %84, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %84, ptr %83)
  call void @avra_rc_retain(ptr %boxed190)
  call void @avra_rc_retain(ptr %84)
  %85 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed190, ptr %84)
  call void @avra_rc_release(ptr %84)
  call void @avra_rc_release(ptr %83)
  call void @avra_rc_release(ptr %81)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  br label %endif189

else188:                                          ; preds = %endif93
  br label %endif189

endif189:                                         ; preds = %else188, %then187
  %regval191 = phi i64 [ 0, %then187 ], [ 0, %else188 ]
  call void @avra_rc_release(ptr %regval185)
  call void @avra_rc_release(ptr %regval84)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elist_text_callee"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed2, ptr %1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp = icmp eq i64 %6, 2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.11, i64 16)

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed3 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed3, i64 4)
  %boxed4 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %boxed5 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %1)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed5, ptr %1)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp6 = icmp eq i64 %11, 3
  br i1 %cmp6, label %then7, label %else8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  br label %endif

then7:                                            ; preds = %endif
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.12, i64 16)

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str.13, i64 16)

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  br label %endif9
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Etext_call"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 3)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed2, ptr %7)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Emint_ty"(ptr %3, ptr %8)
  %10 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed3 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 %2)
  %12 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %12, i64 7)
  call void @avra_array_push(ptr %12, i64 %9)
  call void @avra_array_push_owned(ptr %12, ptr %1)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed3, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %9
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eno_projection"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eanswer_loc"(ptr %0)
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  %4 = call ptr @avra_str_join(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  %5 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16), ptr %2, ptr %4, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16), ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eanswer_loc"(ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif12, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %3, ptr %slot1, align 8
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed3 = inttoptr i64 %6 to ptr
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed3)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed3, i64 %ld4)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr %4, ptr %7)
  %ld5 = load i64, ptr %slot1, align 8
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 0)
  %10 = call i64 @avra_array_get(ptr %8, i64 3)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %10 to ptr
  %11 = call ptr %cast(ptr %9, ptr %0, i64 %ld5)
  %cmp6 = icmp ne ptr %11, null
  br i1 %cmp6, label %then, label %else

then:                                             ; preds = %lbody
  %12 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed7 = inttoptr i64 %12 to ptr
  %ld8 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed7)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eslot_of"(ptr %boxed7, i64 %ld8)
  %cmp9 = icmp ne ptr %13, null
  %not = xor i1 %cmp9, true
  call void @avra_rc_release(ptr %13)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not, %then ], [ false, %else ]
  br i1 %regval, label %then10, label %else11

then10:                                           ; preds = %endif
  %14 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed13 = inttoptr i64 %14 to ptr
  %ld14 = load i64, ptr %slot1, align 8
  %15 = call ptr @avra_insist(ptr %11)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  call void @avra_rc_retain(ptr %boxed13)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eset_slot"(ptr %boxed13, i64 %ld14, i64 %16)
  call void @avra_rc_release(ptr %15)
  br label %endif12

else11:                                           ; preds = %endif
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval15 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %ld16 = load i64, ptr %slot, align 8
  %add = add i64 %ld16, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eset_slot"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBodyRegs$2Eslot_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_enter"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eopen_frame"(ptr %0)
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 12)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EEmitter$2Egive"(ptr %boxed, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eopen_frame"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 13)
  %add = add i64 %1, 1
  call void @avra_slot_set(ptr %0, i64 13, i64 %add)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eat_exit"(ptr %0, i64 %1, i1 %2) {
entry:
  %3 = call ptr @avra_slot_unique(ptr %0, i64 12)
  %4 = call i64 @avra_array_get(ptr %0, i64 13)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 %1)
  call void @avra_array_push(ptr %5, i64 %4)
  %slot = zext i1 %2 to i64
  call void @avra_array_push(ptr %5, i64 %slot)
  call void @avra_array_push_owned(ptr %3, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Efailing"(ptr %0) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %1 = call i64 @avra_array_get(ptr %0, i64 12)
  %boxed = inttoptr i64 %1 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$24280"(ptr %boxed)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot1)
  store ptr %4, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld3)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_deferred"(ptr %0, ptr %ld3)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Earm_stmts"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eopen_frame"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr null)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eclose_frame"(ptr %0, ptr null)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Eleaving"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 12)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ereversed$24280"(ptr %boxed)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 %ld2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot1)
  store ptr %5, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld3)
  call void @avra_rc_retain(ptr %1)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Erun_entry"(ptr %0, ptr %ld3, ptr %1)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_block"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_enter"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Elower_stmts"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %0, ptr %3)
  br label %endif

else:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %7)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %6, %then ], [ %8, %else ]
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Escope_exit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}
