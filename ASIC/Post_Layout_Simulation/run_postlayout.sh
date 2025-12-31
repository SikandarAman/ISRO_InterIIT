#!/bin/bash
# Usage: ./run_postlayout.sh
set -euo pipefail

# Edit these variables if filenames differ
FILELIST=filelist.f
SDF_CMD=sdf.cmd
LOG=postlayout_xrun.log
WAVE=postlayout.vcd

# remove old outputs
rm -f $LOG $WAVE postlayout_out.csv postlayout.vcd

echo "Running post-layout simulation with Xcelium (xrun)..."
/cad/XCELIUM2209/./tools.lnx86/bin/xrun -64bit -access +rwc \
     -y /cad/FOUNDRY/lan/flow/t1u1/reference_libs/GPDK045/gsclib045_svt_v4.4/gsclib045/verilog \
     +libext+.v \
     -timescale 1ns/1ps \
     -f $FILELIST \
     +define+POST_LAYOUT \
     +sdf_cmd_file=$SDF_CMD \
     -l $LOG

echo "Simulation finished. Log: $LOG"
echo "Outputs: postlayout_out.csv  Waveform: postlayout.vcd"

