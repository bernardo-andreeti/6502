library IEEE;                        
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.CONV_STD_LOGIC_VECTOR;

-- Test bench interface is always empty.
entity P6502_RAM_tb  is
end P6502_RAM_tb;


-- Instantiate the components and generates the stimuli.
architecture behavioral of P6502_RAM_tb is  
    
    constant DATA_WIDTH : integer := 8;
    constant ADDR_WIDTH : integer := 16;
    
    signal clk          : std_logic := '0';
    signal rst          : std_logic;
    signal we           : std_logic;
    signal address      : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal dataBus      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal RAM_data_in, RAM_data_out: std_logic_vector(DATA_WIDTH-1 downto 0);
    
begin

    -- Instantiates the units under test.
    DUV: entity work.P6502_RAM 
        port map (
            clk         => clk,
            rst         => rst
        );        
           
    -- Generates the stimuli.
    rst <= '1', '0' after 10 ns;
    clk <= not clk after 20 ns;    -- 25 MHz    

end behavioral;


