/*
 * USART.h
 *
 *  Author: Lucia Catú
 */ 


#ifndef USART_H_
#define USART_H_

#include <avr/io.h>
#include <stdint.h>

void USART_Init(uint32_t baud);
void USART_TransmitChar(char dato);
void USART_TransmitString(const char *texto);
uint8_t USART_Available(void);
char USART_ReceiveChar(void);

#endif