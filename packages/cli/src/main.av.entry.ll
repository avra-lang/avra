; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"avra\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"The Avra compiler\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"0.0.1\00" }, align 16

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

declare i64 @"av_$40std$2Eprocess$2Eexit"(ptr)

declare i64 @"av_$40std$2Ecli$2EApp$2Erun"(ptr)

declare ptr @"av_$40std$2Ecli$2Eargv"()

declare { i1, i64 } @av_light_phase(ptr)

declare ptr @"av_commands$2Eattack_command"()

declare ptr @"av_commands$2Enew_command"()

declare ptr @"av_commands$2Ediagnostics_command"()

declare ptr @"av_commands$2Eruntime_header_command"()

declare ptr @"av_commands$2Egrammar_command"()

declare ptr @"av_commands$2Efmt_command"()

declare ptr @"av_commands$2Eexpand_command"()

declare ptr @"av_commands$2Eexplain_command"()

declare ptr @"av_commands$2Etest_command"()

declare ptr @"av_commands$2Erun_command"()

declare ptr @"av_commands$2Ebuild_command"()

declare ptr @"av_commands$2Eemit_command"()

declare ptr @"av_commands$2Eseats_command"()

declare ptr @"av_commands$2Eir_command"()

declare ptr @"av_commands$2Echeck_command"()

declare void @avra_args_init(i64, ptr)

define i32 @av_entry() {
entry:
  %0 = call ptr @"av_commands$2Echeck_command"()
  %1 = call ptr @"av_commands$2Eir_command"()
  %2 = call ptr @"av_commands$2Eseats_command"()
  %3 = call ptr @"av_commands$2Eemit_command"()
  %4 = call ptr @"av_commands$2Ebuild_command"()
  %5 = call ptr @"av_commands$2Erun_command"()
  %6 = call ptr @"av_commands$2Etest_command"()
  %7 = call ptr @"av_commands$2Eexplain_command"()
  %8 = call ptr @"av_commands$2Eexpand_command"()
  %9 = call ptr @"av_commands$2Efmt_command"()
  %10 = call ptr @"av_commands$2Egrammar_command"()
  %11 = call ptr @"av_commands$2Eruntime_header_command"()
  %12 = call ptr @"av_commands$2Ediagnostics_command"()
  %13 = call ptr @"av_commands$2Enew_command"()
  %14 = call ptr @"av_commands$2Eattack_command"()
  %15 = call ptr @avra_array_sized(i64 15)
  call void @avra_array_push_owned(ptr %15, ptr %0)
  call void @avra_array_push_owned(ptr %15, ptr %1)
  call void @avra_array_push_owned(ptr %15, ptr %2)
  call void @avra_array_push_owned(ptr %15, ptr %3)
  call void @avra_array_push_owned(ptr %15, ptr %4)
  call void @avra_array_push_owned(ptr %15, ptr %5)
  call void @avra_array_push_owned(ptr %15, ptr %6)
  call void @avra_array_push_owned(ptr %15, ptr %7)
  call void @avra_array_push_owned(ptr %15, ptr %8)
  call void @avra_array_push_owned(ptr %15, ptr %9)
  call void @avra_array_push_owned(ptr %15, ptr %10)
  call void @avra_array_push_owned(ptr %15, ptr %11)
  call void @avra_array_push_owned(ptr %15, ptr %12)
  call void @avra_array_push_owned(ptr %15, ptr %13)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  %16 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr %15)
  %17 = call ptr @"av_$40std$2Ecli$2Eargv"()
  call void @avra_rc_retain(ptr %17)
  %18 = call { i1, i64 } @av_light_phase(ptr %17)
  %x = extractvalue { i1, i64 } %18, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %entry
  %x1 = extractvalue { i1, i64 } %18, 1
  br label %endif

else:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %16)
  %19 = call i64 @"av_$40std$2Ecli$2EApp$2Erun"(ptr %16)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ %x1, %then ], [ %19, %else ]
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %20, i64 1)
  call void @avra_array_push(ptr %20, i64 %regval)
  call void @avra_rc_retain(ptr %20)
  %21 = call i64 @"av_$40std$2Eprocess$2Eexit"(ptr %20)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret i32 0
}

define i32 @main(i32 %0, ptr %1) {
entry:
  %argc = zext i32 %0 to i64
  call void @avra_args_init(i64 %argc, ptr %1)
  %code = call i32 @av_entry()
  ret i32 %code
}
