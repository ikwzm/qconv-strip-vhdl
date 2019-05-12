-----------------------------------------------------------------------------------
--!     @file    qconv_components.vhd                                            --
--!     @brief   Quantized Convolution Component Library                         --
--!     @version 0.2.0                                                           --
--!     @date    2019/05/12                                                      --
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>                     --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--                                                                               --
--      Copyright (C) 2019 Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>           --
--      All rights reserved.                                                     --
--                                                                               --
--      Redistribution and use in source and binary forms, with or without       --
--      modification, are permitted provided that the following conditions       --
--      are met:                                                                 --
--                                                                               --
--        1. Redistributions of source code must retain the above copyright      --
--           notice, this list of conditions and the following disclaimer.       --
--                                                                               --
--        2. Redistributions in binary form must reproduce the above copyright   --
--           notice, this list of conditions and the following disclaimer in     --
--           the documentation and/or other materials provided with the          --
--           distribution.                                                       --
--                                                                               --
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS      --
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT        --
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR    --
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT    --
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    --
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT         --
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,    --
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY    --
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT      --
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE    --
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.     --
--                                                                               --
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
-----------------------------------------------------------------------------------
--! @brief Quantized Convolution Component Library                               --
-----------------------------------------------------------------------------------
package QCONV_COMPONENTS is
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_AXI_CORE                                                  --
-----------------------------------------------------------------------------------
component QCONV_STRIP_AXI_CORE
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
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_CORE                                                      --
-----------------------------------------------------------------------------------
component QCONV_STRIP_CORE
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        IN_BUF_SIZE     : --! @brief IN DATA BUFFER SIZE :
                          --! 入力バッファの容量を指定する.
                          --! * ここで指定する単位は1ワード単位.
                          --! * 1ワードは QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD
                          --!   = 64 bit.
                          --! * 入力バッファの容量は 入力チャネル × イメージの幅.
                          integer := 512*4*1;  -- 512word × BANK_SIZE × IN_C_UNROLL 
        K_BUF_SIZE      : --! @brief K DATA BUFFER SIZE :
                          --! カーネル係数バッファの容量を指定する.
                          --! * ここで指定する単位は1ワード単位.
                          --! * 1ワードは 3 * 3 * QCONV_PARAM.NBITS_K_DATA * QCONV_PARAM.NBITS_PER_WORD
                          --! * カーネル係数バッファの容量は K_BUF_SIZE * 288bit になる.
                          integer := 512*3*3*16*1;  -- 512word × 3 × 3 × OUT_C_UNROLL × IN_C_UNROLL
        TH_BUF_SIZE     : --! @brief THRESHOLDS DATA BUFFER SIZE :
                          --! THRESHOLDS バッファの容量を指定する.
                          --! * ここで指定する単位は1ワード単位.
                          --! * 1ワードは QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS
                          --! * = 64bit
                          integer := 512*16;
        IN_C_UNROLL     : --! @brief INPUT  CHANNEL UNROLL SIZE :
                          integer := 1;
        OUT_C_UNROLL    : --! @brief OUTPUT CHANNEL UNROLL SIZE :
                          integer := 16;
        OUT_DATA_BITS   : --! @brief OUTPUT DATA BIT SIZE :
                          --! OUT_DATA のビット幅を指定する.
                          --! * OUT_DATA のビット幅は、64の倍数でなければならない.
                          integer := 64
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        IN_C_BY_WORD    : --! @brief INPUT C CHANNEL SIZE :
                          in  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        IN_W            : --! @brief INPUT IMAGE WIDTH :
                          in  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        IN_H            : --! @brief INPUT IMAGE HEIGHT :
                          in  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        OUT_C           : --! @brief OUTPUT C CHANNEL SIZE :
                          in  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        OUT_W           : --! @brief OUTPUT IMAGE WIDTH :
                          in  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
        OUT_H           : --! @brief OUTPUT IMAGE HEIGHT :
                          in  std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
        K_W             : --! @brief KERNEL WIDTH :
                          in  std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
        K_H             : --! @brief KERNEL HEIGHT :
                          in  std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
        LEFT_PAD_SIZE   : --! @brief PAD SIZE REGISTER :
                          in  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        RIGHT_PAD_SIZE  : --! @brief PAD SIZE REGISTER :
                          in  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        TOP_PAD_SIZE    : --! @brief PAD SIZE REGISTER :
                          in  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        BOTTOM_PAD_SIZE : --! @brief PAD SIZE REGISTER :
                          in  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        USE_TH          : --! @brief USE THRESHOLD REGISTER :
                          in  std_logic_vector(1 downto 0);
        PARAM_IN        : --! @brief K DATA / TH DATA INPUT FLAG :
                          in  std_logic;
        REQ_VALID       : --! @brief REQUEST VALID :
                          in  std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          out std_logic;
        RES_VALID       : --! @brief RESPONSE VALID :
                          out std_logic;
        RES_READY       : --! @brief RESPONSE READY :
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- データ入力 I/F
    -------------------------------------------------------------------------------
        IN_DATA         : --! @brief INPUT IN_DATA :
                          --! IN_DATA 入力.
                          in  std_logic_vector(QCONV_PARAM.NBITS_IN_DATA*QCONV_PARAM.NBITS_PER_WORD-1 downto 0);
        IN_VALID        : --! @brief INPUT IN_DATA VALID :
                          --! IN_DATA 入力有効信号.
                          in  std_logic;
        IN_READY        : --! @brief INPUT IN_DATA READY :
                          --! IN_DATA レディ信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- カーネル係数入力 I/F
    -------------------------------------------------------------------------------
        K_DATA          : --! @brief INPUT K_DATA :
                          --! K_DATA 入力.
                          in  std_logic_vector(QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD-1 downto 0);
        K_VALID         : --! @brief INPUT K_DATA VALID :
                          --! K_DATA 入力有効信号.
                          in  std_logic;
        K_READY         : --! @brief INPUT K_DATA READY :
                          --! K_DATA レディ信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- スレッシュホールド係数入力 I/F
    -------------------------------------------------------------------------------
        TH_DATA         : --! @brief INPUT TH_DATA :
                          --! TH_DATA 入力.
                          in  std_logic_vector(QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS-1 downto 0);
        TH_VALID        : --! @brief INPUT TH_DATA VALID :
                          --! TH_DATA 入力有効信号.
                          in  std_logic;
        TH_READY        : --! @brief INPUT TH_DATA READY :
                          --! TH_DATA レディ信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- データ出力 I/F
    -------------------------------------------------------------------------------
        OUT_DATA        : --! @brief OUTPUT DATA :
                          --! OUT DATA 出力.
                          out std_logic_vector(OUT_DATA_BITS  -1 downto 0);
        OUT_STRB        : --! @brief OUTPUT DATA :
                          --! OUT DATA 出力.
                          out std_logic_vector(OUT_DATA_BITS/8-1 downto 0);
        OUT_LAST        : --! @brief OUTPUT LAST DATA :
                          --! OUT LAST 出力.
                          out std_logic;
        OUT_VALID       : --! @brief OUT_DATA VALID :
                          --! OUT_DATA 出力有効信号.
                          out std_logic;
        OUT_READY       : --! @brief OUT_DATA READY :
                          --! OUT_DATA レディ信号.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_CONTROLLER                                                --
-----------------------------------------------------------------------------------
component QCONV_STRIP_CONTROLLER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        IN_BUF_SIZE     : --! @brief IN DATA BUFFER SIZE :
                          --! 入力バッファの容量を指定する.
                          --! * ここで指定する単位は1ワード単位.
                          --! * 1ワードは QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD
                          --!   = 64 bit.
                          --! * 入力バッファの容量は 入力チャネル × イメージの幅.
                          integer := 512*4*1;  -- 512word × BANK_SIZE × IN_C_UNROLL 
        K_BUF_SIZE      : --! @brief K DATA BUFFER SIZE :
                          --! カーネル係数バッファの容量を指定する.
                          --! * ここで指定する単位は1ワード単位.
                          --! * 1ワードは 3 * 3 * QCONV_PARAM.NBITS_K_DATA * QCONV_PARAM.NBITS_PER_WORD
                          --! * カーネル係数バッファの容量は K_BUF_SIZE * 288bit になる.
                          integer := 512*3*3*16*1;  -- 512word × 3 × 3 × OUT_C_UNROLL × IN_C_UNROLL
        IN_C_UNROLL     : --! @brief INPUT  CHANNEL UNROLL SIZE :
                          integer := 1
    );
    port(
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Register Interface
    -------------------------------------------------------------------------------
        IN_C_BY_WORD    : in  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        IN_W            : in  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        IN_H            : in  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        OUT_C           : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        OUT_W           : in  std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
        OUT_H           : in  std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
        K_W             : in  std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
        K_H             : in  std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
        PAD_SIZE        : in  std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        USE_TH          : in  std_logic_vector(1 downto 0);
        REQ_VALID       : in  std_logic;
        REQ_READY       : out std_logic;
        RES_VALID       : out std_logic;
        RES_READY       : in  std_logic;
        RES_STATUS      : out std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Core Module Interface
    -------------------------------------------------------------------------------
        CORE_IN_C       : out std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        CORE_IN_W       : out std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        CORE_IN_H       : out std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        CORE_OUT_C      : out std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        CORE_OUT_W      : out std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
        CORE_OUT_H      : out std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
        CORE_K_W        : out std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
        CORE_K_H        : out std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
        CORE_L_PAD_SIZE : out std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        CORE_R_PAD_SIZE : out std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        CORE_T_PAD_SIZE : out std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        CORE_B_PAD_SIZE : out std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        CORE_USE_TH     : out std_logic_vector(1 downto 0);
        CORE_PARAM_IN   : out std_logic;
        CORE_REQ_VALID  : out std_logic;
        CORE_REQ_READY  : in  std_logic;
        CORE_RES_VALID  : in  std_logic;
        CORE_RES_READY  : out std_logic;
        CORE_RES_STATUS : in  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In Data AXI Reader Module Interface
    -------------------------------------------------------------------------------
        I_IN_C          : out std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        I_IN_W          : out std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        I_IN_H          : out std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        I_X_POS         : out std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        I_X_SIZE        : out std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        I_REQ_VALID     : out std_logic;
        I_REQ_READY     : in  std_logic;
        I_RES_VALID     : in  std_logic;
        I_RES_READY     : out std_logic;
        I_RES_NONE      : in  std_logic;
        I_RES_ERROR     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Kernel Weight Data AXI Reader Module Interface
    -------------------------------------------------------------------------------        
        K_IN_C          : out std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        K_OUT_C         : out std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        K_OUT_C_POS     : out std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        K_OUT_C_SIZE    : out std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        K_REQ_K3x3      : out std_logic;
        K_REQ_VALID     : out std_logic;
        K_REQ_READY     : in  std_logic;
        K_RES_VALID     : in  std_logic;
        K_RES_READY     : out std_logic;
        K_RES_NONE      : in  std_logic;
        K_RES_ERROR     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Thresholds Data AXI Reader Module Interface
    -------------------------------------------------------------------------------        
        T_OUT_C         : out std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        T_OUT_C_POS     : out std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        T_OUT_C_SIZE    : out std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        T_REQ_VALID     : out std_logic;
        T_REQ_READY     : in  std_logic;
        T_RES_VALID     : in  std_logic;
        T_RES_READY     : out std_logic;
        T_RES_NONE      : in  std_logic;
        T_RES_ERROR     : in  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Data AXI Writer Module Interface
    -------------------------------------------------------------------------------
        O_OUT_C         : out std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        O_OUT_W         : out std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
        O_OUT_H         : out std_logic_vector(QCONV_PARAM.OUT_H_BITS-1 downto 0);
        O_C_POS         : out std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        O_C_SIZE        : out std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        O_X_POS         : out std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
        O_X_SIZE        : out std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
        O_USE_TH        : out std_logic_vector(1 downto 0);
        O_REQ_VALID     : out std_logic;
        O_REQ_READY     : in  std_logic;
        O_RES_VALID     : in  std_logic;
        O_RES_READY     : out std_logic;
        O_RES_NONE      : in  std_logic;
        O_RES_ERROR     : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_REGISTERS                                                 --
-----------------------------------------------------------------------------------
component QCONV_STRIP_REGISTERS
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        ID              : --! @brief REGISTER ID STRING :
                          string(1 to 8) := "QCONV-S1";
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        DATA_ADDR_WIDTH : --! @brief I_DATA_ADDR/K_DATA_ADDR/T_DATA_ADDR/O_DATA_ADDR WIDTH :
                          integer := 64;
        REGS_ADDR_WIDTH : --! @brief REGISTER ADDRESS WIDTH :
                          --! レジスタアクセスインターフェースのアドレスのビット数.
                          integer := 7;
        REGS_DATA_WIDTH : --! @brief REGISTER ADDRESS WIDTH :
                          --! レジスタアクセスインターフェースのデータのビット数.
                          integer := 32
    );
    port(
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- Register Access Interface
    -------------------------------------------------------------------------------
        REGS_REQ        : --! @brief REGISTER ACCESS REQUEST :
                          --! レジスタアクセス要求信号.
                          in  std_logic;
        REGS_WRITE      : --! @brief REGISTER WRITE ACCESS :
                          --! レジスタライトアクセス信号.
                          --! * この信号が'1'の時はライトアクセスを行う.
                          --! * この信号が'0'の時はリードアクセスを行う.
                          in  std_logic;
        REGS_ADDR       : --! @brief REGISTER ACCESS ADDRESS :
                          --! レジスタアクセスアドレス信号.
                          in  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
        REGS_BEN        : --! @brief REGISTER BYTE ENABLE :
                          --! レジスタアクセスバイトイネーブル信号.
                          in  std_logic_vector(REGS_DATA_WIDTH/8-1 downto 0);
        REGS_WDATA      : --! @brief REGISTER ACCESS WRITE DATA :
                          --! レジスタアクセスライトデータ.
                          in  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        REGS_RDATA      : --! @brief REGISTER ACCESS READ DATA :
                          --! レジスタアクセスリードデータ.
                          out std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        REGS_ACK        : --! @brief REGISTER ACCESS ACKNOWLEDGE :
                          --! レジスタアクセス応答信号.
                          out std_logic;
        REGS_ERR        : --! @brief REGISTER ACCESS ERROR ACKNOWLEDGE :
                          --! レジスタアクセスエラー応答信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Registers
    -------------------------------------------------------------------------------
        I_DATA_ADDR     : --! @brief IN  DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        O_DATA_ADDR     : --! @brief OUT DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        K_DATA_ADDR     : --! @brief K   DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        T_DATA_ADDR     : --! @brief TH  DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        I_WIDTH         : --! @brief IN  WIDTH REGISTER :
                          out std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        I_HEIGHT        : --! @brief IN  HEIGHT REGISTER :
                          out std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        I_CHANNELS      : --! @brief IN  CHANNELS REGISTER :
                          out std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        O_WIDTH         : --! @brief OUT WIDTH REGISTER :
                          out std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
        O_HEIGHT        : --! @brief OUT HEIGHT REGISTER :
                          out std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
        O_CHANNELS      : --! @brief OUT CHANNELS REGISTER :
                          out std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        K_WIDTH         : --! @brief K   WIDTH REGISTER :
                          out std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
        K_HEIGHT        : --! @brief K   HEIGHT REGISTER :
                          out std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
        PAD_SIZE        : --! @brief PAD SIZE REGISTER :
                          out std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        USE_TH          : --! @brief USE THRESHOLD REGISTER :
                          out std_logic_vector(1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Request/Response Interface
    -------------------------------------------------------------------------------
        REQ_VALID       : --! @brief REQUEST VALID :
                          out std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          in  std_logic;
        RES_VALID       : --! @brief RESPONSE VALID :
                          in  std_logic;
        RES_READY       : --! @brief RESPONSE READY :
                          out std_logic;
        RES_STATUS      : --! @brief RESPONSE STATUS :
                          in  std_logic;
        REQ_RESET       : --! @brief RESET REQUEST :
                          out std_logic;
        REQ_STOP        : --! @brief STOP REQUEST :
                          out std_logic;
        REQ_PAUSE       : --! @brief PAUSE REQUEST :
                          out std_logic;
    -------------------------------------------------------------------------------
    -- Interrupt Request 
    -------------------------------------------------------------------------------
        IRQ             : --! @brief Interrupt Request :
                          out std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_IN_DATA_BUFFER                                            --
-----------------------------------------------------------------------------------
component QCONV_STRIP_IN_DATA_BUFFER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        O_PARAM         : --! @brief OUTPUT STREAM PARAMETER :
                          --! 出力側の IMAGE STREAM のパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                              ELEM_BITS => 64,
                              C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1*3*3*32),
                              D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1)
                          );
        I_SHAPE         : --! @brief INPUT  SHAPE :
                          --! 入力側のイメージの形(SHAPE)を指定する.
                          IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_EXTERNAL(64,1024,1024,1024);
        O_SHAPE         : --! @brief OUTPUT SHAPE :
                          --! 出力側のイメージの形(SHAPE)を指定する.
                          IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_EXTERNAL(64,1024,1024,1024);
        ELEMENT_SIZE    : --! @brief ELEMENT SIZE :
                          --! 列方向の要素数を指定する.
                          integer := 256;
        IN_C_UNROLL     : --! @brief INPUT  CHANNEL UNROLL SIZE :
                          integer := 1;
        OUT_C_UNROLL    : --! @brief OUTPUT CHANNEL UNROLL SIZE :
                          integer := 1;
        ID              : --! @brief SDPRAM IDENTIFIER :
                          --! どのモジュールで使われているかを示す識別番号.
                          integer := 0 
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        IN_C_BY_WORD    : --! @brief INPUT C CHANNEL SIZE :
                          in  integer range 0 to I_SHAPE.C.MAX_SIZE := I_SHAPE.C.SIZE;
        IN_W            : --! @brief INPUT IMAGE WIDTH :
                          in  integer range 0 to I_SHAPE.X.MAX_SIZE := I_SHAPE.X.SIZE;
        IN_H            : --! @brief INPUT IMAGE HEIGHT :
                          in  integer range 0 to I_SHAPE.Y.MAX_SIZE := I_SHAPE.Y.SIZE;
        OUT_C           : --! @brief OUTPUT C CHANNEL SIZE :
                          in  integer range 0 to O_SHAPE.C.MAX_SIZE := O_SHAPE.C.SIZE;
        OUT_W           : --! @brief OUTPUT IMAGE WIDTH :
                          in  integer range 0 to O_SHAPE.X.MAX_SIZE := O_SHAPE.X.SIZE;
        OUT_H           : --! @brief OUTPUT IMAGE HEIGHT :
                          in  integer range 0 to O_SHAPE.Y.MAX_SIZE := O_SHAPE.Y.SIZE;
        K3x3            : --! @brief KERNEL SIZE :
                          --! * Kernel が 3x3 の場合は'1'.
                          --! * Kernel が 1x1 の場合は'0'.
                          in  std_logic;
        LEFT_PAD_SIZE   : --! @brief IMAGE WIDTH START PAD SIZE :
                          in  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE := 0;
        RIGHT_PAD_SIZE  : --! @brief IMAGE WIDTH LAST  PAD SIZE :
                          in  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE := 0;
        TOP_PAD_SIZE    : --! @brief IMAGE HEIGHT START PAD SIZE :
                          in  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE := 0;
        BOTTOM_PAD_SIZE : --! @brief IMAGE HEIGHT LAST  PAD SIZE :
                          in  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE := 0;
        REQ_VALID       : --! @brief REQUEST VALID :
                          in  std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          out std_logic;
        RES_VALID       : --! @brief RESPONSE VALID :
                          out std_logic;
        RES_READY       : --! @brief RESPONSE READY :
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT IN_DATA :
                          --! IN_DATA 入力.
                          in  std_logic_vector(QCONV_PARAM.NBITS_IN_DATA*QCONV_PARAM.NBITS_PER_WORD-1 downto 0);
        I_VALID         : --! @brief INPUT IN_DATA VALID :
                          --! IN_DATA 入力有効信号.
                          in  std_logic;
        I_READY         : --! @brief INPUT IN_DATA READY :
                          --! IN_DATA レディ信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT IMAGE STREAM DATA :
                          --! ストリームデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT IMAGE STREAM DATA VALID :
                          --! 出力ストリームデータ有効信号.
                          out std_logic;
        O_READY         : --! @brief OUTPUT IMAGE STREAM DATA READY :
                          --! 出力ストリームデータレディ信号.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_TH_DATA_BUFFER                                            --
-----------------------------------------------------------------------------------
component QCONV_STRIP_TH_DATA_BUFFER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        O_PARAM         : --! @brief OUTPUT STREAM PARAMETER :
                          --! 出力側の IMAGE STREAM のパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                              ELEM_BITS => 64,
                              C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1)
                          );
        O_SHAPE         : --! @brief OUTPUT SHAPE :
                          --! 出力側のイメージの形(SHAPE)を指定する.
                          IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_EXTERNAL(64,1024,1024,1024);
        ELEMENT_SIZE    : --! @brief ELEMENT SIZE :
                          --! THRESHOLDS バッファの容量を指定する.
                          --! * ここで指定する単位は1ワード単位.
                          --! * 1ワードは QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS
                          --! * = 64bit
                          integer := 256;
        OUT_C_UNROLL    : --! @brief OUTPUT CHANNEL UNROLL SIZE :
                          integer := 1;
        ID              : --! @brief SDPRAM IDENTIFIER :
                          --! どのモジュールで使われているかを示す識別番号.
                          integer := 0 
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        OUT_C           : --! @brief OUTPUT C CHANNEL SIZE :
                          in  integer range 0 to O_SHAPE.C.MAX_SIZE := O_SHAPE.C.SIZE;
        OUT_W           : --! @brief OUTPUT IMAGE WIDTH :
                          in  integer range 0 to O_SHAPE.X.MAX_SIZE := O_SHAPE.X.SIZE;
        OUT_H           : --! @brief OUTPUT IMAGE HEIGHT :
                          in  integer range 0 to O_SHAPE.Y.MAX_SIZE := O_SHAPE.Y.SIZE;
        REQ_WRITE       : --! @brief REQUEST BUFFER WRITE :
                          in  std_logic := '1';
        REQ_READ        : --! @brief REQUEST BUFFER READ :
                          in  std_logic := '1';
        REQ_VALID       : --! @brief REQUEST VALID :
                          in  std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          out std_logic;
        RES_VALID       : --! @brief RESPONSE VALID :
                          out std_logic;
        RES_READY       : --! @brief RESPONSE READY :
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT THRESHOLDS DATA :
                          --! THRESHOLDS DATA 入力.
                          in  std_logic_vector(QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS-1 downto 0);
        I_VALID         : --! @brief INPUT THRESHOLDS DATA VALID :
                          --! THRESHOLDS DATA 入力有効信号.
                          in  std_logic;
        I_READY         : --! @brief INPUT THRESHOLDS READY :
                          --! THRESHOLDS DATA 入力レディ信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT THRESHOLDS DATA :
                          --! THRESHOLDS DATA 出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT THRESHOLDS DATA VALID :
                          --! THRESHOLDS DATA 出力有効信号.
                          out std_logic;
        O_READY         : --! @brief OUTPUT THRESHOLDS DATA READY :
                          --! THRESHOLDS DATA 出力レディ信号.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_K_DATA_BUFFER                                             --
-----------------------------------------------------------------------------------
component QCONV_STRIP_K_DATA_BUFFER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        O_PARAM         : --! @brief OUTPUT STREAM PARAMETER :
                          --! 出力側の IMAGE STREAM のパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                              ELEM_BITS => 32,
                              C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1*3*3),
                              D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                              Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1)
                          );
        I_SHAPE         : --! @brief INPUT  SHAPE :
                          --! 入力側のイメージの形(SHAPE)を指定する.
                          IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_EXTERNAL(64,1024,1024,1024);
        O_SHAPE         : --! @brief OUTPUT SHAPE :
                          --! 出力側のイメージの形(SHAPE)を指定する.
                          IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_EXTERNAL(64,1024,1024,1024);
        ELEMENT_SIZE    : --! @brief ELEMENT SIZE :
                          --! カーネル係数バッファの容量を指定する.
                          --! * ここで指定する単位は9ワード単位.
                          --! * 1ワードは QCONV_PARAM.NBITS_K_DATA * QCONV_PARAM.NBITS_PER_WORD
                          --! * 9ワードは 9 * 32 = 288 bit
                          --! * カーネル係数バッファの容量は K_BUF_SIZE * 288bit になる.
                          integer := (1024/32)*256;
        IN_C_UNROLL     : --! @brief INPUT  CHANNEL UNROLL SIZE :
                          integer := 1;
        OUT_C_UNROLL    : --! @brief OUTPUT CHANNEL UNROLL SIZE :
                          integer := 1;
        QUEUE_SIZE      : --! @brief OUTPUT PIPELINE QUEUE SIZE :
                          --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 0;
        ID              : --! @brief SDPRAM IDENTIFIER :
                          --! どのモジュールで使われているかを示す識別番号.
                          integer := 0 
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        IN_C_BY_WORD    : --! @brief INPUT C CHANNEL SIZE :
                          in  integer range 0 to I_SHAPE.C.MAX_SIZE := I_SHAPE.C.SIZE;
        OUT_C           : --! @brief OUTPUT C CHANNEL SIZE :
                          in  integer range 0 to O_SHAPE.C.MAX_SIZE := O_SHAPE.C.SIZE;
        OUT_W           : --! @brief OUTPUT IMAGE WIDTH :
                          in  integer range 0 to O_SHAPE.X.MAX_SIZE := O_SHAPE.X.SIZE;
        OUT_H           : --! @brief OUTPUT IMAGE HEIGHT :
                          in  integer range 0 to O_SHAPE.Y.MAX_SIZE := O_SHAPE.Y.SIZE;
        K3x3            : --! @brief KERNEL SIZE :
                          --! * Kernel が 3x3 の場合は'1'.
                          --! * Kernel が 1x1 の場合は'0'.
                          in  std_logic;
        REQ_WRITE       : --! @brief REQUEST BUFFER WRITE :
                          in  std_logic := '1';
        REQ_READ        : --! @brief REQUEST BUFFER READ :
                          in  std_logic := '1';
        REQ_VALID       : --! @brief REQUEST VALID :
                          in  std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          out std_logic;
        RES_VALID       : --! @brief RESPONSE VALID :
                          out std_logic;
        RES_READY       : --! @brief RESPONSE READY :
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT K_DATA :
                          --! K_DATA 入力.
                          in  std_logic_vector(QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD-1 downto 0);
        I_VALID         : --! @brief INPUT K_DATA VALID :
                          --! K_DATA 入力有効信号.
                          in  std_logic;
        I_READY         : --! @brief INPUT IN_DATA READY :
                          --! K_DATA レディ信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT IMAGE STREAM DATA :
                          --! ストリームデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT IMAGE STREAM DATA VALID :
                          --! 出力ストリームデータ有効信号.
                          out std_logic;
        O_READY         : --! @brief OUTPUT IMAGE STREAM DATA READY :
                          --! 出力ストリームデータレディ信号.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_MULTIPLIER                                                      --
-----------------------------------------------------------------------------------
component QCONV_MULTIPLIER
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        I_PARAM         : --! @brief INPUT  CONVOLUTION PIPELINE IMAGE DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        K_PARAM         : --! @brief INPUT  CONVOLUTION PIPELINE WEIGHT DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        O_PARAM         : --! @brief OUTPUT CONVOLUTION PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        CHECK_K_VALID   : --! @brief CHECK K VALID :
                          --! K 入力の VALID フラグをチェックするか否かを指定する.
                          --! * CHECK_K_VALID=1の場合はチェックする.その分、少し回路
                          --!   が大きくなるかも.
                          --! * CHECK_K_VALID=0の場合はチェックしない.その分、少し回
                          --!   路が小さくなるかも.
                          integer := 1;
        QUEUE_SIZE      : --! @brief PIPELINE QUEUE SIZE :
                          --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 2
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
        K_DATA          : --! @brief INPUT CONVOLUTION PIPELINE WEIGHT DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(K_PARAM.DATA.SIZE-1 downto 0);
        K_VALID         : --! @brief INPUT CONVOLUTION PIPELINE WEIGHT DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * K_DATAが有効であることを示す.
                          --! * K_VALID='1'and K_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        K_READY         : --! @brief INPUT CONVOLUTION PIPELINE WEIGHT DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * K_VALID='1'and K_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA :
                          --! パイプラインデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA VALID :
                          --! 出力パイプラインデータ有効信号.
                          --! * O_DATA が有効であることを示す.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          out std_logic;
        O_READY         : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA READY :
                          --! 出力パイプラインデータレディ信号.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_APPLY_THRESHOLDS                                                --
-----------------------------------------------------------------------------------
component QCONV_APPLY_THRESHOLDS
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        I_PARAM         : --! @brief INPUT  CONVOLUTION PIPELINE IMAGE DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     I_PARAM.SHAPE = O_PARAM.SHAPE
                          --!     I_PARAM.SHAPE = K_PARAM.SHAPE
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        T_PARAM         : --! @brief INPUT  CONVOLUTION PIPELINE THRESHOLD DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     T_PARAM.SHAPE = I_PARAM.SHAPE
                          --!     T_PARAM.SHAPE = O_PARAM.SHAPE
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        O_PARAM         : --! @brief OUTPUT CONVOLUTION PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     O_PARAM.SHAPE = I_PARAM.SHAPE
                          --!     O_PARAM.SHAPE = T_PARAM.SHAPE
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        QUEUE_SIZE      : --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 2
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
        T_DATA          : --! @brief INPUT CONVOLUTION PIPELINE THRESHOLD DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(T_PARAM.DATA.SIZE-1 downto 0);
        T_VALID         : --! @brief INPUT CONVOLUTION PIPELINE THRESHOLD DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * T_DATAが有効であることを示す.
                          --! * T_VALID='1'and T_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        T_READY         : --! @brief INPUT CONVOLUTION PIPELINE THRESHOLD DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * T_VALID='1'and T_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA :
                          --! パイプラインデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA VALID :
                          --! 出力パイプラインデータ有効信号.
                          --! * O_DATA が有効であることを示す.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          out std_logic;
        O_READY         : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA READY :
                          --! 出力パイプラインデータレディ信号.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_K_DATA_AXI_READER                                         --
-----------------------------------------------------------------------------------
component QCONV_STRIP_K_DATA_AXI_READER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        AXI_ADDR_WIDTH  : --! @brief AXI ADDRESS WIDTH :
                          integer range 1 to   64 := 32;
        AXI_DATA_WIDTH  : --! @brief AXI DATA WIDTH :
                          integer range 8 to 1024 := 64;
        AXI_ID_WIDTH    : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_USER_WIDTH  : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_XFER_SIZE   : --! @brief AXI MAX XFER_SIZE :
                          integer := 128*(64/8);
        AXI_ID          : --! @brief AXI ID :
                          integer := 0;
        AXI_PROT        : --! @brief AXI PROT :
                          integer := 1;
        AXI_QOS         : --! @brief AXI QOS :
                          integer := 0;
        AXI_REGION      : --! @brief AXI REGION :
                          integer := 0;
        AXI_CACHE       : --! @brief AXI REGION :
                          integer := 15;
        AXI_AUSER       : --! @brief AXI AUSER :
                          integer := 1;
        AXI_REQ_QUEUE   : --! @brief AXI REQUEST QUEUE SIZE :
                          integer := 4;
        REQ_ADDR_WIDTH  : --! @brief REQUEST ADDRESS WIDTH :
                          integer := 32
    );
    port(
    -------------------------------------------------------------------------------
    -- Clock / Reset Signals.
    -------------------------------------------------------------------------------
        CLK             : in  std_logic;
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        AXI_ARID        : out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_ARADDR      : out std_logic_vector(AXI_ADDR_WIDTH  -1 downto 0);
        AXI_ARLEN       : out std_logic_vector(7 downto 0);
        AXI_ARSIZE      : out std_logic_vector(2 downto 0);
        AXI_ARBURST     : out std_logic_vector(1 downto 0);
        AXI_ARLOCK      : out std_logic_vector(0 downto 0);
        AXI_ARCACHE     : out std_logic_vector(3 downto 0);
        AXI_ARPROT      : out std_logic_vector(2 downto 0);
        AXI_ARQOS       : out std_logic_vector(3 downto 0);
        AXI_ARREGION    : out std_logic_vector(3 downto 0);
        AXI_ARUSER      : out std_logic_vector(AXI_USER_WIDTH  -1 downto 0);
        AXI_ARVALID     : out std_logic;
        AXI_ARREADY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        AXI_RID         : in  std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_RDATA       : in  std_logic_vector(AXI_DATA_WIDTH  -1 downto 0);
        AXI_RRESP       : in  std_logic_vector(1 downto 0);
        AXI_RLAST       : in  std_logic;
        AXI_RVALID      : in  std_logic;
        AXI_RREADY      : out std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Stream Master Interface.
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD -1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Request / Response Interface.
    -------------------------------------------------------------------------------
        REQ_VALID       : in  std_logic;
        REQ_ADDR        : in  std_logic_vector(REQ_ADDR_WIDTH -1 downto 0);
        REQ_IN_C        : in  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        REQ_OUT_C       : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        REQ_OUT_C_POS   : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        REQ_OUT_C_SIZE  : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        REQ_K3x3        : in  std_logic;
        REQ_READY       : out std_logic;
        RES_VALID       : out std_logic;
        RES_NONE        : out std_logic;
        RES_ERROR       : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_IN_DATA_AXI_READER                                        --
-----------------------------------------------------------------------------------
component QCONV_STRIP_IN_DATA_AXI_READER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        AXI_ADDR_WIDTH  : --! @brief AXI ADDRESS WIDTH :
                          integer range 1 to   64 := 32;
        AXI_DATA_WIDTH  : --! @brief AXI DATA WIDTH :
                          integer range 8 to 1024 := 64;
        AXI_ID_WIDTH    : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_USER_WIDTH  : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_XFER_SIZE   : --! @brief AXI MAX XFER_SIZE :
                          integer := 12;
        AXI_ID          : --! @brief AXI ID :
                          integer := 0;
        AXI_PROT        : --! @brief AXI PROT :
                          integer := 1;
        AXI_QOS         : --! @brief AXI QOS :
                          integer := 0;
        AXI_REGION      : --! @brief AXI REGION :
                          integer := 0;
        AXI_CACHE       : --! @brief AXI REGION :
                          integer := 15;
        AXI_AUSER       : --! @brief AXI AUSER :
                          integer := 1;
        AXI_REQ_QUEUE   : --! @brief AXI REQUEST QUEUE SIZE :
                          integer := 4;
        REQ_ADDR_WIDTH  : --! @brief REQUEST ADDRESS WIDTH :
                          integer := 32
    );
    port(
    -------------------------------------------------------------------------------
    -- Clock / Reset Signals.
    -------------------------------------------------------------------------------
        CLK             : in  std_logic;
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        AXI_ARID        : out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_ARADDR      : out std_logic_vector(AXI_ADDR_WIDTH  -1 downto 0);
        AXI_ARLEN       : out std_logic_vector(7 downto 0);
        AXI_ARSIZE      : out std_logic_vector(2 downto 0);
        AXI_ARBURST     : out std_logic_vector(1 downto 0);
        AXI_ARLOCK      : out std_logic_vector(0 downto 0);
        AXI_ARCACHE     : out std_logic_vector(3 downto 0);
        AXI_ARPROT      : out std_logic_vector(2 downto 0);
        AXI_ARQOS       : out std_logic_vector(3 downto 0);
        AXI_ARREGION    : out std_logic_vector(3 downto 0);
        AXI_ARUSER      : out std_logic_vector(AXI_USER_WIDTH  -1 downto 0);
        AXI_ARVALID     : out std_logic;
        AXI_ARREADY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        AXI_RID         : in  std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_RDATA       : in  std_logic_vector(AXI_DATA_WIDTH  -1 downto 0);
        AXI_RRESP       : in  std_logic_vector(1 downto 0);
        AXI_RLAST       : in  std_logic;
        AXI_RVALID      : in  std_logic;
        AXI_RREADY      : out std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Stream Master Interface.
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(QCONV_PARAM.NBITS_IN_DATA*QCONV_PARAM.NBITS_PER_WORD-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Request / Response Interface.
    -------------------------------------------------------------------------------
        REQ_VALID       : in  std_logic;
        REQ_ADDR        : in  std_logic_vector(REQ_ADDR_WIDTH -1 downto 0);
        REQ_IN_C        : in  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        REQ_IN_W        : in  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        REQ_IN_H        : in  std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        REQ_X_POS       : in  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        REQ_X_SIZE      : in  std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        REQ_READY       : out std_logic;
        RES_VALID       : out std_logic;
        RES_NONE        : out std_logic;
        RES_ERROR       : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_TH_DATA_AXI_READER                                        --
-----------------------------------------------------------------------------------
component QCONV_STRIP_TH_DATA_AXI_READER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        AXI_ADDR_WIDTH  : --! @brief AXI ADDRESS WIDTH :
                          integer range 1 to   64 := 32;
        AXI_DATA_WIDTH  : --! @brief AXI DATA WIDTH :
                          integer range 8 to 1024 := 64;
        AXI_ID_WIDTH    : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_USER_WIDTH  : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_XFER_SIZE   : --! @brief AXI MAX XFER_SIZE :
                          integer := 128*(64/8);
        AXI_ID          : --! @brief AXI ID :
                          integer := 0;
        AXI_PROT        : --! @brief AXI PROT :
                          integer := 1;
        AXI_QOS         : --! @brief AXI QOS :
                          integer := 0;
        AXI_REGION      : --! @brief AXI REGION :
                          integer := 0;
        AXI_CACHE       : --! @brief AXI REGION :
                          integer := 15;
        AXI_AUSER       : --! @brief AXI AUSER :
                          integer := 1;
        AXI_REQ_QUEUE   : --! @brief AXI REQUEST QUEUE SIZE :
                          integer := 4;
        REQ_ADDR_WIDTH  : --! @brief REQUEST ADDRESS WIDTH :
                          integer := 32
    );
    port(
    -------------------------------------------------------------------------------
    -- Clock / Reset Signals.
    -------------------------------------------------------------------------------
        CLK             : in  std_logic;
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Read Address Channel Signals.
    -------------------------------------------------------------------------------
        AXI_ARID        : out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_ARADDR      : out std_logic_vector(AXI_ADDR_WIDTH  -1 downto 0);
        AXI_ARLEN       : out std_logic_vector(7 downto 0);
        AXI_ARSIZE      : out std_logic_vector(2 downto 0);
        AXI_ARBURST     : out std_logic_vector(1 downto 0);
        AXI_ARLOCK      : out std_logic_vector(0 downto 0);
        AXI_ARCACHE     : out std_logic_vector(3 downto 0);
        AXI_ARPROT      : out std_logic_vector(2 downto 0);
        AXI_ARQOS       : out std_logic_vector(3 downto 0);
        AXI_ARREGION    : out std_logic_vector(3 downto 0);
        AXI_ARUSER      : out std_logic_vector(AXI_USER_WIDTH  -1 downto 0);
        AXI_ARVALID     : out std_logic;
        AXI_ARREADY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Read Data Channel Signals.
    -------------------------------------------------------------------------------
        AXI_RID         : in  std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_RDATA       : in  std_logic_vector(AXI_DATA_WIDTH  -1 downto 0);
        AXI_RRESP       : in  std_logic_vector(1 downto 0);
        AXI_RLAST       : in  std_logic;
        AXI_RVALID      : in  std_logic;
        AXI_RREADY      : out std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Stream Master Interface.
    -------------------------------------------------------------------------------
        O_DATA          : out std_logic_vector(QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS-1 downto 0);
        O_LAST          : out std_logic;
        O_VALID         : out std_logic;
        O_READY         : in  std_logic;
    -------------------------------------------------------------------------------
    -- Request / Response Interface.
    -------------------------------------------------------------------------------
        REQ_VALID       : in  std_logic;
        REQ_ADDR        : in  std_logic_vector(REQ_ADDR_WIDTH -1 downto 0);
        REQ_OUT_C       : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        REQ_OUT_C_POS   : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        REQ_OUT_C_SIZE  : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        REQ_READY       : out std_logic;
        RES_VALID       : out std_logic;
        RES_NONE        : out std_logic;
        RES_ERROR       : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief QCONV_STRIP_OUT_DATA_AXI_WRITER                                       --
-----------------------------------------------------------------------------------
component QCONV_STRIP_OUT_DATA_AXI_WRITER
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        AXI_ADDR_WIDTH  : --! @brief AXI ADDRESS WIDTH :
                          integer range 1 to   64 := 32;
        AXI_DATA_WIDTH  : --! @brief AXI DATA WIDTH :
                          integer range 8 to 1024 := 64;
        AXI_ID_WIDTH    : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_USER_WIDTH  : --! @brief AXI ID WIDTH :
                          integer := 8;
        AXI_XFER_SIZE   : --! @brief AXI MAX XFER_SIZE :
                          integer := 128*(64/8);
        AXI_ID          : --! @brief AXI ID :
                          integer := 0;
        AXI_PROT        : --! @brief AXI PROT :
                          integer := 1;
        AXI_QOS         : --! @brief AXI QOS :
                          integer := 0;
        AXI_REGION      : --! @brief AXI REGION :
                          integer := 0;
        AXI_CACHE       : --! @brief AXI REGION :
                          integer := 15;
        AXI_AUSER       : --! @brief AXI AWUSER :
                          integer := 1;
        AXI_REQ_QUEUE   : --! @brief AXI REQUEST QUEUE SIZE :
                          integer := 4;
        I_DATA_WIDTH    : --! @brief STREAM DATA WIDTH :
                          integer := 32;
        REQ_ADDR_WIDTH  : --! @brief REQUEST ADDRESS WIDTH :
                          integer := 32
    );
    port(
    -------------------------------------------------------------------------------
    -- Clock / Reset Signals.
    -------------------------------------------------------------------------------
        CLK             : in  std_logic;
        RST             : in  std_logic;
        CLR             : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Write Address Channel Signals.
    -------------------------------------------------------------------------------
        AXI_AWID        : out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_AWADDR      : out std_logic_vector(AXI_ADDR_WIDTH  -1 downto 0);
        AXI_AWLEN       : out std_logic_vector(7 downto 0);
        AXI_AWSIZE      : out std_logic_vector(2 downto 0);
        AXI_AWBURST     : out std_logic_vector(1 downto 0);
        AXI_AWLOCK      : out std_logic_vector(0 downto 0);
        AXI_AWCACHE     : out std_logic_vector(3 downto 0);
        AXI_AWPROT      : out std_logic_vector(2 downto 0);
        AXI_AWQOS       : out std_logic_vector(3 downto 0);
        AXI_AWREGION    : out std_logic_vector(3 downto 0);
        AXI_AWUSER      : out std_logic_vector(AXI_USER_WIDTH  -1 downto 0);
        AXI_AWVALID     : out std_logic;
        AXI_AWREADY     : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Write Data Channel Signals.
    -------------------------------------------------------------------------------
        AXI_WID         : out std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_WDATA       : out std_logic_vector(AXI_DATA_WIDTH  -1 downto 0);
        AXI_WSTRB       : out std_logic_vector(AXI_DATA_WIDTH/8-1 downto 0);
        AXI_WLAST       : out std_logic;
        AXI_WVALID      : out std_logic;
        AXI_WREADY      : in  std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Write Response Channel Signals.
    -------------------------------------------------------------------------------
        AXI_BID         : in  std_logic_vector(AXI_ID_WIDTH    -1 downto 0);
        AXI_BRESP       : in  std_logic_vector(1 downto 0);
        AXI_BVALID      : in  std_logic;
        AXI_BREADY      : out std_logic;
    -------------------------------------------------------------------------------
    -- AXI4 Stream Slave Interface.
    -------------------------------------------------------------------------------
        I_DATA          : in  std_logic_vector(I_DATA_WIDTH    -1 downto 0);
        I_STRB          : in  std_logic_vector(I_DATA_WIDTH/8  -1 downto 0) := (others => '1');
        I_LAST          : in  std_logic;
        I_VALID         : in  std_logic;
        I_READY         : out std_logic;
    -------------------------------------------------------------------------------
    -- Request / Response Interface.
    -------------------------------------------------------------------------------
        REQ_VALID       : in  std_logic;
        REQ_ADDR        : in  std_logic_vector(REQ_ADDR_WIDTH -1 downto 0);
        REQ_OUT_C       : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        REQ_OUT_W       : in  std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
        REQ_OUT_H       : in  std_logic_vector(QCONV_PARAM.OUT_H_BITS-1 downto 0);
        REQ_C_POS       : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        REQ_C_SIZE      : in  std_logic_vector(QCONV_PARAM.OUT_C_BITS-1 downto 0);
        REQ_X_POS       : in  std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
        REQ_X_SIZE      : in  std_logic_vector(QCONV_PARAM.OUT_W_BITS-1 downto 0);
        REQ_USE_TH      : in  std_logic_vector(1 downto 0);
        REQ_READY       : out std_logic;
        RES_VALID       : out std_logic;
        RES_NONE        : out std_logic;
        RES_ERROR       : out std_logic;
        RES_READY       : in  std_logic
    );
end component;
end QCONV_COMPONENTS;
