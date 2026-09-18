; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [51 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 50 }, [51 x i8] c"a variant literal without its enum survived typing\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [48 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 47 }, [48 x i8] c"an `is` without an enum variant survived typing\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"a `match` without arms survived typing\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"an arm naming no variant survived typing\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [51 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 50 }, [51 x i8] c"a format pattern reached the enum lowering's binds\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [50 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 49 }, [50 x i8] c"a format pattern reached the enum lowering's test\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [51 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 50 }, [51 x i8] c"a variant pattern without its enum survived typing\00" }, align 16

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

declare { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr, i1)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etagged_value"(ptr, i64, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr, i64, ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayloads_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_at"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr, i64, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_of"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums_reg"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  switch i64 %5, label %arm4 [
    i64 20, label %arm
    i64 28, label %arm2
    i64 29, label %arm3
  ]

arm:                                              ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 1)
  %7 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed5 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed5)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ematched_reg"(ptr %0, i64 %1, i64 %6, ptr %boxed5)
  br label %endswitch

arm2:                                             ; preds = %entry
  %9 = call i64 @avra_array_get(ptr %4, i64 1)
  %10 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed6 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed6)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Easked_reg"(ptr %0, i64 %1, i64 %9, ptr %boxed6)
  br label %endswitch

arm3:                                             ; preds = %entry
  %12 = call ptr @avra_array_get_owned(ptr %4, i64 1)
  %13 = call i64 @avra_array_get(ptr %4, i64 2)
  %boxed7 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %boxed7)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eliteral_reg"(ptr %0, i64 %1, ptr %12, ptr %boxed7)
  call void @avra_rc_release(ptr %12)
  br label %endswitch

arm4:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eforeign_node"(ptr %0, i64 %1)
  br label %endswitch

endswitch:                                        ; preds = %arm4, %arm3, %arm2, %arm
  %regval = phi i64 [ %8, %arm ], [ %11, %arm2 ], [ %14, %arm3 ], [ %15, %arm4 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eliteral_reg"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr %0, i64 %1)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %4, ptr %2)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %5, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  %not = xor i1 %x, true
  br i1 %not, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  %7 = call ptr @avra_array_sized(i64 0)
  %8 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif3

lhead:                                            ; preds = %lbody, %endif3
  %ld = load i64, ptr %slot, align 8
  %cmp5 = icmp slt i64 %ld, %8
  br i1 %cmp5, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %9 = call i64 @avra_array_len(ptr %7)
  %add8 = add i64 1, %9
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 %add8)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %x9 = extractvalue { i1, i64 } %regval, 0
  %x10 = extractvalue { i1, i64 } %regval, 1
  %slot11 = zext i1 %x9 to i64
  %12 = call i64 @avra_insist_scalar(i64 %slot11, i64 %x10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etagged_value"(ptr %0, i64 %11, i64 %10, i64 %12, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

lbody:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot, align 8
  %14 = call i64 @avra_array_get(ptr %3, i64 %ld6)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %14)
  call void @avra_array_push(ptr %7, i64 %15)
  %ld7 = load i64, ptr %slot, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Easked_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %3)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %4, ptr %3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %5, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  %not = xor i1 %x, true
  br i1 %not, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr %0, i64 %8)
  %x5 = extractvalue { i1, i64 } %regval, 0
  %x6 = extractvalue { i1, i64 } %regval, 1
  %slot = zext i1 %x5 to i64
  %10 = call i64 @avra_insist_scalar(i64 %slot, i64 %x6)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %10)
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 5)
  %14 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %14, i64 4)
  call void @avra_array_push(ptr %14, i64 %12)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_array_push(ptr %14, i64 %9)
  call void @avra_array_push(ptr %14, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  br label %endif3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ematched_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_len(ptr %3)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %2)
  %9 = call i64 @avra_array_len(ptr %3)
  %cmp1 = icmp eq i64 %9, 1
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  br label %endif

then2:                                            ; preds = %endif
  %10 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_reg"(ptr %0, i64 %7, ptr %8, ptr %boxed, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_at"(ptr %0, i64 %2)
  %cmp7 = icmp ne ptr %13, null
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %11)
  br label %endif4

then8:                                            ; preds = %endif4
  %14 = call i64 @avra_array_len(ptr %3)
  %sub = sub i64 %14, 1
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %15 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eswitchable"(ptr %0, ptr %3, i64 %sub)
  br label %endif10

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i1 [ %15, %then8 ], [ false, %else9 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif10
  %16 = call ptr @avra_insist(ptr %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %3)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eswitched_reg"(ptr %0, i64 %1, i64 %7, ptr %8, ptr %16, ptr %3)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

else13:                                           ; preds = %endif10
  br label %endif14

endif14:                                          ; preds = %else13, %postret15
  %regval16 = phi i64 [ 0, %postret15 ], [ 0, %else13 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %3)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Echained_reg"(ptr %0, i64 %1, i64 %7, ptr %8, ptr %3, i64 0)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %18

postret15:                                        ; No predecessors!
  call void @avra_rc_release(ptr %16)
  br label %endif14
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Echained_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, i64 %5) {
entry:
  %6 = call ptr @avra_array_get_owned(ptr %4, i64 %5)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  %8 = call i64 @avra_array_len(ptr %4)
  %sub = sub i64 %8, 1
  %cmp = icmp eq i64 %5, %sub
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %7)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_reg"(ptr %0, i64 %2, ptr %3, ptr %6, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %6)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eaccepts_reg"(ptr %0, i64 %2, ptr %3, ptr %6)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l284" to i64))
  call void @avra_array_push(ptr %11, i64 %2)
  call void @avra_array_push_owned(ptr %11, ptr %3)
  call void @avra_array_push_owned(ptr %11, ptr %6)
  call void @avra_array_push_owned(ptr %11, ptr %7)
  %12 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push(ptr %12, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l294" to i64))
  call void @avra_array_push(ptr %12, i64 %1)
  call void @avra_array_push(ptr %12, i64 %2)
  call void @avra_array_push_owned(ptr %12, ptr %3)
  call void @avra_array_push_owned(ptr %12, ptr %4)
  call void @avra_array_push(ptr %12, i64 %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %10, ptr %7, ptr %11, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l294"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %6 = call i64 @avra_array_get(ptr %0, i64 5)
  %add = add i64 %6, 1
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Echained_reg"(ptr %1, i64 %2, i64 %3, ptr %4, ptr %5, i64 %add)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l284"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call i64 @avra_array_get(ptr %0, i64 4)
  %boxed = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %boxed)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_reg"(ptr %1, i64 %2, ptr %3, ptr %4, ptr %boxed)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %6
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_reg"(ptr %0, i64 %1, ptr %2, ptr %3, ptr %4) {
entry:
  %5 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %6, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_binds_of"(ptr %0, i64 %8, i64 %1, ptr %2)
  br label %endif

else:                                             ; preds = %entry
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %9, %then ], [ %10, %else ]
  %11 = call i64 @avra_array_get(ptr %3, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %regval)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebind_patterns"(ptr %0, i64 %11, ptr %regval)
  %13 = call i64 @avra_array_get(ptr %3, i64 1)
  %14 = call i64 @avra_array_get(ptr %3, i64 1)
  call void @avra_rc_retain(ptr %0)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_yield"(ptr %0, i64 %13, i64 %15, ptr %4)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %16
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_yield"(ptr, i64, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_binds_of"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_semantics_of"(ptr %4, ptr %7)
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 0)
  %10 = call i64 @avra_array_get(ptr %8, i64 3)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %10 to ptr
  %11 = call ptr %cast(ptr %9, ptr %0, i64 %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %11
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_semantics_of"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eaccepts_reg"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_accepts_of"(ptr %0, i64 %5, i64 %1, ptr %2)
  store i64 %6, ptr %slot, align 8
  store i64 1, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_len(ptr %boxed2)
  %cmp = icmp slt i64 %ld, %8
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld7 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %ld7

lbody:                                            ; preds = %lhead
  %9 = call i64 @avra_array_get(ptr %3, i64 0)
  %boxed3 = inttoptr i64 %9 to ptr
  %ld4 = load i64, ptr %slot1, align 8
  %10 = call i64 @avra_array_get(ptr %boxed3, i64 %ld4)
  %ld5 = load i64, ptr %slot, align 8
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %11)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l449" to i64))
  %14 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %14, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l455" to i64))
  call void @avra_array_push(ptr %14, i64 %10)
  call void @avra_array_push(ptr %14, i64 %1)
  call void @avra_array_push_owned(ptr %14, ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %14)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %ld5, ptr %12, ptr %13, ptr %14)
  store i64 %15, ptr %slot, align 8
  %ld6 = load i64, ptr %slot1, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l455"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_accepts_of"(ptr %1, i64 %2, i64 %3, ptr %boxed)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l449"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %1, i1 true)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_accepts_of"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_semantics_of"(ptr %4, ptr %7)
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 0)
  %10 = call i64 @avra_array_get(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %10 to ptr
  %11 = call i64 %cast(ptr %9, ptr %0, i64 %1, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eswitched_reg"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %1)
  %7 = call i64 @avra_array_len(ptr %5)
  %sub = sub i64 %7, 1
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %5)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_cases"(ptr %0, ptr %4, ptr %5, i64 %sub)
  %9 = call i64 @avra_array_len(ptr %8)
  %cmp = icmp ne i64 %9, %sub
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %1)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr %0, i64 %2)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %13, i64 15)
  call void @avra_array_push(ptr %13, i64 %12)
  call void @avra_array_push_owned(ptr %13, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %13)
  %15 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif

lhead:                                            ; preds = %endif7, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp2 = icmp slt i64 %ld, %15
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %16 = call i64 @avra_array_get(ptr %5, i64 %sub)
  %boxed = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %6)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_reg"(ptr %0, i64 %2, ptr %3, ptr %boxed, ptr %6)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eclose_region"(ptr %0, i64 %1, i64 %17)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %18

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %19 = call ptr @avra_array_get_owned(ptr %5, i64 %ld3)
  call void @avra_rc_retain(ptr %19)
  call void @avra_cell_release(ptr %slot1)
  store ptr %19, ptr %slot1, align 8
  %cmp4 = icmp slt i64 %ld3, %sub
  br i1 %cmp4, label %then5, label %else6

then5:                                            ; preds = %lbody
  %ld8 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %ld8)
  call void @avra_rc_retain(ptr %6)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_reg"(ptr %0, i64 %2, ptr %3, ptr %ld8, ptr %6)
  call void @avra_rc_retain(ptr %0)
  %21 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Earm_end"(ptr %0, i64 %20)
  br label %endif7

else6:                                            ; preds = %lbody
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval9 = phi i64 [ 0, %then5 ], [ 0, %else6 ]
  %ld10 = load i64, ptr %slot, align 8
  %add = add i64 %ld10, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %19)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Earm_cases"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
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

lhead:                                            ; preds = %endif13, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld19 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld19)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld19

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot2)
  store ptr %6, ptr %slot2, align 8
  %ld4 = load ptr, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld4)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ewhole_test"(ptr %0, ptr %ld4)
  %cmp5 = icmp ne ptr %7, null
  %not = xor i1 %cmp5, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  br label %endif

else:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %7)
  %8 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %1, ptr %7)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ zeroinitializer, %then ], [ %8, %else ]
  %cmp6 = icmp slt i64 %ld3, %3
  br i1 %cmp6, label %then7, label %else8

then7:                                            ; preds = %endif
  %x = extractvalue { i1, i64 } %regval, 0
  br label %endif9

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval10 = phi i1 [ %x, %then7 ], [ false, %else8 ]
  br i1 %regval10, label %then11, label %else12

then11:                                           ; preds = %endif9
  %9 = call ptr @avra_cell_unique(ptr %slot)
  %x14 = extractvalue { i1, i64 } %regval, 0
  %x15 = extractvalue { i1, i64 } %regval, 1
  %slot16 = zext i1 %x14 to i64
  %10 = call i64 @avra_insist_scalar(i64 %slot16, i64 %x15)
  call void @avra_array_push(ptr %9, i64 %10)
  br label %endif13

else12:                                           ; preds = %endif9
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval17 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  %ld18 = load i64, ptr %slot1, align 8
  %add = add i64 %ld18, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ewhole_test"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp ne i64 %3, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed3 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed3, i64 0)
  call void @avra_rc_retain(ptr %boxed2)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed2, i64 %7)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  switch i64 %9, label %arm4 [
    i64 3, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  %11 = call i64 @avra_array_get(ptr %8, i64 2)
  %boxed5 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed6 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed6, i64 1)
  %boxed7 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed7)
  call void @avra_rc_retain(ptr %boxed5)
  %14 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eall_irrefutable"(ptr %boxed7, ptr %boxed5)
  br i1 %14, label %then8, label %else9

arm4:                                             ; preds = %endif
  br label %endswitch

endswitch:                                        ; preds = %arm4, %endif10
  %regval12 = phi ptr [ %regval11, %endif10 ], [ null, %arm4 ]
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval12

then8:                                            ; preds = %arm
  call void @avra_rc_retain(ptr %10)
  br label %endif10

else9:                                            ; preds = %arm
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi ptr [ %10, %then8 ], [ null, %else9 ]
  call void @avra_rc_release(ptr %10)
  br label %endswitch
}

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eall_irrefutable"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eswitchable"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot = alloca i64, align 8
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ewhole_test"(ptr %0, ptr %boxed)
  %cmp2 = icmp ne ptr %4, null
  %not = xor i1 %cmp2, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %4)
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr, i64, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Ebind_regs"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %1)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm4 [
    i64 2, label %arm
    i64 3, label %arm2
    i64 5, label %arm3
  ]

arm:                                              ; preds = %entry
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 %2)
  br label %endswitch

arm2:                                             ; preds = %entry
  %9 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %10 = call i64 @avra_array_get(ptr %6, i64 2)
  %boxed5 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %3)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epayload_binds"(ptr %0, ptr %9, ptr %boxed5, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %9)
  br label %endswitch

arm3:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %13 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  br label %endswitch

arm4:                                             ; preds = %entry
  %14 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm4, %arm3, %arm2, %arm
  %regval = phi ptr [ %8, %arm ], [ %11, %arm2 ], [ %13, %arm3 ], [ %14, %arm4 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epayload_binds"(ptr %0, ptr %1, ptr %2, i64 %3, ptr %4) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_of"(ptr %0, ptr %4)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %1)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayloads_of"(ptr %7, ptr %1)
  %9 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  %10 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif

lhead:                                            ; preds = %endif13, %endif
  %ld = load i64, ptr %slot1, align 8
  %cmp3 = icmp slt i64 %ld, %10
  br i1 %cmp3, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld19 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld19)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld19

lbody:                                            ; preds = %lhead
  %ld4 = load i64, ptr %slot1, align 8
  %11 = call i64 @avra_array_get(ptr %2, i64 %ld4)
  store i64 %11, ptr %slot2, align 8
  %12 = call i64 @avra_array_len(ptr %8)
  %cmp5 = icmp slt i64 %ld4, %12
  br i1 %cmp5, label %then6, label %else7

then6:                                            ; preds = %lbody
  %ld9 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %0)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elooks_inside"(ptr %0, i64 %ld9)
  br label %endif8

else7:                                            ; preds = %lbody
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval10 = phi i1 [ %13, %then6 ], [ false, %else7 ]
  br i1 %regval10, label %then11, label %else12

then11:                                           ; preds = %endif8
  %ld14 = load ptr, ptr %slot, align 8
  %ld15 = load i64, ptr %slot2, align 8
  %14 = call i64 @avra_array_get(ptr %8, i64 %ld4)
  %boxed = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_at"(ptr %0, i64 %3, i64 %ld4, ptr %boxed)
  %16 = call i64 @avra_array_get(ptr %8, i64 %ld4)
  %boxed16 = inttoptr i64 %16 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed16)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_binds_of"(ptr %0, i64 %ld15, i64 %15, ptr %boxed16)
  %18 = call ptr @avra_array_concat(ptr %ld14, ptr %17)
  call void @avra_rc_retain(ptr %18)
  call void @avra_cell_release(ptr %slot)
  store ptr %18, ptr %slot, align 8
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  br label %endif13

else12:                                           ; preds = %endif8
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval17 = phi i64 [ 0, %then11 ], [ 0, %else12 ]
  %ld18 = load i64, ptr %slot1, align 8
  %add = add i64 %ld18, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elooks_inside"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %1)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp = icmp eq i64 %5, 2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp2 = icmp eq i64 %6, 3
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp2, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  br label %endif5

else4:                                            ; preds = %endif
  %7 = call i64 @avra_array_get(ptr %4, i64 0)
  %cmp6 = icmp eq i64 %7, 5
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval7 = phi i1 [ true, %then3 ], [ %cmp6, %else4 ]
  br i1 %regval7, label %then8, label %else9

then8:                                            ; preds = %endif5
  br label %endif10

else9:                                            ; preds = %endif5
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i1 [ true, %then8 ], [ false, %else9 ]
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval11
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_reg"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Epat"(ptr %boxed1, i64 %1)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp = icmp eq i64 %7, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %8 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp2 = icmp eq i64 %8, 1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp2, %else ]
  br i1 %regval, label %then3, label %else4

then3:                                            ; preds = %endif
  br label %endif5

else4:                                            ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp6 = icmp eq i64 %9, 2
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval7 = phi i1 [ true, %then3 ], [ %cmp6, %else4 ]
  br i1 %regval7, label %then8, label %else9

then8:                                            ; preds = %endif5
  call void @avra_rc_retain(ptr %0)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 true)
  br label %endif10

else9:                                            ; preds = %endif5
  %11 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp11 = icmp eq i64 %11, 4
  br i1 %cmp11, label %then12, label %else13

endif10:                                          ; preds = %endif14, %then8
  %regval22 = phi i64 [ %10, %then8 ], [ %regval21, %endif14 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval22

then12:                                           ; preds = %else9
  %12 = call i64 @avra_array_get(ptr %6, i64 1)
  call void @avra_rc_retain(ptr %0)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %12)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Esame_value"(ptr %0, i64 %2, i64 %13, ptr %3)
  br label %endif14

else13:                                           ; preds = %else9
  %15 = call i64 @avra_array_get(ptr %6, i64 0)
  %cmp15 = icmp eq i64 %15, 3
  br i1 %cmp15, label %then16, label %else17

endif14:                                          ; preds = %endif18, %then12
  %regval21 = phi i64 [ %14, %then12 ], [ %regval20, %endif18 ]
  br label %endif10

then16:                                           ; preds = %else13
  %16 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  %17 = call i64 @avra_array_get(ptr %6, i64 2)
  %boxed19 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %boxed19)
  call void @avra_rc_retain(ptr %3)
  %18 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Evariant_reg"(ptr %0, ptr %16, ptr %boxed19, i64 %2, ptr %3)
  call void @avra_rc_release(ptr %16)
  br label %endif18

else17:                                           ; preds = %else13
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %19 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval20 = phi i64 [ %18, %then16 ], [ %20, %else17 ]
  br label %endif14
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Evariant_reg"(ptr %0, ptr %1, ptr %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Evariants_of"(ptr %0, ptr %4)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %1)
  %6 = call { i1, i64 } @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Etag_of"(ptr %5, ptr %1)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi { i1, i64 } [ %6, %then ], [ zeroinitializer, %else ]
  %x = extractvalue { i1, i64 } %regval, 0
  %not = xor i1 %x, true
  br i1 %not, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Edefect"(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 false)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr %0, i64 %3)
  %x5 = extractvalue { i1, i64 } %regval, 0
  %x6 = extractvalue { i1, i64 } %regval, 1
  %slot = zext i1 %x5 to i64
  %10 = call i64 @avra_insist_scalar(i64 %slot, i64 %x6)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 %10)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Emint_shape"(ptr %0, ptr %12)
  %14 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %14, i64 5)
  %15 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %15, i64 4)
  call void @avra_array_push(ptr %15, i64 %13)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_array_push(ptr %15, i64 %9)
  call void @avra_array_push(ptr %15, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %15)
  %17 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed7 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %boxed7)
  call void @avra_rc_retain(ptr %2)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eall_irrefutable"(ptr %boxed7, ptr %2)
  br i1 %19, label %then8, label %else9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  br label %endif3

then8:                                            ; preds = %endif3
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %13

else9:                                            ; preds = %endif3
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  %20 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %1)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EEnumSig$2Epayloads_of"(ptr %20, ptr %1)
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %22)
  %24 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push(ptr %24, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l552" to i64))
  call void @avra_array_push_owned(ptr %24, ptr %21)
  call void @avra_array_push_owned(ptr %24, ptr %2)
  call void @avra_array_push(ptr %24, i64 %3)
  %25 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l556" to i64))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  call void @avra_rc_retain(ptr %24)
  call void @avra_rc_retain(ptr %25)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %13, ptr %23, ptr %24, ptr %25)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %26

postret11:                                        ; No predecessors!
  br label %endif10
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l556"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %1, i1 false)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l552"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epayloads_reg"(ptr %1, ptr %2, ptr %3, i64 %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epayloads_reg"(ptr %0, ptr %1, ptr %2, i64 %3) {
entry:
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %0, i1 true)
  store i64 %4, ptr %slot, align 8
  %5 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld8 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %ld8

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %6 = call i64 @avra_array_get(ptr %2, i64 %ld3)
  store i64 %6, ptr %slot2, align 8
  %7 = call i64 @avra_array_len(ptr %1)
  %cmp4 = icmp slt i64 %ld3, %7
  br i1 %cmp4, label %then, label %else

then:                                             ; preds = %lbody
  %ld5 = load i64, ptr %slot, align 8
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Einterned"(ptr %0, ptr %8)
  %ld6 = load i64, ptr %slot2, align 8
  %10 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l587" to i64))
  call void @avra_array_push(ptr %10, i64 %ld6)
  call void @avra_array_push(ptr %10, i64 %3)
  call void @avra_array_push(ptr %10, i64 %ld3)
  call void @avra_array_push_owned(ptr %10, ptr %1)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l591" to i64))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eregion_as"(ptr %0, i64 %ld5, ptr %9, ptr %10, ptr %11)
  store i64 %12, ptr %slot, align 8
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld7 = load i64, ptr %slot1, align 8
  %add = add i64 %ld7, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l591"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_bool"(ptr %1, i1 false)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower$24l587"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %4 = call i64 @avra_array_get(ptr %0, i64 3)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %6 = call i64 @avra_array_get(ptr %0, i64 3)
  %7 = call i64 @avra_array_get(ptr %5, i64 %6)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Epayload_at"(ptr %1, i64 %3, i64 %4, ptr %boxed)
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %10 = call i64 @avra_array_get(ptr %0, i64 3)
  %11 = call i64 @avra_array_get(ptr %9, i64 %10)
  %boxed1 = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed1)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Epat_accepts_of"(ptr %1, i64 %2, i64 %8, ptr %boxed1)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %12
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower_ordinal$24w"(ptr %0, ptr %1, i64 %2, i64 %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower_ordinal"(ptr %1, i64 %2, i64 %3, ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Elower_ordinal"(ptr %0, i64 %1, i64 %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etag_of"(ptr %0, i64 %2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}
