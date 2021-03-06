LIBRARY lpm;
USE lpm.lpm_components.ALL;

LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;  -- Contains conversion 
                                  -- VECTOR -> INTEGER 
ENTITY darom IS                      ------> Interface
  PORT (clk  : IN STD_LOGIC;
        x_in0, x_in1, x_in2 
                         : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        y    : OUT INTEGER RANGE 0 TO 63);
END darom;

ARCHITECTURE flex OF darom IS
  TYPE STATE_TYPE IS (s0, s1);
  SIGNAL state                     : STATE_TYPE;
  SIGNAL x0, x1, x2, table_in, mem 
                            : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL table_out                 : integer RANGE 0 TO 7;
BEGIN

  table_in(0) <= x0(0);
  table_in(1) <= x1(0);
  table_in(2) <= x2(0);

  PROCESS                    ------> DA in behavioral style
    VARIABLE  p   : integer RANGE 0 TO 63; --Temp. register
    VARIABLE count : integer RANGE 0 TO 3; 
  BEGIN                                -- Counts the shifts
    WAIT UNTIL clk = '1';  
    CASE state IS
      WHEN s0 =>           -- Initialization step
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

  rom_1: LPM_ROM
    GENERIC MAP ( LPM_WIDTH => 3,                 
                  LPM_WIDTHAD => 3,
                  LPM_OUTDATA => "UNREGISTERED",
                  LPM_ADDRESS_CONTROL => "UNREGISTERED",
                  LPM_FILE => "darom3.mif")                       
    PORT MAP ( address => table_in, q => mem);

  table_out <= CONV_INTEGER(mem);
  
END flex;
