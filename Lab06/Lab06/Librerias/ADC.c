/*
 * ADC.c
 *
 * Author: Lucia Catu
 */

#define F_CPU 16000000UL   
#include "ADC.h"          

	//Inicializa el módulo ADC.

void ADC_iniciar(void)
{
	ADMUX = (1 << REFS0); // Referencia de voltaje 
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilita ADC y configura prescaler 
	DIDR0 = (1 << ADC2D); // Deshabilita buffer digital en pin ADC2
}


	// Realiza una conversión analógica en el canal indicado.

uint16_t ADC_leer(uint8_t canal)
{
	canal &= 0x07;
	ADMUX = (ADMUX & 0xF0) | canal | (1 << REFS0); // Mantiene referencia y selecciona canal

	ADCSRA |= (1 << ADSC); // Inicia conversión
	while (ADCSRA & (1 << ADSC)) // Espera hasta que termine la conversión
	{
	}
	return ADC; // Devuelve resultado de 10 bits
}