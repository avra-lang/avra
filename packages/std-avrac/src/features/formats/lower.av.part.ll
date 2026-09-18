; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_bytes_slice\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"avra_str_substring\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"a format's binds were asked before its test found the spans\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_index_of\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_of_str\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_index_of\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_index_of\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"avra_bytes_eq_at\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"avra_bytes_len\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_of_str\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_str_join\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"avra_str_concat\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_of_str\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_index_of\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"avra_str_len\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_bytes_of_str\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"avra_bytes_index_of\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"a grammar door without its declaration survived typing\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"avra_str_of_bytes\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr, ptr, i1, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr, i1)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2Ebinds"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Egrammar_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr, ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr, i64, ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_presence"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_binds"(ptr %0, i64 %1, ptr %2, i64 %3, ptr %4) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etest_regs_of"(ptr %0, i64 %1)
  %6 = call i64 @avra_array_len(ptr %5)
  %7 = call i64 @avra_array_len(ptr %2)
  %mul = mul i64 2, %7
  %add = add i64 1, %mul
  %cmp = icmp ne i64 %6, %add
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Euntested"(ptr %0)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  %10 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif

lhead:                                            ; preds = %endif8, %endif
  %ld = load i64, ptr %slot1, align 8
  %cmp3 = icmp slt i64 %ld, %10
  br i1 %cmp3, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld16 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld16)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld16

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot1, align 8
  %11 = call ptr @avra_array_get_owned(ptr %2, i64 %ld4)
  call void @avra_rc_retain(ptr %11)
  call void @avra_cell_release(ptr %slot2)
  store ptr %11, ptr %slot2, align 8
  %ld5 = load ptr, ptr %slot2, align 8
  %12 = call i64 @avra_array_get(ptr %ld5, i64 0)
  %boxed = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %13 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ebinds"(ptr %boxed)
  br i1 %13, label %then6, label %else7

then6:                                            ; preds = %lbody
  %14 = call ptr @avra_cell_unique(ptr %slot)
  %15 = call i64 @avra_array_get(ptr %5, i64 0)
  %mul9 = mul i64 2, %ld4
  %add10 = add i64 1, %mul9
  %16 = call i64 @avra_array_get(ptr %5, i64 %add10)
  %mul11 = mul i64 2, %ld4
  %add12 = add i64 2, %mul11
  %17 = call i64 @avra_array_get(ptr %5, i64 %add12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ecut"(ptr %0, i64 %15, i64 %16, i64 %17, i64 %3, ptr %4)
  call void @avra_array_push(ptr %14, i64 %18)
  br label %endif8

else7:                                            ; preds = %lbody
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval13 = phi i64 [ 0, %then6 ], [ 0, %else7 ]
  %ld14 = load i64, ptr %slot1, align 8
  %add15 = add i64 %ld14, 1
  store i64 %add15, ptr %slot1, align 8
  call void @avra_rc_release(ptr %11)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ecut"(ptr %0, i64 %1, i64 %2, i64 %3, i64 %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %3)
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %5)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed1, ptr %5)
  %11 = call i64 @avra_array_get(ptr %10, i64 0)
  %cmp = icmp eq i64 %11, 4
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %12)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 %1)
  call void @avra_array_push(ptr %14, i64 %6)
  call void @avra_array_push(ptr %14, i64 %7)
  %15 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %15, i64 7)
  call void @avra_array_push(ptr %15, i64 %13)
  call void @avra_array_push_owned(ptr %15, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %17)
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %19, i64 %4)
  call void @avra_array_push(ptr %19, i64 %6)
  call void @avra_array_push(ptr %19, i64 %7)
  %20 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %20, i64 7)
  call void @avra_array_push(ptr %20, i64 %18)
  call void @avra_array_push_owned(ptr %20, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %18

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %12)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 23)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push(ptr %4, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Euntested"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %1 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %2 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etest_regs_of"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformat_accepts"(ptr %0, i64 %1, ptr %2, ptr %3, i64 %4, ptr %5) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewalked"(ptr %0, ptr %2, ptr %3, i64 %4, ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 1)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %7)
  %9 = call i64 @avra_array_get(ptr %6, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_array_concat(ptr %8, ptr %boxed)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_test"(ptr %0, i64 %1, ptr %10)
  %12 = call i64 @avra_array_get(ptr %6, i64 0)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %12
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_test"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewalked"(ptr %0, ptr %1, ptr %2, i64 %3, ptr %4) {
entry:
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eoctets"(ptr %0, i64 %3, ptr %4)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Emeasured"(ptr %0, i64 %5)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %7)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %9 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 0, %9
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %sub = sub i64 %9, 1
  %10 = call ptr @avra_array_get_owned(ptr %2, i64 %sub)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot)
  store ptr %10, ptr %slot, align 8
  call void @avra_rc_release(ptr %10)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  %11 = call ptr @avra_insist(ptr %ld)
  %12 = call ptr @avra_array_get_owned(ptr %11, i64 1)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %12)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %13)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eminus"(ptr %0, i64 %6, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %8, i64 %15)
  call void @avra_rc_retain(ptr %1)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %1)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %8, i64 %18)
  %20 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %20)
  call void @avra_cell_release(ptr %slot1)
  store ptr %20, ptr %slot1, align 8
  %21 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %endif
  %ld4 = load i64, ptr %slot2, align 8
  %cmp5 = icmp slt i64 %ld4, %21
  br i1 %cmp5, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %12)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eanchored"(ptr %0, i64 %5, i64 %6, ptr %1, ptr %12)
  %ld8 = load ptr, ptr %slot1, align 8
  %23 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %23, i64 %22)
  call void @avra_array_push(ptr %23, i64 %5)
  call void @avra_array_push_owned(ptr %23, ptr %ld8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  call void @avra_rc_retain(ptr %2)
  %24 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Espanned"(ptr %0, ptr %23, ptr %2, i64 %19, i64 %16, i64 0)
  %25 = call i64 @avra_array_get(ptr %23, i64 1)
  %26 = call i64 @avra_array_get(ptr %23, i64 2)
  %boxed = inttoptr i64 %26 to ptr
  %27 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %27, i64 %24)
  call void @avra_array_push(ptr %27, i64 %25)
  call void @avra_array_push_owned(ptr %27, ptr %boxed)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %27

lbody:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot2, align 8
  %28 = call ptr @avra_array_get_owned(ptr %2, i64 %ld6)
  call void @avra_rc_retain(ptr %28)
  call void @avra_cell_release(ptr %slot3)
  store ptr %28, ptr %slot3, align 8
  %29 = call ptr @avra_cell_unique(ptr %slot1)
  call void @avra_rc_retain(ptr %0)
  %30 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %8, i64 %30)
  call void @avra_array_push(ptr %29, i64 %31)
  %32 = call ptr @avra_cell_unique(ptr %slot1)
  call void @avra_rc_retain(ptr %0)
  %33 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %34 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %8, i64 %33)
  call void @avra_array_push(ptr %32, i64 %34)
  %ld7 = load i64, ptr %slot2, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot2, align 8
  call void @avra_rc_release(ptr %28)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Espanned"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4, i64 %5) {
entry:
  %6 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp eq i64 %5, %6
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ehole_span"(ptr %0, ptr %1, ptr %2, i64 %5, i64 %3, i64 %4)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %10)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %14, i64 %12)
  %16 = call i64 @avra_array_get(ptr %1, i64 1)
  %17 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %17 to ptr
  %18 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %18, i64 %15)
  call void @avra_array_push(ptr %18, i64 %16)
  call void @avra_array_push_owned(ptr %18, ptr %boxed)
  %add = add i64 %5, 1
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  call void @avra_rc_retain(ptr %2)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Espanned"(ptr %0, ptr %18, ptr %2, i64 %3, i64 %4, i64 %add)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %19

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ehole_span"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4, i64 %5) {
entry:
  %6 = call i64 @avra_array_len(ptr %2)
  %sub = sub i64 %6, 1
  %cmp = icmp eq i64 %3, %sub
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elast_span"(ptr %0, ptr %1, i64 %3, i64 %4, i64 %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call i64 @avra_array_get(ptr %2, i64 %3)
  %boxed = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed1, i64 2)
  %b = icmp ne i64 %10, 0
  br i1 %b, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %11 = call i64 @avra_array_get(ptr %2, i64 %3)
  %boxed5 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %boxed5, i64 1)
  %boxed6 = inttoptr i64 %12 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed6)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egreedy_span"(ptr %0, ptr %1, i64 %3, i64 %4, ptr %boxed6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else3 ]
  %14 = call i64 @avra_array_get(ptr %2, i64 %3)
  %boxed9 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed9, i64 1)
  %boxed10 = inttoptr i64 %15 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed10)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enext_span"(ptr %0, ptr %1, i64 %3, i64 %4, ptr %boxed10)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

postret7:                                         ; No predecessors!
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Enext_span"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %3)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %6 to ptr
  %mul = mul i64 2, %2
  %7 = call i64 @avra_array_get(ptr %boxed, i64 %mul)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 24)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_array_push(ptr %8, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eliteral"(ptr %0, ptr %4)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %11)
  %13 = call i64 @avra_array_get(ptr %1, i64 1)
  %14 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %14, i64 %13)
  call void @avra_array_push(ptr %14, i64 %10)
  call void @avra_array_push(ptr %14, i64 %5)
  %15 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %15, i64 7)
  call void @avra_array_push(ptr %15, i64 %12)
  call void @avra_array_push_owned(ptr %15, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %15)
  %17 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %17 to ptr
  %mul2 = mul i64 2, %2
  %add = add i64 %mul2, 1
  %18 = call i64 @avra_array_get(ptr %boxed1, i64 %add)
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %19, i64 24)
  call void @avra_array_push(ptr %19, i64 %18)
  call void @avra_array_push(ptr %19, i64 %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %19)
  call void @avra_rc_retain(ptr %4)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %21)
  call void @avra_rc_retain(ptr %0)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eplus"(ptr %0, i64 %12, i64 %22)
  %24 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %24, i64 24)
  call void @avra_array_push(ptr %24, i64 %3)
  call void @avra_array_push(ptr %24, i64 %23)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %24)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %24)
  call void @avra_rc_retain(ptr %0)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %27)
  %29 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %29, i64 10)
  %30 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %30, i64 4)
  call void @avra_array_push(ptr %30, i64 %28)
  call void @avra_array_push_owned(ptr %30, ptr %29)
  call void @avra_array_push(ptr %30, i64 %12)
  call void @avra_array_push(ptr %30, i64 %26)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %30)
  %31 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %30)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %28
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eplus"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  %6 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %6, i64 4)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 %1)
  call void @avra_array_push(ptr %6, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %0) {
entry:
  %1 = call ptr @avra_bytes_of_str(ptr %0)
  %2 = call i64 @avra_bytes_len(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eliteral"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %2, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16), i64 %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %3)
  %6 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %6, i64 7)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %4, i64 2)
  call void @avra_array_push(ptr %4, i64 %3)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egreedy_span"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %3)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %6 to ptr
  %mul = mul i64 2, %2
  %7 = call i64 @avra_array_get(ptr %boxed, i64 %mul)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 24)
  call void @avra_array_push(ptr %8, i64 %7)
  call void @avra_array_push(ptr %8, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eliteral"(ptr %0, ptr %4)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %13)
  %15 = call i64 @avra_array_get(ptr %1, i64 1)
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 %15)
  call void @avra_array_push(ptr %16, i64 %12)
  call void @avra_array_push(ptr %16, i64 %5)
  %17 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %17, i64 7)
  call void @avra_array_push(ptr %17, i64 %14)
  call void @avra_array_push_owned(ptr %17, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %17, ptr %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %11, i64 %14)
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 -1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseeded_cell"(ptr %0, ptr %11, i64 %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efarthest"(ptr %0, ptr %1, i64 %21, i64 %19, i64 %12)
  call void @avra_rc_retain(ptr %0)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %21)
  %24 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %24 to ptr
  %mul2 = mul i64 2, %2
  %add = add i64 %mul2, 1
  %25 = call i64 @avra_array_get(ptr %boxed1, i64 %add)
  %26 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %26, i64 24)
  call void @avra_array_push(ptr %26, i64 %25)
  call void @avra_array_push(ptr %26, i64 %23)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %26)
  %27 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %26)
  call void @avra_rc_retain(ptr %4)
  %28 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %29 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %28)
  call void @avra_rc_retain(ptr %0)
  %30 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eplus"(ptr %0, i64 %23, i64 %29)
  %31 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %31, i64 24)
  call void @avra_array_push(ptr %31, i64 %3)
  call void @avra_array_push(ptr %31, i64 %30)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %31)
  %32 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %31)
  call void @avra_rc_retain(ptr %0)
  %33 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %34 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %34, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %34)
  %35 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %34)
  %36 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %36, i64 10)
  %37 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %37, i64 4)
  call void @avra_array_push(ptr %37, i64 %35)
  call void @avra_array_push_owned(ptr %37, ptr %36)
  call void @avra_array_push(ptr %37, i64 %23)
  call void @avra_array_push(ptr %37, i64 %33)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %37)
  %38 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %37)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %35
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efarthest"(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_start"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 10)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %11, i64 4)
  call void @avra_array_push(ptr %11, i64 %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 %6)
  call void @avra_array_push(ptr %11, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %11)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_cond"(ptr %0, i64 %9)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %3)
  %15 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %15, i64 24)
  call void @avra_array_push(ptr %15, i64 %2)
  call void @avra_array_push(ptr %15, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %15)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 1)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eplus"(ptr %0, i64 %14, i64 %17)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %19)
  %21 = call i64 @avra_array_get(ptr %1, i64 1)
  %22 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %22, i64 %21)
  call void @avra_array_push(ptr %22, i64 %4)
  call void @avra_array_push(ptr %22, i64 %18)
  %23 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %23, i64 7)
  call void @avra_array_push(ptr %23, i64 %20)
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  %24 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %23)
  %25 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %25, i64 24)
  call void @avra_array_push(ptr %25, i64 %3)
  call void @avra_array_push(ptr %25, i64 %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %25)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %25)
  call void @avra_rc_retain(ptr %0)
  %27 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eloop_end"(ptr %0)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %27
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elast_span"(ptr %0, ptr %1, i64 %2, i64 %3, i64 %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eloaded_from"(ptr %0, i64 %4)
  %7 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  %mul = mul i64 2, %2
  %8 = call i64 @avra_array_get(ptr %boxed, i64 %mul)
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %9, i64 24)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_array_push(ptr %9, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  %11 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %11 to ptr
  %mul2 = mul i64 2, %2
  %add = add i64 %mul2, 1
  %12 = call i64 @avra_array_get(ptr %boxed1, i64 %add)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 24)
  call void @avra_array_push(ptr %13, i64 %12)
  call void @avra_array_push(ptr %13, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %13)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %15)
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 8)
  %18 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %18, i64 4)
  call void @avra_array_push(ptr %18, i64 %16)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  call void @avra_array_push(ptr %18, i64 %5)
  call void @avra_array_push(ptr %18, i64 %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %18)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %18)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %16
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eanchored"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %3)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %4)
  %add = add i64 %5, %6
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %add)
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 10)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %11, i64 4)
  call void @avra_array_push(ptr %11, i64 %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 %2)
  call void @avra_array_push(ptr %11, i64 %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %11)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %9)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  call void @avra_rc_retain(ptr %3)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eat_span"(ptr %0, i64 %1, i64 %14, i64 %16, ptr %3)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %17)
  call void @avra_rc_retain(ptr %0)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %21, i64 %19)
  call void @avra_rc_retain(ptr %0)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %22)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %24 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etail_span"(ptr %0, i64 %1, i64 %2, ptr %4)
  call void @avra_rc_retain(ptr %0)
  %25 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %24)
  call void @avra_rc_retain(ptr %0)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %27)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %28)
  %29 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %28, i64 %26)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %29
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etail_span"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ebyte_length"(ptr %3)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eminus"(ptr %0, i64 %2, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eat_span"(ptr %0, i64 %1, i64 %6, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eat_span"(ptr %0, i64 %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eliteral"(ptr %0, ptr %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %6)
  %8 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %8, i64 %1)
  call void @avra_array_push(ptr %8, i64 %2)
  call void @avra_array_push(ptr %8, i64 %3)
  call void @avra_array_push(ptr %8, i64 %5)
  %9 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %9, i64 7)
  call void @avra_array_push(ptr %9, i64 %7)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eminus"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 1)
  %6 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %6, i64 4)
  call void @avra_array_push(ptr %6, i64 %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 %1)
  call void @avra_array_push(ptr %6, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Emeasured"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %2, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eoctets"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eseen_shape"(ptr %boxed1, ptr %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %cmp = icmp eq i64 %6, 4
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %7, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elower_print$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elower_print"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elower_parse$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elower_parse"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elower_print"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egrammar_at"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Edoorless"(ptr %0, i64 %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %3)
  %7 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %9 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed1 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eread_fields"(ptr %0, i64 %8, ptr %boxed1)
  %11 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %11)
  %13 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed2 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %10)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Esurvives"(ptr %0, ptr %boxed2, ptr %10, i64 0)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %10)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewoven"(ptr %0, ptr %6, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %0, ptr %12, i1 false, i64 %16)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %17)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %0, ptr %12)
  %20 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr %0, i64 %20, i64 %19)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %21

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewoven"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %boxed)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  %6 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %7 = call i64 @avra_array_len(ptr %6)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld7 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eglued"(ptr %0, ptr %ld7)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 %ld3)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot2)
  store ptr %9, ptr %slot2, align 8
  %10 = call ptr @avra_cell_unique(ptr %slot)
  %11 = call i64 @avra_array_get(ptr %2, i64 %ld3)
  call void @avra_array_push(ptr %10, i64 %11)
  %12 = call ptr @avra_cell_unique(ptr %slot)
  %ld4 = load ptr, ptr %slot2, align 8
  %13 = call i64 @avra_array_get(ptr %ld4, i64 1)
  %boxed5 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed5)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %boxed5)
  call void @avra_array_push(ptr %12, i64 %14)
  %ld6 = load i64, ptr %slot1, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eglued"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_len(ptr %1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %4, i64 3)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %5, i64 8)
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %7, i64 %3, ptr %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %10)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %12, i64 %7)
  call void @avra_array_push(ptr %12, i64 %9)
  %13 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %13, i64 7)
  call void @avra_array_push(ptr %13, i64 %11)
  call void @avra_array_push_owned(ptr %13, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Esurvives"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %4 = call i64 @avra_array_len(ptr %1)
  %sub = sub i64 %4, 1
  %cmp = icmp sge i64 %3, %sub
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 true)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eholds"(ptr %0, ptr %1, ptr %2, i64 %3)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %6)
  %add = add i64 %3, 1
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Esurvives"(ptr %0, ptr %1, ptr %2, i64 %add)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %8)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %12, i64 %10)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eholds"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 %3)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed1, i64 2)
  %b = icmp ne i64 %6, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eunpassed"(ptr %0, ptr %1, ptr %2, i64 %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %8 = call i64 @avra_array_get(ptr %2, i64 %3)
  %9 = call i64 @avra_array_get(ptr %1, i64 %3)
  %boxed2 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed3)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eunmoved"(ptr %0, i64 %8, ptr %boxed3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eunmoved"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert2"(ptr %0, ptr %3, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16), i64 %1, i64 %4)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16), i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eliteral"(ptr %0, ptr %2)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %10)
  %12 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %12, i64 %7)
  call void @avra_array_push(ptr %12, i64 %8)
  call void @avra_array_push(ptr %12, i64 %9)
  %13 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %13, i64 7)
  call void @avra_array_push(ptr %13, i64 %11)
  call void @avra_array_push_owned(ptr %13, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %13)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %15, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16), i64 %1)
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %17)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 5)
  %20 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %20, i64 4)
  call void @avra_array_push(ptr %20, i64 %18)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_array_push(ptr %20, i64 %11)
  call void @avra_array_push(ptr %20, i64 %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %18
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert2"(ptr %0, ptr %1, ptr %2, i64 %3, i64 %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %1)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 %3)
  call void @avra_array_push(ptr %6, i64 %4)
  %7 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %7, i64 7)
  call void @avra_array_push(ptr %7, i64 %5)
  call void @avra_array_push_owned(ptr %7, ptr %2)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eunpassed"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etrailing"(ptr %0, ptr %1, ptr %2, i64 %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ert1"(ptr %0, ptr %5, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16), i64 %4)
  %7 = call i64 @avra_array_get(ptr %1, i64 %3)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eliteral"(ptr %0, ptr %boxed1)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 1)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %11)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 %6)
  call void @avra_array_push(ptr %13, i64 %9)
  call void @avra_array_push(ptr %13, i64 %10)
  %14 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %14, i64 7)
  call void @avra_array_push(ptr %14, i64 %12)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %14)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %17)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %19, i64 7)
  %20 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %20, i64 4)
  call void @avra_array_push(ptr %20, i64 %18)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_array_push(ptr %20, i64 %12)
  call void @avra_array_push(ptr %20, i64 %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %18
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etrailing"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %slot3 = alloca ptr, align 8
  store ptr null, ptr %slot3, align 8
  %slot2 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %3)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %boxed1)
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 %6)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  %8 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot2, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot2, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld9 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld9)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eglued"(ptr %0, ptr %ld9)
  call void @avra_cell_release(ptr %slot3)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot2, align 8
  %10 = call ptr @avra_array_get_owned(ptr %1, i64 %ld4)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot3)
  store ptr %10, ptr %slot3, align 8
  %cmp5 = icmp sgt i64 %ld4, %3
  br i1 %cmp5, label %then, label %else

then:                                             ; preds = %lbody
  %11 = call ptr @avra_cell_unique(ptr %slot)
  %12 = call i64 @avra_array_get(ptr %2, i64 %ld4)
  call void @avra_array_push(ptr %11, i64 %12)
  %13 = call ptr @avra_cell_unique(ptr %slot)
  %ld6 = load ptr, ptr %slot3, align 8
  %14 = call i64 @avra_array_get(ptr %ld6, i64 1)
  %boxed7 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed7)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Etext_const"(ptr %0, ptr %boxed7)
  call void @avra_array_push(ptr %13, i64 %15)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld8 = load i64, ptr %slot2, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot2, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eread_fields"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %5)
  %7 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  %8 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld5)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld5

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %9 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot2)
  store ptr %9, ptr %slot2, align 8
  %10 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %6)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Efield_read"(ptr %0, i64 %3, ptr %4, i64 %ld3, ptr %6)
  call void @avra_array_push(ptr %10, i64 %11)
  %ld4 = load i64, ptr %slot1, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %9)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Edoorless"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egrammar_at"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed, ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm1 [
    i64 20, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed3, i64 4)
  %boxed4 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed4)
  call void @avra_rc_retain(ptr %boxed2)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Egrammar_of"(ptr %boxed4, ptr %boxed2)
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval = phi ptr [ %10, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Elower_parse"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egrammar_at"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %3, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Edoorless"(ptr %0, i64 %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %3)
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %7)
  %9 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eseen_at"(ptr %0, i64 %10)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  %cmp1 = icmp eq i64 %12, 4
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %8)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efrom_octets"(ptr %0, ptr %1, ptr %6, ptr %8)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %14 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed7 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed7, i64 0)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %8)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eread_into"(ptr %0, ptr %6, i64 %16, ptr %8)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

postret5:                                         ; No predecessors!
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eread_into"(ptr %0, ptr %1, i64 %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewalked"(ptr %0, ptr %4, ptr %boxed, i64 %2, ptr %7)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %9)
  %11 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed1 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %3)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egathered"(ptr %0, ptr %8, ptr %boxed1, i64 %2, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %0, ptr %3, i1 false, i64 %12)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %3, i64 %15)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %16
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egathered"(ptr %0, ptr %1, ptr %2, i64 %3, ptr %4) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_type"(ptr %0, ptr %4)
  %6 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  %7 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %7
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld10 = load ptr, ptr %slot, align 8
  %8 = call i64 @avra_array_len(ptr %ld10)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %5)
  %ld11 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld11)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %10, i64 %9, ptr %ld11)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %10

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %12 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %12)
  call void @avra_cell_release(ptr %slot2)
  store ptr %12, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  %13 = call i64 @avra_array_get(ptr %ld4, i64 0)
  %boxed = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %14 = call i1 @"av_$40std$2Eavrac$2Ecore$2Ebinds"(ptr %boxed)
  br i1 %14, label %then, label %else

then:                                             ; preds = %lbody
  %15 = call ptr @avra_cell_unique(ptr %slot)
  %16 = call i64 @avra_array_get(ptr %1, i64 1)
  %17 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed5 = inttoptr i64 %17 to ptr
  %mul = mul i64 2, %ld3
  %18 = call i64 @avra_array_get(ptr %boxed5, i64 %mul)
  %19 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed6 = inttoptr i64 %19 to ptr
  %mul7 = mul i64 2, %ld3
  %add = add i64 %mul7, 1
  %20 = call i64 @avra_array_get(ptr %boxed6, i64 %add)
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %21, i64 3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %21)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ecut"(ptr %0, i64 %16, i64 %18, i64 %20, i64 %3, ptr %22)
  call void @avra_array_push(ptr %15, i64 %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld8 = load i64, ptr %slot1, align 8
  %add9 = add i64 %ld8, 1
  store i64 %add9, ptr %slot1, align 8
  call void @avra_rc_release(ptr %12)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Efrom_octets"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %5)
  %7 = call ptr @avra_array_get_owned(ptr %2, i64 0)
  %8 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed1 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ewalked"(ptr %0, ptr %7, ptr %boxed1, i64 %6, ptr %10)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_region"(ptr %0, i64 %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ecrossed_into"(ptr %0, ptr %11, ptr %2, i64 %6, ptr %3)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %0, ptr %3)
  %17 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr %0, i64 %17, i64 %16)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %18
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Ecrossed_into"(ptr %0, ptr %1, ptr %2, i64 %3, ptr %4) {
entry:
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 3)
  %6 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %6, i64 7)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_ty"(ptr %0, ptr %7)
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 %3)
  %10 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %10, i64 7)
  call void @avra_array_push(ptr %10, i64 %8)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eopen_presence"(ptr %0, i64 %8, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ecarried_of"(ptr %0, i64 %8, ptr %7)
  %14 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Egathered"(ptr %0, ptr %1, ptr %boxed, i64 %13, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eadopted"(ptr %0, ptr %4, i1 false, i64 %15)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %16)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eabsent_of"(ptr %0, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region_as"(ptr %0, ptr %4, i64 %18)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %19
}
