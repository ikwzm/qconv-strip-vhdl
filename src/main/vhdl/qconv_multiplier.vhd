-----------------------------------------------------------------------------------
--!     @file    qconv_multiplier.vhd
--!     @brief   Quantized Convolution Multiplier Module
--!     @version 0.1.0
--!     @date    2019/3/29
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
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
-----------------------------------------------------------------------------------
--! @brief Quantized Convolution Multiplier Module
-----------------------------------------------------------------------------------
entity  QCONV_MULTIPLIER is
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
end QCONV_MULTIPLIER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.COMPONENTS.PIPELINE_REGISTER;
architecture RTL of QCONV_MULTIPLIER is
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
    subtype   K_ELEM_TYPE     is std_logic_vector(K_PARAM.ELEM_BITS-1 downto 0);
    type      K_ELEM_VECTOR   is array(0 to K_PARAM.SHAPE.Y.SIZE-1,
                                       0 to K_PARAM.SHAPE.X.SIZE-1,
                                       0 to K_PARAM.SHAPE.D.SIZE-1,
                                       0 to K_PARAM.SHAPE.C.SIZE-1) of K_ELEM_TYPE;
    signal    k_element       :  K_ELEM_VECTOR;
    signal    k_c_atrb        :  IMAGE_STREAM_ATRB_VECTOR(0 to K_PARAM.SHAPE.C.SIZE-1);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  Q_PARAM         :  IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS => O_PARAM.ELEM_BITS * QCONV_PARAM.NBITS_PER_WORD,
                                          C         => I_PARAM.SHAPE.C,
                                          D         => I_PARAM.SHAPE.D,
                                          X         => I_PARAM.SHAPE.X,
                                          Y         => I_PARAM.SHAPE.Y
                                      );
    subtype   Q_ELEM_TYPE     is std_logic_vector(Q_PARAM.ELEM_BITS-1 downto 0);
    type      Q_ELEM_VECTOR   is array(0 to Q_PARAM.SHAPE.Y.SIZE-1,
                                       0 to Q_PARAM.SHAPE.X.SIZE-1,
                                       0 to Q_PARAM.SHAPE.D.SIZE-1,
                                       0 to Q_PARAM.SHAPE.C.SIZE-1) of Q_ELEM_TYPE;
    signal    q_element       :  Q_ELEM_VECTOR;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    q_data          :  std_logic_vector(Q_PARAM.DATA.SIZE-1 downto 0);
    signal    q_valid         :  std_logic;
    signal    q_ready         :  std_logic;
    signal    output_data     :  std_logic_vector(Q_PARAM.DATA.SIZE-1 downto 0);
begin
    -------------------------------------------------------------------------------
    -- i_element : 入力パイプラインイメージデータを要素ごとの配列に変換
    -- i_c_valid : 入力パイプラインイメージデータのチャネル有効信号
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
    -- k_element : 入力パイプライン重みデータを要素ごとの配列に変換
    -- k_c_valid : 入力パイプライン重みデータのチャネル有効信号
    -------------------------------------------------------------------------------
    process (K_DATA) begin
        for y in 0 to K_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to K_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to K_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to K_PARAM.SHAPE.C.SIZE-1 loop
            k_element(y,x,d,c) <= GET_ELEMENT_FROM_IMAGE_STREAM_DATA(K_PARAM, c, d, x, y, K_DATA);
        end loop;
        end loop;
        end loop;
        end loop;
        k_c_atrb <= GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(K_PARAM, K_DATA);
    end process;
    -------------------------------------------------------------------------------
    -- o_element : 乗算結果
    -------------------------------------------------------------------------------
    process(i_element, i_c_atrb, k_element, k_c_atrb)
        variable i_data  :    signed(QCONV_PARAM.NBITS_IN_DATA  downto 0);
        variable k_data  :  unsigned(QCONV_PARAM.NBITS_K_DATA-1 downto 0);
        variable o_data  :    signed(O_PARAM.ELEM_BITS       -1 downto 0);
    begin
        for y in 0 to Q_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to Q_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to Q_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to Q_PARAM.SHAPE.C.SIZE-1 loop
            for i in 0 to QCONV_PARAM.NBITS_PER_WORD-1 loop
                if (i_c_atrb(c).VALID = TRUE and CHECK_K_VALID /= 0 and k_c_atrb(c).VALID = TRUE) or
                   (i_c_atrb(c).VALID = TRUE and CHECK_K_VALID  = 0                             ) then
                    i_data := signed("0" & i_element(y,x,d,c)((i+1)*QCONV_PARAM.NBITS_IN_DATA-1 downto i*QCONV_PARAM.NBITS_IN_DATA));
                    k_data := unsigned(    k_element(y,x,d,c)((i+1)*QCONV_PARAM.NBITS_K_DATA -1 downto i*QCONV_PARAM.NBITS_K_DATA ));
                    if (k_data(0) = '1') then
                        o_data := resize( i_data, O_PARAM.ELEM_BITS);
                    else
                        o_data := resize(-i_data, O_PARAM.ELEM_BITS);
                    end if;
                else
                        o_data := to_signed(0, O_PARAM.ELEM_BITS);
                end if;                         
                q_element(y,x,d,c)((i+1)*O_PARAM.ELEM_BITS-1 downto i*O_PARAM.ELEM_BITS) <= std_logic_vector(o_data);
            end loop;
        end loop;
        end loop;
        end loop;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    -- q_data    : パイプラインレジスタに入力するデータ
    -------------------------------------------------------------------------------
    process (q_element, I_DATA)
        variable data :  std_logic_vector(Q_PARAM.DATA.SIZE-1 downto 0);
    begin
        for y in 0 to Q_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to Q_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to Q_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to Q_PARAM.SHAPE.C.SIZE-1 loop
            SET_ELEMENT_TO_IMAGE_STREAM_DATA(Q_PARAM, c, d, x, y, q_element(y,x,d,c), data);
        end loop;        
        end loop;        
        end loop;        
        end loop;
        if (Q_PARAM.DATA.ATRB_FIELD.SIZE > 0) then
            data(Q_PARAM.DATA.ATRB_FIELD.HI downto Q_PARAM.DATA.ATRB_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_FIELD.HI downto I_PARAM.DATA.ATRB_FIELD.LO);
        end if;
        if (Q_PARAM.DATA.INFO_FIELD.SIZE > 0) then
            data(Q_PARAM.DATA.INFO_FIELD.HI downto Q_PARAM.DATA.INFO_FIELD.LO) := I_DATA(I_PARAM.DATA.INFO_FIELD.HI downto I_PARAM.DATA.INFO_FIELD.LO);
        end if;
        q_data <= data;
    end process;
    -------------------------------------------------------------------------------
    -- q_valid   : 
    -------------------------------------------------------------------------------
    q_valid <= '1' when (I_VALID = '1' and K_VALID = '1') else '0';
    I_READY <= '1' when (q_valid = '1' and q_ready = '1') else '0';
    K_READY <= '1' when (q_valid = '1' and q_ready = '1') else '0';
    -------------------------------------------------------------------------------
    -- パイプラインレジスタ
    -------------------------------------------------------------------------------
    QUEUE: PIPELINE_REGISTER                   -- 
        generic map (                          -- 
            QUEUE_SIZE  => QUEUE_SIZE        , --
            WORD_BITS   => Q_PARAM.DATA.SIZE   -- 
        )                                      -- 
        port map (                             -- 
            CLK         => CLK               , -- In  :
            RST         => RST               , -- In  :
            CLR         => CLR               , -- In  :
            I_WORD      => q_data            , -- In  :
            I_VAL       => q_valid           , -- In  :
            I_RDY       => q_ready           , -- Out :
            Q_WORD      => output_data       , -- Out :
            Q_VAL       => O_VALID           , -- Out :
            Q_RDY       => O_READY           , -- In  :
            BUSY        => open                -- Out :
        );                                     -- 
    -------------------------------------------------------------------------------
    -- O_DATA
    -------------------------------------------------------------------------------
    process (output_data)
        variable    data            :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        variable    q_elem          :  Q_ELEM_TYPE;
        variable    q_c_atrb_vector :  IMAGE_STREAM_ATRB_VECTOR(0 to Q_PARAM.SHAPE.C.SIZE-1);
        variable    o_c_atrb_vector :  IMAGE_STREAM_ATRB_VECTOR(0 to O_PARAM.SHAPE.C.SIZE-1);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        for y in 0 to Q_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to Q_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to Q_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to Q_PARAM.SHAPE.C.SIZE-1 loop
            q_elem := GET_ELEMENT_FROM_IMAGE_STREAM_DATA(Q_PARAM, c, d, x, y, output_data);
            for i in 0 to QCONV_PARAM.NBITS_PER_WORD-1 loop
                SET_ELEMENT_TO_IMAGE_STREAM_DATA(
                    PARAM    => O_PARAM,
                    C        => c*QCONV_PARAM.NBITS_PER_WORD+i,
                    D        => d,
                    X        => x,
                    Y        => y,
                    ELEMENT  => q_elem((i+1)*O_PARAM.ELEM_BITS-1 downto i*O_PARAM.ELEM_BITS),
                    DATA     => data
                );
            end loop;
        end loop;       
        end loop;       
        end loop;       
        end loop;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        q_c_atrb_vector := GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(Q_PARAM, output_data);
        for c in 0 to Q_PARAM.SHAPE.C.SIZE-1 loop
            for i in 0 to QCONV_PARAM.NBITS_PER_WORD-1 loop
                o_c_atrb_vector(c*QCONV_PARAM.NBITS_PER_WORD+i).VALID := q_c_atrb_vector(c).VALID;
                o_c_atrb_vector(c*QCONV_PARAM.NBITS_PER_WORD+i).START := FALSE;
                o_c_atrb_vector(c*QCONV_PARAM.NBITS_PER_WORD+i).LAST  := FALSE;
            end loop;
        end loop;
        o_c_atrb_vector(o_c_atrb_vector'low ).START := q_c_atrb_vector(q_c_atrb_vector'low ).START;
        o_c_atrb_vector(o_c_atrb_vector'high).LAST  := q_c_atrb_vector(q_c_atrb_vector'high).LAST;
        SET_ATRB_C_VECTOR_TO_IMAGE_STREAM_DATA(O_PARAM, o_c_atrb_vector, data);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        SET_ATRB_D_VECTOR_TO_IMAGE_STREAM_DATA(O_PARAM, GET_ATRB_D_VECTOR_FROM_IMAGE_STREAM_DATA(Q_PARAM, output_data), data);
        SET_ATRB_X_VECTOR_TO_IMAGE_STREAM_DATA(O_PARAM, GET_ATRB_X_VECTOR_FROM_IMAGE_STREAM_DATA(Q_PARAM, output_data), data);
        SET_ATRB_Y_VECTOR_TO_IMAGE_STREAM_DATA(O_PARAM, GET_ATRB_Y_VECTOR_FROM_IMAGE_STREAM_DATA(Q_PARAM, output_data), data);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        O_DATA <= data;
    end process;
end RTL;
