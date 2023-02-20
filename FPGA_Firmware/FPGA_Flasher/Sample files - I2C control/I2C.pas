// This example shows how to control the I2C bus from the PC (through USB)
// Before running this code, make sure that you enumerate your I2C devices first using FPGAconf's I2C-scan

// (c) 2006-2007 fpga4fun.com KNJN LLC

// USB routines
procedure USB_BulkWrite(pipe: ULONG; const buffer; buffersize: WORD);
var
  nBytes: ULONG;
begin
  DeviceIoControl(hDevice, $222051, @pipe, sizeof(pipe), @buffer, buffersize, nBytes, nil);
  assert(nBytes=buffersize);	// make sure everything was sent
end;

function USB_BulkRead(pipe: ULONG; var buffer; buffersize: WORD): DWORD;
begin
  DeviceIoControl(hDevice, $22204E, @pipe, sizeof(pipe), @buffer, buffersize, Result, nil);
end;

// I2C routine
procedure USB_send_I2C(var bufw; len: integer);
var
  bufr: array[0..63] of byte;
begin
  USB_BulkWrite(0, bufw, len);	// send I2C packet
  USB_BulkRead(1, bufr, sizeof(bufr));	// get the I2C response
  // we could check here if the I2C transaction succeeded or not (i.e. if we got an ACK on the I2C bus)
end;

// example of use
var
  hDevice: THandle;
const
  buf: array[0..3] of byte = (1, 2, $40, $55);	// I2C command packet, here we write one data byte (0x55) to device 0x40

begin
  hDevice := CreateFile(pchar('\\.\EzUSB-0'), 0, 0, nil, OPEN_EXISTING, 0, 0);  assert(hDevice<>INVALID_HANDLE_VALUE);
  USB_send_I2C(buf, sizeof(buf));
  CloseHandle(hDevice);
end;

