// Sample code for FX2 interface
// (c) fpga4fun.com KNJN LLC - 2005, 2006, 2007, 2008

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
void main()
{
	char buf[256];
	int nb_bytes_received;

	// Here we send 5 bytes
	// and we should get back just one byte, which increments by 5 every time we call this software

	USB_Open();
	USB_BulkWrite(2, buf, 5);
	nb_bytes_received = USB_BulkRead(4, buf, sizeof(buf));
	USB_Close();

	printf("Received %d byte: %d\n", nb_bytes_received, buf[0]);
	printf("Press a key to exit");  getch();
}
