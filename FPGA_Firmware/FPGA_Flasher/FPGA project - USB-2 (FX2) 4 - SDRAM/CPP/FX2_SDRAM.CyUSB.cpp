// Sample code for FX2 interface
// (c) fpga4fun.com KNJN LLC 2014 - 2015

// This example uses the CyUSB driver
// Tested with MSVC 6.0

// Make sure you use the multithreaded runtime library 
// (in MSVC6.0, go to Project, Settings, C/C++, Code Generation, Use run-time library - Multithreaded)

///////////////////////////////////////////////////
#include <windows.h>
#include <assert.h>
#include <stdio.h>
#include <conio.h>

#include "CyAPI.h"
#pragma comment(lib, "CyAPI.lib")       // this links CyAPI.lib statically to the project

static GUID GUID_KNJN_FX2 = {0x0EFA2C93, 0x0C7B, 0x454F, 0x94, 0x03, 0xD6, 0x38, 0xF6, 0xC3, 0x7E, 0x65};
static GUID GUID_Cypress = {0xAE18AA60, 0x7F6A, 0x11d4, 0x97, 0xDD, 0x00, 0x01, 0x02, 0x29, 0xB9, 0x59};

#define BulkOutPipe0 USBDevice->EndPoints[1]
#define BulkInPipe1  USBDevice->EndPoints[2]
#define BulkOutPipe2 USBDevice->EndPoints[3]
#define BulkOutPipe3 USBDevice->EndPoints[4]
#define BulkInPipe4  USBDevice->EndPoints[5]
#define BulkInPipe5  USBDevice->EndPoints[6]

///////////////////////////////////////////////////
BYTE SDRAM_PrechargeAll[8] = {0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x02, 0x00};	// cmd precharge all
BYTE SDRAM_LoadModeReg [8] = {0x01, 0x20, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00};	// cmd load mode (burst length=2, CAS_latency=2)
BYTE SDRAM_Read        [8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00};
BYTE SDRAM_Write       [8] = {0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x00, 0x00};

CCyUSBDevice *USBDevice;

WORD SDRAM_getanswer()
{
	WORD bufr;
	LONG len = sizeof(bufr);
	BulkInPipe4->XferData((unsigned char*)&bufr, len);

	return bufr;
}

void SDRAM_init()
{
	LONG len = sizeof(SDRAM_PrechargeAll);
	BulkOutPipe2->XferData(SDRAM_PrechargeAll, len);
	SDRAM_getanswer();

	len = sizeof(SDRAM_LoadModeReg);
	BulkOutPipe2->XferData(SDRAM_LoadModeReg, len);
	SDRAM_getanswer();
}

void SDRAM_write(DWORD adr, WORD data)
{
	LONG len = sizeof(SDRAM_Write);
	*((PDWORD)&SDRAM_Write[0]) = adr;
	*((PDWORD)&SDRAM_Write[4]) = data;
	BulkOutPipe2->XferData(SDRAM_Write, len);
	SDRAM_getanswer();
}

WORD SDRAM_read(DWORD adr)
{
	LONG len = sizeof(SDRAM_Read);
	*((PDWORD)&SDRAM_Read[0]) = adr;
	BulkOutPipe2->XferData(SDRAM_Read, len);
	return SDRAM_getanswer();
}

void main()
{
	USBDevice = new CCyUSBDevice(NULL, GUID_KNJN_FX2);  // ussuming we use the KNJN GUID
	SDRAM_init();

	SDRAM_write(10, 0x2021);
	SDRAM_write(11, 0x1255);

	printf("%08X %08X\n", SDRAM_read(10), SDRAM_read(11));
	delete USBDevice;
}
