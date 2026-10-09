.ifndef OSAGE_ARCH_S
.set OSAGE_ARCH_S, 1

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
.macro _beq target
    b.eq    \target
.endm
.macro _alias name, reg
    \name .req \reg
.endm
.macro _unalias name
    .unreq \name
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

.endif