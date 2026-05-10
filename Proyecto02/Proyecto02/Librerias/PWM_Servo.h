/*
 * PWM_Servo.h
 *
 *  Author: Lucia Catú
 */ 


#ifndef PWM_SERVO_H_
#define PWM_SERVO_H_

#include <avr/io.h>
#include <stdint.h>

#define NUM_SERVOS 4

void PWM_Servo_Init(void);
void PWM_Servo_SetPulse(uint8_t servo, uint16_t pulso_us);
void PWM_Servo_SetAngle(uint8_t servo, uint8_t angulo);

#endif