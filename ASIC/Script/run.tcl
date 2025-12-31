#===========================================================
# Ultra-simple Genus script for old version
# RTL file : decim_filter.v
# Top      : integrator_chain_with_downsampler_comb_nohold_with_fir128
# Usage    : genus -files run.tcl | tee log_genus.txt
#===========================================================

# ---------- LIB / RTL PATHS (EDIT ONLY IF NEEDED) --------
set LIB_DIR "/cad/FOUNDRY/digital/180nm/dig/lib"
set LIB_FILE "typical.lib"

set RTL_DIR "."
set RTL_FILE "decim_filter.v"

set TOP_NAME "integrator_chain_with_downsampler_comb_nohold_with_fir128"
#----------------------------------------------------------

# ----------------- Library setup --------------------------
set_db init_lib_search_path [list $LIB_DIR]
read_lib $LIB_FILE

# ----------------- RTL setup ------------------------------
set_db init_hdl_search_path [list $RTL_DIR]
read_hdl $RTL_FILE

# ----------------- Elaborate design -----------------------
elaborate $TOP_NAME
current_design $TOP_NAME

# ----------------- Constraints ----------------------------
# One clock on port clk, 10 ns (100 MHz)
create_clock -name CLK -period 10 [get_ports clk]
set_clock_uncertainty 0.1 [all_clocks]

# ----------------- Synthesis flow (old style) -------------
syn_gen
syn_map
syn_opt

# ----------------- Reports --------------------------------
report_timing > timing.rpt
report_area   > area.rpt
report_power  > power.rpt

# ----------------- Outputs --------------------------------
# Gate-level mapped netlist (for Innovus)
write_hdl -mapped > mapped_decim_filter.v

# SDC constraints (for Innovus)
write_sdc > mapped_decim_filter.sdc

exit

