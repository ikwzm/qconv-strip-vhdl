#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------
#
#       Version     :   0.1.0
#       Created     :   2019/4/26
#       File name   :   qconv_strib.rb
#       Author      :   Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
#       Description :   QCONV_STRIP 用の Dummy_Plug のシナリオを生成するモジュール
#
#---------------------------------------------------------------------------------
#
#       Copyright (C) 2019 Ichiro Kawazome
#       All rights reserved.
# 
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions
#       are met:
# 
#         1. Redistributions of source code must retain the above copyright
#            notice, this list of conditions and the following disclaimer.
# 
#         2. Redistributions in binary form must reproduce the above copyright
#            notice, this list of conditions and the following disclaimer in
#            the documentation and/or other materials provided with the
#            distribution.
# 
#       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#       "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#       A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
#       OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#       SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#       DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#       THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#       OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
#---------------------------------------------------------------------------------
module Dummy_Plug
  module ScenarioWriter
    module QConvStrip
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class InData
        attr_reader   :channels, :width,  :height, :pad_size, :channels_by_word
        attr_reader   :data
        def initialize(c, w, h, ps, &block)
          @channels = c
          @width    = w
          @height   = h
          @pad_size = ps
          @channels_by_word = (c + 31).div(32)
          if block_given?
            @data   = Array.new(h){Array.new(w){Array.new(@channels_by_word*32, &block) }}
          else
            @data   = Array.new(h){Array.new(w){Array.new(@channels_by_word*32, 0)}}
          end
        end
        def read(c, x, y)
          return @data[y][x][c]
        end
        def write(c, x, y, data)
          @data[y][x][c] = data
        end
        def read_by_word(c_by_word, x, y)
          value = 0
          32.times do |i|
            data   = read(c_by_word*32+i, x, y)
            value |= ((data & 1) << (i+ 0  ))
            value |= ((data & 2) << (i+32-1))
          end
          return value
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class OutData
        attr_reader   :channels, :width,  :height, :use_th
        attr_reader   :data
        def initialize(c, w, h, use_th=0, &block)
          @channels = c
          @width    = w
          @height   = h
          @use_th   = use_th
          if block_given?
            @data   = Array.new(h){Array.new(w){Array.new(c, &block)}}
          else
            @data   = Array.new(h){Array.new(w){Array.new(c, 0)}}
          end
        end
        def read(c, x, y)
          return @data[y][x][c]
        end
        def write(c, x, y, data)
          @data[y][x][c] = data
        end
        def convolution(i_data, k_data)
          k_w = (k_data.kernel_width  == 3) ? [-1,0,1] : [0]
          k_h = (k_data.kernel_height == 3) ? [-1,0,1] : [0]
          @channels.times do |oc|
            i_data.height.times do |y|
              i_data.width.times do |x|
                if x < @width and y < @height
                  data = 0
                  k_h.each_with_index do |ky_pos, ky_idx|
                    k_w.each_with_index do |kx_pos, kx_idx|
                      i_data.channels.times do |ic|
                        if (x+kx_pos >= 0 and x+kx_pos < i_data.width and
                            y+ky_pos >= 0 and y+ky_pos < i_data.height)
                          d = i_data.read(ic, x+kx_pos, y+ky_pos)
                        else
                          d = 0
                        end
                        if (k_data.read(ic, kx_idx, ky_idx, oc) > 0)
                          data = data + d
                        else
                          data = data - d
                        end
                      end
                    end
                  end
                  write(oc, x, y, data)
                end
              end
            end
          end
          return self
        end
        def apply_thresholds(t_data, use_th)
          o_data = OutData.new(@channels, @width, @height, use_th)
          @height.times do |y|
            @width.times do |x|
              @channels.times do |c|
                o  = read(c, x, y)
                t0 = t_data.read(c,0)
                t1 = t_data.read(c,1)
                t2 = t_data.read(c,2)
                t3 = t_data.read(c,3)
                if (t3 == 1) then
                  if    (o < t0) then
                    o_data.write(c, x, y, 0)
                  elsif (o < t1) then
                    o_data.write(c, x, y, 1)
                  elsif (o < t2) then
                    o_data.write(c, x, y, 2)
                  else
                    o_data.write(c, x, y, 3)
                  end
                elsif (t3 == -1) then
                  if    (o > t2) then
                    o_data.write(c, x, y, 0)
                  elsif (o > t1) then
                    o_data.write(c, x, y, 1)
                  elsif (o > t0) then
                    o_data.write(c, x, y, 2)
                  else
                    o_data.write(c, x, y, 3)
                  end
                else
                    o_data.write(c, x, y, t3-2)
                end
              end
            end
          end
          return o_data
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class KernelData
        attr_reader   :kernel_depth,  :kernel_width,  :kernel_height, :output_channels
        attr_reader   :kernel_depth_by_word
        attr_reader   :data
        def initialize(ic, kw, kh, oc, &block)
          @kernel_depth    = ic
          @kernel_width    = kw
          @kernel_height   = kh
          @output_channels = oc
          @kernel_depth_by_word = (ic + 31).div(32)
          if block_given?
            @data = Array.new(kh){Array.new(kw){Array.new(oc){Array.new(@kernel_depth_by_word*32, &block)}}}
          else
            @data = Array.new(kh){Array.new(kw){Array.new(oc){Array.new(@kernel_depth_by_word*32, 0)}}}
          end
        end
        def read(ic, kw, kh, oc)
          return @data[kh][kw][oc][ic]
        end
        def write(ic, kw, kh, oc, data)
          @data[kh][kw][oc][ic] = data
        end
        def read_by_word(c_by_word, x, y, oc)
          value = 0
          32.times do |i|
            data   = read(c_by_word*32+i, x, y, oc)
            value |= ((data & 1) << i)
          end
          return value
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class ThresholdsData
        attr_reader   :channels
        attr_reader   :data
        def initialize(c)
          @channels = c
          @data     = Array.new(c){Array.new(4, 0)}
        end
        def read(c,i)
          return @data[c][i]
        end
        def write(c,i,data)
          @data[c][i] = data
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class AXI_Memory
        attr_reader   :name, :size, :addr_start, :addr_last, :read, :write
        def initialize(name, size, addr_start, read, write)
          @name       = name
          @size       = size
          @addr_start = addr_start
          @addr_last  = addr_start + size - 1
          @read       = read
          @write      = write
        end
        def generate_domain
          index = 0
          str  = "- #{@name}:\n"
          str += "  - {DOMAIN: {INDEX: #{index}, MAP: 0, READ: true, WRITE: true,\n"
          str += sprintf("               ADDR: 0x%08X, LAST: 0x%08X, RESP: DECERR,\n", 0, 0xFFFFFFFF)
          str += "              ASIZE: \"3'b---\", ALOCK: \"1'b-\", ACACHE: \"4'b----\", APROT: \"3'b---\", AQOS: \"4'b----\", AREGION: \"4'b----\",\n"
          str += "              LATENCY: 8, TIMEOUT: 10000}}\n"
          index = index + 1
          if @read == true then
            str += "  - {DOMAIN: {INDEX: #{index}, MAP: 0, READ: true, WRITE: false,\n"
            str += sprintf("               ADDR: 0x%08X, LAST: 0x%08X, RESP: OKAY,  \n", @addr_start, @addr_last)
            str += "              ASIZE: \"3'b---\", ALOCK: \"1'b-\", ACACHE: \"4'b----\", APROT: \"3'b---\", AQOS: \"4'b----\", AREGION: \"4'b----\",\n"
            str += "              LATENCY: 12, RDELAY: 1, TIMEOUT: 10000}}\n"
            index = index + 1
          end
          if @write == true then
            str += "  - {DOMAIN: {INDEX: #{index}, MAP: 0, READ: false, WRITE: true,\n"
            str += sprintf("               ADDR: 0x%08X, LAST: 0x%08X, RESP: OKAY,  \n", @addr_start, @addr_last)
            str += "              ASIZE: \"3'b---\", ALOCK: \"1'b-\", ACACHE: \"4'b----\", APROT: \"3'b---\", AQOS: \"4'b----\", AREGION: \"4'b----\",\n"
            str += "              LATENCY: 1, RDELAY: 12, TIMEOUT: 10000}}\n"
            index = index + 1
          end
          return str
        end
        def generate_clear(size=nil, org=0, data=0)
          if size.nil? then
            size = @last_addr - @start_addr + 1
          end
          str  = "- #{@name}:\n"
          str += "  - FILL  : #{size}\n"
          str += "  - ORG   : #{org}\n"
          str += "  - DB    : #{data}\n"
          return str
        end
        def generate_run(timeout)
          str  = "- #{@name}:\n"
          str += "  - WAIT  : {GPI(0): 1, TIMEOUT: #{timeout}}\n"
          str += "  - START\n"
          str += "  - WAIT  : {GPI(0): 0, TIMEOUT: #{timeout}}\n"
          str += "  - STOP\n"
          return str
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class InDataMemory < AXI_Memory
        def initialize(name, size, addr_start)
          super(name, size, addr_start, true, false)
        end
        def generate_data(data, org=0)
          data_size = data.channels_by_word * data.width * data.height * 8
          warn "#{self.class}(#{@name}) data overflow (memory size = #{@size}, data size = #{data_size})" if (data_size > @size)
          str  = "- #{@name}:\n"
          str += "  - SET\n"
          str += sprintf("  - ORG   : 0x%08X         #   H   W  C \n", org)
          data.height.times do |y|
            data.width.times do |x|
              data.channels_by_word.times do |c|
                str += sprintf("  - DD    : 0x%016X # %3d %3d %2d\n", data.read_by_word(c, x, y), y, x, c)
              end
            end
          end
          return str
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class KernelDataMemory < AXI_Memory
        def initialize(name, size, addr_start)
          super(name, size, addr_start, true, false)
        end
        def generate_data(data, org=0)
          data_size = data.output_channels * data.kernel_depth_by_word * data.kernel_width * data.kernel_height * 4
          warn "#{self.class}(#{@name}) data overflow (memory size = #{@size}, data size = #{data_size})" if (data_size > @size)
          str  = "- #{@name}:\n"
          str += "  - SET\n"
          str += sprintf("  - ORG   : 0x%08X #  N  H  W  C \n", org)
          data.output_channels.times do |oc|
            data.kernel_height.times   do |ky|
              data.kernel_width.times    do |kx|
                data.kernel_depth_by_word.times do |ic|
                  str += sprintf("  - DW    : 0x%08X # %2d %2d %2d %2d\n", data.read_by_word(ic, kx, ky, oc), oc, ky, kx, ic)
                end
              end
            end
          end
          return str
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class ThresholdsDataMemory < AXI_Memory
        def initialize(name, size, addr_start)
          super(name, size, addr_start, true, false)
        end
        def generate_data(data, org=0)
          data_size = data.channels * 4 * 2
          warn "#{self.class}(#{@name}) data overflow (memory size = #{@size}, data size = #{data_size})" if (data_size > @size)
          str  = "- #{@name}:\n"
          str += "  - SET\n"
          str += sprintf("  - ORG   : 0x%04X\n", org)
          data.channels.times do |c|
            str += sprintf("  - DH    : [0x%04X, 0x%04X, 0x%04X, 0x%04X]\n", data.read(c,0) & 0xFFFF, data.read(c,1) & 0xFFFF, data.read(c,2) & 0xFFFF, data.read(c,3) & 0xFFFF)
          end
          return str
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class OutDataMemory < AXI_Memory
        def initialize(name, size, addr_start)
          super(name, size, addr_start, false, true)
        end
        def generate_check(data, org=0)
          if (data.use_th == 3) then
            channels_by_word = (data.channels+31).div(32)
            data_size = channels_by_word * data.width * data.height * 8
            warn "#{self.class}(#{@name}) data overflow (memory size = #{@size}, data size = #{data_size})" if (data_size > @size)
            str  = "- #{@name}:\n"
            str += "  - CHECK\n"
            str += sprintf("  - ORG   : 0x%08X         #   Y   X   C \n", org)
            data.height.times do |y|
              data.width.times   do |x|
                channels_by_word.times do |c|
                  value = 0
                  32.times do |i|
                    d      = data.read(c*32+i, x, y)
                    value |= ((d & 1) << (i+ 0  ))
                    value |= ((d & 2) << (i+32-1))
                  end
                  str += sprintf("  - DD    : 0x%016X # %3d %3d %3d\n", value, y, x, c*32)
                end
              end
            end
            return str
          elsif (data.use_th == 2) then
            data_size = data.channels * data.width * data.height * 1
            warn "#{self.class}(#{@name}) data overflow (memory size = #{@size}, data size = #{data_size})" if (data_size > @size)
            str  = "- #{@name}:\n"
            str += "  - CHECK\n"
            str += sprintf("  - ORG   : 0x%08X         #   Y   X   C \n", org)
            data.height.times do |y|
              data.width.times   do |x|
                data.channels.times do |c|
                  str += sprintf("  - DB    : 0x%02X       # %3d %3d %3d\n", data.read(c, x, y) & 0xFF, y, x, c)
                end
              end
            end
            return str
          else
            data_size = data.channels * data.width * data.height * 2
            warn "#{self.class}(#{@name}) data overflow (memory size = #{@size}, data size = #{data_size})" if (data_size > @size)
            str  = "- #{@name}:\n"
            str += "  - CHECK\n"
            str += sprintf("  - ORG   : 0x%08X #   Y   X   C \n", org)
            data.height.times do |y|
              data.width.times   do |x|
                data.channels.times do |c|
                  str += sprintf("  - DH    : 0x%04X     # %3d %3d %3d\n", data.read(c, x, y) & 0xFFFF, y, x, c)
                end
              end
            end
            return str
          end
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class RegisterIO
        attr_reader   :name
        attr_reader   :regs_addr
        attr_reader   :busy_regs_addr
        attr_reader   :control_regs_addr
        attr_reader   :irq_enable_regs_addr
        attr_reader   :status_regs_addr
        attr_reader   :i_data_addr_regs_addr
        attr_reader   :o_data_addr_regs_addr
        attr_reader   :k_data_addr_regs_addr
        attr_reader   :t_data_addr_regs_addr
        attr_reader   :i_width_regs_addr
        attr_reader   :i_height_regs_addr
        attr_reader   :i_channels_regs_addr
        attr_reader   :o_width_regs_addr
        attr_reader   :o_height_regs_addr
        attr_reader   :o_channels_regs_addr
        attr_reader   :k_width_regs_addr
        attr_reader   :k_height_regs_addr
        attr_reader   :pad_size_regs_addr
        attr_reader   :use_th_regs_addr
        def initialize(name, regs_addr)
          @name = name
          @regs_addr             = regs_addr
          @busy_regs_addr        = regs_addr + 0x00
          @control_regs_addr     = regs_addr + 0x08
          @irq_enable_regs_addr  = regs_addr + 0x10
          @status_regs_addr      = regs_addr + 0x18
          @i_data_addr_regs_addr = regs_addr + 0x20
          @o_data_addr_regs_addr = regs_addr + 0x28
          @k_data_addr_regs_addr = regs_addr + 0x30
          @t_data_addr_regs_addr = regs_addr + 0x38
          @i_width_regs_addr     = regs_addr + 0x40
          @i_height_regs_addr    = regs_addr + 0x48
          @i_channels_regs_addr  = regs_addr + 0x50
          @o_width_regs_addr     = regs_addr + 0x58
          @o_height_regs_addr    = regs_addr + 0x60
          @o_channels_regs_addr  = regs_addr + 0x68
          @k_width_regs_addr     = regs_addr + 0x70
          @k_height_regs_addr    = regs_addr + 0x78
          @pad_size_regs_addr    = regs_addr + 0x80
          @use_th_regs_addr      = regs_addr + 0x88
        end
        def generate_setup(params)
          str  = "- #{@name}:\n"
          if (params.fetch(:start, false))
            str += "  - OUT  : {GPO(0) : 1}\n"
          end
          if (params.key?(:i_data_addr))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # In  Data Address[31:00]\n", @i_data_addr_regs_addr+0, (params[:i_data_addr] >> 0)& 0xFFFFFFFF)
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # In  Data Address[63:32]\n", @i_data_addr_regs_addr+4, (params[:i_data_addr] >>32)& 0xFFFFFFFF)
          end
          if (params.key?(:o_data_addr))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # Out Data Address[31:00]\n", @o_data_addr_regs_addr+0, (params[:o_data_addr] >> 0)& 0xFFFFFFFF)
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # Out Data Address[63:32]\n", @o_data_addr_regs_addr+4, (params[:o_data_addr] >>32)& 0xFFFFFFFF)
          end
          if (params.key?(:k_data_addr))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # K   Data Address[31:00]\n", @k_data_addr_regs_addr+0, (params[:k_data_addr] >> 0)& 0xFFFFFFFF)
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # K   Data Address[63:32]\n", @k_data_addr_regs_addr+4, (params[:k_data_addr] >>32)& 0xFFFFFFFF)
          end
          if (params.key?(:t_data_addr))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # Th  Data Address[31:00]\n", @t_data_addr_regs_addr+0, (params[:t_data_addr] >> 0)& 0xFFFFFFFF)
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # Th  Data Address[63:32]\n", @t_data_addr_regs_addr+4, (params[:t_data_addr] >>32)& 0xFFFFFFFF)
          end
          if (params.key?(:i_width))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # IN_W\n"    , @i_width_regs_addr   , params[:i_width ])
          end
          if (params.key?(:i_height))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # IN_H\n"    , @i_height_regs_addr  , params[:i_height])
          end
          if (params.key?(:i_channels))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # IN_C_BY_WORD\n", @i_channels_regs_addr, params[:i_channels])
          end
          if (params.key?(:o_width))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # OUT_W\n"   , @o_width_regs_addr   , params[:o_width   ])
          end
          if (params.key?(:o_height))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # OUT_H\n"   , @o_height_regs_addr  , params[:o_height  ])
          end
          if (params.key?(:o_channels))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # OUT_C\n"   , @o_channels_regs_addr, params[:o_channels])
          end
          if (params.key?(:k_width))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # K_W\n"     , @k_width_regs_addr   , params[:k_width   ])
          end
          if (params.key?(:k_height))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # K_H\n"     , @k_height_regs_addr  , params[:k_height  ])
          end
          if (params.key?(:pad_size))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # PAD_SIZE\n", @pad_size_regs_addr  , params[:pad_size  ])
          end
          if (params.key?(:use_th))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # USE_TH\n"  , @use_th_regs_addr    , params[:use_th    ])
          end
          if (params.fetch(:interrupt, false))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # IRQE[0]<=1\n", @irq_enable_regs_addr, 1)
          end
          if (params.fetch(:start, false))
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # CTRL[0]<=1\n", @control_regs_addr   , 1)
            str += sprintf("  - READ:  {ADDR: 0x%08X, DATA: \"32'h%08X\"} # BUSY[0]==1\n", @busy_regs_addr      , 1)
          end
          if (params.fetch(:interrupt, false))
            str += sprintf("  - WAIT : {GPI(0) : 1, TIMEOUT: %d} # WAIT for IRQ=1\n", params.fetch(:timeout, 1000000))
            str += sprintf("  - READ : {ADDR: 0x%08X, DATA: \"32'h%08X\"} # STAT[0]==1, STAT[1]==1\n", @status_regs_addr, 3)
            str += sprintf("  - WRITE: {ADDR: 0x%08X, DATA: \"32'h%08X\"} # STAT[0]<=1\n"            , @status_regs_addr, 1)
            str += sprintf("  - WAIT : {GPI(0) : 0, TIMEOUT: %d} # WAIT for IRQ=0\n", params.fetch(:timeout, 100))
            str += sprintf("  - READ : {ADDR: 0x%08X, DATA: \"32'h%08X\"} # STAT[0]==0, STAT[1]==1\n", @status_regs_addr, 2)
          end
          if (params.fetch(:start, false))
            str += "  - OUT  : {GPO(0) : 0}\n"
          end
          return str
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class Marchal
        attr_reader   :name
        def initialize(name)
          @name = name
        end
        def say(line)
          str  = "- #{@name} : \n"
          str += "  - SAY : #{line}\n"
          return str
        end
      end
      #---------------------------------------------------------------------------
      # 
      #---------------------------------------------------------------------------
      class Memory_Test_Writer
        attr_reader   :name, :title
        attr_reader   :marchal, :regs, :i_mem, :o_mem, :k_mem, :t_mem
        def initialize(name, i_mem_start, o_mem_start, k_mem_start, t_mem_start)
          @name    = name
          @marchal = Marchal             .new("MARCHAL")
          @regs    = RegisterIO          .new("CSR",0x0000)
          @i_mem   = InDataMemory        .new("I", 32*32*256/8, i_mem_start)
          @o_mem   = OutDataMemory       .new("O", 32*32*256*2, o_mem_start)
          @k_mem   = KernelDataMemory    .new("K", 256*256  /4, k_mem_start)
          @t_mem   = ThresholdsDataMemory.new("T", 256      *4, t_mem_start)
        end
        def write_start(file)
          file.print "---\n"
          file.print @marchal.say("#{@name} START")
          file.print @i_mem.generate_domain
          file.print @k_mem.generate_domain
          file.print @t_mem.generate_domain
          file.print @o_mem.generate_domain
        end
        def write_test(file, title, i_data, k_data, o_data, t_data=nil, use_th=0)
          setup_param = Hash.new
          setup_param[:i_data_addr] = @i_mem.addr_start
          setup_param[:k_data_addr] = @k_mem.addr_start
          setup_param[:o_data_addr] = @o_mem.addr_start
          setup_param[:t_data_addr] = @t_mem.addr_start if (t_data.nil? == false)
          setup_param[:i_width    ] = i_data.width
          setup_param[:i_height   ] = i_data.height
          setup_param[:i_channels ] = i_data.channels_by_word
          setup_param[:o_width    ] = o_data.width
          setup_param[:o_height   ] = o_data.height
          setup_param[:o_channels ] = o_data.channels
          setup_param[:k_width    ] = k_data.kernel_width
          setup_param[:k_height   ] = k_data.kernel_height
          setup_param[:pad_size   ] = (k_data.kernel_width == 3 and k_data.kernel_height == 3)? 1 : 0
          setup_param[:use_th     ] = use_th
          setup_param[:start      ] = true
          setup_param[:interrupt  ] = true
          file.print "---\n"
          file.print @marchal.say("#{title} START")
          file.print @regs.generate_setup(setup_param)
          file.print @i_mem.generate_data(i_data)
          file.print @k_mem.generate_data(k_data)
          file.print @t_mem.generate_data(t_data) if (t_data.nil? == false)
          file.print @i_mem.generate_run(100000)
          file.print @k_mem.generate_run(100000)
          file.print @t_mem.generate_run(100000)
          file.print @o_mem.generate_run(100000)
          file.print @o_mem.generate_check(o_data)
          file.print "---\n"
          file.print @marchal.say("#{title} DONE")
          file.print "---\n"
        end
        def write_done(file)
          file.print @marchal.say("#{@name} DONE")
          file.print "---\n"
        end
        def test1(file, seq, kw, kh, ic, iw, ih, oc)
          ps = (kw == 3 and kh == 3)? 1 : 0
          ow = iw
          oh = ih
          title = sprintf("TEST 1.%03d IN_C=%-2d IN_W=%-3d IN_H=%-3d OUT_C=%-3d K_W=%d K_H=%d PAD_SIZE=%d USE_TH=%d", seq, ic, iw, ih, oc, kw, kh, ps, 0)
          i_data = InData .new(ic*32, iw, ih, ps){rand(3)}
          o_data = OutData.new(oc, ow, oh)
          k_data = KernelData.new(i_data.channels, kw, kh, o_data.channels){rand(2)}
          o_data = o_data.convolution(i_data, k_data)
          write_test(file, title, i_data, k_data, o_data)
        end
        def test2(file, seq, kw, kh, ic, iw, ih, oc, use_th)
          ps = (kw == 3 and kh == 3)? 1 : 0
          ow = iw
          oh = ih
          title = sprintf("TEST 2.%03d IN_C=%-2d IN_W=%-3d IN_H=%-3d OUT_C=%-3d K_W=%d K_H=%d PAD_SIZE=%d USE_TH=%d", seq, ic, iw, ih, oc, kw, kh, ps, use_th)
          i_data = InData .new(ic*32, iw, ih, ps){rand(3)}
          o_data = OutData.new(oc, ow, oh)
          k_data = KernelData.new(i_data.channels, kw, kh, o_data.channels){rand(2)}
          t_data = ThresholdsData.new(oc)
          oc.times do |c|
            f = rand(5)
            if    (f == 0)
              t_data.write(c,0,-1*32*ic*kw*kh)
              t_data.write(c,1, 0*32*ic*kw*kh)
              t_data.write(c,2, 1*32*ic*kw*kh)
              t_data.write(c,3, 1)
            elsif (f == 1)
              t_data.write(c,0,-2*32*ic*kw*kh)
              t_data.write(c,1, 0*32*ic*kw*kh)
              t_data.write(c,2, 2*32*ic*kw*kh)
              t_data.write(c,3, -1)
            else
              t_data.write(c,0,0)
              t_data.write(c,1,0)
              t_data.write(c,2,0)
              t_data.write(c,3,f)
            end
          end
          o_data = o_data.convolution(i_data, k_data).apply_thresholds(t_data, use_th)
          write_test(file, title, i_data, k_data, o_data, t_data, use_th)
        end
      end
    end
  end
end
