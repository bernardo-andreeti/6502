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
use work.P6502_pkg.all;

entity ALU is
    port( 
        a, b        : in std_logic_vector(7 downto 0);      -- Operands
        carry_in    : in std_logic;                         -- Carry in
        result      : out std_logic_vector(7 downto 0);     -- Operation result
        c           : out std_logic;                        -- Carry flag
        v           : out std_logic;                        -- Overflow flag
        operation   : in ALU_Operation_type     
    );
end ALU;

architecture behavioral of ALU is

    -- Signal used to read the result bits (Can't read directly output ports)
    signal temp: std_logic_vector(7 downto 0);
    signal sum, a_s, b_s: std_logic_vector(8 downto 0);
    signal carry: std_logic;

begin
    
    Result <= temp;
    
    temp <= a and b         when operation = ALU_AND else
            a or b          when operation = ALU_OR else
            a xor b         when operation = ALU_XOR else
            a               when operation = ALU_A else 
            b               when operation = ALU_B else
            sum(7 downto 0);    
            
    a_s <= ('0' & a); b_s <= ('0' & b);
    -- Sum and carry generation
    carry <= carry_in;
    sum <= (a_s + b_s + carry) when operation = ALU_ADC else (a_s + b_s) when operation = ALU_ADD else (a_s + b_s - 1) when operation = ALU_DEC else "000000000" when operation = ALU_NOP;
        
    -- Overflow flag (Operands with the same signal but different from the result's signal)
    v <= '1' when a(7) = b(7) and a(7) /= temp(7) else '0';     -- Behavioral
    
    -- Carry flag
    c <= sum(8); -- when Operation = "101" else '0';
    
end behavioral;

