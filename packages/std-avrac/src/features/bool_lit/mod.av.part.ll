; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"bool_lit\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [47 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 46 }, [47 x i8] c"`true` and `false`; their value is themselves.\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"primary\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"primary\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"primary\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"true\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Expr\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"BoolLit\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"value\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"true\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"false\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Expr\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"BoolLit\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"value\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"false\00" }, align 16

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

declare i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Emethods"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"()

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2Ebool_lit"() {
entry:
  %0 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %0, i64 1)
  call void @avra_array_push_owned(ptr %0, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 0)
  %2 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_array_push_owned(ptr %2, ptr %0)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_array_push(ptr %2, i64 0)
  call void @avra_array_push(ptr %2, i64 0)
  %3 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot = zext i1 %3 to i64
  call void @avra_array_push(ptr %2, i64 %slot)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  %5 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  %7 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %7, i64 2)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_array_push(ptr %7, i64 0)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %8, ptr %4)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push(ptr %8, i64 0)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %9, i64 1)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 0)
  %11 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push(ptr %11, i64 0)
  call void @avra_array_push(ptr %11, i64 0)
  %12 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot1 = zext i1 %12 to i64
  call void @avra_array_push(ptr %11, i64 %slot1)
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  %16 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push(ptr %16, i64 2)
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_array_push(ptr %16, i64 0)
  %17 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %17, ptr %13)
  call void @avra_array_push_owned(ptr %17, ptr %16)
  call void @avra_array_push(ptr %17, i64 0)
  %18 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %18, ptr %8)
  call void @avra_array_push_owned(ptr %18, ptr %17)
  %19 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %20, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %20, ptr %19)
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %21, ptr %20)
  %22 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr %21)
  %23 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %23, ptr %22)
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"()
  call void @avra_array_push_owned(ptr %23, ptr %24)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()
  call void @avra_array_push_owned(ptr %23, ptr %25)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Emethods"()
  call void @avra_array_push_owned(ptr %23, ptr %26)
  %27 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"()
  call void @avra_array_push_owned(ptr %23, ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"()
  call void @avra_array_push_owned(ptr %23, ptr %28)
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()
  call void @avra_array_push_owned(ptr %23, ptr %29)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %23
}
