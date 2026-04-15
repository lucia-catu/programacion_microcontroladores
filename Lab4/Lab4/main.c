/*
 * Lab4.c
 * Created: 
 * Author : Lucia Catú 
 */

/******/
// Encabezado (Libraries)

#define F_CPU 1000000UL
#include <avr/io.h>
#include <stdint.h>
#include <avr/interrupt.h>


// VARIABLE UNIVERSAL DE CONTADOR  

volatile uint8_t contador = 0;        // variable del contador en leds
volatile uint8_t digito = 0;          // variable para multiplexado
volatile uint8_t comparar = 0;        // variable para comparación de leds y display
volatile uint8_t numdisplay = 0;      // variable para el valor del display

// Tabla de valores para el display de 7 segmentos
const uint8_t display[16] = {
	0x3F,
	0x06,
	0x5B,
	0x4F,
	0x66,
	0x6D,
	0x7D,
	0x07,
	0x7F,
	0x6F,
	0x77,
	0x7C,
	0x39,
	0x5E,
	0x79,
	0x71
};

/******/
// Function prototypes

void setup();
void initADC(); 
void compare();

/******/
// Main Function

int main(void)
{
    setup();
	initADC();
	sei();                                             
	while(1){
		uint8_t port_c = (PORTC & 0xF0) | (contador & 0x0F);   // conservar nibble alto y coloca en el nibble bajo el valor del contador
		
		uint8_t bits_altos = (contador & 0xF0) >> 2; //guarda nibble alto y lo coloca en el PORTB
		
		uint8_t port_b = (PORTB & 0x03) | (bits_altos & 0xFC);  //conserva los dos bits menos significativos y coloca el niblle alto 
		
		cli(); 
		PORTC = port_c;   //actualiza portc con contador
		PORTB = port_b;   //actualiza portb con la otra parte del contador
		compare(); 
		sei(); 
	}	
		
}

/******/
// NON-Interrupt subroutines

void setup() {
	
	UCSR0B &= ~((1 << RXEN0) | (1 << TXEN0));     
	
	PCICR = (1<<PCIE1);                        // habilitar interrupción pinchange
	PCMSK1 = (1<<PCINT5) | (1<<PCINT4);        // se activa en PC4 Y PC5
	
	ADCSRA  |= (1<<ADIE);                      // Habilita interrupción ADC
	ADCSRA	|= (1<<ADSC);		               // hace conversión de ADC
	
	TIMSK0  |= (1<<TOIE0);                     // habilita interrupción por overflow del timer0
	
	CLKPR =(1<<CLKPCE);                       // preesclarer
	CLKPR =(1<<CLKPS2);                       
	
	TCCR0A = 0x00;                             // modo normal
	TCCR0B |= (1<<CS01);	                 
	TCNT0 = 100;
	TIFR0  |= (1<<TOV0);
	
	DDRD  = 0xFF;                              // definir salidas
	DDRB  = 0xFF;  
	DDRC  = 0x0F;
	
	PORTD = 0xFF;                              
	PORTB = 0xFF;
	PORTC = 0xFF;                              // activar pullup
}

void initADC(){

	ADMUX = (1<<REFS0)|(1<<ADLAR)|(1<<MUX0)|(1<<MUX1)|(1<<MUX2);   //selecciona el canal ADC7

	ADCSRA = (1<<ADEN)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);  //habilita adc y su interrupción

	ADCSRA |= (1<<ADSC); //inicia conversión ADC
}
void compare() {                                
	if (contador == ADCH) {                     // si el contador es igual al ADC enciende PD7
		PORTD |= (1 << PORTD7);                 
		} 
		else {                          
		PORTD &= ~(1 << PORTD7);                // sino son iguales lo apaga
	}
}
/******/
// Interrupt routines

ISR(PCINT1_vect){                               // Interrupción por pin change
	if (!(PINC & (1 << PINC4))) {               
		contador++ ;                            // si incrementar se presiona sumar al contador
	}
	  if (!(PINC & (1 << PINC5))) {
		contador-- ;                            // si decrementar se presiona restar al contador
	  }
}


ISR(ADC_vect){                                  // interrupción cuando termina una conversión ADC
	ADCSRA |= (1<<ADSC);                        // inicia una nueva conversión
}

ISR(TIMER0_OVF_vect) {
	
	PORTB |= (1 << PORTB0) | (1 << PORTB1); // Apagar displays para no tener ghosting
	
	
	PORTD &= 0x80;     // Apagamos los segmentos PD0-PD6, conserva PD7
	
	TCNT0 = 100;   //recarga el timer 0 para hacer overflow

	if (digito == 0) {
		
		PORTD |= (display[ADCH & 0x0F] & 0x7F); //muestra en display nibble bajo
		PORTB &= ~(1 << PORTB0);    // activa primer display
		digito = 1;       //luego mostrara el otro digito
	}
	else {
		PORTD |= (display[(ADCH >> 4) & 0x0F] & 0x7F);  //muestra en display nibble alto
		PORTB &= ~(1 << PORTB1);          //activa el segundo display
		digito = 0;                       //luego se muestra el primer digito
	}
}