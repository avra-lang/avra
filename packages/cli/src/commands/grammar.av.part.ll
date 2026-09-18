; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"grammar\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"Print the assembled language grammar\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c": \00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
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

declare i64 @"av_$40std$2Eprelude$2Eprintln"(ptr)

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eavra"()

declare ptr @"av_commands$2Ebare_command"(ptr, ptr)

define ptr @"av_commands$2Egrammar_command"() {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %0 = call ptr @"av_commands$2Ebare_command"(ptr getelementptr inbounds (i8, ptr @.str, i64 16), ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  %1 = call ptr @avra_array_sized(i64 0)
  %2 = call ptr @avra_array_new()
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_commands$2EGrammarCmd$2Erun" to i64))
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %3, ptr %0)
  call void @avra_array_push_owned(ptr %3, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %3
}

define i64 @"av_commands$2EGrammarCmd$2Erun"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eavra"()
  %3 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %3 to ptr
  %cmp = icmp ne ptr %boxed, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 6)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed9 = inttoptr i64 %6 to ptr
  %7 = call ptr @avra_insist(ptr %boxed9)
  %8 = call i64 @avra_array_get(ptr %7, i64 0)
  %boxed10 = inttoptr i64 %8 to ptr
  call void @avra_rc_retain(ptr %boxed10)
  %9 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Erender_grammar"(ptr %boxed10)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lhead:                                            ; preds = %lbody, %then
  %ld = load i64, ptr %slot, align 8
  %cmp2 = icmp slt i64 %ld, %5
  br i1 %cmp2, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 1

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %11 = call ptr @avra_array_get_owned(ptr %4, i64 %ld3)
  call void @avra_rc_retain(ptr %11)
  call void @avra_cell_release(ptr %slot1)
  store ptr %11, ptr %slot1, align 8
  %ld4 = load ptr, ptr %slot1, align 8
  %12 = call i64 @avra_array_get(ptr %ld4, i64 0)
  %boxed5 = inttoptr i64 %12 to ptr
  %ld6 = load ptr, ptr %slot1, align 8
  %13 = call i64 @avra_array_get(ptr %ld6, i64 4)
  %boxed7 = inttoptr i64 %13 to ptr
  %14 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %boxed5)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %boxed7)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  %15 = call ptr @avra_str_join(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eprelude$2Eprintln"(ptr %15)
  %ld8 = load i64, ptr %slot, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %11)
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %4)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Erender_grammar"(ptr)
