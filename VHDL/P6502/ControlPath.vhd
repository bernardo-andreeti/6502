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
        clk, rst, ready : in std_logic;
        nmi, nres, irq  : in std_logic;                 -- Interrupt lines (active low)
        spr_in      : in std_logic_vector(7 downto 0);  -- Status Processor Register    
        uins        : out microinstruction;             -- Control signals to data path
        we          : out std_logic;                    -- Memory control (we = 0: READ; we = 1: WRITE) 
        nOffset_in  : in std_logic;                     -- Negative Offset Signal
        instruction : in std_logic_vector(7 downto 0)   -- Current instruction 
       );
end ControlPath;
                   
architecture ControlPath of ControlPath is
    
    -- Instruction register
    signal IR: std_logic_vector(7 downto 0);
    signal currentState, nextState : State;
    
    -- Current instruction decoded
    signal decIns : DecodedInstruction_type;
    
    -- Internal signals
    signal rdy: std_logic;
    
    -- Interrupt Registers
    signal d_nmi, q_nmi: std_logic;
    signal d_nres, q_nres: std_logic;
    signal d_irq, q_irq: std_logic;
    
    -- Auxiliar Interrupt Registers 
    signal nmi_aux, nres_aux, irq_aux: std_logic;
        
begin 

    --------------------------
    -- Instruction register --
    --------------------------
    process(clk, rst, rdy, currentState)
    begin
        if rst = '1' then   
            IR <= x"EA";     -- NOP   
        elsif rising_edge(clk) and rdy = '1' and currentState = T0 then
            if (q_nmi = '1' or q_nres = '1' or (q_irq = '1' and spr_in(INTERRUPT) = '0')) then
                IR <= x"00"; -- Forced BRK to handle interruption
            else
                IR <= instruction;
            end if;    
        end if;
    end process;
    
    decIns <= InstructionDecoder(IR);
    
    ---------------------------
    -- NMI signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            q_nmi <= '0';
        elsif rising_edge(clk) then 
            q_nmi <= d_nmi;
        end if;
    end process;
    
    ---------------------------
    -- NRES signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            q_nres <= '0';
        elsif rising_edge(clk) then 
            q_nres <= d_nres;
        end if;
    end process;
    
    ---------------------------
    -- IRQ signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            q_irq <= '0';
        elsif rising_edge(clk) then 
            q_irq <= d_irq;
        end if;
    end process;
    
    ---------------------------
    -- NMI_AUX signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            nmi_aux <= '1';
        elsif rising_edge(clk) then 
            nmi_aux <= nmi;
        end if;
    end process;
    
    ---------------------------
    -- NRES_AUX signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            nres_aux <= '1';
        elsif rising_edge(clk) then 
            nres_aux <= nres;
        end if;
    end process;
    
    ---------------------------
    -- IRQ_AUX signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            irq_aux <= '1';
        elsif rising_edge(clk) then 
            irq_aux <= irq;
        end if;
    end process;
    
    d_nmi <= '0' when q_nmi = '1' and currentState = T7 and decIns.instruction = BRK else 
             '1' when nmi = '0' and nmi_aux = '1' else
             q_nmi;		 
    d_nres <= '0' when q_nres = '1' and currentState = T7 and decIns.instruction = BRK else 
              '1' when nres = '0' and nres_aux = '1' else  
              q_nres;
    d_irq <= '0' when q_irq = '1' and currentState = T7 and decIns.instruction = BRK else 
             '1' when irq = '0' and irq_aux = '1' else  
              q_irq;          
	 
    ---------------------------
    -- Ready signal register --
    ---------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            rdy <= '0';
        elsif rising_edge(clk) then 
            rdy <= ready;
        end if;
    end process;   
        
    ------------------------
    -- FSM state register --
    ------------------------
    process(clk, rst, rdy)
    begin
        if rst = '1' then 
            currentState <= T0;  -- Resets state machine and keeps processor stuck at T0              
        elsif rising_edge(clk) and rdy = '1' then
            currentState <= nextState;
        end if;
    end process;
    
    ----------------------------------------
    -- FSM next state combinational logic --
    ----------------------------------------
    process(currentState, decIns, spr_in)  
    begin
        case currentState is              
            when T0 =>
                nextState <= T1;   
            when T1 =>  
                if decIns.InsGroup = STATUS_FLAG or decIns.InsGroup = REG_TRANSFER or 
                decIns.instruction = TXS or decIns.instruction = TSX or 
                (decIns.instruction=BEQ and spr_in(ZERO)='0') or 
                (decIns.instruction=BNE and spr_in(ZERO)='1') or 
                (decIns.instruction=BCS and spr_in(CARRY)='0') or 
                (decIns.instruction=BCC and spr_in(CARRY)='1') or 
                (decIns.instruction=BMI and spr_in(NEGATIVE)='0') or 
                (decIns.instruction=BPL and spr_in(NEGATIVE)='1') or 
                (decIns.instruction=BVS and spr_in(OVERFLOW)='0') or 
                (decIns.instruction=BVC and spr_in(OVERFLOW)='1') or 
                decIns.instruction=NOP then 
                    nextState <= T0;                                            
                else
                    nextState <= T2;
                end if;
            when T2 =>
                if (decIns.addressMode=IMM and decIns.InsGroup=LOAD_STORE) or 
                (decIns.addressMode=IMP and decIns.InsGroup=INC_DEC) or 
                decIns.addressMode=ACC or decIns.instruction=PHA or decIns.instruction=PHP then 
                    nextState <= T0;
                else
                    nextState <= T3;
                end if;
            when T3 =>
                if (decIns.addressMode=ZPG and decIns.InsGroup=LOAD_STORE) or 
                (decIns.addressMode=IMM and (decIns.InsGroup=LOGICAL or 
                decIns.InsGroup=ARITHMETIC or decIns.InsGroup=COMPARE)) or 
                (decIns.addressMode=AABS and decIns.InsGroup=JUMP_BRANCH) or 
                decIns.instruction=PLA or decIns.instruction=PLP then
                    nextState <= T0;
                else
                    nextState <= T4;
                end if; 
            when T4 => 
                if ((decIns.addressMode=AABS or decIns.addressMode=ZPG_X or 
                decIns.addressMode=ZPG_Y) and decIns.InsGroup=LOAD_STORE) or 
                (decIns.addressMode=ZPG and (decIns.InsGroup=LOGICAL or 
                decIns.InsGroup=INC_DEC or decIns.InsGroup=SHIFT_ROTATE or 
                decIns.InsGroup=ARITHMETIC or decIns.InsGroup=COMPARE)) or 
                decIns.addressMode=REL then
                    nextState <= T0;
                else
                    nextState <= T5;
                end if;
            when T5 =>
                if (decIns.addressMode=ZPG and decIns.InsGroup=BIT_TEST) or 
                (decIns.addressMode=IND and decIns.InsGroup=JUMP_BRANCH) or 
                ((decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y) and 
                decIns.InsGroup=LOAD_STORE) or ((decIns.addressMode=ZPG_X or 
                decIns.addressMode=AABS) and (decIns.InsGroup=LOGICAL or 
                decIns.InsGroup=COMPARE or decIns.InsGroup=INC_DEC or 
                decIns.InsGroup=SHIFT_ROTATE or decIns.InsGroup=ARITHMETIC)) then
                        nextState <= T0;
                else
                        nextState <= T6;
                end if;
            when T6 =>
                if (decIns.instruction=RTS) or (decIns.addressMode=AABS and 
                (decIns.InsGroup=SUBROUTINE_INTERRUPT or decIns.InsGroup=BIT_TEST)) or 
                ((decIns.addressMode=IND_X or decIns.addressMode=IND_Y) and 
                decIns.InsGroup=LOAD_STORE) or ((decIns.addressMode=ABS_X or 
                decIns.addressMode=ABS_Y) and (decIns.InsGroup=LOGICAL or 
                decIns.InsGroup=INC_DEC or decIns.InsGroup=SHIFT_ROTATE or 
                decIns.InsGroup=ARITHMETIC or decIns.InsGroup=COMPARE))  then
                        nextState <= T0;
                else
                        nextState <= T7;
                end if;
            when T7 =>
                    nextState <= T0;
            when others =>
                nextState <= T0;  
        end case;
    end process;
    
    ------------------------------------
    -- FSM output combinational logic --
    ----------------------------------------
    process(decIns, currentState, rst, rdy, q_nmi, q_irq, q_nres, spr_in, nOffset_in)
    begin
        -- Default Values
        uins <= ('0','0','0','0','0','0','0','0','0','0','0','0','0',"00","0000","00","00",'0','0','0',"000","000","00","00",ALU_NOP,x"00",x"00",x"00");
        we <= '0'; -- Memory Read Mode
        uins.ceP(UNUSED) <= '1';
        
        if rst = '1' then
            uins.rstP(CARRY)     <= '1';
            uins.rstP(ZERO)      <= '1';
            uins.rstP(INTERRUPT) <= '1';
            uins.rstP(DECIMAL)   <= '1';
            uins.rstP(BREAKF)    <= '1';
            uins.rstP(OVERFLOW)  <= '1';
            uins.rstP(NEGATIVE)  <= '1';
            uins.rstP(UNUSED)    <= '1';
            
        elsif rdy = '0' then -- Stall processor operation
            uins <= ('0','0','0','0','0','0','0','0','0','0','0','0','0',"00","0000","00","00",'0','0','0',"000","000","00","00",ALU_NOP,x"00",x"00",x"00");
            uins.ceP(UNUSED) <= '1';
            we <= '0'; 
                                    
    -- FETCH
    -- T0: MAR <- PC; PC++; (all instructions)
    -- DECODE
    -- T1: MAR <- PC; IR <- MEM[MAR]; PC++; (all instructions except one byte ones)
        elsif (currentState = T0 or (currentState = T1 and decIns.size > 1) or 
        (currentState = T2 and decIns.size > 2)) then  
            uins.mux_mar <= "0000";
            uins.wrMAR   <= '1';    -- MAR <- PCH_q & PCL_q
            
            if (currentState = T0 and 
            (q_nmi = '1' or q_nres = '1' or (q_irq = '1' and spr_in(INTERRUPT) = '0'))) or 
            (currentState = T2 and decIns.instruction = JSR) then
                uins.wrPCH <= '0'; uins.wrPCL <= '0';  -- Don't increment PC if handling an interruption, or state T2 of JSR
            else
                uins.wrPCH  <= '1'; uins.wrPCL  <= '1'; -- PC++
            end if;
            
        -- DECODE (Absolute and Indirect)    
            if currentState = T2 and decIns.addressMode = AABS and 
               decIns.instruction /= JSR and decIns.instruction /= JMP then
                uins.mux_db <= "100";   -- DB <- MEM[MAR]
                uins.mux_adl <= "10";
                uins.wrABL <= '1';      -- ABL <- DB
            end if;
                        
            if currentState = T2 and decIns.instruction = JMP then
                uins.mux_db <= "100";   -- DB <- MEM[MAR]
                uins.wrBI <= '1';                       -- BI <- DB
                uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
                if decIns.addressMode=IND then
                    uins.mux_adl <= "10"; uins.wrABL <= '1'; -- ABL <- DB
                end if;
            end if;

            if currentState = T2 and decIns.instruction = JSR then
                uins.mux_db <= "100";   -- DB <- MEM[MAR]
                uins.wrBI <= '1';                       -- BI <- DB
                uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
                uins.mux_adl <= "01"; uins.wrABL <= '1'; -- ABL <- S 
                uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
                uins.mux_s <= '0'; uins.wrS <= '1'; -- S <- S - 1
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
            
        -- Carry flag update delayed for Shift and Rotate Group        
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
                uins.mux_sb <= "001"; uins.ceP(CARRY) <= '1';
            end if;
         
    -- DECODE (Accumulator and Implied addressing mode): BI <- AC; AI <- 0
        elsif currentState = T1 and (decIns.addressMode=ACC or decIns.addressMode=IMP) and 
        (decIns.InsGroup=INC_DEC or decIns.InsGroup=SHIFT_ROTATE or 
        decIns.instruction=PLA or decIns.instruction=PLP or 
        decIns.instruction=RTS or decIns.instruction=RTI) then
            if decIns.addressMode=IMP then
                uins.mux_bi <= "10"; -- BI <- SB                
                if decIns.instruction=INX or decIns.instruction=DEX then
                    uins.mux_sb <= "011"; uins.mux_db <= "001";
                elsif decIns.instruction=INY or decIns.instruction=DEY then
                    uins.mux_sb <= "100"; uins.mux_db <= "001";
                end if;
                uins.mux_ai <= "01"; uins.wrAI <= '1'; -- AI <- x"00"  
            end if;    
            uins.wrBI <= '1'; -- BI <- AC or S        
        
    -- DECODE (PHA and PHP):
        elsif currentState = T1 and 
        (decIns.instruction=PHA or decIns.instruction=PHP or decIns.instruction=BRK) then
            uins.mux_adl <= "01"; uins.wrABL <= '1'; -- ABL <- S 
            uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
            uins.mux_s <= '0'; uins.wrS <= '1';      -- S <- S - 1
            uins.mux_address <= '1';   
                    
    -- DECODE (Logical and Compare Group)
    -- T2 or T3 or T4 or T5 or T6: BI <- MEM[MAR or ABH/ABL]; AI <- AC     
        elsif (((currentState=T2 and (decIns.addressMode=IMM or decIns.addressMode=REL)) or 
        (currentState=T3 and decIns.addressMode=ZPG) or 
        (currentState=T4 and (decIns.addressMode=ZPG_X or decIns.addressMode=AABS)) or 
        (currentState=T5 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or 
        (currentState=T6 and (decIns.addressMode=IND_X or decIns.addressMode=IND_Y))) and 
        (decIns.InsGroup=LOGICAL or decIns.InsGroup=COMPARE or decIns.InsGroup=BIT_TEST or 
        decIns.InsGroup=JUMP_BRANCH or decIns.InsGroup=ARITHMETIC)) then
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.wrBI <= '1';      -- BI <- DB
            uins.wrAI <= '1';     
            if decIns.InsGroup = COMPARE or decIns.instruction = SBC then
                uins.mux_bi <= "01"; -- BI <- !MEM[MAR] for compare and SBC instructions
            end if;
            if decIns.InsGroup = JUMP_BRANCH then
                uins.mux_adl <= "11"; uins.mux_ai <= "00";  -- AI <- PCL
                uins.mux_sb <= "110"; uins.wrOffset <= '1'; -- Check if offset is negative
            elsif decIns.instruction = CPX then
                uins.mux_sb <= "011"; uins.mux_ai <= "10";  -- AI <- X
            elsif decIns.instruction = CPY then
                uins.mux_sb <= "100"; uins.mux_ai <= "10";  -- AI <- Y
            else
                uins.mux_sb <= "101"; uins.mux_ai <= "10";  -- AI <- AC 
            end if;
            if (decIns.addressMode=ZPG or decIns.addressMode=IMM or decIns.addressMode=REL) then 
                uins.mux_address <= '0'; -- address <- MAR
            else
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;
         
    -- DECODE (ZPG and IND_Y)
    -- T2: MAR <- MEM[MAR];    BI <- MEM[MAR]; AI <- 0 (for IND_Y)
        elsif (currentState = T2 and (decIns.addressMode=ZPG or decIns.addressMode = IND_Y)) then
            uins.mux_db <= "100";  -- DB <- MEM[MAR]
            uins.mux_mar <= "0001";   
            uins.wrMAR <= '1';     -- MAR <- DB
            if decIns.addressMode=IND_Y then
                uins.wrBI <= '1';                       -- BI <- DB
                uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
            end if;
                        
    -- DECODE (ZPG_X, ZPG_Y, IND_X)
    -- T2: BI <- MEM[MAR]; AI <- X/Y         
        elsif (currentState = T2 and 
        (decIns.addressMode=ZPG_X or decIns.addressMode=ZPG_Y or decIns.addressMode=IND_X)) then
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
        elsif (currentState = T3 and (decIns.addressMode=ZPG_X or decIns.addressMode=ZPG_Y or 
        decIns.addressMode=IND_X or decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or 
        (currentState = T4 and (decIns.addressMode=IND_Y or decIns.addressMode=IND)) then
            if decIns.addressMode=IND then
                uins.ALUoperation <= ALU_ADC; -- AI + BI + 1
                uins.mux_address <= '1'; -- address <- ABH & ABL
            else
                uins.ALUoperation <= ALU_ADD;
            end if;
            uins.wrABL <= '1';         -- ABL <- AI + BI or AI + BI + 1 for IND
            if (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y or 
            decIns.addressMode=IND_Y or decIns.addressMode=IND) then
                uins.mux_db <= "100";  -- DB <- MEM[MAR]
                uins.wrBI <= '1';      -- BI <- DB
                uins.mux_ai <= "01";   
                uins.wrAI <= '1';      -- AI <- x"00"
            else
                uins.mux_adh <= "10";
                uins.wrABH <= '1';       -- ABH <- x"00"
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;
            
    -- DECODE (RTS, RTI, PLA, PLP): ABL <- AI + BI + 1; ABH <- 1; S <- AI + BI + 1
        elsif ((currentState=T2 or currentState=T4) and 
        (decIns.instruction=PLA or decIns.instruction=PLP or 
        decIns.instruction=RTS or decIns.instruction=RTI)) or 
        (currentState = T6 and decIns.instruction = RTI) then
            uins.ALUoperation <= ALU_ADC; uins.wrABL <= '1';
            uins.mux_sb <= "001"; uins.mux_s <= '1'; uins.wrS <= '1';
            uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
            uins.mux_address <= '1';
            
    -- Last Cycle for RTS    
        elsif currentState = T6 and decIns.instruction = RTS then   
            uins.wrPCL  <= '1'; 
            uins.wrPCH  <= '1'; -- PC ++, corrects JSR anomaly
    
    -- DECODE (RTI), T3: P <- MEM[ABH/ABL]; BI <- S; AI <- 0
        elsif currentState=T3 and decIns.instruction=RTI then
            uins.mux_db <= "100"; uins.mux_address <= '1';
            uins.mux_p <= '1'; uins.ceP <= x"FF";   -- P <- MEM[ABH/ABL];
            uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
            uins.mux_bi <= "10"; uins.wrBI <= '1';  -- BI <- S
    
    -- DECODE (second step) T3: ABH <- MEM[MAR]; or PCL <- AI + BI; PCH <- MEM[MAR]; (JUMP AABS)
        elsif (currentState = T3 and 
        (decIns.addressMode=AABS or decIns.addressMode=IND or decIns.addressMode=REL)) or 
        (currentState=T2 and decIns.instruction=BRK) then
            if ((decIns.instruction=JMP and decIns.addressMode=AABS) or decIns.addressMode=REL) then
                uins.ALUoperation <= ALU_ADD;
                uins.mux_pc <= '1';                      -- PC <- ADH & ADL
                uins.mux_adl <= "00"; uins.wrPCL <= '1'; -- PCL <- AI + BI
                if decIns.addressMode=REL then
                    uins.mux_ai <= "01"; uins.wrAI <= '1';   -- AI <- x"00"
                    uins.mux_db <= "011"; uins.wrBI <= '1';  -- BI <- PCH
                else
                    uins.mux_db <= "100";                    -- DB <- MEM[MAR]
                    uins.mux_adh <= "00"; uins.wrPCH <= '1'; -- PCH <- MEM[MAR]
                end if;    
            elsif decIns.instruction=JSR or decIns.instruction=BRK then
                we <= '1';                               -- Write Mode
                uins.mux_address <= '1';                 -- address <- ABH & ABL
                uins.mux_db <= "011";                    -- MEM[ABH/ABL] <- PCH
            else
                uins.mux_db <= "100";                   -- DB <- MEM[MAR]
                uins.mux_adh <= "00"; uins.wrABH <= '1';-- ABH <- DB
                if decIns.instruction/=STA and decIns.instruction/=STX and decIns.instruction/=STY then -- != Stores
                    uins.mux_address <= '1';                -- address <- ABH & ABL
                end if;
            end if;
            
    -- DECODE (JSR): ABL <- S; ABH <- 1; S--; MEM[ABH/ABL] <- PCL;       
        elsif (currentState=T4 and decIns.addressMode=AABS and decIns.InsGroup=SUBROUTINE_INTERRUPT) or 
        (currentState=T3 and decIns.instruction=BRK) then
            uins.mux_adl <= "01"; uins.wrABL <= '1'; -- ABL <- S 
            uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
            uins.mux_s <= '0'; uins.wrS <= '1';      -- S <- S - 1
            uins.mux_db <= "010";                    -- MEM[ABH/ABL] <- PCL
            we <= '1';                               -- Write Mode
            uins.mux_address <= '1';                 -- address <- ABH & ABL
    
    -- DECODE (BRK): ABL <- S; ABH <- 1; S--; MEM[S] <- P;    
        elsif currentState=T4 and decIns.instruction=BRK then
            uins.mux_adl <= "01"; uins.wrABL <= '1'; -- ABL <- S 
            uins.mux_adh <= "11"; uins.wrABH <= '1'; -- ABH <- 1
            uins.mux_s <= '0'; uins.wrS <= '1';      -- S <- S - 1
            we <= '1'; uins.mux_db <= "101";         -- MEM[S] <- P
            uins.mux_address <= '1';                 -- address <- ABH & ABL
    
    -- DECODE (BRK): MAR <- x"FFFF" for BRK/IRQ, FFFD for NRES or FFFB for NMI interruption 
        elsif currentState=T5 and decIns.instruction=BRK then
            if (q_nmi = '1') then
                uins.mux_mar <= "0111";  -- MAR <- x"FFFB"
            elsif (q_nres = '1') then
                uins.mux_mar <= "0101";  -- MAR <- x"FFFD"
            else -- BRK and IRQ
                uins.mux_mar <= "0011";  -- MAR <- x"FFFF"
            end if;
            uins.wrMAR <= '1';
                
    -- DECODE (BRK): PCH <- MEM[MAR]; MAR <- x"FFFE" for BRK/IRQ, x"FFFC" for NRES or x"FFFA" for NMI;
        elsif currentState=T6 and decIns.instruction=BRK then
            uins.mux_db <= "100"; uins.mux_adh <= "00";
            uins.mux_pc <= '1'; uins.wrPCH <= '1'; -- PCH <- MEM[MAR]
            if (q_nmi = '1') then
                uins.mux_mar <= "1000";  -- MAR <- x"FFFA"
            elsif (q_nres = '1') then
                uins.mux_mar <= "0110";  -- MAR <- x"FFFC"
            else -- BRK and IRQ
                uins.mux_mar <= "0100";  -- MAR <- x"FFFE"
            end if;
            uins.wrMAR <= '1';
        
    -- Last State (BRK): PCL <- MEM[MAR];
        elsif currentState=T7 and decIns.instruction=BRK then        
            uins.mux_db <= "100"; uins.mux_adl <= "10"; 
            uins.mux_pc <= '1'; uins.wrPCL <= '1'; 
            uins.setP(INTERRUPT) <= '1'; -- Update Flags, maybe only for BREAK and IRQ
            if (q_nmi = '0' and q_irq = '0' and q_nres = '0') then
                uins.setP(BREAKF) <= '1'; -- Only set if Break instruction
            end if;
            
    -- DECODE (Implied addressing mode): PCL <- MEM[ABH/ABL]; BI <- S; AI <- 0    
        elsif (currentState=T3 and decIns.instruction=RTS) or 
        (currentState=T5 and decIns.instruction=RTI) then
            uins.mux_db <= "100"; uins.mux_adl <= "10"; 
            uins.mux_pc <= '1'; uins.wrPCL <= '1';
            uins.mux_bi <= "10"; uins.wrBI <= '1'; -- BI <- S (over SB)
            uins.mux_ai <= "01"; uins.wrAI <= '1'; -- AI <- x"00"
            uins.mux_address <= '1';
            
    -- DECODE (JSR and JMP Indirect)        
        elsif currentState = T5 and (decIns.addressMode = IND or 
        (decIns.addressMode = AABS and decIns.InsGroup = SUBROUTINE_INTERRUPT)) then
            uins.ALUoperation <= ALU_B;
            uins.mux_pc <= '1';                      -- PC <- ADH & ADL
            uins.mux_adl <= "00"; uins.wrPCL <= '1'; -- PCL <- BI
            if decIns.addressMode=IND then
                uins.mux_db <= "100";                    -- DB <- MEM[MAR]
                uins.mux_adh <= "00"; uins.wrPCH <= '1'; -- PCH <- MEM[ABH/ABL]
                uins.mux_address <= '1';                 -- address <- ABH & ABL
            end if;     
            
    -- Last cycle for JSR and RTS: PCH <- MEM[MAR or ABH/ABL]
        elsif (currentState=T5 and decIns.instruction=RTS) or 
        (currentState=T6 and decIns.instruction=JSR) or 
        (currentState=T7 and decIns.instruction=RTI) then
            uins.mux_db <= "100"; uins.mux_adh <= "00";
            uins.mux_pc <= '1'; uins.wrPCH <= '1'; -- PCH <- MEM[MAR]
            if decIns.addressMode=IMP then
                uins.mux_address <= '1';
            end if;
            if decIns.instruction=RTI then
                uins.rstP(INTERRUPT) <= '1'; -- Enable IRQ
            end if;
            
    -- DECODE (third step for INC and DEC, Shift and Rotate); BI <- MEM[AB]; AI <- 0    
        elsif ((currentState = T4 and (decIns.addressMode=AABS or decIns.addressMode=ZPG_X)) or 
        (currentState=T5 and decIns.addressMode=ABS_X) or 
        (currentState=T3 and decIns.addressMode=ZPG)) and 
        (decIns.InsGroup=INC_DEC  or decIns.InsGroup=SHIFT_ROTATE) then 
            uins.mux_db <= "100"; uins.wrBI <= '1'; -- BI <- MEM[MAR]
            uins.mux_ai <= "01"; uins.wrAI <= '1';  -- AI <- x"00"
            if decIns.addressMode=ZPG then 
                uins.mux_address <= '0'; -- address <- MAR
            else
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;   

    -- DECODE (ABS_X, ABS_Y IND_Y), Last Cycle for REL: T4 or T5: ABH (PCH for REL) <- AI + BI + hc;
        elsif ((currentState = T4 and 
        (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y or decIns.addressMode=REL)) or 
        (currentState = T5 and decIns.addressMode=IND_Y)) then 
            uins.mux_carry <= "11";     -- carry <- hc
            if decIns.addressMode = REL and nOffset_in = '1' then -- Verify if offset is negative, then
                uins.ALUoperation <= ALU_DECHC; -- AI + BI + hc - 1
            else
                uins.ALUoperation <= ALU_ADC; -- AI + BI + carry
            end if;
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
        elsif ((currentState = T4 and decIns.addressMode=IND_X) or 
        (currentState=T3 and decIns.addressMode=IND_Y)) then
            uins.mux_carry <= "00";     -- carry <- '1'
            uins.ALUoperation <= ALU_ADC;            
            uins.mux_db <= "100";       -- DB <- MEM[ABH/ABL]
            uins.wrBI <= '1';           -- BI <- DB
            if decIns.addressMode=IND_X then
                uins.mux_adh <= "10"; uins.wrABH <= '1'; -- ABH <- x"00"
                uins.wrABL <= '1';          -- ABL <- AI + BI + 1
                uins.mux_ai <= "01"; uins.wrAI <= '1';   -- AI <- x"00"
                uins.mux_address <= '1';    -- address <- ABH & ABL
            else  -- IND_Y
                uins.mux_mar <= "0010";       -- MAR <- AI + BI + 1
                uins.wrMAR <= '1';
                uins.mux_sb <= "100";  -- SB <- Y
                uins.mux_ai <= "10";   
                uins.wrAI <= '1';      -- AI <- SB
            end if;
            
    -- DECODE (IND_X and IND_Y) 
    -- T4 or T5: ABL <- AI + BI; ABH <- MEM[ABH/ABL] 
        elsif ((currentState = T4 and decIns.addressMode=IND_Y) or 
        (currentState = T5 and decIns.addressMode=IND_X)) then
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
        elsif (decIns.InsGroup=LOAD_STORE) and ((currentState = T2 and decIns.addressMode = IMM) or 
        (currentState = T3 and decIns.addressMode = ZPG) or 
        (currentState = T4 and (decIns.addressMode = AABS or 
        decIns.addressMode = ZPG_X or decIns.addressMode=ZPG_Y)) or 
        (currentState = T5 and (decIns.addressMode = ABS_X or decIns.addressMode = ABS_Y)) or 
        (currentState = T6 and (decIns.addressMode = IND_X or decIns.addressMode = IND_Y))) then
            if (decIns.instruction = LDA or decIns.instruction = LDX or decIns.instruction = LDY) then
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
                we <= '1'; -- Enable Write Mode : MEM[MAR] <- AC || X || Y       
            end if;
            if (decIns.addressMode=ZPG or decIns.addressMode=IMM) then 
                uins.mux_address <= '0'; -- address <- MAR
            else
                uins.mux_address <= '1'; -- address <- ABH & ABL
            end if;
            
    -- EXECUTE: Logical and Arithmetic Group (all addressing modes)
        elsif (decIns.InsGroup=LOGICAL or decIns.InsGroup=ARITHMETIC) and 
        ((currentState=T3 and decIns.addressMode=IMM) or 
        (currentState=T4 and decIns.addressMode=ZPG) or 
        (currentState=T5 and (decIns.addressMode=ZPG_X or decIns.addressMode=AABS)) or 
        (currentState=T6 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or 
        (currentState=T7 and (decIns.addressMode=IND_X or decIns.addressMode=IND_Y))) then
            uins.mux_sb <= "001";       -- SB <- ALUresult
            uins.wrAC <= '1';           -- AC <- SB  
            uins.ceP(NEGATIVE) <= '1';
            uins.ceP(ZERO)     <= '1';
            if decIns.instruction = AAND then
                uins.ALUoperation <= ALU_AND; -- AI & BI
            elsif decIns.instruction = ORA then
                uins.ALUoperation <= ALU_OR;  -- AI | BI
            elsif decIns.instruction = EOR then  
                uins.ALUoperation <= ALU_XOR; -- AI ^ BI
            else    -- ADC and SBC
                uins.mux_carry <= "01";
                uins.ALUoperation <= ALU_ADC; -- AI + BI + carry
                uins.ceP(CARRY) <= '1'; uins.ceP(OVERFLOW) <= '1';
            end if;             
                        
    -- EXECUTE: Status Flag Change, T1: IR <- MEM[MAR]; P(i) <- 1 for sets, 0 for rst
        elsif decIns.instruction=CLC and currentState=T1 then
            uins.rstP(CARRY) <= '1'; -- Clear carry flag
        elsif decIns.instruction=SECi and currentState=T1 then
            uins.setP(CARRY) <= '1'; -- Set carry flag
        elsif decIns.instruction=CLD and currentState=T1 then
            uins.rstP(DECIMAL) <= '1'; -- Clear decimal flag
        elsif decIns.instruction=SED and currentState=T1 then
            uins.setP(DECIMAL) <= '1'; -- Set decimal flag 
        elsif decIns.instruction=CLI and currentState=T1 then
            uins.rstP(INTERRUPT) <= '1'; -- Clear interrupt flag
        elsif decIns.instruction=SEI and currentState=T1 then
            uins.setP(INTERRUPT) <= '1'; -- Set interrupt flag
        elsif decIns.instruction=CLV and currentState=T1 then
            uins.rstP(OVERFLOW) <= '1';  -- Clear overflow flag
                        
    -- EXECUTE: Register Transfer Group
        elsif decIns.instruction=TAX and currentState=T1 then   -- X <- AC
            uins.mux_sb <= "101"; uins.wrX <= '1';
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
        elsif decIns.instruction=TAY and currentState=T1 then   -- Y <- AC
            uins.mux_sb <= "101"; uins.wrY <= '1';
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';               
        elsif decIns.instruction=TXA and currentState=T1 then   -- AC <- X
            uins.mux_sb <= "011"; uins.wrAC <= '1';
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
        elsif decIns.instruction=TYA and currentState=T1 then   -- AC <- Y
            uins.mux_sb <= "100"; uins.wrAC <= '1';   
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';

    -- EXECUTE: Stack Group
        elsif decIns.instruction=TSX and currentState=T1 then   -- X <- S
            uins.mux_sb <= "000"; uins.wrX <= '1';
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
        elsif decIns.instruction=TXS and currentState=T1 then   -- S <- X
            uins.mux_sb <= "011"; uins.mux_s <= '1'; 
            uins.wrS <= '1';
        elsif decIns.instruction=PHA and currentState=T2 then   -- MEM[SP] <- AC
            we <= '1'; uins.mux_db <= "000";
            uins.mux_address <= '1';    
        elsif decIns.instruction=PHP and currentState=T2 then   -- MEM[SP] <- P
            we <= '1'; uins.mux_db <= "101";
            uins.mux_address <= '1';
        elsif decIns.instruction=PLA and currentState=T3 then   -- AC <- MEM[SP] 
            uins.mux_db <= "100"; uins.mux_sb <= "110";  
            uins.wrAC <= '1'; uins.mux_address <= '1';
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
        elsif decIns.instruction=PLP and currentState=T3 then   -- P <- MEM[SP]
            uins.mux_db <= "100"; uins.mux_address <= '1';
            uins.mux_p <= '1'; uins.ceP <= x"FF";            
            
    -- EXECUTE: Compare and Bit Test Group(first stage) 
        elsif (decIns.InsGroup=COMPARE or decIns.InsGroup=BIT_TEST) and 
        ((currentState=T3 and decIns.addressMode=IMM) or 
        (currentState=T4 and decIns.addressMode=ZPG) or 
        (currentState=T5 and (decIns.addressMode=ZPG_X or decIns.addressMode=AABS)) or 
        (currentState=T6 and (decIns.addressMode=ABS_X or decIns.addressMode=ABS_Y)) or 
        (currentState=T7 and (decIns.addressMode=IND_X or decIns.addressMode=IND_Y))) then
            if decIns.InsGroup = COMPARE then
                uins.ALUoperation <= ALU_ADC;
                uins.ceP(NEGATIVE) <= '1';
                uins.ceP(CARRY)    <= '1';
            else -- BIT_TEST
                uins.ALUoperation <= ALU_AND;
            end if;
            uins.mux_sb <= "001";
            uins.ceP(ZERO) <= '1';  
            
    -- EXECUTE: Bit Test Group (second stage) 
        elsif decIns.InsGroup = BIT_TEST and 
        ((currentState=T5 and decIns.addressMode=ZPG) or 
        (currentState=T6 and decIns.addressMode=AABS)) then
            uins.ALUoperation <= ALU_B; uins.mux_sb <= "001";      -- SB <- B
            uins.ceP(NEGATIVE) <= '1';  uins.ceP(OVERFLOW) <= '1'; -- NEGATIVE <- B(7); OVERFLOW <- B(6) 
            
    -- EXECUTE: Increment and Decrement Group
        elsif decIns.InsGroup=INC_DEC and 
        ((currentState=T2 and decIns.addressMode=IMP) or 
        (currentState=T4 and decIns.addressMode=ZPG) or 
        (currentState=T5 and (decIns.addressMode=AABS or decIns.addressMode=ZPG_X)) or 
        (currentState=T6 and decIns.addressMode=ABS_X)) then
            if decIns.instruction=INC or decIns.instruction=INX or decIns.instruction=INY then
                uins.ALUoperation <= ALU_ADC;
            else
                uins.ALUoperation <= ALU_DEC; 
            end if;
            if decIns.instruction=INX or decIns.instruction=DEX then
                uins.wrX <= '1';
            elsif decIns.instruction=INY or decIns.instruction=DEY then
                uins.wrY <= '1';
            else
                uins.mux_db <= "001"; -- DB <- ALUresult
                we <= '1'; -- Enable Write Mode 
                if decIns.addressMode=ZPG then 
                    uins.mux_address <= '0'; -- address <- MAR
                else
                    uins.mux_address <= '1'; -- address <- ABH & ABL
                end if;
            end if;
            uins.mux_sb <= "001";
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
                        
    -- EXECUTE: Shift and Rotate Group
        elsif decIns.InsGroup=SHIFT_ROTATE and 
        ((currentState=T2 and decIns.addressMode=ACC) or 
        (currentState=T4 and decIns.addressMode=ZPG) or 
        (currentState=T5 and (decIns.addressMode=AABS or decIns.addressMode=ZPG_X)) or 
        (currentState=T6 and decIns.addressMode=ABS_X)) then
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
            uins.ceP(NEGATIVE) <= '1'; uins.ceP(ZERO) <= '1';
            if decIns.addressMode=ACC then
               uins.wrAC <= '1';
            else
                uins.mux_db <= "001";  -- DB <- ALUresult
                we <= '1';             -- Enable Write Mode 
                if decIns.addressMode=ZPG then 
                    uins.mux_address <= '0'; -- address <- MAR
                else
                    uins.mux_address <= '1'; -- address <- ABH & ABL
                end if;
            end if;
            
        else
        end if;
                
    end process;
   
end ControlPath;