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

-- Same interface as cpu.v from fpga_nes project
entity P6502 is
    port( 
        clk_in, rst_in, ready_in    : in std_logic;
        nnmi_in, nres_in, nirq_in   : in std_logic;   -- Interrupt lines (active low)
        d_in      : in std_logic_vector(7 downto 0);  -- Data from memory
        d_out     : out std_logic_vector(7 downto 0); -- Data to memory
        a_out     : out std_logic_vector(15 downto 0);-- Address bus to memory
        r_nw_out  : out std_logic -- Access control to data memory ('1' for Reads, '0' for Writes)
               
        -- Debuger lines (not used in this implementation)
        -- dbgreg_sel_in : in std_logic_vector(3 downto 0);
        -- dbgreg_in     : in std_logic_vector(7 downto 0);
        -- dbgreg_wr_in  : in std_logic;
        -- dbgreg_out    : out std_logic_vector(7 downto 0);
        -- brk_out       : out std_logic
      );
end P6502;

architecture structural of P6502 is

    signal uins         : Microinstruction;
    signal instruction  : std_logic_vector(7 downto 0);
    signal spr          : std_logic_vector(7 downto 0);
    signal clk_n        : std_logic;
    
begin

    -- Data path operates in falling edge of clock
    -- in order to achieve synchronization on memory read 
    clk_n <= not clk_in;
    -- clock needs to be set to 1.785MHz for correct operation with fpga_nes project
    DATA_PATH: entity work.DataPath
        port map (
            clk         => clk_n,
            rst         => rst_in,
            address     => a_out,
            data_in     => d_in,
            data_out    => d_out,
            spr_out     => spr,
            uins        => uins
        );
        
    CONTROL_PATH: entity work.ControlPath
        port map (
            clk         => clk_in,
            rst         => rst_in,
            uins        => uins,
            spr_in      => spr,    
            instruction => d_in,
            ready       => ready_in,
            nmi         => nnmi_in,
            nres        => nres_in,
            irq         => nirq_in
        );
        
    r_nw_out <= uins.we;
     
end structural;
