# High-Precision Delta-Sigma ADC (16+ ENOB) | Inter-IIT Tech Meet Project

## Introduction
High-precision data conversion is a critical requirement in space-grade applications such as communication, navigation, remote sensing, and human spaceflight. This project focuses on the **design and implementation of a high-resolution Delta-Sigma Analog-to-Digital Converter (ADC)** targeted for **low-bandwidth, high-accuracy sensor interfaces**, aligning with indigenous VLSI development goals under **Atmanirbhar Bharat**.

The work involves **system-level modeling, digital backend design, noise analysis, and ASIC implementation**, demonstrating an end-to-end mixed-signal design flow.

---

## Project Objectives
- Achieve **16+ Effective Number of Bits (ENOB)** for low-frequency sensor signals
- Support **0.5–2 kSPS Nyquist rate** operation
- Design a **robust digital decimation chain** suitable for ASIC integration
- Analyze and mitigate **low-frequency flicker (1/f) noise**
- Validate feasibility for **ASIC / SoC deployment**

---

## System-Level Modeling (MATLAB)
- Designed a **Delta-Sigma Modulator** at the system level using MATLAB
- Optimized **OSR, loop architecture, and quantization** to achieve **>16 ENOB**
- Evaluated key performance metrics:
  - Signal-to-Noise Ratio (SNR)
  - ENOB
  - Power Spectral Density (PSD)
- Served as the **golden reference model** for RTL verification

---

## Digital Decimation Filter Design
- Designed **digital decimation filters (SINC/FIR)** to process modulator bitstream
- Implemented the complete filter chain in **Verilog RTL**
- Verified functional correctness by **matching RTL outputs with MATLAB reference**
- Ensured numerical accuracy under **fixed-point quantization**

---

## Noise Modeling and Auto-Zeroing
- Modeled **flicker (1/f) noise** to analyze its impact on low-frequency precision
- Observed degradation in SNR and ENOB at low input frequencies
- Implemented **auto-zeroing techniques** to suppress low-frequency noise
- Demonstrated **improved accuracy and stability** post noise mitigation

---

## ASIC Implementation Flow
- Performed **RTL synthesis** using **Cadence Genus**
- Completed **Place and Route (P&R)** using **Cadence Innovus**
- Conducted **post-layout simulations** to verify:
  - Functional correctness
  - Timing integrity
  - Layout-induced effects
- Ensured ASIC-ready digital backend for integration into ADC/SoC designs

---

## Tools and Technologies Used
- **MATLAB** – System modeling, performance analysis, reference validation
- **Verilog RTL** – Digital filter and backend implementation
- **Cadence Genus** – Logic synthesis
- **Cadence Innovus** – Physical design (P&R)
- **Post-Layout Simulation** – Timing and functional verification

---

## Key Outcomes
- Achieved **>16 ENOB** for low-bandwidth operation
- Successfully correlated **MATLAB ↔ RTL ↔ Post-layout** results
- Demonstrated effective **flicker noise reduction using auto-zeroing**
- Delivered a **complete ASIC-ready digital backend** for Delta-Sigma ADC

---

## Applications
- Space payload sensor readout
- Precision temperature and position sensing
- Low-frequency, high-dynamic-range instrumentation
- ASIC / SoC-based mixed-signal systems

---

## Contributors
Inter-IIT Tech Meet Team  
Indian Institute of Technology (IIT)
