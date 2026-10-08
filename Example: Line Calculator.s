.include "OSAGE.s"

buffer line_buf, 256
buffer num_buf, 64

.text

fn parse_num, s local, p, start
    mov     p, s

    loop
        ldrb    w10, [p]
        if      w10, eq, 32
            add     p, p, #1
        else
            break
        endif
    endloop

    mov     start, p
    
    loop
        ldrb    w10, [p]
        if      w10, eq, 0
            break
        endif
        if      w10, eq, 32
            break
        endif
        if      w10, eq, #'+'
            break
        endif
        if      w10, eq, #'-'
            if      p, ne, start
                break
            endif
        endif
        if      w10, eq, #'*'
            break
        endif
        if      w10, eq, #'/'
            break
        endif
        add     p, p, #1
    endloop

    str2flt d0, start
    mov     x1, p
    return
endfn

// eval_expr(line) -> d0, evaluated strictly left to right
fn eval_expr, line local, ptr, op, lhs, rhs
    mov     ptr, line
    call    parse_num, ptr
    fmov    d8, d0
    mov     ptr, x1

    loop
        ldrb    w10, [ptr]
        if      w10, eq, 0
            break
        endif
        if      w10, eq, 32
            add     ptr, ptr, #1
            continue
        endif

        mov     op, x10
        add     ptr, ptr, #1

        call    parse_num, ptr
        fmov    d9, d0
        mov     ptr, x1

        if      op, eq, 43
            fadd    d8, d8, d9
        elif    op, eq, 45
            fsub    d8, d8, d9
        elif    op, eq, 42
            fmul    d8, d8, d9
        elif    op, eq, 47
            fdiv    d8, d8, d9
        endif
    endloop

    fmov    d0, d8
    return
endfn

fn 
    loop
        stdout  "calc> "
        stdin   line_buf, 256
        chomp   line_buf
        if      x0, eq, 0
            break
        endif

        lea     x9, line_buf            

        streqs  x9, "exit"
        if      x0, eq, 1
            break
        endif

        streqs  x9, "quit"
        if      x0, eq, 1
            break
        endif

        call    eval_expr, x9
        flt2str num_buf, d0, 4
        lea     x9, num_buf
        puts_z  x9
        stdout  "", nl
    endloop

    sys_exit 0
endfn