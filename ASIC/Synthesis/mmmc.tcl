#===========================
# mmmc.tcl  --  simple 1-view MMMC
#===========================

# Timing library from your 180nm PDK
create_library_set -name libset_slow \
    -timing {/cad/FOUNDRY/digital/180nm/dig/lib/typical.lib}

# Simple RC corner
create_rc_corner -name rc_typ

# Combine into a delay corner
create_delay_corner -name delay_slow \
    -library_set libset_slow \
    -rc_corner   rc_typ

# Constraint mode from your SDC (Genus wrote mapped_decim_filter.sdc)
create_constraint_mode -name const_func \
    -sdc_files {mapped_decim_filter.sdc}

# Single analysis view for both setup & hold
create_analysis_view -name view_slow \
    -delay_corner     delay_slow \
    -constraint_mode  const_func

set_analysis_view -setup view_slow -hold view_slow

