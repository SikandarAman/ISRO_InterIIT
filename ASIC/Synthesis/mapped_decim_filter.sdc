# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Sun Dec 07 04:49:30 IST 2025

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design integrator_chain_with_downsampler_comb_nohold_with_fir128

create_clock -name "CLK" -period 10.0 -waveform {0.0 5.0} [get_ports clk]
set_clock_gating_check -setup 0.0 
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.1 [get_clocks CLK]
set_clock_uncertainty -hold 0.1 [get_clocks CLK]
