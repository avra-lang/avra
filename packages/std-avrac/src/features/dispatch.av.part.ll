; ModuleID = 'avra'
source_filename = "avra"

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

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp1 = icmp eq i64 %3, 1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp5 = icmp eq i64 %4, 4
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp10 = icmp eq i64 %5, 6
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp15 = icmp eq i64 %6, 7
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  br label %endif19

else18:                                           ; preds = %endif14
  %7 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp20 = icmp eq i64 %7, 11
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval21 = phi i1 [ true, %then17 ], [ %cmp20, %else18 ]
  br i1 %regval21, label %then22, label %else23

then22:                                           ; preds = %endif19
  br label %endif24

else23:                                           ; preds = %endif19
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp25 = icmp eq i64 %8, 12
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br i1 %regval26, label %then27, label %else28

then27:                                           ; preds = %endif24
  br label %endif29

else28:                                           ; preds = %endif24
  %9 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp30 = icmp eq i64 %9, 33
  br label %endif29

endif29:                                          ; preds = %else28, %then27
  %regval31 = phi i1 [ true, %then27 ], [ %cmp30, %else28 ]
  br i1 %regval31, label %then32, label %else33

then32:                                           ; preds = %endif29
  %10 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  br label %endif34

else33:                                           ; preds = %endif29
  %11 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp35 = icmp eq i64 %11, 8
  br i1 %cmp35, label %then36, label %else37

endif34:                                          ; preds = %endif43, %then32
  %regval155 = phi ptr [ %10, %then32 ], [ %regval154, %endif43 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval155

then36:                                           ; preds = %else33
  br label %endif38

else37:                                           ; preds = %else33
  %12 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp39 = icmp eq i64 %12, 9
  br label %endif38

endif38:                                          ; preds = %else37, %then36
  %regval40 = phi i1 [ true, %then36 ], [ %cmp39, %else37 ]
  br i1 %regval40, label %then41, label %else42

then41:                                           ; preds = %endif38
  %13 = call ptr @avra_array_get_owned(ptr %0, i64 7)
  br label %endif43

else42:                                           ; preds = %endif38
  %14 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp44 = icmp eq i64 %14, 10
  br i1 %cmp44, label %then45, label %else46

endif43:                                          ; preds = %endif47, %then41
  %regval154 = phi ptr [ %13, %then41 ], [ %regval153, %endif47 ]
  br label %endif34

then45:                                           ; preds = %else42
  %15 = call ptr @avra_array_get_owned(ptr %0, i64 35)
  br label %endif47

else46:                                           ; preds = %else42
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp48 = icmp eq i64 %16, 2
  br i1 %cmp48, label %then49, label %else50

endif47:                                          ; preds = %endif51, %then45
  %regval153 = phi ptr [ %15, %then45 ], [ %regval152, %endif51 ]
  br label %endif43

then49:                                           ; preds = %else46
  %17 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endif51

else50:                                           ; preds = %else46
  %18 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp52 = icmp eq i64 %18, 13
  br i1 %cmp52, label %then53, label %else54

endif51:                                          ; preds = %endif55, %then49
  %regval152 = phi ptr [ %17, %then49 ], [ %regval151, %endif55 ]
  br label %endif47

then53:                                           ; preds = %else50
  %19 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %19 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebody_semantics"(ptr %0, ptr %boxed)
  br label %endif55

else54:                                           ; preds = %else50
  %21 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp56 = icmp eq i64 %21, 3
  br i1 %cmp56, label %then57, label %else58

endif55:                                          ; preds = %endif59, %then53
  %regval151 = phi ptr [ %20, %then53 ], [ %regval150, %endif59 ]
  br label %endif51

then57:                                           ; preds = %else54
  %22 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  br label %endif59

else58:                                           ; preds = %else54
  %23 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp60 = icmp eq i64 %23, 14
  br i1 %cmp60, label %then61, label %else62

endif59:                                          ; preds = %endif63, %then57
  %regval150 = phi ptr [ %22, %then57 ], [ %regval149, %endif63 ]
  br label %endif55

then61:                                           ; preds = %else58
  %24 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  br label %endif63

else62:                                           ; preds = %else58
  %25 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp64 = icmp eq i64 %25, 15
  br i1 %cmp64, label %then65, label %else66

endif63:                                          ; preds = %endif67, %then61
  %regval149 = phi ptr [ %24, %then61 ], [ %regval148, %endif67 ]
  br label %endif59

then65:                                           ; preds = %else62
  %26 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  br label %endif67

else66:                                           ; preds = %else62
  %27 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp68 = icmp eq i64 %27, 16
  br i1 %cmp68, label %then69, label %else70

endif67:                                          ; preds = %endif71, %then65
  %regval148 = phi ptr [ %26, %then65 ], [ %regval147, %endif71 ]
  br label %endif63

then69:                                           ; preds = %else66
  %28 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  br label %endif71

else70:                                           ; preds = %else66
  %29 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp72 = icmp eq i64 %29, 17
  br i1 %cmp72, label %then73, label %else74

endif71:                                          ; preds = %endif75, %then69
  %regval147 = phi ptr [ %28, %then69 ], [ %regval146, %endif75 ]
  br label %endif67

then73:                                           ; preds = %else70
  %30 = call ptr @avra_array_get_owned(ptr %0, i64 6)
  br label %endif75

else74:                                           ; preds = %else70
  %31 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp76 = icmp eq i64 %31, 18
  br i1 %cmp76, label %then77, label %else78

endif75:                                          ; preds = %endif84, %then73
  %regval146 = phi ptr [ %30, %then73 ], [ %regval145, %endif84 ]
  br label %endif71

then77:                                           ; preds = %else74
  br label %endif79

else78:                                           ; preds = %else74
  %32 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp80 = icmp eq i64 %32, 19
  br label %endif79

endif79:                                          ; preds = %else78, %then77
  %regval81 = phi i1 [ true, %then77 ], [ %cmp80, %else78 ]
  br i1 %regval81, label %then82, label %else83

then82:                                           ; preds = %endif79
  %33 = call ptr @avra_array_get_owned(ptr %0, i64 8)
  br label %endif84

else83:                                           ; preds = %endif79
  %34 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp85 = icmp eq i64 %34, 20
  br i1 %cmp85, label %then86, label %else87

endif84:                                          ; preds = %endif98, %then82
  %regval145 = phi ptr [ %33, %then82 ], [ %regval144, %endif98 ]
  br label %endif75

then86:                                           ; preds = %else83
  br label %endif88

else87:                                           ; preds = %else83
  %35 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp89 = icmp eq i64 %35, 28
  br label %endif88

endif88:                                          ; preds = %else87, %then86
  %regval90 = phi i1 [ true, %then86 ], [ %cmp89, %else87 ]
  br i1 %regval90, label %then91, label %else92

then91:                                           ; preds = %endif88
  br label %endif93

else92:                                           ; preds = %endif88
  %36 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp94 = icmp eq i64 %36, 29
  br label %endif93

endif93:                                          ; preds = %else92, %then91
  %regval95 = phi i1 [ true, %then91 ], [ %cmp94, %else92 ]
  br i1 %regval95, label %then96, label %else97

then96:                                           ; preds = %endif93
  %37 = call ptr @avra_array_get_owned(ptr %0, i64 9)
  br label %endif98

else97:                                           ; preds = %endif93
  %38 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp99 = icmp eq i64 %38, 21
  br i1 %cmp99, label %then100, label %else101

endif98:                                          ; preds = %endif127, %then96
  %regval144 = phi ptr [ %37, %then96 ], [ %regval143, %endif127 ]
  br label %endif84

then100:                                          ; preds = %else97
  br label %endif102

else101:                                          ; preds = %else97
  %39 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp103 = icmp eq i64 %39, 22
  br label %endif102

endif102:                                         ; preds = %else101, %then100
  %regval104 = phi i1 [ true, %then100 ], [ %cmp103, %else101 ]
  br i1 %regval104, label %then105, label %else106

then105:                                          ; preds = %endif102
  br label %endif107

else106:                                          ; preds = %endif102
  %40 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp108 = icmp eq i64 %40, 27
  br label %endif107

endif107:                                         ; preds = %else106, %then105
  %regval109 = phi i1 [ true, %then105 ], [ %cmp108, %else106 ]
  br i1 %regval109, label %then110, label %else111

then110:                                          ; preds = %endif107
  br label %endif112

else111:                                          ; preds = %endif107
  %41 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp113 = icmp eq i64 %41, 30
  br label %endif112

endif112:                                         ; preds = %else111, %then110
  %regval114 = phi i1 [ true, %then110 ], [ %cmp113, %else111 ]
  br i1 %regval114, label %then115, label %else116

then115:                                          ; preds = %endif112
  br label %endif117

else116:                                          ; preds = %endif112
  %42 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp118 = icmp eq i64 %42, 23
  br label %endif117

endif117:                                         ; preds = %else116, %then115
  %regval119 = phi i1 [ true, %then115 ], [ %cmp118, %else116 ]
  br i1 %regval119, label %then120, label %else121

then120:                                          ; preds = %endif117
  br label %endif122

else121:                                          ; preds = %endif117
  %43 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp123 = icmp eq i64 %43, 26
  br label %endif122

endif122:                                         ; preds = %else121, %then120
  %regval124 = phi i1 [ true, %then120 ], [ %cmp123, %else121 ]
  br i1 %regval124, label %then125, label %else126

then125:                                          ; preds = %endif122
  %44 = call ptr @avra_array_get_owned(ptr %0, i64 10)
  br label %endif127

else126:                                          ; preds = %endif122
  %45 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp128 = icmp eq i64 %45, 31
  br i1 %cmp128, label %then129, label %else130

endif127:                                         ; preds = %endif131, %then125
  %regval143 = phi ptr [ %44, %then125 ], [ %regval142, %endif131 ]
  br label %endif98

then129:                                          ; preds = %else126
  %46 = call ptr @avra_array_get_owned(ptr %0, i64 11)
  br label %endif131

else130:                                          ; preds = %else126
  %47 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp132 = icmp eq i64 %47, 32
  br i1 %cmp132, label %then133, label %else134

endif131:                                         ; preds = %endif140, %then129
  %regval142 = phi ptr [ %46, %then129 ], [ %regval141, %endif140 ]
  br label %endif127

then133:                                          ; preds = %else130
  br label %endif135

else134:                                          ; preds = %else130
  %48 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp136 = icmp eq i64 %48, 5
  br label %endif135

endif135:                                         ; preds = %else134, %then133
  %regval137 = phi i1 [ true, %then133 ], [ %cmp136, %else134 ]
  br i1 %regval137, label %then138, label %else139

then138:                                          ; preds = %endif135
  %49 = call ptr @avra_array_get_owned(ptr %0, i64 33)
  br label %endif140

else139:                                          ; preds = %endif135
  %50 = call ptr @avra_array_get_owned(ptr %0, i64 34)
  br label %endif140

endif140:                                         ; preds = %else139, %then138
  %regval141 = phi ptr [ %49, %then138 ], [ %50, %else139 ]
  br label %endif131
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Ebody_semantics"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Ecore$2Ebody_behavior"(ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm2 [
    i64 0, label %arm
    i64 1, label %arm1
  ]

arm:                                              ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 12)
  br label %endswitch

arm2:                                             ; preds = %entry
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 13)
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi ptr [ %4, %arm ], [ %5, %arm1 ], [ %6, %arm2 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Ebody_behavior"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 15)
  br label %endif

else:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp1 = icmp eq i64 %4, 1
  br i1 %cmp1, label %then2, label %else3

endif:                                            ; preds = %endif4, %then
  %regval115 = phi ptr [ %3, %then ], [ %regval114, %endif4 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval115

then2:                                            ; preds = %else
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 19)
  br label %endif4

else3:                                            ; preds = %else
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp5 = icmp eq i64 %6, 2
  br i1 %cmp5, label %then6, label %else7

endif4:                                           ; preds = %endif8, %then2
  %regval114 = phi ptr [ %5, %then2 ], [ %regval113, %endif8 ]
  br label %endif

then6:                                            ; preds = %else3
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 20)
  br label %endif8

else7:                                            ; preds = %else3
  %8 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp9 = icmp eq i64 %8, 3
  br i1 %cmp9, label %then10, label %else11

endif8:                                           ; preds = %endif12, %then6
  %regval113 = phi ptr [ %7, %then6 ], [ %regval112, %endif12 ]
  br label %endif4

then10:                                           ; preds = %else7
  %9 = call ptr @avra_array_get_owned(ptr %0, i64 21)
  br label %endif12

else11:                                           ; preds = %else7
  %10 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp13 = icmp eq i64 %10, 4
  br i1 %cmp13, label %then14, label %else15

endif12:                                          ; preds = %endif20, %then10
  %regval112 = phi ptr [ %9, %then10 ], [ %regval111, %endif20 ]
  br label %endif8

then14:                                           ; preds = %else11
  br label %endif16

else15:                                           ; preds = %else11
  %11 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp17 = icmp eq i64 %11, 5
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval = phi i1 [ true, %then14 ], [ %cmp17, %else15 ]
  br i1 %regval, label %then18, label %else19

then18:                                           ; preds = %endif16
  %12 = call ptr @avra_array_get_owned(ptr %0, i64 16)
  br label %endif20

else19:                                           ; preds = %endif16
  %13 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp21 = icmp eq i64 %13, 6
  br i1 %cmp21, label %then22, label %else23

endif20:                                          ; preds = %endif29, %then18
  %regval111 = phi ptr [ %12, %then18 ], [ %regval110, %endif29 ]
  br label %endif12

then22:                                           ; preds = %else19
  br label %endif24

else23:                                           ; preds = %else19
  %14 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp25 = icmp eq i64 %14, 7
  br label %endif24

endif24:                                          ; preds = %else23, %then22
  %regval26 = phi i1 [ true, %then22 ], [ %cmp25, %else23 ]
  br i1 %regval26, label %then27, label %else28

then27:                                           ; preds = %endif24
  %15 = call ptr @avra_array_get_owned(ptr %0, i64 17)
  br label %endif29

else28:                                           ; preds = %endif24
  %16 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp30 = icmp eq i64 %16, 8
  br i1 %cmp30, label %then31, label %else32

endif29:                                          ; preds = %endif33, %then27
  %regval110 = phi ptr [ %15, %then27 ], [ %regval109, %endif33 ]
  br label %endif20

then31:                                           ; preds = %else28
  %17 = call ptr @avra_array_get_owned(ptr %0, i64 22)
  br label %endif33

else32:                                           ; preds = %else28
  %18 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp34 = icmp eq i64 %18, 15
  br i1 %cmp34, label %then35, label %else36

endif33:                                          ; preds = %endif37, %then31
  %regval109 = phi ptr [ %17, %then31 ], [ %regval108, %endif37 ]
  br label %endif29

then35:                                           ; preds = %else32
  %19 = call ptr @avra_array_get_owned(ptr %0, i64 23)
  br label %endif37

else36:                                           ; preds = %else32
  %20 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp38 = icmp eq i64 %20, 18
  br i1 %cmp38, label %then39, label %else40

endif37:                                          ; preds = %endif41, %then35
  %regval108 = phi ptr [ %19, %then35 ], [ %regval107, %endif41 ]
  br label %endif33

then39:                                           ; preds = %else36
  %21 = call ptr @avra_array_get_owned(ptr %0, i64 24)
  br label %endif41

else40:                                           ; preds = %else36
  %22 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp42 = icmp eq i64 %22, 19
  br i1 %cmp42, label %then43, label %else44

endif41:                                          ; preds = %endif45, %then39
  %regval107 = phi ptr [ %21, %then39 ], [ %regval106, %endif45 ]
  br label %endif37

then43:                                           ; preds = %else40
  %23 = call ptr @avra_array_get_owned(ptr %0, i64 25)
  br label %endif45

else44:                                           ; preds = %else40
  %24 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp46 = icmp eq i64 %24, 20
  br i1 %cmp46, label %then47, label %else48

endif45:                                          ; preds = %endif49, %then43
  %regval106 = phi ptr [ %23, %then43 ], [ %regval105, %endif49 ]
  br label %endif41

then47:                                           ; preds = %else44
  %25 = call ptr @avra_array_get_owned(ptr %0, i64 26)
  br label %endif49

else48:                                           ; preds = %else44
  %26 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp50 = icmp eq i64 %26, 9
  br i1 %cmp50, label %then51, label %else52

endif49:                                          ; preds = %endif53, %then47
  %regval105 = phi ptr [ %25, %then47 ], [ %regval104, %endif53 ]
  br label %endif45

then51:                                           ; preds = %else48
  %27 = call ptr @avra_array_get_owned(ptr %0, i64 27)
  br label %endif53

else52:                                           ; preds = %else48
  %28 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp54 = icmp eq i64 %28, 10
  br i1 %cmp54, label %then55, label %else56

endif53:                                          ; preds = %endif57, %then51
  %regval104 = phi ptr [ %27, %then51 ], [ %regval103, %endif57 ]
  br label %endif49

then55:                                           ; preds = %else52
  %29 = call ptr @avra_array_get_owned(ptr %0, i64 28)
  br label %endif57

else56:                                           ; preds = %else52
  %30 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp58 = icmp eq i64 %30, 14
  br i1 %cmp58, label %then59, label %else60

endif57:                                          ; preds = %endif61, %then55
  %regval103 = phi ptr [ %29, %then55 ], [ %regval102, %endif61 ]
  br label %endif53

then59:                                           ; preds = %else56
  %31 = call ptr @avra_array_get_owned(ptr %0, i64 29)
  br label %endif61

else60:                                           ; preds = %else56
  %32 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp62 = icmp eq i64 %32, 11
  br i1 %cmp62, label %then63, label %else64

endif61:                                          ; preds = %endif65, %then59
  %regval102 = phi ptr [ %31, %then59 ], [ %regval101, %endif65 ]
  br label %endif57

then63:                                           ; preds = %else60
  %33 = call ptr @avra_array_get_owned(ptr %0, i64 30)
  br label %endif65

else64:                                           ; preds = %else60
  %34 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp66 = icmp eq i64 %34, 17
  br i1 %cmp66, label %then67, label %else68

endif65:                                          ; preds = %endif69, %then63
  %regval101 = phi ptr [ %33, %then63 ], [ %regval100, %endif69 ]
  br label %endif61

then67:                                           ; preds = %else64
  %35 = call ptr @avra_array_get_owned(ptr %0, i64 31)
  br label %endif69

else68:                                           ; preds = %else64
  %36 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp70 = icmp eq i64 %36, 12
  br i1 %cmp70, label %then71, label %else72

endif69:                                          ; preds = %endif78, %then67
  %regval100 = phi ptr [ %35, %then67 ], [ %regval99, %endif78 ]
  br label %endif65

then71:                                           ; preds = %else68
  br label %endif73

else72:                                           ; preds = %else68
  %37 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp74 = icmp eq i64 %37, 13
  br label %endif73

endif73:                                          ; preds = %else72, %then71
  %regval75 = phi i1 [ true, %then71 ], [ %cmp74, %else72 ]
  br i1 %regval75, label %then76, label %else77

then76:                                           ; preds = %endif73
  %38 = call ptr @avra_array_get_owned(ptr %0, i64 32)
  br label %endif78

else77:                                           ; preds = %endif73
  %39 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp79 = icmp eq i64 %39, 22
  br i1 %cmp79, label %then80, label %else81

endif78:                                          ; preds = %endif82, %then76
  %regval99 = phi ptr [ %38, %then76 ], [ %regval98, %endif82 ]
  br label %endif69

then80:                                           ; preds = %else77
  %40 = call ptr @avra_array_get_owned(ptr %0, i64 14)
  br label %endif82

else81:                                           ; preds = %else77
  %41 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp83 = icmp eq i64 %41, 16
  br i1 %cmp83, label %then84, label %else85

endif82:                                          ; preds = %endif86, %then80
  %regval98 = phi ptr [ %40, %then80 ], [ %regval97, %endif86 ]
  br label %endif78

then84:                                           ; preds = %else81
  %42 = call ptr @avra_array_get_owned(ptr %0, i64 36)
  br label %endif86

else85:                                           ; preds = %else81
  %43 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp87 = icmp eq i64 %43, 21
  br i1 %cmp87, label %then88, label %else89

endif86:                                          ; preds = %endif90, %then84
  %regval97 = phi ptr [ %42, %then84 ], [ %regval96, %endif90 ]
  br label %endif82

then88:                                           ; preds = %else85
  %44 = call ptr @avra_array_get_owned(ptr %0, i64 37)
  br label %endif90

else89:                                           ; preds = %else85
  %45 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp91 = icmp eq i64 %45, 23
  br i1 %cmp91, label %then92, label %else93

endif90:                                          ; preds = %endif94, %then88
  %regval96 = phi ptr [ %44, %then88 ], [ %regval95, %endif94 ]
  br label %endif86

then92:                                           ; preds = %else89
  %46 = call ptr @avra_array_get_owned(ptr %0, i64 38)
  br label %endif94

else93:                                           ; preds = %else89
  %47 = call ptr @avra_array_get_owned(ptr %0, i64 18)
  br label %endif94

endif94:                                          ; preds = %else93, %then92
  %regval95 = phi ptr [ %46, %then92 ], [ %47, %else93 ]
  br label %endif90
}

define ptr @"av_$40std$2Eavrac$2Efeatures$2Epost_order"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %1)
  %3 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %1, i64 %2)
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %0, ptr %3)
  %6 = call ptr @avra_array_get_owned(ptr %5, i64 0)
  %7 = call i64 @avra_array_get(ptr %5, i64 1)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %3)
  %cast = inttoptr i64 %7 to ptr
  %8 = call ptr %cast(ptr %6, ptr %3)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %9
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %4)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr %4)
  %11 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %11, i64 %2)
  %12 = call ptr @avra_array_concat(ptr %10, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %13 = call i64 @avra_array_get(ptr %8, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epost_order"(ptr %0, ptr %1, i64 %13)
  call void @avra_array_push_owned(ptr %4, ptr %14)
  %ld2 = load i64, ptr %slot, align 8
  %add = add i64 %ld2, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %14)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$2488"(ptr)

define ptr @"av_$40std$2Eavrac$2Efeatures$2Epat_semantics_of"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp = icmp eq i64 %2, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp1 = icmp eq i64 %3, 1
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %cmp1, %else ]
  br i1 %regval, label %then2, label %else3

then2:                                            ; preds = %endif
  br label %endif4

else3:                                            ; preds = %endif
  %4 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp5 = icmp eq i64 %4, 2
  br label %endif4

endif4:                                           ; preds = %else3, %then2
  %regval6 = phi i1 [ true, %then2 ], [ %cmp5, %else3 ]
  br i1 %regval6, label %then7, label %else8

then7:                                            ; preds = %endif4
  br label %endif9

else8:                                            ; preds = %endif4
  %5 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp10 = icmp eq i64 %5, 3
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i1 [ true, %then7 ], [ %cmp10, %else8 ]
  br i1 %regval11, label %then12, label %else13

then12:                                           ; preds = %endif9
  br label %endif14

else13:                                           ; preds = %endif9
  %6 = call i64 @avra_array_get(ptr %1, i64 0)
  %cmp15 = icmp eq i64 %6, 4
  br label %endif14

endif14:                                          ; preds = %else13, %then12
  %regval16 = phi i1 [ true, %then12 ], [ %cmp15, %else13 ]
  br i1 %regval16, label %then17, label %else18

then17:                                           ; preds = %endif14
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 39)
  br label %endif19

else18:                                           ; preds = %endif14
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 40)
  br label %endif19

endif19:                                          ; preds = %else18, %then17
  %regval20 = phi ptr [ %7, %then17 ], [ %8, %else18 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval20
}
