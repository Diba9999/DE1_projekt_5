----------------------------------------------------------------------------------
-- Company:          VUT FEKT Brno
-- Engineer:         Libor Brostík, Jakub Dibelka
-- 
-- Create Date:      08.03.2026
-- Design Name:      clk_en
-- Entity Name:      clk_en
-- Project Name:     DE1_projekt_5
-- Target Devices:   Nexys A7 50T
-- Tool Versions:    Vivado 2025.2
-- 
-- Description: 
--    Clock Enable pulse generator. The module counts rising edges of the 
--    input clock (clk) and generates a pulse of one clock cycle duration 
--    every G_MAX cycles.
--
-- Dependencies: 
--    None
--
-- License: MIT  
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_en is
    generic (
        G_MAX : positive := 5  -- Default number of clock cycles
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ce : out STD_LOGIC);
end clk_en;

architecture behavioral of clk_en is

    -- Internal counter
    signal sig_cnt : integer range 0 to G_MAX-1;

begin

    -- Count clock pulses and generate a one-clock-cycle enable pulse
    process (clk) is
    begin
        if rising_edge(clk) then  -- Synchronous process
            if rst = '1' then     -- High-active reset
                ce      <= '0';   -- Reset output
                sig_cnt <= 0;     -- Reset internal counter

            elsif sig_cnt = G_MAX-1 then
                -- TODO: Set output pulse and reset internal counter
                sig_cnt <= 0;
                ce      <= '1';
            else
                -- TODO: Clear output and increment internal counter
                sig_cnt <= sig_cnt + 1;
                ce      <= '0';
                
            end if;  -- End if for reset/check
        end if;      -- End if for rising_edge
    end process;

end architecture behavioral;