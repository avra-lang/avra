; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [36 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 35 }, [36 x i8] c"a list literal without its elements\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"resolve.paired\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"` names both the index and the element\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"bound here\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"give the index its own name \E2\80\94 `for i, \00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c" in \E2\80\A6`\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr, ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_at"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Elower"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %9 = call i64 @avra_array_get(ptr %5, i64 4)
  %10 = call ptr @avra_array_get_owned(ptr %5, i64 5)
  %11 = call ptr @avra_array_get_owned(ptr %5, i64 6)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eliteral_reg"(ptr %1, i64 %2)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif
  %regval3 = phi i64 [ %13, %endif ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval3

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %8)
  br label %endif

else:                                             ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %8, %then ], [ null, %else ]
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %11)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_reg"(ptr %1, i64 %2, i64 %7, ptr %regval, i64 %9, ptr %10, ptr %11)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  br label %endswitch
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eliteral_reg"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eelems_of"(ptr %4)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elist_reg"(ptr %0, i64 %1, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elist_reg"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eelems_of"(ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_reg"(ptr, i64, i64, ptr, i64, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Etype_of"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %9 = call i64 @avra_array_get(ptr %5, i64 4)
  %10 = call ptr @avra_array_get_owned(ptr %5, i64 5)
  %11 = call ptr @avra_array_get_owned(ptr %5, i64 6)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eliteral_type"(ptr %1, i64 %2)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif
  %regval3 = phi ptr [ %13, %endif ], [ %12, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval3

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %8)
  br label %endif

else:                                             ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %8, %then ], [ null, %else ]
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %11)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_type"(ptr %1, i64 %2, i64 %7, ptr %regval, i64 %9, ptr %10, ptr %11)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eliteral_type"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %1)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eelems_of"(ptr %4)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %7 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elist_type"(ptr %0, i64 %1, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elist_type"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_type"(ptr, i64, i64, ptr, i64, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Eresolve"(ptr %0, ptr %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed1, i64 %2)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm2 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  %8 = call ptr @avra_array_get_owned(ptr %5, i64 2)
  %9 = call ptr @avra_array_get_owned(ptr %5, i64 3)
  %10 = call ptr @avra_array_get_owned(ptr %5, i64 6)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then, label %else

arm2:                                             ; preds = %entry
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm2, %endif
  %regval3 = phi i64 [ %12, %endif ], [ %11, %arm2 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval3

then:                                             ; preds = %arm
  call void @avra_rc_retain(ptr %8)
  br label %endif

else:                                             ; preds = %arm
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %8, %then ], [ null, %else ]
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %regval)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eresolve_comp"(ptr %1, i64 %2, i64 %7, ptr %regval, ptr %9, ptr %10)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endswitch
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Eresolve_comp"(ptr %0, i64 %1, i64 %2, ptr %3, ptr %4, ptr %5) {
entry:
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %6 = call i64 @avra_streq(ptr %3, ptr %4)
  %b = icmp ne i64 %6, 0
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %b, %then ], [ false, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Epaired_alike"(ptr %0, i64 %1, ptr %4)
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval4 = phi i64 [ 0, %then1 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_binds"(ptr %3, ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_at"(ptr %0, i64 %1, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr %0, ptr %9, i64 %2)
  %cmp5 = icmp ne ptr %5, null
  br i1 %cmp5, label %then6, label %else7

then6:                                            ; preds = %endif3
  %11 = call ptr @avra_insist(ptr %5)
  %12 = call i64 @avra_array_get(ptr %11, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr %0, ptr %9, i64 %12)
  call void @avra_rc_release(ptr %11)
  br label %endif8

else7:                                            ; preds = %endif3
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi i64 [ 0, %then6 ], [ 0, %else7 ]
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Ecomp_binds"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %0, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call ptr @avra_insist(ptr %0)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %2)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Elists$2Epaired_alike"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr %boxed, i64 %1)
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %2)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  %6 = call ptr @avra_str_join(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %2)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  %8 = call ptr @avra_str_join(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %8)
  %9 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr %4, ptr %6, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %10
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Eheirs"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 6)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_sized(i64 0)
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif
  %regval2 = phi ptr [ %regval, %endif ], [ %5, %arm1 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval2

then:                                             ; preds = %arm
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %3)
  br label %endif

else:                                             ; preds = %arm
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 %3)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %6, %then ], [ %9, %else ]
  call void @avra_rc_release(ptr %4)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2EListSemantics$2Ekids"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm1 [
    i64 9, label %arm
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 4)
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 5)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

arm1:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2EExpr$2Eelems_of"(ptr %1)
  %cmp2 = icmp ne ptr %5, null
  br i1 %cmp2, label %then3, label %else4

endswitch:                                        ; preds = %endif5, %endif
  %regval7 = phi ptr [ %regval, %endif ], [ %regval6, %endif5 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval7

then:                                             ; preds = %arm
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %3)
  br label %endif

else:                                             ; preds = %arm
  %7 = call ptr @avra_insist(ptr %4)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 %3)
  call void @avra_array_push(ptr %9, i64 %8)
  call void @avra_rc_release(ptr %7)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %6, %then ], [ %9, %else ]
  call void @avra_rc_release(ptr %4)
  br label %endswitch

then3:                                            ; preds = %arm1
  call void @avra_rc_retain(ptr %5)
  br label %endif5

else4:                                            ; preds = %arm1
  %10 = call ptr @avra_array_sized(i64 0)
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval6 = phi ptr [ %5, %then3 ], [ %10, %else4 ]
  call void @avra_rc_release(ptr %5)
  br label %endswitch
}
