; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"new\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"get\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"set\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"push\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"set_at\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Cell\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"cells\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [143 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 142 }, [143 x i8] c"`Cell.new(v)` creates an explicit shared `Cell<T>`; copies share one slot, `get()` reads its value, and `set(v)` replaces it through any copy.\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [53 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 52 }, [53 x i8] c"a set_at without its index and value survived typing\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [58 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 57 }, [58 x i8] c"a Cell.set_at whose cell has no held type survived typing\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_slot_set\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"set_at\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"a push without its value survived typing\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [56 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 55 }, [56 x i8] c"a Cell.push whose cell has no held type survived typing\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"avra_array_push\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"push\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"avra_slot_set\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"set\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [4 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 3 }, [4 x i8] c"get\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"a Cell.new without one value survived typing\00" }, align 16
@.str.20 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"Cell.new\00" }, align 16
@.str.21 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"a cell\00" }, align 16
@.str.22 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Cell\00" }, align 16

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr, i64, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr, i64, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr, i64)

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr, i64, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunslottable"(ptr, i64, ptr)

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewrong_arity"(ptr, i64, ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()

declare i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr, ptr, ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecells"() {
entry:
  %0 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %0, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell_type$24w" to i64))
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %1, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_new$24w" to i64))
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_new$24w" to i64))
  %3 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %3, i64 0)
  %4 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %0)
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell$24w" to i64))
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_get$24w" to i64))
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_get$24w" to i64))
  %8 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %8, i64 0)
  %9 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.1, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %6)
  call void @avra_array_push_owned(ptr %9, ptr %7)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell$24w" to i64))
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set$24w" to i64))
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set$24w" to i64))
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 2)
  %14 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %14, ptr getelementptr inbounds (i8, ptr @.str.2, i64 16))
  call void @avra_array_push_owned(ptr %14, ptr %10)
  call void @avra_array_push_owned(ptr %14, ptr %11)
  call void @avra_array_push_owned(ptr %14, ptr %12)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell$24w" to i64))
  %16 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %16, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_push$24w" to i64))
  %17 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %17, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_push$24w" to i64))
  %18 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %18, i64 2)
  %19 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %19, ptr getelementptr inbounds (i8, ptr @.str.3, i64 16))
  call void @avra_array_push_owned(ptr %19, ptr %15)
  call void @avra_array_push_owned(ptr %19, ptr %16)
  call void @avra_array_push_owned(ptr %19, ptr %17)
  call void @avra_array_push_owned(ptr %19, ptr %18)
  %20 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %20, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell$24w" to i64))
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %21, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set_at$24w" to i64))
  %22 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %22, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set_at$24w" to i64))
  %23 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %23, i64 2)
  %24 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %24, ptr getelementptr inbounds (i8, ptr @.str.4, i64 16))
  call void @avra_array_push_owned(ptr %24, ptr %20)
  call void @avra_array_push_owned(ptr %24, ptr %21)
  call void @avra_array_push_owned(ptr %24, ptr %22)
  call void @avra_array_push_owned(ptr %24, ptr %23)
  %25 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %25, ptr %4)
  call void @avra_array_push_owned(ptr %25, ptr %9)
  call void @avra_array_push_owned(ptr %25, ptr %14)
  call void @avra_array_push_owned(ptr %25, ptr %19)
  call void @avra_array_push_owned(ptr %25, ptr %24)
  %26 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %26, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law$24w" to i64))
  %27 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %27, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecell_shape$24w" to i64))
  %28 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %28, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants$24w" to i64))
  %29 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %29, ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_array_push(ptr %29, i64 1)
  call void @avra_array_push(ptr %29, i64 1)
  call void @avra_array_push_owned(ptr %29, ptr %26)
  call void @avra_array_push_owned(ptr %29, ptr %27)
  call void @avra_array_push_owned(ptr %29, ptr %28)
  %30 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %30, ptr %29)
  %31 = call ptr @avra_array_sized(i64 9)
  call void @avra_array_push_owned(ptr %31, ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_array_push_owned(ptr %31, ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  %32 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Egram"()
  call void @avra_array_push_owned(ptr %31, ptr %32)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"()
  call void @avra_array_push_owned(ptr %31, ptr %33)
  %34 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ediags"()
  call void @avra_array_push_owned(ptr %31, ptr %34)
  call void @avra_array_push_owned(ptr %31, ptr %25)
  call void @avra_array_push_owned(ptr %31, ptr %30)
  %35 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eproperties"()
  call void @avra_array_push_owned(ptr %31, ptr %35)
  %36 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Eremedies"()
  call void @avra_array_push_owned(ptr %31, ptr %36)
  call void @avra_rc_release(ptr %36)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.7, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.6, i64 16))
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.5, i64 16))
  call void @avra_rc_release(ptr %25)
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
  ret ptr %31
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_variants$24w"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecell_shape$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecell_shape"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eno_law$24w"(ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set_at$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set_at"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_push$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_push"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_push$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_push"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_get$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_get"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_get$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_get"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_new$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_new"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_new$24w"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_new"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell_type$24w"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell_type"(ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %2
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Ebuilders"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ELanguageFeature$2Egram"()

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecell_shape"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %1 to ptr
  %2 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %2 to ptr
  %3 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %3, i64 11)
  call void @avra_array_push_owned(ptr %3, ptr %boxed1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set_at"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp ne i64 %3, 2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %4, ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %7 = call i64 @avra_array_get(ptr %6, i64 5)
  %boxed1 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %8)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr %boxed1, ptr %9)
  %cmp2 = icmp ne ptr %10, null
  %not = xor i1 %cmp2, true
  br i1 %not, label %then3, label %else4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.8, i64 16))
  br label %endif

then3:                                            ; preds = %endif
  %11 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  %12 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %11, ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %13 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %14 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %13)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %10)
  %15 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %14, i64 0, ptr %10)
  %16 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed8 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed8, i64 0)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %17)
  %19 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed9 = inttoptr i64 %19 to ptr
  %20 = call i64 @avra_array_get(ptr %boxed9, i64 1)
  call void @avra_rc_retain(ptr %0)
  %21 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %20)
  %22 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %22, i64 %15)
  call void @avra_array_push(ptr %22, i64 %18)
  call void @avra_array_push(ptr %22, i64 %21)
  %23 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %23, i64 6)
  call void @avra_array_push_owned(ptr %23, ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  %24 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %23)
  %25 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %25)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %26)
  %27 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %0, ptr %26)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.10, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %27

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.9, i64 16))
  br label %endif5
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set_at"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eheld_type"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed1, ptr %6)
  %cmp2 = icmp ne ptr %7, null
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  br label %endif

then4:                                            ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %9, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %9)
  %11 = call ptr @avra_insist(ptr %7)
  %12 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %12, ptr %10)
  call void @avra_array_push_owned(ptr %12, ptr %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_retain(ptr %12)
  %13 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.11, i64 16), ptr %12)
  %not9 = xor i1 %13, true
  br i1 %not9, label %then10, label %else11

postret7:                                         ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif6

then10:                                           ; preds = %endif6
  %14 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

else11:                                           ; preds = %endif6
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.11, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

postret13:                                        ; No predecessors!
  call void @avra_rc_release(ptr %14)
  br label %endif12
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eheld_type"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %3 = call i64 @avra_array_get(ptr %2, i64 5)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %4)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %5)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr %boxed, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_push"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_len(ptr %2)
  %cmp = icmp slt i64 0, %3
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 0)
  %5 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %5, i64 %4)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  %cmp1 = icmp ne ptr %ld, null
  %not = xor i1 %cmp1, true
  br i1 %not, label %then2, label %else3

then2:                                            ; preds = %endif
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %6, ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %9 = call i64 @avra_array_get(ptr %8, i64 5)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %10)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr %boxed, ptr %11)
  %cmp6 = icmp ne ptr %12, null
  %not7 = xor i1 %cmp6, true
  br i1 %not7, label %then8, label %else9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.12, i64 16))
  br label %endif4

then8:                                            ; preds = %endif4
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  %14 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %13, ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %14

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  %15 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %15)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %17 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %16, i64 0, ptr %12)
  %18 = call ptr @avra_insist(ptr %ld)
  %19 = call i64 @avra_array_get(ptr %18, i64 0)
  call void @avra_rc_retain(ptr %0)
  %20 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %19)
  %21 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %21, i64 %17)
  call void @avra_array_push(ptr %21, i64 %20)
  %22 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %22, i64 6)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr %21)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %22)
  %24 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %24)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %25)
  %26 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %0, ptr %25)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %26

postret11:                                        ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.13, i64 16))
  br label %endif10
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_push"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eheld_type"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eelement"(ptr %boxed1, ptr %6)
  %cmp2 = icmp ne ptr %7, null
  %not3 = xor i1 %cmp2, true
  br i1 %not3, label %then4, label %else5

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  br label %endif

then4:                                            ; preds = %endif
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret7
  %regval8 = phi i64 [ 0, %postret7 ], [ 0, %else5 ]
  %9 = call ptr @avra_insist(ptr %7)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %10, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_retain(ptr %10)
  %11 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.15, i64 16), ptr %10)
  %not9 = xor i1 %11, true
  br i1 %not9, label %then10, label %else11

postret7:                                         ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif6

then10:                                           ; preds = %endif6
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else11:                                           ; preds = %endif6
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  %13 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %13, i64 6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret13:                                        ; No predecessors!
  call void @avra_rc_release(ptr %12)
  br label %endif12
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_set"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Econst_int"(ptr %0, i64 0)
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %6)
  %8 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %8, i64 %3)
  call void @avra_array_push(ptr %8, i64 %4)
  call void @avra_array_push(ptr %8, i64 %7)
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %9, i64 6)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eemit"(ptr %0, ptr %9)
  %11 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %11)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ehollow_of"(ptr %0, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %13
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_set"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eheld_type"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call ptr @avra_insist(ptr %2)
  %4 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %4, ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_retain(ptr %4)
  %5 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16), ptr %4)
  %not1 = xor i1 %5, true
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %7 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %7, i64 6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Einterned"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %6)
  br label %endif4
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_get"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %2)
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %5 = call i64 @avra_array_get(ptr %4, i64 5)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Etype_at"(ptr %0, i64 %6)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Ecell_inner"(ptr %boxed, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eslot_read"(ptr %0, i64 %3, i64 0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %9
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_get"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eheld_type"(ptr %0, ptr %1)
  %cmp = icmp ne ptr %2, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_retain(ptr %3)
  %4 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eseated"(ptr %0, ptr %1, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16), ptr %3)
  %not1 = xor i1 %4, true
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  %6 = call ptr @avra_insist(ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif4
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 11
  call void @avra_rc_release(ptr %0)
  ret i1 %cmp
}

define i64 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Elower_new"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp ne i64 %3, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Elower_defect"(ptr %0, i64 %4, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2ELowerCx$2Ereg_of"(ptr %0, i64 %7)
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Ebox_size"(ptr %0, i64 1)
  %10 = call i64 @avra_array_get(ptr %1, i64 0)
  call void @avra_rc_retain(ptr %0)
  %11 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Eresult"(ptr %0, i64 %10)
  %12 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %12, i64 %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ELowerCx$2Egrown_box"(ptr %0, i64 %11, i64 %9, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %11

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  br label %endif
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Echeck_new"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp ne i64 %3, 1
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %5 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_len(ptr %boxed1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  %7 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Ewrong_arity"(ptr %0, i64 %4, ptr getelementptr inbounds (i8, ptr @.str.20, i64 16), i64 1, i64 %6)
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %9 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed2 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed2, i64 0)
  call void @avra_rc_retain(ptr %0)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Etype_at"(ptr %0, i64 %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i1 @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eerrored_ty"(ptr %0, ptr %11)
  br i1 %12, label %then3, label %else4

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  br label %endif

then3:                                            ; preds = %endif
  %13 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %13

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %postret6
  %regval7 = phi i64 [ 0, %postret6 ], [ 0, %else4 ]
  %14 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %15 = call i64 @avra_array_get(ptr %14, i64 5)
  %boxed8 = inttoptr i64 %15 to ptr
  %16 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed9 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed9, i64 5)
  %boxed10 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %boxed10)
  call void @avra_rc_retain(ptr %11)
  %18 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eshape_of"(ptr %boxed10, ptr %11)
  call void @avra_rc_retain(ptr %boxed8)
  call void @avra_rc_retain(ptr %18)
  %19 = call i1 @"av_$40std$2Eavrac$2Efeatures$2Eslot_worthy"(ptr %boxed8, ptr %18)
  %not = xor i1 %19, true
  br i1 %not, label %then11, label %else12

postret6:                                         ; No predecessors!
  call void @avra_rc_release(ptr %13)
  br label %endif5

then11:                                           ; preds = %endif5
  %20 = call i64 @avra_array_get(ptr %1, i64 2)
  %boxed14 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %boxed14, i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ETypeCx$2Eunslottable"(ptr %0, i64 %21, ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %22

else12:                                           ; preds = %endif5
  br label %endif13

endif13:                                          ; preds = %else12, %postret15
  %regval16 = phi i64 [ 0, %postret15 ], [ 0, %else12 ]
  %23 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed17 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed17, i64 5)
  %boxed18 = inttoptr i64 %24 to ptr
  %25 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %25, i64 11)
  call void @avra_array_push_owned(ptr %25, ptr %11)
  call void @avra_rc_retain(ptr %boxed18)
  call void @avra_rc_retain(ptr %25)
  %26 = call ptr @"av_$40std$2Eavrac$2Ecore$2ETypeRegistry$2Eintern"(ptr %boxed18, ptr %25)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %26

postret15:                                        ; No predecessors!
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  br label %endif13
}

define i1 @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Eon_cell_type"(ptr %0) {
entry:
  %1 = call i64 @avra_array_get(ptr %0, i64 0)
  %cmp = icmp eq i64 %1, 20
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br i1 true, label %then1, label %else2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %endif6
  %regval9 = phi i1 [ %regval8, %endif6 ], [ false, %else ]
  br i1 %regval9, label %then10, label %else11

then1:                                            ; preds = %then
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  br label %endif3

else2:                                            ; preds = %then
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval = phi i1 [ true, %then1 ], [ false, %else2 ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif3
  %3 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed7 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed7, ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  %b = icmp ne i64 %4, 0
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  br label %endif6

else5:                                            ; preds = %endif3
  br label %endif6

endif6:                                           ; preds = %else5, %then4
  %regval8 = phi i1 [ %b, %then4 ], [ false, %else5 ]
  br label %endif

then10:                                           ; preds = %endif
  br label %endif12

else11:                                           ; preds = %endif
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi i1 [ true, %then10 ], [ false, %else11 ]
  call void @avra_rc_release(ptr %0)
  ret i1 %regval13
}
