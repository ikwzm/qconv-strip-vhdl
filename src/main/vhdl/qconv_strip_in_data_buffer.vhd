-----------------------------------------------------------------------------------
--!     @file    qconv_strip_in_data_buffer.vhd
--!     @brief   Quantized Convolution (strip) In Data Buffer Module
--!     @version 0.1.0
--!     @date    2019/4/5
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
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
-----------------------------------------------------------------------------------
--! @brief 
-----------------------------------------------------------------------------------
entity  QCONV_STRIP_IN_DATA_BUFFER is
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
end QCONV_STRIP_IN_DATA_BUFFER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.SDPRAM;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_GENERATOR;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_CHANNEL_REDUCER;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_BUFFER_INTAKE;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_BUFFER_OUTLET;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_GENERATOR_WITH_PADDING;
use     PIPEWORK.CONVOLUTION_TYPES.all;
architecture RTL of QCONV_STRIP_IN_DATA_BUFFER is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  WORD_BITS             :  integer := QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD;
    constant  PAD_DATA              :  std_logic_vector(WORD_BITS-1 downto 0) := (others => '0');
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  BUF_BANK_SIZE         :  integer := 4;
    constant  BUF_LINE_SIZE         :  integer := 4;
    -------------------------------------------------------------------------------
    -- BUF_WIDTH : メモリのビット幅を２のべき乗値で示す
    -------------------------------------------------------------------------------
    function  CALC_BUF_WIDTH    return integer is
        variable width              :  integer;
    begin
        width := 0;
        while (2**width < (IN_C_UNROLL * WORD_BITS)) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant  BUF_WIDTH             :  integer := CALC_BUF_WIDTH;
    -------------------------------------------------------------------------------
    -- BUF_DEPTH: メモリバンク１つあたりの深さ(ビット単位)を２のべき乗値で示す
    -------------------------------------------------------------------------------
    function  CALC_BUF_DEPTH    return integer is
        variable size               :  integer;
        variable depth              :  integer;
    begin
        size  := ELEMENT_SIZE*WORD_BITS;
        size  := (size + BUF_BANK_SIZE - 1)/BUF_BANK_SIZE;
        depth := 0;
        while (2**depth < size) loop
            depth := depth + 1;
        end loop;
        return depth;
    end function;
    constant  BUF_DEPTH             :  integer := CALC_BUF_DEPTH;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  BUF_DATA_BITS         :  integer := 2**BUF_WIDTH;
    constant  BUF_ADDR_BITS         :  integer := BUF_DEPTH - BUF_WIDTH;
    constant  BUF_WENA_BITS         :  integer := 1;
    signal    conv3x3_buf_wdata     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv3x3_buf_waddr     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    conv3x3_buf_we        :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_WENA_BITS-1 downto 0);
    signal    conv3x3_buf_rdata     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv3x3_buf_raddr     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    conv1x1_buf_wdata     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv1x1_buf_waddr     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    conv1x1_buf_we        :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_WENA_BITS-1 downto 0);
    signal    conv1x1_buf_rdata     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv1x1_buf_raddr     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  INTAKE_STREAM_PARAM   :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                           ELEM_BITS => WORD_BITS,
                                           C         => 1,
                                           X         => 1,
                                           Y         => 1
                                       );
    signal    intake_start          :  std_logic;
    signal    intake_busy           :  std_logic;
    signal    intake_done           :  std_logic;
    signal    conv3x3_intake_data   :  std_logic_vector(INTAKE_STREAM_PARAM.DATA.SIZE-1 downto 0);
    signal    conv3x3_intake_valid  :  std_logic;
    signal    conv3x3_intake_ready  :  std_logic;
    signal    conv1x1_intake_data   :  std_logic_vector(INTAKE_STREAM_PARAM.DATA.SIZE-1 downto 0);
    signal    conv1x1_intake_valid  :  std_logic;
    signal    conv1x1_intake_ready  :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  OUTLET_STREAM_PARAM   :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                           ELEM_BITS => WORD_BITS,
                                           C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(3*3*IN_C_UNROLL, TRUE, TRUE),
                                           D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(   OUT_C_UNROLL, TRUE, TRUE),
                                           X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1              , TRUE, TRUE),
                                           Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1              , TRUE, TRUE)
                                       );
    signal    conv3x3_outlet_data   :  std_logic_vector(OUTLET_STREAM_PARAM.DATA.SIZE-1 downto 0);
    signal    conv3x3_outlet_valid  :  std_logic;
    signal    conv3x3_outlet_ready  :  std_logic;
    signal    conv3x3_outlet_atrb_c :  IMAGE_STREAM_ATRB_VECTOR(0 to OUTLET_STREAM_PARAM.SHAPE.C.SIZE-1);
    signal    conv3x3_outlet_atrb_d :  IMAGE_STREAM_ATRB_VECTOR(0 to OUTLET_STREAM_PARAM.SHAPE.D.SIZE-1);
    signal    conv3x3_outlet_atrb_x :  IMAGE_STREAM_ATRB_VECTOR(0 to OUTLET_STREAM_PARAM.SHAPE.X.SIZE-1);
    signal    conv3x3_outlet_atrb_y :  IMAGE_STREAM_ATRB_VECTOR(0 to OUTLET_STREAM_PARAM.SHAPE.Y.SIZE-1);
    signal    conv1x1_outlet_data   :  std_logic_vector(OUTLET_STREAM_PARAM.DATA.SIZE-1 downto 0);
    signal    conv1x1_outlet_valid  :  std_logic;
    signal    conv1x1_outlet_ready  :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE            is (IDLE_STATE, CONV3x3_STATE, CONV1x1_STATE, RES_STATE);
    signal    state                 :  STATE_TYPE;
    signal    conv3x3_start         :  std_logic;
    signal    conv3x3_busy          :  std_logic;
    signal    conv3x3_done          :  std_logic;
    signal    conv1x1_start         :  std_logic;
    signal    conv1x1_busy          :  std_logic;
    signal    conv1x1_done          :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- メインシーケンサ
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                state <= IDLE_STATE;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                state <= IDLE_STATE;
            else
                case state is
                    when IDLE_STATE =>
                        if    (REQ_VALID = '1' and K3x3  = '1') then
                            state <= CONV3x3_STATE;
                        elsif (REQ_VALID = '1' and K3x3 /= '1') then
                            state <= CONV1x1_STATE;
                        else
                            state <= IDLE_STATE;
                        end if;
                    when CONV3x3_STATE =>
                        if (intake_busy = '0' and (conv3x3_busy = '0' or conv3x3_done = '1')) then
                            state <= RES_STATE;
                        else
                            state <= CONV3x3_STATE;
                        end if;
                    when CONV1x1_STATE =>
                        if (intake_busy = '0' and (conv1x1_busy = '0' or conv1x1_done = '1')) then
                            state <= RES_STATE;
                        else
                            state <= CONV1x1_STATE;
                        end if;
                    when RES_STATE =>
                        if (RES_READY = '1') then
                            state <= IDLE_STATE;
                        else
                            state <= RES_STATE;
                        end if;
                    when others =>
                            state <= IDLE_STATE;
                end case;
            end if;
        end if;
    end process;
    REQ_READY     <= '1' when (state = IDLE_STATE) else '0';
    RES_VALID     <= '1' when (state = RES_STATE ) else '0';
    intake_start  <= '1' when (state = IDLE_STATE and REQ_VALID = '1') else '0';
    conv3x3_start <= '1' when (state = IDLE_STATE and REQ_VALID = '1' and K3x3  = '1') else '0';
    conv1x1_start <= '1' when (state = IDLE_STATE and REQ_VALID = '1' and K3x3 /= '1') else '0';
    -------------------------------------------------------------------------------
    -- 入力データを内部データ(INTAKE_STREAM)形式に変換する.
    -------------------------------------------------------------------------------
    INTAKE: block
        signal    swapped_data  :  std_logic_vector(QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD-1 downto 0);
        signal    o_data        :  std_logic_vector(INTAKE_STREAM_PARAM.DATA.SIZE-1 downto 0);
        signal    o_valid       :  std_logic;
        signal    o_ready       :  std_logic;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process(I_DATA) begin
            for word_pos in 0 to QCONV_PARAM.NBITS_PER_WORD-1 loop
            for data_pos in 0 to QCONV_PARAM.NBITS_IN_DATA -1 loop
                swapped_data(word_pos*QCONV_PARAM.NBITS_IN_DATA + data_pos) <= I_DATA(data_pos*QCONV_PARAM.NBITS_PER_WORD + word_pos);
            end loop;
            end loop;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        PADDING: IMAGE_STREAM_GENERATOR_WITH_PADDING     -- 
            generic map (                                -- 
                O_PARAM         => INTAKE_STREAM_PARAM , -- 
                O_SHAPE         => I_SHAPE             , -- 
                I_DATA_BITS     => WORD_BITS           , --
                MAX_PAD_SIZE    => QCONV_PARAM.MAX_PAD_SIZE  -- 
            )                                            -- 
            port map (                                   -- 
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
                START           => intake_start        , -- In  :
                BUSY            => intake_busy         , -- Out :
                DONE            => intake_done         , -- Out :
                C_SIZE          => IN_C_BY_WORD        , -- In  :
                X_SIZE          => IN_W                , -- In  :
                Y_SIZE          => IN_H                , -- In  :
                LEFT_PAD_SIZE   => LEFT_PAD_SIZE       , -- In  :
                RIGHT_PAD_SIZE  => RIGHT_PAD_SIZE      , -- In  :
                TOP_PAD_SIZE    => TOP_PAD_SIZE        , -- In  :
                BOTTOM_PAD_SIZE => BOTTOM_PAD_SIZE     , -- In  :
                PAD_DATA        => PAD_DATA            , -- In  :
                I_DATA          => swapped_data        , -- In  :
                I_VALID         => I_VALID             , -- In  :
                I_READY         => I_READY             , -- Out :
                O_DATA          => o_data              , -- Out :
                O_VALID         => o_valid             , -- Out :
                O_READY         => o_ready               -- In  :
            );
        conv3x3_intake_data  <= o_data;
        conv1x1_intake_data  <= o_data;
        conv3x3_intake_valid <= '1' when (state = CONV3x3_STATE and o_valid  = '1') else '0';
        conv1x1_intake_valid <= '1' when (state = CONV1x1_STATE and o_valid  = '1') else '0';
        o_ready  <= '1' when (state = CONV3x3_STATE and conv3x3_intake_ready = '1') or
                             (state = CONV1x1_STATE and conv1x1_intake_ready = '1') else '0';
    end block;
    -------------------------------------------------------------------------------
    -- 3x3 用のバッファ制御
    -------------------------------------------------------------------------------
    CONV3x3: block
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  KERNEL_SIZE   :  CONVOLUTION_KERNEL_SIZE_TYPE   := CONVOLUTION_KERNEL_SIZE_3x3;
        constant  STRIDE        :  IMAGE_STREAM_STRIDE_PARAM_TYPE := NEW_IMAGE_STREAM_STRIDE_PARAM(1,1);
        constant  BANK_SIZE     :  integer := BUF_BANK_SIZE;
        constant  LINE_SIZE     :  integer := BUF_LINE_SIZE;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  I_CHAN_PARAM  :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => WORD_BITS,
                                       C         => IN_C_UNROLL,
                                       X         => 1,
                                       Y         => 1
                                   );
        signal    i_chan_data   :  std_logic_vector(I_CHAN_PARAM.DATA.SIZE-1 downto 0);
        signal    i_chan_valid  :  std_logic;
        signal    i_chan_ready  :  std_logic;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  O_CHAN_PARAM  :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => WORD_BITS,
                                       C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(IN_C_UNROLL                       , TRUE , TRUE ),
                                       D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(OUT_C_UNROLL                      , FALSE, TRUE ),
                                       X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.X.LO, KERNEL_SIZE.X.HI, TRUE , TRUE ),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.Y.LO, KERNEL_SIZE.Y.HI, TRUE , TRUE ),
                                       STRIDE    => STRIDE
                                   );
        constant  O_CHAN_SHAPE  :  IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE(
                                       ELEM_BITS => WORD_BITS,
                                       C         => NEW_IMAGE_SHAPE_SIDE_AUTO(ELEMENT_SIZE),
                                       D         => O_SHAPE.C,
                                       X         => NEW_IMAGE_SHAPE_SIDE_AUTO(ELEMENT_SIZE),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_AUTO(ELEMENT_SIZE)
                                   );
        signal    o_chan_data   :  std_logic_vector(O_CHAN_PARAM.DATA.SIZE-1 downto 0);
        signal    o_chan_valid  :  std_logic;
        signal    o_chan_ready  :  std_logic;
        signal    o_line_last   :  std_logic;
        signal    o_line_feed   :  std_logic;
        signal    o_line_return :  std_logic;
        signal    o_frame_last  :  std_logic;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    line_valid    :  std_logic_vector(        LINE_SIZE-1 downto 0);
        signal    line_atrb     :  IMAGE_STREAM_ATRB_VECTOR(LINE_SIZE-1 downto 0);
        signal    line_feed     :  std_logic_vector(        LINE_SIZE-1 downto 0);
        signal    line_return   :  std_logic_vector(        LINE_SIZE-1 downto 0);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    x_size        :  integer range 0 to ELEMENT_SIZE;
        signal    c_size        :  integer range 0 to ELEMENT_SIZE;
        signal    c_offset      :  integer range 0 to 2**BUF_ADDR_BITS;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    buf_wdata     :  std_logic_vector(BANK_SIZE*LINE_SIZE*BUF_DATA_BITS-1 downto 0);
        signal    buf_waddr     :  std_logic_vector(BANK_SIZE*LINE_SIZE*BUF_ADDR_BITS-1 downto 0);
        signal    buf_we        :  std_logic_vector(BANK_SIZE*LINE_SIZE              -1 downto 0);
        signal    buf_raddr     :  std_logic_vector(BANK_SIZE*LINE_SIZE*BUF_ADDR_BITS-1 downto 0);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    o_chan_atrb_c :  IMAGE_STREAM_ATRB_VECTOR(0 to O_CHAN_PARAM.SHAPE.C.SIZE-1);
        signal    o_chan_atrb_d :  IMAGE_STREAM_ATRB_VECTOR(0 to O_CHAN_PARAM.SHAPE.D.SIZE-1);
        signal    o_chan_atrb_x :  IMAGE_STREAM_ATRB_VECTOR(0 to O_CHAN_PARAM.SHAPE.X.SIZE-1);
        signal    o_chan_atrb_y :  IMAGE_STREAM_ATRB_VECTOR(0 to O_CHAN_PARAM.SHAPE.Y.SIZE-1);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK,RST) begin
            if (RST = '1') then
                    conv3x3_busy <= '0';
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    conv3x3_busy <= '0';
                elsif (conv3x3_start = '1') then
                    conv3x3_busy <= '1';
                elsif (conv3x3_busy = '1' and o_frame_last  = '1') then
                    conv3x3_busy <= '0';
                end if;
            end if;
        end process;
        conv3x3_done <= '1' when (conv3x3_busy = '1' and o_frame_last  = '1') else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        I_CHAN: IMAGE_STREAM_CHANNEL_REDUCER             -- 
            generic map (                                -- 
                I_PARAM         => INTAKE_STREAM_PARAM , -- 
                O_PARAM         => I_CHAN_PARAM          -- 
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 入力側 Stream I/F
            -----------------------------------------------------------------------
                I_DATA          => conv3x3_intake_data , -- In  :
                I_VALID         => conv3x3_intake_valid, -- In  :
                I_READY         => conv3x3_intake_ready, -- Out :
            -----------------------------------------------------------------------
            -- 出力側 Stream I/F
            -----------------------------------------------------------------------
                O_DATA          => i_chan_data         , -- Out :
                O_VALID         => i_chan_valid        , -- Out :
                O_READY         => i_chan_ready          -- In  :
            );                                           -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        BUF_INTAKE: IMAGE_STREAM_BUFFER_INTAKE           -- 
            generic map (                                -- 
                I_PARAM         => I_CHAN_PARAM        , -- 
                I_SHAPE         => I_SHAPE             , --
                ELEMENT_SIZE    => ELEMENT_SIZE        , --
                BANK_SIZE       => BANK_SIZE           , --
                LINE_SIZE       => LINE_SIZE           , --
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS       , -- 
                LINE_QUEUE      => 1                     --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 入力側 I/F
            -----------------------------------------------------------------------
                I_DATA          => i_chan_data         , -- In  :
                I_VALID         => i_chan_valid        , -- In  :
                I_READY         => i_chan_ready        , -- Out :
            -----------------------------------------------------------------------
            -- 出力側 I/F
            -----------------------------------------------------------------------
                O_LINE_VALID    => line_valid          , -- Out :
                O_X_SIZE        => x_size              , -- Out :
                O_C_SIZE        => c_size              , -- Out :
                O_C_OFFSET      => c_offset            , -- Out :
                O_LINE_ATRB     => line_atrb           , -- Out :
                O_LINE_FEED     => line_feed           , -- In  :
                O_LINE_RETURN   => line_return         , -- In  :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => buf_wdata           , -- Out :
                BUF_ADDR        => buf_waddr           , -- Out :
                BUF_WE          => buf_we                -- Out :
            );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        BUF_OUTLET: IMAGE_STREAM_BUFFER_OUTLET           -- 
            generic map (                                -- 
                O_PARAM         => O_CHAN_PARAM        , --
                O_SHAPE         => O_CHAN_SHAPE        , --
                ELEMENT_SIZE    => ELEMENT_SIZE        , --
                BANK_SIZE       => BANK_SIZE           , --
                LINE_SIZE       => LINE_SIZE           , --
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS       , --
                BANK_QUEUE      => 2                   , --
                LINE_QUEUE      => 1                     --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 各種サイズ
            -----------------------------------------------------------------------
                X_SIZE          => x_size              , -- In  :
                D_SIZE          => OUT_C               , -- In  :
                C_SIZE          => c_size              , -- In  :
                C_OFFSET        => c_offset            , -- In  :
            -----------------------------------------------------------------------
            -- 入力側 I/F
            -----------------------------------------------------------------------
                I_LINE_VALID    => line_valid          , -- In  :
                I_LINE_ATRB     => line_atrb           , -- In  :
                I_LINE_FEED     => line_feed           , -- Out :
                I_LINE_RETURN   => line_return         , -- Out :
            -----------------------------------------------------------------------
            -- 出力側 I/F
            -----------------------------------------------------------------------
                O_DATA          => o_chan_data         , -- Out :
                O_VALID         => o_chan_valid        , -- Out :
                O_READY         => o_chan_ready        , -- In  :
                O_LAST          => o_frame_last        , -- In  :
                O_FEED          => o_line_feed         , -- In  :
                O_RETURN        => o_line_return       , -- In  :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => conv3x3_buf_rdata   , -- In  :
                BUF_ADDR        => buf_raddr             -- Out :
            );
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        o_line_last  <= '1' when (IMAGE_STREAM_DATA_IS_LAST_C(O_CHAN_PARAM, o_chan_data)) and
                                 (IMAGE_STREAM_DATA_IS_LAST_D(O_CHAN_PARAM, o_chan_data)) and
                                 (IMAGE_STREAM_DATA_IS_LAST_X(O_CHAN_PARAM, o_chan_data)) and
                                 (o_chan_valid = '1' and o_chan_ready = '1'             ) else '0';
        o_frame_last <= '1' when (o_line_last  = '1') and
                                 (IMAGE_STREAM_DATA_IS_LAST_Y(O_CHAN_PARAM, o_chan_data)) else '0';
        o_line_feed  <= '1' when (o_line_last  = '1') else '0';
        o_line_return<= '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv3x3_buf_wdata <= buf_wdata when (conv3x3_busy = '1') else (others => '0');
        conv3x3_buf_waddr <= buf_waddr when (conv3x3_busy = '1') else (others => '0');
        conv3x3_buf_we    <= buf_we    when (conv3x3_busy = '1') else (others => '0');
        conv3x3_buf_raddr <= buf_raddr when (conv3x3_busy = '1') else (others => '0');
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv3x3_outlet_data <= CONVOLUTION_PIPELINE_FROM_IMAGE_STREAM(
                                    PIPELINE_PARAM => OUTLET_STREAM_PARAM,
                                    STREAM_PARAM   => O_CHAN_PARAM       ,
                                    KERNEL_SIZE    => KERNEL_SIZE        ,
                                    STRIDE         => STRIDE             ,
                                    STREAM_DATA    => o_chan_data
                                );
        conv3x3_outlet_valid <= o_chan_valid;
        o_chan_ready <= conv3x3_outlet_ready;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_chan_atrb_c <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(O_CHAN_PARAM, o_chan_data);
        o_chan_atrb_d <= GET_ATRB_D_VECTOR_FROM_IMAGE_STREAM_DATA(O_CHAN_PARAM, o_chan_data);
        o_chan_atrb_x <= GET_ATRB_X_VECTOR_FROM_IMAGE_STREAM_DATA(O_CHAN_PARAM, o_chan_data);
        o_chan_atrb_y <= GET_ATRB_Y_VECTOR_FROM_IMAGE_STREAM_DATA(O_CHAN_PARAM, o_chan_data);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv3x3_outlet_atrb_c <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_STREAM_PARAM, conv3x3_outlet_data);
        conv3x3_outlet_atrb_d <= GET_ATRB_D_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_STREAM_PARAM, conv3x3_outlet_data);
        conv3x3_outlet_atrb_x <= GET_ATRB_X_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_STREAM_PARAM, conv3x3_outlet_data);
        conv3x3_outlet_atrb_y <= GET_ATRB_Y_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_STREAM_PARAM, conv3x3_outlet_data);
    end block;
    -------------------------------------------------------------------------------
    -- 1x1 用のバッファ制御
    -------------------------------------------------------------------------------
    CONV1x1: block
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  KERNEL_SIZE   :  CONVOLUTION_KERNEL_SIZE_TYPE   := CONVOLUTION_KERNEL_SIZE_1x1;
        constant  STRIDE        :  IMAGE_STREAM_STRIDE_PARAM_TYPE := NEW_IMAGE_STREAM_STRIDE_PARAM(1,1);
        constant  BANK_SIZE     :  integer := 1;
        constant  LINE_SIZE     :  integer := 2;
        constant  C_WORDS       :  integer := 8;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  I_CHAN_PARAM  :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => WORD_BITS,
                                       C         => IN_C_UNROLL*C_WORDS,
                                       X         => 1,
                                       Y         => 1
                                   );
        signal    i_chan_data   :  std_logic_vector(I_CHAN_PARAM.DATA.SIZE-1 downto 0);
        signal    i_chan_valid  :  std_logic;
        signal    i_chan_ready  :  std_logic;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  O_CHAN_PARAM  :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => WORD_BITS,
                                       C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(IN_C_UNROLL*C_WORDS               , TRUE , TRUE ),
                                       D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(OUT_C_UNROLL                      , FALSE, TRUE ),
                                       X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.X.LO, KERNEL_SIZE.X.HI, TRUE , TRUE ),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.Y.LO, KERNEL_SIZE.Y.HI, TRUE , TRUE ),
                                       STRIDE    => STRIDE
                                   );
        constant  O_CHAN_SHAPE  :  IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE(
                                       ELEM_BITS => WORD_BITS,
                                       C         => NEW_IMAGE_SHAPE_SIDE_AUTO(ELEMENT_SIZE),
                                       D         => O_SHAPE.C,
                                       X         => NEW_IMAGE_SHAPE_SIDE_AUTO(ELEMENT_SIZE),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_AUTO(ELEMENT_SIZE)
                                   );
        signal    o_chan_data   :  std_logic_vector(O_CHAN_PARAM.DATA.SIZE-1 downto 0);
        signal    o_chan_valid  :  std_logic;
        signal    o_chan_ready  :  std_logic;
        signal    o_line_last   :  std_logic;
        signal    o_line_feed   :  std_logic;
        signal    o_line_return :  std_logic;
        signal    o_frame_last  :  std_logic;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    line_valid    :  std_logic_vector(        LINE_SIZE-1 downto 0);
        signal    line_atrb     :  IMAGE_STREAM_ATRB_VECTOR(LINE_SIZE-1 downto 0);
        signal    line_feed     :  std_logic_vector(        LINE_SIZE-1 downto 0);
        signal    line_return   :  std_logic_vector(        LINE_SIZE-1 downto 0);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    x_size        :  integer range 0 to ELEMENT_SIZE;
        signal    c_size        :  integer range 0 to ELEMENT_SIZE;
        signal    c_offset      :  integer range 0 to 2**BUF_ADDR_BITS;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    buf_wdata     :  std_logic_vector(BUF_LINE_SIZE*BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
        signal    buf_waddr     :  std_logic_vector(LINE_SIZE*BUF_ADDR_BITS-1 downto 0);
        signal    buf_we        :  std_logic_vector(LINE_SIZE              -1 downto 0);
        signal    buf_raddr     :  std_logic_vector(LINE_SIZE*BUF_ADDR_BITS-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK,RST) begin
            if (RST = '1') then
                    conv1x1_busy <= '0';
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    conv1x1_busy <= '0';
                elsif (conv1x1_start = '1') then
                    conv1x1_busy <= '1';
                elsif (conv1x1_busy = '1' and o_frame_last  = '1') then
                    conv1x1_busy <= '0';
                end if;
            end if;
        end process;
        conv1x1_done <= '1' when (conv1x1_busy = '1' and o_frame_last  = '1') else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        I_CHAN: IMAGE_STREAM_CHANNEL_REDUCER             -- 
            generic map (                                -- 
                I_PARAM         => INTAKE_STREAM_PARAM , -- 
                O_PARAM         => I_CHAN_PARAM          -- 
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 入力側 Stream I/F
            -----------------------------------------------------------------------
                I_DATA          => conv1x1_intake_data , -- In  :
                I_VALID         => conv1x1_intake_valid, -- In  :
                I_READY         => conv1x1_intake_ready, -- Out :
            -----------------------------------------------------------------------
            -- 出力側 Stream I/F
            -----------------------------------------------------------------------
                O_DATA          => i_chan_data         , -- Out :
                O_VALID         => i_chan_valid        , -- Out :
                O_READY         => i_chan_ready          -- In  :
            );                                           -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        BUF_INTAKE: IMAGE_STREAM_BUFFER_INTAKE           -- 
            generic map (                                -- 
                I_PARAM         => I_CHAN_PARAM        , -- 
                I_SHAPE         => I_SHAPE             , --
                ELEMENT_SIZE    => ELEMENT_SIZE        , --
                BANK_SIZE       => BANK_SIZE           , --
                LINE_SIZE       => LINE_SIZE           , --
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS*C_WORDS,--
                LINE_QUEUE      => 1                     --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 入力側 I/F
            -----------------------------------------------------------------------
                I_DATA          => i_chan_data         , -- In  :
                I_VALID         => i_chan_valid        , -- In  :
                I_READY         => i_chan_ready        , -- Out :
            -----------------------------------------------------------------------
            -- 出力側 I/F
            -----------------------------------------------------------------------
                O_LINE_VALID    => line_valid          , -- Out :
                O_X_SIZE        => x_size              , -- Out :
                O_C_SIZE        => c_size              , -- Out :
                O_C_OFFSET      => c_offset            , -- Out :
                O_LINE_ATRB     => line_atrb           , -- Out :
                O_LINE_FEED     => line_feed           , -- In  :
                O_LINE_RETURN   => line_return         , -- In  :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => buf_wdata           , -- Out :
                BUF_ADDR        => buf_waddr           , -- Out :
                BUF_WE          => buf_we                -- Out :
            );
        process (buf_waddr, conv1x1_busy) begin
            if (conv1x1_busy = '1') then
                for line  in 0 to LINE_SIZE-1 loop
                for c_pos in 0 to C_WORDS  -1 loop
                    conv1x1_buf_waddr((line*C_WORDS+c_pos+1)*BUF_ADDR_BITS-1 downto (line*C_WORDS+c_pos)*BUF_ADDR_BITS) <= buf_waddr((line+1)*BUF_ADDR_BITS-1 downto line*BUF_ADDR_BITS);
                end loop;
                end loop;
            else
                conv1x1_buf_waddr <= (others => '0');
            end if;
        end process;
        process (buf_we, conv1x1_busy) begin
            if (conv1x1_busy = '1') then
                for line  in 0 to LINE_SIZE-1 loop
                for c_pos in 0 to C_WORDS-1   loop
                    conv1x1_buf_we(line*C_WORDS+c_pos) <= buf_we(line);
                end loop;
                end loop;
            else
                conv1x1_buf_we <= (others => '0');
            end if;
        end process;
        conv1x1_buf_wdata <= buf_wdata when (conv1x1_busy = '1') else (others => '0');
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        BUF_OUTLET: IMAGE_STREAM_BUFFER_OUTLET           -- 
            generic map (                                -- 
                O_PARAM         => O_CHAN_PARAM        , --
                O_SHAPE         => O_CHAN_SHAPE        , --
                ELEMENT_SIZE    => ELEMENT_SIZE        , --
                BANK_SIZE       => BANK_SIZE           , --
                LINE_SIZE       => LINE_SIZE           , --
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS*C_WORDS,--
                BANK_QUEUE      => 2                   , --
                LINE_QUEUE      => 1                     --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 各種サイズ
            -----------------------------------------------------------------------
                X_SIZE          => x_size              , -- In  :
                D_SIZE          => OUT_C               , -- In  :
                C_SIZE          => c_size              , -- In  :
                C_OFFSET        => c_offset            , -- In  :
            -----------------------------------------------------------------------
            -- 入力側 I/F
            -----------------------------------------------------------------------
                I_LINE_VALID    => line_valid          , -- In  :
                I_LINE_ATRB     => line_atrb           , -- In  :
                I_LINE_FEED     => line_feed           , -- Out :
                I_LINE_RETURN   => line_return         , -- Out :
            -----------------------------------------------------------------------
            -- 出力側 I/F
            -----------------------------------------------------------------------
                O_DATA          => o_chan_data         , -- Out :
                O_VALID         => o_chan_valid        , -- Out :
                O_READY         => o_chan_ready        , -- In  :
                O_LAST          => o_frame_last        , -- In  :
                O_FEED          => o_line_feed         , -- In  :
                O_RETURN        => o_line_return       , -- In  :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => conv1x1_buf_rdata   , -- In  :
                BUF_ADDR        => buf_raddr             -- Out :
            );
        process (buf_raddr, conv1x1_busy) begin
            if (conv1x1_busy = '1') then
                for line  in 0 to LINE_SIZE-1 loop
                for c_pos in 0 to C_WORDS  -1 loop
                    conv1x1_buf_raddr((line*C_WORDS+c_pos+1)*BUF_ADDR_BITS-1 downto (line*C_WORDS+c_pos)*BUF_ADDR_BITS) <= buf_raddr((line+1)*BUF_ADDR_BITS-1 downto line*BUF_ADDR_BITS);
                end loop;
                end loop;
            else
                conv1x1_buf_raddr <= (others => '0');
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        o_line_last  <= '1' when (IMAGE_STREAM_DATA_IS_LAST_C(O_CHAN_PARAM, o_chan_data)) and
                                 (IMAGE_STREAM_DATA_IS_LAST_D(O_CHAN_PARAM, o_chan_data)) and
                                 (IMAGE_STREAM_DATA_IS_LAST_X(O_CHAN_PARAM, o_chan_data)) and
                                 (o_chan_valid = '1' and o_chan_ready = '1'             ) else '0';
        o_frame_last <= '1' when (o_line_last  = '1') and
                                 (IMAGE_STREAM_DATA_IS_LAST_Y(O_CHAN_PARAM, o_chan_data)) else '0';
        o_line_feed  <= '1' when (o_line_last  = '1') else '0';
        o_line_return<= '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv1x1_outlet_data <= CONVOLUTION_PIPELINE_FROM_IMAGE_STREAM(
                                    PIPELINE_PARAM => OUTLET_STREAM_PARAM,
                                    STREAM_PARAM   => O_CHAN_PARAM       ,
                                    KERNEL_SIZE    => KERNEL_SIZE        ,
                                    STRIDE         => STRIDE             ,
                                    STREAM_DATA    => o_chan_data
                                );
        conv1x1_outlet_valid <= o_chan_valid;
        o_chan_ready <= conv1x1_outlet_ready;
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_DATA  <= conv3x3_outlet_data when (conv3x3_busy = '1') else conv1x1_outlet_data;
    O_VALID <= '1' when (conv3x3_outlet_valid = '1' and conv3x3_busy = '1') or
                        (conv1x1_outlet_valid = '1' and conv1x1_busy = '1') else '0';
    conv3x3_outlet_ready <= '1' when (O_READY = '1' and conv3x3_busy = '1') else '0';
    conv1x1_outlet_ready <= '1' when (O_READY = '1' and conv1x1_busy = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF_L:  for line in 0 to BUF_LINE_SIZE-1 generate
        B:  for bank in 0 to BUF_BANK_SIZE-1 generate
                constant  RAM_ID :  integer := ID + (line*BUF_BANK_SIZE)+bank;
                signal    wdata  :  std_logic_vector(BUF_DATA_BITS-1 downto 0);
                signal    waddr  :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
                signal    we     :  std_logic_vector(BUF_WENA_BITS-1 downto 0);
                signal    rdata  :  std_logic_vector(BUF_DATA_BITS-1 downto 0);
                signal    raddr  :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
            begin
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            wdata <= conv3x3_buf_wdata((line*BUF_BANK_SIZE+bank+1)*BUF_DATA_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_DATA_BITS) or
                     conv1x1_buf_wdata((line*BUF_BANK_SIZE+bank+1)*BUF_DATA_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_DATA_BITS);
            waddr <= conv3x3_buf_waddr((line*BUF_BANK_SIZE+bank+1)*BUF_ADDR_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_ADDR_BITS) or
                     conv1x1_buf_waddr((line*BUF_BANK_SIZE+bank+1)*BUF_ADDR_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_ADDR_BITS);
            we    <= conv3x3_buf_we   ((line*BUF_BANK_SIZE+bank+1)*BUF_WENA_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_WENA_BITS) or
                     conv1x1_buf_we   ((line*BUF_BANK_SIZE+bank+1)*BUF_WENA_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_WENA_BITS);
            raddr <= conv3x3_buf_raddr((line*BUF_BANK_SIZE+bank+1)*BUF_ADDR_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_ADDR_BITS) or
                     conv1x1_buf_raddr((line*BUF_BANK_SIZE+bank+1)*BUF_ADDR_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_ADDR_BITS);
            conv3x3_buf_rdata((line*BUF_BANK_SIZE+bank+1)*BUF_DATA_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_DATA_BITS) <= rdata;
            conv1x1_buf_rdata((line*BUF_BANK_SIZE+bank+1)*BUF_DATA_BITS-1 downto (line*BUF_BANK_SIZE+bank)*BUF_DATA_BITS) <= rdata;
            -----------------------------------------------------------------------
            --
            -----------------------------------------------------------------------
            RAM: SDPRAM                   -- 
                generic map (             -- 
                    DEPTH   => BUF_DEPTH, -- メモリの深さ(ビット単位)を2のべき乗値で指定する.
                    RWIDTH  => BUF_WIDTH, -- リードデータ(RDATA)の幅(ビット数)を2のべき乗値で指定する.
                    WWIDTH  => BUF_WIDTH, -- ライトデータ(WDATA)の幅(ビット数)を2のべき乗値で指定する.
                    WEBIT   => 0        , -- ライトイネーブル信号(WE)の幅(ビット数)を2のべき乗値で指定する.
                    ID      => RAM_ID     -- どのモジュールで使われているかを示す識別番号.
                )                         -- 
                port map (                -- 
                    WCLK    => CLK      , -- In  :
                    WE      => we       , -- In  : 
                    WADDR   => waddr    , -- In  : 
                    WDATA   => wdata    , -- In  : 
                    RCLK    => CLK      , -- In  :
                    RADDR   => raddr    , -- In  :
                    RDATA   => rdata      -- Out :
                );                        -- 
        end generate;
    end generate;
end RTL;
