There are several possible USB drivers for the FX2 boards:

1. CyUSB signed, Cypress GUID (recommended)
2. CyUSB unsigned, KNJN GUID
3. EzUSB: lagacy driver, blocking transfers and 32bit Windows only

Choose one driver when MS Windows asks you (the first time the board is plugged in).
Then select the same driver and GUID in FPGAconf option menu.
