The design consists of a sequence of digital processing blocks forming a complete CIC (SINC²) plus 128-tap FIR decimation filter. The integrator stages accumulate the input sigma–delta bitstream, the downsampler reduces the sampling rate by the oversampling ratio, the comb stages perform differentiation to cancel the integrator accumulation, and the final 128-tap FIR filter smooths the output and compensates for the passband droop of the CIC filter, producing a clean multi-bit digital output.

MODULE HIERARCHY :-

Top Module

The top-level module of the design is:

integrator_chain_with_downsampler_comb_nohold_with_fir128


2. Hierarchy

integrator_chain_with_downsampler_comb_nohold_with_fir128
│
├── integrator_chain_with_downsampler_comb_nohold   (BASE_CHAIN)
│   ├── integrator2
│   │   ├── integrator        (Integrator 1)
│   │   └── integrator        (Integrator 2)
│   ├── downsampler_nohold
│   └── comb_diff_nohold      (Comb 1)
│
├── comb2_diff_nohold         (Comb 2)
│
└── fir128_nohold             (128-Tap FIR Filter)


3. Functional Description of Each Module

1) integrator:
Performs cumulative addition of input samples according to:
y[n] = x[n] + y[n-1]
This block performs noise shaping integration.

2) integrator2:
Implements two cascaded integrators to form a second-order integrator structure
for the SINC² (CIC) filter.

3) downsampler_nohold:
Performs decimation by the Oversampling Ratio (OSR). It outputs one sample for
every OSR input clock cycles and generates a valid signal.

4) comb_diff_nohold (Comb 1):
Performs first-stage differentiation using:
y[n] = x[n] - x[n-1]
This cancels the accumulation effect of the integrators.

5) comb2_diff_nohold (Comb 2):
Second-stage differentiator that completes the SINC² (CIC) filter structure.

6) fir128_nohold:
Implements a 128-tap FIR filter with coefficients equal to 1/128. It performs
moving-average smoothing and compensates for the passband droop of the CIC filter.

7) integrator_chain_with_downsampler_comb_nohold_with_fir128:
Top module that connects the complete signal chain:
Integrator → Downsampler → Comb 1 → Comb 2 → FIR 128 Filter


4. Simulation Steps (Using Icarus Verilog + GTKWave)

Step 1: Compile the design and testbench

iverilog -o TestBench_For_Decimation_Filter.vvp  Decimation_Filter_Final_Design_Code.v  TestBench_For_Decimation_Filter.v

Step 2: Run the simulation

vvp  TestBench_For_Decimation_Filter.vvp

Step 3: View waveforms in GTKWave

gtkwave Waveform.vcd


5. Observed Simulation Signals

The following signals are observed and verified in simulation:

- xin          → Input 1-bit sigma-delta bitstream
- y1_out       → Output of Integrator 1
- y2_out       → Output of Integrator 2
- ds_out       → Downsampler output
- comb1_out    → Output of Comb 1
- comb2_out    → Output of Comb 2
- fir_out      → Final 128-tap FIR filter output


6. Timing Analysis Tool

Post-implementation timing analysis was performed using:

- Vivado 2025.2

---
End of README_RTL
---