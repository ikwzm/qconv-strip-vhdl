-----------------------------------------------------------------------------------
--!     @file    qconv_strip_core_test_bench.vhd
--!     @brief   Test Bench for Quantized Convolution (strip) Core Module
--!     @version 0.1.0
--!     @date    2019/4/19
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
entity  QCONV_STRIP_CORE_TEST_BENCH is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 1;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_CORE_TEST_BENCH;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library DUMMY_PLUG;
use     DUMMY_PLUG.SYNC.all;
use     DUMMY_PLUG.UTIL.all;
use     DUMMY_PLUG.AXI4_TYPES.all;
use     DUMMY_PLUG.CORE.MARCHAL;
use     DUMMY_PLUG.CORE.REPORT_STATUS_TYPE;
use     DUMMY_PLUG.CORE.REPORT_STATUS_VECTOR;
use     DUMMY_PLUG.CORE.MARGE_REPORT_STATUS;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_MASTER_PLAYER;
use     DUMMY_PLUG.AXI4_MODELS.AXI4_STREAM_SLAVE_PLAYER;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_REGISTER_INTERFACE;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
architecture MODEL of QCONV_STRIP_CORE_TEST_BENCH is
    -------------------------------------------------------------------------------
    -- 各種定数
    -------------------------------------------------------------------------------
    constant  PERIOD            :  time    := 10 ns;
    constant  DELAY             :  time    :=  1 ns;
    constant  SYNC_WIDTH        :  integer :=  2;
    constant  GPO_WIDTH         :  integer :=  8;
    constant  GPI_WIDTH         :  integer :=  GPO_WIDTH;
    ------------------------------------------------------------------------------
    -- 
    ------------------------------------------------------------------------------
    constant  QCONV_PARAM       :  QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
    constant  IN_BUF_SIZE       :  integer := 512*4*IN_C_UNROLL             ;
    constant  K_BUF_SIZE        :  integer := 512*9*IN_C_UNROLL*OUT_C_UNROLL;
    constant  TH_BUF_SIZE       :  integer := 512              *OUT_C_UNROLL;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal    CLK               :  std_logic;
    signal    RESET             :  std_logic;
    signal    ARESETn           :  std_logic;
    constant  CLEAR             :  std_logic := '0';
    ------------------------------------------------------------------------------
    -- CSR I/F 
    ------------------------------------------------------------------------------
    constant  C_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => 32,
                                     ARADDR      => 32,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => 32,
                                     RDATA       => 32,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    C_ARADDR          :  std_logic_vector(C_WIDTH.ARADDR -1 downto 0);
    signal    C_ARLEN           :  std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal    C_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    C_ARBURST         :  AXI4_ABURST_TYPE;
    signal    C_ARLOCK          :  std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal    C_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    C_ARPROT          :  AXI4_APROT_TYPE;
    signal    C_ARQOS           :  AXI4_AQOS_TYPE;
    signal    C_ARREGION        :  AXI4_AREGION_TYPE;
    signal    C_ARUSER          :  std_logic_vector(C_WIDTH.ARUSER -1 downto 0);
    signal    C_ARID            :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_ARVALID         :  std_logic;
    signal    C_ARREADY         :  std_logic;
    signal    C_RVALID          :  std_logic;
    signal    C_RLAST           :  std_logic;
    signal    C_RDATA           :  std_logic_vector(C_WIDTH.RDATA  -1 downto 0);
    signal    C_RRESP           :  AXI4_RESP_TYPE;
    signal    C_RUSER           :  std_logic_vector(C_WIDTH.RUSER  -1 downto 0);
    signal    C_RID             :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_RREADY          :  std_logic;
    signal    C_AWADDR          :  std_logic_vector(C_WIDTH.AWADDR -1 downto 0);
    signal    C_AWLEN           :  std_logic_vector(C_WIDTH.ALEN   -1 downto 0);
    signal    C_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    C_AWBURST         :  AXI4_ABURST_TYPE;
    signal    C_AWLOCK          :  std_logic_vector(C_WIDTH.ALOCK  -1 downto 0);
    signal    C_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    C_AWPROT          :  AXI4_APROT_TYPE;
    signal    C_AWQOS           :  AXI4_AQOS_TYPE;
    signal    C_AWREGION        :  AXI4_AREGION_TYPE;
    signal    C_AWUSER          :  std_logic_vector(C_WIDTH.AWUSER -1 downto 0);
    signal    C_AWID            :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_AWVALID         :  std_logic;
    signal    C_AWREADY         :  std_logic;
    signal    C_WLAST           :  std_logic;
    signal    C_WDATA           :  std_logic_vector(C_WIDTH.WDATA  -1 downto 0);
    signal    C_WSTRB           :  std_logic_vector(C_WIDTH.WDATA/8-1 downto 0);
    signal    C_WUSER           :  std_logic_vector(C_WIDTH.WUSER  -1 downto 0);
    signal    C_WID             :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_WVALID          :  std_logic;
    signal    C_WREADY          :  std_logic;
    signal    C_BRESP           :  AXI4_RESP_TYPE;
    signal    C_BUSER           :  std_logic_vector(C_WIDTH.BUSER  -1 downto 0);
    signal    C_BID             :  std_logic_vector(C_WIDTH.ID     -1 downto 0);
    signal    C_BVALID          :  std_logic;
    signal    C_BREADY          :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    IN_C_BY_WORD      :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
    signal    IN_W              :  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
    signal    IN_H              :  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
    signal    OUT_C             :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    OUT_W             :  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
    signal    OUT_H             :  std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
    signal    K_W               :  std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
    signal    K_H               :  std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
    signal    PAD_SIZE          :  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
    signal    USE_TH            :  std_logic;
    constant  PARAM_IN          :  std_logic := '1';
    signal    REQ_VALID         :  std_logic;
    signal    REQ_READY         :  std_logic;
    signal    RES_VALID         :  std_logic;
    signal    RES_READY         :  std_logic;
    signal    IRQ               :  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
    constant  I_WIDTH           :  AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                      ID         => 4,
                                      USER       => 4,
                                      DEST       => 4,
                                      DATA       => QCONV_PARAM.NBITS_IN_DATA*QCONV_PARAM.NBITS_PER_WORD
                                   );
    signal    I_DATA            :  std_logic_vector(I_WIDTH.DATA  -1 downto 0);
    signal    I_STRB            :  std_logic_vector(I_WIDTH.DATA/8-1 downto 0);
    signal    I_KEEP            :  std_logic_vector(I_WIDTH.DATA/8-1 downto 0);
    signal    I_USER            :  std_logic_vector(I_WIDTH.USER  -1 downto 0);
    signal    I_ID              :  std_logic_vector(I_WIDTH.ID    -1 downto 0);
    signal    I_DEST            :  std_logic_vector(I_WIDTH.DEST  -1 downto 0);
    signal    I_LAST            :  std_logic;
    signal    I_VALID           :  std_logic;
    signal    I_READY           :  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
    constant  K_WIDTH           :  AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                      ID         => 4,
                                      USER       => 4,
                                      DEST       => 4,
                                      DATA       => QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD
                                   );
    signal    K_DATA            :  std_logic_vector(K_WIDTH.DATA  -1 downto 0);
    signal    K_STRB            :  std_logic_vector(K_WIDTH.DATA/8-1 downto 0);
    signal    K_KEEP            :  std_logic_vector(K_WIDTH.DATA/8-1 downto 0);
    signal    K_USER            :  std_logic_vector(K_WIDTH.USER  -1 downto 0);
    signal    K_ID              :  std_logic_vector(K_WIDTH.ID    -1 downto 0);
    signal    K_DEST            :  std_logic_vector(K_WIDTH.DEST  -1 downto 0);
    signal    K_LAST            :  std_logic;
    signal    K_VALID           :  std_logic;
    signal    K_READY           :  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
    constant  T_WIDTH           :  AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                      ID         => 4,
                                      USER       => 4,
                                      DEST       => 4,
                                      DATA       => QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS
                                   );
    signal    T_DATA            :  std_logic_vector(T_WIDTH.DATA  -1 downto 0);
    signal    T_STRB            :  std_logic_vector(T_WIDTH.DATA/8-1 downto 0);
    signal    T_KEEP            :  std_logic_vector(T_WIDTH.DATA/8-1 downto 0);
    signal    T_USER            :  std_logic_vector(T_WIDTH.USER  -1 downto 0);
    signal    T_ID              :  std_logic_vector(T_WIDTH.ID    -1 downto 0);
    signal    T_DEST            :  std_logic_vector(T_WIDTH.DEST  -1 downto 0);
    signal    T_LAST            :  std_logic;
    signal    T_VALID           :  std_logic;
    signal    T_READY           :  std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
    constant  O_WIDTH           :  AXI4_STREAM_SIGNAL_WIDTH_TYPE := (
                                      ID         => 4,
                                      USER       => 4,
                                      DEST       => 4,
                                      DATA       => 64
                                   );
    signal    O_DATA            :  std_logic_vector(O_WIDTH.DATA  -1 downto 0);
    constant  O_STRB            :  std_logic_vector(O_WIDTH.DATA/8-1 downto 0) := (others => '1');
    constant  O_KEEP            :  std_logic_vector(O_WIDTH.DATA/8-1 downto 0) := (others => '1');
    constant  O_USER            :  std_logic_vector(O_WIDTH.USER  -1 downto 0) := (others => '0');
    constant  O_ID              :  std_logic_vector(O_WIDTH.ID    -1 downto 0) := (others => '0');
    constant  O_DEST            :  std_logic_vector(O_WIDTH.DEST  -1 downto 0) := (others => '0');
    signal    O_LAST            :  std_logic;
    signal    O_VALID           :  std_logic;
    signal    O_READY           :  std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal    SYNC              :  SYNC_SIG_VECTOR (SYNC_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal    C_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    C_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    I_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    I_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    K_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    K_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    T_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    T_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    signal    O_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    O_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
    -------------------------------------------------------------------------------
    -- 各種状態出力.
    -------------------------------------------------------------------------------
    signal    N_REPORT          :  REPORT_STATUS_TYPE;
    signal    C_REPORT          :  REPORT_STATUS_TYPE;
    signal    I_REPORT          :  REPORT_STATUS_TYPE;
    signal    K_REPORT          :  REPORT_STATUS_TYPE;
    signal    T_REPORT          :  REPORT_STATUS_TYPE;
    signal    O_REPORT          :  REPORT_STATUS_TYPE;
    signal    N_FINISH          :  std_logic;
    signal    C_FINISH          :  std_logic;
    signal    I_FINISH          :  std_logic;
    signal    K_FINISH          :  std_logic;
    signal    T_FINISH          :  std_logic;
    signal    O_FINISH          :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT : entity QCONV.QCONV_STRIP_CORE              -- 
        generic map (                                -- 
            QCONV_PARAM         => QCONV_PARAM     , --
            IN_BUF_SIZE         => IN_BUF_SIZE     , --
            K_BUF_SIZE          => K_BUF_SIZE      , --
            TH_BUF_SIZE         => TH_BUF_SIZE     , --
            IN_C_UNROLL         => IN_C_UNROLL     , --
            OUT_C_UNROLL        => OUT_C_UNROLL    , --
            OUT_DATA_BITS       => O_WIDTH.DATA      --
        )                                            -- 
        port map (
        -------------------------------------------------------------------------------
        -- クロック&リセット信号
        -------------------------------------------------------------------------------
            CLK                 => CLK             , -- In  :
            RST                 => RESET           , -- In  :
            CLR                 => CLEAR           , -- In  :
        -------------------------------------------------------------------------------
        -- 
        -------------------------------------------------------------------------------
            IN_C_BY_WORD        => IN_C_BY_WORD    , -- In  :
            IN_W                => IN_W            , -- In  :
            IN_H                => IN_H            , -- In  :
            OUT_C               => OUT_C           , -- In  :
            OUT_W               => OUT_W           , -- In  :
            OUT_H               => OUT_H           , -- In  :
            K_W                 => K_W             , -- In  :
            K_H                 => K_H             , -- In  :
            LEFT_PAD_SIZE       => PAD_SIZE        , -- In  :
            RIGHT_PAD_SIZE      => PAD_SIZE        , -- In  :
            TOP_PAD_SIZE        => PAD_SIZE        , -- In  :
            BOTTOM_PAD_SIZE     => PAD_SIZE        , -- In  :
            USE_TH              => USE_TH          , -- In  :
            PARAM_IN            => PARAM_IN        , -- In  :
            REQ_VALID           => REQ_VALID       , -- In  :
            REQ_READY           => REQ_READY       , -- Out :
            RES_VALID           => RES_VALID       , -- Out :
            RES_READY           => RES_READY       , -- In  :
        -------------------------------------------------------------------------------
        -- 入力側 I/F
        -------------------------------------------------------------------------------
            IN_DATA             => I_DATA          , -- In  :
            IN_VALID            => I_VALID         , -- In  :
            IN_READY            => I_READY         , -- Out :
        -------------------------------------------------------------------------------
        -- カーネル係数入力 I/F
        -------------------------------------------------------------------------------
            K_DATA              => K_DATA          , -- In  :
            K_VALID             => K_VALID         , -- In  :
            K_READY             => K_READY         , -- Out :
        -------------------------------------------------------------------------------
        -- スレッシュホールド係数入力 I/F
        -------------------------------------------------------------------------------
            TH_DATA             => T_DATA          , -- In  :
            TH_VALID            => T_VALID         , -- In  :
            TH_READY            => T_READY         , -- Out :
        -------------------------------------------------------------------------------
        -- 出力側 I/F
        -------------------------------------------------------------------------------
            OUT_DATA            => O_DATA          , -- Out :
            OUT_LAST            => O_LAST          , -- Out :
            OUT_VALID           => O_VALID         , -- Out :
            OUT_READY           => O_READY           -- In  :
        );
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    N: MARCHAL                                       -- 
        generic map(                                 -- 
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "MARCHAL"       , -- 
            SYNC_PLUG_NUM       => 1               , -- 
            SYNC_WIDTH          => SYNC_WIDTH      , --
            FINISH_ABORT        => FALSE             -- 
        )                                            -- 
        port map(                                    -- 
            CLK                 => CLK             , -- In  :
            RESET               => RESET           , -- In  :
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
            REPORT_STATUS       => N_REPORT        , -- Out :
            FINISH              => N_FINISH          -- Out :
        );                                           -- 
    ------------------------------------------------------------------------------
    -- AXI4_MASTER_PLAYER
    ------------------------------------------------------------------------------
    C: AXI4_MASTER_PLAYER                            -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "CSR"           , -- 
            READ_ENABLE         => TRUE            , -- 
            WRITE_ENABLE        => TRUE            , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => C_WIDTH         , -- 
            SYNC_PLUG_NUM       => 2               , -- 
            SYNC_WIDTH          => SYNC_WIDTH      , -- 
            GPI_WIDTH           => GPI_WIDTH       , -- 
            GPO_WIDTH           => GPO_WIDTH       , -- 
            FINISH_ABORT        => FALSE             -- 
        )                                            -- 
        port map(                                    -- 
        ---------------------------------------------------------------------------
        -- グローバルシグナル.
        ---------------------------------------------------------------------------
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
        ---------------------------------------------------------------------------
        -- リードアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            ARADDR              => C_ARADDR        , -- I/O : 
            ARLEN               => C_ARLEN         , -- I/O : 
            ARSIZE              => C_ARSIZE        , -- I/O : 
            ARBURST             => C_ARBURST       , -- I/O : 
            ARLOCK              => C_ARLOCK        , -- I/O : 
            ARCACHE             => C_ARCACHE       , -- I/O : 
            ARPROT              => C_ARPROT        , -- I/O : 
            ARQOS               => C_ARQOS         , -- I/O : 
            ARREGION            => C_ARREGION      , -- I/O : 
            ARUSER              => C_ARUSER        , -- I/O : 
            ARID                => C_ARID          , -- I/O : 
            ARVALID             => C_ARVALID       , -- I/O : 
            ARREADY             => C_ARREADY       , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => C_RLAST         , -- In  :    
            RDATA               => C_RDATA         , -- In  :    
            RRESP               => C_RRESP         , -- In  :    
            RUSER               => C_RUSER         , -- In  :    
            RID                 => C_RID           , -- In  :    
            RVALID              => C_RVALID        , -- In  :    
            RREADY              => C_RREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR              => C_AWADDR        , -- I/O : 
            AWLEN               => C_AWLEN         , -- I/O : 
            AWSIZE              => C_AWSIZE        , -- I/O : 
            AWBURST             => C_AWBURST       , -- I/O : 
            AWLOCK              => C_AWLOCK        , -- I/O : 
            AWCACHE             => C_AWCACHE       , -- I/O : 
            AWPROT              => C_AWPROT        , -- I/O : 
            AWQOS               => C_AWQOS         , -- I/O : 
            AWREGION            => C_AWREGION      , -- I/O : 
            AWUSER              => C_AWUSER        , -- I/O : 
            AWID                => C_AWID          , -- I/O : 
            AWVALID             => C_AWVALID       , -- I/O : 
            AWREADY             => C_AWREADY       , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST               => C_WLAST         , -- I/O : 
            WDATA               => C_WDATA         , -- I/O : 
            WSTRB               => C_WSTRB         , -- I/O : 
            WUSER               => C_WUSER         , -- I/O : 
            WID                 => C_WID           , -- I/O : 
            WVALID              => C_WVALID        , -- I/O : 
            WREADY              => C_WREADY        , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => C_BRESP         , -- In  :    
            BUSER               => C_BUSER         , -- In  :    
            BID                 => C_BID           , -- In  :    
            BVALID              => C_BVALID        , -- In  :    
            BREADY              => C_BREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => C_GPI           , -- In  :
            GPO                 => C_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => C_REPORT        , -- Out :
            FINISH              => C_FINISH          -- Out :
        );                                           -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    REGS: block
        constant  DATA_ADDR_WIDTH       :  integer := 64;
        constant  REGS_ADDR_WIDTH       :  integer := 7;
        constant  REGS_DATA_WIDTH       :  integer := 32;
        signal    regs_req              :  std_logic;
        signal    regs_write            :  std_logic;
        signal    regs_ack              :  std_logic;
        signal    regs_err              :  std_logic;
        signal    regs_addr             :  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
        signal    regs_ben              :  std_logic_vector(REGS_DATA_WIDTH/8-1 downto 0);
        signal    regs_wdata            :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        signal    regs_rdata            :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
    begin 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        AXI4: AXI4_REGISTER_INTERFACE                --
            generic map (                            -- 
                AXI4_ADDR_WIDTH => C_WIDTH.ARADDR  , --
                AXI4_DATA_WIDTH => C_WIDTH.RDATA   , --
                AXI4_ID_WIDTH   => C_WIDTH.ID      , --
                REGS_ADDR_WIDTH => REGS_ADDR_WIDTH , --
                REGS_DATA_WIDTH => REGS_DATA_WIDTH   --
            )                                        -- 
            port map (                               -- 
            -----------------------------------------------------------------------
            -- Clock and Reset Signals.
            -----------------------------------------------------------------------
                CLK             => CLK             , -- In  :
                RST             => RESET           , -- In  :
                CLR             => CLEAR           , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Read Address Channel Signals.
            -----------------------------------------------------------------------
                ARID            => C_ARID          , -- In  :
                ARADDR          => C_ARADDR        , -- In  :
                ARLEN           => C_ARLEN         , -- In  :
                ARSIZE          => C_ARSIZE        , -- In  :
                ARBURST         => C_ARBURST       , -- In  :
                ARVALID         => C_ARVALID       , -- In  :
                ARREADY         => C_ARREADY       , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Read Data Channel Signals.
            -----------------------------------------------------------------------
                RID             => C_RID           , -- Out :
                RDATA           => C_RDATA         , -- Out :
                RRESP           => C_RRESP         , -- Out :
                RLAST           => C_RLAST         , -- Out :
                RVALID          => C_RVALID        , -- Out :
                RREADY          => C_RREADY        , -- In  :
            -----------------------------------------------------------------------
            -- AXI4 Write Address Channel Signals.
            -----------------------------------------------------------------------
                AWID            => C_AWID          , -- In  :
                AWADDR          => C_AWADDR        , -- In  :
                AWLEN           => C_AWLEN         , -- In  :
                AWSIZE          => C_AWSIZE        , -- In  :
                AWBURST         => C_AWBURST       , -- In  :
                AWVALID         => C_AWVALID       , -- In  :
                AWREADY         => C_AWREADY       , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Write Data Channel Signals.
            -----------------------------------------------------------------------
                WDATA           => C_WDATA         , -- In  :
                WSTRB           => C_WSTRB         , -- In  :
                WLAST           => C_WLAST         , -- In  :
                WVALID          => C_WVALID        , -- In  :
                WREADY          => C_WREADY        , -- Out :
            -----------------------------------------------------------------------
            -- AXI4 Write Response Channel Signals.
            -----------------------------------------------------------------------
                BID             => C_BID           , -- Out :
                BRESP           => C_BRESP         , -- Out :
                BVALID          => C_BVALID        , -- Out :
                BREADY          => C_BREADY        , -- In  :
            -----------------------------------------------------------------------
            -- Register Interface.
            -----------------------------------------------------------------------
                REGS_REQ        => regs_req        , -- Out :
                REGS_WRITE      => regs_write      , -- Out :
                REGS_ACK        => regs_ack        , -- In  :
                REGS_ERR        => regs_err        , -- In  :
                REGS_ADDR       => regs_addr       , -- Out :
                REGS_BEN        => regs_ben        , -- Out :
                REGS_WDATA      => regs_wdata      , -- Out :
                REGS_RDATA      => regs_rdata        -- In  :
            );                                       -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        REGS: entity QCONV.QCONV_STRIP_REGISTERS     -- 
            generic map (                            -- 
                QCONV_PARAM     => QCONV_PARAM     , --
                DATA_ADDR_WIDTH => DATA_ADDR_WIDTH , -- 
                REGS_ADDR_WIDTH => REGS_ADDR_WIDTH , --
                REGS_DATA_WIDTH => REGS_DATA_WIDTH   --
            )                                        -- 
            port map (                               -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK             , -- In  :
                RST             => RESET           , -- In  :
                CLR             => CLEAR           , -- In  :
            -----------------------------------------------------------------------
            -- Register Access Interface
            -----------------------------------------------------------------------
                REGS_REQ        => regs_req        , -- In  :
                REGS_WRITE      => regs_write      , -- In  :
                REGS_ADDR       => regs_addr       , -- In  :
                REGS_BEN        => regs_ben        , -- In  :
                REGS_WDATA      => regs_wdata      , -- In  :
                REGS_RDATA      => regs_rdata      , -- Out :
                REGS_ACK        => regs_ack        , -- Out :
                REGS_ERR        => regs_err        , -- Out :
            -----------------------------------------------------------------------
            -- Quantized Convolution (strip) Registers
            -----------------------------------------------------------------------
                I_DATA_ADDR     => open            , -- Out :
                O_DATA_ADDR     => open            , -- Out :
                K_DATA_ADDR     => open            , -- Out :
                T_DATA_ADDR     => open            , -- Out :
                I_WIDTH         => IN_W            , -- Out :
                I_HEIGHT        => IN_H            , -- Out :
                I_CHANNELS      => IN_C_BY_WORD    , -- Out :
                O_WIDTH         => OUT_W           , -- Out :
                O_HEIGHT        => OUT_H           , -- Out :
                O_CHANNELS      => OUT_C           , -- Out :
                K_WIDTH         => K_W             , -- Out :
                K_HEIGHT        => K_H             , -- Out :
                PAD_SIZE        => PAD_SIZE        , -- Out :
                USE_TH          => USE_TH          , -- Out :
            -----------------------------------------------------------------------
            -- Quantized Convolution (strip) Request/Response Interface
            -----------------------------------------------------------------------
                REQ_VALID       => REQ_VALID       , -- Out :
                REQ_READY       => REQ_READY       , -- In  :
                RES_VALID       => RES_VALID       , -- In  :
                RES_READY       => RES_READY       , -- Out :
                RES_STATUS      => '0'             , -- In  :
                REQ_RESET       => open            , -- Out :
                REQ_STOP        => open            , -- Out :
                REQ_PAUSE       => open            , -- Out :
            -----------------------------------------------------------------------
            -- Interrupt Request 
            -----------------------------------------------------------------------
                IRQ             => IRQ               -- Out :
            );
    end block;                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I: AXI4_STREAM_MASTER_PLAYER                     -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , --
            NAME                => "IN"            , --
            OUTPUT_DELAY        => DELAY           , --
            SYNC_PLUG_NUM       => 3               , --
            WIDTH               => I_WIDTH         , --
            SYNC_WIDTH          => SYNC_WIDTH      , --
            GPI_WIDTH           => GPI_WIDTH       , --
            GPO_WIDTH           => GPO_WIDTH       , --
            FINISH_ABORT        => FALSE             --
        )                                            -- 
        port map(                                    -- 
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
            TDATA               => I_DATA          , -- I/O :
            TSTRB               => I_STRB          , -- I/O :
            TKEEP               => I_KEEP          , -- I/O :
            TUSER               => I_USER          , -- I/O :
            TDEST               => I_DEST          , -- I/O :
            TID                 => I_ID            , -- I/O :
            TLAST               => I_LAST          , -- I/O :
            TVALID              => I_VALID         , -- I/O :
            TREADY              => I_READY         , -- In  :
            SYNC                => SYNC            , -- I/O :
            GPI                 => I_GPI           , -- In  :
            GPO                 => I_GPO           , -- Out :
            REPORT_STATUS       => I_REPORT        , -- Out :
            FINISH              => I_FINISH          -- Out :
        );                                           --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    K: AXI4_STREAM_MASTER_PLAYER                     -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , --
            NAME                => "K"             , --
            OUTPUT_DELAY        => DELAY           , --
            SYNC_PLUG_NUM       => 4               , --
            WIDTH               => K_WIDTH         , --
            SYNC_WIDTH          => SYNC_WIDTH      , --
            GPI_WIDTH           => GPI_WIDTH       , --
            GPO_WIDTH           => GPO_WIDTH       , --
            FINISH_ABORT        => FALSE             --
        )                                            -- 
        port map(                                    -- 
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
            TDATA               => K_DATA          , -- I/O :
            TSTRB               => K_STRB          , -- I/O :
            TKEEP               => K_KEEP          , -- I/O :
            TUSER               => K_USER          , -- I/O :
            TDEST               => K_DEST          , -- I/O :
            TID                 => K_ID            , -- I/O :
            TLAST               => K_LAST          , -- I/O :
            TVALID              => K_VALID         , -- I/O :
            TREADY              => K_READY         , -- In  :
            SYNC                => SYNC            , -- I/O :
            GPI                 => K_GPI           , -- In  :
            GPO                 => K_GPO           , -- Out :
            REPORT_STATUS       => K_REPORT        , -- Out :
            FINISH              => K_FINISH          -- Out :
        );                                           --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    T: AXI4_STREAM_MASTER_PLAYER                     -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , --
            NAME                => "TH"            , --
            OUTPUT_DELAY        => DELAY           , --
            SYNC_PLUG_NUM       => 5               , --
            WIDTH               => T_WIDTH         , --
            SYNC_WIDTH          => SYNC_WIDTH      , --
            GPI_WIDTH           => GPI_WIDTH       , --
            GPO_WIDTH           => GPO_WIDTH       , --
            FINISH_ABORT        => FALSE             --
        )                                            -- 
        port map(                                    -- 
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
            TDATA               => T_DATA          , -- I/O :
            TSTRB               => T_STRB          , -- I/O :
            TKEEP               => T_KEEP          , -- I/O :
            TUSER               => T_USER          , -- I/O :
            TDEST               => T_DEST          , -- I/O :
            TID                 => T_ID            , -- I/O :
            TLAST               => T_LAST          , -- I/O :
            TVALID              => T_VALID         , -- I/O :
            TREADY              => T_READY         , -- In  :
            SYNC                => SYNC            , -- I/O :
            GPI                 => T_GPI           , -- In  :
            GPO                 => T_GPO           , -- Out :
            REPORT_STATUS       => T_REPORT        , -- Out :
            FINISH              => T_FINISH          -- Out :
        );                                           --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O: AXI4_STREAM_SLAVE_PLAYER                      -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , --
            NAME                => "OUT"           , --
            OUTPUT_DELAY        => DELAY           , --
            SYNC_PLUG_NUM       => 6               , --
            WIDTH               => O_WIDTH         , --
            SYNC_WIDTH          => SYNC_WIDTH      , --
            GPI_WIDTH           => GPI_WIDTH       , --
            GPO_WIDTH           => GPO_WIDTH       , --
            FINISH_ABORT        => FALSE             --
        )                                            -- 
        port map(                                    -- 
            ACLK                => CLK             , -- In  :
            ARESETn             => ARESETn         , -- In  :
            TDATA               => O_DATA          , -- In  :
            TSTRB               => O_STRB          , -- In  :
            TKEEP               => O_KEEP          , -- In  :
            TUSER               => O_USER          , -- In  :
            TDEST               => O_DEST          , -- In  :
            TID                 => O_ID            , -- In  :
            TLAST               => O_LAST          , -- In  :
            TVALID              => O_VALID         , -- In  :
            TREADY              => O_READY         , -- Out :
            SYNC                => SYNC            , -- I/O :
            GPI                 => O_GPI           , -- In  :
            GPO                 => O_GPO           , -- Out :
            REPORT_STATUS       => O_REPORT        , -- Out :
            FINISH              => O_FINISH          -- Out :
        );                                       --
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process begin
        loop
            CLK <= '0'; wait for PERIOD / 2;
            CLK <= '1'; wait for PERIOD / 2;
            exit when(N_FINISH = '1');
        end loop;
        CLK <= '0';
        wait;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    C_GPI(0)  <= IRQ;
    C_GPI(C_GPI'high downto 1) <= (C_GPI'high downto 1 => '0');
    I_GPI     <= (others => '0');
    K_GPI     <= (others => '0');
    T_GPI     <= (others => '0');
    O_GPI     <= (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ARESETn  <= '1' when (RESET = '0') else '0';

    process
        variable L   : LINE;
        constant T   : STRING(1 to 7) := "  ***  ";
    begin
        wait until (C_FINISH'event and C_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ CSR ]");                                       WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,C_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,C_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,C_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ IN ]");                                        WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,I_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,I_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,I_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ K ]");                                         WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,K_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,K_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,K_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ TH ]");                                        WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,T_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,T_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,T_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ OUT ]");                                       WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,O_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,O_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,O_REPORT.warning_count );WRITELINE(OUTPUT,L);
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        assert (C_REPORT.error_count    = 0 and
                I_REPORT.error_count    = 0 and
                K_REPORT.error_count    = 0 and
                T_REPORT.error_count    = 0 and
                O_REPORT.error_count    = 0)
            report "Simulation complete(error)."    severity FAILURE;
        assert (C_REPORT.mismatch_count = 0 and
                I_REPORT.mismatch_count = 0 and
                K_REPORT.mismatch_count = 0 and
                T_REPORT.mismatch_count = 0 and
                O_REPORT.mismatch_count = 0)
            report "Simulation complete(mismatch)." severity FAILURE;
        if (FINISH_ABORT) then
            assert FALSE report "Simulation complete(success)."  severity FAILURE;
        else
            assert FALSE report "Simulation complete(success)."  severity NOTE;
        end if;
        wait;
    end process;
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_CORE_TEST_BENCH_1_1 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 1;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_CORE_TEST_BENCH_1_1;
architecture MODEL of QCONV_STRIP_CORE_TEST_BENCH_1_1 is
begin
    TB: entity WORK.QCONV_STRIP_CORE_TEST_BENCH generic map (
        NAME            => NAME         , 
        SCENARIO_FILE   => SCENARIO_FILE,
        IN_C_UNROLL     => IN_C_UNROLL  ,
        OUT_C_UNROLL    => OUT_C_UNROLL ,
        FINISH_ABORT    => FINISH_ABORT
    );
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_CORE_TEST_BENCH_1_4 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 4;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_CORE_TEST_BENCH_1_4;
architecture MODEL of QCONV_STRIP_CORE_TEST_BENCH_1_4 is
begin
    TB: entity WORK.QCONV_STRIP_CORE_TEST_BENCH generic map (
        NAME            => NAME         , 
        SCENARIO_FILE   => SCENARIO_FILE,
        IN_C_UNROLL     => IN_C_UNROLL  ,
        OUT_C_UNROLL    => OUT_C_UNROLL ,
        FINISH_ABORT    => FINISH_ABORT
    );
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_CORE_TEST_BENCH_4_1 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        IN_C_UNROLL     : integer := 4;
        OUT_C_UNROLL    : integer := 1;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_CORE_TEST_BENCH_4_1;
architecture MODEL of QCONV_STRIP_CORE_TEST_BENCH_4_1 is
begin
    TB: entity WORK.QCONV_STRIP_CORE_TEST_BENCH generic map (
        NAME            => NAME         , 
        SCENARIO_FILE   => SCENARIO_FILE,
        IN_C_UNROLL     => IN_C_UNROLL  ,
        OUT_C_UNROLL    => OUT_C_UNROLL ,
        FINISH_ABORT    => FINISH_ABORT
    );
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_CORE_TEST_BENCH_2_2 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        IN_C_UNROLL     : integer := 2;
        OUT_C_UNROLL    : integer := 2;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_CORE_TEST_BENCH_2_2;
architecture MODEL of QCONV_STRIP_CORE_TEST_BENCH_2_2 is
begin
    TB: entity WORK.QCONV_STRIP_CORE_TEST_BENCH generic map (
        NAME            => NAME         , 
        SCENARIO_FILE   => SCENARIO_FILE,
        IN_C_UNROLL     => IN_C_UNROLL  ,
        OUT_C_UNROLL    => OUT_C_UNROLL ,
        FINISH_ABORT    => FINISH_ABORT
    );
end MODEL;
-----------------------------------------------------------------------------------
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_CORE_TEST_BENCH_1_8 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 8;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_CORE_TEST_BENCH_1_8;
architecture MODEL of QCONV_STRIP_CORE_TEST_BENCH_1_8 is
begin
    TB: entity WORK.QCONV_STRIP_CORE_TEST_BENCH generic map (
        NAME            => NAME         , 
        SCENARIO_FILE   => SCENARIO_FILE,
        IN_C_UNROLL     => IN_C_UNROLL  ,
        OUT_C_UNROLL    => OUT_C_UNROLL ,
        FINISH_ABORT    => FINISH_ABORT
    );
end MODEL;
