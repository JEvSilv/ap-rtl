xrun -64 -access +rwc -sv tb/*.sv rtl/*.v -gui -verbose -debug -defparam top.ap.COL_DATA_A=$1 -defparam top.ap.COL_DATA_B=$2

#	+define+INIT_DELAY=2 \       	
#	-defparam AP.DATA_INIT_A=$1 \
#	-defparam AP.DATA_INIT_B=$2 
#	+define+RANDOMIZE_MEM_INIT \
#	-defparam top.th.mem.sram.mem.mem_ext.TEST_FILE_PARAM=$1
