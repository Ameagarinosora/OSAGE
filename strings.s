.ifndef OSAGE_STRINGS_S
.set OSAGE_STRINGS_S, 1

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
    mov     x1, \prec
    bl      __osage_flt2str
.endm

.macro strlen dst, src
    .ifnc \src, x0
        mov     x0, \src
    .endif
    bl      __osage_strlen
    .ifnc \dst, x0
        mov     \dst, x0
    .endif
.endm

routine __osage_streq
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
endroutine

routine __osage_chomp
    cmp     x17, #0
    b.le    .Lchomp_done
    sub     x17, x17, #1
    ldrb    w2, [x16, x17]
    cmp     w2, #10
    b.ne    .Lchomp_done
    strb    wzr, [x16, x17]
.Lchomp_done:
    ret
endroutine

routine __osage_strlen
    mov     x1, x0
.Lslen_loop:
    ldrb    w2, [x1], #1
    cbnz    w2, .Lslen_loop
    sub     x0, x1, x0
    sub     x0, x0, #1
    ret
endroutine

routine __osage_str2int
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
endroutine

routine __osage_int2str
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
endroutine

routine __osage_str2flt
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
endroutine

routine __osage_flt2str
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
endroutine

.endif