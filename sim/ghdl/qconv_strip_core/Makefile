
WORK                  := WORK
SRC_PATH              := ../../../src
DUMMY_PLUG_SRC_PATH   := ../../../Dummy_Plug/src/main/vhdl
PIPEWORK_SRC_PATH     := ../../../PipeWork/src/
PIPEWORKTEST_SRC_PATH := ../../../PipeWorkTest/src/test/vhdl/
QCONV_SRC_PATH        := ../../../src/main/vhdl/
DUMMY_PLUG_WORK_PATH  := ./dummy_plug/
PIPEWORK_WORK_PATH    := ./pipework/
QCONV_WORK_PATH       := ./qconv/
SCENARIO_PATH         := $(SRC_PATH)/test/scenarios/qconv_strip_core

GHDL                  := ghdl
GHDLFLAGS             := --mb-comments -P$(DUMMY_PLUG_WORK_PATH) -P$(PIPEWORK_WORK_PATH) -P$(QCONV_WORK_PATH)

TEST_BENCH            := qconv_strip_core_test_bench_1_1 \
                         qconv_strip_core_test_bench_1_4 \
                         qconv_strip_core_test_bench_4_1 \
                         qconv_strip_core_test_bench_2_2 \
                         $(END_LIST)

DUMMY_PLUG            := $(DUMMY_PLUG_WORK_PATH)/dummy_plug-obj93.cf
PIPEWORK              := $(PIPEWORK_WORK_PATH)/pipework-obj93.cf
QCONV                 := $(QCONV_WORK_PATH)/qconv-obj93.cf
IMAGE_STREAM_MODELS   := image_stream_models.o image_stream_player.o image_stream_slave_player.o

.PHONY all: $(TEST_BENCH)

qconv_strip_core_test_bench_1_1 : qconv_strip_core_test_bench.o $(SCENARIO_PATH)/test.snr
	cp $(SCENARIO_PATH)/test.snr test.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_core_test_bench_1_4 : qconv_strip_core_test_bench.o $(SCENARIO_PATH)/test.snr
	cp $(SCENARIO_PATH)/test.snr test.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_core_test_bench_4_1 : qconv_strip_core_test_bench.o $(SCENARIO_PATH)/test.snr
	cp $(SCENARIO_PATH)/test.snr test.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

qconv_strip_core_test_bench_2_2 : qconv_strip_core_test_bench.o $(SCENARIO_PATH)/test.snr
	cp $(SCENARIO_PATH)/test.snr test.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

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

analyze: $(PIPEWORK) $(DUMMY_PLUG) $(IMAGE_STREAM_MODELS) qconv_strip_core_test_bench.o

image_stream_models.o           : $(PIPEWORKTEST_SRC_PATH)/image_stream_models/image_stream_models.vhd       $(PIPEWORK) $(DUMMY_PLUG)
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

image_stream_player.o           : $(PIPEWORKTEST_SRC_PATH)/image_stream_models/image_stream_player.vhd       $(PIPEWORK) $(DUMMY_PLUG)
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

image_stream_slave_player.o     : $(PIPEWORKTEST_SRC_PATH)/image_stream_models/image_stream_slave_player.vhd $(PIPEWORK) $(DUMMY_PLUG)
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

qconv_strip_core_test_bench.o : ../../../src/test/vhdl/qconv_strip_core_test_bench.vhd $(PIPEWORK) $(DUMMY_PLUG) $(QCONV) $(IMAGE_STREAM_MODELS)
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

