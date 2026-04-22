/*
 * PWM1.c
 *
 * Created: 
 *  Author:
 */ 


#include <avr/io.h>
#include "PWM1.h"

void initPWM1A(void)
{
	//configuración del timer 1
	DDRB |= (1 << DDB1);
	TCCR1A = 0;
	TCCR1B = 0;
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM13) | (1 << WGM12);
	TCCR1A |= (1 << COM1A1);
	TCCR1B |= (1 << CS11);
	
	//pocisión inicial
	ICR1 = 39999;
	
	updateServoPWM1A(1500);
}

void updateServoPWM1A(uint16_t us)
{
	OCR1A = us * 2;
}
