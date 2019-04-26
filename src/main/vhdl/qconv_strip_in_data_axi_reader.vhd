-----------------------------------------------------------------------------------
--!     @file    qconv_strip_in_data_axi_reader.vhd
--!     @brief   Quantized Convolution (strip) In Data AXI Reader Module
--!     @version 0.1.0
--!     @date    2019/4/26
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
entity  QCONV_STRIP_IN_DATA_AXI_READER is
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
end QCONV_STRIP_IN_DATA_AXI_READER;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.AXI4_TYPES.all;
use     PIPEWORK.AXI4_COMPONENTS.AXI4_MASTER_READ_INTERFACE;
use     PIPEWORK.PUMP_COMPONENTS.PUMP_STREAM_INTAKE_CONTROLLER;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_SLICE_MASTER_CONTROLLER;
use     PIPEWORK.COMPONENTS.SDPRAM;
architecture RTL of QCONV_STRIP_IN_DATA_AXI_READER is
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
                                           ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD,
                                           C         => NEW_IMAGE_SHAPE_SIDE_EXTERNAL(QCONV_PARAM.MAX_IN_C_BY_WORD),
                                           X         => NEW_IMAGE_SHAPE_SIDE_EXTERNAL(QCONV_PARAM.MAX_IN_W),
                                           Y         => NEW_IMAGE_SHAPE_SIDE_EXTERNAL(QCONV_PARAM.MAX_IN_H)
                                       );
    signal    req_image_c_size      :  integer range 0 to IMAGE_SHAPE.C.MAX_SIZE;
    signal    req_image_x_size      :  integer range 0 to IMAGE_SHAPE.X.MAX_SIZE;
    signal    req_image_y_size      :  integer range 0 to IMAGE_SHAPE.Y.MAX_SIZE;
    signal    req_slice_x_pos       :  integer range 0 to IMAGE_SHAPE.X.MAX_SIZE;
    signal    req_slice_x_size      :  integer range 0 to IMAGE_SHAPE.X.MAX_SIZE;
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
    constant  BUF_WIDTH             :  integer := MAX(AXI_DATA_WIDTH, O_DATA'length);
    ------------------------------------------------------------------------------
    -- バッファのデータ幅のビット数を２のべき乗値で示す.
    ------------------------------------------------------------------------------
    constant  BUF_DATA_BIT_SIZE     :  integer := CALC_BITS(BUF_WIDTH);
    ------------------------------------------------------------------------------
    -- 入力側のフロー制御用定数.
    ------------------------------------------------------------------------------
    constant  I_FLOW_VALID          :  integer := 1;
    constant  I_USE_PUSH_BUF_SIZE   :  integer := 0;
    constant  I_FIXED_FLOW_OPEN     :  integer := 0;
    constant  I_FIXED_POOL_OPEN     :  integer := 1;
    constant  I_REQ_ADDR_VALID      :  integer := 1;
    constant  I_REQ_SIZE_VALID      :  integer := 1;
    constant  I_FLOW_READY_LEVEL    :  std_logic_vector(BUF_DEPTH downto 0)
                                    := std_logic_vector(to_unsigned(BUF_BYTES - MAX_XFER_BYTES    , BUF_DEPTH+1));
    constant  I_BUF_READY_LEVEL     :  std_logic_vector(BUF_DEPTH downto 0)
                                    := std_logic_vector(to_unsigned(BUF_BYTES - 1*AXI_DATA_WIDTH/8, BUF_DEPTH+1));
    constant  I_MAX_REQ_SIZE        :  integer := IMAGE_SHAPE.X.MAX_SIZE * IMAGE_SHAPE.C.MAX_SIZE * IMAGE_SHAPE.ELEM_BITS / 8;
    constant  REQ_SIZE_WIDTH        :  integer := CALC_BITS(I_MAX_REQ_SIZE+1);
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
    constant  AXI_ACK_REGS          :  integer := 1;
    constant  AXI_RDATA_REGS        :  integer := 3;
    constant  OPEN_INFO_BITS        :  integer := 4;
    constant  CLOSE_INFO_BITS       :  integer := 4;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    i_tran_start          :  std_logic;
    signal    i_tran_first          :  std_logic;
    signal    i_tran_last           :  std_logic;
    signal    i_tran_addr           :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    i_tran_addr_load      :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    i_tran_size           :  std_logic_vector(REQ_SIZE_WIDTH -1 downto 0);
    signal    i_tran_size_load      :  std_logic_vector(REQ_SIZE_WIDTH -1 downto 0);
    signal    i_tran_busy           :  std_logic;
    signal    i_tran_done           :  std_logic;
    signal    i_tran_error          :  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    signal    i_req_valid           :  std_logic;
    signal    i_req_addr            :  std_logic_vector(AXI_ADDR_WIDTH -1 downto 0);
    signal    i_req_size            :  std_logic_vector(REQ_SIZE_WIDTH -1 downto 0);
    signal    i_req_buf_ptr         :  std_logic_vector(BUF_DEPTH      -1 downto 0);
    signal    i_req_first           :  std_logic;
    signal    i_req_last            :  std_logic;
    signal    i_req_ready           :  std_logic;
    signal    i_ack_valid           :  std_logic;
    signal    i_ack_size            :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    i_ack_error           :  std_logic;
    signal    i_ack_next            :  std_logic;
    signal    i_ack_last            :  std_logic;
    signal    i_ack_stop            :  std_logic;
    signal    i_ack_none            :  std_logic;
    signal    i_xfer_busy           :  std_logic;
    signal    i_xfer_done           :  std_logic;
    signal    i_xfer_error          :  std_logic;
    signal    i_flow_ready          :  std_logic;
    signal    i_flow_pause          :  std_logic;
    signal    i_flow_stop           :  std_logic;
    signal    i_flow_last           :  std_logic;
    signal    i_flow_size           :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    i_push_fin_valid      :  std_logic;
    signal    i_push_fin_last       :  std_logic;
    signal    i_push_fin_error      :  std_logic;
    signal    i_push_fin_size       :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    i_push_rsv_valid      :  std_logic;
    signal    i_push_rsv_last       :  std_logic;
    signal    i_push_rsv_error      :  std_logic;
    signal    i_push_rsv_size       :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    i_push_buf_reset      :  std_logic;
    signal    i_push_buf_valid      :  std_logic;
    signal    i_push_buf_last       :  std_logic;
    signal    i_push_buf_error      :  std_logic;
    signal    i_push_buf_size       :  std_logic_vector(BUF_DEPTH         downto 0);
    signal    i_push_buf_ready      :  std_logic;
    signal    i_open                :  std_logic;
    constant  i_open_info           :  std_logic_vector(OPEN_INFO_BITS -1 downto 0) := (others => '0');
    constant  i_close_info          :  std_logic_vector(CLOSE_INFO_BITS-1 downto 0) := (others => '0');
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
    signal    o_open                :  std_logic;
    signal    o_done                :  std_logic;
    signal    o_open_info           :  std_logic_vector(OPEN_INFO_BITS -1 downto 0);
    signal    o_open_valid          :  std_logic;
    signal    o_close_info          :  std_logic_vector(CLOSE_INFO_BITS-1 downto 0);
    signal    o_close_valid         :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    req_image_c_size <= to_integer(to_01(unsigned(REQ_IN_C  )));
    req_image_x_size <= to_integer(to_01(unsigned(REQ_IN_W  )));
    req_image_y_size <= to_integer(to_01(unsigned(REQ_IN_H  )));
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
            MAX_SLICE_C_POS     => 0                   , --
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
            SLICE_C_SIZE        => req_image_c_size    , -- In  :
            SLICE_X_POS         => req_slice_x_pos     , -- In  :
            SLICE_X_SIZE        => req_slice_x_size    , -- In  :
            SLICE_Y_SIZE        => req_image_y_size    , -- In  :
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
            MST_ADDR            => i_tran_addr         , -- Out :
            MST_SIZE            => i_tran_size         , -- Out :
            MST_FIRST           => i_tran_first        , -- Out :
            MST_LAST            => i_tran_last         , -- Out :
            MST_START           => i_tran_start        , -- Out :
            MST_BUSY            => i_tran_busy         , -- In  :
            MST_DONE            => i_tran_done         , -- In  :
            MST_ERROR           => i_tran_error          -- In  :
        );                                               -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    i_tran_addr_load <= (others => '1') when (i_tran_start = '1') else (others => '0');
    i_tran_size_load <= (others => '1') when (i_tran_start = '1') else (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PUMP_CTRL: PUMP_STREAM_INTAKE_CONTROLLER             -- 
        generic map (                                    -- 
            I_CLK_RATE          => 1                   , --
            I_REQ_ADDR_VALID    => I_REQ_ADDR_VALID    , --
            I_REQ_ADDR_BITS     => AXI_ADDR_WIDTH      , --
            I_REG_ADDR_BITS     => AXI_ADDR_WIDTH      , --
            I_REQ_SIZE_VALID    => I_REQ_SIZE_VALID    , --
            I_REQ_SIZE_BITS     => REQ_SIZE_WIDTH      , --
            I_REG_SIZE_BITS     => REQ_SIZE_WIDTH      , --
            I_REG_MODE_BITS     => 1                   , --
            I_REG_STAT_BITS     => 1                   , --
            I_USE_PUSH_BUF_SIZE => I_USE_PUSH_BUF_SIZE , --
            I_FIXED_FLOW_OPEN   => I_FIXED_FLOW_OPEN   , --
            I_FIXED_POOL_OPEN   => I_FIXED_POOL_OPEN   , --
            O_CLK_RATE          => 1                   , --
            O_DATA_BITS         => O_DATA'length       , --
            BUF_DEPTH           => BUF_DEPTH           , --
            BUF_DATA_BITS       => BUF_WIDTH           , --
            I2O_OPEN_INFO_BITS  => OPEN_INFO_BITS      , --
            I2O_CLOSE_INFO_BITS => CLOSE_INFO_BITS     , --
            O2I_OPEN_INFO_BITS  => OPEN_INFO_BITS      , --
            O2I_CLOSE_INFO_BITS => CLOSE_INFO_BITS     , --
            I2O_DELAY_CYCLE     => 1                     --
        )                                                -- 
        port map (                                       -- 
        ---------------------------------------------------------------------------
        --Reset Signals.
        ---------------------------------------------------------------------------
            RST                 => RST                 , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Clock and Clock Enable.
        ---------------------------------------------------------------------------
            I_CLK               => CLK                 , --  In  :
            I_CLR               => CLR                 , --  In  :
            I_CKE               => '1'                 , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Control Register Interface.
        ---------------------------------------------------------------------------
            I_ADDR_L            => i_tran_addr_load    , --  In  :
            I_ADDR_D            => i_tran_addr         , --  In  :
            I_SIZE_L            => i_tran_size_load    , --  In  :
            I_SIZE_D            => i_tran_size         , --  In  :
            I_START_L           => i_tran_start        , --  In  :
            I_START_D           => i_tran_start        , --  In  :
            I_FIRST_L           => i_tran_start        , --  In  :
            I_FIRST_D           => i_tran_first        , --  In  :
            I_LAST_L            => i_tran_start        , --  In  :
            I_LAST_D            => i_tran_last         , --  In  :
            I_DONE_EN_L         => i_tran_start        , --  In  :
            I_DONE_EN_D         => '0'                 , --  In  :
            I_DONE_ST_L         => i_tran_start        , --  In  :
            I_DONE_ST_D         => '0'                 , --  In  :
            I_ERR_ST_L          => i_tran_start        , --  In  :
            I_ERR_ST_D          => '0'                 , --  In  :
            I_CLOSE_ST_L        => i_tran_start        , --  In  :
            I_CLOSE_ST_D        => '0'                 , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Configuration Signals.
        ---------------------------------------------------------------------------
            I_BUF_READY_LEVEL   => I_BUF_READY_LEVEL   , --  In  :
            I_FLOW_READY_LEVEL  => I_FLOW_READY_LEVEL  , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Transaction Command Request Signals.
        ---------------------------------------------------------------------------
            I_REQ_VALID         => i_req_valid         , --  Out :
            I_REQ_ADDR          => i_req_addr          , --  Out :
            I_REQ_SIZE          => i_req_size          , --  Out :
            I_REQ_BUF_PTR       => i_req_buf_ptr       , --  Out :
            I_REQ_FIRST         => i_req_first         , --  Out :
            I_REQ_LAST          => i_req_last          , --  Out :
            I_REQ_READY         => i_req_ready         , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Transaction Command Acknowledge Signals.
        ---------------------------------------------------------------------------
            I_ACK_VALID         => i_ack_valid         , --  In  :
            I_ACK_SIZE          => i_ack_size          , --  In  :
            I_ACK_ERROR         => i_ack_error         , --  In  :
            I_ACK_NEXT          => i_ack_next          , --  In  :
            I_ACK_LAST          => i_ack_last          , --  In  :
            I_ACK_STOP          => i_ack_stop          , --  In  :
            I_ACK_NONE          => i_ack_none          , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Transfer Status Signals.
        ---------------------------------------------------------------------------
            I_XFER_BUSY         => i_xfer_busy         , --  In  :
            I_XFER_DONE         => i_xfer_done         , --  In  :
            I_XFER_ERROR        => i_xfer_error        , --  In  :
        ---------------------------------------------------------------------------
        -- Intake Flow Control Signals.
        ---------------------------------------------------------------------------
            I_FLOW_READY        => i_flow_ready        , --  Out :
            I_FLOW_PAUSE        => i_flow_pause        , --  Out :
            I_FLOW_STOP         => i_flow_stop         , --  Out :
            I_FLOW_LAST         => i_flow_last         , --  Out :
            I_FLOW_SIZE         => i_flow_size         , --  Out :
            I_PUSH_FIN_VALID    => i_push_fin_valid    , --  In  :
            I_PUSH_FIN_LAST     => i_push_fin_last     , --  In  :
            I_PUSH_FIN_ERROR    => i_push_fin_error    , --  In  :
            I_PUSH_FIN_SIZE     => i_push_fin_size     , --  In  :
            I_PUSH_RSV_VALID    => i_push_rsv_valid    , --  In  :
            I_PUSH_RSV_LAST     => i_push_rsv_last     , --  In  :
            I_PUSH_RSV_ERROR    => i_push_rsv_error    , --  In  :
            I_PUSH_RSV_SIZE     => i_push_rsv_size     , --  In  :
            I_PUSH_BUF_RESET    => i_push_buf_reset    , --  In  :
            I_PUSH_BUF_VALID    => i_push_buf_valid    , --  In  :
            I_PUSH_BUF_LAST     => i_push_buf_last     , --  In  :
            I_PUSH_BUF_ERROR    => i_push_buf_error    , --  In  :
            I_PUSH_BUF_SIZE     => i_push_buf_size     , --  In  :
            I_PUSH_BUF_READY    => i_push_buf_ready    , --  Out :
        ---------------------------------------------------------------------------
        -- Intake Status.
        ---------------------------------------------------------------------------
            I_OPEN              => i_open              , --  Out :
            I_TRAN_BUSY         => i_tran_busy         , --  Out :
            I_TRAN_DONE         => i_tran_done         , --  Out :
            I_TRAN_ERROR        => i_tran_error        , --  Out :
        ---------------------------------------------------------------------------
        -- Intake Open/Close Infomation Interface
        ---------------------------------------------------------------------------
            I_I2O_OPEN_INFO     => i_open_info         , --  In  :
            I_I2O_CLOSE_INFO    => i_close_info        , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Clock and Clock Enable.
        ---------------------------------------------------------------------------
            O_CLK               => CLK                 , --  In  :
            O_CLR               => CLR                 , --  In  :
            O_CKE               => '1'                 , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Stream Interface.
        ---------------------------------------------------------------------------
            O_DATA              => O_DATA              , --  Out :
            O_STRB              => open                , --  Out :
            O_LAST              => O_LAST              , --  Out :
            O_VALID             => O_VALID             , --  Out :
            O_READY             => O_READY             , --  In  :
        ---------------------------------------------------------------------------
        -- Outlet Open/Close Infomation Interface
        ---------------------------------------------------------------------------
            O_O2I_OPEN_INFO     => o_open_info         , --  In  :
            O_O2I_OPEN_VALID    => o_open_valid        , --  In  :
            O_O2I_CLOSE_INFO    => o_close_info        , --  In  :
            O_O2I_CLOSE_VALID   => o_close_valid       , --  In  :
            O_I2O_OPEN_INFO     => o_open_info         , --  Out :
            O_I2O_OPEN_VALID    => o_open_valid        , --  Out :
            O_I2O_CLOSE_INFO    => o_close_info        , --  Out :
            O_I2O_CLOSE_VALID   => o_close_valid       , --  Out :
        ---------------------------------------------------------------------------
        -- Outlet Buffer Read Interface.
        ---------------------------------------------------------------------------
            BUF_REN             => buf_ren             , --  Out :
            BUF_PTR             => buf_rptr            , --  Out :
            BUF_DATA            => buf_rdata             --  In  :
        );                                               --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    AXI_IF: AXI4_MASTER_READ_INTERFACE                   -- 
        generic map (                                    -- 
            AXI4_ADDR_WIDTH     => AXI_ADDR_WIDTH      , -- 
            AXI4_DATA_WIDTH     => AXI_DATA_WIDTH      , --   
            AXI4_ID_WIDTH       => AXI_ID_WIDTH        , --   
            VAL_BITS            => 1                   , --   
            REQ_SIZE_BITS       => REQ_SIZE_WIDTH      , --   
            REQ_SIZE_VALID      => 1                   , --   
            FLOW_VALID          => I_FLOW_VALID        , --   
            BUF_DATA_WIDTH      => BUF_WIDTH           , --   
            BUF_PTR_BITS        => BUF_DEPTH           , --   
            ALIGNMENT_BITS      => AXI_ALIGNMENT_BITS  , --   
            XFER_SIZE_BITS      => BUF_DEPTH+1         , --   
            XFER_MIN_SIZE       => MAX_XFER_SIZE       , --   
            XFER_MAX_SIZE       => MAX_XFER_SIZE       , --   
            QUEUE_SIZE          => AXI_REQ_QUEUE       , --   
            RDATA_REGS          => AXI_RDATA_REGS      , --   
            ACK_REGS            => AXI_ACK_REGS          --   
        )                                                -- 
        port map(                                        --
        ---------------------------------------------------------------------------
        -- Clock and Reset Signals.
        ---------------------------------------------------------------------------
            CLK                 => CLK                 , -- In  :
            RST                 => RST                 , -- In  :
            CLR                 => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Address Channel Signals.
        ---------------------------------------------------------------------------
            ARID                => AXI_ARID            , -- Out :
            ARADDR              => AXI_ARADDR          , -- Out :
            ARLEN               => AXI_ARLEN           , -- Out :
            ARSIZE              => AXI_ARSIZE          , -- Out :
            ARBURST             => AXI_ARBURST         , -- Out :
            ARLOCK              => AXI_ARLOCK          , -- Out :
            ARCACHE             => AXI_ARCACHE         , -- Out :
            ARPROT              => AXI_ARPROT          , -- Out :
            ARQOS               => AXI_ARQOS           , -- Out :
            ARREGION            => AXI_ARREGION        , -- Out :
            ARVALID             => AXI_ARVALID         , -- Out :
            ARREADY             => AXI_ARREADY         , -- In  :
        ---------------------------------------------------------------------------
        -- AXI4 Read Data Channel Signals.
        ---------------------------------------------------------------------------
            RID                 => AXI_RID             , -- In  :
            RDATA               => AXI_RDATA           , -- In  :
            RRESP               => AXI_RRESP           , -- In  :
            RLAST               => AXI_RLAST           , -- In  :
            RVALID              => AXI_RVALID          , -- In  :
            RREADY              => AXI_RREADY          , -- Out :
        ---------------------------------------------------------------------------
        -- Command Request Signals.
        ---------------------------------------------------------------------------
            XFER_SIZE_SEL       => "1"                 , -- In  :
            REQ_ADDR            => i_req_addr          , -- In  :
            REQ_SIZE            => i_req_size          , -- In  :
            REQ_ID              => AXI_REQ_ID          , -- In  :
            REQ_BURST           => AXI4_ABURST_INCR    , -- In  :
            REQ_LOCK            => AXI_REQ_LOCK        , -- In  :
            REQ_CACHE           => AXI_REQ_CACHE       , -- In  :
            REQ_PROT            => AXI_REQ_PROT        , -- In  :
            REQ_QOS             => AXI_REQ_QOS         , -- In  :
            REQ_REGION          => AXI_REQ_REGION      , -- In  :
            REQ_BUF_PTR         => i_req_buf_ptr       , -- In  :
            REQ_FIRST           => i_req_first         , -- In  :
            REQ_LAST            => i_req_last          , -- In  :
            REQ_SPECULATIVE     => AXI_REQ_SPECULATIVE , -- In  :
            REQ_SAFETY          => AXI_REQ_SAFETY      , -- In  :
            REQ_VAL(0)          => i_req_valid         , -- In  :
            REQ_RDY             => i_req_ready         , -- Out :
        ---------------------------------------------------------------------------
        -- Command Acknowledge Signals.
        ---------------------------------------------------------------------------
            ACK_VAL(0)          => i_ack_valid         , -- Out :
            ACK_NEXT            => i_ack_next          , -- Out :
            ACK_LAST            => i_ack_last          , -- Out :
            ACK_ERROR           => i_ack_error         , -- Out :
            ACK_STOP            => i_ack_stop          , -- Out :
            ACK_NONE            => i_ack_none          , -- Out :
            ACK_SIZE            => i_ack_size          , -- Out :
        ---------------------------------------------------------------------------
        -- Transfer Status Signal.
        ---------------------------------------------------------------------------
            XFER_BUSY(0)        => i_xfer_busy         , -- Out :
            XFER_ERROR(0)       => i_xfer_error        , -- Out :
            XFER_DONE(0)        => i_xfer_done         , -- Out :
        ---------------------------------------------------------------------------
        -- Flow Control Signals.
        ---------------------------------------------------------------------------
            FLOW_STOP           => i_flow_stop         , -- In  :
            FLOW_PAUSE          => i_flow_pause        , -- In  :
            FLOW_LAST           => i_flow_last         , -- In  :
            FLOW_SIZE           => i_flow_size         , -- In  :
        ---------------------------------------------------------------------------
        -- Push Reserve Size Signals.
        ---------------------------------------------------------------------------
            PUSH_RSV_VAL(0)     => i_push_rsv_valid    , -- Out :
            PUSH_RSV_LAST       => i_push_rsv_last     , -- Out :
            PUSH_RSV_ERROR      => i_push_rsv_error    , -- Out :
            PUSH_RSV_SIZE       => i_push_rsv_size     , -- Out :
        ---------------------------------------------------------------------------
        -- Push Final Size Signals.
        ---------------------------------------------------------------------------
            PUSH_FIN_VAL(0)     => i_push_fin_valid    , -- Out :
            PUSH_FIN_LAST       => i_push_fin_last     , -- Out :
            PUSH_FIN_ERROR      => i_push_fin_error    , -- Out :
            PUSH_FIN_SIZE       => i_push_fin_size     , -- Out :
        ---------------------------------------------------------------------------
        -- Push Buffer Size Signals.
        ---------------------------------------------------------------------------
            PUSH_BUF_RESET(0)   => i_push_buf_reset    , -- Out :
            PUSH_BUF_VAL(0)     => i_push_buf_valid    , -- Out :
            PUSH_BUF_LAST       => i_push_buf_last     , -- Out :
            PUSH_BUF_ERROR      => i_push_buf_error    , -- Out :
            PUSH_BUF_SIZE       => i_push_buf_size     , -- Out :
            PUSH_BUF_RDY(0)     => i_push_buf_ready    , -- In  :
        ---------------------------------------------------------------------------
        -- Read Buffer Interface Signals.
        ---------------------------------------------------------------------------
            BUF_WEN(0)          => buf_wen             , -- Out :
            BUF_BEN             => buf_ben             , -- Out :
            BUF_DATA            => buf_wdata           , -- Out :
            BUF_PTR             => buf_wptr              -- Out :
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

