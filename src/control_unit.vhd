----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    control_unit.vhd
-- Description:  Main Instruction Decoder. 
--               This combinational logic block reads the 4-bit Opcode in the 
--               Decode (ID) stage and instantly generates all multiplexer routing 
--               and enable signals for the Execute, Memory, and Write-Back stages.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.core_pkg.all;

entity control_unit is
    Port (
        opcode      : in  STD_LOGIC_VECTOR (3 downto 0); -- 4-bit Instruction Opcode
        
        -- Execute Stage Controls
        alu_src     : out STD_LOGIC;                     -- '0' = Register 2, '1' = Immediate Value
        alu_ctrl    : out STD_LOGIC_VECTOR (3 downto 0); -- Operation sent to ALU
        
        -- Memory Stage Controls
        mem_read    : out STD_LOGIC;                     -- '1' = Enable RAM Read
        mem_write   : out STD_LOGIC;                     -- '1' = Enable RAM Write
        branch      : out STD_LOGIC;                     -- '1' = Signals a JMP or JZ instruction
        
        -- Write-Back Stage Controls
        reg_write   : out STD_LOGIC;                     -- '1' = Enable writing to Destination Register
        mem_to_reg  : out STD_LOGIC                      -- '1' = Write RAM data, '0' = Write ALU data
    );
end control_unit;

architecture Behavioral of control_unit is
begin
    -- =========================================================================
    -- Instruction Decoding Process (Purely Combinational)
    -- =========================================================================
    process(opcode)
    begin
        -- 1. Default Safe State (NOP)
        -- Initialize all signals to '0' to prevent latch inference and ensure safety
        alu_src    <= '0';
        alu_ctrl   <= OP_NOP;
        mem_read   <= '0';
        mem_write  <= '0';
        branch     <= '0';
        reg_write  <= '0';
        mem_to_reg <= '0';

        -- 2. Opcode Evaluation
        case opcode is
            
            -- LOAD IMMEDIATE: Write the immediate value straight to the register
            when OP_LDI => 
                alu_src   <= '1'; 
                reg_write <= '1';

            -- LOAD FROM RAM: Use immediate as address, read RAM, write to register
            when OP_LDR => 
                alu_src    <= '1'; 
                mem_read   <= '1'; 
                reg_write  <= '1'; 
                mem_to_reg <= '1';

            -- STORE TO RAM: Use immediate as address, write register data to RAM
            when OP_STR => 
                alu_src   <= '1'; 
                mem_write <= '1';

            -- REGISTER-TO-REGISTER MATH: ADD, SUB, AND, OR, XOR, SHL, SHR
            when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR | OP_SHL | OP_SHR => 
                alu_ctrl  <= opcode;
                reg_write <= '1';

            -- COMPARE: Subtract to set Zero Flag, but DO NOT write to register
            when OP_CMP => 
                alu_ctrl  <= opcode;
                -- reg_write remains '0' from default state

            -- REGISTER-TO-IMMEDIATE MATH: ADDI, SUBI
            when OP_ADDI | OP_SUBI => 
                alu_src   <= '1';
                alu_ctrl  <= opcode; 
                reg_write <= '1';

            -- BRANCHING: JMP, JZ
            when OP_JMP | OP_JZ => 
                alu_src  <= '1';     -- Force ALU to pass the immediate value (jump target)
                alu_ctrl <= opcode;  -- Pass opcode down so the EX stage can evaluate conditions
                branch   <= '1';     -- Alert the Hazard Unit of a potential pipeline flush

            -- UNKNOWN OPCODE: Default to NOP
            when others => 
                null;
                
        end case;
    end process;
end Behavioral;