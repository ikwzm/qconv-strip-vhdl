#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require_relative "../../../../tools/lib/Dummy_Plug/ScenarioWriter/qconv_strip"

File.open("test_mem_all.snr", "w") do |file|
  writer = Dummy_Plug::ScenarioWriter::QConvStrip::Memory_Test_Writer.new("TEST", 0x81000000, 0x82000000, 0x83000000, 0x84000000)
  writer.write_start(file)

  ## writer.test1(file, 0, 1, 1, 1, 1, 1, 32)
  ## writer.test1(file, 1, 1, 1, 1, 8, 8, 32)
  ## writer.test1(file, 2, 1, 1, 4, 1, 1, 64)
  ## writer.test1(file, 3, 1, 1, 4,32,32, 32)
  ## writer.test1(file, 4, 3, 3, 1, 8, 8, 32)
  ## writer.test1(file, 5, 3, 3, 4, 8, 8, 64)
  ## writer.test1(file, 6, 3, 3, 4,32,32, 64)

  ## writer.test2(file, 0, 1, 1, 1, 1, 1, 32)
  ## writer.test2(file, 1, 1, 1, 1, 8, 8, 32)
  ## writer.test2(file, 2, 1, 1, 4, 1, 1, 64)
  ## writer.test2(file, 3, 1, 1, 4,32,32, 64)
  ## writer.test2(file, 4, 3, 3, 1, 8, 8, 32)
  ## writer.test2(file, 5, 3, 3, 4, 8, 8, 64)
  writer.test2(file, 6, 3, 3, 4,32,32, 64)

  writer.write_done(file)
end
