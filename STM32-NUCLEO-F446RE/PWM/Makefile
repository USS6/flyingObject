# STM32F446RE Makefile

# Compiler and Tools
CC = arm-none-eabi-gcc
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OC = arm-none-eabi-objcopy
OD = arm-none-eabi-objdump

# Project name
TARGET = firmware

# Output directory
BUILD_DIR = build

# Source and object files
SOURCES = main.c startup_stm32f446xx.s
OBJECTS = $(addprefix $(BUILD_DIR)/, $(SOURCES:.c=.o))
OBJECTS := $(OBJECTS:.s=.o)

# Compiler flags for ARM Cortex-M4
CFLAGS = -mcpu=cortex-m4
CFLAGS += -mthumb
CFLAGS += -mfloat-abi=soft
CFLAGS += -Wall -O2
CFLAGS += -ffunction-sections -fdata-sections

# Linker flags
LDFLAGS = -mcpu=cortex-m4
LDFLAGS += -mthumb
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/$(TARGET).map
LDFLAGS += -T stm32f446_flash.ld

# Build rules
.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET).bin

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@
	arm-none-eabi-size $@

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OC) -O binary $< $@
	@echo "✓ Firmware built: $(BUILD_DIR)/$(TARGET).bin"
	@ls -lh $(BUILD_DIR)/$(TARGET).bin

clean:
	rm -rf $(BUILD_DIR)

verify:
	@echo "=== FIRMWARE INFO ==="
	@file $(BUILD_DIR)/$(TARGET).bin || echo "Binary not built yet"
	@ls -lh $(BUILD_DIR)/$(TARGET).bin $(BUILD_DIR)/$(TARGET).elf 2>/dev/null || echo "Build first with: make all"
	@echo ""
	@echo "=== MEMORY MAP ==="
	@arm-none-eabi-objdump -h $(BUILD_DIR)/$(TARGET).elf 2>/dev/null | grep -E "Idx|LOAD" || echo "Build first with: make all"
