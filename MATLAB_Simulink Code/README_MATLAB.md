# MATLAB / Simulink Code and Analysis Assets

This repository contains delta-sigma modulator models, MATLAB utility scripts, Python-based ENOB analysis tools, reference decimation filters, and performance evaluation data.  
The structure supports simulation, data export, filtering, and SNR/ENOB characterization for continuous-time, discrete-time, and hybrid delta-sigma modulators.

---

## 1. Modulator Models (CT / DT / Hybrid)

**Location:** `./models`

- `continuous_time_dsm_adc.slx`  
- `discrete_time_dsm_adc.slx`  
- `hybrid_dsm_adc.slx`

These Simulink models implement the three delta-sigma modulator architectures.  
All models export their bitstream output to the MATLAB workspace as:

- **`yOut`** — the modulator output array.

---

## 2. MATLAB Utility Scripts

**Location:** `./scripts_matlab`

- `exportcsv.m`  
  Exports the workspace variable `yOut` into a `.csv` file for offline processing.

- `ENOBs_vs_NyquistRate_Plot_Script.m`  
  Generates SNR and ENOB vs. Nyquist rate plots using previously computed data.  
  This script was used to produce the performance graphs contained in the `results` directory.

---

## 3. Python ENOB Analysis

**Location:** `./scripts_python`

- `ENOB_analysis.ipynb`  
  Loads the exported CSV, performs FFT-based spectral analysis, and computes SNR and ENOB using the noise-flooring method.

---

## 4. Digital / Decimation Filter Reference

**Location:** `./filters`

- `filterdesign.slx`  
  Contains the digital decimation chain, consisting of:  
  - Sinc² decimation filter  
  - 128-tap FIR low-pass filter  
  The model includes a random bitstream generator for functional verification.

---

## 5. Data Files

**Location:** `./data`

- `ENOB_in.csv`  
  Example CSV file generated from a delta-sigma modulator simulation.

- `data for snr/enob vs nyquist rate.pdf`  
  Numerical data used for creating SNR and ENOB performance plots.

---

## 6. Performance Plots

**Location:** `./results`

- `snr vs nyquist rate.png`  
- `enob vs nyquist rate.png`  

These figures display the measured SNR and ENOB as functions of Nyquist rate.  
The results demonstrate improved performance at higher Nyquist rates.

---

## 7. Summary

This directory provides the full workflow for:

- Simulating CT, DT, and Hybrid delta-sigma modulators  
- Exporting data for offline analysis  
- Evaluating ENOB using spectral noise-floor techniques  
- Validating digital decimation filters  
- Generating SNR/ENOB performance plots  

The structure is organized to support reproducible and modular analysis of delta-sigma modulator behavior.