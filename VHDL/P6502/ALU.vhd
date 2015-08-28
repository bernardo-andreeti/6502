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
    signal carry_ext: std_logic_vector(7 downto 0);
    signal temp , a_u, b_u, carry_u: unsigned (7 downto 0);
    signal sum_ext, a_ext, b_ext: unsigned(9 downto 0);
     
begin
    
    result <= STD_LOGIC_VECTOR(temp);
    
    temp <= a_u and b_u      when operation = ALU_AND else
            a_u or b_u       when operation = ALU_OR else
            a_u xor b_u      when operation = ALU_XOR else
            b_u sll 1        when operation = ALU_ASL else 
            b_u srl 1        when operation = ALU_LSR else
            a_u              when operation = ALU_A else 
            b_u              when operation = ALU_B else
            ((b_u rol 1) or carry_u)          when operation = ALU_ROL else
            ((carry_u sll 7) or (b_u ror 1))  when operation = ALU_ROR else
            sum_ext(8 downto 1);        
    
    a_u <= UNSIGNED(a); b_u <= UNSIGNED(b); 
    carry_ext <= ("0000000" & carry_in); carry_u <= UNSIGNED(carry_ext);   
    a_ext <= ('0' & a_u & '1'); 
    b_ext <= ('0' & b_u & carry_in) when operation = ALU_ADC else ('0' & b_u & '0');
    
    -- Sum and carry generation
    sum_ext <= (a_ext + b_ext) when (operation = ALU_ADC or operation = ALU_ADD) else (a_ext + b_ext - 2) when operation = ALU_DEC else "0000000000" when operation = ALU_NOP;
       
    -- Overflow flag (Operands with the same signal but different from the result's signal)
    v <= '1' when a_u(7) = b_u(7) and a_u(7) /= temp(7) else '0';     -- Behavioral
    
    -- Carry flag
    c <= b_u(7) when (operation = ALU_ASL or operation = ALU_ROL) else b_u(0) when (operation = ALU_LSR or operation = ALU_ROR) else sum_ext(9);     
    
end behavioral;

