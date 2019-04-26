
WORK                  := WORK
SRC_PATH              := ../../../src
DUMMY_PLUG_SRC_PATH   := ../../../Dummy_Plug/src/main/vhdl
PIPEWORK_SRC_PATH     := ../../../PipeWork/src/
PIPEWORKTEST_SRC_PATH := ../../../PipeWorkTest/src/test/vhdl/
QCONV_SRC_PATH        := ../../../src/main/vhdl/
DUMMY_PLUG_WORK_PATH  := ./dummy_plug/
PIPEWORK_WORK_PATH    := ./pipework/
QCONV_WORK_PATH       := ./qconv/
SCENARIO_PATH         := $(SRC_PATH)/test/scenarios/qconv_strip_axi_core

GHDL                  := ghdl
GHDLFLAGS             := --mb-comments -P$(DUMMY_PLUG_WORK_PATH) -P$(PIPEWORK_WORK_PATH) -P$(QCONV_WORK_PATH)

TEST_BENCH            := qconv_strip_axi_core_test_bench_slv_1_1_064 \
                         qconv_strip_axi_core_test_bench_slv_1_2_016 \
                         qconv_strip_axi_core_test_bench_slv_1_8_512 \
                         qconv_strip_axi_core_test_bench_mem_1_8_512 \
                         qconv_strip_axi_core_test_bench_mem_all     \
                         $(END_LIST)

DUMMY_PLUG            := $(DUMMY_PLUG_WORK_PATH)/dummy_plug-obj93.cf
PIPEWORK              := $(PIPEWORK_WORK_PATH)/pipework-obj93.cf
QCONV                 := $(QCONV_WORK_PATH)/qconv-obj93.cf

.PHONY all: $(TEST_BENCH)

qconv_strip_axi_core_test_bench : qconv_strip_axi_core_test_bench.o test.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_axi_core_test_bench_slv_1_1_064 : qconv_strip_axi_core_test_bench.o $(SCENARIO_PATH)/test_slv_1_1_064.snr
	cp      $(SCENARIO_PATH)/test_slv_1_1_064.snr test_slv_1_1_064.snr 
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_axi_core_test_bench_slv_1_2_016 : qconv_strip_axi_core_test_bench.o $(SCENARIO_PATH)/test_slv_1_2_016.snr
	cp      $(SCENARIO_PATH)/test_slv_1_2_016.snr test_slv_1_2_016.snr 
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_axi_core_test_bench_slv_1_8_512 : qconv_strip_axi_core_test_bench.o $(SCENARIO_PATH)/test_slv_1_8_512.snr
	cp      $(SCENARIO_PATH)/test_slv_1_8_512.snr test_slv_1_8_512.snr 
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_axi_core_test_bench_mem_1_8_512 : qconv_strip_axi_core_test_bench.o $(SCENARIO_PATH)/test_mem_1_8_512.snr
	cp      $(SCENARIO_PATH)/test_mem_1_8_512.snr test_mem_1_8_512.snr 
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_axi_core_test_bench_mem_all     : qconv_strip_axi_core_test_bench.o $(SCENARIO_PATH)/test_mem_all.snr
	cp      $(SCENARIO_PATH)/test_mem_all.snr test_mem_1_8_512.snr 
	$(GHDL) -e $(GHDLFLAGS) --work=WORK qconv_strip_axi_core_test_bench_mem_1_8_512
	$(GHDL) -r $(GHDLFLAGS) --work=WORK qconv_strip_axi_core_test_bench_mem_1_8_512

qconv_strip_axi_core_test_bench.o : ../../../src/test/vhdl/qconv_strip_axi_core_test_bench.vhd $(PIPEWORK) $(DUMMY_PLUG) $(QCONV) 
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

$(QCONV) : $(PIPEWORK) 
	@if [ ! -d $(QCONV_WORK_PATH) ]; \
	    then echo "mkdir -p $(QCONV_WORK_PATH)"; mkdir -p $(QCONV_WORK_PATH); \
	fi
	../../../PipeWork/tools/vhdl-archiver.rb \
            --library QCONV \
            --execute '$(GHDL) -a $(GHDLFLAGS) --work=#{library_name} --workdir=$(QCONV_WORK_PATH) #{file_name}' \
            $(QCONV_SRC_PATH)

$(PIPEWORK) :
	@if [ ! -d $(PIPEWORK_WORK_PATH) ]; \
	    then echo "mkdir -p $(PIPEWORK_WORK_PATH)"; mkdir -p $(PIPEWORK_WORK_PATH); \
	fi
	../../../PipeWork/tools/vhdl-archiver.rb \
            --library PIPEWORK \
            --use_entity 'QUEUE_ARBITER(INTEGER_ARCH)' \
            --use_entity 'SDPRAM(MODEL)' \
            --execute '$(GHDL) -a $(GHDLFLAGS) --work=#{library_name} --workdir=$(PIPEWORK_WORK_PATH) #{file_name}' \
            $(PIPEWORK_SRC_PATH)

$(DUMMY_PLUG) :
	@if [ ! -d $(DUMMY_PLUG_WORK_PATH) ]; \
	    then echo "mkdir -p $(DUMMY_PLUG_WORK_PATH)"; mkdir -p $(DUMMY_PLUG_WORK_PATH); \
	fi
	../../../PipeWork/tools/vhdl-archiver.rb \
	    --library DUMMY_PLUG \
	    --exclude $(DUMMY_PLUG_SRC_PATH)/core/sync_alt.vhd \
	    --exclude $(DUMMY_PLUG_SRC_PATH)/axi4/axi3_signal_printer.vhd \
	    --execute '$(GHDL) -a $(GHDLFLAGS) --work=#{library_name} --workdir=$(DUMMY_PLUG_WORK_PATH) #{file_name}' \
	    $(DUMMY_PLUG_SRC_PATH)

clean:
	rm -f *.o *.cf $(TEST_BENCH) test.snr
	rm -rf ./dummy_plug/ ./pipework/ ./qconv/

analyze: $(PIPEWORK) $(DUMMY_PLUG) qconv_strip_axi_core_test_bench.o

