--*********************************************************
-- IEEE STD 1076-1987/1993 VHDL file: csa7.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
--     7 bit carry save adder with register
LIBRARY lpm;
USE lpm.lpm_components.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY csa7 IS
  PORT ( a, b  : IN  STD_LOGIC_VECTOR(6 DOWNTO 0); 
         clock : IN  STD_LOGIC;
         s     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
         c     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0));
END csa7;

ARCHITECTURE pins OF csa7 IS

  SIGNAL r  : STD_LOGIC_VECTOR(6 DOWNTO 0); -- Result adder
  SIGNAL cr : STD_LOGIC_VECTOR(0 DOWNTO 0); -- Carry reg.

BEGIN

  add_0: lpm_add_sub                 -- Add a and b
    GENERIC MAP ( LPM_WIDTH => 7,
--                  LPM_REPRESENTATION => "UNSIGNED",
                  LPM_DIRECTION => "ADD")  
    PORT MAP ( dataa => a, datab => b,
               result => r, cout => cr(0));
               
  reg_0: lpm_ff                         -- Save a+b
    GENERIC MAP ( LPM_WIDTH => 7 )  
    PORT MAP ( data => r, q => s, clock => clock);
    
  carry_0: lpm_ff                     -- Save carry
    GENERIC MAP ( LPM_WIDTH => 1 )  
    PORT MAP ( data => cr, q => c, clock => clock);
    
END pins;
