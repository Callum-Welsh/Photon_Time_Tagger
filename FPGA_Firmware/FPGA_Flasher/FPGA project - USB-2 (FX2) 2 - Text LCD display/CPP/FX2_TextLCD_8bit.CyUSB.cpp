// Sample code for FX2 interface
// (c) fpga4fun.com KNJN LLC - 2007 - 2015

// This example uses the CyUSB driver
// Tested with MSVC 6.0

// Make sure you use the multithreaded runtime library 
// (in MSVC6.0, go to Project, Settings, C/C++, Code Generation, Use run-time library - Multithreaded)

///////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>

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
CCyUSBDevice *USBDevice;

void USB_WriteChar(char c)
{
	LONG len = 1;
	BulkOutPipe2->XferData((PUCHAR)&c, len);
}

void USB_WriteWord(WORD w)
{
	LONG len = 2;
	BulkOutPipe2->XferData((PUCHAR)&w, len);
}

void USB_WriteString(char* s)
{
	while(*s) USB_WriteChar(*s++);
}

void main()
{
	USBDevice = new CCyUSBDevice(NULL, GUID_Cypress);

// We send bytes to the LCD one by one - not very efficient from the USB point of view, but keeps things simple

// For commands, we send 0x00 followed by the command byte. It is ok to send the 2 bytes at once because 
//  the first one (0x00) is not sent to the LCD module but is just there to indicate to the FPGA that the 
//  second byte is a command to the LCD

	// Commands
	USB_WriteWord(0x3800);	// remember, the PC is little-endian, so that's 0x00 followed by 0x38 !!
	USB_WriteWord(0x0F00);
	USB_WriteWord(0x0100);
	Sleep(3);

	// Data
	USB_WriteString(" Hello");
	USB_WriteWord(0xC000);
	USB_WriteString("Dragon-E");

	delete USBDevice;
}
