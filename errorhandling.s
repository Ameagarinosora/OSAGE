.ifndef OSAGE_ERRORHANDLING_S
.set OSAGE_ERRORHANDLING_S, 1

.macro try_sys err_label, stmt:vararg
    \stmt
    cmp     x0, #0
    b.lt    \err_label
.endm

.macro _try_prop_h id
    b.lt    .Lfr\id
.endm

.macro try_prop stmt:vararg
    \stmt
    cmp     x0, #0
    .altmacro
    _try_prop_h %__fnid
    .noaltmacro
.endm

.macro try_cf err_label, stmt:vararg
    \stmt
    b.cs    \err_label
.endm

.macro _try_cf_prop_h id
    b.cs    .Lfr\id
.endm

.macro try_cf_prop stmt:vararg
    \stmt
    .altmacro
    _try_cf_prop_h %__fnid
    .noaltmacro
.endm

.macro try_null err_label, stmt:vararg
    \stmt
    cbz     x0, \err_label
.endm

.macro _try_null_prop_h id
    cbz     x0, .Lfr\id
.endm

.macro try_null_prop stmt:vararg
    \stmt
    .altmacro
    _try_null_prop_h %__fnid
    .noaltmacro
.endm

.macro try_cond cond, err_label, stmt:vararg
    \stmt
    b.\cond \err_label
.endm

.macro _try_cond_prop_h cond, id
    b.\cond .Lfr\id
.endm

.macro try_cond_prop cond, stmt:vararg
    \stmt
    .altmacro
    _try_cond_prop_h \cond, %__fnid
    .noaltmacro
.endm

.macro get_errno dst, src=x0
    neg     \dst, \src
.endm

.endif