library myers;
use myers.myers_fsm;
use myers.myers_pkg.all;

library std;
use std.textio.all;
use std.env.finish;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;


entity tb_myers_core is
end tb_myers_core;

architecture sim of tb_myers_core is

    ---------------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------------
    
    constant CLK_PERIOD : time := 20 ns;

    ---------------------------------------------------------------------------------
    -- Components
    ---------------------------------------------------------------------------------

    component myers_core
        port (
            clk_i       : in std_logic;
            rst_i       : in std_logic;

            s1_i        : in strand;
            s2_i        : in strand;
            Peq_i       : in peq_array;

            Ph_i        : in strand_vector;
            Pv_i        : in strand_vector;
            Mh_i        : in strand_vector;
            Mv_i        : in strand_vector;
            Xv_i        : in strand_vector;
            idx_i       : in integer;

            add_score_i : in std_logic;
            sub_score_i : in std_logic;
            score_i     : in integer;

            s1_o        : out strand;
            s2_o        : out strand;
            Peq_o       : out peq_array;

            Ph_o        : out strand_vector;
            Pv_o        : out strand_vector;
            Mh_o        : out strand_vector;
            Mv_o        : out strand_vector;
            Xv_o        : out strand_vector;

            add_score_o : out std_logic;
            sub_score_o : out std_logic;
            score_o     : out integer
        );
    end component;

    ---------------------------------------------------------------------------------
    -- Signals
    ---------------------------------------------------------------------------------

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';

    signal s1, s2      : strand;
    signal Peq         : peq_array;

    signal Ph, Mh, Mv, Xv : strand_vector;
    signal Pv             : strand_vector;

    signal idx         : integer;
    signal add_score_i : std_logic;
    signal sub_score_i : std_logic;
    signal score_i     : integer;

    signal Ph_o, Mh_o, Mv_o, Xv_o   : strand_vector;
    signal Pv_o                     : strand_vector;
    signal add_score_o, sub_score_o : std_logic;
    signal score_o                  : integer;
    signal s1_o, s2_o               : strand;
    signal Peq_o                    : peq_array;

begin

   -- Instantiate the Unit Under Test (UUT) --
    uut: myers_core
        port map (
            clk_i       => clk,
            rst_i       => rst,
            s1_i        => s1,
            s2_i        => s2,
            Peq_i       => Peq,
            Ph_i        => Ph,
            Pv_i        => Pv,
            Mh_i        => Mh,
            Mv_i        => Mv,
            Xv_i        => Xv,
            idx_i       => idx,
            add_score_i => add_score_i,
            sub_score_i => sub_score_i,
            score_i     => score_i,
            s1_o        => s1_o,
            s2_o        => s2_o,
            Peq_o       => Peq_o,
            Ph_o        => Ph_o,
            Pv_o        => Pv_o,
            Mh_o        => Mh_o,
            Mv_o        => Mv_o,
            Xv_o        => Xv_o,
            add_score_o => add_score_o,
            sub_score_o => sub_score_o,
            score_o     => score_o
        );

    -- clk generation --
    clk <= not clk after CLK_PERIOD / 2;
    
    -- reset behavior --
    rst <= '1', '0' after CLK_PERIOD * 4;
    
    -- stimulus process --
    stim_proc : process
    begin
        wait until rst = '0';
        wait for CLK_PERIOD;

        -----------------------------------------------------------------------------
        -- Initialization
        -----------------------------------------------------------------------------

        -- s1 = "GGT..."
        s1(0) <= G_CODE;
        s1(1) <= G_CODE;
        s1(2) <= T_CODE;

        -- s2 = "TTA..."
        s2(0) <= T_CODE;
        s2(1) <= T_CODE;
        s2(2) <= A_CODE;

        -- bit-vector
        Ph <= (others => '0');
        Mh <= (others => '0');
        Mv <= (others => '0');
        Xv <= (others => '0');
        Pv <= (others => '1');

        -- Peq setup manually from debug data
        -- Peq index = 0: A, 1: C, 2: G, 3: T
        Peq(0) <= "110000000001001010000010001000000000000001111100000111100001000100011010000000000001010000001010111100000111010000001100010010100000001000001001000100000000010000000010010001000000000100000001000111001100100"; -- A
        Peq(1) <= "000001100100000000000000000001110010000100000000011000010100000010000000000100000100001101000000000011000000000110000001100000010110110110000110000000100110101001100100000100010010100010001010000000000010000"; -- C
        Peq(2) <= "000010001010000100100000010010001100001000000001100000000000111000100100111010101000100010000101000000011000000001010000001100001001000000110000101011011001000000001001101010001001011001110000000000000000000"; -- G
        Peq(3) <= "001100010000110001011101100100000001110010000010000000001010000001000001000001010010000000110000000000100000101000100010000001000000000001000000010000000000000110010000000000100100000000000100111000110001011"; -- T

        -- Initial score
        score_i <= 206;

        -----------------------------------------------------------------------------
        -- First Cycle - idx = 0
        -----------------------------------------------------------------------------
        idx <= 0;
        wait for CLK_PERIOD;
    
        -- check output value
        assert s1 = s1_o
            report "Cycle 1: s1_o mismatch" severity error;
        assert s2 = s2_o
            report "Cycle 1: s1_o mismatch" severity error;
        assert Peq = Peq_o
            report "Cycle 1: Peq_o mismatch" severity error;

        assert Ph_o = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            report "Cycle 1: Ph_o mismatch" severity error;
        assert Pv_o = "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
            report "Cycle 1: Pv_o mismatch" severity error;
        assert Mh_o = "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000"
            report "Cycle 1: Mh_o mismatch" severity error;
        assert Mv_o = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            report "Cycle 1: Mv_o mismatch" severity error;        
        assert Xv_o = "000010001010000100100000010010001100001000000001100000000000111000100100111010101000100010000101000000011000000001010000001100001001000000110000101011011001000000001001101010001001011001110000000000000000000"
            report "Cycle 1: Xv_o mismatch" severity error;

        assert add_score_o = '0'
            report "Cycle 1: add_score_o mismatch" severity error;
        assert sub_score_o = '1'
            report "Cycle 1: sub_score_o mismatch" severity error;
        assert score_o = 206
            report "Cycle 1: score_o mismatch" severity error;

        -- Update for next cycle
        Ph <= Pv_o;
        Mh <= Mh_o;
        Mv <= Mv_o;
        Xv <= Xv_o;
        Pv <= Pv_o;

        add_score_i <= add_score_o;
        sub_score_i <= sub_score_o;
        score_i <= score_o;

        -----------------------------------------------------------------------------
        -- Second Cycle - idx = 1
        -----------------------------------------------------------------------------
        idx <= 1;
        wait for CLK_PERIOD;

        -- check output value
        assert s1 = s1_o
            report "Cycle 2: s1_o mismatch" severity error;
        assert s2 = s2_o
            report "Cycle 2: s1_o mismatch" severity error;
        assert Peq = Peq_o
            report "Cycle 2: Peq_o mismatch" severity error;

        assert Ph_o = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
            report "Cycle 2: Ph_o mismatch" severity error;
        assert Pv_o = "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111111111111110"
            report "Cycle 2: Pv_o mismatch" severity error;
        assert Mh_o = "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000"
            report "Cycle 2: Mh_o mismatch" severity error;
        assert Mv_o = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            report "Cycle 2: Mv_o mismatch" severity error;        
        assert Xv_o = "000010001010000100100000010010001100001000000001100000000000111000100100111010101000100010000101000000011000000001010000001100001001000000110000101011011001000000001001101010001001011001110000000000000000000"
            report "Cycle 2: Xv_o mismatch" severity error;

        assert add_score_o = '0'
            report "Cycle 2: add_score_o mismatch" severity error;
        assert sub_score_o = '1'
            report "Cycle 2: sub_score_o mismatch" severity error;
        assert score_o = 205
            report "Cycle 2: score_o mismatch" severity error;

        -- Update for next cycle
        Ph <= Pv_o;
        Mh <= Mh_o;
        Mv <= Mv_o;
        Xv <= Xv_o;
        Pv <= Pv_o;

        add_score_i <= add_score_o;
        sub_score_i <= sub_score_o;
        score_i <= score_o;

        -----------------------------------------------------------------------------
        -- Third Cycle - idx = 2
        -----------------------------------------------------------------------------
        idx <= 2;
        wait for CLK_PERIOD;

        -- check output value
        assert s1 = s1_o
            report "Cycle 3: s1_o mismatch" severity error;
        assert s2 = s2_o
            report "Cycle 3: s1_o mismatch" severity error;
        assert Peq = Peq_o
            report "Cycle 3: Peq_o mismatch" severity error;

        assert Ph_o = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000"
            report "Cycle 3: Ph_o mismatch" severity error;
        assert Pv_o = "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111001111111111111111100"
            report "Cycle 3: Pv_o mismatch" severity error;
        assert Mh_o = "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000001111111111111111000"
            report "Cycle 3: Mh_o mismatch" severity error;
        assert Mv_o = "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            report "Cycle 3: Mv_o mismatch" severity error;        
        assert Xv_o = "001100010000110001011101100100000001110010000010000000001010000001000001000001010010000000110000000000100000101000100010000001000000000001000000010000000000000110010000000000100100000000000100111000110001011"
            report "Cycle 3: Xv_o mismatch" severity error;

        assert add_score_o = '0'
            report "Cycle 3: add_score_o mismatch" severity error;
        assert sub_score_o = '1'
            report "Cycle 3: sub_score_o mismatch" severity error;
        assert score_o = 204
            report "Cycle 3: score_o mismatch" severity error;

        -----------------------------------------------------------------------------
        -- End of test
        -----------------------------------------------------------------------------
        
        wait for CLK_PERIOD * 10;
        report "-- Simulation completed --" severity note;
        finish;

    end process;

end sim;