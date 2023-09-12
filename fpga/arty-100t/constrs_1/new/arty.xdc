set_property -dict [list \
	CONFIG_VOLTAGE {3.3} \
	CFGBVS {VCCO} \
	BITSTREAM.CONFIG.SPI_BUSWIDTH {4} \
	] [current_design]


# I/O Pins
#set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {sw}];
#set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports {led}];