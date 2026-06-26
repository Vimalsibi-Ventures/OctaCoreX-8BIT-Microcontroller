library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all; -- Import our custom definitions

entity alu_8bit is
    Port (
        in_a      : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        in_b      : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        alu_ctrl  : in  STD_LOGIC_VECTOR (3 downto 0); -- Driven by Control Unit
        alu_res   : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        zero_flag : out STD_LOGIC
    );
end alu_8bit;

architecture Behavioral of alu_8bit is
    signal temp_res : unsigned(DATA_WIDTH-1 downto 0);
    signal unsig_a  : unsigned(DATA_WIDTH-1 downto 0);
    signal unsig_b  : unsigned(DATA_WIDTH-1 downto 0);
begin
    -- Convert std_logic_vector to unsigned for safe arithmetic
    unsig_a <= unsigned(in_a);
    unsig_b <= unsigned(in_b);

    process(unsig_a, unsig_b, alu_ctrl)
    begin
        case alu_ctrl is
            -- Arithmetic
            when OP_ADD | OP_ADDI => 
                temp_res <= unsig_a + unsig_b;
            when OP_SUB | OP_SUBI | OP_CMP => 
                temp_res <= unsig_a - unsig_b;
                
            -- Logical
            when OP_AND => 
                temp_res <= unsig_a and unsig_b;
            when OP_OR => 
                temp_res <= unsig_a or unsig_b;
            when OP_XOR => 
                temp_res <= unsig_a xor unsig_b;
                
            -- Shifting (Shift in_a by 1 bit)
            when OP_SHL => 
                temp_res <= shift_left(unsig_a, 1);
            when OP_SHR => 
                temp_res <= shift_right(unsig_a, 1);
                
            -- Default pass-through for Loads/Stores
            when others => 
                temp_res <= unsig_b;
        end case;
    end process;

    -- Drive physical output pins
    alu_res <= std_logic_vector(temp_res);
    
    -- Set Zero Flag (Crucial for JZ instruction)
    zero_flag <= '1' when temp_res = x"00" else '0';

end Behavioral;