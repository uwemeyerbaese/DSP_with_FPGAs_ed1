LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
PACKAGE da_package IS    -- User defined component
  COMPONENT case3
    PORT ( table_in   : IN   STD_LOGIC_VECTOR(2 DOWNTO 0);
           table_out  : OUT  integer RANGE 0 TO 6);
  END COMPONENT;
END da_package;

LIBRARY work;
USE work.da_package.ALL;

LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
ENTITY dafsm IS                      ------> Interface
       PORT (clk  : IN STD_LOGIC;
             x_in0, x_in1, x_in2 : 
                          IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
             y    : OUT INTEGER RANGE 0 TO 63);
END dafsm;

ARCHITECTURE flex OF dafsm IS
  TYPE STATE_TYPE IS (s0, s1);
  SIGNAL state    : STATE_TYPE;
  SIGNAL x0, x1, x2, table_in 
                            : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL table_out : integer RANGE 0 TO 7;
BEGIN

  table_in(0) <= x0(0);
  table_in(1) <= x1(0);
  table_in(2) <= x2(0);

  PROCESS              ------> DA in behavioral style
    VARIABLE p    : integer RANGE 0 TO 63;-- temp. register
    VARIABLE count : integer RANGE 0 TO 3; -- counts shifts
  BEGIN
    WAIT UNTIL clk = '1';  
    CASE state IS
      WHEN s0 =>        -- Initialization step
        state <= s1;
        count := 0;
        p := 0;           
        x0 <= x_in0;
        x1 <= x_in1;
        x2 <= x_in2;
      WHEN s1 =>            -- Processing step
        IF count = 3 THEN   -- Is sum of product done ?
          y <= p;           -- Output of result to y and
          state <= s0;      -- start next sum of product
        ELSE
          p := p / 2 + table_out * 4;
          x0(0) <= x0(1);
          x0(1) <= x0(2);
          x1(0) <= x1(1);
          x1(1) <= x1(2);
          x2(0) <= x2(1);
          x2(1) <= x2(2);
          count := count + 1;
          state <= s1;
        END IF;
    END CASE;
  END PROCESS;

  LC_Table0: case3
    PORT MAP(table_in => table_in, table_out => table_out);

END flex;
