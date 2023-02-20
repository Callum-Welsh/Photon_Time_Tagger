// This example shows how to control the I2C bus from the PC (through USB)
// Before running this code, make sure that you enumerate your I2C devices first using FPGAconf's I2C-scan

// (c) 2006-2007 fpga4fun.com KNJN LLC

#include <windows.h>
#include <assert.h>

HANDLE* DeviceHandle;

void OpenUSB()
{
	DeviceHandle = CreateFile("\\\\.\\EzUSB-0", GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
	assert(DeviceHandle!=INVALID_HANDLE_VALUE);
}

void OpenI2Cport()
{
	OpenUSB();
}

void CloseUSB()
{
	CloseHandle(DeviceHandle);
}

void CloseI2Cport()
{
	CloseUSB();
}

void USB_BulkWrite(ULONG pipe, void* buffer, WORD buffersize)
{
	int nBytes;
	DeviceIoControl(DeviceHandle, 0x222051, &pipe, sizeof(pipe), buffer, buffersize, &nBytes, NULL);
	assert(nBytes==buffersize);	// make sure everything was sent
}

void USB_BulkRead(ULONG pipe, void* buffer, WORD buffersize)
{
	int nBytes;
	DeviceIoControl(DeviceHandle, 0x22204E, &pipe, sizeof(pipe), buffer, buffersize, &nBytes, NULL);
	assert(nBytes==buffersize);	// make sure everything was read
}

void USB_send_I2C(char* buf, int len)
{
	char I2C_response[64];

	USB_BulkWrite(0, buf, (WORD)len);	// send the I2C packet
	USB_BulkRead(1, I2C_response, sizeof(I2C_response));	// get the I2C response
	// we could check here if the I2C transaction succeeded or not (i.e. if we got an ACK on the I2C bus)
}

void main()
{
	char buf[] = {1, 2, 0x40, 0x38};	// I2C request to write 0x38 to device 0x40

	OpenI2Cport();
	USB_send_I2C(buf, sizeof(buf));
	CloseI2Cport();
}
