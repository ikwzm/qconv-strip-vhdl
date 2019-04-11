-----------------------------------------------------------------------------------
--!     @file    qconv_strip_k_data_buffer.vhd
--!     @brief   Quantized Convolution (strip) Kernel Weight Data Buffer Module
--!     @version 0.1.0
--!     @date    2019/4/11
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
entity  QCONV_STRIP_K_DATA_BUFFER is
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
end QCONV_STRIP_K_DATA_BUFFER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.SDPRAM;
use     PIPEWORK.COMPONENTS.PIPELINE_REGISTER;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.CONVOLUTION_TYPES.all;
use     PIPEWORK.CONVOLUTION_COMPONENTS.CONVOLUTION_PARAMETER_BUFFER_WRITER;
use     PIPEWORK.CONVOLUTION_COMPONENTS.CONVOLUTION_PARAMETER_BUFFER_READER;
architecture RTL of QCONV_STRIP_K_DATA_BUFFER is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  WORD_BITS             :  integer := QCONV_PARAM.NBITS_K_DATA * QCONV_PARAM.NBITS_PER_WORD;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  BUF_KERN_SIZE         :  integer := 3*3;
    constant  BUF_BANK_SIZE         :  integer := BUF_KERN_SIZE*IN_C_UNROLL*OUT_C_UNROLL;
    -------------------------------------------------------------------------------
    -- BUF_WIDTH : メモリのビット幅を２のべき乗値で示す
    -------------------------------------------------------------------------------
    function  CALC_BUF_WIDTH    return integer is
        variable width              :  integer;
    begin
        width := 0;
        while (2**width < (WORD_BITS)) loop
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
        size  := (size + (BUF_BANK_SIZE - 1))/BUF_BANK_SIZE;
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
    constant  BUF_SIZE_BITS         :  integer := BUF_ADDR_BITS + 1;
    signal    conv3x3_buf_wdata     :  std_logic_vector(BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv3x3_buf_waddr     :  std_logic_vector(BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    conv3x3_buf_we        :  std_logic_vector(BUF_BANK_SIZE*BUF_WENA_BITS-1 downto 0);
    signal    conv3x3_buf_rdata     :  std_logic_vector(BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv3x3_buf_raddr     :  std_logic_vector(BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    conv1x1_buf_wdata     :  std_logic_vector(BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv1x1_buf_waddr     :  std_logic_vector(BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    conv1x1_buf_we        :  std_logic_vector(BUF_BANK_SIZE*BUF_WENA_BITS-1 downto 0);
    signal    conv1x1_buf_rdata     :  std_logic_vector(BUF_BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    conv1x1_buf_raddr     :  std_logic_vector(BUF_BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  CONV_BUF_INFO(DATA: std_logic_vector; O_SIZE,I_SIZE, BITS: integer) return std_logic_vector is
        alias     i_data            :  std_logic_vector(I_SIZE*OUT_C_UNROLL*IN_C_UNROLL*BITS-1 downto 0) is DATA;
        variable  o_data            :  std_logic_vector(O_SIZE*OUT_C_UNROLL*IN_C_UNROLL*BITS-1 downto 0);
    begin
        for o_pos in 0 to O_SIZE-1       loop
        for d_pos in 0 to OUT_C_UNROLL-1 loop
        for c_pos in 0 to IN_C_UNROLL -1 loop
            if (o_pos <= I_SIZE-1) then
                o_data(((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                       ((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         )
                :=
                i_data(((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                       ((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         );
            else
                o_data(((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                       ((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         )
                :=    (((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                       ((o_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         => '0');
            end if;
        end loop;
        end loop;
        end loop;
        return o_data;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  IO_SHAPE              :  IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE(
                                           ELEM_BITS => WORD_BITS,
                                           C         => I_SHAPE.C,
                                           D         => O_SHAPE.C,
                                           X         => O_SHAPE.X,
                                           Y         => O_SHAPE.Y
                                       );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE            is (IDLE_STATE,RES_STATE,
                                        CONV3x3_WR_REQ_STATE,
                                        CONV3x3_WR_RES_STATE,
                                        CONV3x3_RD_REQ_STATE,
                                        CONV3x3_RD_RES_STATE,
                                        CONV1x1_WR_REQ_STATE,
                                        CONV1x1_WR_RES_STATE,
                                        CONV1x1_RD_REQ_STATE,
                                        CONV1x1_RD_RES_STATE);
    signal    state                 :  STATE_TYPE;
    signal    wr_rd                 :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    conv3x3_wr_req_valid  :  std_logic;
    signal    conv3x3_wr_req_ready  :  std_logic;
    signal    conv3x3_wr_res_valid  :  std_logic;
    signal    conv3x3_wr_res_ready  :  std_logic;
    signal    conv3x3_wr_busy       :  std_logic;
    signal    conv3x3_rd_req_valid  :  std_logic;
    signal    conv3x3_rd_req_ready  :  std_logic;
    signal    conv3x3_rd_res_valid  :  std_logic;
    signal    conv3x3_rd_res_ready  :  std_logic;
    signal    conv3x3_rd_busy       :  std_logic;
    signal    conv3x3_i_data        :  std_logic_vector(WORD_BITS-1 downto 0);
    signal    conv3x3_i_valid       :  std_logic;
    signal    conv3x3_i_ready       :  std_logic;
    signal    conv3x3_o_data        :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    signal    conv3x3_o_valid       :  std_logic;
    signal    conv3x3_o_ready       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    conv1x1_wr_req_valid  :  std_logic;
    signal    conv1x1_wr_req_ready  :  std_logic;
    signal    conv1x1_wr_res_valid  :  std_logic;
    signal    conv1x1_wr_res_ready  :  std_logic;
    signal    conv1x1_wr_busy       :  std_logic;
    signal    conv1x1_rd_req_valid  :  std_logic;
    signal    conv1x1_rd_req_ready  :  std_logic;
    signal    conv1x1_rd_res_valid  :  std_logic;
    signal    conv1x1_rd_res_ready  :  std_logic;
    signal    conv1x1_rd_busy       :  std_logic;
    signal    conv1x1_i_data        :  std_logic_vector(WORD_BITS-1 downto 0);
    signal    conv1x1_i_valid       :  std_logic;
    signal    conv1x1_i_ready       :  std_logic;
    signal    conv1x1_o_data        :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    signal    conv1x1_o_valid       :  std_logic;
    signal    conv1x1_o_ready       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    output_data           :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    signal    output_valid          :  std_logic;
    signal    output_ready          :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- メインシーケンサ
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                state <= IDLE_STATE;
                wr_rd <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                state <= IDLE_STATE;
                wr_rd <= '0';
            else
                case state is
                    when IDLE_STATE =>
                        if    (REQ_VALID = '1' and K3x3  = '1' and REQ_WRITE = '1') then
                            state <= CONV3x3_WR_REQ_STATE;
                            wr_rd <= REQ_READ;
                        elsif (REQ_VALID = '1' and K3x3  = '1' and REQ_READ  = '1') then
                            state <= CONV3x3_RD_REQ_STATE;
                            wr_rd <= '0';
                        elsif (REQ_VALID = '1' and K3x3 /= '1' and REQ_WRITE = '1') then
                            state <= CONV1x1_WR_REQ_STATE;
                            wr_rd <= REQ_READ;
                        elsif (REQ_VALID = '1' and K3x3 /= '1' and REQ_READ  = '1') then
                            state <= CONV1x1_RD_REQ_STATE;
                            wr_rd <= '0';
                        elsif (REQ_VALID = '1') then
                            state <= RES_STATE;
                            wr_rd <= '0';
                        else
                            state <= IDLE_STATE;
                        end if;
                    when CONV3x3_WR_REQ_STATE =>
                        if (conv3x3_wr_req_ready = '1') then
                            state <= CONV3x3_WR_RES_STATE;
                        else
                            state <= CONV3x3_WR_REQ_STATE;
                        end if;
                    when CONV3x3_WR_RES_STATE =>
                        if    (conv3x3_wr_res_valid = '1' and wr_rd = '1') then
                            state <= CONV3x3_RD_REQ_STATE;
                        elsif (conv3x3_wr_res_valid = '1' and wr_rd = '0') then
                            state <= RES_STATE;
                        else
                            state <= CONV3x3_WR_RES_STATE;
                        end if;
                    when CONV3x3_RD_REQ_STATE =>
                        if (conv3x3_rd_req_ready = '1') then
                            state <= CONV3x3_RD_RES_STATE;
                        else
                            state <= CONV3x3_RD_REQ_STATE;
                        end if;
                    when CONV3x3_RD_RES_STATE =>
                        if    (conv3x3_rd_res_valid = '1') then
                            state <= RES_STATE;
                        else
                            state <= CONV3x3_RD_RES_STATE;
                        end if;
                    when CONV1x1_WR_REQ_STATE =>
                        if (conv1x1_wr_req_ready = '1') then
                            state <= CONV1x1_WR_RES_STATE;
                        else
                            state <= CONV1x1_WR_REQ_STATE;
                        end if;
                    when CONV1x1_WR_RES_STATE =>
                        if    (conv1x1_wr_res_valid = '1' and wr_rd = '1') then
                            state <= CONV1x1_RD_REQ_STATE;
                        elsif (conv1x1_wr_res_valid = '1' and wr_rd = '0') then
                            state <= RES_STATE;
                        else
                            state <= CONV1x1_WR_RES_STATE;
                        end if;
                    when CONV1x1_RD_REQ_STATE =>
                        if (conv1x1_rd_req_ready = '1') then
                            state <= CONV1x1_RD_RES_STATE;
                        else
                            state <= CONV1x1_RD_REQ_STATE;
                        end if;
                    when CONV1x1_RD_RES_STATE =>
                        if    (conv1x1_rd_res_valid = '1') then
                            state <= RES_STATE;
                        else
                            state <= CONV1x1_RD_RES_STATE;
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
    REQ_READY <= '1' when (state = IDLE_STATE) else '0';
    RES_VALID <= '1' when (state = RES_STATE ) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    conv3x3_wr_req_valid <= '1' when (state = CONV3x3_WR_REQ_STATE) else '0';
    conv3x3_wr_res_ready <= '1' when (state = CONV3x3_WR_RES_STATE) else '0';
    conv3x3_rd_req_valid <= '1' when (state = CONV3x3_RD_REQ_STATE) else '0';
    conv3x3_rd_res_ready <= '1' when (state = CONV3x3_RD_RES_STATE) else '0';
    conv1x1_wr_req_valid <= '1' when (state = CONV1x1_WR_REQ_STATE) else '0';
    conv1x1_wr_res_ready <= '1' when (state = CONV1x1_WR_RES_STATE) else '0';
    conv1x1_rd_req_valid <= '1' when (state = CONV1x1_RD_REQ_STATE) else '0';
    conv1x1_rd_res_ready <= '1' when (state = CONV1x1_RD_RES_STATE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    conv3x3_i_data  <= I_DATA;
    conv1x1_i_data  <= I_DATA;
    conv3x3_i_valid <= '1' when (I_VALID = '1' and state = CONV3x3_WR_RES_STATE) else '0';
    conv1x1_i_valid <= '1' when (I_VALID = '1' and state = CONV1x1_WR_RES_STATE) else '0';
    I_READY <= '1' when (conv3x3_i_ready = '1' and state = CONV3x3_WR_RES_STATE) or
                        (conv1x1_i_ready = '1' and state = CONV1x1_WR_RES_STATE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CONV3x3: block
        constant  KERNEL_SIZE   :  CONVOLUTION_KERNEL_SIZE_TYPE := CONVOLUTION_KERNEL_SIZE_3x3;
        constant  BUF_PARAM     :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD             ,
                                       C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(IN_C_UNROLL                      ),
                                       D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(OUT_C_UNROLL                     ),
                                       X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.X.LO,KERNEL_SIZE.X.HI),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.Y.LO,KERNEL_SIZE.Y.HI)
                                   );
        constant  buf_wready    :  std_logic := '1';
        signal    rd_req_addr   :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
        signal    wr_res_addr   :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
        signal    wr_res_size   :  std_logic_vector(BUF_SIZE_BITS-1 downto 0);
        signal    buf_out_data  :  std_logic_vector(BUF_PARAM.DATA.SIZE-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        -- WRITER
        ---------------------------------------------------------------------------
        WR: CONVOLUTION_PARAMETER_BUFFER_WRITER          -- 
            generic map (                                -- 
                PARAM           => BUF_PARAM           , --
                SHAPE           => IO_SHAPE            , --
                BANK_SIZE       => BUF_BANK_SIZE       , --
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS         --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 制御 I/F
            -----------------------------------------------------------------------
                REQ_VALID       => conv3x3_wr_req_valid, -- In  :
                REQ_READY       => conv3x3_wr_req_ready, -- out :
                C_SIZE          => IN_C_BY_WORD        , -- In  :
                D_SIZE          => OUT_C               , -- In  :
                RES_VALID       => conv3x3_wr_res_valid, -- Out :
                RES_READY       => conv3x3_wr_res_ready, -- In  :
                RES_ADDR        => wr_res_addr         , -- Out :
                RES_SIZE        => wr_res_size         , -- Out :
                BUSY            => conv3x3_wr_busy     , -- Out :
            -----------------------------------------------------------------------
            -- 入力 I/F
            -----------------------------------------------------------------------
                I_DATA          => conv3x3_i_data      , -- In  :
                I_VALID         => conv3x3_i_valid     , -- In  :
                I_READY         => conv3x3_i_ready     , -- Out :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => conv3x3_buf_wdata   , -- Out :
                BUF_ADDR        => conv3x3_buf_waddr   , -- Out :
                BUF_WE          => conv3x3_buf_we      , -- Out :
                BUF_PUSH        => open                , -- Out :
                BUF_READY       => buf_wready            -- In  :
            );                                           --  
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    rd_req_addr <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    rd_req_addr <= (others => '0');
                elsif (conv3x3_wr_res_valid = '1' and conv3x3_wr_res_ready = '1') then
                    rd_req_addr <= wr_res_addr;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- READER
        ---------------------------------------------------------------------------
        RD: CONVOLUTION_PARAMETER_BUFFER_READER          -- 
            generic map (                                -- 
                PARAM           => BUF_PARAM           , -- 
                SHAPE           => IO_SHAPE            , --
                BANK_SIZE       => BUF_BANK_SIZE       , -- 
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS         --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 制御 I/F
            -----------------------------------------------------------------------
                REQ_VALID       => conv3x3_rd_req_valid, -- In  :
                REQ_READY       => conv3x3_rd_req_ready, -- out :
                REQ_ADDR        => rd_req_addr         , -- In  :
                REQ_ADDR_LOAD   => wr_rd               , -- In  :
                C_SIZE          => IN_C_BY_WORD        , -- In  :
                D_SIZE          => OUT_C               , -- In  :
                X_SIZE          => OUT_W               , -- In  :
                Y_SIZE          => OUT_H               , -- In  :
                RES_VALID       => conv3x3_rd_res_valid, -- Out :
                RES_READY       => conv3x3_rd_res_ready, -- In  :
                BUSY            => conv3x3_rd_busy     , -- Out :
            -----------------------------------------------------------------------
            -- 出力側 I/F
            -----------------------------------------------------------------------
                O_DATA          => buf_out_data        , -- Out :
                O_VALID         => conv3x3_o_valid     , -- Out :
                O_READY         => conv3x3_o_ready     , -- In  :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => conv3x3_buf_rdata   , -- In  :
                BUF_ADDR        => conv3x3_buf_raddr     -- Out :
            );                                           -- 
        ---------------------------------------------------------------------------
        -- conv3x3_o_data
        ---------------------------------------------------------------------------
        conv3x3_o_data <= CONVOLUTION_PIPELINE_FROM_WEIGHT_STREAM(O_PARAM, BUF_PARAM, KERNEL_SIZE, buf_out_data);
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    CONV1x1: block
        constant  KERNEL_SIZE   :  CONVOLUTION_KERNEL_SIZE_TYPE := CONVOLUTION_KERNEL_SIZE_1x1;
        constant  KERN_SIZE     :  integer  := 8;
        constant  BUF_PARAM     :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD,
                                       C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(IN_C_UNROLL*KERN_SIZE            ),
                                       D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(OUT_C_UNROLL                     ),
                                       X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.X.LO,KERNEL_SIZE.X.HI),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.Y.LO,KERNEL_SIZE.Y.HI)
                                   );
        constant  BANK_SIZE     :  integer  := KERN_SIZE*IN_C_UNROLL*OUT_C_UNROLL;
        signal    buf_wdata     :  std_logic_vector(BANK_SIZE*BUF_DATA_BITS-1 downto 0);
        signal    buf_waddr     :  std_logic_vector(BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
        signal    buf_we        :  std_logic_vector(BANK_SIZE*BUF_WENA_BITS-1 downto 0);
        signal    buf_rdata     :  std_logic_vector(BANK_SIZE*BUF_DATA_BITS-1 downto 0);
        signal    buf_raddr     :  std_logic_vector(BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
        constant  buf_wready    :  std_logic := '1';
        signal    rd_req_addr   :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
        signal    wr_res_addr   :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
        signal    wr_res_size   :  std_logic_vector(BUF_SIZE_BITS  -1 downto 0);
        signal    buf_out_data  :  std_logic_vector(BUF_PARAM.DATA.SIZE-1 downto 0);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        function  TO_BUF_INFO(DATA: std_logic_vector; BITS: integer) return std_logic_vector is
            alias     i_data    :  std_logic_vector(    KERN_SIZE*OUT_C_UNROLL*IN_C_UNROLL*BITS-1 downto 0) is DATA;
            variable  o_data    :  std_logic_vector(BUF_KERN_SIZE*OUT_C_UNROLL*IN_C_UNROLL*BITS-1 downto 0);
        begin
            for k_pos in 0 to BUF_KERN_SIZE-1 loop
            for d_pos in 0 to OUT_C_UNROLL -1 loop
            for c_pos in 0 to IN_C_UNROLL  -1 loop
                if (k_pos < KERN_SIZE) then
                    o_data(((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                           ((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         )
                    :=
                    i_data(((d_pos*KERN_SIZE*IN_C_UNROLL   ) + (k_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                           ((d_pos*KERN_SIZE*IN_C_UNROLL   ) + (k_pos*IN_C_UNROLL) + c_pos    )*BITS         );
                else
                    o_data(((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                           ((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         )
                    :=    (((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                           ((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         => '0');
                end if;
            end loop;
            end loop;
            end loop;
            return o_data;
        end function;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        function  FROM_BUF_INFO(DATA: std_logic_vector; BITS: integer) return std_logic_vector is
            alias     i_data    :  std_logic_vector(BUF_KERN_SIZE*OUT_C_UNROLL*IN_C_UNROLL*BITS-1 downto 0) is DATA;
            variable  o_data    :  std_logic_vector(    KERN_SIZE*OUT_C_UNROLL*IN_C_UNROLL*BITS-1 downto 0);
        begin
            for k_pos in 0 to KERN_SIZE    -1 loop
            for d_pos in 0 to OUT_C_UNROLL -1 loop
            for c_pos in 0 to IN_C_UNROLL  -1 loop
                    o_data(((d_pos*KERN_SIZE*IN_C_UNROLL   ) + (k_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                           ((d_pos*KERN_SIZE*IN_C_UNROLL   ) + (k_pos*IN_C_UNROLL) + c_pos    )*BITS         )
                    :=
                    i_data(((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos + 1)*BITS-1 downto
                           ((k_pos*OUT_C_UNROLL*IN_C_UNROLL) + (d_pos*IN_C_UNROLL) + c_pos    )*BITS         );
            end loop;
            end loop;
            end loop;
            return o_data;
        end function;
    begin
        ---------------------------------------------------------------------------
        -- WRITER
        ---------------------------------------------------------------------------
        WR: CONVOLUTION_PARAMETER_BUFFER_WRITER          -- 
            generic map (                                -- 
                PARAM           => BUF_PARAM           , --
                SHAPE           => IO_SHAPE            , --
                BANK_SIZE       => BANK_SIZE           , --
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS         --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 制御 I/F
            -----------------------------------------------------------------------
                REQ_VALID       => conv1x1_wr_req_valid, -- In  :
                REQ_READY       => conv1x1_wr_req_ready, -- out :
                C_SIZE          => IN_C_BY_WORD        , -- In  :
                D_SIZE          => OUT_C               , -- In  :
                RES_VALID       => conv1x1_wr_res_valid, -- Out :
                RES_READY       => conv1x1_wr_res_ready, -- In  :
                RES_ADDR        => wr_res_addr         , -- Out :
                RES_SIZE        => wr_res_size         , -- Out :
                BUSY            => conv1x1_wr_busy     , -- Out :
            -----------------------------------------------------------------------
            -- 入力 I/F
            -----------------------------------------------------------------------
                I_DATA          => conv1x1_i_data      , -- In  :
                I_VALID         => conv1x1_i_valid     , -- In  :
                I_READY         => conv1x1_i_ready     , -- Out :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => buf_wdata           , -- Out :
                BUF_ADDR        => buf_waddr           , -- Out :
                BUF_WE          => buf_we              , -- Out :
                BUF_PUSH        => open                , -- Out :
                BUF_READY       => buf_wready            -- In  :
            );                                           --  
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    rd_req_addr <= (others => '0');
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    rd_req_addr <= (others => '0');
                elsif (conv1x1_wr_res_valid = '1' and conv1x1_wr_res_ready = '1') then
                    rd_req_addr <= wr_res_addr;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        -- READER
        ---------------------------------------------------------------------------
        RD: CONVOLUTION_PARAMETER_BUFFER_READER          -- 
            generic map (                                -- 
                PARAM           => BUF_PARAM           , -- 
                SHAPE           => IO_SHAPE            , --
                BANK_SIZE       => BANK_SIZE           , -- 
                BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
                BUF_DATA_BITS   => BUF_DATA_BITS         --
            )                                            -- 
            port map (                                   -- 
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK             => CLK                 , -- In  :
                RST             => RST                 , -- In  :
                CLR             => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 制御 I/F
            -----------------------------------------------------------------------
                REQ_VALID       => conv1x1_rd_req_valid, -- In  :
                REQ_READY       => conv1x1_rd_req_ready, -- Out :
                REQ_ADDR        => rd_req_addr         , -- In  :
                REQ_ADDR_LOAD   => wr_rd               , -- In  :
                C_SIZE          => IN_C_BY_WORD        , -- In  :
                D_SIZE          => OUT_C               , -- In  :
                X_SIZE          => OUT_W               , -- In  :
                Y_SIZE          => OUT_H               , -- In  :
                RES_VALID       => conv1x1_rd_res_valid, -- Out :
                RES_READY       => conv1x1_rd_res_ready, -- In  :
                BUSY            => conv1x1_rd_busy     , -- Out :
            -----------------------------------------------------------------------
            -- 出力側 I/F
            -----------------------------------------------------------------------
                O_DATA          => buf_out_data        , -- Out :
                O_VALID         => conv1x1_o_valid     , -- Out :
                O_READY         => conv1x1_o_ready     , -- In  :
            -----------------------------------------------------------------------
            -- バッファメモリ I/F
            -----------------------------------------------------------------------
                BUF_DATA        => buf_rdata           , -- In  :
                BUF_ADDR        => buf_raddr             -- Out :
            );                                           -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv1x1_buf_wdata <= TO_BUF_INFO(buf_wdata, BUF_DATA_BITS);
        conv1x1_buf_waddr <= TO_BUF_INFO(buf_waddr, BUF_ADDR_BITS);
        conv1x1_buf_we    <= TO_BUF_INFO(buf_we   , BUF_WENA_BITS);
        conv1x1_buf_raddr <= TO_BUF_INFO(buf_raddr, BUF_ADDR_BITS);
        buf_rdata <= FROM_BUF_INFO(conv1x1_buf_rdata, BUF_DATA_BITS);
        ---------------------------------------------------------------------------
        -- conv1x1_o_data
        ---------------------------------------------------------------------------
        conv1x1_o_data <= CONVOLUTION_PIPELINE_FROM_WEIGHT_STREAM(O_PARAM, BUF_PARAM, KERNEL_SIZE, buf_out_data);
    end block;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    output_data     <= conv3x3_o_data when (state = CONV3x3_RD_RES_STATE) else conv1x1_o_data;
    output_valid    <= '1' when (conv3x3_o_valid = '1' and state = CONV3x3_RD_RES_STATE) or
                                (conv1x1_o_valid = '1' and state = CONV1x1_RD_RES_STATE) else '0';
    conv3x3_o_ready <= '1' when (output_ready    = '1' and state = CONV3x3_RD_RES_STATE) else '0';
    conv1x1_o_ready <= '1' when (output_ready    = '1' and state = CONV1x1_RD_RES_STATE) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF: for bank in 0 to BUF_BANK_SIZE-1 generate
        constant  RAM_ID :  integer := ID + bank;
        signal    wdata  :  std_logic_vector(BUF_DATA_BITS-1 downto 0);
        signal    waddr  :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
        signal    we     :  std_logic_vector(BUF_WENA_BITS-1 downto 0);
        signal    rdata  :  std_logic_vector(BUF_DATA_BITS-1 downto 0);
        signal    raddr  :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        wdata <= conv3x3_buf_wdata((bank+1)*BUF_DATA_BITS-1 downto (bank)*BUF_DATA_BITS) or
                 conv1x1_buf_wdata((bank+1)*BUF_DATA_BITS-1 downto (bank)*BUF_DATA_BITS);
        waddr <= conv3x3_buf_waddr((bank+1)*BUF_ADDR_BITS-1 downto (bank)*BUF_ADDR_BITS) or
                 conv1x1_buf_waddr((bank+1)*BUF_ADDR_BITS-1 downto (bank)*BUF_ADDR_BITS);
        we    <= conv3x3_buf_we   ((bank+1)*BUF_WENA_BITS-1 downto (bank)*BUF_WENA_BITS) or
                 conv1x1_buf_we   ((bank+1)*BUF_WENA_BITS-1 downto (bank)*BUF_WENA_BITS);
        raddr <= conv3x3_buf_raddr((bank+1)*BUF_ADDR_BITS-1 downto (bank)*BUF_ADDR_BITS) or
                 conv1x1_buf_raddr((bank+1)*BUF_ADDR_BITS-1 downto (bank)*BUF_ADDR_BITS);
        conv3x3_buf_rdata((bank+1)*BUF_DATA_BITS-1 downto (bank)*BUF_DATA_BITS) <= rdata;
        conv1x1_buf_rdata((bank+1)*BUF_DATA_BITS-1 downto (bank)*BUF_DATA_BITS) <= rdata;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
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
    -------------------------------------------------------------------------------
    -- パイプラインレジスタ
    -------------------------------------------------------------------------------
    QUEUE: PIPELINE_REGISTER                   -- 
        generic map (                          -- 
            QUEUE_SIZE  => QUEUE_SIZE        , --
            WORD_BITS   => O_PARAM.DATA.SIZE   -- 
        )                                      -- 
        port map (                             -- 
            CLK         => CLK               , -- In  :
            RST         => RST               , -- In  :
            CLR         => CLR               , -- In  :
            I_WORD      => output_data       , -- In  :
            I_VAL       => output_valid      , -- In  :
            I_RDY       => output_ready      , -- Out :
            Q_WORD      => O_DATA            , -- Out :
            Q_VAL       => O_VALID           , -- Out :
            Q_RDY       => O_READY           , -- In  :
            BUSY        => open                -- Out :
        );                                     -- 
end RTL;
