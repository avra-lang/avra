; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"this binding\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edeclared_binding"(ptr, i64, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_void_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Echeck_let"(ptr %0, i64 %1) {
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
  call void @avra_rc_retain(ptr %0)
  %7 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Erefuses_void_value"(ptr %0, i64 %6)
  br i1 %7, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed7 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed7, i64 1)
  %boxed8 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %boxed8, i64 %1)
  %cmp9 = icmp ne ptr %10, null
  %not10 = xor i1 %cmp9, true
  br i1 %not10, label %then11, label %else12

postret5:                                         ; No predecessors!
  br label %endif4

then11:                                           ; preds = %endif4
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else12:                                           ; preds = %endif4
  br label %endif13

endif13:                                          ; preds = %else12, %postret14
  %regval15 = phi i64 [ 0, %postret14 ], [ 0, %else12 ]
  %11 = call ptr @avra_insist(ptr %4)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed16 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed16, i64 1)
  %boxed17 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed17)
  %15 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %boxed17, i64 %1)
  %cmp18 = icmp ne ptr %15, null
  br i1 %cmp18, label %then19, label %else20

postret14:                                        ; No predecessors!
  br label %endif13

then19:                                           ; preds = %endif13
  call void @avra_rc_retain(ptr %15)
  br label %endif21

else20:                                           ; preds = %endif13
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval22 = phi ptr [ %15, %then19 ], [ getelementptr inbounds (i8, ptr @.str, i64 16), %else20 ]
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edef_type"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval22)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Edeclared_binding"(ptr %0, i64 %12, ptr %regval22, ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval22)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %17
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Eplant_let"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Ebinding_ty"(ptr %boxed1, i64 %1)
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
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Ebind_declared"(ptr %0, i64 %1, ptr %5)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed3, i64 %1)
  %cmp4 = icmp ne ptr %9, null
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  %10 = call ptr @avra_insist(ptr %9)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ETypeCx$2Eplant_want"(ptr %0, i64 %11, ptr %6)
  call void @avra_rc_release(ptr %10)
  br label %endif7

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}
