----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    reg_file.vhd
-- Description:  16-Depth General Purpose Register (GPR) File with Internal Forwarding.
--               Features two asynchronous read ports for immediate operand
--               fetching in the Decode (ID) stage, and one synchronous write port
--               for the Write-Back (WB) stage.
--               Includes a bypass (write-through) multiplexer to solve RAW data
--               hazards when reading and writing to the same register in one cycle.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;

entity reg_file is
    Port (
        clk         : in  STD_LOGIC;                                     -- System Clock
        rst         : in  STD_LOGIC;                                     -- Asynchronous Reset
        we          : in  STD_LOGIC;                                     -- Write Enable from Write-Back Stage
        read_addr_1 : in  STD_LOGIC_VECTOR (REG_ADDR_WIDTH-1 downto 0);  -- Source Register 1 Address (4-bit)
        read_addr_2 : in  STD_LOGIC_VECTOR (REG_ADDR_WIDTH-1 downto 0);  -- Source Register 2 Address (4-bit)
        write_addr  : in  STD_LOGIC_VECTOR (REG_ADDR_WIDTH-1 downto 0);  -- Destination Register Address (4-bit)
        write_data  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);      -- Data to Write (8-bit)
        
        read_data_1 : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);      -- Output Data 1
        read_data_2 : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)       -- Output Data 2
    );
end reg_file;

architecture Behavioral of reg_file is
    -- Define an array of 16 registers, each 8 bits wide
    type reg_array is array (0 to (2**REG_ADDR_WIDTH)-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    
    -- Initialize all registers to 0x00 to prevent 'U' (Uninitialized) states in simulation
    signal registers : reg_array := (others => (others => '0'));
begin
    
    -- =========================================================================
    -- Synchronous Write & Asynchronous Reset Process
    -- =========================================================================
    process(clk, rst)
    begin
        -- Hardware Reset: Instantly clears all 16 registers to zero
        if rst = '1' then
            registers <= (others => (others => '0'));
            
        -- Clocked Write: Saves data on the rising edge if Write Enable (we) is high
        elsif rising_edge(clk) then
            if we = '1' then
                -- Convert the 4-bit write address to an integer to index the array
                registers(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Asynchronous Read with Internal Forwarding (Bypass)
    -- =========================================================================
    -- If the Write-Back stage is writing to the exact same register 
    -- that the Decode stage is trying to read, we bypass the physical register 
    -- array and forward the 'write_data' straight to the output to prevent a stall.
    
    read_data_1 <= write_data when (we = '1' and write_addr = read_addr_1) else 
                   registers(to_integer(unsigned(read_addr_1)));
                   
    read_data_2 <= write_data when (we = '1' and write_addr = read_addr_2) else 
                   registers(to_integer(unsigned(read_addr_2)));

end Behavioral;