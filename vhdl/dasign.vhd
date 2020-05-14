LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

PACKAGE da_package IS    -- User defined components
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

ENTITY dasign IS                      ------> Interface
       PORT (clk  : IN STD_LOGIC;
             x_in0, x_in1, x_in2 
                        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
             y    : OUT INTEGER RANGE -64 TO 63);
END dasign;

ARCHITECTURE flex OF dasign IS

  TYPE STATE_TYPE IS (s0, s1);
  SIGNAL state      : STATE_TYPE;
  SIGNAL table_in   : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL x0, x1, x2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL table_out  : integer RANGE -2 TO 4;
  
BEGIN

  table_in(0) <= x0(0);
  table_in(1) <= x1(0);
  table_in(2) <= x2(0);

  PROCESS               ------> DA in behavioral style
    VARIABLE  p : integer RANGE -64 TO 63;-- Temporary reg.
    VARIABLE count : integer RANGE 0 TO 4; -- Counts the 
  BEGIN                                    -- shifts
    WAIT UNTIL clk = '1';  
    CASE state IS
      WHEN s0 =>        -- Initialization step 
        state <= s1;
        count := 0;
        p := 0;           
        x0 <= x_in0;
        x1 <= x_in1;
        x2 <= x_in2;
      WHEN s1 =>          -- Processing step
        IF count = 4 THEN -- Is sum of product done?
          y <= p;      -- Output of result to y and
          state <= s0; -- start next sum of product
        ELSE
          IF count = 3 THEN           -- Subtract for last 
          p := p / 2 - table_out * 8; -- accumulator step
          ELSE                         
          p := p / 2 + table_out * 8;  -- Accumulation for
          END IF;                      -- all other steps
            FOR k IN 0 TO 2 LOOP    -- Shift bits
              x0(k) <= x0(k+1);
              x1(k) <= x1(k+1);
              x2(k) <= x2(k+1);
            END LOOP;
          count := count + 1;
          state <= s1;
        END IF;
    END CASE;
  END PROCESS;

  LC_Table0: case3s
    PORT MAP(table_in => table_in, table_out => table_out);

END flex;
