/*
 * ADC.h
 *
 * Created: 
 *  Author: lucia catu
 */ 

#ifndef ADC_H_
#define ADC_H_
#include <stdint.h>

void initADC(void);
uint16_t readADC(uint8_t channel);

#endif