.ifndef OSAGE_STRUCT_S
.set OSAGE_STRUCT_S, 1

.set __cls_offset, 0

.macro struct name
    .set __cls_offset, 0
    .macro field fname, fsize=8
        .set \name\()_\fname, __cls_offset
        .set __cls_offset, __cls_offset + \fsize
    .endm
    .macro endstruct
        .set \name\()_size, __cls_offset
        .purgem field
        .purgem endstruct
    .endm
.endm

.macro instance instance_name, class_name
    .pushsection .bss
    .balign 8
\instance_name:
    .space \class_name\()_size
    .popsection
.endm

.macro getfield dst, base_reg, class_name, field_name
    ldr     \dst, [\base_reg, #\class_name\()_\field_name]
.endm

.macro setfield base_reg, class_name, field_name, src
    str     \src, [\base_reg, #\class_name\()_\field_name]
.endm

.macro method instance_ptr, method_name, args:vararg
    mov     x0, \instance_ptr
    .set __ci, 1
    .ifnb \args
    .irp a, \args
        .altmacro
        _mov_arg_ %__ci, \a
        .noaltmacro
        .set __ci, __ci+1
    .endr
    .endif
    bl      \method_name
.endm

.macro array name, len, elemsize=8
    .ifndef \name
        .pushsection .bss
        .balign \elemsize
\name:
        .space (\len) * (\elemsize)
        .popsection

        .set \name\()_len, \len
        .set \name\()_stride, \elemsize
        .set \name\()_size, (\len) * (\elemsize)
    .endif
.endm

.endif