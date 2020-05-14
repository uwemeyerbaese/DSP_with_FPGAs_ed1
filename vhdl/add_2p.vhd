--*********************************************************
-- IEEE STD 1076-1987/1993 VHDL file: add_2p.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
-- 22-bit adder with two pipeline stages
-- Uses four components: csa7.vhd; csa7cin.vhd; 
--                    add_ff8.vhd; add_ff8cin.vhd
LIBRARY lpm;
USE lpm.lpm_components.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
PACKAGE csa_package IS    -- User defined objects
  COMPONENT csa7
    PORT ( a, b  : IN  STD_LOGIC_VECTOR(6 DOWNTO 0); 
           clock : IN  STD_LOGIC;
           s     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
           c     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0));
  END COMPONENT;
  COMPONENT csa7cin
    PORT ( a, b  : IN  STD_LOGIC_VECTOR(6 DOWNTO 0); 
           cin   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
           clock : IN  STD_LOGIC;
           s     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
           c     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0));
  END COMPONENT;
  COMPONENT add_ff8
    PORT ( a, b  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
           clock : IN  STD_LOGIC;
           s     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
  END COMPONENT;
  COMPONENT add_ff8cin
    PORT ( a, b  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
           cin   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0); 
           clock : IN  STD_LOGIC;
           s     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
  END COMPONENT;
END csa_package;

LIBRARY work;
USE work.csa_package.ALL;

LIBRARY lpm;
USE lpm.lpm_components.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY add_2p IS
  GENERIC (WIDTH : INTEGER := 22; -- Total bit width
           WIDTH1  : INTEGER := 7;  -- Bit width of LSBs 
           WIDTH2  : INTEGER := 7;  -- Bit width of middle
           WIDTH12 : INTEGER := 14; -- Sum WIDTH1+WIDTH2
           WIDTH3  : INTEGER := 8;  -- Bit width of MSBs
           ONE     : INTEGER := 1); -- 1 bit for carry reg.
  PORT (x, y : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                                                 --  Inputs
        sum  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                                  -- Result
        clk  : IN  STD_LOGIC);
END add_2p;

ARCHITECTURE flex OF add_2p IS
  SIGNAL  l1, l2, q1, v1, s1              -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1-1 DOWNTO 0);
  SIGNAL  l3, l4, q2, h2, v2, s2             -- Middle bits
                     : STD_LOGIC_VECTOR(WIDTH2-1 DOWNTO 0);
  SIGNAL  l5, l6, q3, h3, v3, s3     -- MSBs of input
                     : STD_LOGIC_VECTOR(WIDTH3-1 DOWNTO 0);
  SIGNAL  s    : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                         -- Output register
  SIGNAL  cq1, cq2, cv2 : STD_LOGIC_VECTOR(ONE-1 DOWNTO 0);
                                           -- Carry signals
            
BEGIN
  PROCESS  -- Split in MSBs and LSBs and store in registers
  BEGIN
    WAIT UNTIL clk = '1';
    -- Split LSBs from input x,y
    FOR k IN WIDTH1-1 DOWNTO 0 LOOP 
      l1(k) <= x(k);
      l2(k) <= y(k);
    END LOOP;
    -- Split middle bits from input x,y
    FOR k IN WIDTH2-1 DOWNTO 0 LOOP 
      l3(k) <= x(k+WIDTH1);
      l4(k) <= y(k+WIDTH1);
    END LOOP;
    -- Split MSBs from input x,y
    FOR k IN WIDTH3-1 DOWNTO 0 LOOP 
      l5(k) <= x(k+WIDTH12);
      l6(k) <= y(k+WIDTH12);
    END LOOP;
  END PROCESS;
--------------- First stage of the adder  -----------------
  add_1: csa7                      -- Add LSBs of x and y
    PORT MAP ( a => l1, b => l2, clock => clk,
                        s => q1, c => cq1);

  add_2: csa7                      -- Add LSBs of x and y
    PORT MAP ( a => l3, b => l4, clock => clk,
                        s => q2,  c => cq2);

  add_3: add_ff8                   -- Add MSBs of x and y
    PORT MAP ( a => l5, b => l6, clock => clk, s => q3);
-------------- Second stage of the adder ------------------
  -- Two operands are zero
  h2 <= (OTHERS => '0'); 
  h3 <= (OTHERS => '0'); 

  reg_1: lpm_ff      
    GENERIC MAP ( LPM_WIDTH => WIDTH1)  
    PORT MAP  ( data => q1, q => v1, clock => clk);

-- Add result from middle bits (x+y) and carry from LSBs
  add_4: csa7cin     
    PORT MAP ( a => q2, b => h2, cin => cq1, clock => clk,
                                 s => v2, c => cv2 );

-- Add result from MSBs bits (x+y) and carry from middle
  add_5: add_ff8cin     
    PORT MAP  ( a => q3, b => h3, cin => cq2, 
                         clock => clk, s => v3 );
---------------- Third stage of the adder -----------------
  reg_2: lpm_ff      
    GENERIC MAP ( LPM_WIDTH => WIDTH1 )  
    PORT MAP  ( data => v1, q => s1, clock => clk);

  reg_3: lpm_ff      
    GENERIC MAP ( LPM_WIDTH => WIDTH1)  
    PORT MAP ( data => v2, q => s2, clock => clk);

-- Add result from MSBs bits (x+y) and 2. carry from middle
  add_6: add_ff8cin     
    PORT MAP  (  a => v3, b => h3, cin => cv2, 
                          clock => clk, s => s3 );
  
  PROCESS (s1, s2, s3)   -- Build a single output word
    BEGIN             -- of WIDTH=WIDTH1+WIDHT2+WIDTH3
      FOR k IN WIDTH1-1 DOWNTO 0 LOOP
        s(k) <= s1(k);
      END LOOP;
      FOR k IN WIDTH2-1 DOWNTO 0 LOOP
        s(k+WIDTH1) <= s2(k);
      END LOOP;
      FOR k IN WIDTH3-1 DOWNTO 0 LOOP
        s(k+WIDTH12) <= s3(k);
      END LOOP;
  END PROCESS;

  sum <= s ;    -- Connect s to output pins
END flex;
