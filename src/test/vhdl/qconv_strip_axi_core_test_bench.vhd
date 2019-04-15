-----------------------------------------------------------------------------------
--!     @file    qconv_strip_axi_core_test_bench.vhd
--!     @brief   Test Bench for Quantized Convolution (strip) AXI Core Module
--!     @version 0.1.0
--!     @date    2019/4/15
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
entity  QCONV_STRIP_AXI_CORE_TEST_BENCH is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test_1_8_512.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 8;
        BUF_SIZE        : integer := 512;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_AXI_CORE_TEST_BENCH;
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
use     DUMMY_PLUG.AXI4_MODELS.AXI4_SLAVE_PLAYER;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_AXI_CORE;
architecture MODEL of QCONV_STRIP_AXI_CORE_TEST_BENCH is
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
    constant  AXI_ADDR_WIDTH    :  integer := 32;
    constant  AXI_DATA_WIDTH    :  integer := 64;
    constant  IN_BUF_SIZE       :  integer := BUF_SIZE*4*IN_C_UNROLL             ;
    constant  K_BUF_SIZE        :  integer := BUF_SIZE*9*IN_C_UNROLL*OUT_C_UNROLL;
    constant  TH_BUF_SIZE       :  integer := BUF_SIZE              *OUT_C_UNROLL;
    -------------------------------------------------------------------------------
    -- グローバルシグナル.
    -------------------------------------------------------------------------------
    signal    CLK               :  std_logic;
    signal    RESET             :  std_logic;
    signal    ARESETn           :  std_logic;
    constant  CLEAR             :  std_logic := '0';
    ------------------------------------------------------------------------------
    -- CSR AXI I/F 
    ------------------------------------------------------------------------------
    constant  S_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
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
    signal    S_ARADDR          :  std_logic_vector(S_WIDTH.ARADDR -1 downto 0);
    signal    S_ARLEN           :  std_logic_vector(S_WIDTH.ALEN   -1 downto 0);
    signal    S_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    S_ARBURST         :  AXI4_ABURST_TYPE;
    signal    S_ARLOCK          :  std_logic_vector(S_WIDTH.ALOCK  -1 downto 0);
    signal    S_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    S_ARPROT          :  AXI4_APROT_TYPE;
    signal    S_ARQOS           :  AXI4_AQOS_TYPE;
    signal    S_ARREGION        :  AXI4_AREGION_TYPE;
    signal    S_ARUSER          :  std_logic_vector(S_WIDTH.ARUSER -1 downto 0);
    signal    S_ARID            :  std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal    S_ARVALID         :  std_logic;
    signal    S_ARREADY         :  std_logic;
    signal    S_RVALID          :  std_logic;
    signal    S_RLAST           :  std_logic;
    signal    S_RDATA           :  std_logic_vector(S_WIDTH.RDATA  -1 downto 0);
    signal    S_RRESP           :  AXI4_RESP_TYPE;
    signal    S_RUSER           :  std_logic_vector(S_WIDTH.RUSER  -1 downto 0);
    signal    S_RID             :  std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal    S_RREADY          :  std_logic;
    signal    S_AWADDR          :  std_logic_vector(S_WIDTH.AWADDR -1 downto 0);
    signal    S_AWLEN           :  std_logic_vector(S_WIDTH.ALEN   -1 downto 0);
    signal    S_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    S_AWBURST         :  AXI4_ABURST_TYPE;
    signal    S_AWLOCK          :  std_logic_vector(S_WIDTH.ALOCK  -1 downto 0);
    signal    S_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    S_AWPROT          :  AXI4_APROT_TYPE;
    signal    S_AWQOS           :  AXI4_AQOS_TYPE;
    signal    S_AWREGION        :  AXI4_AREGION_TYPE;
    signal    S_AWUSER          :  std_logic_vector(S_WIDTH.AWUSER -1 downto 0);
    signal    S_AWID            :  std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal    S_AWVALID         :  std_logic;
    signal    S_AWREADY         :  std_logic;
    signal    S_WLAST           :  std_logic;
    signal    S_WDATA           :  std_logic_vector(S_WIDTH.WDATA  -1 downto 0);
    signal    S_WSTRB           :  std_logic_vector(S_WIDTH.WDATA/8-1 downto 0);
    signal    S_WUSER           :  std_logic_vector(S_WIDTH.WUSER  -1 downto 0);
    signal    S_WID             :  std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal    S_WVALID          :  std_logic;
    signal    S_WREADY          :  std_logic;
    signal    S_BRESP           :  AXI4_RESP_TYPE;
    signal    S_BUSER           :  std_logic_vector(S_WIDTH.BUSER  -1 downto 0);
    signal    S_BID             :  std_logic_vector(S_WIDTH.ID     -1 downto 0);
    signal    S_BVALID          :  std_logic;
    signal    S_BREADY          :  std_logic;
    signal    IRQ               :  std_logic;
    ------------------------------------------------------------------------------
    -- IN DATA AXI I/F 
    ------------------------------------------------------------------------------
    constant  I_AXI_ID          :  integer := 0;
    constant  I_AXI_PROT        :  integer := 0;
    constant  I_AXI_QOS         :  integer := 0;
    constant  I_AXI_REGION      :  integer := 1;
    constant  I_AXI_CACHE       :  integer := 15;
    constant  I_AXI_REQ_QUEUE   :  integer := 2;
    constant  I_AXI_XFER_SIZE   :  integer := 12;
    constant  I_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => AXI_ADDR_WIDTH,
                                     ARADDR      => AXI_ADDR_WIDTH,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => AXI_DATA_WIDTH,
                                     RDATA       => AXI_DATA_WIDTH,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    I_ARADDR          :  std_logic_vector(I_WIDTH.ARADDR -1 downto 0);
    signal    I_ARLEN           :  std_logic_vector(I_WIDTH.ALEN   -1 downto 0);
    signal    I_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    I_ARBURST         :  AXI4_ABURST_TYPE;
    signal    I_ARLOCK          :  std_logic_vector(I_WIDTH.ALOCK  -1 downto 0);
    signal    I_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    I_ARPROT          :  AXI4_APROT_TYPE;
    signal    I_ARQOS           :  AXI4_AQOS_TYPE;
    signal    I_ARREGION        :  AXI4_AREGION_TYPE;
    signal    I_ARUSER          :  std_logic_vector(I_WIDTH.ARUSER -1 downto 0);
    signal    I_ARID            :  std_logic_vector(I_WIDTH.ID     -1 downto 0);
    signal    I_ARVALID         :  std_logic;
    signal    I_ARREADY         :  std_logic;
    signal    I_RVALID          :  std_logic;
    signal    I_RLAST           :  std_logic;
    signal    I_RDATA           :  std_logic_vector(I_WIDTH.RDATA  -1 downto 0);
    signal    I_RRESP           :  AXI4_RESP_TYPE;
    signal    I_RUSER           :  std_logic_vector(I_WIDTH.RUSER  -1 downto 0);
    signal    I_RID             :  std_logic_vector(I_WIDTH.ID     -1 downto 0);
    signal    I_RREADY          :  std_logic;
    signal    I_AWADDR          :  std_logic_vector(I_WIDTH.AWADDR -1 downto 0);
    signal    I_AWLEN           :  std_logic_vector(I_WIDTH.ALEN   -1 downto 0);
    signal    I_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    I_AWBURST         :  AXI4_ABURST_TYPE;
    signal    I_AWLOCK          :  std_logic_vector(I_WIDTH.ALOCK  -1 downto 0);
    signal    I_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    I_AWPROT          :  AXI4_APROT_TYPE;
    signal    I_AWQOS           :  AXI4_AQOS_TYPE;
    signal    I_AWREGION        :  AXI4_AREGION_TYPE;
    signal    I_AWUSER          :  std_logic_vector(I_WIDTH.AWUSER -1 downto 0);
    signal    I_AWID            :  std_logic_vector(I_WIDTH.ID     -1 downto 0);
    signal    I_AWVALID         :  std_logic;
    signal    I_AWREADY         :  std_logic;
    signal    I_WLAST           :  std_logic;
    signal    I_WDATA           :  std_logic_vector(I_WIDTH.WDATA  -1 downto 0);
    signal    I_WSTRB           :  std_logic_vector(I_WIDTH.WDATA/8-1 downto 0);
    signal    I_WUSER           :  std_logic_vector(I_WIDTH.WUSER  -1 downto 0);
    signal    I_WID             :  std_logic_vector(I_WIDTH.ID     -1 downto 0);
    signal    I_WVALID          :  std_logic;
    signal    I_WREADY          :  std_logic;
    signal    I_BRESP           :  AXI4_RESP_TYPE;
    signal    I_BUSER           :  std_logic_vector(I_WIDTH.BUSER  -1 downto 0);
    signal    I_BID             :  std_logic_vector(I_WIDTH.ID     -1 downto 0);
    signal    I_BVALID          :  std_logic;
    signal    I_BREADY          :  std_logic;
    ------------------------------------------------------------------------------
    -- OUT DATA AXI I/F 
    ------------------------------------------------------------------------------
    constant  O_AXI_ID          :  integer := 0;
    constant  O_AXI_PROT        :  integer := 0;
    constant  O_AXI_QOS         :  integer := 0;
    constant  O_AXI_REGION      :  integer := 1;
    constant  O_AXI_CACHE       :  integer := 15;
    constant  O_AXI_REQ_QUEUE   :  integer := 2;
    constant  O_AXI_XFER_SIZE   :  integer := 12;
    constant  O_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => AXI_ADDR_WIDTH,
                                     ARADDR      => AXI_ADDR_WIDTH,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => AXI_DATA_WIDTH,
                                     RDATA       => AXI_DATA_WIDTH,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    O_ARADDR          :  std_logic_vector(O_WIDTH.ARADDR -1 downto 0);
    signal    O_ARLEN           :  std_logic_vector(O_WIDTH.ALEN   -1 downto 0);
    signal    O_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    O_ARBURST         :  AXI4_ABURST_TYPE;
    signal    O_ARLOCK          :  std_logic_vector(O_WIDTH.ALOCK  -1 downto 0);
    signal    O_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    O_ARPROT          :  AXI4_APROT_TYPE;
    signal    O_ARQOS           :  AXI4_AQOS_TYPE;
    signal    O_ARREGION        :  AXI4_AREGION_TYPE;
    signal    O_ARUSER          :  std_logic_vector(O_WIDTH.ARUSER -1 downto 0);
    signal    O_ARID            :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_ARVALID         :  std_logic;
    signal    O_ARREADY         :  std_logic;
    signal    O_RVALID          :  std_logic;
    signal    O_RLAST           :  std_logic;
    signal    O_RDATA           :  std_logic_vector(O_WIDTH.RDATA  -1 downto 0);
    signal    O_RRESP           :  AXI4_RESP_TYPE;
    signal    O_RUSER           :  std_logic_vector(O_WIDTH.RUSER  -1 downto 0);
    signal    O_RID             :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_RREADY          :  std_logic;
    signal    O_AWADDR          :  std_logic_vector(O_WIDTH.AWADDR -1 downto 0);
    signal    O_AWLEN           :  std_logic_vector(O_WIDTH.ALEN   -1 downto 0);
    signal    O_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    O_AWBURST         :  AXI4_ABURST_TYPE;
    signal    O_AWLOCK          :  std_logic_vector(O_WIDTH.ALOCK  -1 downto 0);
    signal    O_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    O_AWPROT          :  AXI4_APROT_TYPE;
    signal    O_AWQOS           :  AXI4_AQOS_TYPE;
    signal    O_AWREGION        :  AXI4_AREGION_TYPE;
    signal    O_AWUSER          :  std_logic_vector(O_WIDTH.AWUSER -1 downto 0);
    signal    O_AWID            :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_AWVALID         :  std_logic;
    signal    O_AWREADY         :  std_logic;
    signal    O_WLAST           :  std_logic;
    signal    O_WDATA           :  std_logic_vector(O_WIDTH.WDATA  -1 downto 0);
    signal    O_WSTRB           :  std_logic_vector(O_WIDTH.WDATA/8-1 downto 0);
    signal    O_WUSER           :  std_logic_vector(O_WIDTH.WUSER  -1 downto 0);
    signal    O_WID             :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_WVALID          :  std_logic;
    signal    O_WREADY          :  std_logic;
    signal    O_BRESP           :  AXI4_RESP_TYPE;
    signal    O_BUSER           :  std_logic_vector(O_WIDTH.BUSER  -1 downto 0);
    signal    O_BID             :  std_logic_vector(O_WIDTH.ID     -1 downto 0);
    signal    O_BVALID          :  std_logic;
    signal    O_BREADY          :  std_logic;
    ------------------------------------------------------------------------------
    -- K DATA AXI I/F 
    ------------------------------------------------------------------------------
    constant  K_AXI_ID          :  integer := 0;
    constant  K_AXI_PROT        :  integer := 0;
    constant  K_AXI_QOS         :  integer := 0;
    constant  K_AXI_REGION      :  integer := 1;
    constant  K_AXI_CACHE       :  integer := 15;
    constant  K_AXI_REQ_QUEUE   :  integer := 2;
    constant  K_AXI_XFER_SIZE   :  integer := 12;
    constant  K_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => AXI_ADDR_WIDTH,
                                     ARADDR      => AXI_ADDR_WIDTH,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => AXI_DATA_WIDTH,
                                     RDATA       => AXI_DATA_WIDTH,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    K_ARADDR          :  std_logic_vector(K_WIDTH.ARADDR -1 downto 0);
    signal    K_ARLEN           :  std_logic_vector(K_WIDTH.ALEN   -1 downto 0);
    signal    K_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    K_ARBURST         :  AXI4_ABURST_TYPE;
    signal    K_ARLOCK          :  std_logic_vector(K_WIDTH.ALOCK  -1 downto 0);
    signal    K_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    K_ARPROT          :  AXI4_APROT_TYPE;
    signal    K_ARQOS           :  AXI4_AQOS_TYPE;
    signal    K_ARREGION        :  AXI4_AREGION_TYPE;
    signal    K_ARUSER          :  std_logic_vector(K_WIDTH.ARUSER -1 downto 0);
    signal    K_ARID            :  std_logic_vector(K_WIDTH.ID     -1 downto 0);
    signal    K_ARVALID         :  std_logic;
    signal    K_ARREADY         :  std_logic;
    signal    K_RVALID          :  std_logic;
    signal    K_RLAST           :  std_logic;
    signal    K_RDATA           :  std_logic_vector(K_WIDTH.RDATA  -1 downto 0);
    signal    K_RRESP           :  AXI4_RESP_TYPE;
    signal    K_RUSER           :  std_logic_vector(K_WIDTH.RUSER  -1 downto 0);
    signal    K_RID             :  std_logic_vector(K_WIDTH.ID     -1 downto 0);
    signal    K_RREADY          :  std_logic;
    signal    K_AWADDR          :  std_logic_vector(K_WIDTH.AWADDR -1 downto 0);
    signal    K_AWLEN           :  std_logic_vector(K_WIDTH.ALEN   -1 downto 0);
    signal    K_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    K_AWBURST         :  AXI4_ABURST_TYPE;
    signal    K_AWLOCK          :  std_logic_vector(K_WIDTH.ALOCK  -1 downto 0);
    signal    K_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    K_AWPROT          :  AXI4_APROT_TYPE;
    signal    K_AWQOS           :  AXI4_AQOS_TYPE;
    signal    K_AWREGION        :  AXI4_AREGION_TYPE;
    signal    K_AWUSER          :  std_logic_vector(K_WIDTH.AWUSER -1 downto 0);
    signal    K_AWID            :  std_logic_vector(K_WIDTH.ID     -1 downto 0);
    signal    K_AWVALID         :  std_logic;
    signal    K_AWREADY         :  std_logic;
    signal    K_WLAST           :  std_logic;
    signal    K_WDATA           :  std_logic_vector(K_WIDTH.WDATA  -1 downto 0);
    signal    K_WSTRB           :  std_logic_vector(K_WIDTH.WDATA/8-1 downto 0);
    signal    K_WUSER           :  std_logic_vector(K_WIDTH.WUSER  -1 downto 0);
    signal    K_WID             :  std_logic_vector(K_WIDTH.ID     -1 downto 0);
    signal    K_WVALID          :  std_logic;
    signal    K_WREADY          :  std_logic;
    signal    K_BRESP           :  AXI4_RESP_TYPE;
    signal    K_BUSER           :  std_logic_vector(K_WIDTH.BUSER  -1 downto 0);
    signal    K_BID             :  std_logic_vector(K_WIDTH.ID     -1 downto 0);
    signal    K_BVALID          :  std_logic;
    signal    K_BREADY          :  std_logic;
    ------------------------------------------------------------------------------
    -- TH DATA AXI I/F 
    ------------------------------------------------------------------------------
    constant  T_AXI_ID          :  integer := 0;
    constant  T_AXI_PROT        :  integer := 0;
    constant  T_AXI_QOS         :  integer := 0;
    constant  T_AXI_REGION      :  integer := 1;
    constant  T_AXI_CACHE       :  integer := 15;
    constant  T_AXI_REQ_QUEUE   :  integer := 2;
    constant  T_AXI_XFER_SIZE   :  integer := 12;
    constant  T_WIDTH           :  AXI4_SIGNAL_WIDTH_TYPE := (
                                     ID          => 4,
                                     AWADDR      => AXI_ADDR_WIDTH,
                                     ARADDR      => AXI_ADDR_WIDTH,
                                     ALEN        => AXI4_ALEN_WIDTH,
                                     ALOCK       => AXI4_ALOCK_WIDTH,
                                     WDATA       => AXI_DATA_WIDTH,
                                     RDATA       => AXI_DATA_WIDTH,
                                     ARUSER      => 1,
                                     AWUSER      => 1,
                                     WUSER       => 1,
                                     RUSER       => 1,
                                     BUSER       => 1);
    signal    T_ARADDR          :  std_logic_vector(T_WIDTH.ARADDR -1 downto 0);
    signal    T_ARLEN           :  std_logic_vector(T_WIDTH.ALEN   -1 downto 0);
    signal    T_ARSIZE          :  AXI4_ASIZE_TYPE;
    signal    T_ARBURST         :  AXI4_ABURST_TYPE;
    signal    T_ARLOCK          :  std_logic_vector(T_WIDTH.ALOCK  -1 downto 0);
    signal    T_ARCACHE         :  AXI4_ACACHE_TYPE;
    signal    T_ARPROT          :  AXI4_APROT_TYPE;
    signal    T_ARQOS           :  AXI4_AQOS_TYPE;
    signal    T_ARREGION        :  AXI4_AREGION_TYPE;
    signal    T_ARUSER          :  std_logic_vector(T_WIDTH.ARUSER -1 downto 0);
    signal    T_ARID            :  std_logic_vector(T_WIDTH.ID     -1 downto 0);
    signal    T_ARVALID         :  std_logic;
    signal    T_ARREADY         :  std_logic;
    signal    T_RVALID          :  std_logic;
    signal    T_RLAST           :  std_logic;
    signal    T_RDATA           :  std_logic_vector(T_WIDTH.RDATA  -1 downto 0);
    signal    T_RRESP           :  AXI4_RESP_TYPE;
    signal    T_RUSER           :  std_logic_vector(T_WIDTH.RUSER  -1 downto 0);
    signal    T_RID             :  std_logic_vector(T_WIDTH.ID     -1 downto 0);
    signal    T_RREADY          :  std_logic;
    signal    T_AWADDR          :  std_logic_vector(T_WIDTH.AWADDR -1 downto 0);
    signal    T_AWLEN           :  std_logic_vector(T_WIDTH.ALEN   -1 downto 0);
    signal    T_AWSIZE          :  AXI4_ASIZE_TYPE;
    signal    T_AWBURST         :  AXI4_ABURST_TYPE;
    signal    T_AWLOCK          :  std_logic_vector(T_WIDTH.ALOCK  -1 downto 0);
    signal    T_AWCACHE         :  AXI4_ACACHE_TYPE;
    signal    T_AWPROT          :  AXI4_APROT_TYPE;
    signal    T_AWQOS           :  AXI4_AQOS_TYPE;
    signal    T_AWREGION        :  AXI4_AREGION_TYPE;
    signal    T_AWUSER          :  std_logic_vector(T_WIDTH.AWUSER -1 downto 0);
    signal    T_AWID            :  std_logic_vector(T_WIDTH.ID     -1 downto 0);
    signal    T_AWVALID         :  std_logic;
    signal    T_AWREADY         :  std_logic;
    signal    T_WLAST           :  std_logic;
    signal    T_WDATA           :  std_logic_vector(T_WIDTH.WDATA  -1 downto 0);
    signal    T_WSTRB           :  std_logic_vector(T_WIDTH.WDATA/8-1 downto 0);
    signal    T_WUSER           :  std_logic_vector(T_WIDTH.WUSER  -1 downto 0);
    signal    T_WID             :  std_logic_vector(T_WIDTH.ID     -1 downto 0);
    signal    T_WVALID          :  std_logic;
    signal    T_WREADY          :  std_logic;
    signal    T_BRESP           :  AXI4_RESP_TYPE;
    signal    T_BUSER           :  std_logic_vector(T_WIDTH.BUSER  -1 downto 0);
    signal    T_BID             :  std_logic_vector(T_WIDTH.ID     -1 downto 0);
    signal    T_BVALID          :  std_logic;
    signal    T_BREADY          :  std_logic;
    -------------------------------------------------------------------------------
    -- シンクロ用信号
    -------------------------------------------------------------------------------
    signal    SYNC              :  SYNC_SIG_VECTOR (SYNC_WIDTH   -1 downto 0);
    -------------------------------------------------------------------------------
    -- GPIO(General Purpose Input/Output)
    -------------------------------------------------------------------------------
    signal    S_GPI             :  std_logic_vector(GPI_WIDTH    -1 downto 0);
    signal    S_GPO             :  std_logic_vector(GPO_WIDTH    -1 downto 0);
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
    signal    S_REPORT          :  REPORT_STATUS_TYPE;
    signal    I_REPORT          :  REPORT_STATUS_TYPE;
    signal    K_REPORT          :  REPORT_STATUS_TYPE;
    signal    T_REPORT          :  REPORT_STATUS_TYPE;
    signal    O_REPORT          :  REPORT_STATUS_TYPE;
    signal    N_FINISH          :  std_logic;
    signal    S_FINISH          :  std_logic;
    signal    I_FINISH          :  std_logic;
    signal    K_FINISH          :  std_logic;
    signal    T_FINISH          :  std_logic;
    signal    O_FINISH          :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    DUT : QCONV_STRIP_AXI_CORE                           -- 
        generic map (                                    --
            IN_BUF_SIZE         => IN_BUF_SIZE         , -- 
            K_BUF_SIZE          => K_BUF_SIZE          , --   
            TH_BUF_SIZE         => TH_BUF_SIZE         , --   
            IN_C_UNROLL         => IN_C_UNROLL         , --   
            OUT_C_UNROLL        => OUT_C_UNROLL        , --   
            DATA_ADDR_WIDTH     => AXI_ADDR_WIDTH      , --   
            S_AXI_ADDR_WIDTH    => S_WIDTH.ARADDR      , --   
            S_AXI_DATA_WIDTH    => S_WIDTH.RDATA       , --   
            S_AXI_ID_WIDTH      => S_WIDTH.ID          , --   
            I_AXI_ADDR_WIDTH    => I_WIDTH.ARADDR      , --   
            I_AXI_DATA_WIDTH    => I_WIDTH.RDATA       , --   
            I_AXI_ID_WIDTH      => I_WIDTH.ID          , --   
            I_AXI_USER_WIDTH    => I_WIDTH.ARUSER      , --   
            I_AXI_XFER_SIZE     => I_AXI_XFER_SIZE     , --   
            I_AXI_ID            => I_AXI_ID            , --   
            I_AXI_PROT          => I_AXI_PROT          , --   
            I_AXI_QOS           => I_AXI_QOS           , --   
            I_AXI_REGION        => I_AXI_REGION        , --   
            I_AXI_CACHE         => I_AXI_CACHE         , --   
            I_AXI_REQ_QUEUE     => I_AXI_REQ_QUEUE     , --   
            O_AXI_ADDR_WIDTH    => O_WIDTH.AWADDR      , --   
            O_AXI_DATA_WIDTH    => O_WIDTH.WDATA       , --   
            O_AXI_ID_WIDTH      => O_WIDTH.ID          , --   
            O_AXI_USER_WIDTH    => O_WIDTH.AWUSER      , --   
            O_AXI_XFER_SIZE     => O_AXI_XFER_SIZE     , --   
            O_AXI_ID            => O_AXI_ID            , --   
            O_AXI_PROT          => O_AXI_PROT          , --   
            O_AXI_QOS           => O_AXI_QOS           , --   
            O_AXI_REGION        => O_AXI_REGION        , --   
            O_AXI_CACHE         => O_AXI_CACHE         , --   
            O_AXI_REQ_QUEUE     => O_AXI_REQ_QUEUE     , --   
            K_AXI_ADDR_WIDTH    => K_WIDTH.ARADDR      , --   
            K_AXI_DATA_WIDTH    => K_WIDTH.RDATA       , --   
            K_AXI_ID_WIDTH      => K_WIDTH.ID          , --   
            K_AXI_USER_WIDTH    => K_WIDTH.ARUSER      , --   
            K_AXI_XFER_SIZE     => K_AXI_XFER_SIZE     , --   
            K_AXI_ID            => K_AXI_ID            , --   
            K_AXI_PROT          => K_AXI_PROT          , --   
            K_AXI_QOS           => K_AXI_QOS           , --   
            K_AXI_REGION        => K_AXI_REGION        , --   
            K_AXI_CACHE         => K_AXI_CACHE         , --   
            K_AXI_REQ_QUEUE     => K_AXI_REQ_QUEUE     , --   
            T_AXI_ADDR_WIDTH    => T_WIDTH.ARADDR      , --   
            T_AXI_DATA_WIDTH    => T_WIDTH.RDATA       , --   
            T_AXI_ID_WIDTH      => T_WIDTH.ID          , --   
            T_AXI_USER_WIDTH    => T_WIDTH.ARUSER      , --   
            T_AXI_XFER_SIZE     => T_AXI_XFER_SIZE     , --   
            T_AXI_ID            => T_AXI_ID            , --   
            T_AXI_PROT          => T_AXI_PROT          , --   
            T_AXI_QOS           => T_AXI_QOS           , --   
            T_AXI_REGION        => T_AXI_REGION        , --   
            T_AXI_CACHE         => T_AXI_CACHE         , --   
            T_AXI_REQ_QUEUE     => T_AXI_REQ_QUEUE       --   
        )                                                -- 
        port map (                                       -- 
            ACLK                => CLK                 , -- In  :
            ARESETn             => ARESETn             , -- In  :
            S_AXI_ARID          => S_ARID              , -- In  :
            S_AXI_ARADDR        => S_ARADDR            , -- In  :
            S_AXI_ARLEN         => S_ARLEN             , -- In  :
            S_AXI_ARSIZE        => S_ARSIZE            , -- In  :
            S_AXI_ARBURST       => S_ARBURST           , -- In  :
            S_AXI_ARVALID       => S_ARVALID           , -- In  :
            S_AXI_ARREADY       => S_ARREADY           , -- Out :
            S_AXI_RID           => S_RID               , -- Out :
            S_AXI_RDATA         => S_RDATA             , -- Out :
            S_AXI_RRESP         => S_RRESP             , -- Out :
            S_AXI_RLAST         => S_RLAST             , -- Out :
            S_AXI_RVALID        => S_RVALID            , -- Out :
            S_AXI_RREADY        => S_RREADY            , -- In  :
            S_AXI_AWID          => S_AWID              , -- In  :
            S_AXI_AWADDR        => S_AWADDR            , -- In  :
            S_AXI_AWLEN         => S_AWLEN             , -- In  :
            S_AXI_AWSIZE        => S_AWSIZE            , -- In  :
            S_AXI_AWBURST       => S_AWBURST           , -- In  :
            S_AXI_AWVALID       => S_AWVALID           , -- In  :
            S_AXI_AWREADY       => S_AWREADY           , -- Out :
            S_AXI_WDATA         => S_WDATA             , -- In  :
            S_AXI_WSTRB         => S_WSTRB             , -- In  :
            S_AXI_WLAST         => S_WLAST             , -- In  :
            S_AXI_WVALID        => S_WVALID            , -- In  :
            S_AXI_WREADY        => S_WREADY            , -- Out :
            S_AXI_BID           => S_BID               , -- Out :
            S_AXI_BRESP         => S_BRESP             , -- Out :
            S_AXI_BVALID        => S_BVALID            , -- Out :
            S_AXI_BREADY        => S_BREADY            , -- In  :
            IO_AXI_ARID         => I_ARID              , -- Out :
            IO_AXI_ARADDR       => I_ARADDR            , -- Out :
            IO_AXI_ARLEN        => I_ARLEN             , -- Out :
            IO_AXI_ARSIZE       => I_ARSIZE            , -- Out :
            IO_AXI_ARBURST      => I_ARBURST           , -- Out :
            IO_AXI_ARLOCK       => I_ARLOCK            , -- Out :
            IO_AXI_ARCACHE      => I_ARCACHE           , -- Out :
            IO_AXI_ARPROT       => I_ARPROT            , -- Out :
            IO_AXI_ARQOS        => I_ARQOS             , -- Out :
            IO_AXI_ARREGION     => I_ARREGION          , -- Out :
            IO_AXI_ARUSER       => I_ARUSER            , -- Out :
            IO_AXI_ARVALID      => I_ARVALID           , -- Out :
            IO_AXI_ARREADY      => I_ARREADY           , -- In  :
            IO_AXI_RID          => I_RID               , -- In  :
            IO_AXI_RDATA        => I_RDATA             , -- In  :
            IO_AXI_RRESP        => I_RRESP             , -- In  :
            IO_AXI_RLAST        => I_RLAST             , -- In  :
            IO_AXI_RVALID       => I_RVALID            , -- In  :
            IO_AXI_RREADY       => I_RREADY            , -- Out :
            IO_AXI_AWID         => O_AWID              , -- Out :
            IO_AXI_AWADDR       => O_AWADDR            , -- Out :
            IO_AXI_AWLEN        => O_AWLEN             , -- Out :
            IO_AXI_AWSIZE       => O_AWSIZE            , -- Out :
            IO_AXI_AWBURST      => O_AWBURST           , -- Out :
            IO_AXI_AWLOCK       => O_AWLOCK            , -- Out :
            IO_AXI_AWCACHE      => O_AWCACHE           , -- Out :
            IO_AXI_AWPROT       => O_AWPROT            , -- Out :
            IO_AXI_AWQOS        => O_AWQOS             , -- Out :
            IO_AXI_AWREGION     => O_AWREGION          , -- Out :
            IO_AXI_AWUSER       => O_AWUSER            , -- Out :
            IO_AXI_AWVALID      => O_AWVALID           , -- Out :
            IO_AXI_AWREADY      => O_AWREADY           , -- In  :
            IO_AXI_WID          => O_WID               , -- Out :
            IO_AXI_WDATA        => O_WDATA             , -- Out :
            IO_AXI_WSTRB        => O_WSTRB             , -- Out :
            IO_AXI_WLAST        => O_WLAST             , -- Out :
            IO_AXI_WVALID       => O_WVALID            , -- Out :
            IO_AXI_WREADY       => O_WREADY            , -- In  :
            IO_AXI_BID          => O_BID               , -- In  :
            IO_AXI_BRESP        => O_BRESP             , -- In  :
            IO_AXI_BVALID       => O_BVALID            , -- In  :
            IO_AXI_BREADY       => O_BREADY            , -- Out :
            K_AXI_ARID          => K_ARID              , -- Out :
            K_AXI_ARADDR        => K_ARADDR            , -- Out :
            K_AXI_ARLEN         => K_ARLEN             , -- Out :
            K_AXI_ARSIZE        => K_ARSIZE            , -- Out :
            K_AXI_ARBURST       => K_ARBURST           , -- Out :
            K_AXI_ARLOCK        => K_ARLOCK            , -- Out :
            K_AXI_ARCACHE       => K_ARCACHE           , -- Out :
            K_AXI_ARPROT        => K_ARPROT            , -- Out :
            K_AXI_ARQOS         => K_ARQOS             , -- Out :
            K_AXI_ARREGION      => K_ARREGION          , -- Out :
            K_AXI_ARUSER        => K_ARUSER            , -- Out :
            K_AXI_ARVALID       => K_ARVALID           , -- Out :
            K_AXI_ARREADY       => K_ARREADY           , -- In  :
            K_AXI_RID           => K_RID               , -- In  :
            K_AXI_RDATA         => K_RDATA             , -- In  :
            K_AXI_RRESP         => K_RRESP             , -- In  :
            K_AXI_RLAST         => K_RLAST             , -- In  :
            K_AXI_RVALID        => K_RVALID            , -- In  :
            K_AXI_RREADY        => K_RREADY            , -- Out :
            K_AXI_AWID          => K_AWID              , -- Out :
            K_AXI_AWADDR        => K_AWADDR            , -- Out :
            K_AXI_AWLEN         => K_AWLEN             , -- Out :
            K_AXI_AWSIZE        => K_AWSIZE            , -- Out :
            K_AXI_AWBURST       => K_AWBURST           , -- Out :
            K_AXI_AWLOCK        => K_AWLOCK            , -- Out :
            K_AXI_AWCACHE       => K_AWCACHE           , -- Out :
            K_AXI_AWPROT        => K_AWPROT            , -- Out :
            K_AXI_AWQOS         => K_AWQOS             , -- Out :
            K_AXI_AWREGION      => K_AWREGION          , -- Out :
            K_AXI_AWUSER        => K_AWUSER            , -- Out :
            K_AXI_AWVALID       => K_AWVALID           , -- Out :
            K_AXI_AWREADY       => K_AWREADY           , -- In  :
            K_AXI_WID           => K_WID               , -- Out :
            K_AXI_WDATA         => K_WDATA             , -- Out :
            K_AXI_WSTRB         => K_WSTRB             , -- Out :
            K_AXI_WLAST         => K_WLAST             , -- Out :
            K_AXI_WVALID        => K_WVALID            , -- Out :
            K_AXI_WREADY        => K_WREADY            , -- In  :
            K_AXI_BID           => K_BID               , -- In  :
            K_AXI_BRESP         => K_BRESP             , -- In  :
            K_AXI_BVALID        => K_BVALID            , -- In  :
            K_AXI_BREADY        => K_BREADY            , -- Out :
            T_AXI_ARID          => T_ARID              , -- Out :
            T_AXI_ARADDR        => T_ARADDR            , -- Out :
            T_AXI_ARLEN         => T_ARLEN             , -- Out :
            T_AXI_ARSIZE        => T_ARSIZE            , -- Out :
            T_AXI_ARBURST       => T_ARBURST           , -- Out :
            T_AXI_ARLOCK        => T_ARLOCK            , -- Out :
            T_AXI_ARCACHE       => T_ARCACHE           , -- Out :
            T_AXI_ARPROT        => T_ARPROT            , -- Out :
            T_AXI_ARQOS         => T_ARQOS             , -- Out :
            T_AXI_ARREGION      => T_ARREGION          , -- Out :
            T_AXI_ARUSER        => T_ARUSER            , -- Out :
            T_AXI_ARVALID       => T_ARVALID           , -- Out :
            T_AXI_ARREADY       => T_ARREADY           , -- In  :
            T_AXI_RID           => T_RID               , -- In  :
            T_AXI_RDATA         => T_RDATA             , -- In  :
            T_AXI_RRESP         => T_RRESP             , -- In  :
            T_AXI_RLAST         => T_RLAST             , -- In  :
            T_AXI_RVALID        => T_RVALID            , -- In  :
            T_AXI_RREADY        => T_RREADY            , -- Out :
            T_AXI_AWID          => T_AWID              , -- Out :
            T_AXI_AWADDR        => T_AWADDR            , -- Out :
            T_AXI_AWLEN         => T_AWLEN             , -- Out :
            T_AXI_AWSIZE        => T_AWSIZE            , -- Out :
            T_AXI_AWBURST       => T_AWBURST           , -- Out :
            T_AXI_AWLOCK        => T_AWLOCK            , -- Out :
            T_AXI_AWCACHE       => T_AWCACHE           , -- Out :
            T_AXI_AWPROT        => T_AWPROT            , -- Out :
            T_AXI_AWQOS         => T_AWQOS             , -- Out :
            T_AXI_AWREGION      => T_AWREGION          , -- Out :
            T_AXI_AWUSER        => T_AWUSER            , -- Out :
            T_AXI_AWVALID       => T_AWVALID           , -- Out :
            T_AXI_AWREADY       => T_AWREADY           , -- In  :
            T_AXI_WID           => T_WID               , -- Out :
            T_AXI_WDATA         => T_WDATA             , -- Out :
            T_AXI_WSTRB         => T_WSTRB             , -- Out :
            T_AXI_WLAST         => T_WLAST             , -- Out :
            T_AXI_WVALID        => T_WVALID            , -- Out :
            T_AXI_WREADY        => T_WREADY            , -- In  :
            T_AXI_BID           => T_BID               , -- In  :
            T_AXI_BRESP         => T_BRESP             , -- In  :
            T_AXI_BVALID        => T_BVALID            , -- In  :
            T_AXI_BREADY        => T_BREADY            , -- Out :
            IRQ                 => IRQ                   -- Out :
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
    S: AXI4_MASTER_PLAYER                            -- 
        generic map (                                -- 
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "CSR"           , -- 
            READ_ENABLE         => TRUE            , -- 
            WRITE_ENABLE        => TRUE            , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => S_WIDTH         , -- 
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
            ARADDR              => S_ARADDR        , -- I/O : 
            ARLEN               => S_ARLEN         , -- I/O : 
            ARSIZE              => S_ARSIZE        , -- I/O : 
            ARBURST             => S_ARBURST       , -- I/O : 
            ARLOCK              => S_ARLOCK        , -- I/O : 
            ARCACHE             => S_ARCACHE       , -- I/O : 
            ARPROT              => S_ARPROT        , -- I/O : 
            ARQOS               => S_ARQOS         , -- I/O : 
            ARREGION            => S_ARREGION      , -- I/O : 
            ARUSER              => S_ARUSER        , -- I/O : 
            ARID                => S_ARID          , -- I/O : 
            ARVALID             => S_ARVALID       , -- I/O : 
            ARREADY             => S_ARREADY       , -- In  :    
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => S_RLAST         , -- In  :    
            RDATA               => S_RDATA         , -- In  :    
            RRESP               => S_RRESP         , -- In  :    
            RUSER               => S_RUSER         , -- In  :    
            RID                 => S_RID           , -- In  :    
            RVALID              => S_RVALID        , -- In  :    
            RREADY              => S_RREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        --------------------------------------------------------------------------
            AWADDR              => S_AWADDR        , -- I/O : 
            AWLEN               => S_AWLEN         , -- I/O : 
            AWSIZE              => S_AWSIZE        , -- I/O : 
            AWBURST             => S_AWBURST       , -- I/O : 
            AWLOCK              => S_AWLOCK        , -- I/O : 
            AWCACHE             => S_AWCACHE       , -- I/O : 
            AWPROT              => S_AWPROT        , -- I/O : 
            AWQOS               => S_AWQOS         , -- I/O : 
            AWREGION            => S_AWREGION      , -- I/O : 
            AWUSER              => S_AWUSER        , -- I/O : 
            AWID                => S_AWID          , -- I/O : 
            AWVALID             => S_AWVALID       , -- I/O : 
            AWREADY             => S_AWREADY       , -- In  :    
        --------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        --------------------------------------------------------------------------
            WLAST               => S_WLAST         , -- I/O : 
            WDATA               => S_WDATA         , -- I/O : 
            WSTRB               => S_WSTRB         , -- I/O : 
            WUSER               => S_WUSER         , -- I/O : 
            WID                 => S_WID           , -- I/O : 
            WVALID              => S_WVALID        , -- I/O : 
            WREADY              => S_WREADY        , -- In  :    
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => S_BRESP         , -- In  :    
            BUSER               => S_BUSER         , -- In  :    
            BID                 => S_BID           , -- In  :    
            BVALID              => S_BVALID        , -- In  :    
            BREADY              => S_BREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- シンクロ用信号
        --------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => S_GPI           , -- In  :
            GPO                 => S_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => S_REPORT        , -- Out :
            FINISH              => S_FINISH          -- Out :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "I"             , -- 
            READ_ENABLE         => TRUE            , -- 
            WRITE_ENABLE        => FALSE           , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => I_WIDTH         , -- 
            SYNC_PLUG_NUM       => 3               , -- 
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
            ARADDR              => I_ARADDR        , -- In  :    
            ARLEN               => I_ARLEN         , -- In  :    
            ARSIZE              => I_ARSIZE        , -- In  :    
            ARBURST             => I_ARBURST       , -- In  :    
            ARLOCK              => I_ARLOCK        , -- In  :    
            ARCACHE             => I_ARCACHE       , -- In  :    
            ARPROT              => I_ARPROT        , -- In  :    
            ARQOS               => I_ARQOS         , -- In  :    
            ARREGION            => I_ARREGION      , -- In  :    
            ARUSER              => I_ARUSER        , -- In  :    
            ARID                => I_ARID          , -- In  :    
            ARVALID             => I_ARVALID       , -- In  :    
            ARREADY             => I_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => I_RLAST         , -- I/O : 
            RDATA               => I_RDATA         , -- I/O : 
            RRESP               => I_RRESP         , -- I/O : 
            RUSER               => I_RUSER         , -- I/O : 
            RID                 => I_RID           , -- I/O : 
            RVALID              => I_RVALID        , -- I/O : 
            RREADY              => I_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR              => I_AWADDR        , -- In  :    
            AWLEN               => I_AWLEN         , -- In  :    
            AWSIZE              => I_AWSIZE        , -- In  :    
            AWBURST             => I_AWBURST       , -- In  :    
            AWLOCK              => I_AWLOCK        , -- In  :    
            AWCACHE             => I_AWCACHE       , -- In  :    
            AWPROT              => I_AWPROT        , -- In  :    
            AWQOS               => I_AWQOS         , -- In  :    
            AWREGION            => I_AWREGION      , -- In  :    
            AWUSER              => I_AWUSER        , -- In  :    
            AWID                => I_AWID          , -- In  :    
            AWVALID             => I_AWVALID       , -- In  :    
            AWREADY             => I_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST               => I_WLAST         , -- In  :    
            WDATA               => I_WDATA         , -- In  :    
            WSTRB               => I_WSTRB         , -- In  :    
            WUSER               => I_WUSER         , -- In  :    
            WID                 => I_WID           , -- In  :    
            WVALID              => I_WVALID        , -- In  :    
            WREADY              => I_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => I_BRESP         , -- I/O : 
            BUSER               => I_BUSER         , -- I/O : 
            BID                 => I_BID           , -- I/O : 
            BVALID              => I_BVALID        , -- I/O : 
            BREADY              => I_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => I_GPI           , -- In  :
            GPO                 => I_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => I_REPORT        , -- Out :
            FINISH              => I_FINISH          -- Out :
       );                                            -- 
    I_AWADDR   <= (others => '0');
    I_AWLEN    <= (others => '0');
    I_AWSIZE   <= (others => '0');
    I_AWBURST  <= (others => '0');
    I_AWLOCK   <= (others => '0');
    I_AWCACHE  <= (others => '0');
    I_AWPROT   <= (others => '0');
    I_AWQOS    <= (others => '0');
    I_AWREGION <= (others => '0');
    I_AWUSER   <= (others => '0');
    I_AWID     <= (others => '0');
    I_AWVALID  <= '0';
    I_WLAST    <= '0';
    I_WDATA    <= (others => '0');
    I_WSTRB    <= (others => '0');
    I_WUSER    <= (others => '0');
    I_WID      <= (others => '0');
    I_WVALID   <= '0';
    I_BREADY   <= '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    K: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "K"             , -- 
            READ_ENABLE         => TRUE            , -- 
            WRITE_ENABLE        => FALSE           , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => K_WIDTH         , -- 
            SYNC_PLUG_NUM       => 4               , -- 
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
            ARADDR              => K_ARADDR        , -- In  :    
            ARLEN               => K_ARLEN         , -- In  :    
            ARSIZE              => K_ARSIZE        , -- In  :    
            ARBURST             => K_ARBURST       , -- In  :    
            ARLOCK              => K_ARLOCK        , -- In  :    
            ARCACHE             => K_ARCACHE       , -- In  :    
            ARPROT              => K_ARPROT        , -- In  :    
            ARQOS               => K_ARQOS         , -- In  :    
            ARREGION            => K_ARREGION      , -- In  :    
            ARUSER              => K_ARUSER        , -- In  :    
            ARID                => K_ARID          , -- In  :    
            ARVALID             => K_ARVALID       , -- In  :    
            ARREADY             => K_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => K_RLAST         , -- I/O : 
            RDATA               => K_RDATA         , -- I/O : 
            RRESP               => K_RRESP         , -- I/O : 
            RUSER               => K_RUSER         , -- I/O : 
            RID                 => K_RID           , -- I/O : 
            RVALID              => K_RVALID        , -- I/O : 
            RREADY              => K_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR              => K_AWADDR        , -- In  :    
            AWLEN               => K_AWLEN         , -- In  :    
            AWSIZE              => K_AWSIZE        , -- In  :    
            AWBURST             => K_AWBURST       , -- In  :    
            AWLOCK              => K_AWLOCK        , -- In  :    
            AWCACHE             => K_AWCACHE       , -- In  :    
            AWPROT              => K_AWPROT        , -- In  :    
            AWQOS               => K_AWQOS         , -- In  :    
            AWREGION            => K_AWREGION      , -- In  :    
            AWUSER              => K_AWUSER        , -- In  :    
            AWID                => K_AWID          , -- In  :    
            AWVALID             => K_AWVALID       , -- In  :    
            AWREADY             => K_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST               => K_WLAST         , -- In  :    
            WDATA               => K_WDATA         , -- In  :    
            WSTRB               => K_WSTRB         , -- In  :    
            WUSER               => K_WUSER         , -- In  :    
            WID                 => K_WID           , -- In  :    
            WVALID              => K_WVALID        , -- In  :    
            WREADY              => K_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => K_BRESP         , -- I/O : 
            BUSER               => K_BUSER         , -- I/O : 
            BID                 => K_BID           , -- I/O : 
            BVALID              => K_BVALID        , -- I/O : 
            BREADY              => K_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => K_GPI           , -- In  :
            GPO                 => K_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => K_REPORT        , -- Out :
            FINISH              => K_FINISH          -- Out :
       );                                            -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    T: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "T"             , -- 
            READ_ENABLE         => TRUE            , -- 
            WRITE_ENABLE        => FALSE           , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => T_WIDTH         , -- 
            SYNC_PLUG_NUM       => 5               , -- 
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
            ARADDR              => T_ARADDR        , -- In  :    
            ARLEN               => T_ARLEN         , -- In  :    
            ARSIZE              => T_ARSIZE        , -- In  :    
            ARBURST             => T_ARBURST       , -- In  :    
            ARLOCK              => T_ARLOCK        , -- In  :    
            ARCACHE             => T_ARCACHE       , -- In  :    
            ARPROT              => T_ARPROT        , -- In  :    
            ARQOS               => T_ARQOS         , -- In  :    
            ARREGION            => T_ARREGION      , -- In  :    
            ARUSER              => T_ARUSER        , -- In  :    
            ARID                => T_ARID          , -- In  :    
            ARVALID             => T_ARVALID       , -- In  :    
            ARREADY             => T_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => T_RLAST         , -- I/O : 
            RDATA               => T_RDATA         , -- I/O : 
            RRESP               => T_RRESP         , -- I/O : 
            RUSER               => T_RUSER         , -- I/O : 
            RID                 => T_RID           , -- I/O : 
            RVALID              => T_RVALID        , -- I/O : 
            RREADY              => T_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR              => T_AWADDR        , -- In  :    
            AWLEN               => T_AWLEN         , -- In  :    
            AWSIZE              => T_AWSIZE        , -- In  :    
            AWBURST             => T_AWBURST       , -- In  :    
            AWLOCK              => T_AWLOCK        , -- In  :    
            AWCACHE             => T_AWCACHE       , -- In  :    
            AWPROT              => T_AWPROT        , -- In  :    
            AWQOS               => T_AWQOS         , -- In  :    
            AWREGION            => T_AWREGION      , -- In  :    
            AWUSER              => T_AWUSER        , -- In  :    
            AWID                => T_AWID          , -- In  :    
            AWVALID             => T_AWVALID       , -- In  :    
            AWREADY             => T_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST               => T_WLAST         , -- In  :    
            WDATA               => T_WDATA         , -- In  :    
            WSTRB               => T_WSTRB         , -- In  :    
            WUSER               => T_WUSER         , -- In  :    
            WID                 => T_WID           , -- In  :    
            WVALID              => T_WVALID        , -- In  :    
            WREADY              => T_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => T_BRESP         , -- I/O : 
            BUSER               => T_BUSER         , -- I/O : 
            BID                 => T_BID           , -- I/O : 
            BVALID              => T_BVALID        , -- I/O : 
            BREADY              => T_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => T_GPI           , -- In  :
            GPO                 => T_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => T_REPORT        , -- Out :
            FINISH              => T_FINISH          -- Out :
       );                                            -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O: AXI4_SLAVE_PLAYER
        generic map (
            SCENARIO_FILE       => SCENARIO_FILE   , -- 
            NAME                => "O"             , -- 
            READ_ENABLE         => FALSE           , -- 
            WRITE_ENABLE        => TRUE            , -- 
            OUTPUT_DELAY        => DELAY           , -- 
            WIDTH               => O_WIDTH         , -- 
            SYNC_PLUG_NUM       => 6               , -- 
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
            ARADDR              => O_ARADDR        , -- In  :    
            ARLEN               => O_ARLEN         , -- In  :    
            ARSIZE              => O_ARSIZE        , -- In  :    
            ARBURST             => O_ARBURST       , -- In  :    
            ARLOCK              => O_ARLOCK        , -- In  :    
            ARCACHE             => O_ARCACHE       , -- In  :    
            ARPROT              => O_ARPROT        , -- In  :    
            ARQOS               => O_ARQOS         , -- In  :    
            ARREGION            => O_ARREGION      , -- In  :    
            ARUSER              => O_ARUSER        , -- In  :    
            ARID                => O_ARID          , -- In  :    
            ARVALID             => O_ARVALID       , -- In  :    
            ARREADY             => O_ARREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- リードデータチャネルシグナル.
        ---------------------------------------------------------------------------
            RLAST               => O_RLAST         , -- I/O : 
            RDATA               => O_RDATA         , -- I/O : 
            RRESP               => O_RRESP         , -- I/O : 
            RUSER               => O_RUSER         , -- I/O : 
            RID                 => O_RID           , -- I/O : 
            RVALID              => O_RVALID        , -- I/O : 
            RREADY              => O_RREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- ライトアドレスチャネルシグナル.
        ---------------------------------------------------------------------------
            AWADDR              => O_AWADDR        , -- In  :    
            AWLEN               => O_AWLEN         , -- In  :    
            AWSIZE              => O_AWSIZE        , -- In  :    
            AWBURST             => O_AWBURST       , -- In  :    
            AWLOCK              => O_AWLOCK        , -- In  :    
            AWCACHE             => O_AWCACHE       , -- In  :    
            AWPROT              => O_AWPROT        , -- In  :    
            AWQOS               => O_AWQOS         , -- In  :    
            AWREGION            => O_AWREGION      , -- In  :    
            AWUSER              => O_AWUSER        , -- In  :    
            AWID                => O_AWID          , -- In  :    
            AWVALID             => O_AWVALID       , -- In  :    
            AWREADY             => O_AWREADY       , -- I/O : 
        ---------------------------------------------------------------------------
        -- ライトデータチャネルシグナル.
        ---------------------------------------------------------------------------
            WLAST               => O_WLAST         , -- In  :    
            WDATA               => O_WDATA         , -- In  :    
            WSTRB               => O_WSTRB         , -- In  :    
            WUSER               => O_WUSER         , -- In  :    
            WID                 => O_WID           , -- In  :    
            WVALID              => O_WVALID        , -- In  :    
            WREADY              => O_WREADY        , -- I/O : 
        --------------------------------------------------------------------------
        -- ライト応答チャネルシグナル.
        --------------------------------------------------------------------------
            BRESP               => O_BRESP         , -- I/O : 
            BUSER               => O_BUSER         , -- I/O : 
            BID                 => O_BID           , -- I/O : 
            BVALID              => O_BVALID        , -- I/O : 
            BREADY              => O_BREADY        , -- In  :    
        ---------------------------------------------------------------------------
        -- シンクロ用信号
        ---------------------------------------------------------------------------
            SYNC(0)             => SYNC(0)         , -- I/O :
            SYNC(1)             => SYNC(1)         , -- I/O :
        --------------------------------------------------------------------------
        -- GPIO
        --------------------------------------------------------------------------
            GPI                 => O_GPI           , -- In  :
            GPO                 => O_GPO           , -- Out :
        --------------------------------------------------------------------------
        -- 各種状態出力.
        --------------------------------------------------------------------------
            REPORT_STATUS       => O_REPORT        , -- Out :
            FINISH              => O_FINISH          -- Out :
       );                                            -- 
    O_ARADDR   <= (others => '0');
    O_ARLEN    <= (others => '0');
    O_ARSIZE   <= (others => '0');
    O_ARBURST  <= (others => '0');
    O_ARLOCK   <= (others => '0');
    O_ARCACHE  <= (others => '0');
    O_ARPROT   <= (others => '0');
    O_ARQOS    <= (others => '0');
    O_ARREGION <= (others => '0');
    O_ARUSER   <= (others => '0');
    O_ARID     <= (others => '0');
    O_ARVALID  <= '0';
    O_RREADY   <= '0';
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
    S_GPI(0)  <= IRQ;
    S_GPI(S_GPI'high downto 1) <= (S_GPI'high downto 1 => '0');
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
        wait until (S_FINISH'event and S_FINISH = '1');
        wait for DELAY;
        WRITE(L,T);                                                   WRITELINE(OUTPUT,L);
        WRITE(L,T & "ERROR REPORT " & NAME);                          WRITELINE(OUTPUT,L);
        WRITE(L,T & "[ CSR ]");                                       WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Error    : ");WRITE(L,S_REPORT.error_count   );WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Mismatch : ");WRITE(L,S_REPORT.mismatch_count);WRITELINE(OUTPUT,L);
        WRITE(L,T & "  Warning  : ");WRITE(L,S_REPORT.warning_count );WRITELINE(OUTPUT,L);
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
        assert (S_REPORT.error_count    = 0 and
                I_REPORT.error_count    = 0 and
                K_REPORT.error_count    = 0 and
                T_REPORT.error_count    = 0 and
                O_REPORT.error_count    = 0)
            report "Simulation complete(error)."    severity FAILURE;
        assert (S_REPORT.mismatch_count = 0 and
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
-- IN_C_UNROLL=1 OUT_C_UNROLL=1 BUF_SIZE=64
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_AXI_CORE_TEST_BENCH_1_1_064 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test_1_1_064.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 1;
        BUF_SIZE        : integer := 64;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_AXI_CORE_TEST_BENCH_1_1_064;
architecture MODEL of QCONV_STRIP_AXI_CORE_TEST_BENCH_1_1_064 is
begin
    TB: entity WORK.QCONV_STRIP_AXI_CORE_TEST_BENCH generic map (
        NAME            => NAME            , 
        SCENARIO_FILE   => SCENARIO_FILE   , 
        IN_C_UNROLL     => IN_C_UNROLL     , 
        OUT_C_UNROLL    => OUT_C_UNROLL    , 
        BUF_SIZE        => BUF_SIZE        , 
        FINISH_ABORT    => FINISH_ABORT    
    );
end MODEL;
-----------------------------------------------------------------------------------
-- IN_C_UNROLL=1 OUT_C_UNROLL=2 BUF_SIZE=16
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
entity  QCONV_STRIP_AXI_CORE_TEST_BENCH_1_2_016 is
    generic (
        NAME            : STRING  := "test";
        SCENARIO_FILE   : STRING  := "test_1_2_016.snr";
        IN_C_UNROLL     : integer := 1;
        OUT_C_UNROLL    : integer := 2;
        BUF_SIZE        : integer := 16;
        FINISH_ABORT    : boolean := FALSE
    );
end     QCONV_STRIP_AXI_CORE_TEST_BENCH_1_2_016;
architecture MODEL of QCONV_STRIP_AXI_CORE_TEST_BENCH_1_2_016 is
begin
    TB: entity WORK.QCONV_STRIP_AXI_CORE_TEST_BENCH generic map (
        NAME            => NAME            , 
        SCENARIO_FILE   => SCENARIO_FILE   , 
        IN_C_UNROLL     => IN_C_UNROLL     , 
        OUT_C_UNROLL    => OUT_C_UNROLL    , 
        BUF_SIZE        => BUF_SIZE        , 
        FINISH_ABORT    => FINISH_ABORT    
    );
end MODEL;
