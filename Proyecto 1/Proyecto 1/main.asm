/*
* Proyecto1.asm
*
* Created: 4/03/2026 16:44:58
* Author : Lucia Catú
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)

.include "M328PDEF.inc"

; =====================================
; SRAM
; =====================================
.dseg
.org SRAM_START
hora_mem:      .byte 1
minuto_mem:    .byte 1
segundo_mem:   .byte 1

; =====================================
; CODE
; =====================================
.cseg

; =====================================
; REGISTROS
; =====================================
.def DISP1   = r16     ; decena hora
.def DISP2   = r17     ; unidad hora
.def DISP3   = r18     ; decena minuto
.def DISP4   = r19     ; unidad minuto

.def TEMP    = r20
.def AUX     = r21
.def COLON   = r22     ; 0=apagado, 1=encendido
.def HALFSEC = r23     ; cuenta medios segundos

; =====================================
; CONSTANTES
; =====================================
.equ DIG1   = 0
.equ DIG2   = 1
.equ DIG3   = 2
.equ DIG4   = 3

.equ LED1   = 4
.equ LED2   = 5

.equ BTN1   = 0
.equ BTN2   = 1
.equ BTN3   = 2
.equ BTN4   = 3
.equ BTN5   = 4

.equ BUZZER = 5

; =====================================
; VECTORES
; =====================================
.org 0x0000
    rjmp SETUP

.org 0x0016                 ; TIMER1 COMPA
    rjmp TIMER1_COMPA_ISR

; =====================================
; SETUP
; =====================================
SETUP:
    ; pila
    ldi TEMP, low(RAMEND)
    out SPL, TEMP
    ldi TEMP, high(RAMEND)
    out SPH, TEMP

    ; deshabilitar USART
    ldi TEMP, 0x00
    sts UCSR0B, TEMP

    cli

    ; -----------------------------
    ; PORTD = segmentos display
    ; -----------------------------
    ldi TEMP, 0xFF
    out DDRD, TEMP
    clr TEMP
    out PORTD, TEMP

    ; -----------------------------
    ; PORTB = comunes + leds
    ; PB0-PB3 comunes
    ; PB4-PB5 leds
    ; -----------------------------
    ldi TEMP, 0b00111111
    out DDRB, TEMP
    clr TEMP
    out PORTB, TEMP

    ; -----------------------------
    ; PORTC = botones + buzzer
    ; PC0-PC4 entradas con pullup
    ; PC5 salida buzzer
    ; -----------------------------
    ldi TEMP, 0b00100000
    out DDRC, TEMP
    ldi TEMP, 0b00011111
    out PORTC, TEMP

    ; -----------------------------
    ; hora inicial: 12:00:00
    ; -----------------------------
    ldi TEMP, 12
    sts hora_mem, TEMP

    clr TEMP
    sts minuto_mem, TEMP
    sts segundo_mem, TEMP

    clr COLON
    clr HALFSEC

    clr DISP1
    clr DISP2
    clr DISP3
    clr DISP4

    ; -----------------------------
    ; Timer1 a 0.5 s
    ; -----------------------------
    clr TEMP
    sts TCCR1A, TEMP

    ldi TEMP, high(7812)
    sts OCR1AH, TEMP
    ldi TEMP, low(7812)
    sts OCR1AL, TEMP

    ; modo CTC
    ldi TEMP, (1<<WGM12)
    sts TCCR1B, TEMP

    ; habilitar interrupción compare A
    ldi TEMP, (1<<OCIE1A)
    sts TIMSK1, TEMP

    ; prescaler 1024
    lds TEMP, TCCR1B
    ori TEMP, (1<<CS12)|(1<<CS10)
    sts TCCR1B, TEMP

    sei

; =====================================
; LOOP PRINCIPAL
; =====================================
MAIN_LOOP:
    rcall RELOJ_A_DISPLAY
    rcall MULTIPLEX
    rjmp MAIN_LOOP


; =====================================
; ISR TIMER1 COMPA
; =====================================
TIMER1_COMPA_ISR:
    push TEMP
    push AUX
    in   TEMP, SREG
    push TEMP

    ; alternar colon
    ldi TEMP, 1
    eor COLON, TEMP

    ; contar medios segundos
    inc HALFSEC
    cpi HALFSEC, 2
    brne FIN_ISR

    clr HALFSEC

    ; segundo_mem++
    lds TEMP, segundo_mem
    inc TEMP
    cpi TEMP, 60
    brlo GUARDAR_SEG

    clr TEMP
    sts segundo_mem, TEMP

    ; minuto_mem++
    lds TEMP, minuto_mem
    inc TEMP
    cpi TEMP, 60
    brlo GUARDAR_MIN

    clr TEMP
    sts minuto_mem, TEMP

    ; hora_mem++
    lds TEMP, hora_mem
    inc TEMP
    cpi TEMP, 24
    brlo GUARDAR_HORA

    clr TEMP

GUARDAR_HORA:
    sts hora_mem, TEMP
    rjmp FIN_ISR

GUARDAR_MIN:
    sts minuto_mem, TEMP
    rjmp FIN_ISR

GUARDAR_SEG:
    sts segundo_mem, TEMP

FIN_ISR:
    pop TEMP
    out SREG, TEMP
    pop AUX
    pop TEMP
    reti

; =====================================
; CONVERTIR RELOJ A DISPLAY
; =====================================
RELOJ_A_DISPLAY:

    ; HORAS
    lds AUX, hora_mem
    clr DISP1

HORAS_10:
    cpi AUX, 10
    brlo HORAS_FIN
    subi AUX, 10
    inc DISP1
    rjmp HORAS_10

HORAS_FIN:
    mov DISP2, AUX

    ; MINUTOS
    lds AUX, minuto_mem
    clr DISP3

MIN_10:
    cpi AUX, 10
    brlo MIN_FIN
    subi AUX, 10
    inc DISP3
    rjmp MIN_10

MIN_FIN:
    mov DISP4, AUX
    ret

; =====================================
; MULTIPLEXADO
; =====================================
MULTIPLEX:

    ; -------- DIG1 --------
    in AUX, PORTB
    andi AUX, 0b00110000
    out PORTB, AUX

    mov TEMP, DISP1
    rcall BUSCAR_TABLA
    out PORTD, TEMP

    in AUX, PORTB
    andi AUX, 0b00110000
    ori AUX, (1<<DIG1)
    out PORTB, AUX
    rcall RETARDO_CORTO

    ; -------- DIG2 --------
    in AUX, PORTB
    andi AUX, 0b00110000
    out PORTB, AUX

    mov TEMP, DISP2
    rcall BUSCAR_TABLA

    tst COLON
    breq NO_DP
    ori TEMP, 0b10000000     ; bit 7 = DP -> dos puntos del centro

NO_DP:
    out PORTD, TEMP

    in AUX, PORTB
    andi AUX, 0b00110000
    ori AUX, (1<<DIG2)
    out PORTB, AUX
    rcall RETARDO_CORTO

    ; -------- DIG3 --------
    in AUX, PORTB
    andi AUX, 0b00110000
    out PORTB, AUX

    mov TEMP, DISP3
    rcall BUSCAR_TABLA
    out PORTD, TEMP

    in AUX, PORTB
    andi AUX, 0b00110000
    ori AUX, (1<<DIG3)
    out PORTB, AUX
    rcall RETARDO_CORTO

    ; -------- DIG4 --------
    in AUX, PORTB
    andi AUX, 0b00110000
    out PORTB, AUX

    mov TEMP, DISP4
    rcall BUSCAR_TABLA
    out PORTD, TEMP

    in AUX, PORTB
    andi AUX, 0b00110000
    ori AUX, (1<<DIG4)
    out PORTB, AUX
    rcall RETARDO_CORTO

    ; apagar solo comunes, conservar LEDs
    in AUX, PORTB
    andi AUX, 0b00110000
    out PORTB, AUX

    ret

; =====================================
; BUSCAR EN TABLA
; =====================================
BUSCAR_TABLA:
    ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)

    add ZL, TEMP
    clr AUX
    adc ZH, AUX

    lpm TEMP, Z
    ret

; =====================================
; RETARDO CORTO
; =====================================
RETARDO_CORTO:
    ldi AUX, 40
L1:
    dec AUX
    brne L1
    ret

; =====================================
; TABLA 7 SEGMENTOS - CATODO COMUN
; =====================================
Tabla:
    .db 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111