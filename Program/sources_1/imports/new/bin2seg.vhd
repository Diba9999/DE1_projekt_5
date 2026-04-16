----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/04/2026 06:17:13 PM
-- Design Name: 
-- Module Name: bin2seg - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
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

entity bin2seg is
    Port ( bin : in STD_LOGIC_VECTOR (3 downto 0);
           seg : out STD_LOGIC_VECTOR (6 downto 0));
end bin2seg;

architecture Behavioral of bin2seg is

begin

p_7seg_decoder : process (bin) is
begin
    case bin is
        when x"0" =>
            seg <= b"000_0001";
        when x"1" =>
            seg <= b"100_1111";
        when x"2" =>
            seg <= b"001_0010";
            
        -- TODO: Complete settings for 3, 4, 5, 6
        when x"3" =>
            seg <= b"000_0110";
        when x"4" =>
            seg <= b"100_1100";
        when x"5" =>
            seg <= b"010_0100";
        when x"6" =>
            seg <= b"010_0000";

        when x"7" =>
            seg <= b"000_1111";
        when x"8" =>
            seg <= b"000_0000";
        when x"9" =>
            seg <= b"000_0100";

        -- TODO: Complete settings for A, b, C, d
        when x"A" =>
            seg <= b"000_1000";
        when x"b" =>
            seg <= b"110_0000";
        when x"C" =>
            seg <= b"011_0001";
        when x"d" =>
            seg <= b"100_0010";
        

        when x"E" =>
            seg <= b"011_0000";
        when x"F" =>
            seg <= b"011_1000";

        -- Default case (e.g., for undefined values)
        when others =>
            seg <= b"111_1111";  -- All segments off
    end case;
end process p_7seg_decoder;

end Behavioral;
