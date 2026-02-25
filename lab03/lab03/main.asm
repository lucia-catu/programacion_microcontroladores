
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

    ; PB0/PB1 salida 
    sbi DDRB, 0
    sbi DDRB, 1

    ; Estado inicial (display apagado)
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

	; Timer0: CTC
    ldi r16, (1<<WGM01)        ; CTC activado (WGM01=1)
    out TCCR0A, r16

    ldi r16, (1<<CS01)|(1<<CS00)  ; prescaler = 64 (CS01=1 y CS00=1)
    out TCCR0B, r16

    ldi r16, 249  ; valor de comparación para 1 ms (con 16 MHz)
    out OCR0A, r16

    ldi r16, (1<<OCIE0A)  ; habilitar interrupción por Compare Match A de Timer0
    sts TIMSK0, r16

    sei     ; habilitar interrupciones globales

/**************/
	;LOOP PRINCIPAL

	MAIN:
	 rjmp MAIN


/**************/
	; interrupciones

T0_ISR:
    ; Solo guardar valores temporales 
    push r16
    push r30
    push r31

    ; Apagar ambos dígitos
    cbi PORTB, 0
    cbi PORTB, 1

    ; Mux
    tst r20    ; prueba r20 contra 0, si r20 = 0 mostrar unidades
    brne mostrar_decenas

mostrar_unidades:
    mov r16, r18
    rcall LOAD_SEG
    out PORTD, r16        ; sacar el patron de segmentos en el display
    sbi PORTB, 0          ; Activar dígito de unidades
    ldi r20, 1            ; Cambiar selector, ahora la siguiente vez mostrar decenas
    rjmp COUNT_MS

mostrar_decenas:
    mov r16, r19
    rcall LOAD_SEG
    out PORTD, r16        ; sacar el patron de segmentos en el display
    sbi PORTB, 1          ; Activar dígito de decenas
    clr r20               ;; Cambiar selector, ahora la siguiente vez mostrar unidades
; Incrementar contador de milisegundos
COUNT_MS:     
    inc r21
    brne MS_CHECK
    inc r22

MS_CHECK:
	; Comparar si el contador llegó a 1000 ms
    cpi r22, 0x03
    brne EXIT_ISR
    cpi r21, 0xE8
    brne EXIT_ISR

	; Si llegó exactamente a 1000 ms reiniciar milisegundos
    clr r21
    clr r22

	;Incrementar contador de segundos

	inc r18      ;incrementar unidades
	cpi r18, 10
	brlo EXIT_ISR        ; si unidades son menores a 10, salir de la interrupcion

	clr r18              ; si llegó a 10, volver a 0
	inc r19              ; incrementar decenas

	cpi r19, 6           ; si llega a 6, llego a 60seg
	brlo EXIT_ISR        ; si es menor a 6 salir de la interrupcion

	; si llegó a 60, reiniciar
	clr r19
	clr r18

	;restaurar registros y salir de la ISR
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