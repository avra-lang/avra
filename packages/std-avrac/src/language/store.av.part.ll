; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\0A\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c".deps\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"sig\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"fp\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"unit\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"obj\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"mod\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"bin\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"warn\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\0A\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"\0A\00" }, align 16

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

declare ptr @"av_$40std$2Eio$2Eread_text"(ptr)

declare ptr @"av_$40std$2Eio$2Eread_bytes"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr, ptr)

declare ptr @"av_$40std$2Epath$2Ejoined_path"(ptr, ptr)

declare ptr @"av_$40std$2Eio$2Ewrite_text"(ptr, ptr)

declare ptr @"av_$40std$2Eio$2Ewrite_bytes"(ptr, ptr)

declare ptr @"av_$40std$2Eio$2Emake_dirs"(ptr)

declare i1 @"av_$40std$2Eio$2Eexists"(ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2EStore$2Ekeep"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eshard"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eio$2Emake_dirs"(ptr %5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %7)
  call void @avra_rc_retain(ptr %3)
  %8 = call ptr @"av_$40std$2Eio$2Ewrite_text"(ptr %7, ptr %3)
  %9 = call i64 @avra_array_get(ptr %8, i64 0)
  %cmp = icmp eq i64 %9, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %10 = call ptr @avra_array_get_owned(ptr %8, i64 1)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %10, %then ], [ getelementptr inbounds (i8, ptr @.str, i64 16), %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eedge_path"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %12)
  %13 = call ptr @"av_$40std$2Eio$2Ewrite_text"(ptr %11, ptr %12)
  %14 = call i64 @avra_array_get(ptr %13, i64 0)
  %cmp1 = icmp eq i64 %14, 0
  br i1 %cmp1, label %then2, label %else3

then2:                                            ; preds = %endif
  %15 = call ptr @avra_array_get_owned(ptr %13, i64 1)
  br label %endif4

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval5 = phi ptr [ %15, %then2 ], [ getelementptr inbounds (i8, ptr @.str.2, i64 16), %else3 ]
  call void @avra_rc_release(ptr %regval5)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eedge_path"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eshard"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Epath$2Ejoined_path"(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eshard"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStored$2Ename"(ptr %1)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Epath$2Ejoined_path"(ptr %boxed, ptr %4)
  %6 = call ptr @avra_str_substring(ptr %2, i64 0, i64 2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Epath$2Ejoined_path"(ptr %5, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %7
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EStored$2Ename"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  switch i64 %1, label %arm6 [
    i64 0, label %arm
    i64 1, label %arm1
    i64 2, label %arm2
    i64 3, label %arm3
    i64 4, label %arm4
    i64 5, label %arm5
  ]

arm:                                              ; preds = %entry
  br label %endswitch

arm1:                                             ; preds = %entry
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

arm3:                                             ; preds = %entry
  br label %endswitch

arm4:                                             ; preds = %entry
  br label %endswitch

arm5:                                             ; preds = %entry
  br label %endswitch

arm6:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm6, %arm5, %arm4, %arm3, %arm2, %arm1, %arm
  %regval = phi ptr [ getelementptr inbounds (i8, ptr @.str.6, i64 16), %arm ], [ getelementptr inbounds (i8, ptr @.str.7, i64 16), %arm1 ], [ getelementptr inbounds (i8, ptr @.str.8, i64 16), %arm2 ], [ getelementptr inbounds (i8, ptr @.str.9, i64 16), %arm3 ], [ getelementptr inbounds (i8, ptr @.str.10, i64 16), %arm4 ], [ getelementptr inbounds (i8, ptr @.str.11, i64 16), %arm5 ], [ getelementptr inbounds (i8, ptr @.str.12, i64 16), %arm6 ]
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EStore$2Ekeep_file"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eshard"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eio$2Emake_dirs"(ptr %5)
  call void @avra_rc_retain(ptr %3)
  %7 = call ptr @"av_$40std$2Eio$2Eread_bytes"(ptr %3)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  switch i64 %8, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %9 = call ptr @avra_array_get_owned(ptr %7, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %10 = call i64 @avra_array_get(ptr %7, i64 1)
  %boxed = inttoptr i64 %10 to ptr
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

endswitch:                                        ; preds = %postret, %arm
  %regval = phi ptr [ %9, %arm ], [ null, %postret ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %regval)
  %12 = call ptr @"av_$40std$2Eio$2Ewrite_bytes"(ptr %11, ptr %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eedge_path"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @"av_$40std$2Eio$2Ewrite_text"(ptr %13, ptr %14)
  %16 = call i64 @avra_array_get(ptr %15, i64 0)
  %cmp = icmp eq i64 %16, 0
  br i1 %cmp, label %then, label %else

postret:                                          ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endswitch

then:                                             ; preds = %endswitch
  %17 = call ptr @avra_array_get_owned(ptr %15, i64 1)
  br label %endif

else:                                             ; preds = %endswitch
  br label %endif

endif:                                            ; preds = %else, %then
  %regval2 = phi ptr [ %17, %then ], [ getelementptr inbounds (i8, ptr @.str.14, i64 16), %else ]
  call void @avra_rc_release(ptr %regval2)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Enode_key"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStored$2Ename"(ptr %0)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  %4 = call ptr @avra_array_concat(ptr %3, ptr %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ejoined"(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_of"(ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Edigest_of"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eget"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EStore$2Ehas"(ptr %0, ptr %1, ptr %2)
  %not = xor i1 %3, true
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
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eio$2Eread_text"(ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  switch i64 %6, label %arm1 [
    i64 0, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 1)
  br label %endswitch

arm1:                                             ; preds = %endif
  %8 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed = inttoptr i64 %8 to ptr
  br label %endswitch

endswitch:                                        ; preds = %arm1, %arm
  %regval2 = phi ptr [ %7, %arm ], [ null, %arm1 ]
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval2
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EStore$2Ehas"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %3)
  %4 = call i1 @"av_$40std$2Eio$2Eexists"(ptr %3)
  br i1 %4, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eedge_path"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %5)
  %6 = call i1 @"av_$40std$2Eio$2Eexists"(ptr %5)
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %6, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EStore$2Eplace"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EStore$2Ehas"(ptr %0, ptr %1, ptr %2)
  %not = xor i1 %4, true
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
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EStore$2Epath"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eio$2Eread_bytes"(ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  switch i64 %7, label %arm1 [
    i64 0, label %arm
  ]

postret:                                          ; No predecessors!
  br label %endif

arm:                                              ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %6, i64 1)
  br label %endswitch

arm1:                                             ; preds = %endif
  %9 = call i64 @avra_array_get(ptr %6, i64 1)
  %boxed = inttoptr i64 %9 to ptr
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

endswitch:                                        ; preds = %postret2, %arm
  %regval3 = phi ptr [ %8, %arm ], [ null, %postret2 ]
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %regval3)
  %10 = call ptr @"av_$40std$2Eio$2Ewrite_bytes"(ptr %3, ptr %regval3)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %regval3)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

postret2:                                         ; No predecessors!
  call void @avra_rc_retain(ptr null)
  br label %endswitch
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Estore_at"(ptr %0) {
entry:
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr %0)
  call void @avra_rc_release(ptr %0)
  ret ptr %1
}
