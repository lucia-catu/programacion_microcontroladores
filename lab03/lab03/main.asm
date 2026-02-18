
/*
* lab03.asm
*
* Created: 17/02/2026 18:44:34
* Author : Lucia Catú
*/
/**************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "m328pdef.inc"
.dseg
.org    SRAM_START

//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.cseg
.org 0x0000

 /**************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/**************/

	//TABLA
Tabla:
    .db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E

/**************/
// Configuración MCU

SETUP:
    ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)

	LDI r16, 0x00							; Habilitar los pines 0 y 1 del puerto D.
	STS UCSR0B, r16

	; PORTD como salida (display) 
    ldi R16, 0xFF
    out DDRD, R16

; Apagar display 
    ldi R16, 0xFF
    out PORTD, R16

; Botones PC0 y PC1 como entrada 
    cbi DDRC, PC0
    cbi DDRC, PC1

; Activar pull-ups
    sbi PORTC, PC0
    sbi PORTC, PC1

; Activar salidas del PORTB
    ldi  r16, 0x0F
    out  DDRB, r16

	rjmp MAIN