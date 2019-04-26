-----------------------------------------------------------------------------------
--!     @file    qconv_strip_core.vhd
--!     @brief   Quantized Convolution (strip) Core Module
--!     @version 0.1.0
--!     @date    2019/4/25
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
entity  QCONV_STRIP_CORE is
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
                          in  std_logic;
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
                          out std_logic_vector(OUT_DATA_BITS-1 downto 0);
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
end QCONV_STRIP_CORE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
use     QCONV.QCONV_COMPONENTS.QCONV_MULTIPLIER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_IN_DATA_BUFFER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_TH_DATA_BUFFER;
use     QCONV.QCONV_COMPONENTS.QCONV_STRIP_K_DATA_BUFFER;
use     QCONV.QCONV_COMPONENTS.QCONV_APPLY_THRESHOLDS;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_CHANNEL_REDUCER;
use     PIPEWORK.CONVOLUTION_TYPES.all;
use     PIPEWORK.CONVOLUTION_COMPONENTS.CONVOLUTION_INT_ADDER_TREE;
use     PIPEWORK.CONVOLUTION_COMPONENTS.CONVOLUTION_INT_ACCUMULATOR;
architecture RTL of QCONV_STRIP_CORE is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      REQ_ARGS_TYPE         is record
              in_c_by_word          :  integer range 0 to QCONV_PARAM.MAX_IN_C_BY_WORD;
              in_w                  :  integer range 0 to QCONV_PARAM.MAX_IN_W;
              in_h                  :  integer range 0 to QCONV_PARAM.MAX_IN_H;
              out_c                 :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
              out_w                 :  integer range 0 to QCONV_PARAM.MAX_OUT_W;
              out_h                 :  integer range 0 to QCONV_PARAM.MAX_OUT_H;
              left_pad_size         :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
              right_pad_size        :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
              top_pad_size          :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
              bottom_pad_size       :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
              k3x3                  :  std_logic;
              use_th                :  std_logic;
              param_in              :  std_logic;
    end record;
    constant  REQ_ARGS_NULL         :  REQ_ARGS_TYPE := (
              in_c_by_word          =>  0 ,
              in_w                  =>  0 ,
              in_h                  =>  0 ,
              out_c                 =>  0 ,
              out_w                 =>  0 ,
              out_h                 =>  0 ,
              left_pad_size         =>  0 ,
              right_pad_size        =>  0 ,
              top_pad_size          =>  0 ,
              bottom_pad_size       =>  0 ,
              k3x3                  => '0',
              use_th                => '0',
              param_in              => '0'
    );
    signal    req_args              :  REQ_ARGS_TYPE;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      PARAM_TYPE            is record
              IN_SHAPE              :  IMAGE_SHAPE_TYPE;
              OUT_SHAPE             :  IMAGE_SHAPE_TYPE;
              IN_DATA_STREAM        :  IMAGE_STREAM_PARAM_TYPE;
              K_DATA_STREAM         :  IMAGE_STREAM_PARAM_TYPE;
              THRESHOLDS_STREAM     :  IMAGE_STREAM_PARAM_TYPE;
              BIAS_STREAM           :  IMAGE_STREAM_PARAM_TYPE;
              MUL_STREAM            :  IMAGE_STREAM_PARAM_TYPE;
              ADD_STREAM            :  IMAGE_STREAM_PARAM_TYPE;
              ACC_STREAM            :  IMAGE_STREAM_PARAM_TYPE;
              PASS_TH_I_STREAM      :  IMAGE_STREAM_PARAM_TYPE;
              PASS_TH_Q_STREAM      :  IMAGE_STREAM_PARAM_TYPE;
              APPLY_TH_I_STREAM     :  IMAGE_STREAM_PARAM_TYPE;
              APPLY_TH_O_STREAM     :  IMAGE_STREAM_PARAM_TYPE;
              APPLY_TH_D_STREAM     :  IMAGE_STREAM_PARAM_TYPE;
              APPLY_TH_Q_STREAM     :  IMAGE_STREAM_PARAM_TYPE;
    end record;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  NEW_PARAM         return PARAM_TYPE is
        variable  param                     :  PARAM_TYPE;
        variable  stream_shape_in_c_by_word :  IMAGE_SHAPE_SIDE_TYPE;
        variable  stream_shape_in_c         :  IMAGE_SHAPE_SIDE_TYPE;
        variable  stream_shape_out_c        :  IMAGE_SHAPE_SIDE_TYPE;
        variable  stream_shape_x            :  IMAGE_SHAPE_SIDE_TYPE;
        variable  stream_shape_y            :  IMAGE_SHAPE_SIDE_TYPE;
        constant  pass_th_q_words           :  integer := OUT_DATA_BITS / QCONV_PARAM.NBITS_OUT_DATA;
        constant  apply_th_q_words          :  integer := OUT_DATA_BITS / QCONV_PARAM.NBITS_IN_DATA ;
    begin
        stream_shape_in_c_by_word := NEW_IMAGE_SHAPE_SIDE_CONSTANT(9*IN_C_UNROLL                           , TRUE, TRUE);
        stream_shape_in_c         := NEW_IMAGE_SHAPE_SIDE_CONSTANT(9*IN_C_UNROLL*QCONV_PARAM.NBITS_PER_WORD, TRUE, TRUE);
        stream_shape_out_c        := NEW_IMAGE_SHAPE_SIDE_CONSTANT(OUT_C_UNROLL, TRUE, TRUE);
        stream_shape_x            := NEW_IMAGE_SHAPE_SIDE_CONSTANT(1           , TRUE, TRUE);
        stream_shape_y            := NEW_IMAGE_SHAPE_SIDE_CONSTANT(1           , TRUE, TRUE);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.IN_DATA_STREAM        := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA*QCONV_PARAM.NBITS_PER_WORD,
                                          C         => stream_shape_in_c_by_word,
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.K_DATA_STREAM        := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_K_DATA*QCONV_PARAM.NBITS_PER_WORD,
                                          C         => stream_shape_in_c_by_word,
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.THRESHOLDS_STREAM    := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NUM_THRESHOLDS * QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, TRUE, TRUE),
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.BIAS_STREAM          := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, TRUE, TRUE),
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.MUL_STREAM           := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA + 1,
                                          C         => stream_shape_in_c,
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.ADD_STREAM           := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, TRUE, TRUE),
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.ACC_STREAM           := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, TRUE, TRUE),
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.PASS_TH_I_STREAM     := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => stream_shape_out_c,
                                          D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, FALSE, FALSE),
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.PASS_TH_Q_STREAM     := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(pass_th_q_words ,TRUE,TRUE),
                                          D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, FALSE, FALSE),
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.APPLY_TH_I_STREAM     := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, TRUE, TRUE),
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.APPLY_TH_O_STREAM     := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, TRUE, TRUE),
                                          D         => stream_shape_out_c,
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.APPLY_TH_D_STREAM     := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA,
                                          C         => stream_shape_out_c,
                                          D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, FALSE, FALSE),
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.APPLY_TH_Q_STREAM     := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA,
                                          C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(apply_th_q_words,TRUE,TRUE),
                                          D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1, FALSE, FALSE),
                                          X         => stream_shape_x,
                                          Y         => stream_shape_y
                                      );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.IN_SHAPE  := NEW_IMAGE_SHAPE_EXTERNAL(
                               ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA,
                               C         => QCONV_PARAM.MAX_IN_C_BY_WORD,
                               X         => QCONV_PARAM.MAX_IN_W + 2,
                               Y         => QCONV_PARAM.MAX_IN_H + 2
                           );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.OUT_SHAPE := NEW_IMAGE_SHAPE_EXTERNAL(
                               ELEM_BITS => QCONV_PARAM.NBITS_IN_DATA,
                               C         => QCONV_PARAM.MAX_OUT_C,
                               X         => QCONV_PARAM.MAX_OUT_W,
                               Y         => QCONV_PARAM.MAX_OUT_H
                           );
        return param;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  PARAM                 :  PARAM_TYPE := NEW_PARAM;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    intake_data           :  std_logic_vector(PARAM.IN_DATA_STREAM.DATA.SIZE-1 downto 0);
    signal    intake_valid          :  std_logic;
    signal    intake_ready          :  std_logic;
    signal    intake_busy           :  std_logic;
    signal    intake_c_atrb_vec     :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.IN_DATA_STREAM.SHAPE.C.SIZE-1);
    signal    intake_d_atrb_vec     :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.IN_DATA_STREAM.SHAPE.D.SIZE-1);
    signal    intake_x_atrb_vec     :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.IN_DATA_STREAM.SHAPE.X.SIZE-1);
    signal    intake_y_atrb_vec     :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.IN_DATA_STREAM.SHAPE.Y.SIZE-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    kernel_data           :  std_logic_vector(PARAM.K_DATA_STREAM.DATA.SIZE-1 downto 0);
    signal    kernel_valid          :  std_logic;
    signal    kernel_ready          :  std_logic;
    signal    kernel_busy           :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    thresholds_data       :  std_logic_vector(PARAM.THRESHOLDS_STREAM.DATA.SIZE-1 downto 0);
    signal    thresholds_valid      :  std_logic;
    signal    thresholds_ready      :  std_logic;
    signal    thresholds_busy       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  bias_data             :  std_logic_vector(PARAM.BIAS_STREAM.DATA.SIZE-1 downto 0) := (others => '0');
    constant  bias_valid            :  std_logic := '1';
    signal    bias_ready            :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    mul_data              :  std_logic_vector(PARAM.MUL_STREAM.DATA.SIZE-1 downto 0);
    signal    mul_valid             :  std_logic;
    signal    mul_ready             :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    add_data              :  std_logic_vector(PARAM.ADD_STREAM.DATA.SIZE-1 downto 0);
    signal    add_valid             :  std_logic;
    signal    add_ready             :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    acc_data              :  std_logic_vector(PARAM.ACC_STREAM.DATA.SIZE-1 downto 0);
    signal    acc_valid             :  std_logic;
    signal    acc_ready             :  std_logic;
    signal    acc_c_atrb_vec        :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.ACC_STREAM.SHAPE.C.SIZE-1);
    signal    acc_d_atrb_vec        :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.ACC_STREAM.SHAPE.D.SIZE-1);
    signal    acc_x_atrb_vec        :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.ACC_STREAM.SHAPE.X.SIZE-1);
    signal    acc_y_atrb_vec        :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.ACC_STREAM.SHAPE.Y.SIZE-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    pass_th_i_data        :  std_logic_vector(PARAM.PASS_TH_I_STREAM.DATA.SIZE-1 downto 0);
    signal    pass_th_i_valid       :  std_logic;
    signal    pass_th_i_ready       :  std_logic;
    signal    pass_th_i_done        :  std_logic;
    signal    pass_th_i_c_vec       :  IMAGE_STREAM_ATRB_VECTOR(0 to PARAM.PASS_TH_I_STREAM.SHAPE.C.SIZE-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    pass_th_q_data        :  std_logic_vector(PARAM.PASS_TH_Q_STREAM.DATA.SIZE-1 downto 0);
    signal    pass_th_q_elem        :  std_logic_vector(PARAM.PASS_TH_Q_STREAM.DATA.ELEM_FIELD.SIZE-1 downto 0);
    signal    pass_th_q_last        :  std_logic;
    signal    pass_th_q_valid       :  std_logic;
    signal    pass_th_q_ready       :  std_logic;
    signal    pass_th_q_busy        :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    apply_th_i_data       :  std_logic_vector(PARAM.APPLY_TH_I_STREAM.DATA.SIZE-1 downto 0);
    signal    apply_th_i_valid      :  std_logic;
    signal    apply_th_i_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    apply_th_o_data       :  std_logic_vector(PARAM.APPLY_TH_O_STREAM.DATA.SIZE-1 downto 0);
    signal    apply_th_o_valid      :  std_logic;
    signal    apply_th_o_ready      :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    apply_th_d_data       :  std_logic_vector(PARAM.APPLY_TH_D_STREAM.DATA.SIZE-1 downto 0);
    signal    apply_th_d_done       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    apply_th_q_data       :  std_logic_vector(PARAM.APPLY_TH_Q_STREAM.DATA.SIZE-1 downto 0);
    signal    apply_th_q_elem       :  std_logic_vector(PARAM.APPLY_TH_Q_STREAM.DATA.ELEM_FIELD.SIZE-1 downto 0);
    signal    apply_th_q_last       :  std_logic;
    signal    apply_th_q_valid      :  std_logic;
    signal    apply_th_q_ready      :  std_logic;
    signal    apply_th_q_busy       :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    outlet_data           :  std_logic_vector(OUT_DATA'length-1 downto 0);
    signal    outlet_last           :  std_logic;
    signal    outlet_valid          :  std_logic;
    signal    outlet_ready          :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    i_req_valid           :  std_logic;
    signal    i_req_ready           :  std_logic;
    signal    i_res_valid           :  std_logic;
    signal    i_res_ready           :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    k_req_valid           :  std_logic;
    signal    k_req_ready           :  std_logic;
    signal    k_res_valid           :  std_logic;
    signal    k_res_ready           :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    t_req_valid           :  std_logic;
    signal    t_req_ready           :  std_logic;
    signal    t_res_valid           :  std_logic;
    signal    t_res_ready           :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE            is (IDLE_STATE, REQ_STATE, RUN_STATE, RES_STATE);
    signal    state                 :  STATE_TYPE;
begin
    -------------------------------------------------------------------------------
    -- State Machine
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
                        if (REQ_VALID = '1') then
                            state <= REQ_STATE;
                        else
                            state <= IDLE_STATE;
                        end if;
                    when REQ_STATE =>
                        if (intake_busy = '1' and kernel_busy = '1') and
                           ((req_args.use_th = '1' and thresholds_busy = '1') or (req_args.use_th = '0')) then
                            state <= RUN_STATE;
                        else
                            state <= REQ_STATE;
                        end if;
                    when RUN_STATE =>
                        if (outlet_valid = '1' and outlet_ready = '1' and outlet_last = '1') then
                            state <= RES_STATE;
                        else
                            state <= RUN_STATE;
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
    -- req_args
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                req_args <= REQ_ARGS_NULL;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                req_args <= REQ_ARGS_NULL;
            elsif (state = IDLE_STATE and REQ_VALID = '1') then
                req_args.in_c_by_word    <= to_integer(unsigned(IN_C_BY_WORD  ));
                req_args.in_w            <= to_integer(unsigned(IN_W          ));
                req_args.in_h            <= to_integer(unsigned(IN_H          ));
                req_args.out_c           <= to_integer(unsigned(OUT_C         ));
                req_args.out_w           <= to_integer(unsigned(OUT_W         ));
                req_args.out_h           <= to_integer(unsigned(OUT_H         ));
                req_args.left_pad_size   <= to_integer(unsigned(LEFT_PAD_SIZE ));
                req_args.right_pad_size  <= to_integer(unsigned(RIGHT_PAD_SIZE));
                req_args.top_pad_size    <= to_integer(unsigned(TOP_PAD_SIZE  ));
                req_args.bottom_pad_size <= to_integer(unsigned(BOTTOM_PAD_SIZE));
                req_args.use_th          <= USE_TH;
                req_args.param_in        <= PARAM_IN;
                if (to_integer(unsigned(K_W)) = 3) and
                   (to_integer(unsigned(K_H)) = 3) then
                    req_args.k3x3     <= '1';
                else
                    req_args.k3x3     <= '0';
                end if;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- INPUT BUFFER
    -------------------------------------------------------------------------------
    IN_DATA_BUF: QCONV_STRIP_IN_DATA_BUFFER              -- 
        generic map (                                    --
            QCONV_PARAM     => QCONV_PARAM             , -- 
            O_PARAM         => PARAM.IN_DATA_STREAM    , -- 
            I_SHAPE         => PARAM.IN_SHAPE          , -- 
            O_SHAPE         => PARAM.OUT_SHAPE         , -- 
            ELEMENT_SIZE    => IN_BUF_SIZE             , --
            IN_C_UNROLL     => IN_C_UNROLL             , --
            OUT_C_UNROLL    => OUT_C_UNROLL            , --
            ID              => 0                         -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            IN_C_BY_WORD    => req_args.in_c_by_word   , -- In  :
            IN_W            => req_args.in_w           , -- In  :
            IN_H            => req_args.in_h           , -- In  :
            OUT_C           => req_args.out_c          , -- In  :
            OUT_W           => req_args.out_w          , -- In  :
            OUT_H           => req_args.out_h          , -- In  :
            LEFT_PAD_SIZE   => req_args.left_pad_size  , -- In  :
            RIGHT_PAD_SIZE  => req_args.right_pad_size , -- In  :
            TOP_PAD_SIZE    => req_args.top_pad_size   , -- In  :
            BOTTOM_PAD_SIZE => req_args.bottom_pad_size, -- In  :
            K3x3            => req_args.k3x3           , -- In  :
            REQ_VALID       => i_req_valid             , -- In  :
            REQ_READY       => i_req_ready             , -- Out :
            RES_VALID       => i_res_valid             , -- In  :
            RES_READY       => i_res_ready             , -- Out :
            I_DATA          => IN_DATA                 , -- In  :
            I_VALID         => IN_VALID                , -- In  :
            I_READY         => IN_READY                , -- Out :
            O_DATA          => intake_data             , -- Out :
            O_VALID         => intake_valid            , -- Out :
            O_READY         => intake_ready              -- In  :
        );                                               --
    process (CLK, RST) begin
        if (RST = '1') then
                intake_busy <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                intake_busy <= '0';
            elsif (state = REQ_STATE and i_req_ready = '1') then
                intake_busy <= '1';
            elsif (i_res_valid = '1' and i_res_ready = '1') then
                intake_busy <= '0';
            end if;
        end if;
    end process;
    i_req_valid <= '1' when (state = REQ_STATE and intake_busy = '0') else '0';
    i_res_ready <= '1' when (state = RUN_STATE and intake_busy = '1') else '0';
    intake_c_atrb_vec <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.IN_DATA_STREAM, intake_data);
    intake_d_atrb_vec <= GET_ATRB_D_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.IN_DATA_STREAM, intake_data);
    intake_x_atrb_vec <= GET_ATRB_X_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.IN_DATA_STREAM, intake_data);
    intake_y_atrb_vec <= GET_ATRB_Y_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.IN_DATA_STREAM, intake_data);
    -------------------------------------------------------------------------------
    -- KERNEL WEIGHT BUFFER
    -------------------------------------------------------------------------------
    K: QCONV_STRIP_K_DATA_BUFFER                         -- 
        generic map (                                    --
            QCONV_PARAM     => QCONV_PARAM             , -- 
            O_PARAM         => PARAM.K_DATA_STREAM     , -- 
            I_SHAPE         => PARAM.IN_SHAPE          , -- 
            O_SHAPE         => PARAM.OUT_SHAPE         , -- 
            ELEMENT_SIZE    => K_BUF_SIZE              , --
            IN_C_UNROLL     => IN_C_UNROLL             , --
            OUT_C_UNROLL    => OUT_C_UNROLL            , --
            QUEUE_SIZE      => 2                       , --
            ID              => 256                       -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            IN_C_BY_WORD    => req_args.in_c_by_word   , -- In  :
            OUT_C           => req_args.out_c          , -- In  :
            OUT_W           => req_args.out_w          , -- In  :
            OUT_H           => req_args.out_h          , -- In  :
            K3x3            => req_args.k3x3           , -- In  :
            REQ_WRITE       => req_args.param_in       , -- In  :
            REQ_READ        => '1'                     , -- In  :
            REQ_VALID       => k_req_valid             , -- In  :
            REQ_READY       => k_req_ready             , -- Out :
            RES_VALID       => k_res_valid             , -- In  :
            RES_READY       => k_res_ready             , -- Out :
            I_DATA          => K_DATA                  , -- In  :
            I_VALID         => K_VALID                 , -- In  :
            I_READY         => K_READY                 , -- Out :
            O_DATA          => kernel_data             , -- Out :
            O_VALID         => kernel_valid            , -- Out :
            O_READY         => kernel_ready              -- In  :
        );                                               --
    process (CLK, RST) begin
        if (RST = '1') then
                kernel_busy <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                kernel_busy <= '0';
            elsif (state = REQ_STATE and k_req_ready = '1') then
                kernel_busy <= '1';
            elsif (k_res_valid = '1' and k_res_ready = '1') then
                kernel_busy <= '0';
            end if;
        end if;
    end process;
    k_req_valid <= '1' when (state = REQ_STATE and kernel_busy = '0') else '0';
    k_res_ready <= '1' when (state = RUN_STATE   and kernel_busy = '1') else '0';
    -------------------------------------------------------------------------------
    -- THRESHOLDS BUFFER
    -------------------------------------------------------------------------------
    TH: QCONV_STRIP_TH_DATA_BUFFER                       -- 
        generic map (                                    --
            QCONV_PARAM     => QCONV_PARAM             , -- 
            O_PARAM         => PARAM.THRESHOLDS_STREAM , -- 
            O_SHAPE         => PARAM.OUT_SHAPE         , -- 
            ELEMENT_SIZE    => TH_BUF_SIZE             , --
            OUT_C_UNROLL    => OUT_C_UNROLL            , --
            ID              => 512                       -- 
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            OUT_C           => req_args.out_c          , -- In  :
            OUT_W           => req_args.out_w          , -- In  :
            OUT_H           => req_args.out_h          , -- In  :
            REQ_WRITE       => req_args.param_in       , -- In  :
            REQ_READ        => '1'                     , -- In  :
            REQ_VALID       => t_req_valid             , -- In  :
            REQ_READY       => t_req_ready             , -- Out :
            RES_VALID       => t_res_valid             , -- In  :
            RES_READY       => t_res_ready             , -- Out :
            I_DATA          => TH_DATA                 , -- In  :
            I_VALID         => TH_VALID                , -- In  :
            I_READY         => TH_READY                , -- Out :
            O_DATA          => thresholds_data         , -- Out :
            O_VALID         => thresholds_valid        , -- Out :
            O_READY         => thresholds_ready          -- In  :
        );                                               --
    process (CLK, RST) begin
        if (RST = '1') then
                thresholds_busy <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                thresholds_busy <= '0';
            elsif (state = REQ_STATE and req_args.use_th = '1' and t_req_ready = '1') then
                thresholds_busy <= '1';
            elsif (t_res_valid = '1' and t_res_ready = '1') then
                thresholds_busy <= '0';
            end if;
        end if;
    end process;
    t_req_valid <= '1' when (state = REQ_STATE and req_args.use_th = '1' and thresholds_busy = '0') else '0';
    t_res_ready <= '1' when (state = RUN_STATE and                           thresholds_busy = '1') else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    MUL: QCONV_MULTIPLIER                                -- 
        generic map (                                    -- 
            QCONV_PARAM     => QCONV_PARAM             , --
            I_PARAM         => PARAM.IN_DATA_STREAM    , --
            K_PARAM         => PARAM.K_DATA_STREAM     , --
            O_PARAM         => PARAM.MUL_STREAM        , --
            CHECK_K_VALID   => 0                       , -- 
            QUEUE_SIZE      => 1                         --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            I_DATA          => intake_data             , -- In  :
            I_VALID         => intake_valid            , -- In  :
            I_READY         => intake_ready            , -- Out :
            K_DATA          => kernel_data             , -- In  :
            K_VALID         => kernel_valid            , -- In  :
            K_READY         => kernel_ready            , -- Out :
            O_DATA          => mul_data                , -- Out :
            O_VALID         => mul_valid               , -- Out :
            O_READY         => mul_ready                 -- In  :
        );                                               -- 
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    ADD: CONVOLUTION_INT_ADDER_TREE                      -- 
        generic map (                                    -- 
            I_PARAM         => PARAM.MUL_STREAM        , --
            O_PARAM         => PARAM.ADD_STREAM        , --
            QUEUE_SIZE      => 1                       , --
            SIGN            => TRUE                      --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            I_DATA          => mul_data                , -- In  :
            I_VALID         => mul_valid               , -- In  :
            I_READY         => mul_ready               , -- Out :
            O_DATA          => add_data                , -- Out :
            O_VALID         => add_valid               , -- Out :
            O_READY         => add_ready                 -- In  :
        );                                               -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    ACC: CONVOLUTION_INT_ACCUMULATOR                     -- 
        generic map (                                    -- 
            I_PARAM         => PARAM.ADD_STREAM        , --
            O_PARAM         => PARAM.ACC_STREAM        , --
            B_PARAM         => PARAM.BIAS_STREAM       , --
            QUEUE_SIZE      => 2                       , --
            SIGN            => TRUE                      --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            I_DATA          => add_data                , -- In  :
            I_VALID         => add_valid               , -- In  :
            I_READY         => add_ready               , -- Out :
            B_DATA          => bias_data               , -- In  :
            B_VALID         => bias_valid              , -- In  :
            B_READY         => bias_ready              , -- Out :
            O_DATA          => acc_data                , -- Out :
            O_VALID         => acc_valid               , -- Out :
            O_READY         => acc_ready                 -- In  :
        );                                               --
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    acc_c_atrb_vec    <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.ACC_STREAM, acc_data);
    acc_d_atrb_vec    <= GET_ATRB_D_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.ACC_STREAM, acc_data);
    acc_x_atrb_vec    <= GET_ATRB_X_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.ACC_STREAM, acc_data);
    acc_y_atrb_vec    <= GET_ATRB_Y_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.ACC_STREAM, acc_data);
    acc_ready         <= '1' when (req_args.use_th = '1' and apply_th_i_ready = '1') or
                                  (req_args.use_th = '0' and pass_th_i_ready  = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    PASS_TH: IMAGE_STREAM_CHANNEL_REDUCER                -- 
        generic map (                                    -- 
            I_PARAM         => PARAM.PASS_TH_I_STREAM  , --
            O_PARAM         => PARAM.PASS_TH_Q_STREAM  , --
            C_SIZE          => 0                       , --
            C_DONE          => 0                         --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            BUSY            => pass_th_q_busy          , -- Out :
            I_DATA          => pass_th_i_data          , -- In  :
            I_DONE          => pass_th_i_done          , -- In  :
            I_VALID         => pass_th_i_valid         , -- In  :
            I_READY         => pass_th_i_ready         , -- Out :
            O_DATA          => pass_th_q_data          , -- Out :
            O_VALID         => pass_th_q_valid         , -- Out :
            O_READY         => pass_th_q_ready           -- In  :
        );                                               -- 
    pass_th_i_data   <= CONVOLUTION_PIPELINE_TO_IMAGE_STREAM(PARAM.PASS_TH_I_STREAM, PARAM.ACC_STREAM, acc_data);
    pass_th_i_c_vec  <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(PARAM.PASS_TH_I_STREAM, pass_th_i_data);
    pass_th_i_done   <= '1' when (IMAGE_STREAM_DATA_IS_LAST_C(PARAM.PASS_TH_I_STREAM, pass_th_i_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_X(PARAM.PASS_TH_I_STREAM, pass_th_i_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_Y(PARAM.PASS_TH_I_STREAM, pass_th_i_data)) else '0';
    pass_th_i_valid  <= '1' when (req_args.use_th = '0' and acc_valid = '1') else '0';
    pass_th_q_elem   <= pass_th_q_data(PARAM.PASS_TH_Q_STREAM.DATA.ELEM_FIELD.HI downto PARAM.PASS_TH_Q_STREAM.DATA.ELEM_FIELD.LO);
    pass_th_q_last   <= '1' when (IMAGE_STREAM_DATA_IS_LAST_C(PARAM.PASS_TH_Q_STREAM, pass_th_q_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_X(PARAM.PASS_TH_Q_STREAM, pass_th_q_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_Y(PARAM.PASS_TH_Q_STREAM, pass_th_q_data)) else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    APPLY_TH: QCONV_APPLY_THRESHOLDS                     -- 
        generic map (                                    --
            QCONV_PARAM     => QCONV_PARAM             , -- 
            I_PARAM         => PARAM.APPLY_TH_I_STREAM , -- 
            T_PARAM         => PARAM.THRESHOLDS_STREAM , --
            O_PARAM         => PARAM.APPLY_TH_O_STREAM , --
            QUEUE_SIZE      => 2                         --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            I_DATA          => apply_th_i_data         , -- In  :
            I_VALID         => apply_th_i_valid        , -- In  :
            I_READY         => apply_th_i_ready        , -- Out :
            T_DATA          => thresholds_data         , -- In  :
            T_VALID         => thresholds_valid        , -- In  :
            T_READY         => thresholds_ready        , -- Out :
            O_DATA          => apply_th_o_data         , -- Out :
            O_VALID         => apply_th_o_valid        , -- Out :
            O_READY         => apply_th_o_ready          -- In  :
        );                                               -- 
    apply_th_i_data  <= acc_data;
    apply_th_i_valid <= '1' when (req_args.use_th = '1' and acc_valid = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    APPLY_QUEUE: IMAGE_STREAM_CHANNEL_REDUCER            -- 
        generic map (                                    -- 
            I_PARAM         => PARAM.APPLY_TH_D_STREAM , --
            O_PARAM         => PARAM.APPLY_TH_Q_STREAM , --
            C_SIZE          => 0                       , --
            C_DONE          => 0                         --
        )                                                -- 
        port map (                                       -- 
            CLK             => CLK                     , -- In  :
            RST             => RST                     , -- In  :
            CLR             => CLR                     , -- In  :
            BUSY            => apply_th_q_busy         , -- Out :
            I_DATA          => apply_th_d_data         , -- In  :
            I_DONE          => apply_th_d_done         , -- In  :
            I_VALID         => apply_th_o_valid        , -- In  :
            I_READY         => apply_th_o_ready        , -- Out :
            O_DATA          => apply_th_q_data         , -- Out :
            O_VALID         => apply_th_q_valid        , -- Out :
            O_READY         => apply_th_q_ready          -- In  :
        );                                               --
    apply_th_d_data  <= CONVOLUTION_PIPELINE_TO_IMAGE_STREAM(PARAM.APPLY_TH_D_STREAM, PARAM.APPLY_TH_O_STREAM, apply_th_o_data);
    apply_th_d_done  <= '1' when (IMAGE_STREAM_DATA_IS_LAST_C(PARAM.APPLY_TH_D_STREAM, apply_th_d_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_X(PARAM.APPLY_TH_D_STREAM, apply_th_d_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_Y(PARAM.APPLY_TH_D_STREAM, apply_th_d_data)) else '0';
    apply_th_q_last  <= '1' when (IMAGE_STREAM_DATA_IS_LAST_C(PARAM.APPLY_TH_Q_STREAM, apply_th_q_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_X(PARAM.APPLY_TH_Q_STREAM, apply_th_q_data) and
                                  IMAGE_STREAM_DATA_IS_LAST_Y(PARAM.APPLY_TH_Q_STREAM, apply_th_q_data)) else '0';
    process (apply_th_q_data)
        variable  elem_data     :  std_logic_vector(PARAM.APPLY_TH_Q_STREAM.DATA.ELEM_FIELD.SIZE-1 downto 0);
        constant  OUT_WORD_BITS :  integer := QCONV_PARAM.NBITS_IN_DATA * QCONV_PARAM.NBITS_PER_WORD;
        constant  OUT_WORDS     :  integer := OUT_DATA_BITS / OUT_WORD_BITS;
    begin
        elem_data := apply_th_q_data(PARAM.APPLY_TH_Q_STREAM.DATA.ELEM_FIELD.HI downto PARAM.APPLY_TH_Q_STREAM.DATA.ELEM_FIELD.LO);
        for out_pos  in 0 to OUT_WORDS-1 loop
        for word_pos in 0 to QCONV_PARAM.NBITS_PER_WORD-1 loop
        for data_pos in 0 to QCONV_PARAM.NBITS_IN_DATA -1 loop
            apply_th_q_elem(out_pos*OUT_WORD_BITS + data_pos*QCONV_PARAM.NBITS_PER_WORD + word_pos) <= elem_data(out_pos*OUT_WORD_BITS + word_pos*QCONV_PARAM.NBITS_IN_DATA + data_pos);
        end loop;
        end loop;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    outlet_data  <= apply_th_q_elem when (req_args.use_th = '1') else pass_th_q_elem;
    outlet_valid <= '1' when (req_args.use_th = '1' and apply_th_q_valid = '1') or
                             (req_args.use_th = '0' and pass_th_q_valid  = '1') else '0';
    outlet_last  <= '1' when (req_args.use_th = '1' and apply_th_q_last  = '1') or
                             (req_args.use_th = '0' and pass_th_q_last   = '1') else '0';
    apply_th_q_ready <= '1' when (req_args.use_th = '1' and outlet_ready = '1') else '0';
    pass_th_q_ready  <= '1' when (req_args.use_th = '0' and outlet_ready = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    OUT_DATA     <= outlet_data;
    OUT_VALID    <= outlet_valid;
    OUT_LAST     <= outlet_last;
    outlet_ready <= OUT_READY;
end RTL;
