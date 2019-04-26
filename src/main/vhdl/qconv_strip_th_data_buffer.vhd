-----------------------------------------------------------------------------------
--!     @file    qconv_strip_th_data_buffer.vhd
--!     @brief   Quantized Convolution (strip) Thresholds Data Buffer Module
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
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
-----------------------------------------------------------------------------------
--! @brief 
-----------------------------------------------------------------------------------
entity  QCONV_STRIP_TH_DATA_BUFFER is
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
                              C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(3*3),
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
end QCONV_STRIP_TH_DATA_BUFFER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.SDPRAM;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.CONVOLUTION_TYPES.all;
use     PIPEWORK.CONVOLUTION_COMPONENTS.CONVOLUTION_PARAMETER_BUFFER;
architecture RTL of QCONV_STRIP_TH_DATA_BUFFER is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  BUF_PARAM         :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                       ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS,
                                       C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(OUT_C_UNROLL, TRUE , TRUE),
                                       D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1           , FALSE, TRUE),
                                       X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1           , TRUE , TRUE),
                                       Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1           , TRUE , TRUE)
                                   );
    constant  BUF_SHAPE         :  IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE(
                                       ELEM_BITS => QCONV_PARAM.NBITS_OUT_DATA*QCONV_PARAM.NUM_THRESHOLDS,
                                       C         => O_SHAPE.C,
                                       D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                                       X         => O_SHAPE.X,
                                       Y         => O_SHAPE.Y
                                   );
    signal    buf_out_data      :  std_logic_vector(BUF_PARAM.DATA.SIZE-1 downto 0);
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF: CONVOLUTION_PARAMETER_BUFFER            -- 
        generic map (                            -- 
            PARAM           => BUF_PARAM       , -- 
            SHAPE           => BUF_SHAPE       , --   
            ELEMENT_SIZE    => ELEMENT_SIZE    , --   
            ID              => ID                --   
        )                                        -- 
        port map (                               -- 
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => CLK             , --   
            RST             => RST             , --   
            CLR             => CLR             , --   
        ---------------------------------------------------------------------------
        -- 制御 I/F
        ---------------------------------------------------------------------------
            REQ_VALID       => REQ_VALID       , --   
            REQ_READY       => REQ_READY       , --   
            REQ_WRITE       => REQ_WRITE       , --   
            REQ_READ        => REQ_READ        , --   
            C_SIZE          => OUT_C           , --   
            X_SIZE          => OUT_W           , --   
            Y_SIZE          => OUT_H           , --   
            RES_VALID       => RES_VALID       , --   
            RES_READY       => RES_READY       , --   
        ---------------------------------------------------------------------------
        -- 入力 I/F
        ---------------------------------------------------------------------------
            I_DATA          => I_DATA          , --   
            I_VALID         => I_VALID         , --   
            I_READY         => I_READY         , --   
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_DATA          => buf_out_data    , --   
            O_VALID         => O_VALID         , --   
            O_READY         => O_READY           --   
        );                                       -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    O_DATA <= CONVOLUTION_PIPELINE_FROM_BIAS_STREAM(O_PARAM, BUF_PARAM, buf_out_data);
end RTL;
