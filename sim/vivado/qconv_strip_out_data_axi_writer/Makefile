all: add_sim.tcl

clean:
	rm add_sim.tcl

add_sim.tcl     : add_sim.yml
	../../../PipeWork/tools/vhdl-archiver.rb -v --config add_sim.yml     > add_sim.tcl


