# clk_wiz_0 constrains its own 100 MHz input and derives clk_out1 (40 MHz).
# For fmax: change clk_wiz_0 CLKOUT1_REQUESTED_OUT_FREQ, re-run implementation, read WNS.
set_false_path -from [get_ports reset_0]
set_false_path -from [get_ports UART_0_rxd]
set_false_path -to [get_ports UART_0_txd]
