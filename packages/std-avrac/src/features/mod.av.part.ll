; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

define ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_row"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emod$24l30" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %cast = inttoptr i64 %3 to ptr
  %6 = call i1 %cast(ptr %2, ptr %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Emod$24l30"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Erow_writes"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emethod_row"(ptr %0, ptr %1, ptr %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call ptr @avra_insist(ptr %3)
  %5 = call i64 @avra_array_get(ptr %4, i64 4)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %cmp1 = icmp eq i64 %6, 1
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp1

postret:                                          ; No predecessors!
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emethod_row"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emod$24l23" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %6)
  %cast = inttoptr i64 %4 to ptr
  %7 = call i1 %cast(ptr %3, ptr %6)
  br i1 %7, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  store i64 %5, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Emod$24l23"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %boxed3)
  %cast = inttoptr i64 %7 to ptr
  %8 = call i1 %cast(ptr %boxed2, ptr %boxed3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %8, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_row"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emod$24l41" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %6)
  %cast = inttoptr i64 %4 to ptr
  %7 = call i1 %cast(ptr %3, ptr %6)
  br i1 %7, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  store i64 %5, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Emod$24l41"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %boxed3)
  %cast = inttoptr i64 %7 to ptr
  %8 = call i1 %cast(ptr %boxed2, ptr %boxed3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %8, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_of"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_row"(ptr %1, ptr %2, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
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
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eproperty_row"(ptr %1, ptr %2, ptr %6)
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

define ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilderRow$2Epayloads"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Emethods"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

entry1:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

entry2:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

entry1:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

entry2:                                           ; No predecessors!
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Egram"() {
entry:
  %0 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_grammar"()
  ret ptr %0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_grammar"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants"(ptr %0) {
entry:
  call void @avra_rc_release(ptr %0)
  ret ptr null
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}
