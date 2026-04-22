/*
 * PWM2.c
 *
 * Created: 
 *  Author: 
 */ 

#include <avr/io.h>
#include "PWM2.h"

void initPWM2A(void)
{
	DDRB |= (1 << DDB3); // D11 como salida
	
	TCCR2A = 0;
	TCCR2B = 0;

	// Modo 3 Fast PWM de 8 bits
	TCCR2A |= (1 << WGM21) | (1 << WGM20);
	TCCR2A |= (1 << COM2A1);

	// Prescaler = 1024 (CS22 = 1, CS21 = 1, CS20 = 1)
	TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20);
	
	// Posición inicial
	OCR2A = 23;
}

void updatePWM2A(uint8_t duty)
{
	OCR2A = duty;
}