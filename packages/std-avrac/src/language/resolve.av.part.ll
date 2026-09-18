; ModuleID = 'avra'
source_filename = "avra"

@.str = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"systems\00" }, align 16
@.str.1 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"bare\00" }, align 16
@.str.2 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"hardware\00" }, align 16
@.str.3 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"owned\00" }, align 16
@.str.4 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"borrow\00" }, align 16
@.str.5 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"move\00" }, align 16
@.str.6 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"level\00" }, align 16
@.str.7 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"unsafe\00" }, align 16
@.str.8 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"extern\00" }, align 16
@.str.9 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"async\00" }, align 16
@.str.10 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"spawn\00" }, align 16
@.str.11 = private unnamed_addr constant { { i32, i32, i32, i32 }, [6 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 5 }, [6 x i8] c"await\00" }, align 16
@.str.12 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"channel\00" }, align 16
@.str.13 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"select\00" }, align 16
@"av_const$20$6" = private global { { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [14 x i64], [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -5, i32 0, i32 40 }, { i64, i64, ptr, ptr, ptr } { i64 14, i64 14, ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [14 x i64], [14 x i8] }, ptr @"av_const$20$6", i32 0, i32 2), ptr getelementptr inbounds ({ { i32, i32, i32, i32 }, { i64, i64, ptr, ptr, ptr }, [14 x i64], [14 x i8] }, ptr @"av_const$20$6", i32 0, i32 3), ptr null }, [14 x i64] [i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.1, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.2, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.3, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.4, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.5, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.6, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.7, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.8, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.9, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.10, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.11, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.12, i64 16) to i64), i64 ptrtoint (ptr getelementptr inbounds (i8, ptr @.str.13, i64 16) to i64)], [14 x i8] c"\01\01\01\01\01\01\01\01\01\01\01\01\01\01" }, align 16
@.str.14 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"walked\00" }, align 16
@.str.15 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"scoped\00" }, align 16
@.str.16 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"resolve.builtin_type\00" }, align 16
@.str.17 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.18 = private unnamed_addr constant { { i32, i32, i32, i32 }, [21 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 20 }, [21 x i8] c"` is a built-in type\00" }, align 16
@.str.19 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.20 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"declared here\00" }, align 16
@.str.21 = private unnamed_addr constant { { i32, i32, i32, i32 }, [70 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 69 }, [70 x i8] c"choose another name \E2\80\94 `int`, `string` and `bool` are the language's\00" }, align 16
@.str.22 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.block_word\00" }, align 16
@.str.23 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.24 = private unnamed_addr constant { { i32, i32, i32, i32 }, [80 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 79 }, [80 x i8] c"` is a sublanguage's block word here, and nothing else in this file may wear it\00" }, align 16
@.str.25 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.26 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"this name\00" }, align 16
@.str.27 = private unnamed_addr constant { { i32, i32, i32, i32 }, [56 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 55 }, [56 x i8] c"rename it, or import the sublanguage under another name\00" }, align 16
@.str.28 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"Self\00" }, align 16
@.str.29 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"resolve.reserved\00" }, align 16
@.str.30 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.31 = private unnamed_addr constant { { i32, i32, i32, i32 }, [40 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 39 }, [40 x i8] c"` is reserved for a future Avra feature\00" }, align 16
@.str.32 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.33 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"cannot be a name\00" }, align 16
@.str.34 = private unnamed_addr constant { { i32, i32, i32, i32 }, [24 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 23 }, [24 x i8] c"pick another name \E2\80\94 `\00" }, align 16
@.str.35 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"` becomes a keyword\00" }, align 16
@.str.36 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.37 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"resolve.reserved\00" }, align 16
@.str.38 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"`Self` is a trait's name for its implementor\00" }, align 16
@.str.39 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"cannot be a name\00" }, align 16
@.str.40 = private unnamed_addr constant { { i32, i32, i32, i32 }, [45 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 44 }, [45 x i8] c"a declaration of your own takes another name\00" }, align 16
@.str.41 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"resolve.reserved\00" }, align 16
@.str.42 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.43 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"` is a keyword\00" }, align 16
@.str.44 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.45 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"cannot be a name\00" }, align 16
@.str.46 = private unnamed_addr constant { { i32, i32, i32, i32 }, [18 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 17 }, [18 x i8] c"pick another name\00" }, align 16
@.str.47 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.48 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"@\00" }, align 16
@.str.49 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.50 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.51 = private unnamed_addr constant { { i32, i32, i32, i32 }, [5 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 4 }, [5 x i8] c"self\00" }, align 16
@.str.52 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"resolve.receiver\00" }, align 16
@.str.53 = private unnamed_addr constant { { i32, i32, i32, i32 }, [60 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 59 }, [60 x i8] c"`self` names a method's receiver \E2\80\94 a `static fn` has none\00" }, align 16
@.str.54 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"no receiver here\00" }, align 16
@.str.55 = private unnamed_addr constant { { i32, i32, i32, i32 }, [54 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 53 }, [54 x i8] c"drop `static`, or take what this needs as a parameter\00" }, align 16
@.str.56 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"resolve.receiver\00" }, align 16
@.str.57 = private unnamed_addr constant { { i32, i32, i32, i32 }, [58 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 57 }, [58 x i8] c"`self` names a method's receiver \E2\80\94 this is not a method\00" }, align 16
@.str.58 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"no receiver here\00" }, align 16
@.str.59 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"move this into `impl <Type> { \E2\80\A6 }`\00" }, align 16
@.str.60 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.61 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"resolve.paired\00" }, align 16
@.str.62 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.63 = private unnamed_addr constant { { i32, i32, i32, i32 }, [39 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 38 }, [39 x i8] c"` names both the index and the element\00" }, align 16
@.str.64 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.65 = private unnamed_addr constant { { i32, i32, i32, i32 }, [11 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 10 }, [11 x i8] c"bound here\00" }, align 16
@.str.66 = private unnamed_addr constant { { i32, i32, i32, i32 }, [41 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 40 }, [41 x i8] c"give the index its own name \E2\80\94 `for i, \00" }, align 16
@.str.67 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c" in \E2\80\A6`\00" }, align 16
@.str.68 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.69 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.unresolved\00" }, align 16
@.str.70 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"no `type \00" }, align 16
@.str.71 = private unnamed_addr constant { { i32, i32, i32, i32 }, [20 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 19 }, [20 x i8] c"` is declared \E2\80\94 `\00" }, align 16
@.str.72 = private unnamed_addr constant { { i32, i32, i32, i32 }, [61 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 60 }, [61 x i8] c"` is a fn, and a name before `{ }` reads as a record literal\00" }, align 16
@.str.73 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.74 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"used here\00" }, align 16
@.str.75 = private unnamed_addr constant { { i32, i32, i32, i32 }, [55 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 54 }, [55 x i8] c"a call taking an empty block writes its parentheses: `\00" }, align 16
@.str.76 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"() { }`\00" }, align 16
@.str.77 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.78 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.unresolved\00" }, align 16
@.str.79 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"no `type \00" }, align 16
@.str.80 = private unnamed_addr constant { { i32, i32, i32, i32 }, [14 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 13 }, [14 x i8] c"` is declared\00" }, align 16
@.str.81 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.82 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"used here\00" }, align 16
@.str.83 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"replace `\00" }, align 16
@.str.84 = private unnamed_addr constant { { i32, i32, i32, i32 }, [9 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 8 }, [9 x i8] c"` with `\00" }, align 16
@.str.85 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.86 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.87 = private unnamed_addr constant { { i32, i32, i32, i32 }, [15 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 14 }, [15 x i8] c"did you mean `\00" }, align 16
@.str.88 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"`?\00" }, align 16
@.str.89 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.90 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.unresolved\00" }, align 16
@.str.91 = private unnamed_addr constant { { i32, i32, i32, i32 }, [8 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 7 }, [8 x i8] c"no `fn \00" }, align 16
@.str.92 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"` is defined\00" }, align 16
@.str.93 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.94 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"called here\00" }, align 16
@.str.95 = private unnamed_addr constant { { i32, i32, i32, i32 }, [24 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 23 }, [24 x i8] c"resolve.runtime_binding\00" }, align 16
@.str.96 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.97 = private unnamed_addr constant { { i32, i32, i32, i32 }, [99 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 98 }, [99 x i8] c"` is a run-time binding of the top level \E2\80\94 a fn body sees declarations, not the values around it\00" }, align 16
@.str.98 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.99 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"read here\00" }, align 16
@.str.100 = private unnamed_addr constant { { i32, i32, i32, i32 }, [7 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 6 }, [7 x i8] c"pass `\00" }, align 16
@.str.101 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"` in as a parameter, or make it a fn\00" }, align 16
@.str.102 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.103 = private unnamed_addr constant { { i32, i32, i32, i32 }, [3 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 2 }, [3 x i8] c"it\00" }, align 16
@.str.104 = private unnamed_addr constant { { i32, i32, i32, i32 }, [13 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 12 }, [13 x i8] c"defined here\00" }, align 16
@.str.105 = private unnamed_addr constant { { i32, i32, i32, i32 }, [23 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 22 }, [23 x i8] c"resolve.use_before_def\00" }, align 16
@.str.106 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.107 = private unnamed_addr constant { { i32, i32, i32, i32 }, [32 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 31 }, [32 x i8] c"` is used before its definition\00" }, align 16
@.str.108 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.109 = private unnamed_addr constant { { i32, i32, i32, i32 }, [10 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 9 }, [10 x i8] c"used here\00" }, align 16
@.str.110 = private unnamed_addr constant { { i32, i32, i32, i32 }, [35 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 34 }, [35 x i8] c"move the definition above this use\00" }, align 16
@.str.111 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.unresolved\00" }, align 16
@.str.112 = private unnamed_addr constant { { i32, i32, i32, i32 }, [2 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 1 }, [2 x i8] c"`\00" }, align 16
@.str.113 = private unnamed_addr constant { { i32, i32, i32, i32 }, [17 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 16 }, [17 x i8] c"` is not defined\00" }, align 16
@.str.114 = private unnamed_addr constant { { i32, i32, i32, i32 }, [1 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 0 }, [1 x i8] zeroinitializer }, align 16
@.str.115 = private unnamed_addr constant { { i32, i32, i32, i32 }, [37 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 36 }, [37 x i8] c"not defined anywhere in this program\00" }, align 16
@.str.116 = private unnamed_addr constant { { i32, i32, i32, i32 }, [19 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 18 }, [19 x i8] c"resolve.unresolved\00" }, align 16
@.str.117 = private unnamed_addr constant { { i32, i32, i32, i32 }, [63 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 62 }, [63 x i8] c"`it` rides a METHOD call's arguments \E2\80\94 nothing binds it here\00" }, align 16
@.str.118 = private unnamed_addr constant { { i32, i32, i32, i32 }, [12 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 11 }, [12 x i8] c"the pronoun\00" }, align 16
@.str.119 = private unnamed_addr constant { { i32, i32, i32, i32 }, [80 x i8] } { { i32, i32, i32, i32 } { i32 1096176193, i32 -1, i32 0, i32 79 }, [80 x i8] c"inside `xs.map(\E2\80\A6)` and friends `it` is the element; elsewhere, name the value\00" }, align 16

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

declare i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr, ptr, ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Epointed"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eerror_at"(ptr, ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr)

declare i64 @"av_$40std$2Eavrac$2Ediagnostics$2EVoices$2Espeak"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Estmt_loc"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of_stmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Efn_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_of"(ptr, i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr, ptr)

declare { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2Efound_at"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Ewritten_seats"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Elanguage$2Ebuiltin_type_name"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etype_decl_name"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eside_table$2415"(ptr, i64, i64, i1)

declare i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24921"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr, ptr)

declare i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24275"(ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr, ptr)

declare i1 @"av_$40std$2Eavrac$2Ecore$2Esame_file"(i64, i64)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Efn_decl"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotations_of"(ptr, i64)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eresolve"(ptr %0, ptr %1, ptr %2, ptr %3, ptr %4, ptr %5) {
entry:
  %slot11 = alloca ptr, align 8
  store ptr null, ptr %slot11, align 8
  %slot = alloca i64, align 8
  %6 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %7 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %boxed)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Edefs_of"(ptr %6, ptr %boxed)
  %9 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed1 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  %boxed2 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  %11 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24275"(ptr %boxed2)
  call void @avra_rc_retain(ptr %3)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Enew_name_facts"(i64 %11, ptr %3)
  %13 = call ptr @avra_array_sized(i64 0)
  %14 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %14
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %15 = call ptr @avra_map_new()
  %16 = call ptr @avra_array_sized(i64 0)
  %17 = call ptr @avra_array_sized(i64 0)
  %18 = call ptr @avra_array_sized(i64 0)
  %19 = call ptr @avra_array_sized(i64 0)
  %20 = call ptr @avra_array_sized(i64 0)
  %21 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed7 = inttoptr i64 %21 to ptr
  %22 = call i64 @avra_array_get(ptr %boxed7, i64 0)
  %boxed8 = inttoptr i64 %22 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  %23 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24275"(ptr %boxed8)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  %24 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eside_table$2415"(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16), i64 0, i64 %23, i1 false)
  %25 = call i64 @avra_array_get(ptr %2, i64 1)
  %boxed9 = inttoptr i64 %25 to ptr
  %26 = call i64 @avra_array_get(ptr %boxed9, i64 2)
  %boxed10 = inttoptr i64 %26 to ptr
  call void @avra_rc_retain(ptr %boxed10)
  %27 = call i64 @"av_$40std$2Eavrac$2Ecore$2EArena$2Ecount$24921"(ptr %boxed10)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  %28 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eside_table$2415"(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16), i64 0, i64 %27, i1 false)
  %29 = call ptr @avra_array_sized(i64 0)
  %30 = call ptr @avra_array_sized(i64 17)
  call void @avra_array_push_owned(ptr %30, ptr %2)
  call void @avra_array_push_owned(ptr %30, ptr %12)
  call void @avra_array_push_owned(ptr %30, ptr %0)
  call void @avra_array_push_owned(ptr %30, ptr %1)
  call void @avra_array_push_owned(ptr %30, ptr %8)
  call void @avra_array_push_owned(ptr %30, ptr %13)
  call void @avra_array_push_owned(ptr %30, ptr %15)
  call void @avra_array_push_owned(ptr %30, ptr %16)
  call void @avra_array_push_owned(ptr %30, ptr %17)
  call void @avra_array_push_owned(ptr %30, ptr %18)
  call void @avra_array_push_owned(ptr %30, ptr %19)
  call void @avra_array_push_owned(ptr %30, ptr %20)
  call void @avra_array_push_owned(ptr %30, ptr %24)
  call void @avra_array_push_owned(ptr %30, ptr %28)
  call void @avra_array_push_owned(ptr %30, ptr %29)
  call void @avra_array_push(ptr %30, i64 0)
  call void @avra_array_push_owned(ptr %30, ptr %4)
  call void @avra_rc_retain(ptr %30)
  call void @avra_cell_release(ptr %slot11)
  store ptr %30, ptr %slot11, align 8
  %ld12 = load ptr, ptr %slot11, align 8
  call void @avra_rc_retain(ptr %ld12)
  %31 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ename_laws"(ptr %ld12)
  %ld13 = load ptr, ptr %slot11, align 8
  %32 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed14 = inttoptr i64 %32 to ptr
  call void @avra_rc_retain(ptr %ld13)
  call void @avra_rc_retain(ptr %boxed14)
  %33 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %ld13, i1 false, ptr %boxed14)
  %ld15 = load ptr, ptr %slot11, align 8
  call void @avra_rc_retain(ptr %ld15)
  call void @avra_rc_retain(ptr %5)
  %34 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %ld15, i1 false, ptr %5)
  %ld16 = load ptr, ptr %slot11, align 8
  %35 = call i64 @avra_array_get(ptr %ld16, i64 1)
  %boxed17 = inttoptr i64 %35 to ptr
  %36 = call i64 @avra_array_get(ptr %3, i64 7)
  %boxed18 = inttoptr i64 %36 to ptr
  %37 = call i64 @avra_array_get(ptr %boxed18, i64 0)
  %boxed19 = inttoptr i64 %37 to ptr
  %38 = call ptr @avra_array_get_owned(ptr %2, i64 1)
  %39 = call ptr @avra_array_get_owned(ptr %2, i64 3)
  %40 = call i64 @avra_array_get(ptr %39, i64 0)
  %boxed20 = inttoptr i64 %40 to ptr
  %41 = call i64 @avra_array_get(ptr %2, i64 2)
  %boxed21 = inttoptr i64 %41 to ptr
  call void @avra_rc_retain(ptr %38)
  call void @avra_rc_retain(ptr %boxed20)
  call void @avra_rc_retain(ptr %boxed21)
  %42 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Emodule_laws"(ptr %38, ptr %boxed20, ptr %boxed21)
  %ld22 = load ptr, ptr %slot11, align 8
  %43 = call i64 @avra_array_get(ptr %ld22, i64 1)
  %boxed23 = inttoptr i64 %43 to ptr
  %44 = call i64 @avra_array_get(ptr %boxed23, i64 5)
  %boxed24 = inttoptr i64 %44 to ptr
  %45 = call i64 @avra_array_get(ptr %boxed24, i64 0)
  %boxed25 = inttoptr i64 %45 to ptr
  %46 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %46, ptr %boxed19)
  call void @avra_array_push_owned(ptr %46, ptr %42)
  call void @avra_array_push_owned(ptr %46, ptr %boxed25)
  call void @avra_rc_retain(ptr %46)
  %47 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eflatten$24141"(ptr %46)
  %48 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %48, ptr %47)
  %49 = call ptr @avra_array_get_owned(ptr %boxed17, i64 0)
  %50 = call ptr @avra_array_get_owned(ptr %boxed17, i64 1)
  %51 = call ptr @avra_array_get_owned(ptr %boxed17, i64 2)
  %52 = call ptr @avra_array_get_owned(ptr %boxed17, i64 3)
  %53 = call i64 @avra_array_get(ptr %boxed17, i64 4)
  %boxed26 = inttoptr i64 %53 to ptr
  %54 = call ptr @avra_array_sized(i64 6)
  call void @avra_array_push_owned(ptr %54, ptr %49)
  call void @avra_array_push_owned(ptr %54, ptr %50)
  call void @avra_array_push_owned(ptr %54, ptr %51)
  call void @avra_array_push_owned(ptr %54, ptr %52)
  call void @avra_array_push_owned(ptr %54, ptr %boxed26)
  call void @avra_array_push_owned(ptr %54, ptr %48)
  call void @avra_cell_release(ptr %slot11)
  call void @avra_rc_release(ptr %52)
  call void @avra_rc_release(ptr %51)
  call void @avra_rc_release(ptr %50)
  call void @avra_rc_release(ptr %49)
  call void @avra_rc_release(ptr %48)
  call void @avra_rc_release(ptr %47)
  call void @avra_rc_release(ptr %46)
  call void @avra_rc_release(ptr %42)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.15, i64 16))
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.14, i64 16))
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %54

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %55 = call i64 @avra_array_get(ptr %8, i64 %ld3)
  %boxed4 = inttoptr i64 %55 to ptr
  %56 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %boxed5 = inttoptr i64 %56 to ptr
  call void @avra_array_push_owned(ptr %13, ptr %boxed5)
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Emodules$2Emodule_laws"(ptr, ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %0, i1 %1, ptr %2) {
entry:
  %slot11 = alloca ptr, align 8
  store ptr null, ptr %slot11, align 8
  %slot10 = alloca i64, align 8
  %slot2 = alloca i64, align 8
  %slot1 = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 15)
  %b = icmp ne i64 %3, 0
  %slot = zext i1 %1 to i64
  call void @avra_slot_set(ptr %0, i64 15, i64 %slot)
  %4 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lexit13, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %slot22 = zext i1 %b to i64
  call void @avra_slot_set(ptr %0, i64 15, i64 %slot22)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %2, i64 %ld3)
  store i64 %5, ptr %slot2, align 8
  %6 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %7 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed4 = inttoptr i64 %8 to ptr
  %ld5 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %boxed4)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Estmt"(ptr %boxed4, i64 %ld5)
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %9)
  %10 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Estmt_semantics_of"(ptr %6, ptr %9)
  %ld6 = load i64, ptr %slot2, align 8
  %11 = call ptr @avra_array_get_owned(ptr %10, i64 0)
  %12 = call i64 @avra_array_get(ptr %10, i64 1)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %12 to ptr
  %13 = call i64 %cast(ptr %11, ptr %0, i64 %ld6)
  %14 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed7 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_get(ptr %boxed7, i64 1)
  %boxed8 = inttoptr i64 %15 to ptr
  %ld9 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %boxed8)
  %16 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eannotations_of"(ptr %boxed8, i64 %ld9)
  %17 = call i64 @avra_array_len(ptr %16)
  store i64 0, ptr %slot10, align 8
  br label %lhead12

lhead12:                                          ; preds = %lbody16, %lbody
  %ld14 = load i64, ptr %slot10, align 8
  %cmp15 = icmp slt i64 %ld14, %17
  br i1 %cmp15, label %lbody16, label %lexit13

lexit13:                                          ; preds = %lhead12
  %ld20 = load i64, ptr %slot1, align 8
  %add21 = add i64 %ld20, 1
  store i64 %add21, ptr %slot1, align 8
  call void @avra_cell_release(ptr %slot11)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  br label %lhead

lbody16:                                          ; preds = %lhead12
  %ld17 = load i64, ptr %slot10, align 8
  %18 = call ptr @avra_array_get_owned(ptr %16, i64 %ld17)
  call void @avra_rc_retain(ptr %18)
  call void @avra_cell_release(ptr %slot11)
  store ptr %18, ptr %slot11, align 8
  %ld18 = load ptr, ptr %slot11, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %ld18)
  %19 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_annotation"(ptr %0, ptr %ld18)
  %ld19 = load i64, ptr %slot10, align 8
  %add = add i64 %ld19, 1
  store i64 %add, ptr %slot10, align 8
  call void @avra_rc_release(ptr %18)
  br label %lhead12
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_annotation"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %2)
  %4 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %5 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %6 = call i64 @avra_array_get(ptr %4, i64 %ld2)
  store i64 %6, ptr %slot1, align 8
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %ld3)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %1) {
entry:
  %slot2 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Epost_order"(ptr %2, ptr %boxed1, i64 %1)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %5, i64 %ld3)
  store i64 %7, ptr %slot2, align 8
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 2)
  %9 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed4 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed4, i64 1)
  %boxed5 = inttoptr i64 %10 to ptr
  %ld6 = load i64, ptr %slot2, align 8
  call void @avra_rc_retain(ptr %boxed5)
  %11 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eexpr"(ptr %boxed5, i64 %ld6)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Esemantics_of"(ptr %8, ptr %11)
  %ld7 = load i64, ptr %slot2, align 8
  %13 = call ptr @avra_array_get_owned(ptr %12, i64 0)
  %14 = call i64 @avra_array_get(ptr %12, i64 3)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %0)
  %cast = inttoptr i64 %14 to ptr
  %15 = call i64 %cast(ptr %13, ptr %0, i64 %ld7)
  %ld8 = load i64, ptr %slot, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Epost_order"(ptr, ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ename_laws"(ptr %0) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %2 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %3 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif18, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %2, i64 %ld2)
  store i64 %4, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed3 = inttoptr i64 %6 to ptr
  %ld4 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed3)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Efn_parts"(ptr %boxed3, i64 %ld4)
  %cmp5 = icmp ne ptr %7, null
  br i1 %cmp5, label %then, label %else

then:                                             ; preds = %lbody
  %8 = call ptr @avra_array_get_owned(ptr %7, i64 0)
  br label %endif

else:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr null)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %8, %then ], [ null, %else ]
  %cmp6 = icmp ne ptr %regval, null
  br i1 %cmp6, label %then7, label %else8

then7:                                            ; preds = %endif
  %9 = call ptr @avra_insist(ptr %regval)
  %ld10 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %ld10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  call void @avra_rc_retain(ptr %10)
  %11 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %9, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endif9

else8:                                            ; preds = %endif
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval11 = phi i64 [ 0, %then7 ], [ 0, %else8 ]
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed12 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed12, i64 1)
  %boxed13 = inttoptr i64 %13 to ptr
  %ld14 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %boxed13)
  %14 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Etype_decl_name"(ptr %boxed13, i64 %ld14)
  %cmp15 = icmp ne ptr %14, null
  br i1 %cmp15, label %then16, label %else17

then16:                                           ; preds = %endif9
  %15 = call ptr @avra_insist(ptr %14)
  %ld19 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Etype_name_law"(ptr %0, ptr %15, i64 %ld19)
  call void @avra_rc_release(ptr %15)
  br label %endif18

else17:                                           ; preds = %endif9
  br label %endif18

endif18:                                          ; preds = %else17, %then16
  %regval20 = phi i64 [ 0, %then16 ], [ 0, %else17 ]
  %ld21 = load i64, ptr %slot, align 8
  %add = add i64 %ld21, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr %7)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Etype_name_law"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %3)
  %4 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %1, ptr %3)
  br i1 %4, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %boxed, i64 6)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2Ebuiltin_type_name"(ptr %boxed2, ptr %1)
  br i1 %8, label %then3, label %else4

postret:                                          ; No predecessors!
  br label %endif

then3:                                            ; preds = %endif
  %9 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_array_push_owned(ptr %9, ptr %1)
  call void @avra_array_push_owned(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  %10 = call ptr @avra_str_join(ptr %9, ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  %11 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16), ptr %3, ptr %10, ptr getelementptr inbounds (i8, ptr @.str.20, i64 16), ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.21, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.20, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.19, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.18, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.17, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.16, i64 16))
  br label %endif5

else4:                                            ; preds = %endif
  br label %endif5

endif5:                                           ; preds = %else4, %then3
  %regval6 = phi i64 [ 0, %then3 ], [ 0, %else4 ]
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 5)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Ediagnostics$2EVoices$2Espeak"(ptr %boxed1, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_name"(ptr %0, ptr %1, ptr %2)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 4)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Esyntax_decl"(ptr %boxed1, ptr %1)
  %cmp = icmp ne ptr %6, null
  br i1 %cmp, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %7 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_array_push_owned(ptr %7, ptr %1)
  call void @avra_array_push_owned(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  %8 = call ptr @avra_str_join(ptr %7, ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  %9 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16), ptr %2, ptr %8, ptr getelementptr inbounds (i8, ptr @.str.26, i64 16), ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.27, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.26, i64 16))
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.25, i64 16))
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.24, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.23, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.22, i64 16))
  br label %endif4
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Esyntax_decl"(ptr, ptr)

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_name"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot16 = alloca i64, align 8
  %slot15 = alloca i1, align 1
  %slot1 = alloca i64, align 8
  %slot = alloca i1, align 1
  store i1 false, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %4 = call i64 @avra_array_len(ptr %3)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load i1, ptr %slot, align 8
  br i1 %ld4, label %then5, label %else6

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %5 = call i64 @avra_array_get(ptr %3, i64 %ld2)
  %boxed = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_streq(ptr %boxed, ptr %1)
  %b = icmp ne i64 %6, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %4, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  br label %lhead

then5:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_keyword"(ptr %0, ptr %1, ptr %2, ptr null)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else6:                                            ; preds = %lexit
  br label %endif7

endif7:                                           ; preds = %else6, %postret
  %regval8 = phi i64 [ 0, %postret ], [ 0, %else6 ]
  %8 = call i64 @avra_streq(ptr %1, ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  %b9 = icmp ne i64 %8, 0
  br i1 %b9, label %then10, label %else11

postret:                                          ; No predecessors!
  br label %endif7

then10:                                           ; preds = %endif7
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_self"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else11:                                           ; preds = %endif7
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  store i1 false, ptr %slot15, align 8
  %10 = call i64 @avra_array_len(ptr getelementptr inbounds (i8, ptr @"av_const$20$6", i64 16))
  store i64 0, ptr %slot16, align 8
  br label %lhead17

postret13:                                        ; No predecessors!
  br label %endif12

lhead17:                                          ; preds = %endif27, %endif12
  %ld19 = load i64, ptr %slot16, align 8
  %cmp20 = icmp slt i64 %ld19, %10
  br i1 %cmp20, label %lbody21, label %lexit18

lexit18:                                          ; preds = %lhead17
  %ld31 = load i1, ptr %slot15, align 8
  br i1 %ld31, label %then32, label %else33

lbody21:                                          ; preds = %lhead17
  %ld22 = load i64, ptr %slot16, align 8
  %11 = call i64 @avra_array_get(ptr getelementptr inbounds (i8, ptr @"av_const$20$6", i64 16), i64 %ld22)
  %boxed23 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_streq(ptr %boxed23, ptr %1)
  %b24 = icmp ne i64 %12, 0
  br i1 %b24, label %then25, label %else26

then25:                                           ; preds = %lbody21
  store i1 true, ptr %slot15, align 8
  store i64 %10, ptr %slot16, align 8
  br label %endif27

else26:                                           ; preds = %lbody21
  br label %endif27

endif27:                                          ; preds = %else26, %then25
  %regval28 = phi i64 [ 0, %then25 ], [ 0, %else26 ]
  %ld29 = load i64, ptr %slot16, align 8
  %add30 = add i64 %ld29, 1
  store i64 %add30, ptr %slot16, align 8
  br label %lhead17

then32:                                           ; preds = %lexit18
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_reserved"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 true

else33:                                           ; preds = %lexit18
  br label %endif34

endif34:                                          ; preds = %else33, %postret35
  %regval36 = phi i64 [ 0, %postret35 ], [ 0, %else33 ]
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.28, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

postret35:                                        ; No predecessors!
  br label %endif34
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_reserved"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.30, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.31, i64 16))
  %4 = call ptr @avra_str_join(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.32, i64 16))
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %1)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.35, i64 16))
  %6 = call ptr @avra_str_join(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.36, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.29, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.33, i64 16))
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.29, i64 16), ptr %2, ptr %4, ptr getelementptr inbounds (i8, ptr @.str.33, i64 16), ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.36, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.35, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.34, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.33, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.32, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.31, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.30, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.29, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_self"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.37, i64 16))
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.40, i64 16))
  %2 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.37, i64 16), ptr %1, ptr getelementptr inbounds (i8, ptr @.str.38, i64 16), ptr getelementptr inbounds (i8, ptr @.str.39, i64 16), ptr getelementptr inbounds (i8, ptr @.str.40, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.40, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.39, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.38, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.37, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_keyword"(ptr %0, ptr %1, ptr %2, ptr %3) {
entry:
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.42, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %1)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.43, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.44, i64 16))
  %cmp = icmp ne ptr %3, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_retain(ptr %3)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi ptr [ %3, %then ], [ getelementptr inbounds (i8, ptr @.str.46, i64 16), %else ]
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.41, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.45, i64 16))
  call void @avra_rc_retain(ptr %regval)
  %6 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.41, i64 16), ptr %2, ptr %5, ptr getelementptr inbounds (i8, ptr @.str.45, i64 16), ptr %regval)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %6)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %regval)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.45, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.44, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.43, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.42, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.41, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %7
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Estmt_loc"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Enew_name_facts"(i64, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2Edefs_of"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %0, i64 %4)
  %cmp2 = icmp ne ptr %5, null
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %0, i64 %4)
  %7 = call ptr @avra_insist(ptr %6)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %8, ptr %7)
  call void @avra_array_push(ptr %8, i64 %4)
  call void @avra_array_push_owned(ptr %2, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

declare i1 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eget$2415"(ptr, i64)

declare i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$2415"(ptr, i64, i1)

declare ptr @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eget$241120"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk_under"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot7 = alloca i64, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 3)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Ewritten_seats"(ptr %boxed, ptr %1)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 14)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr %boxed1, i64 %2)
  %8 = call ptr @avra_slot_unique(ptr %0, i64 9)
  %9 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed2 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_len(ptr %boxed2)
  call void @avra_array_push(ptr %8, i64 %10)
  %11 = call ptr @avra_slot_unique(ptr %0, i64 11)
  %12 = call ptr @avra_array_sized(i64 0)
  %13 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %13
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_array_push_owned(ptr %11, ptr %12)
  %14 = call ptr @avra_array_sized(i64 0)
  %15 = call i64 @avra_array_len(ptr %4)
  store i64 0, ptr %slot7, align 8
  br label %lhead8

lbody:                                            ; preds = %lhead
  %ld3 = load i64, ptr %slot, align 8
  %16 = call i64 @avra_array_get(ptr %4, i64 %ld3)
  %boxed4 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_array_get(ptr %boxed4, i64 3)
  %boxed5 = inttoptr i64 %17 to ptr
  call void @avra_array_push_owned(ptr %12, ptr %boxed5)
  %ld6 = load i64, ptr %slot, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead

lhead8:                                           ; preds = %lbody12, %lexit
  %ld10 = load i64, ptr %slot7, align 8
  %cmp11 = icmp slt i64 %ld10, %15
  br i1 %cmp11, label %lbody12, label %lexit9

lexit9:                                           ; preds = %lhead8
  call void @avra_slot_set_owned(ptr %0, i64 14, ptr %14)
  call void @avra_rc_retain(ptr %0)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %2)
  call void @avra_slot_set_owned(ptr %0, i64 14, ptr %5)
  %19 = call ptr @avra_slot_unique(ptr %0, i64 11)
  %20 = call ptr @avra_array_pop_owned(ptr %19)
  %21 = call ptr @avra_slot_unique(ptr %0, i64 9)
  %22 = call i64 @avra_array_pop(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody12:                                          ; preds = %lhead8
  %ld13 = load i64, ptr %slot7, align 8
  %23 = call i64 @avra_array_get(ptr %4, i64 %ld13)
  %boxed14 = inttoptr i64 %23 to ptr
  %24 = call i64 @avra_array_get(ptr %boxed14, i64 0)
  %boxed15 = inttoptr i64 %24 to ptr
  call void @avra_rc_retain(ptr %boxed15)
  call void @avra_rc_retain(ptr %7)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %boxed15, ptr %7)
  call void @avra_array_push_owned(ptr %14, ptr %25)
  %ld16 = load i64, ptr %slot7, align 8
  %add17 = add i64 %ld16, 1
  store i64 %add17, ptr %slot7, align 8
  call void @avra_rc_release(ptr %25)
  br label %lhead8
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  ret ptr %0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %2 = call ptr @avra_insist(ptr %1)
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  %4 = call ptr @avra_int_text(i64 %3)
  %5 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.47, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %0)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.48, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %4)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.49, i64 16))
  %6 = call ptr @avra_str_join(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.50, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.50, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.49, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.48, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.47, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

postret:                                          ; No predecessors!
  br label %endif
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2410"(ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elambda_scope"(ptr %0, i64 %1, ptr %2, i64 %3) {
entry:
  %slot6 = alloca i64, align 8
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %5 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed5 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr %boxed5, i64 %1)
  %7 = call ptr @avra_slot_unique(ptr %0, i64 8)
  %8 = call ptr @avra_array_sized(i64 0)
  %9 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot6, align 8
  br label %lhead7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %10 = call ptr @avra_array_get_owned(ptr %2, i64 %ld2)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot1)
  store ptr %10, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  %11 = call i64 @avra_array_get(ptr %ld3, i64 0)
  %boxed = inttoptr i64 %11 to ptr
  call void @avra_rc_retain(ptr %0)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %12)
  %13 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %boxed, ptr %12)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %10)
  br label %lhead

lhead7:                                           ; preds = %lbody11, %lexit
  %ld9 = load i64, ptr %slot6, align 8
  %cmp10 = icmp slt i64 %ld9, %9
  br i1 %cmp10, label %lbody11, label %lexit8

lexit8:                                           ; preds = %lhead7
  %14 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed17 = inttoptr i64 %14 to ptr
  %15 = call i64 @avra_array_len(ptr %boxed17)
  %16 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %16, i64 %1)
  call void @avra_array_push_owned(ptr %16, ptr %8)
  call void @avra_array_push(ptr %16, i64 %15)
  call void @avra_array_push_owned(ptr %7, ptr %16)
  call void @avra_rc_retain(ptr %0)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %3)
  %18 = call ptr @avra_slot_unique(ptr %0, i64 8)
  %19 = call ptr @avra_array_pop_owned(ptr %18)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody11:                                          ; preds = %lhead7
  %ld12 = load i64, ptr %slot6, align 8
  %20 = call i64 @avra_array_get(ptr %2, i64 %ld12)
  %boxed13 = inttoptr i64 %20 to ptr
  %21 = call i64 @avra_array_get(ptr %boxed13, i64 0)
  %boxed14 = inttoptr i64 %21 to ptr
  call void @avra_rc_retain(ptr %boxed14)
  call void @avra_rc_retain(ptr %6)
  %22 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %boxed14, ptr %6)
  call void @avra_array_push_owned(ptr %8, ptr %22)
  %ld15 = load i64, ptr %slot6, align 8
  %add16 = add i64 %ld15, 1
  store i64 %add16, ptr %slot6, align 8
  call void @avra_rc_release(ptr %22)
  br label %lhead7
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eloc_of"(ptr %boxed, i64 %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Euse_receiver"(ptr %0, i64 %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Emet"(ptr %0, i64 %1)
  br i1 %2, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %3 = call i64 @avra_array_get(ptr %0, i64 10)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_retain(ptr %0)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eno_receiver"(ptr %0, ptr %5)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i64 %6

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %0)
  %7 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ein_a_method"(ptr %0)
  %not = xor i1 %7, true
  br i1 %not, label %then6, label %else7

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %5)
  br label %endif3

then6:                                            ; preds = %endif3
  call void @avra_rc_retain(ptr %0)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estatic_has_none"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %0)
  ret i64 %9

else7:                                            ; preds = %endif3
  br label %endif8

endif8:                                           ; preds = %else7, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else7 ]
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.51, i64 16))
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echained"(ptr %0, i64 0, ptr getelementptr inbounds (i8, ptr @.str.51, i64 16), ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.51, i64 16))
  call void @avra_rc_release(ptr %0)
  ret i64 %12

postret9:                                         ; No predecessors!
  call void @avra_rc_release(ptr %8)
  br label %endif8
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %2)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$24150"(ptr %boxed1, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$24150"(ptr, i64, ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echained"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  call void @avra_rc_retain(ptr %3)
  call void @avra_cell_release(ptr %slot)
  store ptr %3, ptr %slot, align 8
  store i64 %1, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot1, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp slt i64 %ld, %5
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld7 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld7)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld7

lbody:                                            ; preds = %lhead
  %6 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed2 = inttoptr i64 %6 to ptr
  %ld3 = load i64, ptr %slot1, align 8
  %7 = call i64 @avra_array_get(ptr %boxed2, i64 %ld3)
  %boxed4 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %ld5 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %ld5)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ecaptured"(ptr %0, i64 %8, ptr %2, ptr %ld5)
  %10 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %10, i64 5)
  call void @avra_array_push(ptr %10, i64 %8)
  call void @avra_array_push(ptr %10, i64 %9)
  call void @avra_rc_retain(ptr %10)
  call void @avra_cell_release(ptr %slot)
  store ptr %10, ptr %slot, align 8
  %ld6 = load i64, ptr %slot1, align 8
  %add = add i64 %ld6, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %10)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ecaptured"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot4 = alloca i64, align 8
  %slot = alloca i64, align 8
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %6 = call ptr @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eget$241120"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 1)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %9, ptr %2)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %10, ptr %3)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %11, ptr %9)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_retain(ptr %boxed3)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$241120"(ptr %boxed3, i64 %1, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %13 = call ptr @avra_insist(ptr %6)
  store i64 -1, ptr %slot, align 8
  %14 = call ptr @avra_array_get_owned(ptr %13, i64 0)
  %15 = call i64 @avra_array_len(ptr %14)
  store i64 0, ptr %slot4, align 8
  br label %lhead

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  br label %endif

lhead:                                            ; preds = %endif10, %endif
  %ld = load i64, ptr %slot4, align 8
  %cmp5 = icmp slt i64 %ld, %15
  br i1 %cmp5, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld13 = load i64, ptr %slot, align 8
  %cmp14 = icmp sge i64 %ld13, 0
  br i1 %cmp14, label %then15, label %else16

lbody:                                            ; preds = %lhead
  %ld6 = load i64, ptr %slot4, align 8
  %16 = call i64 @avra_array_get(ptr %14, i64 %ld6)
  %boxed7 = inttoptr i64 %16 to ptr
  %17 = call i64 @avra_streq(ptr %boxed7, ptr %2)
  %b = icmp ne i64 %17, 0
  br i1 %b, label %then8, label %else9

then8:                                            ; preds = %lbody
  store i64 %ld6, ptr %slot, align 8
  store i64 %15, ptr %slot4, align 8
  br label %endif10

else9:                                            ; preds = %lbody
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval11 = phi i64 [ 0, %then8 ], [ 0, %else9 ]
  %ld12 = load i64, ptr %slot4, align 8
  %add = add i64 %ld12, 1
  store i64 %add, ptr %slot4, align 8
  br label %lhead

then15:                                           ; preds = %lexit
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %ld13

else16:                                           ; preds = %lexit
  br label %endif17

endif17:                                          ; preds = %else16, %postret18
  %regval19 = phi i64 [ 0, %postret18 ], [ 0, %else16 ]
  %18 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed20 = inttoptr i64 %18 to ptr
  %19 = call i64 @avra_array_get(ptr %boxed20, i64 1)
  %boxed21 = inttoptr i64 %19 to ptr
  %20 = call i64 @avra_array_get(ptr %13, i64 0)
  %boxed22 = inttoptr i64 %20 to ptr
  %21 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %21, ptr %2)
  %22 = call ptr @avra_array_concat(ptr %boxed22, ptr %21)
  %23 = call i64 @avra_array_get(ptr %13, i64 1)
  %boxed23 = inttoptr i64 %23 to ptr
  %24 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %24, ptr %3)
  %25 = call ptr @avra_array_concat(ptr %boxed23, ptr %24)
  %26 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %26, ptr %22)
  call void @avra_array_push_owned(ptr %26, ptr %25)
  call void @avra_rc_retain(ptr %boxed21)
  call void @avra_rc_retain(ptr %26)
  %27 = call i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$241120"(ptr %boxed21, i64 %1, ptr %26)
  %28 = call i64 @avra_array_get(ptr %13, i64 0)
  %boxed24 = inttoptr i64 %28 to ptr
  %29 = call i64 @avra_array_len(ptr %boxed24)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %29

postret18:                                        ; No predecessors!
  br label %endif17
}

declare i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$241120"(ptr, i64, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estatic_has_none"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.52, i64 16))
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.53, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.54, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.55, i64 16))
  %2 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.52, i64 16), ptr %1, ptr getelementptr inbounds (i8, ptr @.str.53, i64 16), ptr getelementptr inbounds (i8, ptr @.str.54, i64 16), ptr getelementptr inbounds (i8, ptr @.str.55, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.55, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.54, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.53, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.52, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ein_a_method"(ptr %0) {
entry:
  %slot = alloca { i1, i1 }, align 8
  %1 = call ptr @avra_array_get_owned(ptr %0, i64 10)
  store { i1, i1 } zeroinitializer, ptr %slot, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  %cmp = icmp slt i64 0, %2
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %sub = sub i64 %2, 1
  %3 = call i64 @avra_array_get(ptr %1, i64 %sub)
  %b = icmp ne i64 %3, 0
  %pack = insertvalue { i1, i1 } { i1 true, i1 undef }, i1 %b, 1
  store { i1, i1 } %pack, ptr %slot, align 8
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld = load { i1, i1 }, ptr %slot, align 8
  %x = extractvalue { i1, i1 } %ld, 0
  br i1 %x, label %then1, label %else2

then1:                                            ; preds = %endif
  %x4 = extractvalue { i1, i1 } %ld, 1
  br label %endif3

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval5 = phi i1 [ %x4, %then1 ], [ false, %else2 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eno_receiver"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.56, i64 16))
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.57, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.58, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.59, i64 16))
  %2 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.56, i64 16), ptr %1, ptr getelementptr inbounds (i8, ptr @.str.57, i64 16), ptr getelementptr inbounds (i8, ptr @.str.58, i64 16), ptr getelementptr inbounds (i8, ptr @.str.59, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.59, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.58, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.57, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.56, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Emet"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 12)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call i1 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eget$2415"(ptr %boxed, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %0)
  ret i1 true

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 12)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$2415"(ptr %boxed1, i64 %1, i1 true)
  call void @avra_rc_release(ptr %0)
  ret i1 false

postret:                                          ; No predecessors!
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eimpl_stmts"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %2
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %1, i64 %ld2)
  store i64 %3, ptr %slot1, align 8
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eimpl_member"(ptr %0, i64 %ld3)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eimpl_member"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_slot_unique(ptr %0, i64 10)
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call i1 @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eis_static"(ptr %boxed1, i64 %1)
  %not = xor i1 %5, true
  %slot = zext i1 %not to i64
  call void @avra_array_push(ptr %2, i64 %slot)
  %6 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %6, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %6)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %0, i1 false, ptr %6)
  %8 = call ptr @avra_slot_unique(ptr %0, i64 10)
  %9 = call i64 @avra_array_pop(ptr %8)
  %b = icmp ne i64 %9, 0
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_scope"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %4 = call i64 @avra_array_get(ptr %0, i64 13)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eset$2415"(ptr %boxed, i64 %1, i1 true)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eopen_overlay"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %3)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_body"(ptr %0, i64 %1, ptr %2, ptr %3)
  call void @avra_rc_retain(ptr %0)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eclose_overlay"(ptr %0)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eclose_overlay"(ptr %0) {
entry:
  %1 = call ptr @avra_slot_unique(ptr %0, i64 7)
  %2 = call ptr @avra_array_pop_owned(ptr %1)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_body"(ptr %0, i64 %1, ptr %2, ptr %3) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_checked"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_index"(ptr %0, i64 %1)
  %6 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %0, i1 true, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %8 = call i64 @avra_array_get(ptr %2, i64 %ld2)
  store i64 %8, ptr %slot1, align 8
  %ld3 = load i64, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %0)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %ld3)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_index"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eloop_index"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %5, ptr %6)
  br i1 %7, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed7 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed7, i64 1)
  %boxed8 = inttoptr i64 %9 to ptr
  call void @avra_rc_retain(ptr %boxed8)
  %10 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %boxed8, i64 %1)
  %cmp9 = icmp ne ptr %10, null
  br i1 %cmp9, label %then10, label %else11

postret5:                                         ; No predecessors!
  br label %endif4

then10:                                           ; preds = %endif4
  call void @avra_rc_retain(ptr %10)
  br label %endif12

else11:                                           ; preds = %endif4
  br label %endif12

endif12:                                          ; preds = %else11, %then10
  %regval13 = phi ptr [ %10, %then10 ], [ getelementptr inbounds (i8, ptr @.str.60, i64 16), %else11 ]
  %11 = call i64 @avra_streq(ptr %5, ptr %regval13)
  %b = icmp ne i64 %11, 0
  br i1 %b, label %then14, label %else15

then14:                                           ; preds = %endif12
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Epaired_alike"(ptr %0, i64 %1, ptr %5)
  call void @avra_rc_release(ptr %regval13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %12

else15:                                           ; preds = %endif12
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %13 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed19 = inttoptr i64 %13 to ptr
  call void @avra_rc_retain(ptr %boxed19)
  %14 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of_stmt"(ptr %boxed19, i64 %1)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %5, ptr %14)
  %16 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %16, i64 6)
  call void @avra_array_push(ptr %16, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  call void @avra_rc_retain(ptr %16)
  %17 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind"(ptr %0, ptr %15, ptr %16)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %regval13)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %17

postret17:                                        ; No predecessors!
  br label %endif16
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind"(ptr %0, ptr %1, ptr %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %4, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_slot_unique(ptr %0, i64 6)
  call void @avra_map_set_owned(ptr %5, ptr %1, ptr %2)
  br label %endif

else:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed1 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_len(ptr %boxed1)
  %sub = sub i64 %7, 1
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 7)
  %9 = call ptr @avra_array_get_owned(ptr %8, i64 %sub)
  call void @avra_rc_retain(ptr %9)
  call void @avra_cell_release(ptr %slot)
  store ptr %9, ptr %slot, align 8
  %10 = call ptr @avra_cell_unique(ptr %slot)
  call void @avra_map_set_owned(ptr %10, ptr %1, ptr %2)
  %11 = call ptr @avra_slot_unique(ptr %0, i64 7)
  %ld = load ptr, ptr %slot, align 8
  call void @avra_slot_set_owned(ptr %11, i64 %sub, ptr %ld)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Epaired_alike"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %1)
  %4 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.62, i64 16))
  call void @avra_array_push_owned(ptr %4, ptr %2)
  call void @avra_array_push_owned(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.63, i64 16))
  %5 = call ptr @avra_str_join(ptr %4, ptr getelementptr inbounds (i8, ptr @.str.64, i64 16))
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.66, i64 16))
  call void @avra_array_push_owned(ptr %6, ptr %2)
  call void @avra_array_push_owned(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.67, i64 16))
  %7 = call ptr @avra_str_join(ptr %6, ptr getelementptr inbounds (i8, ptr @.str.68, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.61, i64 16))
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.65, i64 16))
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.61, i64 16), ptr %3, ptr %5, ptr getelementptr inbounds (i8, ptr @.str.65, i64 16), ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %8)
  %9 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %8)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.68, i64 16))
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.67, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.66, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.65, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.64, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.63, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.62, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.61, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %9
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Eloop_index"(ptr, i64)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_checked"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %4 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elet_name"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %4, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %5 = call ptr @avra_insist(ptr %4)
  call void @avra_rc_retain(ptr %0)
  %6 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %6)
  %7 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %5, ptr %6)
  br i1 %7, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %9 = call i64 @avra_array_get(ptr %8, i64 4)
  %boxed7 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed8 = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %boxed8, i64 0)
  call void @avra_rc_retain(ptr %boxed7)
  %12 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl_of"(ptr %boxed7, i64 %11, i64 %1)
  %cmp9 = icmp ne ptr %12, null
  br i1 %cmp9, label %then10, label %else11

postret5:                                         ; No predecessors!
  br label %endif4

then10:                                           ; preds = %endif4
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else11:                                           ; preds = %endif4
  br label %endif12

endif12:                                          ; preds = %else11, %postret13
  %regval14 = phi i64 [ 0, %postret13 ], [ 0, %else11 ]
  %13 = call ptr @avra_insist(ptr %4)
  %14 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed15 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed15)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of_stmt"(ptr %boxed15, i64 %1)
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %15)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %13, ptr %15)
  %17 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %17, i64 2)
  call void @avra_array_push(ptr %17, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  call void @avra_rc_retain(ptr %17)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind"(ptr %0, ptr %16, ptr %17)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %0)
  ret i64 %18

postret13:                                        ; No predecessors!
  br label %endif12
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eopen_overlay"(ptr %0) {
entry:
  %1 = call ptr @avra_map_new()
  %2 = call ptr @avra_slot_unique(ptr %0, i64 7)
  call void @avra_array_push_owned(ptr %2, ptr %1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Escope_stmts"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr %0)
  %2 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eopen_overlay"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %0, i1 true, ptr %1)
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eclose_overlay"(ptr %0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echeck_params"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot5 = alloca i64, align 8
  %slot3 = alloca i1, align 1
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %0)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %2)
  %4 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif16, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %4
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 %ld2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot1)
  store ptr %5, ptr %slot1, align 8
  store i1 false, ptr %slot3, align 8
  %ld4 = load ptr, ptr %slot1, align 8
  call void @avra_rc_retain(ptr %ld4)
  %6 = call ptr @avra_array_get_owned(ptr %ld4, i64 0)
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 3)
  %8 = call i64 @avra_array_len(ptr %7)
  store i64 0, ptr %slot5, align 8
  br label %lhead6

lhead6:                                           ; preds = %endif, %lbody
  %ld8 = load i64, ptr %slot5, align 8
  %cmp9 = icmp slt i64 %ld8, %8
  br i1 %cmp9, label %lbody10, label %lexit7

lexit7:                                           ; preds = %lhead6
  %ld13 = load i1, ptr %slot3, align 8
  br i1 %ld13, label %then14, label %else15

lbody10:                                          ; preds = %lhead6
  %ld11 = load i64, ptr %slot5, align 8
  %9 = call i64 @avra_array_get(ptr %7, i64 %ld11)
  %boxed = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_streq(ptr %boxed, ptr %6)
  %b = icmp ne i64 %10, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody10
  store i1 true, ptr %slot3, align 8
  store i64 %8, ptr %slot5, align 8
  br label %endif

else:                                             ; preds = %lbody10
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld12 = load i64, ptr %slot5, align 8
  %add = add i64 %ld12, 1
  store i64 %add, ptr %slot5, align 8
  br label %lhead6

then14:                                           ; preds = %lexit7
  %ld17 = load ptr, ptr %slot1, align 8
  %11 = call i64 @avra_array_get(ptr %ld17, i64 0)
  %boxed18 = inttoptr i64 %11 to ptr
  %12 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed19 = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %boxed19, i64 6)
  %boxed20 = inttoptr i64 %13 to ptr
  %ld21 = load ptr, ptr %slot1, align 8
  %14 = call i64 @avra_array_get(ptr %ld21, i64 0)
  %boxed22 = inttoptr i64 %14 to ptr
  call void @avra_rc_retain(ptr %boxed20)
  call void @avra_rc_retain(ptr %boxed22)
  %15 = call ptr @"av_$40std$2Eavrac$2Efeatures$2Eremedy_for"(ptr %boxed20, ptr %boxed22)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed18)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefuse_keyword"(ptr %0, ptr %boxed18, ptr %3, ptr %15)
  call void @avra_rc_release(ptr %15)
  br label %endif16

else15:                                           ; preds = %lexit7
  %ld23 = load ptr, ptr %slot1, align 8
  %17 = call i64 @avra_array_get(ptr %ld23, i64 0)
  %boxed24 = inttoptr i64 %17 to ptr
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed24)
  call void @avra_rc_retain(ptr %3)
  %18 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %boxed24, ptr %3)
  br label %endif16

endif16:                                          ; preds = %else15, %then14
  %regval25 = phi i64 [ 0, %then14 ], [ 0, %else15 ]
  %ld26 = load i64, ptr %slot, align 8
  %add27 = add i64 %ld26, 1
  store i64 %add27, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2Eremedy_for"(ptr, ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_scope"(ptr %0, ptr %1, i64 %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eopen_overlay"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_body"(ptr %0, ptr %1, i64 %2)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eclose_overlay"(ptr %0)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Earm_body"(ptr %0, ptr %1, i64 %2) {
entry:
  %slot1 = alloca ptr, align 8
  store ptr null, ptr %slot1, align 8
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_retain(ptr %0)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %2)
  call void @avra_cell_release(ptr %slot1)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %4

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %5 = call ptr @avra_array_get_owned(ptr %1, i64 %ld2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot1)
  store ptr %5, ptr %slot1, align 8
  %ld3 = load ptr, ptr %slot1, align 8
  %6 = call i64 @avra_array_get(ptr %ld3, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %7)
  %8 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_binder"(ptr %0, ptr %boxed, ptr %7)
  %not = xor i1 %8, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %lbody
  %ld4 = load ptr, ptr %slot1, align 8
  %9 = call i64 @avra_array_get(ptr %ld4, i64 0)
  %boxed5 = inttoptr i64 %9 to ptr
  %ld6 = load ptr, ptr %slot1, align 8
  %10 = call i64 @avra_array_get(ptr %ld6, i64 1)
  %boxed7 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %boxed5)
  call void @avra_rc_retain(ptr %boxed7)
  %11 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %boxed5, ptr %boxed7)
  %12 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %12, i64 3)
  call void @avra_array_push(ptr %12, i64 %2)
  call void @avra_array_push(ptr %12, i64 %ld2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  call void @avra_rc_retain(ptr %12)
  %13 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind"(ptr %0, ptr %11, ptr %12)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld8 = load i64, ptr %slot, align 8
  %add = add i64 %ld8, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_at"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot = alloca i64, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %4 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr %boxed, i64 %1)
  %5 = call ptr @avra_array_sized(i64 0)
  %6 = call i64 @avra_array_len(ptr %2)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %5

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %7 = call i64 @avra_array_get(ptr %2, i64 %ld1)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %8, ptr %boxed2)
  call void @avra_array_push_owned(ptr %8, ptr %4)
  call void @avra_array_push_owned(ptr %5, ptr %8)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  br label %lhead
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of_pat"(ptr, i64)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebound_pats"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call ptr @avra_array_sized(i64 0)
  %3 = call i64 @avra_array_len(ptr %1)
  store i64 0, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %lbody, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp slt i64 %ld, %3
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %2

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %4 = call i64 @avra_array_get(ptr %1, i64 %ld1)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call ptr @avra_array_get_owned(ptr %boxed, i64 1)
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed2 = inttoptr i64 %6 to ptr
  %7 = call i64 @avra_array_get(ptr %boxed, i64 0)
  call void @avra_rc_retain(ptr %boxed2)
  %8 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of_pat"(ptr %boxed2, i64 %7)
  %9 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %9, ptr %5)
  call void @avra_array_push_owned(ptr %9, ptr %8)
  call void @avra_array_push_owned(ptr %2, ptr %9)
  %ld3 = load i64, ptr %slot, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %5)
  br label %lhead
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Euse_type"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Emet"(ptr %0, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enames_at"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr %4, ptr %2)
  %cmp = icmp ne ptr %5, null
  br i1 %cmp, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %7, i64 7)
  call void @avra_array_push_owned(ptr %7, ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr %2)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Efn_decl"(ptr %4, ptr %2)
  %cmp6 = icmp ne ptr %9, null
  br i1 %cmp6, label %then7, label %else8

postret4:                                         ; No predecessors!
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  br label %endif3

then7:                                            ; preds = %endif3
  call void @avra_rc_retain(ptr %0)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  %11 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.70, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %2)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.71, i64 16))
  call void @avra_array_push_owned(ptr %11, ptr %2)
  call void @avra_array_push_owned(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.72, i64 16))
  %12 = call ptr @avra_str_join(ptr %11, ptr getelementptr inbounds (i8, ptr @.str.73, i64 16))
  %13 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %13, ptr getelementptr inbounds (i8, ptr @.str.75, i64 16))
  call void @avra_array_push_owned(ptr %13, ptr %2)
  call void @avra_array_push_owned(ptr %13, ptr getelementptr inbounds (i8, ptr @.str.76, i64 16))
  %14 = call ptr @avra_str_join(ptr %13, ptr getelementptr inbounds (i8, ptr @.str.77, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.69, i64 16))
  call void @avra_rc_retain(ptr %10)
  call void @avra_rc_retain(ptr %12)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.74, i64 16))
  call void @avra_rc_retain(ptr %14)
  %15 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.69, i64 16), ptr %10, ptr %12, ptr getelementptr inbounds (i8, ptr @.str.74, i64 16), ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.77, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.76, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.75, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.74, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.73, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.72, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.71, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.70, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.69, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %16

else8:                                            ; preds = %endif3
  br label %endif9

endif9:                                           ; preds = %else8, %postret10
  %regval11 = phi i64 [ 0, %postret10 ], [ 0, %else8 ]
  call void @avra_rc_retain(ptr %0)
  %17 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  %18 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.79, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %2)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.80, i64 16))
  %19 = call ptr @avra_str_join(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.81, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.78, i64 16))
  call void @avra_rc_retain(ptr %17)
  call void @avra_rc_retain(ptr %19)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.82, i64 16))
  %20 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.78, i64 16), ptr %17, ptr %19, ptr getelementptr inbounds (i8, ptr @.str.82, i64 16), ptr null)
  call void @avra_rc_retain(ptr %4)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_suggestions"(ptr %4)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %20)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Esuggested"(ptr %0, ptr %20, i64 %1, ptr %2, ptr %21)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %22)
  %23 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %22)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.82, i64 16))
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.81, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.80, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.79, i64 16))
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.78, i64 16))
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %23

postret10:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.77, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.76, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.75, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.74, i64 16))
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.73, i64 16))
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.72, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.71, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.70, i64 16))
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.69, i64 16))
  br label %endif9
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Esuggested"(ptr %0, ptr %1, i64 %2, ptr %3, ptr %4) {
entry:
  %slot = alloca i64, align 8
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %4)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2Eclosest"(ptr %3, ptr %4)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %1

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %5)
  call void @avra_rc_retain(ptr %0)
  %7 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %2)
  %8 = call ptr @avra_array_sized(i64 0)
  call void @avra_rc_retain(ptr %7)
  %9 = call ptr @"av_$40std$2Eavrac$2Ecore$2Esome_list$2410"(ptr %7)
  %10 = call i64 @avra_array_len(ptr %9)
  store i64 0, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %lbody, %endif
  %ld = load i64, ptr %slot, align 8
  %cmp1 = icmp slt i64 %ld, %10
  br i1 %cmp1, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %11 = call i64 @avra_array_get(ptr %6, i64 1)
  %cmp5 = icmp eq i64 %11, 1
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot, align 8
  %12 = call i64 @avra_array_get(ptr %9, i64 %ld2)
  %boxed = inttoptr i64 %12 to ptr
  %13 = call i64 @avra_array_get(ptr %6, i64 0)
  %boxed3 = inttoptr i64 %13 to ptr
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %14, ptr %boxed)
  call void @avra_array_push_owned(ptr %14, ptr %boxed3)
  call void @avra_array_push_owned(ptr %8, ptr %14)
  %ld4 = load i64, ptr %slot, align 8
  %add = add i64 %ld4, 1
  store i64 %add, ptr %slot, align 8
  call void @avra_rc_release(ptr %14)
  br label %lhead

then6:                                            ; preds = %lexit
  %15 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %15, i64 0)
  br label %endif8

else7:                                            ; preds = %lexit
  %16 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %16, i64 1)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %15, %then6 ], [ %16, %else7 ]
  %17 = call i64 @avra_array_get(ptr %6, i64 0)
  %boxed10 = inttoptr i64 %17 to ptr
  %18 = call ptr @avra_array_sized(i64 5)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.83, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %3)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.84, i64 16))
  call void @avra_array_push_owned(ptr %18, ptr %boxed10)
  call void @avra_array_push_owned(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.85, i64 16))
  %19 = call ptr @avra_str_join(ptr %18, ptr getelementptr inbounds (i8, ptr @.str.86, i64 16))
  %20 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %20, ptr %regval9)
  call void @avra_array_push_owned(ptr %20, ptr %19)
  call void @avra_array_push_owned(ptr %20, ptr %8)
  %21 = call i64 @avra_array_get(ptr %6, i64 0)
  %boxed11 = inttoptr i64 %21 to ptr
  %22 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.87, i64 16))
  call void @avra_array_push_owned(ptr %22, ptr %boxed11)
  call void @avra_array_push_owned(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.88, i64 16))
  %23 = call ptr @avra_str_join(ptr %22, ptr getelementptr inbounds (i8, ptr @.str.89, i64 16))
  %24 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %24, ptr %20)
  %25 = call ptr @avra_array_get_owned(ptr %1, i64 0)
  %26 = call ptr @avra_array_get_owned(ptr %1, i64 1)
  %27 = call ptr @avra_array_get_owned(ptr %1, i64 2)
  %28 = call ptr @avra_array_get_owned(ptr %1, i64 3)
  %29 = call i64 @avra_array_get(ptr %1, i64 4)
  %boxed12 = inttoptr i64 %29 to ptr
  %30 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %30, ptr %25)
  call void @avra_array_push_owned(ptr %30, ptr %26)
  call void @avra_array_push_owned(ptr %30, ptr %27)
  call void @avra_array_push_owned(ptr %30, ptr %28)
  call void @avra_array_push_owned(ptr %30, ptr %boxed12)
  call void @avra_array_push_owned(ptr %30, ptr %23)
  call void @avra_array_push_owned(ptr %30, ptr %24)
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.89, i64 16))
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.88, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.87, i64 16))
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.86, i64 16))
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.85, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.84, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.83, i64 16))
  call void @avra_rc_release(ptr %regval9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %30
}

declare ptr @"av_$40std$2Eavrac$2Ecore$2Eclosest"(ptr, ptr)

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_suggestions"(ptr)

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enames_at"(ptr %0, i64 %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %3 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enames_in"(ptr %0, ptr %3)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %0)
  ret ptr %4
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enames_in"(ptr %0, ptr %1) {
entry:
  %cmp = icmp ne ptr %1, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  %2 = call ptr @avra_array_get_owned(ptr %0, i64 1)
  %3 = call ptr @avra_array_get_owned(ptr %2, i64 4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %3

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 16)
  %boxed = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %5 to ptr
  %6 = call ptr @avra_insist(ptr %1)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %8 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %boxed1)
  %cast = inttoptr i64 %8 to ptr
  %9 = call ptr %cast(ptr %boxed1, i64 %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %9

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Euse_call"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Emet"(ptr %0, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  %5 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_name"(ptr %0, ptr %2, ptr %4)
  br i1 %5, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enames_in"(ptr %0, ptr %7)
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %2)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Efn_decl"(ptr %8, ptr %2)
  %cmp = icmp ne ptr %9, null
  br i1 %cmp, label %then6, label %else7

postret4:                                         ; No predecessors!
  br label %endif3

then6:                                            ; preds = %endif3
  %10 = call ptr @avra_insist(ptr %9)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 7)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %11)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else7:                                            ; preds = %endif3
  br label %endif8

endif8:                                           ; preds = %else7, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else7 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Egenerated_named"(ptr %0, ptr %2, ptr %7)
  %cmp11 = icmp ne ptr %13, null
  br i1 %cmp11, label %then12, label %else13

postret9:                                         ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif8

then12:                                           ; preds = %endif8
  %14 = call ptr @avra_insist(ptr %13)
  %15 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %15, i64 7)
  call void @avra_array_push_owned(ptr %15, ptr %14)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %15)
  %16 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %15)
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else13:                                           ; preds = %endif8
  br label %endif14

endif14:                                          ; preds = %else13, %postret15
  %regval16 = phi i64 [ 0, %postret15 ], [ 0, %else13 ]
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %17 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %2, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %17)
  %18 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elocal_binding"(ptr %0, ptr %17)
  %cmp17 = icmp ne ptr %18, null
  br i1 %cmp17, label %then18, label %else19

postret15:                                        ; No predecessors!
  call void @avra_rc_release(ptr %15)
  call void @avra_rc_release(ptr %14)
  br label %endif14

then18:                                           ; preds = %endif14
  %19 = call ptr @avra_insist(ptr %18)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %19)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else19:                                           ; preds = %endif14
  br label %endif20

endif20:                                          ; preds = %else19, %postret21
  %regval22 = phi i64 [ 0, %postret21 ], [ 0, %else19 ]
  call void @avra_rc_retain(ptr %8)
  call void @avra_rc_retain(ptr %2)
  %21 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr %8, ptr %2)
  %cmp23 = icmp ne ptr %21, null
  br i1 %cmp23, label %then24, label %else25

postret21:                                        ; No predecessors!
  call void @avra_rc_release(ptr %19)
  br label %endif20

then24:                                           ; preds = %endif20
  %22 = call ptr @avra_insist(ptr %21)
  %23 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %23, i64 7)
  call void @avra_array_push_owned(ptr %23, ptr %22)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %23)
  %24 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %23)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else25:                                           ; preds = %endif20
  br label %endif26

endif26:                                          ; preds = %else25, %postret27
  %regval28 = phi i64 [ 0, %postret27 ], [ 0, %else25 ]
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %25 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %2, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %25)
  %26 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ehidden_def"(ptr %0, ptr %25)
  br i1 %26, label %then29, label %else30

postret27:                                        ; No predecessors!
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %22)
  br label %endif26

then29:                                           ; preds = %endif26
  call void @avra_rc_retain(ptr %0)
  %27 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %27)
  %28 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eruntime_binding"(ptr %0, ptr %2, ptr %27)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %28

else30:                                           ; preds = %endif26
  br label %endif31

endif31:                                          ; preds = %else30, %postret32
  %regval33 = phi i64 [ 0, %postret32 ], [ 0, %else30 ]
  call void @avra_rc_retain(ptr %0)
  %29 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  %30 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %30, ptr getelementptr inbounds (i8, ptr @.str.91, i64 16))
  call void @avra_array_push_owned(ptr %30, ptr %2)
  call void @avra_array_push_owned(ptr %30, ptr getelementptr inbounds (i8, ptr @.str.92, i64 16))
  %31 = call ptr @avra_str_join(ptr %30, ptr getelementptr inbounds (i8, ptr @.str.93, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.90, i64 16))
  call void @avra_rc_retain(ptr %29)
  call void @avra_rc_retain(ptr %31)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.94, i64 16))
  %32 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.90, i64 16), ptr %29, ptr %31, ptr getelementptr inbounds (i8, ptr @.str.94, i64 16), ptr null)
  call void @avra_rc_retain(ptr %8)
  %33 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Efn_suggestions"(ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %32)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %33)
  %34 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Esuggested"(ptr %0, ptr %32, i64 %1, ptr %2, ptr %33)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %34)
  %35 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %34)
  call void @avra_rc_release(ptr %34)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.94, i64 16))
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.93, i64 16))
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.92, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.91, i64 16))
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.90, i64 16))
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %18)
  call void @avra_rc_release(ptr %17)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %35

postret32:                                        ; No predecessors!
  call void @avra_rc_release(ptr %27)
  br label %endif31
}

declare ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Efn_suggestions"(ptr)

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eruntime_binding"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.96, i64 16))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.97, i64 16))
  %4 = call ptr @avra_str_join(ptr %3, ptr getelementptr inbounds (i8, ptr @.str.98, i64 16))
  %5 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.100, i64 16))
  call void @avra_array_push_owned(ptr %5, ptr %1)
  call void @avra_array_push_owned(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.101, i64 16))
  %6 = call ptr @avra_str_join(ptr %5, ptr getelementptr inbounds (i8, ptr @.str.102, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.95, i64 16))
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.99, i64 16))
  call void @avra_rc_retain(ptr %6)
  %7 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.95, i64 16), ptr %2, ptr %4, ptr getelementptr inbounds (i8, ptr @.str.99, i64 16), ptr %6)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %7)
  %8 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %7)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.102, i64 16))
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.101, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.100, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.99, i64 16))
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.98, i64 16))
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.97, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.96, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.95, i64 16))
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %8
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ehidden_def"(ptr %0, ptr %1) {
entry:
  %slot3 = alloca i64, align 8
  %slot = alloca i1, align 1
  %2 = call i64 @avra_array_get(ptr %0, i64 9)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %4 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 1)
  %boxed2 = inttoptr i64 %5 to ptr
  store i1 false, ptr %slot, align 8
  %6 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %6, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l1242" to i64))
  call void @avra_array_push_owned(ptr %6, ptr %1)
  call void @avra_array_push_owned(ptr %6, ptr %boxed2)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %8 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %9 = call i64 @avra_array_len(ptr %8)
  store i64 0, ptr %slot3, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif

lhead:                                            ; preds = %endif9, %endif
  %ld = load i64, ptr %slot3, align 8
  %cmp4 = icmp slt i64 %ld, %9
  br i1 %cmp4, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld12 = load i1, ptr %slot, align 8
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %ld12

lbody:                                            ; preds = %lhead
  %ld5 = load i64, ptr %slot3, align 8
  %10 = call i64 @avra_array_get(ptr %8, i64 %ld5)
  %boxed6 = inttoptr i64 %10 to ptr
  call void @avra_rc_retain(ptr %6)
  call void @avra_rc_retain(ptr %boxed6)
  %cast = inttoptr i64 %7 to ptr
  %11 = call i1 %cast(ptr %6, ptr %boxed6)
  br i1 %11, label %then7, label %else8

then7:                                            ; preds = %lbody
  store i1 true, ptr %slot, align 8
  store i64 %9, ptr %slot3, align 8
  br label %endif9

else8:                                            ; preds = %lbody
  br label %endif9

endif9:                                           ; preds = %else8, %then7
  %regval10 = phi i64 [ 0, %then7 ], [ 0, %else8 ]
  %ld11 = load i64, ptr %slot3, align 8
  %add = add i64 %ld11, 1
  store i64 %add, ptr %slot3, align 8
  br label %lhead
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l1242"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Econst_value"(ptr %boxed2, i64 %6)
  %cmp = icmp ne ptr %7, null
  %not = xor i1 %cmp, true
  call void @avra_rc_release(ptr %7)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elocal_binding"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr %boxed)
  call void @avra_rc_retain(ptr %1)
  %3 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Eoverlay_index"(ptr %boxed, ptr %1)
  %4 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Eframe_param_hit"(ptr %boxed1, ptr %1)
  %x = extractvalue { i1, i64 } %3, 0
  %not = xor i1 %x, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %6 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed2 = inttoptr i64 %6 to ptr
  %x3 = extractvalue { i1, i64 } %3, 1
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call i64 @"av_$40std$2Eavrac$2Elanguage$2Eoverlay_home"(ptr %boxed2, i64 %x3)
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ -1, %then ], [ %7, %else ]
  %x4 = extractvalue { i1, i64 } %5, 0
  br i1 %x4, label %then5, label %else6

then5:                                            ; preds = %endif
  %x8 = extractvalue { i1, i64 } %5, 1
  br label %endif7

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %then5
  %regval9 = phi i64 [ %x8, %then5 ], [ -1, %else6 ]
  %x10 = extractvalue { i1, i64 } %3, 0
  br i1 %x10, label %then11, label %else12

then11:                                           ; preds = %endif7
  %cmp = icmp sge i64 %regval, %regval9
  br label %endif13

else12:                                           ; preds = %endif7
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i1 [ %cmp, %then11 ], [ false, %else12 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif13
  %add = add i64 %regval, 1
  %8 = call i64 @avra_array_get(ptr %0, i64 7)
  %boxed18 = inttoptr i64 %8 to ptr
  %x19 = extractvalue { i1, i64 } %3, 0
  %x20 = extractvalue { i1, i64 } %3, 1
  %slot = zext i1 %x19 to i64
  %9 = call i64 @avra_insist_scalar(i64 %slot, i64 %x20)
  call void @avra_rc_retain(ptr %boxed18)
  call void @avra_rc_retain(ptr %1)
  %10 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Eoverlay_at"(ptr %boxed18, i64 %9, ptr %1)
  %11 = call ptr @avra_insist(ptr %10)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %11)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echained"(ptr %0, i64 %add, ptr %1, ptr %11)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %12

else16:                                           ; preds = %endif13
  br label %endif17

endif17:                                          ; preds = %else16, %postret
  %regval21 = phi i64 [ 0, %postret ], [ 0, %else16 ]
  %x22 = extractvalue { i1, i64 } %5, 0
  br i1 %x22, label %then23, label %else24

postret:                                          ; No predecessors!
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif17

then23:                                           ; preds = %endif17
  %13 = call i64 @avra_array_get(ptr %0, i64 8)
  %boxed26 = inttoptr i64 %13 to ptr
  %x27 = extractvalue { i1, i64 } %5, 0
  %x28 = extractvalue { i1, i64 } %5, 1
  %slot29 = zext i1 %x27 to i64
  %14 = call i64 @avra_insist_scalar(i64 %slot29, i64 %x28)
  %15 = call i64 @avra_array_get(ptr %boxed26, i64 %14)
  %boxed30 = inttoptr i64 %15 to ptr
  %x31 = extractvalue { i1, i64 } %5, 0
  %x32 = extractvalue { i1, i64 } %5, 1
  %slot33 = zext i1 %x31 to i64
  %16 = call i64 @avra_insist_scalar(i64 %slot33, i64 %x32)
  %add34 = add i64 %16, 1
  %17 = call i64 @avra_array_get(ptr %boxed30, i64 0)
  %18 = call i64 @avra_array_get(ptr %boxed30, i64 1)
  %boxed35 = inttoptr i64 %18 to ptr
  call void @avra_rc_retain(ptr %boxed35)
  call void @avra_rc_retain(ptr %1)
  %19 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2Efound_at"(ptr %boxed35, ptr %1)
  %x36 = extractvalue { i1, i64 } %19, 0
  %x37 = extractvalue { i1, i64 } %19, 1
  %slot38 = zext i1 %x36 to i64
  %20 = call i64 @avra_insist_scalar(i64 %slot38, i64 %x37)
  %21 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %21, i64 4)
  call void @avra_array_push(ptr %21, i64 %17)
  call void @avra_array_push(ptr %21, i64 %20)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %21)
  %22 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echained"(ptr %0, i64 %add34, ptr %1, ptr %21)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %22

else24:                                           ; preds = %endif17
  br label %endif25

endif25:                                          ; preds = %else24, %postret39
  %regval40 = phi i64 [ 0, %postret39 ], [ 0, %else24 ]
  %23 = call i64 @avra_array_get(ptr %0, i64 14)
  %boxed41 = inttoptr i64 %23 to ptr
  call void @avra_rc_retain(ptr %boxed41)
  call void @avra_rc_retain(ptr %1)
  %24 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2Efound_at"(ptr %boxed41, ptr %1)
  %x42 = extractvalue { i1, i64 } %24, 0
  br i1 %x42, label %then43, label %else44

postret39:                                        ; No predecessors!
  call void @avra_rc_release(ptr %22)
  call void @avra_rc_release(ptr %21)
  br label %endif25

then43:                                           ; preds = %endif25
  %x46 = extractvalue { i1, i64 } %24, 0
  %x47 = extractvalue { i1, i64 } %24, 1
  %slot48 = zext i1 %x46 to i64
  %25 = call i64 @avra_insist_scalar(i64 %slot48, i64 %x47)
  call void @avra_rc_retain(ptr %0)
  %26 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_base"(ptr %0)
  %add49 = add i64 %25, %26
  %27 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %27, i64 0)
  call void @avra_array_push(ptr %27, i64 %add49)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echained"(ptr %0, i64 0, ptr %1, ptr %27)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %28

else44:                                           ; preds = %endif25
  br label %endif45

endif45:                                          ; preds = %else44, %postret50
  %regval51 = phi i64 [ 0, %postret50 ], [ 0, %else44 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %29 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eouter_binding"(ptr %0, ptr %1)
  %cmp52 = icmp ne ptr %29, null
  %not53 = xor i1 %cmp52, true
  br i1 %not53, label %then54, label %else55

postret50:                                        ; No predecessors!
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  br label %endif45

then54:                                           ; preds = %endif45
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else55:                                           ; preds = %endif45
  br label %endif56

endif56:                                          ; preds = %else55, %postret57
  %regval58 = phi i64 [ 0, %postret57 ], [ 0, %else55 ]
  %30 = call ptr @avra_insist(ptr %29)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %30)
  %31 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Echained"(ptr %0, i64 0, ptr %1, ptr %30)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %31

postret57:                                        ; No predecessors!
  br label %endif56
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eouter_binding"(ptr %0, ptr %1) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 9)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_len(ptr %boxed)
  %cmp = icmp eq i64 %3, 0
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_array_get_owned(ptr %0, i64 6)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %5 = call i64 @avra_map_has(ptr %4, ptr %1)
  %b = icmp ne i64 %5, 0
  br i1 %b, label %then1, label %else2

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval4 = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

then1:                                            ; preds = %then
  %6 = call ptr @avra_map_get_owned(ptr %4, ptr %1)
  call void @avra_rc_retain(ptr %6)
  call void @avra_cell_release(ptr %slot)
  store ptr %6, ptr %slot, align 8
  call void @avra_rc_release(ptr %6)
  br label %endif3

else2:                                            ; preds = %then
  br label %endif3

endif3:                                           ; preds = %else2, %then1
  %regval = phi i64 [ 0, %then1 ], [ 0, %else2 ]
  %ld = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld)
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld

postret:                                          ; No predecessors!
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %4)
  br label %endif
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_base"(ptr %0) {
entry:
  call void @avra_rc_retain(ptr %0)
  %1 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ein_a_method"(ptr %0)
  br i1 %1, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 1, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %0)
  ret i64 %regval
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2Eoverlay_at"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call i64 @avra_map_has(ptr %3, ptr %2)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %5 = call ptr @avra_map_get_owned(ptr %3, ptr %2)
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
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret ptr %ld
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2Eoverlay_home"(ptr %0, i64 %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %0)
  ret i64 -1

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 2)
  %cmp2 = icmp sle i64 %4, %1
  br i1 %cmp2, label %then, label %else

then:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot, align 8
  call void @avra_rc_release(ptr %0)
  ret i64 %ld3

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %sub5 = sub i64 %ld4, 1
  store i64 %sub5, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Eframe_param_hit"(ptr %0, ptr %1) {
entry:
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call i64 @avra_array_get(ptr %0, i64 %ld1)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed2 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed2)
  call void @avra_rc_retain(ptr %1)
  %5 = call { i1, i64 } @"av_$40std$2Eavrac$2Ecore$2Efound_at"(ptr %boxed2, ptr %1)
  %x = extractvalue { i1, i64 } %5, 0
  br i1 %x, label %then, label %else

then:                                             ; preds = %lbody
  %ld3 = load i64, ptr %slot, align 8
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %ld3, 1
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %pack

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %ld4 = load i64, ptr %slot, align 8
  %sub5 = sub i64 %ld4, 1
  store i64 %sub5, ptr %slot, align 8
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif
}

define { i1, i64 } @"av_$40std$2Eavrac$2Elanguage$2Eoverlay_index"(ptr %0, ptr %1) {
entry:
  %slot2 = alloca ptr, align 8
  store ptr null, ptr %slot2, align 8
  %slot = alloca i64, align 8
  %2 = call i64 @avra_array_len(ptr %0)
  %sub = sub i64 %2, 1
  store i64 %sub, ptr %slot, align 8
  br label %lhead

lhead:                                            ; preds = %endif7, %entry
  %ld = load i64, ptr %slot, align 8
  %cmp = icmp sge i64 %ld, 0
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } zeroinitializer

lbody:                                            ; preds = %lhead
  %ld1 = load i64, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 %ld1)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot2)
  store ptr null, ptr %slot2, align 8
  %4 = call i64 @avra_map_has(ptr %3, ptr %1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %lbody
  %5 = call ptr @avra_map_get_owned(ptr %3, ptr %1)
  call void @avra_rc_retain(ptr %5)
  call void @avra_cell_release(ptr %slot2)
  store ptr %5, ptr %slot2, align 8
  call void @avra_rc_release(ptr %5)
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load ptr, ptr %slot2, align 8
  %cmp4 = icmp ne ptr %ld3, null
  br i1 %cmp4, label %then5, label %else6

then5:                                            ; preds = %endif
  %ld8 = load i64, ptr %slot, align 8
  %pack = insertvalue { i1, i64 } { i1 true, i64 undef }, i64 %ld8, 1
  call void @avra_cell_release(ptr %slot2)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret { i1, i64 } %pack

else6:                                            ; preds = %endif
  br label %endif7

endif7:                                           ; preds = %else6, %postret
  %regval9 = phi i64 [ 0, %postret ], [ 0, %else6 ]
  %ld10 = load i64, ptr %slot, align 8
  %sub11 = sub i64 %ld10, 1
  store i64 %sub11, ptr %slot, align 8
  call void @avra_cell_release(ptr %slot2)
  call void @avra_rc_release(ptr %3)
  br label %lhead

postret:                                          ; No predecessors!
  br label %endif7
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Egenerated_named"(ptr %0, ptr %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 16)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 0)
  %boxed1 = inttoptr i64 %4 to ptr
  %5 = call i64 @avra_array_get(ptr %boxed1, i64 0)
  call void @avra_rc_retain(ptr %boxed1)
  call void @avra_rc_retain(ptr %1)
  %cast = inttoptr i64 %5 to ptr
  %6 = call ptr %cast(ptr %boxed1, ptr %1)
  %cmp = icmp ne ptr %6, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  br label %endif

else:                                             ; preds = %entry
  %cmp2 = icmp ne ptr %2, null
  %not3 = xor i1 %cmp2, true
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ true, %then ], [ %not3, %else ]
  br i1 %regval, label %then4, label %else5

then4:                                            ; preds = %endif
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %6

else5:                                            ; preds = %endif
  br label %endif6

endif6:                                           ; preds = %else5, %postret
  %regval7 = phi i64 [ 0, %postret ], [ 0, %else5 ]
  %7 = call ptr @avra_array_get_owned(ptr %0, i64 0)
  %8 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed8 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed8, i64 4)
  %boxed9 = inttoptr i64 %9 to ptr
  %10 = call ptr @avra_insist(ptr %6)
  call void @avra_rc_retain(ptr %boxed9)
  call void @avra_rc_retain(ptr %10)
  %11 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EDecls$2Edecl"(ptr %boxed9, ptr %10)
  %12 = call i64 @avra_array_get(ptr %11, i64 2)
  call void @avra_rc_retain(ptr %7)
  %13 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of_stmt"(ptr %7, i64 %12)
  %cmp10 = icmp ne ptr %13, null
  br i1 %cmp10, label %then11, label %else12

postret:                                          ; No predecessors!
  br label %endif6

then11:                                           ; preds = %endif6
  %14 = call ptr @avra_insist(ptr %13)
  %15 = call i64 @avra_array_get(ptr %14, i64 0)
  %16 = call ptr @avra_insist(ptr %2)
  %17 = call i64 @avra_array_get(ptr %16, i64 0)
  %18 = call i1 @"av_$40std$2Eavrac$2Ecore$2Esame_file"(i64 %15, i64 %17)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr %14)
  br label %endif13

else12:                                           ; preds = %endif6
  br label %endif13

endif13:                                          ; preds = %else12, %then11
  %regval14 = phi i1 [ %18, %then11 ], [ false, %else12 ]
  br i1 %regval14, label %then15, label %else16

then15:                                           ; preds = %endif13
  call void @avra_rc_retain(ptr %6)
  br label %endif17

else16:                                           ; preds = %endif13
  br label %endif17

endif17:                                          ; preds = %else16, %then15
  %regval18 = phi ptr [ %6, %then15 ], [ null, %else16 ]
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval18
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eblock_scope"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eopen_overlay"(ptr %0)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %4 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eblock_body"(ptr %0, ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %0)
  %5 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eclose_overlay"(ptr %0)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %5
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eblock_body"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eresolve_stmts"(ptr %0, i1 true, ptr %1)
  %cmp = icmp ne ptr %2, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %4 = call ptr @avra_insist(ptr %2)
  %5 = call i64 @avra_array_get(ptr %4, i64 0)
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ewalk"(ptr %0, i64 %5)
  call void @avra_rc_release(ptr %4)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Euse_name"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Emet"(ptr %0, i64 %1)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %4)
  %5 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Erefused_name"(ptr %0, ptr %2, ptr %4)
  br i1 %5, label %then1, label %else2

postret:                                          ; No predecessors!
  br label %endif

then1:                                            ; preds = %endif
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else2:                                            ; preds = %endif
  br label %endif3

endif3:                                           ; preds = %else2, %postret4
  %regval5 = phi i64 [ 0, %postret4 ], [ 0, %else2 ]
  %6 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %6 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %7 = call ptr @"av_$40std$2Eavrac$2Efeatures$2EFileView$2Eorigin_of"(ptr %boxed, i64 %1)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %8 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Evalue_binding"(ptr %0, ptr %2, ptr %7)
  %cmp = icmp ne ptr %8, null
  br i1 %cmp, label %then6, label %else7

postret4:                                         ; No predecessors!
  br label %endif3

then6:                                            ; preds = %endif3
  %9 = call ptr @avra_insist(ptr %8)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %10 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ebind_use"(ptr %0, i64 %1, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %11 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enote_mut_seat"(ptr %0, i64 %1, ptr %9)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %9)
  %12 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enote_settled_seat"(ptr %0, i64 %1, ptr %9)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else7:                                            ; preds = %endif3
  br label %endif8

endif8:                                           ; preds = %else7, %postret9
  %regval10 = phi i64 [ 0, %postret9 ], [ 0, %else7 ]
  call void @avra_rc_retain(ptr %0)
  %13 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eloc_of"(ptr %0, i64 %1)
  %14 = call i64 @avra_streq(ptr %2, ptr getelementptr inbounds (i8, ptr @.str.103, i64 16))
  %b = icmp ne i64 %14, 0
  br i1 %b, label %then11, label %else12

postret9:                                         ; No predecessors!
  call void @avra_rc_release(ptr %9)
  br label %endif8

then11:                                           ; preds = %endif8
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %13)
  %15 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eunbound_pronoun"(ptr %0, ptr %13)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.103, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %15

else12:                                           ; preds = %endif8
  br label %endif13

endif13:                                          ; preds = %else12, %postret14
  %regval15 = phi i64 [ 0, %postret14 ], [ 0, %else12 ]
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %16 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %2, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %16)
  %17 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Ehidden_def"(ptr %0, ptr %16)
  br i1 %17, label %then16, label %else17

postret14:                                        ; No predecessors!
  br label %endif13

then16:                                           ; preds = %endif13
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %13)
  %18 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eruntime_binding"(ptr %0, ptr %2, ptr %13)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.103, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %18

else17:                                           ; preds = %endif13
  br label %endif18

endif18:                                          ; preds = %else17, %postret19
  %regval20 = phi i64 [ 0, %postret19 ], [ 0, %else17 ]
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %7)
  %19 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %2, ptr %7)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %19)
  %20 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elater_def"(ptr %0, ptr %19)
  %cmp21 = icmp ne ptr %20, null
  br i1 %cmp21, label %then22, label %else23

postret19:                                        ; No predecessors!
  br label %endif18

then22:                                           ; preds = %endif18
  %21 = call ptr @avra_insist(ptr %20)
  %22 = call i64 @avra_array_get(ptr %21, i64 0)
  call void @avra_rc_retain(ptr %0)
  %23 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Estmt_loc"(ptr %0, i64 %22)
  %24 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push_owned(ptr %24, ptr getelementptr inbounds (i8, ptr @.str.104, i64 16))
  call void @avra_array_push_owned(ptr %24, ptr %23)
  %25 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push_owned(ptr %25, ptr %24)
  %26 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %26, ptr getelementptr inbounds (i8, ptr @.str.106, i64 16))
  call void @avra_array_push_owned(ptr %26, ptr %2)
  call void @avra_array_push_owned(ptr %26, ptr getelementptr inbounds (i8, ptr @.str.107, i64 16))
  %27 = call ptr @avra_str_join(ptr %26, ptr getelementptr inbounds (i8, ptr @.str.108, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.105, i64 16))
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %27)
  %28 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Eerror_at"(ptr getelementptr inbounds (i8, ptr @.str.105, i64 16), ptr %13, ptr %27)
  call void @avra_rc_retain(ptr %28)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.109, i64 16))
  %29 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Epointed"(ptr %28, ptr getelementptr inbounds (i8, ptr @.str.109, i64 16))
  %30 = call ptr @avra_array_get_owned(ptr %29, i64 0)
  %31 = call ptr @avra_array_get_owned(ptr %29, i64 1)
  %32 = call ptr @avra_array_get_owned(ptr %29, i64 2)
  %33 = call ptr @avra_array_get_owned(ptr %29, i64 4)
  %34 = call i64 @avra_array_get(ptr %29, i64 6)
  %boxed25 = inttoptr i64 %34 to ptr
  %35 = call ptr @avra_array_sized(i64 7)
  call void @avra_array_push_owned(ptr %35, ptr %30)
  call void @avra_array_push_owned(ptr %35, ptr %31)
  call void @avra_array_push_owned(ptr %35, ptr %32)
  call void @avra_array_push_owned(ptr %35, ptr %25)
  call void @avra_array_push_owned(ptr %35, ptr %33)
  call void @avra_array_push_owned(ptr %35, ptr getelementptr inbounds (i8, ptr @.str.110, i64 16))
  call void @avra_array_push_owned(ptr %35, ptr %boxed25)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %35)
  %36 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %35)
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.110, i64 16))
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.109, i64 16))
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.108, i64 16))
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.107, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.106, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.105, i64 16))
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.104, i64 16))
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.103, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0

else23:                                           ; preds = %endif18
  br label %endif24

endif24:                                          ; preds = %else23, %postret26
  %regval27 = phi i64 [ 0, %postret26 ], [ 0, %else23 ]
  %37 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.112, i64 16))
  call void @avra_array_push_owned(ptr %37, ptr %2)
  call void @avra_array_push_owned(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.113, i64 16))
  %38 = call ptr @avra_str_join(ptr %37, ptr getelementptr inbounds (i8, ptr @.str.114, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.111, i64 16))
  call void @avra_rc_retain(ptr %13)
  call void @avra_rc_retain(ptr %38)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.115, i64 16))
  %39 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.111, i64 16), ptr %13, ptr %38, ptr getelementptr inbounds (i8, ptr @.str.115, i64 16), ptr null)
  %40 = call ptr @avra_array_get_owned(ptr %0, i64 5)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %39)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %40)
  %41 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Esuggested"(ptr %0, ptr %39, i64 %1, ptr %2, ptr %40)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %41)
  %42 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %41)
  call void @avra_rc_release(ptr %41)
  call void @avra_rc_release(ptr %40)
  call void @avra_rc_release(ptr %39)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.115, i64 16))
  call void @avra_rc_release(ptr %38)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.114, i64 16))
  call void @avra_rc_release(ptr %37)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.113, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.112, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.111, i64 16))
  call void @avra_rc_release(ptr %20)
  call void @avra_rc_release(ptr %19)
  call void @avra_rc_release(ptr %16)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.103, i64 16))
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %42

postret26:                                        ; No predecessors!
  call void @avra_rc_release(ptr %35)
  call void @avra_rc_release(ptr %33)
  call void @avra_rc_release(ptr %32)
  call void @avra_rc_release(ptr %31)
  call void @avra_rc_release(ptr %30)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.110, i64 16))
  call void @avra_rc_release(ptr %29)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.109, i64 16))
  call void @avra_rc_release(ptr %28)
  call void @avra_rc_release(ptr %27)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.108, i64 16))
  call void @avra_rc_release(ptr %26)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.107, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.106, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.105, i64 16))
  call void @avra_rc_release(ptr %25)
  call void @avra_rc_release(ptr %24)
  call void @avra_rc_release(ptr %23)
  call void @avra_rc_release(ptr %21)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.104, i64 16))
  br label %endif24
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elater_def"(ptr %0, ptr %1) {
entry:
  %slot1 = alloca i64, align 8
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %2 = call i64 @avra_array_get(ptr %0, i64 13)
  %boxed = inttoptr i64 %2 to ptr
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_sized(i64 3)
  call void @avra_array_push(ptr %3, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l1408" to i64))
  call void @avra_array_push_owned(ptr %3, ptr %1)
  call void @avra_array_push_owned(ptr %3, ptr %boxed)
  %4 = call i64 @avra_array_get(ptr %3, i64 0)
  %5 = call ptr @avra_array_get_owned(ptr %0, i64 4)
  %6 = call i64 @avra_array_len(ptr %5)
  store i64 0, ptr %slot1, align 8
  br label %lhead

lhead:                                            ; preds = %endif, %entry
  %ld = load i64, ptr %slot1, align 8
  %cmp = icmp slt i64 %ld, %6
  br i1 %cmp, label %lbody, label %lexit

lexit:                                            ; preds = %lhead
  %ld4 = load ptr, ptr %slot, align 8
  call void @avra_rc_retain(ptr %ld4)
  %cmp5 = icmp ne ptr %ld4, null
  br i1 %cmp5, label %then6, label %else7

lbody:                                            ; preds = %lhead
  %ld2 = load i64, ptr %slot1, align 8
  %7 = call ptr @avra_array_get_owned(ptr %5, i64 %ld2)
  call void @avra_rc_retain(ptr %3)
  call void @avra_rc_retain(ptr %7)
  %cast = inttoptr i64 %4 to ptr
  %8 = call i1 %cast(ptr %3, ptr %7)
  br i1 %8, label %then, label %else

then:                                             ; preds = %lbody
  call void @avra_rc_retain(ptr %7)
  call void @avra_cell_release(ptr %slot)
  store ptr %7, ptr %slot, align 8
  store i64 %6, ptr %slot1, align 8
  br label %endif

else:                                             ; preds = %lbody
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  %ld3 = load i64, ptr %slot1, align 8
  %add = add i64 %ld3, 1
  store i64 %add, ptr %slot1, align 8
  call void @avra_rc_release(ptr %7)
  br label %lhead

then6:                                            ; preds = %lexit
  %9 = call i64 @avra_array_get(ptr %ld4, i64 1)
  %10 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %10, i64 %9)
  br label %endif8

else7:                                            ; preds = %lexit
  call void @avra_rc_retain(ptr null)
  br label %endif8

endif8:                                           ; preds = %else7, %then6
  %regval9 = phi ptr [ %10, %then6 ], [ null, %else7 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld4)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %regval9
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l1408"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %boxed = inttoptr i64 %2 to ptr
  %3 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed1 = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_streq(ptr %boxed, ptr %boxed1)
  %b = icmp ne i64 %4, 0
  br i1 %b, label %then, label %else

then:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %0, i64 2)
  %boxed2 = inttoptr i64 %5 to ptr
  %6 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %boxed2)
  %7 = call i1 @"av_$40std$2Eavrac$2Ecore$2ESideTable$2Eget$2415"(ptr %boxed2, i64 %6)
  %not = xor i1 %7, true
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i1 [ %not, %then ], [ false, %else ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eunbound_pronoun"(ptr %0, ptr %1) {
entry:
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.116, i64 16))
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.117, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.118, i64 16))
  call void @avra_rc_retain(ptr getelementptr inbounds (i8, ptr @.str.119, i64 16))
  %2 = call ptr @"av_$40std$2Eavrac$2Ediagnostics$2Erefusal"(ptr getelementptr inbounds (i8, ptr @.str.116, i64 16), ptr %1, ptr getelementptr inbounds (i8, ptr @.str.117, i64 16), ptr getelementptr inbounds (i8, ptr @.str.118, i64 16), ptr getelementptr inbounds (i8, ptr @.str.119, i64 16))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eemit"(ptr %0, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.119, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.118, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.117, i64 16))
  call void @avra_rc_release(ptr getelementptr inbounds (i8, ptr @.str.116, i64 16))
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i64 %3
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enote_settled_seat"(ptr %0, i64 %1, ptr %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %2, i64 0)
  switch i64 %3, label %arm1 [
    i64 0, label %arm
  ]

arm:                                              ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %2, i64 1)
  call void @avra_rc_retain(ptr %0)
  %5 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_is_settled"(ptr %0, i64 %4)
  br i1 %5, label %then, label %else

arm1:                                             ; preds = %entry
  %6 = call i64 @"av_$40std$2Eavrac$2Efeatures$2Enothing"()
  br label %endswitch

endswitch:                                        ; preds = %arm1, %endif
  %regval2 = phi i64 [ 0, %endif ], [ %6, %arm1 ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 %regval2

then:                                             ; preds = %arm
  %7 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %7 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %8 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Emark_settled_read"(ptr %boxed, i64 %1)
  br label %endif

else:                                             ; preds = %arm
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  br label %endswitch
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Emark_settled_read"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_is_settled"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l814" to i64))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eat_seat"(ptr %0, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l814"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 1)
  %b = icmp ne i64 %2, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eat_seat"(ptr %0, i64 %1, ptr %2) {
entry:
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  %3 = call ptr @avra_array_get_owned(ptr %0, i64 11)
  call void @avra_rc_retain(ptr null)
  call void @avra_cell_release(ptr %slot)
  store ptr null, ptr %slot, align 8
  %4 = call i64 @avra_array_len(ptr %3)
  %cmp = icmp slt i64 0, %4
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  %sub = sub i64 %4, 1
  %5 = call ptr @avra_array_get_owned(ptr %3, i64 %sub)
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
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret
  %regval5 = phi i64 [ 0, %postret ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %0)
  %6 = call i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_base"(ptr %0)
  %sub6 = sub i64 %1, %6
  %cmp7 = icmp sge i64 %sub6, 0
  br i1 %cmp7, label %then8, label %else9

postret:                                          ; No predecessors!
  br label %endif4

then8:                                            ; preds = %endif4
  %7 = call ptr @avra_insist(ptr %ld)
  %8 = call i64 @avra_array_len(ptr %7)
  %cmp11 = icmp slt i64 %sub6, %8
  call void @avra_rc_release(ptr %7)
  br label %endif10

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %then8
  %regval12 = phi i1 [ %cmp11, %then8 ], [ false, %else9 ]
  br i1 %regval12, label %then13, label %else14

then13:                                           ; preds = %endif10
  %9 = call ptr @avra_insist(ptr %ld)
  %10 = call i64 @avra_array_get(ptr %9, i64 %sub6)
  %boxed = inttoptr i64 %10 to ptr
  %11 = call i64 @avra_array_get(ptr %2, i64 0)
  call void @avra_rc_retain(ptr %2)
  call void @avra_rc_retain(ptr %boxed)
  %cast = inttoptr i64 %11 to ptr
  %12 = call i1 %cast(ptr %2, ptr %boxed)
  call void @avra_rc_release(ptr %9)
  br label %endif15

else14:                                           ; preds = %endif10
  br label %endif15

endif15:                                          ; preds = %else14, %then13
  %regval16 = phi i1 [ %12, %then13 ], [ false, %else14 ]
  call void @avra_cell_release(ptr %slot)
  call void @avra_rc_release(ptr %ld)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval16
}

define i64 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enote_mut_seat"(ptr %0, i64 %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_written_mut"(ptr %0, ptr %2)
  br i1 %3, label %then, label %else

then:                                             ; preds = %entry
  %4 = call i64 @avra_array_get(ptr %0, i64 1)
  %boxed = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed)
  %5 = call i64 @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Emark_mut_read"(ptr %boxed, i64 %1)
  br label %endif

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %then
  %regval = phi i64 [ 0, %then ], [ 0, %else ]
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i64 0
}

declare i64 @"av_$40std$2Eavrac$2Efeatures$2ENameFacts$2Emark_mut_read"(ptr, i64)

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_written_mut"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  switch i64 %2, label %arm2 [
    i64 0, label %arm
    i64 4, label %arm1
  ]

arm:                                              ; preds = %entry
  %3 = call i64 @avra_array_get(ptr %1, i64 1)
  call void @avra_rc_retain(ptr %0)
  %4 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_is_mut"(ptr %0, i64 %3)
  br label %endswitch

arm1:                                             ; preds = %entry
  %5 = call i64 @avra_array_get(ptr %1, i64 1)
  %6 = call i64 @avra_array_get(ptr %1, i64 2)
  call void @avra_rc_retain(ptr %0)
  %7 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elambda_seat_mut"(ptr %0, i64 %5, i64 %6)
  br label %endswitch

arm2:                                             ; preds = %entry
  br label %endswitch

endswitch:                                        ; preds = %arm2, %arm1, %arm
  %regval = phi i1 [ %4, %arm ], [ %7, %arm1 ], [ false, %arm2 ]
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %regval
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elambda_seat_mut"(ptr %0, i64 %1, i64 %2) {
entry:
  %3 = call i64 @avra_array_get(ptr %0, i64 0)
  %boxed = inttoptr i64 %3 to ptr
  %4 = call i64 @avra_array_get(ptr %boxed, i64 1)
  %boxed1 = inttoptr i64 %4 to ptr
  call void @avra_rc_retain(ptr %boxed1)
  %5 = call ptr @"av_$40std$2Eavrac$2Ecore$2ENodeStore$2Elambda_parts"(ptr %boxed1, i64 %1)
  %cmp = icmp ne ptr %5, null
  %not = xor i1 %cmp, true
  br i1 %not, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i1 false

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  %6 = call ptr @avra_insist(ptr %5)
  %7 = call i64 @avra_array_get(ptr %6, i64 0)
  %boxed2 = inttoptr i64 %7 to ptr
  %8 = call i64 @avra_array_get(ptr %boxed2, i64 %2)
  %boxed3 = inttoptr i64 %8 to ptr
  %9 = call i64 @avra_array_get(ptr %boxed3, i64 3)
  %boxed4 = inttoptr i64 %9 to ptr
  %10 = call i64 @avra_array_get(ptr %boxed4, i64 0)
  %b = icmp ne i64 %10, 0
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %0)
  ret i1 %b

postret:                                          ; No predecessors!
  br label %endif
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eseat_is_mut"(ptr %0, i64 %1) {
entry:
  %2 = call ptr @avra_array_sized(i64 1)
  call void @avra_array_push(ptr %2, i64 ptrtoint (ptr @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l808" to i64))
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %3 = call i1 @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Eat_seat"(ptr %0, i64 %1, ptr %2)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %0)
  ret i1 %3
}

define i1 @"av_$40std$2Eavrac$2Elanguage$2Eresolve$24l808"(ptr %0, ptr %1) {
entry:
  %2 = call i64 @avra_array_get(ptr %1, i64 0)
  %b = icmp ne i64 %2, 0
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret i1 %b
}

define ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Evalue_binding"(ptr %0, ptr %1, ptr %2) {
entry:
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %3 = call ptr @"av_$40std$2Eavrac$2Elanguage$2Ekeyed"(ptr %1, ptr %2)
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %3)
  %4 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Elocal_binding"(ptr %0, ptr %3)
  %cmp = icmp ne ptr %4, null
  br i1 %cmp, label %then, label %else

then:                                             ; preds = %entry
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %4

else:                                             ; preds = %entry
  br label %endif

endif:                                            ; preds = %else, %postret
  %regval = phi i64 [ 0, %postret ], [ 0, %else ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %2)
  %5 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Enames_in"(ptr %0, ptr %2)
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %1)
  %6 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Etype_decl"(ptr %5, ptr %1)
  %cmp1 = icmp ne ptr %6, null
  br i1 %cmp1, label %then2, label %else3

postret:                                          ; No predecessors!
  br label %endif

then2:                                            ; preds = %endif
  %7 = call ptr @avra_insist(ptr %6)
  %8 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %8, i64 7)
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

else3:                                            ; preds = %endif
  br label %endif4

endif4:                                           ; preds = %else3, %postret5
  %regval6 = phi i64 [ 0, %postret5 ], [ 0, %else3 ]
  call void @avra_rc_retain(ptr %5)
  call void @avra_rc_retain(ptr %1)
  %9 = call ptr @"av_$40std$2Eavrac$2Efeatures$2ENamespace$2Efn_decl"(ptr %5, ptr %1)
  %cmp7 = icmp ne ptr %9, null
  br i1 %cmp7, label %then8, label %else9

postret5:                                         ; No predecessors!
  call void @avra_rc_release(ptr %8)
  call void @avra_rc_release(ptr %7)
  br label %endif4

then8:                                            ; preds = %endif4
  %10 = call ptr @avra_insist(ptr %9)
  %11 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %11, i64 7)
  call void @avra_array_push_owned(ptr %11, ptr %10)
  call void @avra_rc_release(ptr %10)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %11

else9:                                            ; preds = %endif4
  br label %endif10

endif10:                                          ; preds = %else9, %postret11
  %regval12 = phi i64 [ 0, %postret11 ], [ 0, %else9 ]
  call void @avra_rc_retain(ptr %0)
  call void @avra_rc_retain(ptr %1)
  call void @avra_rc_retain(ptr %2)
  %12 = call ptr @"av_$40std$2Eavrac$2Elanguage$2EResolveCx$2Egenerated_named"(ptr %0, ptr %1, ptr %2)
  %cmp13 = icmp ne ptr %12, null
  %not = xor i1 %cmp13, true
  br i1 %not, label %then14, label %else15

postret11:                                        ; No predecessors!
  call void @avra_rc_release(ptr %11)
  call void @avra_rc_release(ptr %10)
  br label %endif10

then14:                                           ; preds = %endif10
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr null

else15:                                           ; preds = %endif10
  br label %endif16

endif16:                                          ; preds = %else15, %postret17
  %regval18 = phi i64 [ 0, %postret17 ], [ 0, %else15 ]
  %13 = call ptr @avra_insist(ptr %12)
  %14 = call ptr @avra_array_sized(i64 2)
  call void @avra_array_push(ptr %14, i64 7)
  call void @avra_array_push_owned(ptr %14, ptr %13)
  call void @avra_rc_release(ptr %13)
  call void @avra_rc_release(ptr %12)
  call void @avra_rc_release(ptr %9)
  call void @avra_rc_release(ptr %6)
  call void @avra_rc_release(ptr %5)
  call void @avra_rc_release(ptr %4)
  call void @avra_rc_release(ptr %3)
  call void @avra_rc_release(ptr %2)
  call void @avra_rc_release(ptr %1)
  call void @avra_rc_release(ptr %0)
  ret ptr %14

postret17:                                        ; No predecessors!
  br label %endif16
}
