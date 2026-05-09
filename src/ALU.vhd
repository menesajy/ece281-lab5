----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( i_A      : in  STD_LOGIC_VECTOR (7 downto 0);
           i_B      : in  STD_LOGIC_VECTOR (7 downto 0);
           i_op     : in  STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags  : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    signal w_result : std_logic_vector(7 downto 0);

    signal w_add_u  : unsigned(8 downto 0);
    signal w_sub_u  : unsigned(8 downto 0);

begin

    -- 9-bit unsigned math for carry/borrow
    w_add_u <= unsigned('0' & i_A) + unsigned('0' & i_B);
    w_sub_u <= unsigned('0' & i_A) - unsigned('0' & i_B);

    process(i_A, i_B, i_op, w_add_u, w_sub_u)
    begin
        case i_op is

            when "000" => -- add
                w_result <= std_logic_vector(w_add_u(7 downto 0));

            when "001" => -- subtract
                w_result <= std_logic_vector(w_sub_u(7 downto 0));

            when "010" => -- and
                w_result <= i_A and i_B;

            when "011" => -- or
                w_result <= i_A or i_B;

            when others =>
                w_result <= (others => '0');

        end case;
    end process;

    o_result <= w_result;

    -- Flags are NZCV
    o_flags(3) <= w_result(7); -- N: negative
    o_flags(2) <= '1' when w_result = "00000000" else '0'; -- Z: zero

    -- C: carry for add, no-borrow for subtract
    o_flags(1) <= w_add_u(8) when i_op = "000" else
                  not w_sub_u(8) when i_op = "001" else
                  '0';

    -- V: signed overflow
    o_flags(0) <= '1' when (i_op = "000" and i_A(7) = i_B(7) and w_result(7) /= i_A(7)) else
                  '1' when (i_op = "001" and i_A(7) /= i_B(7) and w_result(7) /= i_A(7)) else
                  '0';

end Behavioral;