PACKAGE eight_bit_int IS           -- User defined types
  SUBTYPE BYTE IS integer RANGE -128 TO 127;
  SUBTYPE TWOBYTES IS integer RANGE -32768 TO 32767;
END eight_bit_int;

LIBRARY work;
USE work.eight_bit_int.ALL;

LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY mul_ser IS                      ------> Interface
  PORT ( clk  : IN  STD_LOGIC;
         x    : IN  BYTE;
         a    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
         y    : OUT TWOBYTES);
END mul_ser;

ARCHITECTURE flex OF mul_ser IS

  TYPE STATE_TYPE IS (s0, s1, s2);
  SIGNAL state    : STATE_TYPE;
  
BEGIN
 
  States: PROCESS    ------> Multiplier in behavioral style
    VARIABLE  p, t  : TWOBYTES;         -- Double bit width
    VARIABLE count  : integer RANGE 0 TO 7;
  BEGIN
    WAIT UNTIL clk = '1';  
    CASE state IS
      WHEN s0 =>        -- Initialization step 
        state <= s1;
        count := 0;
        p := 0;        -- Product register reset
        t := x;        -- Set temporary shift register to x
      WHEN s1 =>          -- Processing step
        IF count = 7 THEN -- Multiplication ready
          state <= s2;
          ELSE
          IF a(count) = '1' THEN
            p := p + t;     -- Add 2^k
          END IF;
          t := t * 2;
          count := count + 1;
          state <= s1;
        END IF;
      WHEN s2 =>       -- Output of result to y and
        y <= p;        -- start next multiplication
        state <= s0;
    END CASE;
  END PROCESS States;
  
END flex;
