/*
* Proyecto1.asm
*
* Created: 4/03/2026 16:44:58
* Author : Lucia Catú
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)

.cseg
.org 0x0000


 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/

//TABLA
Tabla:
    .db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E


// Configuracion MCU
SETUP:

	ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)

	LDI r16, 0x00							; Habilitar los pines 0 y 1 del puerto D.
	STS UCSR0B, r16

	; Timer0: CTC
    ldi r16, (1<<WGM01)        ; CTC activado (WGM01=1)
    out TCCR0A, r16

    ldi r16, (1<<CS01)|(1<<CS00)  ; prescaler = 64 (CS01=1 y CS00=1)
    out TCCR0B, r16

    ldi r16, 249  ; valor de comparación para 1 ms (con 16 MHz)
    out OCR0A, r16

    ldi r16, (1<<OCIE0A)  ; habilitar interrupción por Compare Match A de Timer0
    sts TIMSK0, r16
    
/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines

/****************************************/