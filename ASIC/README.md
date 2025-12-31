# ASIC Design Flow: Decimation Filter (CIC-2 + FIR-128)

## Project Overview

This project implements a complete ASIC design flow for a high-performance decimation filter targeting a 180nm CMOS technology. The filter combines a second-order Cascaded Integrator-Comb (CIC-2) filter with a 128-tap Finite Impulse Response (FIR-128) filter for efficient downsampling and signal conditioning.

## Architecture

### Top-Level Module
**Module Name:** `integrator_chain_with_downsampler_comb_nohold_with_fir128`

**Design Hierarchy:**
```
integrator_chain_with_downsampler_comb_nohold_with_fir128
├── BASE_CHAIN: integrator_chain_with_downsampler_comb_nohold
│   ├── INT2: integrator2 (CIC-2 Integrator Stage)
│   │   ├── I1: integrator (First Integrator)
│   │   └── I2: integrator (Second Integrator)
│   ├── DS: downsampler_nohold (Downsampling by OSR=1025)
│   └── S1: comb_diff_nohold (First Comb Differentiator)
├── C2: comb2_diff_nohold (Second Comb Differentiator)
└── FIR: fir128_nohold (128-tap Moving Average FIR Filter)
```

### Key Parameters
- **Data Width:** 32 bits
- **Oversampling Ratio (OSR):** 1025
- **FIR Taps:** 128
- **Fractional Bits (FRAC):** 8
- **Operating Frequency:** 100 MHz (10 ns clock period)

### Signal Processing Chain

1. **Integrator Stage (CIC-2):**
   - Two cascaded accumulators operating at high sample rate
   - Performs signal integration for noise shaping
   - 32-bit wide data path to prevent overflow

2. **Downsampler:**
   - Reduces sample rate by factor of 1025
   - Implements decimation without hold operation
   - Generates valid output signal for downstream stages

3. **Comb Differentiator Stages:**
   - Two cascaded differentiators operating at reduced rate
   - Complements integrator stages to form complete CIC filter
   - Provides effective anti-aliasing characteristics

4. **FIR Filter (128-tap):**
   - Moving average implementation
   - 128 coefficients for sharp frequency response
   - 8-bit fractional precision for coefficient scaling
   - Output width: 40 bits (32 + 8 fractional bits)

## ASIC Design Flow

### 1. RTL Design
**File:** `decim_filter.v`

The design is implemented in Verilog HDL with fully synthesizable constructs. All modules use synchronous reset and positive edge-triggered clocking for robust operation.

### 2. Synthesis (Cadence Genus)

**Tool:** Cadence Genus Synthesis Solution v21.14-s082_1  
**Script:** `run.tcl`  
**Technology:** 180nm CMOS standard cell library

**Synthesis Configuration:**
- Library: `/cad/FOUNDRY/digital/180nm/dig/lib/typical.lib`
- Clock constraint: 10 ns period (100 MHz)
- Clock uncertainty: 0.1 ns
- Synthesis flow: `syn_gen` -> `syn_map` -> `syn_opt`

**Outputs:**
- `mapped_decim_filter.v` - Gate-level netlist
- `mapped_decim_filter.sdc` - Timing constraints
- `timing.rpt` - Synthesis timing report
- `area.rpt` - Area utilization report
- `power.rpt` - Power consumption report

**Synthesis Results:**
- Total cell count: 15,934 instances
- Total area: 414,685.656 µm²
- FIR filter area: 389,232.043 µm² (93.9% of total)

### 3. Place and Route (Cadence Innovus)

**Tool:** Cadence Innovus v21.15-s110_1  
**Script:** `innovus.cmd`  
**Technology Files:**
- LEF: `/cad/FOUNDRY/digital/180nm/RC_Libs/libraries/lef/STDCELL/all.lef`
- Liberty: Standard cell timing libraries

**Floorplan Configuration:**
- Aspect ratio: 1.0
- Core utilization: 70%
- Die margins: 20 µm on all sides
- Core rings: VDD/VSS on M3/M4 layers
- Power grid: Vertical stripes on M3, horizontal on M4

**Power Distribution:**
- Core ring width: 3 µm
- Core ring spacing: 3 µm
- Stripe width: 3 µm
- Stripe spacing: 3 µm
- Vertical stripe pitch: 40 µm
- Horizontal stripe pitch: 40 µm

**Design Implementation Steps:**
1. Design initialization and floorplanning
2. Power ring and stripe generation
3. Standard cell placement (timing-driven)
4. Clock tree synthesis
5. Routing (NanoRoute engine)
6. Timing optimization
7. Design rule checking (DRC)

**Outputs:**
- `final_netlist.v` - Post-layout netlist
- `final.def` - Design Exchange Format file
- `final_decimation_filter.gds` - GDSII layout file
- `design_post.sdf` - Standard Delay Format for timing
- `route_report.rpt` - Detailed routing report
- `congestion.rpt` - Routing congestion analysis

**Routing Statistics:**
- Clock net (clk): 57,134 µm total wire length, 9,373 vias
- Reset net: 6,148 µm total wire length, 783 vias
- Multi-layer routing: Metal1 through Metal6
- Total nets: 16,314
- Total pins: 60,654

### 4. Timing Analysis

**Critical Path Analysis:**
- **Longest path:** FIR filter datapath
- **Start point:** FIR/ptr_reg[6]/Q
- **End point:** FIR/sum_reg_reg[46]/D
- **Path delay:** 22.082 ns
- **Required time:** 9.734 ns
- **Slack:** -12.348 ns (VIOLATED)

**Timing Violation Details:**
The design exhibits setup time violations primarily in the FIR filter's carry-save adder tree. The critical path traverses through:
- Register output (DFFX1)
- Multiple logic gates (NOR2X4, AOI222X1, AOI21X1, OR4X2, NAND4X1)
- Carry-save adder tree (multiple ADDFX1/ADDFX2 stages)
- Final register input

**Note:** The timing violations indicate the design cannot meet 100 MHz operation. Potential solutions include:
- Pipeline insertion in FIR datapath
- Clock frequency reduction
- Logic restructuring
- High-speed cell replacement

### 5. Post-Layout Simulation

**Testbench:** `tb_postlayout.v`  
**Simulator:** Cadence Xcelium  
**Back-annotation:** SDF timing delays (`design_post.sdf`)

**Simulation Features:**
- Reads input stimulus from CSV file
- Instantiates post-layout netlist with SDF timing
- Captures all filter stage outputs
- Writes results to output CSV
- Generates VCD waveform file for debugging

**Verification Methodology:**
1. Generate test vectors using `stimulus_creator.sh`
2. Run post-layout simulation with SDF back-annotation
3. Verify functionality with realistic gate delays
4. Analyze timing closure and functional correctness

**Output Files:**
- `postlayout.vcd` - Value Change Dump waveform
- `postlayout_out.csv` - Simulation results

### 6. Formal Verification

**Directory:** `fv/`  
**Design Under Verification:** CIC filter chain with FIR

Formal verification setup for equivalence checking between RTL and gate-level implementations.

## Technology Details

**Process Node:** 180nm CMOS  
**Supply Voltage:** 1.8V  
**Power Rails:**
- VDD: 1.8V
- VSS: 0V (Ground)

**Standard Cells Used:**
- Flip-flops: DFFX1, DFFX2
- Logic gates: NAND, NOR, AND, OR, AOI, OAI families
- Adders: ADDFX1, ADDFX2 (full adders)
- Buffer/Inverter: Various drive strengths

**Metal Layers:**
- Metal1-6 available for routing
- Lower metals (M1-M3) for local interconnect
- Upper metals (M4-M6) for global routing and power

## Folder Structure
- MATLAB_Simulink: Modulator, filter, ENOB scripts
- RTL: Verilog design + testbenches
- ASIC_Flow: Synthesis + PnR + Netlists + Reports
- PostLayout_Sim: SDF-based post-layout simulation
- Docs: Final PDF + figures
- Environment: Tool versions, PDK info

## File Organization

### Source Files
- `decim_filter.v` - RTL source code
- `constraints.sdc` - Timing constraints

### Synthesis Files
- `run.tcl` - Genus synthesis script
- `genus.cmd` - Genus command log
- `log_genus.txt` - Synthesis log
- `mapped_decim_filter.v` - Synthesized netlist
- `mapped_decim_filter.sdc` - Output constraints

### Place & Route Files
- `innovus.cmd` - Innovus command script
- `innovus.cmd1-7` - Additional command logs
- `innovus_log.txt` - Implementation log
- `mmmc.tcl` - Multi-mode multi-corner setup
- `final.def` - Final DEF file
- `final.enc` - Innovus database

### Reports
- `timing.rpt` - Timing analysis
- `area.rpt` - Area breakdown
- `power.rpt` - Power analysis
- `route_report.rpt` - Routing details
- `congestion.rpt` - Congestion analysis

### Output Files
- `final_decimation_filter.gds` - GDSII layout
- `final_netlist.v` - Post-layout netlist
- `design_post.sdf` - Timing delays

### Verification Files
- `tb_postlayout.v` - Post-layout testbench
- `stimulus.csv` - Test vectors
- `stimulus_creator.sh` - Stimulus generation
- `run_postlayout.sh` - Simulation script
- `postlayout.vcd` - Waveform dump

## Design Statistics

**Gate Count:** 15,934 cells  
**Net Count:** 16,314 nets  
**Pin Count:** 60,654 pins  
**I/O Ports:** 207 signals

**Cell Distribution:**
- 2-terminal nets: 11,297 (69.2%)
- 3-terminal nets: 3,975 (24.4%)
- 4-terminal nets: 344 (2.1%)
- 5+ terminal nets: 584 (3.6%)

**Primitive Usage:**
- ADDFX1/ADDFX2: 192 instances
- AOI21X1: 801 instances
- AND2X2/X4: 144 instances
- Various other logic primitives: 63 unique types

## Known Issues

1. **Timing Violations:**
   - Setup time violations in FIR filter path (-12.348 ns slack)
   - Critical path requires optimization or frequency reduction

2. **Power Grid Warnings:**
   - VDD/VSS nets lack complete pin connections
   - May affect IR drop analysis

## How to Reproduce
2. For RTL simulation see RTL/README_RTL
3. For synthesis run GENUS using ASIC_Flow/run.tcl
4. For layout run innovus using innovus.cmd
5. For post-layout simulation use PostLayout_Sim/README_PostLayout

## Usage Instructions

### Running Synthesis
```bash
genus -files run.tcl | tee log_genus.txt
```

### Running Place & Route
```bash
innovus -files innovus.cmd
```

### Running Post-Layout Simulation
```bash
bash run_postlayout.sh
```

## Design Goals Achieved

1. Complete RTL-to-GDSII flow execution
2. Functional decimation filter implementation
3. Multi-stage filtering (CIC-2 + FIR-128)
4. Standard cell-based ASIC design
5. Post-layout verification capability

## Future Improvements

1. Resolve timing violations through:
   - FIR filter pipelining
   - Retiming optimizations
   - Alternative synthesis strategies

2. Power optimization:
   - Clock gating implementation
   - Multi-threshold voltage cells
   - Dynamic voltage/frequency scaling

3. Area optimization:
   - Resource sharing in FIR
   - Coefficient representation optimization

4. Enhanced verification:
   - Comprehensive testbench coverage
   - Corner case validation
   - Power-aware simulation
