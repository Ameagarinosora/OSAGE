.ifndef OSAGE_RAND_S
.set OSAGE_RAND_S, 1

.pushsection .data.__osage_rng_state,"aw",%progbits
.balign 8
.weak __osage_rng_state
__osage_rng_state: .quad 0xbef0ace1
.popsection

.macro rand_seed
    lea     x0, __osage_rng_state
    mov     x1, #8
    mov     x2, #0
    mov     x8, #278
    svc     #0
    lea     x16, __osage_rng_state
    ldr     x17, [x16]
    orr     x17, x17, #1
    str     x17, [x16]
.endm

.macro rand dst
    bl      __osage_rand
    .ifnc \dst, x0
        mov     \dst, x0
    .endif
.endm

.macro rand_range dst, min, max
    mov     x16, \min
    mov     x17, \max
    bl      __osage_rand
    sub     x17, x17, x16
    add     x17, x17, #1
    udiv    x1, x0, x17
    msub    x0, x1, x17, x0
    add     \dst, x0, x16
.endm

routine __osage_rand
    lea     x1, __osage_rng_state
    ldr     x0, [x1]
    eor     x0, x0, x0, lsl #13
    eor     x0, x0, x0, lsr #7
    eor     x0, x0, x0, lsl #17
    str     x0, [x1]
    ret
endroutine

.endif