
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

    ; PORTB = comunes + leds
    ldi r20, 0b00111111
    out DDRB, r20
    clr r20
    out PORTB, r20

    ; PORTC = botones + buzzer
    ; PC0-PC4 entradas con pull-up
    ; PC5 salida buzzer
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

; =====================================
; LED1 parpadea en modo 2
; =====================================
PARPADEO_LED1:                   ;si PUNTOS no es cero se enciende LED1, si es cero ambas leds se apagan
    tst PUNTOS
    breq LED1_apagado
    sbi PORTB, LED1
    cbi PORTB, LED2
    ret

LED1_apagado:
    cbi PORTB, LED1
    cbi PORTB, LED2
    ret

; =====================================
; LED2 parpadea en modo 3
; =====================================
PARPADEO_LED2:
    cbi PORTB, LED1                 ;apaga la led1

    tst PUNTOS                    ;si PUNTOS no es cero se enciende LED2, si es cero se apaga
    breq LED2_apagado
    sbi PORTB, LED2
    ret

LED2_apagado:
    cbi PORTB, LED2
    ret

; =====================================
; LED1 y LED2 parpadea en modo 4
; =====================================
PARPADEO_LED12:                 ;si PUNTOS está activo, se encienden LED1 y LED2, si no, ambos se apagan

    tst PUNTOS
    breq LED12_apagado
	sbi PORTB, LED1
    sbi PORTB, LED2
    ret

LED12_apagado:
    cbi PORTB, LED1
	cbi PORTB, LED2
    ret

; =====================================
; procesar evento incrementar
; =====================================
procesar_inc:
    lds r20, BANDERA_evento_inc   ;revisa la bandera del evento, si sí estaba activa entonces setea la bandera
    tst r20
    breq FIN_procesar_inc

    ; limpiar evento
    ldi r20, 0
    sts BANDERA_evento_inc, r20

    ; decidir que debe hacer según modo
    lds r20, modo

    cpi r20, 2
    breq evento_inc_MODO2

    cpi r20, 3
    breq evento_inc_MODO3

    cpi r20, 4
    breq evento_inc_MODO4

    ret

evento_inc_MODO2:
    rcall SUMAR_HORA_editada
    ret

evento_inc_MODO3:
    rcall SUMAR_FECHA_editada
    ret

evento_inc_MODO4:
    rcall SUMAR_ALARMA_editada
    ret

FIN_procesar_inc:
    ret

; =====================================
; Evento de sumar hora
; =====================================
SUMAR_HORA_editada:
    lds r20, digitos         ;revisa que digitos va a sumar
    cpi r20, 0
    breq sumar_digitos_hora   ;si es cero se incrmenta hora

    ; sumar minutos en edición
    lds r20, edit_minuto            ;incrementa un minuto y revisa si esta debajo de 60. Si sí, guarda el valor, sino regresa a 00.
    inc r20
    cpi r20, 60
    brlo guardar_minutos_editados
    ldi r20, 0

guardar_minutos_editados:
    sts edit_minuto, r20
    ret

sumar_digitos_hora:               ;incrementa una hora y revisa si esta debajo de 24. Si sí, guarda el valor, sino regresa a 00.
    lds r20, edit_hora
    inc r20
    cpi r20, 24
    brlo guardar_horas_editadas
    ldi r20, 0

guardar_horas_editadas:
    sts edit_hora, r20
    ret

; =====================================
; Evento de sumar fecha
; =====================================
SUMAR_FECHA_editada:
    lds r20, digitos                ;revisa que grupo de digitos es, si es cero suma mes. Si no es cero suma día
    cpi r20, 0
    breq sumar_digitos_mes

    ;se obtiene numero de dias maximo segun mes, y se copia a r21
    rcall dia_maximo
    mov r21, r20

    lds r20, edit_dia           
    cp r20, r21                 ;se compara el dia editado para ver si no excede el maximo. Si lo excede regresa a 1, sino incementa el dia y lo guarda
    brne NO_dia_max

    ldi r20, 1
    sts edit_dia, r20
    ret

NO_dia_max:
    inc r20
    sts edit_dia, r20
    ret

sumar_digitos_mes:       ;obtiene el mes editado incrmentando 1, si excede 12, entonces regresa a 1. Si no excede 12 guarda el valor
    lds r20, edit_mes
    inc r20
    cpi r20, 13
    brlo guardar_mes_editado
    ldi r20, 1

guardar_mes_editado:
    sts edit_mes, r20
    rcall ajuste_dia     ;al cambiar de mes el dia puede volverse invalido, entonces se llama ajuste día para corregirlo
    ret

; =====================================
; Evento de sumar alarma
; =====================================
SUMAR_ALARMA_editada:
    lds r20, digitos            ;revisa que digitos se estan editando. Si es cero se va a sumar horas, sino se queda sumando minutos. 
    cpi r20, 0
    breq sumar_horaalarma_editada

    ; sumar minuto alarma
    lds r20, edit_alarm_min      ;cargar los minutos de la alarma que se estan editando e incrementar, si es menor a 60 se guarda, si no se regresa a 00
    inc r20
    cpi r20, 60
    brlo guardar_min_alarma_editado
    ldi r20, 0

guardar_min_alarma_editado:
    sts edit_alarm_min, r20
    ret

sumar_horaalarma_editada:
    lds r20, edit_alarm_hora    ;cargar la hora de la alrma editada e incrementar, si es menor a 24 se guarda, sino regresa a 00
    inc r20
    cpi r20, 24
    brlo guardar_h_alarma_editado
    ldi r20, 0

guardar_h_alarma_editado:
    sts edit_alarm_hora, r20
    ret

; =====================================
; procesar evento decremento
; =====================================
procesar_dec:
    lds r20, BANDERA_evento_dec   ;revisa que la bandera del evento decrementar este encendida
    tst r20
    breq FIN_procesar_dec

    ; limpiar la bandera del evento 
    ldi r20, 0
    sts BANDERA_evento_dec, r20

    ; decidir a que bloque se va según el modo actual
    lds r20, modo

    cpi r20, 2
    breq evento_dec_MODO2

    cpi r20, 3
    breq evento_dec_MODO3

    cpi r20, 4
    breq evento_dec_MODO4

    ret
	
	;dependiendo del modo llama la subrutina correspondiente
evento_dec_MODO2:
    rcall RESTAR_HORA_editada
    ret

evento_dec_MODO3:
    rcall RESTAR_FECHA_editada
    ret

evento_dec_MODO4:
    rcall RESTAR_ALARMA_editada
    ret

FIN_procesar_dec:
    ret

; =====================================
; Evento de restar hora
; =====================================
RESTAR_HORA_editada:
    lds r20, digitos             ;revisa que digitos se van a editar. Si es cero modifica los digitos de hora, si no modifica minutos
    cpi r20, 0
    breq restar_digitos_hora

    ; restar minutos en edición
    lds r20, edit_minuto     ; carga el valor de minutos, si es cero, entonces no decrementa sino que pasa a 59. 
    tst r20
    brne decrementar_minutos 
    ldi r20, 59
    sts edit_minuto, r20
    ret

decrementar_minutos:       ;si no era cero solo decrementa uno y lo guarda
    dec r20
    sts edit_minuto, r20
    ret

restar_digitos_hora:       ;carga la hora editada, y revisa si es cero, entonces no decrementa sino que pasa a 23
    lds r20, edit_hora
    tst r20
    brne decrementar_hora
    ldi r20, 23
    sts edit_hora, r20
    ret

decrementar_hora:        ;si no era cero, solo decrementa uno y lo guarda
    dec r20
    sts edit_hora, r20
    ret

; =====================================
; Evento de restar fecha
; =====================================
RESTAR_FECHA_editada:
    lds r20, digitos      ;revisa que digitos quiere editar, si es cero edita el mes. Si no edita día
    cpi r20, 0
    breq restar_digitos_mes

    ; restar día según mes
    lds r20, edit_dia           ;carga el valor de editar dia, si no es uno decrementa el día y lo guarda
    cpi r20, 1
    brne NO_dia1

    rcall dia_maximo           ;si era uno, entonces busca cual es el dia maximo del mes, y guarda ese día. 
    sts edit_dia, r20
    ret

NO_dia1:
    dec r20
    sts edit_dia, r20
    ret

restar_digitos_mes:
    lds r20, edit_mes        ; cargar mes que se está editando
    cpi r20, 1             ; revisar si está en enero, si es 1, debe pasar a 12
    breq MES_uno          

    dec r20                  ; si no es 1, solo restar 1 y guardar. Se ajusta el día por si el maimo no fuera valido
    sts edit_mes, r20
    rcall ajuste_dia    
    ret

MES_uno:
    ldi r20, 12              ; pasa a ser diciembre y se guarda. Además se ajusta el día por si el maximo neesita modificarse
    sts edit_mes, r20
    rcall ajuste_dia
    ret

; =====================================
; Evento restar alarma
; =====================================
RESTAR_ALARMA_editada:
    lds r20, digitos         ;revisar que digitos se estan editando
    cpi r20, 0               ; si es cero se editan horas
    breq restar_digitos_h_alarma

    ; restar minuto alarma
    lds r20, edit_alarm_min     ;revisar si es cero, si no es cero decrementar y guardar normal
    tst r20
    brne NO_min_cero
    ldi r20, 59                 ;si sí es cero cambiar a 59
    sts edit_alarm_min, r20
    ret

NO_min_cero:
    dec r20
    sts edit_alarm_min, r20
    ret

restar_digitos_h_alarma:
    lds r20, edit_alarm_hora      ;revisar si es cero, sino es cero decrementar la hora
    tst r20
    brne NO_h_cero
    ldi r20, 23                   ;si es cero cambiarlo por 23
    sts edit_alarm_hora, r20
    ret

NO_h_cero:
    dec r20
    sts edit_alarm_hora, r20
    ret

; =====================================
; Procesar evento aceptar
; =====================================
procesar_aceptar:
    lds r20, BANDERA_evento_aceptar   ;revisa que la bandera del evento este encendida
    tst r20
    breq FIN_procesar_aceptar

    ; limpiar la bandera del evento
    ldi r20, 0
    sts BANDERA_evento_aceptar, r20

    ; decidir a que rutina llamar según modo
    lds r20, modo

    cpi r20, 2
    breq evento_aceptar_MODO2

    cpi r20, 3
    breq evento_aceptar_MODO3

    cpi r20, 4
    breq evento_aceptar_MODO4

    cpi r20, 5
    breq evento_aceptar_MODO5

    ret

evento_aceptar_MODO2:
    rcall ACEPTAR_HORA
    ret

evento_aceptar_MODO3:
    rcall ACEPTAR_FECHA
    ret

evento_aceptar_MODO4:
    rcall ACEPTAR_ALARMA
    ret

evento_aceptar_MODO5:
    rcall APAGAR_ALARMA
    ret

FIN_procesar_aceptar:
    ret

; =====================================
; Evento aceptar hora
; =====================================
ACEPTAR_HORA:
    lds r20, edit_hora   ;guarda la hora editada en la variable de hora actual
    sts hora, r20

    lds r20, edit_minuto  ;guarda el minuto editado en la variable de minuto actual
    sts minuto, r20

    ldi r20, 0            ;se inicia el segundo de nuevo cada vez que se configura
    sts segundo, r20      ;se setea digitos y la bandera que indica que ya se termino la edición
    sts digitos, r20
    sts bandera_edicion_hora, r20
    ret

; =====================================
; Evento aceptar fecha
; =====================================
ACEPTAR_FECHA:           ;hace lo mismo que para hora editada pero con mes y dia actual
    lds r20, edit_mes
    sts mes, r20

    lds r20, edit_dia
    sts dia, r20

    ldi r20, 0           ;setea digitos y la bandera de edición de fecha
    sts digitos, r20
    sts bandera_edicion_fecha, r20
    ret

; =====================================
; Evento aceptar alarma
; =====================================
ACEPTAR_ALARMA:                ;hace lo mismo que para hora editada, pero con las variables de alarma
    lds r20, edit_alarm_hora
    sts alarm_hora, r20

    lds r20, edit_alarm_min
    sts alarm_minuto, r20

    ldi r20, 1
    sts alarma_on, r20

    ldi r20, 0
    sts digitos, r20
    sts bandera_edicion_alarma, r20
    ret

; =====================================
; Evento apagar alarma
; =====================================
APAGAR_ALARMA:
    cbi PORTC, BUZZER        ;apaga los bits del buzzer y de las leds. 
    cbi PORTB, LED1
    cbi PORTB, LED2

    ldi r20, 0              ;setea la bandera de alarma encendida, y vuelve a mostrar la hora en modo 0
    sts alarma_on, r20
    sts modo, r20
    ret


; =====================================
; AJUSTAR DIA SEGÚN MES EDITADO
; =====================================
ajuste_dia:
    lds r21, edit_mes   ;revisa que mes se está editando y se dirige al apartado de ajuste según el mes

    ; febrero
    cpi r21, 2
    breq ajuste_28

    ; meses de 30
    cpi r21, 4
    breq ajuste_30
    cpi r21, 6
    breq ajuste_30
    cpi r21, 9
    breq ajuste_30
    cpi r21, 11
    breq ajuste_30

    ; meses de 31
    lds r20, edit_dia     ;revisa el dia, si es menor que 32, regresa, si se pasa entonces corrige el valor a 31 como maximo
    cpi r20, 32     
    brlo ajuste_aceptado
    ldi r20, 31           ;
    sts edit_dia, r20
    rjmp ajuste_aceptado

ajuste_30:
    lds r20, edit_dia     ;revisa el dia, si es menor que 31, regresa, si se pasa entonces corrige el valor a 30 como maximo
    cpi r20, 31
    brlo ajuste_aceptado
    ldi r20, 30
    sts edit_dia, r20
    rjmp ajuste_aceptado

ajuste_28:
    lds r20, edit_dia     ;revisa el dia, si es menor que 29, regresa, si se pasa entonces corrige el valor a 28 como maximo
    cpi r20, 29
    brlo ajuste_aceptado
    ldi r20, 28
    sts edit_dia, r20

ajuste_aceptado:
    ret

; =====================================
; Obtener maximo de día para editar según mes
; =====================================
dia_maximo:
    lds r21, edit_mes   ;revisar que mes se está editando

    ; si es febrero devuelve 28 días 
    cpi r21, 2        
    breq MAX_28

    ; si es abril, junio, septiembre, noviembre, devuelve 30 días
    cpi r21, 4
    breq MAX_30
    cpi r21, 6
    breq MAX_30
    cpi r21, 9
    breq MAX_30
    cpi r21, 11
    breq MAX_30

    ; de lo contrario devuelve 31 días
    ldi r20, 31
    ret

MAX_30:
    ldi r20, 30
    ret

MAX_28:
    ldi r20, 28
    ret

; =====================================
; revisar alarma
; =====================================
revisar_alarma:
    ; si alarma no está activa, salir
    lds r20, alarma_on
    tst r20
    breq FIN_revisar_alarma

    ; Si está activa comparar hora
    lds r20, hora
    lds r21, alarm_hora
    cp r20, r21
    brne FIN_revisar_alarma

    ; Si la hroa es igual, comparar minuto
    lds r20, minuto
    lds r21, alarm_minuto
    cp r20, r21
    brne FIN_revisar_alarma

	;Si hora y minuto son iguales, cambiar el modo a 5
    ldi r20, 5
    sts modo, r20

FIN_revisar_alarma:
    ret


; =====================================
; ISR PCINT1
; =====================================
PCINT1_ISR:
    push r20
    push r21
    push r24
    in   r20, SREG
    push r20

    ; leer el estado actual de los botones
    in r21, PINC

    ; leer el estado previo de los botones
    lds r24, pinc_antes

    ; guardar actual como nuevo previo
    sts pinc_antes, r21

    ; =================================
    ; revisar modo
    ; =================================
    lds r20, antirrebote_modo   ;revisa si ya terminó el antirrebote
    tst r20
    brne revisar_btn_digitos       ;si no es cero salta y no procesa el evento

    sbrs r24, BTN_MODE          ;solo entra al apartado de MODO si antes estaba en 1 y ahora en 0.
    rjmp revisar_btn_digitos

    sbrc r21, BTN_MODE
    rjmp revisar_btn_digitos

    lds r20, modo              ;como si se presiono modo, entonces incrementa el valor de modo solo si es menor a 5, sino vuelve a cero
    inc r20
    cpi r20, 5
    brlo PCINT_guardar_modo

    ldi r20, 0

PCINT_guardar_modo:            ;se guarda el nuevo modo
    sts modo, r20

    cpi r20, 2						;revisa si es modo 2
    brne PCINT_REVISAR_MODO3

    ldi r20, 0						;si era modo dos, limpia la bandera de edicion de hora
    sts bandera_edicion_hora, r20
    rjmp activar_antirrebote_modo

PCINT_REVISAR_MODO3:               ;revisa si es modo 3
    cpi r20, 3
    brne PCINT_REVISAR_MODO4

    ldi r20, 0                     ; si era modo tres, limpia la bandera de edición de fecha
    sts bandera_edicion_fecha, r20
    rjmp activar_antirrebote_modo

PCINT_REVISAR_MODO4:              ;revisa si es modo 4
    cpi r20, 4
    brne activar_antirrebote_modo

    ldi r20, 0                   ; si era modo cuatro, limpia la bandera de edición de alarma
    sts bandera_edicion_alarma, r20

activar_antirrebote_modo:                  ;vuelve a cargar el valor del antirrebote, lo reinicia
    ldi r20, veces_antirrebote_modo
    sts antirrebote_modo, r20
    rjmp FIN_PCINT1_ISR

    ; =================================
    ; Revisar digitos
    ; =================================
revisar_btn_digitos:
    lds r20, antirrebote_digitos     ;revisa si ya terminó el antirrebote
    tst r20
    brne revisar_btn_inc             ;si no es cero se va a al boton inc

    sbrs r24, BTN_DIGITOS            ;solo entra al apartado de digitos si antes estaba en 1 y ahora en 0
    rjmp revisar_btn_inc

    sbrc r21, BTN_DIGITOS
    rjmp revisar_btn_inc

    lds r20, modo                 ;revisa en que modo está, si esta en modo 2,3 o 4 va a cambiar de digitos
    cpi r20, 2
    breq CAMBIAR_DIGITOS
    cpi r20, 3
    breq CAMBIAR_DIGITOS
    cpi r20, 4
    breq CAMBIAR_DIGITOS
    rjmp revisar_btn_inc

CAMBIAR_DIGITOS:			;lee el valor de digitos, y lo cambia con xor, si es 1 ahora es 0 si es 0 ahora es 1
    lds r20, digitos
    ldi r24, 1
    eor r20, r24
    sts digitos, r20

    ldi r20, veces_antirrebote_digitos     ;vuelve a cargar el valor del antirrebote, lo reinicia
    sts antirrebote_digitos, r20
    rjmp FIN_PCINT1_ISR

    ; =================================
    ; revisar incrementar
    ; =================================
revisar_btn_inc:
    lds r20, antirrebote_inc      ;revisa el antirebote del boton incrementar, si no es cero se va al otro boton
    tst r20
    brne revisar_btn_dec          

    sbrs r24, BTN_INC             ;solo entra al apartado de digitos si antes estaba en 1 y ahora en 0
    rjmp revisar_btn_dec

    sbrc r21, BTN_INC
    rjmp revisar_btn_dec

    lds r20, modo              ;revisa si esta en modo 2, 3, o 4 
    cpi r20, 2
    breq GUARDAR_EVENTO_INC
    cpi r20, 3
    breq GUARDAR_EVENTO_INC
    cpi r20, 4
    breq GUARDAR_EVENTO_INC
    rjmp revisar_btn_dec

GUARDAR_EVENTO_INC:
    ldi r20, 1							;solo activa la bandera que sucedio el evento de incrementar
    sts BANDERA_evento_inc, r20

    ldi r20, veces_antirrebote_inc      ;vuelve a cargar el valor del antirrebote, lo reinicia
    sts antirrebote_inc, r20
    rjmp FIN_PCINT1_ISR

    ; =================================
    ; revisar decrementar
    ; =================================
revisar_btn_dec:
    lds r20, antirrebote_dec     ;revisa el antirebote del boton decrementar, sino es cero se va al otro boton
    tst r20
    brne revisar_btn_aceptar

    sbrs r24, BTN_DEC             ;solo entra al apartado de digitos si antes estaba en 1 y ahora en 0
    rjmp revisar_btn_aceptar

    sbrc r21, BTN_DEC
    rjmp revisar_btn_aceptar

    lds r20, modo                  ;revisa si esta en modo 2, 3, o 4 
    cpi r20, 2
    breq GUARDAR_EVENTO_DEC
    cpi r20, 3
    breq GUARDAR_EVENTO_DEC
    cpi r20, 4
    breq GUARDAR_EVENTO_DEC
    rjmp revisar_btn_aceptar
	 
GUARDAR_EVENTO_DEC:              ;solo activa la bandera que sucedio el evento de decrementar
    ldi r20, 1
    sts BANDERA_evento_dec, r20

    ldi r20, veces_antirrebote_dec     ;vuelve a cargar el valor del antirrebote, lo reinicia
    sts antirrebote_dec, r20
    rjmp FIN_PCINT1_ISR

    ; =================================
    ; revisar aceptar
    ; =================================
revisar_btn_aceptar:
    lds r20, antirrebote_aceptar         ;revisa el antirebote del boton aceptar, si no es cero acaba la ISR
    tst r20
    brne FIN_PCINT1_ISR

    sbrs r24, BTN_ACEPTAR                     ;solo entra al apartado de digitos si antes estaba en 1 y ahora en 0
    rjmp FIN_PCINT1_ISR

    sbrc r21, BTN_ACEPTAR
    rjmp FIN_PCINT1_ISR

    lds r20, modo                       ;revisa si esta en modo 2, 3, 4, O 5
    cpi r20, 2
    breq GUARDAR_EVENTO_ACEPTAR
    cpi r20, 3
    breq GUARDAR_EVENTO_ACEPTAR
    cpi r20, 4
    breq GUARDAR_EVENTO_ACEPTAR
    cpi r20, 5
    breq GUARDAR_EVENTO_ACEPTAR
    rjmp FIN_PCINT1_ISR

GUARDAR_EVENTO_ACEPTAR:             ;solo activa la bandera que sucedio el evento aceptar
    ldi r20, 1
    sts BANDERA_evento_aceptar, r20

    ldi r20, veces_antirrebote_aceptar     ;vuelve a cargar el valor del antirrebote, lo reinicia
    sts antirrebote_aceptar, r20

FIN_PCINT1_ISR:
    pop r20
    out SREG, r20
    pop r24
    pop r21
    pop r20
    reti


; =====================================
; ISR TIMER1 COMPA  
; =====================================
TIMER1_COMPA_ISR:
    push r20
    push r21
    in   r20, SREG
    push r20

    ; alternar los puntos de enmedio, cada vez que entra a la isr los puntos cambian de estado
    ldi r20, 1
    eor PUNTOS, r20

    ; contar medios segundos y compararlo con 2 para verificar si llega a un segundo
    inc medio_seg
    cpi medio_seg, 2
    brne fin_T1ISR    ;si no ha llegado a 1seg se termina la isr

    clr medio_seg     ;si ya llego a 1seg se reinicia el contador de medio segundo y se actualiza el reloj

    ;*****incrementar segundos*****
    lds r20, segundo      
    inc r20
    cpi r20, 60
    brlo GUARDAR_SEG   ;si es menor a 60 guarda segundo, sino lo limpia porque no se puede pasar de 60

    clr r20      
    sts segundo, r20

    ;*****incrementar minutos*****
    lds r20, minuto
    inc r20
    cpi r20, 60
    brlo GUARDAR_MIN   ;si es menor a 60 guarda minuto, sino lo limpia porque no se puede pasar de 60

    clr r20
    sts minuto, r20

    ;*****incrementar horas*****
    lds r20, hora
    inc r20
    cpi r20, 24
    brlo GUARDAR_HORA  ;si es menor a 24 guarda hora, sino lo limpia porque no se puede pasar de 24

    ; Además de pasar a 00 horas, se incrementa fecha y se revisa la alarma por si hay alguna porgramada a las 00:00
    clr r20
    sts hora, r20
    rcall AVANZAR_FECHA

    rcall revisar_alarma
    rjmp fin_T1ISR

GUARDAR_HORA:
    sts hora, r20
    rjmp fin_T1ISR

GUARDAR_MIN:
    sts minuto, r20
    rcall revisar_alarma   ;cada vez que hay cambio de minuto se revisa la alarma
    rjmp fin_T1ISR

GUARDAR_SEG:
    sts segundo, r20

fin_T1ISR:
    pop r20
    out SREG, r20
    pop r21
    pop r20
    reti

; =====================================
; Cambia de fecha
; =====================================
AVANZAR_FECHA:
    lds r20, dia   
    inc r20         ;incrementa de dia
    sts dia, r20

    lds r21, mes    ;revisa en que mes está
    cpi r21, 2
    breq MES_28        ;si es febrero se va a a mes de 28 días
    cpi r21, 4         ; si mes es abril, junio, septiembre o noviembre se va a mes de 30 días
    breq MES_30
    cpi r21, 6
    breq MES_30
    cpi r21, 9
    breq MES_30
    cpi r21, 11
    breq MES_30

    rjmp MES_31        ; si es cuaquier otro mes se va a mes de 31 días

MES_28:
    lds r20, dia
    cpi r20, 29        
    brlo correcto      ; si el día es menor que 29 la fecha esta bien
    ldi r20, 1		   ; si el día no es menor que 29, se reinicia el día a 1 y se avanza un mes
    sts dia, r20
    rcall AVANZAR_MES
    rjmp correcto

MES_30:                ; hace lo mismo que para el mes de 28 días pero con 30 días
    lds r20, dia
    cpi r20, 31
    brlo correcto
    ldi r20, 1
    sts dia, r20
    rcall AVANZAR_MES
    rjmp correcto

MES_31:                 ; hace lo mismo que para el mes de 28 días pero con 31 días
    lds r20, dia
    cpi r20, 32
    brlo correcto
    ldi r20, 1
    sts dia, r20
    rcall AVANZAR_MES

correcto:
    ret

; =====================================
; cambiar de mes
; =====================================
AVANZAR_MES:
    lds r20, mes
    inc r20             ;incrementa el mes y lo guarda, pero si se pasa de los 12 meses existentes entonces regresa el mes a 1. Lo regresa a enero
    cpi r20, 13            
    brlo GUARDAR_MES

    ldi r20, 1

GUARDAR_MES:
    sts mes, r20
    ret

; =====================================
; Mostrar la hora en el display
; =====================================
hora_en_display:
cli
	;horas
    lds r21, hora
    clr DISP1

decenas_horas:
    cpi r21, 10				;hace compare del numero de horas con 10, las veces que se haga la comparación mientras sea mayor que 10 es decenas de horas
    brlo unidades_horas     ;si es menor de 10, ya no son decenas de horas sino unidades
    subi r21, 10
    inc DISP1
    rjmp decenas_horas

unidades_horas:
    mov DISP2, r21			;guarda decenas de hora en disp1, y unidades de hora en disp2

	;hacer lo mismo para minutos, pero lo guarda en disp3 y disp4
    lds r21, minuto
    clr DISP3

decenas_minutos:
    cpi r21, 10
    brlo unidades_minutos
    subi r21, 10
    inc DISP3
    rjmp decenas_minutos

unidades_minutos:
    mov DISP4, r21
	sei
    ret

; =====================================
; Mostrar la fecha en el display
; =====================================
fecha_en_display:
cli
	; hace lo mismo que para horas pero para dia
    lds r21, dia
    clr DISP1

decenas_dia:
    cpi r21, 10
    brlo unidades_dia
    subi r21, 10
    inc DISP1
    rjmp decenas_dia

unidades_dia:
    mov DISP2, r21

	;hace lo mismo que para minutos pero para mes
	lds r21, mes
    clr DISP3

decenas_mes:
    cpi r21, 10
    brlo unidades_mes
    subi r21, 10
    inc DISP3
    rjmp decenas_mes

unidades_mes:
    mov DISP4, r21
	sei
    ret

; =====================================
; Mostrar hora editada en display
; =====================================
hora_editada_en_display:
cli
	; hace lo mismo que para horas pero para la variable de la hora que se está editando
    lds r21, edit_hora
    clr DISP1

decenas_hora_editada:
    cpi r21, 10
    brlo unidades_hora_editada
    subi r21, 10
    inc DISP1
    rjmp decenas_hora_editada

unidades_hora_editada:
    mov DISP2, r21

	;	hace lo mismo que para minutos pero para la variable de los minutos que se está editando
    lds r21, edit_minuto
    clr DISP3

decenas_minutos_editados:
    cpi r21, 10
    brlo unidades_minutos_editados
    subi r21, 10
    inc DISP3
    rjmp decenas_minutos_editados

unidades_minutos_editados:
    mov DISP4, r21
	sei
    ret

; =====================================
; Mostrar fecha editada en display
; =====================================
fecha_editada_en_display:
cli
	;hace lo mismo que para dia pero para la variable del dia que se está editando
    lds r21, edit_dia
    clr DISP1

decenas_dia_editado:
    cpi r21, 10
    brlo unidades_dia_editado
    subi r21, 10
    inc DISP1
    rjmp decenas_dia_editado

unidades_dia_editado:
    mov DISP2, r21

	;hace lo mismo que para mes pero para la variable del mes que se está editando
    lds r21, edit_mes
    clr DISP3

decenas_mes_editado:
    cpi r21, 10
    brlo unidades_mes_editado
    subi r21, 10
    inc DISP3
    rjmp decenas_mes_editado

unidades_mes_editado:
    mov DISP4, r21
	sei
    ret

; =====================================
; Mostrar alarma editada en display
; =====================================
alarma_editada_en_display:
cli
    ; hace lo mismo que para horas pero para la variable de la hora de alarma que se está editando
    lds r21, edit_alarm_hora
    clr DISP1

decenas_alarmah_editado:
    cpi r21, 10
    brlo unidades_alarmah_editado
    subi r21, 10
    inc DISP1
    rjmp decenas_alarmah_editado

unidades_alarmah_editado:
    mov DISP2, r21

    ; hace lo mismo que para minutos pero para la variable de los minutos de alarma que se está editando
    lds r21, edit_alarm_min
    clr DISP3

decenas_alarmam_editado:
    cpi r21, 10
    brlo unidades_alarmam_editado
    subi r21, 10
    inc DISP3
    rjmp decenas_alarmam_editado

unidades_alarmam_editado:
    mov DISP4, r21
	sei
    ret

; =====================================
; ISR TIMER0 OVERFLOW
; =====================================
TIMER0_OVF_ISR:
    push r20
    push r21
    push r24
    push ZL
    push ZH
    in   r20, SREG
    push r20

    ; antirrebote de modo
    lds r20, antirrebote_modo   
    tst r20
    breq listo_btn_modo         ;revisa el contador de antirebote, si ya es cero no hace nada, si no decrementa hasta que llegue a cero
    dec r20						;esto hace que mientras el contador no sea 0, ese botón queda bloqueado temporalmente
    sts antirrebote_modo, r20
listo_btn_modo:

    ; antirrebote de digitos  (se repite lo mismo para el resto de botones)
    lds r20, antirrebote_digitos           
    tst r20
    breq listo_btn_digitos
    dec r20
    sts antirrebote_digitos, r20
listo_btn_digitos:

    ; antirrebote de incrementar
    lds r20, antirrebote_inc
    tst r20
    breq listo_btn_inc
    dec r20
    sts antirrebote_inc, r20
listo_btn_inc:

    ; antirrebote de decrementar
    lds r20, antirrebote_dec
    tst r20
    breq listo_btn_dec
    dec r20
    sts antirrebote_dec, r20
listo_btn_dec:

    ; antirrebote de aceptar
    lds r20, antirrebote_aceptar
    tst r20
    breq listo_btn_aceptar
    dec r20
    sts antirrebote_aceptar, r20
listo_btn_aceptar:

    ; apagar solo comunes, conservar LEDs
    in r21, PORTB
    andi r21, 0b00110000
    out PORTB, r21

    ; leer cuál dígito toca encender en esta entrada de la ISR
    lds r20, digito_display

    cpi r20, 0
    breq mostrar_DIG1

    cpi r20, 1
    breq mostrar_DIG2

    cpi r20, 2
    breq mostrar_DIG3

    ; si no fue 0,1,2 entonces DIG4
    rjmp mostrar_DIG4

mostrar_DIG1:
    mov r20, DISP1               ;se lee el numero que toca mostrar y se busca el codigo binario de segmentos
    rcall BUSCAR_TABLA
    out PORTD, r20

    in r21, PORTB
    andi r21, 0b00110000
    ori r21, (1<<DIG1)
    out PORTB, r21              ;enciende el comun del primer display

    ldi r20, 1                  ;ahora deja en 1 r20, para que en la proxima interrupción se muestre DIG2
    sts digito_display, r20
    rjmp FIN_TIMER0_ISR

mostrar_DIG2:
    mov r20, DISP2            ;hace lo mismo que antes pero aquí revisa si puntos está encendido o apagado
    rcall BUSCAR_TABLA

    tst PUNTOS
    breq mostrar_DIG2_sinp   ; si PUNTOS no es cero, le agrega el bit 7 al patrón. Si es cero muestra el digito sin los puntos
    ori r20, 0b10000000

mostrar_DIG2_sinp:
    out PORTD, r20

    in r21, PORTB
    andi r21, 0b00110000        
    ori r21, (1<<DIG2)
    out PORTB, r21            ;enciende el común del segundo display

    ldi r20, 2
    sts digito_display, r20   ; en la proxima interrupción se mostrará DIG3
    rjmp FIN_TIMER0_ISR

mostrar_DIG3:                   ;se hace lo mismo pero se activa el común del DIG3, y luego se carga 3 a r20, para que en la proxima interrupción se muestre DIG4
    mov r20, DISP3
    rcall BUSCAR_TABLA
    out PORTD, r20

    in r21, PORTB
    andi r21, 0b00110000
    ori r21, (1<<DIG3)
    out PORTB, r21

    ldi r20, 3
    sts digito_display, r20
    rjmp FIN_TIMER0_ISR

mostrar_DIG4:               ;se hace lo mismo pero se activa el común del DIG4, y luego se carga O a r20 para que la próxima vez vuelve a empezar por DIG1
    mov r20, DISP4
    rcall BUSCAR_TABLA
    out PORTD, r20

    in r21, PORTB
    andi r21, 0b00110000
    ori r21, (1<<DIG4)
    out PORTB, r21

    ldi r20, 0
    sts digito_display, r20

FIN_TIMER0_ISR:
    pop r20
    out SREG, r20
    pop ZH
    pop ZL
    pop r24
    pop r21
    pop r20
    reti

; =====================================
; BUSCAR EN TABLA
; =====================================
BUSCAR_TABLA:
    ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)

    add ZL, r20
    clr r21
    adc ZH, r21

    lpm r20, Z
    ret

; =====================================
; TABLA 7 SEGMENTOS - CATODO COMUN
; =====================================
Tabla:
    .db 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111