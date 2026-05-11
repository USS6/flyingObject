/* Minimal STM32F446 Startup Code */

/* Core target and syntax */
.syntax unified
.cpu cortex-m4
.thumb

/* Stack configuration */
.section .stack
.align 3
.globl __StackTop
Stack_Mem:
    .space 0x1000  /* 4KB stack */
__StackTop:

/* Vector table */
.section .vectors,"a",%progbits
.align 2
.globl __isr_vector
__isr_vector:
    .word __StackTop          /* Initial stack pointer */
    .word Reset_Handler       /* Reset handler */
    .word NMI_Handler         /* NMI handler */
    .word HardFault_Handler   /* HardFault handler */
    .word MemManage_Handler   /* MPU fault handler */
    .word BusFault_Handler    /* Bus fault handler */
    .word UsageFault_Handler  /* Usage fault handler */
    .word 0                   /* Reserved */
    .word 0                   /* Reserved */
    .word 0                   /* Reserved */
    .word 0                   /* Reserved */
    .word SVC_Handler         /* SVCall handler */
    .word DebugMon_Handler    /* Debug monitor handler */
    .word 0                   /* Reserved */
    .word PendSV_Handler      /* PendSV handler */
    .word SysTick_Handler     /* SysTick handler */

/* Default interrupt handlers */
.section .text
.thumb_func
.globl Reset_Handler
Reset_Handler:
    ldr sp, =__StackTop
    bl main
    b .

.thumb_func
.globl NMI_Handler
NMI_Handler:
    b .

.thumb_func
.globl HardFault_Handler
HardFault_Handler:
    b .

.thumb_func
.globl MemManage_Handler
MemManage_Handler:
    b .

.thumb_func
.globl BusFault_Handler
BusFault_Handler:
    b .

.thumb_func
.globl UsageFault_Handler
UsageFault_Handler:
    b .

.thumb_func
.globl SVC_Handler
SVC_Handler:
    b .

.thumb_func
.globl DebugMon_Handler
DebugMon_Handler:
    b .

.thumb_func
.globl PendSV_Handler
PendSV_Handler:
    b .

.thumb_func
.globl SysTick_Handler
SysTick_Handler:
    b .
