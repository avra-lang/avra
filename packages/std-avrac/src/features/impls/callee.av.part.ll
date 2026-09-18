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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Estands_for"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr, ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Eenum_sig"(ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Edeclared_decl"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emethod_row"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ecallee_of"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estood_over"(ptr %0, ptr %1, ptr %2)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ecallee_of"(ptr %0, ptr %4, ptr %2)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %2)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuiltin_static"(ptr %0, ptr %7, ptr %2)
  %cmp1 = icmp ne ptr %8, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  br label %endif

then2:                                            ; preds = %endif
  %9 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %2)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ethrough_a_contract"(ptr %0, ptr %7, ptr %2)
  %cmp7 = icmp ne ptr %10, null
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif4

then8:                                            ; preds = %endif4
  %11 = call ptr @avra_insist(ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Efn_field"(ptr %0, ptr %1, ptr %2)
  %cmp13 = icmp ne ptr %12, null
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_release(ptr %11)
  br label %endif10

then14:                                           ; preds = %endif10
  %13 = call ptr @avra_insist(ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %14 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed19 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed19, i64 0)
  %boxed20 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %boxed20)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emethod_row"(ptr %boxed20, ptr %2, ptr %7)
  %cmp21 = icmp ne ptr %16, null
  br i1 %cmp21, label %then22, label %else23

postret17:                                        ; No predecessors!
  call void @avra_rc_release(ptr %13)
  br label %endif16

then22:                                           ; preds = %endif16
  %17 = call ptr @avra_insist(ptr %16)
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 5)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

else23:                                           ; preds = %endif16
  br label %endif24

endif24:                                          ; preds = %else23, %postret25
  %regval26 = phi i64 [ 0, %postret25 ], [ 0, %else23 ]
  call void @avra_rc_retain(ptr %7)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Edeclared"(ptr %7)
  %cmp27 = icmp ne ptr %19, null
  br i1 %cmp27, label %then28, label %else29

postret25:                                        ; No predecessors!
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %endif24

then28:                                           ; preds = %endif24
  call void @avra_rc_retain(ptr %19)
  br label %endif30

else29:                                           ; preds = %endif24
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 7)
  br label %endif30

endif30:                                          ; preds = %else29, %then28
  %regval31 = phi ptr [ %19, %then28 ], [ %20, %else29 ]
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval31
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Edeclared"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm3 [
    i64 6, label %arm
    i64 7, label %arm1
    i64 8, label %arm2
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 6)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %boxed)
  call void @avra_rc_release(ptr %2)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed4 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %7, i64 6)
  call void @avra_array_push_owned(ptr %7, ptr %5)
  call void @avra_array_push_owned(ptr %7, ptr %boxed4)
  call void @avra_rc_release(ptr %5)
  br label %endswitch

arm2:                                             ; preds = %entry
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %9 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed5 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 6)
  call void @avra_array_push_owned(ptr %10, ptr %8)
  call void @avra_array_push_owned(ptr %10, ptr %boxed5)
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %7, %arm1 ], [ %10, %arm2 ], [ null, %arm3 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Efn_field"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %boxed, ptr %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %2)
  %6 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EStructSig$2Eslot_of"(ptr %5, ptr %2)
  %x = extractvalue { i1, i64 } %6, 0
  %not1 = xor i1 %x, true
  br i1 %not1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  %x7 = extractvalue { i1, i64 } %6, 0
  %x8 = extractvalue { i1, i64 } %6, 1
  %slot = zext i1 %x7 to i64
  %9 = call i64 @avra_insist_scalar(i64 %slot, i64 %x8)
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 %9)
  %11 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed9 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed9)
  call void @avra_rc_retain(ptr %10)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed9, ptr %10)
  %13 = call i64 @avra_array_get(ptr %12, i64 0)
  %cmp10 = icmp eq i64 %13, 14
  %not11 = xor i1 %cmp10, true
  br i1 %not11, label %then12, label %else13

postret5:                                         ; No predecessors!
  br label %endif4

then12:                                           ; preds = %endif4
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else13:                                           ; preds = %endif4
  br label %endif14

endif14:                                          ; preds = %else13, %postret15
  %regval16 = phi i64 [ 0, %postret15 ], [ 0, %else13 ]
  %x17 = extractvalue { i1, i64 } %6, 0
  %x18 = extractvalue { i1, i64 } %6, 1
  %slot19 = zext i1 %x17 to i64
  %14 = call i64 @avra_insist_scalar(i64 %slot19, i64 %x18)
  %15 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %15, i64 4)
  call void @avra_array_push(ptr %15, i64 %14)
  call void @avra_array_push_owned(ptr %15, ptr %10)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

postret15:                                        ; No predecessors!
  br label %endif14
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ethrough_a_contract"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %3, label %arm3 [
    i64 20, label %arm
    i64 21, label %arm1
    i64 9, label %arm2
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %2)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Etype_receiver"(ptr %0, ptr %4, ptr %boxed, ptr %2)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

arm1:                                             ; preds = %entry
  %7 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %8 = call i64 @avra_array_get(ptr %1, i64 2)
  %9 = call i64 @avra_array_get(ptr %1, i64 3)
  %boxed4 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %10, i64 2)
  call void @avra_array_push_owned(ptr %10, ptr %7)
  call void @avra_array_push(ptr %10, i64 %8)
  call void @avra_array_push_owned(ptr %10, ptr %boxed4)
  call void @avra_rc_release(ptr %7)
  br label %endswitch

arm2:                                             ; preds = %entry
  %11 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %12 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed5 = inttoptr i64 %12 to ptr
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 3)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  call void @avra_array_push_owned(ptr %13, ptr %boxed5)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %6, %arm ], [ %10, %arm1 ], [ %13, %arm2 ], [ null, %arm3 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Etype_receiver"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Enames_a_variant"(ptr %0, ptr %1, ptr %3)
  br i1 %4, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_array_push_owned(ptr %5, ptr %1)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Egrammar_door"(ptr %0, ptr %1, ptr %2, ptr %3)
  %cmp = icmp ne ptr %6, null
  br i1 %cmp, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif

then1:                                            ; preds = %endif
  %7 = call ptr @avra_insist(ptr %6)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 5)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estatic_method"(ptr %0, ptr %1, ptr %3)
  %cmp6 = icmp ne ptr %9, null
  %not = xor i1 %cmp6, true
  br i1 %not, label %then7, label %else8

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif3

then7:                                            ; preds = %endif3
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_array_push_owned(ptr %10, ptr %1)
  call void @avra_array_push_owned(ptr %10, ptr %2)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else8:                                            ; preds = %endif3
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  %11 = call ptr @avra_insist(ptr %9)
  %12 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %12, i64 1)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_array_push_owned(ptr %12, ptr %2)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estatic_method"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %boxed, ptr %1, ptr %2)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %boxed1, ptr %7)
  %9 = call i64 @avra_array_get(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %5)
  %10 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr %5, i64 %9)
  %not2 = xor i1 %10, true
  br i1 %not2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret6:                                         ; No predecessors!
  br label %endif5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Egrammar_door"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Egrammar_of"(ptr %boxed, ptr %1)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 20)
  call void @avra_array_push_owned(ptr %8, ptr %1)
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emethod_row"(ptr %boxed2, ptr %3, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret:                                          ; No predecessors!
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Egrammar_of"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Enames_a_variant"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed, ptr %1)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Eenum_sig"(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ null, %else ]
  %cmp1 = icmp ne ptr %regval, null
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  %6 = call ptr @avra_insist(ptr %regval)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %2)
  %7 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %6, ptr %2)
  %x = extractvalue { i1, i64 } %7, 0
  call void @avra_rc_release(ptr %6)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i1 [ %x, %then2 ], [ false, %else3 ]
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Ebuiltin_static"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %3, label %arm1 [
    i64 20, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %4)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %boxed2, ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 4)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed3, i64 0)
  %cmp = icmp eq i64 %9, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif20
  %regval23 = phi ptr [ %16, %endif20 ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval23

then:                                             ; preds = %arm
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Enames_a_variant"(ptr %0, ptr %4, ptr %2)
  br i1 %10, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  br label %endif6

else5:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estatic_method"(ptr %0, ptr %4, ptr %2)
  %cmp7 = icmp ne ptr %11, null
  call void @avra_rc_release(ptr %11)
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i1 [ true, %then4 ], [ %cmp7, %else5 ]
  br i1 %regval8, label %then9, label %else10

then9:                                            ; preds = %endif6
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else10:                                           ; preds = %endif6
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  %12 = call i64 @avra_array_get(ptr %0, i64 6)
  %boxed14 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed14, i64 0)
  %boxed15 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed15)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emethod_row"(ptr %boxed15, ptr %2, ptr %1)
  %cmp16 = icmp ne ptr %14, null
  %not17 = xor i1 %cmp16, true
  br i1 %not17, label %then18, label %else19

postret12:                                        ; No predecessors!
  br label %endif11

then18:                                           ; preds = %endif11
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else19:                                           ; preds = %endif11
  br label %endif20

endif20:                                          ; preds = %else19, %postret21
  %regval22 = phi i64 [ 0, %postret21 ], [ 0, %else19 ]
  %15 = call ptr @avra_insist(ptr %14)
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 5)
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  br label %endswitch

postret21:                                        ; No predecessors!
  br label %endif20
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Estood_over"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Estands_for"(ptr %boxed, ptr %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %1)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edeclared_decl"(ptr %6)
  %cmp2 = icmp ne ptr %7, null
  br i1 %cmp2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed6 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_insist(ptr %7)
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %2)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %boxed6, ptr %9, ptr %2)
  %cmp7 = icmp ne ptr %10, null
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval8 = phi i1 [ %cmp7, %then3 ], [ false, %else4 ]
  br i1 %regval8, label %then9, label %else10

then9:                                            ; preds = %endif5
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else10:                                           ; preds = %endif5
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret12:                                        ; No predecessors!
  br label %endif11
}
