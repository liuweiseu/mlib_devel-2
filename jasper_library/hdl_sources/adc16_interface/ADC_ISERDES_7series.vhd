----------------------------------------------------------------------------
-- Import useful libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- entity declaraction
entity  ADC_ISERDES_7series  is

    port (
               -- System
               reset        :  in  std_logic;
               bitslip      :  in  std_logic;

               -- Clock inputs
               clkin        :  in  std_logic; -- line
               clkdiv       :  in  std_logic; -- frame

               -- Data (serial in, parallel out)
               s_data        :  in  std_logic;
               p_data        :  out std_logic_vector(7 downto 0)
    );

end  ADC_ISERDES_7series;

architecture ADC_ISERDES_arc of ADC_ISERDES_7series is

     -- Components

     component ISERDESE2 generic (
      DATA_RATE            : string;
      DATA_WIDTH           : integer;
      DYN_CLKDIV_INV_EN    : boolean;
      DYN_CLK_INV_EN       : boolean;
      INTERFACE_TYPE       : string;
      IOBDELAY             : string;
      NUM_CE               : integer;
      OFB_USED             : boolean;
      SERDES_MODE          : string
      );
     port (
      O            : out std_logic;
      Q1           : out std_logic;
      Q2           : out std_logic;
      Q3           : out std_logic;
      Q4           : out std_logic;
      Q5           : out std_logic;
      Q6           : out std_logic;
      Q7           : out std_logic;
      Q8           : out std_logic;
      SHIFTOUT1    : out std_logic;
      SHIFTOUT2    : out std_logic;
      BITSLIP      : in std_logic;
      CE1          : in std_logic;
      CLK          : in std_logic;
      CLKB         : in std_logic;
      OCLK         : in std_logic;
      OCLKB        : in std_logic;
      CLKDIVP      : in std_logic;
      CLKDIV       : in std_logic;
      DYNCLKSEL    : in std_logic;
      DYNCLKDIVSEL : in std_logic;
      SHIFTIN1     : in std_logic;
      SHIFTIN2     : in std_logic;
      RST          : in std_logic;
      D            : in std_logic;
      DDLY         : in std_logic;
      OFB          : in std_logic
      );
     end component;

     -- ISERDES Master
     signal iserdes_q         : std_logic_vector(7 downto 0);
     signal iserdes_d         : std_logic;
     signal iserdes_clk       : std_logic;
     signal iserdes_clk_inv   : std_logic;
     signal iserdes_rst       : std_logic;
     signal iserdes_clkdiv    : std_logic;
     signal iserdes_bitslip   : std_logic;

     signal iserdes_bitslip_d1 : std_logic;
     signal iserdes_bitslip_d2 : std_logic;
     signal iserdes_bitslip_d3 : std_logic;

     begin

     -- Signal routing
     iserdes_clk     <= clkin;
     iserdes_clk_inv <= not clkin;
     iserdes_clkdiv  <= clkdiv;
     iserdes_rst     <= reset;
     iserdes_d       <= s_data;
     -- iserdes_q is inverted, has MSb in bit 0 (due to differential-pair
     -- routing on ADC16 board, and is in straight offset binary.  Leave MSb
     -- inverted to convert to 2's complement, but invert/restore polarity of
     -- remaining bits and bit-reverse since ADC sends LSb first.
     -- SNAP: reverse the bit inversion described above, since the snap doesn't flip differential pairs
     p_data <= not iserdes_q(0) &
                   iserdes_q(1) &
                   iserdes_q(2) &
                   iserdes_q(3) &
                   iserdes_q(4) &
                   iserdes_q(5) &
                   iserdes_q(6) &
                   iserdes_q(7);

     process (clkdiv)
     begin
         if rising_edge(clkdiv) then
             iserdes_bitslip_d1 <= bitslip;
             iserdes_bitslip_d2 <= iserdes_bitslip_d1;
             iserdes_bitslip_d3 <= iserdes_bitslip_d2;
             iserdes_bitslip <= (not iserdes_bitslip_d3 and iserdes_bitslip_d2);
         end if;
     end process;

     -- ISERDESE1 Master
     iserdes_m_inst : ISERDESE2
     GENERIC MAP (
      DATA_RATE            => "DDR",
      DATA_WIDTH           => 8,
      DYN_CLKDIV_INV_EN    => false,
      DYN_CLK_INV_EN       => false,
      INTERFACE_TYPE       => "NETWORKING",
      IOBDELAY             => "IFD",
      NUM_CE               => 1,
      OFB_USED             => false,
      SERDES_MODE          => "MASTER"
      )
     PORT MAP (
      O            => open,
      Q1           => iserdes_q(0),
      Q2           => iserdes_q(1),
      Q3           => iserdes_q(2),
      Q4           => iserdes_q(3),
      Q5           => iserdes_q(4),
      Q6           => iserdes_q(5),
      Q7           => iserdes_q(6),
      Q8           => iserdes_q(7),
      SHIFTOUT1    => open,
      SHIFTOUT2    => open,
      BITSLIP      => iserdes_bitslip,
      CE1          => '1',
      --CE2          => '0', --Useless if NUM_CE = 1
      CLK          => iserdes_clk,
      CLKB         => iserdes_clk_inv,
      OCLK         => '0',
      OCLKB        => '0',
      CLKDIV       => iserdes_clkdiv,
      CLKDIVP      => '0',
      RST          => iserdes_rst,
      D            => '0',
      DDLY         => iserdes_d,
      DYNCLKDIVSEL => '0',
      DYNCLKSEL    => '0',
      OFB          => '0',
      SHIFTIN1     => '0',
      SHIFTIN2     => '0'
      );

end ADC_ISERDES_arc;

