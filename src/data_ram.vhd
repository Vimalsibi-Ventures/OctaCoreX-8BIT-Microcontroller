----------------------------------------------------------------------------------
-- Project Name: OctaCoreX - 8-Bit RISC Microcontroller
-- File Name:    data_ram.vhd
-- Description:  Single-Port Data Random Access Memory (RAM).
--               Contains 256 bytes of addressable memory (8-bit addressing).
--               Features a synchronous write port for the Memory (MEM) stage, 
--               and an ASYNCHRONOUS read port to ensure data is stable on the bus 
--               before the next pipeline register captures it.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;

entity data_ram is
    Port (
        clk      : in  STD_LOGIC;                                -- System Clock
        we       : in  STD_LOGIC;                                -- Write Enable
        re       : in  STD_LOGIC;                                -- Read Enable
        addr     : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- 8-bit Memory Address
        data_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0); -- 8-bit Data to Write
        data_out : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)  -- 8-bit Data Read Output
    );
end data_ram;

architecture Behavioral of data_ram is
    -- Define the memory structure: 256 rows (2^8), each 8 bits wide
    type ram_type is array (0 to (2**DATA_WIDTH)-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    
    -- Initialize memory with zeros to prevent uninitialized states ('U') during simulation
    signal ram_block : ram_type := (others => (others => '0'));
begin

    -- =========================================================================
    -- Synchronous Write Process
    -- =========================================================================
    process(clk)
    begin
        -- Writes only occur precisely on the rising edge of the clock
        if rising_edge(clk) then
            if we = '1' then
                -- Convert the 8-bit address to an integer to index the memory array
                ram_block(to_integer(unsigned(addr))) <= data_in;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- Asynchronous Read Assignment
    -- =========================================================================
    -- If this was synchronous, it would create a race condition where the MEM/WB 
    -- pipeline register ticks at the exact same moment the RAM updates, causing 
    -- the register to accidentally capture the old/empty data.
    
    data_out <= ram_block(to_integer(unsigned(addr))) when re = '1' else (others => '0');

end Behavioral;