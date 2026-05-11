# STM32F446RE PWM Project - Build Guide

## Overview

This project demonstrates how to compile STM32F446RE firmware using ARM toolchain in VS Code Codespace instead of STM32CubeIDE.

---

## Prerequisites

### 1. Install Build Tools

```bash
sudo apt update
sudo apt install -y build-essential git wget
```

**Why:** Provides gcc compiler, make, and other build utilities.

**Verification:**
```bash
gcc --version
g++ --version
make --version
ar --version
```

---

### 2. Install ARM Toolchain (CRITICAL for STM32)

**Package Name vs Binary Name:**
- **Package to install:** `gcc-arm-none-eabi` and `binutils-arm-none-eabi`
- **Binary to use:** `arm-none-eabi-gcc`

```bash
# Search available packages
apt-cache search arm-none-eabi

# Install ARM GCC and binutils
sudo apt install -y gcc-arm-none-eabi binutils-arm-none-eabi
```

**Why:**
- `gcc-arm-none-eabi` = Package name (for apt)
- `arm-none-eabi-gcc` = Actual executable for ARM Cortex-M4
- Regular `gcc` compiles for PC (x86_64), NOT for STM32 microcontrollers

**Difference:**
```bash
gcc              # Produces x86_64 Linux executable ❌ (won't run on STM32)
arm-none-eabi-gcc # Produces ARM firmware ✅ (runs on STM32)
```

**Verification:**
```bash
arm-none-eabi-gcc --version
which arm-none-eabi-gcc
```

**If not found after install:**
```bash
# List all ARM tools installed
ls /usr/bin/arm-none-eabi-*

# Check what the package actually installed
dpkg -L gcc-arm-none-eabi | grep bin
```

---

## Project Files

| File | Purpose |
|------|---------|
| `main.c` | Main firmware code - LED toggle on PA5 (LD2) using GPIO |
| `startup_stm32f446xx.s` | Startup assembly code - initializes stack and calls main() |
| `stm32f446_flash.ld` | Linker script - defines memory layout (Flash: 512KB, RAM: 128KB) |
| `Makefile` | Build automation - compiles, links, and generates binary |

---

## Understanding the Startup Assembly File (.s file)

### What is an Assembly File?

**Assembly** is the language closest to what the CPU actually understands.

**Analogy:** 
- C code is like a recipe in English
- Assembly is like detailed step-by-step instructions in machine code language
- The CPU can only understand assembly (machine code)

When you compile C code, the compiler converts it to assembly first, then to machine code.

### Why Do We Need a Startup File?

When the STM32 chip **powers on**, it doesn't immediately run your `main()` function. Instead:

1. **Chip wakes up** → CPU at memory address `0x08000000` (Flash start)
2. **CPU needs to initialize things** → Stack, memory, etc.
3. **Then call main()** → Your C code starts

**Without a startup file:**
- The chip wakes up but doesn't know what to do
- Stack isn't set up → variables crash
- main() doesn't get called → program doesn't run

### Our Startup File Explained

```asm
/* Minimal STM32F446 Startup Code */

/* Stack configuration */
.syntax unified
.cpu cortex-m4
.thumb
```

**Line-by-line explanation:**

```asm
.syntax unified
```
- Tells assembler to use modern ARM instruction syntax
- (vs old syntax that's harder to read)

```asm
.cpu cortex-m4
```
- Declares we're targeting ARM Cortex-M4 processor
- (STM32F446RE uses Cortex-M4)

```asm
.thumb
```
- Use 16-bit Thumb instruction set (compact and efficient)
- (vs 32-bit ARM instructions)

---

### Stack Setup

```asm
.section .stack
.align 3
.globl __StackTop
Stack_Mem:
    .space 0x1000  /* 4KB stack */
__StackTop:
```

**What is "stack"?**

**Analogy:** Stack is like a pile of dishes:
- You add dishes on top (push)
- You remove from top (pop)
- Variables go on the stack
- Function calls need stack space

**What does this code do?**

```asm
.section .stack
```
- Create a section called `.stack` in memory
- This is where variables and function data go

```asm
.space 0x1000
```
- Reserve 0x1000 bytes = 4096 bytes = 4KB of space for stack

```asm
.globl __StackTop
```
- Mark `__StackTop` as global so linker can find it
- This is the TOP (highest address) of the stack

---

### Reset Handler (Entry Point)

```asm
.section .text
.globl Reset_Handler
.thumb_func
Reset_Handler:
    /* Set stack pointer */
    ldr sp, =__StackTop
    
    /* Call main */
    bl main
    
    /* Infinite loop */
    b .
```

**This is THE MOST IMPORTANT code!**

**What happens step-by-step when chip powers on:**

```asm
.globl Reset_Handler
```
- Export `Reset_Handler` - this is the first code that runs
- The linker puts this at address `0x08000000`

```asm
.thumb_func
```
- Tell assembler this is a Thumb function

```asm
ldr sp, =__StackTop
```
- `ldr` = Load Register
- `sp` = Stack Pointer register (CPU register)
- `=__StackTop` = Address of stack top
- **This initializes the stack!**

**Visual:**
```
CPU registers after this:
sp (Stack Pointer) → points to top of stack memory
```

```asm
bl main
```
- `bl` = Branch with Link
- **Literally calls your main() function**
- CPU jumps to main(), will return here when main() finishes

```asm
b .
```
- `b` = Branch
- `.` = Current position
- **Infinite loop** - if main() returns, loop here forever
- (In real embedded code, main() should never return)

---

## Understanding the Linker Script (.ld file)

### What is a Linker Script?

**Linker** takes your compiled code and tells it where to go in memory.

**Analogy:**
- Compiler converts C to object files (like ingredients)
- Linker arranges those ingredients in the STM32's memory (like assembling a meal)

**But HOW does the linker know where to put things?**

**Answer:** The linker script tells it!

### Memory Layout of STM32F446RE

Your STM32 chip has two types of memory:

```
┌─────────────────────────────────────┐
│  FLASH (512 KB) - Program Storage   │  0x08000000 - 0x0807FFFF
│  - Read-only                        │
│  - Your firmware code lives here    │
│  - Persists when powered off        │
├─────────────────────────────────────┤
│                                     │
│  (empty space)                      │
│                                     │
├─────────────────────────────────────┤
│  RAM (128 KB) - Working Memory      │  0x20000000 - 0x2001FFFF
│  - Read-write                       │
│  - Variables, stack, heap live here │
│  - Lost when powered off            │
└─────────────────────────────────────┘
```

### Our Linker Script Explained

```ld
MEMORY
{
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
  RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 128K
}
```

**Line-by-line:**

```ld
MEMORY { ... }
```
- This block defines available memory regions

```ld
FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
```
- `FLASH` = Name of this memory region (you choose it)
- `(rx)` = Permissions: read + execute (not writable)
- `ORIGIN = 0x08000000` = Starting address in STM32 memory
- `LENGTH = 512K` = Size of Flash = 512 Kilobytes
- **This says: "I have 512KB of read-only code storage starting at address 0x08000000"**

```ld
RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 128K
```
- `RAM` = Name of this memory region
- `(rwx)` = Permissions: read + write + execute
- `ORIGIN = 0x20000000` = Starting address (always for STM32F4)
- `LENGTH = 128K` = Size = 128 Kilobytes
- **This says: "I have 128KB of working memory starting at address 0x20000000"**

---

### Section Placement

```ld
SECTIONS
{
  .text : {
    KEEP(*(.vectors))
    *(.text*)
    *(.rodata*)
  } > FLASH
```

**What is a "section"?**

When compiler creates an object file, it divides code into sections:
- `.text` = Executable code
- `.data` = Initialized variables
- `.bss` = Uninitialized variables
- `.rodata` = Read-only data (constants)

**`.text` section (code):**

```ld
.text : {
  KEEP(*(.vectors))
  *(.text*)
  *(.rodata*)
} > FLASH
```

- `.text :` = Define the .text output section
- `{ ... }` = What goes in it
- `*(.vectors)` = Vector table (interrupt handlers)
- `*(.text*)` = All code
- `*(.rodata*)` = Read-only data (strings, constants)
- `} > FLASH` = **Put all of this in FLASH memory**

**Why FLASH?** Because code needs to persist even when powered off!

```ld
.data : {
  *(.data*)
} > RAM AT > FLASH
```

- `*(.data*)` = Initialized variables
- `} > RAM AT > FLASH` = **Tricky!**
  - `> RAM` = Put the variable at RAM during runtime (fast access)
  - `AT > FLASH` = Store the initial value in FLASH (boot-time copy)
  - **This means: startup code copies initial values from Flash to RAM**

**Visual:**
```
At power-on:
1. Startup code copies initialized variables from FLASH to RAM
2. Now variables are in fast RAM
3. Program runs using variables in RAM
```

```ld
.bss : {
  *(.bss*)
  *(COMMON)
} > RAM
```

- `.bss` = Uninitialized variables
- `} > RAM` = Put in RAM
- No `AT > FLASH` because these start as zero (no initial value to store)

---

## How Everything Works Together

### Step-by-Step Boot Sequence

When you power on the STM32:

```
1. [HARDWARE] Chip wakes up
              CPU jumps to 0x08000000 (Flash start)

2. [STARTUP.S] Reset_Handler runs
              - Sets stack pointer (sp = __StackTop)
              - Calls main()

3. [MAIN.C] main() function starts
            - Your code runs
            - LED blinks

4. [IF main() returns] Infinite loop (b .)
                       Prevents chip reset
```

### How Memory is Organized

**After linking (using the .ld script):**

```
FLASH Memory:
0x08000000 ┌──────────────────────┐
           │  Reset_Handler       │  ← First code to run
           │  (from startup.s)    │
           ├──────────────────────┤
           │  main() function     │  ← Your LED blink code
           │  (from main.c)       │
           ├──────────────────────┤
           │  Data & Constants    │  ← Strings, hardcoded values
           │  (from main.c)       │
           └──────────────────────┘
0x0807FFFF

RAM Memory:
0x20000000 ┌──────────────────────┐
           │  Initialized Vars    │  ← Copied from Flash at startup
           ├──────────────────────┤
           │  Uninitialized Vars  │  ← Set to zero at startup
           ├──────────────────────┤
           │  Stack               │  ← Function calls, local variables
           │  (grows downward)    │
           └──────────────────────┘
0x2001FFFF
```

### Role of Each File

| File | What It Does | When |
|------|-------------|------|
| `main.c` | Your application code (LED blink) | Runs after startup |
| `startup_stm32f446xx.s` | Sets up CPU (stack, calls main) | Runs first at power-on |
| `stm32f446_flash.ld` | Tells linker where to put code | Used during linking step |
| `Makefile` | Automates compile → link → binary | Runs when you do `make all` |

---

## Building Step-by-Step with Files

### Step 1: Compile main.c

```bash
arm-none-eabi-gcc -c main.c -o build/main.o
```

**What happens:**
- Compiler reads `main.c`
- Creates object file `build/main.o`
- Contains compiled code (but not yet placed in memory)
- Address of code = TBD (linker will decide)

**main.o contains:**
```
.text section:
  - main() function code
  - LED initialization
  - LED blinking loop

.rodata section:
  - String constants (if any)
```

---

### Step 2: Assemble startup.s

```bash
arm-none-eabi-gcc -c startup_stm32f446xx.s -o build/startup_stm32f446xx.o
```

**What happens:**
- Assembler reads `startup_stm32f446xx.s` (assembly code)
- Creates object file `build/startup_stm32f446xx.o`
- Contains CPU instructions (lower-level than C)

**startup_stm32f446xx.o contains:**
```
.stack section:
  - 4KB reserved for stack

.text section:
  - Reset_Handler (entry point)
  - Assembly instructions (ldr, bl, b)
```

---

### Step 3: Link With Linker Script

```bash
arm-none-eabi-gcc \
  -T stm32f446_flash.ld \
  build/main.o build/startup_stm32f446xx.o \
  -o build/firmware.elf
```

**What the linker does (using the .ld file):**

1. **Reads the linker script:**
   - "Okay, I have Flash (512KB) and RAM (128KB)"
   - "Code goes in Flash, variables in RAM"

2. **Places Reset_Handler first:**
   - At address 0x08000000 (start of Flash)
   - This must be first so CPU jumps here on power-on

3. **Places main() after Reset_Handler:**
   - At address 0x08000004 (or later)
   - Reset_Handler will call this at 0x08000004

4. **Places variables in RAM:**
   - At 0x20000000
   - Stores initial values in Flash

5. **Creates firmware.elf:**
   - Complete executable with all code and symbols
   - Can be used for debugging

**Result: firmware.elf**
```
Memory layout is now decided:
- Reset_Handler at 0x08000000
- main() at 0x08000100 (example)
- Variables at 0x20000000
- Stack at 0x20000XXX
```

---

### Step 4: Convert to Binary

```bash
arm-none-eabi-objcopy -O binary build/firmware.elf build/firmware.bin
```

**What happens:**
- Takes the ELF executable
- Removes debug symbols
- Extracts only the actual code bytes
- Creates a binary file = **firmware.bin**

**firmware.bin is:**
- Pure machine code
- No debugging info (much smaller)
- Can be programmed directly to STM32 Flash

---

## Summary for Beginners

### Why 3 source files?

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│  main.c              startup_stm32f446xx.s             │
│  ───────              ──────────────────────           │
│  • Your code         • Chip initialization             │
│  • LED blink         • Stack setup                     │
│  • Logic             • First code to run               │
│                                                        │
│             ↓ Compiler & Assembler ↓                  │
│                                                        │
│  main.o              startup_stm32f446xx.o             │
│  ─────────            ───────────────────────          │
│  • Compiled code     • Machine code                    │
│  • Binary format     • Binary format                   │
│                                                        │
│             ↓ Linker (uses .ld script) ↓              │
│                                                        │
│         firmware.elf                                   │
│         ────────────                                   │
│         • Complete executable                         │
│         • All code in right places                    │
│         • Memory layout decided                        │
│                                                        │
│         ↓ Binary converter ↓                          │
│                                                        │
│         firmware.bin                                   │
│         ────────────────                              │
│         • Ready to program to STM32                   │
│         • Just raw code bytes                         │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### Why Linker Script Matters

Without `.ld` file, linker wouldn't know:
- Where to put Reset_Handler? (must be at 0x08000000!)
- How much memory available? (512KB Flash? 128KB RAM?)
- Where to put variables? (Flash or RAM?)
- How big can stack be? (4KB? 8KB?)

**Linker script answers all these questions!**

### The .s and .ld Files Are Essential

- **Without .s (startup):** Chip wakes up but doesn't call your code
- **Without .ld (linker script):** Code placed in wrong memory locations, program crashes

Together, they make the hardware and your C code work together.

---

## Build Process

### Step 1: Compile C Source to Object Files

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfloat-abi=soft \
  -Wall -O2 -ffunction-sections -fdata-sections \
  -c main.c -o build/main.o
```

**Flags Explained:**
- `-mcpu=cortex-m4` = Target ARM Cortex-M4 CPU
- `-mthumb` = Use 16-bit Thumb instruction set
- `-mfloat-abi=soft` = Software floating-point (compatible with all code)
- `-Wall` = Enable all warnings
- `-O2` = Optimization level
- `-ffunction-sections -fdata-sections` = Allow linker to remove unused code
- `-c` = Compile only (generate .o object file)

**Output:** `build/main.o` (compiled object file)

---

### Step 2: Assemble Startup Code to Object File

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfloat-abi=soft \
  -Wall -O2 -ffunction-sections -fdata-sections \
  -c startup_stm32f446xx.s -o build/startup_stm32f446xx.o
```

**Output:** `build/startup_stm32f446xx.o` (startup object file)

---

### Step 3: Link Object Files to ELF Executable

```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb \
  -Wl,--gc-sections \
  -Wl,-Map=build/firmware.map \
  -T stm32f446_flash.ld \
  build/main.o build/startup_stm32f446xx.o \
  -o build/firmware.elf
```

**Linker Flags:**
- `-Wl,--gc-sections` = Remove unused functions/data (reduce size)
- `-Wl,-Map=build/firmware.map` = Generate memory map file
- `-T stm32f446_flash.ld` = Use custom linker script for memory layout

**Output:** `build/firmware.elf` (ELF executable, can be debugged with GDB)

---

### Step 4: Convert ELF to Binary

```bash
arm-none-eabi-objcopy -O binary build/firmware.elf build/firmware.bin
```

**Output:** `build/firmware.bin` ← **This is programmed to the STM32**

---

## Errors Encountered & Solutions

### Error 1: "Unable to locate package arm-none-eabi-gcc"

**Error Message:**
```
E: Unable to locate package arm-none-eabi-gcc
```

**Cause:** Wrong package name or package list not updated.

**Solution 1: Update package list**
```bash
sudo apt update
sudo apt install -y gcc-arm-none-eabi binutils-arm-none-eabi
```

**Solution 2: Find correct package name**
```bash
apt-cache search arm-none-eabi
# Shows: gcc-arm-none-eabi (correct package name)
#        NOT: arm-none-eabi-gcc (this is the binary, not the package)
```

**Key Learning:**
- Package name: `gcc-arm-none-eabi` (what apt understands)
- Binary name: `arm-none-eabi-gcc` (what you run in terminal)

---

### Error 2: "gcc-arm-none-eabi: command not found"

**Error Message:**
```
@USS6 ➜ /workspaces/flyingObject (main) $ gcc-arm-none-eabi --version
bash: gcc-arm-none-eabi: command not found
```

**Cause:** Confused package name with binary name. The package installs binary named `arm-none-eabi-gcc`.

**Solution:**
```bash
# WRONG ❌
gcc-arm-none-eabi --version

# CORRECT ✅
arm-none-eabi-gcc --version
```

---

### Error 3: "unrecognized command-line option '-fFunction-sections'"

**Error Message:**
```
arm-none-eabi-gcc: error: unrecognized command-line option '-fFunction-sections'; did you mean '-ffunction-sections'?
```

**Cause:** Capital 'F' in flag name (typo in Makefile).

**Solution:** Change `-fFunction-sections` to `-ffunction-sections` (lowercase 'f')

**Fixed Makefile line:**
```makefile
CFLAGS += -ffunction-sections -fdata-sections
```

---

### Error 4: "VFP register arguments mismatch" (Floating-Point ABI Error)

**Error Message:**
```
/usr/lib/gcc/arm-none-eabi/13.2.1/../../../arm-none-eabi/bin/ld: error: build/main.o uses VFP register arguments, build/firmware.elf does not
/usr/lib/gcc/arm-none-eabi/13.2.1/../../../arm-none-eabi/bin/ld: failed to merge target specific data of file build/main.o
```

**Cause:** Mismatch between C code and assembly code floating-point settings.
- C code compiled with `-mfloat-abi=hard`
- Assembly startup code compiled without FPU attributes

**Solution 1 (Recommended):** Use soft-float ABI for both

```makefile
# In Makefile
CFLAGS = -mcpu=cortex-m4 -mthumb -mfloat-abi=soft
# Remove: -mfpu=fpv4-sp-d16 -mfloat-abi=hard
```

**Solution 2:** Add FPU attributes to assembly (less compatible)

```asm
# In startup_stm32f446xx.s
.fpu fpv4-sp-d16
.float-abi hard
```

**Note:** Solution 1 (soft-float) is safer and works on all code.

---

## Build Commands

### Build Everything

```bash
cd /workspaces/flyingObject/STM32-NUCLEO-F446RE/PWM
make all
```

**Output:**
```
✓ Firmware built: build/firmware.bin
-rwxrwxrwx 1 codespace codespace 8 May 11 23:00 build/firmware.bin
```

### View Firmware Information

```bash
make verify
```

**Output shows:**
- File type (data/binary)
- Sections (.text, .bss, etc.)
- Memory layout

### Clean Build Artifacts

```bash
make clean
```

Removes `build/` directory.

---

## Understanding the Compiler Toolchain

### arm-none-eabi-gcc Components

When you install `gcc-arm-none-eabi` package, you get:

```
/usr/bin/arm-none-eabi-gcc          # C compiler
/usr/bin/arm-none-eabi-g++          # C++ compiler
/usr/bin/arm-none-eabi-as           # Assembler
/usr/bin/arm-none-eabi-ld           # Linker
/usr/bin/arm-none-eabi-ar           # Archiver (creates static libraries)
/usr/bin/arm-none-eabi-objcopy      # Convert formats (ELF → binary)
/usr/bin/arm-none-eabi-objdump      # Display object info
```

### Compiler Flags for STM32F446RE

| Flag | Value | Meaning |
|------|-------|---------|
| `-mcpu` | `cortex-m4` | Target ARM Cortex-M4 processor |
| `-mthumb` | (none) | Use 16-bit Thumb instruction set |
| `-mfloat-abi` | `soft` or `hard` | How floating-point is handled |
| `-mfpu` | `fpv4-sp-d16` | Floating-point unit (STM32F446 has this) |

**Note:** For maximum compatibility, use `-mfloat-abi=soft` (software FP).

---

## Verification

After building, verify the firmware:

```bash
# Check firmware file
file build/firmware.bin
# Output: data

# Check ELF executable
file build/firmware.elf
# Output: ELF 32-bit LSB executable, ARM, EABI5

# View memory sections
arm-none-eabi-objdump -h build/firmware.elf

# View symbols
arm-none-eabi-nm build/firmware.elf

# Check firmware size
arm-none-eabi-size build/firmware.elf
```

---

## Next Steps

1. **Flash to Board (requires ST-Link):**
   ```bash
   sudo apt install -y openocd
   openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
     -c "init; program build/firmware.bin 0x08000000; reset; shutdown"
   ```

2. **Debug with GDB:**
   ```bash
   arm-none-eabi-gdb build/firmware.elf
   ```

3. **Modify Code:**
   - Edit `main.c` to add new features
   - Run `make all` to rebuild
   - Repeat as needed

---

## Summary

| Step | Command | Output |
|------|---------|--------|
| **Compile** | `arm-none-eabi-gcc -c main.c` | `main.o` |
| **Assemble** | `arm-none-eabi-gcc -c startup.s` | `startup_stm32f446xx.o` |
| **Link** | `arm-none-eabi-gcc ... -o firmware.elf` | `firmware.elf` |
| **Convert** | `arm-none-eabi-objcopy -O binary` | `firmware.bin` ← Program this! |

**Key Concepts:**
- Package name ≠ Binary name (`gcc-arm-none-eabi` ≠ `arm-none-eabi-gcc`)
- Always use `arm-none-eabi-gcc` for STM32 (not `gcc`)
- Floating-point ABI must match across all code
- Use soft-float ABI (`-mfloat-abi=soft`) for compatibility

---

Created: May 11, 2026
