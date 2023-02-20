// FX2 FlashyDemo example
// (c) fpga4fun.com KNJN LLC - 2008, 2009

// This works in conjunction with a FlashyDemo FPGA bitfile

// This example uses the CyUSB driver
// Tested with MS Visual C++ 6.0

///////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <assert.h>

#include "CyAPI.h"
#pragma comment(lib, "CyAPI.lib")       // this links CyAPI.lib statically to the project

// GUID {0EFA2C93-0C7B-454F-9403-D638F6C37E65}
static GUID GUID_KNJN_FX2 = {0x0EFA2C93, 0x0C7B, 0x454F, 0x94, 0x03, 0xD6, 0x38, 0xF6, 0xC3, 0x7E, 0x65};

#define BulkOutPipe0 USBDevice->EndPoints[1]
#define BulkInPipe1  USBDevice->EndPoints[2]
#define BulkOutPipe2 USBDevice->EndPoints[3]
#define BulkOutPipe3 USBDevice->EndPoints[4]
#define BulkInPipe4  USBDevice->EndPoints[5]
#define BulkInPipe5  USBDevice->EndPoints[6]

///////////////////////////////////////////////////
#define nFlashyChannels 4	// 4 for Saxo-Q, 2 for the other FX2 boards
#define AcqDataLen	1024
#define DataPacketVersion	2

void main()
{
	int i, ch;

	struct
	{
		WORD PktAdr;
		BYTE DAC[8];
		BYTE TriggerThreshold;
		BYTE PreTriggerPoint;
		BYTE FilterDataIn_HDiv;
		BYTE AcqAllowed_TriggerSlope;
	}
	TriggerRequest;

	struct DPH
	{
		WORD magic_number;	// 0x55AA
		BYTE version;		// 0x01
		BYTE nb_channels_and_ADCfreq;
	};

	struct
	{
		struct DPH hdr1;					// header
		BYTE samples[AcqDataLen*nFlashyChannels];	// data acquired from Flashy
		DWORD dummy[4];						// don't care data
		DWORD FC[3];						// frequency counters
		struct DPH hdr2;					// second header
	}
	DataPacket;

	// make sure the structures are packed
	assert(sizeof(TriggerRequest)==14);
	assert(sizeof(DataPacket)==AcqDataLen*nFlashyChannels+36);

	TriggerRequest.PktAdr = 0x0000;
	TriggerRequest.DAC[0] = 0xFF;	// max range and position
	TriggerRequest.DAC[1] = 0xFF;
	TriggerRequest.DAC[2] = 0xFF;
	TriggerRequest.DAC[3] = 0xFF;
	TriggerRequest.DAC[4] = 0xFF;
	TriggerRequest.DAC[5] = 0xFF;
	TriggerRequest.DAC[6] = 0xFF;
	TriggerRequest.DAC[7] = 0xFF;
	TriggerRequest.TriggerThreshold = 0;	// trigger now
	TriggerRequest.PreTriggerPoint = 128;	// half the data before the trigger, half after
	TriggerRequest.FilterDataIn_HDiv = 0;	// acquire at full speed
	TriggerRequest.AcqAllowed_TriggerSlope = 0x80;

	CCyUSBDevice *USBDevice = new CCyUSBDevice(NULL, GUID_KNJN_FX2);

	LONG len = sizeof(TriggerRequest);
	BulkOutPipe2->XferData((PUCHAR)&TriggerRequest, len);	// send the trigger request

	len = sizeof(DataPacket);
	BulkInPipe4->XferData((PUCHAR)&DataPacket, len);	// and get the data packet back

	if(DataPacket.hdr1.magic_number==0x55AA && DataPacket.hdr1.version==DataPacketVersion)
	{
		if((DataPacket.hdr1.nb_channels_and_ADCfreq & 0x0F)==nFlashyChannels)
		{
			if(DataPacket.hdr2.magic_number==0x55AA && DataPacket.hdr2.version==DataPacketVersion)
			{
				// display the data received
				for(ch=0; ch<nFlashyChannels; ch++)
				{
					printf("Channel %d: ", ch+1);
					for(i=0; i<AcqDataLen; i++) printf("%d ", DataPacket.samples[i+AcqDataLen*ch]);
					printf("\n");
				}
			}
		}
		else
			printf("Wrong number of Flashy channels (%d received, %d expected)\n", (DataPacket.hdr1.nb_channels_and_ADCfreq & 0x0F), nFlashyChannels);
	}
	else
		printf("Bad packet received\n");

	// now we could re-trigger to get more data if we wanted
	// but let's just exit
	delete USBDevice;
}
