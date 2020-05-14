LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

PACKAGE da_package IS       -- User defined components
  COMPONENT case3s
    PORT ( table_in   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
           table_out  : OUT INTEGER RANGE -2 TO 4);
  END COMPONENT;
END da_package;

LIBRARY work;
USE work.da_package.ALL;

LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY dapara IS                      ------> Interface
       PORT (clk  : IN STD_LOGIC;
             x_in : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
             y    : OUT INTEGER RANGE -46 TO 44);
END dapara;

ARCHITECTURE flex OF dapara IS
  SIGNAL x0, x1, x2, x3 : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL y0, y1, y2, y3 : integer RANGE -2 TO 4;
  SIGNAL s0 : integer RANGE -6 TO 12;
  SIGNAL s1 : integer RANGE -10 TO 8;
  SIGNAL t0, t1, t2, t3 : integer RANGE -2 TO 4;

BEGIN

  PROCESS                    ------> DA in behavioral style
  BEGIN
    WAIT UNTIL clk = '1';  
    FOR k IN 0 TO 1 LOOP  -- Shift all four bits
      x0(k) <= x0(k+1);
      x1(k) <= x1(k+1);
      x2(k) <= x2(k+1);
      x3(k) <= x3(k+1);
    END LOOP;
    x0(2) <= x_in(0); -- Load x_in in the
    x1(2) <= x_in(1); -- MSBs of register 2
    x2(2) <= x_in(2);
    x3(2) <= x_in(3);
    y <= y0 + 2 * y1 + 4 * y2 - 8 * y3;
-- Pipeline register and adder tree 
--  t0 <= y0; t1 <= y1; t2 <= y2; t3 <= y3; 
--  s0 <= t0 + 2 * t1; s1 <= t2 - 2 * t3; 
--  y <= s0 + 4 * s1;
  END PROCESS;

  LC_Table0: case3s
             PORT MAP(table_in => x0, table_out => y0);
  LC_Table1: case3s
             PORT MAP(table_in => x1, table_out => y1);
  LC_Table2: case3s
             PORT MAP(table_in => x2, table_out => y2);
  LC_Table3: case3s
             PORT MAP(table_in => x3, table_out => y3);

END flex;
