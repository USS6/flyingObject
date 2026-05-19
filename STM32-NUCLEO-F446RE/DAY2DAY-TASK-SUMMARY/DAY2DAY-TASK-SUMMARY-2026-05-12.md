# DAY2DAY TASK SUMMARY - 2026-05-12

## Summary

This file captures the Day 2 progress on the STM32F446RE project in Codespace and Windows.

### What was completed
- Confirmed the difference between host `gcc` and cross compiler `arm-none-eabi-gcc`
- Installed ARM toolchain packages: `gcc-arm-none-eabi` and `binutils-arm-none-eabi`
- Verified ARM toolchain binaries with `arm-none-eabi-gcc --version` and `ls /usr/bin/arm-none-eabi-*`
- Added a `Makefile` to automate build steps for `main.c`, `startup_stm32f446xx.s`, and `stm32f446_flash.ld`
- Created a README inside `STM32-NUCLEO-F446RE/PWM` documenting the full build and flashing workflow
- Built sample STM32 firmware in Codespace successfully
- Added `.gitignore` to exclude build output from git
- Committed source files and guide content to git
- Added STM32 reference PDFs to the repository
- Set up Windows OpenOCD flashing and corrected command syntax until flashing succeeded
- Identified and fixed the startup vector / reset handler issue by updating `startup_stm32f446xx.s`

### Key learning points
- `gcc` is for host builds, while `arm-none-eabi-gcc` is for bare-metal ARM firmware
- Ubuntu package names and executable names differ: `gcc-arm-none-eabi` installs the binary `arm-none-eabi-gcc`
- The `.ld` linker script is essential to place code in Flash and RAM correctly
- A proper vector table is required at `0x08000000` for STM32 boot
- `openocd` requires the `program` command and correct path syntax on Windows
- `make all`, `make clean`, and `make verify` are useful build workflow commands

### Files added / changed
- `STM32-NUCLEO-F446RE/PWM/main.c`
- `STM32-NUCLEO-F446RE/PWM/startup_stm32f446xx.s`
- `STM32-NUCLEO-F446RE/PWM/stm32f446_flash.ld`
- `STM32-NUCLEO-F446RE/PWM/Makefile`
- `STM32-NUCLEO-F446RE/PWM/README.md`
- `.gitignore`
- `STM32-NUCLEO-F446RE/rm0390-stm32f446xx-advanced-armbased-32bit-mcus-stmicroelectronics.pdf`
- `STM32-NUCLEO-F446RE/stm32f446mc.pdf`

### Notes for next session
- Add a `flash-windows.md` section in the PWM README for the exact Windows OpenOCD command
- Consider adding a simple `gdb` debug workflow example
- Optionally add a `startup_stm32f446xx.s` explanation section showing the vector table structure more clearly
