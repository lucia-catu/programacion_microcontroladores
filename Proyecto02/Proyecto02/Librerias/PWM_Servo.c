/*
 * PWM_Servo.h
 *
 *  Author: Lucia Catú
 */ 


#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include "PWM_Servo.h"
#include <avr/interrupt.h>
#include <util/atomic.h>

#define SERVO_MIN_US 1000
#define SERVO_MAX_US 2000
#define PERIODO_SERVO_US 20000

// Arduino Nano / ATmega328P
// Servo 1 -> D7  -> PD7
// Servo 2 -> D8  -> PB0
// Servo 3 -> D9  -> PB1
// Servo 4 -> D10 -> PB2

volatile uint16_t pulso_servo_us[NUM_SERVOS] = {
	1500, 1500, 1500, 1500
};

volatile uint8_t servo_actual = 0;

static uint16_t us_to_ocr(uint16_t tiempo_us)
{
	// Timer1 con prescaler 8:
	// 16 MHz / 8 = 2 MHz
	// 1 tick = 0.5 us
	// 1 us = 2 ticks
	return (tiempo_us * 2) - 1;
}

static void Servo_Pin_High(uint8_t servo)
{
	switch (servo)
	{
		case 0:
		PORTD |= (1 << PD7); // D7
		break;

		case 1:
		PORTB |= (1 << PB0); // D8
		break;

		case 2:
		PORTB |= (1 << PB1); // D9
		break;

		case 3:
		PORTB |= (1 << PB2); // D10
		break;
	}
}

static void Servo_Pin_Low(uint8_t servo)
{
	switch (servo)
	{
		case 0:
		PORTD &= ~(1 << PD7); // D7
		break;

		case 1:
		PORTB &= ~(1 << PB0); // D8
		break;

		case 2:
		PORTB &= ~(1 << PB1); // D9
		break;

		case 3:
		PORTB &= ~(1 << PB2); // D10
		break;
	}
}

static void Servo_All_Low(void)
{
	PORTD &= ~(1 << PD7);

	PORTB &= ~(1 << PB0);
	PORTB &= ~(1 << PB1);
	PORTB &= ~(1 << PB2);
}

void PWM_Servo_Init(void)
{
	// Configurar pines de servos como salida
	DDRD |= (1 << DDD7); // D7

	DDRB |= (1 << DDB0); // D8
	DDRB |= (1 << DDB1); // D9
	DDRB |= (1 << DDB2); // D10

	Servo_All_Low();

	// Configurar Timer1 en modo CTC
	TCCR1A = 0;
	TCCR1B = 0;
	TCNT1 = 0;

	// Primer tiempo de comparación
	OCR1A = us_to_ocr(pulso_servo_us[0]);

	// Modo CTC con OCR1A como comparación
	TCCR1B |= (1 << WGM12);

	// Prescaler 8
	TCCR1B |= (1 << CS11);

	// Habilitar interrupción por comparación A
	TIMSK1 |= (1 << OCIE1A);

	servo_actual = 0;
	Servo_Pin_High(servo_actual);
}

void PWM_Servo_SetPulse(uint8_t servo, uint16_t pulso_us)
{
	if (servo >= NUM_SERVOS)
	{
		return;
	}

	if (pulso_us < SERVO_MIN_US)
	{
		pulso_us = SERVO_MIN_US;
	}

	if (pulso_us > SERVO_MAX_US)
	{
		pulso_us = SERVO_MAX_US;
	}

	ATOMIC_BLOCK(ATOMIC_RESTORESTATE)
	{
		pulso_servo_us[servo] = pulso_us;
	}
}

void PWM_Servo_SetAngle(uint8_t servo, uint8_t angulo)
{
	if (angulo > 180)
	{
		angulo = 180;
	}

	uint16_t pulso_us = SERVO_MIN_US +
	((uint32_t)angulo * (SERVO_MAX_US - SERVO_MIN_US)) / 180;

	PWM_Servo_SetPulse(servo, pulso_us);
}

ISR(TIMER1_COMPA_vect)
{
	static uint16_t suma_pulsos = 0;
	uint16_t tiempo_restante = 0;

	if (servo_actual < NUM_SERVOS)
	{
		Servo_Pin_Low(servo_actual);

		suma_pulsos += pulso_servo_us[servo_actual];

		servo_actual++;

		if (servo_actual < NUM_SERVOS)
		{
			Servo_Pin_High(servo_actual);
			OCR1A = us_to_ocr(pulso_servo_us[servo_actual]);
		}
		else
		{
			// Ya se mandaron los 4 pulsos.
			// Ahora se espera el tiempo restante hasta completar 20 ms.
			if (suma_pulsos < PERIODO_SERVO_US)
			{
				tiempo_restante = PERIODO_SERVO_US - suma_pulsos;
			}
			else
			{
				tiempo_restante = 1000;
			}

			OCR1A = us_to_ocr(tiempo_restante);
		}
	}
	else
	{
		// Nuevo ciclo de 20 ms
		suma_pulsos = 0;
		servo_actual = 0;

		Servo_Pin_High(servo_actual);
		OCR1A = us_to_ocr(pulso_servo_us[servo_actual]);
	}
}