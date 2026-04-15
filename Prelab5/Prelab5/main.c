/*
 * prelab5.c
 * Created: 
 * Author: Lucia Catú
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include "PWM/PWM1.h"

/****************************************/
// Variables 
volatile uint8_t valor_ADC = 0;   // Almacena el valor del ADC (8 bits)

/****************************************/
// Function prototypes
void initADC6(void);      // Inicialización del canal ADC6

/****************************************/
// Función principal
int main(void)
{
	cli();          // Deshabilita interrupciones
	initADC6();     // Configura el ADC en el canal 6
	
	// Inicializa PWM1A para servo
	initPWM1A(no_invertido, fastPWM_ICR1_top, 8);
	ICR1 = 39999;   // Define el periodo del PWM (20ms)
	OCR1A = 3000;   // Define el ancho de pulso inicial
	
	sei();          // Habilita interrupciones

	while (1)
	{
		// Conversión del valor ADC (0–255) al rango útil del servo
		updateDutyCycle1A(800 + ((uint32_t)valor_ADC * 4200) / 255);
	}
}

/****************************************/
// NON-Interrupt subroutines
void initADC6(void)
{
	ADMUX = 0;
	// Referencia de voltaje AVcc, ajustado a la izquierda (solo se usa ADCH), selección del canal ADC6
	ADMUX |= (1 << REFS0) | (1 << ADLAR) | (1 << MUX1) | (1 << MUX2);

	ADCSRA = 0;
	// Habilita ADC, interrupción, prescaler en 8 (ADPS1 y ADPS0) e inicia primera conversión
	ADCSRA = (1 << ADEN) | (1 << ADIE) | (1 << ADPS1) | (1 << ADPS0) | (1 << ADSC);
}

/****************************************/
// Interrupt routines
ISR(ADC_vect)
{
	valor_ADC = ADCH;      // Lee los 8 bits más significativos del ADC
	ADCSRA |= (1 << ADSC); // Reinicia la conversión para lectura continua
}