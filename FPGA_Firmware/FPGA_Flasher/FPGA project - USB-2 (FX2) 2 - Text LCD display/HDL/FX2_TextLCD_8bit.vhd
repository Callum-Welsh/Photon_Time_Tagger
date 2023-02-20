// Sample code for FX2 USB-2 interface
// (c) fpga4fun.com KNJN LLC - 2006, 2007, 2008, 2009

// This example shows how to receive data from USB-2
// We control a text LCD using the bytes received

/
// This example was translated from the "FX2_TextLCD.v" file
// by a VHDL user of our boards. This is published here with
// his permission, but without warranty.
//

library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY FX2_TextLCD_SaxoXylo IS
    PORT(    FX2_CLK, FX2_PA_7 : IN STD_LOGIC;
            FX2_SLRD, FX2_SLWR, FX2_PA_2, FX2_PA_3, FX2_PA_4, FX2_PA_5,
FX2_PA_6 : OUT STD_LOGIC;
            LCD_RS, LCD_RW, LCD_E : OUT STD_LOGIC;
            LCD_DB : OUT STD_LOGIC_VECTOR(7 downto 0);
            FX2_FD : INOUT STD_LOGIC_VECTOR(7 downto 0);
            FX2_flags : IN STD_LOGIC_VECTOR(2 downto 0)); END FX2_TextLCD_SaxoXylo;

ARCHITECTURE a OF FX2_TextLCD_SaxoXylo IS

    SIGNAL FIFO_CLK : STD_LOGIC;
    SIGNAL FIFO2_EMPTY : STD_LOGIC;
    SIGNAL FIFO3_EMPTY : STD_LOGIC;
    SIGNAL FIFO4_FULL : STD_LOGIC;
    SIGNAL FIFO5_FULL : STD_LOGIC;

    SIGNAL FIFO2_DATA_AVAILABLE : STD_LOGIC;
    SIGNAL FIFO3_DATA_AVAILABLE : STD_LOGIC;
    SIGNAL FIFO4_READY_TO_ACCEPT_DATA : STD_LOGIC;
    SIGNAL FIFO5_READY_TO_ACCEPT_DATA : STD_LOGIC;

    SIGNAL FIFO_RD : STD_LOGIC;
    SIGNAL FIFO_WR : STD_LOGIC;
    SIGNAL FIFO_PKTEND : STD_LOGIC;
    SIGNAL FIFO_DATAIN_OE : STD_LOGIC;
    SIGNAL FIFO_DATAOUT_OE : STD_LOGIC;

    SIGNAL FIFO_FIFOADR : STD_LOGIC_VECTOR(1 downto 0);
    SIGNAL FIFO_DATAIN : STD_LOGIC_VECTOR(7 downto 0);
    SIGNAL FIFO_DATAOUT : STD_LOGIC_VECTOR(7 downto 0);

    SIGNAL state : STD_LOGIC;

    SIGNAL LCD_DB_INT : STD_LOGIC_VECTOR(7 downto 0);

    SIGNAL DATA_AVAILABLE : STD_LOGIC;

    SIGNAL RECEIVED_ESCAPE : STD_LOGIC;
    SIGNAL RECEIVED_DATA : STD_LOGIC;

    SIGNAL count : std_logic_vector(2 downto 0);

    SIGNAL LCD_INSTRUCTION : STD_LOGIC;

    SIGNAL LCD_E_INT : STD_LOGIC;

    Begin


--////////////////////////////////////////////////////////////////////////////////
--// Rename "FX2" ports into "FIFO" ports, to give them more meaningful names
--// FX2 USB signals are active low, take care of them now
--// Note: You probably don't need to change anything in this section

    FIFO_CLK<= FX2_CLK;

    FIFO2_EMPTY <= not FX2_flags(0);
    FIFO2_DATA_AVAILABLE <= not FIFO2_empty;
    FIFO3_EMPTY <= not FX2_flags(1);
    FIFO3_DATA_AVAILABLE <= not FIFO3_empty;
    FIFO4_full <= not FX2_flags(2);
    FIFO4_ready_to_accept_data <=not FIFO4_full;
    FIFO5_full <= not FX2_PA_7;
    FIFO5_ready_to_accept_data <=not FIFO5_full;

    FX2_PA_3 <='1';

    FX2_SLRD <= not FIFO_RD;
    FX2_SLWR <= not FIFO_WR;

    FX2_PA_2 <= not FIFO_DATAIN_OE;
    FX2_PA_6 <= not FIFO_PKTEND;

    FX2_PA_4 <= FIFO_FIFOADR(0);
    FX2_PA_5 <= FIFO_FIFOADR(1);

    FIFO_DATAIN <= FX2_FD;

    FX2_FD <= FIFO_DATAOUT when FIFO_DATAOUT_OE='1' else "ZZZZZZZZ";


 ----------------------------------------------------------------------------------------------------
--////////////////////////////////////////////////////////////////////////////////
--// So now everything is in positive logic
--//    FIFO_RD, FIFO_WR, FIFO_DATAIN, FIFO_DATAOUT, FIFO_DATAIN_OE,FIFO_DATAOUT_OE, FIFO_PKTEND, FIFO_FIFOADR
--//    FIFO2_empty, FIFO2_data_available
--//    FIFO3_empty, FIFO3_data_available
--//    FIFO4_full, FIFO4_ready_to_accept_data
--//    FIFO5_full, FIFO5_ready_to_accept_data

    FIFO_FIFOADR<="00";

    FIFO_DATAIN_OE<='1';
    FIFO_DATAOUT_OE<='0';

    FIFO_RD <=state;
    FIFO_WR <='0';
    FIFO_PKTEND<='0';
    FIFO_DATAOUT<="00000000";

    LCD_DB<=LCD_DB_INT;

    process (FIFO_CLK)
    begin
    if rising_edge(FIFO_CLK) then
        if state='0' then
            if FIFO2_data_available='1' then
                state<='1';    -- Wait for Data
                end if;
        else
                state <='0'; -- Read Data then go back to waiting
        end if;
    end if;
    end process;

    process (FIFO_CLK)
    begin
        if rising_edge(FIFO_CLK) then
            if FIFO_RD='1' then
                LCD_DB_INT<=FIFO_DATAIN;
                end if;
            end if;
    end process;

    process (FIFO_CLK)
    begin
        if rising_edge(FIFO_CLK) then
            DATA_AVAILABLE <=FIFO_RD;
            end if;
    end process;


    RECEIVED_ESCAPE <= DATA_AVAILABLE when LCD_DB_INT="00000000" else '0';

    RECEIVED_DATA <= DATA_AVAILABLE when LCD_DB_INT/="00000000" else '0';

    -- Counter to stretch LCD Accesses
    process (FIFO_CLK)
    begin
        if rising_edge(FIFO_CLK) then
            if DATA_AVAILABLE='1' or (count/="000") then
                count<=count+"001";
                end if;
            end if;
    end process;


    -- activate LCD_E for 6 clocks, so at 24MHz, that's 6x41.6ns=250ns

    process (FIFO_CLK)
    begin
        if rising_edge(FIFO_CLK) then
            if LCD_E_INT='0' then
                LCD_E_INT<=RECEIVED_DATA;
                elsif count="110" then
                    LCD_E_INT<='0';
                else
                    LCD_E_INT<='1';
                end if;
            end if;
    end process;

    LCD_E<=LCD_E_INT;

    process (FIFO_CLK)
    begin
        if rising_edge(FIFO_CLK) then
            if LCD_INSTRUCTION='0' then
                LCD_INSTRUCTION<=RECEIVED_ESCAPE;
            elsif count="111" then
                LCD_INSTRUCTION<='0';
            else
                LCD_INSTRUCTION<='1';
            end if;
        end if;
    end process;

    LCD_RS <= not LCD_INSTRUCTION;
    LCD_RW<='0';


    End a;
