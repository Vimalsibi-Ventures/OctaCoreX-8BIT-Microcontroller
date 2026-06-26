library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package core_pkg is
    -- System Constants
    constant DATA_WIDTH : integer := 8;
    constant INST_WIDTH : integer := 16;
    constant REG_ADDR_WIDTH : integer := 4;

    -- ISA Opcode Definitions (4-bit)
    constant OP_NOP   : std_logic_vector(3 downto 0) := "0000"; -- Bubble/Stall
    constant OP_LDI   : std_logic_vector(3 downto 0) := "0001"; -- Load Immediate
    constant OP_LDR   : std_logic_vector(3 downto 0) := "0010"; -- Load from RAM
    constant OP_STR   : std_logic_vector(3 downto 0) := "0011"; -- Store to RAM
    
    constant OP_ADD   : std_logic_vector(3 downto 0) := "0100"; -- Add Register
    constant OP_ADDI  : std_logic_vector(3 downto 0) := "0101"; -- Add Immediate
    constant OP_SUB   : std_logic_vector(3 downto 0) := "0110"; -- Subtract Register
    constant OP_SUBI  : std_logic_vector(3 downto 0) := "0111"; -- Subtract Immediate
    
    constant OP_CMP   : std_logic_vector(3 downto 0) := "1000"; -- Compare Register
    constant OP_AND   : std_logic_vector(3 downto 0) := "1001"; -- Bitwise AND
    constant OP_OR    : std_logic_vector(3 downto 0) := "1010"; -- Bitwise OR
    constant OP_XOR   : std_logic_vector(3 downto 0) := "1011"; -- Bitwise XOR
    
    constant OP_SHL   : std_logic_vector(3 downto 0) := "1100"; -- Shift Left
    constant OP_SHR   : std_logic_vector(3 downto 0) := "1101"; -- Shift Right
    constant OP_JMP   : std_logic_vector(3 downto 0) := "1110"; -- Unconditional Jump
    constant OP_JZ    : std_logic_vector(3 downto 0) := "1111"; -- Jump if Zero
    
end package core_pkg;