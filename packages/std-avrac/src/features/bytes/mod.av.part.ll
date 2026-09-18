; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"bytes\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"bytes\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"text\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"at\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"slice\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"concat\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"index_of\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"is_empty\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"run\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"eq_at\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"ieq_at\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"length\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"bytes\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [156 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 155 }, [156 x i8] c"Octets as a value: `s.bytes()` is total, `b.text()` answers null unless the octets are UTF-8, `==` compares every byte, and `at`/`slice` trap past the end.\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg$24w"(ptr, ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Egram"()

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Ebytes"() {
entry:
  %0 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %0, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_str$24w" to i64))
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_str$24w" to i64))
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_str$24w" to i64))
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_ints$24w" to i64))
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_list$24w" to i64))
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_list$24w" to i64))
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  %9 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_text$24w" to i64))
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_text$24w" to i64))
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 0)
  %14 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %10)
  call void @avra_array_push_owned(ptr %14, ptr %11)
  call void @avra_array_push_owned(ptr %14, ptr %12)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %16 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %16, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_at$24w" to i64))
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_at$24w" to i64))
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 0)
  %19 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %19, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %19, ptr %15)
  call void @avra_array_push_owned(ptr %19, ptr %16)
  call void @avra_array_push_owned(ptr %19, ptr %17)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_slice$24w" to i64))
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_slice$24w" to i64))
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %23, i64 0)
  %24 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %24, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %24, ptr %20)
  call void @avra_array_push_owned(ptr %24, ptr %21)
  call void @avra_array_push_owned(ptr %24, ptr %22)
  call void @avra_array_push_owned(ptr %24, ptr %23)
  %25 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %25, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %26 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %26, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_concat$24w" to i64))
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_concat$24w" to i64))
  %28 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %28, i64 0)
  %29 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %29, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push_owned(ptr %29, ptr %25)
  call void @avra_array_push_owned(ptr %29, ptr %26)
  call void @avra_array_push_owned(ptr %29, ptr %27)
  call void @avra_array_push_owned(ptr %29, ptr %28)
  %30 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %30, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %31 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %31, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_index_of$24w" to i64))
  %32 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %32, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_index_of$24w" to i64))
  %33 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %33, i64 0)
  %34 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %34, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %34, ptr %30)
  call void @avra_array_push_owned(ptr %34, ptr %31)
  call void @avra_array_push_owned(ptr %34, ptr %32)
  call void @avra_array_push_owned(ptr %34, ptr %33)
  %35 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %35, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %36 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %36, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_is_empty$24w" to i64))
  %37 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %37, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Elower_is_empty$24w" to i64))
  %38 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %38, i64 0)
  %39 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %39, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_array_push_owned(ptr %39, ptr %35)
  call void @avra_array_push_owned(ptr %39, ptr %36)
  call void @avra_array_push_owned(ptr %39, ptr %37)
  call void @avra_array_push_owned(ptr %39, ptr %38)
  %40 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %40, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %41 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %41, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_run$24w" to i64))
  %42 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %42, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_run$24w" to i64))
  %43 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %43, i64 0)
  %44 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %44, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_array_push_owned(ptr %44, ptr %40)
  call void @avra_array_push_owned(ptr %44, ptr %41)
  call void @avra_array_push_owned(ptr %44, ptr %42)
  call void @avra_array_push_owned(ptr %44, ptr %43)
  %45 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %45, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %46 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %46, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_eq_at$24w" to i64))
  %47 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %47, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_eq_at$24w" to i64))
  %48 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %48, i64 0)
  %49 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %49, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_array_push_owned(ptr %49, ptr %45)
  call void @avra_array_push_owned(ptr %49, ptr %46)
  call void @avra_array_push_owned(ptr %49, ptr %47)
  call void @avra_array_push_owned(ptr %49, ptr %48)
  %50 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %50, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %51 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %51, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_ieq_at$24w" to i64))
  %52 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %52, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_ieq_at$24w" to i64))
  %53 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %53, i64 0)
  %54 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %54, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %54, ptr %50)
  call void @avra_array_push_owned(ptr %54, ptr %51)
  call void @avra_array_push_owned(ptr %54, ptr %52)
  call void @avra_array_push_owned(ptr %54, ptr %53)
  %55 = call ptr @avra_array_sized(i64 11)
  call void @avra_array_push_owned(ptr %55, ptr %4)
  call void @avra_array_push_owned(ptr %55, ptr %9)
  call void @avra_array_push_owned(ptr %55, ptr %14)
  call void @avra_array_push_owned(ptr %55, ptr %19)
  call void @avra_array_push_owned(ptr %55, ptr %24)
  call void @avra_array_push_owned(ptr %55, ptr %29)
  call void @avra_array_push_owned(ptr %55, ptr %34)
  call void @avra_array_push_owned(ptr %55, ptr %39)
  call void @avra_array_push_owned(ptr %55, ptr %44)
  call void @avra_array_push_owned(ptr %55, ptr %49)
  call void @avra_array_push_owned(ptr %55, ptr %54)
  %56 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %56, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w" to i64))
  %57 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %57, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_length$24w" to i64))
  %58 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %58, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Emeasured_reg$24w" to i64))
  %59 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %59, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_array_push_owned(ptr %59, ptr %56)
  call void @avra_array_push_owned(ptr %59, ptr %57)
  call void @avra_array_push_owned(ptr %59, ptr %58)
  %60 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %60, ptr %59)
  %61 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %61, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_array_push_owned(ptr %61, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  %62 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Egram"()
  call void @avra_array_push_owned(ptr %61, ptr %62)
  %63 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"()
  call void @avra_array_push_owned(ptr %61, ptr %63)
  %64 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()
  call void @avra_array_push_owned(ptr %61, ptr %64)
  call void @avra_array_push_owned(ptr %61, ptr %55)
  %65 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Etypes"()
  call void @avra_array_push_owned(ptr %61, ptr %65)
  call void @avra_array_push_owned(ptr %61, ptr %60)
  %66 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()
  call void @avra_array_push_owned(ptr %61, ptr %66)
  call void @avra_rc_release(ptr %66)
  call void @avra_rc_release(ptr %65)
  call void @avra_rc_release(ptr %64)
  call void @avra_rc_release(ptr %63)
  call void @avra_rc_release(ptr %62)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %60)
  call void @avra_rc_release(ptr %59)
  call void @avra_rc_release(ptr %58)
  call void @avra_rc_release(ptr %57)
  call void @avra_rc_release(ptr %56)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %55)
  call void @avra_rc_release(ptr %54)
  call void @avra_rc_release(ptr %53)
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %51)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %49)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %47)
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %45)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %44)
  call void @avra_rc_release(ptr %43)
  call void @avra_rc_release(ptr %42)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  ret ptr %61
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_length$24w"(ptr, ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_ieq_at$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_ieq_at$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_eq_at$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_eq_at$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_run$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_run$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_is_empty$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_index_of$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_index_of$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_concat$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_concat$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_slice$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_slice$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_at$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_at$24w"(ptr, ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_text$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_text$24w"(ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_bytes$24w"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_list$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_list$24w"(ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_ints$24w"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Elower_of_str$24w"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Echeck_of_str$24w"(ptr, ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Eon_str$24w"(ptr, ptr)
