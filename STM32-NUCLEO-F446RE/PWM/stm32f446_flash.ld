/* STM32F446RE Memory Layout
   Flash: 512KB (0x08000000 - 0x0807FFFF)
   RAM:   128KB (0x20000000 - 0x2001FFFF)
*/

MEMORY
{
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 512K
  RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 128K
}

SECTIONS
{
  .text : {
    KEEP(*(.vectors))
    *(.text*)
    *(.rodata*)
  } > FLASH
  
  .data : {
    *(.data*)
  } > RAM AT > FLASH
  
  .bss : {
    *(.bss*)
    *(COMMON)
  } > RAM
  
  /DISCARD/ : {
    *(.note.GNU-stack)
  }
}
