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
use work.P6502_pkg.all;

entity P6502 is
    port( 
        clk, rst    : in std_logic;
        ce          : out std_logic;    -- Chip enable to data memory
        rw          : out std_logic;    -- Access control to data memory (rw =0 : WRITE, rw = 1: READ)
        address     : out std_logic_vector(15 downto 0);    -- Address bus to memory
        data        : inout std_logic_vector(7 downto 0)    -- Data to/from data memory
      );
end P6502;

architecture structural of P6502 is

    signal uins         : Microinstruction;
    signal instruction  : std_logic_vector(7 downto 0);
    signal clk_n        : std_logic;
    
begin

    -- Data path operates in falling edge of clock
    -- in order to achieve synchronization on memory read 
    clk_n <= not clk;
    
    DATA_PATH: entity work.DataPath
        port map (
            clk         => clk_n,
            rst         => rst,
            address     => address,
            data        => data,
            uins        => uins
        );
        
    CONTROL_PATH: entity work.ControlPath
        port map (
            clk         => clk,
            rst         => rst,
            uins        => uins,
            instruction => data            
        );
        
    ce <= uins.ce;
    rw <= uins.rw;
     
end structural;
