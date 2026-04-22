/*
 * PWM_manual.c
 *
 * Created:
 *  Author: 
 */ 

#include <avr/io.h>
#include <avr/interrupt.h> 
#include "PWM_Manual.h"

volatile uint8_t contador_pwm = 0;
volatile uint8_t limite_pwm = 0;

void initPWM_Manual(void)
{
	// Configurar PD6 (D6) como salida para el LED
	DDRD |= (1 << DDD6);

	// Timer 0 en modo Normal (cuenta hasta 255 y hace overflow)
	TCCR0A = 0;
	TCCR0B = 0;

	// sin prescaler 
	TCCR0B |= (1 << CS00);

	// Habilitar la interrupción overflow del Timer0
	TIMSK0 |= (1 << TOIE0);
}

void updatePWM_Manual(uint8_t duty)
{
	limite_pwm = duty;
}

//rutina de interrupción por overflow timer0
ISR(TIMER0_OVF_vect)
{
	contador_pwm++; 
	
	// El contador en cero deberá poner una salida en alto
	if (contador_pwm == 0)
	{
		// si el límite es 0, no lo encendemos para evitar destellos
		if (limite_pwm > 0) {
			PORTD |= (1 << PORTD6); // PD6 en ALTO
		}
	}
	
	// cuándo este llegue al valor seteado, poner en cero
	if (contador_pwm == limite_pwm)
	{
		PORTD &= ~(1 << PORTD6); // PD6 en BAJO
	}
}