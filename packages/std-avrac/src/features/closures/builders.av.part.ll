; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"fn\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [71 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 70 }, [71 x i8] c"defect: a lambda without a span \E2\80\94 the arena and the grammar disagree\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr, ptr, ptr, ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64, i64, i64)

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_type"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuild_fn_type$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuild_fn_type"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuild_lambda$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuild_lambda"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuild_fn_type"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp1 = icmp eq i64 %5, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %6, %then2 ], [ null, %postret5 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi ptr [ %9, %then8 ], [ null, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eanswer"(ptr %0, i64 3)
  %11 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %cmp13 = icmp ne ptr %11, null
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %12, 1
  br label %endif16

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi { i1, i64 } [ %pack, %then14 ], [ zeroinitializer, %else15 ]
  %x = extractvalue { i1, i64 } %regval17, 0
  br i1 %x, label %then18, label %else19

then18:                                           ; preds = %endif16
  %x21 = extractvalue { i1, i64 } %regval17, 1
  br label %endif20

else19:                                           ; preds = %endif16
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval22 = phi i64 [ %x21, %then18 ], [ 0, %else19 ]
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %13, ptr %10)
  %14 = call ptr @avra_array_concat(ptr %regval12, ptr %13)
  %15 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %regval6)
  call void @avra_rc_retain(ptr %regval)
  call void @avra_rc_retain(ptr %regval12)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Eseat_marks"(ptr %regval6, ptr %regval, ptr %regval12, i64 %regval22)
  %17 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %17, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %17, ptr %14)
  call void @avra_array_push(ptr %17, i64 0)
  call void @avra_array_push(ptr %17, i64 0)
  call void @avra_array_push(ptr %17, i64 1)
  call void @avra_array_push_owned(ptr %17, ptr %boxed)
  call void @avra_array_push_owned(ptr %17, ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_type"(ptr %0, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Eseat_marks"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %slot43 = alloca i64, align 8
  %slot42 = alloca i1, align 1
  %slot29 = alloca i64, align 8
  %slot28 = alloca i1, align 1
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  %5 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lexit45, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld63 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld63)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld63

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot2)
  store ptr %6, ptr %slot2, align 8
  %cmp4 = icmp eq i64 %ld3, 0
  br i1 %cmp4, label %then, label %else

then:                                             ; preds = %lbody
  br label %endif

else:                                             ; preds = %lbody
  %sub = sub i64 %ld3, 1
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 %sub)
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 5)
  %cmp5 = icmp ne ptr %8, null
  br i1 %cmp5, label %then6, label %else7

endif:                                            ; preds = %endif11, %then
  %regval14 = phi i64 [ %3, %then ], [ %regval13, %endif11 ]
  %ld15 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %ld15)
  %9 = call ptr @avra_array_get_owned(ptr %ld15, i64 5)
  %cmp16 = icmp ne ptr %9, null
  br i1 %cmp16, label %then17, label %else18

then6:                                            ; preds = %else
  %10 = call i64 @avra_array_get(ptr %8, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %10, 1
  br label %endif8

else7:                                            ; preds = %else
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval = phi { i1, i64 } [ %pack, %then6 ], [ zeroinitializer, %else7 ]
  %x = extractvalue { i1, i64 } %regval, 0
  br i1 %x, label %then9, label %else10

then9:                                            ; preds = %endif8
  %x12 = extractvalue { i1, i64 } %regval, 1
  br label %endif11

else10:                                           ; preds = %endif8
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval13 = phi i64 [ %x12, %then9 ], [ %3, %else10 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

then17:                                           ; preds = %endif
  %11 = call i64 @avra_array_get(ptr %9, i64 0)
  %pack20 = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %11, 1
  br label %endif19

else18:                                           ; preds = %endif
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi { i1, i64 } [ %pack20, %then17 ], [ zeroinitializer, %else18 ]
  %x22 = extractvalue { i1, i64 } %regval21, 0
  br i1 %x22, label %then23, label %else24

then23:                                           ; preds = %endif19
  %x26 = extractvalue { i1, i64 } %regval21, 1
  br label %endif25

else24:                                           ; preds = %endif19
  br label %endif25

endif25:                                          ; preds = %else24, %then23
  %regval27 = phi i64 [ %x26, %then23 ], [ %regval14, %else24 ]
  %12 = call ptr @avra_cell_unique(ptr %slot)
  store i1 false, ptr %slot28, align 8
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuilders$24l115" to i64))
  call void @avra_array_push(ptr %13, i64 %regval14)
  call void @avra_array_push(ptr %13, i64 %regval27)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %15 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot29, align 8
  br label %lhead30

lhead30:                                          ; preds = %endif38, %endif25
  %ld32 = load i64, ptr %slot29, align 8
  %cmp33 = icmp slt i64 %ld32, %15
  br i1 %cmp33, label %lbody34, label %lexit31

lexit31:                                          ; preds = %lhead30
  %ld41 = load i1, ptr %slot28, align 8
  store i1 false, ptr %slot42, align 8
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuilders$24l124" to i64))
  call void @avra_array_push(ptr %16, i64 %regval14)
  call void @avra_array_push(ptr %16, i64 %regval27)
  %17 = call i64 @avra_array_get(ptr %16, i64 0)
  %18 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot43, align 8
  br label %lhead44

lbody34:                                          ; preds = %lhead30
  %ld35 = load i64, ptr %slot29, align 8
  %19 = call i64 @avra_array_get(ptr %0, i64 %ld35)
  %boxed = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %14 to ptr
  %20 = call i1 %cast(ptr %13, ptr %boxed)
  br i1 %20, label %then36, label %else37

then36:                                           ; preds = %lbody34
  store i1 true, ptr %slot28, align 8
  store i64 %15, ptr %slot29, align 8
  br label %endif38

else37:                                           ; preds = %lbody34
  br label %endif38

endif38:                                          ; preds = %else37, %then36
  %regval39 = phi i64 [ 0, %then36 ], [ 0, %else37 ]
  %ld40 = load i64, ptr %slot29, align 8
  %add = add i64 %ld40, 1
  store i64 %add, ptr %slot29, align 8
  br label %lhead30

lhead44:                                          ; preds = %endif54, %lexit31
  %ld46 = load i64, ptr %slot43, align 8
  %cmp47 = icmp slt i64 %ld46, %18
  br i1 %cmp47, label %lbody48, label %lexit45

lexit45:                                          ; preds = %lhead44
  %ld58 = load i1, ptr %slot42, align 8
  %21 = call ptr @avra_array_sized(i64 2)
  %slot59 = zext i1 %ld41 to i64
  call void @avra_array_push(ptr %21, i64 %slot59)
  %slot60 = zext i1 %ld58 to i64
  call void @avra_array_push(ptr %21, i64 %slot60)
  call void @avra_array_push_owned(ptr %12, ptr %21)
  %ld61 = load i64, ptr %slot1, align 8
  %add62 = add i64 %ld61, 1
  store i64 %add62, ptr %slot1, align 8
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %ld15)
  call void @avra_rc_release(ptr %6)
  br label %lhead

lbody48:                                          ; preds = %lhead44
  %ld49 = load i64, ptr %slot43, align 8
  %22 = call i64 @avra_array_get(ptr %1, i64 %ld49)
  %boxed50 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %boxed50)
  %cast51 = inttoptr i64 %17 to ptr
  %23 = call i1 %cast51(ptr %16, ptr %boxed50)
  br i1 %23, label %then52, label %else53

then52:                                           ; preds = %lbody48
  store i1 true, ptr %slot42, align 8
  store i64 %18, ptr %slot43, align 8
  br label %endif54

else53:                                           ; preds = %lbody48
  br label %endif54

endif54:                                          ; preds = %else53, %then52
  %regval55 = phi i64 [ 0, %then52 ], [ 0, %else53 ]
  %ld56 = load i64, ptr %slot43, align 8
  %add57 = add i64 %ld56, 1
  store i64 %add57, ptr %slot43, align 8
  br label %lhead44
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuilders$24l124"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %3, i64 %4, i64 %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %6
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuilders$24l115"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ewithin"(i64 %3, i64 %4, i64 %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %6
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Ebuild_lambda"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr %1

endif:                                            ; preds = %postret, %then
  %regval = phi ptr [ %3, %then ], [ null, %postret ]
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp1 = icmp eq i64 %5, 0
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif

then2:                                            ; preds = %endif
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

endif4:                                           ; preds = %postret5, %then2
  %regval6 = phi ptr [ %6, %then2 ], [ null, %postret5 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etokens"(ptr %0, i64 2)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif4

then8:                                            ; preds = %endif4
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endif10

else9:                                            ; preds = %endif4
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

endif10:                                          ; preds = %postret11, %then8
  %regval12 = phi ptr [ %9, %then8 ], [ null, %postret11 ]
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Eexpr"(ptr %0, i64 4)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp13 = icmp eq i64 %11, 0
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif10

then14:                                           ; preds = %endif10
  %12 = call i64 @avra_array_get(ptr %10, i64 1)
  br label %endif16

else15:                                           ; preds = %endif10
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

endif16:                                          ; preds = %postret17, %then14
  %regval18 = phi i64 [ %12, %then14 ], [ 0, %postret17 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Espan_end"(ptr %0)
  %x = extractvalue { i1, i64 } %13, 0
  %not = xor i1 %x, true
  br i1 %not, label %then19, label %else20

postret17:                                        ; No predecessors!
  br label %endif16

then19:                                           ; preds = %endif16
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 1)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else20:                                           ; preds = %endif16
  br label %endif21

endif21:                                          ; preds = %else20, %postret22
  %regval23 = phi i64 [ 0, %postret22 ], [ 0, %else20 ]
  %15 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %cmp24 = icmp ne ptr %15, null
  br i1 %cmp24, label %then25, label %else26

postret22:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif21

then25:                                           ; preds = %endif21
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %16, 1
  br label %endif27

else26:                                           ; preds = %endif21
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval28 = phi { i1, i64 } [ %pack, %then25 ], [ zeroinitializer, %else26 ]
  %x29 = extractvalue { i1, i64 } %regval28, 0
  br i1 %x29, label %then30, label %else31

then30:                                           ; preds = %endif27
  %x33 = extractvalue { i1, i64 } %regval28, 1
  br label %endif32

else31:                                           ; preds = %endif27
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval34 = phi i64 [ %x33, %then30 ], [ 0, %else31 ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Etype_refs"(ptr %0, i64 3)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  %cmp35 = icmp eq i64 %18, 0
  br i1 %cmp35, label %then36, label %else37

then36:                                           ; preds = %endif32
  %19 = call ptr @avra_array_get_owned(ptr %17, i64 1)
  br label %endif38

else37:                                           ; preds = %endif32
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

endif38:                                          ; preds = %postret39, %then36
  %regval40 = phi ptr [ %19, %then36 ], [ null, %postret39 ]
  %x41 = extractvalue { i1, i64 } %13, 0
  %x42 = extractvalue { i1, i64 } %13, 1
  %slot = zext i1 %x41 to i64
  %20 = call i64 @avra_insist_scalar(i64 %slot, i64 %x42)
  call void @avra_rc_retain(ptr %regval12)
  call void @avra_rc_retain(ptr %regval40)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ealigned_param_types"(ptr %regval12, ptr %regval40, i64 %20)
  call void @avra_rc_retain(ptr %regval12)
  call void @avra_rc_retain(ptr %21)
  call void @avra_rc_retain(ptr %regval6)
  call void @avra_rc_retain(ptr %regval)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emarked_seats"(ptr %regval12, ptr %21, ptr %regval6, ptr %regval, i64 %regval34)
  %23 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %23, i64 24)
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_array_push(ptr %23, i64 %regval18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilder$2Emake_expr"(ptr %0, ptr %23)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %regval40)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %regval6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %24

postret39:                                        ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endif38
}
