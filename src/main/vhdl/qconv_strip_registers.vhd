-----------------------------------------------------------------------------------
--!     @file    qconv_strip_registers.vhd
--!     @brief   Quantized Convolution (strip) Registers Module
--!     @version 0.1.0
--!     @date    2019/5/1
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
entity  QCONV_STRIP_REGISTERS is
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    generic (
        ID              : --! @brief REGISTER ID STRING :
                          string(1 to 8) := "QCONV-S1";
        QCONV_PARAM     : --! @brief QCONV PARAMETER :
                          QCONV_PARAMS_TYPE := QCONV_COMMON_PARAMS;
        DATA_ADDR_WIDTH : --! @brief I_DATA_ADDR/K_DATA_ADDR/T_DATA_ADDR/O_DATA_ADDR WIDTH :
                          integer := 64;
        REGS_ADDR_WIDTH : --! @brief REGISTER ADDRESS WIDTH :
                          --! レジスタアクセスインターフェースのアドレスのビット数.
                          integer := 7;
        REGS_DATA_WIDTH : --! @brief REGISTER ADDRESS WIDTH :
                          --! レジスタアクセスインターフェースのデータのビット数.
                          integer := 32
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
    -- Register Access Interface
    -------------------------------------------------------------------------------
        REGS_REQ        : --! @brief REGISTER ACCESS REQUEST :
                          --! レジスタアクセス要求信号.
                          in  std_logic;
        REGS_WRITE      : --! @brief REGISTER WRITE ACCESS :
                          --! レジスタライトアクセス信号.
                          --! * この信号が'1'の時はライトアクセスを行う.
                          --! * この信号が'0'の時はリードアクセスを行う.
                          in  std_logic;
        REGS_ADDR       : --! @brief REGISTER ACCESS ADDRESS :
                          --! レジスタアクセスアドレス信号.
                          in  std_logic_vector(REGS_ADDR_WIDTH  -1 downto 0);
        REGS_BEN        : --! @brief REGISTER BYTE ENABLE :
                          --! レジスタアクセスバイトイネーブル信号.
                          in  std_logic_vector(REGS_DATA_WIDTH/8-1 downto 0);
        REGS_WDATA      : --! @brief REGISTER ACCESS WRITE DATA :
                          --! レジスタアクセスライトデータ.
                          in  std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        REGS_RDATA      : --! @brief REGISTER ACCESS READ DATA :
                          --! レジスタアクセスリードデータ.
                          out std_logic_vector(REGS_DATA_WIDTH  -1 downto 0);
        REGS_ACK        : --! @brief REGISTER ACCESS ACKNOWLEDGE :
                          --! レジスタアクセス応答信号.
                          out std_logic;
        REGS_ERR        : --! @brief REGISTER ACCESS ERROR ACKNOWLEDGE :
                          --! レジスタアクセスエラー応答信号.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Registers
    -------------------------------------------------------------------------------
        I_DATA_ADDR     : --! @brief IN  DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        O_DATA_ADDR     : --! @brief OUT DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        K_DATA_ADDR     : --! @brief K   DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        T_DATA_ADDR     : --! @brief TH  DATA ADDRESS REGISTER :
                          out std_logic_vector(DATA_ADDR_WIDTH-1 downto 0);
        I_WIDTH         : --! @brief IN  WIDTH REGISTER :
                          out std_logic_vector(QCONV_PARAM.IN_W_BITS        -1 downto 0);
        I_HEIGHT        : --! @brief IN  HEIGHT REGISTER :
                          out std_logic_vector(QCONV_PARAM.IN_H_BITS        -1 downto 0);
        I_CHANNELS      : --! @brief IN  CHANNELS REGISTER :
                          out std_logic_vector(QCONV_PARAM.IN_C_BY_WORD_BITS-1 downto 0);
        O_WIDTH         : --! @brief OUT WIDTH REGISTER :
                          out std_logic_vector(QCONV_PARAM.OUT_W_BITS       -1 downto 0);
        O_HEIGHT        : --! @brief OUT HEIGHT REGISTER :
                          out std_logic_vector(QCONV_PARAM.OUT_H_BITS       -1 downto 0);
        O_CHANNELS      : --! @brief OUT CHANNELS REGISTER :
                          out std_logic_vector(QCONV_PARAM.OUT_C_BITS       -1 downto 0);
        K_WIDTH         : --! @brief K   WIDTH REGISTER :
                          out std_logic_vector(QCONV_PARAM.K_W_BITS         -1 downto 0);
        K_HEIGHT        : --! @brief K   HEIGHT REGISTER :
                          out std_logic_vector(QCONV_PARAM.K_H_BITS         -1 downto 0);
        PAD_SIZE        : --! @brief PAD SIZE REGISTER :
                          out std_logic_vector(QCONV_PARAM.PAD_SIZE_BITS    -1 downto 0);
        USE_TH          : --! @brief USE THRESHOLD REGISTER :
                          out std_logic_vector(1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Request/Response Interface
    -------------------------------------------------------------------------------
        REQ_VALID       : --! @brief REQUEST VALID :
                          out std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          in  std_logic;
        RES_VALID       : --! @brief RESPONSE VALID :
                          in  std_logic;
        RES_READY       : --! @brief RESPONSE READY :
                          out std_logic;
        RES_STATUS      : --! @brief RESPONSE STATUS :
                          in  std_logic;
        REQ_RESET       : --! @brief RESET REQUEST :
                          out std_logic;
        REQ_STOP        : --! @brief STOP REQUEST :
                          out std_logic;
        REQ_PAUSE       : --! @brief PAUSE REQUEST :
                          out std_logic;
    -------------------------------------------------------------------------------
    -- Interrupt Request 
    -------------------------------------------------------------------------------
        IRQ             : --! @brief Interrupt Request :
                          out std_logic
    );
end QCONV_STRIP_REGISTERS;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.REGISTER_ACCESS_DECODER;
architecture RTL of QCONV_STRIP_REGISTERS is
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Registers
    -------------------------------------------------------------------------------
    --           31            24              16               8               0
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x00 |                                                       busy--| |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x04 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x08 |                                                      start--| |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x0C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x10 |                                           interrupt enable--| |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x14 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x18 |                             Status[31:00]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x1C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x20 |                   In  Data Address[31:00]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x24 |                   In  Data Address[63:32]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x28 |                   Out Data Address[31:00]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x2C |                   Out Data Address[63:32]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x30 |                   K   Data Address[31:00]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x34 |                   K   Data Address[63:32]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x38 |                   Th  Data Address[31:00]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x3C |                   Th  Data Address[63:32]                     |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x40 |                               |     In  Width  [15:00]        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x44 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x48 |                               |     In  Height [15:00]        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x4C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x50 |                               |     In  Channel[15:00]        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x54 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x58 |                               |     Out Width  [15:00]        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x5C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x60 |                               |     Out Height [15:00]        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x64 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x68 |                               |     Out Channel[15:00]        |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x6C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x70 |                                             | K  Width[03:00] |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x74 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x78 |                                             | K Height[03:00] |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x7C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x80 |                                             | Pad Size[03:00] |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x84 |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x88 |                                             |  Use Th [00:00] |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -- Addr=0x8C |                                                               |
    --           +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    -------------------------------------------------------------------------------
    constant  REGS_BASE_ADDR        :  integer := 16#00#;
    constant  REGS_DATA_BITS        :  integer := 16#90# * 8;
    -------------------------------------------------------------------------------
    -- レジスタアクセス用の信号群.
    -------------------------------------------------------------------------------
    signal    regs_load             :  std_logic_vector(REGS_DATA_BITS-1 downto 0);
    signal    regs_wbit             :  std_logic_vector(REGS_DATA_BITS-1 downto 0);
    signal    regs_rbit             :  std_logic_vector(REGS_DATA_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Busy Register
    -------------------------------------------------------------------------------
    -- Busy[63:1]  = 予約.
    -- Busy[0]     = 1: 動作中であることを示す. 0: 待機中であることを示す.
    -------------------------------------------------------------------------------
    constant  BUSY_REGS_ADDR        :  integer := REGS_BASE_ADDR + 16#00#;
    constant  BUSY_BUSY_POS         :  integer := 8*BUSY_REGS_ADDR + 0;
    constant  BUSY_RESV_LO          :  integer := 8*BUSY_REGS_ADDR + 1;
    constant  BUSY_RESV_HI          :  integer := 8*BUSY_REGS_ADDR + 64-1;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Control Register
    -------------------------------------------------------------------------------
    -- Control[63:1] = 予約.
    -- Control[0]    = 1 を書き込むことで動作を開始する.
    -------------------------------------------------------------------------------
    constant  CTRL_REGS_ADDR        :  integer := REGS_BASE_ADDR + 16#08#;
    constant  CTRL_START_POS        :  integer := 8*CTRL_REGS_ADDR + 0;
    constant  CTRL_RESV_LO          :  integer := 8*CTRL_REGS_ADDR + 1;
    constant  CTRL_RESV_HI          :  integer := 8*CTRL_REGS_ADDR + 64-1;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Interrupt Enable Register
    -------------------------------------------------------------------------------
    -- IrqEna[63:1] = 予約.
    -- IrqEna[0]    = 1: 割込みを許可する. 0: 割込みを禁止する.
    -------------------------------------------------------------------------------
    constant  IRQE_REGS_ADDR        :  integer := REGS_BASE_ADDR + 16#10#;
    constant  IRQE_IREQ_POS         :  integer := 8*IRQE_REGS_ADDR + 0;
    constant  IRQE_RESV_LO          :  integer := 8*IRQE_REGS_ADDR + 1;
    constant  IRQE_RESV_HI          :  integer := 8*IRQE_REGS_ADDR + 64-1;
    signal    irq_enable            :  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Status Register
    -------------------------------------------------------------------------------
    -- Status[63:2] = 予約.
    -- Status[1]    = 1: 動作が終了したことを示す.
    -- Status[0]    = 1: 割込みが発生したことを示す.
    -------------------------------------------------------------------------------
    constant  STAT_REGS_ADDR        :  integer := REGS_BASE_ADDR + 16#18#;
    constant  STAT_IRQ_POS          :  integer := 8*STAT_REGS_ADDR + 0;
    constant  STAT_DONE_POS         :  integer := 8*STAT_REGS_ADDR + 1;
    constant  STAT_RESV_LO          :  integer := 8*STAT_REGS_ADDR + 2;
    constant  STAT_RESV_HI          :  integer := 8*STAT_REGS_ADDR + 64-1;
    signal    status_done           :  std_logic;
    signal    status_irq            :  std_logic;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Data Address Register
    -------------------------------------------------------------------------------
    constant  I_DATA_ADDR_REGS_ADDR :  integer := REGS_BASE_ADDR + 16#20#;
    constant  I_DATA_ADDR_REGS_BITS :  integer := 64;
    constant  I_DATA_ADDR_REGS_LO   :  integer := 8*I_DATA_ADDR_REGS_ADDR;
    constant  I_DATA_ADDR_REGS_HI   :  integer := 8*I_DATA_ADDR_REGS_ADDR + I_DATA_ADDR_REGS_BITS-1;
    signal    i_data_addr_regs      :  std_logic_vector(I_DATA_ADDR_REGS_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Data Address Register
    -------------------------------------------------------------------------------
    constant  O_DATA_ADDR_REGS_ADDR :  integer := REGS_BASE_ADDR + 16#28#;
    constant  O_DATA_ADDR_REGS_BITS :  integer := 64;
    constant  O_DATA_ADDR_REGS_LO   :  integer := 8*O_DATA_ADDR_REGS_ADDR;
    constant  O_DATA_ADDR_REGS_HI   :  integer := 8*O_DATA_ADDR_REGS_ADDR + O_DATA_ADDR_REGS_BITS-1;
    signal    o_data_addr_regs      :  std_logic_vector(O_DATA_ADDR_REGS_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) K   Data Address Register
    -------------------------------------------------------------------------------
    constant  K_DATA_ADDR_REGS_ADDR :  integer := REGS_BASE_ADDR + 16#30#;
    constant  K_DATA_ADDR_REGS_BITS :  integer := 64;
    constant  K_DATA_ADDR_REGS_LO   :  integer := 8*K_DATA_ADDR_REGS_ADDR;
    constant  K_DATA_ADDR_REGS_HI   :  integer := 8*K_DATA_ADDR_REGS_ADDR + K_DATA_ADDR_REGS_BITS-1;
    signal    k_data_addr_regs      :  std_logic_vector(K_DATA_ADDR_REGS_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Th  Data Address Register
    -------------------------------------------------------------------------------
    constant  T_DATA_ADDR_REGS_ADDR :  integer := REGS_BASE_ADDR + 16#38#;
    constant  T_DATA_ADDR_REGS_BITS :  integer := 64;
    constant  T_DATA_ADDR_REGS_LO   :  integer := 8*T_DATA_ADDR_REGS_ADDR;
    constant  T_DATA_ADDR_REGS_HI   :  integer := 8*T_DATA_ADDR_REGS_ADDR + T_DATA_ADDR_REGS_BITS-1;
    signal    t_data_addr_regs      :  std_logic_vector(T_DATA_ADDR_REGS_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Width    Register
    -------------------------------------------------------------------------------
    constant  I_WIDTH_REGS_ADDR     :  integer := REGS_BASE_ADDR + 16#40#;
    constant  I_WIDTH_REGS_BITS     :  integer := I_WIDTH'length;
    constant  I_WIDTH_REGS_LO       :  integer := 8*I_WIDTH_REGS_ADDR;
    constant  I_WIDTH_REGS_HI       :  integer := 8*I_WIDTH_REGS_ADDR    + I_WIDTH_REGS_BITS-1;
    constant  I_WIDTH_RESV_LO       :  integer := I_WIDTH_REGS_HI        + 1;
    constant  I_WIDTH_RESV_HI       :  integer := 8*I_WIDTH_REGS_ADDR    + 64-1;
    signal    i_width_regs          :  std_logic_vector(I_WIDTH'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Height   Register
    -------------------------------------------------------------------------------
    constant  I_HEIGHT_REGS_ADDR    :  integer := REGS_BASE_ADDR + 16#48#;
    constant  I_HEIGHT_REGS_BITS    :  integer := I_HEIGHT'length;
    constant  I_HEIGHT_REGS_LO      :  integer := 8*I_HEIGHT_REGS_ADDR;
    constant  I_HEIGHT_REGS_HI      :  integer := 8*I_HEIGHT_REGS_ADDR   + I_HEIGHT_REGS_BITS-1;
    constant  I_HEIGHT_RESV_LO      :  integer := I_HEIGHT_REGS_HI       + 1;
    constant  I_HEIGHT_RESV_HI      :  integer := 8*I_HEIGHT_REGS_ADDR   + 64-1;
    signal    i_height_regs         :  std_logic_vector(I_HEIGHT'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Channels Register
    -------------------------------------------------------------------------------
    constant  I_CHANNELS_REGS_ADDR  :  integer := REGS_BASE_ADDR + 16#50#;
    constant  I_CHANNELS_REGS_BITS  :  integer := I_CHANNELS'length;
    constant  I_CHANNELS_REGS_LO    :  integer := 8*I_CHANNELS_REGS_ADDR;
    constant  I_CHANNELS_REGS_HI    :  integer := 8*I_CHANNELS_REGS_ADDR + I_CHANNELS_REGS_BITS-1;
    constant  I_CHANNELS_RESV_LO    :  integer := I_CHANNELS_REGS_HI     + 1;
    constant  I_CHANNELS_RESV_HI    :  integer := 8*I_CHANNELS_REGS_ADDR + 64-1;
    signal    i_channels_regs       :  std_logic_vector(I_CHANNELS'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Width    Register
    -------------------------------------------------------------------------------
    constant  O_WIDTH_REGS_ADDR     :  integer := REGS_BASE_ADDR + 16#58#;
    constant  O_WIDTH_REGS_BITS     :  integer := O_WIDTH'length;
    constant  O_WIDTH_REGS_LO       :  integer := 8*O_WIDTH_REGS_ADDR;
    constant  O_WIDTH_REGS_HI       :  integer := 8*O_WIDTH_REGS_ADDR    + O_WIDTH_REGS_BITS-1;
    constant  O_WIDTH_RESV_LO       :  integer := O_WIDTH_REGS_HI        + 1;
    constant  O_WIDTH_RESV_HI       :  integer := 8*O_WIDTH_REGS_ADDR    + 64-1;
    signal    o_width_regs          :  std_logic_vector(O_WIDTH'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Height   Register
    -------------------------------------------------------------------------------
    constant  O_HEIGHT_REGS_ADDR    :  integer := REGS_BASE_ADDR + 16#60#;
    constant  O_HEIGHT_REGS_BITS    :  integer := O_HEIGHT'length;
    constant  O_HEIGHT_REGS_LO      :  integer := 8*O_HEIGHT_REGS_ADDR;
    constant  O_HEIGHT_REGS_HI      :  integer := 8*O_HEIGHT_REGS_ADDR   + O_HEIGHT_REGS_BITS-1;
    constant  O_HEIGHT_RESV_LO      :  integer := O_HEIGHT_REGS_HI       + 1;
    constant  O_HEIGHT_RESV_HI      :  integer := 8*O_HEIGHT_REGS_ADDR   + 64-1;
    signal    o_height_regs         :  std_logic_vector(O_HEIGHT'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Channels Register
    -------------------------------------------------------------------------------
    constant  O_CHANNELS_REGS_ADDR  :  integer := REGS_BASE_ADDR + 16#68#;
    constant  O_CHANNELS_REGS_BITS  :  integer := O_CHANNELS'length;
    constant  O_CHANNELS_REGS_LO    :  integer := 8*O_CHANNELS_REGS_ADDR;
    constant  O_CHANNELS_REGS_HI    :  integer := 8*O_CHANNELS_REGS_ADDR + O_CHANNELS_REGS_BITS-1;
    constant  O_CHANNELS_RESV_LO    :  integer := O_CHANNELS_REGS_HI     + 1;
    constant  O_CHANNELS_RESV_HI    :  integer := 8*O_CHANNELS_REGS_ADDR + 64-1;
    signal    o_channels_regs       :  std_logic_vector(O_CHANNELS'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) K   Width    Register
    -------------------------------------------------------------------------------
    constant  K_WIDTH_REGS_ADDR     :  integer := REGS_BASE_ADDR + 16#70#;
    constant  K_WIDTH_REGS_BITS     :  integer := K_WIDTH'length;
    constant  K_WIDTH_REGS_LO       :  integer := 8*K_WIDTH_REGS_ADDR;
    constant  K_WIDTH_REGS_HI       :  integer := 8*K_WIDTH_REGS_ADDR    + K_WIDTH_REGS_BITS-1;
    constant  K_WIDTH_RESV_LO       :  integer := K_WIDTH_REGS_HI        + 1;
    constant  K_WIDTH_RESV_HI       :  integer := 8*K_WIDTH_REGS_ADDR    + 64-1;
    signal    k_width_regs          :  std_logic_vector(K_WIDTH'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) K   Height   Register
    -------------------------------------------------------------------------------
    constant  K_HEIGHT_REGS_ADDR    :  integer := REGS_BASE_ADDR + 16#78#;
    constant  K_HEIGHT_REGS_BITS    :  integer := K_HEIGHT'length;
    constant  K_HEIGHT_REGS_LO      :  integer := 8*K_HEIGHT_REGS_ADDR;
    constant  K_HEIGHT_REGS_HI      :  integer := 8*K_HEIGHT_REGS_ADDR   + K_HEIGHT_REGS_BITS-1;
    constant  K_HEIGHT_RESV_LO      :  integer := K_HEIGHT_REGS_HI       + 1;
    constant  K_HEIGHT_RESV_HI      :  integer := 8*K_HEIGHT_REGS_ADDR   + 64-1;
    signal    k_height_regs         :  std_logic_vector(K_HEIGHT'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Pad Size     Register
    -------------------------------------------------------------------------------
    constant  PAD_SIZE_REGS_ADDR    :  integer := REGS_BASE_ADDR + 16#80#;
    constant  PAD_SIZE_REGS_BITS    :  integer := PAD_SIZE'length;
    constant  PAD_SIZE_REGS_LO      :  integer := 8*PAD_SIZE_REGS_ADDR;
    constant  PAD_SIZE_REGS_HI      :  integer := 8*PAD_SIZE_REGS_ADDR   + PAD_SIZE_REGS_BITS-1;
    constant  PAD_SIZE_RESV_LO      :  integer := PAD_SIZE_REGS_HI       + 1;
    constant  PAD_SIZE_RESV_HI      :  integer := 8*PAD_SIZE_REGS_ADDR   + 64-1;
    signal    pad_size_regs         :  std_logic_vector(PAD_SIZE'range);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Use Threshold Register
    -------------------------------------------------------------------------------
    constant  USE_TH_REGS_ADDR      :  integer := REGS_BASE_ADDR + 16#88#;
    constant  USE_TH_REGS_BITS      :  integer := 2;
    constant  USE_TH_REGS_LO        :  integer := 8*USE_TH_REGS_ADDR;
    constant  USE_TH_REGS_HI        :  integer := 8*USE_TH_REGS_ADDR   + USE_TH_REGS_BITS-1;
    constant  USE_TH_RESV_LO        :  integer := USE_TH_REGS_HI       + 1;
    constant  USE_TH_RESV_HI        :  integer := 8*USE_TH_REGS_ADDR   + 64-1;
    signal    use_th_regs           :  std_logic_vector(USE_TH_REGS_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    type      STATE_TYPE            is (IDLE_STATE, REQ_STATE, RUN_STATE, DONE_STATE);
    signal    state                 :  STATE_TYPE;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    DEC: REGISTER_ACCESS_DECODER             -- 
        generic map (                        -- 
            ADDR_WIDTH  => REGS_ADDR_WIDTH , --
            DATA_WIDTH  => REGS_DATA_WIDTH , --
            WBIT_MIN    => regs_wbit'low   , --
            WBIT_MAX    => regs_wbit'high  , --
            RBIT_MIN    => regs_rbit'low   , --
            RBIT_MAX    => regs_rbit'high    --
        )                                    -- 
        port map (                           -- 
            REGS_REQ    => REGS_REQ        , -- In  :
            REGS_WRITE  => REGS_WRITE      , -- In  :
            REGS_ADDR   => REGS_ADDR       , -- In  :
            REGS_BEN    => REGS_BEN        , -- In  :
            REGS_WDATA  => REGS_WDATA      , -- In  :
            REGS_RDATA  => REGS_RDATA      , -- Out :
            REGS_ACK    => REGS_ACK        , -- Out :
            REGS_ERR    => REGS_ERR        , -- Out :
            W_DATA      => regs_wbit       , -- Out :
            W_LOAD      => regs_load       , -- Out :
            R_DATA      => regs_rbit         -- In  :
        );
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Control/Status Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                state       <= IDLE_STATE;
                irq_enable  <= '0';
                status_done <= '0';
                status_irq  <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                state       <= IDLE_STATE;
                irq_enable  <= '0';
                status_done <= '0';
                status_irq  <= '0';
            else
                case state is
                    when IDLE_STATE =>
                        if (regs_load(CTRL_START_POS) = '1' and regs_wbit(CTRL_START_POS) = '1') then
                            state <= REQ_STATE;
                            status_done <= '0';
                        else
                            state <= IDLE_STATE;
                        end if;
                    when REQ_STATE =>
                        if (REQ_READY = '1') then
                            state <= RUN_STATE;
                        else
                            state <= REQ_STATE;
                        end if;
                    when RUN_STATE =>
                        if (RES_VALID = '1') then
                            state <= DONE_STATE;
                        else
                            state <= RUN_STATE;
                        end if;
                    when DONE_STATE =>
                            state <= IDLE_STATE;
                            status_done <= '1';
                    when others => 
                            state <= IDLE_STATE;
                end case;
                if (regs_load(IRQE_IREQ_POS) = '1') then
                    irq_enable <= regs_wbit(IRQE_IREQ_POS);
                end if;
                if    (regs_load(STAT_IRQ_POS) = '1' and regs_wbit(STAT_IRQ_POS) = '1') then
                    status_irq <= '0';
                elsif (state = DONE_STATE) then
                    status_irq <= '1';
                end if;
            end if;
        end if;
    end process;
    REQ_VALID  <= '1' when (state  = REQ_STATE ) else '0';
    RES_READY  <= '1' when (state  = RUN_STATE ) else '0';
    REQ_RESET  <= '0';
    REQ_PAUSE  <= '0';
    REQ_STOP   <= '0';
    regs_rbit(BUSY_BUSY_POS ) <= '1' when (state /= IDLE_STATE) else '0';
    regs_rbit(BUSY_RESV_HI downto BUSY_RESV_LO) <= (BUSY_RESV_HI downto BUSY_RESV_LO => '0');
    regs_rbit(CTRL_START_POS) <= '0';
    regs_rbit(CTRL_RESV_HI downto CTRL_RESV_LO) <= (CTRL_RESV_HI downto CTRL_RESV_LO => '0');
    regs_rbit(IRQE_IREQ_POS ) <= irq_enable;
    regs_rbit(IRQE_RESV_HI downto IRQE_RESV_LO) <= (IRQE_RESV_HI downto IRQE_RESV_LO => '0');
    regs_rbit(STAT_IRQ_POS  ) <= status_irq;
    regs_rbit(STAT_DONE_POS ) <= status_done;
    regs_rbit(STAT_RESV_HI downto STAT_RESV_LO) <= (STAT_RESV_HI downto STAT_RESV_LO => '0');
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Data Address Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                i_data_addr_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                i_data_addr_regs <= (others => '0');
            else
                for pos in i_data_addr_regs'range loop
                    if (regs_load(pos+I_DATA_ADDR_REGS_LO) = '1') then
                        i_data_addr_regs(pos) <= regs_wbit(pos+I_DATA_ADDR_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(I_DATA_ADDR_REGS_HI downto I_DATA_ADDR_REGS_LO) <= i_data_addr_regs;
    I_DATA_ADDR <= i_data_addr_regs(I_DATA_ADDR'high downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Data Address Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                o_data_addr_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                o_data_addr_regs <= (others => '0');
            else
                for pos in o_data_addr_regs'range loop
                    if (regs_load(pos+O_DATA_ADDR_REGS_LO) = '1') then
                        o_data_addr_regs(pos) <= regs_wbit(pos+O_DATA_ADDR_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(O_DATA_ADDR_REGS_HI downto O_DATA_ADDR_REGS_LO) <= o_data_addr_regs;
    O_DATA_ADDR <= o_data_addr_regs(O_DATA_ADDR'high downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) K   Data Address Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                k_data_addr_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                k_data_addr_regs <= (others => '0');
            else
                for pos in k_data_addr_regs'range loop
                    if (regs_load(pos+K_DATA_ADDR_REGS_LO) = '1') then
                        k_data_addr_regs(pos) <= regs_wbit(pos+K_DATA_ADDR_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(K_DATA_ADDR_REGS_HI downto K_DATA_ADDR_REGS_LO) <= k_data_addr_regs;
    K_DATA_ADDR <= k_data_addr_regs(K_DATA_ADDR'high downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Th  Data Address Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                t_data_addr_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                t_data_addr_regs <= (others => '0');
            else
                for pos in t_data_addr_regs'range loop
                    if (regs_load(pos+T_DATA_ADDR_REGS_LO) = '1') then
                        t_data_addr_regs(pos) <= regs_wbit(pos+T_DATA_ADDR_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(T_DATA_ADDR_REGS_HI downto T_DATA_ADDR_REGS_LO) <= t_data_addr_regs;
    T_DATA_ADDR <= t_data_addr_regs(T_DATA_ADDR'high downto 0);
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Width    Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                i_width_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                i_width_regs <= (others => '0');
            else
                for pos in i_width_regs'range loop
                    if (regs_load(pos+I_WIDTH_REGS_LO) = '1') then
                        i_width_regs(pos) <= regs_wbit(pos+I_WIDTH_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(I_WIDTH_REGS_HI downto I_WIDTH_REGS_LO) <= i_width_regs;
    regs_rbit(I_WIDTH_RESV_HI downto I_WIDTH_RESV_LO) <= (I_WIDTH_RESV_HI downto I_WIDTH_RESV_LO => '0');
    I_WIDTH <= i_width_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Height   Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                i_height_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                i_height_regs <= (others => '0');
            else
                for pos in i_height_regs'range loop
                    if (regs_load(pos+I_HEIGHT_REGS_LO) = '1') then
                        i_height_regs(pos) <= regs_wbit(pos+I_HEIGHT_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(I_HEIGHT_REGS_HI downto I_HEIGHT_REGS_LO) <= i_height_regs;
    regs_rbit(I_HEIGHT_RESV_HI downto I_HEIGHT_RESV_LO) <= (I_HEIGHT_RESV_HI downto I_HEIGHT_RESV_LO => '0');
    I_HEIGHT <= i_height_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) In  Channels Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                i_channels_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                i_channels_regs <= (others => '0');
            else
                for pos in i_channels_regs'range loop
                    if (regs_load(pos+I_CHANNELS_REGS_LO) = '1') then
                        i_channels_regs(pos) <= regs_wbit(pos+I_CHANNELS_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(I_CHANNELS_REGS_HI downto I_CHANNELS_REGS_LO) <= i_channels_regs;
    regs_rbit(I_CHANNELS_RESV_HI downto I_CHANNELS_RESV_LO) <= (I_CHANNELS_RESV_HI downto I_CHANNELS_RESV_LO => '0');
    I_CHANNELS <= i_channels_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Width    Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                o_width_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                o_width_regs <= (others => '0');
            else
                for pos in o_width_regs'range loop
                    if (regs_load(pos+O_WIDTH_REGS_LO) = '1') then
                        o_width_regs(pos) <= regs_wbit(pos+O_WIDTH_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(O_WIDTH_REGS_HI downto O_WIDTH_REGS_LO) <= o_width_regs;
    regs_rbit(O_WIDTH_RESV_HI downto O_WIDTH_RESV_LO) <= (O_WIDTH_RESV_HI downto O_WIDTH_RESV_LO => '0');
    O_WIDTH <= o_width_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Height   Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                o_height_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                o_height_regs <= (others => '0');
            else
                for pos in o_height_regs'range loop
                    if (regs_load(pos+O_HEIGHT_REGS_LO) = '1') then
                        o_height_regs(pos) <= regs_wbit(pos+O_HEIGHT_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(O_HEIGHT_REGS_HI downto O_HEIGHT_REGS_LO) <= o_height_regs;
    regs_rbit(O_HEIGHT_RESV_HI downto O_HEIGHT_RESV_LO) <= (O_HEIGHT_RESV_HI downto O_HEIGHT_RESV_LO => '0');
    O_HEIGHT <= o_height_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Out Channels Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                o_channels_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                o_channels_regs <= (others => '0');
            else
                for pos in o_channels_regs'range loop
                    if (regs_load(pos+O_CHANNELS_REGS_LO) = '1') then
                        o_channels_regs(pos) <= regs_wbit(pos+O_CHANNELS_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(O_CHANNELS_REGS_HI downto O_CHANNELS_REGS_LO) <= o_channels_regs;
    regs_rbit(O_CHANNELS_RESV_HI downto O_CHANNELS_RESV_LO) <= (O_CHANNELS_RESV_HI downto O_CHANNELS_RESV_LO => '0');
    O_CHANNELS <= o_channels_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) K   Width    Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                k_width_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                k_width_regs <= (others => '0');
            else
                for pos in k_width_regs'range loop
                    if (regs_load(pos+K_WIDTH_REGS_LO) = '1') then
                        k_width_regs(pos) <= regs_wbit(pos+K_WIDTH_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(K_WIDTH_REGS_HI downto K_WIDTH_REGS_LO) <= k_width_regs;
    regs_rbit(K_WIDTH_RESV_HI downto K_WIDTH_RESV_LO) <= (K_WIDTH_RESV_HI downto K_WIDTH_RESV_LO => '0');
    K_WIDTH <= k_width_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) K   Height   Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                k_height_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                k_height_regs <= (others => '0');
            else
                for pos in k_height_regs'range loop
                    if (regs_load(pos+K_HEIGHT_REGS_LO) = '1') then
                        k_height_regs(pos) <= regs_wbit(pos+K_HEIGHT_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(K_HEIGHT_REGS_HI downto K_HEIGHT_REGS_LO) <= k_height_regs;
    regs_rbit(K_HEIGHT_RESV_HI downto K_HEIGHT_RESV_LO) <= (K_HEIGHT_RESV_HI downto K_HEIGHT_RESV_LO => '0');
    K_HEIGHT <= k_height_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Pad Size     Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                pad_size_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                pad_size_regs <= (others => '0');
            else
                for pos in pad_size_regs'range loop
                    if (regs_load(pos+PAD_SIZE_REGS_LO) = '1') then
                        pad_size_regs(pos) <= regs_wbit(pos+PAD_SIZE_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(PAD_SIZE_REGS_HI downto PAD_SIZE_REGS_LO) <= pad_size_regs;
    regs_rbit(PAD_SIZE_RESV_HI downto PAD_SIZE_RESV_LO) <= (PAD_SIZE_RESV_HI downto PAD_SIZE_RESV_LO => '0');
    PAD_SIZE <= pad_size_regs;
    -------------------------------------------------------------------------------
    -- Quantized Convolution (strip) Use Threshold Register
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                use_th_regs <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                use_th_regs <= (others => '0');
            else
                for pos in use_th_regs'range loop
                    if (regs_load(pos+USE_TH_REGS_LO) = '1') then
                        use_th_regs(pos) <= regs_wbit(pos+USE_TH_REGS_LO);
                    end if;
                end loop;
            end if;
        end if;
    end process;
    regs_rbit(USE_TH_REGS_HI downto USE_TH_REGS_LO) <= use_th_regs;
    regs_rbit(USE_TH_RESV_HI downto USE_TH_RESV_LO) <= (USE_TH_RESV_HI downto USE_TH_RESV_LO => '0');
    USE_TH <= use_th_regs;
    -------------------------------------------------------------------------------
    -- Interrupt Request
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                IRQ <= '0';
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                IRQ <= '0';
            elsif (irq_enable = '1' and status_irq = '1') then
                IRQ <= '1';
            else
                IRQ <= '0';
            end if;
        end if;
    end process;
end RTL;
