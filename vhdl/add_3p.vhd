--*********************************************************
-- IEEE STD 1076-1987/1993 VHDL file: add_3p.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
-- 29-bit adder with three pipeline stages
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

ENTITY add_3p IS
  GENERIC (WIDTH   : INTEGER := 29; -- Total bit width
           WIDTH0  : INTEGER := 7;  -- Bit width of LSBs 
           WIDTH1  : INTEGER := 7;  -- Bit width of 2. LSBs
           WIDTH01 : INTEGER := 14; -- Sum WIDTH0+WIDTH1
           WIDTH2  : INTEGER := 7;  -- Bit width of 2. MSBs
           WIDTH012 :INTEGER := 21; -- WIDTH0+WIDTH1+WIDTH2
           WIDTH3  : INTEGER := 8;  -- Bit width of MSBs
           ONE     : INTEGER := 1); -- 1 bit for carry reg.
  PORT ( x,y :  IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                                 --  Inputs
         sum :  OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                                  -- Result
         clk :  IN  STD_LOGIC);
END add_3p;

ARCHITECTURE flex OF add_3p IS
  SIGNAL  l0, l1, q0, v0, r0, s0          -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH0-1 DOWNTO 0);
  SIGNAL  l2, l3, q1, v1, r1, s1       -- 2. LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1-1 DOWNTO 0); 
  SIGNAL  l4, l5, q2, v2, r2, s2, h7        -- 2. MSBs bits
                     : STD_LOGIC_VECTOR(WIDTH2-1 DOWNTO 0); 
  SIGNAL  l6, l7, q3, v3, r3, s3, h8       -- MSBs of input
                     : STD_LOGIC_VECTOR(WIDTH3-1 DOWNTO 0); 
  SIGNAL  s          : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                                         -- Output register
  SIGNAL  cq0, cq1, cq2, cv1, cv2, cr2     -- Carry signals
                      :   STD_LOGIC_VECTOR(ONE-1 DOWNTO 0);
                                                     
                                                
BEGIN
  PROCESS  -- Split in MSBs and LSBs and store in registers
  BEGIN
    WAIT UNTIL clk = '1';
    -- Split LSBs from input x,y
    FOR k IN WIDTH0-1 DOWNTO 0 LOOP 
      l0(k) <= x(k);
      l1(k) <= y(k);
    END LOOP;
    -- Split 2. LSBs from input x,y
    FOR k IN WIDTH1-1 DOWNTO 0 LOOP 
      l2(k) <= x(k+WIDTH0);
      l3(k) <= y(k+WIDTH0);
    END LOOP;
    -- Split 2. MSBs from input x,y
    FOR k IN WIDTH2-1 DOWNTO 0 LOOP 
      l4(k) <= x(k+WIDTH01);
      l5(k) <= y(k+WIDTH01);
    END LOOP;
    -- Split MSBs from input x,y
    FOR k IN WIDTH3-1 DOWNTO 0 LOOP 
      l6(k) <= x(k+WIDTH012);
      l7(k) <= y(k+WIDTH012);
    END LOOP;
  END PROCESS;
---------------- First stage of the adder  ----------------
  add_0: csa7                      -- Add LSBs of x and y
    PORT MAP (a => l0, b => l1, clock => clk,
                       s => q0, c => cq0);
  add_1: csa7                   -- Add 2. LSBs of x and y
    PORT MAP ( a => l2, b => l3, clock => clk,
                        s => q1, c => cq1);
  add_2: csa7                   -- Add 2. MSBs of x and y
    PORT MAP ( a => l4, b => l5, clock => clk,
                        s => q2, c => cq2);
  add_3: add_ff8                   -- Add MSBs of x and y
    PORT MAP ( a => l6, b => l7, clock => clk, s => q3);
--------------- Second stage of the adder -----------------
  -- Two operands are zero
  h7 <= (OTHERS => '0'); 
  h8 <= (OTHERS => '0'); 

  reg_1: lpm_ff          
    GENERIC MAP ( LPM_WIDTH => WIDTH0)  
    PORT MAP ( data => q0, q => v0, clock => clk);
    
-- Add result from 2. LSBs (x+y) and carry from LSBs    
  add_4: csa7cin     
    PORT MAP ( a => q1, b => h7, cin => cq0, clock => clk,
                                 s => v1,    c => cv1 );
                                                
-- Add result from 2. MSBs (x+y) and carry from 2. LSBs                                                
  add_5: csa7cin     
    PORT MAP ( a => q2, b => h7, cin => cq1, clock => clk,
                                 s => v2,    c => cv2 );
                                                
-- Add result from MSBs (x+y) and carry from 2. MSBs                                                
  add_6: add_ff8cin     
    PORT MAP ( a => q3, b => h8, cin => cq2, 
                        clock => clk, s => v3 );
-------------- Third stage of the adder -------------------
  reg_2: lpm_ff          
    GENERIC MAP ( LPM_WIDTH => WIDTH0)  
    PORT MAP ( data => v0, q => r0, clock => clk);
  reg_3: lpm_ff          
    GENERIC MAP ( LPM_WIDTH => WIDTH1)  
    PORT MAP ( data => v1, q => r1, clock => clk);

-- Add result from 2. MSBs (x+y) and carry from 2. LSBs    
  add_7: csa7cin     
    PORT MAP ( a => v2, b => h7, cin => cv1, clock => clk,
                                      s => r2, c => cr2);
                                      
-- Add result from MSBs (x+y) and carry from 2. MSBs
  add_8: add_ff8cin     
    PORT MAP ( a => v3, b => h8, cin => cv2, clock => clk,
                                                s => r3 );
----------------- Fourth stage of the adder ----------------------
  reg_4: lpm_ff          
    GENERIC MAP ( LPM_WIDTH => WIDTH0)  
    PORT MAP ( data => r0, q => s0, clock => clk);
  reg_5: lpm_ff          
    GENERIC MAP ( LPM_WIDTH => WIDTH1 )  
    PORT MAP ( data => r1, q => s1, clock => clk);
  reg_6: lpm_ff          
    GENERIC MAP ( LPM_WIDTH => WIDTH2 )  
    PORT MAP ( data => r2, q => s2, clock => clk);
    
-- Add result from MSBs (x+y) and carry from 2. MSBs    
  add_9: add_ff8cin     
    PORT MAP ( a => r3, b => h8, cin => cr2, clock => clk, 
                                                 s => s3 );

  PROCESS (s0, s1, s2, s3)  -- Build a single output word
  BEGIN           -- of WIDTH=WIDTH0+WIDTH1+WIDHT2+WIDTH3
    FOR k IN WIDTH0-1 DOWNTO 0 LOOP
      s(k) <= s0(k);
    END LOOP;
    FOR k IN WIDTH1-1 DOWNTO 0 LOOP
      s(k+WIDTH0) <= s1(k);
    END LOOP;
    FOR k IN WIDTH2-1 DOWNTO 0 LOOP
      s(k+WIDTH01) <= s2(k);
    END LOOP;
    FOR k IN WIDTH3-1 DOWNTO 0 LOOP
      s(k+WIDTH012) <= s3(k);
    END LOOP;
  END PROCESS;

  sum <= s ;    -- Connect s to output pins
END flex;
