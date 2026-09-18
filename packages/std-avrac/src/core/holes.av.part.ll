; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"${\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"}\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"$\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Code\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"Stmts\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Arms\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"Decls\00" }, align 16

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

define ptr @"av_$40std$2Eavrac$2Ecore$2Eplaceholder"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_str_join(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %5 = call i64 @avra_array_len(ptr %1)
  %6 = call i64 @avra_array_get(ptr %0, i64 %5)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_str_concat(ptr %4, ptr %boxed3)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %9 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_int_text(i64 %8)
  %11 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %12 = call ptr @avra_str_join(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %13 = call ptr @avra_str_concat(ptr %boxed, ptr %12)
  call void @avra_array_push_owned(ptr %2, ptr %13)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Ehole_name"(ptr %0) {
entry:
  %slot3 = alloca i64, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %1 = call i64 @avra_str_contains(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %b = icmp ne i64 %1, 0
  %not = xor i1 %b, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot1)
  store ptr %3, ptr %slot1, align 8
  store i64 0, ptr %slot2, align 8
  store i64 0, ptr %slot3, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %endif21, %endif
  %ld = load i64, ptr %slot3, align 8
  %4 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call ptr @avra_cell_unique(ptr %slot)
  %ld33 = load i64, ptr %slot2, align 8
  %6 = call i64 @avra_str_len(ptr %0)
  %7 = call ptr @avra_str_substring(ptr %0, i64 %ld33, i64 %6)
  call void @avra_array_push_owned(ptr %5, ptr %7)
  %ld34 = load ptr, ptr %slot, align 8
  %ld35 = load ptr, ptr %slot1, align 8
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %8, ptr %ld34)
  call void @avra_array_push_owned(ptr %8, ptr %ld35)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %8

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot3, align 8
  %9 = call i64 @avra_str_char_code(ptr %0, i64 %ld4)
  %cmp5 = icmp eq i64 %9, 36
  br i1 %cmp5, label %then6, label %else7

then6:                                            ; preds = %lbody
  %ld9 = load i64, ptr %slot3, align 8
  %add = add i64 %ld9, 1
  %10 = call i64 @avra_str_len(ptr %0)
  %cmp10 = icmp slt i64 %add, %10
  br label %endif8

else7:                                            ; preds = %lbody
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval11 = phi i1 [ %cmp10, %then6 ], [ false, %else7 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif8
  %ld15 = load i64, ptr %slot3, align 8
  %add16 = add i64 %ld15, 1
  %11 = call i64 @avra_str_char_code(ptr %0, i64 %add16)
  %cmp17 = icmp eq i64 %11, 123
  br label %endif14

else13:                                           ; preds = %endif8
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval18 = phi i1 [ %cmp17, %then12 ], [ false, %else13 ]
  br i1 %regval18, label %then19, label %else20

then19:                                           ; preds = %endif14
  %ld22 = load i64, ptr %slot3, align 8
  %add23 = add i64 %ld22, 2
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2Eclosing"(ptr %0, i64 %add23)
  %13 = call ptr @avra_cell_unique(ptr %slot)
  %ld24 = load i64, ptr %slot2, align 8
  %ld25 = load i64, ptr %slot3, align 8
  %14 = call ptr @avra_str_substring(ptr %0, i64 %ld24, i64 %ld25)
  call void @avra_array_push_owned(ptr %13, ptr %14)
  %15 = call ptr @avra_cell_unique(ptr %slot1)
  %ld26 = load i64, ptr %slot3, align 8
  %add27 = add i64 %ld26, 2
  %16 = call ptr @avra_str_substring(ptr %0, i64 %add27, i64 %12)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Ecore$2Edigits"(ptr %16)
  call void @avra_array_push(ptr %15, i64 %17)
  %add28 = add i64 %12, 1
  store i64 %add28, ptr %slot3, align 8
  %ld29 = load i64, ptr %slot3, align 8
  store i64 %ld29, ptr %slot2, align 8
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  br label %endif21

else20:                                           ; preds = %endif14
  %ld30 = load i64, ptr %slot3, align 8
  %add31 = add i64 %ld30, 1
  store i64 %add31, ptr %slot3, align 8
  br label %endif21

endif21:                                          ; preds = %else20, %then19
  %regval32 = phi i64 [ 0, %then19 ], [ 0, %else20 ]
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Edigits"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %1 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp slt i64 %ld, %1
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %mul = mul i64 %ld2, 10
  %ld3 = load i64, ptr %slot1, align 8
  %2 = call i64 @avra_str_char_code(ptr %0, i64 %ld3)
  %sub = sub i64 %2, 48
  %add = add i64 %mul, %sub
  store i64 %add, ptr %slot, align 8
  %ld4 = load i64, ptr %slot1, align 8
  %add5 = add i64 %ld4, 1
  store i64 %add5, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Ecore$2Eclosing"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  store i64 %1, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %2 = call i64 @avra_str_len(ptr %0)
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %then, label %else

lexit:                                            ; preds = %endif
  %ld4 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld4

then:                                             ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_str_char_code(ptr %0, i64 %ld1)
  %cmp2 = icmp ne i64 %3, 125
  br label %endif

else:                                             ; preds = %lhead
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp2, %then ], [ false, %else ]
  br i1 %regval, label %lbody, label %lexit

lbody:                                            ; preds = %endif
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Ecore$2EHoleName$2Elone"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  %1 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %2, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  store i1 true, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Eholes$24l9" to i64))
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot1, align 8
  br label %lhead

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %lexit
  %regval10 = phi i1 [ %ld9, %lexit ], [ false, %else ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval10

lhead:                                            ; preds = %endif7, %then
  %ld = load i64, ptr %slot1, align 8
  %cmp2 = icmp slt i64 %ld, %6
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld9 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  br label %endif

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld3)
  %boxed4 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed4)
  %cast = inttoptr i64 %4 to ptr
  %8 = call i1 %cast(ptr %3, ptr %boxed4)
  %not = xor i1 %8, true
  br i1 %not, label %then5, label %else6

then5:                                            ; preds = %lbody
  store i1 false, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  br label %endif7

else6:                                            ; preds = %lbody
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  %ld8 = load i64, ptr %slot1, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eholes$24l9"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_str_len(ptr %1)
  %cmp = icmp eq i64 %2, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Emeta_name"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm3 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
  ]

arm:                                              ; preds = %entry
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.5, i64 16), %arm ], [ getelementptr inbounds (i8, ptr @.str.6, i64 16), %arm1 ], [ getelementptr inbounds (i8, ptr @.str.7, i64 16), %arm2 ], [ getelementptr inbounds (i8, ptr @.str.8, i64 16), %arm3 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eholes_seat"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %2, label %arm2 [
    i64 2, label %arm
    i64 0, label %arm1
  ]

arm:                                              ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 5)
  br label %endswitch

arm1:                                             ; preds = %entry
  %cmp = icmp eq i64 %1, 1
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 4)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif, %arm
  %regval3 = phi ptr [ %3, %arm ], [ %regval, %endif ], [ %4, %arm2 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval3

then:                                             ; preds = %arm1
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  br label %endif

else:                                             ; preds = %arm1
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 4)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %5, %then ], [ %6, %else ]
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eholes_kind"(ptr %0) {
entry:
  %slot19 = alloca i64, align 8
  %slot18 = alloca i1, align 1
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %1 = call i64 @avra_array_len(ptr %0)
  %cmp = icmp slt i64 0, %1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_cell_release(ptr %slot)
  store ptr %2, ptr %slot, align 8
  call void @avra_rc_release(ptr %2)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %ld, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

then2:                                            ; preds = %endif
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %4 = call ptr @avra_insist(ptr %ld)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eclass_kind"(ptr %4)
  %cmp6 = icmp ne ptr %5, null
  %not7 = xor i1 %cmp6, true
  br i1 %not7, label %then8, label %else9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  br label %endif4

then8:                                            ; preds = %endif4
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  %6 = call i64 @avra_array_len(ptr %0)
  %cmp13 = icmp eq i64 %6, 1
  br i1 %cmp13, label %then14, label %else15

postret11:                                        ; No predecessors!
  br label %endif10

then14:                                           ; preds = %endif10
  %7 = call ptr @avra_insist(ptr %5)
  br label %endif16

else15:                                           ; preds = %endif10
  %8 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emany_of"(ptr %8)
  call void @avra_rc_release(ptr %8)
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval17 = phi ptr [ %7, %then14 ], [ %9, %else15 ]
  store i1 true, ptr %slot18, align 8
  %10 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Ecore$2Eholes$24l221" to i64))
  call void @avra_array_push_owned(ptr %10, ptr %regval17)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %12 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot19, align 8
  br label %lhead

lhead:                                            ; preds = %endif26, %endif16
  %ld20 = load i64, ptr %slot19, align 8
  %cmp21 = icmp slt i64 %ld20, %12
  br i1 %cmp21, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld29 = load i1, ptr %slot18, align 8
  br i1 %ld29, label %then30, label %else31

lbody:                                            ; preds = %lhead
  %ld22 = load i64, ptr %slot19, align 8
  %13 = call i64 @avra_array_get(ptr %0, i64 %ld22)
  %boxed = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %11 to ptr
  %14 = call i1 %cast(ptr %10, ptr %boxed)
  %not23 = xor i1 %14, true
  br i1 %not23, label %then24, label %else25

then24:                                           ; preds = %lbody
  store i1 false, ptr %slot18, align 8
  store i64 %12, ptr %slot19, align 8
  br label %endif26

else25:                                           ; preds = %lbody
  br label %endif26

endif26:                                          ; preds = %else25, %then24
  %regval27 = phi i64 [ 0, %then24 ], [ 0, %else25 ]
  %ld28 = load i64, ptr %slot19, align 8
  %add = add i64 %ld28, 1
  store i64 %add, ptr %slot19, align 8
  br label %lhead

then30:                                           ; preds = %lexit
  call void @avra_rc_retain(ptr %regval17)
  br label %endif32

else31:                                           ; preds = %lexit
  br label %endif32

endif32:                                          ; preds = %else31, %then30
  %regval33 = phi ptr [ %regval17, %then30 ], [ null, %else31 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval17)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval33
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eholes$24l221"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2Eagrees"(ptr %1, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Eagrees"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eclass_kind"(ptr %0)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emany_of"(ptr %3)
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emany_of"(ptr %1)
  %6 = call i64 @avra_array_get(ptr %4, i64 0)
  %7 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp1 = icmp eq i64 %6, %7
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %cmp1, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Emany_of"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm3 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
  ]

arm:                                              ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 1)
  br label %endswitch

arm2:                                             ; preds = %entry
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 2)
  br label %endswitch

arm3:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  br label %endswitch

endswitch:                                        ; preds = %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ %2, %arm ], [ %3, %arm1 ], [ %4, %arm2 ], [ %5, %arm3 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Ecore$2Eclass_kind"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp1 = icmp eq i64 %3, 1
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval15 = phi ptr [ %2, %then ], [ %regval14, %endif4 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval15

then2:                                            ; preds = %else
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Emany_of"(ptr %boxed)
  br label %endif4

else3:                                            ; preds = %else
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp5 = icmp eq i64 %6, 2
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif12, %then2
  %regval14 = phi ptr [ %5, %then2 ], [ %regval13, %endif12 ]
  br label %endif

then6:                                            ; preds = %else3
  br label %endif8

else7:                                            ; preds = %else3
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp9 = icmp eq i64 %7, 3
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval = phi i1 [ true, %then6 ], [ %cmp9, %else7 ]
  br i1 %regval, label %then10, label %else11

then10:                                           ; preds = %endif8
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  br label %endif12

else11:                                           ; preds = %endif8
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi ptr [ %8, %then10 ], [ null, %else11 ]
  br label %endif4
}

define i1 @"av_$40std$2Eavrac$2Ecore$2Efits"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm5 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

arm1:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp17 = icmp eq i64 %4, 4
  br i1 %cmp17, label %then18, label %else19

arm2:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp32 = icmp eq i64 %5, 4
  br i1 %cmp32, label %then33, label %else34

arm3:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp52 = icmp eq i64 %6, 4
  br i1 %cmp52, label %then53, label %else54

arm4:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %7, label %arm64 [
    i64 0, label %arm62
    i64 1, label %arm63
  ]

arm5:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %8, label %arm74 [
    i64 0, label %arm72
    i64 1, label %arm73
  ]

endswitch:                                        ; preds = %endswitch75, %endswitch65, %endif60, %endif50, %endif30, %endif
  %regval81 = phi i1 [ %regval16, %endif ], [ %regval31, %endif30 ], [ %regval51, %endif50 ], [ %regval61, %endif60 ], [ %regval71, %endswitch65 ], [ %regval80, %endswitch75 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval81

then:                                             ; preds = %arm
  %9 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %cmp6 = icmp eq i64 %10, 0
  br label %endif

else:                                             ; preds = %arm
  %11 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp7 = icmp eq i64 %11, 2
  br i1 %cmp7, label %then8, label %else9

endif:                                            ; preds = %endif14, %then
  %regval16 = phi i1 [ %cmp6, %then ], [ %regval15, %endif14 ]
  br label %endswitch

then8:                                            ; preds = %else
  br label %endif10

else9:                                            ; preds = %else
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp11 = icmp eq i64 %12, 3
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval = phi i1 [ true, %then8 ], [ %cmp11, %else9 ]
  br i1 %regval, label %then12, label %else13

then12:                                           ; preds = %endif10
  br label %endif14

else13:                                           ; preds = %endif10
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval15 = phi i1 [ true, %then12 ], [ false, %else13 ]
  br label %endif

then18:                                           ; preds = %arm1
  br label %endif20

else19:                                           ; preds = %arm1
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp21 = icmp eq i64 %13, 2
  br label %endif20

endif20:                                          ; preds = %else19, %then18
  %regval22 = phi i1 [ true, %then18 ], [ %cmp21, %else19 ]
  br i1 %regval22, label %then23, label %else24

then23:                                           ; preds = %endif20
  br label %endif25

else24:                                           ; preds = %endif20
  %14 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp26 = icmp eq i64 %14, 6
  br label %endif25

endif25:                                          ; preds = %else24, %then23
  %regval27 = phi i1 [ true, %then23 ], [ %cmp26, %else24 ]
  br i1 %regval27, label %then28, label %else29

then28:                                           ; preds = %endif25
  br label %endif30

else29:                                           ; preds = %endif25
  br label %endif30

endif30:                                          ; preds = %else29, %then28
  %regval31 = phi i1 [ true, %then28 ], [ false, %else29 ]
  br label %endswitch

then33:                                           ; preds = %arm2
  br label %endif35

else34:                                           ; preds = %arm2
  %15 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp36 = icmp eq i64 %15, 2
  br label %endif35

endif35:                                          ; preds = %else34, %then33
  %regval37 = phi i1 [ true, %then33 ], [ %cmp36, %else34 ]
  br i1 %regval37, label %then38, label %else39

then38:                                           ; preds = %endif35
  br label %endif40

else39:                                           ; preds = %endif35
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp41 = icmp eq i64 %16, 6
  br label %endif40

endif40:                                          ; preds = %else39, %then38
  %regval42 = phi i1 [ true, %then38 ], [ %cmp41, %else39 ]
  br i1 %regval42, label %then43, label %else44

then43:                                           ; preds = %endif40
  br label %endif45

else44:                                           ; preds = %endif40
  %17 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp46 = icmp eq i64 %17, 5
  br label %endif45

endif45:                                          ; preds = %else44, %then43
  %regval47 = phi i1 [ true, %then43 ], [ %cmp46, %else44 ]
  br i1 %regval47, label %then48, label %else49

then48:                                           ; preds = %endif45
  br label %endif50

else49:                                           ; preds = %endif45
  br label %endif50

endif50:                                          ; preds = %else49, %then48
  %regval51 = phi i1 [ true, %then48 ], [ false, %else49 ]
  br label %endswitch

then53:                                           ; preds = %arm3
  br label %endif55

else54:                                           ; preds = %arm3
  %18 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp56 = icmp eq i64 %18, 6
  br label %endif55

endif55:                                          ; preds = %else54, %then53
  %regval57 = phi i1 [ true, %then53 ], [ %cmp56, %else54 ]
  br i1 %regval57, label %then58, label %else59

then58:                                           ; preds = %endif55
  br label %endif60

else59:                                           ; preds = %endif55
  br label %endif60

endif60:                                          ; preds = %else59, %then58
  %regval61 = phi i1 [ true, %then58 ], [ false, %else59 ]
  br label %endswitch

arm62:                                            ; preds = %arm4
  %19 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed66 = inttoptr i64 %19 to ptr
  %20 = call i64 @avra_array_get(ptr %boxed66, i64 0)
  %cmp67 = icmp eq i64 %20, 2
  %not = xor i1 %cmp67, true
  br label %endswitch65

arm63:                                            ; preds = %arm4
  %21 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed68 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %boxed68, i64 0)
  %cmp69 = icmp eq i64 %22, 2
  %not70 = xor i1 %cmp69, true
  br label %endswitch65

arm64:                                            ; preds = %arm4
  br label %endswitch65

endswitch65:                                      ; preds = %arm64, %arm63, %arm62
  %regval71 = phi i1 [ %not, %arm62 ], [ %not70, %arm63 ], [ false, %arm64 ]
  br label %endswitch

arm72:                                            ; preds = %arm5
  %23 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed76 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed76, i64 0)
  %cmp77 = icmp eq i64 %24, 2
  br label %endswitch75

arm73:                                            ; preds = %arm5
  %25 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed78 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %boxed78, i64 0)
  %cmp79 = icmp eq i64 %26, 2
  br label %endswitch75

arm74:                                            ; preds = %arm5
  br label %endswitch75

endswitch75:                                      ; preds = %arm74, %arm73, %arm72
  %regval80 = phi i1 [ %cmp77, %arm72 ], [ %cmp79, %arm73 ], [ false, %arm74 ]
  br label %endswitch
}
