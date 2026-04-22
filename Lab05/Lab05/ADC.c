/*
 * ADC.c
 *
 * Created: 
 *  Author: lucia catu
 */ 

#include <avr/io.h>
#include "ADC.h"

void initADC(void)
{
	ADMUX = (1 << REFS0);
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t readADC(uint8_t channel)
{
	channel &= 0x07;
	ADMUX = (ADMUX & 0xF8) | channel;
	
	// Hacemos una primera conversión y no la guardamos para dar tiempo para estabilizar la señal
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));

	uint32_t suma = 0;
	// promedio de 8 lecturas
	for (uint8_t i = 0; i < 8; i++)
	{
		ADCSRA |= (1 << ADSC);
		while (ADCSRA & (1 << ADSC));
		suma += ADC;
	}
	return (uint16_t)(suma / 8);
}