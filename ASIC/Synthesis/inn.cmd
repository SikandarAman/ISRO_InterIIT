#===========================================================
# inn.cmd  --  Encounter/ancient-Innovus P&R with power ring
# Netlist : mapped_decim_filter.v
# Top     : integrator_chain_with_downsampler_comb_nohold_with_fir128
#===========================================================

# ---------- Import setup (init_design flow) ---------------

set init_lef_file { \
    /cad/FOUNDRY/digital/180nm/RC_Libs/libraries/lef/STDCELL/all.lef \
}

set init_verilog {mapped_decim_filter.v}

set init_top_cell integrator_chain_with_downsampler_comb_nohold_with_fir128
set init_design_settop 1

set init_pwr_net  VDD
set init_gnd_net  VSS

set init_mmmc_file mmmc.tcl

# Build design database (reads LEF + netlist)
init_design



# ---------- Floorplan ------------------------------------

# floorPlan -r <util> <aspect> <left> <bottom> <right> <top>
# This style already worked earlier in your logs
floorPlan -r 1.0 0.7 20 20 20 20


# ---------- Power ring + stripes -------------------------

# Core power ring around the core area
addRing \
  -type core_rings \
  -nets {VDD VSS} \
  -layer {top M4 bottom M4 left M3 right M3} \
  -width 3 \
  -spacing 3 \
  -offset 5

# Vertical stripes on M3
addStripe \
  -nets {VDD VSS} \
  -direction vertical \
  -layer M3 \
  -width 3 \
  -spacing 3 \
  -set_to_set_distance 40

# Horizontal stripes on M4
addStripe \
  -nets {VDD VSS} \
  -direction horizontal \
  -layer M4 \
  -width 3 \
  -spacing 3 \
  -set_to_set_distance 40


# ---------- Placement ------------------------------------

placeDesign


# ---------- Routing (errors caught so script continues) ---

if {[catch {routeDesign} msg]} {
    puts "routeDesign finished with internal errors: $msg"
}


# ---------- Save results ---------------------------------

saveDesign   final.enc
defOut       final.def
saveNetlist  final_netlist.v

exit

