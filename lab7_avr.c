#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <stdio.h>
#include <math.h>
#include <avr/sleep.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include <string.h>

int serial_putchar(char, FILE *);
int serial_getchar(FILE *);
static FILE serial_stream = FDEV_SETUP_STREAM(serial_putchar,serial_getchar,_FDEV_SETUP_RW);

void init_serial(void);
void init_adc(void);
int read_adc(void);

void update_clock_speed(void);


int main()
{
	char buffer[100] = "no string yet";
	unsigned int railv;
	char ts_enable;
	unsigned int ts;
	update_clock_speed();  //adjust OSCCAL
	init_serial(); 
	init_adc();
	_delay_ms(1000); //let serial work itself out
	ts_enable = 0;
	while(strncmp("START",&buffer[0],strlen("START"))) {
		fgets(buffer,100,stdin);
		sscanf(buffer,"START %u\n",&ts_enable);
	}
	// Configure timer
	while(1) //raspberry pi controls reset line
	{
		railv = (1.1*1023*10000)/read_adc();

		// determine whether to provide timestamps
		if (!ts_enable) {
			printf("The power rail is approximately %u\.%uV\n\r",
					railv/10000,railv%10000);
		} else {
			printf("The power rail at %u s is approximately %u\.%uV\n\r",
					ts,railv/10000,railv%10000);
		}
		_delay_ms(1000);
		if(ts_enable)
			ts++;
	}    
}


//read the first two bytes of eeprom, if they have been programmed
//use the first byte as an offset for adjusting OSCCAL and the second as
//the direction to adjust 0=increase, 1=decrease.
//Any offset is allowed and users are cautioned that it is possible to
// adjust the oscillator beyond safe operating bounds.
void update_clock_speed(void)
{
	char temp;
	temp=eeprom_read_byte((void *)1); //read oscillator offset sign 
	//0 is positive 1 is  negative
	//erased reads as ff (so avoid that)
	if(temp==0||temp==1)      //if sign is invalid, don't change oscillator
	{
		if(temp==0)
		{
			temp=eeprom_read_byte((void *)0);
			if(temp != 0xff) OSCCAL+=temp;
		}
		else
		{
			temp=eeprom_read_byte((void *)0);
			if(temp!=0xff) OSCCAL -=temp;
		}
	}
}

/* Initializes AVR USART for 9600 baud (assuming 8MHz clock) */
/* 8MHz/(16*(51+1)) = 9615 about 0.2% error                  */
void init_serial(void)
{
	UBRR0H=0;
	UBRR0L=51; // 9600 BAUD FOR 1MHZ SYSTEM CLOCK
	UCSR0A=0;
	UCSR0C= (1<<USBS0)|(3<<UCSZ00) ;  // 8 BIT NO PARITY 2 STOP
	UCSR0B=(1<<RXEN0)|(1<<TXEN0)  ; //ENABLE TX AND RX ALSO 8 BIT
	stdin=&serial_stream;
	stdout=&serial_stream;

}   
//simplest possible putchar, waits until UDR is empty and puts character
int serial_putchar(char val, FILE *fp)
{
	while(!(UCSR0A&(1<<UDRE0))); //wait until empty 
	UDR0 = val;
	return 0;
}

//simplest possible getchar, waits until a char is available and reads it
//note:1) it is a blocking read (will wait forever for a char)
//note:2) if multiple characters come in and are not read, they will be lost
int serial_getchar(FILE *fp)
{
	while(!(UCSR0A&(1<<RXC0)));  //WAIT FOR CHAR
	return UDR0;
}     
void init_adc(void)
{
	ADMUX = (1<<REFS0) | 14; //AVCC reference and 1.1 bandgap measurement
	ADCSRA = (1<<ADEN) | (3<<ADPS0); // enable ADC, prescaler=64
	ADCSRB = 0;
	DIDR0 = 0;
} 
int read_adc(void)
{
	ADCSRA |= (1<<ADSC);
	while(ADCSRA & (1<<ADSC)); //wait for coversion
	return ADC;
} 
