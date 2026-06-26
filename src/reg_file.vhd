library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;

entity reg_file is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        we          : in  STD_LOGIC; -- Write Enable
        read_addr_1 : in  STD_LOGIC_VECTOR (REG_ADDR_WIDTH-1 downto 0);
        read_addr_2 : in  STD_LOGIC_VECTOR (REG_ADDR_WIDTH-1 downto 0);
        write_addr  : in  STD_LOGIC_VECTOR (REG_ADDR_WIDTH-1 downto 0);
        write_data  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        
        read_data_1 : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        read_data_2 : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
    );
end reg_file;

architecture Behavioral of reg_file is
    -- Create an array of 16 registers, each 8 bits wide
    type reg_array is array (0 to (2**REG_ADDR_WIDTH)-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal registers : reg_array := (others => (others => '0'));
begin
    
    -- Synchronous Write & Asynchronous Reset
    process(clk, rst)
    begin
        if rst = '1' then
            -- Clear all registers to zero
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            -- Write data on the clock edge if enabled
            if we = '1' then
                registers(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    -- Asynchronous Reads (Data flows out immediately when address changes)
    read_data_1 <= registers(to_integer(unsigned(read_addr_1)));
    read_data_2 <= registers(to_integer(unsigned(read_addr_2)));

end Behavioral;