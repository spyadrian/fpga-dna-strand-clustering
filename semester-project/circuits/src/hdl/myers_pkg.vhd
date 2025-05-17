library myers;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;


package myers_pkg is

    ---------------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------------

    constant STRAND_LEN : integer := 207;
    constant CHAR_SIZE  : integer := 2;
    
    constant A_CODE : std_logic_vector := "00";
    constant C_CODE : std_logic_vector := "01";
    constant G_CODE : std_logic_vector := "10";
    constant T_CODE : std_logic_vector := "11";

    ---------------------------------------------------------------------------------
    -- Types
    ---------------------------------------------------------------------------------

    subtype strand_char is std_logic_vector(CHAR_SIZE - 1 downto 0);
    subtype strand_vector is std_logic_vector(STRAND_LEN - 1 downto 0);
    -- subtype strand is std_logic_vector(STRAND_LEN * CHAR_SIZE - 1 downto 0);

    type strand is array (0 to STRAND_LEN - 1) of strand_char;
    type peq_array is array (0 to STRAND_LEN - 1) of strand_vector;

    ---------------------------------------------------------------------------------
    -- Functions
    ---------------------------------------------------------------------------------

    function shift_Ph(Ph : strand_vector) return strand_vector;
    function shift_Mh(Mh : strand_vector) return strand_vector;

    function update_Pv(Mh, Xv, Ph : strand_vector) return strand_vector;
    function update_Mv(Ph, Xv : strand_vector) return strand_vector;

    function get_Eq(Peq : peq_array; s : strand; idx : integer) return strand_vector;

    function compute_Xv(Eq, Mv : strand_vector) return strand_vector;
    function compute_Xh(Eq, Pv : strand_vector) return strand_vector;

    function compute_Ph(Mv, Xh, Pv : strand_vector) return strand_vector;
    function compute_Mh(Pv, Xh : strand_vector) return strand_vector;

    function populate_Peq(s : strand) return peq_array;

    ---------------------------------------------------------------------------------
    -- Procedures
    ---------------------------------------------------------------------------------

    -- ...

end myers_pkg;


package body myers_pkg is

    ---------------------------------------------------------------------------------
    -- Functions
    ---------------------------------------------------------------------------------

    function shift_Ph(Ph : strand_vector) return strand_vector is
    begin 
        return (Ph(STRAND_LEN - 2 downto 0) & '1');
    end function;
    
    function shift_Mh(Mh : strand_vector) return strand_vector is 
    begin
        return (Mh(STRAND_LEN - 2 downto 0) & '0');
    end function;


    function update_Pv(Mh, Xv, Ph : strand_vector) return strand_vector is
    begin
        return Mh or not (Xv or Ph);
    end function;

    function update_Mv(Ph, Xv : strand_vector) return strand_vector is
    begin
        return Ph and Xv;
    end function;


    function get_Eq(Peq : peq_array; s : strand; idx : integer) return strand_vector is
    begin
        return Peq(to_integer(unsigned(s(idx))));
    end function;


    function compute_Xv(Eq, Mv : strand_vector) return strand_vector is
    begin
        return Eq or Mv;
    end function;

    function compute_Xh(Eq, Pv : strand_vector) return strand_vector is
    begin
        return std_logic_vector(
            (((unsigned(Eq) and unsigned(Pv)) + unsigned(Pv)) xor unsigned(Pv)) or unsigned(Eq)
        );
    end function;


    function compute_Ph(Mv, Xh, Pv : strand_vector) return strand_vector is
    begin
        return Mv or not (Xh or Pv);
    end function;

    function compute_Mh(Pv, Xh : strand_vector) return strand_vector is
    begin
        return Pv and Xh;
    end function;


    function populate_Peq(s : strand) return peq_array is

        variable Peq : peq_array := (others => (others => '0'));
    begin

        for j in 0 to STRAND_LEN - 1 loop
            case s(j) is
                when A_CODE => Peq(0)(j) := '1'; -- 'A'
                when C_CODE => Peq(1)(j) := '1'; -- 'C'
                when G_CODE => Peq(2)(j) := '1'; -- 'G'
                when T_CODE => Peq(3)(j) := '1'; -- 'T'
                when others => null;
            end case;
        end loop;

        return Peq;
    end function;
    

    ---------------------------------------------------------------------------------
    -- Procedures
    ---------------------------------------------------------------------------------

    -- ...

end package body;

