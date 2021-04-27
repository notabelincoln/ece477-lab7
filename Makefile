# GCC variables
RPICC=gcc
RPICFLAGS=-g -O2 -Wall
RPITARGET=lab7_rpi
AVRCC=avr-gcc
AVRCFLAGS=-O3
AVRTARGET=lab7_avr
AVRCONFIG=avrdude_gpio.conf

all:	avr rpi

avr:	fuse $(AVRTARGET) $(AVRTARGET).hex flash
rpi:	$(RPITARGET)

$(RPITARGET):	$(RPITARGET).o
	$(CC) -o $(RPITARGET) $(RPITARGET).o

$(RPITARGET).o:	$(RPITARGET).c
	$(RPICC) $(RPICFLAGS) -c $(RPITARGET).c

# Compile avr code and flash it to the board
fuse:	$(AVRCONFIG)
	avrdude -C ./$(AVRCONFIG) -c pi_1 -p m88p -U lfuse:w:0xe2:m -U hfuse:w:0xdf:m -U efuse:w:0xf9:m

eeprom:
	avrdude -C ./$(AVRCONFIG) -c pi_1 -p m88p -U eeprom:w:0x04,0x01:m

$(AVRTARGET):	$(AVRTARGET).c
	$(AVRCC) -mmcu=atmega88pa $(AVRFLAGS) $(AVRTARGET).c -o $(AVRTARGET)

$(AVRTARGET).hex:	$(AVRTARGET)
	avr-objcopy -j .text -j .data -O ihex $(AVRTARGET) $(AVRTARGET).hex

flash:	$(AVRTARGET).hex $(AVRCONFIG)
	avrdude -C $(AVRCONFIG) -c pi_1 -p m88p -U flash:w:$(AVRTARGET).hex:i

clean:
	rm -f *~ *.o *.hex $(RPITARGET) $(AVRTARGET)

