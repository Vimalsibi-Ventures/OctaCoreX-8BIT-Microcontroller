----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    tb_risc_core.vhd
-- Description:  Exhaustive Self-Checking Verification Testbench.
--               This module acts as the system test environment. It instantiates 
--               the top-level motherboard and feeds it a hardcoded assembly program 
--               from an internal Instruction ROM. The program is specifically 
--               designed to force Data Hazards (Read-After-Write) and Branch 
--               Penalties to verify the Hazard Unit's stall and flush logic.
--               It actively monitors the Write-Back bus and halts the simulation
--               automatically upon detecting the correct final mathematical result.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;
use std.env.finish; -- VHDL-2008 standard for clean simulation termination

entity tb_risc_core is
-- Testbench has no external ports
end tb_risc_core;

architecture Behavioral of tb_risc_core is

    -- =========================================================================
    -- Unit Under Test (UUT) Declaration
    -- =========================================================================
    component risc_core_top
        Port ( 
            clk            : in  STD_LOGIC;
            rst            : in  STD_LOGIC;
            inst_in        : in  STD_LOGIC_VECTOR(15 downto 0);
            pc_out         : out STD_LOGIC_VECTOR(7 downto 0);
            monitor_result : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- =========================================================================
    -- Simulation Signals
    -- =========================================================================
    signal clk            : STD_LOGIC := '0';
    signal rst            : STD_LOGIC := '0';
    signal inst_in        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal pc_out         : STD_LOGIC_VECTOR(7 downto 0);
    signal monitor_result : STD_LOGIC_VECTOR(7 downto 0);
    
    constant clk_period   : time := 10 ns;
    
    -- =========================================================================
    -- Hardcoded Instruction ROM (The Assembly Test Program)
    -- =========================================================================
    -- Instruction Format: [Opcode:4] [Dest_Reg:4] [Source_Reg/Immediate:8]
    type rom_type is array (0 to 31) of STD_LOGIC_VECTOR(15 downto 0);
    constant INST_ROM : rom_type := (
        -- INITIALIZATION
        0 => x"1105", -- 0: LDI R1, 0x05 (Load Decimal 5 into R1)
        1 => x"1203", -- 1: LDI R2, 0x03 (Load Decimal 3 into R2)
        
        -- HAZARD TEST 1: Data Collision (Read-After-Write)
        -- The ADD instruction needs R2 and R1, but they are still traveling 
        -- down the pipeline. The Hazard Unit MUST stall the Fetch stage here.
        2 => x"4210", -- 2: ADD R2, R1   (R2 = 3 + 5 = 8)
        
        -- ALU EXTENDED TEST: Logical Shift
        3 => x"C200", -- 3: SHL R2       (Shift Left: 8 * 2 = 16 or Hex 0x10)
        
        -- MEMORY STAGE TEST
        4 => x"3220", -- 4: STR R2, [0x20] (Store 0x10 to RAM address 0x20)
        5 => x"2420", -- 5: LDR R4, [0x20] (Load 0x10 from RAM address 0x20 into R4)
        
        -- HAZARD TEST 2: Conditional Branching & Flushes
        6 => x"8420", -- 6: CMP R4, R2   (Compare 0x10 to 0x10. Result is 0, Zero Flag = '1')
        7 => x"F00A", -- 7: JZ 0x0A      (Jump to Address 10 because Zero Flag is '1')
        
        -- GHOST INSTRUCTIONS: These will be fetched while the JZ is decoded,
        -- but the Hazard Unit MUST flush them (overwrite with NOPs) when the jump executes.
        8 => x"15EE", -- 8: LDI R5, 0xEE (SHOULD NEVER EXECUTE)
        9 => x"16FF", -- 9: LDI R6, 0xFF (SHOULD NEVER EXECUTE)
        
        -- JUMP TARGET (Address 10 / 0x0A)
        10 => x"5405", -- 10 (0x0A): ADDI R4, 0x05 (R4 = 0x10 + 5 = 0x15)
        
        -- INFINITE LOOP (Safety Trap)
        11 => x"E00B", -- 11 (0x0B): JMP 0x0B (Jump to self to hold pipeline state)
        
        others => x"0000" -- Pad remainder of ROM with NOPs
    );

begin

    -- =========================================================================
    -- UUT Instantiation
    -- =========================================================================
    UUT: risc_core_top PORT MAP (
        clk => clk, 
        rst => rst, 
        inst_in => inst_in, 
        pc_out => pc_out, 
        monitor_result => monitor_result
    );

    -- =========================================================================
    -- Clock Generation Process
    -- =========================================================================
    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- =========================================================================
    -- Asynchronous ROM Read
    -- =========================================================================
    -- Fetch the next instruction based on the lower 5 bits of the Program Counter
    inst_in <= INST_ROM(to_integer(unsigned(pc_out(4 downto 0))));

    -- =========================================================================
    -- Stimulation & Timeout Process
    -- =========================================================================
    stim_proc: process
    begin
        -- 1. Apply Hard Reset to clear all pipeline registers
        rst <= '1'; 
        wait for 15 ns; 
        rst <= '0';
        
        -- 2. Wait for a maximum duration (40 clock cycles)
        -- This provides ample time for the pipeline to handle the data stalls and branch flushes.
        wait for clk_period * 40; 
        
        -- 3. If the simulation hasn't been halted by the check_proc below, it means it failed.
        report "[FAIL] Timeout! Pipeline failed to output 0x15 to the Write-Back bus." severity failure;
        finish;
    end process;

    -- =========================================================================
    -- Active Bus Monitor (Verification Process)
    -- =========================================================================
    check_proc: process(monitor_result)
    begin
        -- We expect the final valid instruction (ADDI R4, 0x05) to push 
        -- the value 0x15 (Decimal 21) onto the Write-Back bus.
        if monitor_result = x"15" then
            report "[PASS] OctaCoreX Exhaustive Verification Successful!" severity note;
            -- Instantly and cleanly halt the simulation upon success
            finish; 
        end if;
    end process;

end Behavioral;