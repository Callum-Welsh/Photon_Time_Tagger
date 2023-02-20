// Sample code for FX2 interface with the CyUSB driver
// (c) KNJN LLC - 2012 - 2015

// Tested with MSVC 6.0
// Make sure you use the multithreaded runtime library 
// (in MSVC6.0, go to Project, Settings, C/C++, Code Generation, Use run-time library - Multithreaded)

///////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <conio.h>

#include "CyAPI.h"
#pragma comment(lib, "CyAPI.lib")       // this links CyAPI.lib statically to the project

static GUID GUID_Cypress = {0xAE18AA60, 0x7F6A, 0x11d4, 0x97, 0xDD, 0x00, 0x01, 0x02, 0x29, 0xB9, 0x59};
//static GUID GUID_KNJN_FX2 = {0x0EFA2C93, 0x0C7B, 0x454F, 0x94, 0x03, 0xD6, 0x38, 0xF6, 0xC3, 0x7E, 0x65};

#define BulkOutPipe0 USBDevice->EndPoints[1]
#define BulkInPipe1  USBDevice->EndPoints[2]
#define BulkOutPipe2 USBDevice->EndPoints[3]
#define BulkOutPipe3 USBDevice->EndPoints[4]
#define BulkInPipe4  USBDevice->EndPoints[5]
#define BulkInPipe5  USBDevice->EndPoints[6]

///////////////////////////////////////////////////
void main()
{
	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL, GUID_Cypress);
	if (USBDevice->DeviceCount()>0)
	{
		for(int i=0; i<100; i++)	// blink the LEDs for a few seconds
		{
			LONG len = 1;
			printf("%d ", i);
			BulkOutPipe2->XferData((PUCHAR)&i, len);	// send one byte (the value of i) to FIFO2
			Sleep(50);
		}
	}
	else
		printf("Cannot open USB driver.\n");

	delete USBDevice;

	printf("Press any key to exit...");
	getch();
}
