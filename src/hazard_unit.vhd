library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hazard_unit is
    Port (
        -- Inputs from Decode Stage (Current Instruction)
        id_rs_addr      : in STD_LOGIC_VECTOR(3 downto 0); -- Source Register
        id_rd_addr      : in STD_LOGIC_VECTOR(3 downto 0); -- Dest Register (sometimes read in STR/Math)
        
        -- Inputs from Older Instructions (Currently in EX or MEM stages)
        ex_reg_write    : in STD_LOGIC;
        ex_dest_addr    : in STD_LOGIC_VECTOR(3 downto 0);
        mem_reg_write   : in STD_LOGIC;
        mem_dest_addr   : in STD_LOGIC_VECTOR(3 downto 0);
        
        -- Branch control from Execute Stage
        branch_taken    : in STD_LOGIC; 
        
        -- Outputs to Control the Pipeline Registers
        pc_write        : out STD_LOGIC; -- '0' pauses the Program Counter
        if_id_write     : out STD_LOGIC; -- '0' pauses the Fetch register
        control_mux_sel : out STD_LOGIC; -- '1' injects NOPs into ID/EX register
        flush           : out STD_LOGIC  -- '1' clears pipeline after a jump
    );
end hazard_unit;

architecture Behavioral of hazard_unit is
    signal data_hazard : STD_LOGIC;
begin

    -- 1. Detect Data Hazards
    -- If EX or MEM stage is going to write to a register that the ID stage is trying to read...
    process(id_rs_addr, id_rd_addr, ex_reg_write, ex_dest_addr, mem_reg_write, mem_dest_addr)
    begin
        data_hazard <= '0';
        
        if (ex_reg_write = '1' and (ex_dest_addr = id_rs_addr or ex_dest_addr = id_rd_addr)) then
            data_hazard <= '1';
        elsif (mem_reg_write = '1' and (mem_dest_addr = id_rs_addr or mem_dest_addr = id_rd_addr)) then
            data_hazard <= '1';
        end if;
    end process;

    -- 2. Output Hazard Mitigation Signals
    -- If there is a data hazard, we STALL (Pause PC and Fetch, inject NOP).
    pc_write        <= '0' when data_hazard = '1' else '1';
    if_id_write     <= '0' when data_hazard = '1' else '1';
    control_mux_sel <= '1' when data_hazard = '1' else '0'; 
    
    -- 3. Branch Flush Logic
    -- If a jump is taken, clear the wrong instructions that were just fetched.
    flush           <= '1' when branch_taken = '1' else '0';

end Behavioral;