----------------------------------------------------------------------------------
-- Company:          VUT FEKT Brno
-- Engineer:         Libor Brostík, Jakub Dibelka
-- 
-- Create Date:      07.04.2026
-- Design Name:      color_control
-- Entity Name:      color_control
-- Project Name:     DE1_projekt_5
-- Target Devices:   Nexys A7 50T
-- Tool Versions:    Vivado 2025.2
-- 
-- Description: 
--    RGB color controller with adjustable brightness and cycle speed. 
--    Includes edge detection for button control, a color wheel (HSV-like) 
--    transition logic, and BCD output formatting for 7-segment displays.
--
-- Dependencies: 
--    None
--
-- License: MIT  
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity color_control is
    Port ( 
        clk          : in  STD_LOGIC;
        rst          : in  STD_LOGIC;
        en           : in  STD_LOGIC;
        up           : in  STD_LOGIC;
        down         : in  STD_LOGIC;
        mode_speed   : in  STD_LOGIC;
        mode_brig    : in  STD_LOGIC;
        value        : out STD_LOGIC_VECTOR (15 downto 0);
        red          : out STD_LOGIC_VECTOR (7 downto 0);
        green        : out STD_LOGIC_VECTOR (7 downto 0);
        blue         : out STD_LOGIC_VECTOR (7 downto 0)
    );
end color_control;

architecture Behavioral of color_control is

    type btn_state is (SET_BRIGHTNESS, SET_SPEED);
    signal MODE : btn_state := SET_BRIGHTNESS;

    signal brig_reg  : unsigned(3 downto 0)  := "0101"; -- Jas 5
    signal speed_reg : unsigned(3 downto 0)  := "0101"; -- Rychlost 5

    -- Edge Detection registry
    signal up_last, down_last        : STD_LOGIC := '0';  -- Pro UP a DOWN
    signal m_speed_last, m_brig_last : STD_LOGIC := '0';  -- Pro tlačítka L (brig) a R (speed)

    -- Barvy
    signal r_cnt : unsigned(7 downto 0) := x"FF"; 
    signal g_cnt : unsigned(7 downto 0) := x"00";
    signal b_cnt : unsigned(7 downto 0) := x"00";

    -- Časování (100 MHz)
    constant TICKS_PER_SEC : unsigned(19 downto 0) := to_unsigned(65000, 20); 
    signal delay_counter   : unsigned(23 downto 0) := (others => '0');

begin

    p_color_control : process(clk)
        variable target_delay : unsigned(23 downto 0);
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                MODE <= SET_BRIGHTNESS;
                brig_reg <= "0101";
                speed_reg <= "0101";
                r_cnt <= x"FF"; g_cnt <= x"00"; b_cnt <= x"00";
                delay_counter <= (others => '0');
                up_last <= '0'; down_last <= '0';
                m_speed_last <= '0'; m_brig_last <= '0';
                
            elsif (en = '1') then
                
                -- --- OVLÁDÁNÍ ( POMOCÍ DETEKCE HRANY) ---
                -- Výběr režimů
                if (mode_speed = '1' and m_speed_last = '0') then MODE <= SET_SPEED; end if;
                if (mode_brig = '1' and m_brig_last = '0')   then MODE <= SET_BRIGHTNESS; end if;

                -- Příčítání při zmáčknutí UP
                if (up = '1' and up_last = '0') then
                    if (MODE = SET_BRIGHTNESS and brig_reg < 10) then brig_reg <= brig_reg + 1;
                    elsif (MODE = SET_SPEED and speed_reg < 10)  then speed_reg <= speed_reg + 1;
                    end if;
                end if;

                -- Odečítání při zmáčknutí DOWN
                if (down = '1' and down_last = '0') then
                    if (MODE = SET_BRIGHTNESS and brig_reg > 0) then brig_reg <= brig_reg - 1;
                    elsif (MODE = SET_SPEED and speed_reg > 0)  then speed_reg <= speed_reg - 1;
                    end if;
                end if;
                
                -- Uložení poslední hodnoty pro porovnání s novou (detekce hrany)
                up_last <= up; down_last <= down;
                m_speed_last <= mode_speed; m_brig_last <= mode_brig;

                -- --- BAREVNÝ EFEKT (OBRÁCENÁ RYCHLOST) ---
                if (speed_reg > 0) then
                    --          1 -> (11-1) *TICKS => POMALÉ
                    --         10 -> (11-10)*TICKS => RYCHLÉ
                    target_delay := (to_unsigned(11, 4) - speed_reg) * TICKS_PER_SEC;
                    
                    if (delay_counter >= target_delay) then
                        delay_counter <= (others => '0');
                        if (r_cnt > 0 and b_cnt = 0) then
                            r_cnt <= r_cnt - 1; g_cnt <= g_cnt + 1;
                        elsif (g_cnt > 0 and r_cnt = 0) then
                            g_cnt <= g_cnt - 1; b_cnt <= b_cnt + 1;
                        elsif (b_cnt > 0 and g_cnt = 0) then
                            b_cnt <= b_cnt - 1; r_cnt <= r_cnt + 1;
                        end if;
                    else
                        delay_counter <= delay_counter + 1;
                    end if;
                else
                    delay_counter <= (others => '0'); -- Speed 0 = Pauza
                end if;
            end if;
        end if;
    end process;

    -- Aplikace jasu (pomocí násobení)
    p_brightness_apply : process(r_cnt, g_cnt, b_cnt, brig_reg)
        variable r_tmp, g_tmp, b_tmp : unsigned(11 downto 0); 
    begin
        -- Dočasné hodnoty velikost 12bit
        r_tmp := r_cnt * brig_reg;
        g_tmp := g_cnt * brig_reg;
        b_tmp := b_cnt * brig_reg;
        -- Oříznutí pouze 8 horních bitů
        red   <= std_logic_vector(r_tmp(11 downto 4));
        green <= std_logic_vector(g_tmp(11 downto 4));
        blue  <= std_logic_vector(b_tmp(11 downto 4));
    end process;

    -- Výstup na displej
    p_display_out : process(MODE, brig_reg, speed_reg)
        variable val : unsigned(3 downto 0);
        variable mode_prefix : std_logic_vector(3 downto 0);
        variable tens : std_logic_vector(3 downto 0);
        variable ones : std_logic_vector(3 downto 0);
    begin
        -- 1. Zjistíme aktuální hodnotu a znak módu
        if MODE = SET_BRIGHTNESS then 
            val := brig_reg; 
            mode_prefix := x"B"; -- Znak 'b'
        else 
            val := speed_reg; 
            mode_prefix := x"5"; -- Znak '5'
        end if;
        
        -- 2. Rozdělíme hodnotu na desítky a jednotky (BCD formát pro displej)
        if val = 10 then 
            tens := x"1";
            ones := x"0";
        else 
            tens := x"0";
            ones := std_logic_vector(val);
        end if;
        
        -- 3. Složíme 16bitové slovo: [Znak] [Mezera(F)] [Desítky] [Jednotky]
        -- Příklad pro speed 7: x"5" & x"F" & x"0" & x"7" -> 5F07
        value <= mode_prefix & x"F" & tens & ones;
    end process;

end Behavioral;