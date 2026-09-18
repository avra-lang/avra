; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"defect: a disarmed query database was reused\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"rev \00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c": \00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c" hits, \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c" misses\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare void @avra_trap(ptr)

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Edisarm"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %3 = call ptr @avra_array_get_owned(ptr %ld, i64 2)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld2 = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld2, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_slot_set_owned(ptr %5, i64 2, ptr %2)
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld5)
  %6 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 %ld3)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Equery$2Enever_verify$24w" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %8)
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Equery$2Enever_verify$24w"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @"av_$40std$2Eavrac$2Equery$2Enever_verify"(i64 %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_slot_set_owned(ptr %boxed, i64 0, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Equery$2Enever_verify"(i64 %0) {
entry:
  %1 = call ptr @avra_str_crossing(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_trap(ptr %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret i64 %0
}

define ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0) {
entry:
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Eevict_family"(ptr %0, i64 %1) {
entry:
  %slot8 = alloca ptr, align 8
  store ptr null, ptr %slot8, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  store i64 %1, ptr %slot1, align 8
  %ld = load ptr, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %ld, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld2 = load i64, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %ld3, i64 1)
  %boxed4 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed4)
  %mul = mul i64 %6, 256
  %cmp = icmp slt i64 %ld2, %mul
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld13 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld13)
  %7 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld13)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

lbody:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot1, align 8
  %8 = call i64 @avra_int_div(i64 %ld5, i64 256)
  %ld6 = load i64, ptr %slot1, align 8
  %9 = call i64 @avra_int_mod(i64 %ld6, i64 256)
  %ld7 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld7)
  %10 = call ptr @avra_array_get_owned(ptr %ld7, i64 1)
  %11 = call ptr @avra_array_get_owned(ptr %10, i64 %8)
  call void @avra_rc_retain(ptr %11)
  call void @avra_cell_release(ptr %slot8)
  store ptr %11, ptr %slot8, align 8
  %ld9 = load ptr, ptr %slot8, align 8
  %12 = call i64 @avra_array_len(ptr %ld9)
  %cmp10 = icmp slt i64 %9, %12
  br i1 %cmp10, label %then, label %else

then:                                             ; preds = %lbody
  %13 = call ptr @avra_cell_unique(ptr %slot8)
  call void @avra_slot_set(ptr %13, i64 %9, i64 0)
  %14 = call ptr @avra_cell_unique(ptr %slot)
  %15 = call ptr @avra_slot_unique(ptr %14, i64 1)
  %ld11 = load ptr, ptr %slot8, align 8
  call void @avra_slot_set_owned(ptr %15, i64 %8, ptr %ld11)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld12 = load i64, ptr %slot1, align 8
  %add = add i64 %ld12, %4
  store i64 %add, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot8)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %ld7)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Esettle"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot)
  store ptr %3, ptr %slot, align 8
  %4 = call ptr @avra_cell_unique(ptr %slot)
  %5 = call ptr @avra_slot_unique(ptr %4, i64 3)
  %6 = call ptr @avra_array_pop_owned(ptr %5)
  %7 = call ptr @avra_array_get_owned(ptr %6, i64 0)
  %8 = call ptr @avra_cell_unique(ptr %slot)
  %9 = call ptr @avra_slot_unique(ptr %8, i64 4)
  %10 = call ptr @avra_array_pop_owned(ptr %9)
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_rc_retain(ptr %1)
  %11 = call ptr @"av_$40std$2Eavrac$2Equery$2Estate_cell"(ptr %ld, ptr %1)
  %cmp = icmp ne ptr %11, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %12 = call ptr @avra_insist(ptr %11)
  %13 = call i64 @avra_array_get(ptr %12, i64 3)
  %cmp1 = icmp eq i64 %13, %2
  call void @avra_rc_release(ptr %12)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %14 = call ptr @avra_insist(ptr %11)
  %15 = call i64 @avra_array_get(ptr %14, i64 1)
  call void @avra_rc_release(ptr %14)
  br label %endif4

else3:                                            ; preds = %endif
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  %16 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %ld5)
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i64 [ %15, %then2 ], [ %16, %else3 ]
  %ld7 = load ptr, ptr %slot, align 8
  %ld8 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld8)
  %17 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %ld8)
  %18 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %18, ptr %7)
  call void @avra_array_push(ptr %18, i64 %regval6)
  call void @avra_array_push(ptr %18, i64 %17)
  call void @avra_array_push(ptr %18, i64 %2)
  call void @avra_rc_retain(ptr %ld7)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Equery$2Ewrite_cell"(ptr %ld7, ptr %1, ptr %18)
  %ld9 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld9)
  %20 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld9)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %20
}

define i64 @"av_$40std$2Eavrac$2Equery$2Ewrite_cell"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_slot"(ptr %0, ptr %1)
  %4 = call i64 @avra_int_div(i64 %3, i64 256)
  %5 = call i64 @avra_int_mod(i64 %3, i64 256)
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sle i64 %7, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 %4)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  br label %lhead1

lbody:                                            ; preds = %lhead
  %10 = call ptr @avra_slot_unique(ptr %0, i64 1)
  %11 = call ptr @avra_array_sized(i64 0)
  call void @avra_array_push_owned(ptr %10, ptr %11)
  call void @avra_rc_release(ptr %11)
  br label %lhead

lhead1:                                           ; preds = %lbody4, %lexit
  %ld = load ptr, ptr %slot, align 8
  %12 = call i64 @avra_array_len(ptr %ld)
  %cmp3 = icmp sle i64 %12, %5
  br i1 %cmp3, label %lbody4, label %lexit2

lexit2:                                           ; preds = %lhead1
  %13 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_slot_set_owned(ptr %13, i64 %5, ptr %2)
  %14 = call ptr @avra_slot_unique(ptr %0, i64 1)
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_slot_set_owned(ptr %14, i64 %4, ptr %ld5)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody4:                                           ; preds = %lhead1
  %15 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_array_push(ptr %15, i64 0)
  br label %lhead1
}

define i64 @"av_$40std$2Eavrac$2Equery$2Estate_slot"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %4 = call i64 @avra_array_get(ptr %boxed, i64 %3)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_len(ptr %boxed2)
  %mul = mul i64 %5, %7
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  %add = add i64 %mul, %8
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %add
}

define i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  call void @avra_rc_release(ptr %0)
  ret i64 %1
}

define ptr @"av_$40std$2Eavrac$2Equery$2Estate_cell"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_slot"(ptr %0, ptr %1)
  %3 = call i64 @avra_int_div(i64 %2, i64 256)
  %4 = call i64 @avra_int_mod(i64 %2, i64 256)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp sge i64 %3, %6
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 %3)
  %9 = call i64 @avra_array_len(ptr %8)
  %cmp1 = icmp sge i64 %4, %9
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 %4)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret5:                                         ; No predecessors!
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Erevision"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ebegin"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_cell_unique(ptr %slot)
  %5 = call ptr @avra_slot_unique(ptr %4, i64 3)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %3)
  call void @avra_array_push_owned(ptr %5, ptr %6)
  %7 = call ptr @avra_cell_unique(ptr %slot)
  %8 = call ptr @avra_slot_unique(ptr %7, i64 4)
  call void @avra_array_push_owned(ptr %8, ptr %1)
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld)
  %9 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %9
}

define ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Eask"(ptr %0, ptr %1) {
entry:
  %slot26 = alloca ptr, align 8
  store ptr null, ptr %slot26, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Erecord_dep"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  store i1 false, ptr %slot, align 8
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Equery$2Edb$24l136" to i64))
  call void @avra_array_push_owned(ptr %4, ptr %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %6 = call ptr @avra_array_get_owned(ptr %3, i64 4)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  br i1 %ld4, label %then5, label %else6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %8 = call i64 @avra_array_get(ptr %6, i64 %ld2)
  %boxed = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %5 to ptr
  %9 = call i1 %cast(ptr %4, ptr %boxed)
  br i1 %9, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %7, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

then5:                                            ; preds = %lexit
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 2)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

else6:                                            ; preds = %lexit
  br label %endif7

endif7:                                           ; preds = %else6, %postret
  %regval8 = phi i64 [ 0, %postret ], [ 0, %else6 ]
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %1)
  %11 = call ptr @"av_$40std$2Eavrac$2Equery$2Estate_cell"(ptr %3, ptr %1)
  %cmp9 = icmp ne ptr %11, null
  %not = xor i1 %cmp9, true
  br i1 %not, label %then10, label %else11

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %10)
  br label %endif7

then10:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Emiss"(ptr %0)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else11:                                           ; preds = %endif7
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  %13 = call ptr @avra_insist(ptr %11)
  %14 = call i64 @avra_array_get(ptr %13, i64 2)
  call void @avra_rc_retain(ptr %3)
  %15 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %3)
  %cmp15 = icmp eq i64 %14, %15
  br i1 %cmp15, label %then16, label %else17

postret13:                                        ; No predecessors!
  call void @avra_rc_release(ptr %12)
  br label %endif12

then16:                                           ; preds = %endif12
  call void @avra_rc_retain(ptr %0)
  %16 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Ehit"(ptr %0)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else17:                                           ; preds = %endif12
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %17 = call i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Eany_dep_changed"(ptr %0, ptr %13)
  br i1 %17, label %then21, label %else22

postret19:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  br label %endif18

then21:                                           ; preds = %endif18
  call void @avra_rc_retain(ptr %0)
  %18 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Emiss"(ptr %0)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %18

else22:                                           ; preds = %endif18
  br label %endif23

endif23:                                          ; preds = %else22, %postret24
  %regval25 = phi i64 [ 0, %postret24 ], [ 0, %else22 ]
  call void @avra_rc_retain(ptr %0)
  %19 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %19)
  call void @avra_cell_release(ptr %slot26)
  store ptr %19, ptr %slot26, align 8
  %ld27 = load ptr, ptr %slot26, align 8
  %20 = call ptr @avra_array_get_owned(ptr %13, i64 0)
  %21 = call i64 @avra_array_get(ptr %13, i64 1)
  %ld28 = load ptr, ptr %slot26, align 8
  call void @avra_rc_retain(ptr %ld28)
  %22 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %ld28)
  %23 = call i64 @avra_array_get(ptr %13, i64 3)
  %24 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %24, ptr %20)
  call void @avra_array_push(ptr %24, i64 %21)
  call void @avra_array_push(ptr %24, i64 %22)
  call void @avra_array_push(ptr %24, i64 %23)
  call void @avra_rc_retain(ptr %ld27)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %24)
  %25 = call i64 @"av_$40std$2Eavrac$2Equery$2Ewrite_cell"(ptr %ld27, ptr %1, ptr %24)
  %ld29 = load ptr, ptr %slot26, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld29)
  %26 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld29)
  call void @avra_rc_retain(ptr %0)
  %27 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Ehit"(ptr %0)
  call void @avra_cell_release(ptr %slot26)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %27

postret24:                                        ; No predecessors!
  call void @avra_rc_release(ptr %18)
  br label %endif23
}

define i1 @"av_$40std$2Eavrac$2Equery$2Edb$24l136"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Equery$2Esame_key"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Equery$2Esame_key"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %cmp1 = icmp eq i64 %4, %5
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Eany_dep_changed"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 %ld2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot1)
  store ptr %4, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld3)
  %6 = call i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Echanged_after"(ptr %0, ptr %ld3, i64 %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Echanged_after"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  %4 = call i64 @avra_array_get(ptr %3, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %6 = call i64 @avra_array_get(ptr %boxed, i64 %5)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %1, i64 1)
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %boxed1)
  %cast = inttoptr i64 %8 to ptr
  %9 = call i64 %cast(ptr %boxed1, i64 %7)
  %cmp = icmp sgt i64 %9, %2
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Ehit"(ptr %0) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %ld, i64 5)
  %add = add i64 %2, 1
  %3 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_slot_set(ptr %3, i64 5, i64 %add)
  %ld1 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld1)
  %4 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Emiss"(ptr %0) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_cell_release(ptr %slot)
  store ptr %1, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %ld, i64 6)
  %add = add i64 %2, 1
  %3 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_slot_set(ptr %3, i64 6, i64 %add)
  %ld1 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld1)
  %4 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Erecord_dep"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  %3 = call i64 @avra_array_get(ptr %2, i64 3)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %6 = call i64 @avra_array_len(ptr %5)
  %cmp1 = icmp slt i64 0, %6
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %sub = sub i64 %6, 1
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 %sub)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi i64 [ 0, %then2 ], [ 0, %else3 ]
  %ld = load ptr, ptr %slot, align 8
  %8 = call ptr @avra_insist(ptr %ld)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %boxed6 = inttoptr i64 %9 to ptr
  call void @avra_array_push_owned(ptr %boxed6, ptr %1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Eset_input"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot)
  store ptr %3, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Equery$2Estate_cell"(ptr %ld, ptr %1)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_insist(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 3)
  %cmp1 = icmp eq i64 %6, %2
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %ld5 = load ptr, ptr %slot, align 8
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call ptr @avra_insist(ptr %4)
  %9 = call i64 @avra_array_get(ptr %8, i64 1)
  %ld6 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld6)
  %10 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %ld6)
  %11 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  call void @avra_array_push(ptr %11, i64 %9)
  call void @avra_array_push(ptr %11, i64 %10)
  call void @avra_array_push(ptr %11, i64 %2)
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Equery$2Ewrite_cell"(ptr %ld5, ptr %1, ptr %11)
  %ld7 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld7)
  %13 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld7)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval8 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %cmp9 = icmp ne ptr %4, null
  br i1 %cmp9, label %then10, label %else11

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif4

then10:                                           ; preds = %endif4
  %ld13 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld13)
  %14 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %ld13)
  %add = add i64 %14, 1
  %15 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_slot_set(ptr %15, i64 0, i64 %add)
  br label %endif12

else11:                                           ; preds = %endif4
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval14 = phi i64 [ 0, %then10 ], [ 0, %else11 ]
  %ld15 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld15)
  %16 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %ld15)
  %ld16 = load ptr, ptr %slot, align 8
  %17 = call ptr @avra_array_sized(i64 0)
  %18 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_array_push(ptr %18, i64 %16)
  call void @avra_array_push(ptr %18, i64 %16)
  call void @avra_array_push(ptr %18, i64 %2)
  call void @avra_rc_retain(ptr %ld16)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Equery$2Ewrite_cell"(ptr %ld16, ptr %1, ptr %18)
  %ld17 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld17)
  %20 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld17)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %20
}

define ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Estats"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %1)
  %3 = call ptr @avra_int_text(i64 %2)
  %4 = call i64 @avra_array_get(ptr %1, i64 5)
  %5 = call ptr @avra_int_text(i64 %4)
  %6 = call i64 @avra_array_get(ptr %1, i64 6)
  %7 = call ptr @avra_int_text(i64 %6)
  %8 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %3)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %9 = call ptr @avra_str_join(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9
}

define i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Eactive"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Equery$2Edb$24l210" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 4)
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
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %3 to ptr
  %8 = call i1 %cast(ptr %2, ptr %boxed)
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

define i1 @"av_$40std$2Eavrac$2Equery$2Edb$24l210"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Equery$2Esame_key"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Equery$2EDb$2Efamily_active"(ptr %0, i64 %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Equery$2Edb$24l217" to i64))
  call void @avra_array_push(ptr %2, i64 %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  %5 = call ptr @avra_array_get_owned(ptr %4, i64 4)
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
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld2)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %3 to ptr
  %8 = call i1 %cast(ptr %2, ptr %boxed)
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

define i1 @"av_$40std$2Eavrac$2Equery$2Edb$24l217"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %cmp = icmp eq i64 %2, %3
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Echanged_at"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Equery$2Estate_cell"(ptr %2, ptr %1)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %3, i64 1)
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %4, 1
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %pack, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  br i1 %x, label %then1, label %else2

then1:                                            ; preds = %endif
  %x4 = extractvalue { i1, i64 } %regval, 1
  br label %endif3

else2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %2)
  %5 = call i64 @"av_$40std$2Eavrac$2Equery$2Estate_revision"(ptr %2)
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval5 = phi i64 [ %x4, %then1 ], [ %5, %else2 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval5
}

define i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Efamily"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Equery$2EDb$2Esnapshot"(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  %3 = call ptr @avra_cell_unique(ptr %slot)
  %4 = call ptr @avra_slot_unique(ptr %3, i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  %ld = load ptr, ptr %slot, align 8
  %5 = call i64 @avra_array_get(ptr %ld, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed)
  %sub = sub i64 %6, 1
  %ld1 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld1)
  %7 = call i64 @"av_$40std$2Eavrac$2Equery$2EDb$2Ereplace"(ptr %0, ptr %ld1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %sub
}

define ptr @"av_$40std$2Eavrac$2Equery$2Enew_db"() {
entry:
  %0 = call ptr @avra_array_sized(i64 0)
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %4, i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push(ptr %4, i64 0)
  call void @avra_array_push(ptr %4, i64 0)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}
