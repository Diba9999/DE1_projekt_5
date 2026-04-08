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

![Screenshot of a block desing](img/Design_schematic.jpg)
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


### Color FSM
Tento modul tvoří "mozek" celé aplikace.


### RGB PWM Driver
Pro ovládání výsledné barvy a svítivosti lampy slouží tento modul. Přijímá číselné hodnoty a převádí je na tři nezávislé signály pulzně šířkové modulace (PWM). Pro PWM modul zadefinujeme tyto I/O porty
| Port name | Direction | Type | Description |
| :--- | :---: | :--- | :--- |
| `clk` | in | `std_logic` | Main clock |
| `en` | in | `std_logic` | Clock enable |
| `rst` | in | `std_logic` | High-active synchronous reset |
| `brightness` | in | `std_logic_vector (x downto 0)` | Input value determining the overall brightness level |
| `speed` | in | `std_logic_vector (x downto 0)` | Input value determining the speed of color transitions or pulsing |
| `color` | in | `std_logic_vector (x downto 0)` | Input value selecting the specific color |
| `LED_R` | out | `std_logic` | PWM output signal for the Red LED channel |
| `LED_G` | out | `std_logic` | PWM output signal for the Green LED channel |
| `LED_B` | out | `std_logic` | PWM output signal for the Blue LED channel |

```vhdl
Sem vložit kód
```
