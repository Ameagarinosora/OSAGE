**OSAGE** is a structured assembly framework for **AArch64 (ARM64) Linux**. It provides a high-level, Pascal-inspired macro layer on top of GNU Assembler (`as`) so you can write clearer, more maintainable assembly while retaining full control of the underlying machine code.

It draws inspiration from the classic Pascal unit model: modular includes, initialization sections, and a clean separation of concerns, while staying pure assembly.

## Features

- **Unit / module system** – `uses`, `export`, `initialization` / `endinit`, `run_inits`
- **Structured control flow** – `if` / `elif` / `else` / `endif`, `while` / `endwhile`, `repeat` / `until`, `for` / `endfor`, `loop` / `endloop`, `switch` / `case` / `default` / `endswitch`, `break`, `continue`, `unless`
- **Functions** – `fn` / `endfn`, named parameters & locals (mapped to callee-saved registers), `call`, `return`
- **Core utilities** – `push` / `pop`, `lea`, `buffer`, `string`, `imm` (64-bit immediates), bit-set helpers, reference helpers
- **I/O** – stdout/stderr macros, `print_int` / `print_hex` / `print_flt`, `read_line`, `prompt`, file open/read/write/seek/close, ANSI color & cursor control, `argc` / `argv`, `sys_exit`
- **Strings** – length, equality, conversion (int ↔ string, float ↔ string), `chomp`
- **Time** – monotonic clock, milliseconds, sleep / delay, date/time helpers
- **Random** – seed and range generation
- **Error handling** – `try_sys`, `try_prop`, null/condition checks with automatic propagation
- **Architecture abstraction** – conditional branches and loops written in a portable style (currently AArch64)

## Project Layout

```
OSAGE/
├── pascalunitmodel.sh      # Simple build helper (assemble + link)
└── osage/
    ├── osage.s             # Master include (pulls everything in)
    ├── arch.s              # Architecture primitives
    ├── core.s              # Core macros (push/pop, lea, buffers…)
    ├── unit.s              # Unit / init system
    ├── flow.s              # Control-flow macros
    ├── func.s              # Function definition & calling convention
    ├── io.s                # I/O and system-call wrappers
    ├── strings.s           # String helpers
    ├── struct.s            # Example program (telemetry benchmark)
    ├── rand.s              # Random number generation
    ├── time.s              # Timing utilities
    └── errorhandling.s     # Try / error-propagation macros
```

## Requirements

- AArch64 Linux (or cross-toolchain targeting `aarch64-linux-gnu`)
- GNU Assembler (`as`) and Linker (`ld`)
- Standard system headers / Linux syscalls (no libc required)

## Quick Start

1. Place your source next to the `osage/` directory (or adjust include paths).

2. Write a program:

```asm
.include "osage.s"

fn main
    color   #36
    stdout  "Hello from OSAGE!", nl
    color   #0

    for x19, #5
        stdout  "  iteration "
        print_int x19, nl
    endfor x19

    return  #0
endfn

fn _start
    call    main
    sys_exit #0
endfn
```

3. Build with the provided helper:

```bash
./pascalunitmodel.sh hello hello.s
# or manually:
as -I osage -I . hello.s -o hello.o
ld --gc-sections hello.o -o hello
```

4. Run:

```bash
./hello
```

## Design Notes

- All public macros are deliberately written in lowercase for a high-level feel.
- Internal helper macros are prefixed with `_`.
- The framework carefully manages register allocation (especially callee-saved registers x19–x28) inside `fn` / `endfn`.
- Sections are used extensively (`.text.<name>`, `.rodata`, `.bss`, custom `osage_init`) so the linker can discard unused code (`--gc-sections`).
- No external runtime or libc is required — everything is pure assembly + Linux syscalls.

## Status

OSAGE is a work-in-progress research / educational project. The core control-flow, function, I/O, string, time, and error-handling layers are functional. Structured data (`struct` / `field` / `instance`) macros appear in the example but are not yet fully defined in the library itself.

## License

MIT

---

**Happy assembling!**