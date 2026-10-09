.ifndef OSAGE_UNIT_S
.set OSAGE_UNIT_S, 1

.macro uses name
    .ifndef __uses_\name
        .set __uses_\name, 1
        .include "\name\().inc"
    .endif
.endm

.macro export names:vararg
    .irp n, \names
        .global \n
    .endr
.endm

.macro initialization name
    .pushsection osage_init,"aw",%progbits
    .balign 8
    .quad __init_\name
    .popsection
    routine __init_\name
    stp     x29, x30, [sp, #-16]!
.endm
.macro endinit
    ldp     x29, x30, [sp], #16
    ret
    endroutine
.endm

.macro run_inits
    .pushsection osage_init,"aw",%progbits
    .balign 8
    .quad 0
    .popsection
    stp     x19, x20, [sp, #-16]!
    lea     x19, __start_osage_init
    lea     x20, __stop_osage_init
.Lri_l\@:
    cmp     x19, x20
    b.hs    .Lri_d\@
    ldr     x0, [x19], #8
    cbz     x0, .Lri_l\@
    blr     x0
    b       .Lri_l\@
.Lri_d\@:
    ldp     x19, x20, [sp], #16
.endm

.endif