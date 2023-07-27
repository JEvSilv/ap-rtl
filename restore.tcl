
# XM-Sim Command File
# TOOL:	xmsim(64)	19.11-a001
#
#
# You can restore this configuration with:
#
#      xrun -64 -access +rwc -sv tb/top.sv rtl/ap.v -verbose -debug -defparam top.ap.COL_DATA_A=utils/col_data_a.hex -defparam top.ap.COL_DATA_B=utils/col_data_b.hex -input restore.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves top.ap._ap_state_irq top.ap.addr top.ap.ap_mode top.ap.ap_state top.ap.ap_state_irq top.ap.bit_cnt top.ap.clk top.ap.cmd top.ap.col_a top.ap.col_b top.ap.col_c top.ap.data top.ap.data_out top.ap.i top.ap.key_a top.ap.key_b top.ap.mask_a top.ap.mask_b top.ap.next_state top.ap.or_lut top.ap.pass_cnt top.ap.rst top.ap.sel_col top.ap.tags top.ap.write_en top.ap.wrt_bit_lut

simvision -input restore.tcl.svcf
