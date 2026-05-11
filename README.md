# flyingObject
flyingObject is a repository created to work on embedded product which can fly.

CREATING BUILD SYSTEM FOR STM32 IN CODESPACE: (05/12)
1.Update linux packages to latest version
sudo apt update (Error seen if sudo not used as the update is not requested as root user)
2(For linux based compiling).Get gcc compiler and build tools to compile C/C++ code
    (sudo apt install -y build-essential git wget) 
    VERIFY: gcc --version, g++ --version, make --version, ar --version(archiver tool manages static library files) 
    NOTES: Why ar(archive) tool is needed? 
        1.Helps to convert multiple object files to a single static library file.
        (ar rcs libsample.a sample1.o sample2.o)
        2.Static library file generated, can then be used to link files to generate ELF file 
        (arm-none-eabi-gcc main.o -L. -lsample -o finalsample.elf) - 
            -L. - says file can be found in current directory
            -lsample - abbreviated for libsample.a
        3.A much direct approach can be done using below command 
        (arm-none-eabi-gcc main.o ./libsample.a -o finalsample.elf)
2(For ARM based compiling).Get ARM compiler for STM32
    2.1.Search arm gcc compiler using (apt-cache search arm-none-eabi)
        OUTPUT: gcc-arm-none-eabi - GCC cross compiler for ARM Cortex-R/M processors
                binutils-arm-none-eabi - GNU assembler, linker and binary utilities for ARM Cortex-R/M processors
        NOTES: arm-none-eabi - arm - processor, none - no OS, eabi - Embedded Application Binary Interface (calling conventions for ARM)
               gcc-arm-none-eabi - Is just package name and should not be missunderstood for compiler name 
    2.2.Install compiler using (sudo apt install -y gcc-arm-none-eabi)
        VERIFY: dpkg -L gcc-arm-none-eabi | grep /usr/bin
        OUTPUT: ...
                /usr/bin/arm-none-eabi-gcc
                ...
                Based on above output, arm gcc compiler name can be picked as "arm-none-eabi-gcc"
    2.3.Install binutils (sudo apt install binutils-arm-none-eabi)
        VERIFY: dpkg -L binutils-arm-none-eabi | grep /usr/bin
        OUTPUT: ...
                /usr/bin/arm-none-eabi-objcopy
                /usr/bin/arm-none-eabi-objdump
                ...
                /usr/bin/arm-none-eabi-readelf
                /usr/bin/arm-none-eabi-size
                ...
    2.4.Install make file (sudo apt install make)