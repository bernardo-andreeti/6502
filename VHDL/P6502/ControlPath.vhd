--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Control path                                                      --
-- DESCRIPTION  : 6502 Control Logic                                                --     
-- AUTHOR       : Everton Alceu Carara and Bernardo Favero Andreeti                 --
-- CREATED      : Feb, 2015                                                         --
-- VERSION      : 0.7                                                               --
-- HISTORY      : Version 0.1 - Feb, 2015 - Everton Alceu Carara                    --
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

    
    opcode <= instruction when currentState = T1 else IR;          
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
                    nextState <= T1;
                    
            when T1 =>  
                if (decIns.instruction=CLC or decIns.instruction=CLD or decIns.instruction=CLI or decIns.instruction=CLV or decIns.instruction=SECi or decIns.instruction=SED or decIns.instruction=SEI) then
                    nextState <= T0;
                
                elsif decIns.instruction=BRK then  
                    nextState <= BREAK;
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
                if (decIns.addressMode=AABS or decIns.addressMode=ZPG_XY) then
                    nextState <= T0;
                else
                    nextState <= T5;
                end if;
            
            when T5 =>
            if (decIns.addressMode=IND_X or decIns.addressMode=IND_Y or decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y) then
                    nextState <= T0;
            else
                    nextState <= T6;
            end if;
            
            when T6 =>
            
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
            if currentState = T1 then
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
        uins <= ('0','0','0','0','0','0','0','0','0','0','0','0','0',"00","00","00",'0','0',"000","000","00","00","000",x"00",x"00",x"00",'0','0');
        
        if currentState = IDLE then
            uins.rstP(CARRY)     <= '1';
            uins.rstP(ZERO)      <= '1';
            uins.rstP(INTERRUPT) <= '1';
            uins.rstP(DECIMAL)   <= '1';
            uins.rstP(BREAKF)    <= '1';
            uins.rstP(OVERFLOW)  <= '1';
            uins.rstP(NEGATIVE)  <= '1';
            uins.rstP(5)         <= '1';
                                    
    -- FETCH
    -- T0: MAR <- PC; PC++; (all instructions)
    -- DECODE
    -- T1: MAR <- PC; IR <- MEM[MAR]; PC++; (all instructions except one byte ones)
        elsif currentState = T0 or (currentState = T1 and decIns.size > 1) or (currentState = T2 and decIns.size > 2) then  
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
        
        -- DECODE (absolute)    
            if (currentState = T2 and decIns.addressMode = AABS) then
                uins.mux_db <= "100";   -- DB <- MEM[MAR]
                uins.mux_adl <= "10";
                uins.wrABL <= '1';      -- ABL <- DB
            end if;
            
        -- DECODE (ABS_X and ABS_Y)
            -- T2: BI <- MEM[MAR]; AI <- X/Y; MAR <- PC; PC++;
            if (currentState = T2 and (decIns.addressMode = ABS_X or decIns.addressMode = ABS_Y)) then  
                uins.mux_db <= "100";  -- DB <- MEM[MAR]
                uins.wrBI <= '1';      -- BI <- DB
                if (decIns.addressMode = ABS_X) then  
                    uins.mux_sb <= "011";  -- SB <- X
                else -- ABS_Y
                    uins.mux_sb <= "100";  -- SB <- Y
                end if;
                uins.mux_ai <= "10";   
                uins.wrAI <= '1';          -- AI <- SB  
            end if;    
        
    -- DECODE (ZPG, IND_X and IND_Y)
    -- T2 or T4: MAR <- MEM[MAR];    
        elsif ((currentState = T2 and (decIns.addressMode=ZPG or decIns.addressMode = IND_Y)) or (currentState = T4 and decIns.addressMode = IND_X)) then
            uins.ce <= '1';
            uins.rw <= '1';        -- Enable Read Mode
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.mux_mar <= "01";   
            uins.wrMAR <= '1';     -- MAR <- DB
                        
    -- DECODE (ZPG_XY, IND_X, IND_Y)
    -- T2 or T3: BI <- MEM[MAR]; AI <- X/Y         
        elsif ((currentState = T2 and (decIns.addressMode=ZPG_XY or decIns.addressMode=IND_X)) or (currentState = T3 and decIns.addressMode=IND_Y)) then
            uins.ce <= '1';
            uins.rw <= '1';        -- Enable Read Mode
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.wrBI <= '1';      -- BI <- DB
            if (decIns.instruction = LDA or decIns.instruction = LDY or decIns.instruction = STA or decIns.instruction = STY or decIns.addressMode = IND_X) then  
                uins.mux_sb <= "011";  -- SB <- X
            else
                uins.mux_sb <= "100";  -- SB <- Y
            end if;
            uins.mux_ai <= "10";   
            uins.wrAI <= '1';      -- AI <- SB
            
    -- DECODE (second step for ZPG_XY, IND_X, IND_Y, ABS_X, ABS_Y)
    -- T3 or T4: ABL <- AI + BI; T3(ABS_XY) ABL <- AI + BI; BI <- MEM[MAR]; AI <- 0;         
        elsif ((currentState = T3 and (decIns.addressMode=ZPG_XY or decIns.addressMode=IND_X or decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or (currentState = T4 and decIns.addressMode=IND_Y)) then
            uins.ALUoperation <= "110";
            uins.wrABL <= '1';         -- ABL <- AI + BI 
            if (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y) then
                uins.ce <= '1';
                uins.rw <= '1';        -- Enable Read Mode
                uins.mux_db <= "100";  -- DB <- MEM[MAR]
                uins.wrBI <= '1';      -- BI <- DB
                uins.mux_ai <= "01";   
                uins.wrAI <= '1';      -- AI <- x"00"
            else
                uins.mux_adh <= "10";
                uins.wrABH <= '1';       -- ABH <- x"00"
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;
            
    -- DECODE (second step)    
    -- T3: ABH <- MEM[MAR];     - Second decode step for Absolute addressing mode
        elsif (currentState = T3 and decIns.addressMode=AABS) then
            uins.ce <= '1';
            uins.rw <= '1';         -- Enable Read Mode
            uins.mux_db <= "100";   -- DB <- MEM[MAR]
            uins.mux_adh <= "00";
            uins.wrABH <= '1';      -- ABH <- DB
            uins.mux_address <= '1';-- address <- ABH & ABL 

    -- DECODE (third step for ABS_X and ABS_Y)    
    -- T4: ABH <- AI + BI + hc;
        elsif (currentState = T4 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) then 
            uins.mux_carry <= "11";     -- carry <- hc
            uins.ALUoperation <= "101"; -- AI + BI + carry
            uins.mux_sb <= "001";
            uins.mux_adh <= "01";
            uins.wrABH <= '1';          -- ABH <- ALUresult
            uins.mux_address <= '1';    -- address <- ABH & ABL
            
    -- EXECUTE
        -- Load and Store Group (all addressing modes)
        elsif ((currentState = T2 and decIns.addressMode = IMM) or (currentState = T3 and decIns.addressMode = ZPG) or (currentState = T4 and (decIns.addressMode = AABS or decIns.addressMode = ZPG_XY)) or (currentState = T5 and (decIns.addressMode = IND_X or decIns.addressMode = IND_Y or decIns.addressMode = ABS_X or decIns.addressMode = ABS_Y))) then
            if (decIns.instruction = LDA or decIns.instruction = LDX or decIns.instruction = LDY) then
                uins.ce <= '1';
                uins.rw <= '1';        -- Enable Read Mode
                uins.mux_db <= "100";  -- DB <- MEM[MAR] 
                uins.mux_sb <= "110";  -- SB <- DB
                if decIns.instruction = LDA then
                    uins.wrAC <= '1';  -- AC <- SB
                elsif decIns.instruction = LDX then
                    uins.wrX <= '1';   -- X <- SB
                else  -- LDY
                    uins.wrY <= '1';   -- Y <- SB
                end if;
                uins.ceP(NEGATIVE) <= '1';
                uins.ceP(ZERO)     <= '1';
            else -- STA, STX and STY
                if decIns.instruction = STA then
                    uins.mux_db <= "000";  -- DB <- AC
                elsif decIns.instruction = STX then 
                    uins.mux_sb <= "011";  -- SB <- X
                    uins.mux_db <= "001";  -- DB <- SB
                else  -- STY    
                    uins.mux_sb <= "100";  -- SB <- Y
                    uins.mux_db <= "001";  -- DB <- SB
                 end if;   
                uins.ce <= '1';
                uins.rw <= '0';        -- Enable Write Mode : MEM[MAR] <- AC || X || Y
            end if;
            if (decIns.addressMode=AABS or decIns.addressMode=ZPG_XY or decIns.addressMode=IND_Y or decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y) then 
                uins.mux_address <= '1';    -- address <- ABH & ABL
            end if;    
                        
    -- EXECUTE (one byte instructions)
    -- T1: IR <- MEM[MAR]; P(i) <- 1 for sets, 0 for rst (One byte instructions)    
        -- Clear carry flag
        elsif decIns.instruction=CLC and currentState=T1 then
            uins.rstP(CARRY) <= '1';
           
        -- Set carry flag
        elsif decIns.instruction=SECi and currentState=T1 then
            uins.setP(CARRY) <= '1';
            
        -- Clear decimal flag
        elsif decIns.instruction=CLD and currentState=T1 then
            uins.rstP(DECIMAL) <= '1';
            
        -- Set decimal flag
        elsif decIns.instruction=SED and currentState=T1 then
            uins.setP(DECIMAL) <= '1';           
        
        -- Clear interrupt flag
        elsif decIns.instruction=CLI and currentState=T1 then
            uins.rstP(INTERRUPT) <= '1';
            
        -- Set interrupt flag
        elsif decIns.instruction=SEI and currentState=T1 then
            uins.setP(INTERRUPT) <= '1';
            
        -- Clear overflow flag
        elsif decIns.instruction=CLV and currentState=T1 then
            uins.rstP(OVERFLOW) <= '1';            

        else
        end if;
                
    end process;
   
end ControlPath;