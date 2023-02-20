// Sample code for FX2 interface with the CyUSB driver
// (c) KNJN LLC 2015

// Tested with Microsoft Visual Studio community 2015
// To create the project, use New project --> Win32 console application

///////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <conio.h>

#include "CyAPI.h"
#pragma comment(lib, "CyAPI.lib")       // this links CyAPI.lib statically to the project
#pragma comment(lib, "legacy_stdio_definitions.lib")

static GUID GUID_Cypress = { 0xAE18AA60, 0x7F6A, 0x11d4, 0x97, 0xDD, 0x00, 0x01, 0x02, 0x29, 0xB9, 0x59 };
//static GUID GUID_KNJN_FX2 = { 0x0EFA2C93, 0x0C7B, 0x454F, 0x94, 0x03, 0xD6, 0x38, 0xF6, 0xC3, 0x7E, 0x65 };

///////////////////////////////////////////////////
#define BulkOutPipe0 USBDevice->EndPoints[1]
#define BulkInPipe1  USBDevice->EndPoints[2]
#define BulkOutPipe2 USBDevice->EndPoints[3]
#define BulkOutPipe3 USBDevice->EndPoints[4]
#define BulkInPipe4  USBDevice->EndPoints[5]
#define BulkInPipe5  USBDevice->EndPoints[6]

CCyUSBDevice *USBDevice;

void send(BYTE b)
{
	LONG len = 1;
	BulkOutPipe2->XferData((PUCHAR)&b, len);
	Sleep(b & 1 ? 1 : 20);
}

void CMD(BYTE b)
{
	send(b & 0xF0);  
	send(b << 4 & 0xF0);
}

void ASCII(CHAR c)
{
	send(c & 0xF0 | 1);  
	send(c << 4 & 0xF0 | 1);
}

void WriteString(char* s)
{
	while (*s) ASCII(*s++);
}

void main()
{
	USBDevice = new CCyUSBDevice(NULL, GUID_Cypress);
	if (USBDevice->DeviceCount() > 0)
	{
		send(0x30);
		send(0x30);
		CMD(0x32);  // set LCD interface to 4bit

		CMD(0x28);  // bits N/F (2-line / 5x8 font)
		CMD(0x01);  // clear display

		CMD(0x0F);  // bits D/C/B (display on, curson on, character blinks)
		CMD(0x06);  // bits ID/S (increments, shift off)

		WriteString(" Xylo-E ");

		CMD(0xC0);  // move to 2nd line
		WriteString("LCD test");
	}
	else
		printf("Unable to open the driver... ");

	delete USBDevice;
	printf("Press any key to exit.");	_getch();
}
