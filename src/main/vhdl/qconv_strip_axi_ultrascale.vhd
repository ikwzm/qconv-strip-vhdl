-----------------------------------------------------------------------------------
--!     @file    qconv_strip_axi_ultrascale.vhd
--!     @brief   Quantized Convolution (strip) AXI I/F UltraScale Wrapper Module
--!     @version 0.1.0
--!     @date    2019/4/9
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2018-2019 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
-----------------------------------------------------------------------------------
--! @brief 
-----------------------------------------------------------------------------------
entity  QCONV_STRIP_AXI_ULTRASCALE is
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        IN_C_UNROLL         : integer := 1;
        OUT_C_UNROLL        : integer := 8;
        S_AXI_ADDR_WIDTH    : integer := 12;
        S_AXI_DATA_WIDTH    : integer := 32;
        M_AXI_ADDR_WIDTH    : integer := 32;
        M_AXI_DATA_WIDTH    : integer := 64;
        I_AXI_PROT          : integer := 1;
        I_AXI_QOS           : integer := 0;
        I_AXI_REGION        : integer := 0;
        I_AXI_CACHE         : integer := 15;
        O_AXI_PROT          : integer := 1;
        O_AXI_QOS           : integer := 0;
        O_AXI_REGION        : integer := 0;
        O_AXI_CACHE         : integer := 15;
        K_AXI_PROT          : integer := 1;
        K_AXI_QOS           : integer := 0;
        K_AXI_REGION        : integer := 0;
        K_AXI_CACHE         : integer := 15;
        T_AXI_PROT          : integer := 1;
        T_AXI_QOS           : integer := 0;
        T_AXI_REGION        : integer := 0;
        T_AXI_CACHE         : integer := 15
    );
    port(
    -------------------------------------------------------------------------------
    -- Clock / Reset Signals.
    -------------------------------------------------------------------------------
        ACLK                : in  std_logic;
        ARESETn             : in  std_logic;
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        S_AXI_ARADDR        : in  std_logic_vector(S_AXI_ADDR_WIDTH  -1 downto 0);
        S_AXI_ARVALID       : in  std_logic;
        S_AXI_ARREADY       : out std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Data Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_RDATA         : out std_logic_vector(S_AXI_DATA_WIDTH  -1 downto 0);
        S_AXI_RRESP         : out std_logic_vector(1 downto 0);  
        S_AXI_RVALID        : out std_logic;
        S_AXI_RREADY        : in  std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Address Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_AWADDR        : in  std_logic_vector(S_AXI_ADDR_WIDTH  -1 downto 0);
        S_AXI_AWVALID       : in  std_logic;
        S_AXI_AWREADY       : out std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Data Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_WDATA         : in  std_logic_vector(S_AXI_DATA_WIDTH  -1 downto 0);
        S_AXI_WSTRB         : in  std_logic_vector(S_AXI_DATA_WIDTH/8-1 downto 0);
        S_AXI_WVALID        : in  std_logic;
        S_AXI_WREADY        : out std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Response Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_BRESP         : out std_logic_vector(1 downto 0);
        S_AXI_BVALID        : out std_logic;
        S_AXI_BREADY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_ARADDR       : out std_logic_vector(M_AXI_ADDR_WIDTH  -1 downto 0);
        IO_AXI_ARLEN        : out std_logic_vector(7 downto 0);
        IO_AXI_ARSIZE       : out std_logic_vector(2 downto 0);
        IO_AXI_ARBURST      : out std_logic_vector(1 downto 0);
        IO_AXI_ARLOCK       : out std_logic_vector(0 downto 0);
        IO_AXI_ARCACHE      : out std_logic_vector(3 downto 0);
        IO_AXI_ARPROT       : out std_logic_vector(2 downto 0);
        IO_AXI_ARQOS        : out std_logic_vector(3 downto 0);
        IO_AXI_ARREGION     : out std_logic_vector(3 downto 0);
        IO_AXI_ARVALID      : out std_logic;
        IO_AXI_ARREADY      : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_RDATA        : in  std_logic_vector(M_AXI_DATA_WIDTH  -1 downto 0);
        IO_AXI_RRESP        : in  std_logic_vector(1 downto 0);
        IO_AXI_RLAST        : in  std_logic;
        IO_AXI_RVALID       : in  std_logic;
        IO_AXI_RREADY       : out std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_AWADDR       : out std_logic_vector(M_AXI_ADDR_WIDTH  -1 downto 0);
        IO_AXI_AWLEN        : out std_logic_vector(7 downto 0);
        IO_AXI_AWSIZE       : out std_logic_vector(2 downto 0);
        IO_AXI_AWBURST      : out std_logic_vector(1 downto 0);
        IO_AXI_AWLOCK       : out std_logic_vector(0 downto 0);
        IO_AXI_AWCACHE      : out std_logic_vector(3 downto 0);
        IO_AXI_AWPROT       : out std_logic_vector(2 downto 0);
        IO_AXI_AWQOS        : out std_logic_vector(3 downto 0);
        IO_AXI_AWREGION     : out std_logic_vector(3 downto 0);
        IO_AXI_AWVALID      : out std_logic;
        IO_AXI_AWREADY      : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_WDATA        : out std_logic_vector(M_AXI_DATA_WIDTH  -1 downto 0);
        IO_AXI_WSTRB        : out std_logic_vector(M_AXI_DATA_WIDTH/8-1 downto 0);
        IO_AXI_WLAST        : out std_logic;
        IO_AXI_WVALID       : out std_logic;
        IO_AXI_WREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_BRESP        : in  std_logic_vector(1 downto 0);
        IO_AXI_BVALID       : in  std_logic;
        IO_AXI_BREADY       : out std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_ARADDR        : out std_logic_vector(M_AXI_ADDR_WIDTH  -1 downto 0);
        K_AXI_ARLEN         : out std_logic_vector(7 downto 0);
        K_AXI_ARSIZE        : out std_logic_vector(2 downto 0);
        K_AXI_ARBURST       : out std_logic_vector(1 downto 0);
        K_AXI_ARLOCK        : out std_logic_vector(0 downto 0);
        K_AXI_ARCACHE       : out std_logic_vector(3 downto 0);
        K_AXI_ARPROT        : out std_logic_vector(2 downto 0);
        K_AXI_ARQOS         : out std_logic_vector(3 downto 0);
        K_AXI_ARREGION      : out std_logic_vector(3 downto 0);
        K_AXI_ARVALID       : out std_logic;
        K_AXI_ARREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_RDATA         : in  std_logic_vector(M_AXI_DATA_WIDTH  -1 downto 0);
        K_AXI_RRESP         : in  std_logic_vector(1 downto 0);
        K_AXI_RLAST         : in  std_logic;
        K_AXI_RVALID        : in  std_logic;
        K_AXI_RREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_AWADDR        : out std_logic_vector(M_AXI_ADDR_WIDTH  -1 downto 0);
        K_AXI_AWLEN         : out std_logic_vector(7 downto 0);
        K_AXI_AWSIZE        : out std_logic_vector(2 downto 0);
        K_AXI_AWBURST       : out std_logic_vector(1 downto 0);
        K_AXI_AWLOCK        : out std_logic_vector(0 downto 0);
        K_AXI_AWCACHE       : out std_logic_vector(3 downto 0);
        K_AXI_AWPROT        : out std_logic_vector(2 downto 0);
        K_AXI_AWQOS         : out std_logic_vector(3 downto 0);
        K_AXI_AWREGION      : out std_logic_vector(3 downto 0);
        K_AXI_AWVALID       : out std_logic;
        K_AXI_AWREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_WDATA         : out std_logic_vector(M_AXI_DATA_WIDTH  -1 downto 0);
        K_AXI_WSTRB         : out std_logic_vector(M_AXI_DATA_WIDTH/8-1 downto 0);
        K_AXI_WLAST         : out std_logic;
        K_AXI_WVALID        : out std_logic;
        K_AXI_WREADY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_BRESP         : in  std_logic_vector(1 downto 0);
        K_AXI_BVALID        : in  std_logic;
        K_AXI_BREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_ARADDR        : out std_logic_vector(M_AXI_ADDR_WIDTH  -1 downto 0);
        T_AXI_ARLEN         : out std_logic_vector(7 downto 0);
        T_AXI_ARSIZE        : out std_logic_vector(2 downto 0);
        T_AXI_ARBURST       : out std_logic_vector(1 downto 0);
        T_AXI_ARLOCK        : out std_logic_vector(0 downto 0);
        T_AXI_ARCACHE       : out std_logic_vector(3 downto 0);
        T_AXI_ARPROT        : out std_logic_vector(2 downto 0);
        T_AXI_ARQOS         : out std_logic_vector(3 downto 0);
        T_AXI_ARREGION      : out std_logic_vector(3 downto 0);
        T_AXI_ARVALID       : out std_logic;
        T_AXI_ARREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_RDATA         : in  std_logic_vector(M_AXI_DATA_WIDTH  -1 downto 0);
        T_AXI_RRESP         : in  std_logic_vector(1 downto 0);
        T_AXI_RLAST         : in  std_logic;
        T_AXI_RVALID        : in  std_logic;
        T_AXI_RREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_AWADDR        : out std_logic_vector(M_AXI_ADDR_WIDTH  -1 downto 0);
        T_AXI_AWLEN         : out std_logic_vector(7 downto 0);
        T_AXI_AWSIZE        : out std_logic_vector(2 downto 0);
        T_AXI_AWBURST       : out std_logic_vector(1 downto 0);
        T_AXI_AWLOCK        : out std_logic_vector(0 downto 0);
        T_AXI_AWCACHE       : out std_logic_vector(3 downto 0);
        T_AXI_AWPROT        : out std_logic_vector(2 downto 0);
        T_AXI_AWQOS         : out std_logic_vector(3 downto 0);
        T_AXI_AWREGION      : out std_logic_vector(3 downto 0);
        T_AXI_AWVALID       : out std_logic;
        T_AXI_AWREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_WDATA         : out std_logic_vector(M_AXI_DATA_WIDTH  -1 downto 0);
        T_AXI_WSTRB         : out std_logic_vector(M_AXI_DATA_WIDTH/8-1 downto 0);
        T_AXI_WLAST         : out std_logic;
        T_AXI_WVALID        : out std_logic;
        T_AXI_WREADY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_BRESP         : in  std_logic_vector(1 downto 0);
        T_AXI_BVALID        : in  std_logic;
        T_AXI_BREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- Interrupt Request
    -------------------------------------------------------------------------------
        interrupt           : out std_logic
    );
end  QCONV_STRIP_AXI_ULTRASCALE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library QCONV;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_AXI_CORE;
architecture RTL of QCONV_STRIP_AXI_ULTRASCALE is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  MIN(A,B: integer) return integer is
    begin
        if (A < B) then return A;
        else            return B;
        end if;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function CALC_BITS(SIZE:integer) return integer is
        variable bits : integer;
    begin
        bits := 0;
        while (2**bits < SIZE) loop
            bits := bits + 1;
        end loop;
        return bits;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  ID                    : string(1 to 8) := "QCONV-S2";
    constant  BUF_DEPTH             : integer := 512;
    constant  IN_BUF_SIZE           : integer := BUF_DEPTH*4*IN_C_UNROLL;
    constant  K_BUF_SIZE            : integer := BUF_DEPTH*3*3*OUT_C_UNROLL*IN_C_UNROLL;
    constant  TH_BUF_SIZE           : integer := BUF_DEPTH*OUT_C_UNROLL;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_AXI_XFER_SIZE       : integer := CALC_BITS(MIN(4096, ((IO_AXI_RDATA'length/8) * (2**IO_AXI_ARLEN'length))));
    constant  O_AXI_XFER_SIZE       : integer := CALC_BITS(MIN(4096, ((IO_AXI_WDATA'length/8) * (2**IO_AXI_ARLEN'length))));
    constant  K_AXI_XFER_SIZE       : integer := CALC_BITS(MIN(4096, (( K_AXI_RDATA'length/8) * (2** K_AXI_ARLEN'length))));
    constant  T_AXI_XFER_SIZE       : integer := CALC_BITS(MIN(4096, (( T_AXI_RDATA'length/8) * (2** T_AXI_ARLEN'length))));

    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_AXI_REQ_QUEUE       : integer := 4;
    constant  O_AXI_REQ_QUEUE       : integer := 4;
    constant  K_AXI_REQ_QUEUE       : integer := 4;
    constant  T_AXI_REQ_QUEUE       : integer := 1;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_AXI_USER_WIDTH      : integer := 8;
    constant  O_AXI_USER_WIDTH      : integer := 8;
    constant  K_AXI_USER_WIDTH      : integer := 8;
    constant  T_AXI_USER_WIDTH      : integer := 8;

    constant  S_AXI_ID_WIDTH        : integer := 4;
    constant  I_AXI_ID_WIDTH        : integer := 4;
    constant  O_AXI_ID_WIDTH        : integer := 4;
    constant  K_AXI_ID_WIDTH        : integer := 4;
    constant  T_AXI_ID_WIDTH        : integer := 4;

    constant  I_AXI_ID              : integer := 0;
    constant  O_AXI_ID              : integer := 0;
    constant  K_AXI_ID              : integer := 0;
    constant  T_AXI_ID              : integer := 0;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  S_AXI_ARID            : std_logic_vector(S_AXI_ID_WIDTH-1 downto 0) := (others => '0');
    constant  S_AXI_AWID            : std_logic_vector(S_AXI_ID_WIDTH-1 downto 0) := (others => '0');
    signal    S_AXI_RID             : std_logic_vector(S_AXI_ID_WIDTH-1 downto 0);
    signal    S_AXI_BID             : std_logic_vector(S_AXI_ID_WIDTH-1 downto 0);
    constant  S_AXI_ARLEN           : std_logic_vector(7 downto 0) := (others => '0');
    constant  S_AXI_ARSIZE          : std_logic_vector(2 downto 0) := "010";
    constant  S_AXI_ARBURST         : std_logic_vector(1 downto 0) := "01";
    signal    S_AXI_RLAST           : std_logic;
    constant  S_AXI_AWLEN           : std_logic_vector(7 downto 0) := (others => '0');
    constant  S_AXI_AWSIZE          : std_logic_vector(2 downto 0) := "010";
    constant  S_AXI_AWBURST         : std_logic_vector(1 downto 0) := "01";
    constant  S_AXI_WLAST           : std_logic := '1';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    IO_AXI_ARID           : std_logic_vector(I_AXI_ID_WIDTH-1 downto 0);
    signal    IO_AXI_AWID           : std_logic_vector(O_AXI_ID_WIDTH-1 downto 0);
    signal    IO_AXI_WID            : std_logic_vector(O_AXI_ID_WIDTH-1 downto 0);
    constant  IO_AXI_RID            : std_logic_vector(I_AXI_ID_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(I_AXI_ID, I_AXI_ID_WIDTH));
    constant  IO_AXI_BID            : std_logic_vector(O_AXI_ID_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(O_AXI_ID, O_AXI_ID_WIDTH));
    signal    IO_AXI_ARUSER         : std_logic_vector(I_AXI_USER_WIDTH-1 downto 0);
    signal    IO_AXI_AWUSER         : std_logic_vector(O_AXI_USER_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    K_AXI_ARID            : std_logic_vector(K_AXI_ID_WIDTH-1 downto 0);
    signal    K_AXI_AWID            : std_logic_vector(K_AXI_ID_WIDTH-1 downto 0);
    signal    K_AXI_WID             : std_logic_vector(K_AXI_ID_WIDTH-1 downto 0);
    constant  K_AXI_RID             : std_logic_vector(K_AXI_ID_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(K_AXI_ID, K_AXI_ID_WIDTH));
    constant  K_AXI_BID             : std_logic_vector(K_AXI_ID_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(K_AXI_ID, K_AXI_ID_WIDTH));
    signal    K_AXI_ARUSER          : std_logic_vector(K_AXI_USER_WIDTH-1 downto 0);
    signal    K_AXI_AWUSER          : std_logic_vector(K_AXI_USER_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    T_AXI_ARID            : std_logic_vector(T_AXI_ID_WIDTH-1 downto 0);
    signal    T_AXI_AWID            : std_logic_vector(T_AXI_ID_WIDTH-1 downto 0);
    signal    T_AXI_WID             : std_logic_vector(T_AXI_ID_WIDTH-1 downto 0);
    constant  T_AXI_RID             : std_logic_vector(T_AXI_ID_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(T_AXI_ID, T_AXI_ID_WIDTH));
    constant  T_AXI_BID             : std_logic_vector(T_AXI_ID_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(T_AXI_ID, T_AXI_ID_WIDTH));
    signal    T_AXI_ARUSER          : std_logic_vector(T_AXI_USER_WIDTH-1 downto 0);
    signal    T_AXI_AWUSER          : std_logic_vector(T_AXI_USER_WIDTH-1 downto 0);
begin

CORE: QCONV_STRIP_AXI_CORE 
    generic map (
        ID                  => ID                  , -- 
        IN_BUF_SIZE         => IN_BUF_SIZE         , -- 
        K_BUF_SIZE          => K_BUF_SIZE          , --   
        TH_BUF_SIZE         => TH_BUF_SIZE         , --   
        IN_C_UNROLL         => IN_C_UNROLL         , --   
        OUT_C_UNROLL        => OUT_C_UNROLL        , --   
        DATA_ADDR_WIDTH     => M_AXI_ADDR_WIDTH    , --   
        S_AXI_ADDR_WIDTH    => S_AXI_ADDR_WIDTH    , --   
        S_AXI_DATA_WIDTH    => S_AXI_DATA_WIDTH    , --   
        S_AXI_ID_WIDTH      => S_AXI_ID_WIDTH      , --   
        I_AXI_ADDR_WIDTH    => M_AXI_ADDR_WIDTH    , --   
        I_AXI_DATA_WIDTH    => M_AXI_DATA_WIDTH    , --   
        I_AXI_ID_WIDTH      => I_AXI_ID_WIDTH      , --   
        I_AXI_USER_WIDTH    => I_AXI_USER_WIDTH    , --   
        I_AXI_XFER_SIZE     => I_AXI_XFER_SIZE     , --   
        I_AXI_ID            => I_AXI_ID            , --   
        I_AXI_PROT          => I_AXI_PROT          , --   
        I_AXI_QOS           => I_AXI_QOS           , --   
        I_AXI_REGION        => I_AXI_REGION        , --   
        I_AXI_CACHE         => I_AXI_CACHE         , --   
        I_AXI_REQ_QUEUE     => I_AXI_REQ_QUEUE     , --   
        O_AXI_ADDR_WIDTH    => M_AXI_ADDR_WIDTH    , --   
        O_AXI_DATA_WIDTH    => M_AXI_DATA_WIDTH    , --   
        O_AXI_ID_WIDTH      => O_AXI_ID_WIDTH      , --   
        O_AXI_USER_WIDTH    => O_AXI_USER_WIDTH    , --   
        O_AXI_XFER_SIZE     => O_AXI_XFER_SIZE     , --   
        O_AXI_ID            => O_AXI_ID            , --   
        O_AXI_PROT          => O_AXI_PROT          , --   
        O_AXI_QOS           => O_AXI_QOS           , --   
        O_AXI_REGION        => O_AXI_REGION        , --   
        O_AXI_CACHE         => O_AXI_CACHE         , --   
        O_AXI_REQ_QUEUE     => O_AXI_REQ_QUEUE     , --   
        K_AXI_ADDR_WIDTH    => M_AXI_ADDR_WIDTH    , --   
        K_AXI_DATA_WIDTH    => M_AXI_DATA_WIDTH    , --   
        K_AXI_ID_WIDTH      => K_AXI_ID_WIDTH      , --   
        K_AXI_USER_WIDTH    => K_AXI_USER_WIDTH    , --   
        K_AXI_XFER_SIZE     => K_AXI_XFER_SIZE     , --   
        K_AXI_ID            => K_AXI_ID            , --   
        K_AXI_PROT          => K_AXI_PROT          , --   
        K_AXI_QOS           => K_AXI_QOS           , --   
        K_AXI_REGION        => K_AXI_REGION        , --   
        K_AXI_CACHE         => K_AXI_CACHE         , --   
        K_AXI_REQ_QUEUE     => K_AXI_REQ_QUEUE     , --   
        T_AXI_ADDR_WIDTH    => M_AXI_ADDR_WIDTH    , --   
        T_AXI_DATA_WIDTH    => M_AXI_DATA_WIDTH    , --   
        T_AXI_ID_WIDTH      => T_AXI_ID_WIDTH      , --   
        T_AXI_USER_WIDTH    => T_AXI_USER_WIDTH    , --   
        T_AXI_XFER_SIZE     => T_AXI_XFER_SIZE     , --   
        T_AXI_ID            => T_AXI_ID            , --   
        T_AXI_PROT          => T_AXI_PROT          , --   
        T_AXI_QOS           => T_AXI_QOS           , --   
        T_AXI_REGION        => T_AXI_REGION        , --   
        T_AXI_CACHE         => T_AXI_CACHE         , --   
        T_AXI_REQ_QUEUE     => T_AXI_REQ_QUEUE       --   
    )
    port map(
    -------------------------------------------------------------------------------
    -- Clock / Reset Signals.
    -------------------------------------------------------------------------------
        ACLK                => ACLK                , --   
        ARESETn             => ARESETn             , --   
    -------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        S_AXI_ARID          => S_AXI_ARID          , --   
        S_AXI_ARADDR        => S_AXI_ARADDR        , --   
        S_AXI_ARLEN         => S_AXI_ARLEN         , --   
        S_AXI_ARSIZE        => S_AXI_ARSIZE        , --   
        S_AXI_ARBURST       => S_AXI_ARBURST       , --   
        S_AXI_ARVALID       => S_AXI_ARVALID       , --   
        S_AXI_ARREADY       => S_AXI_ARREADY       , --   
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Data Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_RID           => S_AXI_RID           , --   
        S_AXI_RDATA         => S_AXI_RDATA         , --   
        S_AXI_RRESP         => S_AXI_RRESP         , --   
        S_AXI_RLAST         => S_AXI_RLAST         , --   
        S_AXI_RVALID        => S_AXI_RVALID        , --   
        S_AXI_RREADY        => S_AXI_RREADY        , --   
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Address Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_AWID          => S_AXI_AWID          , --   
        S_AXI_AWADDR        => S_AXI_AWADDR        , --   
        S_AXI_AWLEN         => S_AXI_AWLEN         , --   
        S_AXI_AWSIZE        => S_AXI_AWSIZE        , --   
        S_AXI_AWBURST       => S_AXI_AWBURST       , --   
        S_AXI_AWVALID       => S_AXI_AWVALID       , --   
        S_AXI_AWREADY       => S_AXI_AWREADY       , --   
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Data Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_WDATA         => S_AXI_WDATA         , --   
        S_AXI_WSTRB         => S_AXI_WSTRB         , --   
        S_AXI_WLAST         => S_AXI_WLAST         , --   
        S_AXI_WVALID        => S_AXI_WVALID        , --   
        S_AXI_WREADY        => S_AXI_WREADY        , --   
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Response Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_BID           => S_AXI_BID           , --   
        S_AXI_BRESP         => S_AXI_BRESP         , --   
        S_AXI_BVALID        => S_AXI_BVALID        , --   
        S_AXI_BREADY        => S_AXI_BREADY        , --   
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_ARID         => IO_AXI_ARID         , --   
        IO_AXI_ARADDR       => IO_AXI_ARADDR       , --   
        IO_AXI_ARLEN        => IO_AXI_ARLEN        , --   
        IO_AXI_ARSIZE       => IO_AXI_ARSIZE       , --   
        IO_AXI_ARBURST      => IO_AXI_ARBURST      , --   
        IO_AXI_ARLOCK       => IO_AXI_ARLOCK       , --   
        IO_AXI_ARCACHE      => IO_AXI_ARCACHE      , --   
        IO_AXI_ARPROT       => IO_AXI_ARPROT       , --   
        IO_AXI_ARQOS        => IO_AXI_ARQOS        , --   
        IO_AXI_ARREGION     => IO_AXI_ARREGION     , --   
        IO_AXI_ARUSER       => IO_AXI_ARUSER       , --   
        IO_AXI_ARVALID      => IO_AXI_ARVALID      , --   
        IO_AXI_ARREADY      => IO_AXI_ARREADY      , --   
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_RID          => IO_AXI_RID          , --   
        IO_AXI_RDATA        => IO_AXI_RDATA        , --   
        IO_AXI_RRESP        => IO_AXI_RRESP        , --   
        IO_AXI_RLAST        => IO_AXI_RLAST        , --   
        IO_AXI_RVALID       => IO_AXI_RVALID       , --   
        IO_AXI_RREADY       => IO_AXI_RREADY       , --   
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_AWID         => IO_AXI_AWID         , --   
        IO_AXI_AWADDR       => IO_AXI_AWADDR       , --   
        IO_AXI_AWLEN        => IO_AXI_AWLEN        , --   
        IO_AXI_AWSIZE       => IO_AXI_AWSIZE       , --   
        IO_AXI_AWBURST      => IO_AXI_AWBURST      , --   
        IO_AXI_AWLOCK       => IO_AXI_AWLOCK       , --   
        IO_AXI_AWCACHE      => IO_AXI_AWCACHE      , --   
        IO_AXI_AWPROT       => IO_AXI_AWPROT       , --   
        IO_AXI_AWQOS        => IO_AXI_AWQOS        , --   
        IO_AXI_AWREGION     => IO_AXI_AWREGION     , --   
        IO_AXI_AWUSER       => IO_AXI_AWUSER       , --   
        IO_AXI_AWVALID      => IO_AXI_AWVALID      , --   
        IO_AXI_AWREADY      => IO_AXI_AWREADY      , --   
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_WID          => IO_AXI_WID          , --   
        IO_AXI_WDATA        => IO_AXI_WDATA        , --   
        IO_AXI_WSTRB        => IO_AXI_WSTRB        , --   
        IO_AXI_WLAST        => IO_AXI_WLAST        , --   
        IO_AXI_WVALID       => IO_AXI_WVALID       , --   
        IO_AXI_WREADY       => IO_AXI_WREADY       , --   
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_BID          => IO_AXI_BID          , --   
        IO_AXI_BRESP        => IO_AXI_BRESP        , --   
        IO_AXI_BVALID       => IO_AXI_BVALID       , --   
        IO_AXI_BREADY       => IO_AXI_BREADY       , --   
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_ARID          => K_AXI_ARID          , --   
        K_AXI_ARADDR        => K_AXI_ARADDR        , --   
        K_AXI_ARLEN         => K_AXI_ARLEN         , --   
        K_AXI_ARSIZE        => K_AXI_ARSIZE        , --   
        K_AXI_ARBURST       => K_AXI_ARBURST       , --   
        K_AXI_ARLOCK        => K_AXI_ARLOCK        , --   
        K_AXI_ARCACHE       => K_AXI_ARCACHE       , --   
        K_AXI_ARPROT        => K_AXI_ARPROT        , --   
        K_AXI_ARQOS         => K_AXI_ARQOS         , --   
        K_AXI_ARREGION      => K_AXI_ARREGION      , --   
        K_AXI_ARUSER        => K_AXI_ARUSER        , --   
        K_AXI_ARVALID       => K_AXI_ARVALID       , --   
        K_AXI_ARREADY       => K_AXI_ARREADY       , --   
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_RID           => K_AXI_RID           , --   
        K_AXI_RDATA         => K_AXI_RDATA         , --   
        K_AXI_RRESP         => K_AXI_RRESP         , --   
        K_AXI_RLAST         => K_AXI_RLAST         , --   
        K_AXI_RVALID        => K_AXI_RVALID        , --   
        K_AXI_RREADY        => K_AXI_RREADY        , --   
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_AWID          => K_AXI_AWID          , --   
        K_AXI_AWADDR        => K_AXI_AWADDR        , --   
        K_AXI_AWLEN         => K_AXI_AWLEN         , --   
        K_AXI_AWSIZE        => K_AXI_AWSIZE        , --   
        K_AXI_AWBURST       => K_AXI_AWBURST       , --   
        K_AXI_AWLOCK        => K_AXI_AWLOCK        , --   
        K_AXI_AWCACHE       => K_AXI_AWCACHE       , --   
        K_AXI_AWPROT        => K_AXI_AWPROT        , --   
        K_AXI_AWQOS         => K_AXI_AWQOS         , --   
        K_AXI_AWREGION      => K_AXI_AWREGION      , --   
        K_AXI_AWUSER        => K_AXI_AWUSER        , --   
        K_AXI_AWVALID       => K_AXI_AWVALID       , --   
        K_AXI_AWREADY       => K_AXI_AWREADY       , --   
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_WID           => K_AXI_WID           , --   
        K_AXI_WDATA         => K_AXI_WDATA         , --   
        K_AXI_WSTRB         => K_AXI_WSTRB         , --   
        K_AXI_WLAST         => K_AXI_WLAST         , --   
        K_AXI_WVALID        => K_AXI_WVALID        , --   
        K_AXI_WREADY        => K_AXI_WREADY        , --   
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_BID           => K_AXI_BID           , --   
        K_AXI_BRESP         => K_AXI_BRESP         , --   
        K_AXI_BVALID        => K_AXI_BVALID        , --   
        K_AXI_BREADY        => K_AXI_BREADY        , --   
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_ARID          => T_AXI_ARID          , --   
        T_AXI_ARADDR        => T_AXI_ARADDR        , --   
        T_AXI_ARLEN         => T_AXI_ARLEN         , --   
        T_AXI_ARSIZE        => T_AXI_ARSIZE        , --   
        T_AXI_ARBURST       => T_AXI_ARBURST       , --   
        T_AXI_ARLOCK        => T_AXI_ARLOCK        , --   
        T_AXI_ARCACHE       => T_AXI_ARCACHE       , --   
        T_AXI_ARPROT        => T_AXI_ARPROT        , --   
        T_AXI_ARQOS         => T_AXI_ARQOS         , --   
        T_AXI_ARREGION      => T_AXI_ARREGION      , --   
        T_AXI_ARUSER        => T_AXI_ARUSER        , --   
        T_AXI_ARVALID       => T_AXI_ARVALID       , --   
        T_AXI_ARREADY       => T_AXI_ARREADY       , --   
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_RID           => T_AXI_RID           , --   
        T_AXI_RDATA         => T_AXI_RDATA         , --   
        T_AXI_RRESP         => T_AXI_RRESP         , --   
        T_AXI_RLAST         => T_AXI_RLAST         , --   
        T_AXI_RVALID        => T_AXI_RVALID        , --   
        T_AXI_RREADY        => T_AXI_RREADY        , --   
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_AWID          => T_AXI_AWID          , --   
        T_AXI_AWADDR        => T_AXI_AWADDR        , --   
        T_AXI_AWLEN         => T_AXI_AWLEN         , --   
        T_AXI_AWSIZE        => T_AXI_AWSIZE        , --   
        T_AXI_AWBURST       => T_AXI_AWBURST       , --   
        T_AXI_AWLOCK        => T_AXI_AWLOCK        , --   
        T_AXI_AWCACHE       => T_AXI_AWCACHE       , --   
        T_AXI_AWPROT        => T_AXI_AWPROT        , --   
        T_AXI_AWQOS         => T_AXI_AWQOS         , --   
        T_AXI_AWREGION      => T_AXI_AWREGION      , --   
        T_AXI_AWUSER        => T_AXI_AWUSER        , --   
        T_AXI_AWVALID       => T_AXI_AWVALID       , --   
        T_AXI_AWREADY       => T_AXI_AWREADY       , --   
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_WID           => T_AXI_WID           , --   
        T_AXI_WDATA         => T_AXI_WDATA         , --   
        T_AXI_WSTRB         => T_AXI_WSTRB         , --   
        T_AXI_WLAST         => T_AXI_WLAST         , --   
        T_AXI_WVALID        => T_AXI_WVALID        , --   
        T_AXI_WREADY        => T_AXI_WREADY        , --   
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_BID           => T_AXI_BID           , --   
        T_AXI_BRESP         => T_AXI_BRESP         , --   
        T_AXI_BVALID        => T_AXI_BVALID        , --   
        T_AXI_BREADY        => T_AXI_BREADY        , --   
    -------------------------------------------------------------------------------
    -- Interrupt Request
    -------------------------------------------------------------------------------
        IRQ                 => interrupt             --   
    );
end RTL;
