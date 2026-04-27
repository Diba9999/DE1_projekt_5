# RGB MOOD LAMP VYTVOŘENÉ NA DESCE NEXYS A7-50T
## Cíl projektu
Cílem projektu je návrh a implementace ovladače pro RGB lampu na desce Nexys A7-50T. Lampa umožňuje uživateli měnit parametry lampy pomocí tlačítek na desce. Aktualní nastavení a jeho hodnoty bude možné sledovat na 7-segmentovém displeji.

### Členové týmu
  #### Jakub Dibelka
  * návrh a tvorba programu
  #### Libor Brostík
  * finální dokumentace projektu (README.md) a tvorba programu

### Základní funkce
* **Výběr barvy:** Možnost přepínat mezi předdefinovanými barvami
* **Úprava svítivosti:** Zvyšení nebo snížení intenzity světla pomocí PWM
* **Úprava rychlosti:** Snižování nebo zvyšování rychlosti pulzování nebo prolínání barev
* **Zobrazení hodnot pomoci 7-segmentového displeje:** Podle nastavení můžeme na displeji sledovat aktualní hodnotu svítivosti/rychlosti
* **Reset:** Návrat parametrů do původního stavu

### Obsah
* [Cíl projektu](#cíl-projektu)
* [Lab1: Architecture](#lab1-architecture)
* [Lab2: Unit Design](#lab2-unit-design)
* [Lab3: Integration](#lab3-integration)

## Lab1: Architecture
### Blokové schéma
Návrh blokového schématu pro naší aplikaci

![Screenshot of a block desing](img/Design_v4.drawio.png)

### Příprava .XDC souboru
Pro správné propojení kódu VHDL s fyzickým hardwarem desky [Nexys A7-50T](nexys.xdc) využijeme constraints soubor (.xdc). V něm namapujeme tyto porty:
#### Tlačítka
* **BTNC:** Tlačítko na reset
* **BTNL:** Přepnutí do režimu nastavení svítivosti (Brightness)
* **BTNR:** Přepnutí do režimu nastavení rychlosti (Speed)
* **BTNU/BTND:** Zvyšování / snižování hodnoty pro dané nastavení
#### RGB
* **LED17_R, LED17_G, LED17_B:** Pro ovládání jednotlivých barev
#### RGB
* **SEG:** Zobrazení hodnot pro aktuální nastavení

## Lab2: Unit Design
### Debounce
Mechanická tlačítka při stlačení nebo uvolnění generují sérii rychlých stavových změn (zákmitů). Abychom předešli tomu, že systém vyhodnotí jeden stisk jako několikanásobné zmáčknutí, využíváme modul Debounce. Ten vzorkuje vstupní signál a na výstup propustí stabilní logickou hodnotu až ve chvíli, kdy se vstupní signál ustálí po určitou dobu.

| Port name | Direction | Type | Description |
| :--- | :---: | :--- | :--- |
| `clk` | in | `std_logic` | Main clock |
| `rst` | in | `std_logic` | High-active synchronous reset |
| `btn1` | in | `std_logic` | Input for button 1 |
| `btn2` | in | `std_logic` | Input for button 2 |
| `btn3` | in | `std_logic` | Input for button 3 |
| `btn4` | in | `std_logic` | Input for button 4 |
| `btn1_state` | out | `std_logic` | State of button 1 |
| `btn2_state` | out | `std_logic` | State of button 2 |
| `btn3_state` | out | `std_logic` | State of button 3 |
| `btn4_state` | out | `std_logic` | State of button 4 |

Pomocí debounce ošetříme 4 tlačítka BTNU, BTND, BTNL a BTNR proti zákmitům.
#### Debounce VHDL
<details>
<summary>Kód zde</summary>

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity debounce is
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
end debounce;

architecture Behavioral of debounce is
    ----------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------
    constant C_SHIFT_LEN : positive := 4;       -- Debounce history
    constant C_MAX       : positive := 200_000; -- Sampling period
                                                -- 2 for simulation
                                                -- 200_000 (2 ms) for implementation !!!

    ----------------------------------------------------------------
    -- Internal signals
    ----------------------------------------------------------------
    signal ce_sample  : std_logic;
    signal sync0      : std_logic_vector(3 downto 0);
    signal sync1      : std_logic_vector(3 downto 0);
    signal debounced  : std_logic_vector(3 downto 0);
    signal delayed    : std_logic_vector(3 downto 0);
    signal btn_in_vec : std_logic_vector(3 downto 0);  -- Seskupení vstupu do vektoru
    
    -- registr je pole/matice od 3 do 0 |  naplněn std_logic_vector dané velikosti
    type shift_reg_array is array (3 downto 0) of std_logic_vector(C_SHIFT_LEN-1 downto 0);
    --   nazev signálu | tvorba objektu signálu | := počáteční hodnota | nastav řadky(nastav v řádku '0')   
    signal shift_reg : shift_reg_array:= (others => (others => '0'));

    ----------------------------------------------------------------
    -- Component declaration for clock enable
    ----------------------------------------------------------------
    component clk_en is
        generic ( G_MAX : positive );
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            ce  : out std_logic
        );
    end component clk_en;
      
    
begin
    btn_in_vec <= btn4 & btn3 & btn2 & btn1;
    
    ----------------------------------------------------------------
    -- Clock enable instance
    ----------------------------------------------------------------
    clock_0 : clk_en
        generic map ( G_MAX => C_MAX )
        port map (
            clk => clk,
            rst => rst,
            ce  => ce_sample
        );

    ----------------------------------------------------------------
    -- Synchronizer + debounce
    ----------------------------------------------------------------
    p_debounce : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync0     <= (others => '0');
                sync1     <= (others => '0');
                shift_reg <= (others => (others => '0')); -- Restart celého pole
                debounced <= (others => '0');
                delayed   <= (others => '0');

            else
                -- Input synchronizer
                sync1 <= sync0;
                sync0 <= btn_in_vec;
                
                for i in 0 to 3 loop
                    -- Sample only when enable pulse occurs
                    if ce_sample = '1' then
    
                        -- Shift registru pro každé tlačítko zvlášť
                        shift_reg(i) <= shift_reg(i)(C_SHIFT_LEN-2 downto 0) & sync1(i);
    
                        -- Kontrola jestli jsou všechny bity (i) vstupu '1'
                        if shift_reg(i) = (shift_reg(i)'range => '1') then
                            debounced(i) <= '1';
                        -- Kontrola jestli jsou všechny bity (i) vstupu '1'
                        elsif shift_reg(i) = (shift_reg(i)'range => '0') then
                            debounced(i) <= '0';
                        end if;
    
                    end if;
                end loop;

                -- One clock delayed output
                delayed <= debounced;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------
    -- Outputs - Mapování vnitřního vektoru zpět na individuální  výstupy 
    ----------------------------------------------------------------------
    btn1_state <= debounced(0);
    btn2_state <= debounced(1);
    btn3_state <= debounced(2);
    btn4_state <= debounced(3);

end Behavioral;
```
</details>

#### Debounce Testbench
<p>
  <img src="img/debounce_tbv2.png" width="800"><br>
  <em><a href="testbenches/debounce_tb.vhd">VHDL Testbench</a></em>
</p>

Kód pro debounce testbench [zde](testbenches/debounce_tb.vhd)

### Color Control
Tento modul tvoří "mozek" celé aplikace. Umožňuje měnit barvu, svítivost a rychlost RGB LED.
| Port name | Direction | Type | Description |
| :--- | :---: | :--- | :--- |
| `clk` | in | `std_logic` | Main clock |
| `en` | in | `std_logic` | Clock enable |
| `rst` | in | `std_logic` | High-active synchronous reset |
| `up` | in | `std_logic` | Increment command from debounced button |
| `down` | in | `std_logic` | Decrement command from debounced button |
| `mode_brig` | in | `std_logic` | Mode selector for brightness adjustment |
| `mode_speed` | in | `std_logic` | Mode selector for speed adjustment |
| `value` | out | `std_logic_vector (6 downto 0)` | Value of speed/brig. for 7-segment driver|
| `red` | out | `std_logic_vector (8 downto 0)` | Calculated Red value for the PWM driver |
| `green` | out | `std_logic_vector (8 downto 0)` | Calculated Green value for the PWM driver |
| `blue` | out | `std_logic_vector (8 downto 0)` | Calculated Blue value for the PWM driver |


#### Color Control VHDL
<details>
<summary>Kód zde</summary>

```vhdl
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
        value        : out STD_LOGIC_VECTOR (7 downto 0);
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
    begin
        if MODE = SET_BRIGHTNESS then val := brig_reg; else val := speed_reg; end if;
        
        if val = 10 then value <= x"10";  -- Při val = 0 zapsání x10, aby se nezobarzilo A 
        else value <= "0000" & std_logic_vector(val);
        end if;
    end process;

end Behavioral;
```
</details>

#### Color Control Testbench
<p>
  <img src="img/color_fsm_tb.png" width="800"><br>
  <em><a href="testbenches/color_fsm_tb.vhd">VHDL Testbench</a></em>
</p>

> [!NOTE]
> Testbench není finální (může se ještě změnit).

### RGB PWM Driver
Pro ovládání výsledné barvy a svítivosti lampy slouží tento modul. Přijímá číselné hodnoty a převádí je na tři nezávislé signály pulzně šířkové modulace (PWM). Pro PWM modul zadefinujeme tyto I/O porty
| Port name | Direction | Type | Description |
| :--- | :---: | :--- | :--- |
| `clk` | in | `std_logic` | Main clock |
| `en` | in | `std_logic` | Clock enable |
| `rst` | in | `std_logic` | High-active synchronous reset |
| `red` | in | `std_logic_vector (7 downto 0)` | Input value determining value for Red LED |
| `green` | in | `std_logic_vector (7 downto 0)` | Input value determining value for Green LED |
| `blue` | in | `std_logic_vector (7 downto 0)` | Input value determining value for Blue LED |
| `led_r` | out | `std_logic` | PWM output signal for the Red LED channel |
| `led_g` | out | `std_logic` | PWM output signal for the Green LED channel |
| `led_b` | out | `std_logic` | PWM output signal for the Blue LED channel |


#### PWM Driver VHDL
<details>
<summary>Kód zde</summary>

```vhdl
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
```
</details>

#### PWM Driver Testbench
<p>
  <img src="img/pwm_driver_tbv2.png" width="800"><br>
  <em><a href="testbenches/pwm_driver_tb.vhd">VHDL Testbench</a></em>
</p>

## Lab3: Integration
### 7-segment display
Pro lepší přehled nad aktuálním nastavením byl dodatečně přidán modul pro 7-segmentový displej. Díky němu můžeme sledovat aktualní hodnoty dle vybraného nastavení
#### 7-segment VHDL
<details>
<summary>Kód zde</summary>
  
```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity display_driver is
    Port ( clk   : in  STD_LOGIC;
           rst   : in  STD_LOGIC;
           data  : in  STD_LOGIC_VECTOR (7 downto 0);
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
    signal sig_digit : std_logic_vector(0 downto 0);
    signal sig_bin   : std_logic_vector(3 downto 0);


begin

    ------------------------------------------------------------------------
    -- Clock enable generator for refresh timing
    ------------------------------------------------------------------------
    clock_0 : clk_en
        generic map ( G_MAX => 160_000 )  -- Adjust for flicker-free multiplexing
        port map (                   -- For simulation: 16
            clk => clk,              -- For implementation: 1_600_000
            rst => rst,
            ce  => sig_en
        );

    ------------------------------------------------------------------------
    -- N-bit counter for digit selection
    ------------------------------------------------------------------------
    counter_0 : counter
        generic map ( G_BITS => 1 )
        port map (
            clk => clk,
            rst => rst,
            en  => sig_en,
            cnt => sig_digit
        );

    ------------------------------------------------------------------------
    -- Digit select
    ------------------------------------------------------------------------
    sig_bin <= data(3 downto 0) when sig_digit = "0" else
               data(7 downto 4);

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
            when "0" =>
                anode <= "11111110";  -- Right digit active
            when "1" =>
                anode <= "11111101";  -- Left digit active
            
            when others =>
                anode <= "11111111";  -- All off
        end case;
    end process;

end Behavioral;
```
</details>

### Top-Level
Je to hlavní entita, která je spojnice mezi programem a hardwarem. V této entitě se inicializují vstupy a výstupy všech modulů.

#### Top-Level VHDL
<details>
<summary>Kód zde</summary>
  
```vhdl
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
    signal sig_btnu, sig_btnd, sig_btnl, sig_btnr : STD_LOGIC;  
    
    -- Signály clock enable
    signal sig_ce_ctrl   : STD_LOGIC;
    signal sig_ce_pwm    : STD_LOGIC;
    
    -- Datové signály barev (CONTROL -> PWM)
    signal sig_red   : STD_LOGIC_VECTOR (7 downto 0);
    signal sig_green : STD_LOGIC_VECTOR (7 downto 0);
    signal sig_blue  : STD_LOGIC_VECTOR (7 downto 0);
    
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
```
</details>

## Lab4: Tuning
Zaměřili na ladění kódu, identifikaci a následnou opravu chyb programů.

## Lab5: Completion

