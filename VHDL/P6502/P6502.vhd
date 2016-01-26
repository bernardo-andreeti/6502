--------------------------------------------------------------------------------------
-- DESIGN UNIT  : 6502                                                              --
-- DESCRIPTION  : Top-level processor entity. Connects control and data paths       --
-- AUTHOR       : Everton Alceu Carara                                              --
-- CREATED      : Fev, 2015                                                         --
-- VERSION      : 1.0                                                               --
-- HISTORY      : Version 1.0 - Fev, 2015 - Everton Alceu Carara                    --
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.P6502_pkg.all;

-- Same interface as cpu.v from fpga_nes project
entity P6502 is
    generic (
        PC_INIT         : UNSIGNED(15 downto 0) := (others=>'0')    -- Address of the program first instruction. Set according to the assembler process.
    );
    port( 
        clk, rst, ready : in std_logic;
        nmi, nres, irq  : in std_logic;   -- Interrupt lines (active low)
        data_in         : in std_logic_vector(7 downto 0);  -- Data from memory
        data_out        : out std_logic_vector(7 downto 0); -- Data to memory
        address_out     : out std_logic_vector(15 downto 0);-- Address bus to memory
        we  : out std_logic -- Access control to data memory ('0' for Reads, '1' for Writes)
    );
end P6502;

architecture structural of P6502 is

    signal uins           : Microinstruction;
    signal instruction    : std_logic_vector(7 downto 0);
    signal spr            : std_logic_vector(7 downto 0);
    signal clk_n, nOffset : std_logic;
    
begin

    -- Data path operates in falling edge of clock in order to achieve synchronization on memory read 
    clk_n <= not clk;
    -- clock needs to be set to 1.785MHz for correct operation with fpga_nes project
    DATA_PATH: entity work.DataPath
        generic map (
            PC_INIT     => PC_INIT
        )
        port map (
            clk         => clk_n,
            rst         => rst,
            address     => address_out,
            data_in     => data_in,
            data_out    => data_out,
            spr_out     => spr,
            nOffset_out => nOffset, 
            uins        => uins
        );
        
    CONTROL_PATH: entity work.ControlPath
        port map (
            clk         => clk,
            rst         => rst,
            uins        => uins,
            spr_in      => spr,    
            instruction => data_in,
            we          => we,
            nOffset_in  => nOffset,
            ready       => ready,
            nmi         => nmi,
            nres        => nres,
            irq         => irq
        );
     
end structural;