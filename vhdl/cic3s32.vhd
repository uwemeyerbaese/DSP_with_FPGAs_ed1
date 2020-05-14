PACKAGE n_bit_int IS           -- User defined types
  SUBTYPE word26 IS INTEGER RANGE -2**25 TO 2**25-1;
  SUBTYPE word21 IS INTEGER RANGE -2**20 TO 2**20-1;
  SUBTYPE word16 IS INTEGER RANGE -2**15 TO 2**15-1;
  SUBTYPE word14 IS INTEGER RANGE -2**14 TO 2**14-1;
  SUBTYPE word13 IS INTEGER RANGE -2**13 TO 2**13-1;
  SUBTYPE word12 IS INTEGER RANGE -2**12 TO 2**12-1;
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;


ENTITY cic3s32 IS     
  PORT ( clk   :   IN  STD_LOGIC;
         x_in  :   IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        y_out  :   OUT STD_LOGIC_VECTOR(8 DOWNTO 0));
END cic3s32;

ARCHITECTURE flex OF cic3s32 IS
  TYPE    STATE_TYPE IS (hold, sample);
  SIGNAL  state     : STATE_TYPE ;
  SIGNAL  count     : integer RANGE 0 TO 31;
  SIGNAL  clk2      : STD_LOGIC;
  SIGNAL  x         : STD_LOGIC_VECTOR(7 DOWNTO 0);      
                                        -- Registered input
  SIGNAL  sxtx : STD_LOGIC_VECTOR(25 DOWNTO 0);  
                                     -- Sign extended input
  SIGNAL  i0 :  word26;                      -- I section 0
  SIGNAL  i1 :  word21;                      -- I section 1
  SIGNAL  i2 :  word16;                      -- I section 2
  SIGNAL  i2d1, i2d2, i2d3, i2d4, c1, c0 : word14;  
                                    -- I and COMB section 0
  SIGNAL  c1d1, c1d2, c1d3, c1d4, c2 : word13;   -- COMB  1
  SIGNAL  c2d1, c2d2, c2d3, c2d4, c3 : word12;   -- COMB  2
      
BEGIN

  FSM: PROCESS 
  BEGIN
    WAIT UNTIL clk = '0';
    CASE state IS
      WHEN hold =>  
        IF count < 31 THEN   
           state <= hold;
        ELSE
           state <= sample;
        END IF;
      WHEN OTHERS =>
        state <= hold;
    END CASE;
  END PROCESS FSM;

  Sxt: PROCESS (x)
  BEGIN
    sxtx(7 DOWNTO 0) <= x;
    FOR k IN 25 DOWNTO 8 LOOP
      sxtx(k) <= x(x'high);
    END LOOP;
  END PROCESS Sxt;

  Int: PROCESS 
  BEGIN
  WAIT 
    UNTIL clk = '1';
      x   <= x_in;
      i0  <= i0 + CONV_INTEGER(sxtx);        
      i1  <= i1 + i0 / 32;        
      i2  <= i2 + i1 / 32;        
    CASE state IS
      WHEN sample =>  
        c0    <= i2 /4;
        count <= 0;
      WHEN OTHERS =>  
        count <= count + 1;
    END CASE;
    IF (count > 8) and (count <16) THEN
      clk2  <= '1';
    ELSE
      clk2  <= '0';
    END IF;
  END PROCESS Int;

  Comb: PROCESS 
  BEGIN
    WAIT UNTIL clk2 = '1';
      i2d1 <= c0;
      i2d2 <= i2d1;
      c1   <= c0 - i2d2;
      c1d1 <= c1 / 2;
      c1d2 <= c1d1;
      c2   <= c1 / 2 - c1d2;
      c2d1 <= c2 / 2;
      c2d2 <= c2d1;
      c3   <= c2 / 2 - c2d2;
  END PROCESS Comb;

  y_out <= CONV_STD_LOGIC_VECTOR(c3 / 8, 9);

END flex;
