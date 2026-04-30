library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity color_control_tb is
    
end color_control_tb;

architecture sim of color_control_tb is

    -- Signály pro propojení s komponentou
    signal clk_tb          : std_logic := '0';
    signal rst_tb          : std_logic := '0';
    signal en_tb           : std_logic := '0';
    signal up_tb           : std_logic := '0';
    signal down_tb         : std_logic := '0';
    signal mode_speed_tb   : std_logic := '0';
    signal mode_brig_tb    : std_logic := '0';
    signal value_tb        : std_logic_vector(15 downto 10) := (others => '0');
    signal red_tb, green_tb, blue_tb : std_logic_vector(7 downto 0);

    -- Zde musí být plný vektor, pokud má port 16 bitů:
    signal value_full_tb   : std_logic_vector(15 downto 0);

    -- Perioda hodin (100 MHz -> 10 ns)
    constant CLK_PERIOD : time := 1 ns;

    procedure press_btn(signal btn : out std_logic; signal clk : in std_logic) is
    begin
        wait until falling_edge(clk); -- Počkáme na sestupnou hranu
        btn <= '1';                   
        wait until falling_edge(clk); 
        btn <= '0';                   
        wait for 100 ns;              -- Krátká pauza
    end procedure;

begin

    uut: entity work.color_control
        port map (
            clk         => clk_tb,
            rst         => rst_tb,
            en          => en_tb,
            up          => up_tb,
            down        => down_tb,
            mode_speed  => mode_speed_tb,
            mode_brig   => mode_brig_tb,
            value       => value_full_tb,
            red         => red_tb,
            green       => green_tb,
            blue        => blue_tb
        );

    -- Generátor hodin
    clk_process : process
    begin
        while now <= 5 ms loop 
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait; -- Zastaví generování hodin a tím i celou simulaci
    end process;

    -- Stimulus proces: Řídí události v čase
    stim_proc: process
    begin
        -- 1. Reset systému (0 - 150 ns)
        rst_tb <= '1';
        wait for 50 ns;
        rst_tb <= '0';
        en_tb  <= '1';
        wait for 100 ns;

        -- 2. Zvýšení jasu (Čas ~ 0.0 ms)
        press_btn(mode_brig_tb, clk_tb);
        press_btn(up_tb, clk_tb);
        press_btn(up_tb, clk_tb);
        
        -- Čekáme 1 milisekundu a sledujeme průběh barev
        wait for 1 ms;

        -- 3. Snížení rychlosti (Čas ~ 1.0 ms)
        press_btn(mode_speed_tb, clk_tb);
        press_btn(down_tb, clk_tb);
        press_btn(down_tb, clk_tb);
        press_btn(down_tb, clk_tb);
        
        wait for 1 ms;

        -- 4. Snížení jasu (Čas ~ 2.0 ms)
        press_btn(mode_brig_tb, clk_tb);
        for i in 1 to 4 loop
            press_btn(down_tb, clk_tb);
        end loop;

        wait for 1 ms;

        -- 5. Zvýšení rychlosti na maximum (Čas ~ 3.0 ms)
        press_btn(mode_speed_tb, clk_tb);
        for i in 1 to 6 loop
            press_btn(up_tb, clk_tb);
        end loop;

        wait; 
    end process;

end sim;
