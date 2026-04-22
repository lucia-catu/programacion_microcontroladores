/*
 * Lab05.c
 *
 * Created: 15/04/2026 14:35:46
 * Author : lucia catu
 */ 
/****************************************/
// Encabezado (Libraries)
/*
 * Lab06.c
 * Author: Micros Lu
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h> // Incluir librería de interrupciones
#include <stdint.h>
#include "ADC.h"          //Incluir todas las librerias propias
#include "PWM1.h"
#include "PWM2.h"
#include "PWM_Manual.h" 


int main(void)
{
	uint16_t pot_servo = 0;  //inicializar variables para cada pot
	uint16_t pot_pwm2 = 0;
	uint16_t pot_manual = 0; 
	
	// Inicializar todos los módulos
	initADC();
	initPWM1A();
	initPWM2A();
	initPWM_Manual(); 

	sei();  //interrupciones globales

	while (1)
	{
		// control de servo con Timer 1
		pot_servo = readADC(0);    // Leer canal A0 
		uint16_t pwm_duty1 = (uint16_t)(500 + ((uint32_t)pot_servo * 2000) / 1023); //rango en segundos
		updateServoPWM1A(pwm_duty1);   //Actualizar servo1

		// control de servo con timer 2
		pot_pwm2 = readADC(1);          // Leer canal A1
		uint8_t pwm_duty2 = (uint8_t)(9 + ((uint32_t)pot_pwm2 * 28) / 1023);  //rango en segundos
		updatePWM2A(pwm_duty2);       //Actualizar servo2

		// control de led manual
		pot_manual = readADC(2);                              // Leer canal A2
		uint8_t pwm_duty_manual = (uint8_t)(pot_manual / 4);  // Mapear 0-1023 a 0-255
		updatePWM_Manual(pwm_duty_manual);                    // Actualizar LED
	}
}
