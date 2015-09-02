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
        spr_in      : in std_logic_vector(7 downto 0); -- Status Processor Register    
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
                if (decIns.InsGroup = STATUS_FLAG) or (decIns.instruction=BEQ and spr_in(ZERO)='0') then 
                    nextState <= T0;
                
                elsif decIns.instruction=BRK then  
                    nextState <= BREAK;
                else
                    nextState <= T2;
                end if;
                
            when T2 =>
                if (decIns.addressMode=IMM and decIns.InsGroup=LOAD_STORE) then 
                    nextState <= T0;
                else
                    nextState <= T3;
                end if;
                
            when T3 =>
                if (decIns.addressMode=ZPG and decIns.InsGroup=LOAD_STORE) or (decIns.addressMode=IMM and decIns.InsGroup=LOGICAL)  or (decIns.addressMode=AABS and decIns.InsGroup=JUMP_BRANCH) or decIns.addressMode=ACC then
                    nextState <= T0;
                else
                    nextState <= T4;
                end if; 
                
            when T4 => 
                if ((decIns.addressMode=AABS or decIns.addressMode=ZPG_X or decIns.addressMode=ZPG_Y) and decIns.InsGroup=LOAD_STORE) or (decIns.addressMode=ZPG and (decIns.InsGroup=LOGICAL or decIns.InsGroup=INC_DEC or decIns.InsGroup=SHIFT_ROTATE)) or decIns.addressMode=REL then
                    nextState <= T0;
                else
                    nextState <= T5;
                end if;
            
            when T5 =>
                if (decIns.addressMode=IND and decIns.InsGroup=JUMP_BRANCH) or ((decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y) and decIns.InsGroup=LOAD_STORE) or ((decIns.addressMode=ZPG_X or decIns.addressMode=AABS) and (decIns.InsGroup=LOGICAL or decIns.InsGroup=COMPARE or decIns.InsGroup=INC_DEC or decIns.InsGroup=SHIFT_ROTATE)) then
                        nextState <= T0;
                else
                        nextState <= T6;
                end if;
            
            when T6 =>
                if ((decIns.addressMode=IMP or decIns.addressMode=AABS) and decIns.InsGroup=SUBROUTINE_INTERRUPT) or ((decIns.addressMode=IND_X or decIns.addressMode=IND_Y) and decIns.InsGroup=LOAD_STORE) or ((decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y) and (decIns.InsGroup=LOGICAL or decIns.InsGroup=INC_DEC or decIns.InsGroup=SHIFT_ROTATE))  then
                        nextState <= T0;
                else
                        nextState <= T7;
                end if;
            
            when T7 =>
                -- if ((decIns.addressMode=IND_X or decIns.addressMode=IND_Y) and decIns.InsGroup=LOGICAL) then
                    nextState <= T0;
                    
                -- end if;
                
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
        uins <= ('0','0','0','0','0','0','0','0','0','0','0','0',"00","00","00","00",'0','0',"000","000","00","00",ALU_NOP,x"00",x"00",x"00",'0','0');
        
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
            if currentState = T2 and (decIns.addressMode = AABS or decIns.addressMode = IND) then
                uins.mux_db <= "100";   -- DB <- MEM[MAR]
                if (decIns.instruction=JMP or decIns.instruction=JSR) and decIns.addressMode = AABS then
                    uins.wrBI <= '1';                       -- BI <- DB
                    uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
                    if decIns.instruction=JSR then 
                        uins.mux_adl <= "01"; uins.wrABL <= '1'; -- ABL <- S 
                        uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
                        uins.mux_s <= '0'; uins.wrS <= '1'; -- S <- S - 1                      
                    end if;
                else
                    uins.mux_adl <= "10";
                    uins.wrABL <= '1';      -- ABL <- DB
                end if;
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
        -- Flag update delayed for Shift and Rotate Group        
            if currentState = T0 and decIns.InsGroup = SHIFT_ROTATE then
                if decIns.instruction=ASL then
                    uins.ALUoperation <= ALU_ASL;
                elsif decIns.instruction=LSR then
                    uins.ALUoperation <= ALU_LSR;
                elsif decIns.instruction=ROLL then
                    uins.ALUoperation <= ALU_ROL;
                else
                    uins.ALUoperation <= ALU_ROR;    
                end if;
            uins.mux_sb <= "001"; uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1'; uins.ceP(CARRY) <= '1';end if;
            
    -- DECODE (Logical and Compare Group)
    -- T2 or T3 or T4 or T5 or T6: BI <- MEM[MAR or ABH/ABL]; AI <- AC     
        elsif (((currentState=T2 and (decIns.addressMode=IMM or decIns.addressMode=REL)) or (currentState=T3 and decIns.addressMode=ZPG) or (currentState=T4 and (decIns.addressMode=ZPG_X or decIns.addressMode=AABS)) or (currentState=T5 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or (currentState=T6 and (decIns.addressMode=IND_X or decIns.addressMode=IND_Y))) and (decIns.InsGroup=LOGICAL or decIns.InsGroup=COMPARE or decIns.InsGroup=JUMP_BRANCH)) then
            uins.ce <= '1';
            uins.rw <= '1';        -- Enable Read Mode
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            if decIns.InsGroup=COMPARE then
                uins.mux_bi <= "01"; -- BI <- !MEM[MAR] for compare instructions
            end if;
            uins.wrBI <= '1';      -- BI <- DB
            if decIns.InsGroup=JUMP_BRANCH then
                uins.mux_adl <= "11"; 
                uins.mux_ai <= "00";  -- AI <- PCL
            else
                uins.mux_sb <= "101";  -- SB <- AC
                uins.mux_ai <= "10";   
            end if;
            uins.wrAI <= '1';      -- AI <- SB
            if (decIns.addressMode=ZPG or decIns.addressMode=IMM or decIns.addressMode=REL) then 
                uins.mux_address <= '0'; -- address <- MAR
            else
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;
         
    -- DECODE (ZPG and IND_Y)
    -- T2: MAR <- MEM[MAR];    BI <- MEM[MAR]; AI <- 0 (for IND_Y)
        elsif (currentState = T2 and (decIns.addressMode=ZPG or decIns.addressMode = IND_Y)) then
            uins.ce <= '1';
            uins.rw <= '1';        -- Enable Read Mode
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.mux_mar <= "01";   
            uins.wrMAR <= '1';     -- MAR <- DB
            if decIns.addressMode=IND_Y then
                uins.wrBI <= '1';                       -- BI <- DB
                uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
            end if;
                        
    -- DECODE (ZPG_X, ZPG_Y, IND_X)
    -- T2: BI <- MEM[MAR]; AI <- X/Y         
        elsif (currentState = T2 and (decIns.addressMode=ZPG_X or decIns.addressMode=ZPG_Y or decIns.addressMode=IND_X)) then
            uins.ce <= '1';
            uins.rw <= '1';        -- Enable Read Mode
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.wrBI <= '1';      -- BI <- DB
            if (decIns.addressMode=ZPG_X or decIns.addressMode=IND_X) then
                uins.mux_sb <= "011";  -- SB <- X
            else -- ZPG_Y 
                uins.mux_sb <= "100";  -- SB <- Y
            end if;
            uins.mux_ai <= "10";   
            uins.wrAI <= '1';      -- AI <- SB
            
    -- DECODE (ZPG_X, ZPG_Y IND_X, IND_Y, ABS_X, ABS_Y)
    --  ABL <- AI + BI; ADH <- 0 or ABL <- AI + BI; BI <- MEM[MAR]; AI <- 0        
        elsif (currentState = T3 and (decIns.addressMode=ZPG_X or decIns.addressMode=ZPG_Y or decIns.addressMode=IND_X or decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or (currentState = T4 and (decIns.addressMode=IND_Y or decIns.addressMode=IND)) then
            if decIns.addressMode=IND then
                uins.ALUoperation <= ALU_ADC; -- AI + BI + 1
            else
                uins.ALUoperation <= ALU_ADD;
            end if;
            uins.wrABL <= '1';         -- ABL <- AI + BI or AI + BI + 1 for IND
            if (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y or decIns.addressMode=IND_Y or decIns.addressMode=IND) then
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
        
    -- DECODE (Accumulator and Implied addressing mode): BI <- AC; AI <- 0
        elsif currentState = T2 and (decIns.addressMode=ACC or decIns.addressMode=IMP) then
            if decIns.addressMode = IMP then
                uins.mux_bi <= "10"; -- BI <- SB
                uins.mux_ai <= "01"; uins.wrAI <= '1'; -- AI <- x"00"
            end if;    
            uins.wrBI <= '1'; -- BI <- AC or S
    
    -- DECODE (Implied addressing mode): ABL <- AI + BI + 1; ABH <- 1; S <- AI + BI + 1
        elsif (currentState = T3 or currentState = T5) and decIns.addressMode=IMP then
            uins.ALUoperation <= ALU_ADC; uins.wrABL <= '1';
            uins.mux_sb <= "001"; uins.mux_s <= '1'; uins.wrS <= '1';
            uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
            uins.mux_address <= '1';
    
    -- DECODE (second step) T3: ABH <- MEM[MAR]; or PCL <- AI + BI; PCH <- MEM[MAR]; (JUMP AABS)
        elsif currentState = T3 and (decIns.addressMode=AABS or decIns.addressMode=IND) then
            if decIns.instruction=JMP and decIns.addressMode=AABS then
                uins.ALUoperation <= ALU_ADD;
                uins.mux_pc <= '1';                      -- PC <- ADH & ADL
                uins.mux_adl <= "00"; uins.wrPCL <= '1'; -- PCL <- AI + BI
                uins.mux_db <= "100";                    -- DB <- MEM[MAR]
                uins.mux_adh <= "00"; uins.wrPCH <= '1'; -- PCH <- MEM[MAR]
            elsif decIns.instruction=JSR then
                uins.ce <= '1'; uins.rw <= '0';          -- Write Mode
                uins.mux_address <= '1';                 -- address <- ABH & ABL
                uins.mux_db <= "011";                    -- MEM[ABH/ABL] <- PCH
            else
                uins.ce <= '1'; uins.rw <= '1';         -- Enable Read Mode
                uins.mux_db <= "100";                   -- DB <- MEM[MAR]
                uins.mux_adh <= "00"; uins.wrABH <= '1';-- ABH <- DB
                uins.mux_address <= '1';                -- address <- ABH & ABL
            end if;
            
    -- DECODE(Branch):
        elsif (currentState=T3 and decIns.addressMode=REL) then
            uins.ALUoperation <= ALU_ADD;
            uins.mux_pc <= '1';                      -- PC <- ADH & ADL
            uins.mux_adl <= "00"; uins.wrPCL <= '1'; -- PCL <- AI + BI
            uins.mux_ai <= "01"; uins.wrAI <= '1';   -- AI <- x"00"
            uins.mux_db <= "011"; uins.wrBI <= '1';  -- BI <- PCH
    
    -- DECODE (JSR): ADL <- S; ADH <- 1; S--;        
        elsif (currentState=T4 and decIns.addressMode=AABS and decIns.InsGroup=SUBROUTINE_INTERRUPT) then
            uins.mux_adl <= "01"; uins.wrABL <= '1'; -- ABL <- S 
            uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
            uins.mux_s <= '0'; uins.wrS <= '1';      -- S <- S - 1
            uins.mux_db <= "010";                      -- MEM[ABH/ABL] <- PCL
            uins.mux_address <= '1';                 -- address <- ABH & ABL
            
    -- DECODE (JSR) MEM[ABH/ABL] <- PCL; MAR <- PC; PCL <- BI
        elsif (currentState = T5 and decIns.addressMode = AABS and decIns.InsGroup = SUBROUTINE_INTERRUPT) then
            uins.ce <= '1'; uins.rw <= '0';            -- Write Mode
            uins.mux_address <= '1';                   -- address <- ABH & ABL
            uins.mux_db <= "010";                      -- MEM[ABH/ABL] <- PCL
            uins.mux_mar <= "00"; uins.wrMAR   <= '1'; -- MAR <- PCH_q & PCL_q
    
    -- DECODE (Implied addressing mode): PCL <- MEM[ABH/ABL]; BI <- S; AI <- 0    
        elsif (currentState= T4 and decIns.addressMode= IMP and decIns.InsGroup= SUBROUTINE_INTERRUPT) then
            uins.mux_db <= "100"; uins.mux_adl <= "10"; uins.mux_pc <= '1'; uins.wrPCL <= '1';
            uins.mux_bi <= "10"; uins.wrBI <= '1'; -- BI <- S (over SB)
            uins.mux_ai <= "01"; uins.wrAI <= '1'; -- AI <- x"00"
            uins.mux_address <= '1';
            
    -- Last cycle for JSR and RTS: PCH <- MEM[MAR or ABH/ABL]
        elsif currentState = T6 and decIns.InsGroup = SUBROUTINE_INTERRUPT then
            uins.ce <= '1'; uins.rw <= '1';         -- Enable Read Mode
            uins.mux_db <= "100"; uins.mux_pc <= '1';
            if decIns.addressMode=IMP then
                uins.mux_adh <= "00"; uins.wrPCH <= '1'; -- PCH <- MEM[MAR]
                uins.mux_address <= '1';
            else
                uins.mux_pc <= '1';                        -- PC <- ADH & ADL
                uins.ALUoperation <= ALU_B;
                uins.mux_adl <= "00"; uins.wrPCL <= '1';   -- PCL <- BI
            end if;
    
    -- DECODE (third step for INC and DEC, Shift and Rotate); BI <- MEM[AB]; AI <- 0    
        elsif ((currentState = T4 and (decIns.addressMode=AABS or decIns.addressMode=ZPG_X)) or (currentState=T5 and decIns.addressMode=ABS_X) or (currentState=T3 and decIns.addressMode=ZPG)) and (decIns.InsGroup=INC_DEC  or decIns.InsGroup=SHIFT_ROTATE) then        
            uins.ce <= '1'; uins.rw <= '1'; -- Enable Read Mode
            uins.mux_db <= "100"; uins.wrBI <= '1'; -- BI <- MEM[MAR]
            uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
            if decIns.addressMode=ZPG then 
                uins.mux_address <= '0'; -- address <- MAR
            else
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;   

    -- DECODE (ABS_X, ABS_Y IND_Y), Last Cycle for REL: T4 or T5: ABH (PCH for REL) <- AI + BI + hc;
        elsif ((currentState = T4 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y or decIns.addressMode=REL)) or (currentState = T5 and decIns.addressMode=IND_Y)) then 
            uins.mux_carry <= "11";     -- carry <- hc
            uins.ALUoperation <= ALU_ADC; -- AI + BI + carry
            uins.mux_sb <= "001";
            uins.mux_adh <= "01";
            if decIns.addressMode=REL then
                uins.mux_pc <= '1';
                uins.wrPCH <= '1';
            else
                uins.wrABH <= '1';          -- ABH <- ALUresult
                uins.mux_address <= '1';    -- address <- ABH & ABL
            end if;
            
    -- DECODE (IND_X and IND_Y) 
    -- T3 or T4: ABL <- AI + BI + 1; BI <- MEM[ABH/ABL]; AI <- 0;   
        elsif ((currentState = T4 and decIns.addressMode=IND_X) or (currentState=T3 and decIns.addressMode=IND_Y)) then
            uins.mux_carry <= "00";     -- carry <- '1'
            uins.ALUoperation <= ALU_ADC;            
            uins.ce <= '1';
            uins.rw <= '1';             -- Enable Read Mode
            uins.mux_db <= "100";       -- DB <- MEM[ABH/ABL]
            uins.wrBI <= '1';           -- BI <- DB
            if decIns.addressMode=IND_X then
                uins.mux_adh <= "10"; uins.wrABH <= '1'; -- ABH <- x"00"
                uins.wrABL <= '1';          -- ABL <- AI + BI + 1
                uins.mux_ai <= "01"; uins.wrAI <= '1';   -- AI <- x"00"
                uins.mux_address <= '1';    -- address <- ABH & ABL
            else  -- IND_Y
                uins.mux_mar <= "11";       -- MAR <- AI + BI + 1
                uins.wrMAR <= '1';
                uins.mux_sb <= "100";  -- SB <- Y
                uins.mux_ai <= "10";   
                uins.wrAI <= '1';      -- AI <- SB
            end if;
            
    -- DECODE (IND_X and IND_Y) 
    -- T4 or T5: ABL <- AI + BI; ABH <- MEM[ABH/ABL] 
        elsif ((currentState = T4 and decIns.addressMode=IND_Y) or (currentState = T5 and decIns.addressMode=IND_X)) then
            uins.ALUoperation <= ALU_ADD;
            uins.wrABL <= '1';           -- ABL <- AI + BI
            uins.mux_db <= "100";        -- DB <- MEM[MAR]
            if decIns.addressMode=IND_X then
                uins.wrABH <= '1';       -- ABH <- MEM[ABH/ABL]
                uins.mux_address <= '1'; -- address <- ABH & ABL
            else -- IND_Y
                uins.wrBI <= '1';        -- BI <- MEM[MAR]
                uins.mux_ai <= "01";   
                uins.wrAI <= '1';        -- AI <- x"00"
            end if;
                        
    -- EXECUTE: Load and Store Group (all addressing modes)
        elsif (decIns.InsGroup=LOAD_STORE) then
            if ((currentState = T2 and decIns.addressMode = IMM) or (currentState = T3 and decIns.addressMode = ZPG) or (currentState = T4 and (decIns.addressMode = AABS or decIns.addressMode = ZPG_X or decIns.addressMode=ZPG_Y)) or (currentState = T5 and (decIns.addressMode = ABS_X or decIns.addressMode = ABS_Y)) or (currentState=T6 and (decIns.addressMode = IND_X or decIns.addressMode = IND_Y))) then
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
                if (decIns.addressMode=ZPG or decIns.addressMode=IMM) then 
                    uins.mux_address <= '0'; -- address <- MAR
                else
                    uins.mux_address <= '1'; -- address <- ABH & ABL
                end if;
            end if;
            
    -- EXECUTE: Logical Group (all addressing modes)
        elsif (decIns.InsGroup=LOGICAL) then
            if ((currentState=T3 and decIns.addressMode=IMM) or (currentState=T4 and decIns.addressMode=ZPG) or (currentState=T5 and (decIns.addressMode=ZPG_X or decIns.addressMode=AABS)) or (currentState=T6 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or (currentState=T7 and (decIns.addressMode=IND_X or decIns.addressMode=IND_Y))) then
                uins.mux_sb <= "001";   -- SB <- ALUresult
                uins.wrAC <= '1';          -- AC <- SB  
                uins.ceP(NEGATIVE) <= '1';
                uins.ceP(ZERO)     <= '1';
                if decIns.instruction = AAND then
                    uins.ALUoperation <= ALU_AND; -- AI & BI
                elsif decIns.instruction = ORA then
                    uins.ALUoperation <= ALU_OR;  -- AI | BI
                else  -- EOR
                    uins.ALUoperation <= ALU_XOR; -- AI ^ BI 
                end if; 
            end if;            
                        
    -- EXECUTE: one byte instructions
    -- T1: IR <- MEM[MAR]; P(i) <- 1 for sets, 0 for rst (One byte instructions)
        elsif (decIns.InsGroup=STATUS_FLAG and currentState=T1) then 
            if decIns.instruction=CLC then
                uins.rstP(CARRY) <= '1'; -- Clear carry flag
            elsif decIns.instruction=SECi then
                uins.setP(CARRY) <= '1'; -- Set carry flag
            elsif decIns.instruction=CLD then
                uins.rstP(DECIMAL) <= '1'; -- Clear decimal flag
            elsif decIns.instruction=SED then
                uins.setP(DECIMAL) <= '1'; -- Set decimal flag 
            elsif decIns.instruction=CLI then
                uins.rstP(INTERRUPT) <= '1'; -- Clear interrupt flag
            elsif decIns.instruction=SEI then
                uins.setP(INTERRUPT) <= '1'; -- Set interrupt flag
            elsif decIns.instruction=CLV then
                uins.rstP(OVERFLOW) <= '1';  -- Clear overflow flag
            end if; 
            
    -- EXECUTE: Compare and Bit Test Group
        elsif (decIns.InsGroup=COMPARE) then
            if (currentState=T5 and decIns.addressMode=AABS) then
                uins.ALUoperation <= ALU_ADC; 
                uins.mux_sb <= "001";       -- SB <- AI + BI + 1
                uins.ceP(NEGATIVE) <= '1';
                uins.ceP(CARRY)    <= '1';
                uins.ceP(ZERO)     <= '1';
                
            end if;
            
    -- EXECUTE: Increment and Decrement Group
        elsif (decIns.InsGroup=JUMP_BRANCH) then
            if currentState = T5 and decIns.addressMode = IND then
                uins.ALUoperation <= ALU_B;
                uins.mux_pc <= '1';                      -- PC <- ADH & ADL
                uins.mux_adl <= "00"; uins.wrPCL <= '1'; -- PCL <- BI
                uins.mux_db <= "100";                    -- DB <- MEM[MAR]
                uins.mux_adh <= "00"; uins.wrPCH <= '1'; -- PCH <- MEM[ABH/ABL]
                uins.mux_address <= '1';                 -- address <- ABH & ABL
            end if;
        
    -- EXECUTE: Increment and Decrement Group
        elsif (decIns.InsGroup=INC_DEC) then
            if ((currentState=T4 and decIns.addressMode=ZPG) or (currentState=T5 and (decIns.addressMode=AABS or decIns.addressMode=ZPG_X)) or (currentState=T6 and decIns.addressMode=ABS_X)) then
                if decIns.instruction=INC then
                    uins.ALUoperation <= ALU_ADC;
                else
                    uins.ALUoperation <= ALU_DEC; -- DEC
                end if;
                uins.mux_sb <= "001"; uins.mux_db <= "001"; -- DB <- ALUresult
                uins.ce <= '1'; uins.rw <= '0';             -- Enable Write Mode 
                uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
                if decIns.addressMode=ZPG then 
                    uins.mux_address <= '0'; -- address <- MAR
                else
                    uins.mux_address <= '1'; -- address <- ABH & ABL
                end if;
                
            end if;
            
    -- EXECUTE: Shift and Rotate Group
        elsif (decIns.InsGroup=SHIFT_ROTATE) then
            if ((currentState=T3 and decIns.addressMode=ACC) or (currentState=T4 and decIns.addressMode=ZPG) or (currentState=T5 and (decIns.addressMode=AABS or decIns.addressMode=ZPG_X)) or (currentState=T6 and decIns.addressMode=ABS_X)) then
                uins.mux_carry <= "01";     -- carry <- P_q(CARRY)
                if decIns.instruction=ASL then
                    uins.ALUoperation <= ALU_ASL;
                elsif decIns.instruction=LSR then
                    uins.ALUoperation <= ALU_LSR;
                elsif decIns.instruction=ROLL then
                    uins.ALUoperation <= ALU_ROL;
                else
                    uins.ALUoperation <= ALU_ROR;    
                end if;
                uins.mux_sb <= "001";
                if decIns.addressMode=ACC then
                   uins.wrAC <= '1';
                else
                    uins.mux_db <= "001";           -- DB <- ALUresult
                    uins.ce <= '1'; uins.rw <= '0'; -- Enable Write Mode 
                    if decIns.addressMode=ZPG then 
                        uins.mux_address <= '0'; -- address <- MAR
                    else
                        uins.mux_address <= '1'; -- address <- ABH & ABL
                    end if;
                end if;
            end if;
        else
        end if;
                
    end process;
   
end ControlPath;