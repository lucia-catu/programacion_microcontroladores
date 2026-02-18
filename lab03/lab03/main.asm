
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

rjmp start

.org PCI1addr								; habilito la interrupción para los pines del portC
RJMP IncDec_4leds

 /**************/
// Configuración de la pila

start:
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

// Oscilador a 1MHz
LDI R16, (1<<CLKPCE)						; Habilito la posibilidad de cambiar el oscilador
STS CLKPR, R16								; aquí escribo el valor en el registro CLKPR

LDI R16, 0b0000_0100						; Configuro el prescaler a 16 (16MHz/16 = 1MHz)
STS CLKPR, R16								; Escribo ese valor en el registro CLKPR y con eso ya cambié el oscilador.
// 

; PORT B
    ldi  r16, 0x0F             ; Salidas en el port B para los 4 leds
    out  DDRB, r16

	ldi r16, 0x00              ; Leds apagadas
	out PORTB, r16

; PORTD como salida (display) 
    ldi R16, 0xFF
    out DDRD, R16

    ldi R16, 0xFF   ; Apagar display 
    out PORTD, R16

; PORT C
    cbi DDRC, PC0 ;Botones PC0 y PC1 como entrada 
    cbi DDRC, PC1

    sbi PORTC, PC0 ; Activar pull-ups
    sbi PORTC, PC1

// Configurar PCINT1
LDI R16, (1<<PCIE1)
STS PCICR, R16
LDI R16, (1<<PCINT8)|(1<<PCINT9)
STS PCMSK1, R16

// CLEAR de mis contadores y variables 
CLR R20
CLR R21	
IN R21, PINC			; estado previo de botones

// ACTIVO INTERRUPCIONES GLOBALES
SEI 

	rjmp MAIN

/**************/
	;LOOP PRINCIPAL

	MAIN:
	 rjmp MAIN

/**************/
// NON-Interrupt subroutines

/**************/
// Interrupt routines

IncDec_4leds:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    IN   R16, PINC							 
    MOV  R17, R16							 

    EOR  R16, R21							 
											 
// Suma										 
    SBRS R16, 0								 
    RJMP resta								 
    SBRS R17, 0								  
    INC  R20

resta:
// Resta
    SBRS R16, 1								 
    RJMP mostrar_leds						 
    SBRS R17, 1								  
    DEC  R20								 

mostrar_leds:
    ANDI R20, 0x0F							 
    OUT  PORTB, R20

    MOV  R21, R17							

    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI

