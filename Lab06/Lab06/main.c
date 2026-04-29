/*
 * Laboratorio 6.c
 * Author: Lucia Catu
 */

#define F_CPU 16000000UL

// Librerías principales
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

// Librerías propias
#include "Librerias/ADC.h"
#include "Librerias/USART.h"

	//Enumeración para controlar los estados del programa
typedef enum
{
	ESTADO_MENU = 0,
	ESTADO_ESPERAR_CARACTER
} estado_programa_t;



	// Configura las salidas para los LEDs, PC2 queda como entrada
	
static void iniciar_salidas(void)
{
	DDRB = 0x3F;     // PB0 a PB5 como salida
	PORTB = 0x00;   // Apaga LEDs de puerto B

	DDRC |= (1 << PC0) | (1 << PC1);   // PC0 y PC1 como salida
	DDRC &= ~(1 << PC2);               // PC2 como entrada

	PORTC &= (uint8_t)~((1 << PC0) | (1 << PC1)); // LEDs apagados
}


	//Muestra un valor de 8 bits en LEDs
static void mostrar_en_leds(uint8_t valor)
{
	PORTB = valor & 0x3F;                       // Envía 6 bits bajos
	PORTC = (PORTC & 0xFC) | ((valor >> 6) & 0x03); // Envía 2 bits altos
}



	//Envía una cadena de texto por USART, se recorre carácter por carácter
	
static void enviar_texto(const char *texto)
{
	while (*texto != '\0')
	{
		while (!USART_enviar_caracter(*texto))
		{
			// Espera hasta poder transmitir
		}
		texto++;
	}
}



	//Envía un número entero por USART
	
static void enviar_numero(uint16_t valor)
{
	while (!USART_enviar_numero(valor))
	{
		// Espera hasta completar envío
	}
}


	//Muestra el valor leído del potenciómetro
static void enviar_valor_pot(uint16_t valor)
{
	while (!USART_enviar_texto("Valor del potenciometro: "))
	{
	}

	while (!USART_enviar_numero(valor))
	{
	}

	while (!USART_enviar_texto("\r\n"))
	{
	}
}


	//Muestra el menú principal al usuario
	
static void mostrar_menu(void)
{
	enviar_texto("\r\nMenu\r\n");
	enviar_texto("1. Mostrar ASCII en LEDs\r\n");
	enviar_texto("2. Mostrar valor del potenciometro\r\n");
	enviar_texto("Seleccione una opcion: ");
}



	//Función principal

int main(void)
{
	char caracter_recibido;          // Guarda carácter recibido por serial
	uint16_t valor_adc;             // Guarda lectura ADC
	estado_programa_t estado_actual; // Guarda estado actual del programa

	// Inicializaciones
	iniciar_salidas();
	mostrar_en_leds(0); // LEDs apagados al inicio

	ADC_iniciar();       // Inicializa ADC
	USART_iniciar(9600); // Inicializa USART a 9600 baudios

	sei(); // Habilita interrupciones globales

	estado_actual = ESTADO_MENU;

	mostrar_menu();

	while (1)
	{
		// Verifica si llegó un carácter por USART
		if (USART_leer_caracter(&caracter_recibido))
		{
			// Ignora Enter
			if ((caracter_recibido == '\r') || (caracter_recibido == '\n'))
			{
				continue;
			}

			// Si el programa está esperando un carácter
			if (estado_actual == ESTADO_ESPERAR_CARACTER)
			{
				// Muestra código ASCII en LEDs
				mostrar_en_leds((uint8_t)caracter_recibido);

				// Muestra datos en terminal serial
				enviar_texto("\r\nCaracter recibido: ");

				while (!USART_enviar_caracter(caracter_recibido))
				{
				}

				enviar_texto("\r\nValor decimal: ");
				enviar_numero((uint8_t)caracter_recibido);
				enviar_texto("\r\n");

				// Regresa al menú principal
				estado_actual = ESTADO_MENU;
				mostrar_menu();
			}
			else
			{
				// Si está en menú, evalúa opción ingresada
				switch (caracter_recibido)
				{
					case '1':
						// Solicita un carácter
						enviar_texto("\r\nIngrese un caracter: ");
						estado_actual = ESTADO_ESPERAR_CARACTER;
						break;

					case '2':
						// Lee potenciómetro en canal ADC2
						valor_adc = ADC_leer(2);

						enviar_texto("\r\n");
						enviar_valor_pot(valor_adc);

						mostrar_menu();
						break;

					default:
						// Opción no válida
						enviar_texto("\r\nOpcion invalida\r\n");
						mostrar_menu();
						break;
				}
			}
		}

		// Pequeña pausa para estabilidad
		_delay_ms(10);
	}
}