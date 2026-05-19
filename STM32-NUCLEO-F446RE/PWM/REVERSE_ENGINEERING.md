# Reverse Engineering: main.i → main.s Transformation

## Overview
This document explains how the preprocessed C code (`main.i`) is transformed into ARM assembly code (`main.s`) during the compilation stage.

## Compilation Pipeline
```
main.c (Source) → Preprocessor → main.i (Expanded C) → Compiler → main.s (Assembly)
```

---

## Stage 1: Preprocessing (main.c → main.i)

### What Happens
The preprocessor expands all macros and removes directives before compilation.

### Key Transformations

#### 1. Macro Expansion
**Before (main.c):**
```c
#define RCC_BASE       0x40023800
#define GPIOA_BASE     0x40020000
#define RCC_AHB1ENR    (*(volatile unsigned int *)(RCC_BASE + 0x30))
```

**After (main.i):**
```c
RCC_AHB1ENR |= 0x00000001;
// Becomes:
(*(volatile unsigned int *)(0x40023800 + 0x30)) |= 0x00000001;
```

- All `#define` constants are replaced with their literal values
- Register address pointers are fully expanded inline
- Macro functions are inlined (if any)

#### 2. Comments Removed
All C-style comments (`/* */` and `//`) are stripped

#### 3. Includes Processed
The preprocessor marker lines show include depth:
```
# 0 "./STM32-NUCLEO-F446RE/PWM/main.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "./STM32-NUCLEO-F446RE/PWM/main.c"
```

### Result
The `main.i` file is pure C code with:
- All macros fully expanded
- All preprocessor directives removed
- Ready for the compiler

---

## Stage 2: Compilation (main.i → main.s)

### ARM Assembly Context
This is compiled for ARM (32-bit), targeting the STM32F446RE microcontroller using the ARM EABI (Embedded ABI) calling convention.

### Function: `delay(unsigned int count)`

#### Assembly Structure
```asm
delay:
    @ Function supports interworking.
    @ args = 0, pretend = 0, frame = 8
    @ frame_needed = 1, uses_anonymous_args = 0
    @ link register save eliminated.
    str    fp, [sp, #-4]!        @ Save frame pointer
    add    fp, sp, #0            @ Set up frame pointer
    sub    sp, sp, #12           @ Allocate stack space (8 bytes used)
    str    r0, [fp, #-8]         @ Store 'count' argument on stack
```

#### Compilation Strategy
```c
void delay(unsigned int count) {
    while (count--) {
        __asm("nop");
    }
}
```

**Compiled to:**
```asm
    b    .L2              @ Branch to loop condition
.L3:                       @ Loop body
    .syntax divided
@ 17 "main.c" 1
    nop                   @ Inline assembly: __asm("nop")
@ 0 "" 2
    .arm
    .syntax unified
.L2:                       @ Loop condition
    ldr  r3, [fp, #-8]    @ Load 'count' from stack
    sub  r2, r3, #1       @ Decrement: r2 = count - 1
    str  r2, [fp, #-8]    @ Store back to stack
    cmp  r3, #0           @ Compare original value with 0
    bne  .L3              @ Branch if not equal (count != 0)
```

**Key Points:**
- `str` = Store Register (save data to memory)
- `ldr` = Load Register (read data from memory)
- `sub` = Subtract
- `cmp` = Compare
- `bne` = Branch if Not Equal
- Stack frame is used to store the `count` variable
- Post-decrement loop: `while (count--)` evaluates original value then decrements

---

### Function: `main(void)`

#### Compilation Strategy

**C Code:**
```c
int main(void) {
    RCC_AHB1ENR |= 0x00000001;
    GPIOA_MODER &= ~(0x00000C00);
    GPIOA_MODER |= 0x00000400;
    while (1) {
        GPIOA_ODR |= 0x00000020;
        delay(500000);
        GPIOA_ODR &= ~0x00000020;
        delay(500000);
    }
    return 0;
}
```

**Compiled Structure:**

1. **Stack Frame Setup**
```asm
main:
    push   {fp, lr}       @ Save frame pointer and return address
    add    fp, sp, #4     @ Set up stack frame
```

2. **Register Address Loading via Literal Pool**
The compiler loads addresses from a literal pool (label `.L6`) to reduce code size:
```asm
ldr    r3, .L6          @ Load RCC_AHB1ENR address (0x40023830)
ldr    r3, [r3]         @ Load current value
ldr    r2, .L6          @ Load address again
orr    r3, r3, #1       @ OR with 0x00000001 (Enable GPIOA clock)
str    r3, [r2]         @ Store result back
```

**Literal Pool:**
```asm
.L6:
    .word   1073887280    @ 0x40023830 = RCC_AHB1ENR
    .word   1073872896    @ 0x40020000 = GPIOA_MODER
    .word   1073872916    @ 0x40020014 = GPIOA_ODR
    .word   500000        @ Delay count
```

3. **Bit Manipulation Operations**
The compiler uses ARM bit manipulation instructions:
- `orr` = Bitwise OR (set bits)
- `bic` = Bitwise Clear (clear bits)

```asm
@ GPIOA_MODER &= ~(0x00000C00);
ldr    r3, .L6+4
ldr    r3, [r3]
ldr    r2, .L6+4
bic    r3, r3, #3072     @ Clear bits (3072 = 0x0C00)
str    r3, [r2]

@ GPIOA_MODER |= 0x00000400;
ldr    r3, .L6+4
ldr    r3, [r3]
ldr    r2, .L6+4
orr    r3, r3, #1024     @ Set bits (1024 = 0x0400)
str    r3, [r2]
```

4. **Infinite Loop with Function Calls**
```asm
.L5:                              @ Loop label
    ldr    r3, .L6+8              @ Load GPIOA_ODR address
    ldr    r3, [r3]               @ Read current value
    ldr    r2, .L6+8
    orr    r3, r3, #32            @ Set bit 5 (turn on LED)
    str    r3, [r2]               @ Write back
    
    ldr    r0, .L6+12             @ Load delay count (500000) into r0 (arg register)
    bl     delay                   @ Branch with Link (call delay function)
    
    @ Similar code for clearing LED
    ldr    r3, .L6+8
    ldr    r3, [r3]
    ldr    r2, .L6+8
    bic    r3, r3, #32            @ Clear bit 5 (turn off LED)
    str    r3, [r2]
    
    ldr    r0, .L6+12
    bl     delay
    
    b      .L5                     @ Branch back to loop start
```

5. **Function Return**
```asm
    @ (unreachable in this case due to infinite loop)
    add    sp, fp, #0              @ Clean up stack
    ldr    fp, [sp], #4            @ Restore frame pointer
    bx     lr                       @ Return to caller
```

---

## Key Compilation Techniques

### 1. **Literal Pool**
- Large constants (addresses, numbers) are stored in a separate data section (`.L6`)
- Used via PC-relative addressing with `ldr`
- Reduces instruction size and increases code efficiency

### 2. **Register Allocation**
- `r0`: First argument (count, delay amount)
- `r2`: Temporary for results
- `r3`: Temporary for loaded values
- `fp`: Frame pointer
- `sp`: Stack pointer
- `lr`: Link register (return address)

### 3. **EABI Calling Convention**
- First 4 arguments passed in `r0-r3`
- Return value in `r0`
- Caller saves registers if needed
- Function may trash `r0-r3` (caller-save)

### 4. **Optimization Trade-offs**
The compiler made these choices:
- Repeated loads from literal pool (could optimize with register caching)
- Frame pointer maintained (even though not strictly necessary)
- Memory stack used for `delay()` variable storage
- Inline assembly `nop` preserved as-is

### 5. **EABI Attributes**
The `.eabi_attribute` directives specify:
- CPU compatibility (arm7tdmi, armv4t)
- Floating point (softvfp - soft-float)
- ABI compliance level

---

## Address Translation Reference

| Macro | Expanded Address | Hex |
|-------|------------------|-----|
| RCC_BASE + 0x30 | 0x40023830 | 1073887280 |
| GPIOA_BASE + 0x00 | 0x40020000 | 1073872896 |
| GPIOA_BASE + 0x14 | 0x40020014 | 1073872916 |

---

## Summary

| Stage | Input | Output | Main Changes |
|-------|-------|--------|--------------|
| **Preprocessing** | main.c (with macros) | main.i (expanded C) | Macro expansion, comment removal, address inlining |
| **Compilation** | main.i (C code) | main.s (Assembly) | Function prologue/epilogue, register allocation, instruction selection, literal pool creation |

The transformation from high-level C to low-level ARM assembly involves careful management of the stack frame, register allocation, and instruction sequencing to produce efficient embedded code for the STM32F446RE microcontroller.
