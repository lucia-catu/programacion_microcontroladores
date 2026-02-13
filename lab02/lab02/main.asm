

.include "m328pdef.inc"

.org 0x0000
    rjmp SETUP

;-----------------------------
SETUP:
    ; Stack
    ldi  r16, high(RAMEND)
    out  SPH, r16
    ldi  r16, low(RAMEND)
    out  SPL, r16

    ; PORTB 
    ldi  r16, 0x0F
    out  DDRB, r16

    ; Inicializar contador en R21
    clr  r21

    ; Timer0 modo NORMAL
    clr  r16
    out  TCCR0A, r16

    ; Prescaler = 1024 (CS02=1, CS01=0, CS00=1)
    ldi  r16, (1<<CS02) | (1<<CS00)
    out  TCCR0B, r16

    ; Preload = 0 para máximo periodo por overflow
    clr  r16
    out  TCNT0, r16
    sbi  TIFR0, TOV0 ; Limpiar bandera TOV0 

    rjmp MAIN_LOOP

;------------------------------------------------------------

MAIN_LOOP:
    
    IN      R16, TIFR0 
    RCALL   WAIT_OVF            ; se llama el timer0

    INC     R21                 ; se incrementa el registro
    ANDI    R21, 0X0F           ;se toma el nibble menos significativo
    MOV     R16, R21            
    OUT     PORTB, R16          ; sacar el registro copiado por el puertoB
    RJMP    MAIN_LOOP

WAIT_OVF:
WAIT:
    IN     R16, TIFR0            ; leer las banderas
    SBRS   R16, TOV0             ; verificar el overflow
    RJMP   WAIT      

    SBI    TIFR0, TOV0           ; limpiar la bandera
    RET