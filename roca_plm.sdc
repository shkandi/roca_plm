create_clock -period 50MHz -name {clk_in} [get_ports {clk_in}]
create_clock -period 50MHz -name {Clk} [get_ports {Clk}]

derive_clock_uncertainty