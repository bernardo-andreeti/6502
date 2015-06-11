-------------------------------------------------------------------------
-- Design unit: FlipFlopD_sr
-- Description: Flip-Flop D with preset
--------------------------------------------------------------------------

library IEEE;                        
use IEEE.std_logic_1164.all;


entity FlipFlopD_sr is
    port (
        clk         : in std_logic;
        rst, set    : in std_logic;
        ce          : in std_logic;
        d           : in std_logic;        
        q           : out std_logic
    );
end FlipFlopD_sr;


architecture beharioral of FlipFlopD_sr is
begin    
    
    process (clk,rst,set)
    begin
    
        if rst = '1' then
            q <= '0';       
        
        elsif rising_edge(clk) then
            if set = '1' then
                q <= '1';
            elsif ce = '1' then
                q <= d;
            end if;
        end if;    
    
    end process;
    
end beharioral;


