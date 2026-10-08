.ifndef __ARCH_TEST
.macro _cmp a, b
    cmp     \a, \b
.endm
.macro _b target
    b       \target
.endm
.macro _for_init reg, count
    mov     \reg, \count
.endm
.macro _for_test reg, target
    cbz     \reg, \target
.endm
.macro _for_step reg, target
    subs    \reg, \reg, #1
    b.ne    \target
.endm
.macro _bnot cond, target
    .ifc \cond, eq
        b.ne    \target
        .exitm
    .endif
    .ifc \cond, ne
        b.eq    \target
        .exitm
    .endif
    .ifc \cond, gt
        b.le    \target
        .exitm
    .endif
    .ifc \cond, ge
        b.lt    \target
        .exitm
    .endif
    .ifc \cond, lt
        b.ge    \target
        .exitm
    .endif
    .ifc \cond, le
        b.gt    \target
        .exitm
    .endif
    .ifc \cond, hi
        b.ls    \target
        .exitm
    .endif
    .ifc \cond, ls
        b.hi    \target
        .exitm
    .endif
    .ifc \cond, hs
        b.lo    \target
        .exitm
    .endif
    .ifc \cond, cs
        b.cc    \target
        .exitm
    .endif
    .ifc \cond, lo
        b.hs    \target
        .exitm
    .endif
    .ifc \cond, cc
        b.cs    \target
        .exitm
    .endif
    .ifc \cond, mi
        b.pl    \target
        .exitm
    .endif
    .ifc \cond, pl
        b.mi    \target
        .exitm
    .endif
    .ifc \cond, vs
        b.vc    \target
        .exitm
    .endif
    .ifc \cond, vc
        b.vs    \target
        .exitm
    .endif
    .error "unknown condition: \cond"
.endm
.endif

.set __uid, 0
.set __sp,  0
.set __lp,  0

.macro _slot_ n, kind, id, el
    .set __kd\n, \kind
    .set __id\n, \id
    .set __el\n, \el
.endm
.macro _setel_ n, el
    .set __el\n, \el
.endm
.macro _setkd_ n, kind
    .set __kd\n, \kind
.endm
.macro _peek_ n
    .set __curkd, __kd\n
    .set __curid, __id\n
    .set __curel, __el\n
.endm
.macro _lpush_ n, id
    .set __lid\n, \id
.endm
.macro _lpeek_ n
    .set __curlid, __lid\n
.endm

.macro _push kind
    .set __uid, __uid+1
    .set __sp, __sp+1
    .altmacro
    _slot_ %__sp, \kind, %__uid, %__uid
    .noaltmacro
    .if \kind >= 3
        .set __lp, __lp+1
        .altmacro
        _lpush_ %__lp, %__uid
        .noaltmacro
    .endif
.endm

.macro _peek
    .if __sp == 0
        .error "block end without a matching opener"
    .endif
    .altmacro
    _peek_ %__sp
    .noaltmacro
.endm

.macro _pop
    .if __curkd >= 3
        .set __lp, __lp-1
    .endif
    .set __sp, __sp-1
.endm

.macro _expect lo, hi, name
    _peek
    .if (__curkd < \lo) || (__curkd > \hi)
        .error "\name does not match the open block"
    .endif
.endm

.macro _brfalse a, c, b, target
    .ifb \c
        _bnot   \a, \target
    .else
        .ifb \b
            .error "expected: a, cond, b"
        .endif
        _cmp    \a, \b
        _bnot   \c, \target
    .endif
.endm

.macro _if_h id, a, c, b
    _brfalse \a, \c, \b, .Lel\id
.endm
.macro if a, c, b
    _push   1
    .altmacro
    _if_h   %__uid, \a, \c, \b
    .noaltmacro
.endm

.macro _elif_h id, old, new, a, c, b
    _b      .Le\id
.Lel\old:
    _brfalse \a, \c, \b, .Lel\new
.endm
.macro elif a, c, b
    _expect 1, 1, "elif"
    .set __uid, __uid+1
    .altmacro
    _elif_h %__curid, %__curel, %__uid, \a, \c, \b
    _setel_ %__sp, %__uid
    .noaltmacro
.endm

.macro _else_h id, el
    _b      .Le\id
.Lel\el:
.endm
.macro else
    _expect 1, 1, "else"
    .altmacro
    _else_h %__curid, %__curel
    _setkd_ %__sp, 2
    .noaltmacro
.endm

.macro _endif_h id, el, kind
    .if \kind == 1
.Lel\el:
    .endif
.Le\id:
.endm
.macro endif
    _expect 1, 2, "endif"
    .altmacro
    _endif_h %__curid, %__curel, %__curkd
    .noaltmacro
    _pop
.endm

.macro _while_h id, a, c, b
.Lc\id:
    _brfalse \a, \c, \b, .Le\id
.endm
.macro while a, c, b
    _push   3
    .altmacro
    _while_h %__uid, \a, \c, \b
    .noaltmacro
.endm
.macro _endwhile_h id
    _b      .Lc\id
.Le\id:
.endm
.macro endwhile
    _expect 3, 3, "endwhile"
    .altmacro
    _endwhile_h %__curid
    .noaltmacro
    _pop
.endm

.macro _repeat_h id
.Lt\id:
.endm
.macro repeat
    _push   4
    .altmacro
    _repeat_h %__uid
    .noaltmacro
.endm
.macro _until_h id, a, c, b
.Lc\id:
    _brfalse \a, \c, \b, .Lt\id
.Le\id:
.endm
.macro until a, c, b
    _expect 4, 4, "until"
    .altmacro
    _until_h %__curid, \a, \c, \b
    .noaltmacro
    _pop
.endm

.macro _loop_h id
.Lc\id:
.endm
.macro loop
    _push   5
    .altmacro
    _loop_h %__uid
    .noaltmacro
.endm
.macro endloop
    _expect 5, 5, "endloop"
    .altmacro
    _endwhile_h %__curid
    .noaltmacro
    _pop
.endm

.macro _for_h id, reg, count
    _for_init \reg, \count
.Lt\id:
    _for_test \reg, .Le\id
.endm
.macro for reg, count
    _push   6
    .altmacro
    _for_h  %__uid, \reg, \count
    .noaltmacro
.endm
.macro _endfor_h id, reg
.Lc\id:
    _for_step \reg, .Lt\id
.Le\id:
.endm
.macro endfor reg
    _expect 6, 6, "endfor"
    .altmacro
    _endfor_h %__curid, \reg
    .noaltmacro
    _pop
.endm

.macro _brk_h id
    _b      .Le\id
.endm
.macro break
    .if __lp == 0
        .error "break outside of a loop"
    .endif
    .altmacro
    _lpeek_ %__lp
    _brk_h  %__curlid
    .noaltmacro
.endm
.macro _cont_h id
    _b      .Lc\id
.endm
.macro continue
    .if __lp == 0
        .error "continue outside of a loop"
    .endif
    .altmacro
    _lpeek_ %__lp
    _cont_h %__curlid
    .noaltmacro
.endm

.macro check_blocks
    .if __sp != 0
        .error "unclosed block: missing endif/endwhile/endfor/until/endloop"
    .endif
.endm

.macro push a, b
    .ifb \b
        str     \a, [sp, #-16]!
    .else
        stp     \a, \b, [sp, #-16]!
    .endif
.endm

.macro pop a, b
    .ifb \b
        ldr     \a, [sp], #16
    .else
        ldp     \a, \b, [sp], #16
    .endif
.endm

.macro lea reg, sym
    adrp    \reg, \sym
    add     \reg, \reg, :lo12:\sym
.endm

.macro buffer name, len
    .ifndef \name
        .pushsection .bss
        .balign 8
\name:
        .space \len
        .popsection
    .endif
.endm

.macro string name, text, nl
    .ifndef \name
        .pushsection .rodata
        .balign 8
\name:
        .ascii "\text"
        .ifnb \nl
            .ifc \nl, nl
                .byte 10
            .endif
        .endif
        .byte 0
        .set \name\()_len, . - \name - 1
        .popsection
    .endif
.endm

.macro stdout str, nl
    .pushsection .rodata
.Lstr\@:
    .ascii "\str"
    .ifnb \nl
        .ifc \nl, nl
            .byte 10
        .endif
    .endif
    .set .Llen\@, . - .Lstr\@
    .popsection
    stp     x0, x1, [sp, #-32]!
    stp     x2, x8, [sp, #16]
    mov     x0, #1
    lea     x1, .Lstr\@
    mov     x2, #.Llen\@
    mov     x8, #64
    svc     #0
    ldp     x2, x8, [sp, #16]
    ldp     x0, x1, [sp], #32
.endm

.macro putb buf, len
    stp     x0, x1, [sp, #-32]!
    stp     x2, x8, [sp, #16]

    .ifb \len
        mov     x2, #\buf\()_len
    .else
        mov     x2, \len
    .endif

    lea     x1, \buf
    mov     x0, #1
    mov     x8, #64
    svc     #0

    ldp     x2, x8, [sp, #16]
    ldp     x0, x1, [sp], #32
.endm

.macro stdin name, len
    stp     x1, x2, [sp, #-32]!
    str     x8, [sp, #16]
    mov     x0, #0
    lea     x1, \name
    mov     x2, #\len
    mov     x8, #63
    svc     #0
    ldr     x8, [sp, #16]
    ldp     x1, x2, [sp], #32
.endm

.macro puts_z reg
    stp     x0, x1, [sp, #-48]!
    stp     x2, x8, [sp, #16]
    stp     x9, x10, [sp, #32]
    mov     x9, \reg
    mov     x2, #0
.Lpz_l\@:
    ldrb    w10, [x9, x2]
    cbz     w10, .Lpz_d\@
    add     x2, x2, #1
    b       .Lpz_l\@
.Lpz_d\@:
    mov     x1, x9
    mov     x0, #1
    mov     x8, #64
    svc     #0
    ldp     x9, x10, [sp, #32]
    ldp     x2, x8, [sp, #16]
    ldp     x0, x1, [sp], #48
.endm

.macro getchar dst, addr
    ldrb    \dst, [\addr]
.endm

.macro sys_exit code=0
    mov     x0, #\code
    mov     x8, #93
    svc     #0
.endm

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

.macro chomp name
    lea     x16, \name
    mov     x17, x0
    bl      __osage_chomp
.endm

.macro streq a, b
    mov     x16, \a
    mov     x17, \b
    bl      __osage_streq
.endm

.macro streqs a, lit
    .pushsection .rodata
.Lsl\@:
    .asciz "\lit"
    .popsection
    mov     x16, \a
    lea     x17, .Lsl\@
    bl      __osage_streq
.endm

.macro str2int dst, addr
    mov     x0, \addr
    bl      __osage_str2int
    .ifnc \dst, x0
        mov     \dst, x0
    .endif
.endm

.macro int2str buf, val
    mov     x0, \val
    lea     x1, \buf
    bl      __osage_int2str
.endm

.macro str2flt ddst, addr
    mov     x0, \addr
    bl      __osage_str2flt
    .ifnc \ddst, d0
        fmov    \ddst, d0
    .endif
.endm

.macro flt2str buf, dsrc, prec=4
    .ifnc \dsrc, d0
        fmov    d0, \dsrc
    .endif
    lea     x0, \buf
    mov     x1, #\prec
    bl      __osage_flt2str
.endm

.pushsection .text

__osage_streq:
.Lseq_loop:
    ldrb    w11, [x16], #1
    ldrb    w12, [x17], #1
    cmp     w11, w12
    b.ne    .Lseq_mismatch
    cbnz    w11, .Lseq_loop
    mov     x0, #1
    ret
.Lseq_mismatch:
    mov     x0, #0
    ret

__osage_chomp:
    cmp     x17, #0
    b.le    .Lchomp_done
    sub     x17, x17, #1
    strb    wzr, [x16, x17]
.Lchomp_done:
    ret

__osage_str2int:
    mov     x1, x0
    mov     x0, #0
    mov     x2, #1

    ldrb    w3, [x1]
    cmp     w3, #45
    b.ne    .Ls2i_loop
    mov     x2, #-1
    add     x1, x1, #1

.Ls2i_loop:
    ldrb    w3, [x1], #1
    sub     w3, w3, #48
    cmp     w3, #9
    b.hi    .Ls2i_done
    mov     x4, #10
    mul     x0, x0, x4
    add     x0, x0, w3, uxtw
    b       .Ls2i_loop

.Ls2i_done:
    mul     x0, x0, x2
    ret

__osage_int2str:
    stp     x19, x20, [sp, #-64]!
    stp     x21, x30, [sp, #16]

    mov     x19, x1
    mov     x20, x1
    mov     x21, #10

    cmp     x0, #0
    b.ge    1f
    mov     w2, #45
    strb    w2, [x20], #1
    neg     x0, x0
1:
    add     x2, sp, #64
    mov     x3, x2
2:
    udiv    x4, x0, x21
    msub    x5, x4, x21, x0
    add     w5, w5, #48
    sub     x2, x2, #1
    strb    w5, [x2]
    mov     x0, x4
    cbnz    x0, 2b
3:
    cmp     x2, x3
    b.eq    4f
    ldrb    w5, [x2], #1
    strb    w5, [x20], #1
    b       3b
4:
    strb    wzr, [x20]
    sub     x0, x20, x19

    ldp     x21, x30, [sp, #16]
    ldp     x19, x20, [sp], #64
    ret

__osage_str2flt:
    mov     x1, x0
    fmov    d0, xzr
    mov     x2, #1

    ldrb    w3, [x1]
    cmp     w3, #45
    b.ne    .Ls2f_int
    mov     x2, #-1
    add     x1, x1, #1

.Ls2f_int:
    ldrb    w3, [x1], #1
    cmp     w3, #46
    b.eq    .Ls2f_frac_prep
    sub     w3, w3, #48
    cmp     w3, #9
    b.hi    .Ls2f_sign

    mov     x4, #10
    scvtf   d16, x4
    fmul    d0, d0, d16
    scvtf   d17, x3
    fadd    d0, d0, d17
    b       .Ls2f_int

.Ls2f_frac_prep:
    mov     x4, #10
    scvtf   d16, x4

.Ls2f_frac:
    ldrb    w3, [x1], #1
    sub     w3, w3, #48
    cmp     w3, #9
    b.hi    .Ls2f_sign

    scvtf   d17, x3
    fdiv    d17, d17, d16
    fadd    d0, d0, d17

    mov     x4, #10
    scvtf   d18, x4
    fmul    d16, d16, d18
    b       .Ls2f_frac

.Ls2f_sign:
    cmp     x2, #-1
    b.ne    .Ls2f_done
    fneg    d0, d0

.Ls2f_done:
    ret

__osage_flt2str:
    stp     x19, x20, [sp, #-80]!
    stp     x21, x30, [sp, #16]
    stp     d8, d9, [sp, #32]

    mov     x19, x0
    mov     x20, x0
    mov     x21, x1
    fmov    d8, d0

    fcmp    d8, #0.0
    b.ge    1f
    mov     w2, #45
    strb    w2, [x20], #1
    fneg    d8, d8
1:
    fcvtzs  x0, d8
    scvtf   d9, x0
    fsub    d9, d8, d9

    add     x2, sp, #80
    mov     x3, x2
    mov     x4, #10
2:
    udiv    x5, x0, x4
    msub    x6, x5, x4, x0
    add     w6, w6, #48
    sub     x2, x2, #1
    strb    w6, [x2]
    mov     x0, x5
    cbnz    x0, 2b
3:
    cmp     x2, x3
    b.eq    4f
    ldrb    w6, [x2], #1
    strb    w6, [x20], #1
    b       3b
4:
    mov     w2, #46
    strb    w2, [x20], #1

    cbz     x21, 6f
5:
    mov     x4, #10
    scvtf   d16, x4
    fmul    d9, d9, d16
    fcvtzs  x0, d9
    add     w6, w0, #48
    strb    w6, [x20], #1

    scvtf   d17, x0
    fsub    d9, d9, d17
    subs    x21, x21, #1
    b.ne    5b
6:
    strb    wzr, [x20]
    sub     x0, x20, x19

    ldp     d8, d9, [sp, #32]
    ldp     x21, x30, [sp, #16]
    ldp     x19, x20, [sp], #80
    ret

.popsection
