-----------------------------------------------------------------------------------------
-- Design unit: Display Controller
-- Description: This circuit drives the anode signals (display enable) and corresponding 
-- cathode patterns (segments code) of each digit in a repeating, continuous succession, 
-- at an update rate that is faster than the human eye can detect.
-----------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity DisplayCtrl is
    port (
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Board display segments
        segments        : out std_logic_vector(7 downto 0);
        
        -- Display enable (active low)
        display_en_n    : out std_logic_vector(3 downto 0);
        
        -- 7 segments input codes to each display
        display0        : in std_logic_vector(7 downto 0);  -- Right most display
        display1        : in std_logic_vector(7 downto 0);
        display2        : in std_logic_vector(7 downto 0);
        display3        : in std_logic_vector(7 downto 0)   -- Left most display
    );
end DisplayCtrl;

architecture arch1 of DisplayCtrl is

    signal display: std_logic_vector(1 downto 0);
    signal count : std_logic_vector(15 downto 0);
    signal clk_div: std_logic;
    
begin
    
    -- Reduce the board clock frequence
    process(clk, rst)
    begin
        if rst = '1' then
            count <= (others=>'0');
            
        elsif rising_edge(clk) then
            count <= count + 1;
        end if;
                
    end process;
        
    clk_div <= count(count'high);   -- Reduced clock
        
    -- Continuously enables a display at time and 
    -- present the code corresponding to one of the 
    -- four display entries 
    process(clk_div, rst)
    begin
        if rst = '1' then
            display_en_n <= "1111";     -- Disable all displays
            display <= (others=>'0');   -- Turn of all segments
            
        elsif rising_edge(clk_div) then
            display <= display + 1;     -- Select one display to enable
            
            -- Verifies the enabled display present the corresponding code
            case display is
                when "00" =>
                    display_en_n <= "1110"; -- Enables the right most display  
                    segments <= display0;   -- Presents the display0 input code
                
                when "01" =>
                    display_en_n <= "1101";
                    segments <= display1;
                    
                when "10" =>
                    display_en_n <= "1011";
                    segments <= display2;
                    
                when "11" =>
                    display_en_n <= "0111"; -- Enables the right most display 
                    segments <= display3;   -- Presents the display3 input code

                when others =>
                    segments <= (others=>'1');
                    
            end case;
        end if;
    end process;
end arch1;