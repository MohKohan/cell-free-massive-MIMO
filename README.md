# Contamination-Aware Channel Estimation & Distributed Precoding for Cell-Free Massive MIMO with Mobility Support

> **M.A.Sc. Thesis Simulation Framework** — École de technologie supérieure (ÉTS), Université du Québec  
> **Author:** Mohadese Shajari Kohan · Supervisor: Prof. Michel Kadoch

---

## Overview

This repository contains the full MATLAB simulation framework developed for the thesis *"Contamination-Aware Channel Estimation & Distributed Precoding for Cell-Free Massive MIMO System with Mobility Support"* (ÉTS, 2026).

Cell-Free massive MIMO (CF-mMIMO) eliminates conventional cell boundaries by enabling cooperative transmission from a large number of geographically distributed access points (APs). While theoretically powerful, practical deployment faces key challenges: **pilot contamination**, **high computational complexity**, **fronthaul constraints**, and **user mobility**. This framework directly addresses all four within a single, unified simulation environment.

The codebase models a realistic CF-mMIMO system with:
- Contamination-aware channel estimation (multi-stage pilot contamination mitigation)
- Distributed MMSE precoding with SNR-adaptive regularization
- User-centric AP selection with load balancing
- Mobility-aware serving-set adaptation and handover management
- Dual-band operation at sub-6 GHz (3.5 GHz) and millimeter-wave (28 GHz)
- Monte Carlo statistical validation framework

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  CF-mMIMO Network (1 km × 1 km)         │
│                                                         │
│   64 distributed APs (8 antennas each)                  │
│   40 mobile users  |  Dual-band: 3.5 GHz + 28 GHz      │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Channel     │  │  Pilot Assign│  │  Contamination│  │
│  │  Generation  │→ │  & Estimation│→ │  Mitigation  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                                    ↓          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Distributed │  │  Power       │  │  Mobility &  │  │
│  │  MMSE Precod.│← │  Allocation  │  │  Handover    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │       Monte Carlo Analysis & Visualization        │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Key Features

### 1. Contamination-Aware Channel Estimation
- **Spatial pilot assignment** to minimize inter-user pilot reuse based on large-scale fading coefficients
- **Successive interference cancellation (SIC)** to iteratively suppress pilot contamination
- **Contamination-aware LMMSE weighting** that explicitly models residual contamination structure
- Outperforms conventional LMMSE estimation, especially in near-far contamination scenarios

### 2. Distributed MMSE Precoding
- Local precoding at each AP using partial channel state information (CSI)
- **SNR-adaptive regularization** that automatically adjusts to channel conditions
- Near-centralized MMSE performance with significantly reduced fronthaul overhead
- Comparison benchmarks: Maximum Ratio (MR), Zero-Forcing (ZF), centralized MMSE

### 3. User-Centric AP Selection & Load Balancing
- Each user served by `S = 5` best APs selected via a quality metric combining sub-6 GHz and mmWave path loss
- Load balancing enforces per-AP capacity constraints (max 5 users/AP)
- Hierarchical AP deployment modeling dense-urban and sparse-suburban regions

### 4. Power Allocation
- **Equal power allocation** baseline
- **Optimized power allocation** with per-AP constraints
- Fairness-aware resource distribution with Jain's fairness index evaluation
- Energy efficiency (bits/Joule) optimization considering circuit power and PA efficiency

### 5. Mobility & Handover Management
- **Random waypoint mobility model** at pedestrian speeds (3 km/h default; sweep: 0, 3, 30 km/h)
- Temporal channel correlation model (Jake's model / AR(1) process)
- **Dynamic serving-set adaptation**: APs are added/dropped as users move
- Handover hysteresis margin (6 dB) and timer (5 s) to prevent ping-pong effects
- Metrics: handover rate, SINR continuity, service interruption probability

### 6. Dual-Band Channel Modeling
- Separate path loss models for sub-6 GHz (α = 3.2) and mmWave (α = 4.5)
- Spatially correlated channels with realistic antenna array response
- Rician fading with distance-dependent K-factor (3GPP model)
- Shadow fading with σ = 8 dB

### 7. Monte Carlo Statistical Validation
- Configurable number of Monte Carlo trials with reproducible RNG seed
- Confidence interval computation for all key metrics
- Automatic unit tests for MR SINR, ZF orthogonality, near-far contamination, and spatial correlation PSD

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **MATLAB** | R2021a or later |
| **Toolboxes** | Communications Toolbox, Parallel Computing Toolbox |
| **Hardware** | Multi-core CPU recommended (parallel pool with 6 workers used by default) |

> The script automatically detects and starts a parallel pool (`parpool`) if one is not already running.

---

## Getting Started

### Installation

```bash
git clone https://github.com/<your-username>/cf-mmimo-simulation.git
cd cf-mmimo-simulation
```

### Running the Simulation

Open MATLAB and run the main script:

```matlab
run('mobilityz_v21.m')
```

The script is self-contained. On launch it will:
1. Initialize system parameters
2. Start a parallel worker pool
3. Run automatic unit tests
4. Deploy the network topology and generate channel models
5. Execute estimation, precoding, and mobility simulations
6. Generate all performance plots and analysis reports

---

## Configuration

All simulation parameters are set via the `params` struct at the top of `mobilityz_v21.m`. The most commonly adjusted parameters are:

```matlab
% Network
params.L = 64;                  % Number of APs
params.M = 8;                   % Antennas per AP
params.K = 40;                  % Number of users
params.S = 5;                   % Serving APs per user
params.area_size = 1000;        % Area size (m)

% Frequency
params.fc = [3.5e9, 28e9];      % Sub-6 GHz + mmWave carrier frequencies

% Pilot
params.tau_p = 20;              % Pilot sequence length
params.tau_c = 500;             % Coherence block length

% Power (dBm)
params.p_pilot_dbm = 23;
params.p_data_dbm  = 27;

% Mobility
params.user_velocity_kmh = 3;         % Target velocity
params.user_velocity_kmh_sweep = [0, 3, 30];  % Sweep values
params.mobility_model = 'random_waypoint';
params.simulation_time = 60;          % Seconds
params.handover_margin_db = 6;        % Hysteresis (dB)
```

---

## Output & Plots

The simulation generates a comprehensive set of figures covering:

- **Channel estimation quality**: NMSE vs. SNR, contamination ratio distributions
- **Precoding performance**: CDF of per-user SINR for MR / ZF / distributed MMSE / centralized MMSE
- **Rate analysis**: Achievable sum rate and per-user rate CDF under equal vs. optimized power
- **Energy efficiency**: Bits/Joule vs. number of APs, transmit power, and user load
- **Mobility results**: SINR evolution over time, handover events, serving-set adaptation
- **Monte Carlo validation**: Mean ± confidence intervals for all key metrics

---

## Code Structure

```
mobilityz_v21.m
│
├── System Initialization & Parameter Setup
├── Network Deployment
│   ├── deploy_hierarchical_aps()
│   ├── deploy_clustered_users()
│   └── deploy_cellular_overlay()
│
├── Channel Modeling
│   ├── compute_dual_band_pathloss()
│   ├── generate_correlated_channels_with_mobility()
│   └── generate_spatial_correlation_matrix()
│
├── AP Selection
│   └── advanced_ap_selection()           ← load-balanced user-centric clustering
│
├── Beam Management (mmWave)
│   ├── position_based_beam_prediction()
│   └── coordinated_beam_refinement()
│
├── Channel Estimation
│   ├── spatial_pilot_assignment()
│   ├── contamination_aware_estimation_PROPOSED()   ← main contribution
│   └── covariance_aware_estimation_literature()    ← baseline
│
├── Precoding
│   ├── distributed_mmse_precoding()       ← main contribution
│   ├── compute_MR_precoding()
│   ├── compute_ZF_precoding_centralized()
│   └── compute_near_centralized_MMSE()
│
├── Power Allocation & SINR
│   ├── proper_power_allocation()
│   ├── compute_sinr()
│   └── compute_snr_metrics()
│
├── Mobility & Handover
│   └── simulate_mobility_and_handover()
│
├── Monte Carlo Analysis
│   ├── run_monte_carlo_analysis()
│   └── compute_monte_carlo_statistics()
│
├── Validation & Unit Tests
│   ├── run_all_unit_tests()
│   ├── test_single_cell_MR()
│   ├── test_zf_precoding_orthogonality()
│   ├── test_near_far_contamination()
│   └── validate_against_literature()
│
└── Visualization
    ├── visualize_contamination_analysis()
    ├── generate_monte_carlo_plots()
    └── visualize_mobility_and_handover()
```

---

## Results Summary

Selected key results from the thesis (64 APs, 8 antennas/AP, 40 users, 1 km² area):

| Metric | Baseline (Conv. LMMSE) | Proposed Framework |
|--------|------------------------|-------------------|
| Pilot contamination (NMSE) | −16.8 dB | Significantly reduced |
| Near-far contamination ratio | Up to 92.7 dB | Mitigated via SIC + weighting |
| Precoding vs. centralized MMSE gap | — | < 1 dB (distributed MMSE) |
| Service continuity under mobility | Degrades with speed | Stable via dynamic AP selection |
| Energy efficiency | Baseline | Improved with optimized PA |

> Full numerical results, CDF curves, and statistical analyses are presented in Chapter 4 of the thesis.

---

## Academic Context

This repository accompanies the following thesis:

> **Mohadese Shajari Kohan**, *"Contamination-Aware Channel Estimation & Distributed Precoding for Cell-Free Massive MIMO System with Mobility Support"*, M.A.Sc. Thesis, Department of Electrical Engineering, École de technologie supérieure (ÉTS), Université du Québec, Montréal, April 2026.  
> Supervisor: Prof. Michel Kadoch

If you use this code or find it useful in your research, please cite the above thesis.

---

## License

© 2026 Mohadese Shajari Kohan. This work is shared under a **Creative Commons Attribution–NonCommercial–NoDerivatives** license. You may freely distribute or reproduce this work for non-commercial purposes, provided the author is credited and the content is not modified.

---

## Contact

**Mohadese Shajari Kohan**  
M.A.Sc. Graduate, Electrical Engineering  
École de technologie supérieure (ÉTS), Université du Québec  
Montréal, Québec, Canada
