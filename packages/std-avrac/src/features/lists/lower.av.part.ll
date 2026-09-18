; ModuleID = 'avra'
source_filename = "avra"

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

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elist_reg"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call i64 @avra_array_len(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %5)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %7, i64 %6, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %9 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %9)
  call void @avra_array_push(ptr %3, i64 %10)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_reg"(ptr %0, i64 %1, i64 %2, ptr %3, i64 %4, ptr %5, ptr %6) {
entry:
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %9 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %8, i64 %7, ptr %9)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eelem_type"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopened"(ptr %0, i64 %4, ptr %11)
  call void @avra_rc_release(ptr %11)
  br label %endif

else:                                             ; preds = %entry
  %13 = call i64 @avra_array_get(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %0)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecounted"(ptr %0, i64 %4, i64 %13)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %12, %then ], [ %14, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_open"(ptr %0, ptr %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_index"(ptr %0, ptr %regval)
  %cmp1 = icmp ne ptr %5, null
  %not2 = xor i1 %cmp1, true
  br i1 %not2, label %then3, label %else4

then3:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_elem"(ptr %0, ptr %regval, i64 %16)
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval6 = phi i64 [ %17, %then3 ], [ %16, %else4 ]
  %cmp7 = icmp ne ptr %3, null
  %not8 = xor i1 %cmp7, true
  br i1 %not8, label %then9, label %else10

then9:                                            ; preds = %endif5
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 %regval6)
  br label %endif11

else10:                                           ; preds = %endif5
  %19 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %19, i64 %16)
  call void @avra_array_push(ptr %19, i64 %regval6)
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval12 = phi ptr [ %18, %then9 ], [ %19, %else10 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval12)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %0, i64 %2, ptr %regval12)
  %cmp13 = icmp ne ptr %6, null
  br i1 %cmp13, label %then14, label %else15

then14:                                           ; preds = %endif11
  %21 = call ptr @avra_insist(ptr %6)
  %22 = call i64 @avra_array_get(ptr %21, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval12)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %0, i64 %22, ptr %regval12)
  %24 = call ptr @avra_insist(ptr %6)
  %25 = call i64 @avra_array_get(ptr %24, i64 0)
  call void @avra_rc_retain(ptr %0)
  %26 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %25)
  %27 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower$24l92" to i64))
  call void @avra_array_push(ptr %27, i64 %8)
  call void @avra_array_push(ptr %27, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr %0, i64 %26, ptr %27)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %21)
  br label %endif16

else15:                                           ; preds = %endif11
  call void @avra_rc_retain(ptr %0)
  %29 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %30 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %0, i64 %8, i64 %29)
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi i64 [ 0, %then14 ], [ 0, %else15 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eturn_close"(ptr %0, ptr %regval)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elower$24l92"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %1, i64 %3)
  call void @avra_rc_retain(ptr %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epush_slot"(ptr %1, i64 %2, i64 %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evoid_region"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecounted"(ptr, i64, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eelem_type"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}
