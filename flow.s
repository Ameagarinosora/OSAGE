.ifndef OSAGE_FLOW_S
.set OSAGE_FLOW_S, 1

.set __uid, 0
.set __sp,  0
.set __lp,  0
.set __bp,  0

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

.macro _bpush_ n, id
    .set __bid\n, \id
.endm
.macro _bpeek_ n
    .set __curbid, __bid\n
.endm

.macro _push kind
    .set __uid, __uid+1
    .set __sp, __sp+1
    .altmacro
    _slot_ %__sp, \kind, %__uid, %__uid
    .noaltmacro
    .if (\kind >= 3) && (\kind <= 6)
        .set __lp, __lp+1
        .altmacro
        _lpush_ %__lp, %__uid
        .noaltmacro
    .endif
    .if (\kind >= 3) && (\kind <= 7)
        .set __bp, __bp+1
        .altmacro
        _bpush_ %__bp, %__uid
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
    .if (__curkd >= 3) && (__curkd <= 6)
        .set __lp, __lp-1
    .endif
    .if (__curkd >= 3) && (__curkd <= 9)
        .set __bp, __bp-1
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
    _assert_callee \reg
    _push   6
    .altmacro
    _for_h  %__uid, \reg, \count
    _for_slot_ %__sp, \reg
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
    _check_endfor_reg_ %__sp, \reg
    _endfor_h %__curid, \reg
    .noaltmacro
    _pop
.endm
.macro _brk_h id
    _b      .Le\id
.endm
.macro break
    .if __bp == 0
        .error "break outside of a loop or switch"
    .endif
    .altmacro
    _bpeek_ %__bp
    _brk_h  %__curbid
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

.macro _assert_callee reg
    .ifndef OSAGE_NO_SAFETY
        .set __is_scratch, 0
        .irp s, x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15,w16,w17
            .ifc \reg, \s
                .set __is_scratch, 1
            .endif
        .endr
        .if __is_scratch
            .ifdef OSAGE_WARN_ONLY
                .warning "OSAGE Warning [W01]: Loop register '\reg' is a volatile scratch register (x0-x17). Macros inside loop may clobber it!"
            .else
                .error "OSAGE Error [E01]: Loop register '\reg' is a volatile scratch register (x0-x17). Use callee-saved registers x19-x28 instead! (Define OSAGE_NO_SAFETY=1 to bypass)"
            .endif
        .endif
    .endif
.endm

.macro _check_endfor_reg_h expected_reg, actual_reg
    .ifndef OSAGE_NO_SAFETY
        .ifnc \actual_reg, \expected_reg
            .ifdef OSAGE_WARN_ONLY
                .warning "OSAGE Warning [W02]: 'endfor \actual_reg' does not match opening 'for' register '\expected_reg'!"
            .else
                .error "OSAGE Error [E02]: 'endfor \actual_reg' does not match opening 'for' register '\expected_reg'!"
            .endif
        .endif
    .endif
.endm

.macro _for_slot_ n, reg
    .macro _for_reg_\n actual_reg
        _check_endfor_reg_h \reg, \actual_reg
    .endm
.endm

.macro _check_endfor_reg_ n, end_reg
    _for_reg_\n \end_reg
    .purgem _for_reg_\n
.endm

.macro unless a, cond, b
    .ifc \cond, eq
        if \a, ne, \b
        .exitm
    .endif
    .ifc \cond, ne
        if \a, eq, \b
        .exitm
    .endif
    .ifc \cond, gt
        if \a, le, \b
        .exitm
    .endif
    .ifc \cond, ge
        if \a, lt, \b
        .exitm
    .endif
    .ifc \cond, lt
        if \a, ge, \b
        .exitm
    .endif
    .ifc \cond, le
        if \a, gt, \b
        .exitm
    .endif
    .ifc \cond, hi
        if \a, ls, \b
        .exitm
    .endif
    .ifc \cond, ls
        if \a, hi, \b
        .exitm
    .endif
    .ifc \cond, hs
        if \a, lo, \b
        .exitm
    .endif
    .ifc \cond, cs
        if \a, cc, \b
        .exitm
    .endif
    .ifc \cond, lo
        if \a, hs, \b
        .exitm
    .endif
    .ifc \cond, cc
        if \a, cs, \b
        .exitm
    .endif
    .ifc \cond, mi
        if \a, pl, \b
        .exitm
    .endif
    .ifc \cond, pl
        if \a, mi, \b
        .exitm
    .endif
    .ifc \cond, vs
        if \a, vc, \b
        .exitm
    .endif
    .ifc \cond, vc
        if \a, vs, \b
        .exitm
    .endif
    .error "unknown condition: \cond"
.endm

.macro endunless
    endif
.endm

.macro _sw_h id, reg
    .macro _swr_cmp\id v
        _cmp \reg, \v
    .endm
.endm

.macro switch reg
    _push   7
    .altmacro
    _sw_h   %__uid, \reg
    .noaltmacro
.endm

.macro _case_h id, kind, old, new, cnt, vals:vararg
    .if \kind == 8
        _b      .Le\id
.Lel\old:
    .endif
    .if \cnt == 1
        _swr_cmp\id \vals
        _bnot   eq, .Lel\new
    .else
        .irp v, \vals
            _swr_cmp\id \v
            _beq    .Lcb\new
        .endr
        _b      .Lel\new
.Lcb\new:
    .endif
.endm

.macro case vals:vararg
    _expect 7, 8, "case"
    .set __uid, __uid+1
    .set __cn, 0
    .irp v, \vals
        .set __cn, __cn+1
    .endr
    .if __cn == 0
        .error "case needs at least one value"
    .endif
    .altmacro
    _case_h %__curid, %__curkd, %__curel, %__uid, %__cn, \vals
    _setel_ %__sp, %__uid
    _setkd_ %__sp, 8
    .noaltmacro
.endm

.macro _default_h id, kind, el
    .if \kind == 8
        _b      .Le\id
.Lel\el:
    .endif
.endm

.macro default
    _expect 7, 8, "default"
    .altmacro
    _default_h %__curid, %__curkd, %__curel
    _setkd_ %__sp, 9
    .noaltmacro
.endm

.macro _endsw_h id, kind, el
    .if \kind == 8
.Lel\el:
    .endif
.Le\id:
    .purgem _swr_cmp\id
.endm

.macro endswitch
    _expect 7, 9, "endswitch"
    .altmacro
    _endsw_h %__curid, %__curkd, %__curel
    .noaltmacro
    _pop
.endm
.endif