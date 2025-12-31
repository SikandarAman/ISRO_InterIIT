if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name libset_slow\
   -timing\
    [list ${::IMEX::libVar}/mmmc/typical.lib]
create_rc_corner -name rc_typ\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_delay_corner -name delay_slow\
   -library_set libset_slow\
   -rc_corner rc_typ
create_constraint_mode -name const_func\
   -sdc_files\
    [list /dev/null]
create_analysis_view -name view_slow -constraint_mode const_func -delay_corner delay_slow
set_analysis_view -setup [list view_slow] -hold [list view_slow]
