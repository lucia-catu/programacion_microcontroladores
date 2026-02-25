
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
	rjmp SETUP

.org 0x001C
    rjmp T0_ISR

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

	; PORTD salida (segmentos)
    ldi r16, 0xFF
    out DDRD, r16

    ; PB0/PB1 salida (selección dígitos)
    sbi DDRB, 0
    sbi DDRB, 1

    ; Estado inicial
    cbi PORTB, 0
    cbi PORTB, 1
    ldi r16, 0xFF
    out PORTD, r16

	; Variables
    clr r18   ; unidades
    clr r19   ; decenas
    clr r20   ; 0=unidades 1=decenas
    clr r21
    clr r22

	; Timer0: CTC, prescaler 64, OCR0A=249 (1ms)
    ldi r16, (1<<WGM01)
    out TCCR0A, r16
    ldi r16, (1<<CS01)|(1<<CS00)
    out TCCR0B, r16
    ldi r16, 249
    out OCR0A, r16
    ldi r16, (1<<OCIE0A)
    sts TIMSK0, r16

    sei

/**************/
	;LOOP PRINCIPAL

	MAIN:
	 rjmp MAIN


/**************/
	; interrupciones

T0_ISR:
    ; SOLO guardar temporales / Z
    push r16
    push r30
    push r31

    ; Apagar ambos dígitos
    cbi PORTB, 0
    cbi PORTB, 1

    ; Mux
    tst r20
    brne SHOW_TENS

SHOW_UNITS:
    mov r16, r18
    rcall LOAD_SEG
    out PORTD, r16
    sbi PORTB, 0          ; ON unidades
    ldi r20, 1
    rjmp COUNT_MS

SHOW_TENS:
    mov r16, r19
    rcall LOAD_SEG
    out PORTD, r16
    sbi PORTB, 1          ; ON decenas
    clr r20

COUNT_MS:
    ; ms++
    inc r21
    brne MS_CHECK
    inc r22

MS_CHECK:
    ; 1000 ms = 0x03E8
    cpi r22, 0x03
    brne EXIT_ISR
    cpi r21, 0xE8
    brne EXIT_ISR

    clr r21
    clr r22

; +1 segundo (00..59)

inc r18
cpi r18, 10
brlo EXIT_ISR        ; si unidades < 10 ? listo

clr r18              ; si llegó a 10 ? volver a 0
inc r19              ; subir decenas

cpi r19, 6           ; ¿llegó a 6?
brlo EXIT_ISR        ; si <6 ? listo (10..59)

; si llegó a 60 ? reiniciar
clr r19
clr r18

EXIT_ISR:
    pop r31
    pop r30
    pop r16
    reti

; ----------------------------------------------------------
; LOAD_SEG para display
; ----------------------------------------------------------
LOAD_SEG:
    ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)
    add ZL, r16
    adc ZH, r1
    lpm r16, Z
    ret