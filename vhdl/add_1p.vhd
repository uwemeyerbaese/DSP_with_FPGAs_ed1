LIBRARY lpm;
USE lpm.lpm_components.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY add_1p IS
  GENERIC (WIDTH  : INTEGER := 15; -- Total bit width
           WIDTH1 : INTEGER := 7;  -- Bit width of LSBs 
           WIDTH2 : INTEGER := 8;  -- Bit width of MSBs
           ONE    : INTEGER := 1); -- 1 bit for carry reg.
  PORT (x,y : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  
                                                  -- Inputs
        sum : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  
                                                  -- Result
        clk : IN  STD_LOGIC);
END add_1p;

ARCHITECTURE flex OF add_1p IS
  SIGNAL l1, l2, r1, q1                   -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1-1 DOWNTO 0); 
  SIGNAL l3, l4, r2, q2, u2, h2           -- MSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH2-1 DOWNTO 0); 
  SIGNAL s           : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); 
                                         -- Output register
  SIGNAL cr1, cq1    : STD_LOGIC_VECTOR(ONE-1 DOWNTO 0);
                                       -- LSBs carry signal
                         
      
BEGIN 
  PROCESS  -- Split in MSBs and LSBs and store in registers
  BEGIN
    WAIT UNTIL clk = '1';
    -- Split LSBs from input x,y
    FOR k IN WIDTH1-1 DOWNTO 0 LOOP 
      l1(k) <= x(k);
      l2(k) <= y(k);
    END LOOP;
    -- Split MSBs from input x,y
    FOR k IN WIDTH2-1 DOWNTO 0 LOOP 
      l3(k) <= x(k+WIDTH1);
      l4(k) <= y(k+WIDTH1);
    END LOOP;
  END PROCESS;
-------------- First stage of the adder  ------------------
  add_1: lpm_add_sub                 -- Add LSBs of x and y
         GENERIC MAP ( LPM_WIDTH => WIDTH1,
                       LPM_REPRESENTATION => "UNSIGNED",
                       LPM_DIRECTION => "ADD")  
         PORT MAP ( dataa => l1, datab => l2,
                    result => r1,  cout => cr1(0));
  reg_1: lpm_ff           -- Save LSBs of x+y and carry
         GENERIC MAP ( LPM_WIDTH => WIDTH1 )  
         PORT MAP ( data => r1, q => q1,clock => clk );
  reg_2: lpm_ff
         GENERIC MAP ( LPM_WIDTH => ONE )  
         PORT MAP ( data => cr1, q => cq1, clock => clk );

  add_2: lpm_add_sub                 -- Add MSBs of x and y
         GENERIC MAP ( LPM_WIDTH => WIDTH2,
                       LPM_REPRESENTATION => "UNSIGNED",
                       LPM_DIRECTION => "ADD")  
         PORT MAP (dataa => l3, datab => l4, result => r2);
  reg_3: lpm_ff                   -- Save MSBs of x+y 
         GENERIC MAP ( LPM_WIDTH => WIDTH2 )  
         PORT MAP ( data => r2, q => q2, clock => clk );
------------ Second stage of the adder --------------------
  -- One operand is zero
  h2 <= (OTHERS => '0'); 

  -- Add result from MSBs (x+y) and carry from LSBs
  add_3: lpm_add_sub     
         GENERIC MAP ( LPM_WIDTH => WIDTH2,
                       LPM_REPRESENTATION => "UNSIGNED",
                       LPM_DIRECTION => "ADD")  
         PORT MAP ( cin => cq1(0), dataa => q2, 
                    datab => h2, result => u2 );

  PROCESS              -- Build a single registered output
  BEGIN                -- word of WIDTH=WIDTH1+WIDHT2
    WAIT UNTIL clk = '1';
    FOR k IN WIDTH1-1 DOWNTO 0 LOOP
      s(k) <= q1(k);
    END LOOP;
    FOR k IN WIDTH2-1 DOWNTO 0 LOOP
      s(k+WIDTH1) <= u2(k);
    END LOOP;
  END PROCESS;

  sum <= s ;    -- Connect s to output pins
END flex;
