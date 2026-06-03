# 0 "./STM32-NUCLEO-F446RE/PWM/main.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "./STM32-NUCLEO-F446RE/PWM/main.c"
# 15 "./STM32-NUCLEO-F446RE/PWM/main.c"
void delay(unsigned int count) {
    while (count--) {
        __asm("nop");
    }
}


int main(void) {

    (*(volatile unsigned int *)(0x40023800 + 0x30)) |= 0x00000001;


    (*(volatile unsigned int *)(0x40020000 + 0x00)) &= ~(0x00000C00);
    (*(volatile unsigned int *)(0x40020000 + 0x00)) |= 0x00000400;


    while (1) {

        (*(volatile unsigned int *)(0x40020000 + 0x14)) |= 0x00000020;
        delay(500000);


        (*(volatile unsigned int *)(0x40020000 + 0x14)) &= ~0x00000020;
        delay(500000);
    }

    return 0;
}
