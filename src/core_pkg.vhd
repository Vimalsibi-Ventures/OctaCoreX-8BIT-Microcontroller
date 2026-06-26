----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    core_pkg.vhd
-- Description:  Global package definition for the OctaCoreX architecture. 
--               This file contains system-wide constants, bit-widths, and 
--               the explicit mapping for the 4-bit Opcode Instruction Set 
--               Architecture (ISA).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package core_pkg is

    -- =========================================================================
    -- System Constants & Bus Widths
    -- =========================================================================
    constant DATA_WIDTH     : integer := 8;  -- 8-bit Datapath (ALU, RAM, Registers)
    constant INST_WIDTH     : integer := 16; -- 16-bit Instruction Word [Opcode:4][Dest:4][Imm:8]
    constant REG_ADDR_WIDTH : integer := 4;  -- 4-bit Register Addressing (Supports 16 GPRs)

    -- =========================================================================
    -- Instruction Set Architecture (ISA) Opcode Definitions
    -- =========================================================================
    
    -- 1. Control & System Instructions
    constant OP_NOP   : std_logic_vector(3 downto 0) := "0000"; -- No Operation (Used for pipeline bubbles)
    
    -- 2. Data Memory & Transfer Instructions
    constant OP_LDI   : std_logic_vector(3 downto 0) := "0001"; -- Load Immediate to Register
    constant OP_LDR   : std_logic_vector(3 downto 0) := "0010"; -- Load from Data RAM to Register
    constant OP_STR   : std_logic_vector(3 downto 0) := "0011"; -- Store from Register to Data RAM
    
    -- 3. Arithmetic Instructions
    constant OP_ADD   : std_logic_vector(3 downto 0) := "0100"; -- Add Register to Register
    constant OP_ADDI  : std_logic_vector(3 downto 0) := "0101"; -- Add Immediate to Register
    constant OP_SUB   : std_logic_vector(3 downto 0) := "0110"; -- Subtract Register from Register
    constant OP_SUBI  : std_logic_vector(3 downto 0) := "0111"; -- Subtract Immediate from Register
    constant OP_CMP   : std_logic_vector(3 downto 0) := "1000"; -- Compare (Subtract without writing back, sets Zero Flag)
    
    -- 4. Logical & Bitwise Instructions
    constant OP_AND   : std_logic_vector(3 downto 0) := "1001"; -- Bitwise AND
    constant OP_OR    : std_logic_vector(3 downto 0) := "1010"; -- Bitwise OR
    constant OP_XOR   : std_logic_vector(3 downto 0) := "1011"; -- Bitwise XOR
    constant OP_SHL   : std_logic_vector(3 downto 0) := "1100"; -- Logical Shift Left (Multiply by 2)
    constant OP_SHR   : std_logic_vector(3 downto 0) := "1101"; -- Logical Shift Right (Divide by 2)
    
    -- 5. Control Flow / Branching Instructions
    constant OP_JMP   : std_logic_vector(3 downto 0) := "1110"; -- Unconditional Jump to Address
    constant OP_JZ    : std_logic_vector(3 downto 0) := "1111"; -- Jump to Address IF Zero Flag = '1'
    
end package core_pkg;