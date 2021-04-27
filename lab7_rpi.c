#include <stdio.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

int init(void);

int main(int argc, char * argv[])
{
	FILE *serial_out;
	FILE *serial_in;
	FILE *disk_out;
	int fdserial, fdscan;
	int i;
	float railv;
	char buffer[100];
	char strfloat[16];
	char *filename = "./rail_voltages.dat";
	char debug;

	debug = 0; // check if debug flag is enabled
	for (i = 0; i < argc; i++) {
		if (!(strcmp("debug",argv[i])))
			debug = 1;
	}

	fdserial=init(); // initialize serial port
	if(fdserial <1)
		exit(0);
	serial_out=fdopen(fdserial,"w");
	serial_in=fdopen(fdserial,"r");

	if(serial_out==NULL || serial_in==NULL) {
		printf("fdopen failed \n");
		exit(0);
	}

	disk_out=fopen(filename,"a"); // open file to record data

	if(disk_out==NULL) {
		disk_out=stdout;
		printf("couldn't open \"%s\" using stdout\n",filename);
	}

	fprintf(serial_out,"START\n"); // begin transaction
	fflush(serial_out);

	// Constantly read from serial input
	while(fgets(buffer,100,serial_in)) {
		// scan for float value
		fdscan = sscanf(buffer,"\nThe power rail is approximately %fV",&railv); 
		if (fdscan < 0) {
			printf("Couldn't receive data from serial port\n");
			exit(errno);

		}

		if (debug) {
			printf("%s - %f\n",buffer,railv);
			fflush(stdout);
		}
		memset(buffer,0,100);

		sprintf(strfloat, "%.4f\n", railv); // convert float to string
		fputs(strfloat,disk_out); // write float to file
		fflush(disk_out); // flush output, prepare for next input
	}
}

int  init()
{
	int fd1;
	struct termios tc;                // terminal control structure

	//todo serial port should not be hard coded
	fd1 = open("/dev/serial0", O_RDWR|O_NOCTTY);
	if(fd1<1) 
	{
		printf("Failed to open serial port\n");
		return 0;
	}
	tcgetattr(fd1, &tc);
	tc.c_iflag = IGNPAR;
	tc.c_oflag = 0;
	tc.c_cflag = CS8 | CREAD | CLOCAL; //8 bit chars enable receiver no modem status lines
	tc.c_lflag = ICANON;

	//todo baud rate should not be hard coded
	cfsetispeed(&tc, B9600);
	cfsetospeed(&tc, B9600);
	//todo should have bits per character set
	tcsetattr(fd1, TCSANOW, &tc);
	return fd1;
}
