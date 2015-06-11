--------------------------------------------------------------------------------------------------
-- DESIGN UNIT  : ALU                                                                           --
-- DESCRIPTION  : Arithmetic and logic unit                                                     --
-- AUTHOR       : Everton Alceu Carara                                                          --
-- CREATED      : Feb, 2015                                                                     --
-- VERSION      : 1.0                                                                           --
-- HISTORY      : Version 1.0 - Feb, 2015 - Everton Alceu Carara                                --
--------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ALU is
    port( 
        a, b        : in std_logic_vector(7 downto 0);      -- Operands
        carry_in    : in std_logic;                         -- Carry in
        result      : out std_logic_vector(7 downto 0);     -- Operation result
        n           : out std_logic;                        -- Negative flag
        z           : out std_logic;                        -- Zero flag
        c           : out std_logic;                        -- Carry flag
        v           : out std_logic;                        -- Overflow flag
        operation   : in std_logic_vector(2 downto 0)       -- Operation select                  
    );
end ALU;

architecture behavioral of ALU is

    -- Signal used to read the result bits (Can't read directly output ports)
    signal temp: std_logic_vector(7 downto 0);
    signal sum: std_logic_vector(8 downto 0);
    signal carry: std_logic;

begin
    
    Result <= temp;
    
    temp <= a and b         when Operation = "000" else
            a or b          when Operation = "001" else
            a xor b         when Operation = "010" else
            a               when Operation = "011" else 
            b               when Operation = "100" else
            sum(7 downto 0);    
            
    
    -- Sum and carry generation
    carry <= carry_in when Operation = "101" else '0';      -- Operation = "101": ADC or SBC
    sum <= ('0' & a) + ('0' & b) + carry;
    
    -- Negative flag (result's MSb)
    n <= temp(7);
    
    -- Zero flag
    z <= '1' when temp = x"0000" else '0';
    
    -- Overflow flag (Operands with the same signal but different from the result's signal)
    v <= '1' when a(7) = b(7) and a(7) /= temp(7) else '0';     -- Behavioral
    
    -- Carry flag
    c <= sum(8) when Operation = "101" else '0';
    
end behavioral;

