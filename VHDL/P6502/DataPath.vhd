--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Data path                                                         --
-- DESCRIPTION  : Organization described in 6502.circ (Logisim schematic)           --
-- AUTHOR       : Everton Alceu Carara and Bernardo Andreeti                        --
-- CREATED      : Feb, 2015                                                         --
-- VERSION      : 0.7                                                               --
-- HISTORY      : Version 0.1 - Feb, 2015 - Everton Alceu Carara                    --
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.P6502_pkg.all;
   
entity DataPath is
    generic (
        PC_INIT         : UNSIGNED(15 downto 0) := (others=>'0')    -- First instruction address
    );
    port(  
        clk, rst        : in std_logic;
        address         : out std_logic_vector(15 downto 0);    -- Address bus to memory
        data_in         : in std_logic_vector(7 downto 0);      -- Data from memory
        data_out        : out std_logic_vector(7 downto 0);     -- Data to memory
        spr_out         : out std_logic_vector(7 downto 0);     -- Status Processor Register
        nOffset_out     : out std_logic;                        -- Negative Offset Signal
        uins            : in Microinstruction                   -- Control signals
      );
end DataPath;

architecture structural of DataPath is

    -- Internal busses
    signal DB, SB, ADL, ADH: std_logic_vector(7 downto 0);
    
    -- Registers nets
    signal AI_d, AI_q, BI_d, BI_q, AC_q, S_d, S_q, X_q, Y_q, PCH_q, PCL_q, ABL_q, ABH_q, P_d, P_q: std_logic_vector(7 downto 0);
     
    -- Internal nets
    signal ALUresult: std_logic_vector(7 downto 0);
    signal carryFlag, overflowFlag, ALUcarry_in, halfCarry: std_logic;
    signal inPC, MAR_d, MAR_q: std_logic_vector(15 downto 0);
    
begin

    AI: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => AI_d,
            q       => AI_q,
            ce      => uins.wrAI
        );
        
    BI: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => BI_d,
            q       => BI_q,
            ce      => uins.wrBI
        );
        
    -- Multiplexer connected to the AI register input
    MUX_AI: AI_d <= ADL when uins.mux_ai = "00" else 
                    x"00" when uins.mux_ai = "01" else
                    SB;
    
    -- Multiplexer connected to the BI register input
    MUX_BI: BI_d <= DB when uins.mux_bi = "00" else 
                    not DB when uins.mux_bi = "01" else
                    SB;
    
    ALU: entity work.ALU 
        port map (
            a           => AI_q,
            b           => BI_q,
            result      => ALUresult,
            operation   => uins.ALUoperation,
            c           => carryFlag,
            v           => overflowFlag,
            carry_in    => ALUcarry_in
        );
        
    -- Multiplexer connected to the ALU carry input
    MUX_CARRY: ALUcarry_in <=   '1' when uins.mux_carry = "00" else
                                P_q(CARRY) when uins.mux_carry = "01" else
                                not P_q(CARRY) when uins.mux_carry = "10" else
                                halfCarry;
                            
    AC: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => SB,
            q       => AC_q,
            ce      => uins.wrAC
        );
                
    -- DB bus
    MUX_DB: DB <= AC_q when uins.mux_db = "000" else 
                  SB when uins.mux_db = "001" else
                  PCL_q when uins.mux_db = "010" else
                  PCH_q when uins.mux_db = "011" else
                  data_in when uins.mux_db = "100" else
                  P_q;   
                              
    -- SB bus
    MUX_SB: SB <= S_q when uins.mux_sb = "000" else
                  ALUresult when uins.mux_sb = "001" else 
                  ADH when uins.mux_sb = "010" else
                  X_q when uins.mux_sb = "011" else
                  Y_q when uins.mux_sb = "100" else
                  AC_q when uins.mux_sb = "101" else
                  DB;
          
    -- ADL bus
    MUX_ADL: ADL <= ALUresult when uins.mux_adl = "00" else
                    S_q when uins.mux_adl = "01" else
                    DB when uins.mux_adl = "10" else
                    PCL_q;
    
    
    -- ADH bus
    MUX_ADH: ADH <= DB when uins.mux_adh = "00" else
                    SB when uins.mux_adh = "01" else
                    (x"00") when uins.mux_adh = "10" else
                    (x"01");
    
    S: entity work.RegisterNbits
        generic map (
            WIDTH   => 8,
            INIT_VALUE  => 255
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => S_d,
            q       => S_q,
            ce      => uins.wrS
        );
        
    -- Multiplexer connected to the S register input
    MUX_S: S_d <= STD_LOGIC_VECTOR(UNSIGNED(S_q) - 1) when uins.mux_s = '0' else SB;
    
    X: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => SB,
            q       => X_q,
            ce      => uins.wrX
        );
        
    Y: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => SB,
            q       => Y_q,
            ce      => uins.wrY
        );
        
    PCH: entity work.RegisterNbits
        generic map (
            WIDTH   => 8,
            INIT_VALUE => TO_INTEGER(PC_INIT(15 downto 8))
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => inPC(15 downto 8),
            q       => PCH_q,
            ce      => uins.wrPCH
        );
        
    PCL: entity work.RegisterNbits
        generic map (
            WIDTH   => 8,
            INIT_VALUE => TO_INTEGER(PC_INIT(7 downto 0))
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => inPC(7 downto 0),
            q       => PCL_q,
            ce      => uins.wrPCL
        );
        
    -- Multiplexer connected to the PCH/PCL register inputs
    MUX_PC: inPC <= STD_LOGIC_VECTOR(UNSIGNED(PCH_q & PCL_q) + 1) when uins.mux_pc = '0' else ADH & ADL;
    
    ABL: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => ADL,
            q       => ABL_q,
            ce      => uins.wrABL
        );
        
    ABH: entity work.RegisterNbits
        generic map (
            WIDTH   => 8
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => ADH,
            q       => ABH_q,
            ce      => uins.wrABH
        );
        
    MUX_MAR: MAR_d <= (PCH_q & PCL_q) when uins.mux_mar = "0000" else
                      (x"00" & DB) when uins.mux_mar = "0001" else
                      (x"00" & ALUresult) when uins.mux_mar = "0010" else
                      (x"FFFF") when uins.mux_mar = "0011" else
                      (x"FFFE") when uins.mux_mar = "0100" else -- BRK/IRQ request handler
                      (x"FFFD") when uins.mux_mar = "0101" else
                      (x"FFFC") when uins.mux_mar = "0110" else -- Power on reset handler
                      (x"FFFB") when uins.mux_mar = "0111" else
                      (x"FFFA");                                -- NMI request handler 
        
    MAR: entity work.RegisterNbits

        generic map (
            WIDTH   => 16
        )
        port map (
            clk     => clk,
            rst     => rst,
            d       => MAR_d,
            q       => MAR_q,
            ce      => uins.wrMAR
        );

    MUX_ADDRESS: address <= MAR_q when uins.mux_address = '0' else
                            (ABH_q & ABL_q);
        
    data_out <= DB;
    spr_out <= P_q;    
    
    P_d(CARRY) <= carryFlag when uins.mux_p = '0' else DB(CARRY);
    P_d(ZERO) <= '1' when (SB = x"00" and uins.mux_p = '0') else DB(ZERO) when uins.mux_p = '1' else '0';
    P_d(INTERRUPT) <= DB(INTERRUPT) when uins.mux_p = '1' else '0';
    P_d(DECIMAL) <= DB(DECIMAL) when uins.mux_p = '1' else '0';
    P_d(BREAKF) <= DB(BREAKF) when uins.mux_p = '1' else '0';
    P_d(OVERFLOW) <= overflowFlag when uins.mux_p = '0' else DB(OVERFLOW);
    P_d(NEGATIVE) <= SB(7) when uins.mux_p = '0' else DB(NEGATIVE); -- Negative flag (result's MSb)
    P_d(UNUSED) <= '1'; 
    
    STATUS_PROCESSOR_REGISTER: for i in 0 to 7 generate
        FFD: entity work.FlipFlopD_sr
            port map(
                clk     => clk,
                rst     => uins.rstP(i),
                set     => uins.setP(i),
                ce      => uins.ceP(i),
                d       => P_d(i),
                q       => P_q(i)
            );
    end generate;
    
    -- Half Carry Flip Flop
    FFHC: entity work.FlipFlopD_sr 
        port map(
                clk     => clk,
                rst     => uins.rstP(CARRY),
                set     => '0',
                ce      => '1',
                d       => carryFlag,
                q       => halfCarry
            );
            
    -- Negative Offset Flip Flop
    FFNO: entity work.FlipFlopD_sr 
        port map(
                clk     => clk,
                rst     => uins.rstP(NEGATIVE),
                set     => '0',
                ce      => uins.wrOffset,
                d       => SB(7), -- Detects negative offsets for branch instructions
                q       => nOffset_out
            );        

end Structural;
