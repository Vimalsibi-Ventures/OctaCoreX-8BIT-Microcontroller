library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;
use std.env.finish; 

entity tb_risc_core is
end tb_risc_core;

architecture Behavioral of tb_risc_core is

    component risc_core_top
        Port ( clk, rst : in STD_LOGIC; inst_in : in STD_LOGIC_VECTOR(15 downto 0); pc_out, monitor_result : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    signal clk, rst : STD_LOGIC := '0';
    signal inst_in : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal pc_out, monitor_result : STD_LOGIC_VECTOR(7 downto 0);
    constant clk_period : time := 10 ns;
    
    -- Expanded ROM to hold the rigorous test sequence
    type rom_type is array (0 to 31) of STD_LOGIC_VECTOR(15 downto 0);
    constant INST_ROM : rom_type := (
        0 => x"1105", -- 0: LDI R1, 0x05 (Load 5)
        1 => x"1203", -- 1: LDI R2, 0x03 (Load 3)
        
        -- HAZARD TEST 1: Data Collision
        2 => x"4210", -- 2: ADD R2, R1  (R2 = 3 + 5 = 8). Pipeline MUST stall here!
        
        -- ALU EXTENDED TEST: Shift Left
        3 => x"C200", -- 3: SHL R2      (R2 = 8 << 1 = 16 or 0x10)
        
        -- MEMORY TEST
        4 => x"3220", -- 4: STR R2, [0x20] (Store 0x10 to RAM address 0x20)
        5 => x"2420", -- 5: LDR R4, [0x20] (Load 0x10 from RAM to R4)
        
        -- CONDITIONAL BRANCH TEST (CMP + JZ)
        6 => x"8420", -- 6: CMP R4, R2  (0x10 - 0x10 = 0. Zero Flag becomes 1)
        7 => x"F00A", -- 7: JZ 0x0A     (Jump if Zero to address 10). MUST flush next instructions!
        
        -- THESE SHOULD BE FLUSHED
        8 => x"15EE", -- 8: LDI R5, 0xEE (NEVER EXECUTED)
        9 => x"16FF", -- 9: LDI R6, 0xFF (NEVER EXECUTED)
        
        -- TARGET OF JUMP
        10 => x"5405", -- 10 (0x0A): ADDI R4, 0x05 (R4 = 0x10 + 5 = 0x15)
        11 => x"E00B", -- 11 (0x0B): JMP 0x0B (Infinite Trap to hold state)
        
        others => x"0000"
    );

begin
    UUT: risc_core_top PORT MAP (clk => clk, rst => rst, inst_in => inst_in, pc_out => pc_out, monitor_result => monitor_result);

    clk_process :process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Fetch based on PC (using 5 bits to support 32 instructions)
    inst_in <= INST_ROM(to_integer(unsigned(pc_out(4 downto 0))));

    stim_proc: process
    begin
        rst <= '1'; wait for 15 ns; rst <= '0';
        wait for clk_period * 40; 
        report "[FAIL] Timeout! Pipeline failed to output 0x15 to Write-Back bus." severity failure;
        finish;
    end process;

    check_proc: process(monitor_result)
    begin
        -- We expect the final instruction (ADDI R4, 0x05) to output 0x15 (Decimal 21)
        if monitor_result = x"15" then
            report "[PASS] OctaCoreX Exhaustive Verification Successful!" severity note;
            finish; 
        end if;
    end process;

end Behavioral;