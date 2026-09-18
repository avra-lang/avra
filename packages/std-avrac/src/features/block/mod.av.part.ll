; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"block\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"block\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [67 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 66 }, [67 x i8] c"`{ <statements> <expression> }`; the last expression is the value.\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"block\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"block\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"block\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"{\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"s\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"stmt\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"BREAK\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"}\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [32 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 31 }, [32 x i8] c"expected `}` to close the block\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"block\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"s\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilderRow$2Epayloads"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Emethods"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()

define ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2Eblock"() {
entry:
  %0 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %0, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2Ebuild_block$24w" to i64))
  %1 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %1, ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EBuilderRow$2Epayloads"()
  call void @avra_array_push_owned(ptr %1, ptr %2)
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %3, ptr %1)
  %4 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %4, i64 1)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 0)
  %6 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %6, i64 0)
  call void @avra_array_push_owned(ptr %6, ptr %4)
  call void @avra_array_push_owned(ptr %6, ptr %5)
  call void @avra_array_push(ptr %6, i64 0)
  call void @avra_array_push(ptr %6, i64 0)
  call void @avra_array_push(ptr %6, i64 0)
  %7 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot = zext i1 %7 to i64
  call void @avra_array_push(ptr %6, i64 %slot)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %8, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 0)
  %10 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %10, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %10, ptr %8)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_array_push(ptr %10, i64 0)
  call void @avra_array_push(ptr %10, i64 0)
  %11 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot1 = zext i1 %11 to i64
  call void @avra_array_push(ptr %10, i64 %slot1)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %12, ptr %10)
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_array_push(ptr %13, i64 0)
  call void @avra_array_push(ptr %13, i64 0)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 2)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 0)
  %16 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %16, i64 0)
  call void @avra_array_push_owned(ptr %16, ptr %14)
  call void @avra_array_push_owned(ptr %16, ptr %15)
  call void @avra_array_push(ptr %16, i64 0)
  call void @avra_array_push(ptr %16, i64 0)
  call void @avra_array_push(ptr %16, i64 0)
  %17 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot2 = zext i1 %17 to i64
  call void @avra_array_push(ptr %16, i64 %slot2)
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %18, ptr %16)
  %19 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  call void @avra_array_push(ptr %19, i64 0)
  call void @avra_array_push(ptr %19, i64 0)
  %20 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %20, ptr %13)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %21, ptr %20)
  %22 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %22, i64 3)
  call void @avra_array_push_owned(ptr %22, ptr %21)
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %23, i64 1)
  %24 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %24, i64 0)
  call void @avra_array_push_owned(ptr %24, ptr %22)
  call void @avra_array_push_owned(ptr %24, ptr %23)
  call void @avra_array_push(ptr %24, i64 0)
  call void @avra_array_push(ptr %24, i64 0)
  call void @avra_array_push(ptr %24, i64 0)
  %25 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot3 = zext i1 %25 to i64
  call void @avra_array_push(ptr %24, i64 %slot3)
  %26 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %26, i64 1)
  call void @avra_array_push_owned(ptr %26, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 0)
  %28 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %28, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  %29 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push(ptr %29, i64 0)
  call void @avra_array_push_owned(ptr %29, ptr %26)
  call void @avra_array_push_owned(ptr %29, ptr %27)
  call void @avra_array_push_owned(ptr %29, ptr %28)
  call void @avra_array_push(ptr %29, i64 0)
  call void @avra_array_push(ptr %29, i64 0)
  %30 = call i1 @"av_$40std$2Eavrac$2Egrammar$2EItem$2Elisted"()
  %slot4 = zext i1 %30 to i64
  call void @avra_array_push(ptr %29, i64 %slot4)
  %31 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %31, ptr %6)
  call void @avra_array_push_owned(ptr %31, ptr %24)
  call void @avra_array_push_owned(ptr %31, ptr %29)
  %32 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %32, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  %33 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %33, i64 1)
  call void @avra_array_push_owned(ptr %33, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_array_push_owned(ptr %33, ptr %32)
  %34 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %34, ptr %31)
  call void @avra_array_push_owned(ptr %34, ptr %33)
  call void @avra_array_push(ptr %34, i64 0)
  %35 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %35, ptr %34)
  %36 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %36, ptr %35)
  %37 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %37, ptr %36)
  %38 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %38, ptr %37)
  %39 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %39, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %39, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %39, ptr %38)
  %40 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %40, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %40, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %40, ptr %39)
  call void @avra_array_push_owned(ptr %40, ptr %3)
  %41 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()
  call void @avra_array_push_owned(ptr %40, ptr %41)
  %42 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Emethods"()
  call void @avra_array_push_owned(ptr %40, ptr %42)
  %43 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"()
  call void @avra_array_push_owned(ptr %40, ptr %43)
  %44 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"()
  call void @avra_array_push_owned(ptr %40, ptr %44)
  %45 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()
  call void @avra_array_push_owned(ptr %40, ptr %45)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %42)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %40
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2Ebuild_block$24w"(ptr, ptr)
