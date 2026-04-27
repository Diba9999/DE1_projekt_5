----------------------------------------------------------------------------------
-- Company:          VUT FEKT Brno
-- Engineer:         Libor Brostík, Jakub Dibelka
-- 
-- Create Date:      19.04.2026
-- Design Name:      RGB_Mood_Lamp_top
-- Entity Name:      display_driver
-- Project Name:     DE1_projekt_5
-- Target Devices:   Nexys A7 50T
-- Tool Versions:    Vivado 2025.2
-- 
-- Description: 
--    Driver pro 4 pozice na sedmisegmentovém displeji (zobrazuje 16bitová data)
--
-- Dependencies: 
--    Clock_En, Counter, bin2seg
--
-- License: MIT   
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity display_driver is
    Port ( clk   : in  STD_LOGIC;
           rst   : in  STD_LOGIC;
           data  : in  STD_LOGIC_VECTOR (15 downto 0); -- Změněno na 16 bitů (4 znaky)
           seg   : out STD_LOGIC_VECTOR (6 downto 0);
           anode : out STD_LOGIC_VECTOR (7 downto 0)
           );
end display_driver;

architecture Behavioral of display_driver is

    -- Component declaration for clock enable
    component clk_en is
        generic ( G_MAX : positive );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            ce  : out std_logic
        );
    end component clk_en;
 
    -- Component declaration for binary counter
    component counter is
        generic ( G_BITS : positive );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            en  : in  std_logic;
            cnt : out std_logic_vector(G_BITS - 1 downto 0)
        );
    end component counter;
 
    component bin2seg is 
        port ( bin : in  STD_LOGIC_VECTOR (3 downto 0);
               seg : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component bin2seg;
 
    -- Internal signals
    signal sig_en    : std_logic;
    signal sig_digit : std_logic_vector(1 downto 0); -- Zvětšeno na 2 bity (stavy 00, 01, 10, 11)
    signal sig_bin   : std_logic_vector(3 downto 0);

begin

    ------------------------------------------------------------------------
    -- Clock enable generator for refresh timing
    ------------------------------------------------------------------------
    clock_0 : clk_en
        generic map ( G_MAX => 160_000 )  -- Adjust for flicker-free multiplexing
        port map (                   
            clk => clk,              
            rst => rst,
            ce  => sig_en
        );

    ------------------------------------------------------------------------
    -- N-bit counter for digit selection
    ------------------------------------------------------------------------
    counter_0 : counter
        generic map ( G_BITS => 2 ) -- Čítá 4 stavy (pro 4 displeje)
        port map (
            clk => clk,
            rst => rst,
            en  => sig_en,
            cnt => sig_digit
        );

    ------------------------------------------------------------------------
    -- Digit select (Výběr aktuálních 4 bitů ze 16)
    ------------------------------------------------------------------------
    with sig_digit select sig_bin <=
        data(3 downto 0)   when "00", -- Znak na pozici AN0 (Jednotky)
        data(7 downto 4)   when "01", -- Znak na pozici AN1 (Desítky)
        data(11 downto 8)  when "10", -- Znak na pozici AN2 (Mezera)
        data(15 downto 12) when "11", -- Znak na pozici AN3 (Znak módu)
        "0000" when others;

    ------------------------------------------------------------------------
    -- 7-segment decoder
    ------------------------------------------------------------------------
    decoder_0 : bin2seg
        port map (
            bin => sig_bin,
            seg => seg   
        );

    ------------------------------------------------------------------------
    -- Anode select process
    ------------------------------------------------------------------------
    p_anode_select : process (sig_digit) is
    begin
        case sig_digit is
            when "00" =>
                anode <= "11111110";  -- Zapne úplně pravý displej AN0
            when "01" =>
                anode <= "11111101";  -- Zapne druhý displej zprava AN1
            when "10" =>
                anode <= "11111111";  -- Zapne třetí displej zprava AN2
            when "11" =>
                anode <= "11110111";  -- Zapne čtvrtý displej zprava AN3
            when others =>
                anode <= "11111111";  -- Vše vypnuto
        end case;
    end process;

end Behavioral;