------------------------------------------------------------------------------------------------
-- DESIGN UNIT  : 6502 Package                                                                --
-- DESCRIPTION  : Decodable instructions enumeration and control signals grouping             --
-- AUTHOR       : Everton Alceu Carara and Bernardo Favero Andreeti                           --
-- CREATED      : June 3rd, 2015                                                              --
-- VERSION      : 0.5                                                                         --
------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.Std_Logic_1164.all;

package P6502_pkg is  

    -- Constant flags
    constant CARRY     : integer := 0;
    constant ZERO      : integer := 1;
    constant INTERRUPT : integer := 2;
    constant DECIMAL   : integer := 3;
    constant BREAKF    : integer := 4;
    constant UNUSED    : integer := 5;
    constant OVERFLOW  : integer := 6;
    constant NEGATIVE  : integer := 7;
    
    -- Instructions execution cycle
    type State is (T0, T1, T2, T3, T4, T5, T6, T7);
     
    -- Instruction_type enumeration defines the instructions decodable by the control path
    type Instruction_type is (  
        LDA, LDX, LDY,
        STA, STX, STY,
        ADC, SBC,
        INC, INX, INY,
        DEC, DEX, DEY,
        TAX, TAY, TXA, TYA,
        AAND, EOR, ORA,
        CMP, CPX, CPY, BITT,
        ASL, LSR, ROLL, RORR,
        JMP, BCC, BCS, BEQ, BMI, BNE, BPL, BVC, BVS,
        TSX, TXS, PHA, PHP, PLA, PLP,
        CLC, CLD, CLI, CLV, SECi, SED, SEI,
        JSR, RTS, BRK, RTI, NOP,

        invalid_instruction
    );
    
    type InstructionGroup_type is (
        LOAD_STORE, ARITHMETIC, INC_DEC, REG_TRANSFER, 
        LOGICAL, COMPARE, BIT_TEST, STATUS_FLAG, 
        SUBROUTINE_INTERRUPT, JUMP_BRANCH, 
        STACK, SHIFT_ROTATE
    );
    
    type ALU_Operation_type is (
        ALU_AND, ALU_OR, ALU_XOR,
        ALU_A, ALU_B, ALU_ADD, ALU_ADC, 
        ALU_DEC, ALU_DECHC, ALU_ASL, ALU_LSR, 
        ALU_ROL, ALU_ROR, ALU_NOP
    );
    
    type AddressMode_type is (IMM, ZPG, ZPG_X, ZPG_Y, IND_X, IND_Y, AABS, ABS_X, ABS_Y, IMP, REL, ACC, IND);
    
    type DecodedInstruction_type is record
        instruction        : Instruction_type;
        addressMode        : AddressMode_type;
        InsGroup           : InstructionGroup_type;    
        size               : integer range 1 to 3;
    end record;
 
    type Microinstruction is record
        wrAI         : std_logic;                    -- Write control for AI register
        wrBI         : std_logic;                    -- Write control for BI register
        wrAC         : std_logic;                    -- Write control for AC register
        wrS          : std_logic;                    -- Write control for S register
        wrX          : std_logic;                    -- Write control for X register
        wrY          : std_logic;                    -- Write control for Y register
        wrPCH        : std_logic;                    -- Write control for PCH register
        wrPCL        : std_logic;                    -- Write control for PCL register
        wrABH        : std_logic;                    -- Write control for ABH register
        wrABL        : std_logic;                    -- Write control for ABL register
        wrMAR        : std_logic;                    -- Write control for MAR register
        wrOffset     : std_logic;                    -- Write control for Negative Offset register
        mux_address  : std_logic;                    -- Multiplexer selection input
        mux_bi       : std_logic_vector(1 downto 0); -- Multiplexer selection input
        mux_mar      : std_logic_vector(3 downto 0); -- Multiplexer selection input
        mux_ai       : std_logic_vector(1 downto 0); -- Multiplexer selection input
        mux_carry    : std_logic_vector(1 downto 0); -- Multiplexer selection input
        mux_s        : std_logic;                    -- Multiplexer selection input
        mux_pc       : std_logic;                    -- Multiplexer selection input
        mux_p        : std_logic;                    -- Multiplexer selection input
        mux_db       : std_logic_vector(2 downto 0); -- DB Multiplexer selection input
        mux_sb       : std_logic_vector(2 downto 0); -- SB Multiplexer selection input 
        mux_adl      : std_logic_vector(1 downto 0); -- ADL Multiplexer selection input 
        mux_adh      : std_logic_vector(1 downto 0); -- ADH Multiplexer selection input 
        ALUoperation : ALU_Operation_type;
        setP         : std_logic_vector(7 downto 0);
        rstP         : std_logic_vector(7 downto 0);
        ceP          : std_logic_vector(7 downto 0);
    end record;
    
    function InstructionDecoder(opcode: in std_logic_vector(7 downto 0)) return DecodedInstruction_type;    
end P6502_pkg;

package body P6502_pkg is

    function InstructionDecoder(opcode: in std_logic_vector(7 downto 0)) return DecodedInstruction_type is
    
        variable di: DecodedInstruction_type;
        
    begin
    
        case opcode is
            --------------------------
            -- Load and Store Group --
            --------------------------
            -- LDA
            when x"AD" =>   di.instruction := LDA;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"A5" =>   di.instruction := LDA;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"A9" =>   di.instruction := LDA;  di.addressMode := IMM;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"BD" =>   di.instruction := LDA;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"B9" =>   di.instruction := LDA;  di.addressMode := ABS_Y;    di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"B5" =>   di.instruction := LDA;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"A1" =>   di.instruction := LDA;  di.addressMode := IND_X;    di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"B1" =>   di.instruction := LDA;  di.addressMode := IND_Y;    di.size := 2;   di.InsGroup := LOAD_STORE;
                       
            -- LDX
            when x"AE" =>   di.instruction := LDX;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"A6" =>   di.instruction := LDX;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"A2" =>   di.instruction := LDX;  di.addressMode := IMM;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"BE" =>   di.instruction := LDX;  di.addressMode := ABS_Y;    di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"B6" =>   di.instruction := LDX;  di.addressMode := ZPG_Y;    di.size := 2;   di.InsGroup := LOAD_STORE;
                                 
            -- LDY
            when x"AC" =>   di.instruction := LDY;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"A4" =>   di.instruction := LDY;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"A0" =>   di.instruction := LDY;  di.addressMode := IMM;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"BC" =>   di.instruction := LDY;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"B4" =>   di.instruction := LDY;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := LOAD_STORE;
            
            -- STA
            when x"8D" =>   di.instruction := STA;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"85" =>   di.instruction := STA;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"9D" =>   di.instruction := STA;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"99" =>   di.instruction := STA;  di.addressMode := ABS_Y;    di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"95" =>   di.instruction := STA;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"81" =>   di.instruction := STA;  di.addressMode := IND_X;    di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"91" =>   di.instruction := STA;  di.addressMode := IND_Y;    di.size := 2;   di.InsGroup := LOAD_STORE;
            
            -- STX
            when x"8E" =>   di.instruction := STX;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"86" =>   di.instruction := STX;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"96" =>   di.instruction := STX;  di.addressMode := ZPG_Y;    di.size := 2;   di.InsGroup := LOAD_STORE;
            
            -- STY
            when x"8C" =>   di.instruction := STY;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := LOAD_STORE;
            when x"84" =>   di.instruction := STY;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := LOAD_STORE;
            when x"94" =>   di.instruction := STY;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := LOAD_STORE;
            
            
            ----------------------
            -- Arithmetic Group --
            ----------------------
            -- ADC
            when x"6D" =>   di.instruction := ADC;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := ARITHMETIC;
            when x"65" =>   di.instruction := ADC;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"69" =>   di.instruction := ADC;  di.addressMode := IMM;      di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"7D" =>   di.instruction := ADC;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := ARITHMETIC;
            when x"79" =>   di.instruction := ADC;  di.addressMode := ABS_Y;    di.size := 3;   di.InsGroup := ARITHMETIC;
            when x"75" =>   di.instruction := ADC;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"61" =>   di.instruction := ADC;  di.addressMode := IND_X;    di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"71" =>   di.instruction := ADC;  di.addressMode := IND_Y;    di.size := 2;   di.InsGroup := ARITHMETIC;
            
            -- SBC
            when x"ED" =>   di.instruction := SBC;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := ARITHMETIC;
            when x"E5" =>   di.instruction := SBC;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"E9" =>   di.instruction := SBC;  di.addressMode := IMM;      di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"FD" =>   di.instruction := SBC;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := ARITHMETIC;
            when x"F9" =>   di.instruction := SBC;  di.addressMode := ABS_Y;    di.size := 3;   di.InsGroup := ARITHMETIC;
            when x"F5" =>   di.instruction := SBC;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"E1" =>   di.instruction := SBC;  di.addressMode := IND_X;    di.size := 2;   di.InsGroup := ARITHMETIC;
            when x"F1" =>   di.instruction := SBC;  di.addressMode := IND_Y;    di.size := 2;   di.InsGroup := ARITHMETIC;
           
           
            -----------------------------------
            -- Increment and Decrement Group --
            -----------------------------------
            -- INC
            when x"EE" =>   di.instruction := INC;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := INC_DEC;
            when x"E6" =>   di.instruction := INC;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := INC_DEC;
            when x"FE" =>   di.instruction := INC;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := INC_DEC;
            when x"F6" =>   di.instruction := INC;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := INC_DEC;
            
            -- INX
            when x"E8" =>   di.instruction := INX;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := INC_DEC;
            
            -- INY
            when x"C8" =>   di.instruction := INY;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := INC_DEC;
            
            -- DEC
            when x"CE" =>   di.instruction := DEC;  di.addressMode := AABS;     di.size := 3;   di.InsGroup := INC_DEC;
            when x"C6" =>   di.instruction := DEC;  di.addressMode := ZPG;      di.size := 2;   di.InsGroup := INC_DEC;
            when x"DE" =>   di.instruction := DEC;  di.addressMode := ABS_X;    di.size := 3;   di.InsGroup := INC_DEC;
            when x"D6" =>   di.instruction := DEC;  di.addressMode := ZPG_X;    di.size := 2;   di.InsGroup := INC_DEC;
            
            -- DEX
            when x"CA" =>   di.instruction := DEX;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := INC_DEC;
            
            -- DEY
            when x"88" =>   di.instruction := DEY;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := INC_DEC;
            
            
            -----------------------------
            -- Register Transfer Group --
            -----------------------------
            -- TAX
            when x"AA" =>   di.instruction := TAX;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := REG_TRANSFER;
            
            -- TAY
            when x"A8" =>   di.instruction := TAY;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := REG_TRANSFER;
            
            -- TXA
            when x"8A" =>   di.instruction := TXA;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := REG_TRANSFER;
            
            -- TYA
            when x"98" =>   di.instruction := TYA;  di.addressMode := IMP;      di.size := 1;   di.InsGroup := REG_TRANSFER;
            
            
            -------------------
            -- Logical Group --
            -------------------
            -- AND
            when x"2D" =>   di.instruction := AAND;  di.addressMode := AABS;     di.size := 3;  di.InsGroup := LOGICAL;
            when x"25" =>   di.instruction := AAND;  di.addressMode := ZPG;      di.size := 2;  di.InsGroup := LOGICAL;
            when x"29" =>   di.instruction := AAND;  di.addressMode := IMM;      di.size := 2;  di.InsGroup := LOGICAL;
            when x"3D" =>   di.instruction := AAND;  di.addressMode := ABS_X;    di.size := 3;  di.InsGroup := LOGICAL;
            when x"39" =>   di.instruction := AAND;  di.addressMode := ABS_Y;    di.size := 3;  di.InsGroup := LOGICAL;
            when x"35" =>   di.instruction := AAND;  di.addressMode := ZPG_X;    di.size := 2;  di.InsGroup := LOGICAL;
            when x"21" =>   di.instruction := AAND;  di.addressMode := IND_X;    di.size := 2;  di.InsGroup := LOGICAL;
            when x"31" =>   di.instruction := AAND;  di.addressMode := IND_Y;    di.size := 2;  di.InsGroup := LOGICAL;
            
            -- EOR
            when x"4D" =>   di.instruction := EOR;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := LOGICAL;
            when x"45" =>   di.instruction := EOR;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := LOGICAL;
            when x"49" =>   di.instruction := EOR;  di.addressMode := IMM;       di.size := 2;  di.InsGroup := LOGICAL;
            when x"5D" =>   di.instruction := EOR;  di.addressMode := ABS_X;     di.size := 3;  di.InsGroup := LOGICAL;
            when x"59" =>   di.instruction := EOR;  di.addressMode := ABS_Y;     di.size := 3;  di.InsGroup := LOGICAL;
            when x"55" =>   di.instruction := EOR;  di.addressMode := ZPG_X;     di.size := 2;  di.InsGroup := LOGICAL;
            when x"41" =>   di.instruction := EOR;  di.addressMode := IND_X;     di.size := 2;  di.InsGroup := LOGICAL;
            when x"51" =>   di.instruction := EOR;  di.addressMode := IND_Y;     di.size := 2;  di.InsGroup := LOGICAL;
            
            -- ORA
            when x"0D" =>   di.instruction := ORA;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := LOGICAL;
            when x"05" =>   di.instruction := ORA;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := LOGICAL;
            when x"09" =>   di.instruction := ORA;  di.addressMode := IMM;       di.size := 2;  di.InsGroup := LOGICAL;
            when x"1D" =>   di.instruction := ORA;  di.addressMode := ABS_X;     di.size := 3;  di.InsGroup := LOGICAL;
            when x"19" =>   di.instruction := ORA;  di.addressMode := ABS_Y;     di.size := 3;  di.InsGroup := LOGICAL;
            when x"15" =>   di.instruction := ORA;  di.addressMode := ZPG_X;     di.size := 2;  di.InsGroup := LOGICAL;
            when x"01" =>   di.instruction := ORA;  di.addressMode := IND_X;     di.size := 2;  di.InsGroup := LOGICAL;
            when x"11" =>   di.instruction := ORA;  di.addressMode := IND_Y;     di.size := 2;  di.InsGroup := LOGICAL;
            
           
            --------------------------------
            -- Compare and Bit Test Group --
            --------------------------------
            -- CMP
            when x"CD" =>   di.instruction := CMP;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := COMPARE;
            when x"C5" =>   di.instruction := CMP;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := COMPARE;
            when x"C9" =>   di.instruction := CMP;  di.addressMode := IMM;       di.size := 2;  di.InsGroup := COMPARE;
            when x"DD" =>   di.instruction := CMP;  di.addressMode := ABS_X;     di.size := 3;  di.InsGroup := COMPARE;
            when x"D9" =>   di.instruction := CMP;  di.addressMode := ABS_Y;     di.size := 3;  di.InsGroup := COMPARE;
            when x"D5" =>   di.instruction := CMP;  di.addressMode := ZPG_X;     di.size := 2;  di.InsGroup := COMPARE;
            when x"C1" =>   di.instruction := CMP;  di.addressMode := IND_X;     di.size := 2;  di.InsGroup := COMPARE;
            when x"D1" =>   di.instruction := CMP;  di.addressMode := IND_Y;     di.size := 2;  di.InsGroup := COMPARE;
            
            -- CPX
            when x"EC" =>   di.instruction := CPX;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := COMPARE;
            when x"E4" =>   di.instruction := CPX;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := COMPARE;
            when x"E0" =>   di.instruction := CPX;  di.addressMode := IMM;       di.size := 2;  di.InsGroup := COMPARE;
             
            -- CPY
            when x"CC" =>   di.instruction := CPY;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := COMPARE;
            when x"C4" =>   di.instruction := CPY;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := COMPARE;
            when x"C0" =>   di.instruction := CPY;  di.addressMode := IMM;       di.size := 2;  di.InsGroup := COMPARE;
            
            -- BIT
            when x"2C" =>   di.instruction := BITT; di.addressMode := AABS;      di.size := 3;  di.InsGroup := BIT_TEST;
            when x"24" =>   di.instruction := BITT; di.addressMode := ZPG;       di.size := 2;  di.InsGroup := BIT_TEST;
            
            ------------------------------
            -- Shift and Rotate Group   --
            ------------------------------
            -- ASL
            when x"0E" =>   di.instruction := ASL;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"06" =>   di.instruction := ASL;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            when x"0A" =>   di.instruction := ASL;  di.addressMode := ACC;       di.size := 1;  di.InsGroup := SHIFT_ROTATE;
            when x"1E" =>   di.instruction := ASL;  di.addressMode := ABS_X;     di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"16" =>   di.instruction := ASL;  di.addressMode := ZPG_X;     di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            
            -- LSR
            when x"4E" =>   di.instruction := LSR;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"46" =>   di.instruction := LSR;  di.addressMode := ZPG;       di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            when x"4A" =>   di.instruction := LSR;  di.addressMode := ACC;       di.size := 1;  di.InsGroup := SHIFT_ROTATE;
            when x"5E" =>   di.instruction := LSR;  di.addressMode := ABS_X;     di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"56" =>   di.instruction := LSR;  di.addressMode := ZPG_X;     di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            
            -- ROL
            when x"2E" =>   di.instruction := ROLL;  di.addressMode := AABS;     di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"26" =>   di.instruction := ROLL;  di.addressMode := ZPG;      di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            when x"2A" =>   di.instruction := ROLL;  di.addressMode := ACC;      di.size := 1;  di.InsGroup := SHIFT_ROTATE;
            when x"3E" =>   di.instruction := ROLL;  di.addressMode := ABS_X;    di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"36" =>   di.instruction := ROLL;  di.addressMode := ZPG_X;    di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            
            -- ROR
            when x"6E" =>   di.instruction := RORR;  di.addressMode := AABS;     di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"66" =>   di.instruction := RORR;  di.addressMode := ZPG;      di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            when x"6A" =>   di.instruction := RORR;  di.addressMode := ACC;      di.size := 1;  di.InsGroup := SHIFT_ROTATE;
            when x"7E" =>   di.instruction := RORR;  di.addressMode := ABS_X;    di.size := 3;  di.InsGroup := SHIFT_ROTATE;
            when x"76" =>   di.instruction := RORR;  di.addressMode := ZPG_X;    di.size := 2;  di.InsGroup := SHIFT_ROTATE;
            
            ------------------------------
            -- Jump and Branch Group    --
            ------------------------------
            -- JMP
            when x"4C" =>   di.instruction := JMP;   di.addressMode := AABS;     di.size := 3;  di.InsGroup := JUMP_BRANCH;
            when x"6C" =>   di.instruction := JMP;   di.addressMode := IND;      di.size := 3;  di.InsGroup := JUMP_BRANCH;
            
            -- BCC
            when x"90" =>   di.instruction := BCC;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BCS
            when x"B0" =>   di.instruction := BCS;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BEQ
            when x"F0" =>   di.instruction := BEQ;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BMI
            when x"30" =>   di.instruction := BMI;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BNE
            when x"D0" =>   di.instruction := BNE;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BPL
            when x"10" =>   di.instruction := BPL;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BVC
            when x"50" =>   di.instruction := BVC;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            -- BVS
            when x"70" =>   di.instruction := BVS;   di.addressMode := REL;      di.size := 2;  di.InsGroup := JUMP_BRANCH;
            
            ------------------------------
            -- Stack Group              --
            ------------------------------
            -- TSX
            when x"BA" =>   di.instruction := TSX;   di.addressMode := IMP;      di.size := 1;  di.InsGroup := STACK;
            
            -- TXS
            when x"9A" =>   di.instruction := TXS;   di.addressMode := IMP;      di.size := 1;  di.InsGroup := STACK;
            
            -- PHA
            when x"48" =>   di.instruction := PHA;   di.addressMode := IMP;      di.size := 1;  di.InsGroup := STACK;
            
            -- PHP
            when x"08" =>   di.instruction := PHP;   di.addressMode := IMP;      di.size := 1;  di.InsGroup := STACK;
            
            -- PLA
            when x"68" =>   di.instruction := PLA;   di.addressMode := IMP;      di.size := 1;  di.InsGroup := STACK;
            
            -- PLP
            when x"28" =>   di.instruction := PLP;   di.addressMode := IMP;      di.size := 1;  di.InsGroup := STACK;
            
            ------------------------------
            -- Status Flag Change Group --
            ------------------------------
            -- CLC
            when x"18" =>   di.instruction := CLC;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := STATUS_FLAG;
            
            -- CLD
            when x"D8" =>   di.instruction := CLD;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := STATUS_FLAG;
            
            -- CLI
            when x"58" =>   di.instruction := CLI;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := STATUS_FLAG;
            
            -- CLV
            when x"B8" =>   di.instruction := CLV;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := STATUS_FLAG;
            
            -- SEC
            when x"38" =>   di.instruction := SECi;  di.addressMode := IMP;      di.size := 1;  di.InsGroup := STATUS_FLAG;
            
            -- SED
            when x"F8" =>   di.instruction := SED;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := STATUS_FLAG;
            
            -- SEI
            when x"78" =>   di.instruction := SEI;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := STATUS_FLAG;
                     
            --------------------------------------
            -- Subroutine and Interrupt Group  --
            --------------------------------------
            -- JSR
            when x"20" =>   di.instruction := JSR;  di.addressMode := AABS;      di.size := 3;  di.InsGroup := SUBROUTINE_INTERRUPT;
            
            -- RTS
            when x"60" =>   di.instruction := RTS;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := SUBROUTINE_INTERRUPT;
                       
            -- BRK
            when x"00" =>   di.instruction := BRK;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := SUBROUTINE_INTERRUPT;
            
            -- RTI
            when x"40" =>   di.instruction := RTI;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := SUBROUTINE_INTERRUPT;
            
            -- NOP
            when x"EA" =>   di.instruction := NOP;  di.addressMode := IMP;       di.size := 1;  di.InsGroup := SUBROUTINE_INTERRUPT;
            
            when others =>   di.instruction := invalid_instruction;
            
        end case;                     
        return di;
        
    end InstructionDecoder;
    
    
end P6502_pkg;