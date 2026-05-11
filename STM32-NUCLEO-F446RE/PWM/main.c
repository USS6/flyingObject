/**
 * STM32F446RE Minimal Firmware Example
 * Blinks LED on LD2 (Pin PA5) using busy-wait delay
 */

/* Register definitions (simplified) */
#define RCC_BASE       0x40023800
#define GPIOA_BASE     0x40020000

#define RCC_AHB1ENR    (*(volatile unsigned int *)(RCC_BASE + 0x30))
#define GPIOA_MODER    (*(volatile unsigned int *)(GPIOA_BASE + 0x00))
#define GPIOA_ODR      (*(volatile unsigned int *)(GPIOA_BASE + 0x14))

/* Simple delay function */
void delay(unsigned int count) {
    while (count--) {
        __asm("nop");  /* no operation */
    }
}

/* Main function */
int main(void) {
    /* Enable GPIOA clock (bit 0 of AHB1ENR) */
    RCC_AHB1ENR |= 0x00000001;
    
    /* Configure PA5 as output (bits 10-11 = 01) */
    GPIOA_MODER &= ~(0x00000C00);  /* Clear bits 10-11 */
    GPIOA_MODER |= 0x00000400;     /* Set bits 10-11 to 01 (output mode) */
    
    /* Toggle LED forever */
    while (1) {
        /* Set PA5 (turn on LED) */
        GPIOA_ODR |= 0x00000020;
        delay(500000);
        
        /* Clear PA5 (turn off LED) */
        GPIOA_ODR &= ~0x00000020;
        delay(500000);
    }
    
    return 0;
}
