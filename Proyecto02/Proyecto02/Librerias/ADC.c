/*
 * ADC.c
 *
 *  Author: Lucia Catú
 */ 
#include "ADC.h"

void ADC_Init(void)
{
	// Referencia AVcc, canal inicial ADC0
	ADMUX = (1 << REFS0);

	// Habilitar ADC con prescaler 128
	// 16 MHz / 128 = 125 kHz
	ADCSRA = (1 << ADEN)  |
	(1 << ADPS2) |
	(1 << ADPS1) |
	(1 << ADPS0);
}

uint16_t ADC_Read(uint8_t canal)
{
	canal = canal & 0x0F;

	// Mantiene AVcc como referencia y cambia solo el canal
	ADMUX = (ADMUX & 0xF0) | canal;

	// Iniciar conversión
	ADCSRA |= (1 << ADSC);

	// Esperar a que termine la conversión
	while (ADCSRA & (1 << ADSC));

	return ADC;
}