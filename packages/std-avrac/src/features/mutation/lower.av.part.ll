; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"an assignment to a non-place survived a clean analysis\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_slot_set\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Econcrete"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Edeclared_binding"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_slot"(ptr, i64, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Elower_assign"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened_place"(ptr %0, i64 %7)
  %cmp2 = icmp ne ptr %8, null
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %10 = call ptr @avra_insist(ptr %8)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  switch i64 %11, label %arm9 [
    i64 0, label %arm
  ]

postret7:                                         ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif6

arm:                                              ; preds = %endif6
  %12 = call i64 @avra_array_get(ptr %10, i64 1)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 24)
  call void @avra_array_push(ptr %13, i64 %12)
  call void @avra_array_push(ptr %13, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr %13)
  br label %endswitch

arm9:                                             ; preds = %endif6
  %15 = call i64 @avra_array_get(ptr %10, i64 1)
  %16 = call i64 @avra_array_get(ptr %10, i64 2)
  %17 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %17, i64 %15)
  call void @avra_array_push(ptr %17, i64 %16)
  call void @avra_array_push(ptr %17, i64 %2)
  %18 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %18, i64 6)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endswitch

endswitch:                                        ; preds = %arm9, %arm
  %regval10 = phi i64 [ %14, %arm ], [ %19, %arm9 ]
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval10
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened_place"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Elower_mut"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeFacts$2Edeclared_binding"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_like"(ptr %0, i64 %2)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Econcrete"(ptr %0, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %5, %then ], [ %7, %else ]
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 22)
  call void @avra_array_push(ptr %8, i64 %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 24)
  call void @avra_array_push(ptr %10, i64 %regval)
  call void @avra_array_push(ptr %10, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %10)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_slot"(ptr %0, i64 %1, i64 %regval)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_like"(ptr, i64)
