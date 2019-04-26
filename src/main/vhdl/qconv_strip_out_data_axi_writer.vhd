-----------------------------------------------------------------------------------
--!     @file    qconv_strip_out_data_axi_writer.vhd
--!     @brief   Quantized Convolution (strip) Out Data AXI Writer Module
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
library QCONV;
use     QCONV.QCONV_PARAMS.all;
-----------------------------------------------------------------------------------
--! @brief 
-----------------------------------------------------------------------------------
entity  QCONV_STRIP_OUT_DATA_AXI_WRITER is
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
        REQ_USE_TH      : in  std_logic;
        REQ_READY       : out std_logic;
        RES_VALID       : out std_logic;
        RES_NONE        : out std_logic;
        RES_ERROR       : out std_logic;
        RES_READY       : in  std_logic
    );
end QCONV_STRIP_OUT_DATA_AXI_WRITER;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.AXI4_TYPES.all;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_MASTER_WRITE_INTERFACE;
use     PIPEWORK.PUMP_COMPONENTS.PUMP_STREAM_OUTLET_CONTROLLER;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_SLICE_MASTER_CONTROLLER;
use     PIPEWORK.COMPONENTS.SDPRAM;
architecture RTL of QCONV_STRIP_OUT_DATA_AXI_WRITER is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  MAX(A,B: integer) return integer is
    begin
        if (A > B) then return A;
        else            return B;
        end if;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  MAX(A,B,C: integer) return integer is
    begin
        return MAX(A,MAX(B,C));
    end function;
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
    function  MIN(A,B,C: integer) return integer is
    begin
        return MIN(A,MIN(B,C));
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
    constant  IMAGE_SHAPE           :  IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE(
                                           ELEM_BITS => MAX(QCONV_PARAM.NBITS_OUT_DATA, QCONV_PARAM.NBITS_IN_DATA, I_DATA_WIDTH),
                                           C         => NEW_IMAGE_SHAPE_SIDE_EXTERNAL(QCONV_PARAM.MAX_OUT_C),
                                           X         => NEW_IMAGE_SHAPE_SIDE_EXTERNAL(QCONV_PARAM.MAX_OUT_W),
                                           Y         => NEW_IMAGE_SHAPE_SIDE_EXTERNAL(QCONV_PARAM.MAX_OUT_H)
                                       );
    signal    req_image_c_size      :  integer range 0 to IMAGE_SHAPE.C.MAX_SIZE;
    signal    req_image_x_size      :  integer range 0 to IMAGE_SHAPE.X.MAX_SIZE;
    signal    req_image_y_size      :  integer range 0 to IMAGE_SHAPE.Y.MAX_SIZE;
    signal    req_slice_c_pos       :  integer range 0 to IMAGE_SHAPE.C.MAX_SIZE;
    signal    req_slice_c_size      :  integer range 0 to IMAGE_SHAPE.C.MAX_SIZE;
    signal    req_slice_x_pos       :  integer range 0 to IMAGE_SHAPE.X.MAX_SIZE;
    signal    req_slice_x_size      :  integer range 0 to IMAGE_SHAPE.X.MAX_SIZE;
    signal    req_elem_bytes        :  integer range 0 to IMAGE_SHAPE.ELEM_BITS/8;
    signal    req_axi_addr          :  std_logic_vector(AXI_ADDR_WIDTH-1 downto 0);
    -------------------------------------------------------------------------------
    -- 一回のトランザクションで転送する最大転送バイト数
    -------------------------------------------------------------------------------
    constant  MAX_XFER_BYTES        :  integer := MIN(4096, 256*(AXI_DATA_WIDTH/8), 2**AXI_XFER_SIZE);
    constant  MAX_XFER_SIZE         :  integer := CALC_BITS(MAX_XFER_BYTES);
    ------------------------------------------------------------------------------
    -- バッファの容量をバイト数で示す.
    ------------------------------------------------------------------------------
    constant  BUF_BYTES             :  integer := MAX_XFER_BYTES*2;
    ------------------------------------------------------------------------------
    -- バッファの容量(バイト数)を２のべき乗値で示す.
    ------------------------------------------------------------------------------
    constant  BUF_DEPTH             :  integer := CALC_BITS(BUF_BYTES);
    ------------------------------------------------------------------------------
    -- バッファのデータ幅のビット数を示す.
    ------------------------------------------------------------------------------
    constant  BUF_WIDTH             :  integer := MAX(AXI_DATA_WIDTH, I_DATA_WIDTH);
    ------------------------------------------------------------------------------
    -- バッファのデータ幅のビット数を２のべき乗値で示す.
    ------------------------------------------------------------------------------
    constant  BUF_DATA_BIT_SIZE     :  integer := CALC_BITS(BUF_WIDTH);
    ------------------------------------------------------------------------------
    -- 入力側のフロー制御用定数.
    ------------------------------------------------------------------------------
    constant  O_FLOW_VALID          :  integer := 1;
    constant  O_USE_PULL_BUF_SIZE   :  integer := 0;
    constant  O_FIXED_FLOW_OPEN     :  integer := 0;
    constant  O_FIXED_POOL_OPEN     :  integer := 1;
    constant  O_REQ_ADDR_VALID      :  integer := 1;
    constant  O_REQ_SIZE_VALID      :  integer := 1;
    constant  O_BUF_READY_LEVEL     :  std_logic_vector(BUF_DEPTH downto 0)
                                    := std_logic_vector(to_unsigned(AXI_DATA_WIDTH/8, BUF_DEPTH+1));
    constant  O_MAX_REQ_SIZE        :  integer := IMAGE_SHAPE.X.MAX_SIZE * IMAGE_SHAPE.C.MAX_SIZE * IMAGE_SHAPE.ELEM_BITS / 8;
    constant  REQ_SIZE_WIDTH        :  integer := CALC_BITS(O_MAX_REQ_SIZE+1);
    -------------------------------------------------------------------------------
    -- AXI I/F 定数
    -------------------------------------------------------------------------------
    constant  AXI_REQ_PROT          :  AXI4_APROT_TYPE
                                    := std_logic_vector(to_unsigned(AXI_PROT  , AXI4_APROT_WIDTH  ));
    constant  AXI_REQ_QOS           :  AXI4_AQOS_TYPE
                                    := std_logic_vector(to_unsigned(AXI_QOS   , AXI4_AQOS_WIDTH   ));
    constant  AXI_REQ_REGION        :  AXI4_AREGION_TYPE
                                    := std_logic_vector(to_unsigned(AXI_REGION, AXI4_AREGION_WIDTH));
    constant  AXI_REQ_CACHE         :  AXI4_ACACHE_TYPE
                                    := std_logic_vector(to_unsigned(AXI_CACHE , AXI4_ACACHE_WIDTH ));
    constant  AXI_REQ_ID            :  std_logic_vector(AXI_ID_WIDTH -1 downto 0)
                                    := std_logic_vector(to_unsigned(AXI_ID    , AXI_ID_WIDTH      ));
    constant  AXI_REQ_LOCK          :  AXI4_ALOCK_TYPE  := (others => '0');
    constant  AXI_REQ_SPECULATIVE   :  std_logic := '1';
    constant  AXI_REQ_SAFETY        :  std_logic := '0';
    constant  AXI_ALIGNMENT_BITS    :  integer := 32;
    constant  AXI_REQ_REGS          :  integer := 1;
    constant  AXI_ACK_REGS          :  integer := 1;
    constant  AXI_RESP_REGS         :  integer := 1;
    constant  OPEN_INFO_BITS        :  integer := 4;
    constant  CLOSE_INFO_BITS       :  integer := 4;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    o_tran_start          :  std_logic;
    signal    o_tran_first          :  std_logic;
    signal    o_tran_last           :  std_logic;
    signal    o_tran_addr           :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    o_tran_addr_load      :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    o_tran_size           :  std_logic_vector(REQ_SIZE_WIDTH -1 downto 0);
    signal    o_tran_size_load      :  std_logic_vector(REQ_SIZE_WIDTH -1 downto 0);
    signal    o_tran_busy           :  std_logic;
    signal    o_tran_done           :  std_logic;
    signal    o_tran_error          :  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    o_req_valid           :  std_logic;
    signal    o_req_addr            :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    o_req_size            :  std_logic_vector(REQ_SIZE_WIDTH -1 downto 0);
    signal    o_req_buf_ptr         :  std_logic_vector(BUF_DEPTH      -1 downto 0);
    signal    o_req_first           :  std_logic;
    signal    o_req_last            :  std_logic;
    signal    o_req_ready           :  std_logic;
    signal    o_ack_valid           :  std_logic;
    signal    o_ack_size            :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    o_ack_error           :  std_logic;
    signal    o_ack_next            :  std_logic;
    signal    o_ack_last            :  std_logic;
    signal    o_ack_stop            :  std_logic;
    signal    o_ack_none            :  std_logic;
    signal    o_xfer_busy           :  std_logic;
    signal    o_xfer_done           :  std_logic;
    signal    o_xfer_error          :  std_logic;
    signal    o_flow_ready          :  std_logic;
    signal    o_flow_pause          :  std_logic;
    signal    o_flow_stop           :  std_logic;
    signal    o_flow_last           :  std_logic;
    signal    o_flow_size           :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    o_flow_ready_level    :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    o_pull_fin_valid      :  std_logic;
    signal    o_pull_fin_last       :  std_logic;
    signal    o_pull_fin_error      :  std_logic;
    signal    o_pull_fin_size       :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    o_pull_rsv_valid      :  std_logic;
    signal    o_pull_rsv_last       :  std_logic;
    signal    o_pull_rsv_error      :  std_logic;
    signal    o_pull_rsv_size       :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    o_pull_buf_reset      :  std_logic;
    signal    o_pull_buf_valid      :  std_logic;
    signal    o_pull_buf_last       :  std_logic;
    signal    o_pull_buf_error      :  std_logic;
    signal    o_pull_buf_size       :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    o_pull_buf_ready      :  std_logic;
    signal    o_open                :  std_logic;
    constant  o_open_info           :  std_logic_vector(OPEN_INFO_BITS -1 downto 0) := (others => '0');
    constant  o_close_info          :  std_logic_vector(CLOSE_INFO_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    buf_ren               :  std_logic;
    signal    buf_rptr              :  std_logic_vector(BUF_DEPTH      -1 downto 0);
    signal    buf_rdata             :  std_logic_vector(BUF_WIDTH      -1 downto 0);
    signal    buf_wen               :  std_logic;
    signal    buf_wptr              :  std_logic_vector(BUF_DEPTH      -1 downto 0);
    signal    buf_wdata             :  std_logic_vector(BUF_WIDTH      -1 downto 0);
    signal    buf_we                :  std_logic_vector(BUF_WIDTH/8    -1 downto 0);
    signal    buf_ben               :  std_logic_vector(BUF_WIDTH/8    -1 downto 0);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    i_open                :  std_logic;
    signal    i_done                :  std_logic;
    signal    i_open_info           :  std_logic_vector(OPEN_INFO_BITS -1 downto 0);
    signal    i_open_valid          :  std_logic;
    signal    i_close_info          :  std_logic_vector(CLOSE_INFO_BITS-1 downto 0);
    signal    i_close_valid         :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (REQ_USE_TH, REQ_OUT_C, REQ_C_POS, REQ_C_SIZE)
        variable elem_bytes   :  integer;
        variable image_c_size :  integer;
        variable slice_c_pos  :  integer;
        variable slice_c_size :  integer;
        procedure CALC_C_SIZE(constant ELEM_BITS: integer) is
        begin
            if    (ELEM_BITS mod I_DATA_WIDTH = 0) then
                elem_bytes   := ELEM_BITS/8;
                image_c_size := to_integer(to_01(unsigned(REQ_OUT_C )));
                slice_c_pos  := to_integer(to_01(unsigned(REQ_C_POS )));
                slice_c_size := to_integer(to_01(unsigned(REQ_C_SIZE)));
            elsif (ELEM_BITS < I_DATA_WIDTH and I_DATA_WIDTH mod ELEM_BITS = 0) then
                elem_bytes   := I_DATA_WIDTH/8;
                image_c_size := to_integer(to_01(unsigned(REQ_OUT_C ))) / (I_DATA_WIDTH / ELEM_BITS);
                slice_c_pos  := to_integer(to_01(unsigned(REQ_C_POS ))) / (I_DATA_WIDTH / ELEM_BITS);
                slice_c_size := to_integer(to_01(unsigned(REQ_C_SIZE))) / (I_DATA_WIDTH / ELEM_BITS);
            else
                assert (FALSE) report string'("Invalid ELEM_BITS") severity FAILURE;
            end if;
        end procedure;
    begin
        if (REQ_USE_TH = '1') then
            CALC_C_SIZE(QCONV_PARAM.NBITS_IN_DATA );
        else
            CALC_C_SIZE(QCONV_PARAM.NBITS_OUT_DATA);
        end if;
        req_elem_bytes   <= elem_bytes;
        req_image_c_size <= image_c_size;
        req_slice_c_pos  <= slice_c_pos;
        req_slice_c_size <= slice_c_size;
    end process;
    req_image_x_size <= to_integer(to_01(unsigned(REQ_OUT_W )));
    req_image_y_size <= to_integer(to_01(unsigned(REQ_OUT_H )));
    req_slice_x_pos  <= to_integer(to_01(unsigned(REQ_X_POS )));
    req_slice_x_size <= to_integer(to_01(unsigned(REQ_X_SIZE)));
    req_axi_addr     <= std_logic_vector(resize(unsigned(REQ_ADDR), AXI_ADDR_WIDTH));
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    MST_CTRL: IMAGE_SLICE_MASTER_CONTROLLER              -- 
        generic map (                                    -- 
            SOURCE_SHAPE        => IMAGE_SHAPE         , --
            SLICE_SHAPE         => IMAGE_SHAPE         , --
            MAX_SLICE_C_POS     => IMAGE_SHAPE.C.MAX_SIZE , --
            MAX_SLICE_X_POS     => IMAGE_SHAPE.X.MAX_SIZE , --
            MAX_SLICE_Y_POS     => 0                   , --
            ADDR_BITS           => AXI_ADDR_WIDTH      , --
            SIZE_BITS           => REQ_SIZE_WIDTH        --
        )                                                -- 
        port map (                                       -- 
        -------------------------------------------------------------------------------
        -- クロック&リセット信号
        -------------------------------------------------------------------------------
            CLK                 => CLK                 , -- In  :
            RST                 => RST                 , -- In  :
            CLR                 => CLR                 , -- In  :
        -------------------------------------------------------------------------------
        -- 
        -------------------------------------------------------------------------------
            SOURCE_C_SIZE       => req_image_c_size    , -- In  :
            SOURCE_X_SIZE       => req_image_x_size    , -- In  :
            SOURCE_Y_SIZE       => req_image_y_size    , -- In  :
            SLICE_C_POS         => req_slice_c_pos     , -- In  :
            SLICE_C_SIZE        => req_slice_c_size    , -- In  :
            SLICE_X_POS         => req_slice_x_pos     , -- In  :
            SLICE_X_SIZE        => req_slice_x_size    , -- In  :
            SLICE_Y_SIZE        => req_image_y_size    , -- In  :
            ELEM_BYTES          => req_elem_bytes      , -- In  :
            REQ_ADDR            => req_axi_addr        , -- In  :
            REQ_VALID           => REQ_VALID           , -- In  :
            REQ_READY           => REQ_READY           , -- Out :
            RES_NONE            => RES_NONE            , -- Out :
            RES_ERROR           => RES_ERROR           , -- Out :
            RES_VALID           => RES_VALID           , -- Out :
            RES_READY           => RES_READY           , -- In  :
        -------------------------------------------------------------------------------
        -- 
        -------------------------------------------------------------------------------
            MST_ADDR            => o_tran_addr         , -- Out :
            MST_SIZE            => o_tran_size         , -- Out :
            MST_FIRST           => o_tran_first        , -- Out :
            MST_LAST            => o_tran_last         , -- Out :
            MST_START           => o_tran_start        , -- Out :
            MST_BUSY            => o_tran_busy         , -- In  :
            MST_DONE            => o_tran_done         , -- In  :
            MST_ERROR           => o_tran_error          -- In  :
        );                                               -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    o_tran_addr_load <= (others => '1') when (o_tran_start = '1') else (others => '0');
    o_tran_size_load <= (others => '1') when (o_tran_start = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                o_flow_ready_level <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                o_flow_ready_level <= (others => '0');
            elsif (o_tran_start = '1') then
                if (unsigned(o_tran_size) > 2**AXI_XFER_SIZE) then
                    o_flow_ready_level <= std_logic_vector(to_unsigned(2**AXI_XFER_SIZE, o_flow_ready_level'length));
                else
                    o_flow_ready_level <= std_logic_vector(resize(unsigned(o_tran_size), o_flow_ready_level'length));
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PUMP_CTRL: PUMP_STREAM_OUTLET_CONTROLLER             -- 
        generic map (                                    -- 
            O_CLK_RATE          => 1                   , --
            O_REQ_ADDR_VALID    => O_REQ_ADDR_VALID    , --
            O_REQ_ADDR_BITS     => AXI_ADDR_WIDTH      , --
            O_REG_ADDR_BITS     => AXI_ADDR_WIDTH      , --
            O_REQ_SIZE_VALID    => O_REQ_SIZE_VALID    , --
            O_REQ_SIZE_BITS     => REQ_SIZE_WIDTH      , --
            O_REG_SIZE_BITS     => REQ_SIZE_WIDTH      , --
            O_REG_MODE_BITS     => 1                   , --
            O_REG_STAT_BITS     => 1                   , --
            O_USE_PULL_BUF_SIZE => O_USE_PULL_BUF_SIZE , --
            O_FIXED_FLOW_OPEN   => O_FIXED_FLOW_OPEN   , --
            O_FIXED_POOL_OPEN   => O_FIXED_POOL_OPEN   , --
            I_CLK_RATE          => 1                   , --
            I_DATA_BITS         => I_DATA_WIDTH        , --
            BUF_DEPTH           => BUF_DEPTH           , --
            BUF_DATA_BITS       => BUF_WIDTH           , --
            O2I_OPEN_INFO_BITS  => OPEN_INFO_BITS      , --
            O2I_CLOSE_INFO_BITS => CLOSE_INFO_BITS     , --
            I2O_OPEN_INFO_BITS  => OPEN_INFO_BITS      , --
            I2O_CLOSE_INFO_BITS => CLOSE_INFO_BITS     , --
            I2O_DELAY_CYCLE     => 1                     --
        )                                                -- 
        port map (                                       -- 
        ---------------------------------------------------------------------------
        --Reset Signals.
        ---------------------------------------------------------------------------
            RST                 => RST                 , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Clock and Clock Enable.
        ---------------------------------------------------------------------------
            O_CLK               => CLK                 , --  In  :
            O_CLR               => CLR                 , --  In  :
            O_CKE               => '1'                 , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Control Register Interface.
        ---------------------------------------------------------------------------
            O_ADDR_L            => o_tran_addr_load    , --  In  :
            O_ADDR_D            => o_tran_addr         , --  In  :
            O_SIZE_L            => o_tran_size_load    , --  In  :
            O_SIZE_D            => o_tran_size         , --  In  :
            O_START_L           => o_tran_start        , --  In  :
            O_START_D           => o_tran_start        , --  In  :
            O_FIRST_L           => o_tran_start        , --  In  :
            O_FIRST_D           => o_tran_first        , --  In  :
            O_LAST_L            => o_tran_start        , --  In  :
            O_LAST_D            => o_tran_last         , --  In  :
            O_DONE_EN_L         => o_tran_start        , --  In  :
            O_DONE_EN_D         => '0'                 , --  In  :
            O_DONE_ST_L         => o_tran_start        , --  In  :
            O_DONE_ST_D         => '0'                 , --  In  :
            O_ERR_ST_L          => o_tran_start        , --  In  :
            O_ERR_ST_D          => '0'                 , --  In  :
            O_CLOSE_ST_L        => o_tran_start        , --  In  :
            O_CLOSE_ST_D        => '0'                 , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Configuration Signals.
        ---------------------------------------------------------------------------
            O_BUF_READY_LEVEL   => O_BUF_READY_LEVEL   , --  In  :
            O_FLOW_READY_LEVEL  => o_flow_ready_level  , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Transaction Command Request Signals.
        ---------------------------------------------------------------------------
            O_REQ_VALID         => o_req_valid         , --  Out :
            O_REQ_ADDR          => o_req_addr          , --  Out :
            O_REQ_SIZE          => o_req_size          , --  Out :
            O_REQ_BUF_PTR       => o_req_buf_ptr       , --  Out :
            O_REQ_FIRST         => o_req_first         , --  Out :
            O_REQ_LAST          => o_req_last          , --  Out :
            O_REQ_READY         => o_req_ready         , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Transaction Command Acknowledge Signals.
        ---------------------------------------------------------------------------
            O_ACK_VALID         => o_ack_valid         , --  In  :
            O_ACK_SIZE          => o_ack_size          , --  In  :
            O_ACK_ERROR         => o_ack_error         , --  In  :
            O_ACK_NEXT          => o_ack_next          , --  In  :
            O_ACK_LAST          => o_ack_last          , --  In  :
            O_ACK_STOP          => o_ack_stop          , --  In  :
            O_ACK_NONE          => o_ack_none          , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Transfer Status Signals.
        ---------------------------------------------------------------------------
            O_XFER_BUSY         => o_xfer_busy         , --  In  :
            O_XFER_DONE         => o_xfer_done         , --  In  :
            O_XFER_ERROR        => o_xfer_error        , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Flow Control Signals.
        ---------------------------------------------------------------------------
            O_FLOW_READY        => o_flow_ready        , --  Out :
            O_FLOW_PAUSE        => o_flow_pause        , --  Out :
            O_FLOW_STOP         => o_flow_stop         , --  Out :
            O_FLOW_LAST         => o_flow_last         , --  Out :
            O_FLOW_SIZE         => o_flow_size         , --  Out :
            O_PULL_FIN_VALID    => o_pull_fin_valid    , --  In  :
            O_PULL_FIN_LAST     => o_pull_fin_last     , --  In  :
            O_PULL_FIN_ERROR    => o_pull_fin_error    , --  In  :
            O_PULL_FIN_SIZE     => o_pull_fin_size     , --  In  :
            O_PULL_RSV_VALID    => o_pull_rsv_valid    , --  In  :
            O_PULL_RSV_LAST     => o_pull_rsv_last     , --  In  :
            O_PULL_RSV_ERROR    => o_pull_rsv_error    , --  In  :
            O_PULL_RSV_SIZE     => o_pull_rsv_size     , --  In  :
            O_PULL_BUF_RESET    => o_pull_buf_reset    , --  In  :
            O_PULL_BUF_VALID    => o_pull_buf_valid    , --  In  :
            O_PULL_BUF_LAST     => o_pull_buf_last     , --  In  :
            O_PULL_BUF_ERROR    => o_pull_buf_error    , --  In  :
            O_PULL_BUF_SIZE     => o_pull_buf_size     , --  In  :
            O_PULL_BUF_READY    => o_pull_buf_ready    , --  Out :
        ---------------------------------------------------------------------------
        -- Outlet Status.
        ---------------------------------------------------------------------------
            O_OPEN              => o_open              , --  Out :
            O_TRAN_BUSY         => o_tran_busy         , --  Out :
            O_TRAN_DONE         => o_tran_done         , --  Out :
            O_TRAN_ERROR        => o_tran_error        , --  Out :
        ---------------------------------------------------------------------------
        -- Outlet Open/Close Infomation Interface
        ---------------------------------------------------------------------------
            O_O2I_OPEN_INFO     => o_open_info         , --  In  :
            O_O2I_CLOSE_INFO    => o_close_info        , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Clock and Clock Enable.
        ---------------------------------------------------------------------------
            I_CLK               => CLK                 , --  In  :
            I_CLR               => CLR                 , --  In  :
            I_CKE               => '1'                 , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Stream Interface.
        ---------------------------------------------------------------------------
            I_DATA              => I_DATA              , --  In  :
            I_STRB              => I_STRB              , --  In  :
            I_LAST              => I_LAST              , --  In  :
            I_VALID             => I_VALID             , --  In  :
            I_READY             => I_READY             , --  Out :
        ---------------------------------------------------------------------------
        -- Intake Status.
        ---------------------------------------------------------------------------
            I_OPEN              => i_open              , --  Out :
            I_DONE              => i_done              , --  Out :
        ---------------------------------------------------------------------------
        -- Intake Open/Close Infomation Interface
        ---------------------------------------------------------------------------
            I_I2O_OPEN_INFO     => i_open_info         , --  In  :
            I_I2O_OPEN_VALID    => i_open_valid        , --  In  :
            I_I2O_CLOSE_INFO    => i_close_info        , --  In  :
            I_I2O_CLOSE_VALID   => i_close_valid       , --  In  :
            I_O2I_OPEN_INFO     => i_open_info         , --  Out :
            I_O2I_OPEN_VALID    => i_open_valid        , --  Out :
            I_O2I_CLOSE_INFO    => i_close_info        , --  Out :
            I_O2I_CLOSE_VALID   => i_close_valid       , --  Out :
        ---------------------------------------------------------------------------
        -- Intake Buffer Read Interface.
        ---------------------------------------------------------------------------
            BUF_WEN             => buf_wen             , --  Out :
            BUF_BEN             => buf_ben             , --  Out :
            BUF_PTR             => buf_wptr            , --  Out :
            BUF_DATA            => buf_wdata             --  Out :
        );                                               --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    AXI_IF: AXI4_MASTER_WRITE_INTERFACE                  -- 
        generic map (                                    -- 
            AXI4_ADDR_WIDTH     => AXI_ADDR_WIDTH      , -- 
            AXI4_DATA_WIDTH     => AXI_DATA_WIDTH      , --   
            AXI4_ID_WIDTH       => AXI_ID_WIDTH        , --   
            VAL_BITS            => 1                   , --   
            REQ_SIZE_BITS       => REQ_SIZE_WIDTH      , --   
            REQ_SIZE_VALID      => 1                   , --   
            FLOW_VALID          => O_FLOW_VALID        , --   
            BUF_DATA_WIDTH      => BUF_WIDTH           , --   
            BUF_PTR_BITS        => BUF_DEPTH           , --   
            ALIGNMENT_BITS      => AXI_ALIGNMENT_BITS  , --   
            XFER_SIZE_BITS      => BUF_DEPTH+1         , --   
            XFER_MIN_SIZE       => MAX_XFER_SIZE       , --   
            XFER_MAX_SIZE       => MAX_XFER_SIZE       , --   
            QUEUE_SIZE          => AXI_REQ_QUEUE       , --   
            REQ_REGS            => AXI_REQ_REGS        , --   
            ACK_REGS            => AXI_ACK_REGS        , --   
            RESP_REGS           => AXI_RESP_REGS         --   
        )                                                -- 
        port map(                                        --
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals.
        ---------------------------------------------------------------------------
            CLK                 => CLK                 , -- In  :
            RST                 => RST                 , -- In  :
            CLR                 => CLR                 , -- In  :
        --------------------------------------------------------------------------
        -- AXI4 Write Address Channel Signals.
        --------------------------------------------------------------------------
            AWID                => AXI_AWID            , -- Out :
            AWADDR              => AXI_AWADDR          , -- Out :
            AWLEN               => AXI_AWLEN           , -- Out :
            AWSIZE              => AXI_AWSIZE          , -- Out :
            AWBURST             => AXI_AWBURST         , -- Out :
            AWLOCK              => AXI_AWLOCK          , -- Out :
            AWCACHE             => AXI_AWCACHE         , -- Out :
            AWPROT              => AXI_AWPROT          , -- Out :
            AWQOS               => AXI_AWQOS           , -- Out :
            AWREGION            => AXI_AWREGION        , -- Out :
            AWVALID             => AXI_AWVALID         , -- Out :
            AWREADY             => AXI_AWREADY         , -- In  :
        --------------------------------------------------------------------------
        -- AXI4 Write Data Channel Signals.
        --------------------------------------------------------------------------
            WID                 => AXI_WID             , -- Out :
            WDATA               => AXI_WDATA           , -- Out :
            WSTRB               => AXI_WSTRB           , -- Out :
            WLAST               => AXI_WLAST           , -- Out :
            WVALID              => AXI_WVALID          , -- Out :
            WREADY              => AXI_WREADY          , -- In  :
        --------------------------------------------------------------------------
        -- AXI4 Write Response Channel Signals.
        --------------------------------------------------------------------------
            BID                 => AXI_BID             , -- In  :
            BRESP               => AXI_BRESP           , -- In  :
            BVALID              => AXI_BVALID          , -- In  :
            BREADY              => AXI_BREADY          , -- Out :
        ---------------------------------------------------------------------------
        -- Command Request Signals.
        ---------------------------------------------------------------------------
            XFER_SIZE_SEL       => "1"                 , -- In  :
            REQ_ADDR            => o_req_addr          , -- In  :
            REQ_SIZE            => o_req_size          , -- In  :
            REQ_ID              => AXI_REQ_ID          , -- In  :
            REQ_BURST           => AXI4_ABURST_INCR    , -- In  :
            REQ_LOCK            => AXI_REQ_LOCK        , -- In  :
            REQ_CACHE           => AXI_REQ_CACHE       , -- In  :
            REQ_PROT            => AXI_REQ_PROT        , -- In  :
            REQ_QOS             => AXI_REQ_QOS         , -- In  :
            REQ_REGION          => AXI_REQ_REGION      , -- In  :
            REQ_BUF_PTR         => o_req_buf_ptr       , -- In  :
            REQ_FIRST           => o_req_first         , -- In  :
            REQ_LAST            => o_req_last          , -- In  :
            REQ_SPECULATIVE     => AXI_REQ_SPECULATIVE , -- In  :
            REQ_SAFETY          => AXI_REQ_SAFETY      , -- In  :
            REQ_VAL(0)          => o_req_valid         , -- In  :
            REQ_RDY             => o_req_ready         , -- Out :
        ---------------------------------------------------------------------------
        -- Command Acknowledge Signals.
        ---------------------------------------------------------------------------
            ACK_VAL(0)          => o_ack_valid         , -- Out :
            ACK_NEXT            => o_ack_next          , -- Out :
            ACK_LAST            => o_ack_last          , -- Out :
            ACK_ERROR           => o_ack_error         , -- Out :
            ACK_STOP            => o_ack_stop          , -- Out :
            ACK_NONE            => o_ack_none          , -- Out :
            ACK_SIZE            => o_ack_size          , -- Out :
        ---------------------------------------------------------------------------
        -- Transfer Status Signal.
        ---------------------------------------------------------------------------
            XFER_BUSY(0)        => o_xfer_busy         , -- Out :
            XFER_ERROR(0)       => o_xfer_error        , -- Out :
            XFER_DONE(0)        => o_xfer_done         , -- Out :
        ---------------------------------------------------------------------------
        -- Flow Control Signals.
        ---------------------------------------------------------------------------
            FLOW_STOP           => o_flow_stop         , -- In  :
            FLOW_PAUSE          => o_flow_pause        , -- In  :
            FLOW_LAST           => o_flow_last         , -- In  :
            FLOW_SIZE           => o_flow_size         , -- In  :
        ---------------------------------------------------------------------------
        -- Pull Reserve Size Signals.
        ---------------------------------------------------------------------------
            PULL_RSV_VAL(0)     => o_pull_rsv_valid    , -- Out :
            PULL_RSV_LAST       => o_pull_rsv_last     , -- Out :
            PULL_RSV_ERROR      => o_pull_rsv_error    , -- Out :
            PULL_RSV_SIZE       => o_pull_rsv_size     , -- Out :
        ---------------------------------------------------------------------------
        -- Pull Final Size Signals.
        ---------------------------------------------------------------------------
            PULL_FIN_VAL(0)     => o_pull_fin_valid    , -- Out :
            PULL_FIN_LAST       => o_pull_fin_last     , -- Out :
            PULL_FIN_ERROR      => o_pull_fin_error    , -- Out :
            PULL_FIN_SIZE       => o_pull_fin_size     , -- Out :
        ---------------------------------------------------------------------------
        -- Pull Buffer Size Signals.
        ---------------------------------------------------------------------------
            PULL_BUF_RESET(0)   => o_pull_buf_reset    , -- Out :
            PULL_BUF_VAL(0)     => o_pull_buf_valid    , -- Out :
            PULL_BUF_LAST       => o_pull_buf_last     , -- Out :
            PULL_BUF_ERROR      => o_pull_buf_error    , -- Out :
            PULL_BUF_SIZE       => o_pull_buf_size     , -- Out :
            PULL_BUF_RDY(0)     => o_pull_buf_ready    , -- In  :
        ---------------------------------------------------------------------------
        -- Read Buffer Interface Signals.
        ---------------------------------------------------------------------------
            BUF_REN(0)          => buf_ren             , -- Out :
            BUF_DATA            => buf_rdata           , -- Out :
            BUF_PTR             => buf_rptr              -- Out :
        );                                               -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    RAM: SDPRAM 
        generic map(
            DEPTH       => BUF_DEPTH+3         ,
            RWIDTH      => BUF_DATA_BIT_SIZE   , --
            WWIDTH      => BUF_DATA_BIT_SIZE   , --
            WEBIT       => BUF_DATA_BIT_SIZE-3 , --
            ID          => 0                     -- 
        )                                        -- 
        port map (                               -- 
            WCLK        => CLK                 , -- In  :
            WE          => buf_we              , -- In  :
            WADDR       => buf_wptr(BUF_DEPTH-1 downto BUF_DATA_BIT_SIZE-3), -- In  :
            WDATA       => buf_wdata           , -- In  :
            RCLK        => CLK                 , -- In  :
            RADDR       => buf_rptr(BUF_DEPTH-1 downto BUF_DATA_BIT_SIZE-3), -- In  :
            RDATA       => buf_rdata             -- Out :
        );
    buf_we <= buf_ben when (buf_wen = '1') else (others => '0');
end RTL;
