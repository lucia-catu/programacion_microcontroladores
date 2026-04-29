/*
 * USART.h
 *
 * Author: Lucia Catu
 */

#ifndef USART_H_      
#define USART_H_

#include <avr/io.h>
#include <stdint.h>

// Tamaño del buffer de recepción (RX)
#define TAM_BUFFER_RX 64

// Tamaño del buffer de transmisión (TX)
#define TAM_BUFFER_TX 64


void USART_iniciar(unsigned long baudrate); //Inicia el módulo USART

uint8_t USART_hay_dato(void);//Indica si existe al menos un dato recibido
uint8_t USART_leer_caracter(char *dato); //Lee un carácter recibido
uint8_t USART_enviar_caracter(char dato); //Envía un carácter por USART
uint8_t USART_enviar_texto(const char *texto); //Envía una cadena de texto completa
uint8_t USART_enviar_numero(uint16_t valor); //Convierte y envía un número entero por USART

#endif