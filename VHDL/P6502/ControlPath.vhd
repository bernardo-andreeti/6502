--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Control path                                                      --
-- DESCRIPTION  : 6502 Control Logic                                                --                    
-- AUTHOR       : Everton Alceu Carara and Bernardo Favero Andreeti                 --
-- CREATED      : Feb, 2015                                                         --
-- VERSION      : 1.0                                                               --
-- HISTORY      : Version 1.0 - Feb, 2015 - Everton Alceu Carara                    --
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.P6502_pkg.all;

entity ControlPath is
    port(   
        clk, rst    : in std_logic;          
        uins        : out microinstruction;             -- Control signals to data path
        instruction : in std_logic_vector(7 downto 0)   -- Current instruction stored in instruction register
       );
end ControlPath;
                   
architecture ControlPath of ControlPath is
    
    -- Instruction register
    signal IR: std_logic_vector(7 downto 0);
    signal currentState, nextState : State;
    
    -- Current instruction decoded
    signal decIns : DecodedInstruction_type;
    
    signal opcode: std_logic_vector(7 downto 0);
    
begin  

    
    opcode <= instruction when currentState = T0 else IR;          
    decIns <= InstructionDecoder(opcode);

    ------------------------
    -- FSM state register --
    ------------------------
    process(rst, clk)
    begin
        if rst = '1' then 
            currentState <= IDLE;    -- Sidle is the state the machine stays while processor is being reset
                            
        elsif rising_edge(clk) then
            currentState <= nextState;
        end if;
    end process;
    
    
    ----------------------------------------
    -- FSM next state combinational logic --
    ----------------------------------------
    process(currentState, decIns)  
    begin
  
        case currentState is
                  
            when IDLE =>  
                nextState <= T0;
                
            when T0 =>
                if decIns.instruction = BRK then  -- BRK instruction
                    nextState <= BREAK;    
                else
                    nextState <= T1;
                end if;
                
            when T1 =>  
                if (decIns.instruction=CLC or decIns.instruction=CLD or decIns.instruction=CLI or decIns.instruction=CLV or decIns.instruction=SECi or decIns.instruction=SED or decIns.instruction=SEI) then
                    nextState <= T0;
                else
                    nextState <= T2;
                end if;
                
            when T2 =>
                if (decIns.addressMode=IMM) then
                    nextState <= T0;
                else
                    nextState <= T3;
                end if;
                
            when T3 =>
                if (decIns.addressMode=ZPG) then
                    nextState <= T0;
                else
                    nextState <= T4;
                end if; 
                
            when T4 => 
                if (decIns.addressMode=AABS) then
                    nextState <= T0;
                else
                    nextState <= T5;
                end if;
            
            when T5 =>
            
                nextState <= T0;

            when BREAK =>
                nextState <= BREAK;
            
            when others =>
                nextState <= T0;
                
        end case;
    end process;
    
    --------------------------
    -- Instruction register --
    --------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            IR <= (others=>'0');
            
        elsif rising_edge(clk) then
            if currentState = T0 then
                IR <= instruction;
            end if;
        end if;
    end process;
    
    ----------------------------------------
    -- FSM output combinational logic --
    ----------------------------------------
    process(decIns,currentState)
    begin
        -- Default Values
        uins <= ('0','0','0','0','0','0','0','0','0','0','0','0',"00","00","00",'0','0',"000","000","00","00","000",x"00",x"00",x"00",'0','0');
        
        if currentState = IDLE then
            uins.rstP(CARRY)     <= '1';
            uins.rstP(ZERO)      <= '1';
            uins.rstP(INTERRUPT) <= '1';
            uins.rstP(DECIMAL)   <= '1';
            uins.rstP(BREAKF)    <= '1';
            uins.rstP(OVERFLOW)  <= '1';
            uins.rstP(NEGATIVE)  <= '1';
            uins.rstP(5)         <= '1';
                                    
    -- Fetch
    -- T0: MAR <- PC; IR <- MEM[MAR]; PC++; (all instructions)
    -- Decode:
    -- T1: MAR <- PC; PC++; (all instructions except one byte ones)
        elsif currentState = T0 or (currentState = T1 and decIns.size > 1) then  
            -- MAR <- PC
            uins.mux_mar <= "00";  
            uins.wrMAR   <= '1';    -- MAR <- PCH_q & PCL_q

            -- PC++
            uins.mux_pc <= '0';
            uins.wrPCH  <= '1';
            uins.wrPCL  <= '1';
            
            -- Enable Memory Read Mode
            uins.ce <= '1';
            uins.rw <= '1';
            
            -- Decode steps for Absolute addressing mode -> se address mudar junto com pc
            --if (decIns.addressMode = AABS and currentState = T1) then
            --  uins.mux_db <= "100";  -- DB <- MEM[MAR]
            --  uins.mux_adl <= "10";  
            --  uins.wrABL <= '1';     -- ABL <- DB
            --elsif (currentState = T2) then
            --  uins.mux_db <= "100";  -- DB <- MEM[MAR]
            --  uins.mux_adh <= "00";  
            --  uins.wrABH <= '1';     -- ABH <- DB
            --  uins.mux_mar <= "01";  -- MAR <- [ABH/ABL]
            --end if;
            
    -- T1: MAR <- PC; P(i) <- 1 for sets, 0 for rst (One byte instructions)    
        -- Clear carry flag
        elsif decIns.instruction=CLC and currentState=T1 then
            uins.rstP(CARRY) <= '1';
            uins.wrMAR <= '1'; 
           
        -- Set carry flag
        elsif decIns.instruction=SECi and currentState=T1 then
            uins.setP(CARRY) <= '1';
            uins.wrMAR <= '1';
            
        -- Clear decimal flag
        elsif decIns.instruction=CLD and currentState=T1 then
            uins.rstP(DECIMAL) <= '1';
            uins.wrMAR <= '1';
            
        -- Set decimal flag
        elsif decIns.instruction=SED and currentState=T1 then
            uins.setP(DECIMAL) <= '1';
            uins.wrMAR <= '1';            
        
        -- Clear interrupt flag
        elsif decIns.instruction=CLI and currentState=T1 then
            uins.rstP(INTERRUPT) <= '1';
            uins.wrMAR <= '1';
            
        -- Set interrupt flag
        elsif decIns.instruction=SEI and currentState=T1 then
            uins.setP(INTERRUPT) <= '1';
            uins.wrMAR <= '1';
            
        -- Clear overflow flag
        elsif decIns.instruction=CLV and currentState=T1 then
            uins.rstP(OVERFLOW) <= '1';
            uins.wrMAR <= '1';
                    
    -- T2 or T3: AC <- MEM[MAR]; wrn, wrz   - Execute step for Immediate (T2) and ZPG (T3) addressing mode
        elsif ((currentState = T2 and decIns.addressMode = IMM) or (currentState = T3 and decIns.addressMode = ZPG)) then
            if (decIns.instruction = LDA or decIns.instruction = LDX or decIns.instruction = LDY) then
                uins.ce <= '1';
                uins.rw <= '1';        -- Enable Read Mode
                uins.mux_db <= "100";  -- DB <- MEM[MAR] 
                uins.mux_sb <= "110";  -- SB <- DB
                uins.wrAC <= '1';      -- AC <- SB
            else -- STA, STX and STY
                uins.mux_db <= "000";  -- DB <- AC
                uins.ce <= '1';
                uins.rw <= '0';        -- Enable Write Mode : MEM[MAR] <- AC
            end if;
            
            uins.wrMAR <= '1'; 
                    
    -- T2: MAR <- MEM[MAR];     - Decode step for Zero Page addressing mode
        elsif (currentState = T2 and decIns.addressMode=ZPG)  then
            uins.ce <= '1';
            uins.rw <= '1';        -- Enable Read Mode
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.mux_mar <= "10";   
            uins.wrMAR <= '1';     -- MAR <- DB
                    
        -- working till here

        else
        end if;
                
    end process;
   

end ControlPath;