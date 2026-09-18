; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"the root package\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"package `\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"void\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"ptr\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"Bytes\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2Emut_mark"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Esigs_agree"(ptr %0, ptr %1) {
entry:
  %slot10 = alloca ptr, align 8
  store ptr null, ptr %slot10, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_len(ptr %boxed1)
  %cmp = icmp ne i64 %3, %5
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed3, i64 0)
  %cmp4 = icmp ne i64 %7, %9
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %11 = call i64 @avra_array_len(ptr %10)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret8:                                         ; No predecessors!
  br label %endif7

lhead:                                            ; preds = %endif24, %endif7
  %ld = load i64, ptr %slot, align 8
  %cmp11 = icmp slt i64 %ld, %11
  br i1 %cmp11, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

lbody:                                            ; preds = %lhead
  %ld12 = load i64, ptr %slot, align 8
  %12 = call ptr @avra_array_get_owned(ptr %10, i64 %ld12)
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot10)
  store ptr %12, ptr %slot10, align 8
  %cmp13 = icmp sgt i64 %ld12, 0
  br i1 %cmp13, label %then14, label %else15

then14:                                           ; preds = %lbody
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed17 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed17, i64 %ld12)
  %boxed18 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed18, i64 0)
  %ld19 = load ptr, ptr %slot10, align 8
  %16 = call i64 @avra_array_get(ptr %ld19, i64 0)
  %cmp20 = icmp ne i64 %15, %16
  br label %endif16

else15:                                           ; preds = %lbody
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval21 = phi i1 [ %cmp20, %then14 ], [ false, %else15 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif16
  call void @avra_cell_release(ptr %slot10)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else23:                                           ; preds = %endif16
  br label %endif24

endif24:                                          ; preds = %else23, %postret25
  %regval26 = phi i64 [ 0, %postret25 ], [ 0, %else23 ]
  %ld27 = load i64, ptr %slot, align 8
  %add = add i64 %ld27, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  br label %lhead

postret25:                                        ; No predecessors!
  br label %endif24
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_of"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etparams"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edecl_of"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_of"(ptr %boxed, i64 %5, i64 %1)
  %7 = call ptr @avra_insist(ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Epackage_word"(ptr %0) {
entry:
  %1 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp eq i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr getelementptr inbounds (i8, ptr @.str, i64 16)

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %3 = call ptr @avra_str_join(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_named"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eleave_tscope"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Efull_type"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Evar_named"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm1 [
    i64 21, label %arm
  ]

arm:                                              ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %3, i64 3)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_streq(ptr %boxed, ptr %2)
  %b = icmp ne i64 %6, 0
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi i1 [ %b, %arm ], [ false, %arm1 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eshape_named"(ptr %0) {
entry:
  %1 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %b = icmp ne i64 %1, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 15)
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %b1 = icmp ne i64 %3, 0
  br i1 %b1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval10 = phi ptr [ %2, %then ], [ %regval9, %endif4 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %regval10

then2:                                            ; preds = %else
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 5)
  br label %endif4

else3:                                            ; preds = %else
  %5 = call i64 @avra_streq(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %b5 = icmp ne i64 %5, 0
  br i1 %b5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval9 = phi ptr [ %4, %then2 ], [ %regval, %endif8 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif

then6:                                            ; preds = %else3
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 4)
  br label %endif8

else7:                                            ; preds = %else3
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Escalar_named"(ptr %0)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval = phi ptr [ %6, %then6 ], [ %7, %else7 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif4
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Escalar_named"(ptr)

define { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edeclared_arity"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_named"(ptr %boxed, ptr %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etparams"(ptr %boxed2, ptr %6)
  %8 = call i64 @avra_array_len(ptr %7)
  %cmp3 = icmp eq i64 %8, 0
  br i1 %cmp3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %8, 1
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %pack

postret7:                                         ; No predecessors!
  br label %endif6
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_row"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenter_tscope"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ebuiltin_type_name"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eshape_named"(ptr %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_row"(ptr %0, ptr %1)
  %cmp1 = icmp ne ptr %3, null
  call void @avra_rc_release(ptr %3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Enew_type_cx"(ptr %0, ptr %1, ptr %2, ptr %3, i64 %4, i64 %5) {
entry:
  %6 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 22)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed, ptr %7)
  %9 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed1 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed1, i64 2)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %11 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24921"(ptr %boxed2)
  call void @avra_rc_retain(ptr %8)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enew_type_facts"(i64 %4, i64 %5, i64 %11, ptr %8)
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call ptr @avra_array_sized(i64 0)
  %16 = call ptr @avra_array_sized(i64 0)
  %17 = call ptr @avra_array_sized(i64 0)
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call ptr @avra_array_sized(i64 0)
  %20 = call ptr @avra_array_sized(i64 14)
  call void @avra_array_push_owned(ptr %20, ptr %2)
  call void @avra_array_push_owned(ptr %20, ptr %3)
  call void @avra_array_push_owned(ptr %20, ptr %12)
  call void @avra_array_push_owned(ptr %20, ptr %8)
  call void @avra_array_push_owned(ptr %20, ptr %0)
  call void @avra_array_push_owned(ptr %20, ptr %1)
  call void @avra_array_push_owned(ptr %20, ptr %13)
  call void @avra_array_push_owned(ptr %20, ptr %14)
  call void @avra_array_push_owned(ptr %20, ptr %15)
  call void @avra_array_push_owned(ptr %20, ptr %16)
  call void @avra_array_push_owned(ptr %20, ptr %17)
  call void @avra_array_push_owned(ptr %20, ptr %18)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_array_push(ptr %20, i64 0)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %20
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enew_type_facts"(i64, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24921"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_declaration"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ediverges"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotations_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Epost_order"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_decl"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 4)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %3, 10
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eruntime_stmts"(ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %5)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 2)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot, align 8
  br label %lhead

else:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp12 = icmp eq i64 %10, 1
  br i1 %cmp12, label %then13, label %else14

endif:                                            ; preds = %endif15, %lexit
  %regval70 = phi i64 [ 0, %lexit ], [ %regval69, %endif15 ]
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Espeak_hungry"(ptr %0)
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

lhead:                                            ; preds = %endif9, %then
  %ld = load i64, ptr %slot, align 8
  %cmp2 = icmp slt i64 %ld, %9
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  br label %endif

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %13 = call i64 @avra_array_get(ptr %8, i64 %ld3)
  store i64 %13, ptr %slot1, align 8
  %14 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed4 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed4, i64 1)
  %boxed5 = inttoptr i64 %15 to ptr
  %ld6 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed5)
  %16 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_declaration"(ptr %boxed5, i64 %ld6)
  br i1 %16, label %then7, label %else8

then7:                                            ; preds = %lbody
  %ld10 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_annotations"(ptr %0, i64 %ld10)
  br label %endif9

else8:                                            ; preds = %lbody
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval = phi i64 [ 0, %then7 ], [ 0, %else8 ]
  %ld11 = load i64, ptr %slot, align 8
  %add = add i64 %ld11, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then13:                                           ; preds = %else
  %18 = call i64 @avra_array_get(ptr %1, i64 9)
  %boxed16 = inttoptr i64 %18 to ptr
  %cmp17 = icmp ne ptr %boxed16, null
  %not = xor i1 %cmp17, true
  br i1 %not, label %then18, label %else19

else14:                                           ; preds = %else
  %19 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp22 = icmp eq i64 %19, 7
  br i1 %cmp22, label %then23, label %else24

endif15:                                          ; preds = %endif25, %endif20
  %regval69 = phi i64 [ %regval21, %endif20 ], [ %regval68, %endif25 ]
  br label %endif

then18:                                           ; preds = %then13
  %20 = call i64 @avra_array_get(ptr %1, i64 2)
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %21, i64 %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %21)
  call void @avra_rc_release(ptr %21)
  br label %endif20

else19:                                           ; preds = %then13
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %23 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Efn_body"(ptr %0, ptr %1)
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval21 = phi i64 [ %22, %then18 ], [ %23, %else19 ]
  br label %endif15

then23:                                           ; preds = %else14
  %24 = call i64 @avra_array_get(ptr %1, i64 9)
  %boxed26 = inttoptr i64 %24 to ptr
  %cmp27 = icmp ne ptr %boxed26, null
  %not28 = xor i1 %cmp27, true
  br i1 %not28, label %then29, label %else30

else24:                                           ; preds = %else14
  %25 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp33 = icmp eq i64 %25, 8
  br i1 %cmp33, label %then34, label %else35

endif25:                                          ; preds = %endif36, %endif31
  %regval68 = phi i64 [ %regval32, %endif31 ], [ %regval67, %endif36 ]
  br label %endif15

then29:                                           ; preds = %then23
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endif31

else30:                                           ; preds = %then23
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %27 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Emethod_body"(ptr %0, ptr %1)
  br label %endif31

endif31:                                          ; preds = %else30, %then29
  %regval32 = phi i64 [ %26, %then29 ], [ %27, %else30 ]
  br label %endif25

then34:                                           ; preds = %else24
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %28 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edefault_body"(ptr %0, ptr %1)
  br label %endif36

else35:                                           ; preds = %else24
  %29 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp37 = icmp eq i64 %29, 11
  br i1 %cmp37, label %then38, label %else39

endif36:                                          ; preds = %endif40, %then34
  %regval67 = phi i64 [ %28, %then34 ], [ %regval66, %endif40 ]
  br label %endif25

then38:                                           ; preds = %else35
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %30 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecase_body"(ptr %0, ptr %1)
  br label %endif40

else39:                                           ; preds = %else35
  %31 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp41 = icmp eq i64 %31, 2
  br i1 %cmp41, label %then42, label %else43

endif40:                                          ; preds = %endif54, %then38
  %regval66 = phi i64 [ %30, %then38 ], [ %regval65, %endif54 ]
  br label %endif36

then42:                                           ; preds = %else39
  br label %endif44

else43:                                           ; preds = %else39
  %32 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp45 = icmp eq i64 %32, 3
  br label %endif44

endif44:                                          ; preds = %else43, %then42
  %regval46 = phi i1 [ true, %then42 ], [ %cmp45, %else43 ]
  br i1 %regval46, label %then47, label %else48

then47:                                           ; preds = %endif44
  br label %endif49

else48:                                           ; preds = %endif44
  %33 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp50 = icmp eq i64 %33, 4
  br label %endif49

endif49:                                          ; preds = %else48, %then47
  %regval51 = phi i1 [ true, %then47 ], [ %cmp50, %else48 ]
  br i1 %regval51, label %then52, label %else53

then52:                                           ; preds = %endif49
  %34 = call i64 @avra_array_get(ptr %1, i64 2)
  %35 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %35, i64 %34)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %35)
  %36 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %35)
  call void @avra_rc_release(ptr %35)
  br label %endif54

else53:                                           ; preds = %endif49
  %37 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp55 = icmp eq i64 %37, 12
  br i1 %cmp55, label %then56, label %else57

endif54:                                          ; preds = %endif58, %then52
  %regval65 = phi i64 [ %36, %then52 ], [ %regval64, %endif58 ]
  br label %endif40

then56:                                           ; preds = %else53
  %38 = call i64 @avra_array_get(ptr %1, i64 2)
  %39 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %39, i64 %38)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %39)
  %40 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %39)
  call void @avra_rc_release(ptr %39)
  br label %endif58

else57:                                           ; preds = %else53
  %41 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp59 = icmp eq i64 %41, 6
  br i1 %cmp59, label %then60, label %else61

endif58:                                          ; preds = %endif62, %then56
  %regval64 = phi i64 [ %40, %then56 ], [ %regval63, %endif62 ]
  br label %endif54

then60:                                           ; preds = %else57
  %42 = call i64 @avra_array_get(ptr %1, i64 2)
  %43 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %43, i64 %42)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %43)
  %44 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %43)
  call void @avra_rc_release(ptr %43)
  br label %endif62

else61:                                           ; preds = %else57
  %45 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endif62

endif62:                                          ; preds = %else61, %then60
  %regval63 = phi i64 [ %44, %then60 ], [ %45, %else61 ]
  br label %endif58
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Espeak_hungry"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_slot_set(ptr %0, i64 13, i64 1)
  %1 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %1 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_ones"(ptr %boxed)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_slot_set(ptr %0, i64 13, i64 0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %2, i64 %ld2)
  store i64 %4, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed3 = inttoptr i64 %5 to ptr
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed3)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Escope_at"(ptr %boxed3, i64 %ld4)
  %cmp5 = icmp ne ptr %6, null
  br i1 %cmp5, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %6)
  br label %endif

else:                                             ; preds = %lbody
  %7 = call ptr @avra_array_sized(i64 0)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %6, %then ], [ %7, %else ]
  call void @avra_slot_set_owned(ptr %0, i64 6, ptr %regval)
  %ld6 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_node"(ptr %0, i64 %ld6)
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_node"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %4)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %boxed2, ptr %4)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %9 = call i64 @avra_array_get(ptr %6, i64 4)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %9 to ptr
  %10 = call ptr %cast(ptr %8, ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eset_type"(ptr %7, i64 %1, ptr %10)
  %12 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %13 = call i64 @avra_array_get(ptr %6, i64 1)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %4)
  %cast3 = inttoptr i64 %13 to ptr
  %14 = call ptr %cast3(ptr %12, ptr %4)
  %15 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %16 = call i64 @avra_array_get(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %15)
  call void @avra_rc_retain(ptr %4)
  %cast4 = inttoptr i64 %16 to ptr
  %17 = call ptr %cast4(ptr %15, ptr %4)
  %18 = call ptr @avra_array_concat(ptr %14, ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eany_hungry"(ptr %0, ptr %18)
  br i1 %19, label %then, label %else

then:                                             ; preds = %entry
  %20 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed5 = inttoptr i64 %20 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ego_hungry"(ptr %boxed5, i64 %1)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %22 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed6 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  %23 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_at"(ptr %boxed6, i64 %1)
  br i1 %23, label %then7, label %else8

then7:                                            ; preds = %endif
  %24 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %25 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed10 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %24)
  call void @avra_rc_retain(ptr %boxed10)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eremember_scope"(ptr %24, i64 %1, ptr %boxed10)
  call void @avra_rc_release(ptr %24)
  br label %endif9

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i64 [ 0, %then7 ], [ 0, %else8 ]
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eremember_scope"(ptr, i64, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ego_hungry"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eany_hungry"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %3, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_at"(ptr %boxed, i64 %ld3)
  br i1 %5, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eset_type"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Escope_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_ones"(ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecase_body"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 9)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_insist(ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 4)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed2, ptr %boxed3)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %9, %then ], [ null, %else ]
  %cmp4 = icmp ne ptr %regval, null
  br i1 %cmp4, label %then5, label %else6

then5:                                            ; preds = %endif
  %10 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  br label %endif7

else6:                                            ; preds = %endif
  call void @avra_rc_retain(ptr null)
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi ptr [ %10, %then5 ], [ null, %else6 ]
  %cmp9 = icmp ne ptr %regval8, null
  br i1 %cmp9, label %then10, label %else11

then10:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr %regval8)
  br label %endif12

else11:                                           ; preds = %endif7
  %11 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi ptr [ %regval8, %then10 ], [ %11, %else11 ]
  %12 = call ptr @avra_slot_unique(ptr %0, i64 9)
  call void @avra_array_push_owned(ptr %12, ptr %regval13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval13)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %4, ptr %regval13)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %4)
  %15 = call ptr @avra_slot_unique(ptr %0, i64 9)
  %16 = call ptr @avra_array_pop_owned(ptr %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval13)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Especs$2Efits_case"(ptr %0, i64 %4, ptr %regval13)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval13)
  call void @avra_rc_release(ptr %regval8)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %17
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Especs$2Efits_case"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Efeed"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_at"(ptr %boxed, i64 %1)
  %not = xor i1 %4, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %1, ptr %2)
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 6)
  %7 = call i64 @avra_array_get(ptr %0, i64 13)
  %b = icmp ne i64 %7, 0
  call void @avra_slot_set(ptr %0, i64 13, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebeneath"(ptr %0, i64 %1)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %endif7, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_slot_set_owned(ptr %0, i64 6, ptr %6)
  %slot20 = zext i1 %b to i64
  call void @avra_slot_set(ptr %0, i64 13, i64 %slot20)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call i64 @avra_array_get(ptr %8, i64 %ld2)
  store i64 %10, ptr %slot1, align 8
  %11 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed3 = inttoptr i64 %11 to ptr
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed3)
  %12 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_at"(ptr %boxed3, i64 %ld4)
  br i1 %12, label %then5, label %else6

then5:                                            ; preds = %lbody
  %13 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed8 = inttoptr i64 %13 to ptr
  %ld9 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed8)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eabsorb_hunger"(ptr %boxed8, i64 %ld9)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed10 = inttoptr i64 %15 to ptr
  %ld11 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed10)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Escope_at"(ptr %boxed10, i64 %ld11)
  %cmp12 = icmp ne ptr %16, null
  br i1 %cmp12, label %then13, label %else14

else6:                                            ; preds = %lbody
  br label %endif7

endif7:                                           ; preds = %else6, %endif15
  %regval18 = phi i64 [ 0, %endif15 ], [ 0, %else6 ]
  %ld19 = load i64, ptr %slot, align 8
  %add = add i64 %ld19, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

then13:                                           ; preds = %then5
  call void @avra_rc_retain(ptr %16)
  br label %endif15

else14:                                           ; preds = %then5
  call void @avra_rc_retain(ptr %6)
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval16 = phi ptr [ %16, %then13 ], [ %6, %else14 ]
  call void @avra_slot_set_owned(ptr %0, i64 6, ptr %regval16)
  %ld17 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_node"(ptr %0, i64 %ld17)
  call void @avra_rc_release(ptr %regval16)
  call void @avra_rc_release(ptr %16)
  br label %endif7
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eabsorb_hunger"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebeneath"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %4)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %boxed2, ptr %4)
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %9 = call i64 @avra_array_get(ptr %6, i64 1)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %4)
  %cast = inttoptr i64 %9 to ptr
  %10 = call ptr %cast(ptr %8, ptr %4)
  %11 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %12 = call i64 @avra_array_get(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %4)
  %cast3 = inttoptr i64 %12 to ptr
  %13 = call ptr %cast3(ptr %11, ptr %4)
  %14 = call ptr @avra_array_concat(ptr %10, ptr %13)
  %15 = call i64 @avra_array_len(ptr %14)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %15
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %7)
  %16 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr %7)
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 %1)
  %18 = call ptr @avra_array_concat(ptr %16, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %19 = call i64 @avra_array_get(ptr %14, i64 %ld4)
  call void @avra_rc_retain(ptr %0)
  %20 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebeneath"(ptr %0, i64 %19)
  call void @avra_array_push_owned(ptr %7, ptr %20)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %20)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot4 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eset_want"(ptr %boxed, i64 %1, ptr %2)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed2, i64 %1)
  %8 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %7)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %boxed3, ptr %7)
  %10 = call ptr @avra_array_get_owned(ptr %9, i64 0)
  %11 = call i64 @avra_array_get(ptr %9, i64 2)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %7)
  %cast = inttoptr i64 %11 to ptr
  %12 = call ptr %cast(ptr %10, ptr %7)
  %13 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %13
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot, align 8
  %14 = call i64 @avra_array_get(ptr %12, i64 %ld5)
  store i64 %14, ptr %slot4, align 8
  %ld6 = load i64, ptr %slot4, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %ld6, ptr %2)
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eset_want"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eretype_seated"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Ehungry_at"(ptr %boxed, i64 %1)
  %not = xor i1 %5, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr %boxed2, i64 %1)
  %cmp = icmp ne ptr %8, null
  %not3 = xor i1 %cmp, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %9 = call ptr @avra_insist(ptr %8)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed9 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_len(ptr %boxed9)
  %12 = call i64 @avra_array_len(ptr %2)
  %cmp10 = icmp ne i64 %11, %12
  br i1 %cmp10, label %then11, label %else12

postret7:                                         ; No predecessors!
  br label %endif6

then11:                                           ; preds = %endif6
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else12:                                           ; preds = %endif6
  br label %endif13

endif13:                                          ; preds = %else12, %postret14
  %regval15 = phi i64 [ 0, %postret14 ], [ 0, %else12 ]
  %13 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed16 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed16)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eabsorb_hunger"(ptr %boxed16, i64 %1)
  %15 = call ptr @avra_insist(ptr %8)
  %16 = call i64 @avra_array_get(ptr %15, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %17 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Elambda_body"(ptr %0, i64 %1, ptr %2, ptr %3, i64 %16)
  %18 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed17 = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %boxed17, i64 5)
  %boxed18 = inttoptr i64 %19 to ptr
  %20 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %20, i64 14)
  call void @avra_array_push_owned(ptr %20, ptr %2)
  call void @avra_array_push_owned(ptr %20, ptr %3)
  call void @avra_array_push_owned(ptr %20, ptr %17)
  call void @avra_rc_retain(ptr %boxed18)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed18, ptr %20)
  %22 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed19 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %boxed19)
  call void @avra_rc_retain(ptr %21)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eset_type"(ptr %boxed19, i64 %1, ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %21

postret14:                                        ; No predecessors!
  br label %endif13
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Elambda_body"(ptr %0, i64 %1, ptr %2, ptr %3, i64 %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eseat_lambda"(ptr %boxed, i64 %1, ptr %2, ptr %3)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecapture_seats"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eseat_captures"(ptr %7, i64 %1, ptr %8)
  %10 = call ptr @avra_slot_unique(ptr %0, i64 10)
  %11 = call i64 @avra_array_get(ptr %0, i64 9)
  %boxed1 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_len(ptr %boxed1)
  call void @avra_array_push(ptr %10, i64 %12)
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %4)
  %14 = call ptr @avra_slot_unique(ptr %0, i64 10)
  %15 = call i64 @avra_array_pop(ptr %14)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %13
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Etype_at"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %1) {
entry:
  %slot2 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 13)
  %b = icmp ne i64 %2, 0
  call void @avra_slot_set(ptr %0, i64 13, i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epost_order"(ptr %3, ptr %boxed1, i64 %1)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %slot6 = zext i1 %b to i64
  call void @avra_slot_set(ptr %0, i64 13, i64 %slot6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %6, i64 %ld3)
  store i64 %8, ptr %slot2, align 8
  %ld4 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_node"(ptr %0, i64 %ld4)
  %ld5 = load i64, ptr %slot, align 8
  %add = add i64 %ld5, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eseat_captures"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecapture_seats"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ecapture"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call ptr @avra_insist(ptr %3)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %8
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_array_get(ptr %7, i64 %ld2)
  %boxed3 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed3)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebinding_ty"(ptr %0, ptr %boxed3)
  call void @avra_array_push_owned(ptr %5, ptr %10)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebinding_ty"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm7 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_type"(ptr %0, i64 %3)
  br label %endswitch

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_type"(ptr %0, i64 0)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr %0, i64 %6)
  br label %endswitch

arm3:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  %9 = call i64 @avra_array_get(ptr %1, i64 2)
  %10 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Epattern_type"(ptr %boxed, i64 %8, i64 %9)
  %cmp = icmp ne ptr %11, null
  br i1 %cmp, label %then, label %else

arm4:                                             ; preds = %entry
  %12 = call i64 @avra_array_get(ptr %1, i64 1)
  %13 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Elambda_param_ty"(ptr %0, i64 %12, i64 %13)
  br label %endswitch

arm5:                                             ; preds = %entry
  %15 = call i64 @avra_array_get(ptr %1, i64 1)
  %16 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecapture_ty"(ptr %0, i64 %15, i64 %16)
  br label %endswitch

arm6:                                             ; preds = %entry
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %18)
  call void @avra_rc_release(ptr %18)
  br label %endswitch

arm7:                                             ; preds = %entry
  %20 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed8 = inttoptr i64 %20 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed8)
  %21 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edecl_type"(ptr %0, ptr %boxed8)
  br label %endswitch

endswitch:                                        ; preds = %arm7, %arm6, %arm5, %arm4, %endif, %arm2, %arm1, %arm
  %regval9 = phi ptr [ %4, %arm ], [ %5, %arm1 ], [ %7, %arm2 ], [ %regval, %endif ], [ %14, %arm4 ], [ %17, %arm5 ], [ %19, %arm6 ], [ %21, %arm7 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval9

then:                                             ; preds = %arm3
  call void @avra_rc_retain(ptr %11)
  br label %endif

else:                                             ; preds = %arm3
  %22 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %11, %then ], [ %22, %else ]
  call void @avra_rc_release(ptr %11)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edecl_type"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %5 = call i64 @avra_array_get(ptr %4, i64 15)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_type_of"(ptr %boxed, ptr %boxed1, ptr %boxed2, ptr %1)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_type_of"(ptr, ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecapture_ty"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ecapture"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 %2)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebinding_ty"(ptr %0, ptr %boxed2)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ecapture"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Elambda_param_ty"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Elambda_seats"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 %2)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Elambda_seats"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Epattern_type"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %1, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 6)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 %1)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eseat_lambda"(ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edefault_body"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 9)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_insist(ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 4)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed3 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed2, ptr %boxed3)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %9, %then ], [ null, %else ]
  %cmp4 = icmp ne ptr %regval, null
  br i1 %cmp4, label %then5, label %else6

then5:                                            ; preds = %endif
  %10 = call ptr @avra_array_get_owned(ptr %regval, i64 1)
  br label %endif7

else6:                                            ; preds = %endif
  call void @avra_rc_retain(ptr null)
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi ptr [ %10, %then5 ], [ null, %else6 ]
  %cmp9 = icmp ne ptr %regval8, null
  br i1 %cmp9, label %then10, label %else11

then10:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr %regval8)
  br label %endif12

else11:                                           ; preds = %endif7
  %11 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi ptr [ %regval8, %then10 ], [ %11, %else11 ]
  %12 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenter_tscope"(ptr %0, i64 %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval13)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %4, ptr %regval13)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eleave_tscope"(ptr %0)
  %17 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed14 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %regval13)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Efits_default"(ptr %0, i64 %4, ptr %boxed14, ptr %regval13)
  call void @avra_rc_release(ptr %regval13)
  call void @avra_rc_release(ptr %regval8)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %18
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Efits_default"(ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Emethod_body"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ereceiver_contract"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ereceiver_contract"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_contract"(ptr, ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 13)
  %b = icmp ne i64 %2, 0
  call void @avra_slot_set(ptr %0, i64 13, i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %slot8 = zext i1 %b to i64
  call void @avra_slot_set(ptr %0, i64 13, i64 %slot8)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %4, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed3 = inttoptr i64 %7 to ptr
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed3, i64 %ld4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr %5, ptr %8)
  %ld5 = load i64, ptr %slot1, align 8
  %10 = call ptr @avra_array_get_owned(ptr %9, i64 0)
  %11 = call i64 @avra_array_get(ptr %9, i64 2)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %11 to ptr
  %12 = call i64 %cast(ptr %10, ptr %0, i64 %ld5)
  %ld6 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_annotations"(ptr %0, i64 %ld6)
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_annotations"(ptr %0, i64 %1) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotations_of"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot2)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 %ld3)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot2)
  store ptr %6, ptr %slot2, align 8
  %7 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed4 = inttoptr i64 %7 to ptr
  %ld5 = load ptr, ptr %slot2, align 8
  %8 = call i64 @avra_array_get(ptr %ld5, i64 1)
  call void @avra_rc_retain(ptr %boxed4)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eowns"(ptr %boxed4, i64 %8)
  br i1 %9, label %then, label %else

then:                                             ; preds = %lbody
  %ld6 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld6)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_annotation"(ptr %0, ptr %ld6)
  %ld7 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld7)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Echeck_annotation"(ptr %0, i64 %1, ptr %ld7)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld8 = load i64, ptr %slot, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Echeck_annotation"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_annotation"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eowns"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Efn_body"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_contract"(ptr %0, ptr %1, i64 0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eruntime_stmts"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %6 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_declaration"(ptr %boxed, i64 %4)
  %not = xor i1 %6, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_array_push(ptr %1, i64 %4)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenclosing_ret"(ptr %0) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebehind_lambda"(ptr %0)
  br i1 %1, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 9)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 0, %3
  br i1 %cmp, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  %sub = sub i64 %3, 1
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 %sub)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval4 = phi i64 [ 0, %then1 ], [ 0, %else2 ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebehind_lambda"(ptr %0) {
entry:
  %slot = alloca { i1, i64 }, align 8
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 10)
  store { i1, i64 } zeroinitializer, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp slt i64 0, %2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %sub = sub i64 %2, 1
  %3 = call i64 @avra_array_get(ptr %1, i64 %sub)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %3, 1
  store { i1, i64 } %pack, ptr %slot, align 8
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load { i1, i64 }, ptr %slot, align 8
  %x = extractvalue { i1, i64 } %ld, 0
  br i1 %x, label %then1, label %else2

then1:                                            ; preds = %endif
  %4 = call i64 @avra_array_get(ptr %0, i64 9)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_len(ptr %boxed)
  %x4 = extractvalue { i1, i64 } %ld, 0
  %x5 = extractvalue { i1, i64 } %ld, 1
  %slot6 = zext i1 %x4 to i64
  %6 = call i64 @avra_insist_scalar(i64 %slot6, i64 %x5)
  %cmp7 = icmp sle i64 %5, %6
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval8 = phi i1 [ %cmp7, %then1 ], [ false, %else2 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval8
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewritten"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Efull_type"(ptr %0, ptr %4, ptr %2)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2Esame_expr"(i64, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eheard_mut"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eheard_marks"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %4, %then ], [ %5, %else ]
  call void @avra_rc_retain(ptr %regval)
  %6 = call i1 @"av_$40std$2Eavrac$2Ecore$2Emut_mark"(ptr %regval, i64 %2)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i1 %6
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Eheard_marks"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etarget_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm7 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
    i64 6, label %arm6
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

arm:                                              ; preds = %endif
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrowed_param"(ptr %0, i64 %1, i64 %7)
  %cmp8 = icmp ne ptr %8, null
  br i1 %cmp8, label %then9, label %else10

arm1:                                             ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_type"(ptr %0, i64 0)
  br label %endswitch

arm2:                                             ; preds = %endif
  %10 = call i64 @avra_array_get(ptr %5, i64 1)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrowed_def"(ptr %0, i64 %1, i64 %10)
  %cmp13 = icmp ne ptr %11, null
  br i1 %cmp13, label %then14, label %else15

arm3:                                             ; preds = %endif
  %12 = call i64 @avra_array_get(ptr %5, i64 1)
  %13 = call i64 @avra_array_get(ptr %5, i64 2)
  %14 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed18 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed18)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Epattern_type"(ptr %boxed18, i64 %12, i64 %13)
  %cmp19 = icmp ne ptr %15, null
  br i1 %cmp19, label %then20, label %else21

arm4:                                             ; preds = %endif
  %16 = call i64 @avra_array_get(ptr %5, i64 1)
  %17 = call i64 @avra_array_get(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Elambda_param_ty"(ptr %0, i64 %16, i64 %17)
  br label %endswitch

arm5:                                             ; preds = %endif
  %19 = call i64 @avra_array_get(ptr %5, i64 1)
  %20 = call i64 @avra_array_get(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %0)
  %21 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ecapture_ty"(ptr %0, i64 %19, i64 %20)
  br label %endswitch

arm6:                                             ; preds = %endif
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %22)
  call void @avra_rc_release(ptr %22)
  br label %endswitch

arm7:                                             ; preds = %endif
  %24 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed24 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed24)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Edecl_type"(ptr %0, ptr %boxed24)
  br label %endswitch

endswitch:                                        ; preds = %arm7, %arm6, %arm5, %arm4, %endif22, %endif16, %arm1, %endif11
  %regval25 = phi ptr [ %regval12, %endif11 ], [ %9, %arm1 ], [ %regval17, %endif16 ], [ %regval23, %endif22 ], [ %18, %arm4 ], [ %21, %arm5 ], [ %23, %arm6 ], [ %25, %arm7 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval25

then9:                                            ; preds = %arm
  call void @avra_rc_retain(ptr %8)
  br label %endif11

else10:                                           ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  %26 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_type"(ptr %0, i64 %7)
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval12 = phi ptr [ %8, %then9 ], [ %26, %else10 ]
  call void @avra_rc_release(ptr %8)
  br label %endswitch

then14:                                           ; preds = %arm2
  call void @avra_rc_retain(ptr %11)
  br label %endif16

else15:                                           ; preds = %arm2
  call void @avra_rc_retain(ptr %0)
  %27 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr %0, i64 %10)
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi ptr [ %11, %then14 ], [ %27, %else15 ]
  call void @avra_rc_release(ptr %11)
  br label %endswitch

then20:                                           ; preds = %arm3
  call void @avra_rc_retain(ptr %15)
  br label %endif22

else21:                                           ; preds = %arm3
  %28 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif22

endif22:                                          ; preds = %else21, %then20
  %regval23 = phi ptr [ %15, %then20 ], [ %28, %else21 ]
  call void @avra_rc_release(ptr %15)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrowed_def"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrow_hit"(ptr %0, i64 %1, ptr %3, i64 %2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrow_hit"(ptr %0, i64 %1, ptr %2, i64 %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Etyping$24l763" to i64))
  call void @avra_array_push(ptr %4, i64 %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  %not = xor i1 %cmp5, true
  br i1 %not, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %7)
  %cast = inttoptr i64 %5 to ptr
  %8 = call i1 %cast(ptr %4, ptr %7)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead

then6:                                            ; preds = %lexit
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else7:                                            ; preds = %lexit
  br label %endif8

endif8:                                           ; preds = %else7, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else7 ]
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_insist(ptr %ld4)
  %11 = call i64 @avra_array_get(ptr %10, i64 2)
  %boxed10 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %boxed10)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Enarrow"(ptr %boxed, i64 %1, ptr %boxed10)
  %13 = call ptr @avra_insist(ptr %ld4)
  %14 = call ptr @avra_array_get_owned(ptr %13, i64 1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret:                                          ; No predecessors!
  br label %endif8
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Etyping$24l763"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %cmp = icmp eq i64 %2, %3
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Enarrow"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrowed_param"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrow_hit"(ptr %0, i64 %1, ptr %3, i64 %2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_binding"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epair"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_slot_unique(ptr %0, i64 12)
  call void @avra_array_push(ptr %2, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_loc"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Efull_type"(ptr %0, ptr %3, ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erecord_binding"(ptr %0, i64 %1, ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_sig"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_under"(ptr %0, i64 %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Estmt_sig"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 6)
  %5 = call ptr @avra_slot_unique(ptr %0, i64 9)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %6, %then ], [ null, %else ]
  %cmp1 = icmp ne ptr %regval, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %regval)
  br label %endif4

else3:                                            ; preds = %endif
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %regval, %then2 ], [ %7, %else3 ]
  call void @avra_array_push_owned(ptr %5, ptr %regval5)
  %cmp6 = icmp ne ptr %3, null
  br i1 %cmp6, label %then7, label %else8

then7:                                            ; preds = %endif4
  %8 = call ptr @avra_array_get_owned(ptr %3, i64 0)
  br label %endif9

else8:                                            ; preds = %endif4
  call void @avra_rc_retain(ptr null)
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval10 = phi ptr [ %8, %then7 ], [ null, %else8 ]
  %cmp11 = icmp ne ptr %regval10, null
  br i1 %cmp11, label %then12, label %else13

then12:                                           ; preds = %endif9
  call void @avra_rc_retain(ptr %regval10)
  br label %endif14

else13:                                           ; preds = %endif9
  %9 = call ptr @avra_array_sized(i64 0)
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi ptr [ %regval10, %then12 ], [ %9, %else13 ]
  call void @avra_slot_set_owned(ptr %0, i64 6, ptr %regval15)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eenter_tscope"(ptr %0, i64 %1)
  %cmp16 = icmp ne ptr %3, null
  br i1 %cmp16, label %then17, label %else18

then17:                                           ; preds = %endif14
  %11 = call ptr @avra_array_get_owned(ptr %3, i64 1)
  br label %endif19

else18:                                           ; preds = %endif14
  call void @avra_rc_retain(ptr null)
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval20 = phi ptr [ %11, %then17 ], [ null, %else18 ]
  %cmp21 = icmp ne ptr %regval20, null
  br i1 %cmp21, label %then22, label %else23

then22:                                           ; preds = %endif19
  %12 = call ptr @avra_insist(ptr %regval20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %2, ptr %12)
  call void @avra_rc_release(ptr %12)
  br label %endif24

else23:                                           ; preds = %endif19
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval25 = phi i64 [ 0, %then22 ], [ 0, %else23 ]
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eleave_tscope"(ptr %0)
  call void @avra_slot_set_owned(ptr %0, i64 6, ptr %4)
  %16 = call ptr @avra_slot_unique(ptr %0, i64 9)
  %17 = call ptr @avra_array_pop_owned(ptr %16)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval20)
  call void @avra_rc_release(ptr %regval15)
  call void @avra_rc_release(ptr %regval10)
  call void @avra_rc_release(ptr %regval5)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eblock_type"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Etype_stmts"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Evalueless_type"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Evalueless_type"(ptr %0, ptr %1) {
entry:
  %slot10 = alloca ptr, align 8
  store ptr null, ptr %slot10, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp slt i64 0, %2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %sub = sub i64 %2, 1
  %3 = call i64 @avra_array_get(ptr %1, i64 %sub)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %ld, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed5 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_insist(ptr %ld)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  call void @avra_rc_retain(ptr %boxed5)
  %9 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ediverges"(ptr %boxed5, i64 %8)
  call void @avra_rc_release(ptr %7)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ %9, %then2 ], [ false, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 9)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot10)
  store ptr null, ptr %slot10, align 8
  %11 = call i64 @avra_array_len(ptr %10)
  %cmp11 = icmp slt i64 0, %11
  br i1 %cmp11, label %then12, label %else13

else8:                                            ; preds = %endif4
  br label %endif9

endif9:                                           ; preds = %else8, %postret
  %regval23 = phi i64 [ 0, %postret ], [ 0, %else8 ]
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed24 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed24, i64 4)
  %boxed25 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed25, i64 0)
  %boxed26 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 6)
  call void @avra_rc_retain(ptr %boxed26)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Einterned"(ptr %boxed26, ptr %15)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

then12:                                           ; preds = %then7
  %sub15 = sub i64 %11, 1
  %17 = call ptr @avra_array_get_owned(ptr %10, i64 %sub15)
  call void @avra_rc_retain(ptr %17)
  call void @avra_cell_release(ptr %slot10)
  store ptr %17, ptr %slot10, align 8
  call void @avra_rc_release(ptr %17)
  br label %endif14

else13:                                           ; preds = %then7
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i64 [ 0, %then12 ], [ 0, %else13 ]
  %ld17 = load ptr, ptr %slot10, align 8
  call void @avra_rc_retain(ptr %ld17)
  %cmp18 = icmp ne ptr %ld17, null
  br i1 %cmp18, label %then19, label %else20

then19:                                           ; preds = %endif14
  call void @avra_rc_retain(ptr %ld17)
  br label %endif21

else20:                                           ; preds = %endif14
  %18 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval22 = phi ptr [ %ld17, %then19 ], [ %18, %else20 ]
  call void @avra_cell_release(ptr %slot10)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval22

postret:                                          ; No predecessors!
  call void @avra_cell_release(ptr %slot10)
  call void @avra_rc_release(ptr %regval22)
  call void @avra_rc_release(ptr %ld17)
  call void @avra_rc_release(ptr %10)
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_narrowed"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm2 [
    i64 2, label %arm
    i64 0, label %arm1
  ]

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif

arm:                                              ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %6, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrowed_def_walk"(ptr %0, i64 %8, i64 %2)
  br label %endswitch

arm1:                                             ; preds = %endif
  %10 = call i64 @avra_array_get(ptr %6, i64 1)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 1)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eseat_type"(ptr %0, i64 %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eframed"(ptr %0, ptr %11, i64 %10, ptr %12, i64 %2)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

arm2:                                             ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %2)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval3 = phi ptr [ %9, %arm ], [ %13, %arm1 ], [ %14, %arm2 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval3
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eframed"(ptr %0, ptr %1, i64 %2, ptr %3, i64 %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecarried"(ptr %boxed1, ptr %3)
  %cmp = icmp ne ptr %7, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %4)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_insist(ptr %7)
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 %2)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_array_push_owned(ptr %10, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epush_frame"(ptr %0, ptr %1, ptr %10)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epop_frame"(ptr %0, ptr %1)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epop_frame"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_slot_unique(ptr %0, i64 7)
  %4 = call ptr @avra_array_pop_owned(ptr %3)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_slot_unique(ptr %0, i64 8)
  %6 = call ptr @avra_array_pop_owned(ptr %5)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi i64 [ 0, %arm ], [ 0, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epush_frame"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %3, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_slot_unique(ptr %0, i64 7)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_slot_unique(ptr %0, i64 8)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi i64 [ 0, %arm ], [ 0, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Enarrowed_def_walk"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed1, i64 %1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp = icmp eq i64 %6, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ewalk_type"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eframed"(ptr %0, ptr %8, i64 %1, ptr %9, i64 %2)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %7)
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Epaired"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Etyping$24l789" to i64))
  call void @avra_array_push(ptr %2, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 12)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call i64 @avra_array_get(ptr %4, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  %cast = inttoptr i64 %3 to ptr
  %7 = call i1 %cast(ptr %2, i64 %6)
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
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Etyping$24l789"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_expr"(i64 %1, i64 %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}
