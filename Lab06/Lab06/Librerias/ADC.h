/*
 * ADC.h
 *
 * Author: Lucia Catu
 */

#ifndef ADC_H_     
#define ADC_H_

// Librerías necesarias
#include <avr/io.h>
#include <stdint.h>
void ADC_iniciar(void); //Inicia el módulo ADC del microcontrolador.
uint16_t ADC_leer(uint8_t canal); //Realiza una lectura analógica en el canal indicado.

#endif