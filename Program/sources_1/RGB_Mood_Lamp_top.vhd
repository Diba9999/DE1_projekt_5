----------------------------------------------------------------------------------
-- Company:          VUT FEKT Brno
-- Engineer:         Libor Brostík, Jakub Dibelka
-- 
-- Create Date:      09.04.2026
-- Design Name:      RGB_Mood_Lamp_top
-- Entity Name:      RGB_Mood_Lamp_top
-- Project Name:     DE1_projekt_5
-- Target Devices:   Nexys A7 50T
-- Tool Versions:    Vivado 2025.2
-- 
-- Description: 
--    Top-level entity for RGB Mood Lamp project. Integrates debounced button 
--    inputs, color/mode logic, PWM drivers for RGB LED, and 7-segment display output.
--
-- Dependencies: 
--    Debounce, Clk_En, Display_Driver, Color_Control, PWM_Driver
--
-- License: MIT  
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RGB_Mood_Lamp_top is
    Port ( clk     : in STD_LOGIC;
           btnc    : in STD_LOGIC; -- Slouží jako RST
           btnu    : in STD_LOGIC;
           btnd    : in STD_LOGIC;
           btnl    : in STD_LOGIC;
           btnr    : in STD_LOGIC;
           led17_r : out STD_LOGIC;
           led17_g : out STD_LOGIC;
           led17_b : out STD_LOGIC;
           seg     : out STD_LOGIC_VECTOR(6 downto 0);
           an      : out STD_LOGIC_VECTOR(7 downto 0)
          );
end RGB_Mood_Lamp_top;

architecture Behavioral of RGB_Mood_Lamp_top is

    -- ==========================================
    -- Deklarace komponent (podle README.md)
    -- ==========================================
    
    component debounce is
        Port ( clk        : in STD_LOGIC;
               rst        : in STD_LOGIC;
               btn1       : in STD_LOGIC;
               btn2       : in STD_LOGIC;
               btn3       : in STD_LOGIC;
               btn4       : in STD_LOGIC;
               btn1_state : out STD_LOGIC;
               btn2_state : out STD_LOGIC;
               btn3_state : out STD_LOGIC;
               btn4_state : out STD_LOGIC
               );
    end component;

    component clk_en is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               ce  : out STD_LOGIC);
    end component;

    component color_control is
        Port ( clk          : in  STD_LOGIC;
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
    end component;

    component pwm_driver is
        Generic (   
               pwm_bits : integer := 8  
        );
        Port ( clk    : in  STD_LOGIC;
               en     : in  STD_LOGIC;
               rst    : in  STD_LOGIC;
               red    : in  STD_LOGIC_VECTOR (7 downto 0);
               green  : in  STD_LOGIC_VECTOR (7 downto 0);
               blue   : in  STD_LOGIC_VECTOR (7 downto 0);
               led_r  : out STD_LOGIC;
               led_g  : out STD_LOGIC;
               led_b  : out STD_LOGIC);
    end component;
    
    component display_driver is
        Port ( clk   : in  STD_LOGIC;
               rst   : in  STD_LOGIC;
               data  : in  STD_LOGIC_VECTOR (15 downto 0);
               seg   : out STD_LOGIC_VECTOR (6 downto 0);
               anode : out STD_LOGIC_VECTOR (7 downto 0)
               );
    end component;           

    -- ==========================================
    -- Propojovací signály
    -- ==========================================
    
    -- Signály z debounce filtru
    signal sig_btnu, sig_btnd, sig_btnl, sig_btnr : STD_LOGIC;  
    
    -- Signály clock enable
    signal sig_ce_ctrl   : STD_LOGIC;
    signal sig_ce_pwm    : STD_LOGIC;
    
    -- Datové signály barev (CONTROL -> PWM)
    signal sig_red   : STD_LOGIC_VECTOR (7 downto 0);
    signal sig_green : STD_LOGIC_VECTOR (7 downto 0);
    signal sig_blue  : STD_LOGIC_VECTOR (7 downto 0);
    
    -- Informační signály pro 7-segment (zatím nevyvedené ven z topu)
    signal sig_data  : STD_LOGIC_VECTOR (15 downto 0);

begin

    -- ==========================================
    -- Instancování a mapování komponent
    -- ==========================================

    -- Tlačítkový debounce
    DEBOUNCE_inst: debounce
        Port Map (
            clk        => clk,
            rst        => btnc,
            btn1       => btnu,
            btn2       => btnd,
            btn3       => btnl,
            btn4       => btnr,
            btn1_state => sig_btnu,
            btn2_state => sig_btnd,
            btn3_state => sig_btnl,
            btn4_state => sig_btnr
        );
        
    -- Display_driver
    DISPLAY_DRIVER_inst: display_driver
        Port Map (
            clk   => clk,
            rst   => btnc,
            data  => sig_data,
            seg   => seg,
            anode => an
        );

    -- Clock enable pro Color_contro
    CLK_EN_CTRL_inst: clk_en
        Port Map (
            clk => clk,
            rst => btnc,
            ce  => sig_ce_ctrl
        );

    -- Clock enable pro PWM
    CLK_EN_PWM_inst: clk_en
        Port Map (
            clk => clk,
            rst => btnc,
            ce  => sig_ce_pwm
        );

    -- Konečný automat pro barvy a logiku aplikace
    COLOR_CONTROL_inst: color_control
        Port Map (
            clk         => clk,
            rst         => btnc,
            en          => sig_ce_ctrl,
            up          => sig_btnu,
            down        => sig_btnd,
            mode_speed  => sig_btnr,
            mode_brig   => sig_btnl,
            value       => sig_data, -- Signál pro 7-segment
            red         => sig_red,
            green       => sig_green,
            blue        => sig_blue
        );

    -- PWM Driver pro RGB LED
    PWM_DRIVER_inst: pwm_driver
        Generic Map (
            pwm_bits => 8
        )
        Port Map (
            clk   => clk,
            en    => sig_ce_pwm,
            rst   => btnc,
            red   => sig_red,
            green => sig_green,
            blue  => sig_blue,
            led_r => led17_r,
            led_g => led17_g,
            led_b => led17_b
        );

end Behavioral;