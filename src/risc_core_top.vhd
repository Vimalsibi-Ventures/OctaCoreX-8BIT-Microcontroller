----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    risc_core_top.vhd
-- Description:  Top-Level "Motherboard" Entity.
--               Instantiates and wires together the ALU, Register File, Data RAM, 
--               Control Unit, and Hazard Unit. It explicitly defines the D-Flip-Flop
--               Pipeline Boundary Registers to separate the 5 hardware stages.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;

entity risc_core_top is
    Port (
        clk            : in  STD_LOGIC;                                -- System Clock
        rst            : in  STD_LOGIC;                                -- Hard Reset
        inst_in        : in  STD_LOGIC_VECTOR(INST_WIDTH-1 downto 0);  -- 16-bit Instruction from ROM
        pc_out         : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);  -- Program Counter to ROM
        monitor_result : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)   -- Write-Back Bus for Testbench
    );
end risc_core_top;

architecture Structural of risc_core_top is

    -- =========================================================================
    -- Component Declarations
    -- =========================================================================
    component alu_8bit
        Port ( in_a, in_b : in STD_LOGIC_VECTOR(7 downto 0); alu_ctrl : in STD_LOGIC_VECTOR(3 downto 0); alu_res : out STD_LOGIC_VECTOR(7 downto 0); zero_flag : out STD_LOGIC);
    end component;

    component reg_file
        Port ( clk, rst, we : in STD_LOGIC; read_addr_1, read_addr_2, write_addr : in STD_LOGIC_VECTOR(3 downto 0); write_data : in STD_LOGIC_VECTOR(7 downto 0); read_data_1, read_data_2 : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component data_ram
        Port ( clk, we, re : in STD_LOGIC; addr, data_in : in STD_LOGIC_VECTOR(7 downto 0); data_out : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component control_unit
        Port ( opcode : in STD_LOGIC_VECTOR(3 downto 0); alu_src : out STD_LOGIC; alu_ctrl : out STD_LOGIC_VECTOR(3 downto 0); mem_read, mem_write, branch, reg_write, mem_to_reg : out STD_LOGIC);
    end component;

    component hazard_unit
        Port ( id_rs_addr, id_rd_addr, ex_dest_addr, mem_dest_addr : in STD_LOGIC_VECTOR(3 downto 0); ex_reg_write, mem_reg_write, branch_taken : in STD_LOGIC; pc_write, if_id_write, control_mux_sel, flush : out STD_LOGIC);
    end component;

    -- =========================================================================
    -- Pipeline Registers & Internal Signals
    -- =========================================================================
    signal pc_reg : unsigned(DATA_WIDTH-1 downto 0) := (others => '0');
    signal if_id_inst : STD_LOGIC_VECTOR(INST_WIDTH-1 downto 0) := (others => '0');
    
    signal id_ex_reg_data1, id_ex_reg_data2, id_ex_imm : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal id_ex_dest_addr : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 downto 0);
    signal id_ex_alu_ctrl : STD_LOGIC_VECTOR(3 downto 0);
    signal id_ex_alu_src, id_ex_mem_read, id_ex_mem_write, id_ex_branch, id_ex_reg_write, id_ex_mem_to_reg : STD_LOGIC;
    
    signal ex_mem_alu_res, ex_mem_write_data : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal ex_mem_dest_addr : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 downto 0);
    signal ex_mem_mem_read, ex_mem_mem_write, ex_mem_branch, ex_mem_reg_write, ex_mem_mem_to_reg : STD_LOGIC;
    
    signal mem_wb_ram_data, mem_wb_alu_res : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal mem_wb_dest_addr : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 downto 0);
    signal mem_wb_reg_write, mem_wb_mem_to_reg : STD_LOGIC;

    signal wire_hazard_stall, wire_hazard_flush, wire_pc_write, wire_if_id_write : STD_LOGIC;
    signal ctrl_alu_src, ctrl_mem_read, ctrl_mem_write, ctrl_branch, ctrl_reg_write, ctrl_mem_to_reg : STD_LOGIC;
    signal ctrl_alu_ctrl : STD_LOGIC_VECTOR(3 downto 0);
    
    signal id_opcode, id_rd, id_rs : STD_LOGIC_VECTOR(3 downto 0);
    signal id_imm, wire_reg_data1, wire_reg_data2, wire_alu_b_in, wire_alu_res, wire_ram_out, wire_wb_data : STD_LOGIC_VECTOR(7 downto 0);
    signal wire_alu_zero, branch_eval : STD_LOGIC;

begin

    id_opcode <= if_id_inst(15 downto 12); id_rd <= if_id_inst(11 downto 8);
    id_rs <= if_id_inst(7 downto 4); id_imm <= if_id_inst(7 downto 0);

    U_CONTROL: control_unit PORT MAP (
        opcode => id_opcode, alu_src => ctrl_alu_src, alu_ctrl => ctrl_alu_ctrl, 
        mem_read => ctrl_mem_read, mem_write => ctrl_mem_write, branch => ctrl_branch, 
        reg_write => ctrl_reg_write, mem_to_reg => ctrl_mem_to_reg
    );

    U_HAZARD: hazard_unit PORT MAP (
        id_rs_addr => id_rs, id_rd_addr => id_rd, 
        ex_dest_addr => id_ex_dest_addr, mem_dest_addr => ex_mem_dest_addr,
        ex_reg_write => id_ex_reg_write, mem_reg_write => ex_mem_reg_write,
        branch_taken => branch_eval, pc_write => wire_pc_write, 
        if_id_write => wire_if_id_write, control_mux_sel => wire_hazard_stall, flush => wire_hazard_flush
    );

    U_REG_FILE: reg_file PORT MAP (
        clk => clk, rst => rst, we => mem_wb_reg_write,
        read_addr_1 => id_rd, read_addr_2 => id_rs, 
        write_addr => mem_wb_dest_addr, write_data => wire_wb_data,
        read_data_1 => wire_reg_data1, read_data_2 => wire_reg_data2
    );

    wire_alu_b_in <= id_ex_imm when id_ex_alu_src = '1' else id_ex_reg_data2;
    
    U_ALU: alu_8bit PORT MAP (
        in_a => id_ex_reg_data1, in_b => wire_alu_b_in, alu_ctrl => id_ex_alu_ctrl, 
        alu_res => wire_alu_res, zero_flag => wire_alu_zero
    );
    
    U_DATA_RAM: data_ram PORT MAP (
        clk => clk, we => ex_mem_mem_write, re => ex_mem_mem_read, 
        addr => ex_mem_alu_res, data_in => ex_mem_write_data, data_out => wire_ram_out
    );

    wire_wb_data <= mem_wb_ram_data when mem_wb_mem_to_reg = '1' else mem_wb_alu_res;
    
    branch_eval <= '1' when (id_ex_branch = '1' and (id_ex_alu_ctrl = OP_JMP or (id_ex_alu_ctrl = OP_JZ and id_ex_reg_data1 = x"00"))) else '0';

    pc_out <= std_logic_vector(pc_reg); 
    monitor_result <= wire_wb_data;

    process(clk, rst)
    begin
        if rst = '1' then
            pc_reg <= (others => '0'); if_id_inst <= (others => '0');
            id_ex_reg_write <= '0'; ex_mem_reg_write <= '0'; mem_wb_reg_write <= '0';
        elsif rising_edge(clk) then
            if wire_hazard_flush = '1' then pc_reg <= unsigned(wire_alu_res);
            elsif wire_pc_write = '1' then pc_reg <= pc_reg + 1; end if;

            if wire_hazard_flush = '1' then if_id_inst <= (others => '0');
            elsif wire_if_id_write = '1' then if_id_inst <= inst_in; end if;

            if wire_hazard_stall = '1' or wire_hazard_flush = '1' then
                id_ex_reg_write <= '0'; id_ex_mem_write <= '0'; id_ex_branch <= '0';
            else
                id_ex_reg_data1 <= wire_reg_data1; id_ex_reg_data2 <= wire_reg_data2; id_ex_imm <= id_imm;
                id_ex_dest_addr <= id_rd; id_ex_alu_ctrl <= ctrl_alu_ctrl; id_ex_alu_src <= ctrl_alu_src;
                id_ex_mem_read <= ctrl_mem_read; id_ex_mem_write <= ctrl_mem_write; id_ex_branch <= ctrl_branch;
                id_ex_reg_write <= ctrl_reg_write; id_ex_mem_to_reg <= ctrl_mem_to_reg;
            end if;

            ex_mem_alu_res <= wire_alu_res; ex_mem_write_data <= id_ex_reg_data1;
            ex_mem_dest_addr <= id_ex_dest_addr; ex_mem_mem_read <= id_ex_mem_read; ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_branch <= id_ex_branch; ex_mem_reg_write <= id_ex_reg_write; ex_mem_mem_to_reg <= id_ex_mem_to_reg;

            mem_wb_ram_data <= wire_ram_out; mem_wb_alu_res <= ex_mem_alu_res;
            mem_wb_dest_addr <= ex_mem_dest_addr; mem_wb_reg_write <= ex_mem_reg_write; mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end if;
    end process;
end Structural;