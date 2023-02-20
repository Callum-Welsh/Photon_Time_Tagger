// Sample code for FX2 interface
// (c) fpga4fun.com KNJN LLC - 2005, 2006, 2007, 2008

// This example uses the EzUSB driver

// Tested with MSVC 6.0

///////////////////////////////////////////////////
#include <windows.h>
#include <assert.h>

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
void USB_BulkWrite(ULONG pipe, void* buffer, ULONG buffersize)
{
	DWORD nBytes;
	assert(buffersize<0x10000);
	DeviceIoControl(XyloDeviceHandle, 0x222051, &pipe, sizeof(pipe), buffer, buffersize, &nBytes, NULL);

	assert(nBytes==buffersize);	// make sure everything was sent
}

DWORD USB_BulkRead(ULONG pipe, void* buffer, ULONG buffersize)
{
	DWORD nBytes;
	assert(buffersize<0x10000);
	DeviceIoControl(XyloDeviceHandle, 0x22204E, &pipe, sizeof(pipe), buffer, buffersize, &nBytes, NULL);

	return nBytes;
}

///////////////////////////////////////////////////
void USB_WriteChar(char c)
{
	USB_BulkWrite(2, &c, 1);
}

void USB_WriteWord(WORD w)
{
	USB_BulkWrite(2, &w, 2);
}

void main()
{
	USB_Open();

// We send bytes to the LCD one by one - not very efficient from the USB point of view, but keeps things simple

// For commands, we send 0x00 followed by the command byte. It is ok to send the 2 bytes at once because 
//  the first one (0x00) is not sent to the LCD module but is just there to indicate to the FPGA that the 
//  second byte is a command to the LCD

	// Commands
	USB_WriteWord(0x3800);	// remember, the PC is little-endian, so that's 0x00 followed by 0x38 !!
	USB_WriteWord(0x0F00);
	USB_WriteWord(0x0100);
	Sleep(2);

	// Data
	USB_WriteChar('S');
	USB_WriteChar('a');
	USB_WriteChar('x');
	USB_WriteChar('o');
	USB_WriteChar(' ');
	USB_WriteChar('i');
	USB_WriteChar('s');

	USB_WriteWord(0xC000);
	USB_WriteChar('f');
	USB_WriteChar('l');
	USB_WriteChar('y');
	USB_WriteChar('i');
	USB_WriteChar('n');
	USB_WriteChar('g');
	USB_WriteChar('.');
	USB_WriteChar('.');
	USB_WriteChar('.');

	USB_Close();
}
