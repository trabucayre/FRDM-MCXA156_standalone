/*
 * Bare-minimal blinky for FRDM-MCXA156: red LED on P3_12 (active low).
 * No board/clock_config/pin_mux files: runs on the reset clock (FRO12M).
 */
#include "fsl_clock.h"
#include "fsl_reset.h"
#include "fsl_gpio.h"
#include "fsl_port.h"

#include "fsl_debug_console.h"

#define LED_GPIO GPIO3
#define LED_PORT PORT3
#define LED_PIN  12U

static volatile uint32_t ms_ticks;

void SysTick_Handler(void)
{
	ms_ticks++;
}

static void delay_ms(uint32_t ms)
{
	uint32_t start = ms_ticks;
	while ((ms_ticks - start) < ms) {}
}

/* Debug console: LPUART0 on P0_2 (RX) / P0_3 (TX), routed to the MCU-Link VCOM */
static void uart_init(void)
{
	CLOCK_EnableClock(kCLOCK_GatePORT0);
	RESET_ReleasePeripheralReset(kPORT0_RST_SHIFT_RSTn);
	RESET_ReleasePeripheralReset(kLPUART0_RST_SHIFT_RSTn);

	PORT_SetPinMux(PORT0, 2U, kPORT_MuxAlt2);
	PORT_SetPinMux(PORT0, 3U, kPORT_MuxAlt2);
	PORT0->PCR[2] |= PORT_PCR_IBE_MASK | PORT_PCR_PE_MASK | PORT_PCR_PS_MASK; /* RX: input, pull-up */
	PORT0->PCR[3] |= PORT_PCR_IBE_MASK;

	CLOCK_SetClockDiv(kCLOCK_DivLPUART0, 1U);
	CLOCK_AttachClk(kFRO12M_to_LPUART0);

	DbgConsole_Init(0U, 115200U, kSerialPort_Uart, CLOCK_GetLpuartClkFreq(0U));
}

static void clock_init()
{
	/* Clocks + reset release for GPIO3 / PORT3 */
	CLOCK_EnableClock(kCLOCK_GateGPIO3);
	CLOCK_EnableClock(kCLOCK_GatePORT3);
	RESET_ReleasePeripheralReset(kGPIO3_RST_SHIFT_RSTn);
	RESET_ReleasePeripheralReset(kPORT3_RST_SHIFT_RSTn);
}

static void gpio_init()
{
	/* P3_12 as GPIO */
	PORT_SetPinMux(LED_PORT, LED_PIN, kPORT_MuxAlt0);
	LED_PORT->PCR[LED_PIN] |= PORT_PCR_IBE_MASK;

	gpio_pin_config_t led = {kGPIO_DigitalOutput, 1U}; /* 1 = LED off */
	GPIO_PinInit(LED_GPIO, LED_PIN, &led);

}

int main(void)
{
	clock_init();
	gpio_init();

	uart_init();

	SystemCoreClockUpdate();
	SysTick_Config(SystemCoreClock / 1000U);

	while (1) {
		GPIO_PortToggle(LED_GPIO, 1U << LED_PIN);
		PRINTF("hello world from Standalone Toolchain\r\n");
		delay_ms(500U/4);
	}
}
