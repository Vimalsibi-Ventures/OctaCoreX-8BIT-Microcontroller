----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    alu_8bit.vhd
-- Description:  Arithmetic Logic Unit (ALU) for the OctaCoreX datapath.
--               Performs 8-bit arithmetic (ADD, SUB), logical (AND, OR, XOR), 
--               and shift operations based on the 4-bit control signal from 
--               the Control Unit. Evaluates the Zero Flag for branch instructions.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all; -- Import custom ISA and system constants

entity alu_8bit is
    Port (
        in_a      : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- Operand A (from Register File)
        in_b      : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- Operand B (from Register or Immediate)
        alu_ctrl  : in  STD_LOGIC_VECTOR (3 downto 0);            -- 4-bit Operation Selector
        alu_res   : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- 8-bit Execution Result
        zero_flag : out STD_LOGIC                                 -- Active High when Result is 0x00
    );
end alu_8bit;

architecture Behavioral of alu_8bit is
    -- Internal signals for unsigned arithmetic processing
    signal temp_res : unsigned(DATA_WIDTH-1 downto 0);
    signal unsig_a  : unsigned(DATA_WIDTH-1 downto 0);
    signal unsig_b  : unsigned(DATA_WIDTH-1 downto 0);
begin
    
    -- Convert incoming STD_LOGIC_VECTOR data to unsigned for safe math operations
    unsig_a <= unsigned(in_a);
    unsig_b <= unsigned(in_b);

    -- =========================================================================
    -- ALU Execution Process
    -- =========================================================================
    process(unsig_a, unsig_b, alu_ctrl)
    begin
        case alu_ctrl is
            -- 1. Arithmetic Operations
            when OP_ADD | OP_ADDI => 
                temp_res <= unsig_a + unsig_b;
                
            when OP_SUB | OP_SUBI | OP_CMP => 
                -- CMP performs a subtraction to set the Zero Flag without writing back
                temp_res <= unsig_a - unsig_b;
                
            -- 2. Logical Operations
            when OP_AND => 
                temp_res <= unsig_a and unsig_b;
                
            when OP_OR => 
                temp_res <= unsig_a or unsig_b;
                
            when OP_XOR => 
                temp_res <= unsig_a xor unsig_b;
                
            -- 3. Shift Operations
            when OP_SHL => 
                -- Shift Left by 1 bit (Equivalent to mathematically multiplying by 2)
                temp_res <= shift_left(unsig_a, 1);
                
            when OP_SHR => 
                -- Shift Right by 1 bit (Equivalent to mathematically dividing by 2)
                temp_res <= shift_right(unsig_a, 1);
                
            -- 4. Default Pass-Through (Used for Loads/Stores and NOPs)
            when others => 
                -- By default, pass the second operand (B) through the ALU unmodified
                temp_res <= unsig_b;
        end case;
    end process;

    -- =========================================================================
    -- Output Assignments
    -- =========================================================================
    
    -- Convert the calculated unsigned result back to STD_LOGIC_VECTOR for the bus
    alu_res <= std_logic_vector(temp_res);
    
    -- Evaluate the Zero Flag asynchronously (Crucial for JZ conditional branches)
    zero_flag <= '1' when temp_res = x"00" else '0';

end Behavioral;