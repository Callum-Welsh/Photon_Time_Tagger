// Sample code for FX2 interface
// (c) fpga4fun.com KNJN LLC 2014 - 2015

// This example uses the EzUSB driver
// Tested with MSVC 6.0

///////////////////////////////////////////////////
#include <windows.h>
#include <assert.h>
#include <stdio.h>
#include <conio.h>

HANDLE XyloDeviceHandle;

///////////////////////////////////////////////////
// Open and close the USB driver
void USB_Open()
{
	XyloDeviceHandle = CreateFile("\\\\.\\EzUSB-0", GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
	assert(XyloDeviceHandle!=INVALID_HANDLE_VALUE);
}

void USB_Close()
{
	CloseHandle(XyloDeviceHandle);
}

///////////////////////////////////////////////////
// USB functions to send and receive bulk packets
void USB_BulkWrite(DWORD pipe, void* buffer, DWORD buffersize)
{
	DWORD nBytes;
	assert(buffersize<0x10000);
	DeviceIoControl(XyloDeviceHandle, 0x222051, &pipe, sizeof(pipe), buffer, buffersize, &nBytes, NULL);

	assert(nBytes==buffersize);	// make sure everything was sent
}

DWORD USB_BulkRead(DWORD pipe, void* buffer, DWORD buffersize)
{
	DWORD nBytes;
	assert(buffersize<0x10000);
	DeviceIoControl(XyloDeviceHandle, 0x22204E, &pipe, sizeof(pipe), buffer, buffersize, &nBytes, NULL);

	return nBytes;
}

///////////////////////////////////////////////////
BYTE SDRAM_PrechargeAll[8] = {0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x02, 0x00};	// cmd precharge all
BYTE SDRAM_LoadModeReg [8] = {0x01, 0x20, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00};	// cmd load mode (burst length=2, CAS_latency=2)
BYTE SDRAM_Read        [8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00};
BYTE SDRAM_Write       [8] = {0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x00, 0x00};

void SDRAM_init()
{
	WORD bufr;
	USB_BulkWrite(2, SDRAM_PrechargeAll, sizeof(SDRAM_PrechargeAll));
	USB_BulkRead(4, &bufr, sizeof(bufr));

	USB_BulkWrite(2, SDRAM_LoadModeReg, sizeof(SDRAM_LoadModeReg));
	USB_BulkRead(4, &bufr, sizeof(bufr));
}

void SDRAM_write(DWORD adr, WORD data)
{
	WORD bufr;
	*((PDWORD)&SDRAM_Write[0]) = adr;
	*((PDWORD)&SDRAM_Write[4]) = data;
	USB_BulkWrite(2, SDRAM_Write, sizeof(SDRAM_Write));
	USB_BulkRead(4, &bufr, sizeof(bufr));
}

WORD SDRAM_read(DWORD adr)
{
	WORD bufr;
	*((PDWORD)&SDRAM_Read[0]) = adr;
	USB_BulkWrite(2, SDRAM_Read, sizeof(SDRAM_Read));
	USB_BulkRead(4, &bufr, sizeof(bufr));

	return bufr;
}

void main()
{
	USB_Open();
	SDRAM_init();

	SDRAM_write(10, 0x2021);
	SDRAM_write(11, 0x1255);

	printf("%08X %08X\n", SDRAM_read(10), SDRAM_read(11));
	USB_Close();
	getch();
}
