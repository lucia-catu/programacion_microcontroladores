/*
 * prelab4.c
 *
 * Created:
 * Author: Lucia Catú
 * Description: Contador binario de 8 bits
 */

/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

/****************************************/
// Function prototypes
void setup(void);
void initGPIO(void);
void initPCINT(void);
void initTimer0(void);
void actualizarLEDs(uint8_t valor);

/****************************************/
// Variables globales
volatile uint8_t contador = 0;

// Estado de botones
volatile uint8_t estadoInc = 1;
volatile uint8_t estadoDec = 1;

// Flags de antirebote
volatile uint8_t antireboteIncActivo = 0;
volatile uint8_t antireboteDecActivo = 0;

// Contadores de tiempo para antirebote
volatile uint8_t tiempoInc = 0;
volatile uint8_t tiempoDec = 0;

/****************************************/
// Main Function
int main(void)     
{
	setup();

	while (1)          //este while actualiza constantemente los LEDs según el valor actual de contador
	{
		actualizarLEDs(contador);
	}
}

/****************************************/
// NON-Interrupt subroutines
void setup(void)
{
    cli();

    initGPIO();
    initPCINT();
    initTimer0();

    actualizarLEDs(contador);

    sei();
}

void initGPIO(void)
{
    /************ LEDs ************/
    DDRB |= (1 << DDB4) | (1 << DDB5);   // PB4 y PB5 como salida
    DDRC |= 0x3F;                        // PC0 a PC5 como salida

    /************ Botones ************/
    DDRD &= ~(1 << DDD7);                // PD7 entrada
    DDRB &= ~(1 << DDB1);                // PB1 entrada

    PORTD |= (1 << PORTD7);              // Pull-up PD7
    PORTB |= (1 << PORTB1);              // Pull-up PB1
}

void initPCINT(void)
{
    // PD7- PCINT23
    PCICR |= (1 << PCIE2);
    PCMSK2 |= (1 << PCINT23);

    // PB1 - PCINT1
    PCICR |= (1 << PCIE0);
    PCMSK0 |= (1 << PCINT1);
}

void initTimer0(void)
{
    // Timer0 en CTC a 1 ms

    TCCR0A = 0;
    TCCR0B = 0;

    TCCR0A |= (1 << WGM01);              // modo CTC
    OCR0A = 249;                         // 1 ms
    TIMSK0 |= (1 << OCIE0A);             // interrupción compare A

    TCCR0B |= (1 << CS01) | (1 << CS00); // prescaler 64
}

void actualizarLEDs(uint8_t valor)
{
    // Limpiar PB4 y PB5
    PORTB &= ~((1 << PORTB4) | (1 << PORTB5));

    // b0 - PB4
    if (valor & (1 << 0))
        PORTB |= (1 << PORTB4);

    // b7 - PB5
    if (valor & (1 << 7))
        PORTB |= (1 << PORTB5);

    // Limpiar PC0-PC5
    PORTC &= ~0x3F;

    // b1-b6 * se evalua los bits del 1 al 6 del numero, si un bit esta en 1 enciende la led del PORTC
    if (valor & (1 << 1)) PORTC |= (1 << PORTC5);
    if (valor & (1 << 2)) PORTC |= (1 << PORTC4);
    if (valor & (1 << 3)) PORTC |= (1 << PORTC3);
    if (valor & (1 << 4)) PORTC |= (1 << PORTC2);
    if (valor & (1 << 5)) PORTC |= (1 << PORTC1);
    if (valor & (1 << 6)) PORTC |= (1 << PORTC0);
}

/****************************************/
// Interrupt routines

// PD7 (incrementar)
ISR(PCINT2_vect)
{
    if (!antireboteIncActivo)
    {
        antireboteIncActivo = 1;
        tiempoInc = 0;
    }
}

// PB1 (decrementar)
ISR(PCINT0_vect)
{
    if (!antireboteDecActivo)
    {
        antireboteDecActivo = 1;
        tiempoDec = 0;
    }
}

// Timer cada 1 ms
ISR(TIMER0_COMPA_vect)
{
    /************ Incrementar ************/
    if (antireboteIncActivo)
    {
        tiempoInc++;

        if (tiempoInc >= 20)
        {
            uint8_t lecturaActual = (PIND & (1 << PIND7)) ? 1 : 0;

            if ((estadoInc == 1) && (lecturaActual == 0))
            {
                contador++;
            }

            estadoInc = lecturaActual;
            antireboteIncActivo = 0;
            tiempoInc = 0;
        }
    }

    /************ Decrementar ************/
    if (antireboteDecActivo)
    {
        tiempoDec++;

        if (tiempoDec >= 20)
        {
            uint8_t lecturaActual = (PINB & (1 << PINB1)) ? 1 : 0;

            if ((estadoDec == 1) && (lecturaActual == 0))
            {
                contador--;
            }

            estadoDec = lecturaActual;
            antireboteDecActivo = 0;
            tiempoDec = 0;
        }
    }
}