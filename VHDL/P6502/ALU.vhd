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
use IEEE.numeric_std.all;
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
    signal sum_ext, a_ext, b_ext: unsigned(9 downto 0);
     
begin  
    result <= temp;
    
    temp <= a and b                  when operation = ALU_AND else
            a or b                   when operation = ALU_OR else
            a xor b                  when operation = ALU_XOR else
            b(6 downto 0) & '0'      when operation = ALU_ASL else 
            '0' & b(7 downto 1)      when operation = ALU_LSR else
            b(6 downto 0) & carry_in when operation = ALU_ROL else
            carry_in & b(7 downto 1) when operation = ALU_ROR else
            a                        when operation = ALU_A else 
            b                        when operation = ALU_B else
            STD_LOGIC_VECTOR(sum_ext(8 downto 1));        
    
    a_ext <= UNSIGNED('0' & a & '1'); 
    b_ext <= UNSIGNED('0' & b & carry_in) when operation = ALU_ADC or operation = ALU_DECHC else UNSIGNED('0' & b & '0');
    
    -- Sum and carry generation
    sum_ext <= (a_ext + b_ext) when (operation = ALU_ADC or operation = ALU_ADD) else (a_ext + b_ext - 2) when (operation = ALU_DEC or operation = ALU_DECHC) else "0000000000";
       
    -- Overflow flag (Operands with the same signal but different from the result's signal)
    v <= '1' when a(7) = b(7) and a(7) /= temp(7) else '1' when (b(6) = '1' and operation = ALU_B) else '0';     -- Behavioral
    
    -- Carry flag
    c <= b(7) when (operation = ALU_ASL or operation = ALU_ROL) else b(0) when (operation = ALU_LSR or operation = ALU_ROR) else sum_ext(9);     
    
end behavioral;

