	.cpu arm7tdmi
	.arch armv4t
	.fpu softvfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"main.c"
	.text
	.align	2
	.global	delay
	.syntax unified
	.arm
	.type	delay, %function
delay:
	@ Function supports interworking.
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	b	.L2
.L3:
	.syntax divided
@ 17 "main.c" 1
	nop
@ 0 "" 2
	.arm
	.syntax unified
.L2:
	ldr	r3, [fp, #-8]
	sub	r2, r3, #1
	str	r2, [fp, #-8]
	cmp	r3, #0
	bne	.L3
	nop
	nop
	add	sp, fp, #0
	@ sp needed
	ldr	fp, [sp], #4
	bx	lr
	.size	delay, .-delay
	.align	2
	.global	main
	.syntax unified
	.arm
	.type	main, %function
main:
	@ Function supports interworking.
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	ldr	r3, .L6
	ldr	r3, [r3]
	ldr	r2, .L6
	orr	r3, r3, #1
	str	r3, [r2]
	ldr	r3, .L6+4
	ldr	r3, [r3]
	ldr	r2, .L6+4
	bic	r3, r3, #3072
	str	r3, [r2]
	ldr	r3, .L6+4
	ldr	r3, [r3]
	ldr	r2, .L6+4
	orr	r3, r3, #1024
	str	r3, [r2]
.L5:
	ldr	r3, .L6+8
	ldr	r3, [r3]
	ldr	r2, .L6+8
	orr	r3, r3, #32
	str	r3, [r2]
	ldr	r0, .L6+12
	bl	delay
	ldr	r3, .L6+8
	ldr	r3, [r3]
	ldr	r2, .L6+8
	bic	r3, r3, #32
	str	r3, [r2]
	ldr	r0, .L6+12
	bl	delay
	b	.L5
.L7:
	.align	2
.L6:
	.word	1073887280
	.word	1073872896
	.word	1073872916
	.word	500000
	.size	main, .-main
	.ident	"GCC: (15:13.2.rel1-2) 13.2.1 20231009"
