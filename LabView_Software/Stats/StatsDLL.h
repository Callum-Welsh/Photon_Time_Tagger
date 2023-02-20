// StatsDLL.cpp : FPGA-based Fast Multisource Pulse Registration System 
// Simple .dll for LabVIEW or C++ program API.
// by Sergey Polyakov & Joffrey Peters

// This dll provides USB connectivity to the Xylo-EM board, allowing the user to pull single pulse and coincidence statistics,
// or time-tagged events from the FPGA. 
// TTL pulses and toggling is supported on two channels


#ifdef STATS_LIBRARY_EXPORTS
#    define LIBRARY_API __declspec(dllexport)
#else
#    define LIBRARY_API __declspec(dllimport)
#endif

#include "stdafx.h"
#include <iostream>
#include <fstream>
#include <conio.h>
#include <time.h>
#include <bitset>
#include <stdio.h>

#include "C:\Cypress\Cypress Suite USB 3.4.7\CyAPI\inc\CyAPI.h"

//NOTE: CyAPI.h requires linking to Setupapi.lib

//FPGA commands
static unsigned char FPGA_NO_CHANGE = 0;
static unsigned char FPGA_CLEAR = 1;
static unsigned char FPGA_DISABLE = 2;
static unsigned char FPGA_ENABLE = 4;
static unsigned char FPGA_GETDATA = 8;


//TTL FPGA output commands
static unsigned char FPGA_PULSE = 0x10; //16
static unsigned char FPGA_TOGGLE = 0x20; //32
//TTL channels
static unsigned char FPGA_TTL_1 = 0x40; //64
static unsigned char FPGA_TTL_2 = 0x80; //128

//Errors
static const int ERROR_USB_INITIATED = -1; //Error: USB communication already initiated.
static const int ERROR_USB_UNINITIATED = -2; //Error: Trying to close NULL USB connection.
static const int ERROR_FPGA_REQUEST_DATA_SIZE = -3; //Error while requesting data size from FPGA
static const int ERROR_FPGA_GET_DATA_SIZE = -4; //Error getting size of data from FPGA
static const int ERROR_FPGA_GET_BULK_DATA = -5; //Error while getting bulk data from FPGA
static const int ERROR_FPGA_DATA_SIZE = -6; //Error: returned data not the 64 bytes expected...
static const int ERROR_COUNTS_INITIALIZATION = -7; //Error: insufficiently sized buffer passed to FPGA_Counts()
static const int ERROR_FPGA_PULSE = -8; //Error: could not send pulse command to FPGA.
static const int ERROR_FPGA_TOGGLE = -9; //Error: could not send toggle command to FPGA.

//constants
static const int USBFrame = 512;
static const int BYTE_SIZE = 8;
static const int FPGAdataPointSize = 4; //Time Tag data is 4 bytes per click
static const int FPGAStatsDataSize = 64; //64 bytes

//KNJN GUID {0EFA2C93-0C7B-454F-9403-D638F6C37E65}
static GUID GUID_KNJN_FX2 = {0x0EFA2C93, 0x0C7B, 0x454F, 0x94, 0x03, 0xD6, 0x38, 0xF6, 0xC3, 0x7E, 0x65};
//CYUSB GUID="{AE18AA60-7F6A-11d4-97DD-00010229B959} //Using this one with the CyUSB signed driver!
static GUID GUID_CYUSB_FX2 = {0xAE18AA60, 0x7F6A, 0x11d4, 0x97, 0xDD, 0x00, 0x01, 0x02, 0x29, 0xB9, 0x59};

#define BulkOutPipe0 USBDevice->EndPoints[1] 
#define BulkInPipe1  USBDevice->EndPoints[2]
#define BulkOutPipe2 USBDevice->EndPoints[3]
#define BulkOutPipe3 USBDevice->EndPoints[4]
#define BulkInPipe4  USBDevice->EndPoints[5]
#define BulkInPipe5  USBDevice->EndPoints[6]


//Name of a function with real time access to received data.
//User could write his/her own function and give its name here. Default function is "correlate"
//The user function must be declared as
//void <function_name> (unsigned char* data, int length, __int64 *stats);
//where:
//data is an array of recorded events, 4 bytes are used per one event, as defined in documentation
//length is the length of the array (divide by 4 to get number of events)
//stats is an array of integers, with any user output. The pointer to zeroth element will be passed to LabVEIW. The LavVIEW code assumes a 16-element array.

#define REALTIME_FUNCTION correlate

///////////////////////////////////////////////////
// Opens and closes the FPGA/USB driver
///////////////////////////////////////////////////

//create USB connection with CyUSB driver and return 0; if USB connection already created, return -1.
LIBRARY_API int USB_Open();

//return 0 if all is well, or -2 if CyUSB connection is NULL to begin with
LIBRARY_API int USB_Close();

///////////////////////////////////////////////////
// Pulls timestamped clicks from FPGA
//
//bool saveClicks: boolean to specify whether time-tagged events should be saved in a file of fileName
//unsigned char fpgaCommand: command to give to FPGA, (FPGA_ENABLE, FPGA_DISABLE, FPGA_CLEAR, FPGA_NO_CHANGE)
//								Note: one may also include TTL commands with these by simply using bitwise or | to
//									  combine the commands. Using multiple runs will cause these commands to be issued
//									  to the FPGA that many times before returning results to the user.
//char* fileName: name of file storing time-tagged events
//int* stats: 16 element array of integers used to store the 4-channel coincidence statistics measured by correlate() function
//int runs: number of times the USB transfer should occur before returning the *stats array and close file write.
// 
//returns 0 if successful, < 0 otherwise:
// ERROR_FPGA_REQUEST_DATA_SIZE is for uninitialized USB devices
// ERROR_FPGA_REQUEST_DATA_SIZE is for data request size errors
// ERROR_FPGA_GET_BULK_DATA is for data transfer errors
//
///////////////////////////////////////////////////
LIBRARY_API int FPGA_TimeTag(bool saveClicks, unsigned char  fpgaCommand, char* fileName, __int64* stats, int runs);

///////////////////////////////////////////////////
// Pulls click statistics from the FPGA
//
//bool saveData: boolean to specify whether click information should be saved in a file of fileName
//unsigned char fpgaCommand: command to give to FPGA, (FPGA_ENABLE, FPGA_DISABLE, FPGA_CLEAR, FPGA_NO_CHANGE)
//								Note: one may also include TTL commands with these by simply using bitwise or | to
//									  combine the commands. Using multiple runs will cause these commands to be issued
//									  to the FPGA that many times before returning results to the user.
//char* fileName: name of file storing time-tagged events
//int* stats: 16 element array of integers used to store the 4-channel coincidence statistics taken during this function call (runs FPGA board queries)
//unsigned int* data: the data in the raw format sent by the FPGA. The first 6 bytes are dedicated to clock ticks, the next 14 sets of 4 bytes are for
//		individual clicks, then coincidence clicks in the order defined by the stats structure below. The last two bytes are for four-fold coincidences.
//		The bytes are ordered least to most significant due to the way the FPGA transfers the data
//int* length: length of the data variable passed into the function. The output value of length will be the actual length of the *data array passed out.
//int runs: number of times the USB transfer should occur before returning the *stats and *data arrays and close file write.
// 
//returns 0 if successful, <0 otherwise:
// ERROR_FPGA_REQUEST_DATA_SIZE is for errors requesting data size, (typically due to disconnected, misprogrammed, or uninitialized USB devices)
// ERROR_FPGA_REQUEST_DATA_SIZE is for data request size errors 
// ERROR_FPGA_GET_BULK_DATA is for data transfer errors
// ERROR_COUNTS_INITIALIZATION is for insufficient *length parameter passed given the number of runs
//
///////////////////////////////////////////////////
LIBRARY_API int FPGA_Counts(bool saveData, unsigned char  fpgaCommand, char* fileName, __int64* stats, unsigned __int64* data, int* length, int runs);


/********
Output pulse from channel.
returns 0 if successful, negative value if error
********/

LIBRARY_API int FPGA_Pulse(unsigned char fpgaCommand);


/********
Toggle channel output state.

returns new output state, or negative value if error
********/

LIBRARY_API int FPGA_Toggle(unsigned char fpgaCommand);

/////////////////////////////////////////////////////
// Default REALTIME_FUNCTION
// Simple correlation analysis. Computes statistics.
/////////////////////////////////////////////////////
/*
stats structure: number of occurences of these events:

 stats[0] start events
 stats[1] state 0
 stats[2] state 1
 stats[3] state 2
 stats[4] state 3
 stats[5] states 0&1
 stats[6] states 0&2
 stats[7] states 0&3
 stats[8] state 1&2
 stats[9] state 1&3
 stats[10] state 2&3 
 stats[11] states 0&1&2
 stats[12] states 0&1&3
 stats[13] states 0&2&3
 stats[14] state 1&2&3              
 stats[15] states 0&1&2&3
*/
void correlate (unsigned char* data, int length, __int64 *stats);