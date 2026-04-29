/*
 * USART.c
 *
 * Author: Lucia Catu
 */

#define F_CPU 16000000UL   

#include "USART.h"         
#include <avr/interrupt.h> 

static volatile char buffer_rx[TAM_BUFFER_RX];
static volatile uint8_t cabeza_rx = 0; // Posición donde se guarda el próximo dato recibido
static volatile uint8_t cola_rx = 0;   // Posición desde donde se lee el próximo dato

static volatile char buffer_tx[TAM_BUFFER_TX];
static volatile uint8_t cabeza_tx = 0; // Posición donde se guarda el próximo dato a enviar
static volatile uint8_t cola_tx = 0;   // Posición desde donde se envía el próximo dato


	//Inicializa la comunicación USART con el baudrate indicado.

void USART_iniciar(unsigned long baudrate)
{
	uint16_t ubrr;

	ubrr = (uint16_t)((F_CPU / (16UL * baudrate)) - 1UL);	// Calcula el valor para el registro UBRR según la velocidad deseada

	// Carga el valor calculado en los registros de baudrate
	UBRR0H = (uint8_t)(ubrr >> 8);
	UBRR0L = (uint8_t)ubrr;

	UCSR0A = 0x00; // Modo normal de velocidad

	// Habilita recepción, transmisión e interrupción por recepción
	UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0);

	//  8 bits de datos, 1 bit de parada, sin paridad
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

	//Verifica si hay algún dato recibido en el buffer RX.
	
uint8_t USART_hay_dato(void)
{
	return (cabeza_rx != cola_rx);
}

// Lee un carácter recibido desde el buffer RX.
uint8_t USART_leer_caracter(char *dato)
{
	if (cabeza_rx == cola_rx)
	{
		return 0; // No hay datos disponibles
	}

	*dato = buffer_rx[cola_rx]; // Lee el dato más antiguo del buffer

	// Avanza la cola de forma circular
	cola_rx = (uint8_t)((cola_rx + 1U) % TAM_BUFFER_RX);

	return 1;
}


	//Guarda un carácter en el buffer TX para enviarlo por USART.

uint8_t USART_enviar_caracter(char dato)
{
	uint8_t siguiente_cabeza;

	// Calcula la siguiente posición libre del buffer
	siguiente_cabeza = (uint8_t)((cabeza_tx + 1U) % TAM_BUFFER_TX);

	if (siguiente_cabeza == cola_tx)
	{
		return 0; // Buffer lleno
	}

	buffer_tx[cabeza_tx] = dato; // Guarda el dato en el buffer
	cabeza_tx = siguiente_cabeza; // Actualiza la cabeza del buffer

	// Habilita interrupción cuando el registro UDR0 esté vacío
	UCSR0B |= (1 << UDRIE0);

	return 1;
}

//envía una cadena de texto compelta
uint8_t USART_enviar_texto(const char *texto)
{
	while (*texto != '\0')
	{
		if (!USART_enviar_caracter(*texto))
		{
			return 0; // No se pudo enviar porque el buffer está lleno
		}

		texto++;
	}

	return 1;
}


	//Convierte un número entero en caracteres ASCII y lo envía por USART.
uint8_t USART_enviar_numero(uint16_t valor)
{
	char digitos[5];       // Almacena los dígitos del número
	uint8_t cantidad = 0;  // Cuenta cuántos dígitos tiene el número

	if (valor == 0U)
	{
		return USART_enviar_caracter('0');
	}

	// Separa el número en dígitos, pero quedan guardados al revés
	while ((valor > 0U) && (cantidad < sizeof(digitos)))
	{
		digitos[cantidad] = (char)('0' + (valor % 10U));
		valor /= 10U;
		cantidad++;
	}

	// Envía los dígitos en orden correcto
	while (cantidad > 0U)
	{
		cantidad--;

		if (!USART_enviar_caracter(digitos[cantidad]))
		{
			return 0;
		}
	}

	return 1;
}

	//Interrupción de recepción USART.

ISR(USART_RX_vect)
{
	uint8_t siguiente_cabeza;
	char dato;

	dato = (char)UDR0; // Lee el dato recibido

	// Calcula la siguiente posición del buffer RX
	siguiente_cabeza = (uint8_t)((cabeza_rx + 1U) % TAM_BUFFER_RX);

	// Si el buffer no está lleno, guarda el dato recibido
	if (siguiente_cabeza != cola_rx)
	{
		buffer_rx[cabeza_rx] = dato;
		cabeza_rx = siguiente_cabeza;
	}
}

	//Interrupción de registro de datos vacío.

ISR(USART_UDRE_vect)
{
	if (cabeza_tx == cola_tx)
	{
		// Si ya no hay datos por enviar, deshabilita esta interrupción
		UCSR0B &= ~(1 << UDRIE0);
	}
	else
	{
		// Envía el siguiente carácter del buffer TX
		UDR0 = buffer_tx[cola_tx];

		// Avanza la cola del buffer de transmisión
		cola_tx = (uint8_t)((cola_tx + 1U) % TAM_BUFFER_TX);
	}
}