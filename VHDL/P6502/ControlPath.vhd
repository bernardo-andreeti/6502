--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Control path                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara                                              --
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
               
                    nextState <= T3;
                
                
            when T3 =>
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
		uins <= ('0','0','0','0','0','0','0','0','0','0','0',"00","00","00",'0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0',"000",x"00",x"00",x"00",'0','0');
			
        if currentState = IDLE then
            uins.rstP(CARRY) 		<= '1';
			uins.rstP(ZERO) 		<= '1';
            uins.rstP(INTERRUPT) <= '1';
            uins.rstP(DECIMAL) 	<= '1';
			uins.rstP(BREAKF) 		<= '1';
			uins.rstP(OVERFLOW) <= '1';
			uins.rstP(NEGATIVE) 	<= '1';
			uins.rstP(5) 	<= '1';
			uins.pc_ad <= '1';
						            
        -- Fetch
        -- T0: AB <- PC; PC++; IR <- DB; (all instructions)
        -- T1: AB <- PC; PC++; (all instructions except one byte ones)
        -- T1: AB <- PC; IR <- MEM[AB] (One byte instructions)
        elsif currentState = T0 or (currentState = T1 and decIns.size > 1)  then  
            -- AB <- PC
            uins.pc_ad <= '1';
            uins.mux_abh <= "00";
            uins.wrABH <= '1';
            uins.wrABL <= '1';
						
            -- PC++
			uins.mux_pc <= '0';
            uins.wrPCH <= '1';
            uins.wrPCL <= '1';
			-- read instruction (MEM[AB])
			uins.ce <= '1';
			uins.rw <= '1';
			
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
		
		-- working till here
			
        -- BI <- MEM[AB]; AI <- 0
        elsif   ( (decIns.instruction=LDA or decIns.instruction=LDX or decIns.instruction=LDY) and 
                  (decIns.addressMode=IMM or decIns.addressMode=ZPG) and currentState=T2 ) 
                  or 
                ( (decIns.instruction=ADC or decIns.instruction=SBC or decIns.instruction=AAND or decIns.instruction=ORA or decIns.instruction=EOR ) and 
                  decIns.addressMode=ZPG and currentState=T2 ) then 
            -- BI <- MEM[AB]
            uins.ce <= '1';
            uins.rw <= '1';
            uins.mux_bi <= '0';
            uins.wrBI <= '1';            
            
            -- AI <- 0
            uins.mux_ai <= "10";
            uins.wrAI <= '1';
        
        -- LDA_IMM T3: AC <- AI + BI + 0; wrn; wrz
        -- LDX_IMM T3: X <- AI + BI + 0; wrn; wrz
        -- LDY_IMM T3: Y <- AI + BI + 0; wrn; wrz
        -- AND_IMM T3: AC <- AI & BI; wrn; wrz
        -- ORA_IMM T3: AC <- AI | BI; wrn; wrz
        -- EOR_IMM T3: AC <- AI ^ BI; wrn; wrz
        elsif (decIns.instruction=LDA or decIns.instruction=LDX or decIns.instruction=LDY or decIns.instruction=AAND or decIns.instruction=ORA or decIns.instruction=EOR) and 
               decIns.addressMode=IMM and currentState=T3 then
            
            if decIns.instruction=AAND then
                uins.ALUoperation <= "000";     -- AI & BI
            elsif decIns.instruction=ORA then
                uins.ALUoperation <= "001";     -- AI | BI
            elsif decIns.instruction=EOR then
                uins.ALUoperation <= "010";     -- AI ^ BI
            else -- LDA, LDX, LDY
                uins.ALUoperation <= "110";     -- A + B + 0
            end if; 
            
            uins.alu_sb <= '1';
            uins.ceP(NEGATIVE) <= '1';      -- wrn
            uins.ceP(ZERO) <= '1';          -- wrz
            
            if decIns.instruction=LDA or decIns.instruction=AAND or decIns.instruction=ORA or decIns.instruction=EOR then
                uins.wrAC <= '1';
            elsif decIns.instruction=LDX then
                uins.wrX <= '1';
            else -- LDY
                uins.wrY <= '1';
            end if;
 
            
        -- BI <- MEM[AB]; AI <- AC
        -- BI <- !MEM[AB]; AI <- AC (SBC)
        elsif   (decIns.instruction=ADC or decIns.instruction=SBC or decIns.instruction=AAND or decIns.instruction=ORA or decIns.instruction=EOR) and
                decIns.addressMode=IMM and currentState=T2 then           
            
            uins.ce <= '1';
            uins.rw <= '1';
            
            if decIns.instruction=SBC then
                uins.mux_bi <= '1'; -- BI <- !MEM[AB]
            else
                uins.mux_bi <= '0'; -- BI <- MEM[AB]
            end if;
            uins.wrBI <= '1';
            
            -- AI <- AC
            uins.ac_sb <= '1';
            uins.mux_ai <= "01";
            uins.wrAI <= '1';
            
        -- JUNTAR COM O T3 DAS LDs E LÓGICAS
        -- AC <- AI + BI + c; wrn; wrz; wrc; wrv; 
        elsif (decIns.instruction=ADC or decIns.instruction=SBC) and decIns.addressMode=IMM and currentState=T3  then
            
            -- AC <- AI + BI + c
            uins.ALUoperation <= "101";     -- A + B + c
            
            if decIns.instruction=SBC then
                uins.mux_carry <= "10";     -- !c
            else
                uins.mux_carry <= "01";     -- c
            end if;
            uins.alu_sb <= '1';
            uins.wrAC <= '1';
            uins.ceP(NEGATIVE) <= '1';      -- wrn
            uins.ceP(ZERO) <= '1';          -- wrz
            uins.ceP(CARRY) <= '1';         -- wrc
            uins.ceP(OVERFLOW) <= '1';      -- wrv
        
        -- else
        end if;
                
    end process;
   

end ControlPath;