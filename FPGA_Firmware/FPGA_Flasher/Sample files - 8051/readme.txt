Emulation of an FPGA JTAG cable
-------------------------------

The USB JTAG adapter open source project shows how to emulate an FPGA JTAG cable inside the FX2 chip.

For example, to emulate an Altera USB-Blaster:
1. Open FPGAconf
2. Select the "8051" tab
3. Load the "USB JTAG adapter.hex" of your board
4. Click on "Program!"
5. The FX2 re-enumerates in USB-Blaster mode (Windows "beeps" twice).
6. Go to Quartus-II programmer, click on "Hardware Setup..." and you should be able to select a USB-Blaster JTAG cable.

Now you can program the FPGA and the FPGA boot-PROM using JTAG. You can also use SignalTap.

See the following pages for more information:
 http://www.ixo.de/info/usb_jtag/
 http://www.fpga4fun.com/forum/viewtopic.php?t=483
 http://www.fpga4fun.com/forum/viewtopic.php?t=1094
