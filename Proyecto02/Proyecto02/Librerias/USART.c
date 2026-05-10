/*
 * USART.c
 *
 *  Author: Lucia Catú
 */ 

#ifndef F_CPU
#define F_CPU 16000000UL
#endif

#include "USART.h"

void USART_Init(uint32_t baud)
{
	uint16_t ubrr_value = (F_CPU / (16UL * baud)) - 1;

	UBRR0H = (uint8_t)(ubrr_value >> 8);
	UBRR0L = (uint8_t)ubrr_value;

	// Habilitar recepción y transmisión
	UCSR0B = (1 << RXEN0) | (1 << TXEN0);

	// 8 bits de datos, 1 bit de parada, sin paridad
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void USART_TransmitChar(char dato)
{
	while (!(UCSR0A & (1 << UDRE0)));

	UDR0 = dato;
}

void USART_TransmitString(const char *texto)
{
	while (*texto)
	{
		USART_TransmitChar(*texto);
		texto++;
	}
}

uint8_t USART_Available(void)
{
	return (UCSR0A & (1 << RXC0));
}

char USART_ReceiveChar(void)
{
	while (!(UCSR0A & (1 << RXC0)));

	return UDR0;
}
