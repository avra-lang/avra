; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.export_kind\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"`export use` \E2\80\94 a re-export \E2\80\94 arrives with a later slice\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"this line\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.export_kind\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [63 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 62 }, [63 x i8] c"an impl is not exported \E2\80\94 its methods travel with their type\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"this impl\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [24 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 23 }, [24 x i8] c"export the type instead\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.export_kind\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [64 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 63 }, [64 x i8] c"`export` marks a fn, type, enum or trait \E2\80\94 not this statement\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"marked here\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [48 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 47 }, [48 x i8] c"drop the `export`, or declare the value as a fn\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eloc_at"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eimpl_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Euse_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_kind"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_exported"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Emodule_laws"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Elaw_of"(ptr %0, ptr %1, i64 %6)
  call void @avra_array_push_owned(ptr %3, ptr %7)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Elaw_of"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt_span"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eloc_at"(ptr %1, ptr %3)
  call void @avra_rc_retain(ptr %0)
  %5 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_exported"(ptr %0, i64 %2)
  br i1 %5, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Edeclared_kind"(ptr %0, i64 %2)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  call void @avra_rc_release(ptr %6)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not, %then ], [ false, %else ]
  br i1 %regval, label %then1, label %else2

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr %0, i64 %2)
  %cmp4 = icmp ne ptr %7, null
  %not5 = xor i1 %cmp4, true
  call void @avra_rc_release(ptr %7)
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval6 = phi i1 [ %not5, %then1 ], [ false, %else2 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif3
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Eunexportable"(ptr %4, ptr %0, i64 %2)
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

else8:                                            ; preds = %endif3
  br label %endif9

endif9:                                           ; preds = %else8, %postret
  %regval10 = phi i64 [ 0, %postret ], [ 0, %else8 ]
  %10 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %10

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Eunexportable"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Euse_parts"(ptr %1, i64 %2)
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  %4 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr %0, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16), ptr getelementptr inbounds (i8, ptr @.str.2, i64 16), ptr null)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eimpl_parts"(ptr %1, i64 %2)
  %cmp1 = icmp ne ptr %5, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %6 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16), ptr %0, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16), ptr getelementptr inbounds (i8, ptr @.str.5, i64 16), ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16), ptr %0, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16), ptr getelementptr inbounds (i8, ptr @.str.9, i64 16), ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  br label %endif4
}
