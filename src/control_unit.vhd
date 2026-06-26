library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.core_pkg.all;

entity control_unit is
    Port (
        opcode      : in  STD_LOGIC_VECTOR (3 downto 0);
        alu_src     : out STD_LOGIC; 
        alu_ctrl    : out STD_LOGIC_VECTOR (3 downto 0);
        mem_read    : out STD_LOGIC;
        mem_write   : out STD_LOGIC;
        branch      : out STD_LOGIC; 
        reg_write   : out STD_LOGIC;
        mem_to_reg  : out STD_LOGIC  
    );
end control_unit;

architecture Behavioral of control_unit is
begin
    process(opcode)
    begin
        -- Default Safe State
        alu_src    <= '0'; alu_ctrl   <= OP_NOP; mem_read   <= '0';
        mem_write  <= '0'; branch     <= '0';    reg_write  <= '0';
        mem_to_reg <= '0';

        case opcode is
            when OP_LDI => 
                alu_src <= '1'; reg_write <= '1';
            when OP_LDR => 
                alu_src <= '1'; mem_read <= '1'; reg_write <= '1'; mem_to_reg <= '1';
            when OP_STR => 
                alu_src <= '1'; mem_write <= '1';
            when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR | OP_SHL | OP_SHR | OP_CMP => 
                alu_ctrl <= opcode;
                if opcode /= OP_CMP then reg_write <= '1'; end if;
            when OP_ADDI | OP_SUBI => 
                alu_src <= '1'; alu_ctrl <= opcode; reg_write <= '1';
            when OP_JMP | OP_JZ => 
                alu_src  <= '1';     -- USE IMMEDIATE AS TARGET
                alu_ctrl <= opcode;  -- PASS OPCODE TO EX STAGE
                branch   <= '1';
            when others => null;
        end case;
    end process;
end Behavioral;