----------------------------------------------------------------------------------
-- Company: VUT
-- Engineer: BRostík, Dibelka
-- 
-- Create Date: 03/19/2026 01:09:52 PM
-- Design Name: 
-- Module Name: debounce - Behavioral
-- Project Name: 
-- Target Devices: Nexys A7 50T
-- 
-- Revision:
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------

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
