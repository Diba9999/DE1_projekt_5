# RGB MOOD LAMP VYTVOŘENÉ NA DESCE NEXYS A7-50T
### Členové týmu
  #### Jakub Dibelka
  * návrh a tvorba programu
  #### Libor Brostík
  * finální dokumentace projektu (README.md) a tvorba programu
  
### Obsah
* [Cíl projektu](#cíl-projektu)

## Cíl projektu
Cílem projektu je návrh a implementace ovladače pro RGB lampu na desce Nexys A7-50T. Lampa umožňuje uživateli měnit parametry lampy pomocí tlačítek na desce
### Základní funkce
* **Výběr barvy:** Možnost přepínat mezi předdefinovanými barvami
* **Úprava svítivosti:** Zvyšení nebo snížení intenzity světla pomocí PWM
* **Úprava rychlosti:** Snižování nebo zvyšování rychlosti pulzování nebo prolínání barev
* **Reset:** Návrat parametrů do původního stavu

## Lab1: Architecture
### Blokové schéma
Návrh blokového schématu pro naší aplikaci (není finální)

![Screenshot of a block desing](img/Design_schematic.png)
### Příprava .XDC souboru
Pro správné propojení kódu VHDL s fyzickým hardwarem desky [Nexys A7-50T](nexys.xdc) využijeme constraints soubor (.xdc). V něm namapujeme tyto porty:
#### Tlačítka
* **BTNC:** Tlačítko na reset
* **BTNL:** Přepnutí do režimu nastavení svítivosti (Brightness)
* **BTNR:** Přepnutí do režimu nastavení rychlosti (Speed)
* **BTNU/BTND:** Zvyšování / snižování hodnoty pro dané nastavení
#### RGB
* **LED17_R, LED17_G, LED17_B:** Pro ovládání jednotlivých barev
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

### Color FSM
Tento modul tvoří "mozek" celé aplikace.
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

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity color_fsm is
    Port ( -- Vstupy
           clk          : in  STD_LOGIC;
           rst          : in  STD_LOGIC;
           en           : in  STD_LOGIC;
           up           : in  STD_LOGIC;
           down         : in  STD_LOGIC;
           mode_speed   : in  STD_LOGIC;
           mode_brig    : in  STD_LOGIC;
           -- Výstupy pro informaci ( 7-segmentovka)
           brig         : out STD_LOGIC_VECTOR (3 downto 0);
           speed        : out STD_LOGIC_VECTOR (3 downto 0);
           -- Výstupy pro PWM drivery (8 bitů pro každou barvu)
           red          : out STD_LOGIC_VECTOR (7 downto 0);
           green        : out STD_LOGIC_VECTOR (7 downto 0);
           blue         : out STD_LOGIC_VECTOR (7 downto 0)
           );
end color_fsm;

architecture Behavioral of color_fsm is

    -- Definice stavů pro FSM ovládání (tlačítka)
    type btn_state is (SET_BRIGHTNESS, SET_SPEED);
    signal MODE : btn_state := SET_BRIGHTNESS;

    -- Registry pro uživatelské nastavení (rozsah 0-10)
    signal brig_reg  : unsigned(3 downto 0)  := "0110"; -- Výchozí jas = 6
    signal speed_reg : unsigned(3 downto 0)  := "0101"; -- Výchozí rychlost = 5 (5 sekund)

    -- Vnitřní registry pro plynulou barvu (8-bitové, rozsah 0-255)
    signal r_cnt : unsigned(7 downto 0) := x"FF"; 
    signal g_cnt : unsigned(7 downto 0) := x"00";
    signal b_cnt : unsigned(7 downto 0) := x"00";

    -- Časovače pro přesné sekundy (clk 100 MHz)
    -- Výpočet tiků za sekundu: takt 100 MHz / 765 barevných kroků = 130718 taktů na 1 krok pro 1 sekundu
    constant TICKS_PER_SEC : unsigned(19 downto 0) := to_unsigned(130718, 20);
    signal delay_counter   : unsigned(23 downto 0) := (others => '0');

begin

    -- Hlavní synchronní proces
    p_color_control : process(clk)
        variable target_delay : unsigned(23 downto 0);
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                MODE          <= SET_BRIGHTNESS;
                brig_reg      <= "0110";
                speed_reg     <= "0101"; -- Návrat na 5 sekund
                r_cnt         <= x"FF";  -- Reset na plnou červenou
                g_cnt         <= x"00";
                b_cnt         <= x"00";
                delay_counter <= (others => '0');
                
            elsif (en = '1') then
                
                -- 1) LOGIKA PŘEPÍNÁNÍ REŽIMŮ A NASTAVENÍ (Jas/Rychlost)
                case MODE is
                    when SET_BRIGHTNESS =>
                        if (up = '1') and (brig_reg < 10) then  -- Změna maxima reg. speed
                            brig_reg <= brig_reg + 1;
                        elsif (down = '1') and (brig_reg > 0) then
                            brig_reg <= brig_reg - 1;
                        end if;

                        if (mode_speed = '1') then MODE <= SET_SPEED; end if;

                    when SET_SPEED =>
                        if (up = '1') and (speed_reg < 10) then   -- Změna maxima reg. speed
                            speed_reg <= speed_reg + 1;
                        elsif (down = '1') and (speed_reg > 0) then
                            speed_reg <= speed_reg - 1;
                        end if;

                        if (mode_brig = '1') then MODE <= SET_BRIGHTNESS; end if;
                end case;

                -- 2) LOGIKA PLYNULÉHO PŘECHODU BAREV S PŘESNÝM ČASOVÁNÍM A PAUZOU
                if (speed_reg > 0) then
                    
                    -- Výpočet cílového zpoždění (např. 10 * 130718 = 10 sekund)
                    target_delay := speed_reg * TICKS_PER_SEC; 
                    
                    delay_counter <= delay_counter + 1;

                    if (delay_counter >= target_delay) then
                        delay_counter <= (others => '0'); -- Reset čítače zpoždění
                        
                        -- Krok duhy
                        if (r_cnt > 0 and b_cnt = 0) then
                            r_cnt <= r_cnt - 1; g_cnt <= g_cnt + 1;
                        elsif (g_cnt > 0 and r_cnt = 0) then
                            g_cnt <= g_cnt - 1; b_cnt <= b_cnt + 1;
                        elsif (b_cnt > 0 and g_cnt = 0) then
                            b_cnt <= b_cnt - 1; r_cnt <= r_cnt + 1;
                        end if;
                    end if;
                    
                else
                    -- Rychlost je 0 = PAUZA
                    -- Vynulujeme čítač pro budoucí spuštění, ale barvy (r,g,b) zůstávají beze změny
                    delay_counter <= (others => '0');
                end if;
                
            end if;
        end if;
    end process p_color_control;

    -- VÝPOČET FINÁLNÍHO BARVY (i s jasem)
    p_brightness_apply : process(r_cnt, g_cnt, b_cnt, brig_reg)
        variable r, g, b : unsigned(11 downto 0); 
    begin
        r := r_cnt * brig_reg;
        g := g_cnt * brig_reg;
        b := b_cnt * brig_reg;
        
        -- 12bitového výsledku vezmeme horních 8 bitů a pošleme je na výstup FSm
        red   <= std_logic_vector(r(11 downto 4));
        green <= std_logic_vector(g(11 downto 4));
        blue  <= std_logic_vector(b(11 downto 4));
    end process p_brightness_apply;

    -- Přiřazení vnitřních registrů na výstup
    brig  <= std_logic_vector(brig_reg);
    speed <= std_logic_vector(speed_reg);

end Behavioral;
```

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

```vhdl
Sem vložit kód
```
