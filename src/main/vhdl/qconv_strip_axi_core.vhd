-----------------------------------------------------------------------------------
--!     @file    qconv_strip_axi_core.vhd
--!     @brief   Quantized Convolution (strip) AXI I/F Core Module
--!     @version 0.1.0
--!     @date    2019/5/5
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
library QCONV;
use     QCONV.QCONV_PARAMS.all;
-----------------------------------------------------------------------------------
--! @brief 
-----------------------------------------------------------------------------------
entity  QCONV_STRIP_AXI_CORE is
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        ID                  : --! @brief QCONV ID STRING :
                              string(1 to 8) := "QCONV-S1";
        IN_BUF_SIZE         : --! @brief IN DATA BUFFER SIZE :
                              --! 入力バッファの容量を指定する.
                              --! * ここで指定する単位は1ワード単位.
                              --! * 1ワードは QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD
                              --!   = 64 bit.
                              --! * 入力バッファの容量は 入力チャネル × イメージの幅.
                              integer := 512*4*1;  -- 512word × BANK_SIZE × IN_C_UNROLL 
        K_BUF_SIZE          : --! @brief K DATA BUFFER SIZE :
                              --! カーネル係数バッファの容量を指定する.
                              --! * ここで指定する単位は1ワード単位.
                              --! * 1ワードは 3 * 3 * QCONV_PARAM.NBITS_K_DATA * QCONV_PARAM.NBITS_PER_WORD
                              --! * カーネル係数バッファの容量は K_BUF_SIZE * 288bit になる.
                              integer := 512*3*3*8*1;  -- 512word × 3 × 3 × OUT_C_UNROLL × IN_C_UNROLL
        TH_BUF_SIZE         : --! @brief THRESHOLDS DATA BUFFER SIZE :
                              --! THRESHOLDS バッファの容量を指定する.
                              --! * ここで指定する単位は1ワード単位.
                              --! * 1ワードは QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS
                              --! * = 64bit
                              integer := 512*8;
        IN_C_UNROLL         : --! @brief INPUT  CHANNEL UNROLL SIZE :
                              integer := 1;
        OUT_C_UNROLL        : --! @brief OUTPUT CHANNEL UNROLL SIZE :
                              integer := 8;
        DATA_ADDR_WIDTH     : --! @brief DATA ADDRESS WIDTH :
                              --! IN_DATA/OUT_DATA/K_DATA/TH_DATA のメモリアドレスのビット幅を指定する.
                              integer := 32;
        S_AXI_ADDR_WIDTH    : --! @brief CSR I/F AXI ADDRRESS WIDTH :
                              integer := 32;
        S_AXI_DATA_WIDTH    : --! @brief CSR I/F AXI DATA WIDTH :
                              integer := 32;
        S_AXI_ID_WIDTH      : --! @brief CSR I/F AXI4 ID WIDTH :
                              integer := 4;
        I_AXI_ADDR_WIDTH    : --! @brief IN  DATA AXI ADDRESS WIDTH :
                              integer := 32;
        I_AXI_DATA_WIDTH    : --! @brief IN  DATA AXI DATA WIDTH :
                              integer := 64;
        I_AXI_ID_WIDTH      : --! @brief IN  DATA AXI ID WIDTH :
                              integer := 8;
        I_AXI_USER_WIDTH    : --! @brief IN  DATA AXI ID WIDTH :
                              integer := 8;
        I_AXI_XFER_SIZE     : --! @brief IN  DATA AXI MAX XFER_SIZE :
                              integer := 11;
        I_AXI_ID            : --! @brief IN  DATA AXI ID :
                              integer := 0;
        I_AXI_PROT          : --! @brief IN  DATA AXI PROT :
                              integer := 1;
        I_AXI_QOS           : --! @brief IN  DATA AXI QOS :
                              integer := 0;
        I_AXI_REGION        : --! @brief IN  DATA AXI REGION :
                              integer := 0;
        I_AXI_CACHE         : --! @brief IN  DATA AXI REGION :
                              integer := 15;
        I_AXI_AUSER         : --! @brief IN  DATA AXI ARUSER :
                              integer := 0;
        I_AXI_REQ_QUEUE     : --! @brief IN  DATA AXI REQUEST QUEUE SIZE :
                              integer := 4;
        O_AXI_ADDR_WIDTH    : --! @brief OUT DATA AXI ADDRESS WIDTH :
                              integer := 32;
        O_AXI_DATA_WIDTH    : --! @brief OUT DATA AXI DATA WIDTH :
                              integer := 64;
        O_AXI_ID_WIDTH      : --! @brief OUT DATA AXI ID WIDTH :
                              integer := 8;
        O_AXI_USER_WIDTH    : --! @brief OUT DATA AXI ID WIDTH :
                              integer := 8;
        O_AXI_XFER_SIZE     : --! @brief OUT DATA AXI MAX XFER_SIZE :
                              integer := 11;
        O_AXI_ID            : --! @brief OUT DATA AXI ID :
                              integer := 0;
        O_AXI_PROT          : --! @brief OUT DATA AXI PROT :
                              integer := 1;
        O_AXI_QOS           : --! @brief OUT DATA AXI QOS :
                              integer := 0;
        O_AXI_REGION        : --! @brief OUT DATA AXI REGION :
                              integer := 0;
        O_AXI_CACHE         : --! @brief OUT DATA AXI REGION :
                              integer := 15;
        O_AXI_AUSER         : --! @brief OUT DATA AXI AWUSER :
                              integer := 0;
        O_AXI_REQ_QUEUE     : --! @brief OUT DATA AXI REQUEST QUEUE SIZE :
                              integer := 4;
        K_AXI_ADDR_WIDTH    : --! @brief K   DATA AXI ADDRESS WIDTH :
                              integer := 32;
        K_AXI_DATA_WIDTH    : --! @brief K   DATA AXI DATA WIDTH :
                              integer := 64;
        K_AXI_ID_WIDTH      : --! @brief K   DATA AXI ID WIDTH :
                              integer := 8;
        K_AXI_USER_WIDTH    : --! @brief K   DATA AXI ID WIDTH :
                              integer := 8;
        K_AXI_XFER_SIZE     : --! @brief K   DATA AXI MAX XFER_SIZE :
                              integer := 11;
        K_AXI_ID            : --! @brief K   DATA AXI ID :
                              integer := 0;
        K_AXI_PROT          : --! @brief K   DATA AXI PROT :
                              integer := 1;
        K_AXI_QOS           : --! @brief K   DATA AXI QOS :
                              integer := 0;
        K_AXI_REGION        : --! @brief K   DATA AXI REGION :
                              integer := 0;
        K_AXI_CACHE         : --! @brief K   DATA AXI REGION :
                              integer := 15;
        K_AXI_AUSER         : --! @brief K   DATA AXI ARUSER :
                              integer := 0;
        K_AXI_REQ_QUEUE     : --! @brief K   DATA AXI REQUEST QUEUE SIZE :
                              integer := 4;
        T_AXI_ADDR_WIDTH    : --! @brief TH  DATA AXI ADDRESS WIDTH :
                              integer := 32;
        T_AXI_DATA_WIDTH    : --! @brief TH  DATA AXI DATA WIDTH :
                              integer := 64;
        T_AXI_ID_WIDTH      : --! @brief TH  DATA AXI ID WIDTH :
                              integer := 8;
        T_AXI_USER_WIDTH    : --! @brief TH  DATA AXI ID WIDTH :
                              integer := 8;
        T_AXI_XFER_SIZE     : --! @brief TH  DATA AXI MAX XFER_SIZE :
                              integer := 11;
        T_AXI_ID            : --! @brief TH  DATA AXI ID :
                              integer := 0;
        T_AXI_PROT          : --! @brief TH  DATA AXI PROT :
                              integer := 1;
        T_AXI_QOS           : --! @brief TH  DATA AXI QOS :
                              integer := 0;
        T_AXI_REGION        : --! @brief TH  DATA AXI REGION :
                              integer := 0;
        T_AXI_CACHE         : --! @brief TH  DATA AXI REGION :
                              integer := 15;
        T_AXI_AUSER         : --! @brief TH  DATA AXI ARUSER :
                              integer := 0;
        T_AXI_REQ_QUEUE     : --! @brief TH  DATA AXI REQUEST QUEUE SIZE :
                              integer := 1
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
        S_AXI_ARID          : in  std_logic_vector(S_AXI_ID_WIDTH    -1 downto 0);
        S_AXI_ARADDR        : in  std_logic_vector(S_AXI_ADDR_WIDTH  -1 downto 0);
        S_AXI_ARLEN         : in  std_logic_vector(7 downto 0);
        S_AXI_ARSIZE        : in  std_logic_vector(2 downto 0);
        S_AXI_ARBURST       : in  std_logic_vector(1 downto 0);
        S_AXI_ARVALID       : in  std_logic;
        S_AXI_ARREADY       : out std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Read Data Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_RID           : out std_logic_vector(S_AXI_ID_WIDTH    -1 downto 0);
        S_AXI_RDATA         : out std_logic_vector(S_AXI_DATA_WIDTH  -1 downto 0);
        S_AXI_RRESP         : out std_logic_vector(1 downto 0);  
        S_AXI_RLAST         : out std_logic;
        S_AXI_RVALID        : out std_logic;
        S_AXI_RREADY        : in  std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Address Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_AWID          : in  std_logic_vector(S_AXI_ID_WIDTH    -1 downto 0);
        S_AXI_AWADDR        : in  std_logic_vector(S_AXI_ADDR_WIDTH  -1 downto 0);
        S_AXI_AWLEN         : in  std_logic_vector(7 downto 0);
        S_AXI_AWSIZE        : in  std_logic_vector(2 downto 0);
        S_AXI_AWBURST       : in  std_logic_vector(1 downto 0);
        S_AXI_AWVALID       : in  std_logic;
        S_AXI_AWREADY       : out std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Data Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_WDATA         : in  std_logic_vector(S_AXI_DATA_WIDTH  -1 downto 0);
        S_AXI_WSTRB         : in  std_logic_vector(S_AXI_DATA_WIDTH/8-1 downto 0);
        S_AXI_WLAST         : in  std_logic;
        S_AXI_WVALID        : in  std_logic;
        S_AXI_WREADY        : out std_logic;
    ------------------------------------------------------------------------------
    -- Control Status Register I/F AXI4 Write Response Channel Signals.
    ------------------------------------------------------------------------------
        S_AXI_BID           : out std_logic_vector(S_AXI_ID_WIDTH    -1 downto 0);
        S_AXI_BRESP         : out std_logic_vector(1 downto 0);
        S_AXI_BVALID        : out std_logic;
        S_AXI_BREADY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_ARID         : out std_logic_vector(I_AXI_ID_WIDTH    -1 downto 0);
        IO_AXI_ARADDR       : out std_logic_vector(I_AXI_ADDR_WIDTH  -1 downto 0);
        IO_AXI_ARLEN        : out std_logic_vector(7 downto 0);
        IO_AXI_ARSIZE       : out std_logic_vector(2 downto 0);
        IO_AXI_ARBURST      : out std_logic_vector(1 downto 0);
        IO_AXI_ARLOCK       : out std_logic_vector(0 downto 0);
        IO_AXI_ARCACHE      : out std_logic_vector(3 downto 0);
        IO_AXI_ARPROT       : out std_logic_vector(2 downto 0);
        IO_AXI_ARQOS        : out std_logic_vector(3 downto 0);
        IO_AXI_ARREGION     : out std_logic_vector(3 downto 0);
        IO_AXI_ARUSER       : out std_logic_vector(I_AXI_USER_WIDTH  -1 downto 0);
        IO_AXI_ARVALID      : out std_logic;
        IO_AXI_ARREADY      : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_RID          : in  std_logic_vector(I_AXI_ID_WIDTH    -1 downto 0);
        IO_AXI_RDATA        : in  std_logic_vector(I_AXI_DATA_WIDTH  -1 downto 0);
        IO_AXI_RRESP        : in  std_logic_vector(1 downto 0);
        IO_AXI_RLAST        : in  std_logic;
        IO_AXI_RVALID       : in  std_logic;
        IO_AXI_RREADY       : out std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_AWID         : out std_logic_vector(O_AXI_ID_WIDTH    -1 downto 0);
        IO_AXI_AWADDR       : out std_logic_vector(O_AXI_ADDR_WIDTH  -1 downto 0);
        IO_AXI_AWLEN        : out std_logic_vector(7 downto 0);
        IO_AXI_AWSIZE       : out std_logic_vector(2 downto 0);
        IO_AXI_AWBURST      : out std_logic_vector(1 downto 0);
        IO_AXI_AWLOCK       : out std_logic_vector(0 downto 0);
        IO_AXI_AWCACHE      : out std_logic_vector(3 downto 0);
        IO_AXI_AWPROT       : out std_logic_vector(2 downto 0);
        IO_AXI_AWQOS        : out std_logic_vector(3 downto 0);
        IO_AXI_AWREGION     : out std_logic_vector(3 downto 0);
        IO_AXI_AWUSER       : out std_logic_vector(O_AXI_USER_WIDTH  -1 downto 0);
        IO_AXI_AWVALID      : out std_logic;
        IO_AXI_AWREADY      : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_WID          : out std_logic_vector(O_AXI_ID_WIDTH    -1 downto 0);
        IO_AXI_WDATA        : out std_logic_vector(O_AXI_DATA_WIDTH  -1 downto 0);
        IO_AXI_WSTRB        : out std_logic_vector(O_AXI_DATA_WIDTH/8-1 downto 0);
        IO_AXI_WLAST        : out std_logic;
        IO_AXI_WVALID       : out std_logic;
        IO_AXI_WREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- IN/OUT DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        IO_AXI_BID          : in  std_logic_vector(O_AXI_ID_WIDTH    -1 downto 0);
        IO_AXI_BRESP        : in  std_logic_vector(1 downto 0);
        IO_AXI_BVALID       : in  std_logic;
        IO_AXI_BREADY       : out std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_ARID          : out std_logic_vector(K_AXI_ID_WIDTH    -1 downto 0);
        K_AXI_ARADDR        : out std_logic_vector(K_AXI_ADDR_WIDTH  -1 downto 0);
        K_AXI_ARLEN         : out std_logic_vector(7 downto 0);
        K_AXI_ARSIZE        : out std_logic_vector(2 downto 0);
        K_AXI_ARBURST       : out std_logic_vector(1 downto 0);
        K_AXI_ARLOCK        : out std_logic_vector(0 downto 0);
        K_AXI_ARCACHE       : out std_logic_vector(3 downto 0);
        K_AXI_ARPROT        : out std_logic_vector(2 downto 0);
        K_AXI_ARQOS         : out std_logic_vector(3 downto 0);
        K_AXI_ARREGION      : out std_logic_vector(3 downto 0);
        K_AXI_ARUSER        : out std_logic_vector(K_AXI_USER_WIDTH  -1 downto 0);
        K_AXI_ARVALID       : out std_logic;
        K_AXI_ARREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_RID           : in  std_logic_vector(K_AXI_ID_WIDTH    -1 downto 0);
        K_AXI_RDATA         : in  std_logic_vector(K_AXI_DATA_WIDTH  -1 downto 0);
        K_AXI_RRESP         : in  std_logic_vector(1 downto 0);
        K_AXI_RLAST         : in  std_logic;
        K_AXI_RVALID        : in  std_logic;
        K_AXI_RREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_AWID          : out std_logic_vector(K_AXI_ID_WIDTH    -1 downto 0);
        K_AXI_AWADDR        : out std_logic_vector(K_AXI_ADDR_WIDTH  -1 downto 0);
        K_AXI_AWLEN         : out std_logic_vector(7 downto 0);
        K_AXI_AWSIZE        : out std_logic_vector(2 downto 0);
        K_AXI_AWBURST       : out std_logic_vector(1 downto 0);
        K_AXI_AWLOCK        : out std_logic_vector(0 downto 0);
        K_AXI_AWCACHE       : out std_logic_vector(3 downto 0);
        K_AXI_AWPROT        : out std_logic_vector(2 downto 0);
        K_AXI_AWQOS         : out std_logic_vector(3 downto 0);
        K_AXI_AWREGION      : out std_logic_vector(3 downto 0);
        K_AXI_AWUSER        : out std_logic_vector(K_AXI_USER_WIDTH  -1 downto 0);
        K_AXI_AWVALID       : out std_logic;
        K_AXI_AWREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_WID           : out std_logic_vector(K_AXI_ID_WIDTH    -1 downto 0);
        K_AXI_WDATA         : out std_logic_vector(K_AXI_DATA_WIDTH  -1 downto 0);
        K_AXI_WSTRB         : out std_logic_vector(K_AXI_DATA_WIDTH/8-1 downto 0);
        K_AXI_WLAST         : out std_logic;
        K_AXI_WVALID        : out std_logic;
        K_AXI_WREADY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- K DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        K_AXI_BID           : in  std_logic_vector(K_AXI_ID_WIDTH    -1 downto 0);
        K_AXI_BRESP         : in  std_logic_vector(1 downto 0);
        K_AXI_BVALID        : in  std_logic;
        K_AXI_BREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_ARID          : out std_logic_vector(T_AXI_ID_WIDTH    -1 downto 0);
        T_AXI_ARADDR        : out std_logic_vector(T_AXI_ADDR_WIDTH  -1 downto 0);
        T_AXI_ARLEN         : out std_logic_vector(7 downto 0);
        T_AXI_ARSIZE        : out std_logic_vector(2 downto 0);
        T_AXI_ARBURST       : out std_logic_vector(1 downto 0);
        T_AXI_ARLOCK        : out std_logic_vector(0 downto 0);
        T_AXI_ARCACHE       : out std_logic_vector(3 downto 0);
        T_AXI_ARPROT        : out std_logic_vector(2 downto 0);
        T_AXI_ARQOS         : out std_logic_vector(3 downto 0);
        T_AXI_ARREGION      : out std_logic_vector(3 downto 0);
        T_AXI_ARUSER        : out std_logic_vector(T_AXI_USER_WIDTH  -1 downto 0);
        T_AXI_ARVALID       : out std_logic;
        T_AXI_ARREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_RID           : in  std_logic_vector(T_AXI_ID_WIDTH    -1 downto 0);
        T_AXI_RDATA         : in  std_logic_vector(T_AXI_DATA_WIDTH  -1 downto 0);
        T_AXI_RRESP         : in  std_logic_vector(1 downto 0);
        T_AXI_RLAST         : in  std_logic;
        T_AXI_RVALID        : in  std_logic;
        T_AXI_RREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_AWID          : out std_logic_vector(T_AXI_ID_WIDTH    -1 downto 0);
        T_AXI_AWADDR        : out std_logic_vector(T_AXI_ADDR_WIDTH  -1 downto 0);
        T_AXI_AWLEN         : out std_logic_vector(7 downto 0);
        T_AXI_AWSIZE        : out std_logic_vector(2 downto 0);
        T_AXI_AWBURST       : out std_logic_vector(1 downto 0);
        T_AXI_AWLOCK        : out std_logic_vector(0 downto 0);
        T_AXI_AWCACHE       : out std_logic_vector(3 downto 0);
        T_AXI_AWPROT        : out std_logic_vector(2 downto 0);
        T_AXI_AWQOS         : out std_logic_vector(3 downto 0);
        T_AXI_AWREGION      : out std_logic_vector(3 downto 0);
        T_AXI_AWUSER        : out std_logic_vector(T_AXI_USER_WIDTH  -1 downto 0);
        T_AXI_AWVALID       : out std_logic;
        T_AXI_AWREADY       : in  std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_WID           : out std_logic_vector(T_AXI_ID_WIDTH    -1 downto 0);
        T_AXI_WDATA         : out std_logic_vector(T_AXI_DATA_WIDTH  -1 downto 0);
        T_AXI_WSTRB         : out std_logic_vector(T_AXI_DATA_WIDTH/8-1 downto 0);
        T_AXI_WLAST         : out std_logic;
        T_AXI_WVALID        : out std_logic;
        T_AXI_WREADY        : in  std_logic;
    -------------------------------------------------------------------------------
    -- TH DATA AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        T_AXI_BID           : in  std_logic_vector(T_AXI_ID_WIDTH    -1 downto 0);
        T_AXI_BRESP         : in  std_logic_vector(1 downto 0);
        T_AXI_BVALID        : in  std_logic;
        T_AXI_BREADY        : out std_logic;
    -------------------------------------------------------------------------------
    -- Interrupt Request
    -------------------------------------------------------------------------------
        IRQ                 : out std_logic
    );
end  QCONV_STRIP_AXI_CORE;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_REGISTER_INTERFACE;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_IN_DATA_AXI_READER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_K_DATA_AXI_READER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_TH_DATA_AXI_READER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_OUT_DATA_AXI_WRITER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_CORE;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_REGISTERS;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_CONTROLLER;
architecture RTL of QCONV_STRIP_AXI_CORE is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  QCONV_PARAM           :  QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    RESET                 :  std_logic;
    constant  CLEAR                 :  std_logic := '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  REGS_ADDR_WIDTH       :  integer :=  8;
    constant  REGS_DATA_WIDTH       :  integer := 64;
    signal    regs_req              :  std_logic;
    signal    regs_write            :  std_logic;
    signal    regs_ack              :  std_logic;
    signal    regs_err              :  std_logic;
    signal    regs_addr             :  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
    signal    regs_ben              :  std_logic_vector(REGS_DATA_WIDTH/8-1 downto 0);
    signal    regs_wdata            :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
    signal    regs_rdata            :  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    ctrl_in_c_by_word     :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
    signal    ctrl_in_w             :  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
    signal    ctrl_in_h             :  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
    signal    ctrl_out_c            :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    ctrl_out_w            :  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
    signal    ctrl_out_h            :  std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
    signal    ctrl_k_w              :  std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
    signal    ctrl_k_h              :  std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
    signal    ctrl_pad_size         :  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
    signal    ctrl_use_th           :  std_logic_vector(1 downto 0);
    signal    ctrl_req_valid        :  std_logic;
    signal    ctrl_req_ready        :  std_logic;
    signal    ctrl_res_valid        :  std_logic;
    signal    ctrl_res_ready        :  std_logic;
    signal    ctrl_res_status       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    core_in_c_by_word     :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
    signal    core_in_w             :  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
    signal    core_in_h             :  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
    signal    core_out_c            :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    core_out_w            :  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
    signal    core_out_h            :  std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
    signal    core_k_w              :  std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
    signal    core_k_h              :  std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
    signal    core_l_pad_size       :  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
    signal    core_r_pad_size       :  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
    signal    core_t_pad_size       :  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
    signal    core_b_pad_size       :  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
    signal    core_use_th           :  std_logic_vector(1 downto 0);
    signal    core_param_in         :  std_logic;
    signal    core_req_valid        :  std_logic;
    signal    core_req_ready        :  std_logic;
    signal    core_res_valid        :  std_logic;
    signal    core_res_ready        :  std_logic;
    constant  core_res_status       :  std_logic := '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  I_DATA_WIDTH          :  integer := QCONV_PARAM.NBITS_IN_DATA*QCONV_PARAM.NBITS_PER_WORD;
    signal    i_data_addr           :  std_logic_vector(DATA_ADDR_WIDTH              -1 downto 0);
    signal    i_data                :  std_logic_vector(I_DATA_WIDTH                 -1 downto 0);
    signal    i_data_last           :  std_logic;
    signal    i_data_valid          :  std_logic;
    signal    i_data_ready          :  std_logic;
    signal    i_in_c                :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
    signal    i_in_w                :  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
    signal    i_in_h                :  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
    signal    i_x_pos               :  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
    signal    i_x_size              :  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
    signal    i_req_valid           :  std_logic;
    signal    i_req_ready           :  std_logic;
    signal    i_res_valid           :  std_logic;
    signal    i_res_ready           :  std_logic;
    signal    i_res_none            :  std_logic;
    signal    i_res_error           :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  O_DATA_WIDTH          :  integer := 64;
    signal    o_data_addr           :  std_logic_vector(DATA_ADDR_WIDTH              -1 downto 0);
    signal    o_data                :  std_logic_vector(O_DATA_WIDTH                 -1 downto 0);
    signal    o_data_strb           :  std_logic_vector(O_DATA_WIDTH/8               -1 downto 0);
    signal    o_data_last           :  std_logic;
    signal    o_data_valid          :  std_logic;
    signal    o_data_ready          :  std_logic;
    signal    o_out_c               :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    o_out_w               :  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
    signal    o_out_h               :  std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
    signal    o_c_pos               :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    o_c_size              :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    o_x_pos               :  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
    signal    o_x_size              :  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
    signal    o_use_th              :  std_logic_vector(1 downto 0);
    signal    o_req_valid           :  std_logic;
    signal    o_req_ready           :  std_logic;
    signal    o_res_valid           :  std_logic;
    signal    o_res_ready           :  std_logic;
    signal    o_res_none            :  std_logic;
    signal    o_res_error           :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  K_DATA_WIDTH          :  integer := QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD;
    signal    k_data_addr           :  std_logic_vector(DATA_ADDR_WIDTH              -1 downto 0);
    signal    k_data                :  std_logic_vector(K_DATA_WIDTH                 -1 downto 0);
    signal    k_data_last           :  std_logic;
    signal    k_data_valid          :  std_logic;
    signal    k_data_ready          :  std_logic;
    signal    k_in_c_by_word        :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
    signal    k_out_c               :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    k_out_c_pos           :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    k_out_c_size          :  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
    signal    k_k3x3                :  std_logic;
    signal    k_req_valid           :  std_logic;
    signal    k_req_ready           :  std_logic;
    signal    k_res_valid           :  std_logic;
    signal    k_res_ready           :  std_logic;
    signal    k_res_none            :  std_logic;
    signal    k_res_error           :  std_logic;
    
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  T_DATA_WIDTH          :  integer := QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS;
    signal    t_data_addr           :  std_logic_vector(DATA_ADDR_WIDTH              -1 downto 0);
    signal    t_data                :  std_logic_vector(T_DATA_WIDTH                 -1 downto 0);
    signal    t_data_last           :  std_logic;
    signal    t_data_valid          :  std_logic;
    signal    t_data_ready          :  std_logic;
    signal    t_out_c               :  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
    signal    t_out_c_pos           :  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
    signal    t_out_c_size          :  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
    signal    t_req_valid           :  std_logic;
    signal    t_req_ready           :  std_logic;
    signal    t_res_valid           :  std_logic;
    signal    t_res_ready           :  std_logic;
    signal    t_res_none            :  std_logic;
    signal    t_res_error           :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    RESET <= '1' when (ARESETn = '0') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    S_AXI_IF: AXI4_REGISTER_INTERFACE                -- 
        generic map (                                -- 
            AXI4_ADDR_WIDTH => S_AXI_ADDR_WIDTH    , --
            AXI4_DATA_WIDTH => S_AXI_DATA_WIDTH    , --
            AXI4_ID_WIDTH   => S_AXI_ID_WIDTH      , --
            REGS_ADDR_WIDTH => REGS_ADDR_WIDTH     , --
            REGS_DATA_WIDTH => REGS_DATA_WIDTH       --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals.
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            ARID            => S_AXI_ARID          , -- In  :
            ARADDR          => S_AXI_ARADDR        , -- In  :
            ARLEN           => S_AXI_ARLEN         , -- In  :
            ARSIZE          => S_AXI_ARSIZE        , -- In  :
            ARBURST         => S_AXI_ARBURST       , -- In  :
            ARVALID         => S_AXI_ARVALID       , -- In  :
            ARREADY         => S_AXI_ARREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            RID             => S_AXI_RID           , -- Out :
            RDATA           => S_AXI_RDATA         , -- Out :
            RRESP           => S_AXI_RRESP         , -- Out :
            RLAST           => S_AXI_RLAST         , -- Out :
            RVALID          => S_AXI_RVALID        , -- Out :
            RREADY          => S_AXI_RREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            AWID            => S_AXI_AWID          , -- In  :
            AWADDR          => S_AXI_AWADDR        , -- In  :
            AWLEN           => S_AXI_AWLEN         , -- In  :
            AWSIZE          => S_AXI_AWSIZE        , -- In  :
            AWBURST         => S_AXI_AWBURST       , -- In  :
            AWVALID         => S_AXI_AWVALID       , -- In  :
            AWREADY         => S_AXI_AWREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            WDATA           => S_AXI_WDATA         , -- In  :
            WSTRB           => S_AXI_WSTRB         , -- In  :
            WLAST           => S_AXI_WLAST         , -- In  :
            WVALID          => S_AXI_WVALID        , -- In  :
            WREADY          => S_AXI_WREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            BID             => S_AXI_BID           , -- Out :
            BRESP           => S_AXI_BRESP         , -- Out :
            BVALID          => S_AXI_BVALID        , -- Out :
            BREADY          => S_AXI_BREADY        , -- In  :
        ---------------------------------------------------------------------------
        -- Register Interface.
        ---------------------------------------------------------------------------
            REGS_REQ        => regs_req            , -- Out :
            REGS_WRITE      => regs_write          , -- Out :
            REGS_ACK        => regs_ack            , -- In  :
            REGS_ERR        => regs_err            , -- In  :
            REGS_ADDR       => regs_addr           , -- Out :
            REGS_BEN        => regs_ben            , -- Out :
            REGS_WDATA      => regs_wdata          , -- Out :
            REGS_RDATA      => regs_rdata            -- In  :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I_AXI_IF: QCONV_STRIP_IN_DATA_AXI_READER         -- 
        generic map (                                -- 
            QCONV_PARAM     => QCONV_PARAM         , --
            AXI_ADDR_WIDTH  => I_AXI_ADDR_WIDTH    , --
            AXI_DATA_WIDTH  => I_AXI_DATA_WIDTH    , --
            AXI_ID_WIDTH    => I_AXI_ID_WIDTH      , --
            AXI_USER_WIDTH  => I_AXI_USER_WIDTH    , --
            AXI_XFER_SIZE   => I_AXI_XFER_SIZE     , --
            AXI_ID          => I_AXI_ID            , --
            AXI_PROT        => I_AXI_PROT          , --
            AXI_QOS         => I_AXI_QOS           , --
            AXI_REGION      => I_AXI_REGION        , -- 
            AXI_CACHE       => I_AXI_CACHE         , --
            AXI_AUSER       => I_AXI_AUSER         , --
            AXI_REQ_QUEUE   => I_AXI_REQ_QUEUE     , --
            REQ_ADDR_WIDTH  => DATA_ADDR_WIDTH       -- 
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock / Reset Signals.
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            AXI_ARID        => IO_AXI_ARID         , -- Out :
            AXI_ARADDR      => IO_AXI_ARADDR       , -- Out :
            AXI_ARLEN       => IO_AXI_ARLEN        , -- Out :
            AXI_ARSIZE      => IO_AXI_ARSIZE       , -- Out :
            AXI_ARBURST     => IO_AXI_ARBURST      , -- Out :
            AXI_ARLOCK      => IO_AXI_ARLOCK       , -- Out :
            AXI_ARCACHE     => IO_AXI_ARCACHE      , -- Out :
            AXI_ARPROT      => IO_AXI_ARPROT       , -- Out :
            AXI_ARQOS       => IO_AXI_ARQOS        , -- Out :
            AXI_ARREGION    => IO_AXI_ARREGION     , -- Out :
            AXI_ARUSER      => IO_AXI_ARUSER       , -- Out :
            AXI_ARVALID     => IO_AXI_ARVALID      , -- Out :
            AXI_ARREADY     => IO_AXI_ARREADY      , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            AXI_RID         => IO_AXI_RID          , -- In  :
            AXI_RDATA       => IO_AXI_RDATA        , -- In  :
            AXI_RRESP       => IO_AXI_RRESP        , -- In  :
            AXI_RLAST       => IO_AXI_RLAST        , -- In  :
            AXI_RVALID      => IO_AXI_RVALID       , -- In  :
            AXI_RREADY      => IO_AXI_RREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Stream Master Interface.
        ---------------------------------------------------------------------------
            O_DATA          => i_data              , -- Out :
            O_LAST          => i_data_last         , -- Out :
            O_VALID         => i_data_valid        , -- Out :
            O_READY         => i_data_ready        , -- In  :
        ---------------------------------------------------------------------------
        -- Request / Response Interface.
        ---------------------------------------------------------------------------
            REQ_ADDR        => i_data_addr         , -- In  :
            REQ_IN_C        => i_in_c              , -- In  :
            REQ_IN_W        => i_in_w              , -- In  :
            REQ_IN_H        => i_in_h              , -- In  :
            REQ_X_POS       => i_x_pos             , -- In  :
            REQ_X_SIZE      => i_x_size            , -- In  :
            REQ_VALID       => i_req_valid         , -- In  :
            REQ_READY       => i_req_ready         , -- Out :
            RES_VALID       => i_res_valid         , -- Out :
            RES_NONE        => i_res_none          , -- Out :
            RES_ERROR       => i_res_error         , -- Out :
            RES_READY       => i_res_ready           -- In  :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_AXI_IF: QCONV_STRIP_OUT_DATA_AXI_WRITER        -- 
        generic map (                                -- 
            QCONV_PARAM     => QCONV_PARAM         , --
            AXI_ADDR_WIDTH  => O_AXI_ADDR_WIDTH    , --
            AXI_DATA_WIDTH  => O_AXI_DATA_WIDTH    , --
            AXI_ID_WIDTH    => O_AXI_ID_WIDTH      , --
            AXI_USER_WIDTH  => O_AXI_USER_WIDTH    , --
            AXI_XFER_SIZE   => O_AXI_XFER_SIZE     , --
            AXI_ID          => O_AXI_ID            , --
            AXI_PROT        => O_AXI_PROT          , --
            AXI_QOS         => O_AXI_QOS           , --
            AXI_REGION      => O_AXI_REGION        , --
            AXI_CACHE       => O_AXI_CACHE         , --
            AXI_AUSER       => O_AXI_AUSER         , --
            AXI_REQ_QUEUE   => O_AXI_REQ_QUEUE     , --
            I_DATA_WIDTH    => O_DATA_WIDTH        , --
            REQ_ADDR_WIDTH  => DATA_ADDR_WIDTH       --
        )                                            -- 
        port map(                                    -- 
        ---------------------------------------------------------------------------
        -- Clock / Reset Signals.
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        ---------------------------------------------------------------------------
            AXI_AWID        => IO_AXI_AWID         , -- Out :
            AXI_AWADDR      => IO_AXI_AWADDR       , -- Out :
            AXI_AWLEN       => IO_AXI_AWLEN        , -- Out :
            AXI_AWSIZE      => IO_AXI_AWSIZE       , -- Out :
            AXI_AWBURST     => IO_AXI_AWBURST      , -- Out :
            AXI_AWLOCK      => IO_AXI_AWLOCK       , -- Out :
            AXI_AWCACHE     => IO_AXI_AWCACHE      , -- Out :
            AXI_AWPROT      => IO_AXI_AWPROT       , -- Out :
            AXI_AWQOS       => IO_AXI_AWQOS        , -- Out :
            AXI_AWREGION    => IO_AXI_AWREGION     , -- Out :
            AXI_AWUSER      => IO_AXI_AWUSER       , -- Out :
            AXI_AWVALID     => IO_AXI_AWVALID      , -- Out :
            AXI_AWREADY     => IO_AXI_AWREADY      , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        ---------------------------------------------------------------------------
            AXI_WID         => IO_AXI_WID          , -- Out :
            AXI_WDATA       => IO_AXI_WDATA        , -- Out :
            AXI_WSTRB       => IO_AXI_WSTRB        , -- Out :
            AXI_WLAST       => IO_AXI_WLAST        , -- Out :
            AXI_WVALID      => IO_AXI_WVALID       , -- Out :
            AXI_WREADY      => IO_AXI_WREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        ---------------------------------------------------------------------------
            AXI_BID         => IO_AXI_BID          , -- In  :
            AXI_BRESP       => IO_AXI_BRESP        , -- In  :
            AXI_BVALID      => IO_AXI_BVALID       , -- In  :
            AXI_BREADY      => IO_AXI_BREADY       , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Stream Slave Interface.
        ---------------------------------------------------------------------------
            I_DATA          => o_data              , -- In  :
            I_STRB          => o_data_strb         , -- In  :
            I_LAST          => o_data_last         , -- In  :
            I_VALID         => o_data_valid        , -- In  :
            I_READY         => o_data_ready        , -- Out :
        ---------------------------------------------------------------------------
        -- Request / Response Interface.
        ---------------------------------------------------------------------------
            REQ_ADDR        => o_data_addr         , -- In  :
            REQ_OUT_C       => o_out_c             , -- In  :
            REQ_OUT_W       => o_out_w             , -- In  :
            REQ_OUT_H       => o_out_h             , -- In  :
            REQ_C_POS       => o_c_pos             , -- In  :
            REQ_C_SIZE      => o_c_size            , -- In  :
            REQ_X_POS       => o_x_pos             , -- In  :
            REQ_X_SIZE      => o_x_size            , -- In  :
            REQ_USE_TH      => o_use_th            , -- In  :
            REQ_VALID       => o_req_valid         , -- In  :
            REQ_READY       => o_req_ready         , -- Out :
            RES_VALID       => o_res_valid         , -- Out :
            RES_NONE        => o_res_none          , -- Out :
            RES_ERROR       => o_res_error         , -- Out :
            RES_READY       => o_res_ready           -- In  :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    K_AXI_IF: QCONV_STRIP_K_DATA_AXI_READER          -- 
        generic map (                                -- 
            QCONV_PARAM     => QCONV_PARAM         , -- 
            AXI_ADDR_WIDTH  => K_AXI_ADDR_WIDTH    , --
            AXI_DATA_WIDTH  => K_AXI_DATA_WIDTH    , --
            AXI_ID_WIDTH    => K_AXI_ID_WIDTH      , --
            AXI_USER_WIDTH  => K_AXI_USER_WIDTH    , --
            AXI_XFER_SIZE   => K_AXI_XFER_SIZE     , --
            AXI_ID          => K_AXI_ID            , --
            AXI_PROT        => K_AXI_PROT          , --
            AXI_QOS         => K_AXI_QOS           , --
            AXI_REGION      => K_AXI_REGION        , --
            AXI_CACHE       => K_AXI_CACHE         , --
            AXI_AUSER       => K_AXI_AUSER         , --
            AXI_REQ_QUEUE   => K_AXI_REQ_QUEUE     , --
            REQ_ADDR_WIDTH  => DATA_ADDR_WIDTH       --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock / Reset Signals.
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            AXI_ARID        => K_AXI_ARID          , -- Out :
            AXI_ARADDR      => K_AXI_ARADDR        , -- Out :
            AXI_ARLEN       => K_AXI_ARLEN         , -- Out :
            AXI_ARSIZE      => K_AXI_ARSIZE        , -- Out :
            AXI_ARBURST     => K_AXI_ARBURST       , -- Out :
            AXI_ARLOCK      => K_AXI_ARLOCK        , -- Out :
            AXI_ARCACHE     => K_AXI_ARCACHE       , -- Out :
            AXI_ARPROT      => K_AXI_ARPROT        , -- Out :
            AXI_ARQOS       => K_AXI_ARQOS         , -- Out :
            AXI_ARREGION    => K_AXI_ARREGION      , -- Out :
            AXI_ARUSER      => K_AXI_ARUSER        , -- Out :
            AXI_ARVALID     => K_AXI_ARVALID       , -- Out :
            AXI_ARREADY     => K_AXI_ARREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            AXI_RID         => K_AXI_RID           , -- In  :
            AXI_RDATA       => K_AXI_RDATA         , -- In  :
            AXI_RRESP       => K_AXI_RRESP         , -- In  :
            AXI_RLAST       => K_AXI_RLAST         , -- In  :
            AXI_RVALID      => K_AXI_RVALID        , -- In  :
            AXI_RREADY      => K_AXI_RREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Stream Master Interface.
        ---------------------------------------------------------------------------
            O_DATA          => k_data              , -- Out :
            O_LAST          => k_data_last         , -- Out :
            O_VALID         => k_data_valid        , -- Out :
            O_READY         => k_data_ready        , -- In  :
        ---------------------------------------------------------------------------
        -- Request / Response Interface.
        ---------------------------------------------------------------------------
            REQ_ADDR        => k_data_addr         , -- In  :
            REQ_IN_C        => k_in_c_by_word      , -- In  :
            REQ_OUT_C       => k_out_c             , -- In  :
            REQ_OUT_C_POS   => k_out_c_pos         , -- In  :
            REQ_OUT_C_SIZE  => k_out_c_size        , -- In  :
            REQ_K3x3        => k_k3x3              , -- In  :
            REQ_VALID       => k_req_valid         , -- In  :
            REQ_READY       => k_req_ready         , -- Out :
            RES_VALID       => k_res_valid         , -- Out :
            RES_NONE        => k_res_none          , -- Out :
            RES_ERROR       => k_res_error         , -- Out :
            RES_READY       => k_res_ready           -- In  :
        );
    K_AXI_AWID     <= (others => '0');
    K_AXI_AWADDR   <= (others => '0');
    K_AXI_AWLEN    <= (others => '0');
    K_AXI_AWSIZE   <= (others => '0');
    K_AXI_AWBURST  <= (others => '0');
    K_AXI_AWLOCK   <= (others => '0');
    K_AXI_AWCACHE  <= (others => '0');
    K_AXI_AWPROT   <= (others => '0');
    K_AXI_AWQOS    <= (others => '0');
    K_AXI_AWREGION <= (others => '0');
    K_AXI_AWUSER   <= (others => '0');
    K_AXI_AWVALID  <= '0';
    K_AXI_WID      <= (others => '0');
    K_AXI_WDATA    <= (others => '0');
    K_AXI_WSTRB    <= (others => '0');
    K_AXI_WLAST    <= '0';
    K_AXI_WVALID   <= '0';
    K_AXI_BREADY   <= '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    T_AXI_IF: QCONV_STRIP_TH_DATA_AXI_READER         -- 
        generic map (                                -- 
            QCONV_PARAM     => QCONV_PARAM         , -- 
            AXI_ADDR_WIDTH  => T_AXI_ADDR_WIDTH    , --
            AXI_DATA_WIDTH  => T_AXI_DATA_WIDTH    , --
            AXI_ID_WIDTH    => T_AXI_ID_WIDTH      , --
            AXI_USER_WIDTH  => T_AXI_USER_WIDTH    , --
            AXI_XFER_SIZE   => T_AXI_XFER_SIZE     , --
            AXI_ID          => T_AXI_ID            , --
            AXI_PROT        => T_AXI_PROT          , --
            AXI_QOS         => T_AXI_QOS           , --
            AXI_REGION      => T_AXI_REGION        , --
            AXI_CACHE       => T_AXI_CACHE         , --
            AXI_AUSER       => T_AXI_AUSER         , --
            AXI_REQ_QUEUE   => T_AXI_REQ_QUEUE     , --
            REQ_ADDR_WIDTH  => DATA_ADDR_WIDTH       --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- Clock / Reset Signals.
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            AXI_ARID        => T_AXI_ARID          , -- Out :
            AXI_ARADDR      => T_AXI_ARADDR        , -- Out :
            AXI_ARLEN       => T_AXI_ARLEN         , -- Out :
            AXI_ARSIZE      => T_AXI_ARSIZE        , -- Out :
            AXI_ARBURST     => T_AXI_ARBURST       , -- Out :
            AXI_ARLOCK      => T_AXI_ARLOCK        , -- Out :
            AXI_ARCACHE     => T_AXI_ARCACHE       , -- Out :
            AXI_ARPROT      => T_AXI_ARPROT        , -- Out :
            AXI_ARQOS       => T_AXI_ARQOS         , -- Out :
            AXI_ARREGION    => T_AXI_ARREGION      , -- Out :
            AXI_ARUSER      => T_AXI_ARUSER        , -- Out :
            AXI_ARVALID     => T_AXI_ARVALID       , -- Out :
            AXI_ARREADY     => T_AXI_ARREADY       , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            AXI_RID         => T_AXI_RID           , -- In  :
            AXI_RDATA       => T_AXI_RDATA         , -- In  :
            AXI_RRESP       => T_AXI_RRESP         , -- In  :
            AXI_RLAST       => T_AXI_RLAST         , -- In  :
            AXI_RVALID      => T_AXI_RVALID        , -- In  :
            AXI_RREADY      => T_AXI_RREADY        , -- Out :
        ---------------------------------------------------------------------------
        -- AXI4 Stream Master Interface.
        ---------------------------------------------------------------------------
            O_DATA          => t_data              , -- Out :
            O_LAST          => t_data_last         , -- Out :
            O_VALID         => t_data_valid        , -- Out :
            O_READY         => t_data_ready        , -- In  :
        ---------------------------------------------------------------------------
        -- Request / Response Interface.
        ---------------------------------------------------------------------------
            REQ_ADDR        => t_data_addr         , -- In  :
            REQ_OUT_C       => t_out_c             , -- In  :
            REQ_OUT_C_POS   => t_out_c_pos         , -- In  :
            REQ_OUT_C_SIZE  => t_out_c_size        , -- In  :
            REQ_VALID       => t_req_valid         , -- In  :
            REQ_READY       => t_req_ready         , -- Out :
            RES_VALID       => t_res_valid         , -- Out :
            RES_NONE        => t_res_none          , -- Out :
            RES_ERROR       => t_res_error         , -- Out :
            RES_READY       => t_res_ready           -- In  :
        );
    T_AXI_AWID     <= (others => '0');
    T_AXI_AWADDR   <= (others => '0');
    T_AXI_AWLEN    <= (others => '0');
    T_AXI_AWSIZE   <= (others => '0');
    T_AXI_AWBURST  <= (others => '0');
    T_AXI_AWLOCK   <= (others => '0');
    T_AXI_AWCACHE  <= (others => '0');
    T_AXI_AWPROT   <= (others => '0');
    T_AXI_AWQOS    <= (others => '0');
    T_AXI_AWREGION <= (others => '0');
    T_AXI_AWUSER   <= (others => '0');
    T_AXI_AWVALID  <= '0';
    T_AXI_WID      <= (others => '0');
    T_AXI_WDATA    <= (others => '0');
    T_AXI_WSTRB    <= (others => '0');
    T_AXI_WLAST    <= '0';
    T_AXI_WVALID   <= '0';
    T_AXI_BREADY   <= '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    REGS: QCONV_STRIP_REGISTERS                      -- 
        generic map (                                -- 
            ID              => ID                  , -- 
            QCONV_PARAM     => QCONV_PARAM         , -- 
            DATA_ADDR_WIDTH => DATA_ADDR_WIDTH     , -- 
            REGS_ADDR_WIDTH => REGS_ADDR_WIDTH     , -- 
            REGS_DATA_WIDTH => REGS_DATA_WIDTH       -- 
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- Register Access Interface
        ---------------------------------------------------------------------------
            REGS_REQ        => regs_req            , -- In  :
            REGS_WRITE      => regs_write          , -- In  :
            REGS_ADDR       => regs_addr           , -- In  :
            REGS_BEN        => regs_ben            , -- In  :
            REGS_WDATA      => regs_wdata          , -- In  :
            REGS_RDATA      => regs_rdata          , -- Out :
            REGS_ACK        => regs_ack            , -- Out :
            REGS_ERR        => regs_err            , -- Out :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Registers
        ---------------------------------------------------------------------------
            I_DATA_ADDR     => i_data_addr         , -- Out :
            O_DATA_ADDR     => o_data_addr         , -- Out :
            K_DATA_ADDR     => k_data_addr         , -- Out :
            T_DATA_ADDR     => t_data_addr         , -- Out :
            I_WIDTH         => ctrl_in_w           , -- Out :
            I_HEIGHT        => ctrl_in_h           , -- Out :
            I_CHANNELS      => ctrl_in_c_by_word   , -- Out :
            O_WIDTH         => ctrl_out_w          , -- Out :
            O_HEIGHT        => ctrl_out_h          , -- Out :
            O_CHANNELS      => ctrl_out_c          , -- Out :
            K_WIDTH         => ctrl_k_w            , -- Out :
            K_HEIGHT        => ctrl_k_h            , -- Out :
            PAD_SIZE        => ctrl_pad_size       , -- Out :
            USE_TH          => ctrl_use_th         , -- Out :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Request/Response Interface
        ---------------------------------------------------------------------------
            REQ_VALID       => ctrl_req_valid      , -- Out :
            REQ_READY       => ctrl_req_ready      , -- In  :
            RES_VALID       => ctrl_res_valid      , -- In  :
            RES_READY       => ctrl_res_ready      , -- Out :
            RES_STATUS      => ctrl_res_status     , -- In  :
            REQ_RESET       => open                , -- Out :
            REQ_STOP        => open                , -- Out :
            REQ_PAUSE       => open                , -- Out :
        ---------------------------------------------------------------------------
        -- Interrupt Request 
        ---------------------------------------------------------------------------
            IRQ             => IRQ                   -- Out :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CTRL: QCONV_STRIP_CONTROLLER                     -- 
        generic map (                                -- 
            QCONV_PARAM     => QCONV_PARAM         , -- 
            IN_BUF_SIZE     => IN_BUF_SIZE         , --
            K_BUF_SIZE      => K_BUF_SIZE          , --
            IN_C_UNROLL     => IN_C_UNROLL           --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Register Interface
        ---------------------------------------------------------------------------
            IN_C_BY_WORD    => ctrl_in_c_by_word   , -- In  :
            IN_W            => ctrl_in_w           , -- In  :
            IN_H            => ctrl_in_h           , -- In  :
            OUT_C           => ctrl_out_c          , -- In  :
            OUT_W           => ctrl_out_w          , -- In  :
            OUT_H           => ctrl_out_h          , -- In  :
            K_W             => ctrl_k_w            , -- In  :
            K_H             => ctrl_k_h            , -- In  :
            PAD_SIZE        => ctrl_pad_size       , -- In  :
            USE_TH          => ctrl_use_th         , -- In  :
            REQ_VALID       => ctrl_req_valid      , -- In  :
            REQ_READY       => ctrl_req_ready      , -- Out :
            RES_VALID       => ctrl_res_valid      , -- Out :
            RES_READY       => ctrl_res_ready      , -- In  :
            RES_STATUS      => ctrl_res_status     , -- Out :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Core Module Interface
        ---------------------------------------------------------------------------
            CORE_IN_C       => core_in_c_by_word   , -- Out :
            CORE_IN_W       => core_in_w           , -- Out :
            CORE_IN_H       => core_in_h           , -- Out :
            CORE_OUT_C      => core_out_c          , -- Out :
            CORE_OUT_W      => core_out_w          , -- Out :
            CORE_OUT_H      => core_out_h          , -- Out :
            CORE_K_W        => core_k_w            , -- Out :
            CORE_K_H        => core_k_h            , -- Out :
            CORE_L_PAD_SIZE => core_l_pad_size     , -- Out :
            CORE_R_PAD_SIZE => core_r_pad_size     , -- Out :
            CORE_T_PAD_SIZE => core_t_pad_size     , -- Out :
            CORE_B_PAD_SIZE => core_b_pad_size     , -- Out :
            CORE_USE_TH     => core_use_th         , -- Out :
            CORE_PARAM_IN   => core_param_in       , -- Out :
            CORE_REQ_VALID  => core_req_valid      , -- Out :
            CORE_REQ_READY  => core_req_ready      , -- In  :
            CORE_RES_VALID  => core_res_valid      , -- In  :
            CORE_RES_READY  => core_res_ready      , -- Out :
            CORE_RES_STATUS => core_res_status     , -- In  :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) In Data AXI Reader Module Interface
        ---------------------------------------------------------------------------
            I_IN_C          => i_in_c              , -- Out :
            I_IN_W          => i_in_w              , -- Out :
            I_IN_H          => i_in_h              , -- Out :
            I_X_POS         => i_x_pos             , -- Out :
            I_X_SIZE        => i_x_size            , -- Out :
            I_REQ_VALID     => i_req_valid         , -- Out :
            I_REQ_READY     => i_req_ready         , -- In  :
            I_RES_VALID     => i_res_valid         , -- In  :
            I_RES_READY     => i_res_ready         , -- Out :
            I_RES_NONE      => i_res_none          , -- In  :
            I_RES_ERROR     => i_res_error         , -- In  :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Kernel Weight Data AXI Reader Module Interface
        ---------------------------------------------------------------------------
            K_IN_C          => k_in_c_by_word      , -- Out :
            K_OUT_C         => k_out_c             , -- Out :
            K_OUT_C_POS     => k_out_c_pos         , -- Out :
            K_OUT_C_SIZE    => k_out_c_size        , -- Out :
            K_REQ_K3x3      => k_k3x3              , -- Out :
            K_REQ_VALID     => k_req_valid         , -- Out :
            K_REQ_READY     => k_req_ready         , -- In  :
            K_RES_VALID     => k_res_valid         , -- In  :
            K_RES_READY     => k_res_ready         , -- Out :
            K_RES_NONE      => k_res_none          , -- In  :
            K_RES_ERROR     => k_res_error         , -- In  :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Thresholds Data AXI Reader Module Interface
        ---------------------------------------------------------------------------
            T_OUT_C         => t_out_c             , -- Out :
            T_OUT_C_POS     => t_out_c_pos         , -- Out :
            T_OUT_C_SIZE    => t_out_c_size        , -- Out :
            T_REQ_VALID     => t_req_valid         , -- Out :
            T_REQ_READY     => t_req_ready         , -- In  :
            T_RES_VALID     => t_res_valid         , -- In  :
            T_RES_READY     => t_res_ready         , -- Out :
            T_RES_NONE      => t_res_none          , -- In  :
            T_RES_ERROR     => t_res_error         , -- In  :
        ---------------------------------------------------------------------------
        -- Quantized Convolution (strip) Out Data AXI Writer Module Interface
        ---------------------------------------------------------------------------
            O_OUT_C         => o_out_c             , -- Out :
            O_OUT_W         => o_out_w             , -- Out :
            O_OUT_H         => o_out_h             , -- Out :
            O_C_POS         => o_c_pos             , -- Out :
            O_C_SIZE        => o_c_size            , -- Out :
            O_X_POS         => o_x_pos             , -- Out :
            O_X_SIZE        => o_x_size            , -- Out :
            O_USE_TH        => o_use_th            , -- Out :
            O_REQ_VALID     => o_req_valid         , -- Out :
            O_REQ_READY     => o_req_ready         , -- In  :
            O_RES_VALID     => o_res_valid         , -- In  :
            O_RES_READY     => o_res_ready         , -- Out :
            O_RES_NONE      => o_res_none          , -- In  :
            O_RES_ERROR     => o_res_error           -- In  :
        );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CORE: QCONV_STRIP_CORE
        generic map (                                -- 
            QCONV_PARAM     => QCONV_PARAM         , -- 
            IN_BUF_SIZE     => IN_BUF_SIZE         , -- 
            K_BUF_SIZE      => K_BUF_SIZE          , -- 
            TH_BUF_SIZE     => TH_BUF_SIZE         , -- 
            IN_C_UNROLL     => IN_C_UNROLL         , -- 
            OUT_C_UNROLL    => OUT_C_UNROLL        , -- 
            OUT_DATA_BITS   => O_DATA_WIDTH          -- 
        )
        port map (
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => ACLK                , -- In  :
            RST             => RESET               , -- In  :
            CLR             => CLEAR               , -- In  :
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            IN_C_BY_WORD    => core_in_c_by_word   , -- In  :
            IN_W            => core_in_w           , -- In  :
            IN_H            => core_in_h           , -- In  :
            OUT_C           => core_out_c          , -- In  :
            OUT_W           => core_out_w          , -- In  :
            OUT_H           => core_out_h          , -- In  :
            K_W             => core_k_w            , -- In  :
            K_H             => core_k_h            , -- In  :
            LEFT_PAD_SIZE   => core_l_pad_size     , -- In  :
            RIGHT_PAD_SIZE  => core_r_pad_size     , -- In  :
            TOP_PAD_SIZE    => core_t_pad_size     , -- In  :
            BOTTOM_PAD_SIZE => core_b_pad_size     , -- In  :
            USE_TH          => core_use_th         , -- In  :
            PARAM_IN        => core_param_in       , -- In  :
            REQ_VALID       => core_req_valid      , -- In  :
            REQ_READY       => core_req_ready      , -- Out :
            RES_VALID       => core_res_valid      , -- Out :
            RES_READY       => core_res_ready      , -- In  :
        ---------------------------------------------------------------------------
        -- データ入力 I/F
        ---------------------------------------------------------------------------
            IN_DATA         => i_data              , -- In  :
            IN_VALID        => i_data_valid        , -- In  :
            IN_READY        => i_data_ready        , -- Out :
        ---------------------------------------------------------------------------
        -- カーネル係数入力 I/F
        ---------------------------------------------------------------------------
            K_DATA          => k_data              , -- In  :
            K_VALID         => k_data_valid        , -- In  :
            K_READY         => k_data_ready        , -- Out :
        ---------------------------------------------------------------------------
        -- スレッシュホールド係数入力 I/F
        ---------------------------------------------------------------------------
            TH_DATA         => t_data              , -- In  :
            TH_VALID        => t_data_valid        , -- In  :
            TH_READY        => t_data_ready        , -- Out :
        ---------------------------------------------------------------------------
        -- データ出力 I/F
        ---------------------------------------------------------------------------
            OUT_DATA        => o_data              , -- Out :
            OUT_STRB        => o_data_strb         , -- Out :
            OUT_LAST        => o_data_last         , -- Out :
            OUT_VALID       => o_data_valid        , -- Out :
            OUT_READY       => o_data_ready          -- In  :
    );
end RTL;

