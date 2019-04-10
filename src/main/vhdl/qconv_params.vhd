-----------------------------------------------------------------------------------
--!     @file    qconv_params.vhd
--!     @brief   Quantized Convolution Parameters Package
--!     @version 0.1.0
--!     @date    2019/3/20
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
-----------------------------------------------------------------------------------
--! @brief Quantized Convolution のパラメータを定義しているパッケージ
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
package QCONV_PARAMS is

    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    type      QCONV_PARAMS_TYPE     is record
                  NUM_PE                   :  integer;
                  NBITS_PER_WORD           :  integer;
                  NBITS_IN_DATA            :  integer;
                  NBITS_K_DATA             :  integer;
                  NBITS_OUT_DATA           :  integer;
                  NUM_THRESHOLDS           :  integer;
                  MAX_IN_W                 :  integer;
                  MAX_IN_H                 :  integer;
                  MAX_IN_C                 :  integer;
                  MAX_IN_C_BY_WORD         :  integer;
                  MAX_OUT_C                :  integer;
                  MAX_OUT_W                :  integer;
                  MAX_OUT_H                :  integer;
                  MAX_K_W                  :  integer;
                  MAX_K_H                  :  integer;
                  MAX_PAD_SIZE             :  integer;
                  IN_C_BITS                :  integer;
                  IN_C_BY_WORD_BITS        :  integer;
                  IN_W_BITS                :  integer;
                  IN_H_BITS                :  integer;
                  OUT_C_BITS               :  integer;
                  OUT_W_BITS               :  integer;
                  OUT_H_BITS               :  integer;
                  K_W_BITS                 :  integer;
                  K_H_BITS                 :  integer;
                  PAD_SIZE_BITS            :  integer;
    end record;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  NEW_QCONV_PARAMS(
                  NUM_PE                   :  integer;
                  NBITS_PER_WORD           :  integer;
                  NBITS_IN_DATA            :  integer;
                  NBITS_K_DATA             :  integer;
                  NBITS_OUT_DATA           :  integer;
                  NUM_THRESHOLDS           :  integer;
                  MAX_K_W                  :  integer;
                  MAX_K_H                  :  integer;
                  MAX_PAD_SIZE             :  integer;
                  MAX_IN_C                 :  integer;
                  MAX_OUT_C                :  integer;
                  MAX_OUT_W                :  integer;
                  MAX_OUT_H                :  integer
    )             return                      QCONV_PARAMS_TYPE;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    constant  QCONV_COMMON_PARAMS          :  QCONV_PARAMS_TYPE := NEW_QCONV_PARAMS(
                                                  NUM_PE         => 16,    
                                                  NBITS_PER_WORD => 32,    -- 1 word     = 32bit
                                                  NBITS_IN_DATA  => 2,     -- 1 in_data  =  2bit
                                                  NBITS_K_DATA   => 1,     -- 1 k_data   =  1bit
                                                  NBITS_OUT_DATA => 16,    -- 1 out_data = 16bit
                                                  NUM_THRESHOLDS => 4,     --
                                                  MAX_K_W        => 3,     -- 
                                                  MAX_K_H        => 3,     -- 
                                                  MAX_PAD_SIZE   => 8,     -- 
                                                  MAX_IN_C       => 1024,  -- 
                                                  MAX_OUT_C      => 1024,  -- 
                                                  MAX_OUT_W      => 1024,  --
                                                  MAX_OUT_H      => 1024   -- 
                                              );
end     QCONV_PARAMS;
-----------------------------------------------------------------------------------
--! @brief Quantized Convolution のパラメータを定義しているパッケージ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
package body QCONV_PARAMS is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  max_to_bits(MAX:integer) return integer is
        variable bits : integer;
    begin
        bits := 1;
        while (2**bits <= MAX) loop
            bits := bits + 1;
        end loop;
        return bits;
    end function;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    function  NEW_QCONV_PARAMS(
                  NUM_PE                   :  integer;
                  NBITS_PER_WORD           :  integer;
                  NBITS_IN_DATA            :  integer;
                  NBITS_K_DATA             :  integer;
                  NBITS_OUT_DATA           :  integer;
                  NUM_THRESHOLDS           :  integer;
                  MAX_K_W                  :  integer;
                  MAX_K_H                  :  integer;
                  MAX_PAD_SIZE             :  integer;
                  MAX_IN_C                 :  integer;
                  MAX_OUT_C                :  integer;
                  MAX_OUT_W                :  integer;
                  MAX_OUT_H                :  integer
    )             return                      QCONV_PARAMS_TYPE
    is
         variable params                   :  QCONV_PARAMS_TYPE;
    begin
        params.NUM_PE            := NUM_PE;
        params.NBITS_PER_WORD    := NBITS_PER_WORD;
        params.NBITS_IN_DATA     := NBITS_IN_DATA;
        params.NBITS_K_DATA      := NBITS_K_DATA;
        params.NBITS_OUT_DATA    := NBITS_OUT_DATA;
        params.NUM_THRESHOLDS    := NUM_THRESHOLDS;
        params.MAX_IN_W          := MAX_OUT_W + 2;
        params.MAX_IN_H          := MAX_OUT_H + 2;
        params.MAX_IN_C          := MAX_IN_C;
        params.MAX_IN_C_BY_WORD  := MAX_IN_C / params.NBITS_PER_WORD;
        params.MAX_OUT_C         := MAX_OUT_C;
        params.MAX_OUT_W         := MAX_OUT_W;
        params.MAX_OUT_H         := MAX_OUT_H;
        params.MAX_K_W           := MAX_K_W;
        params.MAX_K_H           := MAX_K_H;
        params.MAX_PAD_SIZE      := MAX_PAD_SIZE;
        params.IN_C_BITS         := max_to_bits(params.MAX_IN_C);
        params.IN_C_BY_WORD_BITS := max_to_bits(params.MAX_IN_C_BY_WORD);
        params.IN_W_BITS         := max_to_bits(params.MAX_IN_W);
        params.IN_H_BITS         := max_to_bits(params.MAX_IN_H);
        params.OUT_C_BITS        := max_to_bits(params.MAX_OUT_C);
        params.OUT_W_BITS        := max_to_bits(params.MAX_OUT_W);
        params.OUT_H_BITS        := max_to_bits(params.MAX_OUT_H);
        params.K_W_BITS          := max_to_bits(params.MAX_K_W);
        params.K_H_BITS          := max_to_bits(params.MAX_K_H);
        params.PAD_SIZE_BITS     := max_to_bits(params.MAX_PAD_SIZE);
        return params;
    end function;
end QCONV_PARAMS;
