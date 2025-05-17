library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_top is
end tb_top;

architecture Behavioral of tb_top is

    signal clk     : STD_LOGIC := '0';
    signal rst     : STD_LOGIC := '0';
    signal led_out : STD_LOGIC;

    component top
        Port ( 
            clk     : in  STD_LOGIC;
            rst     : in  STD_LOGIC;
            led_out : out STD_LOGIC
        );
    end component;

begin

    -- TODO:

end Behavioral;

