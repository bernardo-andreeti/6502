
library IEEE;                        
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Test bench interface is always empty.
entity P6502_RAM  is
    port (
        clk             : in std_logic;
        rst             : in std_logic;
        ready           : in std_logic;
        nmi, nres, irq  : in std_logic;   -- Interrupt lines (active low)
        display         : out std_logic_vector(7 downto 0);
        display_en_n    : out std_logic_vector(3 downto 0)
    );
end P6502_RAM;

-- Instantiate the components and generates the stimuli.
architecture behavioral of P6502_RAM is  
    
    -- Address of the program first instruction. Set according to the assembler process.
    constant PC_INIT                    : UNSIGNED(15 downto 0) := x"4000";
    
    signal RAMdata_in, RAMdata_out      : std_logic_vector(7 downto 0);
    signal reg1, reg2                   : std_logic_vector(7 downto 0);
    signal reg_CPUwe, CPUwe             : std_logic;
    signal reg_CPUaddress, address_temp : std_logic_vector(15 downto 0);
    signal display0, display1, 
           display2, display3           : std_logic_vector(7 downto 0);
    --signal count                        : std_logic_vector(5 downto 0);
    signal count                        : UNSIGNED(5 downto 0);
    signal clk_div                      : std_logic;
    
    function BCD7segments(number: in std_logic_vector(3 downto 0)) return std_logic_vector is
        variable display: std_logic_vector(7 downto 0);
    begin
        case number is
            when x"0" =>    display := "11000000";
            when x"1" =>    display := "11111001";
            when x"2" =>    display := "10100100";
            when x"3" =>    display := "10110000";
            when x"4" =>    display := "10011001";  
            when x"5" =>    display := "10010010";
            when x"6" =>    display := "10000011";
            when x"7" =>    display := "10111001";
            when x"8" =>    display := "10000000";
            when x"9" =>    display := "10011000";
            when x"A" =>    display := "10001000";
            when x"b" =>    display := "10000011";
            when x"C" =>    display := "11000110";
            when x"d" =>    display := "10100001";
            when x"E" =>    display := "10000110";
            when x"F" =>    display := "10001110";
            when others =>  display := "11111111";
        end case;
        return display;
    end BCD7segments;
    
begin
    -- Divides the Nexys board clock by 48 (100 MHz/48 = 2 MHz) 
    process(clk,rst)
    begin
        if rst = '1' then
            count <= (others=>'0');
        elsif rising_edge(clk) then
            if count = x"2F" then 
                count <= "000000";
            else
                count <= count + 1;
            end if;
        end if;
    end process;
    
    process(clk,rst)
    begin
        if rst = '1' then
            clk_div <= '0';
        elsif rising_edge(clk) then
            if count < x"18" then 
                clk_div <= '0';
            else
                clk_div <= '1';
            end if;
        end if;
   end process;
    
    -- 6502 Processor Core
    P6502: entity work.P6502 
        generic map (
            PC_INIT => PC_INIT
        )
        port map (
            clk         => clk_div,
            rst         => rst,
            we          => CPUwe,
            data_in     => RAMdata_out,
            data_out    => RAMdata_in,
            address_out => address_temp,
            ready       => ready,
            nmi         => nmi,
            nres        => nres,     
            irq         => irq
        );
    
    -- Sync Memory Writes   
    process(clk, rst)
    begin
        if rst = '1' then
            reg_CPUwe <= '0';
        elsif rising_edge(clk) then
            if count = x"16" then  
                reg_CPUwe <= CPUwe; -- High only for one period of 100 MHz clock
            else
                reg_CPUwe <= '0';
            end if;
        end if;
    end process;
    
    -- Sync IO access when integrated in fpga_nes project
    process(clk, rst)
    begin
        if rst = '1' then
            reg_CPUaddress <= (others=>'0');
        elsif rising_edge(clk) then
            if count = x"16" then
                reg_CPUaddress <= address_temp; -- Same moment as CPUwe signal is assigned
            end if;
        end if;
    end process;   
        
    -- Program/Data memory
    RAM: entity work.Memory(block_ram) 
        generic map (
            DATA_WIDTH    => 8,
            ADDR_WIDTH    => 16,
            IMAGE         => "AllSuite_IRQ_test.txt" 
        )
        port map (
            clk         => clk,
            we          => reg_CPUwe,
            data_in     => RAMdata_in,
            data_out    => RAMdata_out,
            address     => reg_CPUaddress
        );
        
    DISPLAY_CONTROL: entity work.DisplayCtrl
        port map (
            clk             => clk,
            rst             => rst,
            segments        => display,
            display_en_n    => display_en_n,
            display0        => display0,  -- Left most  display
            display1        => display1, 
            display2        => display2,  
            display3        => display3   -- Right most display
        );
    
    process(clk,rst)
    begin
        if rst = '1' then
            reg1 <= (others=>'0');
            reg2 <= (others=>'0');
        
        elsif rising_edge(clk) then
            if reg_CPUaddress = x"0210" and reg_CPUwe = '0' and RAMdata_out = x"FE" then -- LOAD
                reg1 <= RAMdata_out;
            end if;
            
            if reg_CPUaddress = x"0210" and reg_CPUwe = '1' then -- STORE
                reg2 <= RAMdata_in;
            end if;
        end if;
    end process;
    
    display0 <= BCD7segments(reg2(3 downto 0));
    display1 <= BCD7segments(reg2(7 downto 4));
    display2 <= BCD7segments(reg1(3 downto 0));
    display3 <= BCD7segments(reg1(7 downto 4));
        
end behavioral;


