.ifndef OSAGE_FUNC_S
.set OSAGE_FUNC_S, 1

.macro _req_ name, num
    \name .req x\num
.endm
.macro _unreq_ name
    .unreq \name
.endm

.set __fnid, 0
.set __fn_open, 0
.set __fn_n, 0
.set __fn_np, 0
.set __fn_loc, 0
.set __fn_i, 0
.set __fn_save, 0
.set __fn_size, 16
.set __ci, 0

.macro _mov_param_ reg, idx
    mov     \reg, x\idx
.endm
.macro _mov_arg_ idx, src
    mov     x\idx, \src
.endm
.macro _ret_h id
    b       .Lfr\id
.endm

.macro _fn_pro_ size, save
    stp     x29, x30, [sp, #-\size]!
    mov     x29, sp
    .if \save >= 2
        stp     x19, x20, [sp, #16]
    .endif
    .if \save >= 4
        stp     x21, x22, [sp, #32]
    .endif
    .if \save >= 6
        stp     x23, x24, [sp, #48]
    .endif
    .if \save >= 8
        stp     x25, x26, [sp, #64]
    .endif
    .if \save >= 10
        stp     x27, x28, [sp, #80]
    .endif
.endm

.macro _endfn_h id, save, size
.Lfr\id:
    .if \save >= 2
        ldp     x19, x20, [sp, #16]
    .endif
    .if \save >= 4
        ldp     x21, x22, [sp, #32]
    .endif
    .if \save >= 6
        ldp     x23, x24, [sp, #48]
    .endif
    .if \save >= 8
        ldp     x25, x26, [sp, #64]
    .endif
    .if \save >= 10
        ldp     x27, x28, [sp, #80]
    .endif
    ldp     x29, x30, [sp], #\size
    ret
.endm

.macro fn name, vars:vararg
    .if __fn_open
        .error "fn inside another fn (missing endfn?)"
    .endif
    .set __fn_open, 1
    .set __fnid, __fnid+1
    .set __fn_n, 0
    .set __fn_np, 0
    .set __fn_loc, 0
    .ifnb \vars
    .irp v, \vars
        .ifc \v, local
            .set __fn_loc, 1
        .else
            .if __fn_n >= 10
                .error "too many variables (max 10: x19-x28)"
            .endif
            .altmacro
            _req_   \v, %(__fn_n+19)
            .noaltmacro
            .set __fn_n, __fn_n+1
            .if __fn_loc == 0
                .set __fn_np, __fn_np+1
            .endif
        .endif
    .endr
    .endif
    .if __fn_np > 8
        .error "at most 8 parameters (x0-x7); put extra names after 'local'"
    .endif
    .set __fn_save, (__fn_n+1) & ~1
    .set __fn_size, 16 + 8*__fn_save
    .global \name
\name:
    .altmacro
    _fn_pro_ %__fn_size, %__fn_save
    .noaltmacro
    .set __fn_i, 0
    .ifnb \vars
    .irp v, \vars
        .ifnc \v, local
            .if __fn_i < __fn_np
                .altmacro
                _mov_param_ \v, %__fn_i
                .noaltmacro
            .endif
            .set __fn_i, __fn_i+1
        .endif
    .endr
    .endif
    .macro _fn_done_
        .ifnb \vars
        .irp v, \vars
            .ifnc \v, local
                _unreq_ \v
            .endif
        .endr
        .endif
    .endm
.endm

.macro return val
    .if __fn_open == 0
        .error "return outside of fn"
    .endif
    .ifnb \val
        mov     x0, \val
    .endif
    .altmacro
    _ret_h  %__fnid
    .noaltmacro
.endm

.macro endfn
    .if __fn_open == 0
        .error "endfn without fn"
    .endif
    .if __sp != 0
        .error "unclosed if/while/for inside this function"
    .endif
    .altmacro
    _endfn_h %__fnid, %__fn_save, %__fn_size
    .noaltmacro
    _fn_done_
    .purgem _fn_done_
    .set __fn_open, 0
.endm

.macro call name, args:vararg
    .set __ci, 0
    .ifnb \args
    .irp a, \args
        .altmacro
        _mov_arg_ %__ci, \a
        .noaltmacro
        .set __ci, __ci+1
    .endr
    .endif
    .if __ci > 8
        .error "at most 8 arguments"
    .endif
    bl      \name
.endm

.endif