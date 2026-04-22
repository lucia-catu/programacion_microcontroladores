/*
 * NombreProgra.c
 *
 * Created: 
 * Author: lucia catú
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)

#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>

/****************************************/
// Function prototypes

void initUSART(void);
void USART_Transmit(unsigned char data);
unsigned char USART_Receive(void);

/****************************************/
// Main Function
int main(void) {
    
    // PB0 a PB5 como salidas 
    DDRB |= 0x3F; 
    
    // PC0 y PC1 como salidas 
    DDRC |= 0x03; 

    // Inicializar comunicación serial a 9600 baudios
    initUSART();

    // Enviar un carácter 
    USART_Transmit('K');

    unsigned char caracter_recibido;

    while (1) {
        
		//Recibir y mostrar en LEDs 
        caracter_recibido = USART_Receive(); 

        // Actualizar PORTB 
        PORTB = (PORTB & 0xC0) | (caracter_recibido & 0x3F);

        // Actualizar PORTC: 
        PORTC = (PORTC & 0xFC) | ((caracter_recibido & 0xC0) >> 6);
        
        // Eco para la terminal
        USART_Transmit(caracter_recibido);
    }
}

// FUNCIONES DEL USART 

void initUSART(void) {
    // Configuramos los baudios a 9600 - UBRR debe ser 103
    uint16_t ubrr = 103;
    UBRR0H = (unsigned char)(ubrr >> 8);
    UBRR0L = (unsigned char)ubrr;

    // Habilitar Transmisor (TXEN0) y Receptor (RXEN0)
    UCSR0B = (1 << RXEN0) | (1 << TXEN0);

    // 8 bits de datos, 1 bit de parada, sin paridad
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void USART_Transmit(unsigned char data) {
    // Esperar a que el buffer de transmisión esté vacío, para recibir un dato nuevo
    while (!(UCSR0A & (1 << UDRE0)));
    
    // Poner el dato en el registro UDR0
    UDR0 = data;
}

unsigned char USART_Receive(void) {
    // Esperar hasta que se detecte que llegó un dato completo
    while (!(UCSR0A & (1 << RXC0)));
    
    // Retornar el dato que llegó al buffer
    return UDR0;
}
