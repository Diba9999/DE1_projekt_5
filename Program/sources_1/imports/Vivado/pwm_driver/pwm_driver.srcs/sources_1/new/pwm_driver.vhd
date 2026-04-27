----------------------------------------------------------------------------------
-- Company:          VUT FEKT Brno
-- Engineer:         Libor Brostík, Jakub Dibelka
-- 
-- Create Date:      08.04.2026
-- Design Name:      pwm_driver
-- Entity Name:      pwm_driver
-- Project Name:     DE1_projekt_5
-- Target Devices:   Nexys A7 50T
-- Tool Versions:    Vivado 2025.2
-- 
-- Description: 
--    3-channel PWM (Pulse Width Modulation) driver for RGB LED control. 
--    Uses a shared free-running counter and independent comparators 
--    to generate duty cycles for Red, Green, and Blue channels.
--
-- Dependencies: 
--    None
--
-- License: MIT  
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; -- Knihovna pro práci s čísly a aritmetikou    

entity pwm_driver is
    Generic (   
            pwm_bits : integer := 8  
    );
    Port ( 
            clk    : in  STD_LOGIC;
            en     : in  STD_LOGIC;
            rst    : in  STD_LOGIC;
              
            red    : in  STD_LOGIC_VECTOR (7 downto 0);
            green  : in  STD_LOGIC_VECTOR (7 downto 0);
            blue   : in  STD_LOGIC_VECTOR (7 downto 0);
            
            led_r  : out STD_LOGIC;
            led_g  : out STD_LOGIC;
            led_b  : out STD_LOGIC);
end pwm_driver;

architecture Behavioral of pwm_driver is
    -- Hlavní PWM čítač (typu unsigned pro aritmetiku)
    signal pwm_cnt : unsigned(pwm_bits - 1 downto 0);

    signal duty_r : unsigned(7 downto 0);
    signal duty_g : unsigned(7 downto 0);
    signal duty_b : unsigned(7 downto 0);
begin
    duty_r <= unsigned(red);
    duty_g <= unsigned(green);
    duty_b <= unsigned(blue);
    
process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pwm_cnt <= (others => '0');
                led_r   <= '0';
                led_g   <= '0';
                led_b   <= '0';
                
            else
                pwm_cnt <= pwm_cnt + 1;
                -- Komparátor Červená
                if pwm_cnt < duty_r then 
                    led_r <= '1'; 
                else 
                    led_r <= '0'; 
                end if;
                -- Komparátor Zelená
                if pwm_cnt < duty_g then 
                    led_g <= '1'; 
                else 
                    led_g <= '0'; 
                end if;
                -- Komparátor Modrá
                if pwm_cnt < duty_b then 
                    led_b <= '1'; 
                else 
                    led_b <= '0'; 
                end if;
            end if;
        end if;
    end process;  
end Behavioral;