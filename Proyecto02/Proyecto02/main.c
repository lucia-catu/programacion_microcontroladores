/*
 * Proyecto02.c
 *
 * Author : Lucia Catú
 */ 

#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>

#include "Librerias/ADC.h"
#include "Librerias/USART.h"
#include "Librerias/PWM_Servo.h"

// LEDs
#define LED_MANUAL  PD4   // D4
#define LED_UART    PD5   // D5
#define LED_EEPROM  PD6   // D6

uint16_t Convertir_ADC_A_Pulso(uint16_t valor_adc)
{
	// Convierte ADC 0-1023 a pulso 1000-2000 us
	return 1000 + ((uint32_t)valor_adc * 1000) / 1023;
}

void LEDs_Init(void)
{
	DDRD |= (1 << LED_MANUAL);
	DDRD |= (1 << LED_UART);
	DDRD |= (1 << LED_EEPROM);

	PORTD &= ~(1 << LED_MANUAL);
	PORTD &= ~(1 << LED_UART);
	PORTD &= ~(1 << LED_EEPROM);
}

void Modo_Manual_LED(void)
{
	PORTD |=  (1 << LED_MANUAL);
	PORTD &= ~(1 << LED_UART);
	PORTD &= ~(1 << LED_EEPROM);
}

int main(void)
{
	uint16_t adc0;
	uint16_t adc1;
	uint16_t adc2;
	uint16_t adc3;

	uint16_t pulso1;
	uint16_t pulso2;
	uint16_t pulso3;
	uint16_t pulso4;

	ADC_Init();
	USART_Init(9600);
	PWM_Servo_Init();
	LEDs_Init();

	Modo_Manual_LED();

	sei();

	USART_TransmitString("Arduino Nano - Modo manual iniciado\r\n");

	while (1)
	{
		adc0 = ADC_Read(0); // A0
		adc1 = ADC_Read(1); // A1
		adc2 = ADC_Read(2); // A2
		adc3 = ADC_Read(3); // A3

		pulso1 = Convertir_ADC_A_Pulso(adc0);
		pulso2 = Convertir_ADC_A_Pulso(adc1);
		pulso3 = Convertir_ADC_A_Pulso(adc2);
		pulso4 = Convertir_ADC_A_Pulso(adc3);

		PWM_Servo_SetPulse(0, pulso1);
		PWM_Servo_SetPulse(1, pulso2);
		PWM_Servo_SetPulse(2, pulso3);
		PWM_Servo_SetPulse(3, pulso4);

		_delay_ms(20);
	}
}
