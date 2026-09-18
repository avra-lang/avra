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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eis_flat"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Erides_pointer"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eflat_fields"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24114"(i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EMetaHeap$2Eslots"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Evariants_of_type"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslot_of"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %3)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp = icmp eq i64 %7, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %8, label %arm2 [
    i64 0, label %arm
  ]

else:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp3 = icmp eq i64 %9, 1
  br i1 %cmp3, label %then4, label %else5

endif:                                            ; preds = %endif6, %endswitch
  %regval75 = phi ptr [ %regval, %endswitch ], [ %regval74, %endif6 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval75

arm:                                              ; preds = %then
  %10 = call i64 @avra_array_get(ptr %1, i64 1)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push(ptr %11, i64 %10)
  br label %endswitch

arm2:                                             ; preds = %then
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval = phi ptr [ %11, %arm ], [ null, %arm2 ]
  br label %endif

then4:                                            ; preds = %else
  %12 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %12, label %arm8 [
    i64 1, label %arm7
  ]

else5:                                            ; preds = %else
  %13 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp11 = icmp eq i64 %13, 2
  br i1 %cmp11, label %then12, label %else13

endif6:                                           ; preds = %endif14, %endswitch9
  %regval74 = phi ptr [ %regval10, %endswitch9 ], [ %regval73, %endif14 ]
  br label %endif

arm7:                                             ; preds = %then4
  %14 = call i64 @avra_array_get(ptr %1, i64 1)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 1)
  call void @avra_array_push(ptr %15, i64 %14)
  br label %endswitch9

arm8:                                             ; preds = %then4
  br label %endswitch9

endswitch9:                                       ; preds = %arm8, %arm7
  %regval10 = phi ptr [ %15, %arm7 ], [ null, %arm8 ]
  br label %endif6

then12:                                           ; preds = %else5
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %16, label %arm16 [
    i64 3, label %arm15
  ]

else13:                                           ; preds = %else5
  %17 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp19 = icmp eq i64 %17, 3
  br i1 %cmp19, label %then20, label %else21

endif14:                                          ; preds = %endif22, %endswitch17
  %regval73 = phi ptr [ %regval18, %endswitch17 ], [ %regval72, %endif22 ]
  br label %endif6

arm15:                                            ; preds = %then12
  %18 = call i64 @avra_array_get(ptr %1, i64 1)
  %b = icmp ne i64 %18, 0
  %19 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %19, i64 2)
  %slot = zext i1 %b to i64
  call void @avra_array_push(ptr %19, i64 %slot)
  br label %endswitch17

arm16:                                            ; preds = %then12
  br label %endswitch17

endswitch17:                                      ; preds = %arm16, %arm15
  %regval18 = phi ptr [ %19, %arm15 ], [ null, %arm16 ]
  br label %endif14

then20:                                           ; preds = %else13
  %20 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %20, label %arm24 [
    i64 2, label %arm23
  ]

else21:                                           ; preds = %else13
  %21 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp28 = icmp eq i64 %21, 16
  br i1 %cmp28, label %then29, label %else30

endif22:                                          ; preds = %endif31, %endswitch25
  %regval72 = phi ptr [ %regval27, %endswitch25 ], [ %regval71, %endif31 ]
  br label %endif14

arm23:                                            ; preds = %then20
  %22 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed26 = inttoptr i64 %22 to ptr
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 3)
  call void @avra_array_push_owned(ptr %23, ptr %boxed26)
  br label %endswitch25

arm24:                                            ; preds = %then20
  br label %endswitch25

endswitch25:                                      ; preds = %arm24, %arm23
  %regval27 = phi ptr [ %23, %arm23 ], [ null, %arm24 ]
  br label %endif22

then29:                                           ; preds = %else21
  %24 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed32 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed32)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eoptional_slot"(ptr %0, ptr %1, ptr %2, ptr %boxed32)
  br label %endif31

else30:                                           ; preds = %else21
  %26 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp33 = icmp eq i64 %26, 10
  br i1 %cmp33, label %then34, label %else35

endif31:                                          ; preds = %endif36, %then29
  %regval71 = phi ptr [ %25, %then29 ], [ %regval70, %endif36 ]
  br label %endif22

then34:                                           ; preds = %else30
  %27 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed37 = inttoptr i64 %27 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed37)
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Elist_slot"(ptr %0, ptr %1, ptr %2, ptr %boxed37)
  br label %endif36

else35:                                           ; preds = %else30
  %29 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp38 = icmp eq i64 %29, 12
  br i1 %cmp38, label %then39, label %else40

endif36:                                          ; preds = %endif41, %then34
  %regval70 = phi ptr [ %28, %then34 ], [ %regval69, %endif41 ]
  br label %endif31

then39:                                           ; preds = %else35
  %30 = call i64 @avra_array_get(ptr %6, i64 2)
  %boxed42 = inttoptr i64 %30 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed42)
  %31 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Etable_slot"(ptr %0, ptr %1, ptr %2, ptr %boxed42)
  br label %endif41

else40:                                           ; preds = %else35
  %32 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp43 = icmp eq i64 %32, 6
  br i1 %cmp43, label %then44, label %else45

endif41:                                          ; preds = %endif46, %then39
  %regval69 = phi ptr [ %31, %then39 ], [ %regval68, %endif46 ]
  br label %endif36

then44:                                           ; preds = %else40
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Erecord_slot"(ptr %0, ptr %1, ptr %2, ptr %3)
  br label %endif46

else45:                                           ; preds = %else40
  %34 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp47 = icmp eq i64 %34, 7
  br i1 %cmp47, label %then48, label %else49

endif46:                                          ; preds = %endif55, %then44
  %regval68 = phi ptr [ %33, %then44 ], [ %regval67, %endif55 ]
  br label %endif41

then48:                                           ; preds = %else45
  br label %endif50

else49:                                           ; preds = %else45
  %35 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp51 = icmp eq i64 %35, 13
  br label %endif50

endif50:                                          ; preds = %else49, %then48
  %regval52 = phi i1 [ true, %then48 ], [ %cmp51, %else49 ]
  br i1 %regval52, label %then53, label %else54

then53:                                           ; preds = %endif50
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %36 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Evariant_slot"(ptr %0, ptr %1, ptr %2, ptr %3)
  br label %endif55

else54:                                           ; preds = %endif50
  %37 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp56 = icmp eq i64 %37, 8
  br i1 %cmp56, label %then57, label %else58

endif55:                                          ; preds = %endif59, %then53
  %regval67 = phi ptr [ %36, %then53 ], [ %regval66, %endif59 ]
  br label %endif46

then57:                                           ; preds = %else54
  %38 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed60 = inttoptr i64 %38 to ptr
  call void @avra_rc_retain(ptr %boxed60)
  call void @avra_rc_retain(ptr %3)
  %39 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %boxed60, ptr %3)
  %cmp61 = icmp ne ptr %39, null
  br i1 %cmp61, label %then62, label %else63

else58:                                           ; preds = %else54
  br label %endif59

endif59:                                          ; preds = %else58, %endif64
  %regval66 = phi ptr [ %regval65, %endif64 ], [ null, %else58 ]
  br label %endif55

then62:                                           ; preds = %then57
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %40 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Erecord_slot"(ptr %0, ptr %1, ptr %2, ptr %3)
  br label %endif64

else63:                                           ; preds = %then57
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %41 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Evariant_slot"(ptr %0, ptr %1, ptr %2, ptr %3)
  br label %endif64

endif64:                                          ; preds = %else63, %then62
  %regval65 = phi ptr [ %40, %then62 ], [ %41, %else63 ]
  call void @avra_rc_release(ptr %39)
  br label %endif59
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Evariant_slot"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Evariants_of_type"(ptr %boxed, ptr %3)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EMetaHeap$2Eslots"(ptr %2, ptr %1)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %7 = call i64 @avra_array_len(ptr %6)
  %cmp1 = icmp eq i64 %7, 0
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %8 = call ptr @avra_insist(ptr %5)
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  switch i64 %10, label %arm6 [
    i64 0, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif4

arm:                                              ; preds = %endif4
  %11 = call i64 @avra_array_get(ptr %9, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %11, 1
  br label %endswitch

arm6:                                             ; preds = %endif4
  br label %endswitch

endswitch:                                        ; preds = %arm6, %arm
  %regval7 = phi { i1, i64 } [ %pack, %arm ], [ zeroinitializer, %arm6 ]
  %x = extractvalue { i1, i64 } %regval7, 0
  %not8 = xor i1 %x, true
  br i1 %not8, label %then9, label %else10

then9:                                            ; preds = %endswitch
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else10:                                           ; preds = %endswitch
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  %x14 = extractvalue { i1, i64 } %regval7, 0
  %x15 = extractvalue { i1, i64 } %regval7, 1
  %slot = zext i1 %x14 to i64
  %12 = call i64 @avra_insist_scalar(i64 %slot, i64 %x15)
  %cmp16 = icmp slt i64 %12, 0
  br i1 %cmp16, label %then17, label %else18

postret12:                                        ; No predecessors!
  br label %endif11

then17:                                           ; preds = %endif11
  br label %endif19

else18:                                           ; preds = %endif11
  %13 = call i64 @avra_array_get(ptr %8, i64 1)
  %boxed20 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_len(ptr %boxed20)
  %cmp21 = icmp sge i64 %12, %14
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval22 = phi i1 [ true, %then17 ], [ %cmp21, %else18 ]
  br i1 %regval22, label %then23, label %else24

then23:                                           ; preds = %endif19
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else24:                                           ; preds = %endif19
  br label %endif25

endif25:                                          ; preds = %else24, %postret26
  %regval27 = phi i64 [ 0, %postret26 ], [ 0, %else24 ]
  %15 = call i64 @avra_array_len(ptr %6)
  %16 = call ptr @avra_array_slice(ptr %6, i64 1, i64 %15)
  %17 = call i64 @avra_array_get(ptr %8, i64 1)
  %boxed28 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %boxed28, i64 %12)
  %boxed29 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed29)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslots_of"(ptr %0, ptr %16, ptr %2, ptr %boxed29)
  %cmp30 = icmp ne ptr %19, null
  %not31 = xor i1 %cmp30, true
  br i1 %not31, label %then32, label %else33

postret26:                                        ; No predecessors!
  br label %endif25

then32:                                           ; preds = %endif25
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else33:                                           ; preds = %endif25
  br label %endif34

endif34:                                          ; preds = %else33, %postret35
  %regval36 = phi i64 [ 0, %postret35 ], [ 0, %else33 ]
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %20, i64 0)
  call void @avra_array_push(ptr %20, i64 %12)
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %21, ptr %20)
  %22 = call ptr @avra_insist(ptr %19)
  %23 = call ptr @avra_array_concat(ptr %21, ptr %22)
  %24 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %24, i64 0)
  call void @avra_array_push_owned(ptr %24, ptr %23)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %24)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Epushed"(ptr %0, ptr %24)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %25

postret35:                                        ; No predecessors!
  br label %endif34
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Epushed"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_slot_unique(ptr %0, i64 1)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %sub = sub i64 %4, 1
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 4)
  call void @avra_array_push(ptr %5, i64 %sub)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslots_of"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %4 = call i64 @avra_array_len(ptr %1)
  %5 = call i64 @avra_array_len(ptr %3)
  %cmp = icmp ne i64 %4, %5
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
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
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %endif9, %endif
  %ld = load i64, ptr %slot1, align 8
  %cmp3 = icmp slt i64 %ld, %7
  br i1 %cmp3, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld13 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld13)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld13

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot1, align 8
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 %ld4)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot2)
  store ptr %8, ptr %slot2, align 8
  %ld5 = load ptr, ptr %slot2, align 8
  %9 = call i64 @avra_array_get(ptr %3, i64 %ld4)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslot_of"(ptr %0, ptr %ld5, ptr %2, ptr %boxed)
  %cmp6 = icmp ne ptr %10, null
  %not = xor i1 %cmp6, true
  br i1 %not, label %then7, label %else8

then7:                                            ; preds = %lbody
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else8:                                            ; preds = %lbody
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  %11 = call ptr @avra_cell_unique(ptr %slot)
  %12 = call ptr @avra_insist(ptr %10)
  call void @avra_array_push_owned(ptr %11, ptr %12)
  %ld12 = load i64, ptr %slot1, align 8
  %add = add i64 %ld12, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  br label %lhead

postret10:                                        ; No predecessors!
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Erecord_slot"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %6 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eis_flat"(ptr %boxed1, ptr %3)
  br i1 %6, label %then, label %else

then:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %3)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eflat_fields"(ptr %boxed3, ptr %3)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed4 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed4)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslot_of"(ptr %0, ptr %1, ptr %2, ptr %boxed4)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed5 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %3)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efields_of_type"(ptr %boxed5, ptr %3)
  %cmp = icmp ne ptr %13, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then6, label %else7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  br label %endif

then6:                                            ; preds = %endif
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else7:                                            ; preds = %endif
  br label %endif8

endif8:                                           ; preds = %else7, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else7 ]
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EMetaHeap$2Eslots"(ptr %2, ptr %1)
  %15 = call ptr @avra_insist(ptr %13)
  %16 = call i64 @avra_array_get(ptr %15, i64 1)
  %boxed11 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed11)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Earray_slot"(ptr %0, ptr %14, ptr %2, ptr %boxed11)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

postret9:                                         ; No predecessors!
  br label %endif8
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Earray_slot"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslots_of"(ptr %0, ptr %1, ptr %2, ptr %3)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
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
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 0)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Epushed"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Etable_slot"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %4, label %arm1 [
    i64 6, label %arm
  ]

arm:                                              ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %5, 1
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi { i1, i64 } [ %pack, %arm ], [ zeroinitializer, %arm1 ]
  %x = extractvalue { i1, i64 } %regval, 0
  %not = xor i1 %x, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %endswitch
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %endswitch
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval2 = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %x3 = extractvalue { i1, i64 } %regval, 0
  %x4 = extractvalue { i1, i64 } %regval, 1
  %slot = zext i1 %x3 to i64
  %7 = call i64 @avra_insist_scalar(i64 %slot, i64 %x4)
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 %7)
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  %10 = call i64 @avra_array_get(ptr %8, i64 1)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_len(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24114"(i64 %11, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslots_of"(ptr %0, ptr %9, ptr %2, ptr %12)
  %cmp = icmp ne ptr %13, null
  %not5 = xor i1 %cmp, true
  br i1 %not5, label %then6, label %else7

postret:                                          ; No predecessors!
  br label %endif

then6:                                            ; preds = %endif
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else7:                                            ; preds = %endif
  br label %endif8

endif8:                                           ; preds = %else7, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else7 ]
  %14 = call i64 @avra_array_get(ptr %8, i64 0)
  %boxed11 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_insist(ptr %13)
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 1)
  call void @avra_array_push_owned(ptr %16, ptr %boxed11)
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Epushed"(ptr %0, ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

postret9:                                         ; No predecessors!
  br label %endif8
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Elist_slot"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EMetaHeap$2Eslots"(ptr %2, ptr %1)
  %5 = call i64 @avra_array_len(ptr %4)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24114"(i64 %5, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Earray_slot"(ptr %0, ptr %4, ptr %2, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eoptional_slot"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %4, 4
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %8 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Erides_pointer"(ptr %boxed1, ptr %3)
  br i1 %8, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eslot_of"(ptr %0, ptr %1, ptr %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed7 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed7, i64 0)
  %boxed8 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  call void @avra_rc_retain(ptr %3)
  %12 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eis_flat"(ptr %boxed8, ptr %3)
  br i1 %12, label %then9, label %else10

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif4

then9:                                            ; preds = %endif4
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EMetaHeap$2Eslots"(ptr %2, ptr %1)
  %14 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %14, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Earray_slot"(ptr %0, ptr %13, ptr %2, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

else10:                                           ; preds = %endif4
  br label %endif11

endif11:                                          ; preds = %else10, %postret12
  %regval13 = phi i64 [ 0, %postret12 ], [ 0, %else10 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

postret12:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  br label %endif11
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2EStaticBuild$2Eboxes"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}
