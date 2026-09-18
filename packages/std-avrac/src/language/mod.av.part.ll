; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"lex.error\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0001\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [46 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 45 }, [46 x i8] c"a character or string the lexer cannot accept\00" }, align 16
@"av_const$5$10$0" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$0", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$0", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.1, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.2, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"parse.expected\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0100\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [43 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 42 }, [43 x i8] c"the parse needed a token that is not there\00" }, align 16
@"av_const$5$10$1" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$1", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$1", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.3, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.4, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.5, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"parse.trailing\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0101\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [38 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 37 }, [38 x i8] c"input remains after the program ended\00" }, align 16
@"av_const$5$10$2" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$2", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$2", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.6, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.7, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.8, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"build.failed\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0102\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [32 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 31 }, [32 x i8] c"a builder rejected its captures\00" }, align 16
@"av_const$5$10$3" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$3", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$3", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.9, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.10, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.11, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"language.defect\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0900\00" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"the language definition itself is defective\00" }, align 16
@"av_const$5$10$4" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$4", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$4", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.12, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.13, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.14, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"block.parse\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F2082\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [42 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 41 }, [42 x i8] c"a sublanguage block parses by its grammar\00" }, align 16
@"av_const$5$10$5" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$5", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$5", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.15, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.16, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.17, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.unresolved\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3000\00" }, align 16
@.str.20 = private unnamed_addr constant { { i32, i32, i32, i32 }, [22 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 21 }, [22 x i8] c"a name is not defined\00" }, align 16
@"av_const$5$10$6" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$6", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$6", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.18, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.19, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.20, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.21 = private unnamed_addr constant { { i32, i32, i32, i32 }, [23 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 22 }, [23 x i8] c"resolve.use_before_def\00" }, align 16
@.str.22 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3001\00" }, align 16
@.str.23 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"a name is used before its definition\00" }, align 16
@"av_const$5$10$7" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$7", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$7", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.21, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.22, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.23, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.24 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"resolve.reserved\00" }, align 16
@.str.25 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3002\00" }, align 16
@.str.26 = private unnamed_addr constant { { i32, i32, i32, i32 }, [50 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 49 }, [50 x i8] c"the name is a keyword \E2\80\94 today's or a future one\00" }, align 16
@"av_const$5$10$8" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$8", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$8", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.24, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.25, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.26, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.27 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"lower.no_projection\00" }, align 16
@.str.28 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0901\00" }, align 16
@.str.29 = private unnamed_addr constant { { i32, i32, i32, i32 }, [44 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 43 }, [44 x i8] c"the program's answer has no text projection\00" }, align 16
@"av_const$5$10$9" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$9", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$9", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.27, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.28, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.29, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.30 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"lower.entry_only\00" }, align 16
@.str.31 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F0902\00" }, align 16
@.str.32 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"run-time statements belong to the entry file\00" }, align 16
@"av_const$5$10$10" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$10", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$10", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.30, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.31, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.32, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.33 = private unnamed_addr constant { { i32, i32, i32, i32 }, [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 15 }, [16 x i8] c"type.type_value\00" }, align 16
@.str.34 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F2014\00" }, align 16
@.str.35 = private unnamed_addr constant { { i32, i32, i32, i32 }, [27 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 26 }, [27 x i8] c"a type name is not a value\00" }, align 16
@"av_const$5$10$11" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$11", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$11", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.33, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.34, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.35, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.36 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"resolve.nested_type\00" }, align 16
@.str.37 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3007\00" }, align 16
@.str.38 = private unnamed_addr constant { { i32, i32, i32, i32 }, [40 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 39 }, [40 x i8] c"type declarations live at the top level\00" }, align 16
@"av_const$5$10$12" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$12", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$12", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.36, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.37, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.38, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.39 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"resolve.builtin_type\00" }, align 16
@.str.40 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3008\00" }, align 16
@.str.41 = private unnamed_addr constant { { i32, i32, i32, i32 }, [42 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 41 }, [42 x i8] c"a built-in type name cannot be redeclared\00" }, align 16
@"av_const$5$10$13" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$13", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$13", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.39, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.40, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.41, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.42 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"resolve.paired\00" }, align 16
@.str.43 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3010\00" }, align 16
@.str.44 = private unnamed_addr constant { { i32, i32, i32, i32 }, [49 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 48 }, [49 x i8] c"a pairing loop names its index and element apart\00" }, align 16
@"av_const$5$10$14" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$14", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$14", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.42, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.43, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.44, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@.str.45 = private unnamed_addr constant { { i32, i32, i32, i32 }, [24 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 23 }, [24 x i8] c"resolve.runtime_binding\00" }, align 16
@.str.46 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"F3020\00" }, align 16
@.str.47 = private unnamed_addr constant { { i32, i32, i32, i32 }, [56 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 55 }, [56 x i8] c"a fn body cannot read the top level's run-time bindings\00" }, align 16
@"av_const$5$10$15" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 3, i64 3, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$15", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [3 x i64], [3 x i8] }, ptr @"av_const$5$10$15", i32 0, i32 3), ptr null }, [3 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.45, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.46, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.47, i64 16) to i64)], [3 x i8] c"\01\01\01" }, align 16
@"av_const$5$10" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [16 x i64], [16 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 16, i64 16, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [16 x i64], [16 x i8] }, ptr @"av_const$5$10", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [16 x i64], [16 x i8] }, ptr @"av_const$5$10", i32 0, i32 3), ptr null }, [16 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$0", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$1", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$2", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$3", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$4", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$5", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$6", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$7", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$8", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$9", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$10", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$11", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$12", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$13", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$14", i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @"av_const$5$10$15", i64 16) to i64)], [16 x i8] c"\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01\01" }, align 16
@.str.48 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"<source>\00" }, align 16
@.str.49 = private unnamed_addr constant { { i32, i32, i32, i32 }, [25 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 24 }, [25 x i8] c"@std.avrac.language.avra\00" }, align 16

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

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eanalyze_source"(ptr %0) {
entry:
  %1 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eavra"()
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.48, i64 16))
  call void @avra_rc_retain(ptr %0)
  %2 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Enew_source_file"(ptr getelementptr inbounds (i8, ptr @.str.48, i64 16), ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2ELanguage$2Eanalyze"(ptr %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.48, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2ELanguage$2Eanalyze"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Enew_source_file"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Enode_builder_name"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2Eready"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eavra"() {
entry:
  %0 = call ptr @avra_once_get(ptr getelementptr inbounds (i8, ptr @.str.49, i64 16))
  %cmp = icmp ne ptr %0, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  br label %endif

else:                                             ; preds = %entry
  %1 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Elanguage_features"()
  call void @avra_rc_retain(ptr %1)
  %2 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eassemble"(ptr %1)
  call void @avra_once_set(ptr getelementptr inbounds (i8, ptr @.str.49, i64 16), ptr %2)
  call void @avra_rc_release(ptr %1)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %0, %then ], [ %2, %else ]
  call void @avra_rc_release(ptr %0)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.49, i64 16))
  ret ptr %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eassemble"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecompose_grammar"(ptr %0)
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Egrammar$2EGrammar$2Emerged"(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Enode_payload_rows"()
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebind_nodes"(ptr %3, ptr %4)
  %6 = call i64 @avra_array_get(ptr %5, i64 0)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Eready"(ptr %boxed1)
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ecode_registry"(ptr %0)
  %9 = call i64 @avra_array_get(ptr %7, i64 4)
  %boxed2 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %5, i64 1)
  %boxed3 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuilder_defects"(ptr %0, ptr %3)
  call void @avra_rc_retain(ptr %8)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecode_defects"(ptr %8)
  %13 = call ptr @avra_array_sized(i64 4)
  call void @avra_array_push_owned(ptr %13, ptr %boxed2)
  call void @avra_array_push_owned(ptr %13, ptr %boxed3)
  call void @avra_array_push_owned(ptr %13, ptr %11)
  call void @avra_array_push_owned(ptr %13, ptr %12)
  call void @avra_rc_retain(ptr %13)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24182"(ptr %13)
  %15 = call i64 @avra_array_len(ptr %14)
  %cmp = icmp eq i64 %15, 0
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %14)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eunassembled"(ptr %0, ptr %14)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %16

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuilder_index"(ptr %0)
  call void @avra_rc_retain(ptr %17)
  call void @avra_rc_retain(ptr %4)
  %18 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ewith_nodes"(ptr %17, ptr %4)
  call void @avra_rc_retain(ptr %3)
  %19 = call ptr @"av_$40std$2Eavrac$2Egrammar$2EGrammar$2Ekeywords"(ptr %3)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %20 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Erows_of"(ptr %0, ptr %8)
  %21 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Enew_dispatch"()
  %22 = call ptr @avra_array_sized(i64 0)
  %23 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %23, ptr %0)
  call void @avra_array_push_owned(ptr %23, ptr %18)
  call void @avra_array_push_owned(ptr %23, ptr %7)
  call void @avra_array_push_owned(ptr %23, ptr %19)
  call void @avra_array_push_owned(ptr %23, ptr %20)
  call void @avra_array_push_owned(ptr %23, ptr %21)
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %23

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %16)
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Enew_dispatch"()

define ptr @"av_$40std$2Eavrac$2Elanguage$2Erows_of"(ptr %0, ptr %1) {
entry:
  %slot26 = alloca i64, align 8
  %slot15 = alloca i64, align 8
  %slot4 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %2)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241110"(ptr %2)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot4, align 8
  br label %lhead5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed2 = inttoptr i64 %8 to ptr
  call void @avra_array_push_owned(ptr %2, ptr %boxed2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead5:                                           ; preds = %lbody9, %lexit
  %ld7 = load i64, ptr %slot4, align 8
  %cmp8 = icmp slt i64 %ld7, %6
  br i1 %cmp8, label %lbody9, label %lexit6

lexit6:                                           ; preds = %lhead5
  call void @avra_rc_retain(ptr %5)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24372"(ptr %5)
  %10 = call ptr @avra_array_sized(i64 0)
  %11 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot15, align 8
  br label %lhead16

lbody9:                                           ; preds = %lhead5
  %ld10 = load i64, ptr %slot4, align 8
  %12 = call i64 @avra_array_get(ptr %0, i64 %ld10)
  %boxed11 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed11, i64 6)
  %boxed12 = inttoptr i64 %13 to ptr
  call void @avra_array_push_owned(ptr %5, ptr %boxed12)
  %ld13 = load i64, ptr %slot4, align 8
  %add14 = add i64 %ld13, 1
  store i64 %add14, ptr %slot4, align 8
  br label %lhead5

lhead16:                                          ; preds = %lbody20, %lexit6
  %ld18 = load i64, ptr %slot15, align 8
  %cmp19 = icmp slt i64 %ld18, %11
  br i1 %cmp19, label %lbody20, label %lexit17

lexit17:                                          ; preds = %lhead16
  call void @avra_rc_retain(ptr %10)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241112"(ptr %10)
  %15 = call ptr @avra_array_sized(i64 0)
  %16 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot26, align 8
  br label %lhead27

lbody20:                                          ; preds = %lhead16
  %ld21 = load i64, ptr %slot15, align 8
  %17 = call i64 @avra_array_get(ptr %0, i64 %ld21)
  %boxed22 = inttoptr i64 %17 to ptr
  %18 = call i64 @avra_array_get(ptr %boxed22, i64 7)
  %boxed23 = inttoptr i64 %18 to ptr
  call void @avra_array_push_owned(ptr %10, ptr %boxed23)
  %ld24 = load i64, ptr %slot15, align 8
  %add25 = add i64 %ld24, 1
  store i64 %add25, ptr %slot15, align 8
  br label %lhead16

lhead27:                                          ; preds = %lbody31, %lexit17
  %ld29 = load i64, ptr %slot26, align 8
  %cmp30 = icmp slt i64 %ld29, %16
  br i1 %cmp30, label %lbody31, label %lexit28

lexit28:                                          ; preds = %lhead27
  call void @avra_rc_retain(ptr %15)
  %19 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241114"(ptr %15)
  %20 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %20, ptr %4)
  call void @avra_array_push_owned(ptr %20, ptr %9)
  call void @avra_array_push_owned(ptr %20, ptr %14)
  call void @avra_array_push_owned(ptr %20, ptr %1)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %20

lbody31:                                          ; preds = %lhead27
  %ld32 = load i64, ptr %slot26, align 8
  %21 = call i64 @avra_array_get(ptr %0, i64 %ld32)
  %boxed33 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %boxed33, i64 8)
  %boxed34 = inttoptr i64 %22 to ptr
  call void @avra_array_push_owned(ptr %15, ptr %boxed34)
  %ld35 = load i64, ptr %slot26, align 8
  %add36 = add i64 %ld35, 1
  store i64 %add36, ptr %slot26, align 8
  br label %lhead27
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241114"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241112"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24372"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$241110"(ptr)

declare ptr @"av_$40std$2Eavrac$2Egrammar$2EGrammar$2Ekeywords"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ewith_nodes"(ptr %0, ptr %1) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_cell_release(ptr %slot)
  store ptr %0, ptr %slot, align 8
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_builders"()
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld10 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld10)
  call void @avra_cell_release(ptr %slot2)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld10

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %4 = call ptr @avra_array_get_owned(ptr %2, i64 %ld3)
  call void @avra_rc_retain(ptr %4)
  call void @avra_cell_release(ptr %slot2)
  store ptr %4, ptr %slot2, align 8
  %5 = call ptr @avra_cell_unique(ptr %slot)
  %ld4 = load ptr, ptr %slot2, align 8
  %6 = call i64 @avra_array_get(ptr %ld4, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  %ld5 = load ptr, ptr %slot2, align 8
  %ld6 = load ptr, ptr %slot2, align 8
  %7 = call i64 @avra_array_get(ptr %ld6, i64 0)
  %boxed7 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %boxed7)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Epayloads_for"(ptr %1, ptr %boxed7)
  %9 = call ptr @avra_array_get_owned(ptr %ld5, i64 0)
  %10 = call i64 @avra_array_get(ptr %ld5, i64 1)
  %boxed8 = inttoptr i64 %10 to ptr
  %11 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %boxed8)
  call void @avra_array_push_owned(ptr %11, ptr %8)
  call void @avra_map_set_owned(ptr %5, ptr %boxed, ptr %11)
  %ld9 = load i64, ptr %slot1, align 8
  %add = add i64 %ld9, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %4)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Epayloads_for"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %2 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Emod$24l67" to i64))
  call void @avra_array_push_owned(ptr %2, ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 %ld2)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  %cast = inttoptr i64 %3 to ptr
  %6 = call i1 %cast(ptr %2, ptr %5)
  br i1 %6, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot)
  store ptr %5, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead

then6:                                            ; preds = %lexit
  %7 = call ptr @avra_array_get_owned(ptr %ld4, i64 2)
  br label %endif8

else7:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr null)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %7, %then6 ], [ null, %else7 ]
  %cmp10 = icmp ne ptr %regval9, null
  br i1 %cmp10, label %then11, label %else12

then11:                                           ; preds = %endif8
  call void @avra_rc_retain(ptr %regval9)
  br label %endif13

else12:                                           ; preds = %endif8
  %8 = call ptr @avra_array_sized(i64 0)
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi ptr [ %regval9, %then11 ], [ %8, %else12 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval14
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Emod$24l67"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Egrammar$2Enode_builder_name"(ptr %2, ptr %boxed)
  %5 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_streq(ptr %4, ptr %boxed1)
  %b = icmp ne i64 %6, 0
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enode_builders"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuilder_index"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eunassembled"(ptr %0, ptr %1) {
entry:
  %2 = call ptr @avra_map_new()
  %3 = call ptr @avra_array_sized(i64 0)
  %4 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Erows_of"(ptr %0, ptr %4)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Enew_dispatch"()
  call void @avra_rc_retain(ptr %1)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eas_defects"(ptr %1)
  %8 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %8, ptr %0)
  call void @avra_array_push_owned(ptr %8, ptr %2)
  call void @avra_array_push(ptr %8, i64 0)
  call void @avra_array_push_owned(ptr %8, ptr %3)
  call void @avra_array_push_owned(ptr %8, ptr %5)
  call void @avra_array_push_owned(ptr %8, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %8
}

declare ptr @"av_$40std$2Eavrac$2Elanguage$2Eas_defects"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ecode_defects"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebuilder_defects"(ptr, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ecode_registry"(ptr %0) {
entry:
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %1, ptr getelementptr inbounds (i8, ptr @"av_const$5$10", i64 16))
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %0)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %4 = call ptr @avra_array_concat(ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24180"(ptr %4)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_array_push_owned(ptr %2, ptr %boxed2)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24180"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebind_nodes"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Enode_payload_rows"()

declare ptr @"av_$40std$2Eavrac$2Egrammar$2EGrammar$2Emerged"(ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ecompose_grammar"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Elanguage_features"() {
entry:
  %0 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_spine$2Estmt_spine"()
  %1 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Eclosures"()
  %2 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_expr$2Etype_expr"()
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2Eblock"()
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Eannotations"()
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Emodules"()
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Especs$2Especs"()
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Elet_stmt"()
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Econsts"()
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eimpls"()
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Emutation"()
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Eloops"()
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2Ebool_lit"()
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Equote_lit"()
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Esublang"()
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Eif_expr"()
  %16 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2Ewhen_expr"()
  %17 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs"()
  %18 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecomponents$2Ecomponents"()
  %19 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Enullable"()
  %20 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformats"()
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums"()
  %22 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eresults"()
  %23 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edefers"()
  %24 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Efns"()
  %25 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Etables"()
  %26 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Egrammar_lit$2Egrammar_lit"()
  %27 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eexpr_spine"()
  %28 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elists"()
  %29 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Emaps"()
  %30 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Ebytes"()
  %31 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecells"()
  %32 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Estr_lit"()
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2Eexpr_stmt"()
  %34 = call ptr @avra_array_sized(i64 34)
  call void @avra_array_push_owned(ptr %34, ptr %0)
  call void @avra_array_push_owned(ptr %34, ptr %1)
  call void @avra_array_push_owned(ptr %34, ptr %2)
  call void @avra_array_push_owned(ptr %34, ptr %3)
  call void @avra_array_push_owned(ptr %34, ptr %4)
  call void @avra_array_push_owned(ptr %34, ptr %5)
  call void @avra_array_push_owned(ptr %34, ptr %6)
  call void @avra_array_push_owned(ptr %34, ptr %7)
  call void @avra_array_push_owned(ptr %34, ptr %8)
  call void @avra_array_push_owned(ptr %34, ptr %9)
  call void @avra_array_push_owned(ptr %34, ptr %10)
  call void @avra_array_push_owned(ptr %34, ptr %11)
  call void @avra_array_push_owned(ptr %34, ptr %12)
  call void @avra_array_push_owned(ptr %34, ptr %13)
  call void @avra_array_push_owned(ptr %34, ptr %14)
  call void @avra_array_push_owned(ptr %34, ptr %15)
  call void @avra_array_push_owned(ptr %34, ptr %16)
  call void @avra_array_push_owned(ptr %34, ptr %17)
  call void @avra_array_push_owned(ptr %34, ptr %18)
  call void @avra_array_push_owned(ptr %34, ptr %19)
  call void @avra_array_push_owned(ptr %34, ptr %20)
  call void @avra_array_push_owned(ptr %34, ptr %21)
  call void @avra_array_push_owned(ptr %34, ptr %22)
  call void @avra_array_push_owned(ptr %34, ptr %23)
  call void @avra_array_push_owned(ptr %34, ptr %24)
  call void @avra_array_push_owned(ptr %34, ptr %25)
  call void @avra_array_push_owned(ptr %34, ptr %26)
  call void @avra_array_push_owned(ptr %34, ptr %27)
  call void @avra_array_push_owned(ptr %34, ptr %28)
  call void @avra_array_push_owned(ptr %34, ptr %29)
  call void @avra_array_push_owned(ptr %34, ptr %30)
  call void @avra_array_push_owned(ptr %34, ptr %31)
  call void @avra_array_push_owned(ptr %34, ptr %32)
  call void @avra_array_push_owned(ptr %34, ptr %33)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
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
  ret ptr %34
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_stmt$2Eexpr_stmt"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estr_lit$2Estr_lit"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ecells$2Ecells"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebytes$2Ebytes"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emaps$2Emaps"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elists$2Elists"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eexpr_spine$2Eexpr_spine"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Egrammar_lit$2Egrammar_lit"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Etables$2Etables"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Efns$2Efns"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Edefers$2Edefers"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eresults$2Eresults"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eenums$2Eenums"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eformats$2Eformats"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enullable$2Enullable"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ecomponents$2Ecomponents"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estructs$2Estructs"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ewhen_expr$2Ewhen_expr"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eif_expr$2Eif_expr"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esublang$2Esublang"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Equote$2Equote_lit"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ebool_lit$2Ebool_lit"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eloops$2Eloops"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emutation$2Emutation"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eimpls$2Eimpls"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Econsts$2Econsts"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Elet_stmt$2Elet_stmt"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Especs$2Especs"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Emodules"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eannotations$2Eannotations"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eblock$2Eblock"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Etype_expr$2Etype_expr"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eclosures$2Eclosures"()

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_spine$2Estmt_spine"()
