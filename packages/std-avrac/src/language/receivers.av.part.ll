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

declare i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Esettle"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()

declare i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ebegin"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Eask"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24480"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Esig"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2Efp"(i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2Efp_list"(ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2Emut_mark"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Ehas_body"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Estore"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_named"(ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_trait"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eself_type_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etarget_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2415"(i64, i1)

declare i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24921"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Eresolved"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_mark"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Ekey"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2Eordinal"(ptr)

declare i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Efamily_active"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etbounds"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edeclares_writing"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_member"(ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_written_so_far"(ptr, ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_writes_so_far"(ptr, ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Ereceivers"(ptr %0) {
entry:
  %slot39 = alloca i64, align 8
  %slot28 = alloca i64, align 8
  %slot17 = alloca ptr, align 8
  store ptr null, ptr %slot17, align 8
  %slot16 = alloca i64, align 8
  %slot = alloca i64, align 8
  %1 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 5)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eordinal"(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Efamily_active"(ptr %boxed, i64 %3)
  br i1 %4, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 16)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekey"(ptr %5, i64 0)
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed1 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %6)
  %8 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Eask"(ptr %boxed1, ptr %6)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp = icmp eq i64 %9, 1
  %not = xor i1 %cmp, true
  br i1 %not, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %10 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed7 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed7)
  call void @avra_rc_retain(ptr %6)
  %11 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ebegin"(ptr %boxed7, ptr %6)
  %12 = call ptr @avra_array_sized(i64 0)
  %13 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %14 = call ptr @avra_array_get_owned(ptr %13, i64 10)
  %15 = call i64 @avra_array_len(ptr %14)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret5:                                         ; No predecessors!
  br label %endif4

lhead:                                            ; preds = %endif12, %endif4
  %ld = load i64, ptr %slot, align 8
  %cmp8 = icmp slt i64 %ld, %15
  br i1 %cmp8, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %16 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot16, align 8
  br label %lhead18

lbody:                                            ; preds = %lhead
  %ld9 = load i64, ptr %slot, align 8
  %17 = call ptr @avra_array_get_owned(ptr %14, i64 %ld9)
  call void @avra_rc_retain(ptr %17)
  %18 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Eseated"(ptr %17)
  br i1 %18, label %then10, label %else11

then10:                                           ; preds = %lbody
  %19 = call i64 @avra_array_get(ptr %17, i64 0)
  %boxed13 = inttoptr i64 %19 to ptr
  call void @avra_array_push_owned(ptr %12, ptr %boxed13)
  br label %endif12

else11:                                           ; preds = %lbody
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %ld15 = load i64, ptr %slot, align 8
  %add = add i64 %ld15, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %17)
  br label %lhead

lhead18:                                          ; preds = %lbody22, %lexit
  %ld20 = load i64, ptr %slot16, align 8
  %cmp21 = icmp slt i64 %ld20, %16
  br i1 %cmp21, label %lbody22, label %lexit19

lexit19:                                          ; preds = %lhead18
  %20 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed27 = inttoptr i64 %20 to ptr
  call void @avra_rc_retain(ptr %boxed27)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eclear_written"(ptr %boxed27)
  %22 = call ptr @avra_array_sized(i64 0)
  %23 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot28, align 8
  br label %lhead29

lbody22:                                          ; preds = %lhead18
  %ld23 = load i64, ptr %slot16, align 8
  %24 = call ptr @avra_array_get_owned(ptr %12, i64 %ld23)
  call void @avra_rc_retain(ptr %24)
  call void @avra_cell_release(ptr %slot17)
  store ptr %24, ptr %slot17, align 8
  %ld24 = load ptr, ptr %slot17, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld24)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Esig"(ptr %0, ptr %ld24)
  call void @avra_rc_retain(ptr %25)
  %26 = call i64 @"av_$40std$2Eavrac$2Ecore$2Etouch$24480"(ptr %25)
  %ld25 = load i64, ptr %slot16, align 8
  %add26 = add i64 %ld25, 1
  store i64 %add26, ptr %slot16, align 8
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  br label %lhead18

lhead29:                                          ; preds = %lbody33, %lexit19
  %ld31 = load i64, ptr %slot28, align 8
  %cmp32 = icmp slt i64 %ld31, %23
  br i1 %cmp32, label %lbody33, label %lexit30

lexit30:                                          ; preds = %lhead29
  %27 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed38 = inttoptr i64 %27 to ptr
  call void @avra_rc_retain(ptr %boxed38)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %22)
  %28 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Esettle_writers"(ptr %boxed38, ptr %12, ptr %22)
  %29 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %30 = call ptr @avra_array_sized(i64 0)
  %31 = call i64 @avra_array_len(ptr %12)
  store i64 0, ptr %slot39, align 8
  br label %lhead40

lbody33:                                          ; preds = %lhead29
  %ld34 = load i64, ptr %slot28, align 8
  %32 = call i64 @avra_array_get(ptr %12, i64 %ld34)
  %boxed35 = inttoptr i64 %32 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed35)
  %33 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Esummary"(ptr %0, ptr %boxed35)
  call void @avra_array_push_owned(ptr %22, ptr %33)
  %ld36 = load i64, ptr %slot28, align 8
  %add37 = add i64 %ld36, 1
  store i64 %add37, ptr %slot28, align 8
  call void @avra_rc_release(ptr %33)
  br label %lhead29

lhead40:                                          ; preds = %lbody44, %lexit30
  %ld42 = load i64, ptr %slot39, align 8
  %cmp43 = icmp slt i64 %ld42, %31
  br i1 %cmp43, label %lbody44, label %lexit41

lexit41:                                          ; preds = %lhead40
  call void @avra_rc_retain(ptr %30)
  %34 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp"(i64 17, ptr %30)
  call void @avra_rc_retain(ptr %29)
  call void @avra_rc_retain(ptr %6)
  %35 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Esettle"(ptr %29, ptr %6, i64 %34)
  %36 = call i64 @avra_array_len(ptr %12)
  call void @avra_cell_release(ptr %slot17)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %36

lbody44:                                          ; preds = %lhead40
  %ld45 = load i64, ptr %slot39, align 8
  %37 = call i64 @avra_array_get(ptr %12, i64 %ld45)
  %boxed46 = inttoptr i64 %37 to ptr
  %38 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed47 = inttoptr i64 %38 to ptr
  call void @avra_rc_retain(ptr %boxed47)
  call void @avra_rc_retain(ptr %boxed46)
  %39 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Ewritten_bits"(ptr %boxed47, ptr %boxed46)
  call void @avra_rc_retain(ptr %39)
  %40 = call i64 @"av_$40std$2Eavrac$2Ecore$2Efp_list"(ptr %39)
  call void @avra_array_push(ptr %30, i64 %40)
  %ld48 = load i64, ptr %slot39, align 8
  %add49 = add i64 %ld48, 1
  store i64 %add49, ptr %slot39, align 8
  call void @avra_rc_release(ptr %39)
  br label %lhead40
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Ewritten_bits"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_count"(ptr %0, ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_written_so_far"(ptr %0, ptr %1, i64 %ld1)
  br i1 %4, label %then, label %else

then:                                             ; preds = %lbody
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 1, %then ], [ 0, %else ]
  call void @avra_array_push(ptr %2, i64 %regval)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_count"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Esettle_writers"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 true, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lexit4, %entry
  %ld = load i1, ptr %slot, align 8
  br i1 %ld, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  store i1 false, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead3

lhead3:                                           ; preds = %endif, %lbody
  %ld5 = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld5, %3
  br i1 %cmp, label %lbody6, label %lexit4

lexit4:                                           ; preds = %lhead3
  call void @avra_cell_release(ptr %slot2)
  br label %lhead

lbody6:                                           ; preds = %lhead3
  %ld7 = load i64, ptr %slot1, align 8
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 %ld7)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot2)
  store ptr %4, ptr %slot2, align 8
  %ld8 = load ptr, ptr %slot2, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld7)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld8)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Esettle_one"(ptr %0, ptr %ld8, ptr %boxed)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody6
  store i1 true, ptr %slot, align 8
  br label %endif

else:                                             ; preds = %lbody6
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld9 = load i64, ptr %slot1, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead3
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Esettle_one"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot2 = alloca i1, align 1
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 0)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif11, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld14 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld14

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %3, i64 %ld3)
  %b = icmp ne i64 %5, 0
  store i1 %b, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %6 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_written_so_far"(ptr %0, ptr %1, i64 %ld3)
  %not = xor i1 %6, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  %ld4 = load i1, ptr %slot2, align 8
  br i1 %ld4, label %then5, label %else6

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %endif7
  %regval8 = phi i1 [ %regval, %endif7 ], [ false, %else ]
  br i1 %regval8, label %then9, label %else10

then5:                                            ; preds = %then
  br label %endif7

else6:                                            ; preds = %then
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %7 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Eflows_write"(ptr %0, ptr %2, i64 %ld3)
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval = phi i1 [ true, %then5 ], [ %7, %else6 ]
  br label %endif

then9:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Erecord_seat_written"(ptr %0, ptr %1, i64 %ld3)
  store i1 true, ptr %slot, align 8
  br label %endif11

else10:                                           ; preds = %endif
  br label %endif11

endif11:                                          ; preds = %else10, %then9
  %regval12 = phi i64 [ 0, %then9 ], [ 0, %else10 ]
  %ld13 = load i64, ptr %slot1, align 8
  %add = add i64 %ld13, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Erecord_seat_written"(ptr, ptr, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2EDecls$2Eflows_write"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Ereceivers$24l132" to i64))
  call void @avra_array_push(ptr %3, i64 %2)
  call void @avra_array_push_owned(ptr %3, ptr %0)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %4 to ptr
  %8 = call i1 %cast(ptr %3, ptr %boxed)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
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

define i1 @"av_$40std$2Eavrac$2Elanguage$2Ereceivers$24l132"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %cmp = icmp eq i64 %2, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %5)
  %7 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_writes_so_far"(ptr %boxed, ptr %5, i64 %6)
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %7, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Esummary"(ptr %0, ptr %1) {
entry:
  %slot20 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %boxed, ptr %1)
  %4 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_count"(ptr %boxed1, ptr %1)
  %6 = call i64 @avra_array_get(ptr %3, i64 9)
  %boxed2 = inttoptr i64 %6 to ptr
  %cmp = icmp ne ptr %boxed2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2415"(i64 %5, i1 false)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Ereceiver_type"(ptr %0, ptr %3)
  %11 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed3 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %1)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed3, ptr %1)
  %cmp4 = icmp ne ptr %12, null
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %12)
  br label %endif7

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi ptr [ %13, %then5 ], [ null, %else6 ]
  %cmp9 = icmp ne ptr %regval8, null
  br i1 %cmp9, label %then10, label %else11

then10:                                           ; preds = %endif7
  %14 = call ptr @avra_array_get_owned(ptr %regval8, i64 0)
  br label %endif12

else11:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr null)
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi ptr [ %14, %then10 ], [ null, %else11 ]
  %cmp14 = icmp ne ptr %regval13, null
  br i1 %cmp14, label %then15, label %else16

then15:                                           ; preds = %endif12
  call void @avra_rc_retain(ptr %regval13)
  br label %endif17

else16:                                           ; preds = %endif12
  %15 = call ptr @avra_array_sized(i64 0)
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval18 = phi ptr [ %regval13, %then15 ], [ %15, %else16 ]
  %16 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %17 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed19 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed19)
  call void @avra_rc_retain(ptr %1)
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Estore"(ptr %boxed19, ptr %1)
  %19 = call i64 @avra_array_get(ptr %3, i64 1)
  call void @avra_rc_retain(ptr %0)
  %20 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Eresolved"(ptr %0, i64 %19)
  %21 = call i64 @avra_array_get(ptr %3, i64 10)
  %22 = call i64 @avra_array_get(ptr %3, i64 11)
  %23 = call ptr @"av_$40std$2Eavrac$2Ecore$2Efilled$2415"(i64 %5, i1 false)
  %24 = call ptr @avra_array_sized(i64 0)
  %25 = call ptr @avra_array_sized(i64 10)
  call void @avra_array_push_owned(ptr %25, ptr %0)
  call void @avra_array_push_owned(ptr %25, ptr %16)
  call void @avra_array_push_owned(ptr %25, ptr %18)
  call void @avra_array_push_owned(ptr %25, ptr %20)
  call void @avra_array_push_owned(ptr %25, ptr %10)
  call void @avra_array_push_owned(ptr %25, ptr %regval18)
  call void @avra_array_push(ptr %25, i64 %21)
  call void @avra_array_push(ptr %25, i64 %22)
  call void @avra_array_push_owned(ptr %25, ptr %23)
  call void @avra_array_push_owned(ptr %25, ptr %24)
  call void @avra_rc_retain(ptr %25)
  call void @avra_cell_release(ptr %slot)
  store ptr %25, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %26 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eassigns"(ptr %ld)
  %27 = call i64 @avra_array_get(ptr %3, i64 10)
  store i64 %27, ptr %slot20, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %endif17
  %ld21 = load i64, ptr %slot20, align 8
  %28 = call i64 @avra_array_get(ptr %3, i64 11)
  %cmp22 = icmp slt i64 %ld21, %28
  br i1 %cmp22, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld26 = load ptr, ptr %slot, align 8
  %29 = call i64 @avra_array_get(ptr %ld26, i64 8)
  %boxed27 = inttoptr i64 %29 to ptr
  %ld28 = load ptr, ptr %slot, align 8
  %30 = call i64 @avra_array_get(ptr %ld28, i64 9)
  %boxed29 = inttoptr i64 %30 to ptr
  %31 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %31, ptr %boxed27)
  call void @avra_array_push_owned(ptr %31, ptr %boxed29)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval18)
  call void @avra_rc_release(ptr %regval13)
  call void @avra_rc_release(ptr %regval8)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %31

lbody:                                            ; preds = %lhead
  %ld23 = load ptr, ptr %slot, align 8
  %ld24 = load i64, ptr %slot20, align 8
  call void @avra_rc_retain(ptr %ld23)
  %32 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Esite_evidence"(ptr %ld23, i64 %ld24)
  %ld25 = load i64, ptr %slot20, align 8
  %add = add i64 %ld25, 1
  store i64 %add, ptr %slot20, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Esite_evidence"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emethod_parts"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emethod_evidence"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %boxed1, i64 %1)
  %cmp2 = icmp ne ptr %7, null
  br i1 %cmp2, label %then3, label %else4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  br label %endif

then3:                                            ; preds = %endif
  %8 = call ptr @avra_insist(ptr %7)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecall_args"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed"(ptr %0, ptr %8, ptr %9, i64 0)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Evalued_evidence"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endif5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Evalued_evidence"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecalled_seat"(ptr %0, i64 %1)
  %x = extractvalue { i1, i64 } %2, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %2, 0
  %x2 = extractvalue { i1, i64 } %2, 1
  %slot = zext i1 %x1 to i64
  %3 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %4 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp slt i64 %3, %5
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp, %then ], [ false, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  %x6 = extractvalue { i1, i64 } %2, 0
  %x7 = extractvalue { i1, i64 } %2, 1
  %slot8 = zext i1 %x6 to i64
  %7 = call i64 @avra_insist_scalar(i64 %slot8, i64 %x7)
  %8 = call i64 @avra_array_get(ptr %6, i64 %7)
  %boxed9 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed9)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Earrow_marks"(ptr %0, ptr %boxed9)
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecall_args"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed_marks"(ptr %0, ptr %9, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret
  %regval10 = phi i64 [ 0, %postret ], [ 0, %else4 ]
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed11 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed11)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eapplied_parts"(ptr %boxed11, i64 %1)
  %cmp12 = icmp ne ptr %13, null
  %not = xor i1 %cmp12, true
  br i1 %not, label %then13, label %else14

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  br label %endif5

then13:                                           ; preds = %endif5
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else14:                                           ; preds = %endif5
  br label %endif15

endif15:                                          ; preds = %else14, %postret16
  %regval17 = phi i64 [ 0, %postret16 ], [ 0, %else14 ]
  %14 = call ptr @avra_insist(ptr %13)
  %15 = call i64 @avra_array_get(ptr %14, i64 0)
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %15)
  %cmp18 = icmp ne ptr %16, null
  br i1 %cmp18, label %then19, label %else20

postret16:                                        ; No predecessors!
  br label %endif15

then19:                                           ; preds = %endif15
  %17 = call ptr @avra_insist(ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Earrow_marks"(ptr %0, ptr %17)
  %19 = call ptr @avra_insist(ptr %13)
  %20 = call i64 @avra_array_get(ptr %19, i64 1)
  %boxed22 = inttoptr i64 %20 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  call void @avra_rc_retain(ptr %boxed22)
  %21 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed_marks"(ptr %0, ptr %18, ptr %boxed22)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %endif21

else20:                                           ; preds = %endif15
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval23 = phi i64 [ 0, %then19 ], [ 0, %else20 ]
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_step"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm2 [
    i64 0, label %arm
    i64 1, label %arm1
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eroot_type"(ptr %0, i64 %1)
  br label %endswitch

arm1:                                             ; preds = %endif
  %7 = call i64 @avra_array_get(ptr %4, i64 1)
  %8 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed3 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %boxed3)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efield_type"(ptr %0, ptr %9, ptr %boxed3)
  call void @avra_rc_release(ptr %9)
  br label %endswitch

arm2:                                             ; preds = %endif
  %11 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eelement_type"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %12)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval4 = phi ptr [ %6, %arm ], [ %10, %arm1 ], [ %13, %arm2 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eelement_type"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed1, ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 10, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  br label %endswitch

arm2:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm
  %regval3 = phi ptr [ %7, %arm ], [ null, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval3
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efield_type"(ptr %0, ptr %1, ptr %2) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efield_type_named"(ptr %boxed, ptr %4, ptr %2)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

postret:                                          ; No predecessors!
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efield_type_named"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eroot_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm3 [
    i64 1, label %arm
    i64 0, label %arm1
    i64 2, label %arm2
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  br label %endswitch

arm1:                                             ; preds = %endif
  %7 = call i64 @avra_array_get(ptr %4, i64 1)
  %8 = call i64 @avra_array_get(ptr %0, i64 5)
  %boxed4 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_len(ptr %boxed4)
  %cmp5 = icmp slt i64 %7, %9
  br i1 %cmp5, label %then6, label %else7

arm2:                                             ; preds = %endif
  %10 = call i64 @avra_array_get(ptr %4, i64 1)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ebound_type"(ptr %0, i64 %10)
  br label %endswitch

arm3:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %endif8, %arm
  %regval10 = phi ptr [ %6, %arm ], [ %regval9, %endif8 ], [ %11, %arm2 ], [ null, %arm3 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval10

then6:                                            ; preds = %arm1
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  %13 = call ptr @avra_array_get_owned(ptr %12, i64 %7)
  call void @avra_rc_release(ptr %12)
  br label %endif8

else7:                                            ; preds = %arm1
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %13, %then6 ], [ null, %else7 ]
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ebound_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_value"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %5)
  %cmp1 = icmp ne ptr %6, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %7 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed7 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebound_decl_of"(ptr %boxed7, i64 %5)
  %cmp8 = icmp ne ptr %8, null
  br i1 %cmp8, label %then9, label %else10

postret5:                                         ; No predecessors!
  br label %endif4

then9:                                            ; preds = %endif4
  %9 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed12 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %boxed12)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed12, ptr %10)
  %cmp13 = icmp ne ptr %11, null
  br i1 %cmp13, label %then14, label %else15

else10:                                           ; preds = %endif4
  br label %endif11

endif11:                                          ; preds = %else10, %postret23
  %regval24 = phi i64 [ 0, %postret23 ], [ 0, %else10 ]
  %12 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed25 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed25)
  %13 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emethod_parts"(ptr %boxed25, i64 %5)
  %cmp26 = icmp ne ptr %13, null
  %not27 = xor i1 %cmp26, true
  br i1 %not27, label %then28, label %else29

then14:                                           ; preds = %then9
  call void @avra_rc_retain(ptr %11)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %11)
  br label %endif16

else15:                                           ; preds = %then9
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi ptr [ %14, %then14 ], [ null, %else15 ]
  %cmp18 = icmp ne ptr %regval17, null
  br i1 %cmp18, label %then19, label %else20

then19:                                           ; preds = %endif16
  %15 = call ptr @avra_array_get_owned(ptr %regval17, i64 1)
  br label %endif21

else20:                                           ; preds = %endif16
  call void @avra_rc_retain(ptr null)
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval22 = phi ptr [ %15, %then19 ], [ null, %else20 ]
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval22

postret23:                                        ; No predecessors!
  call void @avra_rc_release(ptr %regval22)
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif11

then28:                                           ; preds = %endif11
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Econstructed_type"(ptr %0, i64 %5)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else29:                                           ; preds = %endif11
  br label %endif30

endif30:                                          ; preds = %else29, %postret31
  %regval32 = phi i64 [ 0, %postret31 ], [ 0, %else29 ]
  %17 = call ptr @avra_insist(ptr %13)
  %18 = call i64 @avra_array_get(ptr %17, i64 0)
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %18)
  %cmp33 = icmp ne ptr %19, null
  %not34 = xor i1 %cmp33, true
  br i1 %not34, label %then35, label %else36

postret31:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  br label %endif30

then35:                                           ; preds = %endif30
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else36:                                           ; preds = %endif30
  br label %endif37

endif37:                                          ; preds = %else36, %postret38
  %regval39 = phi i64 [ 0, %postret38 ], [ 0, %else36 ]
  %20 = call ptr @avra_insist(ptr %19)
  %21 = call i64 @avra_array_get(ptr %17, i64 1)
  %boxed40 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %boxed40)
  %22 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecallee_of"(ptr %0, ptr %20, ptr %boxed40)
  %23 = call i64 @avra_array_get(ptr %22, i64 0)
  switch i64 %23, label %arm44 [
    i64 1, label %arm
    i64 2, label %arm41
    i64 3, label %arm42
    i64 4, label %arm43
  ]

postret38:                                        ; No predecessors!
  br label %endif37

arm:                                              ; preds = %endif37
  %24 = call i64 @avra_array_get(ptr %22, i64 1)
  %boxed45 = inttoptr i64 %24 to ptr
  %25 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed46 = inttoptr i64 %25 to ptr
  call void @avra_rc_retain(ptr %boxed46)
  call void @avra_rc_retain(ptr %boxed45)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed46, ptr %boxed45)
  %cmp47 = icmp ne ptr %26, null
  br i1 %cmp47, label %then48, label %else49

arm41:                                            ; preds = %endif37
  %27 = call i64 @avra_array_get(ptr %22, i64 1)
  %boxed57 = inttoptr i64 %27 to ptr
  %28 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed58 = inttoptr i64 %28 to ptr
  call void @avra_rc_retain(ptr %boxed58)
  call void @avra_rc_retain(ptr %boxed57)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed58, ptr %boxed57)
  %cmp59 = icmp ne ptr %29, null
  br i1 %cmp59, label %then60, label %else61

arm42:                                            ; preds = %endif37
  %30 = call ptr @avra_array_get_owned(ptr %22, i64 1)
  %31 = call ptr @avra_array_get_owned(ptr %30, i64 2)
  call void @avra_rc_release(ptr %30)
  br label %endswitch

arm43:                                            ; preds = %endif37
  %32 = call i64 @avra_array_get(ptr %22, i64 1)
  %boxed69 = inttoptr i64 %32 to ptr
  %33 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed70 = inttoptr i64 %33 to ptr
  call void @avra_rc_retain(ptr %boxed70)
  call void @avra_rc_retain(ptr %boxed69)
  %34 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Esig"(ptr %boxed70, ptr %boxed69)
  %cmp71 = icmp ne ptr %34, null
  br i1 %cmp71, label %then72, label %else73

arm44:                                            ; preds = %endif37
  br label %endswitch

endswitch:                                        ; preds = %arm44, %endif79, %arm42, %endif67, %endif55
  %regval81 = phi ptr [ %regval56, %endif55 ], [ %regval68, %endif67 ], [ %31, %arm42 ], [ %regval80, %endif79 ], [ null, %arm44 ]
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval81

then48:                                           ; preds = %arm
  call void @avra_rc_retain(ptr %26)
  %35 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %26)
  br label %endif50

else49:                                           ; preds = %arm
  br label %endif50

endif50:                                          ; preds = %else49, %then48
  %regval51 = phi ptr [ %35, %then48 ], [ null, %else49 ]
  %cmp52 = icmp ne ptr %regval51, null
  br i1 %cmp52, label %then53, label %else54

then53:                                           ; preds = %endif50
  %36 = call ptr @avra_array_get_owned(ptr %regval51, i64 1)
  br label %endif55

else54:                                           ; preds = %endif50
  call void @avra_rc_retain(ptr null)
  br label %endif55

endif55:                                          ; preds = %else54, %then53
  %regval56 = phi ptr [ %36, %then53 ], [ null, %else54 ]
  call void @avra_rc_release(ptr %regval51)
  call void @avra_rc_release(ptr %26)
  br label %endswitch

then60:                                           ; preds = %arm41
  call void @avra_rc_retain(ptr %29)
  %37 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %29)
  br label %endif62

else61:                                           ; preds = %arm41
  br label %endif62

endif62:                                          ; preds = %else61, %then60
  %regval63 = phi ptr [ %37, %then60 ], [ null, %else61 ]
  %cmp64 = icmp ne ptr %regval63, null
  br i1 %cmp64, label %then65, label %else66

then65:                                           ; preds = %endif62
  %38 = call ptr @avra_array_get_owned(ptr %regval63, i64 1)
  br label %endif67

else66:                                           ; preds = %endif62
  call void @avra_rc_retain(ptr null)
  br label %endif67

endif67:                                          ; preds = %else66, %then65
  %regval68 = phi ptr [ %38, %then65 ], [ null, %else66 ]
  call void @avra_rc_release(ptr %regval63)
  call void @avra_rc_release(ptr %29)
  br label %endswitch

then72:                                           ; preds = %arm43
  call void @avra_rc_retain(ptr %34)
  %39 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDeclSig$2Efn_sig"(ptr %34)
  br label %endif74

else73:                                           ; preds = %arm43
  br label %endif74

endif74:                                          ; preds = %else73, %then72
  %regval75 = phi ptr [ %39, %then72 ], [ null, %else73 ]
  %cmp76 = icmp ne ptr %regval75, null
  br i1 %cmp76, label %then77, label %else78

then77:                                           ; preds = %endif74
  %40 = call ptr @avra_array_get_owned(ptr %regval75, i64 1)
  br label %endif79

else78:                                           ; preds = %endif74
  call void @avra_rc_retain(ptr null)
  br label %endif79

endif79:                                          ; preds = %else78, %then77
  %regval80 = phi ptr [ %40, %then77 ], [ null, %else78 ]
  call void @avra_rc_release(ptr %regval75)
  call void @avra_rc_release(ptr %34)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecallee_of"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed1, ptr %1)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp = icmp eq i64 %6, 10
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp2 = icmp eq i64 %7, 11
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp2, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  br label %endif5

else4:                                            ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp6 = icmp eq i64 %8, 12
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval7 = phi i1 [ true, %then3 ], [ %cmp6, %else4 ]
  br i1 %regval7, label %then8, label %else9

then8:                                            ; preds = %endif5
  br label %endif10

else9:                                            ; preds = %endif5
  %9 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp11 = icmp eq i64 %9, 4
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval12 = phi i1 [ true, %then8 ], [ %cmp11, %else9 ]
  br i1 %regval12, label %then13, label %else14

then13:                                           ; preds = %endif10
  br label %endif15

else14:                                           ; preds = %endif10
  %10 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp16 = icmp eq i64 %10, 3
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval17 = phi i1 [ true, %then13 ], [ %cmp16, %else14 ]
  br i1 %regval17, label %then18, label %else19

then18:                                           ; preds = %endif15
  %11 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed21 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed21, i64 2)
  %boxed22 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed22, i64 4)
  %boxed23 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed23, i64 0)
  %boxed24 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed24)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Erow_writes"(ptr %boxed24, ptr %2, ptr %5)
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 0)
  %slot = zext i1 %15 to i64
  call void @avra_array_push(ptr %16, i64 %slot)
  br label %endif20

else19:                                           ; preds = %endif15
  %17 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp25 = icmp eq i64 %17, 6
  br i1 %cmp25, label %then26, label %else27

endif20:                                          ; preds = %endif28, %then18
  %regval60 = phi ptr [ %16, %then18 ], [ %regval59, %endif28 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval60

then26:                                           ; preds = %else19
  %18 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed29 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed29)
  call void @avra_rc_retain(ptr %2)
  %19 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efield_or_method"(ptr %0, ptr %1, ptr %boxed29, ptr %2)
  br label %endif28

else27:                                           ; preds = %else19
  %20 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp30 = icmp eq i64 %20, 7
  br i1 %cmp30, label %then31, label %else32

endif28:                                          ; preds = %endif33, %then26
  %regval59 = phi ptr [ %19, %then26 ], [ %regval58, %endif33 ]
  br label %endif20

then31:                                           ; preds = %else27
  %21 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed34 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed34)
  call void @avra_rc_retain(ptr %2)
  %22 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Edeclared_method"(ptr %0, ptr %boxed34, ptr %2)
  br label %endif33

else32:                                           ; preds = %else27
  %23 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp35 = icmp eq i64 %23, 8
  br i1 %cmp35, label %then36, label %else37

endif33:                                          ; preds = %endif38, %then31
  %regval58 = phi ptr [ %22, %then31 ], [ %regval57, %endif38 ]
  br label %endif28

then36:                                           ; preds = %else32
  %24 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed39 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed39)
  call void @avra_rc_retain(ptr %2)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efield_or_method"(ptr %0, ptr %1, ptr %boxed39, ptr %2)
  br label %endif38

else37:                                           ; preds = %else32
  %26 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp40 = icmp eq i64 %26, 21
  br i1 %cmp40, label %then41, label %else42

endif38:                                          ; preds = %endif43, %then36
  %regval57 = phi ptr [ %25, %then36 ], [ %regval56, %endif43 ]
  br label %endif33

then41:                                           ; preds = %else37
  %27 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  %28 = call i64 @avra_array_get(ptr %5, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  call void @avra_rc_retain(ptr %2)
  %29 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ebounded_member"(ptr %0, ptr %27, i64 %28, ptr %2)
  call void @avra_rc_release(ptr %27)
  br label %endif43

else42:                                           ; preds = %else37
  %30 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp44 = icmp eq i64 %30, 9
  br i1 %cmp44, label %then45, label %else46

endif43:                                          ; preds = %endif47, %then41
  %regval56 = phi ptr [ %29, %then41 ], [ %regval55, %endif47 ]
  br label %endif38

then45:                                           ; preds = %else42
  %31 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed48 = inttoptr i64 %31 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed48)
  call void @avra_rc_retain(ptr %2)
  %32 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Econtract_member"(ptr %0, ptr %boxed48, ptr %2)
  br label %endif47

else46:                                           ; preds = %else42
  %33 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp49 = icmp eq i64 %33, 20
  br i1 %cmp49, label %then50, label %else51

endif47:                                          ; preds = %endif52, %then45
  %regval55 = phi ptr [ %32, %then45 ], [ %regval54, %endif52 ]
  br label %endif43

then50:                                           ; preds = %else46
  %34 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed53 = inttoptr i64 %34 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed53)
  call void @avra_rc_retain(ptr %2)
  %35 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Estatic_member"(ptr %0, ptr %boxed53, ptr %2)
  br label %endif52

else51:                                           ; preds = %else46
  %36 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %36, i64 5)
  br label %endif52

endif52:                                          ; preds = %else51, %then50
  %regval54 = phi ptr [ %35, %then50 ], [ %36, %else51 ]
  br label %endif47
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Estatic_member"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %boxed, ptr %1, ptr %2)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %boxed1, ptr %8)
  %10 = call i64 @avra_array_get(ptr %9, i64 2)
  call void @avra_rc_retain(ptr %6)
  %11 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr %6, i64 %10)
  %not2 = xor i1 %11, true
  br i1 %not2, label %then3, label %else4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif

then3:                                            ; preds = %endif
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 5)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %13 = call ptr @avra_insist(ptr %4)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 2)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %12)
  br label %endif5
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Econtract_member"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_member"(ptr %boxed, ptr %1, ptr %2)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 4)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ebounded_member"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etbounds"(ptr %boxed, ptr %1)
  %6 = call i64 @avra_array_len(ptr %5)
  %cmp = icmp sge i64 %2, %6
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 %2)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %8 to ptr
  %cmp3 = icmp ne ptr %boxed2, null
  %not = xor i1 %cmp3, true
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not, %else ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret
  %regval7 = phi i64 [ 0, %postret ], [ 0, %else5 ]
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %11 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed8 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %5, i64 %2)
  %boxed9 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed9, i64 1)
  %boxed10 = inttoptr i64 %13 to ptr
  %14 = call ptr @avra_insist(ptr %boxed10)
  %15 = call i64 @avra_array_get(ptr %14, i64 0)
  %boxed11 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %boxed8)
  call void @avra_rc_retain(ptr %boxed11)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etrait_named"(ptr %10, ptr %boxed8, ptr %boxed11)
  %cmp12 = icmp ne ptr %16, null
  %not13 = xor i1 %cmp12, true
  br i1 %not13, label %then14, label %else15

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif6

then14:                                           ; preds = %endif6
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 5)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %17

else15:                                           ; preds = %endif6
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %18 = call ptr @avra_insist(ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  call void @avra_rc_retain(ptr %3)
  %19 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Econtract_member"(ptr %0, ptr %18, ptr %3)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %19

postret17:                                        ; No predecessors!
  call void @avra_rc_release(ptr %17)
  br label %endif16
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Edeclared_method"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Emethod"(ptr %boxed, ptr %1, ptr %2)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 1)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efield_or_method"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efn_field_arrow"(ptr %0, ptr %1, ptr %3)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Edeclared_method"(ptr %0, ptr %2, ptr %3)
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
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 3)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efn_field_arrow"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Efield_type_named"(ptr %boxed, ptr %1, ptr %2)
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
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr %boxed2, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

postret:                                          ; No predecessors!
  br label %endif
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Erow_writes"(ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Econstructed_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_lit_name"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 4)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr %boxed2, ptr %6)
  %cmp3 = icmp ne ptr %7, null
  %not4 = xor i1 %cmp3, true
  br i1 %not4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed10 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_insist(ptr %7)
  call void @avra_rc_retain(ptr %boxed10)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eself_type_of"(ptr %boxed10, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret8:                                         ; No predecessors!
  br label %endif7
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estruct_lit_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Emethod_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_step"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eapplied_parts"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed_marks"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %2, i64 %ld2)
  store i64 %4, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %1)
  %5 = call i1 @"av_$40std$2Eavrac$2Ecore$2Emut_mark"(ptr %1, i64 %ld2)
  br i1 %5, label %then, label %else

then:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eseat_of"(ptr %0, i64 %ld3)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %6)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %1) {
entry:
  %x = extractvalue { i1, i64 } %1, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %1, 0
  %x2 = extractvalue { i1, i64 } %1, 1
  %slot = zext i1 %x1 to i64
  %2 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %3 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp slt i64 %2, %4
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp, %then ], [ false, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  %5 = call ptr @avra_slot_unique(ptr %0, i64 8)
  %x6 = extractvalue { i1, i64 } %1, 0
  %x7 = extractvalue { i1, i64 } %1, 1
  %slot8 = zext i1 %x6 to i64
  %6 = call i64 @avra_insist_scalar(i64 %slot8, i64 %x7)
  call void @avra_slot_set(ptr %5, i64 %6, i64 1)
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval9 = phi i64 [ 0, %then3 ], [ 0, %else4 ]
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eseat_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_root"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %3)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed1, i64 %6)
  %cmp2 = icmp ne ptr %7, null
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  br label %endif

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %8 = call ptr @avra_insist(ptr %7)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  switch i64 %9, label %arm10 [
    i64 1, label %arm
    i64 0, label %arm9
  ]

postret7:                                         ; No predecessors!
  br label %endif6

arm:                                              ; preds = %endif6
  br label %endswitch

arm9:                                             ; preds = %endif6
  %10 = call i64 @avra_array_get(ptr %8, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %10, 1
  br label %endswitch

arm10:                                            ; preds = %endif6
  br label %endswitch

endswitch:                                        ; preds = %arm10, %arm9, %arm
  %regval11 = phi { i1, i64 } [ { i1 true, i64 0 }, %arm ], [ %pack, %arm9 ], [ zeroinitializer, %arm10 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %regval11
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_root"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecall_args"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed, i64 %1)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  switch i64 %4, label %arm1 [
    i64 17, label %arm
  ]

arm:                                              ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 3)
  br label %endswitch

arm1:                                             ; preds = %entry
  %6 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %5, %arm ], [ %6, %arm1 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Earrow_marks"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Earrow_parts"(ptr %boxed1, ptr %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %4)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif
}

define { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecalled_seat"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecall_args"(ptr %0, i64 %1)
  %3 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Ebinding"(ptr %boxed, i64 %1)
  %cmp1 = icmp ne ptr %5, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm7 [
    i64 0, label %arm
  ]

postret5:                                         ; No predecessors!
  br label %endif4

arm:                                              ; preds = %endif4
  %8 = call i64 @avra_array_get(ptr %6, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %8, 1
  br label %endswitch

arm7:                                             ; preds = %endif4
  br label %endswitch

endswitch:                                        ; preds = %arm7, %arm
  %regval8 = phi { i1, i64 } [ %pack, %arm ], [ zeroinitializer, %arm7 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %regval8
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eunder_trait"(ptr %0, ptr %1)
  %5 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %2, i64 %ld2)
  store i64 %6, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %7 to ptr
  %add = add i64 %3, %ld2
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eseat_mark"(ptr %boxed, ptr %1, i64 %add)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %b = icmp ne i64 %9, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %10 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eseat_of"(ptr %0, i64 %ld3)
  br i1 %4, label %then4, label %else5

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %endif6
  %regval8 = phi i64 [ 0, %endif6 ], [ 0, %else ]
  %ld9 = load i64, ptr %slot, align 8
  %add10 = add i64 %ld9, 1
  store i64 %add10, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead

then4:                                            ; preds = %then
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %10)
  br label %endif6

else5:                                            ; preds = %then
  %add7 = add i64 %3, %ld2
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eflow"(ptr %0, { i1, i64 } %10, ptr %1, i64 %add7)
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval = phi i64 [ 0, %then4 ], [ 0, %else5 ]
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eflow"(ptr %0, { i1, i64 } %1, ptr %2, i64 %3) {
entry:
  %x = extractvalue { i1, i64 } %1, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_slot_unique(ptr %0, i64 9)
  %x1 = extractvalue { i1, i64 } %1, 0
  %x2 = extractvalue { i1, i64 } %1, 1
  %slot = zext i1 %x1 to i64
  %5 = call i64 @avra_insist_scalar(i64 %slot, i64 %x2)
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 %5)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push(ptr %6, i64 %3)
  call void @avra_array_push_owned(ptr %4, ptr %6)
  call void @avra_rc_release(ptr %6)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eunder_trait"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %boxed, ptr %1)
  %4 = call ptr @avra_array_get_owned(ptr %3, i64 7)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %6)
  %7 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eis_trait"(ptr %boxed1, ptr %6)
  call void @avra_rc_release(ptr %6)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %7, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed5 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %1)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Ehas_body"(ptr %boxed5, ptr %1)
  %not = xor i1 %9, true
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ %not, %then2 ], [ false, %else3 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval6
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emethod_evidence"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %3 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eseat_of"(ptr %0, i64 %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %4)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot, align 8
  br label %lhead

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval10 = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call ptr @avra_insist(ptr %5)
  %9 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %boxed)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ecallee_of"(ptr %0, ptr %8, ptr %boxed)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  switch i64 %11, label %arm15 [
    i64 0, label %arm
    i64 1, label %arm11
    i64 2, label %arm12
    i64 3, label %arm13
    i64 4, label %arm14
  ]

lhead:                                            ; preds = %endif7, %then
  %ld = load i64, ptr %slot, align 8
  %cmp2 = icmp slt i64 %ld, %7
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %12 = call i64 @avra_array_get(ptr %6, i64 %ld3)
  store i64 %12, ptr %slot1, align 8
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %13 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ewritable"(ptr %0, i64 %ld4)
  br i1 %13, label %then5, label %else6

then5:                                            ; preds = %lbody
  %ld8 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %14 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eseat_of"(ptr %0, i64 %ld8)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %14)
  br label %endif7

else6:                                            ; preds = %lbody
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  %ld9 = load i64, ptr %slot, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif

arm:                                              ; preds = %endif
  %16 = call i64 @avra_array_get(ptr %10, i64 1)
  %b = icmp ne i64 %16, 0
  br i1 %b, label %then16, label %else17

arm11:                                            ; preds = %endif
  %17 = call ptr @avra_array_get_owned(ptr %10, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eflow"(ptr %0, { i1, i64 } %3, ptr %17, i64 0)
  %19 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed20 = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  call void @avra_rc_retain(ptr %boxed20)
  %20 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed"(ptr %0, ptr %17, ptr %boxed20, i64 1)
  call void @avra_rc_release(ptr %17)
  br label %endswitch

arm12:                                            ; preds = %endif
  %21 = call i64 @avra_array_get(ptr %10, i64 1)
  %boxed21 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed22 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed21)
  call void @avra_rc_retain(ptr %boxed22)
  %23 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed"(ptr %0, ptr %boxed21, ptr %boxed22, i64 0)
  br label %endswitch

arm13:                                            ; preds = %endif
  %24 = call i64 @avra_array_get(ptr %10, i64 1)
  %boxed23 = inttoptr i64 %24 to ptr
  %25 = call i64 @avra_array_get(ptr %boxed23, i64 1)
  %boxed24 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed25 = inttoptr i64 %26 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed24)
  call void @avra_rc_retain(ptr %boxed25)
  %27 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed_marks"(ptr %0, ptr %boxed24, ptr %boxed25)
  br label %endswitch

arm14:                                            ; preds = %endif
  %28 = call ptr @avra_array_get_owned(ptr %10, i64 1)
  %29 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed26 = inttoptr i64 %29 to ptr
  call void @avra_rc_retain(ptr %boxed26)
  call void @avra_rc_retain(ptr %28)
  %30 = call i1 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edeclares_writing"(ptr %boxed26, ptr %28)
  br i1 %30, label %then27, label %else28

arm15:                                            ; preds = %endif
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm15, %endif29, %arm13, %arm12, %arm11, %endif18
  %regval32 = phi i64 [ %regval19, %endif18 ], [ %20, %arm11 ], [ %23, %arm12 ], [ %27, %arm13 ], [ %36, %endif29 ], [ %31, %arm15 ]
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval32

then16:                                           ; preds = %arm
  call void @avra_rc_retain(ptr %0)
  %32 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %3)
  br label %endif18

else17:                                           ; preds = %arm
  %33 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval19 = phi i64 [ %32, %then16 ], [ %33, %else17 ]
  br label %endswitch

then27:                                           ; preds = %arm14
  call void @avra_rc_retain(ptr %0)
  %34 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %3)
  br label %endif29

else28:                                           ; preds = %arm14
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval30 = phi i64 [ 0, %then27 ], [ 0, %else28 ]
  %35 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed31 = inttoptr i64 %35 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %28)
  call void @avra_rc_retain(ptr %boxed31)
  %36 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Efeed"(ptr %0, ptr %28, ptr %boxed31, i64 1)
  call void @avra_rc_release(ptr %28)
  br label %endswitch
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ewritable"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emeasured"(ptr %0, i64 %1)
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed6 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %3)
  call void @avra_rc_retain(ptr %boxed6)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed6, ptr %6)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp7 = icmp eq i64 %8, 0
  br i1 %cmp7, label %then8, label %else9

postret4:                                         ; No predecessors!
  br label %endif3

then8:                                            ; preds = %endif3
  br label %endif10

else9:                                            ; preds = %endif3
  %9 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp11 = icmp eq i64 %9, 1
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval12 = phi i1 [ true, %then8 ], [ %cmp11, %else9 ]
  br i1 %regval12, label %then13, label %else14

then13:                                           ; preds = %endif10
  br label %endif15

else14:                                           ; preds = %endif10
  %10 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp16 = icmp eq i64 %10, 4
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval17 = phi i1 [ true, %then13 ], [ %cmp16, %else14 ]
  br i1 %regval17, label %then18, label %else19

then18:                                           ; preds = %endif15
  br label %endif20

else19:                                           ; preds = %endif15
  %11 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp21 = icmp eq i64 %11, 2
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval22 = phi i1 [ true, %then18 ], [ %cmp21, %else19 ]
  br i1 %regval22, label %then23, label %else24

then23:                                           ; preds = %endif20
  br label %endif25

else24:                                           ; preds = %endif20
  %12 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp26 = icmp eq i64 %12, 3
  br label %endif25

endif25:                                          ; preds = %else24, %then23
  %regval27 = phi i1 [ true, %then23 ], [ %cmp26, %else24 ]
  br i1 %regval27, label %then28, label %else29

then28:                                           ; preds = %endif25
  br label %endif30

else29:                                           ; preds = %endif25
  %13 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp31 = icmp eq i64 %13, 17
  br label %endif30

endif30:                                          ; preds = %else29, %then28
  %regval32 = phi i1 [ true, %then28 ], [ %cmp31, %else29 ]
  br i1 %regval32, label %then33, label %else34

then33:                                           ; preds = %endif30
  br label %endif35

else34:                                           ; preds = %endif30
  %14 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp36 = icmp eq i64 %14, 15
  br label %endif35

endif35:                                          ; preds = %else34, %then33
  %regval37 = phi i1 [ true, %then33 ], [ %cmp36, %else34 ]
  br i1 %regval37, label %then38, label %else39

then38:                                           ; preds = %endif35
  br label %endif40

else39:                                           ; preds = %endif35
  %15 = call i64 @avra_array_get(ptr %7, i64 0)
  %cmp41 = icmp eq i64 %15, 5
  br label %endif40

endif40:                                          ; preds = %else39, %then38
  %regval42 = phi i1 [ true, %then38 ], [ %cmp41, %else39 ]
  br i1 %regval42, label %then43, label %else44

then43:                                           ; preds = %endif40
  br label %endif45

else44:                                           ; preds = %endif40
  br label %endif45

endif45:                                          ; preds = %else44, %then43
  %regval46 = phi i1 [ false, %then43 ], [ true, %else44 ]
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval46
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emeasured"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eplace_step"(ptr %boxed, i64 %1)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm1 [
    i64 1, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call ptr @avra_array_get_owned(ptr %4, i64 2)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eplace_type"(ptr %0, i64 %6)
  %cmp2 = icmp ne ptr %8, null
  br i1 %cmp2, label %then3, label %else4

arm1:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif5
  %regval13 = phi i1 [ %regval12, %endif5 ], [ false, %arm1 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval13

then3:                                            ; preds = %arm
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %10 = call i64 @avra_array_get(ptr %9, i64 2)
  %boxed6 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed6, i64 4)
  %boxed7 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed7, i64 2)
  %boxed8 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed9 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed9, i64 0)
  %boxed10 = inttoptr i64 %14 to ptr
  %15 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %boxed10)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed10, ptr %15)
  call void @avra_rc_retain(ptr %boxed8)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %16)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_row"(ptr %boxed8, ptr %7, ptr %16)
  %cmp11 = icmp ne ptr %17, null
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %9)
  br label %endif5

else4:                                            ; preds = %arm
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval12 = phi i1 [ %cmp11, %then3 ], [ false, %else4 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endswitch
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_row"(ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eassigns"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  %1 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_get(ptr %boxed, i64 2)
  %boxed1 = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %3 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24921"(ptr %boxed1)
  br label %lhead

lhead:                                            ; preds = %endif7, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %4 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %4 to ptr
  %ld3 = load i64, ptr %slot, align 8
  call void @avra_rc_retain(ptr %boxed2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr %boxed2, i64 %ld3)
  %cmp4 = icmp ne ptr %5, null
  br i1 %cmp4, label %then, label %else

then:                                             ; preds = %lbody
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ein_range"(ptr %0, i64 %7)
  call void @avra_rc_release(ptr %6)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %8, %then ], [ false, %else ]
  br i1 %regval, label %then5, label %else6

then5:                                            ; preds = %endif
  %9 = call ptr @avra_insist(ptr %5)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  call void @avra_rc_retain(ptr %0)
  %11 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Eseat_of"(ptr %0, i64 %10)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Emark"(ptr %0, { i1, i64 } %11)
  call void @avra_rc_release(ptr %9)
  br label %endif7

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval8 = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  %ld9 = load i64, ptr %slot, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2ESurvey$2Ein_range"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 6)
  %cmp = icmp sge i64 %1, %2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 7)
  %cmp1 = icmp slt i64 %1, %3
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eassign_target"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EWorkspace$2Ereceiver_type"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 7)
  %boxed = inttoptr i64 %2 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %1, i64 7)
  %boxed2 = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_insist(ptr %boxed2)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Etarget_of"(ptr %boxed1, ptr %5)
  %cmp3 = icmp ne ptr %6, null
  %not4 = xor i1 %cmp3, true
  br i1 %not4, label %then5, label %else6

postret:                                          ; No predecessors!
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %postret8
  %regval9 = phi i64 [ 0, %postret8 ], [ 0, %else6 ]
  %7 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed10 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_insist(ptr %6)
  call void @avra_rc_retain(ptr %boxed10)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eself_type_of"(ptr %boxed10, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret8:                                         ; No predecessors!
  br label %endif7
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Eclear_written"(ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eseated"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %cmp = icmp eq i64 %2, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %cmp2 = icmp eq i64 %4, 7
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp2, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}
