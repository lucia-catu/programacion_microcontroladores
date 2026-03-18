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
