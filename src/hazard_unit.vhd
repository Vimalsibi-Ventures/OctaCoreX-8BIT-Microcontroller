----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    hazard_unit.vhd
-- Description:  Pipeline Hazard Mitigation Unit (The Traffic Cop).
--               Monitors the instruction currently being decoded (ID stage) and 
--               checks if it requires data from older instructions currently in 
--               the Execute (EX) or Memory (MEM) stages. 
--               If a data collision (Read-After-Write hazard) is detected, it 
--               stalls the pipeline. If a branch is taken, it flushes the pipeline.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hazard_unit is
    Port (
        -- Inputs from Decode (ID) Stage (Current Instruction)
        id_rs_addr      : in STD_LOGIC_VECTOR(3 downto 0); -- Source Register Address
        id_rd_addr      : in STD_LOGIC_VECTOR(3 downto 0); -- Dest Register Address (sometimes read in STR/Math)
        
        -- Inputs from Older Instructions (Currently in EX or MEM stages)
        ex_reg_write    : in STD_LOGIC;                    -- Is EX stage going to write to a register?
        ex_dest_addr    : in STD_LOGIC_VECTOR(3 downto 0); -- Which register is EX writing to?
        mem_reg_write   : in STD_LOGIC;                    -- Is MEM stage going to write to a register?
        mem_dest_addr   : in STD_LOGIC_VECTOR(3 downto 0); -- Which register is MEM writing to?
        
        -- Branch control from Execute (EX) Stage
        branch_taken    : in STD_LOGIC;                    -- '1' if a JMP or JZ was successfully evaluated
        
        -- Outputs to Control the Pipeline Registers
        pc_write        : out STD_LOGIC;                   -- '0' pauses the Program Counter (Stall)
        if_id_write     : out STD_LOGIC;                   -- '0' pauses the Fetch register (Stall)
        control_mux_sel : out STD_LOGIC;                   -- '1' injects NOPs into ID/EX register (Bubble)
        flush           : out STD_LOGIC                    -- '1' clears IF/ID pipeline after a jump
    );
end hazard_unit;

architecture Behavioral of hazard_unit is
    signal data_hazard : STD_LOGIC;
begin

    -- =========================================================================
    -- Data Hazard Detection Process (Read-After-Write)
    -- =========================================================================
    -- If the EX or MEM stage is currently processing an instruction that will 
    -- write to a register that the current ID stage is trying to read, we MUST 
    -- halt the ID stage until the write is complete.
    process(id_rs_addr, id_rd_addr, ex_reg_write, ex_dest_addr, mem_reg_write, mem_dest_addr)
    begin
        data_hazard <= '0'; -- Default: No hazard
        
        -- 1. Check EX Stage Hazard
        if (ex_reg_write = '1' and (ex_dest_addr = id_rs_addr or ex_dest_addr = id_rd_addr)) then
            data_hazard <= '1';
            
        -- 2. Check MEM Stage Hazard
        elsif (mem_reg_write = '1' and (mem_dest_addr = id_rs_addr or mem_dest_addr = id_rd_addr)) then
            data_hazard <= '1';
        end if;
    end process;

    -- =========================================================================
    -- Hazard Mitigation Signal Routing
    -- =========================================================================
    
    -- If there is a data hazard, STALL the front of the pipeline.
    -- '0' disables the register writes, locking the PC and IF/ID in place.
    pc_write        <= '0' when data_hazard = '1' else '1';
    if_id_write     <= '0' when data_hazard = '1' else '1';
    
    -- If there is a data hazard, inject a BUBBLE (NOP) into the back of the pipeline.
    -- '1' triggers the multiplexer in the top-level file to zero out control signals.
    control_mux_sel <= '1' when data_hazard = '1' else '0'; 
    
    -- 3. Branch Flush Logic
    -- If a jump is taken, clear the wrong instructions that were just fetched.
    flush           <= '1' when branch_taken = '1' else '0';

end Behavioral;