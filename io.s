.ifndef OSAGE_IO_S
.set OSAGE_IO_S, 1

.equ AT_FDCWD,   -100
.equ O_RDONLY,   0
.equ O_WRONLY,   1
.equ O_RDWR,     2
.equ O_CREAT,    64
.equ O_EXCL,     128
.equ O_TRUNC,    512
.equ O_APPEND,   1024

.equ SEEK_SET,   0
.equ SEEK_CUR,   1
.equ SEEK_END,   2

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

.macro sys_write fd, buf, len
    mov     x0, \fd
    mov     x1, \buf
    mov     x2, \len
    mov     x8, #64
    svc     #0
.endm

.macro sys_read fd, buf, len
    mov     x0, \fd
    mov     x1, \buf
    mov     x2, \len
    mov     x8, #63
    svc     #0
.endm

.macro stderr str, nl
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
    mov     x0, #2
    lea     x1, .Lstr\@
    mov     x2, #.Llen\@
    mov     x8, #64
    svc     #0
    ldp     x2, x8, [sp, #16]
    ldp     x0, x1, [sp], #32
.endm

.macro stderr_raw str, nl
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
    mov     x0, #2
    lea     x1, .Lstr\@
    mov     x2, #.Llen\@
    mov     x8, #64
    svc     #0
.endm

.macro println
    .pushsection .rodata
.Lnl\@:
    .byte 10
    .popsection
    stp     x0, x1, [sp, #-32]!
    stp     x2, x8, [sp, #16]
    mov     x0, #1
    lea     x1, .Lnl\@
    mov     x2, #1
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
    mov     x2, \len
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
    mov     x0, \code
    mov     x8, #93
    svc     #0
.endm

.macro stdout_raw str, nl
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
    mov     x0, #1
    lea     x1, .Lstr\@
    mov     x2, #.Llen\@
    mov     x8, #64
    svc     #0
.endm

.macro putc ch
    stp     x0, x1, [sp, #-48]!
    stp     x2, x8, [sp, #16]
    mov     x2, \ch
    strb    w2, [sp, #32]
    add     x1, sp, #32
    mov     x0, #1
    mov     x2, #1
    mov     x8, #64
    svc     #0
    ldp     x2, x8, [sp, #16]
    ldp     x0, x1, [sp], #48
.endm

.macro print_int reg, nl
    stp     x0, x30, [sp, #-16]!
    mov     x0, \reg
    bl      __osage_print_int
    ldp     x0, x30, [sp], #16
    .ifnb \nl
        .ifc \nl, nl
            println
        .endif
    .endif
.endm

.macro print_hex reg, nl
    stp     x0, x30, [sp, #-16]!
    mov     x0, \reg
    bl      __osage_print_hex
    ldp     x0, x30, [sp], #16
    .ifnb \nl
        .ifc \nl, nl
            println
        .endif
    .endif
.endm

.macro print_flt dsrc, prec=4, nl
    stp     x0, x30, [sp, #-16]!
    .ifnc \dsrc, d0
        str     d0, [sp, #-16]!
        fmov    d0, \dsrc
    .endif
    mov     x0, \prec
    bl      __osage_print_flt
    .ifnc \dsrc, d0
        ldr     d0, [sp], #16
    .endif
    ldp     x0, x30, [sp], #16
    .ifnb \nl
        .ifc \nl, nl
            println
        .endif
    .endif
.endm

.macro file_open dst_fd, path, flags=0, mode=0644
    mov     x0, #AT_FDCWD
    .ifnc \path, x1
        mov x1, \path
    .endif
    mov     x2, \flags
    mov     x3, \mode
    mov     x8, #56
    svc     #0
    .ifnc \dst_fd, x0
        mov \dst_fd, x0
    .endif
.endm

.macro file_close fd
    .ifnc \fd, x0
        mov x0, \fd
    .endif
    mov     x8, #57
    svc     #0
.endm

.macro file_seek dst_offset, fd, offset, whence=SEEK_SET
    .ifnc \fd, x0
        mov x0, \fd
    .endif
    mov     x1, \offset
    mov     x2, \whence
    mov     x8, #62
    svc     #0
    .ifnc \dst_offset, x0
        mov \dst_offset, x0
    .endif
.endm

.macro file_read dst_bytes, fd, buf, len
    mov     x0, \fd
    mov     x1, \buf
    mov     x2, \len
    mov     x8, #63
    svc     #0
    .ifnc \dst_bytes, x0
        mov \dst_bytes, x0
    .endif
.endm

.macro file_write dst_bytes, fd, buf, len
    mov     x0, \fd
    mov     x1, \buf
    mov     x2, \len
    mov     x8, #64
    svc     #0
    .ifnc \dst_bytes, x0
        mov \dst_bytes, x0
    .endif
.endm

.macro read_file_all dst_bytes, path, buf, max_len
    mov     x0, \path
    mov     x1, \buf
    mov     x2, \max_len
    bl      __osage_read_file_all
    .ifnc \dst_bytes, x0
        mov \dst_bytes, x0
    .endif
.endm

.macro write_file_all dst_bytes, path, buf, len, mode=0644
    mov     x0, \path
    mov     x1, \buf
    mov     x2, \len
    mov     x3, \mode
    bl      __osage_write_file_all
    .ifnc \dst_bytes, x0
        mov \dst_bytes, x0
    .endif
.endm

.macro read_line buf, len
    stp     x1, x2, [sp, #-64]!
    stp     x3, x4, [sp, #16]
    stp     x5, x6, [sp, #32]
    stp     x8, x30, [sp, #48]
    mov     x1, \len
    lea     x0, \buf
    bl      __osage_read_line
    ldp     x8, x30, [sp, #48]
    ldp     x5, x6, [sp, #32]
    ldp     x3, x4, [sp, #16]
    ldp     x1, x2, [sp], #64
.endm

.macro prompt text, buf, len
    stdout "\text"
    read_line \buf, \len
.endm

.macro getc dst
    stp     x0, x1, [sp, #-48]!
    stp     x2, x8, [sp, #16]
    str     xzr, [sp, #32]
    mov     x0, #0
    add     x1, sp, #32
    mov     x2, #1
    mov     x8, #63
    svc     #0
    cmp     x0, #1
    b.eq    .Lgc_ok\@
    mov     x1, #-1
    str     x1, [sp, #32]
.Lgc_ok\@:
    ldp     x2, x8, [sp, #16]
    ldp     x0, x1, [sp]
    ldr     \dst, [sp, #32]
    add     sp, sp, #48
.endm

.macro ansi_clear
    stdout_raw "\033[2J\033[H"
.endm

.macro cursor_to row, col
    stdout_raw "\033["
    stp     x0, x30, [sp, #-16]!
    mov     x0, \row
    bl      __osage_print_int
    ldp     x0, x30, [sp], #16
    stdout_raw ";"
    stp     x0, x30, [sp, #-16]!
    mov     x0, \col
    bl      __osage_print_int
    ldp     x0, x30, [sp], #16
    stdout_raw "H"
.endm

.macro color n
    stdout_raw "\033["
    stp     x0, x30, [sp, #-16]!
    mov     x0, \n
    bl      __osage_print_int
    ldp     x0, x30, [sp], #16
    stdout_raw "m"
.endm

.macro die msg, code=#1
    stderr "\msg", nl
    sys_exit \code
.endm

.macro assert reg, cond, val, msg
    unless \reg, \cond, \val
        die "\msg"
    endunless
.endm

.macro argc dst
    ldr     \dst, [sp]
.endm

.macro argv dst, index
    .set __is_reg, 0
    .irp r, x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28
        .ifc \index, \r
            .set __is_reg, 1
        .endif
    .endr
    .if __is_reg
        add     x16, sp, #8
        ldr     \dst, [x16, \index, lsl #3]
    .else
        mov     x16, \index
        add     x17, sp, #8
        ldr     \dst, [x17, x16, lsl #3]
    .endif
.endm

routine __osage_read_line
    cmp     x1, #2
    b.hs    .Lrl_ok
    mov     x0, #-1
    ret
.Lrl_ok:
    mov     x3, x0
    mov     x4, x3
    sub     x5, x1, #1
.Lrl_loop:
    cbz     x5, .Lrl_done
    mov     x0, #0
    mov     x1, x4
    mov     x2, #1
    mov     x8, #63
    svc     #0
    cmp     x0, #0
    b.lt    .Lrl_err
    b.eq    .Lrl_eof
    ldrb    w6, [x4]
    cmp     w6, #10
    b.eq    .Lrl_done
    add     x4, x4, #1
    sub     x5, x5, #1
    b       .Lrl_loop
.Lrl_eof:
    cmp     x4, x3
    b.ne    .Lrl_done
    strb    wzr, [x3]
    mov     x0, #-1
    ret
.Lrl_err:
    strb    wzr, [x3]
    ret
.Lrl_done:
    strb    wzr, [x4]
    sub     x0, x4, x3
    ret
endroutine

routine __osage_print_int
    stp     x1, x2, [sp, #-96]!
    stp     x3, x4, [sp, #16]
    stp     x5, x8, [sp, #32]
    add     x1, sp, #96
    mov     x2, x1
    mov     x4, #10
    mov     x5, #0
    cmp     x0, #0
    b.ge    .Lpi_loop
    neg     x0, x0
    mov     x5, #1
.Lpi_loop:
    udiv    x3, x0, x4
    msub    x8, x3, x4, x0
    add     w8, w8, #48
    sub     x1, x1, #1
    strb    w8, [x1]
    mov     x0, x3
    cbnz    x0, .Lpi_loop
    cbz     x5, .Lpi_out
    mov     w8, #45
    sub     x1, x1, #1
    strb    w8, [x1]
.Lpi_out:
    sub     x2, x2, x1
    mov     x0, #1
    mov     x8, #64
    svc     #0
    ldp     x5, x8, [sp, #32]
    ldp     x3, x4, [sp, #16]
    ldp     x1, x2, [sp], #96
    ret
endroutine

routine __osage_print_hex
    stp     x1, x2, [sp, #-96]!
    stp     x3, x8, [sp, #16]
    add     x1, sp, #96
    mov     x2, x1
.Lph_loop:
    and     x3, x0, #15
    cmp     x3, #10
    add     x3, x3, #48
    b.lo    .Lph_dig
    add     x3, x3, #39
.Lph_dig:
    sub     x1, x1, #1
    strb    w3, [x1]
    lsr     x0, x0, #4
    cbnz    x0, .Lph_loop
    mov     w3, #120
    sub     x1, x1, #1
    strb    w3, [x1]
    mov     w3, #48
    sub     x1, x1, #1
    strb    w3, [x1]
    sub     x2, x2, x1
    mov     x0, #1
    mov     x8, #64
    svc     #0
    ldp     x3, x8, [sp, #16]
    ldp     x1, x2, [sp], #96
    ret
endroutine

routine __osage_print_flt
    stp     x30, x1, [sp, #-160]!
    stp     x2, x3, [sp, #16]
    stp     x4, x5, [sp, #32]
    stp     x6, x8, [sp, #48]
    stp     d0, d16, [sp, #64]
    str     d17, [sp, #80]
    mov     x1, x0
    add     x0, sp, #96
    bl      __osage_flt2str
    mov     x2, x0
    add     x1, sp, #96
    mov     x0, #1
    mov     x8, #64
    svc     #0
    ldr     d17, [sp, #80]
    ldp     d0, d16, [sp, #64]
    ldp     x6, x8, [sp, #48]
    ldp     x4, x5, [sp, #32]
    ldp     x2, x3, [sp, #16]
    ldp     x30, x1, [sp], #160
    ret
endroutine

routine __osage_read_file_all
    stp     x19, x20, [sp, #-32]!
    stp     x21, x30, [sp, #16]

    mov     x19, x1
    mov     x20, x2

    mov     x1, x0
    mov     x0, #AT_FDCWD
    mov     x2, #O_RDONLY
    mov     x3, #0
    mov     x8, #56
    svc     #0

    cmp     x0, #0
    b.lt    .Lrfa_err

    mov     x21, x0

    mov     x0, x21
    mov     x1, x19
    mov     x2, x20
    mov     x8, #63
    svc     #0

    mov     x19, x0

    mov     x0, x21
    mov     x8, #57
    svc     #0

    mov     x0, x19
    ldp     x21, x30, [sp, #16]
    ldp     x19, x20, [sp], #32
    ret

.Lrfa_err:
    ldp     x21, x30, [sp, #16]
    ldp     x19, x20, [sp], #32
    ret
endroutine

routine __osage_write_file_all
    stp     x19, x20, [sp, #-48]!
    stp     x21, x22, [sp, #16]
    str     x30, [sp, #32]

    mov     x19, x1
    mov     x20, x2
    mov     x21, x3

    mov     x1, x0
    mov     x0, #AT_FDCWD
    mov     x2, #(O_WRONLY | O_CREAT | O_TRUNC)
    mov     x3, x21
    mov     x8, #56
    svc     #0

    cmp     x0, #0
    b.lt    .Lwfa_err

    mov     x22, x0

    mov     x0, x22
    mov     x1, x19
    mov     x2, x20
    mov     x8, #64
    svc     #0

    mov     x19, x0

    mov     x0, x22
    mov     x8, #57
    svc     #0

    mov     x0, x19
    ldr     x30, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp], #48
    ret

.Lwfa_err:
    ldr     x30, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp], #48
    ret
endroutine

.endif