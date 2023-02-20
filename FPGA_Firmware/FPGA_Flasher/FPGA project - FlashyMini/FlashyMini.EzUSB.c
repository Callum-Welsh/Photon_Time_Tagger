// Sample code for FX2 interface
// (c) fpga4fun.com KNJN LLC - 2005, 2006, 2007, 2008, 2009

// This example uses the EzUSB driver
// Tested with Digital Mars C compiler

///////////////////////////////////////////////////
#include <windows.h>
#include <assert.h>

HANDLE XyloDeviceHandle;

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
// We get 512 bytes out of FIFO4, and we print the values on the console

void main()
{
	int i, n;
	char buf[512];

	USB_Open();
	n = USB_BulkRead(4, buf, sizeof(buf));
	USB_Close();

	printf("Received %d bytes... ", n);
	for(i=0; i<n; i++) printf("%d ", (unsigned char) buf[i]);
}
