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

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 5
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp1 = icmp eq i64 %3, 0
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp5 = icmp eq i64 %4, 1
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp10 = icmp eq i64 %5, 4
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp15 = icmp eq i64 %6, 2
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp20 = icmp eq i64 %7, 3
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi i1 [ true, %then17 ], [ %cmp20, %else18 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif19
  br label %endif24

else23:                                           ; preds = %endif19
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp25 = icmp eq i64 %8, 6
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br i1 %regval26, label %then27, label %else28

then27:                                           ; preds = %endif24
  br label %endif29

else28:                                           ; preds = %endif24
  %9 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp30 = icmp eq i64 %9, 7
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval31 = phi i1 [ true, %then27 ], [ %cmp30, %else28 ]
  br i1 %regval31, label %then32, label %else33

then32:                                           ; preds = %endif29
  br label %endif34

else33:                                           ; preds = %endif29
  %10 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp35 = icmp eq i64 %10, 9
  br label %endif34

endif34:                                          ; preds = %else33, %then32
  %regval36 = phi i1 [ true, %then32 ], [ %cmp35, %else33 ]
  br i1 %regval36, label %then37, label %else38

then37:                                           ; preds = %endif34
  br label %endif39

else38:                                           ; preds = %endif34
  %11 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp40 = icmp eq i64 %11, 13
  br label %endif39

endif39:                                          ; preds = %else38, %then37
  %regval41 = phi i1 [ true, %then37 ], [ %cmp40, %else38 ]
  br i1 %regval41, label %then42, label %else43

then42:                                           ; preds = %endif39
  br label %endif44

else43:                                           ; preds = %endif39
  %12 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp45 = icmp eq i64 %12, 8
  br label %endif44

endif44:                                          ; preds = %else43, %then42
  %regval46 = phi i1 [ true, %then42 ], [ %cmp45, %else43 ]
  br i1 %regval46, label %then47, label %else48

then47:                                           ; preds = %endif44
  br label %endif49

else48:                                           ; preds = %endif44
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp50 = icmp eq i64 %13, 20
  br label %endif49

endif49:                                          ; preds = %else48, %then47
  %regval51 = phi i1 [ true, %then47 ], [ %cmp50, %else48 ]
  br i1 %regval51, label %then52, label %else53

then52:                                           ; preds = %endif49
  br label %endif54

else53:                                           ; preds = %endif49
  %14 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp55 = icmp eq i64 %14, 10
  br label %endif54

endif54:                                          ; preds = %else53, %then52
  %regval56 = phi i1 [ true, %then52 ], [ %cmp55, %else53 ]
  br i1 %regval56, label %then57, label %else58

then57:                                           ; preds = %endif54
  br label %endif59

else58:                                           ; preds = %endif54
  %15 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp60 = icmp eq i64 %15, 11
  br label %endif59

endif59:                                          ; preds = %else58, %then57
  %regval61 = phi i1 [ true, %then57 ], [ %cmp60, %else58 ]
  br i1 %regval61, label %then62, label %else63

then62:                                           ; preds = %endif59
  br label %endif64

else63:                                           ; preds = %endif59
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp65 = icmp eq i64 %16, 21
  br label %endif64

endif64:                                          ; preds = %else63, %then62
  %regval66 = phi i1 [ true, %then62 ], [ %cmp65, %else63 ]
  br i1 %regval66, label %then67, label %else68

then67:                                           ; preds = %endif64
  br label %endif69

else68:                                           ; preds = %endif64
  %17 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp70 = icmp eq i64 %17, 14
  br label %endif69

endif69:                                          ; preds = %else68, %then67
  %regval71 = phi i1 [ true, %then67 ], [ %cmp70, %else68 ]
  br i1 %regval71, label %then72, label %else73

then72:                                           ; preds = %endif69
  br label %endif74

else73:                                           ; preds = %endif69
  %18 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp75 = icmp eq i64 %18, 12
  br label %endif74

endif74:                                          ; preds = %else73, %then72
  %regval76 = phi i1 [ true, %then72 ], [ %cmp75, %else73 ]
  br i1 %regval76, label %then77, label %else78

then77:                                           ; preds = %endif74
  br label %endif79

else78:                                           ; preds = %endif74
  %19 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp80 = icmp eq i64 %19, 16
  br i1 %cmp80, label %then81, label %else82

endif79:                                          ; preds = %endif83, %then77
  %regval89 = phi i1 [ true, %then77 ], [ %regval88, %endif83 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval89

then81:                                           ; preds = %else78
  %20 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eopt_rides_pointer"(ptr %0, ptr %20)
  br i1 %21, label %then84, label %else85

else82:                                           ; preds = %else78
  br label %endif83

endif83:                                          ; preds = %else82, %endif86
  %regval88 = phi i1 [ %regval87, %endif86 ], [ false, %else82 ]
  br label %endif79

then84:                                           ; preds = %then81
  br label %endif86

else85:                                           ; preds = %then81
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %22 = call i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eabstract_yet"(ptr %0, ptr %20)
  br label %endif86

endif86:                                          ; preds = %else85, %then84
  %regval87 = phi i1 [ true, %then84 ], [ %22, %else85 ]
  call void @avra_rc_release(ptr %20)
  br label %endif83
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eabstract_yet"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eopt_rides_pointer"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24255"(i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebound_closed"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 %ld1)
  %cmp2 = icmp ne ptr %5, null
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %5)
  br label %endif

else:                                             ; preds = %lbody
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_array_push_owned(ptr %2, ptr %regval)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eunpinned_of"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot1)
  store ptr %3, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 %ld2)
  %boxed3 = inttoptr i64 %5 to ptr
  %cmp4 = icmp ne ptr %boxed3, null
  %not = xor i1 %cmp4, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  %ld5 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld5

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %3)
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %ld5)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ebound_args"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 %ld1)
  %cmp2 = icmp ne ptr %5, null
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %5)
  br label %endif

else:                                             ; preds = %lbody
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  call void @avra_array_push_owned(ptr %2, ptr %regval)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %slot36 = alloca i64, align 8
  %slot35 = alloca i1, align 1
  %slot25 = alloca i64, align 8
  %slot = alloca i1, align 1
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %1)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm10 [
    i64 21, label %arm
    i64 10, label %arm2
    i64 11, label %arm3
    i64 12, label %arm4
    i64 19, label %arm5
    i64 16, label %arm6
    i64 13, label %arm7
    i64 8, label %arm8
    i64 14, label %arm9
  ]

arm:                                              ; preds = %entry
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %9 = call i64 @avra_array_get(ptr %6, i64 2)
  %10 = call i64 @avra_array_get(ptr %8, i64 0)
  %11 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %10, %11
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  %12 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed14 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %boxed14, ptr %2, ptr %3)
  br label %endswitch

arm3:                                             ; preds = %entry
  %14 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed15 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed15)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %boxed15, ptr %2, ptr %3)
  br label %endswitch

arm4:                                             ; preds = %entry
  %16 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %17 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %18 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %16, ptr %2, ptr %3)
  br i1 %18, label %then16, label %else17

arm5:                                             ; preds = %entry
  br label %endswitch

arm6:                                             ; preds = %entry
  %19 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed20 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed20)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %20 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %boxed20, ptr %2, ptr %3)
  br label %endswitch

arm7:                                             ; preds = %entry
  %21 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %22 = call ptr @avra_array_get_owned(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %23 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %21, ptr %2, ptr %3)
  br i1 %23, label %then21, label %else22

arm8:                                             ; preds = %entry
  %24 = call ptr @avra_array_get_owned(ptr %6, i64 3)
  store i1 true, ptr %slot, align 8
  %25 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eunify$24l391" to i64))
  call void @avra_array_push_owned(ptr %25, ptr %0)
  call void @avra_array_push_owned(ptr %25, ptr %2)
  call void @avra_array_push_owned(ptr %25, ptr %3)
  %26 = call i64 @avra_array_get(ptr %25, i64 0)
  %27 = call i64 @avra_array_len(ptr %24)
  store i64 0, ptr %slot25, align 8
  br label %lhead

arm9:                                             ; preds = %entry
  %28 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %29 = call ptr @avra_array_get_owned(ptr %6, i64 3)
  store i1 true, ptr %slot35, align 8
  %30 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %30, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eunify$24l399" to i64))
  call void @avra_array_push_owned(ptr %30, ptr %0)
  call void @avra_array_push_owned(ptr %30, ptr %2)
  call void @avra_array_push_owned(ptr %30, ptr %3)
  %31 = call i64 @avra_array_get(ptr %30, i64 0)
  %32 = call i64 @avra_array_len(ptr %28)
  store i64 0, ptr %slot36, align 8
  br label %lhead37

arm10:                                            ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm10, %endif55, %lexit, %endif23, %arm6, %arm5, %endif18, %arm3, %arm2, %endif
  %regval57 = phi i1 [ %regval, %endif ], [ %13, %arm2 ], [ %15, %arm3 ], [ %regval19, %endif18 ], [ true, %arm5 ], [ %20, %arm6 ], [ %regval24, %endif23 ], [ %ld34, %lexit ], [ %regval56, %endif55 ], [ true, %arm10 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval57

then:                                             ; preds = %arm
  %33 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed11 = inttoptr i64 %33 to ptr
  %34 = call i64 @avra_array_get(ptr %boxed11, i64 %9)
  %boxed12 = inttoptr i64 %34 to ptr
  %cmp13 = icmp ne ptr %boxed12, null
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp13, %then ], [ true, %else ]
  call void @avra_rc_release(ptr %8)
  br label %endswitch

then16:                                           ; preds = %arm4
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %35 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %17, ptr %2, ptr %3)
  br label %endif18

else17:                                           ; preds = %arm4
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval19 = phi i1 [ %35, %then16 ], [ false, %else17 ]
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  br label %endswitch

then21:                                           ; preds = %arm7
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %36 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %22, ptr %2, ptr %3)
  br label %endif23

else22:                                           ; preds = %arm7
  br label %endif23

endif23:                                          ; preds = %else22, %then21
  %regval24 = phi i1 [ %36, %then21 ], [ false, %else22 ]
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  br label %endswitch

lhead:                                            ; preds = %endif31, %arm8
  %ld = load i64, ptr %slot25, align 8
  %cmp26 = icmp slt i64 %ld, %27
  br i1 %cmp26, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld34 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld27 = load i64, ptr %slot25, align 8
  %37 = call i64 @avra_array_get(ptr %24, i64 %ld27)
  %boxed28 = inttoptr i64 %37 to ptr
  call void @avra_rc_retain(ptr %25)
  call void @avra_rc_retain(ptr %boxed28)
  %cast = inttoptr i64 %26 to ptr
  %38 = call i1 %cast(ptr %25, ptr %boxed28)
  %not = xor i1 %38, true
  br i1 %not, label %then29, label %else30

then29:                                           ; preds = %lbody
  store i1 false, ptr %slot, align 8
  store i64 %27, ptr %slot25, align 8
  br label %endif31

else30:                                           ; preds = %lbody
  br label %endif31

endif31:                                          ; preds = %else30, %then29
  %regval32 = phi i64 [ 0, %then29 ], [ 0, %else30 ]
  %ld33 = load i64, ptr %slot25, align 8
  %add = add i64 %ld33, 1
  store i64 %add, ptr %slot25, align 8
  br label %lhead

lhead37:                                          ; preds = %endif48, %arm9
  %ld39 = load i64, ptr %slot36, align 8
  %cmp40 = icmp slt i64 %ld39, %32
  br i1 %cmp40, label %lbody41, label %lexit38

lexit38:                                          ; preds = %lhead37
  %ld52 = load i1, ptr %slot35, align 8
  br i1 %ld52, label %then53, label %else54

lbody41:                                          ; preds = %lhead37
  %ld42 = load i64, ptr %slot36, align 8
  %39 = call i64 @avra_array_get(ptr %28, i64 %ld42)
  %boxed43 = inttoptr i64 %39 to ptr
  call void @avra_rc_retain(ptr %30)
  call void @avra_rc_retain(ptr %boxed43)
  %cast44 = inttoptr i64 %31 to ptr
  %40 = call i1 %cast44(ptr %30, ptr %boxed43)
  %not45 = xor i1 %40, true
  br i1 %not45, label %then46, label %else47

then46:                                           ; preds = %lbody41
  store i1 false, ptr %slot35, align 8
  store i64 %32, ptr %slot36, align 8
  br label %endif48

else47:                                           ; preds = %lbody41
  br label %endif48

endif48:                                          ; preds = %else47, %then46
  %regval49 = phi i64 [ 0, %then46 ], [ 0, %else47 ]
  %ld50 = load i64, ptr %slot36, align 8
  %add51 = add i64 %ld50, 1
  store i64 %add51, ptr %slot36, align 8
  br label %lhead37

then53:                                           ; preds = %lexit38
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %29)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %41 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %0, ptr %29, ptr %2, ptr %3)
  br label %endif55

else54:                                           ; preds = %lexit38
  br label %endif55

endif55:                                          ; preds = %else54, %then53
  %regval56 = phi i1 [ %41, %then53 ], [ false, %else54 ]
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eunify$24l399"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %2, ptr %1, ptr %3, ptr %boxed)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %5
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eunify$24l391"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efully_bound"(ptr %2, ptr %1, ptr %3, ptr %boxed)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %5
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %2)
  br i1 %5, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %1)
  br i1 %6, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed6 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %1)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed6, ptr %1)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  switch i64 %10, label %arm14 [
    i64 21, label %arm
    i64 10, label %arm7
    i64 11, label %arm8
    i64 12, label %arm9
    i64 16, label %arm10
    i64 13, label %arm11
    i64 8, label %arm12
    i64 14, label %arm13
  ]

postret4:                                         ; No predecessors!
  br label %endif3

arm:                                              ; preds = %endif3
  %11 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  %12 = call i64 @avra_array_get(ptr %9, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evar_binds"(ptr %0, ptr %11, i64 %12, ptr %2, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %11)
  br label %endswitch

arm7:                                             ; preds = %endif3
  %14 = call i64 @avra_array_get(ptr %9, i64 1)
  %boxed15 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed15)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eelem_unifies"(ptr %0, ptr %boxed15, ptr %2, ptr %3, ptr %4)
  br label %endswitch

arm8:                                             ; preds = %endif3
  %16 = call i64 @avra_array_get(ptr %9, i64 1)
  %boxed16 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed16)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %17 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ecell_unifies"(ptr %0, ptr %boxed16, ptr %2, ptr %3, ptr %4)
  br label %endswitch

arm9:                                             ; preds = %endif3
  %18 = call i64 @avra_array_get(ptr %9, i64 2)
  %boxed17 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed17)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evalue_unifies"(ptr %0, ptr %boxed17, ptr %2, ptr %3, ptr %4)
  br label %endswitch

arm10:                                            ; preds = %endif3
  %20 = call i64 @avra_array_get(ptr %9, i64 1)
  %boxed18 = inttoptr i64 %20 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed18)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %21 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ecarried_unifies"(ptr %0, ptr %boxed18, ptr %2, ptr %3, ptr %4)
  br label %endswitch

arm11:                                            ; preds = %endif3
  %22 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  %23 = call i64 @avra_array_get(ptr %9, i64 2)
  %boxed19 = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  call void @avra_rc_retain(ptr %boxed19)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %24 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Esides_unify"(ptr %0, ptr %22, ptr %boxed19, ptr %2, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %22)
  br label %endswitch

arm12:                                            ; preds = %endif3
  %25 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  %26 = call i64 @avra_array_get(ptr %9, i64 3)
  %boxed20 = inttoptr i64 %26 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %25)
  call void @avra_rc_retain(ptr %boxed20)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %27 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eapp_unifies"(ptr %0, ptr %25, ptr %boxed20, ptr %2, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %25)
  br label %endswitch

arm13:                                            ; preds = %endif3
  %28 = call ptr @avra_array_get_owned(ptr %9, i64 1)
  %29 = call i64 @avra_array_get(ptr %9, i64 3)
  %boxed21 = inttoptr i64 %29 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %28)
  call void @avra_rc_retain(ptr %boxed21)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %30 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efn_unifies"(ptr %0, ptr %28, ptr %boxed21, ptr %2, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %28)
  br label %endswitch

arm14:                                            ; preds = %endif3
  %31 = call i64 @avra_array_get(ptr %1, i64 0)
  %32 = call i64 @avra_array_get(ptr %2, i64 0)
  %cmp = icmp eq i64 %31, %32
  br label %endswitch

endswitch:                                        ; preds = %arm14, %arm13, %arm12, %arm11, %arm10, %arm9, %arm8, %arm7, %arm
  %regval22 = phi i1 [ %13, %arm ], [ %15, %arm7 ], [ %17, %arm8 ], [ %19, %arm9 ], [ %21, %arm10 ], [ %24, %arm11 ], [ %27, %arm12 ], [ %30, %arm13 ], [ %cmp, %arm14 ]
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval22
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Efn_unifies"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot9 = alloca ptr, align 8
  store ptr null, ptr %slot9, align 8
  %slot = alloca i64, align 8
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr %boxed1, ptr %3)
  %cmp = icmp ne ptr %8, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_insist(ptr %8)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed2 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_len(ptr %boxed2)
  %12 = call i64 @avra_array_len(ptr %1)
  %cmp3 = icmp ne i64 %11, %12
  br i1 %cmp3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %13 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret7:                                         ; No predecessors!
  br label %endif6

lhead:                                            ; preds = %endif18, %endif6
  %ld = load i64, ptr %slot, align 8
  %cmp10 = icmp slt i64 %ld, %13
  br i1 %cmp10, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %14 = call i64 @avra_array_get(ptr %9, i64 2)
  %boxed22 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed22)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %2, ptr %boxed22, ptr %4, ptr %5)
  call void @avra_cell_release(ptr %slot9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %15

lbody:                                            ; preds = %lhead
  %ld11 = load i64, ptr %slot, align 8
  %16 = call ptr @avra_array_get_owned(ptr %1, i64 %ld11)
  call void @avra_rc_retain(ptr %16)
  call void @avra_cell_release(ptr %slot9)
  store ptr %16, ptr %slot9, align 8
  %ld12 = load ptr, ptr %slot9, align 8
  %17 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed13 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %boxed13, i64 %ld11)
  %boxed14 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld12)
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %ld12, ptr %boxed14, ptr %4, ptr %5)
  %not15 = xor i1 %19, true
  br i1 %not15, label %then16, label %else17

then16:                                           ; preds = %lbody
  call void @avra_cell_release(ptr %slot9)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else17:                                           ; preds = %lbody
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  %ld21 = load i64, ptr %slot, align 8
  %add = add i64 %ld21, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %16)
  br label %lhead

postret19:                                        ; No predecessors!
  br label %endif18
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eapp_unifies"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %3)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  switch i64 %9, label %arm2 [
    i64 8, label %arm
  ]

arm:                                              ; preds = %entry
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  %11 = call ptr @avra_array_get_owned(ptr %8, i64 3)
  %12 = call i64 @avra_array_get(ptr %10, i64 0)
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %12, %13
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif
  %regval3 = phi i1 [ %regval, %endif ], [ false, %arm2 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval3

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Epaired_unify"(ptr %0, ptr %2, ptr %11, ptr %4, ptr %5)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %14, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Epaired_unify"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  %5 = call i64 @avra_array_len(ptr %1)
  %6 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp ne i64 %5, %6
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  store i1 true, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %endif8, %endif
  %ld = load i64, ptr %slot1, align 8
  %cmp3 = icmp slt i64 %ld, %7
  br i1 %cmp3, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld11 = load i1, ptr %slot, align 8
  call void @avra_cell_release(ptr %slot2)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld11

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot1, align 8
  %8 = call ptr @avra_array_get_owned(ptr %1, i64 %ld4)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot2)
  store ptr %8, ptr %slot2, align 8
  %ld5 = load ptr, ptr %slot2, align 8
  %9 = call i64 @avra_array_get(ptr %2, i64 %ld4)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %ld5, ptr %boxed, ptr %3, ptr %4)
  %not = xor i1 %10, true
  br i1 %not, label %then6, label %else7

then6:                                            ; preds = %lbody
  store i1 false, ptr %slot, align 8
  br label %endif8

else7:                                            ; preds = %lbody
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi i64 [ 0, %then6 ], [ 0, %else7 ]
  %ld10 = load i64, ptr %slot1, align 8
  %add = add i64 %ld10, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Esides_unify"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eres_parts"(ptr %boxed1, ptr %3)
  %cmp = icmp ne ptr %8, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_insist(ptr %8)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %11 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %boxed2, ptr %4, ptr %5)
  br i1 %11, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  %12 = call ptr @avra_insist(ptr %8)
  %13 = call i64 @avra_array_get(ptr %12, i64 1)
  %boxed6 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %2, ptr %boxed6, ptr %4, ptr %5)
  call void @avra_rc_release(ptr %12)
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval7 = phi i1 [ %14, %then3 ], [ false, %else4 ]
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval7
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ecarried_unifies"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm3 [
    i64 16, label %arm
    i64 17, label %arm2
  ]

arm:                                              ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %7, i64 1)
  %boxed4 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed4)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %boxed4, ptr %3, ptr %4)
  br label %endswitch

arm2:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed5 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed5, i64 5)
  %boxed6 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %1)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed6, ptr %1)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %cmp = icmp eq i64 %14, 21
  %not = xor i1 %cmp, true
  call void @avra_rc_release(ptr %13)
  br label %endswitch

arm3:                                             ; preds = %entry
  %15 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed7 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %boxed7, i64 5)
  %boxed8 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  call void @avra_rc_retain(ptr %1)
  %17 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed8, ptr %1)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp9 = icmp eq i64 %18, 21
  %not10 = xor i1 %cmp9, true
  br i1 %not10, label %then, label %else

endswitch:                                        ; preds = %endif, %arm2, %arm
  %regval11 = phi i1 [ %10, %arm ], [ %not, %arm2 ], [ %regval, %endif ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval11

then:                                             ; preds = %arm3
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4)
  br label %endif

else:                                             ; preds = %arm3
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %19, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %17)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evalue_unifies"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm3 [
    i64 12, label %arm
    i64 19, label %arm2
  ]

arm:                                              ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %7, i64 2)
  %boxed4 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed4)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %boxed4, ptr %3, ptr %4)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm
  %regval = phi i1 [ %10, %arm ], [ true, %arm2 ], [ false, %arm3 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ecell_unifies"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr %boxed1, ptr %2)
  %cmp = icmp ne ptr %7, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %8 = call ptr @avra_insist(ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %8, ptr %3, ptr %4)
  call void @avra_rc_release(ptr %8)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %9, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eelem_unifies"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm3 [
    i64 10, label %arm
    i64 18, label %arm2
  ]

arm:                                              ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %7, i64 1)
  %boxed4 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed4)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunify"(ptr %0, ptr %1, ptr %boxed4, ptr %3, ptr %4)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm
  %regval = phi i1 [ %10, %arm ], [ true, %arm2 ], [ false, %arm3 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Evar_binds"(ptr %0, ptr %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %7 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp = icmp ne i64 %6, %7
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %3)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp2 = icmp eq i64 %11, 17
  br i1 %cmp2, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed8 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed8, i64 5)
  %boxed9 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed9)
  call void @avra_rc_retain(ptr %3)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed9, ptr %3)
  %15 = call i64 @avra_array_get(ptr %14, i64 0)
  %cmp10 = icmp eq i64 %15, 18
  br i1 %cmp10, label %then11, label %else12

postret6:                                         ; No predecessors!
  br label %endif5

then11:                                           ; preds = %endif5
  br label %endif13

else12:                                           ; preds = %endif5
  %16 = call i64 @avra_array_get(ptr %14, i64 0)
  %cmp14 = icmp eq i64 %16, 19
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i1 [ true, %then11 ], [ %cmp14, %else12 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif13
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else17:                                           ; preds = %endif13
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  %17 = call ptr @avra_array_get_owned(ptr %5, i64 0)
  %18 = call ptr @avra_array_get_owned(ptr %17, i64 %2)
  %cmp21 = icmp ne ptr %18, null
  %not = xor i1 %cmp21, true
  br i1 %not, label %then22, label %else23

postret19:                                        ; No predecessors!
  br label %endif18

then22:                                           ; preds = %endif18
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %3)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EPins$2Epin"(ptr %5, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else23:                                           ; preds = %endif18
  br label %endif24

endif24:                                          ; preds = %else23, %postret25
  %regval26 = phi i64 [ 0, %postret25 ], [ 0, %else23 ]
  %20 = call ptr @avra_insist(ptr %18)
  %21 = call i64 @avra_array_get(ptr %20, i64 0)
  %22 = call i64 @avra_array_get(ptr %3, i64 0)
  %cmp27 = icmp eq i64 %21, %22
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp27

postret25:                                        ; No predecessors!
  br label %endif24
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2EPins$2Epin"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_slot_unique(ptr %0, i64 0)
  call void @avra_slot_set_owned(ptr %3, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_pins"(i64 %0) {
entry:
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$24255"(i64 %0, ptr null)
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_rc_release(ptr %1)
  ret ptr %2
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Etparams_refused"(ptr %0) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot1)
  store ptr %2, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Erepeated_at"(ptr %0, i64 %ld2)
  br i1 %3, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %2)
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Erepeated_at"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 -1, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 %1)
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %cmp5 = icmp slt i64 %ld4, %1
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 %ld2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_streq(ptr %boxed, ptr %2)
  %b = icmp ne i64 %5, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i64 %ld2, ptr %slot, align 8
  store i64 %3, ptr %slot1, align 8
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %1) {
entry:
  %slot14 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm8 [
    i64 13, label %arm
    i64 10, label %arm2
    i64 11, label %arm3
    i64 16, label %arm4
    i64 12, label %arm5
    i64 19, label %arm6
    i64 8, label %arm7
  ]

arm:                                              ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %7 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed9 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %boxed9)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eres_side_unlawful"(ptr %0, ptr %6, ptr %boxed9)
  call void @avra_rc_release(ptr %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed10 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed10)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %boxed10)
  br label %endswitch

arm3:                                             ; preds = %entry
  %11 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed11 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %boxed11)
  br label %endswitch

arm4:                                             ; preds = %entry
  %13 = call i64 @avra_array_get(ptr %4, i64 1)
  %boxed12 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed12)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %boxed12)
  br label %endswitch

arm5:                                             ; preds = %entry
  %15 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed13 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed13)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %boxed13)
  br label %endswitch

arm6:                                             ; preds = %entry
  br label %endswitch

arm7:                                             ; preds = %entry
  %17 = call ptr @avra_array_get_owned(ptr %4, i64 3)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eunify$24l295" to i64))
  call void @avra_array_push_owned(ptr %18, ptr %0)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  %20 = call i64 @avra_array_len(ptr %17)
  store i64 0, ptr %slot14, align 8
  br label %lhead

arm8:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm8, %lexit, %arm6, %arm5, %arm4, %arm3, %arm2, %arm
  %regval18 = phi ptr [ %8, %arm ], [ %10, %arm2 ], [ %12, %arm3 ], [ %14, %arm4 ], [ %16, %arm5 ], [ null, %arm6 ], [ %ld17, %lexit ], [ null, %arm8 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval18

lhead:                                            ; preds = %endif, %arm7
  %ld = load i64, ptr %slot14, align 8
  %cmp = icmp slt i64 %ld, %20
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld17)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %endswitch

lbody:                                            ; preds = %lhead
  %ld15 = load i64, ptr %slot14, align 8
  %21 = call ptr @avra_array_get_owned(ptr %17, i64 %ld15)
  call void @avra_rc_retain(ptr %18)
  call void @avra_rc_retain(ptr %21)
  %cast = inttoptr i64 %19 to ptr
  %22 = call i1 %cast(ptr %18, ptr %21)
  br i1 %22, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %21)
  call void @avra_cell_release(ptr %slot)
  store ptr %21, ptr %slot, align 8
  store i64 %20, ptr %slot14, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld16 = load i64, ptr %slot14, align 8
  %add = add i64 %ld16, 1
  store i64 %add, ptr %slot14, align 8
  call void @avra_rc_release(ptr %21)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eunify$24l295"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %boxed, ptr %1)
  %cmp = icmp ne ptr %3, null
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eres_side_unlawful"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %4 = call i64 @avra_array_get(ptr %3, i64 5)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 5)
  %boxed2 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed2, ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %7)
  %8 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr %boxed, ptr %7)
  %not = xor i1 %8, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %10 = call i64 @avra_array_get(ptr %9, i64 5)
  %boxed3 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed4 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed4, i64 5)
  %boxed5 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %2)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed5, ptr %2)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %13)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr %boxed3, ptr %13)
  %not6 = xor i1 %14, true
  br i1 %not6, label %then7, label %else8

postret:                                          ; No predecessors!
  br label %endif

then7:                                            ; preds = %endif
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %15, null
  br i1 %cmp, label %then12, label %else13

postret10:                                        ; No predecessors!
  br label %endif9

then12:                                           ; preds = %endif9
  call void @avra_rc_retain(ptr %15)
  br label %endif14

else13:                                           ; preds = %endif9
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunlawful_side"(ptr %0, ptr %2)
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi ptr [ %15, %then12 ], [ %16, %else13 ]
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval15
}
