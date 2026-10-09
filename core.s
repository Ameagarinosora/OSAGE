.ifndef OSAGE_CORE_S
.set OSAGE_CORE_S, 1

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

.macro preserve reg1, reg2
    stp     \reg1, \reg2, [sp, #-16]!
.endm

.macro restore reg1, reg2
    ldp     \reg1, \reg2, [sp], #16
.endm

.macro unreachable
    brk #0
.endm

.macro set_include reg, bit
    orr \reg, \reg, #(1 << \bit)
.endm

.macro set_exclude reg, bit
    bic \reg, \reg, #(1 << \bit)
.endm

.macro set_toggle reg, bit
    eor \reg, \reg, #(1 << \bit)
.endm

.macro tst_bit reg, bit
    tst \reg, #(1 << \bit)
.endm

.macro pass_ref param_reg, symbol
    lea \param_reg, \symbol
.endm

.macro ref_get dst_reg, ptr_reg, offset=#0
    ldr \dst_reg, [\ptr_reg, \offset]
.endm

.macro ref_set ptr_reg, src_reg, offset=#0
    str \src_reg, [\ptr_reg, \offset]
.endm

.macro ref_add ptr_reg, val, scratch_reg=x1
    ldr \scratch_reg, [\ptr_reg]
    add \scratch_reg, \scratch_reg, \val
    str \scratch_reg, [\ptr_reg]
.endm

.macro routine name
    .pushsection .text.\name,"ax",%progbits
    .balign 4
\name:
.endm

.macro endroutine
    .popsection
.endm
.macro imm reg, value
    movz    \reg, #((\value) & 0xffff)
    .if ((\value) >> 16) & 0xffff
        movk    \reg, #(((\value) >> 16) & 0xffff), lsl #16
    .endif
    .if ((\value) >> 32) & 0xffff
        movk    \reg, #(((\value) >> 32) & 0xffff), lsl #32
    .endif
    .if ((\value) >> 48) & 0xffff
        movk    \reg, #(((\value) >> 48) & 0xffff), lsl #48
    .endif
.endm

.endif