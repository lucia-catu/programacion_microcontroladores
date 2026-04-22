/*
 * PWM_manual.h
 *
 * Created: 
 *  Author: 
 */ 


#ifndef PWM_MANUAL_H_
#define PWM_MANUAL_H_

#include <stdint.h>

// Inicializa el Timer0 y el pin del LED (PD6)
void initPWM_Manual(void);

// Actualiza el límite del ciclo de trabajo (0 a 255)
void updatePWM_Manual(uint8_t duty);

#endif /* PWM_MANUAL_H_ */