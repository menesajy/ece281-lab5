--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_basys3 is
    port(
        -- inputs
        clk     : in std_logic;
        sw      : in std_logic_vector(7 downto 0);
        btnU    : in std_logic;
        btnC    : in std_logic;

        -- outputs
        led : out std_logic_vector(15 downto 0);

        -- 7-segment display
        seg : out std_logic_vector(6 downto 0);
        an  : out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- FSM cycle
    signal w_cycle : std_logic_vector(3 downto 0);

    -- operand registers
    signal f_A : std_logic_vector(7 downto 0);
    signal f_B : std_logic_vector(7 downto 0);

    -- ALU outputs
    signal w_alu_result : std_logic_vector(7 downto 0);
    signal w_flags      : std_logic_vector(3 downto 0);

    -- selected display value
    signal w_display_bin : std_logic_vector(7 downto 0);

    -- decimal conversion
    signal w_sign_bit   : std_logic;
    signal w_sign_digit : std_logic_vector(3 downto 0);
    signal w_hund       : std_logic_vector(3 downto 0);
    signal w_tens       : std_logic_vector(3 downto 0);
    signal w_ones       : std_logic_vector(3 downto 0);

    -- TDM outputs
    signal w_hex : std_logic_vector(3 downto 0);
    signal w_an  : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------------------------------
    -- FSM
   
    u_fsm : entity work.controller_fsm
        port map(
            i_reset => btnU,
            i_adv   => btnC,
            o_cycle => w_cycle
        );

    --------------------------------------------------------------------------
    -- Operand Registers
    --------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then

            if btnU = '1' then
                f_A <= (others => '0');
                f_B <= (others => '0');

            else

                -- load A
                if w_cycle = "0010" then
                    f_A <= sw;

                -- load B
                elsif w_cycle = "0100" then
                    f_B <= sw;

                end if;

            end if;
        end if;
    end process;

    --------------------------------------------------------------------------
    -- ALU
    --------------------------------------------------------------------------

    u_alu : entity work.ALU
        port map(
            i_A      => f_A,
            i_B      => f_B,
            i_op     => sw(2 downto 0),
            o_result => w_alu_result,
            o_flags  => w_flags
        );

      -- Display Selection
    --------------------------------------------------------------------------

    with w_cycle select
        w_display_bin <=
            f_A          when "0010",
            f_B          when "0100",
            w_alu_result when "1000",
            (others => '0') when others;

   
    u_twos_comp : entity work.twos_comp
        port map(
            i_bin  => w_display_bin,
            o_sign => w_sign_bit,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );

    -- negative sign or blank
    w_sign_digit <= "1010" when w_sign_bit = '1' else "1111";

    --------------------------------------------------------------------------
    -- Time Division Multiplexing
    --------------------------------------------------------------------------

    u_tdm : entity work.TDM4
        generic map(
            k_WIDTH => 4
        )
        port map(
            i_clk   => clk,
            i_reset => btnU,
            i_D3    => w_sign_digit,
            i_D2    => w_hund,
            i_D1    => w_tens,
            i_D0    => w_ones,
            o_data  => w_hex,
            o_sel   => w_an
        );

    --------------------------------------------------------------------------
    -- Seven Segment Decoder
    --------------------------------------------------------------------------

    u_sevenseg : entity work.sevenseg_decoder
        port map(
            i_Hex   => w_hex,
            o_seg_n => seg
        );

  

    -- blank displays during clear state
    an <= "1111" when w_cycle = "0001" else w_an;

   
    -- LEDs
    --------------------------------------------------------------------------

    -- FSM state LEDs
    led(3 downto 0) <= w_cycle;

    -- unused LEDs
    led(11 downto 4) <= (others => '0');

    -- flags
    led(15 downto 12) <= w_flags;

end top_basys3_arch;