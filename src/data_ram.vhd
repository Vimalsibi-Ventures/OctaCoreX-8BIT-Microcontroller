library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.core_pkg.all;

entity data_ram is
    Port (
        clk      : in  STD_LOGIC;
        we       : in  STD_LOGIC; -- Write Enable
        re       : in  STD_LOGIC; -- Read Enable
        addr     : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        data_in  : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
        data_out : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0)
    );
end data_ram;

architecture Behavioral of data_ram is
    -- 256 x 8-bit Memory Array
    type ram_type is array (0 to (2**DATA_WIDTH)-1) of STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal ram_block : ram_type := (others => (others => '0'));
begin

    -- Synchronous Read and Write
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram_block(to_integer(unsigned(addr))) <= data_in;
            end if;
            
            if re = '1' then
                data_out <= ram_block(to_integer(unsigned(addr)));
            else
                data_out <= (others => '0'); -- Default zero output to prevent floating wires
            end if;
        end if;
    end process;

end Behavioral;