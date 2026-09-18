; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c":\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"...\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [40 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 39 }, [40 x i8] c"@std.avrac.features.formats.close_brace\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"}\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"@std.avrac.features.formats.open_brace\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"{\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Enamed_ref"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ebound_names"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Erepeated_fault"(ptr %0) {
entry:
  %slot4 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca { i1, i64 }, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ebound_names"(ptr %0)
  store { i1, i64 } zeroinitializer, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat$24l415" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_array_sized(i64 0)
  %5 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %6 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  call void @avra_array_push(ptr %4, i64 %ld2)
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

lhead5:                                           ; preds = %endif, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %6
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  %ld13 = load { i1, i64 }, ptr %slot, align 8
  %x = extractvalue { i1, i64 } %ld13, 0
  %not = xor i1 %x, true
  br i1 %not, label %then14, label %else15

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %7 = call i64 @avra_array_get(ptr %4, i64 %ld10)
  call void @avra_rc_retain(ptr %2)
  %cast = inttoptr i64 %3 to ptr
  %8 = call i1 %cast(ptr %2, i64 %7)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody9
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %7, 1
  store { i1, i64 } %pack, ptr %slot, align 8
  store i64 %6, ptr %slot4, align 8
  br label %endif

else:                                             ; preds = %lbody9
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld11 = load i64, ptr %slot4, align 8
  %add12 = add i64 %ld11, 1
  store i64 %add12, ptr %slot4, align 8
  br label %lhead5

then14:                                           ; preds = %lexit6
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else15:                                           ; preds = %lexit6
  br label %endif16

endif16:                                          ; preds = %else15, %postret
  %regval17 = phi i64 [ 0, %postret ], [ 0, %else15 ]
  %x18 = extractvalue { i1, i64 } %ld13, 0
  %x19 = extractvalue { i1, i64 } %ld13, 1
  %slot20 = zext i1 %x18 to i64
  %9 = call i64 @avra_insist_scalar(i64 %slot20, i64 %x19)
  %10 = call i64 @avra_array_get(ptr %1, i64 %9)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 4)
  call void @avra_array_push_owned(ptr %11, ptr %boxed)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

postret:                                          ; No predecessors!
  br label %endif16
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat$24l415"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 -1, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 %1)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot, align 8
  %cmp5 = icmp slt i64 %ld4, %1
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call i64 @avra_array_get(ptr %4, i64 %ld2)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_streq(ptr %boxed, ptr %3)
  %b = icmp ne i64 %7, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i64 %ld2, ptr %slot, align 8
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eadjacent_fault"(ptr %0) {
entry:
  %slot4 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca { i1, i64 }, align 8
  store { i1, i64 } zeroinitializer, ptr %slot, align 8
  %1 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat$24l378" to i64))
  call void @avra_array_push_owned(ptr %1, ptr %0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %4, 1
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %sub
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  call void @avra_array_push(ptr %3, i64 %ld2)
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

lhead5:                                           ; preds = %endif, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %5
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  %ld13 = load { i1, i64 }, ptr %slot, align 8
  %x = extractvalue { i1, i64 } %ld13, 0
  %not = xor i1 %x, true
  br i1 %not, label %then14, label %else15

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %6 = call i64 @avra_array_get(ptr %3, i64 %ld10)
  call void @avra_rc_retain(ptr %1)
  %cast = inttoptr i64 %2 to ptr
  %7 = call i1 %cast(ptr %1, i64 %6)
  br i1 %7, label %then, label %else

then:                                             ; preds = %lbody9
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %6, 1
  store { i1, i64 } %pack, ptr %slot, align 8
  store i64 %5, ptr %slot4, align 8
  br label %endif

else:                                             ; preds = %lbody9
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld11 = load i64, ptr %slot4, align 8
  %add12 = add i64 %ld11, 1
  store i64 %add12, ptr %slot4, align 8
  br label %lhead5

then14:                                           ; preds = %lexit6
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else15:                                           ; preds = %lexit6
  br label %endif16

endif16:                                          ; preds = %else15, %postret
  %regval17 = phi i64 [ 0, %postret ], [ 0, %else15 ]
  %x18 = extractvalue { i1, i64 } %ld13, 0
  %x19 = extractvalue { i1, i64 } %ld13, 1
  %slot20 = zext i1 %x18 to i64
  %8 = call i64 @avra_insist_scalar(i64 %slot20, i64 %x19)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 %8)
  %10 = call i64 @avra_array_get(ptr %9, i64 0)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed21 = inttoptr i64 %11 to ptr
  %x22 = extractvalue { i1, i64 } %ld13, 0
  %x23 = extractvalue { i1, i64 } %ld13, 1
  %slot24 = zext i1 %x22 to i64
  %12 = call i64 @avra_insist_scalar(i64 %slot24, i64 %x23)
  %add25 = add i64 %12, 1
  %13 = call i64 @avra_array_get(ptr %0, i64 %add25)
  %boxed26 = inttoptr i64 %13 to ptr
  %14 = call i64 @avra_array_get(ptr %boxed26, i64 0)
  %boxed27 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed27, i64 0)
  %boxed28 = inttoptr i64 %15 to ptr
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 3)
  call void @avra_array_push_owned(ptr %16, ptr %boxed21)
  call void @avra_array_push_owned(ptr %16, ptr %boxed28)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

postret:                                          ; No predecessors!
  br label %endif16
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat$24l378"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 %1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_str_len(ptr %boxed2)
  %cmp = icmp eq i64 %5, 0
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ehas_holes"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %2, 0
  %not = xor i1 %cmp, true
  call void @avra_rc_release(ptr %0)
  ret i1 %not
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eread_format"(ptr %0) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call ptr @avra_bytes_of_str(ptr %0)
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot)
  store ptr %4, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endswitch, %entry
  br i1 true, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld2 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclosed"(ptr %ld2, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Estepped"(ptr %1, ptr %0, ptr %ld)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %lbody
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  call void @avra_rc_retain(ptr %8)
  call void @avra_cell_release(ptr %slot)
  store ptr %8, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %endswitch

arm1:                                             ; preds = %lbody
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

endswitch:                                        ; preds = %postret, %arm
  %regval = phi i64 [ 0, %arm ], [ 0, %postret ]
  call void @avra_rc_release(ptr %6)
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  call void @avra_rc_release(ptr null)
  call void @avra_rc_release(ptr %9)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclosed"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %1)
  %4 = call ptr @avra_array_concat(ptr %boxed, ptr %3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  %cmp = icmp ne ptr %boxed1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_insist(ptr %boxed2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclosing"(ptr %0, ptr %5)
  %12 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %12, ptr %10)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_array_push(ptr %12, i64 0)
  %13 = call i64 @avra_array_get(ptr %12, i64 1)
  %boxed3 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed3)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eadjacent_fault"(ptr %boxed3)
  %cmp4 = icmp ne ptr %14, null
  br i1 %cmp4, label %then5, label %else6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

then5:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %14)
  br label %endif7

else6:                                            ; preds = %endif
  %15 = call i64 @avra_array_get(ptr %12, i64 1)
  %boxed8 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Erepeated_fault"(ptr %boxed8)
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval9 = phi ptr [ %14, %then5 ], [ %16, %else6 ]
  %17 = call ptr @avra_array_get_owned(ptr %12, i64 0)
  %18 = call i64 @avra_array_get(ptr %12, i64 1)
  %boxed10 = inttoptr i64 %18 to ptr
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %19, ptr %17)
  call void @avra_array_push_owned(ptr %19, ptr %boxed10)
  call void @avra_array_push_owned(ptr %19, ptr %regval9)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %19
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclosing"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call ptr @avra_insist(ptr %boxed)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_array_push_owned(ptr %5, ptr %1)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  %7 = call ptr @avra_array_concat(ptr %2, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Estepped"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enext_brace"(ptr %0, i64 %3)
  %cmp = icmp slt i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %2, i64 0)
  %6 = call i64 @avra_str_len(ptr %1)
  %7 = call ptr @avra_str_substring(ptr %1, i64 %5, i64 %6)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclosed"(ptr %2, ptr %7)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 1)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %10 = call i64 @avra_array_get(ptr %2, i64 0)
  %11 = call ptr @avra_str_substring(ptr %1, i64 %10, i64 %4)
  call void @avra_rc_retain(ptr %0)
  %12 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Edoubled"(ptr %0, i64 %4)
  br i1 %12, label %then1, label %else2

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

then1:                                            ; preds = %endif
  %add = add i64 %4, 1
  %13 = call ptr @avra_str_substring(ptr %1, i64 %4, i64 %add)
  %add4 = add i64 %4, 2
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eescaped"(ptr %2, ptr %11, ptr %13, i64 %add4)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 0)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else2 ]
  %16 = call i64 @avra_bytes_at(ptr %0, i64 %4)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eshut"()
  %cmp7 = icmp eq i64 %16, %17
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  br label %endif3

then8:                                            ; preds = %endif3
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %18, i64 1)
  call void @avra_array_push(ptr %18, i64 %4)
  call void @avra_rc_retain(ptr %18)
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efaulted"(ptr %18)
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %20, i64 1)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %20

else9:                                            ; preds = %endif3
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclose_brace"()
  %add13 = add i64 %4, 1
  %22 = call i64 @avra_bytes_index_of(ptr %0, ptr %21, i64 %add13)
  %cmp14 = icmp slt i64 %22, 0
  br i1 %cmp14, label %then15, label %else16

postret11:                                        ; No predecessors!
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  br label %endif10

then15:                                           ; preds = %endif10
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 0)
  call void @avra_array_push(ptr %23, i64 %4)
  call void @avra_rc_retain(ptr %23)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efaulted"(ptr %23)
  %25 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %25, i64 1)
  call void @avra_array_push_owned(ptr %25, ptr %24)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %25

else16:                                           ; preds = %endif10
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  %add20 = add i64 %4, 1
  %26 = call ptr @avra_str_substring(ptr %1, i64 %add20, i64 %22)
  call void @avra_rc_retain(ptr %26)
  %27 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ehole_of"(ptr %26, i64 %4)
  %28 = call i64 @avra_array_get(ptr %27, i64 0)
  switch i64 %28, label %arm21 [
    i64 1, label %arm
  ]

postret18:                                        ; No predecessors!
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  br label %endif17

arm:                                              ; preds = %endif17
  %29 = call i64 @avra_array_get(ptr %27, i64 1)
  %boxed = inttoptr i64 %29 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %30 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efaulted"(ptr %boxed)
  %31 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %31, i64 1)
  call void @avra_array_push_owned(ptr %31, ptr %30)
  call void @avra_rc_release(ptr %30)
  br label %endswitch

arm21:                                            ; preds = %endif17
  %32 = call i64 @avra_array_get(ptr %27, i64 1)
  %boxed22 = inttoptr i64 %32 to ptr
  %add23 = add i64 %22, 1
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %boxed22)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eopened"(ptr %2, ptr %11, ptr %boxed22, i64 %add23)
  %34 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %34, i64 0)
  call void @avra_array_push_owned(ptr %34, ptr %33)
  call void @avra_rc_release(ptr %33)
  br label %endswitch

endswitch:                                        ; preds = %arm21, %arm
  %regval24 = phi ptr [ %31, %arm ], [ %34, %arm21 ]
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval24
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eopened"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %5, ptr %1)
  %6 = call ptr @avra_array_concat(ptr %boxed, ptr %5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %8 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %8 to ptr
  %cmp = icmp ne ptr %boxed1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %9 = call ptr @avra_array_sized(i64 0)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %11, i64 %3)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push_owned(ptr %11, ptr %2)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclosing"(ptr %0, ptr %7)
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %15, i64 %3)
  call void @avra_array_push_owned(ptr %15, ptr %12)
  call void @avra_array_push_owned(ptr %15, ptr %13)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_array_push_owned(ptr %15, ptr %2)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %15

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ehole_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_str_index_of(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %cmp = icmp slt i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %3 = call ptr @avra_str_substring(ptr %0, i64 0, i64 %2)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %0, %then ], [ %3, %else ]
  %4 = call ptr @avra_str_trim(ptr %regval)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eshorn"(ptr %4)
  %cmp1 = icmp slt i64 %2, 0
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %add = add i64 %2, 1
  %6 = call i64 @avra_str_len(ptr %0)
  %7 = call ptr @avra_str_substring(ptr %0, i64 %add, i64 %6)
  %8 = call ptr @avra_str_trim(ptr %7)
  call void @avra_rc_release(ptr %7)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ null, %then2 ], [ %8, %else3 ]
  call void @avra_rc_retain(ptr %5)
  %9 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enamed"(ptr %5)
  %not = xor i1 %9, true
  br i1 %not, label %then6, label %else7

then6:                                            ; preds = %endif4
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 2)
  call void @avra_array_push(ptr %10, i64 %1)
  call void @avra_array_push_owned(ptr %10, ptr %0)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 1)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else7:                                            ; preds = %endif4
  br label %endif8

endif8:                                           ; preds = %else7, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else7 ]
  %cmp10 = icmp ne ptr %regval5, null
  br i1 %cmp10, label %then11, label %else12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif8

then11:                                           ; preds = %endif8
  %12 = call ptr @avra_insist(ptr %regval5)
  call void @avra_rc_retain(ptr %12)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enamed"(ptr %12)
  %not14 = xor i1 %13, true
  call void @avra_rc_release(ptr %12)
  br label %endif13

else12:                                           ; preds = %endif8
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i1 [ %not14, %then11 ], [ false, %else12 ]
  br i1 %regval15, label %then16, label %else17

then16:                                           ; preds = %endif13
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 2)
  call void @avra_array_push(ptr %14, i64 %1)
  call void @avra_array_push_owned(ptr %14, ptr %0)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 1)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %regval5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %15

else17:                                           ; preds = %endif13
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  call void @avra_rc_retain(ptr %regval5)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewritten_type"(ptr %regval5)
  %17 = call i64 @avra_streq(ptr %4, ptr %5)
  %b = icmp ne i64 %17, 0
  %not21 = xor i1 %b, true
  %18 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %18, ptr %5)
  call void @avra_array_push_owned(ptr %18, ptr %16)
  %slot = zext i1 %not21 to i64
  call void @avra_array_push(ptr %18, i64 %slot)
  %19 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %19, i64 0)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %regval5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %19

postret19:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  br label %endif18
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewritten_type"(ptr %0) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %1 = call ptr @avra_insist(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enamed_ref"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

postret:                                          ; No predecessors!
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enamed"(ptr %0) {
entry:
  %slot9 = alloca i64, align 8
  %slot4 = alloca i64, align 8
  %slot = alloca i1, align 1
  %1 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp eq i64 %1, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %2 = call i64 @avra_str_char_code(ptr %0, i64 0)
  %3 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ename_start"(i64 %2)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %3, %then ], [ false, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  store i1 true, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat$24l333" to i64))
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call ptr @avra_array_sized(i64 0)
  %7 = call i64 @avra_str_len(ptr %0)
  store i64 0, ptr %slot4, align 8
  br label %lhead

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %lexit11
  %regval24 = phi i1 [ %ld23, %lexit11 ], [ false, %else2 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval24

lhead:                                            ; preds = %lbody, %then1
  %ld = load i64, ptr %slot4, align 8
  %cmp5 = icmp slt i64 %ld, %7
  br i1 %cmp5, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %8 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot9, align 8
  br label %lhead10

lbody:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot4, align 8
  %9 = call i64 @avra_str_char_code(ptr %0, i64 %ld6)
  %10 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ename_part"(i64 %9)
  %slot7 = zext i1 %10 to i64
  call void @avra_array_push(ptr %6, i64 %slot7)
  %ld8 = load i64, ptr %slot4, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot4, align 8
  br label %lhead

lhead10:                                          ; preds = %endif19, %lexit
  %ld12 = load i64, ptr %slot9, align 8
  %cmp13 = icmp slt i64 %ld12, %8
  br i1 %cmp13, label %lbody14, label %lexit11

lexit11:                                          ; preds = %lhead10
  %ld23 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  br label %endif3

lbody14:                                          ; preds = %lhead10
  %ld15 = load i64, ptr %slot9, align 8
  %11 = call i64 @avra_array_get(ptr %6, i64 %ld15)
  %b = icmp ne i64 %11, 0
  call void @avra_rc_retain(ptr %4)
  %cast = inttoptr i64 %5 to ptr
  %12 = call i1 %cast(ptr %4, i1 %b)
  %not16 = xor i1 %12, true
  br i1 %not16, label %then17, label %else18

then17:                                           ; preds = %lbody14
  store i1 false, ptr %slot, align 8
  store i64 %8, ptr %slot9, align 8
  br label %endif19

else18:                                           ; preds = %lbody14
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval20 = phi i64 [ 0, %then17 ], [ 0, %else18 ]
  %ld21 = load i64, ptr %slot9, align 8
  %add22 = add i64 %ld21, 1
  store i64 %add22, ptr %slot9, align 8
  br label %lhead10
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat$24l333"(ptr %0, i1 %1) {
entry:
  call void @avra_rc_release(ptr %0)
  ret i1 %1
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ename_part"(i64 %0) {
entry:
  %1 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ename_start"(i64 %0)
  br i1 %1, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp = icmp sge i64 %0, 48
  br i1 %cmp, label %then1, label %else2

endif:                                            ; preds = %endif3, %then
  %regval5 = phi i1 [ true, %then ], [ %regval, %endif3 ]
  ret i1 %regval5

then1:                                            ; preds = %else
  %cmp4 = icmp sle i64 %0, 57
  br label %endif3

else2:                                            ; preds = %else
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval = phi i1 [ %cmp4, %then1 ], [ false, %else2 ]
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ename_start"(i64 %0) {
entry:
  %cmp = icmp eq i64 %0, 95
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp sge i64 %0, 65
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval6 = phi i1 [ true, %then ], [ %regval, %endif4 ]
  br i1 %regval6, label %then7, label %else8

then2:                                            ; preds = %else
  %cmp5 = icmp sle i64 %0, 90
  br label %endif4

else3:                                            ; preds = %else
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval = phi i1 [ %cmp5, %then2 ], [ false, %else3 ]
  br label %endif

then7:                                            ; preds = %endif
  br label %endif9

else8:                                            ; preds = %endif
  %cmp10 = icmp sge i64 %0, 97
  br i1 %cmp10, label %then11, label %else12

endif9:                                           ; preds = %endif13, %then7
  %regval16 = phi i1 [ true, %then7 ], [ %regval15, %endif13 ]
  ret i1 %regval16

then11:                                           ; preds = %else8
  %cmp14 = icmp sle i64 %0, 122
  br label %endif13

else12:                                           ; preds = %else8
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval15 = phi i1 [ %cmp14, %then11 ], [ false, %else12 ]
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eshorn"(ptr %0) {
entry:
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eellipsis"()
  %2 = call i64 @avra_str_ends_with(ptr %0, ptr %1)
  %b = icmp ne i64 %2, 0
  %not = xor i1 %b, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  ret ptr %0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_str_len(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eellipsis"()
  %5 = call i64 @avra_str_len(ptr %4)
  %sub = sub i64 %3, %5
  %6 = call ptr @avra_str_substring(ptr %0, i64 0, i64 %sub)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eellipsis"() {
entry:
  ret ptr getelementptr inbounds (i8, ptr @.str.4, i64 16)
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclose_brace"() {
entry:
  %0 = call ptr @avra_once_get(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %cmp = icmp ne ptr %0, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %1 = call ptr @avra_bytes_of_str(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_once_set(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %0, %then ], [ %1, %else ]
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efaulted"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eshut"() {
entry:
  ret i64 125
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eescaped"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %5, ptr %1)
  call void @avra_array_push_owned(ptr %5, ptr %2)
  %6 = call ptr @avra_array_concat(ptr %boxed, ptr %5)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %9 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed1 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %10, i64 %3)
  call void @avra_array_push_owned(ptr %10, ptr %7)
  call void @avra_array_push_owned(ptr %10, ptr %8)
  call void @avra_array_push_owned(ptr %10, ptr %6)
  call void @avra_array_push_owned(ptr %10, ptr %boxed1)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Edoubled"(ptr %0, i64 %1) {
entry:
  %add = add i64 %1, 1
  %2 = call i64 @avra_bytes_len(ptr %0)
  %cmp = icmp slt i64 %add, %2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %add1 = add i64 %1, 1
  %3 = call i64 @avra_bytes_at(ptr %0, i64 %add1)
  %4 = call i64 @avra_bytes_at(ptr %0, i64 %1)
  %cmp2 = icmp eq i64 %3, %4
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp2, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enext_brace"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eopen_brace"()
  %3 = call i64 @avra_bytes_index_of(ptr %0, ptr %2, i64 %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eclose_brace"()
  %5 = call i64 @avra_bytes_index_of(ptr %0, ptr %4, i64 %1)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eearlier"(i64 %3, i64 %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eearlier"(i64 %0, i64 %1) {
entry:
  %cmp = icmp slt i64 %0, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp1 = icmp slt i64 %1, 0
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval10 = phi i64 [ %1, %then ], [ %regval9, %endif4 ]
  ret i64 %regval10

then2:                                            ; preds = %else
  br label %endif4

else3:                                            ; preds = %else
  %cmp5 = icmp slt i64 %0, %1
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval9 = phi i64 [ %0, %then2 ], [ %regval, %endif8 ]
  br label %endif

then6:                                            ; preds = %else3
  br label %endif8

else7:                                            ; preds = %else3
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval = phi i64 [ %0, %then6 ], [ %1, %else7 ]
  br label %endif4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eopen_brace"() {
entry:
  %0 = call ptr @avra_once_get(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %cmp = icmp ne ptr %0, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %1 = call ptr @avra_bytes_of_str(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_once_set(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %0, %then ], [ %1, %else ]
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  ret ptr %regval
}
