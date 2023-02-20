// StatsDLL.cpp : FPGA-based Fast Multisource Pulse Registration System 
// Simple .dll for LabVIEW or C++ program API.
// by Sergey Polyakov & Joffrey Peters

// The computer communicates with the FPGA via a USB 2 port using the signed CyUSB driver.
// The bidirectional USB communication protocol consists of this basic structure
// 1) a request sent by a computer (sends one byte via FIFO2, which is used for a primitive control of FPGA, see documentation)
// 2) a response of FPGA (replies with 2 bytes via FIFO5, reports the length of collected information in bytes)
// 3) data of a total length reported in step 2 is then availible for download via FIFO4

// This dll provides USB connectivity to the Xylo-EM board, allowing the user to pull single pulse and coincidence statistics,
// or time-tagged events from the FPGA. 
// TTL pulses and toggling is supported on two channels

#define STATS_LIBRARY_EXPORTS
#include "StatsDLL.h"

//Globally accessible elements. Attaching the DLL instantiates these objects, and detaching deletes them.
CCyUSBDevice* USBDevice;
unsigned char* buffer;
int bufferSize = 65536;
long moreData;//amount of data to retrieve from last transfer's overflow
int incompletePacket; //TODO: is this necessary?
char* debug = "C:\\FPGA\\debug.txt"; 
std::ofstream debugLog; //Debug log only logs error statements in released code


//This is the main DLL entry method. The USBDevice is initialized and deleted here, as well as some buffers and a debug log.
BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved ){

	switch (ul_reason_for_call){
		case DLL_PROCESS_ATTACH:
			debugLog.open(debug, std::ios::out | std::ios::app); //only errors enter the debug log
			USBDevice = NULL;
			buffer = new unsigned char[bufferSize];
			moreData = 0; 
			incompletePacket = 0;
			//debugLog << "attaching DLL" << std::endl;
			//debugLog.flush();
			break;
		case DLL_THREAD_ATTACH://not threading
			break; 
		case DLL_THREAD_DETACH://not threading
			break;
		case DLL_PROCESS_DETACH:
			delete USBDevice;
			delete buffer;
			//debugLog << "detaching DLL" << std::endl;
			debugLog.close();
			break;
		default: //woohoo, do nothing.
			break;
	}

	return TRUE;
}

//Open USB connection to FPGA board.
int USB_Open(){
	
	if(USBDevice == NULL){
		//std::cout << "Creating USBDevice." << std::endl;
		//debugLog << "Creating USBDevice." << std::endl;
		USBDevice = new CCyUSBDevice(NULL, GUID_CYUSB_FX2,true);
		return 0;
	}
	else{
		//std::cout << "Error: USB communication already initiated." << std::endl;
		debugLog << "Error: USB communication already initiated." << std::endl;
		return ERROR_USB_INITIATED;
	}
}

//Close USB connection to FPGA board.
int USB_Close() {
	if(USBDevice == NULL){
		//std::cout << "Error: Trying to close NULL USB connection." << std::endl;
		debugLog << "Error: Trying to close NULL USB connection." << std::endl;
		return ERROR_USB_UNINITIATED;
	}
	else{
		debugLog << "Closing and deleting USB Device." << std::endl;
		delete USBDevice;
		USBDevice = NULL;
		return 0;
	}
}

// Pulls timestamped clicks from FPGA, and calculates user-defined statistics data (stats)
_declspec(dllexport) int FPGA_TimeTag(bool saveClicks, unsigned char  fpgaCommand, char* fileName, __int64* stats, int runs){
	//debugLog << "start" << std::endl;
	//debugLog.flush(;)
	//debugLog << "Max packet size: " << USBDevice->MaxPacketSize << std::endl;

	//clicklog
	//std::string line;
	//static char delimiter = ' ';
	
	std::ofstream clickLog;
	if(saveClicks){
		clickLog.open(fileName, std::ios::out | std::ios::app | std::ios::binary);
	}

	/*
	FILE * clickFile;
	if(saveClicks){
		clickFile = fopen(fileName ,"at");
		setvbuf(clickFile,NULL,_IOFBF,256);
	}
	*/
	//initialize stats?
	for (int i = 0; i < 16; i++ ){ //dangerous process... how do you know how long stats is?
		stats[i] = 0;
	}

	//command to send to FPGA or data received from FPGA
	unsigned char fpgaCommunicator[2];
	long fpgaCommunicatorBytes = 1;
	fpgaCommunicator[0] = fpgaCommand;

	//variables
	int status = 0;
	long size = 0;

	for(int run = 0; run < runs; run++){
		//request number of new data points
		if(!status){
			fpgaCommunicator[0] = fpgaCommand;
			fpgaCommunicatorBytes = 1;
			///debugLog << "requesting size" << std::endl;
			status = !BulkOutPipe2->XferData(fpgaCommunicator, fpgaCommunicatorBytes);

			if(status){
				debugLog << "error requesting data size" << std::endl;
				debugLog.flush();
				status = ERROR_FPGA_REQUEST_DATA_SIZE;
			}
		}
		if(!status){
			//get data size
			fpgaCommunicator[0] = 0;
			fpgaCommunicator[1] = 1;
			fpgaCommunicatorBytes = 2;
			status = !BulkInPipe5->XferData(fpgaCommunicator, fpgaCommunicatorBytes);

			if(status){//error
				debugLog << "error getting size of data" << std::endl;
				debugLog.flush();
				status = ERROR_FPGA_GET_DATA_SIZE;
			}
		}

		if(!status){
			//calculate size
			size = (long) fpgaCommunicator[1]+ ((long) fpgaCommunicator[0])*256; //number of bytes stored in FPGA since last query
			//debugLog << "data size: " << size << " + " << moreData << " from last round = " << size + moreData << std::endl;
			//debugLog.flush();
			size += moreData;
			
			if(size < USBFrame){
				size = USBFrame;
			}
			moreData = size%USBFrame;
			size -=  moreData;

			status = !BulkInPipe4->XferData((buffer + incompletePacket), size); //starting off at pointer + incompletePacket, to ensure that data point from last query is completed.

			if(status){//error
				debugLog << "error sending data transfer request for size: " << size << std::endl;
				debugLog.flush();
				status = ERROR_FPGA_GET_BULK_DATA;;
			}
			else{
				size += incompletePacket; //the total data size in buffer is the size of the data retrieved + the incomplete packet from the previous query
				//debugLog << "got data of size: " << size << std::endl;
				//debugLog.flush();
			}
		}

		if (!status){
			incompletePacket = size%FPGAdataPointSize;  //incomplete packets from this query
			if(incompletePacket){
				debugLog << "Incomplete packet: " << incompletePacket << std::endl;
				debugLog.flush();
			}
			
			//save clicks, but don't save any incomplete data packets; save those for next round
			
			if(saveClicks){
				for (int j=0; j<(size-incompletePacket); j+=FPGAdataPointSize){
					//big-endian binary output with whitespace
					//clickLog << (unsigned int) buffer[j+3] << delimiter << (unsigned int) buffer[j+2] << delimiter << (unsigned int) buffer[j+1] << delimiter << (unsigned int) buffer[j] << std::endl;
					
					// FPGA outputs little-endian, which is what is used on x86; we output little-endian with no whitespace for compactness
					clickLog << buffer[j] << buffer[j+1] << buffer[j+2] << buffer[j+3];

					//writing the start, ch 1, ch 2, ch 3, ch 4 as a hexadecimal, then the timestamp as an integer.
					//clickLog << std::hex << std::showbase << (buffer[j+3]&248) << delimiter;

					//writing the start, ch 1, ch 2, ch 3, ch 4 as a pesudo-binary string, then the timestamp as an integer.
					//clickLog << (std::bitset<5>) ((buffer[j+3]&248) >> 3) << delimiter;
					//clickLog << std::dec << (buffer[j+3]&7)*256*256*256+buffer[j+2]*256*256+buffer[j+1]*256+buffer[j] << std::endl;


					//faster write?

					// this is the pseudo-binary for clicks/starts, and integer timestamp
					/*
					line = ((std::bitset<5>) ((buffer[j+3]&248) >> 3)).to_string();
					line += ' ';
					line += std::to_string((buffer[j+3]&7)*256*256*256+buffer[j+2]*256*256+buffer[j+1]*256+buffer[j]);
					line += '\n';
					line.shrink_to_fit();
					fwrite(line.c_str(), sizeof(char),line.length(),clickFile);
					*/
					//faster write for pure binary
					//fwrite(&buffer[j],sizeof(buffer[j]),FPGAdataPointSize,clickFile);


					//casting each byte as a bitset to print in "binary" or a string of 1s and 0s.
					//clickLog << (std::bitset<8>) buffer[j+3] << delimiter << (std::bitset<8>) buffer[j+2] << delimiter << (std::bitset<8>) buffer[j+1] << delimiter << (std::bitset<8>) buffer[j] << std::endl;
				}
				//clickLog.flush();
			}
			
			if(incompletePacket){
				for(int k = 0; k < incompletePacket; k++){
					buffer[k] = buffer[size + k - incompletePacket]; //transfer the bits from the incomplete data packet to the beginning of the buffer
				}
			}
		}

		//stats
		REALTIME_FUNCTION (buffer, size, stats);
	}
	
	//debugLog << "stop" << std::endl;
	//debugLog.close();
	
	
	if(saveClicks){
		clickLog.close();
	}
	/*
	if(saveClicks){
		fclose(clickFile);
	}*/

	return status;
}



// Pulls click statistics from the FPGA

_declspec(dllexport) int FPGA_Counts(bool saveData, unsigned char  fpgaCommand, char* fileName, __int64* stats, unsigned __int64* data, int* length, int runs){

	//datalog
	static char delimiter = ' ';
	std::ofstream dataLog;
	if(saveData){
		dataLog.open(fileName, std::ios::out | std::ios::app);
	}

	//command to send to FPGA or data received from FPGA
	unsigned char fpgaCommunicator[2];
	long fpgaCommunicatorBytes = 1;
	fpgaCommunicator[0] = fpgaCommand;

	//variables
	int status = 0;
	long size = 0;

	//if an insufficiently large data array is passed, fail before getting any data at all...
	if(runs*FPGAStatsDataSize > *length){
		status = ERROR_COUNTS_INITIALIZATION;
	}
	else{
		*length = 0;
	}

	for(int run = 0; run < runs; run++){

		//request number of new data points
		if(!status){
			fpgaCommunicator[0] = fpgaCommand;
			fpgaCommunicator[1] = 0;
			fpgaCommunicatorBytes = 1;
			///debugLog << "requesting size" << std::endl;
			status = !BulkOutPipe2->XferData(fpgaCommunicator, fpgaCommunicatorBytes);

			if(status){
				debugLog << "error requesting data size" << std::endl;
				debugLog.flush();
				status = ERROR_FPGA_REQUEST_DATA_SIZE;
			}
		}
		if(!status){
			//get data size --NOTE: This isn't really necessary, since we know the data will be 64 bytes. This was just to reduce development time by using the TimeTag project as a template.
			fpgaCommunicator[0] = 0;
			fpgaCommunicator[1] = 1;
			fpgaCommunicatorBytes = 512;
			status = !BulkInPipe5->XferData(buffer+incompletePacket, fpgaCommunicatorBytes);

			if(status){//error
				debugLog << "error getting size of data" << std::endl;
				debugLog.flush();
				status = ERROR_FPGA_GET_DATA_SIZE;
			}
		}

		if(!status){
			//calculate size
			size = (long) (buffer+incompletePacket)[1]+ ((long) (buffer+incompletePacket)[0])*256; //number of bytes stored in FPGA since last query
			//debugLog << "data size: " << size << " + " << moreData << " from last round = " << size + moreData << std::endl;
			//debugLog.flush();
			size += moreData;
			
			if(size < USBFrame){
				size = USBFrame;
			}
			moreData = size%USBFrame;
			size -=  moreData;

			status = !BulkInPipe4->XferData((buffer + incompletePacket), size); //starting off at pointer + incompletePacket, to ensure that data point from last query is completed.

			if(status){//error
				debugLog << status << "error requesting/getting data of size: " << size << std::endl;
				debugLog.flush();
				status = ERROR_FPGA_GET_BULK_DATA;
			}
			else{
				size += incompletePacket; //the total data size in buffer is the size of the data retrieved + the incomplete packet from the previous query
				if(size != 64){
					//this really ought not happen...
					status = ERROR_FPGA_DATA_SIZE;
					debugLog << status << " Error: Wrong data size; retrieved data of size: " << size << std::endl;
					debugLog.flush();
				}
				//debugLog << "got data of size: " << size << std::endl;
				//debugLog.flush();
			}
		}

		if (!status){
			incompletePacket = size%BYTE_SIZE;  //incomplete packets from this query... don't think there should be any.
			if(incompletePacket){
				debugLog << "This shouldn't happen? Incompete packet... size%8 != 0..." << std::endl;
				debugLog.flush();
			}

			
			//save data, but don't save any incomplete data packets; save those for next round, if they exist at all...

			//generate stats output
			//this uses knowledge of the byte by byte structure of the data returned by the FPGA
			//6 bytes for the first set (clocks), 4 bytes each for clicks, two-, and three-fold coincidences, and 2 bytes for 4-fold coincidences. This totals 64 bytes.
			//The data seems to be least-significant byte first due to how it was streamed from the FPGA
			
			//first six bytes of 0 clicks
			unsigned int p = 1;
			for(int k = 0; k < 6; k++){
				stats[0] += (int) p*((unsigned int) buffer[k]);
				p = p<<8; //next byte should be multiplied by a number 2^8 greater
			}
			//next 56 bytes:
			for(int j = 6; j < 62; j+=4){
				p = 1; //2^(3*8) is t he amount by which the 4th byte needs to be raised
				for(int k = 0; k < 4; k++){
					stats[(j-2)/4] += p*((unsigned int) buffer[j+k]);
					p=p<<8; //next byte should be multiplied by a number 2^8 greater
				}
			}
			//last two bytes
			stats[15] = (unsigned int) buffer[62] + 256*((unsigned int) buffer[63]);

			//Now to store the data
			for (int j = 0; j < (size - incompletePacket); j+=BYTE_SIZE){
					for (int k=0; k<BYTE_SIZE; k++){
						*(data+(*length)+j+k) = buffer[j+k + incompletePacket];
						if(saveData){
							dataLog << buffer[j+BYTE_SIZE-k-1] << delimiter;
						}
					}
					if(saveData){
						dataLog << std::endl;
					}
			}
			if(saveData){
				//debugLog << "data saved." << std::endl;
				//debugLog.flush();
				dataLog.flush();
			}
			*length += (size-incompletePacket);
			//debugLog << "Length: " << *length << std::endl;

			if(incompletePacket){ //really don't think this should happen... but just in case?
				for(int k = 0; k < incompletePacket; k++){
					buffer[k] = buffer[size + k - incompletePacket]; //transfer the bits from the incomplete data packet to the beginning of the buffer
				}
			}
		}
	}
	
	//debugLog << "stop" << std::endl;
	//debugLog.close();

	if(saveData){
		dataLog.close();
	}

	return status;
}


/********
Output pulse from channel.
returns 0 if successful, negative value if error
********/

_declspec(dllexport) int FPGA_Pulse(unsigned char fpgaTTLChannel){

	//command to send to FPGA or data received from FPGA
	unsigned char fpgaCommunicator[2];
	long fpgaCommunicatorBytes = 1;
	fpgaCommunicator[0] = fpgaTTLChannel | FPGA_PULSE;
	fpgaCommunicator[1] = 0;

	//variables
	int status = 0;
	long size = 0;

//send a command to the fpga
	status = !BulkOutPipe2->XferData(fpgaCommunicator, fpgaCommunicatorBytes);

	if(status){
		debugLog << "error requesting pulse" << std::endl;
		debugLog.flush();
		status = ERROR_FPGA_PULSE;
	}
	
	return status;
}


/********
Toggle channel output state.

returns 0 if successful, or negative value if error
********/

_declspec(dllexport) int FPGA_Toggle(unsigned char fpgaTTLChannel){
		//command to send to FPGA or data received from FPGA
	unsigned char fpgaCommunicator[2];
	long fpgaCommunicatorBytes = 1;
	fpgaCommunicator[0] = fpgaTTLChannel | FPGA_TOGGLE;
	fpgaCommunicator[1] = 0;

	//variables
	int status = 0;
	long size = 0;

	//send a command to the fpga
	status = !BulkOutPipe2->XferData(fpgaCommunicator, fpgaCommunicatorBytes);

	if(status){
		debugLog << "error requesting toggle" << std::endl;
		debugLog.flush();
		status = ERROR_FPGA_TOGGLE;
	}

	return status;
}

/////////////////////////////////////////////////////
// Default real-time
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
void correlate (unsigned char * data, int length, __int64 *stats)
{
    int i;
    int dlength = length%4;
    
    for (i=0; i<length; i+=4)
    {
        int state[4];
        state[0] = (data[i+3]&0x08)?true:false;
        state[1] = (data[i+3]&0x10)?true:false;
        state[2] = (data[i+3]&0x20)?true:false;
        state[3] = (data[i+3]&0x40)?true:false;

		//# of starts
		stats[0]+= data[i+3]&0x80?1:0;

        stats[3] += (int)state[2];//state 2
        stats[4] += (int)state[3];//state 3
        
        if (state[0])
        {
                stats[1] += 1; //state 0;
     
                stats[5] += (state[1])?1:0; //states 0&1
                stats[6] += (state[2])?1:0; //states 0&2
                stats[7] += (state[3])?1:0; //states 0&3
                
                stats[11] += (state[1]&state[2])?1:0; //states 0,1&2
                stats[12] += (state[1]&state[3])?1:0; //states 0,1&3
                stats[13] += (state[2]&state[3])?1:0; //states 0,2&3

                stats[15] += (state[1]&state[2]&state[3])?1:0; //states 0,1,2&3
        }
         
        if (state[1])
        {        
                 stats[2] += 1;//state 1
                 
                 stats[8] += (state[2])?1:0; //state 1&2
                 stats[9] += (state[3])?1:0; //state 1&3
        
                 stats[14] += (state[2]&state[3])?1:0;  //state 1&2&3              
        }
        stats[10] += (state[2]&state[3])?1:0; //state 2&3
    }
    return;             
}

