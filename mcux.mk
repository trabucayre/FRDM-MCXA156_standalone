CROSS_COMPILE ?= arm-none-eabi-
BASE_DIR      ?= ../

CC      := $(CROSS_COMPILE)gcc
CXX     := $(CROSS_COMPILE)g++
LD      := $(CROSS_COMPILE)gcc
AR      := $(CROSS_COMPILE)ar
AS      := $(CROSS_COMPILE)as
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

MCUX_LIB_DIR       ?= $(BASE_DIR)/nxp_libs
MCUX_DEVICES_DIR    = ${MCUX_LIB_DIR}/mcux-devices-mcx
MCUX_CORE_DIR       = ${MCUX_LIB_DIR}/mcuxsdk-core
MCUX_COMPONENTS_DIR = ${MCUX_LIB_DIR}/mcux-component
MCUX_CMSIS_DIR      = ${MCUX_LIB_DIR}/mcu-sdk-cmsis

###############################################################################
# Device description (MCXA156). Specific to the target chip.
###############################################################################
MCUX_DEVICE   = MCXA156
MCUX_CPU_PART = CPU_MCXA156VLL

# Cross-compiler configurations/flags
MCUX_CPU_FLAGS = -mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16

# some variables to points device/target BSP
MCUX_DEVICE_DIR  = ${MCUX_DEVICES_DIR}/MCXA/${MCUX_DEVICE}
MCUX_PERIPH_DIR  = ${MCUX_DEVICES_DIR}/MCXA/periph1
SDK_DEFINES      = -D${MCUX_CPU_PART} -D${MCUX_DEVICE}_SERIES \
	-D__STARTUP_CLEAR_BSS -DMCUXPRESSO_SDK
LDSCRIPT         = ${MCUX_DEVICE_DIR}/gcc/${MCUX_DEVICE}_flash.ld

###############################################################################
# mcux_sdk_configure(<target>)
###############################################################################
# basic requirement:
# - startup, SystemInit, clock/reset, fsl_common, and 
#   newlib syscall stubs (_write/_read/... + _sbrk).
SDK_SRCS = \
	${MCUX_DEVICE_DIR}/gcc/startup_${MCUX_DEVICE}.S \
	${MCUX_DEVICE_DIR}/system_${MCUX_DEVICE}.c \
	${MCUX_DEVICE_DIR}/drivers/fsl_clock.c \
	${MCUX_DEVICE_DIR}/drivers/fsl_reset.c \
	${MCUX_CORE_DIR}/drivers/common/fsl_common.c \
	${MCUX_CORE_DIR}/drivers/common/fsl_common_arm.c \
	${MCUX_COMPONENTS_DIR}/misc_utilities/fsl_syscall_stub.c \
	${MCUX_COMPONENTS_DIR}/misc_utilities/fsl_sbrk.c

SDK_INC = \
	-I${MCUX_DEVICE_DIR} \
	-I${MCUX_PERIPH_DIR} \
	-I${MCUX_DEVICE_DIR}/drivers \
	-I${MCUX_CMSIS_DIR}/Core/Include \
	-I${MCUX_CMSIS_DIR}/Core/Include/m-profile \
	-I${MCUX_CORE_DIR}/drivers/common

# Some useful source/include
# - control port and GPIOs
SDK_INC += \
	-I${MCUX_CORE_DIR}/drivers/port \
	-I${MCUX_CORE_DIR}/drivers/gpio
SDK_SRCS += \
	${MCUX_CORE_DIR}/drivers/gpio/fsl_gpio.c

# UART + debug console lite
SDK_INC += \
	-I${MCUX_COMPONENTS_DIR}/debug_console_lite \
	-I${MCUX_COMPONENTS_DIR}/str \
	-I${MCUX_COMPONENTS_DIR}/uart \
	-I${MCUX_CORE_DIR}/drivers/lpuart

SDK_SRCS += \
	${MCUX_COMPONENTS_DIR}/debug_console_lite/fsl_debug_console.c \
	${MCUX_COMPONENTS_DIR}/str/fsl_str.c \
	${MCUX_COMPONENTS_DIR}/uart/fsl_adapter_lpuart.c \
	${MCUX_CORE_DIR}/drivers/lpuart/fsl_lpuart.c

SDK_DEFINES += -DSDK_DEBUGCONSOLE=1

SRCS += $(TARGET).c

# Adds the full configuration/linker script/... to cmake
# for cross-compile step.
CFLAGS = $(MCUX_CPU_FLAGS) $(SDK_DEFINES) $(SDK_INC) --specs=picolibc.specs \
	-Wall -ffunction-sections -fdata-sections -fno-common -fno-builtin

ASMFLAGS = $(MCUX_CPU_FLAGS) $(SDK_DEFINES) -D__START=main $(SDK_INC) --specs=picolibc.specs \
	-ffunction-sections -fdata-sections -fno-common -fno-builtin

LDFLAGS = ${MCUX_CPU_FLAGS} --specs=picolibc.specs --crt0=none \
	-T${LDSCRIPT} -Wl,--gc-sections -Wl,--print-memory-usage \
	-Wl,--no-warn-rwx-segments -Wl,-Map=$(TARGET).map

SDK_BUILD_DIR ?= $(BASE_DIR)/sdk_build
SDK_LIB       := $(SDK_BUILD_DIR)/libmcux_sdk.a

LDLIBS = -Wl,--start-group $(SDK_LIB) -lm -lc -lgcc -Wl,--end-group -ldummyhost

SDK_OBJS := $(addprefix $(SDK_BUILD_DIR)/,$(addsuffix .o,$(basename $(notdir $(SDK_SRCS)))))
OBJS     := $(SRCS:.c=.o)

vpath %.c $(dir $(SDK_SRCS))
vpath %.S $(dir $(SDK_SRCS))

.SECONDARY: $(OBJS)

all: bin
elf: $(TARGET).elf
hex: $(TARGET).hex
bin: $(TARGET).bin

test:
	echo $(OBJS)

%.o: %.S
	$(CC) $(ASMFLAGS) -o $@ -c $<

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

%.o: %.cxx
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $<

%.bin: %.elf
	$(OBJCOPY) -Obinary $< $@
%.hex: %.elf
	$(OBJCOPY) -Oihex $< $@
$(SDK_BUILD_DIR):
	mkdir -p $@

$(SDK_BUILD_DIR)/%.o: %.S | $(SDK_BUILD_DIR)
	$(CC) $(ASMFLAGS) -o $@ -c $<

$(SDK_BUILD_DIR)/%.o: %.c | $(SDK_BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ -c $<

$(SDK_LIB): $(SDK_OBJS)
	$(AR) rcs $@ $?

%.elf: $(OBJS) $(SDK_LIB) $(LDSCRIPT)
	$(LD) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@

flash: $(TARGET).bin
	pyocd load -t mcxa156vll $<

clean:
	@rm -f *.map $(OBJS) *.elf *.hex *.bin

clean-all: clean
	@rm -rf $(BASE_DIR)/sdk_build
