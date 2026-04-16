----------------------------------------------------------------------------------
-- Company: VUT Fekt
-- Engineer: Bolek Polívka, Dibelka
-- 
-- Create Date: 09.04.2026 14:13:02
-- Design Name: RGB_Mood_Lamp_toplevel
-- Module Name: RGB_Mood_Lamp_top - Behavioral
-- Project Name: DE1_projekt_5
-- Target Devices: Nexys A7-50T
-- Tool Versions: 
-- Description: Top level structural design for RGB Mood Lamp
-- 
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

    component color_fsm is
        Port ( clk          : in  STD_LOGIC;
               rst          : in  STD_LOGIC;
               en           : in  STD_LOGIC;
               up           : in  STD_LOGIC;
               down         : in  STD_LOGIC;
               mode_speed   : in  STD_LOGIC;
               mode_brig    : in  STD_LOGIC;
               value        : out STD_LOGIC_VECTOR (7 downto 0);
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
               data  : in  STD_LOGIC_VECTOR (7 downto 0);
               seg   : out STD_LOGIC_VECTOR (6 downto 0);
               anode : out STD_LOGIC_VECTOR (7 downto 0)
               );
    end component;           

    -- ==========================================
    -- Propojovací signály
    -- ==========================================
    
    -- Signály z debounce filtru
    signal btnu_deb, btnd_deb, btnl_deb, btnr_deb : STD_LOGIC;
    
    -- Signály clock enable
    signal ce_fsm    : STD_LOGIC;
    signal ce_pwm    : STD_LOGIC;
    
    -- Datové signály barev (FSM -> PWM)
    signal red_sig   : STD_LOGIC_VECTOR (7 downto 0);
    signal green_sig : STD_LOGIC_VECTOR (7 downto 0);
    signal blue_sig  : STD_LOGIC_VECTOR (7 downto 0);
    
    -- Informační signály pro 7-segment (zatím nevyvedené ven z topu)
    signal sig_data  : STD_LOGIC_VECTOR (7 downto 0);

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
            btn1_state => btnu_deb,
            btn2_state => btnd_deb,
            btn3_state => btnl_deb,
            btn4_state => btnr_deb
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

    -- Clock enable pro FSM
    CLK_EN_FSM_inst: clk_en
        Port Map (
            clk => clk,
            rst => btnc,
            ce  => ce_fsm
        );

    -- Clock enable pro PWM
    CLK_EN_PWM_inst: clk_en
        Port Map (
            clk => clk,
            rst => btnc,
            ce  => ce_pwm
        );

    -- Konečný automat pro barvy a logiku aplikace
    COLOR_FSM_inst: color_fsm
        Port Map (
            clk         => clk,
            rst         => btnc,
            en          => ce_fsm,
            up          => btnu_deb,
            down        => btnd_deb,
            mode_speed  => btnr_deb,
            mode_brig   => btnl_deb,
            value       => sig_data, -- Signál pro 7-segment
            red         => red_sig,
            green       => green_sig,
            blue        => blue_sig
        );

    -- PWM Driver pro RGB LED
    PWM_DRIVER_inst: pwm_driver
        Generic Map (
            pwm_bits => 8
        )
        Port Map (
            clk   => clk,
            en    => ce_pwm,
            rst   => btnc,
            red   => red_sig,
            green => green_sig,
            blue  => blue_sig,
            led_r => led17_r,
            led_g => led17_g,
            led_b => led17_b
        );

end Behavioral;