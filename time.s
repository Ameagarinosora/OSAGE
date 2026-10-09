.ifndef OSAGE_TIME_S
.set OSAGE_TIME_S, 1

.macro ticks dst
    mrs     \dst, cntvct_el0
.endm

.macro tick_freq dst
    mrs     \dst, cntfrq_el0
.endm

.macro _clock_get id, sec_reg, nsec_reg
    sub     sp, sp, #16
    mov     x0, #\id
    mov     x1, sp
    mov     x8, #113
    svc     #0
    ldr     \sec_reg,  [sp]
    ldr     \nsec_reg, [sp, #8]
    add     sp, sp, #16
.endm

.macro time_now sec_reg, nsec_reg
    _clock_get 0, \sec_reg, \nsec_reg
.endm

.macro time_mono sec_reg, nsec_reg
    _clock_get 1, \sec_reg, \nsec_reg
.endm

.macro time_ms dst
    _clock_get 1, x16, x17
    mov     x0, #1000
    mul     x16, x16, x0
    imm     x0, 1000000
    udiv    x17, x17, x0
    add     \dst, x16, x17
.endm

.macro elapsed_ms dst, start
    mov     x15, \start
    time_ms x0
    sub     \dst, x0, x15
.endm

.macro delay_ms ms
    mov     x17, \ms
    mrs     x16, cntfrq_el0
    mul     x17, x17, x16
    mov     x16, #1000
    udiv    x17, x17, x16
    mrs     x16, cntvct_el0
    add     x17, x17, x16
.Ldly\@:
    mrs     x16, cntvct_el0
    cmp     x16, x17
    b.lo    .Ldly\@
.endm

.macro sleep_ms ms
    mov     x16, \ms
    sub     sp, sp, #16
    mov     x17, #1000
    udiv    x0, x16, x17
    msub    x1, x0, x17, x16
    imm     x17, 1000000
    mul     x1, x1, x17
    stp     x0, x1, [sp]
    mov     x0, sp
    mov     x1, #0
    mov     x8, #101
    svc     #0
    add     sp, sp, #16
.endm

.macro sleep_next_sec
    sub     sp, sp, #32
    mov     x0, #0
    mov     x1, sp
    mov     x8, #113
    svc     #0
    ldr     x2, [sp, #8]
    imm     x3, 1000000000
    sub     x3, x3, x2
    str     xzr, [sp, #16]
    str     x3, [sp, #24]
    add     x0, sp, #16
    mov     x1, #0
    mov     x8, #101
    svc     #0
    add     sp, sp, #32
.endm

.macro time_hms h, m, s, epoch, tz=#0
    mov     x17, \tz
    add     x16, \epoch, x17
    imm     x17, 86400
    udiv    \h, x16, x17
    msub    x16, \h, x17, x16
    mov     x17, #3600
    udiv    \h, x16, x17
    msub    x16, \h, x17, x16
    mov     x17, #60
    udiv    \m, x16, x17
    msub    \s, \m, x17, x16
.endm

.macro time_weekday dst, epoch
    mov     x16, \epoch
    imm     x17, 86400
    udiv    x16, x16, x17
    add     x16, x16, #4
    mov     x17, #7
    udiv    \dst, x16, x17
    msub    \dst, \dst, x17, x16
.endm

.macro time_date y, m, d, epoch
    mov     x0, \epoch
    bl      __osage_civil
    mov     \y, x0
    mov     \m, x1
    mov     \d, x2
.endm

routine __osage_civil
    imm     x9, 86400
    udiv    x0, x0, x9
    imm     x9, 719468
    add     x0, x0, x9
    imm     x9, 146097
    udiv    x1, x0, x9
    msub    x2, x1, x9, x0
    mov     x9, #1460
    udiv    x3, x2, x9
    mov     x9, #36524
    udiv    x4, x2, x9
    imm     x9, 146096
    udiv    x5, x2, x9
    sub     x3, x2, x3
    add     x3, x3, x4
    sub     x3, x3, x5
    mov     x9, #365
    udiv    x3, x3, x9
    mov     x9, #400
    madd    x0, x1, x9, x3
    mov     x9, #365
    mul     x4, x3, x9
    lsr     x5, x3, #2
    add     x4, x4, x5
    mov     x9, #100
    udiv    x5, x3, x9
    sub     x4, x4, x5
    sub     x4, x2, x4
    mov     x9, #5
    mul     x5, x4, x9
    add     x5, x5, #2
    mov     x9, #153
    udiv    x5, x5, x9
    mul     x6, x5, x9
    add     x6, x6, #2
    mov     x9, #5
    udiv    x6, x6, x9
    sub     x2, x4, x6
    add     x2, x2, #1
    cmp     x5, #10
    add     x7, x5, #3
    sub     x6, x5, #9
    csel    x1, x7, x6, lo
    cmp     x1, #2
    cinc    x0, x0, ls
    ret
endroutine

.endif