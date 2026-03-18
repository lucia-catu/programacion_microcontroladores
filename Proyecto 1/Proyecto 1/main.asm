/*
* Proyecto1.asm
*
* Created: 4/03/2026 16:44:58
* Author : Lucia Catú
*/

.include "M328PDEF.inc"

; =====================================
; SRAM
; =====================================
.dseg
.org SRAM_START
hora:         .byte 1
minuto:       .byte 1
segundo:      .byte 1
dia:          .byte 1
mes:          .byte 1
modo:         .byte 1

digitos:        .byte 1
edit_hora:    .byte 1
edit_minuto:  .byte 1
bandera_edicion_hora:    .byte 1

edit_mes:     .byte 1
edit_dia:     .byte 1
bandera_edicion_fecha:  .byte 1

alarm_hora:    .byte 1
alarm_minuto:  .byte 1
alarma_on:      .byte 1

edit_alarm_hora:   .byte 1
edit_alarm_min:    .byte 1
bandera_edicion_alarma:   .byte 1

digito_display:          .byte 1
pinc_antes:    .byte 1
antirrebote_modo:      .byte 1
antirrebote_digitos:     .byte 1
antirrebote_inc:        .byte 1
BANDERA_evento_inc:     .byte 1
antirrebote_dec:      .byte 1
BANDERA_evento_dec:   .byte 1
antirrebote_aceptar:        .byte 1
BANDERA_evento_aceptar:     .byte 1


.cseg

; =====================================
; Registros
.def DISP1   = r16
.def DISP2   = r17
.def DISP3   = r18
.def DISP4   = r19

.def PUNTOS   = r22
.def medio_seg = r23

; =====================================
; Constantes
.equ DIG1      = 0
.equ DIG2      = 1
.equ DIG3      = 2
.equ DIG4      = 3

.equ LED1      = 4
.equ LED2      = 5

.equ BTN_INC    = 0      ; PC0
.equ BTN_DEC  = 1      ; PC1
.equ BTN_MODE  = 2      ; PC2
.equ BTN_DIGITOS = 3      ; PC3
.equ BTN_ACEPTAR    = 4      ; PC4

.equ BUZZER    = 5

.equ T1VALUE   = 7812

.equ veces_antirrebote_modo = 20
.equ veces_antirrebote_digitos = 20
.equ veces_antirrebote_inc = 20
.equ veces_antirrebote_dec = 20
.equ veces_antirrebote_aceptar = 20

; =====================================
; Vectores

.org 0x0000
    rjmp SETUP

.org PCI1addr
    rjmp PCINT1_ISR

.org OC1Aaddr
    rjmp TIMER1_COMPA_ISR

.org OVF0addr
    rjmp TIMER0_OVF_ISR

; =====================================
; Setup

SETUP:
    ; pila
    ldi r20, low(RAMEND)
    out SPL, r20
    ldi r20, high(RAMEND)
    out SPH, r20

    ; deshabilitar USART
    ldi r20, 0x00
    sts UCSR0B, r20

    cli

    ; PORTD segmentos display
    ldi r20, 0xFF
    out DDRD, r20
    clr r20
    out PORTD, r20

    ; PORTB  comunes y leds
    ldi r20, 0b00111111
    out DDRB, r20
    clr r20
    out PORTB, r20

    ; PORTC  botones y buzzer
    ldi r20, 0b00100000
    out DDRC, r20
    ldi r20, 0b00011111
    out PORTC, r20

    ; hora inicial: 00:00:00
    ldi r20, 0
    sts hora, r20
    sts minuto, r20
    sts segundo, r20

    ; fecha inicial: 01/01
    ldi r20, 1
    sts dia, r20
    sts mes, r20

    ; modo inicial = 0
    ldi r20, 0
    sts modo, r20
    sts digitos, r20
    sts edit_hora, r20
    sts edit_minuto, r20
    sts bandera_edicion_hora, r20
    sts edit_mes, r20
    sts edit_dia, r20
    sts bandera_edicion_fecha, r20
    sts alarm_hora, r20
    sts alarm_minuto, r20
    sts alarma_on, r20
    sts edit_alarm_hora, r20
    sts edit_alarm_min, r20
    sts bandera_edicion_alarma, r20
    sts digito_display, r20

    in r20, PINC
    sts pinc_antes, r20

    ldi r20, 0
    sts antirrebote_modo, r20
    sts antirrebote_digitos, r20
    sts antirrebote_inc, r20
    sts BANDERA_evento_inc, r20
    sts antirrebote_dec, r20
    sts BANDERA_evento_dec, r20
    sts antirrebote_aceptar, r20
    sts BANDERA_evento_aceptar, r20


    clr PUNTOS
    clr medio_seg

    clr DISP1
    clr DISP2
    clr DISP3
    clr DISP4

    ; Timer1
		clr r20
		sts TCCR1A, r20

		ldi r20, high(T1VALUE)
		sts OCR1AH, r20
		ldi r20, low(T1VALUE)
		sts OCR1AL, r20

		; modo CTC
		ldi r20, (1<<WGM12)
		sts TCCR1B, r20

		; habilitar interrupción compare A
		ldi r20, (1<<OCIE1A)
		sts TIMSK1, r20

		; prescaler 1024
		lds r20, TCCR1B
		ori r20, (1<<CS12)|(1<<CS10)
		sts TCCR1B, r20

	; Timer0
		clr r20
		out TCCR0A, r20          ; modo normal
		out TCCR0B, r20
		out TCNT0, r20           ; arrancar en 0

		ldi r20, (1<<TOIE0)
		sts TIMSK0, r20          ; habilitar overflow Timer0

		; prescaler 64
		ldi r20, (1<<CS01)|(1<<CS00)
		out TCCR0B, r20

    ; PCINT
		ldi r20, (1<<PCINT8)|(1<<PCINT9)|(1<<PCINT10)|(1<<PCINT11)|(1<<PCINT12)
		sts PCMSK1, r20

		ldi r20, (1<<PCIE1)
		sts PCICR, r20

		ldi r20, (1<<PCIF1)
		sts PCIFR, r20
    sei
; =====================================
; Loop principal
; =====================================
MAIN_LOOP:

    lds r20, modo  ;lee el modo y salta al bloque de modo correspondiente 

    cpi r20, 0
    breq MODO_0

    cpi r20, 1
    breq MODO_1

    cpi r20, 2
    breq MODO_2

    cpi r20, 3
    breq MODO_3

	cpi r20, 4
    breq MODO_4

	cpi r20, 5
    breq MODO_5

    rjmp MAIN_LOOP

; =====================================
; MODO 0 = HORA
; =====================================
MODO_0:
    sbi PORTB, LED1    ;prende led1
    cbi PORTB, LED2    ;apaga led2

    ; limpiar banderas de edición
    ldi r20, 0
    sts bandera_edicion_hora, r20
    sts bandera_edicion_fecha, r20
	sts bandera_edicion_alarma, r20

    rcall hora_en_display
    rjmp MAIN_LOOP

; =====================================
; MODO 1 = FECHA
; =====================================
MODO_1:
    cbi PORTB, LED1 ;apaga led1
    sbi PORTB, LED2 ;enciende led2

    ; limpiar banderas de edición
    ldi r20, 0
    sts bandera_edicion_hora, r20
    sts bandera_edicion_fecha, r20
	sts bandera_edicion_alarma, r20

    rcall fecha_en_display
    rjmp MAIN_LOOP

; =====================================
; MODO 2 = CONFIGURAR HORA
; =====================================
MODO_2:
    rcall ENTRAR_MODO_2
    rcall PARPADEO_LED1
    rcall procesar_inc
    rcall procesar_dec
    rcall procesar_aceptar
    rcall hora_editada_en_display
    rjmp MAIN_LOOP

; =====================================
; MODO 3 = CONFIGURAR FECHA
; =====================================
MODO_3:
    rcall ENTRAR_MODO_3
    rcall PARPADEO_LED2
    rcall procesar_inc
    rcall procesar_dec
    rcall procesar_aceptar
    rcall fecha_editada_en_display
    rjmp MAIN_LOOP

; =====================================
; MODO 4 = CONFIGURAR ALARMA
; =====================================
MODO_4:
    rcall ENTRAR_MODO_4
    rcall PARPADEO_LED12
    rcall procesar_inc
    rcall procesar_dec
    rcall procesar_aceptar
    rcall alarma_editada_en_display
    rjmp MAIN_LOOP

; =====================================
; MODO 5 = ALARMA SONANDO
; =====================================
MODO_5:
    rcall procesar_aceptar

    lds r20, modo
    cpi r20, 5
    brne MAIN_LOOP

    sbi PORTC, BUZZER
    sbi PORTB, LED1
    sbi PORTB, LED2

    rcall hora_en_display

    rjmp MAIN_LOOP

; =====================================
; ENTRAR MODO 2
; =====================================
ENTRAR_MODO_2:
    lds r20, bandera_edicion_hora   ;bandera para que el valor de hora no se vuelva a copiar mientras esta editando
    tst r20                         
    brne retornar_modo_2			; si no es cero no vuelve a copiar la hora actual y salta a retornar

    lds r20, hora				;Copia el valor de hora a la variable de edición de hora
    sts edit_hora, r20

    lds r20, minuto             ;Copia el valor de minuto a la variable de edición de minuto
    sts edit_minuto, r20

    ldi r20, 0                  ;pone digitos en 0 para que se empiece editando la hora 
    sts digitos, r20

    ldi r20, 1             ;se activa la bandera de edición de hora para que no se vuelva a repetir la copia de la hora actual
    sts bandera_edicion_hora, r20

retornar_modo_2:
    ret

; =====================================
; ENTRAR MODO 3 
; =====================================
ENTRAR_MODO_3:								;funciona igual que entrar a modo 2, pero copia el valor de la fecha actual en las variables de edición
    lds r20, bandera_edicion_fecha
    tst r20
    brne retornar_modo_3

    lds r20, mes
    sts edit_mes, r20

    lds r20, dia
    sts edit_dia, r20

    ldi r20, 0
    sts digitos, r20

    ldi r20, 1
    sts bandera_edicion_fecha, r20

retornar_modo_3:
    ret

; =====================================
; ENTRAR MODO 4
; =====================================
ENTRAR_MODO_4:									;funciona igual que entrar a modo 2, pero copia el valor de la alarma actual en las variables de edición
    lds r20, bandera_edicion_alarma
    tst r20
    brne retornar_modo_4

    lds r20, alarm_hora
    sts edit_alarm_hora, r20

    lds r20, alarm_minuto
    sts edit_alarm_min, r20

    ldi r20, 0
    sts digitos, r20

    ldi r20, 1
    sts bandera_edicion_alarma, r20

retornar_modo_4:
    ret