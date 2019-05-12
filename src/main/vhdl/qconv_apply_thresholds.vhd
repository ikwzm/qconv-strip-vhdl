-----------------------------------------------------------------------------------
--!     @file    qconv_apply_thresholds.vhd
--!     @brief   Quantized Convolution Apply Thresholds Module
--!     @version 0.2.0
--!     @date    2019/5/12
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
--! @brief Quantized Convolution Apply Thresholds Module
-----------------------------------------------------------------------------------
entity  QCONV_APPLY_THRESHOLDS is
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
end QCONV_APPLY_THRESHOLDS;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.COMPONENTS.PIPELINE_REGISTER;
architecture RTL of QCONV_APPLY_THRESHOLDS is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   I_ELEM_TYPE     is std_logic_vector(I_PARAM.ELEM_BITS-1 downto 0);
    type      I_ELEM_VECTOR   is array(0 to I_PARAM.SHAPE.Y.SIZE-1,
                                       0 to I_PARAM.SHAPE.X.SIZE-1,
                                       0 to I_PARAM.SHAPE.D.SIZE-1,
                                       0 to I_PARAM.SHAPE.C.SIZE-1) of I_ELEM_TYPE;
    signal    i_element       :  I_ELEM_VECTOR;
    signal    i_c_atrb        :  IMAGE_STREAM_ATRB_VECTOR(0 to I_PARAM.SHAPE.C.SIZE-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   T_ELEM_TYPE     is std_logic_vector(T_PARAM.ELEM_BITS-1 downto 0);
    type      T_ELEM_VECTOR   is array(0 to T_PARAM.SHAPE.Y.SIZE-1,
                                       0 to T_PARAM.SHAPE.X.SIZE-1,
                                       0 to T_PARAM.SHAPE.D.SIZE-1,
                                       0 to T_PARAM.SHAPE.C.SIZE-1) of T_ELEM_TYPE;
    signal    t_element       :  T_ELEM_VECTOR;
    signal    t_c_atrb        :  IMAGE_STREAM_ATRB_VECTOR(0 to T_PARAM.SHAPE.C.SIZE-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   O_ELEM_TYPE     is std_logic_vector(O_PARAM.ELEM_BITS-1 downto 0);
    type      O_ELEM_VECTOR   is array(0 to O_PARAM.SHAPE.Y.SIZE-1,
                                       0 to O_PARAM.SHAPE.X.SIZE-1,
                                       0 to O_PARAM.SHAPE.D.SIZE-1,
                                       0 to O_PARAM.SHAPE.C.SIZE-1) of O_ELEM_TYPE;
    signal    o_element       :  O_ELEM_VECTOR;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    q_data          :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    signal    q_valid         :  std_logic;
    signal    q_ready         :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- i_element : 入力パイプラインイメージデータを要素ごとの配列に変換
    -- i_d_valid : 入力パイプラインイメージデータのチャネル有効信号
    -------------------------------------------------------------------------------
    process (I_DATA) begin
        for y in 0 to I_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to I_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to I_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to I_PARAM.SHAPE.C.SIZE-1 loop
            i_element(y,x,d,c) <= GET_ELEMENT_FROM_IMAGE_STREAM_DATA(I_PARAM, c, d, x, y, I_DATA);
        end loop;
        end loop;
        end loop;
        end loop;
        i_c_atrb <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(I_PARAM, I_DATA);
    end process;
    -------------------------------------------------------------------------------
    -- t_element : 入力パイプライン THRESHOLD データを要素ごとの配列に変換
    -- t_d_valid : 入力パイプライン THRESHOLD データのチャネル有効信号
    -------------------------------------------------------------------------------
    process (T_DATA) begin
        for y in 0 to T_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to T_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to T_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to T_PARAM.SHAPE.C.SIZE-1 loop
            t_element(y,x,d,c) <= GET_ELEMENT_FROM_IMAGE_STREAM_DATA(T_PARAM, c, d, x, y, T_DATA);
        end loop;
        end loop;
        end loop;
        end loop;
        t_c_atrb <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(T_PARAM, T_DATA);
    end process;
    -------------------------------------------------------------------------------
    -- o_element : 演算結果
    -------------------------------------------------------------------------------
    process(i_element, t_element)
        variable i_data  :           signed(I_PARAM.ELEM_BITS  -1 downto 0);
        variable t_data  : std_logic_vector(T_PARAM.ELEM_BITS  -1 downto 0);
        variable t0      :           signed(T_PARAM.ELEM_BITS/4-1 downto 0);
        variable t1      :           signed(T_PARAM.ELEM_BITS/4-1 downto 0);
        variable t2      :           signed(T_PARAM.ELEM_BITS/4-1 downto 0);
        variable s_flag  :           signed(T_PARAM.ELEM_BITS/4-1 downto 0);
        variable u_flag  :         unsigned(T_PARAM.ELEM_BITS/4-1 downto 0);
        variable o_data  :         unsigned(O_PARAM.ELEM_BITS  -1 downto 0);
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            i_data := to_01(signed(i_element(y,x,d,c)));
            t_data := t_element(y,x,d,c);
            t0     := to_01(  signed(t_data((0+1)*QCONV_PARAM.NBITS_OUT_DATA-1 downto 0*QCONV_PARAM.NBITS_OUT_DATA)));
            t1     := to_01(  signed(t_data((1+1)*QCONV_PARAM.NBITS_OUT_DATA-1 downto 1*QCONV_PARAM.NBITS_OUT_DATA)));
            t2     := to_01(  signed(t_data((2+1)*QCONV_PARAM.NBITS_OUT_DATA-1 downto 2*QCONV_PARAM.NBITS_OUT_DATA)));
            s_flag := to_01(  signed(t_data((3+1)*QCONV_PARAM.NBITS_OUT_DATA-1 downto 3*QCONV_PARAM.NBITS_OUT_DATA)));
            u_flag := to_01(unsigned(t_data((3+1)*QCONV_PARAM.NBITS_OUT_DATA-1 downto 3*QCONV_PARAM.NBITS_OUT_DATA)));
            if    (s_flag = 1) then
                if    (i_data < t0) then
                    o_data := to_unsigned(0, O_PARAM.ELEM_BITS);
                elsif (i_data < t1) then
                    o_data := to_unsigned(1, O_PARAM.ELEM_BITS);
                elsif (i_data < t2) then
                    o_data := to_unsigned(2, O_PARAM.ELEM_BITS);
                else
                    o_data := to_unsigned(3, O_PARAM.ELEM_BITS);
                end if;
            elsif (s_flag = -1) then
                if    (i_data > t2) then
                    o_data := to_unsigned(0, O_PARAM.ELEM_BITS);
                elsif (i_data > t1) then
                    o_data := to_unsigned(1, O_PARAM.ELEM_BITS);
                elsif (i_data > t0) then
                    o_data := to_unsigned(2, O_PARAM.ELEM_BITS);
                else
                    o_data := to_unsigned(3, O_PARAM.ELEM_BITS);
                end if;
            else
                o_data := resize((u_flag - 2), O_PARAM.ELEM_BITS);
            end if;
            o_element(y,x,d,c) <= std_logic_vector(o_data);
        end loop;
        end loop;
        end loop;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    -- q_data    : パイプラインレジスタに入力するデータ
    -------------------------------------------------------------------------------
    process (o_element, I_DATA)
        variable data :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            SET_ELEMENT_TO_IMAGE_STREAM_DATA(O_PARAM, c, d, x, y, o_element(y,x,d,c), data);
        end loop;        
        end loop;        
        end loop;
        end loop;
        if (O_PARAM.DATA.ATRB_FIELD.SIZE > 0) then
            data(O_PARAM.DATA.ATRB_FIELD.HI downto O_PARAM.DATA.ATRB_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_FIELD.HI downto I_PARAM.DATA.ATRB_FIELD.LO);
        end if;
        if (O_PARAM.DATA.INFO_FIELD.SIZE > 0) then
            data(O_PARAM.DATA.INFO_FIELD.HI downto O_PARAM.DATA.INFO_FIELD.LO) := I_DATA(I_PARAM.DATA.INFO_FIELD.HI downto I_PARAM.DATA.INFO_FIELD.LO);
        end if;
        q_data <= data;
    end process;
    -------------------------------------------------------------------------------
    -- q_valid   : 
    -------------------------------------------------------------------------------
    q_valid <= '1' when (I_VALID = '1' and T_VALID = '1') else '0';
    I_READY <= '1' when (q_valid = '1' and q_ready = '1') else '0';
    T_READY <= '1' when (q_valid = '1' and q_ready = '1') else '0';
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
            I_WORD      => q_data            , -- In  :
            I_VAL       => q_valid           , -- In  :
            I_RDY       => q_ready           , -- Out :
            Q_WORD      => O_DATA            , -- Out :
            Q_VAL       => O_VALID           , -- Out :
            Q_RDY       => O_READY           , -- In  :
            BUSY        => open                -- Out :
        );                                     -- 
end RTL;
