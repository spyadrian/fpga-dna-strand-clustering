library myers;
use myers.myers_pkg.all;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;


entity myers_core is

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
        idx_i       : in integer;           -- change to generic

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

end myers_core;


architecture Behavioral of myers_core is

    ---------------------------------------------------------------------------------
    -- signals
    ---------------------------------------------------------------------------------

    signal eq, ph, pv, mh, mv, xh : strand_vector;

begin

    ---------------------------------------------------------------------------------
    -- core
    ---------------------------------------------------------------------------------

    proc_core : process(clk_i)
    begin 
    
        if rising_edge(clk_i) then
        
            if rst_i = '1' then
            
                eq          <= (others => '0');
                ph          <= (others => '0');
                pv          <= (others => '0');
                mh          <= (others => '0');
                mv          <= (others => '0');
                xh          <= (others => '0');
                
                ph_o        <= (others => '0');
                pv_o        <= (others => '0');
                mh_o        <= (others => '0');
                mv_o        <= (others => '0');
                xv_o        <= (others => '0');
                
                add_score_o <= '0';
                sub_score_o <= '0';
            
            else
            
                if idx_i /= 1 then
        
                    -- shift ph and mh
                    ph <= (std_logic_vector(shift_left(unsigned(ph), 1)) and '1');
                    mh <= (std_logic_vector(shift_left(unsigned(mh), 1)) and '0');
                    
                    -- update pv and mv
                    pv <= mh or (not (xv_i or ph));
                    mv <= ph and xv_i;
                else 
                
                    pv <= pv_i;
                    mv <= mv_i;
                end if;
                
                -- get eq and idx
                eq <= peq_i(to_integer(unsigned(s1_i(idx_i))));
        
                -- compute xv and xh
                xv_o <= eq or mv_i;
                xh <= std_logic_vector(
                    (((unsigned(eq) and unsigned(pv)) + unsigned(pv)) xor unsigned(pv)) or unsigned(eq)
                );
                
                -- compute new ph and mh
                ph_o <= mv or (not (xh or pv));
                mh_o <= pv and xh;
                
                -- try to update score instantly ? no pipeline
                -- update score 
                add_score_o <= ph_o(strand_len - 1);
                sub_score_o <= mh_o(strand_len - 1);
            end if;
            
        end if;
    end process proc_core;
    
    ---------------------------------------------------------------------------------
    -- score
    ---------------------------------------------------------------------------------

    proc_score : process(clk_i)
    begin
    
        if rising_edge(clk_i) then
    
            if rst_i = '1' then
                score_o <= strand_len;
            
            else
            
                if add_score_i = '1' then
                    score_o <= score_i + 1;
                end if;
            
                if sub_score_i = '1' then
                    score_o <= score_i - 1;
                end if;
            
            end if;     
        end if;
        
    end process proc_score;

end behavioral;
