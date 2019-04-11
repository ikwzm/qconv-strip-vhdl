-----------------------------------------------------------------------------------
--!     @file    qconv_strip_controller.vhd
--!     @brief   Quantized Convolution (strip) Controller Module
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
library QCONV;
use     QCONV.QCONV_PARAMS.all;
-----------------------------------------------------------------------------------
--! @brief 
-----------------------------------------------------------------------------------
entity  QCONV_STRIP_CONTROLLER is
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
        USE_TH          : in  std_logic;
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
        CORE_USE_TH     : out std_logic;
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
        O_USE_TH        : out std_logic;
        O_REQ_VALID     : out std_logic;
        O_REQ_READY     : in  std_logic;
        O_RES_VALID     : in  std_logic;
        O_RES_READY     : out std_logic;
        O_RES_NONE      : in  std_logic;
        O_RES_ERROR     : in  std_logic
    );
end QCONV_STRIP_CONTROLLER;
-----------------------------------------------------------------------------------
-- アーキテクチャ本体
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_SLICE_RANGE_GENERATOR;
library QCONV;
use     QCONV.QCONV_PARAMS.all;
architecture RTL of QCONV_STRIP_CONTROLLER is
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
    signal    conv_3x3              :  boolean;
    signal    kernel_half_size      :  integer range 0 to 1;
    signal    in_data_c_by_word     :  integer range 0 to QCONV_PARAM.MAX_IN_C_BY_WORD;
    signal    in_data_x_size        :  integer range 0 to QCONV_PARAM.MAX_IN_W;
    signal    in_data_y_size        :  integer range 0 to QCONV_PARAM.MAX_IN_H;
    signal    in_data_pad_size      :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
    signal    out_data_c_size       :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
    signal    out_data_x_size       :  integer range 0 to QCONV_PARAM.MAX_OUT_W;
    signal    out_data_y_size       :  integer range 0 to QCONV_PARAM.MAX_OUT_H;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    in_data_slice_x_pos   :  integer range 0 to QCONV_PARAM.MAX_IN_W;
    signal    in_data_slice_x_size  :  integer range 0 to QCONV_PARAM.MAX_IN_W;
    signal    in_data_slice_y_pos   :  integer range 0 to QCONV_PARAM.MAX_IN_H;
    signal    in_data_slice_y_size  :  integer range 0 to QCONV_PARAM.MAX_IN_H;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    remain_out_c_size     :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
    signal    out_data_slice_c_max  :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
    signal    out_data_slice_c_pos  :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
    signal    out_data_slice_c_size :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
    signal    out_data_slice_c_last :  boolean;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    remain_out_x_size     :  integer range 0 to QCONV_PARAM.MAX_OUT_W;
    signal    out_data_slice_x_max  :  integer range 0 to QCONV_PARAM.MAX_OUT_W;
    signal    out_data_slice_x_pos  :  integer range 0 to QCONV_PARAM.MAX_OUT_W;
    signal    out_data_slice_x_size :  integer range 0 to QCONV_PARAM.MAX_OUT_W;
    signal    out_data_slice_x_first:  boolean;
    signal    out_data_slice_x_last :  boolean;
    signal    left_pad_size         :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
    signal    right_pad_size        :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
    signal    top_pad_size          :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
    signal    bottom_pad_size       :  integer range 0 to QCONV_PARAM.MAX_PAD_SIZE;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      EXT_STATE_TYPE        is (EXT_IDLE_STATE, EXT_REQ_STATE, EXT_RES_STATE);
    signal    conv_start            :  std_logic;
    signal    conv_busy             :  std_logic;
    signal    conv_core_start       :  std_logic;
    signal    conv_core_busy        :  std_logic;
    signal    in_data_read_start    :  std_logic;
    signal    in_data_read_busy     :  std_logic;
    signal    k_data_read_start     :  std_logic;
    signal    k_data_read_busy      :  std_logic;
    signal    th_data_read_start    :  std_logic;
    signal    th_data_read_busy     :  std_logic;
    signal    out_data_write_start  :  std_logic;
    signal    out_data_write_busy   :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- Top Level State Machine
    -------------------------------------------------------------------------------
    TOP: block
        ---------------------------------------------------------------------------
        -- K3x3 の場合、バッファの深さは   IN_C_UNROLL ワード単位でしか格納できない.
        -- K1x1 の場合、バッファの深さは 8*IN_C_UNROLL ワード単位でしか格納できない.
        -- ここでは入力された IN_C_BY_WORD を K3x3 の場合は IN_C_UNROLL 単位で、
        -- K1x1 の場合は 8*IN_C_UNROLL 切り上げる.
        -- 例えば K3x3 で IN_C_UNROLL が4 だった場合、
        --     IN_C_BY_WORD=1〜 4 -> ROUND_UP_IN_C_BY_WORD= 4
        --     IN_C_BY_WORD=5〜 8 -> ROUND_UP_IN_C_BY_WORD= 8
        --     IN_C_BY_WORD=9〜12 -> ROUND_UP_IN_C_BY_WORD=12
        -- rndup_in_c_by_word <= (IN_C_BY_WORD + ROUND_UP_MASK) and (not ROUND_UP_MASK);
        ---------------------------------------------------------------------------
        function  ROUND_UP_IN_C_BY_WORD(IN_C_BY_WORD: integer; C_UNROLL: integer) return integer is
            constant  ROUND_UP_MASK     :  unsigned(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0)
                                        := to_unsigned((2**CALC_BITS(C_UNROLL)-1), QCONV_PARAM.IN_C_BY_WORD_BITS);
            variable  u_in_c_by_word    :  unsigned(        QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
            variable  s_in_c_by_word    :  std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
            variable  i_in_c_by_word    :  integer range 0 to QCONV_PARAM.MAX_IN_C_BY_WORD;
        begin
            u_in_c_by_word := to_unsigned(IN_C_BY_WORD, QCONV_PARAM.IN_C_BY_WORD_BITS) + ROUND_UP_MASK;
            s_in_c_by_word := std_logic_vector(u_in_c_by_word) and (not std_logic_vector(ROUND_UP_MASK));
            i_in_c_by_word := to_integer(unsigned(s_in_c_by_word));
            return i_in_c_by_word;
        end function;
        ---------------------------------------------------------------------------
        -- 各バッファの深さ
        ---------------------------------------------------------------------------
        constant  IN_BUF_DEPTH          :  integer := IN_BUF_SIZE/(    IN_C_UNROLL);
        constant  K_BUF_DEPTH           :  integer := K_BUF_SIZE /(3*3*IN_C_UNROLL);
        ---------------------------------------------------------------------------
        -- バッファの深さを IN_C_BY_WORD で割る.
        -- ただし IN_CY_B_WORD は２のべき乗値に切り上げてから BUF_DEPTH を割る.
        --     IN_C_BY_WORD= 1     -> BUF_DEPTH/1
        --     IN_C_BY_WORD= 2     -> BUF_DEPTH/2
        --     IN_C_BY_WORD= 3〜 4 -> BUF_DEPTH/4
        --     IN_C_BY_WORD= 5〜 8 -> BUF_DEPTH/8
        --     IN_C_BY_WORD= 9〜16 -> BUF_DEPTH/16
        --     IN_C_BY_WORD=17〜32 -> BUF_DEPTH/32
        ---------------------------------------------------------------------------
        function  DEVIDE_BY_LOG2(BUF_DEPTH: integer; IN_C_BY_WORD: integer) return integer is
            variable  u_in_c_by_word    :  unsigned(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        begin
            u_in_c_by_word := to_unsigned(IN_C_BY_WORD, QCONV_PARAM.IN_C_BY_WORD_BITS) - 1;
            for i in u_in_c_by_word'high downto u_in_c_by_word'low loop
                if (u_in_c_by_word(i) = '1') then
                    return BUF_DEPTH/(2**(i+1));
                end if;
            end loop;
            return BUF_DEPTH;
        end function;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        type      STATE_TYPE            is (IDLE_STATE, PREP_STATE, START_STATE, WAIT_STATE, NEXT_STATE, RES_STATE);
        signal    state                 :  STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST)
            variable  rndup_in_c_by_word   :  integer range 0 to QCONV_PARAM.MAX_IN_C_BY_WORD;
            variable  slice_c_max          :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
            variable  slice_x_max          :  integer range 0 to QCONV_PARAM.MAX_OUT_C;
        begin
            if (RST = '1') then
                    state                  <= IDLE_STATE;
                    in_data_c_by_word      <= 0;
                    in_data_x_size         <= 0;
                    in_data_y_size         <= 0;
                    in_data_pad_size       <= 0;
                    remain_out_c_size      <= 0;
                    out_data_c_size        <= 0;
                    out_data_x_size        <= 0;
                    out_data_y_size        <= 0;
                    out_data_slice_c_max   <= 0;
                    out_data_slice_c_pos   <= 0;
                    out_data_slice_c_size  <= 0;
                    out_data_slice_c_last  <= FALSE;
                    out_data_slice_x_max   <= 0;
                    conv_3x3               <= FALSE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state                  <= IDLE_STATE;
                    in_data_c_by_word      <= 0;
                    in_data_x_size         <= 0;
                    in_data_y_size         <= 0;
                    in_data_pad_size       <= 0;
                    remain_out_c_size      <= 0;
                    out_data_c_size        <= 0;
                    out_data_x_size        <= 0;
                    out_data_y_size        <= 0;
                    out_data_slice_c_max   <= 0;
                    out_data_slice_c_pos   <= 0;
                    out_data_slice_c_size  <= 0;
                    out_data_slice_c_last  <= FALSE;
                    out_data_slice_x_max   <= 0;
                    conv_3x3               <= FALSE;
                else
                    case state is
                        when IDLE_STATE =>
                            if (REQ_VALID = '1') then
                                state <= PREP_STATE;
                            else
                                state <= IDLE_STATE;
                            end if;
                            in_data_c_by_word <= to_integer(unsigned(IN_C_BY_WORD));
                            in_data_x_size    <= to_integer(unsigned(IN_W));
                            in_data_y_size    <= to_integer(unsigned(IN_H));
                            in_data_pad_size  <= to_integer(unsigned(PAD_SIZE));
                            out_data_c_size   <= to_integer(unsigned(OUT_C));
                            out_data_x_size   <= to_integer(unsigned(OUT_W));
                            out_data_y_size   <= to_integer(unsigned(OUT_H));
                            remain_out_c_size <= to_integer(unsigned(OUT_C));
                            conv_3x3 <= ((to_integer(to_01(unsigned(K_W))) = 3) and
                                         (to_integer(to_01(unsigned(K_H))) = 3));
                        when PREP_STATE =>
                            if (conv_3x3) then
                                rndup_in_c_by_word   := ROUND_UP_IN_C_BY_WORD(in_data_c_by_word, IN_C_UNROLL    );
                                out_data_slice_c_max <= DEVIDE_BY_LOG2(     K_BUF_DEPTH, rndup_in_c_by_word); 
                                out_data_slice_x_max <= DEVIDE_BY_LOG2(    IN_BUF_DEPTH, rndup_in_c_by_word) - 2;
                                kernel_half_size     <= 1;
                            else
                                rndup_in_c_by_word   := ROUND_UP_IN_C_BY_WORD(in_data_c_by_word, IN_C_UNROLL * 8);
                                out_data_slice_c_max <= DEVIDE_BY_LOG2(8 *  K_BUF_DEPTH, rndup_in_c_by_word); 
                                out_data_slice_x_max <= DEVIDE_BY_LOG2(2 * IN_BUF_DEPTH, rndup_in_c_by_word);
                                kernel_half_size     <= 0;
                            end if;
                            out_data_slice_c_pos   <= 0;
                            out_data_slice_c_last  <= FALSE;
                            state <= START_STATE;
                        when START_STATE =>
                            if (remain_out_c_size <= out_data_slice_c_max) then
                                out_data_slice_c_size <= remain_out_c_size;
                                out_data_slice_c_last <= TRUE;
                            else
                                out_data_slice_c_size <= out_data_slice_c_max;
                                out_data_slice_c_last <= FALSE;
                            end if;
                            state <= WAIT_STATE;
                        when WAIT_STATE =>
                            if (k_data_read_busy = '0' and th_data_read_busy = '0' and conv_busy = '0') then
                                state <= NEXT_STATE;
                            else
                                state <= WAIT_STATE;
                            end if;
                        when NEXT_STATE =>
                            out_data_slice_c_pos <= out_data_slice_c_pos + out_data_slice_c_size;
                            remain_out_c_size    <= remain_out_c_size    - out_data_slice_c_size;
                            if (out_data_slice_c_last = TRUE) then
                                state <= RES_STATE;
                            else
                                state <= START_STATE;
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
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        REQ_READY  <= '1' when (state = IDLE_STATE) else '0';
        RES_VALID  <= '1' when (state = RES_STATE ) else '0';
        RES_STATUS <= '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv_start         <= '1' when (state = START_STATE) else '0';
        k_data_read_start  <= '1' when (state = START_STATE) else '0';
        th_data_read_start <= '1' when (state = START_STATE and USE_TH = '1') else '0';
    end block;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Main Control.
    -------------------------------------------------------------------------------
    CONV_CTRL: block
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        type      STATE_TYPE          is (IDLE_STATE,
                                          LOOP_START_STATE,
                                          GEN_REQ_STATE   ,
                                          GEN_RES_STATE   ,
                                          CORE_WAIT_STATE ,
                                          LOOP_NEXT_STATE);
        signal    state               :  STATE_TYPE;
        signal    gen_req_valid       :  std_logic;
        signal    gen_req_ready       :  std_logic;
        signal    gen_res_valid       :  std_logic;
        signal    gen_res_ready       :  std_logic;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  IMAGE_SHAPE         :  IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_CONSTANT(
                                             ELEM_BITS => 64,
                                             X         => QCONV_PARAM.MAX_IN_W,
                                             Y         => QCONV_PARAM.MAX_IN_H
                                         );
        constant  MIN_SLICE_X_POS     :  integer := - QCONV_PARAM.MAX_PAD_SIZE;
        constant  MAX_SLICE_X_POS     :  integer :=   QCONV_PARAM.MAX_IN_W;
        constant  MIN_SLICE_Y_POS     :  integer := - QCONV_PARAM.MAX_PAD_SIZE;
        constant  MAX_SLICE_Y_POS     :  integer :=   QCONV_PARAM.MAX_IN_H;
        signal    start_x_pos         :  integer range MIN_SLICE_X_POS to MAX_SLICE_X_POS;
        signal    next_x_pos          :  integer range MIN_SLICE_X_POS to MAX_SLICE_X_POS;
        signal    start_y_pos         :  integer range MIN_SLICE_Y_POS to MAX_SLICE_Y_POS;
        signal    next_y_pos          :  integer range MIN_SLICE_Y_POS to MAX_SLICE_Y_POS;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state                 <= IDLE_STATE;
                    remain_out_x_size     <= 0;
                    out_data_slice_x_pos  <= 0;
                    out_data_slice_x_size <= 0;
                    out_data_slice_x_first<= TRUE;
                    out_data_slice_x_last <= FALSE;
                    start_x_pos           <= 0;
                    start_y_pos           <= 0;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state                 <= IDLE_STATE;
                    remain_out_x_size     <= 0;
                    out_data_slice_x_pos  <= 0;
                    out_data_slice_x_size <= 0;
                    out_data_slice_x_first<= TRUE;
                    out_data_slice_x_last <= FALSE;
                    start_x_pos           <= 0;
                    start_y_pos           <= 0;
                else
                    case state is
                        when IDLE_STATE =>
                            if (conv_start = '1') then
                                state <= LOOP_START_STATE;
                            else
                                state <= IDLE_STATE;
                            end if;
                            remain_out_x_size     <= out_data_x_size;
                            out_data_slice_x_pos  <= 0;
                            out_data_slice_x_first<= TRUE;
                            out_data_slice_x_last <= FALSE;
                            start_x_pos           <= -(in_data_pad_size - kernel_half_size);
                            start_y_pos           <= -(in_data_pad_size - kernel_half_size);
                        when LOOP_START_STATE =>
                            if (remain_out_x_size <= out_data_slice_x_max) then
                                out_data_slice_x_size <= remain_out_x_size;
                                out_data_slice_x_last <= TRUE;
                            else
                                out_data_slice_x_size <= out_data_slice_x_max;
                                out_data_slice_x_last <= FALSE;
                            end if;
                            state     <= GEN_REQ_STATE;
                        when GEN_REQ_STATE =>
                            if (gen_req_ready = '1') then
                                state <= GEN_RES_STATE;
                            else
                                state <= GEN_REQ_STATE;
                            end if;
                        when GEN_RES_STATE =>
                            if (gen_res_valid = '1') then
                                state <= CORE_WAIT_STATE;
                            else
                                state <= GEN_RES_STATE;
                            end if;
                        when CORE_WAIT_STATE =>
                            if (conv_core_busy = '0' and in_data_read_busy = '0' and out_data_write_busy = '0') then
                                state <= LOOP_NEXT_STATE;
                            else
                                state <= CORE_WAIT_STATE;
                            end if;
                        when LOOP_NEXT_STATE =>
                            start_x_pos            <= next_x_pos;
                            out_data_slice_x_first <= FALSE;
                            out_data_slice_x_pos   <= out_data_slice_x_pos + out_data_slice_x_size;
                            remain_out_x_size      <= remain_out_x_size    - out_data_slice_x_size;
                            if (out_data_slice_x_last = TRUE) then
                                state <= IDLE_STATE;
                            else
                                state <= LOOP_START_STATE;
                            end if;
                        when others =>
                                state <= IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        conv_busy            <= '1' when (state /= IDLE_STATE      ) else '0';
        conv_core_start      <= '1' when (state  = GEN_RES_STATE and gen_res_valid = '1') else '0';
        in_data_read_start   <= '1' when (state  = GEN_RES_STATE and gen_res_valid = '1') else '0';
        out_data_write_start <= '1' when (state  = GEN_RES_STATE and gen_res_valid = '1') else '0';
        gen_req_valid        <= '1' when (state  = GEN_REQ_STATE   ) else '0';
        gen_res_ready        <= '1' when (state  = LOOP_NEXT_STATE ) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        GEN: IMAGE_SLICE_RANGE_GENERATOR
            generic map (
                SOURCE_SHAPE        => IMAGE_SHAPE         , --
                SLICE_SHAPE         => IMAGE_SHAPE         , --
                MIN_SLICE_X_POS     => MIN_SLICE_X_POS     , --
                MAX_SLICE_X_POS     => MAX_SLICE_X_POS     , --
                MIN_SLICE_Y_POS     => MIN_SLICE_Y_POS     , --
                MAX_SLICE_Y_POS     => MAX_SLICE_Y_POS     , --
                MAX_PAD_L_SIZE      => QCONV_PARAM.MAX_PAD_SIZE, --
                MAX_PAD_R_SIZE      => QCONV_PARAM.MAX_PAD_SIZE, --
                MAX_PAD_T_SIZE      => QCONV_PARAM.MAX_PAD_SIZE, --
                MAX_PAD_B_SIZE      => QCONV_PARAM.MAX_PAD_SIZE, --
                MAX_KERNEL_L_SIZE   => 1                   , --
                MAX_KERNEL_R_SIZE   => 1                   , --
                MAX_KERNEL_T_SIZE   => 1                   , --
                MAX_KERNEL_B_SIZE   => 1                     --
            )
            port map (
            -----------------------------------------------------------------------
            -- クロック&リセット信号
            -----------------------------------------------------------------------
                CLK                 => CLK                 , -- In  :
                RST                 => RST                 , -- In  :
                CLR                 => CLR                 , -- In  :
            -----------------------------------------------------------------------
            -- 計算に必要な情報
            -- これらの信号の値は計算中は変更してはならない.
            -----------------------------------------------------------------------
                SOURCE_X_SIZE       => in_data_x_size      , -- In  :
                SOURCE_Y_SIZE       => in_data_y_size      , -- In  :
                KERNEL_L_SIZE       => kernel_half_size    , -- In  :
                KERNEL_R_SIZE       => kernel_half_size    , -- In  :
                KERNEL_T_SIZE       => kernel_half_size    , -- In  :
                KERNEL_B_SIZE       => kernel_half_size    , -- In  :
            -----------------------------------------------------------------------
            -- 計算開始信号
            -----------------------------------------------------------------------
                REQ_START_X_POS     => start_x_pos         , -- In  :
                REQ_START_Y_POS     => start_y_pos         , -- In  :
                REQ_SLICE_X_SIZE    => out_data_slice_x_size,-- In  :
                REQ_SLICE_Y_SIZE    => out_data_y_size     , -- In  :
                REQ_VALID           => gen_req_valid       , -- In  :
                REQ_READY           => gen_req_ready       , -- Out :
            -----------------------------------------------------------------------
            -- 計算結果
            -----------------------------------------------------------------------
                RES_START_X_POS     => in_data_slice_x_pos , -- Out :
                RES_START_Y_POS     => in_data_slice_y_pos , -- Out :
                RES_SLICE_X_SIZE    => in_data_slice_x_size, -- Out :
                RES_SLICE_Y_SIZE    => in_data_slice_y_size, -- Out :
                RES_PAD_L_SIZE      => left_pad_size       , -- Out :
                RES_PAD_R_SIZE      => right_pad_size      , -- Out :
                RES_PAD_T_SIZE      => top_pad_size        , -- Out :
                RES_PAD_B_SIZE      => bottom_pad_size     , -- Out :
                RES_NEXT_X_POS      => next_x_pos          , -- Out :
                RES_NEXT_Y_POS      => open                , -- Out :
                RES_VALID           => gen_res_valid       , -- Out :
                RES_READY           => gen_res_ready         -- In  :
            );                                               -- 
    end block;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Core Module Control.
    -------------------------------------------------------------------------------
    CONV_CORE: block
        signal    state     :  EXT_STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state <= EXT_IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state <= EXT_IDLE_STATE;
                else
                    case state is
                        when EXT_IDLE_STATE =>
                            if (conv_core_start = '1') then
                                state <= EXT_REQ_STATE;
                            else
                                state <= EXT_IDLE_STATE;
                            end if;
                        when EXT_REQ_STATE  =>
                            if (CORE_REQ_READY = '1') then
                                state <= EXT_RES_STATE;
                            else
                                state <= EXT_REQ_STATE;
                            end if;
                        when EXT_RES_STATE =>
                            if (CORE_RES_VALID = '1') then
                                state <= EXT_IDLE_STATE;
                            else
                                state <= EXT_RES_STATE;
                            end if;
                        when others =>
                                state <= EXT_IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        conv_core_busy <= '1' when (state /= EXT_IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        CORE_REQ_VALID  <= '1' when (state = EXT_REQ_STATE) else '0';
        CORE_RES_READY  <= '1' when (state = EXT_RES_STATE) else '0';
        CORE_IN_C       <= std_logic_vector(to_unsigned(in_data_c_by_word    , QCONV_PARAM.IN_C_BY_WORD_BITS));
        CORE_IN_W       <= std_logic_vector(to_unsigned(in_data_slice_x_size , QCONV_PARAM.IN_W_BITS ));
        CORE_IN_H       <= std_logic_vector(to_unsigned(in_data_slice_y_size , QCONV_PARAM.IN_H_BITS ));
        CORE_OUT_C      <= std_logic_vector(to_unsigned(out_data_slice_c_size, QCONV_PARAM.OUT_C_BITS));
        CORE_OUT_W      <= std_logic_vector(to_unsigned(out_data_slice_x_size, QCONV_PARAM.OUT_W_BITS));
        CORE_OUT_H      <= std_logic_vector(to_unsigned(out_data_y_size      , QCONV_PARAM.OUT_H_BITS));
        CORE_K_W        <= K_W;
        CORE_K_H        <= K_H;
        CORE_USE_TH     <= USE_TH;
        CORE_PARAM_IN   <= '1' when (out_data_slice_x_first = TRUE) else '0';
        CORE_L_PAD_SIZE <= std_logic_vector(to_unsigned(left_pad_size        , QCONV_PARAM.PAD_SIZE_BITS));
        CORE_R_PAD_SIZE <= std_logic_vector(to_unsigned(right_pad_size       , QCONV_PARAM.PAD_SIZE_BITS));
        CORE_T_PAD_SIZE <= std_logic_vector(to_unsigned(top_pad_size         , QCONV_PARAM.PAD_SIZE_BITS));
        CORE_B_PAD_SIZE <= std_logic_vector(to_unsigned(bottom_pad_size      , QCONV_PARAM.PAD_SIZE_BITS));
    end block;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In Data AXI Reader Module Control
    -------------------------------------------------------------------------------
    IN_DATA_READ: block
        signal    state     :  EXT_STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state <= EXT_IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state <= EXT_IDLE_STATE;
                else
                    case state is
                        when EXT_IDLE_STATE =>
                            if (in_data_read_start = '1') then
                                state <= EXT_REQ_STATE;
                            else
                                state <= EXT_IDLE_STATE;
                            end if;
                        when EXT_REQ_STATE  =>
                            if (I_REQ_READY = '1') then
                                state <= EXT_RES_STATE;
                            else
                                state <= EXT_REQ_STATE;
                            end if;
                        when EXT_RES_STATE =>
                            if (I_RES_VALID = '1') then
                                state <= EXT_IDLE_STATE;
                            else
                                state <= EXT_RES_STATE;
                            end if;
                        when others =>
                                state <= EXT_IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        in_data_read_busy <= '1' when (state /= EXT_IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        I_REQ_VALID <= '1' when (state = EXT_REQ_STATE) else '0';
        I_RES_READY <= '1' when (state = EXT_RES_STATE) else '0';
        I_IN_C      <= std_logic_vector(to_unsigned(in_data_c_by_word   , QCONV_PARAM.IN_C_BY_WORD_BITS));
        I_IN_W      <= std_logic_vector(to_unsigned(in_data_x_size      , QCONV_PARAM.IN_W_BITS));
        I_IN_H      <= std_logic_vector(to_unsigned(in_data_slice_y_size, QCONV_PARAM.IN_H_BITS));
        I_X_POS     <= std_logic_vector(to_unsigned(in_data_slice_x_pos , QCONV_PARAM.IN_W_BITS));
        I_X_SIZE    <= std_logic_vector(to_unsigned(in_data_slice_x_size, QCONV_PARAM.IN_W_BITS));
    end block;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Kernel Weight Data AXI Reader Module Control
    -------------------------------------------------------------------------------
    K_DATA_READ: block
        signal    state     :  EXT_STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state <= EXT_IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state <= EXT_IDLE_STATE;
                else
                    case state is
                        when EXT_IDLE_STATE =>
                            if (k_data_read_start = '1') then
                                state <= EXT_REQ_STATE;
                            else
                                state <= EXT_IDLE_STATE;
                            end if;
                        when EXT_REQ_STATE  =>
                            if (K_REQ_READY = '1') then
                                state <= EXT_RES_STATE;
                            else
                                state <= EXT_REQ_STATE;
                            end if;
                        when EXT_RES_STATE =>
                            if (K_RES_VALID = '1') then
                                state <= EXT_IDLE_STATE;
                            else
                                state <= EXT_RES_STATE;
                            end if;
                        when others =>
                                state <= EXT_IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        k_data_read_busy <= '1' when (state /= EXT_IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        K_REQ_VALID  <= '1' when (state = EXT_REQ_STATE) else '0';
        K_RES_READY  <= '1' when (state = EXT_RES_STATE) else '0';
        K_IN_C       <= std_logic_vector(to_unsigned(in_data_c_by_word    , QCONV_PARAM.IN_C_BY_WORD_BITS));
        K_OUT_C      <= std_logic_vector(to_unsigned(out_data_c_size      , QCONV_PARAM.OUT_C_BITS));
        K_OUT_C_POS  <= std_logic_vector(to_unsigned(out_data_slice_c_pos , QCONV_PARAM.OUT_C_BITS));
        K_OUT_C_SIZE <= std_logic_vector(to_unsigned(out_data_slice_c_size, QCONV_PARAM.OUT_C_BITS));
        K_REQ_K3x3   <= '1' when (conv_3x3 = TRUE) else '0';
    end block;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Thresholds Data AXI Reader Module Control
    -------------------------------------------------------------------------------
    TH_DATA_READ: block
        signal    state     :  EXT_STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state <= EXT_IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state <= EXT_IDLE_STATE;
                else
                    case state is
                        when EXT_IDLE_STATE =>
                            if (th_data_read_start = '1') then
                                state <= EXT_REQ_STATE;
                            else
                                state <= EXT_IDLE_STATE;
                            end if;
                        when EXT_REQ_STATE  =>
                            if (T_REQ_READY = '1') then
                                state <= EXT_RES_STATE;
                            else
                                state <= EXT_REQ_STATE;
                            end if;
                        when EXT_RES_STATE =>
                            if (T_RES_VALID = '1') then
                                state <= EXT_IDLE_STATE;
                            else
                                state <= EXT_RES_STATE;
                            end if;
                        when others =>
                                state <= EXT_IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        th_data_read_busy <= '1' when (state /= EXT_IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        T_REQ_VALID  <= '1' when (state = EXT_REQ_STATE) else '0';
        T_RES_READY  <= '1' when (state = EXT_RES_STATE) else '0';
        T_OUT_C      <= std_logic_vector(to_unsigned(out_data_c_size      , QCONV_PARAM.OUT_C_BITS));
        T_OUT_C_POS  <= std_logic_vector(to_unsigned(out_data_slice_c_pos , QCONV_PARAM.OUT_C_BITS));
        T_OUT_C_SIZE <= std_logic_vector(to_unsigned(out_data_slice_c_size, QCONV_PARAM.OUT_C_BITS));
    end block;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Data AXI Writer Module Control
    -------------------------------------------------------------------------------
    OUT_DATA_WRITE: block
        signal    state     :  EXT_STATE_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (CLK, RST) begin
            if (RST = '1') then
                    state <= EXT_IDLE_STATE;
            elsif (CLK'event and CLK = '1') then
                if (CLR = '1') then
                    state <= EXT_IDLE_STATE;
                else
                    case state is
                        when EXT_IDLE_STATE =>
                            if (out_data_write_start = '1') then
                                state <= EXT_REQ_STATE;
                            else
                                state <= EXT_IDLE_STATE;
                            end if;
                        when EXT_REQ_STATE  =>
                            if (O_REQ_READY = '1') then
                                state <= EXT_RES_STATE;
                            else
                                state <= EXT_REQ_STATE;
                            end if;
                        when EXT_RES_STATE =>
                            if (O_RES_VALID = '1') then
                                state <= EXT_IDLE_STATE;
                            else
                                state <= EXT_RES_STATE;
                            end if;
                        when others =>
                                state <= EXT_IDLE_STATE;
                    end case;
                end if;
            end if;
        end process;
        out_data_write_busy <= '1' when (state /= EXT_IDLE_STATE) else '0';
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        O_REQ_VALID  <= '1' when (state = EXT_REQ_STATE) else '0';
        O_RES_READY  <= '1' when (state = EXT_RES_STATE) else '0';
        O_OUT_C      <= std_logic_vector(to_unsigned(out_data_c_size       , QCONV_PARAM.OUT_C_BITS));
        O_OUT_W      <= std_logic_vector(to_unsigned(out_data_x_size       , QCONV_PARAM.OUT_W_BITS));
        O_OUT_H      <= std_logic_vector(to_unsigned(out_data_y_size       , QCONV_PARAM.OUT_H_BITS));
        O_C_POS      <= std_logic_vector(to_unsigned(out_data_slice_c_pos  , QCONV_PARAM.OUT_C_BITS));
        O_C_SIZE     <= std_logic_vector(to_unsigned(out_data_slice_c_size , QCONV_PARAM.OUT_C_BITS));
        O_X_POS      <= std_logic_vector(to_unsigned(out_data_slice_x_pos  , QCONV_PARAM.OUT_W_BITS));
        O_X_SIZE     <= std_logic_vector(to_unsigned(out_data_slice_x_size , QCONV_PARAM.OUT_W_BITS));
        O_USE_TH     <= USE_TH;
    end block;
end RTL;
