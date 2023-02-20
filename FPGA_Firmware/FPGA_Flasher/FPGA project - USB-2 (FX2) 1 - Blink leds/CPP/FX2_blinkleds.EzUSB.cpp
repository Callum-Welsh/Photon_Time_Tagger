// Sample code for FX2 interface with the EzUSB driver
// (c) KNJN LLC - 2012

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
	int i;
	USB_Open();

	for(i=0; i<100; i++)	// blink the LEDs for a few seconds
	{
		USB_BulkWrite(2, &i, 1);	// send only one byte (= the value of i) to FIFO2
		Sleep(50);
	}

	USB_Close();
}
