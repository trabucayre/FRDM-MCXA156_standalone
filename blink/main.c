/*
 * Bare-minimal blinky for FRDM-MCXA156: red LED on P3_12 (active low).
 * No board/clock_config/pin_mux files: runs on the reset clock (FRO12M).
 */
#include "fsl_clock.h"
#include "fsl_reset.h"
#include "fsl_gpio.h"
#include "fsl_port.h"

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
    while ((ms_ticks - start) < ms)
    {
    }
}

int main(void)
{
    /* Clocks + reset release for GPIO3 / PORT3 */
    CLOCK_EnableClock(kCLOCK_GateGPIO3);
    CLOCK_EnableClock(kCLOCK_GatePORT3);
    RESET_ReleasePeripheralReset(kGPIO3_RST_SHIFT_RSTn);
    RESET_ReleasePeripheralReset(kPORT3_RST_SHIFT_RSTn);

    /* P3_12 as GPIO */
    PORT_SetPinMux(LED_PORT, LED_PIN, kPORT_MuxAlt0);
    LED_PORT->PCR[LED_PIN] |= PORT_PCR_IBE_MASK;

    gpio_pin_config_t led = {kGPIO_DigitalOutput, 1U}; /* 1 = LED off */
    GPIO_PinInit(LED_GPIO, LED_PIN, &led);

    SystemCoreClockUpdate();
    SysTick_Config(SystemCoreClock / 1000U);

    while (1)
    {
        GPIO_PortToggle(LED_GPIO, 1U << LED_PIN);
        delay_ms(500U);
    }
}
