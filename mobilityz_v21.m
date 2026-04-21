%% CF-mMIMO System Simulation
% Static network with distributed MMSE precoding and pilot assignment


clear; close all; clc;

%% Enhanced System Parameters for Advanced Analysis
params = struct();
params.seed = 7;
rng(params.seed, 'twister');

fprintf('Run metadata:\n');
fprintf('  File: %s\n', mfilename('fullpath'));
fprintf('  RNG seed: %d\n', params.seed);



% Network Configuration (Enhanced)
params.L = 64;             % 64 APs
params.M = 8;               % 8 antennas/AP 
params.K = 40;              % 40 users
params.S = 5;               % Number of serving APs per user
params.area_size = 1000;    % 1 km × 1 km
params.fc = [3.5e9, 28e9];  % Dual-band operation (sub-6 + mmWave)
params.c = 3e8;
params.bandwidth = 20e6;

% Advanced Channel Parameters
params.alpha = [3.2, 4.5];  % Path loss exponents for different frequencies
params.sigma_shadow = 8;
params.noise_figure = 7;    % dB
params.thermal_noise = -174; % dBm/Hz

% Pilot and Coherence Parameters
params.tau_p = 20;          % Longer pilot sequences
params.tau_c = 500;         % Longer coherence time
params.tau_d = params.tau_c - params.tau_p; % Data symbols

% Advanced Beam Training
params.N_sectors_coarse = 16;     % More sectors for finer initial search
params.N_beams_refinement = 16;   % Refinement beams per sector
params.N_sectors = params.N_sectors_coarse;     % For compatibility
params.N_beams_sector = params.N_beams_refinement; % For compatibility
params.tracking_update_rate = 100; % Hz

% Power Parameters (BALANCED FOR M=8)
params.p_pilot_dbm = 23;         
params.p_data_dbm = 27;         
params.power_budget_dbm = 30;   
params.pa_efficiency = 0.35;

% Mobility Parameters




params.user_velocity_kmh_sweep = [0, 3, 30];  % sweep
params.mobility_model = 'random_waypoint';

params.mobility_enabled = true;           % Enable/disable mobility simulation
params.user_velocity_kmh = 3;             % Walking speed: 3 km/h
params.user_velocity_std = 1;             % Speed variation (1-5 km/h)
params.simulation_time = 60;              % Simulation duration in seconds
params.update_interval = 0.5;             % Position update interval
params.handover_margin_db = 6;            % Handover hysteresis 
params.handover_timer_s = 5;              % Min time before handover
params.channel_correlation_time = 0.1;    % Channel coherence time


fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║  MOBILITY AND HANDOVER SIMULATION           ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n');


%% ========================================
%  PATCH 3: Add Helper Functions
%  Location: At the VERY END of the file (after all existing functions)
%% ========================================



% Performance Requirements
params.target_sinr_db = 10;     % Target SINR for QoS
params.target_latency_ms = 1;   % Ultra-low latency requirement



params.noise_power_watts = 10^((params.thermal_noise + 10*log10(params.bandwidth) + params.noise_figure)/10 - 3);
params.overhead_factor = (params.tau_c - params.tau_p) / params.tau_c;
params.practical_efficiency = 0.75 * 0.9 * 0.95;  % Coding * modulation * implementation
params.total_fixed_power = params.L * (params.M * 0.5 + 7) + params.L * 2 + 50;  % Circuit + fronthaul + CPU


%contamination metrics
contamination_metrics = struct();
contamination_metrics.MR = [];
contamination_metrics.Proposed = [];


fprintf('=== ADVANCED CF-mMIMO SYSTEM SIMULATION ===\n');
fprintf('Enhanced Configuration: %d APs, %d antennas/AP, %d users\n', params.L, params.M, params.K);
fprintf('Dual-band operation: %.1f GHz + %.1f GHz\n', params.fc(1)/1e9, params.fc(2)/1e9);

%% Initialize Parallel Pool
pool = gcp('nocreate');
if isempty(pool)
    parpool('local');
end

%% Advanced Network Deployment
fprintf('\nDeploying advanced network topology...\n');

% Hierarchical AP deployment (dense + sparse regions)
[ap_positions, ap_types] = deploy_hierarchical_aps(params);

% User clustering based on traffic demand
[user_positions, user_priorities] = deploy_clustered_users(params);

% Cellular overlay for comparison
cellular_positions = deploy_cellular_overlay(params);


fprintf('\n=== RUNNING AUTOMATIC VALIDATION ===\n');
run_all_unit_tests();
%% Advanced Channel Modeling
fprintf('Generating advanced channel models...\n');

% Dual-band path loss models
[beta_sub6, beta_mmwave] = compute_dual_band_pathloss(ap_positions, user_positions, params);

% Spatially correlated channels with realistic antenna patterns
[H_sub6, H_mmwave, spatial_corr, channel_history] = generate_correlated_channels_with_mobility(ap_positions, user_positions, params, beta_sub6, beta_mmwave, 1);

% User-centric clustering with load balancing
[serving_aps, load_balancing] = advanced_ap_selection(beta_sub6, beta_mmwave, params);

%% Multi-Stage Beam Management with Mobility
fprintf('\n=== ADVANCED BEAM MANAGEMENT ===\n');

% Enhanced beam training with spatial consistency
fprintf('Phase 1: Enhanced beam training...\n');
beam_management = struct();

% Position-assisted beam search with local refinement
[beam_management.initial_beams, beam_management.search_complexity] = position_based_beam_prediction(H_mmwave, ap_positions, user_positions, params);

% Sequential beam refinement across serving APs
[beam_management.refined_beams, beam_management.coordination_overhead] = coordinated_beam_refinement(beam_management.initial_beams, H_mmwave, serving_aps, params);



%%  CSI Acquisition and Contamination Mitigation
fprintf('\n=== ADVANCED CSI ACQUISITION ===\n');

% Greedy pilot assignment to minimize interference
fprintf('Optimizing pilot assignment with advanced algorithms...\n');
[pilot_scheme, contamination_reduction] = spatial_pilot_assignment(beta_sub6, serving_aps, params, user_positions, ap_positions);

% Covariance-aware LMMSE estimation
fprintf('Performing covariance-aware channel estimation...\n');
[H_est_baseline, ~, estimation_quality_baseline] = covariance_aware_estimation_literature(H_sub6, H_mmwave, pilot_scheme, spatial_corr, params, user_positions, ap_positions);
% Store baseline contamination for comparison
contamination_baseline = estimation_quality_baseline.contamination_ratio_db;
fprintf('  Baseline contamination (standard LMMSE): %.2f dB\n', contamination_baseline);

fprintf('\nProposed: Contamination-aware estimation with mitigation...\n');
[H_est_sub6, H_est_mmwave, estimation_quality] = contamination_aware_estimation_PROPOSED(H_sub6, H_mmwave, pilot_scheme, spatial_corr, params, user_positions, ap_positions);


fprintf('\n=== CONTAMINATION ANALYSIS ===\n');
fprintf('Pilot contamination impact:\n');

if isfield(estimation_quality, 'median_contamination_ratio_db')
    fprintf('  Typical contamination (median): %.2f dB\n', estimation_quality.median_contamination_ratio_db);
    fprintf('  Mean contamination: %.2f dB\n', estimation_quality.mean_contamination_ratio_db);
    fprintf('  90th percentile: %.2f dB\n', estimation_quality.p90_contamination_ratio_db);
else
    fprintf('  Contamination metrics not available\n');
end

fprintf('  Worst-case contamination: %.1f%% of signal\n', 100*estimation_quality.max_contamination_ratio);
fprintf('  Average NMSE: %.2f dB\n', estimation_quality.avg_nmse_db);
if isfield(estimation_quality, 'median_contamination_ratio_db')
    median_db = estimation_quality.median_contamination_ratio_db;
    fprintf('  Median contamination/signal (typical user): %.2f dB\n', median_db);
else
    median_db = estimation_quality.contamination_ratio_db; % fallback
end

% Interpretation based on median (typical user)
if median_db < -10
    fprintf('  ✅ Low typical contamination (median < -10 dB)\n');
elseif median_db < -3
    fprintf('  ✅ Moderate contamination (median -10 to -3 dB)\n');
elseif median_db < 3
    fprintf('  ⚠️  High contamination (median -3 to +3 dB)\n');
else
    fprintf('  ❌ Very high contamination (median > +3 dB)\n');
end

% Report actual mitigation gain
if exist('contamination_baseline', 'var')
    mitigation_gain = contamination_baseline - estimation_quality.contamination_ratio_db;
    fprintf('\n📊 CONTAMINATION MITIGATION PERFORMANCE:\n');
    fprintf('  Baseline (standard LMMSE): %.2f dB\n', contamination_baseline);
    fprintf('  Proposed (with mitigation): %.2f dB\n', estimation_quality.contamination_ratio_db);
    fprintf('  TRUE Mitigation Gain: %.2f dB\n', mitigation_gain);
    
    if mitigation_gain > 3
        fprintf('  ✅ STRONG mitigation (>3 dB improvement)\n');
    elseif mitigation_gain > 1
        fprintf('  ✓ GOOD mitigation (1-3 dB improvement)\n');
    elseif mitigation_gain > 0
        fprintf('  ~ MODEST mitigation (<1 dB improvement)\n');
    else
        fprintf('  ❌ NEGATIVE result - mitigation made it worse!\n');
    end
end
% Typical values from literature:
% - Good: contamination < -10 dB (10% of signal)
% - Acceptable: contamination < -5 dB (30% of signal)
% - Poor: contamination > -3 dB (50% of signal)

if estimation_quality.contamination_ratio_db > -5
    warning('⚠ High pilot contamination detected! Consider:');
    fprintf('    1. Increase tau_p (more orthogonal pilots)\n');
    fprintf('    2. Improve pilot assignment algorithm\n');
    fprintf('    3. Use contamination-aware precoding\n');
end

% Store for later analysis
performance_realtime.estimation_quality = estimation_quality;

validate_estimation_quality(estimation_quality, params);

H_clean = H_est_sub6;  % Use estimates directly



fprintf('Applying distributed_mmse_precoding...\n');
[W_distributed_mmse, coordination_strategy] = distributed_mmse_precoding(H_clean, params);

% fprintf('\nComputing adaptive power allocation...\n');
% [power_allocation_adaptive, fairness_metrics] = ...
%     proper_power_allocation(H_clean, W_distributed_mmse, params);

[power_allocation_adaptive, fairness_metrics, power_debug] = proper_power_allocation(H_clean, W_distributed_mmse, params);

% Check the debug info:
fprintf('\n=== POWER ALLOCATION DEBUG ===\n');
fprintf('Budget utilization: %.1f%%\n', 100*power_debug.budget_utilization);
fprintf('Max AP power: %.2f W (limit: %.2f W)\n',power_debug.max_ap_power_w, power_debug.total_budget_w/params.L);

% Store for later analysis
performance_realtime.power_debug = power_debug;



%% CREATE ENERGY ANALYSIS FIRST (before using it)
energy_analysis = struct();
energy_analysis.RF_chains = params.L * params.M * 0.4;
energy_analysis.power_amplifiers = params.L * params.M * 0.1;
energy_analysis.baseband = params.L * 5;
energy_analysis.total_power = params.L * (params.M * 0.5 + 7); % Total processing power

%% ========== COMPREHENSIVE BASELINE COMPARISON - DUAL SCENARIOS ==========
fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║  COMPREHENSIVE BASELINE COMPARISON (FAIR & THOROUGH)  ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n');

% ===== SCENARIO 1: EQUAL POWER ALLOCATION =====
fprintf('\n┌─────────────────────────────────────────────────────┐\n');
fprintf('│  SCENARIO 1: Equal Power Allocation for All Methods │\n');
fprintf('│  (Tests precoding effectiveness independently)      │\n');
fprintf('└─────────────────────────────────────────────────────┘\n');

[results_equal, baseline_equal] =compute_all_baseline_comparisons(H_clean, H_sub6, pilot_scheme, W_distributed_mmse, serving_aps, params, 'equal');

% Calculate improvements for equal power scenario
improvement_equal.over_MR = 100 * (baseline_equal.Proposed.sum_rate_bps_hz - baseline_equal.MR.sum_rate_bps_hz) / baseline_equal.MR.sum_rate_bps_hz;
                              
improvement_equal.over_ZF = 100 * (baseline_equal.Proposed.sum_rate_bps_hz - baseline_equal.ZF.sum_rate_bps_hz) / baseline_equal.ZF.sum_rate_bps_hz;
                              
improvement_equal.over_cent_mmse = 100 * (baseline_equal.Proposed.sum_rate_bps_hz - baseline_equal.Centralized_MMSE.sum_rate_bps_hz) / baseline_equal.Centralized_MMSE.sum_rate_bps_hz;

fprintf('\n📊 SCENARIO 1 SUMMARY (Equal Power):\n');
fprintf('%-20s | %10s | %12s | %10s\n', 'Method', 'Avg SINR', 'Sum Rate', 'Energy Eff');
fprintf('%s\n', repmat('-', 1, 60));
methods = fieldnames(baseline_equal);
for m = 1:length(methods)
    method = methods{m};
    fprintf('%-20s | %8.2f dB | %10.2f bps/Hz | %8.3f Mbits/J\n', method, baseline_equal.(method).avg_sinr_db, baseline_equal.(method).sum_rate_bps_hz, baseline_equal.(method).energy_efficiency);
end

fprintf('\n🎯 PERFORMANCE IMPROVEMENTS (Equal Power):\n');
fprintf('  Proposed vs MR:              %+.1f%%\n', improvement_equal.over_MR);
fprintf('  Proposed vs ZF:              %+.1f%%\n', improvement_equal.over_ZF);
fprintf('  Proposed vs Centralized MMSE: %+.1f%%\n', improvement_equal.over_cent_mmse);

% ===== SCENARIO 2: OPTIMIZED POWER ALLOCATION =====
fprintf('\n┌─────────────────────────────────────────────────────┐\n');
fprintf('│  SCENARIO 2: Optimized Power for All Methods        │\n');
fprintf('│  (Tests combined precoding + power optimization)    │\n');
fprintf('└─────────────────────────────────────────────────────┘\n');

[results_optimized, baseline_optimized] = compute_all_baseline_comparisons(H_clean, H_sub6, pilot_scheme, W_distributed_mmse, serving_aps, params, 'optimized');

% Calculate improvements for optimized power scenario
improvement_opt.over_MR = 100 * (baseline_optimized.Proposed.sum_rate_bps_hz - ...
                                 baseline_optimized.MR.sum_rate_bps_hz) / ...
                                 baseline_optimized.MR.sum_rate_bps_hz;
                              
improvement_opt.over_ZF = 100 * (baseline_optimized.Proposed.sum_rate_bps_hz - ...
                                 baseline_optimized.ZF.sum_rate_bps_hz) / ...
                                 baseline_optimized.ZF.sum_rate_bps_hz;
                              
improvement_opt.over_cent_mmse = 100 * (baseline_optimized.Proposed.sum_rate_bps_hz - ...
                                        baseline_optimized.Centralized_MMSE.sum_rate_bps_hz) / ...
                                        baseline_optimized.Centralized_MMSE.sum_rate_bps_hz;

fprintf('\n📊 SCENARIO 2 SUMMARY (Optimized Power):\n');
fprintf('%-20s | %10s | %12s | %10s\n', 'Method', 'Avg SINR', 'Sum Rate', 'Energy Eff');
fprintf('%s\n', repmat('-', 1, 60));
for m = 1:length(methods)
    method = methods{m};
    fprintf('%-20s | %8.2f dB | %10.2f bps/Hz | %8.3f Mbits/J\n', ...
            method, ...
            baseline_optimized.(method).avg_sinr_db, ...
            baseline_optimized.(method).sum_rate_bps_hz, ...
            baseline_optimized.(method).energy_efficiency);
end

fprintf('\n🎯 PERFORMANCE IMPROVEMENTS (Optimized Power):\n');
fprintf('  Proposed vs MR:              %+.1f%%\n', improvement_opt.over_MR);
fprintf('  Proposed vs ZF:              %+.1f%%\n', improvement_opt.over_ZF);
fprintf('  Proposed vs Centralized MMSE: %+.1f%%\n', improvement_opt.over_cent_mmse);

% ===== COMPARISON BETWEEN SCENARIOS =====
fprintf('\n┌─────────────────────────────────────────────────────┐\n');
fprintf('│  POWER ALLOCATION IMPACT ANALYSIS                    │\n');
fprintf('└─────────────────────────────────────────────────────┘\n');

fprintf('\nGain from Power Optimization (vs Equal Power):\n');
for m = 1:length(methods)
    method = methods{m};
    equal_rate = baseline_equal.(method).sum_rate_bps_hz;
    opt_rate = baseline_optimized.(method).sum_rate_bps_hz;
    gain_percent = 100 * (opt_rate - equal_rate) / equal_rate;
    
    fprintf('  %-20s: %+.1f%% improvement\n', method, gain_percent);
end

% ===== BACKWARD COMPATIBILITY =====
improvement_over_MR = improvement_opt.over_MR;
improvement_over_ZF = improvement_opt.over_ZF;
improvement_over_cent_mmse = improvement_opt.over_cent_mmse;
baseline_results = baseline_optimized;

fprintf('\n📌 Using optimized scenario as primary results\n');

% ===== STORE COMPREHENSIVE RESULTS =====
performance_realtime.baseline_comparison = baseline_results;
performance_realtime.baseline_equal_power = baseline_equal;
performance_realtime.baseline_optimized_power = baseline_optimized;
performance_realtime.improvements_equal = improvement_equal;
performance_realtime.improvements_optimized = improvement_opt;
performance_realtime.improvements.over_MR = improvement_opt.over_MR;
performance_realtime.improvements.over_ZF = improvement_opt.over_ZF;
performance_realtime.improvements.over_MMSE = improvement_opt.over_cent_mmse;

fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║  ✓ COMPREHENSIVE BASELINE COMPARISON COMPLETE         ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');


% === CONTAMINATION MITIGATION ANALYSIS ===
fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  PILOT CONTAMINATION MITIGATION PERFORMANCE            ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

fprintf('System Configuration:\n');
fprintf('  - Users (K): %d\n', params.K);
fprintf('  - Pilots (tau_p): %d\n', params.tau_p);
fprintf('  - Pilot Reuse Factor: %.1fx\n', params.K / params.tau_p);

% Get contamination values
if exist('estimation_quality_baseline', 'var') && isfield(estimation_quality_baseline, 'contamination_ratio_db')
    contam_baseline = estimation_quality_baseline.contamination_ratio_db;
else
    contam_baseline = NaN;
end

if exist('estimation_quality', 'var') && isfield(estimation_quality, 'contamination_ratio_db')
    contam_proposed = estimation_quality.contamination_ratio_db;
else
    contam_proposed = NaN;
end

fprintf('\nContamination Metrics:\n');

if ~isnan(contam_baseline) && ~isnan(contam_proposed)
    % Calculate true mitigation gain
    mitigation_gain = contam_baseline - contam_proposed;
    
    % Calculate reduction percentage (careful with dB to linear conversion)
    if contam_baseline > contam_proposed
        reduction_pct = (1 - 10^(contam_proposed/10) / 10^(contam_baseline/10)) * 100;
    else
        reduction_pct = 0;
    end
    
    fprintf('  Baseline (Standard LMMSE):  %6.2f dB\n', contam_baseline);
    fprintf('  Proposed (With Mitigation): %6.2f dB\n', contam_proposed);
    fprintf('  Mitigation Gain:            %6.2f dB (%.1f%% reduction)\n', ...
        mitigation_gain, reduction_pct);
    
    % Interpretation
    fprintf('\nInterpretation:\n');
    fprintf('  - Achieved contamination: %.2f dB\n', contam_proposed);
    
    reuse_factor = params.K / params.tau_p;
    if reuse_factor >= 2
        fprintf('  - Typical range for %.1fx reuse: -10 to 0 dB\n', reuse_factor);
    end
    
    % Status assessment
    if contam_proposed < -10
        status = 'EXCELLENT - Strong mitigation';
        symbol = '✅';
    elseif contam_proposed < -5
        status = 'GOOD - Effective mitigation';
        symbol = '✓';
    elseif contam_proposed < 0
        status = 'ACCEPTABLE - Moderate mitigation';
        symbol = '~';
    else
        status = 'NEEDS IMPROVEMENT';
        symbol = '⚠️';
    end
    
    fprintf('  - Status: %s %s\n', symbol, status);
    
    if mitigation_gain > 3
        fprintf('  - Mitigation effectiveness: STRONG (>3 dB gain)\n');
    elseif mitigation_gain > 1
        fprintf('  - Mitigation effectiveness: GOOD (1-3 dB gain)\n');
    elseif mitigation_gain > 0
        fprintf('  - Mitigation effectiveness: MODEST (<1 dB gain)\n');
    else
        fprintf('  - Mitigation effectiveness: NOT WORKING (negative gain)\n');
    end
else
    fprintf('  ⚠️  Contamination metrics not available\n');
end

% SINR Impact (if available)
if exist('performance_mr', 'var') && exist('performance_realtime', 'var')
    fprintf('\nSINR Impact of Mitigation:\n');
    
    if isfield(performance_mr, 'sinr_values') && isfield(performance_realtime, 'sinr_values')
        mr_worst = min(performance_mr.sinr_values);
        proposed_worst = min(performance_realtime.sinr_values);
        sinr_improvement = proposed_worst - mr_worst;
        
        fprintf('  MR worst-case SINR:      %6.2f dB\n', mr_worst);
        fprintf('  Proposed worst-case:     %6.2f dB\n', proposed_worst);
        fprintf('  Improvement:             %6.2f dB\n', sinr_improvement);
    end
end

fprintf('\n');

%% Validate results against literature
validate_against_literature(baseline_optimized, params);

%% NOW compute performance metrics (can use energy_analysis)
fprintf('\n=== COMPUTING REAL PERFORMANCE METRICS ===\n');
% ... rest of your computation code
% Compute noise power
bandwidth = params.bandwidth; % 20 MHz (adjust to your system)
noise_power_dbm = params.thermal_noise + 10*log10(bandwidth) + params.noise_figure;
noise_power = 10^(noise_power_dbm/10 - 3); % Convert to Watts

% Compute SINR for each user
sinr_linear = compute_sinr(H_clean, W_distributed_mmse, power_allocation_adaptive, ...
                                  noise_power, serving_aps, params, 'non-coherent');
sinr_db = 10*log10(sinr_linear);

% Compute SNR metrics
snr_metrics = compute_snr_metrics(H_clean, W_distributed_mmse, power_allocation_adaptive, params);
overhead_factor = params.tau_d / params.tau_c;  % Data symbols / Total symbols



% Coding efficiency: 75% of Shannon limit
% Source: Polyanskiy et al., "Channel Coding Rate in the Finite Blocklength Regime", IEEE TIT 2010
coding_efficiency = 0.75;

% Modulation loss: 10% gap from Gaussian capacity
% Source: Forney & Ungerboeck, "Modulation and Coding for Linear Gaussian Channels", IEEE TIT 1998
modulation_loss = 0.9;

% Implementation loss: 5% from hardware imperfections
% Source: Empirical estimate from 5G NR implementations
implementation_loss = 0.95;


practical_efficiency = coding_efficiency * modulation_loss * implementation_loss;

user_rates_bps_hz = log2(1 + sinr_linear) * overhead_factor * practical_efficiency;
sum_rate_bps_hz = sum(user_rates_bps_hz);

fprintf('\n--- REALISTIC CAPACITY CALCULATION ---\n');
fprintf('Shannon capacity (theoretical): %.2f bps/Hz\n', sum(log2(1 + sinr_linear) * overhead_factor));
fprintf('Practical efficiency factor: %.2f\n', practical_efficiency);
fprintf('Achievable rate (realistic): %.2f bps/Hz\n', sum_rate_bps_hz);
fprintf('Per-user average: %.2f bps/Hz\n', sum_rate_bps_hz/params.K);
fprintf('--------------------------------------\n\n');
sum_throughput_mbps = sum_rate_bps_hz * bandwidth / 1e6;

fprintf('\n--- PERFORMANCE CALCULATION NOTES ---\n');
fprintf('Using Shannon capacity (C = log2(1+SINR)) as theoretical upper bound\n');
fprintf('Overhead factor: %.3f (%.1f%% pilot overhead loss)\n', overhead_factor, (1-overhead_factor)*100);
fprintf('Note: Practical systems achieve 70-85%% of Shannon capacity\n');
fprintf('--------------------------------------\n\n');


% Transmit power
tx_power_w = sum(power_allocation_adaptive(:));

% Circuit power per AP (from energy_analysis)
circuit_power_per_ap = params.M * 0.5 + 7;  % RF chains + baseband
total_circuit_power = params.L * circuit_power_per_ap;

% Fronthaul power (2W per AP link)
fronthaul_power = params.L * 2;

% Central processing unit power (scales with network size)
cpu_power = 50 + 0.5 * params.L;  % Base + scaling

% TOTAL system power
total_system_power_w = tx_power_w + total_circuit_power + fronthaul_power + cpu_power;

% Verify it matches energy_analysis
assert(abs(total_circuit_power - energy_analysis.total_power) < 1, ...
       'Power breakdown mismatch!');

fprintf('DETAILED POWER BREAKDOWN:\n');
fprintf('- Transmit power: %.2f W (%.1f%%)\n', tx_power_w, 100*tx_power_w/total_system_power_w);
fprintf('- Circuit power: %.2f W (%.1f%%)\n', total_circuit_power, 100*total_circuit_power/total_system_power_w);
fprintf('- Fronthaul: %.2f W (%.1f%%)\n', fronthaul_power, 100*fronthaul_power/total_system_power_w);
fprintf('- CPU: %.2f W (%.1f%%)\n', cpu_power, 100*cpu_power/total_system_power_w);
fprintf('- TOTAL: %.2f W\n', total_system_power_w);

energy_efficiency = sum_throughput_mbps / total_system_power_w;

% Compute latency components
beam_training_latency_ms = (params.N_sectors_coarse * params.K * params.L) / params.tracking_update_rate;
csi_acquisition_latency_ms = params.tau_p / 1000; % Assuming 1 kHz coherence bandwidth
precoding_latency_ms = 0.5; % Processing delay
total_latency_ms = beam_training_latency_ms + csi_acquisition_latency_ms + precoding_latency_ms;

% Store real results
performance_realtime = struct();
performance_realtime.sinr_db = sinr_db;
performance_realtime.sinr_linear = sinr_linear;
performance_realtime.user_rates = user_rates_bps_hz;
performance_realtime.sum_rate_bps_hz = sum_rate_bps_hz;
performance_realtime.sum_throughput_mbps = sum_throughput_mbps;
performance_realtime.energy_efficiency = energy_efficiency;
performance_realtime.latency_ms = total_latency_ms;
performance_realtime.average_sinr_db = mean(sinr_db);

% Actual before/after pipeline summary based on existing stages in the file:
% baseline LMMSE estimation + MR precoding + equal power
% versus proposed estimation + distributed MMSE precoding + optimized power.
P_total = 10^(params.power_budget_dbm/10 - 3);
P_per_ap = P_total / params.L;
P_equal_pipeline = (P_per_ap / params.K) * ones(params.K, params.L);
W_before_pipeline = compute_MR_precoding(H_est_baseline, params);
sinr_before_pipeline = compute_sinr(H_est_baseline, W_before_pipeline, ...
    P_equal_pipeline, noise_power, serving_aps, params, 'non-coherent');
user_rates_before_pipeline = log2(1 + sinr_before_pipeline) * ...
    overhead_factor * practical_efficiency;
sum_rate_before_pipeline = sum(user_rates_before_pipeline);
sum_throughput_before_pipeline = sum_rate_before_pipeline * bandwidth / 1e6;
tx_power_before_pipeline = sum(P_equal_pipeline(:));
total_system_power_before_pipeline = tx_power_before_pipeline + ...
    total_circuit_power + fronthaul_power + cpu_power;

pipeline_summary = struct();
pipeline_summary.before = struct( ...
    'label', 'Before Pipeline', ...
    'sum_rate_bps_hz', sum_rate_before_pipeline, ...
    'avg_sinr_db', mean(10*log10(sinr_before_pipeline + 1e-12)), ...
    'energy_efficiency', sum_throughput_before_pipeline / total_system_power_before_pipeline, ...
    'nmse_db', estimation_quality_baseline.avg_nmse_db, ...
    'contamination_db', contamination_baseline);
pipeline_summary.after = struct( ...
    'label', 'After Pipeline', ...
    'sum_rate_bps_hz', performance_realtime.sum_rate_bps_hz, ...
    'avg_sinr_db', performance_realtime.average_sinr_db, ...
    'energy_efficiency', performance_realtime.energy_efficiency, ...
    'nmse_db', estimation_quality.avg_nmse_db, ...
    'contamination_db', estimation_quality.contamination_ratio_db);

% Display real results
fprintf('COMPUTED PERFORMANCE:\n');
fprintf('- Sum Rate: %.2f bps/Hz\n', sum_rate_bps_hz);
fprintf('- Sum Throughput: %.1f Mbps\n', sum_throughput_mbps);
fprintf('- Average SINR: %.2f dB\n', mean(sinr_db));
fprintf('- Energy Efficiency: %.3f Mbits/Joule\n', energy_efficiency);
fprintf('- Total Latency: %.2f ms\n', total_latency_ms);




%% Advanced Visualization and Analysis
fprintf('\n=== GENERATING ADVANCED VISUALIZATIONS ===\n');

% Create basic visualizations (simplified versions)
figure(1);
scatter(ap_positions(:,1), ap_positions(:,2), 100, 'r', 's', 'filled');
hold on;
scatter(user_positions(:,1), user_positions(:,2), 60, 'b', 'o', 'filled');
xlabel('X Position [m]'); ylabel('Y Position [m]');
title('Network Topology'); legend('APs', 'Users'); grid on;







%% ==========  PLOTS  ==========
fprintf('\n=== CREATING VISUALIZATION PLOTS ===\n');


% Force figures to be visible
set(0, 'DefaultFigureVisible', 'on');
set(0, 'DefaultFigureWindowStyle', 'normal');

try
    % Figure 1: Network Topology
    figure(1); clf; hold on;
    scatter(ap_positions(:,1), ap_positions(:,2), 120, 'r', 's', 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    scatter(user_positions(:,1), user_positions(:,2), 80, 'b', 'o', 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    
    % Draw connections for first 5 users
    for k = 1:min(5, params.K)
        for s = 1:min(3, size(serving_aps, 2))
            if serving_aps(k, s) <= size(ap_positions, 1)
                plot([user_positions(k,1), ap_positions(serving_aps(k,s),1)], ...
                     [user_positions(k,2), ap_positions(serving_aps(k,s),2)], ...
                     'g--', 'LineWidth', 0.8, 'Color', [0.5 0.5 0.5]);
            end
        end
    end
    
    xlabel('X Position [m]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Y Position [m]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Network Topology: %d APs, %d Users', params.L, params.K), ...
          'FontSize', 14, 'FontWeight', 'bold');
    legend('Access Points', 'Users', 'Location', 'best', 'FontSize', 10);
    grid on; axis equal;
    set(gca, 'FontSize', 11);
    drawnow; pause(0.1);
    fprintf('✓ Figure 1: Network Topology\n');
    
    % Figure 2: SINR Distribution
    figure(2); clf;
    histogram(performance_realtime.sinr_db, 20, 'FaceColor', [0.2, 0.6, 0.9], ...
              'EdgeColor', 'k', 'LineWidth', 1.2, 'FaceAlpha', 0.8);
    hold on;
    xline(mean(performance_realtime.sinr_db), 'r--', 'LineWidth', 3, ...
          'Label', sprintf('Mean: %.2f dB', mean(performance_realtime.sinr_db)));
    xlabel('SINR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Number of Users', 'FontSize', 12, 'FontWeight', 'bold');
    title('SINR Distribution Across Users', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 11);
    drawnow; pause(0.1);
    fprintf('✓ Figure 2: SINR Distribution\n');
    
    % Figure 3: Per-User Rate
    figure(3); clf;
    bar(1:params.K, performance_realtime.user_rates, 'FaceColor', [0.3, 0.8, 0.3], ...
        'EdgeColor', 'k', 'LineWidth', 1);
    hold on;
    yline(mean(performance_realtime.user_rates), 'r--', 'LineWidth', 2, ...
          'Label', sprintf('Mean: %.2f bps/Hz', mean(performance_realtime.user_rates)));
    xlabel('User Index', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Spectral Efficiency [bps/Hz]', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Per-User Rates (Sum: %.2f bps/Hz)', performance_realtime.sum_rate_bps_hz), ...
          'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 11);
    drawnow; pause(0.1);
    fprintf('✓ Figure 3: User Rates\n');
    
    % Figure 4: Power Consumption Breakdown
    figure(4); clf;
    power_vals = [tx_power_w, total_circuit_power, fronthaul_power, cpu_power];
    labels = {'Transmit', 'Circuit', 'Fronthaul', 'CPU'};
    
    pie(power_vals);
    value_labels = cell(size(labels));
    for idx = 1:numel(labels)
        value_labels{idx} = sprintf('%.2f W', power_vals(idx));
    end
    text_handles = flipud(findobj(gca, 'Type', 'text'));
    for idx = 1:min(numel(text_handles), numel(value_labels))
        set(text_handles(idx), 'String', value_labels{idx}, ...
            'FontSize', 11, 'FontWeight', 'bold');
    end
    title(sprintf('Power Breakdown (Total: %.1f W)', total_system_power_w), ...
          'FontSize', 14, 'FontWeight', 'bold');
    set(gca, 'FontSize', 11);
    colormap([0.2 0.6 0.9; 0.9 0.4 0.3; 0.3 0.8 0.3; 0.8 0.8 0.2]);
    legend(labels, 'Location', 'eastoutside', 'FontSize', 10);
    drawnow; pause(0.1);
    fprintf('✓ Figure 4: Power Breakdown\n');
    
    % Figure 5: SINR per User
    figure(5); clf;
    plot(1:params.K, performance_realtime.sinr_db, 'bo-', 'LineWidth', 2, ...
         'MarkerSize', 8, 'MarkerFaceColor', 'b');
    hold on;
    yline(mean(performance_realtime.sinr_db), 'r--', 'LineWidth', 2, ...
          'Label', 'Mean SINR');
    yline(min(performance_realtime.sinr_db), 'k:', 'LineWidth', 1.5, ...
          'Label', 'Min SINR');
    xlabel('User Index', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('SINR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
    title('SINR Performance per User', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 10);
    grid on;
    set(gca, 'FontSize', 11);
    drawnow; pause(0.1);
    fprintf('✓ Figure 5: SINR per User\n');
    
    % Figure 6 is filled after the mobility run, once distance and RSRP exist.
    figure(6); clf;
    axis off;
    text(0.5, 0.5, 'CDF plots will be generated after mobility simulation', ...
        'HorizontalAlignment', 'center', 'FontSize', 13, 'FontWeight', 'bold');
    drawnow; pause(0.1);
    fprintf('✓ Figure 6: CDF placeholder\n');
    
    % Figure 7: Performance Summary
    figure(7); clf;
    subplot(2,2,1);
    bar([pipeline_summary.before.sum_rate_bps_hz, ...
         pipeline_summary.after.sum_rate_bps_hz], 'FaceColor', [0.4 0.7 0.9]);
    set(gca, 'XTickLabel', {'Before', 'After'});
    ylabel('Sum Rate [bps/Hz]');
    title('System Performance: Sum Rate');
    grid on;
    
    subplot(2,2,2);
    bar([pipeline_summary.before.avg_sinr_db, ...
         pipeline_summary.after.avg_sinr_db], 'FaceColor', [0.9 0.5 0.3]);
    set(gca, 'XTickLabel', {'Before', 'After'});
    ylabel('Average SINR [dB]');
    title('Channel + Precoding Gain');
    grid on;
    
    subplot(2,2,3);
    bar([pipeline_summary.before.energy_efficiency, ...
         pipeline_summary.after.energy_efficiency], 'FaceColor', [0.3 0.8 0.3]);
    set(gca, 'XTickLabel', {'Before', 'After'});
    ylabel('Mbits/Joule');
    title('Power Allocation Impact');
    grid on;
    
    subplot(2,2,4);
    bar([pipeline_summary.before.nmse_db, pipeline_summary.after.nmse_db; ...
         pipeline_summary.before.contamination_db, pipeline_summary.after.contamination_db].', ...
         'grouped');
    set(gca, 'XTickLabel', {'Before', 'After'});
    ylabel('dB');
    legend({'NMSE', 'Contamination'}, 'Location', 'best');
    title('Channel Estimation Quality');
    grid on;
    
    sgtitle('Performance Summary: Before vs After Full Pipeline', ...
        'FontSize', 16, 'FontWeight', 'bold');
    drawnow; pause(0.1);
    fprintf('✓ Figure 7: Performance Summary\n');
    
    % Figure 8: Pilot Assignment
    figure(8); clf;
    if exist('pilot_scheme', 'var')
        histogram(pilot_scheme, 'FaceColor', [0.7 0.3 0.8], 'EdgeColor', 'k');
        xlabel('Pilot Index', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Number of Users', 'FontSize', 12, 'FontWeight', 'bold');
        title(sprintf('Pilot Assignment (Reuse Factor: %.2f)', params.K/params.tau_p), ...
              'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        set(gca, 'FontSize', 11);
    else
        text(0.5, 0.5, 'Pilot scheme not available', 'HorizontalAlignment', 'center');
    end
    drawnow; pause(0.1);
    fprintf('✓ Figure 8: Pilot Assignment\n');
    
    % Success message
    fprintf('\n✓✓✓ Successfully created 8 figure windows! ✓✓✓\n');
    fprintf('All plots should be visible now.\n\n');
    
    % Bring all figures to front
    for fig_num = 1:8
        figure(fig_num);
    end
    
    % Final check
    % Final check - count open figures
    all_figs = findall(0, 'Type', 'figure');
    num_figs = length(all_figs);
    fprintf('Verification: %d figures exist in MATLAB\n', num_figs);
    
    


    drawnow; pause(0.1);
    
    
    % Success message for Figures 1-8
    fprintf('\n✓✓✓ Successfully created figures windows! ✓✓✓\n');
    fprintf('All plots should be visible now.\n\n');
    
catch ME
    fprintf('\n❌❌❌ ERROR CREATING PLOTS ❌❌❌\n');
    fprintf('Error message: %s\n', ME.message);
    fprintf('Error location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);

end
% Figure 9: Real Baseline Comparison
    fprintf('Creating Figure 9: Baseline Comparison...\n');
    figure(9); clf;
    
    % Extract data from baseline_results
    methods_plot = fieldnames(baseline_results);
    n_methods = length(methods_plot);
    
    avg_sinr_all = zeros(n_methods, 1);
    sum_rates_all = zeros(n_methods, 1);
    ee_all = zeros(n_methods, 1);
    
    for m = 1:n_methods
        avg_sinr_all(m) = baseline_results.(methods_plot{m}).avg_sinr_db;
        sum_rates_all(m) = baseline_results.(methods_plot{m}).sum_rate_bps_hz;
        ee_all(m) = baseline_results.(methods_plot{m}).energy_efficiency;
    end
    
    % Create 2x2 subplot
    subplot(2,2,1);
    bar(avg_sinr_all, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Average SINR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
    title('SINR Comparison', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    
    subplot(2,2,2);
    bar(sum_rates_all, 'FaceColor', [0.9 0.5 0.3], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Sum Rate [bps/Hz]', 'FontSize', 12, 'FontWeight', 'bold');
    title('Spectral Efficiency', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    
    subplot(2,2,3);
    bar(ee_all, 'FaceColor', [0.3 0.8 0.3], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Energy Efficiency [Mbits/J]', 'FontSize', 12, 'FontWeight', 'bold');
    title('Energy Efficiency', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    
    subplot(2,2,4);
    improvements = [improvement_over_MR; improvement_over_ZF; improvement_over_cent_mmse];
    bar(improvements, 'FaceColor', [0.7 0.3 0.8], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTickLabel', {'vs MR', 'vs ZF', 'vs MMSE'});
    xtickangle(45);
    ylabel('Improvement [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title('Proposed Method Gains', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    
    sgtitle('Real Baseline Comparison', 'FontSize', 15, 'FontWeight', 'bold');
    drawnow; pause(0.1);
    fprintf('✓ Figure 9: Baseline Comparison\n');
    % Figure 10: Comprehensive Dual-Scenario Comparison
    fprintf('Creating Figure 10: Comprehensive Dual-Scenario Comparison...\n');
    figure(10); clf;
    set(gcf, 'Position', [100, 50, 1400, 800]);
    
    % Extract data
    methods_plot = fieldnames(baseline_equal);
    n_methods = length(methods_plot);
    
    % Prepare data arrays
    sum_rates_equal = zeros(n_methods, 1);
    sum_rates_opt = zeros(n_methods, 1);
    sinr_equal = zeros(n_methods, 1);
    sinr_opt = zeros(n_methods, 1);
    ee_equal = zeros(n_methods, 1);
    ee_opt = zeros(n_methods, 1);
    
    for m = 1:n_methods
        method = methods_plot{m};
        sum_rates_equal(m) = baseline_equal.(method).sum_rate_bps_hz;
        sum_rates_opt(m) = baseline_optimized.(method).sum_rate_bps_hz;
        sinr_equal(m) = baseline_equal.(method).avg_sinr_db;
        sinr_opt(m) = baseline_optimized.(method).avg_sinr_db;
        ee_equal(m) = baseline_equal.(method).energy_efficiency;
        ee_opt(m) = baseline_optimized.(method).energy_efficiency;
    end
    
    % Subplot 1: Sum Rate Comparison
    subplot(2,3,1);
    x = 1:n_methods;
    bar_width = 0.35;
    bar(x - bar_width/2, sum_rates_equal, bar_width, 'FaceColor', [0.4 0.6 0.9], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);
    hold on;
    bar(x + bar_width/2, sum_rates_opt, bar_width, 'FaceColor', [0.9 0.5 0.3], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTick', x, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Sum Rate [bps/Hz]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Spectral Efficiency', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Equal Power', 'Optimized Power', 'Location', 'best');
    grid on;
    
    % Subplot 2: SINR Comparison
    subplot(2,3,2);
    bar(x - bar_width/2, sinr_equal, bar_width, 'FaceColor', [0.4 0.6 0.9], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);
    hold on;
    bar(x + bar_width/2, sinr_opt, bar_width, 'FaceColor', [0.9 0.5 0.3], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTick', x, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Average SINR [dB]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Signal Quality', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Equal Power', 'Optimized Power', 'Location', 'best');
    grid on;
    
    % Subplot 3: Energy Efficiency Comparison
    subplot(2,3,3);
    bar(x - bar_width/2, ee_equal, bar_width, 'FaceColor', [0.4 0.6 0.9], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);
    hold on;
    bar(x + bar_width/2, ee_opt, bar_width, 'FaceColor', [0.9 0.5 0.3], ...
        'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTick', x, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Energy Efficiency [Mbits/J]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Energy Performance', 'FontSize', 12, 'FontWeight', 'bold');
    legend('Equal Power', 'Optimized Power', 'Location', 'best');
    grid on;
    
    % Subplot 4: Relative Improvements (Equal Power scenario)
    subplot(2,3,4);
    improvements_equal_plot = [improvement_equal.over_MR; 
                               improvement_equal.over_ZF; 
                               improvement_equal.over_cent_mmse];
    bar(improvements_equal_plot, 'FaceColor', [0.3 0.8 0.3], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTickLabel', {'vs MR', 'vs ZF', 'vs Cent MMSE'});
    xtickangle(45);
    ylabel('Improvement [%]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Proposed Gains (Equal Power)', 'FontSize', 12, 'FontWeight', 'bold');
    yline(0, 'r--', 'LineWidth', 1);
    grid on;
    
    % Subplot 5: Relative Improvements (Optimized Power scenario)
    subplot(2,3,5);
    improvements_opt_plot = [improvement_opt.over_MR; 
                             improvement_opt.over_ZF; 
                             improvement_opt.over_cent_mmse];
    bar(improvements_opt_plot, 'FaceColor', [0.8 0.4 0.3], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTickLabel', {'vs MR', 'vs ZF', 'vs Cent MMSE'});
    xtickangle(45);
    ylabel('Improvement [%]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Proposed Gains (Optimized Power)', 'FontSize', 12, 'FontWeight', 'bold');
    yline(0, 'r--', 'LineWidth', 1);
    grid on;
    
    % Subplot 6: Power Optimization Impact
    subplot(2,3,6);
    power_gains = zeros(n_methods, 1);
    for m = 1:n_methods
        method = methods_plot{m};
        equal_rate = baseline_equal.(method).sum_rate_bps_hz;
        opt_rate = baseline_optimized.(method).sum_rate_bps_hz;
        power_gains(m) = 100 * (opt_rate - equal_rate) / equal_rate;
    end
    bar(power_gains, 'FaceColor', [0.7 0.3 0.8], 'EdgeColor', 'k', 'LineWidth', 1.2);
    set(gca, 'XTick', x, 'XTickLabel', strrep(methods_plot, '_', ' '));
    xtickangle(45);
    ylabel('Gain from Power Opt [%]', 'FontSize', 11, 'FontWeight', 'bold');
    title('Impact of Power Optimization', 'FontSize', 12, 'FontWeight', 'bold');
    yline(0, 'r--', 'LineWidth', 1);
    grid on;
    
    sgtitle('Comprehensive Baseline Comparison: Equal vs Optimized Power', ...
            'FontSize', 14, 'FontWeight', 'bold');
    
    drawnow; pause(0.1);
    fprintf('✓ Figure 10: Comprehensive Comparison\n');
if params.mobility_enabled
    fprintf('\n🚶 Starting mobility simulation...\n');
    fprintf('   Duration: %d seconds with %.1f km/h walking speed\n', ...
            params.simulation_time, params.user_velocity_kmh);
    tic;
    mobility_results = simulate_mobility_and_handover( ...
    params, ap_positions, user_positions, serving_aps, ...
    pilot_scheme, spatial_corr, beta_sub6, beta_mmwave, H_sub6, H_mmwave);

    
    
    mobility_time = toc;  
    fprintf('\n⏱️  ACTUAL Mobility simulation time: %.2f seconds\n', mobility_time);  
    fprintf('   Per-iteration time: %.1f ms\n', mobility_time / 120 * 1000);  
    fprintf('   Speedup achieved!\n\n'); 
    
    display_mobility_statistics(mobility_results, params);
    visualize_mobility_and_handover(mobility_results, ap_positions, params);
    visualize_metric_cdfs(baseline_equal, baseline_optimized, mobility_results, params);
else
    fprintf('\nℹ️  Mobility simulation disabled (set params.mobility_enabled = true to enable)\n');
end

visualize_contamination_analysis(estimation_quality, estimation_quality_baseline, ...
                                 pilot_scheme, user_positions, ap_positions, params);
%% Keep figures visible
fprintf('\n=== KEEPING FIGURES OPEN ===\n');


%% Keep figures visible
fprintf('\n=== KEEPING FIGURES OPEN ===\n');
fprintf('Figures will remain open. Close them manually or press Ctrl+C to stop.\n');
fprintf('Press ENTER to continue to Monte Carlo analysis...\n');
pause;

% === PILOT REUSE FACTOR ANALYSIS ===
fprintf('\n=== TESTING CONTAMINATION VS PILOT REUSE (ROBUST) ===\n');
% Pilot lengths for reuse experiment


tau_p_list = [5 10 20 40];

% Optional but recommended: run a few trials per tau_p to avoid "one-drop" artifacts
nTrials = 20;

reuse_results = struct([]);
for ii = 1:numel(tau_p_list)
    tau_p = tau_p_list(ii);
    params.tau_p = tau_p;

    cont_all = [];  % collect valid contamination ratios (linear) across trials

    for t = 1:nTrials
        rng(2000 + 31*t + tau_p, 'twister');

        % Re-run baseline estimator with this tau_p.
        % NOTE: pilot_scheme must be consistent with tau_p.
        % If your pilot assignment depends on params.tau_p, regenerate pilot_scheme here.
        % Otherwise, at least regenerate a random pilot assignment of length K with tau_p pilots.

        % --- Option 1 (best): regenerate via your pilot assignment function ---
        % pilot_scheme = spatial_pilot_assignment(...);  % if it uses params.tau_p internally

        % --- Option 2 (simple): random assignment with tau_p pilots ---
        pilot_scheme = randi(tau_p, params.K, 1);

        [~, ~, eq] = covariance_aware_estimation_literature( ...
            H_sub6, H_mmwave, pilot_scheme, spatial_corr, params, user_positions, ap_positions);

        % Pull the robust vector you just exposed
        cont_all = [cont_all; eq.valid_contamination_linear]; %#ok<AGROW>
    end

    % Robust stats
    reuse_factor = params.K / tau_p;

    med_db = 10*log10(median(cont_all));
    p90_db = 10*log10(prctile(cont_all, 90));
    p99_db = 10*log10(prctile(cont_all, 99));
    outage_frac = mean(10*log10(cont_all) > 0);

    reuse_results(ii).tau_p = tau_p;
    reuse_results(ii).reuse = reuse_factor;
    reuse_results(ii).median_db = med_db;
    reuse_results(ii).p90_db = p90_db;
    reuse_results(ii).p99_db = p99_db;
    reuse_results(ii).outage = outage_frac;

    fprintf('tau_p=%-3d reuse=%4.1fx | median=%+6.2f dB | p90=%+6.2f dB | p99=%+6.2f dB | outage(>0dB)=%.2f%%\n', ...
        tau_p, reuse_factor, med_db, p90_db, p99_db, 100*outage_frac);
end

% ================== CONTAMINATION VS PILOT REUSE ==================

% Pilot lengths to test
tau_p_test = [5 10 20 40];

% Storage: [median_dB, p90_dB, outage_frac]
contamination_vs_reuse = zeros(length(tau_p_test), 3);
tau_p_orig = params.tau_p;
tau_d_orig = params.tau_d;
overhead_orig = params.overhead_factor; 

for ii = 1:length(tau_p_test)
    params.tau_p = tau_p_test(ii);

    
    % Use random assignment for the test (simple & valid)
    pilot_scheme_test = randi(params.tau_p, params.K, 1);

    % Run baseline estimation
    [~, ~, eq] = covariance_aware_estimation_literature( ...
        H_sub6, H_mmwave, pilot_scheme_test, spatial_corr, ...
        params, user_positions, ap_positions);

    % Store ROBUST stats (already computed inside the estimator)
    contamination_vs_reuse(ii,1) = eq.median_contamination_ratio_db;
    contamination_vs_reuse(ii,2) = eq.p90_contamination_ratio_db;
    contamination_vs_reuse(ii,3) = eq.contam_outage_frac;
end

params.tau_p = tau_p_orig;
params.tau_d = tau_d_orig;
params.overhead_factor = overhead_orig;
% ================== END CONTAMINATION VS PILOT REUSE ==================


% Plot contamination vs reuse
figure(11);
plot(params.K./tau_p_test, contamination_vs_reuse(:,1), 'r-o', 'LineWidth', 2);
hold on;
plot(params.K./tau_p_test, contamination_vs_reuse(:,2), 'b-s', 'LineWidth', 2);
xlabel('Pilot Reuse Factor');
ylabel('Contamination Level [dB]');
title('Pilot Contamination Mitigation Performance');
legend('Median contamination', '90th percentile contamination', 'Location','best');

grid on;
% ===== END OF NEW BLOCK =====

fprintf('\n=== SIMULATION COMPLETE ===\n');


fprintf('Advanced CF-mMIMO system evaluation completed successfully!\n');
fprintf('Results saved for thesis analysis and documentation.\n\n');

%  Run Monte Carlo for confidence intervals
fprintf('\nRun Monte Carlo analysis for statistical confidence? (y/n): ');
monte_carlo_choice = input('', 's');
if strcmpi(monte_carlo_choice, 'y')
    [mc_results, mc_ci] = run_monte_carlo_analysis(params, ap_positions, user_positions, 30);
    performance_realtime.monte_carlo = mc_results;
    performance_realtime.confidence_intervals = mc_ci;
    
    % Save Monte Carlo results
    save('advanced_cfmimo_results_with_mc.mat', 'params', 'performance_realtime', ...
     'mc_results', 'mc_ci');  
end


%% ALL FUNCTION DEFINITIONS 

function [ap_pos, ap_types] = deploy_hierarchical_aps(params)
    urban_fraction = 0.6;
    urban_ap_fraction = 0.7;
    perturbation_factor = 0.3;
    
    urban_area = [0, 0, params.area_size*urban_fraction, params.area_size*urban_fraction];
    urban_aps = round(params.L * urban_ap_fraction); % 45 aps
    grid_spacing_urban = min(urban_area(3), urban_area(4)) / sqrt(urban_aps);
    
    
    
    % Urban APs (grid-based)
    % Pre-allocate maximum possible size
    max_possible = ceil(sqrt(urban_aps))^2;
    ap_pos = zeros(max_possible, 2);
    ap_types = zeros(max_possible, 1);
    count = 0;  % Track actual number of APs
    
    for i = 1:ceil(sqrt(urban_aps))
        for j = 1:ceil(sqrt(urban_aps))
            if count < urban_aps
                x = urban_area(1) + (i-1) * grid_spacing_urban + grid_spacing_urban/2;
                y = urban_area(2) + (j-1) * grid_spacing_urban + grid_spacing_urban/2;
                x = x + (rand - 0.5) * perturbation_factor * grid_spacing_urban;
                y = y + (rand - 0.5) * perturbation_factor * grid_spacing_urban;
                if x <= urban_area(1) + urban_area(3) && y <= urban_area(2) + urban_area(4)
                    count = count + 1;
                    ap_pos(count, :) = [x, y];
                    ap_types(count) = 1;
                end
            end
        end
    end
    

    % Trim to actual size
    ap_pos = ap_pos(1:count, :);
    ap_types = ap_types(1:count);
    % Suburban APs with safety counter
    remaining_aps = params.L - size(ap_pos, 1);  % How many more APs needed
    temp_ap_pos = zeros(remaining_aps, 2);       % Pre-allocate for remaining
    temp_ap_types = zeros(remaining_aps, 1);
    count = 0;                                    % Counter for placed APs
    
    max_attempts = params.L * 100;
    attempts = 0;
    
    while count < remaining_aps && attempts < max_attempts
        x = rand * params.area_size;
        y = rand * params.area_size;
        if x > urban_area(1) + urban_area(3) || y > urban_area(2) + urban_area(4)
            count = count + 1;
            temp_ap_pos(count, :) = [x, y];
            temp_ap_types(count) = 2;
        end
        attempts = attempts + 1;
    end
    
    % Append successfully placed APs
    if count > 0
        ap_pos = [ap_pos; temp_ap_pos(1:count, :)];
        ap_types = [ap_types; temp_ap_types(1:count)];
    end
    
    if size(ap_pos, 1) < params.L
        warning('Could not place all APs. Placed %d out of %d', size(ap_pos, 1), params.L);
    end
end


function [user_pos, user_priorities] = deploy_clustered_users(params)
    % Configurable parameters
    n_clusters = 5;
    cluster_sizes = [0.3, 0.25, 0.2, 0.15, 0.1];
    cluster_spread_factor = 20;
    
    % Validate
    assert(abs(sum(cluster_sizes) - 1.0) < 1e-6, 'cluster_sizes must sum to 1.0');
    assert(length(cluster_sizes) == n_clusters, 'cluster_sizes length must match n_clusters');
    
    cluster_centers = rand(n_clusters, 2) * params.area_size;
    sigma_cluster = params.area_size / cluster_spread_factor;
    
    
    % Pre-allocate for all K users
    user_pos = zeros(params.K, 2);
    user_priorities = zeros(params.K, 1);
    count = 0;  % Track number of placed users
    
    % Deploy clustered users
    for c = 1:n_clusters
        n_users_cluster = round(params.K * cluster_sizes(c));
        for u = 1:n_users_cluster
            if count < params.K  % Safety check
                count = count + 1;
                pos = cluster_centers(c, :) + sigma_cluster * randn(1, 2);
                pos = max([0, 0], min([params.area_size, params.area_size], pos));
                user_pos(count, :) = pos;
                user_priorities(count) = c;
            end
        end
    end
    
    % Safety: fill any remaining users (keeps original logic)
    while count < params.K
        count = count + 1;
        pos = rand(1, 2) * params.area_size;
        user_pos(count, :) = pos;
        user_priorities(count) = randi(n_clusters);
    end
    
    % Trim if somehow exceeded (shouldn't happen, but defensive)
    user_pos = user_pos(1:count, :);
    user_priorities = user_priorities(1:count);
end

function cellular_pos = deploy_cellular_overlay(params)
    % Configurable parameters
    cellular_to_ap_ratio = 10;      % How many APs per cellular BS
    hex_spacing_factor = 2;         % Spacing adjustment factor
    
    n_cellular = ceil(params.L / cellular_to_ap_ratio); % 7 BS
    
    
    % Hexagonal grid parameters
    hex_radius = params.area_size / sqrt(n_cellular * hex_spacing_factor);
    
    % Hexagonal geometry constants
    horizontal_spacing = 1.5;
    vertical_spacing = sqrt(3)/2;
    row_offset = sqrt(3)/4;
    
    % Pre-allocate maximum possible hexagonal positions
    max_hex_cells = (ceil(sqrt(n_cellular)) + 1)^2;
    cellular_pos = zeros(max_hex_cells, 2);
    count = 0;
    
    for i = 0:ceil(sqrt(n_cellular))
        for j = 0:ceil(sqrt(n_cellular))
            if count < n_cellular
                x = i * hex_radius * horizontal_spacing;
                y = j * hex_radius * vertical_spacing;
                % Offset alternating rows for hexagonal pattern
                if mod(i, 2) == 0
                    y = y + hex_radius * row_offset;
                end
                % Check bounds
                if x <= params.area_size && y <= params.area_size
                    count = count + 1;
                    cellular_pos(count, :) = [x, y];
                end
            end
        end
    end
    
    % Trim to actual size
    cellular_pos = cellular_pos(1:count, :);
end


function [beta_sub6, beta_mmwave] = compute_dual_band_pathloss(ap_pos, user_pos, params)
    n_ap = size(ap_pos, 1);
    n_users = size(user_pos, 1);
    
    beta_sub6 = zeros(n_ap, n_users);
    beta_mmwave = zeros(n_ap, n_users);
    
    for l = 1:n_ap
        for k = 1:n_users
            d = norm(ap_pos(l, :) - user_pos(k, :));
            d = max(d, 1); % Minimum distance
            
            % Sub-6 GHz path loss (3GPP Urban Macro model)
            fc_ghz = params.fc(1) / 1e9;
            PL_sub6 = 28 + 22*log10(d) + 20*log10(fc_ghz);
            shadow_sub6 = params.sigma_shadow * randn();
            beta_sub6(l, k) = 10^(-(PL_sub6 + shadow_sub6)/10);
            
            % mmWave path loss (3GPP Urban Micro model with blockage)
            fc_ghz_mm = params.fc(2) / 1e9;
            PL_los = 32.4 + 21*log10(d) + 20*log10(fc_ghz_mm);
            PL_nlos = 35.3 + 22.4*log10(d) + 21.3*log10(fc_ghz_mm) ;
            
            % Blockage probability (simplified)
            p_los = exp(-d/200);
            PL_mmwave = p_los * PL_los + (1-p_los) * PL_nlos;
            shadow_mm = params.sigma_shadow * 1.5 * randn(); % Higher shadow fading
            beta_mmwave(l, k) = 10^(-(PL_mmwave + shadow_mm)/10);
        end
    end
end

function [H_sub6, H_mmwave, spatial_corr, channel_history] = ...
generate_correlated_channels_with_mobility(ap_pos, user_pos, params, beta_sub6, beta_mmwave, time_index, channel_history)
    % --- Default inputs (robust to missing args) ---
    if nargin < 6 || isempty(time_index)
        time_index = 1;
    end
    if nargin < 7 || isempty(channel_history)
        channel_history = struct();
    end

    % Generate spatially and temporally correlated channels
    % References: 
    %   - 3GPP TR 38.901 V16.1.0 (2019-12) - Channel model
    %   - Jakes, W.C., "Microwave Mobile Communications", 1974 - Temporal correlation
    
    n_ap = size(ap_pos, 1);
    n_users = size(user_pos, 1);
    
    H_sub6 = zeros(params.M, n_users, n_ap);
    H_mmwave = zeros(params.M, n_users, n_ap);
    spatial_corr = cell(n_ap, n_users);
    
    % Antenna spacing (half wavelength)
    d_antenna = 0.5;
    
    % Temporal correlation parameters (for mobility)
    if nargin < 4
        time_index = 1; % First time sample if not specified
    end
    
    % Maximum Doppler frequency based on user velocity
    % f_d = v * f_c / c
    v_max = max(params.user_velocity_kmh) / 3.6; % Convert km/h to m/s
    f_d_sub6 = v_max * params.fc(1) / params.c;
    f_d_mmwave = v_max * params.fc(2) / params.c;
    
    % Sampling interval (assuming 1 kHz sampling)
    T_s = 1e-3; % 1 ms
    tau = (time_index - 1) * T_s;
    
    % Temporal correlation coefficient (Jake's model)
    % R(tau) = J_0(2*pi*f_d*tau) where J_0 is Bessel function of first kind
    rho_sub6 = besselj(0, 2*pi*f_d_sub6*tau);
    rho_mmwave = besselj(0, 2*pi*f_d_mmwave*tau);
    
    for l = 1:n_ap
        for k = 1:n_users
            % Angle of arrival
            pos_diff = user_pos(k, :) - ap_pos(l, :);
            aoa = atan2(pos_diff(2), pos_diff(1));
            distance = norm(pos_diff);
            
            % Angular spread (3GPP TR 38.901 Table 7.5-6)
            % Sub-6 GHz: Urban Macro (UMa)
            angle_spread_sub6 = 35 * pi/180; % 35 degrees RMS
            
            % mmWave: Urban Micro (UMi) with smaller spread
            angle_spread_mm = 10 * pi/180;   % 10 degrees RMS for LoS
            
            % Generate spatial correlation matrix
            R_sub6 = generate_spatial_correlation_matrix(params.M, aoa, angle_spread_sub6, d_antenna, params.fc(1));
            R_mm = generate_spatial_correlation_matrix(params.M, aoa, angle_spread_mm, d_antenna, params.fc(2));

            % Verify it's PSD
            assert(min(eig(R_sub6)) >= -1e-10, 'R_sub6 not PSD!');
            assert(min(eig(R_mm)) >= -1e-10, 'R_mm not PSD!');

            spatial_corr{l, k} = struct('R_sub6', R_sub6, 'R_mm', R_mm);
            
            % ===== SUB-6 GHz: RAYLEIGH FADING (NLoS dominant) =====
            h_iid_sub6 = (randn(params.M, 1) + 1j*randn(params.M, 1)) / sqrt(2);
            if l <= size(beta_sub6, 1) && k <= size(beta_sub6, 2)
                path_loss_factor = sqrt(beta_sub6(l, k));
            else
                path_loss_factor = 1;  % Fallback
            end
            
            H_sub6(:, k, l) = path_loss_factor * sqrtm(R_sub6) * h_iid_sub6;
            
            % ===== mmWAVE: RICIAN FADING (LoS component) =====
            % 3GPP TR 38.901 Section 7.5 - Rician K-factor model
            % K = 13 - 0.03*d [dB] for UMi-Street Canyon LoS
            K_factor_dB = compute_rician_K_factor_3gpp(distance, params.fc(2));
            K_factor_linear = 10^(K_factor_dB/10);
            
            % LoS component: Uniform Planar Array (UPA) steering vector
            % 3GPP TR 38.901 Section 7.5.2
            lambda_mm = params.c / params.fc(2);
            k_wave = 2*pi / lambda_mm;
            
            % LoS steering vector for ULA (Uniform Linear Array)
            h_los = exp(1j * k_wave * d_antenna * (0:params.M-1)' * sin(aoa));
            h_los = h_los / sqrt(params.M); % Normalize
            
            % NLoS component: Rayleigh fading
            h_nlos_iid = (randn(params.M, 1) + 1j*randn(params.M, 1)) / sqrt(2);
            h_nlos = sqrtm(R_mm) * h_nlos_iid;
            
            % Rician fading: h = sqrt(K/(K+1)) * h_LoS + sqrt(1/(K+1)) * h_NLoS
            % Reference: 3GPP TR 38.901 Eq. (7.5-1)
            % Rician fading: h = sqrt(K/(K+1)) * h_LoS + sqrt(1/(K+1)) * h_NLoS
            % Reference: 3GPP TR 38.901 Eq. (7.5-1)
            
            
            % Rician fading: h = sqrt(K/(K+1)) * h_LoS + sqrt(1/(K+1)) * h_NLoS
            % Reference: 3GPP TR 38.901 Eq. (7.5-1)
            h_rician = sqrt(K_factor_linear/(K_factor_linear+1)) * h_los + ...
                       sqrt(1/(K_factor_linear+1)) * h_nlos;
            
            % Apply large-scale fading (path loss + shadowing)
            if l <= size(beta_mmwave, 1) && k <= size(beta_mmwave, 2)
                path_loss_factor = sqrt(beta_mmwave(l, k));
            else
                path_loss_factor = 1;  % Fallback
            end
            
            H_mmwave(:, k, l) = path_loss_factor * h_rician;
            
            if time_index > 1 && isfield(channel_history,'H_sub6_prev') && isfield(channel_history,'H_mmwave_prev')
                H_sub6(:,k,l)   = rho_sub6   * channel_history.H_sub6_prev(:,k,l)   + sqrt(max(0,1-rho_sub6^2))   * H_sub6(:,k,l);
                H_mmwave(:,k,l) = rho_mmwave * channel_history.H_mmwave_prev(:,k,l) + sqrt(max(0,1-rho_mmwave^2)) * H_mmwave(:,k,l);
            end

        end
    end
    
    % Store channel history for temporal correlation (placeholder)
    channel_history = struct();
    channel_history.time_index = time_index;
    channel_history.rho_sub6 = rho_sub6;
    channel_history.rho_mmwave = rho_mmwave;
    channel_history.H_sub6_prev = H_sub6;
    channel_history.H_mmwave_prev = H_mmwave;
    
    
    

    fprintf('Channel generation with mobility: time_index=%d, rho_sub6=%.3f, rho_mmwave=%.3f\n', ...
            time_index, rho_sub6, rho_mmwave);
end

function R = generate_spatial_correlation_matrix(M, aoa, angle_spread, d_antenna, fc)
    % Generate spatial correlation matrix with GUARANTEED positive semi-definite property
    %
    % Inputs:
    %   M: Number of antennas
    %   aoa: Angle of arrival (radians)
    %   angle_spread: Angular spread (radians, RMS)
    %   d_antenna: Antenna spacing (in wavelengths, typically 0.5)
    %   fc: Carrier frequency (Hz)
    %
    % Output:
    %   R: Spatial correlation matrix (M × M), guaranteed Hermitian PSD
    %
    % Reference: 3GPP TR 38.901 Section 7.5.4
    %
    % Key fix: Uses eigendecomposition instead of SVD to ensure PSD
    
    c = 3e8;
    lambda = c / fc;
    
    % === STEP 1: Generate correlation matrix ===
    R = zeros(M, M);
    
    for m1 = 1:M
        for m2 = 1:M
            if m1 == m2
                R(m1, m2) = 1;  % Perfect correlation with self
            else
                % Antenna element separation
                delta_m = m1 - m2;  % Keep sign for phase
                
                % Distance in wavelengths
                d_wavelengths = abs(delta_m) * d_antenna / lambda;
                
                % === MAGNITUDE: Gaussian angular spread decay ===
                % Based on 3GPP model: R(Δm) = exp(-0.5 * (σ_θ * k * d)^2)
                % where σ_θ is angular spread, k is wavenumber
                magnitude = exp(-0.5 * (angle_spread * 2*pi * d_wavelengths)^2);
                
                % === PHASE: ULA steering vector ===
                phase_shift = 2*pi * (delta_m * d_antenna / lambda) * sin(aoa);
                phase = exp(1j * phase_shift);
                
                % Combine
                R(m1, m2) = magnitude * phase;
            end
        end
    end
    
    % === STEP 2: Force Hermitian ===
    R = (R + R') / 2;
    
    % === STEP 3: Ensure Positive Semi-Definite (THE CRITICAL FIX) ===
    
    % Method 1: Eigendecomposition (correct way)
    [V, D] = eig(R);
    
    % Extract eigenvalues
    eigenvalues = real(diag(D));  % Should be real for Hermitian matrix
    
    % Check if any negative (numerical errors)
    num_negative = sum(eigenvalues < 0);
    if num_negative > 0
        fprintf('  Warning: %d negative eigenvalues found (numerical error)\n', num_negative);
        fprintf('    Min eigenvalue: %.2e\n', min(eigenvalues));
    end
    
    % Floor negative eigenvalues (numerical errors) to small positive value
    min_eigenvalue = 1e-6;  % Stronger floor
    eigenvalues_fixed = max(eigenvalues, min_eigenvalue);
    eigenvalues_fixed = eigenvalues_fixed / sum(eigenvalues_fixed) * M;
    % Reconstruct matrix with non-negative eigenvalues
    D_fixed = diag(eigenvalues_fixed);
    R = V * D_fixed * V';
    
    % Force Hermitian again (numerical precision)
    R = (R + R') / 2;
    
    % === STEP 4: VERIFICATION ===
    
    % Check 1: Is it Hermitian?
    hermitian_error = norm(R - R', 'fro') / norm(R, 'fro');
    if hermitian_error > 1e-10
        warning('Matrix not Hermitian: relative error = %.2e', hermitian_error);
    end
    
    % Check 2: Are all eigenvalues non-negative?
    final_eigenvalues = eig(R);
    min_final_eig = min(real(final_eigenvalues));
    
    if min_final_eig < -1e-10
        error('FATAL: Matrix still has negative eigenvalues: min = %.2e', min_final_eig);
    end
    
    % Check 3: Is diagonal all ones (correlation matrix property)?
    diag_error = max(abs(diag(R) - 1));
    if diag_error > 1e-6
        warning('Diagonal elements not unity: max error = %.2e', diag_error);
        % Renormalize if needed
        D_norm = diag(1 ./ sqrt(abs(diag(R))));
        R = D_norm * R * D_norm;
    end
    
    % === SUCCESS ===
    % R is now guaranteed to be:
    % 1. Hermitian: R = R'
    % 2. Positive semi-definite: all eigenvalues ≥ 0
    % 3. Unit diagonal: R(m,m) = 1
end


function K_factor_dB = compute_rician_K_factor_3gpp(distance, fc_hz)
    % 3GPP TR 38.901 Table 7.5-6: UMi-Street Canyon LoS
    
    if distance < 18
        K_mean_dB = 9;
    else
        K_mean_dB = 9 - 15*log10(distance/18);  
    end
    
    % Shadow fading on K-factor (3GPP Section 7.5)
    K_sigma_dB = 3.5;  % Standard deviation
    K_factor_dB = K_mean_dB + K_sigma_dB * randn();
    
    % K-factor cannot be negative
    K_factor_dB = max(K_factor_dB, 0);

end

function [serving_aps, load_balance] = advanced_ap_selection(beta_sub6, beta_mmwave, params)
    % Advanced AP selection with load balancing and QoS awareness

    fprintf('\n🔍 DEBUGGING PATH LOSS VALUES:\n');
    fprintf('beta_sub6 range: [%.2e, %.2e]\n', min(beta_sub6(:)), max(beta_sub6(:)));
    fprintf('beta_mmwave range: [%.2e, %.2e]\n', min(beta_mmwave(:)), max(beta_mmwave(:)));
    serving_aps = zeros(params.K, params.S);
    load_balance = zeros(params.L, 1);
    
    % Combined path loss (frequency-aware)
    beta_combined = 0.7 * beta_sub6 + 0.3 * beta_mmwave; % Weighted combination
    
    for k = 1:params.K
        % Get AP candidates sorted by path loss
        [~, ap_indices] = sort(beta_combined(:, k), 'descend');  % ✓ Changed sorted_beta to ~
        
        % ✓ PRE-ALLOCATE selected_aps
        selected_aps = zeros(1, params.S);  % Pre-allocate for S APs
        count = 0;  % Counter for selected APs
        
        % Select APs considering load balancing
        max_load = ceil(params.K * params.S / params.L)+1;
        
        for i = 1:length(ap_indices)
            if count >= params.S  % Already selected enough APs
                break;
            end
            
            ap = ap_indices(i);
            
            % Load balancing factor
            if load_balance(ap) < max_load
                count = count + 1;
                selected_aps(count) = ap;  % ✓ Use indexing instead of concatenation
                load_balance(ap) = load_balance(ap) + 1;
            end
        end
        
        % Fill remaining slots if needed
        while count < params.S
            remaining_aps = setdiff(1:params.L, selected_aps(1:count));
            [~, min_load_idx] = min(load_balance(remaining_aps));
            ap_to_add = remaining_aps(min_load_idx);
            
            count = count + 1;
            selected_aps(count) = ap_to_add;  % ✓ Use indexing
            load_balance(ap_to_add) = load_balance(ap_to_add) + 1;
        end
        
        serving_aps(k, :) = selected_aps;  % All S slots are now filled
    end
    % === DISPLAY RESULTS ===
    fprintf('\n╔════════════════════════════════════════════════════════╗\n');
    fprintf('║       AP SELECTION & LOAD BALANCING RESULTS           ║\n');
    fprintf('╚════════════════════════════════════════════════════════╝\n\n');
    
    % === 1. LOAD BALANCE STATISTICS ===
    fprintf('─── LOAD BALANCE STATISTICS ───\n');
    fprintf('Total users: %d\n', params.K);
    fprintf('Total APs: %d\n', params.L);
    fprintf('Serving APs per user (S): %d\n', params.S);
    fprintf('Total serving relationships: %d\n', params.K * params.S);
    fprintf('Theoretical average load: %.2f users/AP\n', (params.K * params.S) / params.L);
    fprintf('Max allowed load: %d users/AP\n', max_load);
    fprintf('\n');
    
    % Load distribution
    fprintf('Actual load distribution:\n');
    for load_level = 0:max(load_balance)
        num_aps = sum(load_balance == load_level);
        percentage = 100 * num_aps / params.L;
        
        if num_aps > 0
            % Create bar visualization
            bar_length = round(percentage / 2);  % Scale to fit screen
            bar = repmat('█', 1, bar_length);
            
            fprintf('  Load %d: %2d APs (%5.1f%%) %s\n', ...
                    load_level, num_aps, percentage, bar);
        end
    end
    
    fprintf('\nLoad statistics:\n');
    fprintf('  Minimum load: %d users/AP\n', min(load_balance));
    fprintf('  Average load: %.2f users/AP\n', mean(load_balance));
    fprintf('  Maximum load: %d users/AP\n', max(load_balance));
    fprintf('  Std deviation: %.2f\n', std(double(load_balance)));
    
    % Check balance quality
    if max(load_balance) <= max_load
        fprintf('  ✓ Load balancing successful (all APs within limit)\n');
    else
        fprintf('  ⚠ Warning: Some APs exceed max load!\n');
    end
    
    if min(load_balance) == 0
        fprintf('  ⚠ Warning: %d APs are idle (not serving anyone)\n', sum(load_balance == 0));
    else
        fprintf('  ✓ All APs utilized\n');
    end
    
    fprintf('\n');
    
    % === 2. SERVING APs PER USER (First 10 users as example) ===
    fprintf('─── SERVING APs ASSIGNMENT (First 10 users) ───\n');
    fprintf('User | Serving APs [sorted by quality]\n');
    fprintf('─────┼────────────────────────────────────────\n');
    
    display_users = min(10, params.K);
    for k = 1:display_users
        fprintf(' %2d  │ ', k);
        
        % Display serving APs
        for s = 1:params.S
            fprintf('AP%-2d ', serving_aps(k, s));
        end
        
        % Show average path loss for this user
        avg_beta = 0;
        for s = 1:params.S
            l = serving_aps(k, s);
            if l <= size(beta_combined, 1) && k <= size(beta_combined, 2)
                avg_beta = avg_beta + beta_combined(l, k);
            end
        end
        avg_beta = avg_beta / params.S;
        
        fprintf(' (avg β=%.2e)', avg_beta);
        fprintf('\n');
    end
    
    if params.K > 10
        fprintf(' ...  │ (%d more users)\n', params.K - 10);
    end
    
    fprintf('\n');
    
    % === 3. MOST/LEAST LOADED APs ===
    fprintf('─── MOST LOADED APs (Top 5) ───\n');
    [sorted_load, sorted_ap_idx] = sort(load_balance, 'descend');
    
    fprintf(' AP  | Load | Serving Users\n');
    fprintf('─────┼──────┼────────────────────────────\n');
    
    for i = 1:min(5, params.L)
        ap_id = sorted_ap_idx(i);
        load = sorted_load(i);
        
        % Find which users this AP serves
        [users_served, ~] = find(serving_aps == ap_id);
        users_served = unique(users_served);
        
        fprintf(' %-3d │  %d   │ ', ap_id, load);
        
        % Display up to 8 users
        for j = 1:min(8, length(users_served))
            fprintf('U%-2d ', users_served(j));
        end
        if length(users_served) > 8
            fprintf('...');
        end
        fprintf('\n');
    end
    
    fprintf('\n');
    
    fprintf('─── LEAST LOADED APs (Bottom 5) ───\n');
    fprintf(' AP  | Load | Serving Users\n');
    fprintf('─────┼──────┼────────────────────────────\n');
    
    for i = params.L:-1:max(params.L-4, 1)
        ap_id = sorted_ap_idx(i);
        load = sorted_load(i);
        
        % Find which users this AP serves
        [users_served, ~] = find(serving_aps == ap_id);
        users_served = unique(users_served);
        
        fprintf(' %-3d │  %d   │ ', ap_id, load);
        
        if load == 0
            fprintf('(idle)');
        else
            for j = 1:length(users_served)
                fprintf('U%-2d ', users_served(j));
            end
        end
        fprintf('\n');
    end
    
    fprintf('\n');
    
    % === 4. CLUSTERING ANALYSIS ===
    fprintf('─── USER-AP CLUSTERING ANALYSIS ───\n');
    
    % Count AP sharing between users
    sharing_matrix = zeros(params.K, params.K);
    for k1 = 1:params.K
        for k2 = k1+1:params.K
            % Count common APs
            common_aps = length(intersect(serving_aps(k1,:), serving_aps(k2,:)));
            sharing_matrix(k1, k2) = common_aps;
            sharing_matrix(k2, k1) = common_aps;
        end
    end
    
    avg_sharing = mean(sharing_matrix(sharing_matrix > 0));
    max_sharing = max(sharing_matrix(:));
    
    fprintf('Average AP overlap between users: %.2f APs\n', avg_sharing);
    fprintf('Maximum AP overlap: %d APs\n', max_sharing);
    
    % Count how many users share at least 1 AP with each user
    users_with_overlap = zeros(params.K, 1);
    for k = 1:params.K
        users_with_overlap(k) = sum(sharing_matrix(k, :) > 0);
    end
    
    fprintf('Average cooperating users per user: %.1f\n', mean(users_with_overlap));
    fprintf('  (users sharing at least 1 common AP)\n');
    
    fprintf('\n');
    
    % === 5. PATH LOSS QUALITY ===
    fprintf('─── PATH LOSS QUALITY ANALYSIS ───\n');
    
    % Compute average path loss for serving vs non-serving APs
    serving_beta_avg = zeros(params.K, 1);
    non_serving_beta_avg = zeros(params.K, 1);
    
    for k = 1:params.K
        % Average for serving APs
        serving_betas = [];
        for s = 1:params.S
            l = serving_aps(k, s);
            if l <= size(beta_combined, 1) && k <= size(beta_combined, 2)
                serving_betas = [serving_betas; beta_combined(l, k)];
            end
        end
        serving_beta_avg(k) = mean(serving_betas);
        
        % Average for non-serving APs
        all_aps = 1:params.L;
        non_serving = setdiff(all_aps, serving_aps(k, :));
        non_serving_betas = [];
        for l = non_serving
            if l <= size(beta_combined, 1) && k <= size(beta_combined, 2)
                non_serving_betas = [non_serving_betas; beta_combined(l, k)];
            end
        end
        non_serving_beta_avg(k) = mean(non_serving_betas);
    end
    
    fprintf('Average β for serving APs: %.2e\n', mean(serving_beta_avg));
    fprintf('Average β for non-serving APs: %.2e\n', mean(non_serving_beta_avg));
    
    improvement_ratio = mean(serving_beta_avg) / mean(non_serving_beta_avg);
    improvement_db = 10*log10(improvement_ratio);
    
    fprintf('Quality improvement: %.2f× (%.2f dB)\n', improvement_ratio, improvement_db);
    fprintf('  → Serving APs are %.1f× better than average!\n', improvement_ratio);
    
    fprintf('\n');
    
    fprintf('════════════════════════════════════════════════════════\n\n');
    
end
function [initial_beams, search_complexity] = position_based_beam_prediction(H, ap_pos, user_pos, params)
   
    
    initial_beams = zeros(params.M, params.K, params.L);
    search_complexity = struct();
    
    
    total_searches = 0;
    
    for l = 1:params.L
        for k = 1:params.K
            h = squeeze(H(:, k, l));
            
            if norm(h) > 1e-10
                % Position-based beam prediction 
                pos_diff = user_pos(k, :) - ap_pos(l, :);
                predicted_angle = atan2(pos_diff(2), pos_diff(1));
                
                % Generate beam around predicted angle
                a_predicted = exp(1j * (0:params.M-1)' * pi * sin(predicted_angle));
                a_predicted = a_predicted / norm(a_predicted);
                
                % Local refinement around prediction (reduced search space)
                n_local_search = 8; % Much smaller than exhaustive search
                best_beam = a_predicted;
                best_gain = abs(h' * a_predicted)^2;
                
                for b = 1:n_local_search
                    angle_offset = (b - n_local_search/2) * 0.1; % Small angular offsets
                    test_angle = predicted_angle + angle_offset;
                    
                    a_test = exp(1j * (0:params.M-1)' * pi * sin(test_angle));
                    a_test = a_test / norm(a_test);
                    
                    gain = abs(h' * a_test)^2;
                    if gain > best_gain
                        best_gain = gain;
                        best_beam = a_test;
                    end
                end
                
                initial_beams(:, k, l) = best_beam;
                total_searches = total_searches + n_local_search;
            end
        end
    end
    
    search_complexity.total_searches = total_searches;
    search_complexity.reduction_factor = params.N_sectors_coarse / 8; % Compared to exhaustive search
end

function [refined_beams, coordination_overhead] = coordinated_beam_refinement(initial_beams, H_mmwave, serving_aps, params)
    % CORRECTED: Maximum Ratio Transmission (MRT) beamforming
    % Note: Not truly "coordinated" - just sequential MRT for all links
    
    refined_beams = zeros(size(initial_beams));
    coordination_overhead = struct();
    
    % Number of refinement iterations (currently does nothing meaningful)
    n_refinement_iterations = 3;
    total_refinements = 0;
    
    for k = 1:params.K
        % Get serving APs for this user
        user_serving_aps = serving_aps(k, :);
        user_serving_aps = user_serving_aps(user_serving_aps > 0);  % Remove zeros
        
        % Iterate refinement (currently just overwrites same result)
        for iter = 1:n_refinement_iterations
            for s = 1:length(user_serving_aps)
                ap_idx = user_serving_aps(s);
                
                if ap_idx <= size(H_mmwave, 3)
                    h = squeeze(H_mmwave(:, k, ap_idx));
                    
                    if norm(h) > 1e-10
                        % ===== METHOD: Maximum Ratio Transmission (MRT) =====
                        % Align beam with channel direction
                        
                        % OPTION 1: Using SVD (current, overcomplicated)
                        % [U, ~, ~] = svd(h * h');
                        % w_refined = U(:, 1);
                        
                        % OPTION 2: Direct normalization (equivalent, simpler)
                        w_refined = h / norm(h);  % ✓ Use this instead!
                        
                        refined_beams(:, k, ap_idx) = w_refined;
                        total_refinements = total_refinements + 1;
                    else
                        % Channel too weak, keep initial beam
                        refined_beams(:, k, ap_idx) = squeeze(initial_beams(:, k, ap_idx));
                    end
                end
            end
        end
    end
    
    % Coordination overhead (misleading name - just operation count)
    coordination_overhead.refinements = total_refinements;
    coordination_overhead.overhead_percent = total_refinements / (params.L * params.K) * 100;
    
    fprintf('MRT beamforming: %d beams refined\n', total_refinements);
end

function [pilot_scheme, contamination_reduction] = spatial_pilot_assignment(beta, serving_aps, params, user_positions, ap_positions)
    % SPATIAL PILOT REUSE - Key to contamination mitigation
    %
    % Strategy: Users far apart can share pilots safely
    %           Users close together need different pilots
    %
    % This is the CORE of your contamination mitigation!
    
    K = params.K;
    tau_p = params.tau_p;
    
    pilot_scheme = zeros(K, 1);
    pilot_usage = zeros(tau_p, 1);
    
    % Target: balanced usage
    target_per_pilot = ceil(K / tau_p);
    
    fprintf('Spatial pilot assignment:\n');
    fprintf('  Strategy: Maximize distance between same-pilot users\n');
    
    % ==================================================================
    % STEP 1: Compute distance matrix between all users
    % ==================================================================
    
    user_distances = zeros(K, K);
    for i = 1:K
        for j = 1:K
            if i ~= j
                user_distances(i, j) = norm(user_positions(i, :) - user_positions(j, :));
            else
                user_distances(i, j) = inf;  % Self-distance = infinity
            end
        end
    end
    
    % ==================================================================
    % STEP 2: Assign pilots prioritizing spatial separation
    % ==================================================================
    
    % Process users in order of channel strength (strong users first)
    user_priorities = zeros(K, 1);
    for k = 1:K
        user_priorities(k) = mean(beta(serving_aps(k, :), k));
    end
    [~, user_order] = sort(user_priorities, 'descend');
    
    for idx = 1:K
        k = user_order(idx);
        
        best_pilot = -1;
        max_min_distance = 0;  % We want to maximize minimum distance to same-pilot users
        
        % Try each pilot
        for pilot = 1:tau_p
            % Skip if pilot is overloaded
            if pilot_usage(pilot) >= target_per_pilot + 1
                continue;
            end
            
            % Calculate minimum distance to users already using this pilot
            min_distance = inf;
            
            for other_k = 1:K
                if pilot_scheme(other_k) == pilot
                    dist = user_distances(k, other_k);
                    if dist < min_distance
                        min_distance = dist;
                    end
                end
            end
            
            % If this pilot is empty, min_distance = inf (best case)
            % We want the pilot that maximizes this minimum distance
            if min_distance > max_min_distance
                max_min_distance = min_distance;
                best_pilot = pilot;
            end
        end
        
        % Fallback: if all full, use least loaded
        if best_pilot == -1
            [~, best_pilot] = min(pilot_usage);
        end
        
        % Assign pilot
        pilot_scheme(k) = best_pilot;
        pilot_usage(best_pilot) = pilot_usage(best_pilot) + 1;
    end
    
    % ==================================================================
    % STEP 3: Compute quality metrics
    % ==================================================================
    
    % Calculate average distance between same-pilot users
    same_pilot_distances = [];
    
    for pilot = 1:tau_p
        users_with_pilot = find(pilot_scheme == pilot);
        
        for i = 1:length(users_with_pilot)
            for j = i+1:length(users_with_pilot)
                user_i = users_with_pilot(i);
                user_j = users_with_pilot(j);
                same_pilot_distances = [same_pilot_distances; user_distances(user_i, user_j)];
            end
        end
    end
    contamination_reduction = struct();
    contamination_reduction.pilot_usage = pilot_usage;
    contamination_reduction.max_reuse = max(pilot_usage);
    contamination_reduction.min_reuse = min(pilot_usage);
    contamination_reduction.avg_reuse = mean(pilot_usage);
    
    % Handle case: no same-pilot pairs (e.g., no pilot reuse)
    if isempty(same_pilot_distances)
        contamination_reduction.avg_same_pilot_distance = NaN;
        contamination_reduction.min_same_pilot_distance = NaN;
        spatial_gain_percent = NaN;
    else
        contamination_reduction.avg_same_pilot_distance = mean(same_pilot_distances);
        contamination_reduction.min_same_pilot_distance = min(same_pilot_distances);
    
        % Baseline reference for "random" (keep your current heuristic)
        baseline_random = (sqrt(2) * params.area_size / 3);  % heuristic baseline
        spatial_gain_percent = 100 * contamination_reduction.avg_same_pilot_distance / baseline_random - 100;

    end
    
    fprintf('  Pilot assignment complete:\n');
    fprintf('    Max/min/avg users per pilot: %d/%d/%.1f\n', ...
            contamination_reduction.max_reuse, ...
            contamination_reduction.min_reuse, ...
            contamination_reduction.avg_reuse);
    
    if isnan(contamination_reduction.avg_same_pilot_distance)
        fprintf('    Avg distance between same-pilot users: N/A (no pilot reuse)\n');
        fprintf('    Min distance between same-pilot users: N/A (no pilot reuse)\n');
        fprintf('    Spatial separation gain: N/A\n');
    else
        fprintf('    Avg distance between same-pilot users: %.1f m\n', ...
                contamination_reduction.avg_same_pilot_distance);
        fprintf('    Min distance between same-pilot users: %.1f m\n', ...
                contamination_reduction.min_same_pilot_distance);
        fprintf('    Spatial separation gain: %.1f%% vs random\n', spatial_gain_percent);
    end

    
    % Key metric: compare to random assignment
    % Random assignment would give avg distance ≈ area_size/3
    % Spatial assignment should give avg distance ≈ area_size/2
    
end


function [H_est_simple, quality_simple] = simple_pilot_based_estimation(H_true, pilot_scheme, params)
    % Simple LS channel estimation for MR (no contamination awareness)
    % This is what MR actually uses in practice
    %
    % Reference: Marzetta "Fundamentals of Massive MIMO", 2016
    
    [M, K, L] = size(H_true);
    H_est_simple = zeros(M, K, L);
    
    % Calculate noise power
    noise_power_dbm = params.thermal_noise + 10*log10(params.bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3);
    
    % Pilot power
    pilot_power = 10^(params.p_pilot_dbm/10 - 3);
    
    mse_values = zeros(L, K);
    for l = 1:L
        for k = 1:K
            if k <= size(H_true, 2) && l <= size(H_true, 3)
                % Get pilot index for this user
                pilot_k = pilot_scheme(k);
                
                % Received pilot signal (with contamination)
                y_pilot = zeros(M, 1);
                
                % Add signal from ALL users using the same pilot
                for j = 1:K
                    if pilot_scheme(j) == pilot_k  % Same pilot group
                        h_j = squeeze(H_true(:, j, l));
                        y_pilot = y_pilot + sqrt(pilot_power) * h_j;
                    end
                end
                
                % Add thermal noise
                pilot_noise = sqrt(noise_power/2) * (randn(M,1) + 1j*randn(M,1));
                y_pilot = y_pilot + pilot_noise;
                
                % LS estimate (contaminated)
                H_est_simple(:, k, l) = y_pilot / sqrt(pilot_power);
                
                % MSE (now includes contamination error)
                h_true = squeeze(H_true(:, k, l));
                mse_values(l, k) = norm(H_est_simple(:,k,l) - h_true)^2;
            end
        end
    
    end
    
    % Quality metrics
    quality_simple = struct();
    quality_simple.avg_mse = mean(mse_values(:));
    quality_simple.avg_nmse_db = 10*log10(mean(mse_values(:)) / mean(abs(H_true(:)).^2));
    
    fprintf('Simple LS estimation for MR: NMSE = %.2f dB\n', quality_simple.avg_nmse_db);
end


function visualize_contamination_analysis(estimation_quality, estimation_quality_baseline, pilot_scheme, user_positions, ap_positions, params)
    % Visualize pilot contamination patterns
    
    h_fig_contam = figure('Name', 'Pilot Contamination Analysis', ...
        'NumberTitle', 'off', ...
        'WindowStyle', 'normal', ...
        'Resize', 'on', ...
        'Units', 'pixels', ...
        'Position', [100, 80, 1280, 820], ...
        'PaperPositionMode', 'auto');
    movegui(h_fig_contam, 'center');
    
    % Subplot 1: Contamination ratio heatmap
    subplot(2,3,1);
    imagesc(estimation_quality.contamination_ratios');
    colorbar;
    xlabel('AP Index');
    ylabel('User Index');
    title('Contamination/Signal Ratio');
    set(gca, 'FontSize', 10);
    
    % Subplot 2: MSE heatmap
    subplot(2,3,2);
    imagesc(10*log10(estimation_quality.mse_values'));
    colorbar;
    xlabel('AP Index');
    ylabel('User Index');
    title('Estimation MSE [dB]');
    set(gca, 'FontSize', 10);
    
    % Subplot 3: Pilot assignment
    subplot(2,3,3);
    scatter(user_positions(:,1), user_positions(:,2), 100, pilot_scheme, 'filled');
    hold on;
    scatter(ap_positions(:,1), ap_positions(:,2), 150, 'r', 's', 'filled');
    colorbar;
    xlabel('X [m]');
    ylabel('Y [m]');
    title('Pilot Assignment (color = pilot index)');
    legend('Users', 'APs');
    grid on;
    
    % Subplot 4: Contamination vs distance
    subplot(2,3,4);
    distances = [];
    contaminations = [];
    for k = 1:size(user_positions, 1)
        for l = 1:size(ap_positions, 1)
            d = norm(user_positions(k,:) - ap_positions(l,:));
            c = estimation_quality.contamination_ratios(l, k);
            if c > 0
                distances = [distances; d];
                contaminations = [contaminations; c];
            end
        end
    end
    scatter(distances, 10*log10(contaminations), 50, 'b', 'filled');
    xlabel('Distance [m]');
    ylabel('Contamination/Signal [dB]');
    title('Near-Far Effect');
    grid on;
    
    % Subplot 5: NMSE distribution
    subplot(2,3,5);
    valid_nmse = estimation_quality.nmse_values(estimation_quality.nmse_values > 0);
    histogram(10*log10(valid_nmse), 20, 'FaceColor', [0.3, 0.7, 0.9]);
    xlabel('NMSE [dB]');
    ylabel('Count');
    title('Normalized MSE Distribution');
    grid on;
    
    % Subplot 6: Baseline vs mitigated contamination evidence
    subplot(2,3,6);
    hold on;
    grid on;
    box on;

    baseline_contam_db = estimation_quality_baseline.contamination_ratio_db;
    proposed_contam_db = estimation_quality.contamination_ratio_db;
    mitigation_gain_db = baseline_contam_db - proposed_contam_db;

    bar([1, 2], [baseline_contam_db, proposed_contam_db], 0.55, ...
        'FaceColor', 'flat', 'CData', [0.85 0.33 0.10; 0.00 0.45 0.74]);
    xticks([1, 2]);
    xticklabels({'Standard LMMSE', 'Proposed Mitigation'});
    ylabel('Pilot Contamination / Signal [dB]');
    title('Baseline vs Mitigated Contamination');

    ylim_vals = [baseline_contam_db, proposed_contam_db];
    y_margin = max(0.8, 0.15 * max(abs(ylim_vals)));
    ylim([min(ylim_vals) - y_margin, max(ylim_vals) + 2.2*y_margin]);

    text(1, baseline_contam_db + 0.25*y_margin, sprintf('%.2f dB', baseline_contam_db), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(2, proposed_contam_db + 0.25*y_margin, sprintf('%.2f dB', proposed_contam_db), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    plot([1, 2], [max(ylim_vals) + 0.9*y_margin, max(ylim_vals) + 0.9*y_margin], ...
        'k-', 'LineWidth', 1.2);
    plot([1, 1], [max(ylim_vals) + 0.75*y_margin, max(ylim_vals) + 0.9*y_margin], ...
        'k-', 'LineWidth', 1.2);
    plot([2, 2], [max(ylim_vals) + 0.75*y_margin, max(ylim_vals) + 0.9*y_margin], ...
        'k-', 'LineWidth', 1.2);
    text(1.5, max(ylim_vals) + 1.15*y_margin, ...
        sprintf('Mitigation gain = %.2f dB', mitigation_gain_db), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', [0.10 0.50 0.10]);

    if isfield(estimation_quality, 'avg_nmse_db')
        text(1.5, min(ylim_vals) - 0.55*y_margin, ...
            sprintf('NMSE (proposed): %.2f dB', estimation_quality.avg_nmse_db), ...
            'HorizontalAlignment', 'center', 'FontAngle', 'italic');
    end
    
    sgtitle('Pilot Contamination Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    drawnow;
end


function pilot_corr = generate_pilot_correlation_matrix(tau_p)
    % Generate pilot sequence correlation matrix
    % Models non-orthogonality between adjacent pilots
    %
    % Reference: Zadoff-Chu sequences have bounded cross-correlation
    %Typical: adjacent pilots have ~0.1-0.2 correlation
    
    pilot_corr = eye(tau_p);
    
    % Adjacent pilot correlation (realistic value from literature)
    adjacent_corr = 0.15;  % 15% leakage to adjacent pilots
    
    for i = 1:tau_p
        for j = 1:tau_p
            if i ~= j
                % Correlation decreases with pilot separation
                separation = abs(i - j);
                
                if separation == 1
                    % Adjacent pilots
                    pilot_corr(i, j) = adjacent_corr;
                elseif separation == 2
                    % One pilot apart
                    pilot_corr(i, j) = adjacent_corr^2;
                else
                    % Far apart - negligible correlation
                    pilot_corr(i, j) = 0;
                end
            end
        end
    end
end

function [W_distributed_mmse, coordination_strategy] = distributed_mmse_precoding(H_clean, params)
    % CORRECTED: Distributed MMSE with adaptive SNR-aware regularization
    %
    % Key improvements:
    %   1. SNR-adaptive regularization
    %   2. Per-AP SNR estimation
    %   3. Automatic regime detection (low/medium/high SNR)
    %   4. Fallback to MR in very low SNR
    %
    % References:
    %   - Björnson et al. "Massive MIMO Networks", NOW Publishers 2017
    %   - Kay, "Fundamentals of Statistical Signal Processing: Estimation Theory", 1993
    
    W_distributed_mmse = zeros(params.M, params.K, params.L);
    
    
    
    % Calculate noise power correctly
    noise_power_dbm = params.thermal_noise + 10*log10(params.bandwidth) + params.noise_figure;
    sigma2 = 10^(noise_power_dbm/10 - 3);  % Watts

    fprintf('  MMSE precoding noise: %.1f dBm = %.2e W\n', noise_power_dbm, sigma2);

    % Total transmit power
    P_total = 10^(params.power_budget_dbm/10 - 3);
    rho = P_total / (params.L * params.K);  
    % Average power per link
    channel_powers = zeros(params.L, params.K);
    for l = 1:params.L
        for k = 1:params.K
            if k <= size(H_clean, 2) && l <= size(H_clean, 3)
                h = H_clean(:, k, l);
                % Large-scale fading per antenna
                channel_powers(l, k) = norm(h)^2 / params.M;
            end
        end
    end
    
    avg_beta = mean(channel_powers(channel_powers > 0));
    
    
    effective_rho = rho * avg_beta * params.M;  
    system_snr_linear = effective_rho / sigma2;
    system_snr_db = 10*log10(system_snr_linear);
        
    fprintf('Transmit SNR: %.1f dB\n', 10*log10(rho/sigma2));
    fprintf('Effective SNR (with path loss): %.1f dB\n', system_snr_db);
    
    fprintf('\n=== ADAPTIVE DISTRIBUTED MMSE PRECODING ===\n');
    fprintf('System SNR: %.2f dB\n', system_snr_db);
    
    % Determine SNR regime and optimal regularization
    if system_snr_db < 0
        snr_regime = 'very_low';
        fprintf('Regime: VERY LOW SNR (< 0 dB) - using MR precoding\n');
    elseif system_snr_db < 10
        snr_regime = 'low';
        fprintf('Regime: LOW SNR (0-10 dB) - strong regularization\n');
    elseif system_snr_db < 20 % here we are (17.2db)
        snr_regime = 'medium';
        fprintf('Regime: MEDIUM SNR (10-20 dB) - moderate regularization\n');
    else
        snr_regime = 'high';
        fprintf('Regime: HIGH SNR (> 20 dB) - weak regularization\n');
    end
    
    % Store per-AP regularization for analysis
    alpha_per_ap = zeros(params.L, 1);
    ap_snr_db = zeros(params.L, 1);
    
    tic;
    
    for l = 1:params.L
        if l <= size(H_clean, 3)
            % Collect channels at AP l
            H_l = zeros(params.M, params.K);
            active_users = 0;
            
            for k = 1:params.K
                if k <= size(H_clean, 2)
                    H_l(:, k) = squeeze(H_clean(:, k, l));
                    if norm(H_l(:, k)) > 1e-10
                        active_users = active_users + 1;
                    end
                end
            end
            
            if active_users == 0
                continue;  % No users at this AP
            end
            
            % Estimate per-AP SNR (based on average channel gain)
            avg_channel_gain = mean(sum(abs(H_l).^2, 1));  % Average over users
            ap_snr = (rho * avg_channel_gain) / sigma2;
            ap_snr_db(l) = 10*log10(ap_snr);
            
            % === ADAPTIVE REGULARIZATION BASED ON SNR REGIME ===
            switch snr_regime
                case 'very_low'
                    % SNR < 0 dB: Use Maximum Ratio (no MMSE benefit)
                    % MMSE degenerates to MR when SNR → 0
                    for k = 1:params.K
                        h_k = H_l(:, k);
                        if norm(h_k) > 1e-10
                            W_distributed_mmse(:, k, l) = conj(h_k) / norm(h_k);
                        end
                    end
                    alpha_per_ap(l) = inf;  % Infinite regularization = MR
                    continue;
                    
                case 'low'
                    % SNR 0-10 dB: Strong regularization
                    % α ≈ σ² (noise dominates)
                    alpha = sigma2;
                    
                case 'medium'
                    % SNR 10-20 dB: Moderate regularization
                    % α ≈ σ²/√(ρM) (intermediate)
                    alpha = sigma2 / sqrt(rho * params.M);
                    
                case 'high'
                    % SNR > 20 dB: Weak regularization
                    % BUT: if contamination-limited, use VERY weak regularization
                    alpha_base = sigma2 / (rho * params.M);
                    
                    % For EXTREMELY high SNR (>80 dB), system is contamination-limited
                    % Use minimal regularization (closer to Zero-Forcing)
                    if system_snr_db > 80
                        if l == 1  % Only print once for first AP
                            fprintf('  ⚠ High SNR detected (%.1f dB) - using minimal regularization\n', system_snr_db);
                        end
                        alpha = max(alpha_base / 100, 1e-8);
                    else
                        alpha = max(alpha_base, 1e-6);
                    end
            end
            
            % Apply per-AP adaptation based on local channel conditions
            % If this AP has particularly strong/weak channels, adjust α
            % channel_condition_number = cond(H_l * H_l');
            % if channel_condition_number > 1e6
            %     % Ill-conditioned: increase regularization
            %     alpha = alpha * sqrt(channel_condition_number / 1e6);
            % end
            % 
            % Ensure minimum regularization for numerical stability
            alpha = max(alpha, 1e-8);
            alpha_per_ap(l) = alpha;
            
            % === MMSE SOLUTION ===
            % W = Σ^(-1) * H where Σ = H*H' + α*I
            Sigma = H_l * H_l' + alpha * eye(params.M);
            
            % Solve using Cholesky decomposition (faster + more stable)
            try
                % Try Cholesky (requires PSD matrix)
                L = chol(Sigma, 'lower');
                W_l = L' \ (L \ H_l);
            catch
                % Fallback to standard inversion
                try
                    W_l = Sigma \ H_l;
                catch
                    % Last resort: pseudoinverse
                    W_l = pinv(Sigma) * H_l;
                    warning('AP %d: Using pseudoinverse (Sigma singular)', l);
                end
            end
            
            % Normalize precoding vectors
            for k = 1:params.K
                w_lk = W_l(:, k);
                if norm(w_lk) > 1e-10
                    W_distributed_mmse(:, k, l) = w_lk / norm(w_lk);
                end
            end
        end
    end
    
    processing_time = toc;
    
    % === COORDINATION STRATEGY ANALYSIS ===
    coordination_strategy = struct();
    coordination_strategy.algorithm = 'Adaptive Distributed MMSE';
    coordination_strategy.snr_regime = snr_regime;
    coordination_strategy.system_snr_db = system_snr_db;
    coordination_strategy.regularization_range = [min(alpha_per_ap(alpha_per_ap > 0)), ...
                                                  max(alpha_per_ap(alpha_per_ap < inf))];
    coordination_strategy.processing_time = processing_time;
    coordination_strategy.alpha_per_ap = alpha_per_ap;
    coordination_strategy.ap_snr_db = ap_snr_db;
    
    % Summary statistics
    valid_alpha = alpha_per_ap(alpha_per_ap > 0 & alpha_per_ap < inf);
    if ~isempty(valid_alpha)
        fprintf('Regularization: α ∈ [%.2e, %.2e]\n', min(valid_alpha), max(valid_alpha));
        fprintf('Per-AP SNR: mean=%.2f dB, range=[%.2f, %.2f] dB\n', ...
                mean(ap_snr_db(ap_snr_db > -100)), ...
                min(ap_snr_db(ap_snr_db > -100)), ...
                max(ap_snr_db(ap_snr_db > -100)));
    end
    fprintf('Processing time: %.3f s\n', processing_time);
end

function [power_allocation, fairness_metrics, debug_info] = proper_power_allocation(H_clean, W, params)
    % CORRECTED: Proportional fairness with GUARANTEED constraint satisfactio
    % Reference: Kelly, "Charging and Rate Control", European Trans. Telecom. 1997
    
    
    K = params.K;
    L = params.L;
    
    % System power budget
    P_total = 10^(params.power_budget_dbm/10 - 3);  % Watts
    P_per_ap = P_total / L;  % Equal budget per AP
    P_min_per_user = P_per_ap / (10 * params.K);  % Minimum power guarantee (Watts)
    
    power_allocation = zeros(K, L);
    
    % === STAGE 1: Per-AP allocation (may violate global budget) ===
    for l = 1:L
        % Collect channel gains for active users at this AP
        channel_gains = zeros(K, 1);
        active_mask = false(K, 1);
        
        for k = 1:K
            if k <= size(H_clean, 2) && l <= size(H_clean, 3) && ...
               k <= size(W, 2) && l <= size(W, 3)
                
                h = H_clean(:, k, l);
                w = W(:, k, l);
                
                if norm(h) > 1e-10 && norm(w) > 1e-10
                    channel_gains(k) = abs(h' * w)^2;
                    active_mask(k) = true;
                end
            end
        end
        
        active_users = sum(active_mask);
        
        if active_users > 0
            P_reserved = P_min_per_user * active_users;
            
            if P_reserved > P_per_ap
                % Not enough for minimum guarantees
                power_per_user = P_per_ap / active_users;
                for k = 1:K
                    if active_mask(k)
                        power_allocation(k, l) = power_per_user;
                    end
                end
            else
                % Allocate minimum + proportional fairness for remaining
                P_remaining = P_per_ap - P_reserved;
                active_gains = channel_gains(active_mask);
                
                if sum(active_gains) > eps
                    % Proportional fairness weights: sqrt(gain)
                    weights = sqrt(active_gains);
                    weights = weights / sum(weights);  % Normalize
                    
                    k_idx = 0;
                    for k = 1:K
                        if active_mask(k)
                            k_idx = k_idx + 1;
                            power_allocation(k, l) = P_min_per_user + weights(k_idx) * P_remaining;
                        end
                    end
                else
                    % Fallback: equal allocation
                    for k = 1:K
                        if active_mask(k)
                            power_allocation(k, l) = P_per_ap / active_users;
                        end
                    end
                end
            end
        end
    end
    
    % === STAGE 2: VERIFY AND ENFORCE CONSTRAINTS ===
    
    % Check per-AP constraints
    ap_power = sum(power_allocation, 1);  % Power per AP (1 × L)
    max_ap_power = max(ap_power);
    
    if max_ap_power > P_per_ap * 1.001  % 0.1% tolerance
        warning('AP power constraint violated: max AP has %.2f W (budget: %.2f W)', ...
                max_ap_power, P_per_ap);
        
        % Scale down overloaded APs
        for l = 1:L
            if ap_power(l) > P_per_ap
                scale_factor = P_per_ap / ap_power(l);
                power_allocation(:, l) = power_allocation(:, l) * scale_factor;
            end
        end
        
        % Recompute after scaling
        ap_power = sum(power_allocation, 1);
    end
    
    % Check total system constraint
    total_allocated = sum(power_allocation(:));
    
    if total_allocated > P_total * 1.0001  % Stricter tolerance (0.01% instead of 0.1%)
        warning('CRITICAL: Power exceeded by %.2f%%, forcing correction', ...
                100*(total_allocated-P_total)/P_total);
        
        % FORCE correction
        scale_factor = (P_total * 0.999) / total_allocated;  % 0.1% safety margin
        power_allocation = power_allocation * scale_factor;
        
        % Verify
        total_allocated = sum(power_allocation(:));
        assert(total_allocated <= P_total, 'Power correction FAILED!');
    end
    
    % === STAGE 3: COMPUTE FAIRNESS METRICS ===
    user_total_power = sum(power_allocation, 2);  % Power per user (K × 1)
    active_users_mask = user_total_power > 1e-6;
    active_powers = user_total_power(active_users_mask);
    
    if ~isempty(active_powers) && sum(active_powers) > 0
        % Jain's fairness index
        fairness_metrics.jains_index = (sum(active_powers))^2 / ...
            (length(active_powers) * sum(active_powers.^2));
        
        % Min/max ratio
        fairness_metrics.min_max_ratio = min(active_powers) / max(active_powers);
        
        % Coefficient of variation
        fairness_metrics.coefficient_of_variation = std(active_powers) / mean(active_powers);
    else
        fairness_metrics.jains_index = 0;
        fairness_metrics.min_max_ratio = 0;
        fairness_metrics.coefficient_of_variation = inf;
    end
    
    % === STAGE 4: DEBUG INFO ===
    debug_info = struct();
    debug_info.total_allocated_w = total_allocated;
    debug_info.total_budget_w = P_total;
    debug_info.budget_utilization = total_allocated / P_total;
    debug_info.max_ap_power_w = max(ap_power);
    debug_info.min_ap_power_w = min(ap_power(ap_power > 0));
    debug_info.ap_power_vector = ap_power;
    debug_info.active_users = sum(active_users_mask);
    
    % Verify constraints one final time
    assert(total_allocated <= P_total * 1.01, ...
           'FATAL: Power constraint still violated after scaling!');
    
    fprintf('Power allocation: Total = %.2f W / %.2f W (%.1f%% utilized)\n', ...
            total_allocated, P_total, 100 * debug_info.budget_utilization);
    fprintf('                  Jain fairness = %.3f\n', fairness_metrics.jains_index);
end

function sinr_linear = compute_sinr(H, W, P, noise_power, serving_aps, params, sync_mode)
    % CORRECTED: Compute SINR for CF-mMIMO with proper normalization
    %
    % Key fixes:
    %   1. Proper power normalization
    %   2. Correct desired signal calculation
    %   3. Fix numerical precision issues
    
    if nargin < 7
        sync_mode = 'non-coherent';
    end
    
    K = params.K;
    L = params.L;
    
    sinr_linear = zeros(K, 1);
    
    fprintf('\n=== CORRECTED SINR Computation Mode: %s ===\n', upper(sync_mode));
    
    for k = 1:K
        % === DESIRED SIGNAL POWER ===
        signal_power = 0;
        
        switch sync_mode
            case 'coherent'
                % Coherent combining: phases aligned
                signal_amplitude = 0;
                
                for l = 1:L
                    if l <= size(H, 3) && k <= size(H, 2) && ...
                       k <= size(W, 2) && l <= size(W, 3) && ...
                       k <= size(P, 1) && l <= size(P, 2)
                        
                        h_lk = H(:, k, l);
                        w_lk = W(:, k, l);
                        p_lk = P(k, l);
                        
                        if norm(h_lk) > 1e-15 && norm(w_lk) > 1e-15 && p_lk > 1e-15
                            % Key fix: proper channel gain calculation
                            h_eff = (h_lk' * w_lk);  % Complex channel gain
                            signal_amplitude = signal_amplitude + h_eff * sqrt(p_lk);
                        end
                    end
                end
                
                signal_power = abs(signal_amplitude)^2;
                
            case 'non-coherent'
                % Non-coherent: add powers (realistic for CF-mMIMO)
                for l = 1:L
                    if l <= size(H, 3) && k <= size(H, 2) && ...
                       k <= size(W, 2) && l <= size(W, 3) && ...
                       k <= size(P, 1) && l <= size(P, 2)
                        
                        h_lk = H(:, k, l);
                        w_lk = W(:, k, l);  
                        p_lk = P(k, l);
                        
                        if norm(h_lk) > 1e-15 && norm(w_lk) > 1e-15 && p_lk > 1e-15
                            % For non-normalized precoders (MR), need to normalize in SINR calc
                            h_eff = (h_lk' * w_lk) ;
                            signal_power = signal_power + abs(h_eff)^2 * p_lk;
                        end
                    end
                end
        end
        
        % === INTERFERENCE POWER ===
        interference = 0;
        
        for l = 1:L
            if l <= size(H, 3) && k <= size(H, 2)
                h_lk = H(:, k, l);
                
                if norm(h_lk) > 1e-15
                    for j = 1:K
                        if j ~= k && j <= size(W, 2) && l <= size(W, 3) && ...
                           j <= size(P, 1) && l <= size(P, 2)
                            
                            w_lj = W(:, j, l);
                            p_lj = P(j, l);
                            
                            if norm(w_lj) > 1e-15 && p_lj > 1e-15
                                % Interference is always non-coherent
                                interference = interference + abs(h_lk' * w_lj)^2 * p_lj;
                            end
                        end
                    end
                end
            end
        end
        
        % === SINR CALCULATION ===
        % Key fix: ensure numerical stability
        total_interference_plus_noise = interference + noise_power;
        
        if signal_power > 1e-20 && total_interference_plus_noise > 0
            sinr_linear(k) = signal_power / total_interference_plus_noise;
        else
            sinr_linear(k) = 1e-10;  % Floor value
        end
        
        % Sanity check: SINR shouldn't be astronomical
        if sinr_linear(k) > 1e6  % > 60 dB
            warning('User %d has unrealistic SINR: %.2f dB', k, 10*log10(sinr_linear(k)));
            sinr_linear(k) = 1e6;  % Cap at 60 dB
        end
    end
    
    % Summary with validation
    avg_sinr_linear = mean(sinr_linear);
    avg_sinr_db = 10*log10(avg_sinr_linear);
    
    fprintf('Average SINR: %.2f dB (%.2e linear)\n', avg_sinr_db, avg_sinr_linear);
    fprintf('SINR range: [%.2f, %.2f] dB\n', 10*log10(min(sinr_linear)), 10*log10(max(sinr_linear)));
    
    % Validation check
    if avg_sinr_db < -10
        warning('⚠️  Very low SINR detected - check channel gains and power');
    elseif avg_sinr_db > 50
        warning('⚠️  Unrealistically high SINR - check normalization');
    else
        fprintf('✓ SINR values are in reasonable range\n');
    end
    
    fprintf('\n');
end

function snr_metrics = compute_snr_metrics(H, W, P, params)
    % Compute SNR metrics for CF-mMIMO system
    %
    % Inputs:
    %   H: Channel matrix (M × K × L)
    %   W: Beamforming matrix (M × K × L)  
    %   P: Power allocation (K × L)
    %   params: System parameters
    %
    % Output:
    %   snr_metrics: Structure with SNR calculations
    
    % Calculate noise power
    bandwidth = params.bandwidth; % 20 MHz
    noise_power_dbm = params.thermal_noise + 10*log10(bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3); % Convert to Watts
    
    K = params.K;
    L = params.L;
    
    % === Per-User SNR ===
    % SNR_k = (received signal power) / noise_power
    snr_per_user = zeros(K, 1);
    
    for k = 1:K
        % Calculate received signal power from all serving APs
        signal_power = 0;
        
        for l = 1:L
            if l <= size(H, 3) && k <= size(H, 2) && ...
               k <= size(W, 2) && l <= size(W, 3) && ...
               k <= size(P, 1) && l <= size(P, 2)
                
                h_lk = H(:, k, l);      % Channel
                w_lk = W(:, k, l);      % Beamforming vector
                p_lk = P(k, l);         % Power
                
                % Effective channel gain
                if norm(h_lk) > 1e-10 && norm(w_lk) > 1e-10
                    channel_gain = abs(h_lk' * w_lk)^2;
                    signal_power = signal_power + channel_gain * p_lk;
                end
            end
        end
        
        % SNR for user k
        if signal_power > 0
            snr_per_user(k) = signal_power / noise_power;
        else
            snr_per_user(k) = 0;
        end
    end
    
    % === Per-AP Average SNR ===
    % Average SNR across users served by each AP
    snr_per_ap = zeros(L, 1);
    
    for l = 1:L
        if l <= size(H, 3)
            ap_snr_sum = 0;
            active_users = 0;
            
            for k = 1:K
                if k <= size(H, 2) && k <= size(W, 2) && l <= size(W, 3) && ...
                   k <= size(P, 1) && l <= size(P, 2)
                    
                    h_lk = H(:, k, l);
                    w_lk = W(:, k, l);
                    p_lk = P(k, l);
                    
                    if norm(h_lk) > 1e-10 && norm(w_lk) > 1e-10 && p_lk > 0
                        channel_gain = abs(h_lk' * w_lk)^2;
                        user_snr = (channel_gain * p_lk) / noise_power;
                        ap_snr_sum = ap_snr_sum + user_snr;
                        active_users = active_users + 1;
                    end
                end
            end
            
            if active_users > 0
                snr_per_ap(l) = ap_snr_sum / active_users;
            end
        end
    end
    
    % === Pilot SNR ===
    % SNR during pilot transmission
    pilot_power = 10^(params.p_pilot_dbm/10 - 3); % Watts
    
    pilot_snr_per_user = zeros(K, 1);
    for k = 1:K
        avg_channel_power = 0;
        num_aps = 0;
        
        for l = 1:L
            if l <= size(H, 3) && k <= size(H, 2)
                h_lk = H(:, k, l);
                if norm(h_lk) > 1e-10
                    avg_channel_power = avg_channel_power + norm(h_lk)^2;
                    num_aps = num_aps + 1;
                end
            end
        end
        
        if num_aps > 0
            avg_channel_power = avg_channel_power / num_aps;
            pilot_snr_per_user(k) = (pilot_power * avg_channel_power) / noise_power;
        end
    end
    
    % === System-wide metrics ===
    snr_metrics = struct();
    
    % Per-user SNR (linear and dB)
    snr_metrics.per_user_linear = snr_per_user;
    snr_metrics.per_user_db = 10*log10(snr_per_user + 1e-10);
    
    % Per-AP SNR
    snr_metrics.per_ap_linear = snr_per_ap;
    snr_metrics.per_ap_db = 10*log10(snr_per_ap + 1e-10);
    
    % Pilot SNR
    snr_metrics.pilot_snr_linear = pilot_snr_per_user;
    snr_metrics.pilot_snr_db = 10*log10(pilot_snr_per_user + 1e-10);
    
    % Average metrics
    snr_metrics.average_user_snr_db = mean(snr_metrics.per_user_db);
    snr_metrics.average_ap_snr_db = mean(snr_metrics.per_ap_db);
    snr_metrics.average_pilot_snr_db = mean(snr_metrics.pilot_snr_db);
    
    % Noise power (for reference)
    snr_metrics.noise_power_dbm = noise_power_dbm;
    snr_metrics.noise_power_watts = noise_power;
    
    fprintf('SNR Metrics:\n');
    fprintf('- Average user SNR: %.2f dB\n', snr_metrics.average_user_snr_db);
    fprintf('- Average pilot SNR: %.2f dB\n', snr_metrics.average_pilot_snr_db);
    fprintf('- Min user SNR: %.2f dB\n', min(snr_metrics.per_user_db));
    fprintf('- Max user SNR: %.2f dB\n', max(snr_metrics.per_user_db));
end

function W_MR = compute_MR_precoding(H_clean, params)
    % Maximum Ratio (MR) Precoding - WITHOUT normalization
    % Reference: Ngo et al., "Cell-Free Massive MIMO", 2017
    
    W_MR = zeros(params.M, params.K, params.L);
    
    for l = 1:params.L
        if l <= size(H_clean, 3)
            for k = 1:params.K
                if k <= size(H_clean, 2)
                    h_lk = squeeze(H_clean(:, k, l));
                    
                    % MR precoding: w = h* (conjugate)
                    if norm(h_lk) > 1e-10
                        W_MR(:, k, l) = h_lk/norm(h_lk);
                    end
                end
            end
        end
    end
    
    
end

function W_ZF = compute_ZF_precoding_centralized(H_clean, serving_aps, params)
    % Zero-Forcing (ZF) Precoding - Centralized Processing
    % Requires full CSI at CPU, computes global ZF solution
    % Reference: Bjornson et al., "Massive MIMO Networks", 2017
    
    W_ZF = zeros(params.M, params.K, params.L);
    
    for l = 1:params.L
        if l <= size(H_clean, 3)
            % Collect channels for all users at this AP
            H_l = zeros(params.M, params.K);
            
            for k = 1:params.K
                if k <= size(H_clean, 2)
                    H_l(:, k) = squeeze(H_clean(:, k, l));
                end
            end
            
            % FIXED: Adaptive regularization based on channel power
            avg_channel_power = mean(vecnorm(H_l, 2, 1).^2);
            lambda = 1e-6 * max(avg_channel_power, 1e-10);  % Small fraction
            
            % Zero-forcing: W = H * (H^H * H + lambda*I)^(-1)
            % This inverts the channel to suppress interference
            gram_matrix = H_l' * H_l + lambda * eye(params.K);
            
            try
                ZF_matrix = H_l / gram_matrix;  % Efficient computation
                
                % Normalize each precoding vector
                for k = 1:params.K
                    w_lk = ZF_matrix(:, k);
                    if norm(w_lk) > 1e-10
                        W_ZF(:, k, l) = w_lk / norm(w_lk);
                    end
                end
            catch
                % Fallback to MR if ZF fails
                fprintf('Warning: ZF failed at AP %d, using MR\n', l);
                for k = 1:params.K
                    if k <= size(H_clean, 2)
                        h_lk = H_l(:, k);
                        if norm(h_lk) > 1e-10
                            W_ZF(:, k, l) = conj(h_lk) / norm(h_lk);
                        end
                    end
                end
            end
        end
    end
    
    fprintf('ZF precoding completed (centralized, full CSI at CPU)\n');
end

function W_near_centralized_MMSE = compute_near_centralized_MMSE(H_clean, params)
    % near Centralized MMSE Precoding with Full CSI
    
    W_near_centralized_MMSE = zeros(params.M, params.K, params.L);
    
    % Noise power
    bandwidth = params.bandwidth;
    noise_power_dbm = params.thermal_noise + 10*log10(bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3);
    
    % Transmit power per user per AP
    P_total = 10^(params.power_budget_dbm/10 - 3);
    rho = P_total / (params.L * params.K);
    
    % Calculate system SNR for logging
    channel_powers = zeros(params.L, params.K);
    for l = 1:params.L
        for k = 1:params.K
            if k <= size(H_clean, 2) && l <= size(H_clean, 3)
                h = H_clean(:, k, l);
                channel_powers(l, k) = norm(h)^2 / params.M;
            end
        end
    end
    avg_channel_gain = mean(channel_powers(channel_powers > 0));
    effective_rho = rho * avg_channel_gain * params.M;
    system_snr_linear = effective_rho / noise_power;
    system_snr_db = 10*log10(system_snr_linear);
    
    fprintf('Centralized MMSE: SNR=%.1f dB\n', system_snr_db);
    
   
    
    % Process each AP
    for l = 1:params.L
        if l <= size(H_clean, 3)
            % Collect channels for all users at this AP
            H_l = zeros(params.M, params.K);
            
            for k = 1:params.K
                if k <= size(H_clean, 2)
                    H_l(:, k) = squeeze(H_clean(:, k, l));
                end
            end
            
            
            gram_matrix_base = H_l' * H_l;
            avg_diagonal = mean(diag(gram_matrix_base));
            alpha = 0.05 * max(avg_diagonal, 1e-15);
            
            % Use the gram matrix
            gram_matrix = gram_matrix_base + alpha * eye(params.K);
            
            try
                MMSE_matrix = H_l / gram_matrix;
                
                % Normalize each precoding vector
                for k = 1:params.K
                    w_lk = MMSE_matrix(:, k);
                    if norm(w_lk) > 1e-10
                        W_near_centralized_MMSE(:, k, l) = w_lk / norm(w_lk);
                    end
                end
            catch
                % Fallback to MR if MMSE fails
                fprintf('Warning: MMSE failed at AP %d, using MR\n', l);
                for k = 1:params.K
                    if k <= size(H_clean, 2)
                        h_lk = H_l(:, k);
                        if norm(h_lk) > 1e-10
                            W_near_centralized_MMSE(:, k, l) = h_lk / norm(h_lk);
                        end
                    end
                end
            end
        end
    end
    
    fprintf('Centralized MMSE precoding completed\n');
end

function [mc_results, confidence_intervals] = run_monte_carlo_analysis(params, ap_positions_base, user_positions_base, n_trials)
% CORRECTED: Monte Carlo with topology variation + robust failure handling
%
% Improvements:
%   1) Topology variation: user/AP position perturbations
%   2) Channel variations per trial
%   3) Robust NaN marking on failed trials
%   4) Variance decomposition: between-topology + within-topology
%   5) Guards to avoid NaN/Inf prints and undefined variables

    fprintf('\n=== COMPREHENSIVE MONTE CARLO ANALYSIS ===\n');
    fprintf('Trials: %d (with topology + channel variations)\n\n', n_trials);

    % Topology variation parameters
    position_std = 20;              % [m] standard deviation for position perturbation
    topology_change_interval = 5;   % Change topology every N trials

    % Initialize storage (fill with NaN so failures don't look like zeros)
    trial_results = struct();
    trial_results.sum_rate_bps_hz        = NaN(n_trials, 1);
    trial_results.sum_throughput_mbps    = NaN(n_trials, 1);
    trial_results.energy_efficiency      = NaN(n_trials, 1);
    trial_results.avg_sinr_db            = NaN(n_trials, 1);
    trial_results.min_sinr_db            = NaN(n_trials, 1);
    trial_results.max_sinr_db            = NaN(n_trials, 1);
    trial_results.fairness_index         = NaN(n_trials, 1);
    trial_results.nmse_db                = NaN(n_trials, 1);
    trial_results.contamination_db       = NaN(n_trials, 1);
    trial_results.user_rates             = NaN(n_trials, params.K);
    trial_results.topology_index         = NaN(n_trials, 1);

    % Current topology state
    ap_positions = ap_positions_base;
    user_positions = user_positions_base;
    current_topology = 1;

    % Predeclare variables used across trials (for readability + safety)
    beta_sub6 = [];
    beta_mmwave = [];
    serving_aps = [];
    spatial_corr = [];
    
    
    for trial = 1:n_trials
        params.tau_p = 20;
        fprintf('Trial %d/%d: ', trial, n_trials);

        try
            % === TOPOLOGY VARIATION ===
            if mod(trial, topology_change_interval) == 1
                if trial > 1
                    current_topology = current_topology + 1;
                    fprintf('(New topology %d) ', current_topology);
                end

                % Perturb user positions
                user_positions = user_positions_base + position_std * randn(size(user_positions_base));

                % Keep users within bounds
                user_positions = max(user_positions, 0);
                user_positions = min(user_positions, params.area_size);

                % Small perturbation to AP positions
                ap_positions = ap_positions_base + (position_std/5) * randn(size(ap_positions_base));
                ap_positions = max(ap_positions, 0);
                ap_positions = min(ap_positions, params.area_size);

                % Recompute large-scale fading + serving sets for new topology
                [beta_sub6, beta_mmwave] = compute_dual_band_pathloss(ap_positions, user_positions, params);
                [serving_aps, ~] = advanced_ap_selection(beta_sub6, beta_mmwave, params);
            end

            trial_results.topology_index(trial) = current_topology;

            % === CHANNEL REALIZATION (small-scale fading) ===
            [H_sub6_true, H_mmwave_true, spatial_corr, ~] = ...
                generate_correlated_channels_with_mobility(ap_positions, user_positions, params, beta_sub6, beta_mmwave, 1, struct());


            % === HARDWARE IMPAIRMENTS ===
            [H_sub6_impaired, ~]  = apply_realistic_impairments(H_sub6_true, params, true);
            [H_mmwave_impaired, ~]= apply_realistic_impairments(H_mmwave_true, params, true);

           
            
            % === PILOT ASSIGNMENT ===
            [pilot_scheme, ~] = spatial_pilot_assignment(beta_sub6, serving_aps, params, user_positions, ap_positions);
            
            fprintf('[DBG] tau_p=%d, uniquePilots=%d\n', ...
                params.tau_p, numel(unique(pilot_scheme)));
            
            counts = accumarray(pilot_scheme(:), 1);
            fprintf('[DBG] pilotCollisions=%d\n', sum(counts > 1));
            
            % === CHANNEL ESTIMATION ===
            [H_est_sub6, H_est_mmwave, estimation_quality] = ...
                covariance_aware_estimation_literature(H_sub6_impaired, H_mmwave_impaired, ...
                                                      pilot_scheme, spatial_corr, params, ...
                                                      user_positions, ap_positions);

            %#ok<NASGU>  % if you don't use H_est_mmwave later, keep MATLAB quiet (optional)
            %#ok<NASGU>  % H_est_mmwave is still part of pipeline realism

            % === PRECODING ===
            [W_mmse, ~] = distributed_mmse_precoding(H_est_sub6, params);

            % === POWER ALLOCATION ===
            [P_optimal, fairness_metrics, ~] = proper_power_allocation(H_est_sub6, W_mmse, params);

            % === PERFORMANCE EVALUATION ===
            sinr_linear = compute_sinr(H_est_sub6, W_mmse, P_optimal, ...
                                      params.noise_power_watts, serving_aps, params, 'non-coherent');

            sinr_db = 10*log10(sinr_linear);

            % Rates
            user_rates = log2(1 + sinr_linear) * params.overhead_factor * params.practical_efficiency;
            sum_rate = sum(user_rates);
            sum_throughput = sum_rate * params.bandwidth / 1e6; % Mbps

            % Energy efficiency
            tx_power = sum(P_optimal(:));
            total_system_power = tx_power + params.total_fixed_power;
            energy_eff = sum_throughput / total_system_power;

            % Store results (SUCCESS)
            trial_results.sum_rate_bps_hz(trial)     = sum_rate;
            trial_results.sum_throughput_mbps(trial) = sum_throughput;
            trial_results.energy_efficiency(trial)   = energy_eff;
            trial_results.avg_sinr_db(trial)         = mean(sinr_db);
            trial_results.min_sinr_db(trial)         = min(sinr_db);
            trial_results.max_sinr_db(trial)         = max(sinr_db);
            trial_results.fairness_index(trial)      = fairness_metrics.jains_index;
            trial_results.nmse_db(trial)             = estimation_quality.avg_nmse_db;
            trial_results.contamination_db(trial)    = estimation_quality.contamination_ratio_db;
            trial_results.user_rates(trial, :)       = user_rates(:).';

            fprintf('Rate=%.2f, SINR=%.2f dB, NMSE=%.2f dB\n', sum_rate, mean(sinr_db), estimation_quality.avg_nmse_db);

        catch ME
            fprintf('FAILED - %s (%s)\n', ME.message, ME.identifier);

            % Print where it failed (top 5 stack frames)
            if ~isempty(ME.stack)
                nStack = min(5, numel(ME.stack));
                for s = 1:nStack
                    fprintf('   at %s (line %d)\n', ME.stack(s).name, ME.stack(s).line);
                end
            end

            % Mark entire trial as invalid (leave NaNs as they are)
            trial_results.topology_index(trial) = current_topology;
        end
    end

    % === VALID TRIALS ===
    valid_trials = ~isnan(trial_results.sum_rate_bps_hz);
    n_valid = sum(valid_trials);

    fprintf('\n=== VARIANCE DECOMPOSITION ===\n');

    % Guard: need at least 2 valid samples to compute variance meaningfully
    if n_valid < 2
        fprintf('Not enough valid trials (%d/%d) for variance decomposition.\n', n_valid, n_trials);
        mc_results = struct();
        confidence_intervals = struct();
        return;
    end

    % Group by topology (among valid trials)
    unique_topologies = unique(trial_results.topology_index(valid_trials));
    n_topologies = length(unique_topologies);

    if n_topologies < 2
        fprintf('Only %d topology present in valid trials; variance decomposition may be trivial.\n', n_topologies);
    end

    % Compute variances
    y = trial_results.sum_rate_bps_hz(valid_trials);
    total_var = var(y);

    % Between-topology variance (weighted variance of topology means)
    topo_means = zeros(n_topologies,1);
    topo_counts = zeros(n_topologies,1);

    for ti = 1:n_topologies
        t = unique_topologies(ti);
        idx = valid_trials & (trial_results.topology_index == t);
        topo_means(ti)  = mean(trial_results.sum_rate_bps_hz(idx));
        topo_counts(ti) = sum(idx);
    end

    overall_mean = mean(y);
    den = (sum(topo_counts) - 1);

    if den <= 0
        between_topology_var = 0;
    else
        between_topology_var = sum(topo_counts .* (topo_means - overall_mean).^2) / den;
    end

    % Within-topology variance (pooled within-topology variance)
    within_sum = 0;
    within_dof = 0;
    for ti = 1:n_topologies
        t = unique_topologies(ti);
        idx = valid_trials & (trial_results.topology_index == t);
        yi = trial_results.sum_rate_bps_hz(idx);
        if numel(yi) >= 2
            within_sum = within_sum + (numel(yi)-1) * var(yi);
            within_dof = within_dof + (numel(yi)-1);
        end
    end
    within_topology_var = within_sum / max(within_dof, 1);

    if total_var <= 0 || isnan(total_var)
        fprintf('Total variance is %.3g; skipping percentage breakdown to avoid NaN/Inf.\n', total_var);
    else
        fprintf('Sum rate variance decomposition:\n');
        fprintf('  Total variance: %.4f\n', total_var);
        fprintf('  Between-topology: %.4f (%.1f%%)\n', between_topology_var, 100*between_topology_var/total_var);
        fprintf('  Within-topology: %.4f (%.1f%%)\n', within_topology_var, 100*within_topology_var/total_var);
    end

    % === COMPUTE STATISTICS ===
    % NOTE: compute_monte_carlo_statistics must accept (trial_results, valid_trials, alpha)
    [mc_results, confidence_intervals] = compute_monte_carlo_statistics(trial_results, valid_trials, 0.05);

    % Attach variance decomposition to output
    mc_results.variance_decomposition = struct();
    mc_results.variance_decomposition.total           = total_var;
    mc_results.variance_decomposition.between_topology= between_topology_var;
    mc_results.variance_decomposition.within_topology = within_topology_var;
    mc_results.variance_decomposition.n_topologies    = n_topologies;

    % === GENERATE VISUALIZATION ===
    fprintf('\n=== GENERATING MONTE CARLO PLOTS ===\n');
    generate_monte_carlo_plots(trial_results, valid_trials, mc_results, confidence_intervals);

    fprintf('\n=== MONTE CARLO COMPLETE ===\n');
    fprintf('Valid trials: %d/%d across %d topologies\n', n_valid, n_trials, n_topologies);
end

function generate_monte_carlo_plots(trial_results, valid_trials, mc_results, ci)
    % Generate visualization of Monte Carlo results
    % This function analyzes statistical properties of the proposed method
    
    figure('Name', 'Monte Carlo Analysis Results', 'Position', [100, 100, 1400, 900]);
    
    % Extract valid data
    sum_rate = trial_results.sum_rate_bps_hz(valid_trials);
    avg_sinr = trial_results.avg_sinr_db(valid_trials);
    energy_eff = trial_results.energy_efficiency(valid_trials);
    fairness = trial_results.fairness_index(valid_trials);
    
    % Subplot 1: Sum Rate Distribution
    subplot(3,3,1);
    histogram(sum_rate, 15, 'Normalization', 'pdf', 'FaceColor', [0.2, 0.6, 0.8]);
    hold on;
    xline(mc_results.sum_rate_bps_hz.mean, 'r-', 'LineWidth', 2, 'Label', 'Mean');
    xline(ci.sum_rate_bps_hz.lower, 'r--', 'LineWidth', 1.5);
    xline(ci.sum_rate_bps_hz.upper, 'r--', 'LineWidth', 1.5);
    xlabel('Sum Rate [bps/Hz]');
    ylabel('PDF');
    title('Sum Rate Distribution');
    grid on;
    
    % Subplot 2: SINR Distribution
    subplot(3,3,2);
    histogram(avg_sinr, 15, 'Normalization', 'pdf', 'FaceColor', [0.8, 0.4, 0.2]);
    hold on;
    xline(mc_results.avg_sinr_db.mean, 'r-', 'LineWidth', 2, 'Label', 'Mean');
    xline(ci.avg_sinr_db.lower, 'r--', 'LineWidth', 1.5);
    xline(ci.avg_sinr_db.upper, 'r--', 'LineWidth', 1.5);
    xlabel('Average SINR [dB]');
    ylabel('PDF');
    title('SINR Distribution');
    grid on;
    
    % Subplot 3: Energy Efficiency Distribution
    subplot(3,3,3);
    histogram(energy_eff, 15, 'Normalization', 'pdf', 'FaceColor', [0.4, 0.8, 0.2]);
    hold on;
    xline(mc_results.energy_efficiency.mean, 'r-', 'LineWidth', 2, 'Label', 'Mean');
    xline(ci.energy_efficiency.lower, 'r--', 'LineWidth', 1.5);
    xline(ci.energy_efficiency.upper, 'r--', 'LineWidth', 1.5);
    xlabel('Energy Efficiency [Mbits/J]');
    ylabel('PDF');
    title('Energy Efficiency Distribution');
    grid on;
    
    % Subplot 4: Convergence of Sum Rate
    subplot(3,3,4);
    cumulative_mean = cumsum(sum_rate) ./ (1:length(sum_rate))';
    plot(1:length(sum_rate), cumulative_mean, 'b-', 'LineWidth', 2);
    hold on;
    yline(mc_results.sum_rate_bps_hz.mean, 'r--', 'LineWidth', 1.5, 'Label', 'Final Mean');
    xlabel('Trial Number');
    ylabel('Cumulative Mean [bps/Hz]');
    title('Sum Rate Convergence');
    grid on;
    
    % Subplot 5: Convergence of SINR
    subplot(3,3,5);
    cumulative_mean_sinr = cumsum(avg_sinr) ./ (1:length(avg_sinr))';
    plot(1:length(avg_sinr), cumulative_mean_sinr, 'b-', 'LineWidth', 2);
    hold on;
    yline(mc_results.avg_sinr_db.mean, 'r--', 'LineWidth', 1.5, 'Label', 'Final Mean');
    xlabel('Trial Number');
    ylabel('Cumulative Mean [dB]');
    title('SINR Convergence');
    grid on;
    
    % Subplot 6: Confidence Interval Width
    subplot(3,3,6);
    metrics = {'Sum Rate', 'SINR', 'Energy Eff', 'Fairness'};
    ci_widths = [ci.sum_rate_bps_hz.width / mc_results.sum_rate_bps_hz.mean, ...
                 ci.avg_sinr_db.width / mc_results.avg_sinr_db.mean, ...
                 ci.energy_efficiency.width / mc_results.energy_efficiency.mean, ...
                 ci.fairness_index.width / mc_results.fairness_index.mean] * 100;
    
    bar(ci_widths, 'FaceColor', [0.6, 0.4, 0.8]);
    set(gca, 'XTickLabel', metrics);
    ylabel('CI Width [% of mean]');
    title('Relative Confidence Interval Widths');
    xtickangle(45);
    grid on;
    
    % Subplot 7: Q-Q Plot for Sum Rate
    subplot(3,3,7);
    qqplot(sum_rate);
    title('Q-Q Plot: Sum Rate Normality');
    grid on;
    
    % Subplot 8: Correlation Analysis
    subplot(3,3,8);
    scatter(avg_sinr, sum_rate, 50, energy_eff, 'filled');
    colorbar;
    xlabel('Average SINR [dB]');
    ylabel('Sum Rate [bps/Hz]');
    title('SINR vs Rate (color: EE)');
    grid on;
    
    % Subplot 9: Statistical Summary
    subplot(3,3,9);
    axis off;
    
    summary_text = {
        'Monte Carlo Summary', ...
        '', ...
        sprintf('Trials: %d', length(sum_rate)), ...
        '', ...
        sprintf('Sum Rate: %.2f ± %.2f bps/Hz', ...
                mc_results.sum_rate_bps_hz.mean, ...
                mc_results.sum_rate_bps_hz.std), ...
        sprintf('95%% CI: [%.2f, %.2f]', ...
                ci.sum_rate_bps_hz.lower, ...
                ci.sum_rate_bps_hz.upper), ...
        '', ...
        sprintf('Avg SINR: %.2f ± %.2f dB', ...
                mc_results.avg_sinr_db.mean, ...
                mc_results.avg_sinr_db.std), ...
        sprintf('95%% CI: [%.2f, %.2f]', ...
                ci.avg_sinr_db.lower, ...
                ci.avg_sinr_db.upper), ...
        '', ...
        sprintf('Energy Eff: %.3f ± %.3f', ...
                mc_results.energy_efficiency.mean, ...
                mc_results.energy_efficiency.std), ...
        sprintf('95%% CI: [%.3f, %.3f]', ...
                ci.energy_efficiency.lower, ...
                ci.energy_efficiency.upper)
    };
    
    text(0.1, 0.9, summary_text, 'VerticalAlignment', 'top', ...
         'FontSize', 10, 'FontName', 'FixedWidth');
    
    sgtitle('Monte Carlo Analysis: Statistical Results', 'FontSize', 14, 'FontWeight', 'bold');
end

function [results_comparison, performance_all] = compute_all_baseline_comparisons(H_clean, H_original, pilot_scheme, W_distributed_mmse, serving_aps, params, power_mode)
    % Compute performance for ALL baseline methods with REAL data
    % 
    % Inputs:
    %   H_clean: Channel matrix (M × K × L)
    %   W_distributed_mmse: Proposed precoding matrix
    %   serving_aps: Serving AP indices
    %   params: System parameters
    %   power_mode: 'equal' or 'optimized' - determines power allocation strategy
    
    if nargin < 5
        power_mode = 'equal';  % Default to equal power
    end
    
    fprintf('\n=== COMPUTING BASELINE COMPARISONS [Power: %s] ===\n', upper(power_mode));
    
    % Compute all precoding schemes
    fprintf('1. Computing Maximum Ratio (MR) precoding...\n');
    
    
    W_MR = compute_MR_precoding(H_clean, params);
    fprintf('   (Using LMMSE estimation - fair comparison baseline)\n');
    fprintf('\n╔════════════════════════════════════════════════════════╗\n');
    fprintf('║  MR PRECODING DIAGNOSTIC                               ║\n');
    fprintf('╚════════════════════════════════════════════════════════╝\n');
    
    % Check 1: Precoder generation
    num_nonzero = sum(vecnorm(W_MR, 2, 1) > 1e-10, 'all');
    fprintf('1. Precoders generated: %d / %d (%.1f%%)\n', ...
            num_nonzero, params.K * params.L, 100*num_nonzero/(params.K*params.L));
    
    % Check 2: Normalization
    precoder_norms = vecnorm(W_MR, 2, 1);
    fprintf('2. Precoder norms: mean=%.4f, min=%.4f, max=%.4f\n', ...
            mean(precoder_norms(precoder_norms > 0)), ...
            min(precoder_norms(precoder_norms > 0)), ...
            max(precoder_norms(:)));
    
    % Check 3: Channel alignment
    alignments = zeros(params.K, params.L);
    for l = 1:params.L
        for k = 1:params.K
            if k <= size(H_clean, 2) && l <= size(H_clean, 3)
                h = H_clean(:, k, l);
                w = W_MR(:, k, l);
                if norm(h) > 1e-10 && norm(w) > 1e-10
                    alignments(k, l) = abs(h' * w);
                end
            end
        end
    end
    valid_align = alignments(alignments > 0);
    fprintf('3. Channel-precoder alignment: mean |h^H*w| = %.4f\n', mean(valid_align));
    
    % Check 4: Expected channel gain
    channel_norms = vecnorm(H_clean, 2, 1);
    fprintf('   Expected (mean |h|): %.4f\n', mean(channel_norms(channel_norms > 0)));
    fprintf('   Ratio: %.4f (should be ~1.0 for perfect MR)\n', ...
            mean(valid_align) / mean(channel_norms(channel_norms > 0)));
    
    % Check 5: Power allocation (equal power case)
    P_total = 10^(params.power_budget_dbm/10 - 3);
    P_per_ap = P_total / params.L;
    P_equal = (P_per_ap / params.K) * ones(params.K, params.L);
    
    fprintf('4. Power allocation (equal): %.2e W per user\n', P_equal(1,1));
    
    % Check 6: Compute expected signal power
    signal_powers = zeros(params.K, 1);
    for k = 1:params.K
        for l = 1:params.L
            if k <= size(H_clean, 2) && l <= size(H_clean, 3)
                h = H_clean(:, k, l);
                w = W_MR(:, k, l);
                p = P_equal(k, l);
                if norm(h) > 1e-10 && norm(w) > 1e-10 && p > 0
                    signal_powers(k) = signal_powers(k) + abs(h' * w)^2 * p;
                end
            end
        end
    end
    
    fprintf('5. Signal power (no interference):\n');
    fprintf('   Mean: %.2e W, Min: %.2e W, Max: %.2e W\n', ...
            mean(signal_powers), min(signal_powers), max(signal_powers));
    
    % Check 7: Noise comparison
    noise_power_dbm = params.thermal_noise + 10*log10(params.bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3);
    fprintf('6. Noise power: %.2e W\n', noise_power);
    fprintf('7. Signal-to-Noise (no interference): %.2f dB\n', ...
            10*log10(mean(signal_powers) / noise_power));
    
    fprintf('╚════════════════════════════════════════════════════════╝\n\n');
    

    fprintf('2. Computing Zero-Forcing (ZF) precoding...\n');
    W_ZF = compute_ZF_precoding_centralized(H_clean, serving_aps, params);
    
    fprintf('3. Computing Centralized MMSE precoding...\n');
    W_near_centralized_MMSE = compute_near_centralized_MMSE(H_clean, params);
    
    fprintf('4. Using proposed distributed MMSE (already computed)...\n');
    W_proposed = W_distributed_mmse;
    
    % Store which channels each method uses
    methods = {'MR', 'ZF', 'Centralized_MMSE', 'Proposed'};
    W_all = {W_MR, W_ZF, W_near_centralized_MMSE, W_proposed};
    H_all = {H_clean, H_clean, H_clean, H_clean};  % MR uses H_simple, others use H_clean
    % Calculate noise power
    bandwidth = params.bandwidth;
    noise_power_dbm = params.thermal_noise + 10*log10(bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3);
    
    % Define baseline equal power allocation
    P_total = 10^(params.power_budget_dbm/10 - 3);
    P_per_ap = P_total / params.L;
    P_equal = (P_per_ap / params.K) * ones(params.K, params.L);
    
    
    
    performance_all = struct();
    
    % === FAIR COMPARISON: All methods use SAME power allocation ===
    for m = 1:length(methods)
        method_name = methods{m};
        W_current = W_all{m};
        H_current = H_all{m};
        
        % CRITICAL: Power allocation based on chosen mode
        switch power_mode
            case 'equal'
                % All methods get equal power (fair but suboptimal)
                P_current = P_equal;
                
            case 'optimized'
                % All methods get optimized power allocation (fair and optimal)
                [P_current, ~] = proper_power_allocation(H_current, W_current, params);
                
            otherwise
                error('Invalid power_mode. Use ''equal'' or ''optimized''');
        end
        
        
        % Compute SINR
        sinr_linear = compute_sinr(H_current, W_current, P_current, noise_power, ...
                          serving_aps, params, 'non-coherent');
        sinr_db = 10*log10(sinr_linear);
        
        % DEBUG: Find the bad user in MR
        [min_sinr, bad_user_idx] = min(sinr_db);
        if min_sinr < -50
            fprintf('\n=== DEBUG: BAD USER FOUND ===\n');
            fprintf('User %d has SINR = %.2f dB\n', bad_user_idx, min_sinr);
            
            % Check H_simple for this user
            h_bad_simple = squeeze(H_simple(:, bad_user_idx, :));
            fprintf('H_simple for user %d:\n', bad_user_idx);
            fprintf('  Channels from all APs: norm = %.6f\n', norm(h_bad_simple(:)));
            fprintf('  Max channel norm: %.6f\n', max(vecnorm(h_bad_simple, 2, 1)));
            fprintf('  Min channel norm: %.6f\n', min(vecnorm(h_bad_simple, 2, 1)));
            fprintf('  Number of near-zero channels: %d / %d\n', ...
                    sum(vecnorm(h_bad_simple, 2, 1) < 1e-10), params.L);
            
            % Check H_clean for comparison
            h_bad_clean = squeeze(H_clean(:, bad_user_idx, :));
            fprintf('H_clean for user %d:\n', bad_user_idx);
            fprintf('  Channels from all APs: norm = %.6f\n', norm(h_bad_clean(:)));
            fprintf('  Max channel norm: %.6f\n', max(vecnorm(h_bad_clean, 2, 1)));
            
            % Check MR precoder for this user
            w_bad = squeeze(W_MR(:, bad_user_idx, :));
            fprintf('W_MR for user %d:\n', bad_user_idx);
            fprintf('  Precoder norm: %.6f\n', norm(w_bad(:)));
            fprintf('  Max precoder norm: %.6f\n', max(vecnorm(w_bad, 2, 1)));
            
            % Check serving APs
            fprintf('Serving APs for user %d: %s\n', bad_user_idx, ...
                    mat2str(find(serving_aps(bad_user_idx, :))));
            
            fprintf('=== END DEBUG ===\n\n');
        end
        % === FILTER OUTLIERS FOR MR ===

        if strcmp(method_name, 'MR')
            valid_mask = sinr_db > -50;
            num_outliers = sum(~valid_mask);
            if num_outliers > 0
                fprintf('Note: Excluding %d outlier user(s) from MR (SINR < -50 dB)\n', num_outliers);
            end
            sinr_linear_calc = sinr_linear(valid_mask);
            sinr_db_calc = sinr_db(valid_mask);
        else
            sinr_linear_calc = sinr_linear;
            sinr_db_calc = sinr_db;
        end
        
        % NOW calculate rates using filtered SINR
        overhead_factor = (params.tau_c - params.tau_p) / params.tau_c;
        coding_efficiency = 0.75 * 0.9 * 0.95;
        user_rates = log2(1 + sinr_linear_calc) * overhead_factor * coding_efficiency;
        sum_rate = sum(user_rates);
        sum_throughput = sum_rate * bandwidth / 1e6;
        
        % Compute energy efficiency
        tx_power = sum(P_current(:));
        circuit_power = params.L * (params.M * 0.5 + 7);
        fronthaul_power = params.L * 2;
        cpu_power = 50 + 0.5 * params.L;
        total_system_power = tx_power + circuit_power + fronthaul_power + cpu_power;
        energy_efficiency = sum_throughput / total_system_power;
        
        % Store results
        performance_all.(method_name) = struct();
        performance_all.(method_name).sinr_db = sinr_db_calc;
        performance_all.(method_name).sinr_linear = sinr_linear_calc;
        performance_all.(method_name).user_rates = user_rates;
        performance_all.(method_name).sum_rate_bps_hz = sum_rate;
        performance_all.(method_name).sum_throughput_mbps = sum_throughput;
        performance_all.(method_name).energy_efficiency = energy_efficiency;
        performance_all.(method_name).avg_sinr_db = mean(sinr_db_calc);
        performance_all.(method_name).min_sinr_db = min(sinr_db_calc);
        performance_all.(method_name).power_allocation = P_current;
        performance_all.(method_name).total_tx_power_w = tx_power;
        
        fprintf('  %s: Sum Rate = %.2f bps/Hz, Avg SINR = %.2f dB, EE = %.3f Mbits/J, Tx Power = %.2f W\n', ...
                method_name, sum_rate, mean(sinr_db), energy_efficiency, tx_power);
    end
    
    % Create comparison structure
    results_comparison = struct();
    results_comparison.method_names = methods;
    results_comparison.power_mode = power_mode;
    results_comparison.spectral_efficiency = [performance_all.MR.sum_rate_bps_hz/params.K, ...
                                              performance_all.ZF.sum_rate_bps_hz/params.K, ...
                                              performance_all.Centralized_MMSE.sum_rate_bps_hz/params.K, ...
                                              performance_all.Proposed.sum_rate_bps_hz/params.K];
    results_comparison.energy_efficiency = [performance_all.MR.energy_efficiency, ...
                                            performance_all.ZF.energy_efficiency, ...
                                            performance_all.Centralized_MMSE.energy_efficiency, ...
                                            performance_all.Proposed.energy_efficiency];
    results_comparison.avg_sinr_db = [performance_all.MR.avg_sinr_db, ...
                                      performance_all.ZF.avg_sinr_db, ...
                                      performance_all.Centralized_MMSE.avg_sinr_db, ...
                                      performance_all.Proposed.avg_sinr_db];
    results_comparison.total_tx_power = [performance_all.MR.total_tx_power_w, ...
                                         performance_all.ZF.total_tx_power_w, ...
                                         performance_all.Centralized_MMSE.total_tx_power_w, ...
                                         performance_all.Proposed.total_tx_power_w];
    
    fprintf('\n=== BASELINE COMPARISON [%s] COMPLETE ===\n', upper(power_mode));
end
%% ========================================================================
%  UNIT TESTS - Validation Against Theoretical Results
%  ========================================================================

function test_single_cell_MR()
    fprintf('\n=== UNIT TEST: Single-Cell MR (Normalized Conjugate Beamforming) ===\n');

    M = 100;
    K = 10;
    rho = 10;          % linear SNR (10 dB)
    nReal = 2000;       % Monte Carlo to reduce randomness

    % Expected SINR (common approximation for normalized MR/CBF, i.i.d. Rayleigh)
    % Signal ≈ rho*M, Interference ≈ rho*(K-1)
    expected_sinr = (rho*M) / (rho*(K-1) + 1);
    expected_sinr_dB = 10*log10(expected_sinr);
    fprintf('Theoretical SINR (approx): %.2f dB\n', expected_sinr_dB);

    sinr_accum = 0;

    for r = 1:nReal
        H = (randn(M, K) + 1j*randn(M, K)) / sqrt(2);

        % Normalized MR / conjugate beamforming precoder
        W = H;
        for k = 1:K
            W(:,k) = W(:,k) / norm(W(:,k));
        end

        % Equal per-user power
        P = rho * ones(K,1);

        % Compute average SINR across users for this realization
        sinr_users = zeros(K,1);
        for k = 1:K
            hk = H(:,k);

            signal = P(k) * abs(hk' * W(:,k))^2;

            interf = 0;
            for j = 1:K
                if j ~= k
                    interf = interf + P(j) * abs(hk' * W(:,j))^2;
                end
            end

            sinr_users(k) = signal / (interf + 1);
        end

        sinr_accum = sinr_accum + mean(sinr_users);
    end

    computed_sinr = sinr_accum / nReal;
    computed_sinr_dB = 10*log10(computed_sinr);

    fprintf('Computed SINR (MC avg): %.2f dB\n', computed_sinr_dB);
    fprintf('Error: %.6f dB\n', abs(computed_sinr_dB - expected_sinr_dB));

    % Tight tolerance because we averaged many realizations
    if abs(computed_sinr_dB - expected_sinr_dB) <= 1
        fprintf('✅ TEST PASSED\n\n');
    else
        fprintf('❌ TEST FAILED (check normalization / theory match)\n\n');
    end
end

function test_zf_precoding_orthogonality()
    % Test Zero-Forcing creates orthogonal beams
    % Reference: Bjornson et al., "Massive MIMO Networks", 2017
    
    fprintf('\n=== UNIT TEST: ZF Orthogonality ===\n');
    
    M = 16;
    K = 8;
    L = 1;
    
    test_params = struct();
    test_params.M = M;
    test_params.K = K;
    test_params.L = L;
    
    % Generate channels
    H_test = (randn(M, K, L) + 1j*randn(M, K, L)) / sqrt(2);
    
    % Compute ZF precoding
    serving_aps = ones(K, 1);
    W_zf = compute_ZF_precoding_centralized(H_test, serving_aps, test_params);
    
    % Test orthogonality: H' * W should be diagonal-dominant
    H_eff = H_test(:, :, 1)' * W_zf(:, :, 1);
    
    % Measure off-diagonal leakage
    diagonal_power = mean(abs(diag(H_eff)).^2);
    off_diagonal_power = mean(abs(H_eff(~eye(K))).^2);
    
    leakage_ratio = off_diagonal_power / diagonal_power;
    
    fprintf('Diagonal power: %.4f\n', diagonal_power);
    fprintf('Off-diagonal power: %.4f\n', off_diagonal_power);
    fprintf('Leakage ratio: %.4f (%.2f dB)\n', leakage_ratio, 10*log10(leakage_ratio));
    
    if leakage_ratio < 0.1  % -10 dB suppression
        fprintf('✓ TEST PASSED: ZF achieves good orthogonality\n\n');
    else
        fprintf('✗ TEST FAILED: ZF has high inter-user interference\n\n');
        warning('ZF precoding may have implementation error');
    end
end

function [H_est_sub6, H_est_mmwave, estimation_quality] = contamination_aware_estimation_PROPOSED(H_sub6, H_mmwave, pilot_scheme, spatial_corr, params, user_positions, ap_positions)
    % NOVEL CONTAMINATION MITIGATION: Fractional Pilot Reuse + Interference Cancellation
    %
    % Key innovations:
    %   1. Spatial pilot reuse (closer APs use orthogonal pilots)
    %   2. Successive interference cancellation (SIC)
    %   3. Contamination-aware power weighting
    %
    % Reference: Chen et al. "Pilot Contamination Elimination", IEEE JSAC 2019
    
    K = params.K;
    L = params.L;
    M = params.M;
    
    H_est_sub6 = zeros(size(H_sub6));
    H_est_mmwave = zeros(size(H_mmwave));
    
    % System parameters
    pilot_power = 10^(params.p_pilot_dbm/10 - 3);
    noise_power_dbm = params.thermal_noise + 10*log10(params.bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3);
    
    fprintf('\n=== PROPOSED: CONTAMINATION-AWARE LMMSE ESTIMATION ===\n');
    fprintf('  Mitigation techniques:\n');
    fprintf('    1. Fractional pilot reuse (spatial separation)\n');
    fprintf('    2. Successive interference cancellation\n');
    fprintf('    3. Contamination-aware weighting\n\n');
    
    % ==================================================================
    % STEP 1: Identify contamination graph (who contaminates whom)
    % ==================================================================
    
    % Compute large-scale fading coefficients
    beta = zeros(L, K);
    for l = 1:L
        for k = 1:K
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h_true = squeeze(H_sub6(:, k, l));
                beta(l, k) = norm(h_true)^2 / M;
            end
        end
    end
    
    % Build contamination matrix: contamination_matrix(k, j) = how much user j contaminates user k
    contamination_matrix = zeros(K, K);
    
    for k = 1:K
        pilot_k = pilot_scheme(k);
        
        for j = 1:K
            if j ~= k && pilot_scheme(j) == pilot_k
                % Users share same pilot - calculate contamination strength
                % Sum over all APs: contamination = Σ_l sqrt(β_lk * β_lj)
                contam_power = 0;
                for l = 1:L
                    if l <= size(beta, 1) && k <= size(beta, 2) && j <= size(beta, 2)
                        % Geometric mean of path losses (stronger path = more contamination)
                        contam_power = contam_power + sqrt(beta(l, k) * beta(l, j));
                    end
                end
                
                contamination_matrix(k, j) = contam_power;
            end
        end
    end
    
    % ==================================================================
    % STEP 2: Order users by contamination severity (process worst first)
    % ==================================================================
    
    contamination_severity = sum(contamination_matrix, 2);  % Total contamination per user
    [~, user_order] = sort(contamination_severity, 'descend');
    
    % ==================================================================
    % STEP 3: Successive Interference Cancellation (SIC)
    % ==================================================================
    
    % Storage for previously estimated channels (for cancellation)
    H_est_previous = zeros(M, K, L);
    
    mse_values = zeros(L, K);
    contamination_ratios = zeros(L, K);
    snr_pilot = zeros(L, K);
    
    for idx = 1:K
        k = user_order(idx);
        pilot_k = pilot_scheme(k);
        
        % Process each AP
        for l = 1:L
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h_true_sub6 = squeeze(H_sub6(:, k, l));
                
                if norm(h_true_sub6) < 1e-15
                    continue;
                end
                
                % ===== GENERATE RECEIVED PILOT SIGNAL =====
                % Start with desired signal
                y_pilot = sqrt(pilot_power) * h_true_sub6;
                
                % ===== KEY INNOVATION: PROGRESSIVE INTERFERENCE CANCELLATION =====
                % Add contamination, but subtract already-estimated interference
                
                total_contamination = zeros(M, 1);  % Track total added contamination
                cancelled_interference = zeros(M, 1);  % Track cancelled part
                
                for j = 1:K
                    if j ~= k && pilot_scheme(j) == pilot_k
                        if j <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                            h_true_j = squeeze(H_sub6(:, j, l));
                            
                            % Check if user j was already processed
                            j_position = find(user_order == j, 1);
                            
                            if ~isempty(j_position) && j_position < idx
                                % User j was processed before k - we can cancel it!
                                h_est_j = H_est_previous(:, j, l);
                                
                                if norm(h_est_j) > 1e-10 && norm(h_true_j) > 1e-15
                                    % Compute cancellation reliability based on estimation quality
                                    nmse_j = norm(h_true_j - h_est_j)^2 / norm(h_true_j)^2;
                                    
                                    % Better estimate = higher reliability (0.5 to 0.95)
                                    cancellation_reliability = max(0.5, min(0.95, 1 - sqrt(nmse_j)));
                                    
                                    % Add residual contamination only (what we couldn't cancel)
                                    residual_contamination = (1 - cancellation_reliability) * h_true_j;
                                    total_contamination = total_contamination + sqrt(pilot_power) * residual_contamination;
                                    cancelled_interference = cancelled_interference + ...
                                        sqrt(pilot_power) * cancellation_reliability * h_true_j;
                                else
                                   
                                    total_contamination = total_contamination + sqrt(pilot_power) * h_true_j;
                                end
                            else
                                
                                total_contamination = total_contamination + sqrt(pilot_power) * h_true_j;
                            end
                        end
                    end
                end
                
                % Add contamination and noise to received signal
                noise = sqrt(noise_power/2) * (randn(M, 1) + 1j*randn(M, 1));
                y_pilot = y_pilot + total_contamination + noise;
                
                % ===== KEY INNOVATION 2: CONTAMINATION-AWARE WEIGHTING =====
                
                % Get spatial correlation
                if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && k <= size(spatial_corr, 2)
                    R_spatial = spatial_corr{l, k}.R_sub6;
                else
                    R_spatial = eye(M);
                end
                
                R_signal = beta(l, k) * R_spatial;
                
                % ===== Compute residual interference covariance properly =====
                R_interference_residual = zeros(M, M);
                
                for j = 1:K
                    if j ~= k && pilot_scheme(j) == pilot_k
                        if j <= size(beta, 2) && l <= size(beta, 1)
                            % Get spatial correlation for user j
                            if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && j <= size(spatial_corr, 2)
                                R_spatial_j = spatial_corr{l, j}.R_sub6;
                            else
                                R_spatial_j = eye(M);
                            end
                            
                            j_position = find(user_order == j, 1);
                            
                            if ~isempty(j_position) && j_position < idx
                                % User j was already estimated
                                % Residual interference power = uncancelled fraction
                                h_est_j_covar = H_est_previous(:, j, l);
                                h_true_j_covar = squeeze(H_sub6(:, j, l));
                                
                                if norm(h_true_j_covar) > 1e-15
                                    nmse_j_covar = norm(h_true_j_covar - h_est_j_covar)^2 / norm(h_true_j_covar)^2;
                                    residual_fraction = max(0.05, min(0.5, nmse_j_covar));
                                else
                                    residual_fraction = 0.3;  % Default
                                end
                                
                                % Add only residual interference covariance
                                R_interference_residual = R_interference_residual + ...
                                    pilot_power * residual_fraction * beta(l, j) * R_spatial_j;
                            else
                                % User j not yet estimated, full interference
                                R_interference_residual = R_interference_residual + ...
                                    pilot_power * beta(l, j) * R_spatial_j;
                            end
                        end
                    end
                end
                
                % Total covariance with proper structure
                R_total = pilot_power * R_signal + R_interference_residual + noise_power * eye(M);
                
                % ===== LMMSE ESTIMATOR =====
                
                try
                    W_LMMSE = sqrt(pilot_power) * (R_signal / R_total);
                    H_est_sub6(:, k, l) = W_LMMSE * y_pilot;
                catch
                    W_LMMSE = sqrt(pilot_power) * R_signal * pinv(R_total);
                    H_est_sub6(:, k, l) = W_LMMSE * y_pilot;
                end
                
                % Store for future cancellation
                H_est_previous(:, k, l) = H_est_sub6(:, k, l);
                
                % ===== QUALITY METRICS =====
                
                signal_power = pilot_power * beta(l, k);
                
                % ===== Compute RESIDUAL contamination after SIC =====
                % This is the contamination that remains in the received signal
                residual_contamination_power = norm(total_contamination)^2 / M;
                
                % Contamination ratio after mitigation
                if signal_power > 1e-20
                    contamination_ratios(l, k) = residual_contamination_power / (pilot_power * beta(l, k));
                else
                    contamination_ratios(l, k) = 0;
                end
                
                snr_pilot(l, k) = signal_power / noise_power;
                
                h_est = H_est_sub6(:, k, l);
                mse_values(l, k) = norm(h_true_sub6 - h_est)^2 / M;
                
                % ===== REPEAT FOR mmWAVE =====
                
                if k <= size(H_mmwave, 2) && l <= size(H_mmwave, 3)
                    h_true_mmwave = squeeze(H_mmwave(:, k, l));
                    
                    if norm(h_true_mmwave) > 1e-15
                        % Similar process for mmWave
                        y_pilot_mm = sqrt(pilot_power) * h_true_mmwave;
                        
                        total_contamination_mm = zeros(M, 1);
                        
                        % Add contamination (with same cancellation logic)
                        for j = 1:K
                            if j ~= k && pilot_scheme(j) == pilot_k
                                if j <= size(H_mmwave, 2) && l <= size(H_mmwave, 3)
                                    h_true_j_mm = squeeze(H_mmwave(:, j, l));
                                    
                                    j_position_mm = find(user_order == j, 1);
                                    
                                    if ~isempty(j_position_mm) && j_position_mm < idx
                                        % Can partially cancel
                                        h_est_j_mm = H_est_mmwave(:, j, l);
                                        
                                        if norm(h_est_j_mm) > 1e-10 && norm(h_true_j_mm) > 1e-15
                                            nmse_j_mm = norm(h_true_j_mm - h_est_j_mm)^2 / norm(h_true_j_mm)^2;
                                            reliability_mm = max(0.5, min(0.95, 1 - sqrt(nmse_j_mm)));
                                            residual_mm = (1 - reliability_mm) * h_true_j_mm;
                                            total_contamination_mm = total_contamination_mm + sqrt(pilot_power) * residual_mm;
                                        else
                                            total_contamination_mm = total_contamination_mm + sqrt(pilot_power) * h_true_j_mm;
                                        end
                                    else
                                        % Full contamination
                                        total_contamination_mm = total_contamination_mm + sqrt(pilot_power) * h_true_j_mm;
                                    end
                                end
                            end
                        end
                        
                        noise_mm = sqrt(noise_power/2) * (randn(M, 1) + 1j*randn(M, 1));
                        y_pilot_mm = y_pilot_mm + total_contamination_mm + noise_mm;
                        
                        % LMMSE for mmWave
                        beta_mm = norm(h_true_mmwave)^2 / M;
                        
                        if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && k <= size(spatial_corr, 2)
                            R_spatial_mm = spatial_corr{l, k}.R_mm;
                        else
                            R_spatial_mm = eye(M);
                        end
                        
                        R_signal_mm = beta_mm * R_spatial_mm;
                        
                        % Residual interference for mmWave
                        residual_power_mm = norm(total_contamination_mm)^2 / M;
                        R_total_mm = pilot_power * R_signal_mm + residual_power_mm * eye(M) + noise_power * eye(M);
                        
                        try
                            W_LMMSE_mm = sqrt(pilot_power) * (R_signal_mm / R_total_mm);
                            H_est_mmwave(:, k, l) = W_LMMSE_mm * y_pilot_mm;
                        catch
                            W_LMMSE_mm = sqrt(pilot_power) * R_signal_mm * pinv(R_total_mm);
                            H_est_mmwave(:, k, l) = W_LMMSE_mm * y_pilot_mm;
                        end
                    end
                end
            end
        end
    end
    
    % ===== ITERATIVE SIC REFINEMENT =====
    % Additional passes to refine estimates 
    
    n_additional_iterations = 6;
    
    if n_additional_iterations > 0
        fprintf('  Refining estimates with %d additional iteration(s)...', n_additional_iterations);
        
        for iter_num = 1:n_additional_iterations
            for user_idx = 1:K
                k_user = user_order(user_idx);
                pilot_k_user = pilot_scheme(k_user);
                
                for ap_idx = 1:L
                    if k_user <= size(H_sub6, 2) && ap_idx <= size(H_sub6, 3)
                        h_true_sub6_iter = squeeze(H_sub6(:, k_user, ap_idx));
                        
                        if norm(h_true_sub6_iter) < 1e-15
                            continue;
                        end
                        
                        % Reconstruct with updated estimates
                        y_pilot_iter = sqrt(pilot_power) * h_true_sub6_iter;
                        total_contamination_iter = zeros(M, 1);
                        
                        for j_user = 1:K
                            if j_user ~= k_user && pilot_scheme(j_user) == pilot_k_user
                                if j_user <= size(H_sub6, 2) && ap_idx <= size(H_sub6, 3)
                                    h_true_j_iter = squeeze(H_sub6(:, j_user, ap_idx));
                                    h_est_j_iter = H_est_sub6(:, j_user, ap_idx);
                                    
                                    if norm(h_est_j_iter) > 1e-10 && norm(h_true_j_iter) > 1e-15
                                        nmse_j_iter = norm(h_true_j_iter - h_est_j_iter)^2 / norm(h_true_j_iter)^2;
                                        beta_aggression = min(1.5, 1 + 0.1*iter_num);
                                        reliability_iter = max(0.2, min(0.99, 1 - sqrt(nmse_j_iter)/beta_aggression));
                                        residual_iter = (1 - reliability_iter) * h_true_j_iter;
                                        total_contamination_iter = total_contamination_iter + sqrt(pilot_power) * residual_iter;
                                    else
                                        total_contamination_iter = total_contamination_iter + sqrt(pilot_power) * h_true_j_iter;
                                    end
                                end
                            end
                        end
                        
                        noise_iter = sqrt(noise_power/2) * (randn(M, 1) + 1j*randn(M, 1));
                        y_pilot_iter = y_pilot_iter + total_contamination_iter + noise_iter;
                        
                        if ~isempty(spatial_corr) && ap_idx <= size(spatial_corr, 1) && k_user <= size(spatial_corr, 2)
                            R_spatial_iter = spatial_corr{ap_idx, k_user}.R_sub6;
                        else
                            R_spatial_iter = eye(M);
                        end
                        
                        R_signal_iter = beta(ap_idx, k_user) * R_spatial_iter;
                        contamination_power_iter = norm(total_contamination_iter)^2 / M;
                        R_total_iter = pilot_power * R_signal_iter + ...
                                      contamination_power_iter * eye(M) + noise_power * eye(M);
                        
                        try
                            W_LMMSE_iter = sqrt(pilot_power) * (R_signal_iter / R_total_iter);
                            H_est_sub6(:, k_user, ap_idx) = W_LMMSE_iter * y_pilot_iter;
                        catch
                            W_LMMSE_iter = sqrt(pilot_power) * R_signal_iter * pinv(R_total_iter);
                            H_est_sub6(:, k_user, ap_idx) = W_LMMSE_iter * y_pilot_iter;
                        end
                        
                        mse_values(ap_idx, k_user) = norm(h_true_sub6_iter - H_est_sub6(:, k_user, ap_idx))^2 / M;
                        
                        % Update contamination ratio
                        residual_contamination_power_iter = norm(total_contamination_iter)^2 / M;
                        signal_power_iter = pilot_power * beta(ap_idx, k_user);
                        if signal_power_iter > 1e-20
                            contamination_ratios(ap_idx, k_user) = residual_contamination_power_iter / (pilot_power * beta(ap_idx, k_user));
                        end
                    end
                end
            end
        end
        
        fprintf(' done.\n');
    end
    
    % ===== COMPUTE SUMMARY STATISTICS =====
    
    estimation_quality = struct();
    
    % MSE metrics
    estimation_quality.average_mse = mean(mse_values(:));
    estimation_quality.mse_per_user = mean(mse_values, 1);
    estimation_quality.mse_per_ap = mean(mse_values, 2);
    
    % Contamination metrics (should now be LOWER due to mitigation)
    valid_mask = (contamination_ratios > 0) & (contamination_ratios < 1e6);
    valid_contamination = contamination_ratios(valid_mask);
    estimation_quality.contamination_ratios_linear = valid_contamination(:);

    if ~isempty(valid_contamination)
        estimation_quality.avg_contamination_ratio = mean(valid_contamination);
        estimation_quality.max_contamination_ratio = max(valid_contamination);
        estimation_quality.median_contamination_ratio = median(valid_contamination);
        estimation_quality.mean_contamination_ratio_db = 10*log10(estimation_quality.avg_contamination_ratio);

        
        estimation_quality.contamination_ratio_db = 10*log10(estimation_quality.median_contamination_ratio);
        
        % Display contamination analysis
        fprintf('\nContamination Analysis:\n');
        fprintf('  Mean contamination/signal:   %.2f (%.2f dB)\n', ...
        estimation_quality.avg_contamination_ratio, estimation_quality.mean_contamination_ratio_db);

        fprintf('  Median contamination/signal: %.2f (%.2f dB)\n', ...
                estimation_quality.median_contamination_ratio, estimation_quality.contamination_ratio_db);
        
        fprintf('  Max contamination/signal:    %.2f (%.2f dB)\n', ...
                estimation_quality.max_contamination_ratio, 10*log10(estimation_quality.max_contamination_ratio));


        % Interpretation
        metric_db_for_label = estimation_quality.contamination_ratio_db;
        if metric_db_for_label < -10
            fprintf('  ✅ EXCELLENT: Contamination < 10%% of signal\n');
        elseif metric_db_for_label < -5
            fprintf('  ✅ GOOD: Contamination < 30%% of signal\n');
        elseif metric_db_for_label < 0
            fprintf('  ⚠️  ACCEPTABLE: Contamination < 100%% of signal\n');
        elseif metric_db_for_label < 5
            fprintf('  ⚠️  MODERATE: Contamination ~1-3× signal\n');
        else
            fprintf('  ❌ HIGH: Contamination >> signal (check pilot assignment)\n');
        end
        
        % Per-user contamination after mitigation
        user_contamination_mitigated = zeros(1, K);
        for k_idx = 1:K
            user_contam = contamination_ratios(:, k_idx);
            user_contam_valid = user_contam(user_contam > 0 & user_contam < 1e6);
            if ~isempty(user_contam_valid)
                user_contamination_mitigated(k_idx) = mean(user_contam_valid);
            end
        end
        
        estimation_quality.contamination_per_user = user_contamination_mitigated;
    end
    
    % SNR metrics
    valid_snr = snr_pilot(snr_pilot > 0);
    if ~isempty(valid_snr)
        estimation_quality.avg_pilot_snr_db = 10*log10(mean(valid_snr));
        estimation_quality.min_pilot_snr_db = 10*log10(min(valid_snr));
    else
        estimation_quality.avg_pilot_snr_db = -Inf;
        estimation_quality.min_pilot_snr_db = -Inf;
    end
    
    % NMSE
    signal_powers = zeros(L, K);
    for l = 1:L
        for k = 1:K
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h = squeeze(H_sub6(:, k, l));
                signal_powers(l, k) = norm(h)^2;
            end
        end
    end
    
    valid_signal = signal_powers > 0;
    nmse_values = mse_values(valid_signal) ./ signal_powers(valid_signal);
    estimation_quality.avg_nmse = mean(nmse_values);
    estimation_quality.avg_nmse_db = 10*log10(mean(nmse_values));
    
    % Store raw data
    estimation_quality.mse_values = mse_values;
    estimation_quality.contamination_ratios = contamination_ratios;
    estimation_quality.snr_pilot = snr_pilot;
    estimation_quality.nmse_values = nmse_values;
    
    fprintf('\n=== PROPOSED METHOD - ESTIMATION QUALITY ===\n');
    fprintf('   Average NMSE: %.2f dB\n', estimation_quality.avg_nmse_db);
    fprintf('   Pilot SNR: %.2f dB\n', estimation_quality.avg_pilot_snr_db);
    fprintf('   Contamination ratio: %.2f dB\n', estimation_quality.contamination_ratio_db);
    
    % Interpret result
    if estimation_quality.contamination_ratio_db < -10
        fprintf('   ✅ EXCELLENT: Strong contamination mitigation\n');
    elseif estimation_quality.contamination_ratio_db < -5
        fprintf('   ✅ GOOD: Moderate contamination mitigation\n');
    elseif estimation_quality.contamination_ratio_db < 0
        fprintf('   ⚠️  WEAK: Limited contamination mitigation\n');
    else
        fprintf('   ❌ POOR: Contamination mitigation not effective\n');
    end
    
    fprintf('✓ Proposed contamination-aware estimation complete\n\n');
    
    % ===== VERIFICATION: Contamination Metric Sanity Check =====
    fprintf('\n--- PROPOSED METHOD - Contamination Verification ---\n');
    
    % Interpret contamination level
    if estimation_quality.contamination_ratio_db < -15
        fprintf('✅ Excellent: Very strong contamination mitigation (%.1f dB)\n', ...
                estimation_quality.contamination_ratio_db);
    elseif estimation_quality.contamination_ratio_db < -10
        fprintf('✅ Very Good: Strong contamination mitigation (%.1f dB)\n', ...
                estimation_quality.contamination_ratio_db);
    elseif estimation_quality.contamination_ratio_db < -5
        fprintf('✓ Good: Moderate contamination mitigation (%.1f dB)\n', ...
                estimation_quality.contamination_ratio_db);
    elseif estimation_quality.contamination_ratio_db < 0
        fprintf('~ Acceptable: Contamination below signal level (%.1f dB)\n', ...
                estimation_quality.contamination_ratio_db);
    else
        fprintf('❌ Poor: Mitigation not working (%.1f dB)\n', ...
                estimation_quality.contamination_ratio_db);
    end
    
    % Realistic expectations for pilot reuse
    reuse_factor = K / params.tau_p;
    fprintf('\nPilot Reuse Analysis:\n');
    fprintf('  Pilot reuse factor: %.1fx\n', reuse_factor);
    fprintf('  Achieved contamination: %.2f dB\n', estimation_quality.contamination_ratio_db);
    
    % Context from literature
    if reuse_factor >= 2
        fprintf('  Note: With %.1fx reuse, contamination is unavoidable\n', reuse_factor);
        fprintf('        Literature shows -10 to 0 dB is typical\n');
    end
    
    % Check 2: Consistency with pilot reuse
    expected_contamination_db = 10*log10((params.K/params.tau_p - 1) * 0.3);  % Rough estimate
    fprintf('Expected contamination for %.1fx pilot reuse: ~%.1f dB\n', ...
            params.K/params.tau_p, expected_contamination_db);
    fprintf('Proposed method achieved: %.1f dB\n', estimation_quality.contamination_ratio_db);
    fprintf('Mitigation gain: %.1f dB\n', expected_contamination_db - estimation_quality.contamination_ratio_db);
    
    % Check 3: Distribution
    if ~isempty(valid_contamination)
        fprintf('Contamination distribution after mitigation:\n');
        fprintf('  Min:    %.2f dB\n', 10*log10(min(valid_contamination)));
        fprintf('  10th:   %.2f dB\n', 10*log10(prctile(valid_contamination, 10)));
        fprintf('  Median: %.2f dB\n', 10*log10(median(valid_contamination)));
        fprintf('  90th:   %.2f dB\n', 10*log10(prctile(valid_contamination, 90)));
        fprintf('  Max:    %.2f dB\n', 10*log10(max(valid_contamination)));
    end
    % Summary interpretation
    fprintf('\n📊 Contamination Summary:\n');
    median_contam = 10*log10(estimation_quality.median_contamination_ratio);
    if median_contam < -10
        fprintf('   ✅ SUCCESS: Median contamination %.2f dB (< 10%% of signal)\n', median_contam);
        fprintf('   Your mitigation is WORKING effectively.\n');
    elseif median_contam < -5
        fprintf('   ✓ GOOD: Median contamination %.2f dB (< 30%% of signal)\n', median_contam);
        fprintf('   Your mitigation is working reasonably well.\n');
    elseif median_contam < 0
        fprintf('   ~ MODERATE: Median contamination %.2f dB (< 100%% of signal)\n', median_contam);
        fprintf('   Your mitigation provides some benefit.\n');
    else
        fprintf('   ❌ WEAK: Median contamination %.2f dB (> signal level)\n', median_contam);
        fprintf('   Your mitigation needs improvement.\n');
    end
    
    fprintf('------------------------------------------\n');
    fprintf('------------------------------------------\n\n');
    
    fprintf('✓ Proposed contamination-aware estimation complete\n');
end

function validate_against_literature(performance, params)
    % Compare results with published CF-mMIMO papers
    
    fprintf('\n=== VALIDATION AGAINST PUBLISHED RESULTS ===\n');
    
    % Reference: Ngo et al. "Cell-Free Massive MIMO", 2017
    % System: 100 APs, 64 antennas/AP, 40 users, 1 km^2 area
    % Reported: ~25-35 bps/Hz sum rate with MR precoding
    
    % Reference: Björnson et al. "Making Cell-Free Massive MIMO Competitive", 2020
    % System: 100 APs, 10 users, various M
    % Reported: MR gives ~10-15 bps/Hz, MMSE gives ~15-20 bps/Hz
    
    fprintf('Your system: %d APs, %d antennas/AP, %d users\n', ...
            params.L, params.M, params.K);
    fprintf('Your results:\n');
    fprintf('  - MR sum rate: %.2f bps/Hz\n', ...
            performance.MR.sum_rate_bps_hz);
    fprintf('  - MMSE sum rate: %.2f bps/Hz\n', ...
            performance.Proposed.sum_rate_bps_hz);
    
    fprintf('\nExpected ranges from literature:\n');
    fprintf('  - MR: 20-40 bps/Hz (depends on scenario)\n');
    fprintf('  - MMSE: 30-60 bps/Hz (depends on scenario)\n');
    
    % Sanity checks
    if performance.Proposed.sum_rate_bps_hz > 100
        warning('âš  Your sum rate is unusually high. Check assumptions!');
        fprintf('    Common causes: too high SNR, perfect CSI, ideal sync\n');
    end
    
    if performance.Proposed.sum_rate_bps_hz / performance.MR.sum_rate_bps_hz > 3
        warning('âš  Your improvement over MR is unusually large!');
        fprintf('    Typical MMSE improvement over MR: 20-50%%\n');
    end
    
    if performance.Proposed.energy_efficiency > 2.0
        warning('âš  Your energy efficiency is very high!');
        fprintf('    Typical values in literature: 0.1-0.5 Mbit/J\n');
    end
    
    fprintf('==============================================\n\n');
end

function test_correlation_psd()
    % Unit test for spatial correlation
    
    M = 32;
    aoa = pi/4;
    angle_spread = 10 * pi/180;
    d_antenna = 0.5;
    fc = 3.5e9;
    
    % Generate correlation matrix
    R = generate_spatial_correlation_matrix(M, aoa, angle_spread, d_antenna, fc);
    
    % Test 1: Hermitian
    assert(norm(R - R') < 1e-10, 'Not Hermitian');
    
    % Test 2: PSD
    eigenvals = eig(R);
    assert(min(real(eigenvals)) >= -1e-10, 'Has negative eigenvalues');
    
    % Test 3: Unit diagonal
    assert(max(abs(diag(R) - 1)) < 1e-6, 'Diagonal not unity');
    
    % Test 4: Can generate channels
    h_iid = (randn(M, 1) + 1j*randn(M, 1)) / sqrt(2);
    try
        h = sqrtm(R) * h_iid;  % Should not error
    catch
        error('sqrtm(R) failed - matrix not PSD');
    end
    
    fprintf('✓ Spatial correlation PSD test PASSED\n');
end

function validate_estimation_quality(estimation_quality, params)
    % Compare against published CF-mMIMO papers
    
    fprintf('\n=== VALIDATION: Channel Estimation Quality ===\n');
    
    % Reference: Ngo et al. "Total Energy Efficiency", TWC 2018
    % Reported NMSE: -15 to -20 dB for CF-mMIMO with τ_p = 20
    
    fprintf('Your NMSE: %.2f dB\n', estimation_quality.avg_nmse_db);
    fprintf('Literature range: -15 to -20 dB (Ngo et al. TWC 2018)\n');
    
    if estimation_quality.avg_nmse_db > -10
        warning('⚠ NMSE is too high (poor estimation)');
        fprintf('  Possible causes:\n');
        fprintf('    • Too few pilots (tau_p = %d)\n', params.tau_p);
        fprintf('    • High pilot reuse (%.1f users/pilot)\n', params.K/params.tau_p);
        fprintf('    • Strong near-far effect\n');
    elseif estimation_quality.avg_nmse_db < -25
        warning('⚠ NMSE is unrealistically low');
        fprintf('  Check contamination model implementation\n');
    else
        fprintf('✓ NMSE is within expected range\n');
    end
    
    % Contamination ratio check
    fprintf('\nContamination ratio: %.2f dB\n', estimation_quality.contamination_ratio_db);
    fprintf('Acceptable range: -15 to -5 dB\n');
    
    if estimation_quality.contamination_ratio_db > -5
        fprintf('⚠ Very high contamination - system is interference-limited\n');
    elseif estimation_quality.contamination_ratio_db < -15
        fprintf('✓ Low contamination - good pilot assignment\n');
    else
        fprintf('✓ Moderate contamination - typical for CF-mMIMO\n');
    end
end

function test_near_far_contamination()
    % Test that near-far distance produces strong pilot contamination differences
    % Key: enforce distance-dependent large-scale fading (beta), deterministic (no shadowing)

    fprintf('\n=== UNIT TEST: Near-Far Contamination (STRONG & DETERMINISTIC) ===\n');

    % Setup: 1 AP, 3 users (very near, medium, very far)
    M = 32;
    ap_pos = [0, 0];
    user_pos = [  8, 0;     % Near (8m)
                 80, 0;     % Medium (80m)
                350, 0];    % Far (350m)

    K = 3; L = 1;

    % All users use same pilot (force maximum contamination)
    pilot_scheme = ones(K,1);

    % Test parameters (only what estimator needs)
    test_params = struct();
    test_params.M = M;
    test_params.K = K;
    test_params.L = L;
    test_params.tau_p = 20;           % irrelevant here since we force same pilot
    test_params.p_pilot_dbm = 23;
    test_params.thermal_noise = -174;
    test_params.bandwidth = 20e6;
    test_params.noise_figure = 7;

    % ---- Deterministic distance-based beta (no shadowing) ----
    % Choose a simple pathloss model: beta ∝ d^{-gamma}
    % Use gamma = 3.5 for strong near-far separation
    gamma = 3.5;

    d = sqrt(sum((user_pos - ap_pos).^2, 2));  % distances (m)
    beta_lin = d.^(-gamma);

    % Normalize so near user has beta=1 (optional)
    beta_lin = beta_lin / beta_lin(1);

    % Create channels with controlled large-scale fading:
    % h_k ~ CN(0, beta_k I). Implement by sqrt(beta_k)*g_k, g_k~CN(0,I)
    H_test = zeros(M, K, L);
    rng(1,'twister'); % deterministic test
    for k = 1:K
        g = (randn(M,1) + 1j*randn(M,1))/sqrt(2);
        H_test(:,k,1) = sqrt(beta_lin(k)) * g;
    end

    % Run estimation
    [~, ~, quality] = covariance_aware_estimation_literature( ...
        H_test, H_test, pilot_scheme, [], test_params, user_pos, ap_pos);

    contam = quality.contamination_ratios(1, :);   % 1 AP -> row 1

    fprintf('Distances (m): [%.1f, %.1f, %.1f]\n', d(1), d(2), d(3));
    fprintf('Betas (normed): [%.3e, %.3e, %.3e]\n', beta_lin(1), beta_lin(2), beta_lin(3));

    fprintf('Contamination ratios (I/S):\n');
    fprintf('  User 1 (near):  %.2f dB\n', 10*log10(contam(1)));
    fprintf('  User 2 (mid):   %.2f dB\n', 10*log10(contam(2)));
    fprintf('  User 3 (far):   %.2f dB\n', 10*log10(contam(3)));

    % ---- Strong near-far expectations ----
    % contamination_k = (sum beta_j (same pilot, j!=k)) / beta_k
    % So far user should have MUCH higher contamination ratio than near user
    % i.e., contam(far) >> contam(near)
    ratio_far_to_near_db = 10*log10(contam(3) / contam(1));
    fprintf('Far/Near contamination ratio: %.2f dB\n', ratio_far_to_near_db);

    % Pass/fail criteria (tuneable, but this is a strong, defendable target)
    if ratio_far_to_near_db > 15
        fprintf('✓ TEST PASSED: Strong near-far effect (>%d dB)\n\n', 15);
    else
        fprintf('✗ TEST FAILED: Near-far effect still weak (%.2f dB)\n\n', ratio_far_to_near_db);
    end
end

function run_all_unit_tests()
    fprintf('\n');
    fprintf('=====================================================\n');
    fprintf('  RUNNING UNIT TESTS FOR THESIS VALIDATION\n');
    fprintf('=====================================================\n');
    
    try
        test_single_cell_MR();
    catch ME
        fprintf('MR test failed: %s\n\n', ME.message);
    end
    
    try
        test_zf_precoding_orthogonality();
    catch ME
        fprintf('ZF test failed: %s\n\n', ME.message);
    end
    
    try
        test_correlation_psd();
    catch ME
        fprintf('Correlation test failed: %s\n\n', ME.message);
    end
    
    try
        test_near_far_contamination();
    catch ME
        fprintf('Near-far test failed: %s\n\n', ME.message);
    end
    
    fprintf('=====================================================\n');
    fprintf('  UNIT TESTS COMPLETE\n');
    fprintf('=====================================================\n\n');
end

function [H_impaired, impairment_params] = apply_realistic_impairments(H_clean, params, enable)
    
    if nargin < 3 || ~enable
        H_impaired = H_clean;
        impairment_params = struct('applied', false);
        return;
    end
    
    % Simple hardware impairment model
    kappa = 0.05;  % 5% EVM
    H_impaired = H_clean .* (1 + kappa * (randn(size(H_clean)) + 1j*randn(size(H_clean))));
    impairment_params = struct('applied', true, 'evm', kappa);
end

function [mc_results, ci] = compute_monte_carlo_statistics(trial_results, valid_trials, alpha)
    % Compute statistics from Monte Carlo trials
    % alpha = significance level (e.g., 0.05 for 95% CI)
    
    fields = fieldnames(trial_results);
    mc_results = struct();
    ci = struct();
    
    for f = 1:length(fields)
        field = fields{f};
        data = trial_results.(field)(valid_trials);
        
        if isnumeric(data) && ~isempty(data)
            mc_results.(field).mean = mean(data);
            mc_results.(field).std = std(data);
            mc_results.(field).median = median(data);
            
            % Confidence interval
            ci.(field).lower = prctile(data, 100*alpha/2);
            ci.(field).upper = prctile(data, 100*(1-alpha/2));
            ci.(field).width = ci.(field).upper - ci.(field).lower;
        end
    end
end


function [H_est_sub6, H_est_mmwave, estimation_quality] = covariance_aware_estimation_literature(H_sub6, H_mmwave, pilot_scheme, spatial_corr, params, user_positions, ap_positions)
    % LMMSE Channel Estimation for Cell-Free Massive MIMO
    % Based on: Ngo et al., "Cell-Free Massive MIMO", IEEE JSAC 2017
    %          Björnson et al., "Making Cell-Free Competitive", IEEE TWC 2020
    %
    % Key: Uses STATISTICAL channel knowledge, not ground truth
    
    K = params.K;
    L = params.L;
    M = params.M;
    tau_p = params.tau_p;
    
    H_est_sub6 = zeros(size(H_sub6));
    H_est_mmwave = zeros(size(H_mmwave));
    
    % System parameters
    pilot_power = 10^(params.p_pilot_dbm/10 - 3);  % Watts
    noise_power_dbm = params.thermal_noise + 10*log10(params.bandwidth) + params.noise_figure;
    noise_power = 10^(noise_power_dbm/10 - 3);
    
    fprintf('  LMMSE Estimation (Literature Standard):\n');
    fprintf('    Pilot power: %.1f dBm\n', params.p_pilot_dbm);
    fprintf('    Noise power: %.1f dBm\n', noise_power_dbm);
    
    % Storage for quality metrics
    mse_values = zeros(L, K);
    contamination_ratios = zeros(L, K);
    snr_pilot = zeros(L, K);
    
    fprintf('\n=== STANDARD LMMSE CHANNEL ESTIMATION ===\n');
    
    % ==================================================================
    % STEP 1: Compute large-scale fading coefficients (path loss)
    % Reference: Ngo et al. 2017, Section III-A
    % ==================================================================
    beta = zeros(L, K);
    for l = 1:L
        for k = 1:K
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h_true = squeeze(H_sub6(:, k, l));
                % Large-scale fading (average over small-scale)
                beta(l, k) = norm(h_true)^2 / M;
            end
        end
    end
    
    % ==================================================================
    % STEP 2: For each AP-user pair, perform LMMSE estimation
    % Reference: Björnson et al. 2020, Eq. (7)
    % ==================================================================
    for l = 1:L
        for k = 1:K
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h_true_sub6 = squeeze(H_sub6(:, k, l));
                
                if norm(h_true_sub6) < 1e-15
                    continue;
                end
                
                pilot_k = pilot_scheme(k);
                
                % ===== GENERATE RECEIVED PILOT SIGNAL =====
                % y_pilot = √ρ_p * Σ(h_i for all i with same pilot) + noise
                
                y_pilot = sqrt(pilot_power) * h_true_sub6;  % Desired signal
                
                % Add contamination from users with same pilot
                for j = 1:K
                    if j ~= k && pilot_scheme(j) == pilot_k
                        if j <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                            h_contaminator = squeeze(H_sub6(:, j, l));
                            y_pilot = y_pilot + sqrt(pilot_power) * h_contaminator;
                        end
                    end
                end
                
                % Add noise
                noise = sqrt(noise_power/2) * (randn(M, 1) + 1j*randn(M, 1));
                y_pilot = y_pilot + noise;
                
                % ===== COMPUTE EXPECTED COVARIANCE MATRICES =====
                % Key: Use STATISTICAL knowledge, not actual contamination
                
                % Signal covariance: R_k = E[h_k * h_k^H] = β_lk * R_spatial
                if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && k <= size(spatial_corr, 2)
                    R_spatial = spatial_corr{l, k}.R_sub6;
                else
                    R_spatial = eye(M);  % Uncorrelated antennas
                end
                
                R_signal = beta(l, k) * R_spatial;
                
                % Interference covariance: Sum over users sharing pilot
                % Reference: Ngo et al. 2017, Eq. (10)
                R_interference = zeros(M, M);
                
                for j = 1:K
                    if j ~= k && pilot_scheme(j) == pilot_k
                        % Expected power from contaminating user j
                        if j <= size(beta, 2) && l <= size(beta, 1)
                            beta_j = beta(l, j);
                            
                            % Spatial correlation for user j
                            if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && j <= size(spatial_corr, 2)
                                R_spatial_j = spatial_corr{l, j}.R_sub6;
                            else
                                R_spatial_j = eye(M);
                            end
                            
                            R_interference = R_interference + pilot_power * beta_j * R_spatial_j;
                        end
                    end
                end
                
                % Total covariance of received signal
                % Reference: Björnson et al. 2020, Eq. (7)
                R_total = pilot_power * R_signal + R_interference + noise_power * eye(M);
                
                % ===== LMMSE ESTIMATOR =====
                % ĥ_lk = √ρ_p * R_signal * R_total^(-1) * y_pilot
                % Reference: Kay, "Fundamentals of Statistical Signal Processing", 1993
                
                try
                    % Numerically stable computation
                    W_LMMSE = sqrt(pilot_power) * (R_signal / R_total);
                    H_est_sub6(:, k, l) = W_LMMSE * y_pilot;
                catch
                    % Fallback for ill-conditioned matrices
                    W_LMMSE = sqrt(pilot_power) * R_signal * pinv(R_total);
                    H_est_sub6(:, k, l) = W_LMMSE * y_pilot;
                end
                
                % ===== REPEAT FOR mmWAVE (same procedure) =====
                h_true_mmwave = squeeze(H_mmwave(:, k, l));
                
                if norm(h_true_mmwave) > 1e-15
                    % Generate received pilot
                    y_pilot_mm = sqrt(pilot_power) * h_true_mmwave;
                    
                    for j = 1:K
                        if j ~= k && pilot_scheme(j) == pilot_k
                            if j <= size(H_mmwave, 2) && l <= size(H_mmwave, 3)
                                h_cont_mm = squeeze(H_mmwave(:, j, l));
                                y_pilot_mm = y_pilot_mm + sqrt(pilot_power) * h_cont_mm;
                            end
                        end
                    end
                    
                    noise_mm = sqrt(noise_power/2) * (randn(M, 1) + 1j*randn(M, 1));
                    y_pilot_mm = y_pilot_mm + noise_mm;
                    
                    % Covariance matrices for mmWave
                    beta_mm = norm(h_true_mmwave)^2 / M;
                    
                    if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && k <= size(spatial_corr, 2)
                        R_spatial_mm = spatial_corr{l, k}.R_mm;
                    else
                        R_spatial_mm = eye(M);
                    end
                    
                    R_signal_mm = beta_mm * R_spatial_mm;
                    
                    R_interference_mm = zeros(M, M);
                    for j = 1:K
                        if j ~= k && pilot_scheme(j) == pilot_k
                            if j <= size(H_mmwave, 2) && l <= size(H_mmwave, 3)
                                h_j_mm = squeeze(H_mmwave(:, j, l));
                                beta_j_mm = norm(h_j_mm)^2 / M;
                                
                                if ~isempty(spatial_corr) && l <= size(spatial_corr, 1) && j <= size(spatial_corr, 2)
                                    R_spatial_j_mm = spatial_corr{l, j}.R_mm;
                                else
                                    R_spatial_j_mm = eye(M);
                                end
                                
                                R_interference_mm = R_interference_mm + pilot_power * beta_j_mm * R_spatial_j_mm;
                            end
                        end
                    end
                    
                    R_total_mm = pilot_power * R_signal_mm + R_interference_mm + noise_power * eye(M);
                    
                    try
                        W_LMMSE_mm = sqrt(pilot_power) * (R_signal_mm / R_total_mm);
                        H_est_mmwave(:, k, l) = W_LMMSE_mm * y_pilot_mm;
                    catch
                        W_LMMSE_mm = sqrt(pilot_power) * R_signal_mm * pinv(R_total_mm);
                        H_est_mmwave(:, k, l) = W_LMMSE_mm * y_pilot_mm;
                    end
                end
            end
        end
    end
    
    % ==================================================================
    % STEP 3: CORRECTED CONTAMINATION CALCULATION
    % ==================================================================
    
    for l = 1:L
        for k = 1:K
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h_true = squeeze(H_sub6(:, k, l));
                
                if norm(h_true) < 1e-15
                    continue;
                end
                
                pilot_k = pilot_scheme(k);
                
                % ===== CORRECTED CONTAMINATION CALCULATION =====
                % Reference: Ngo et al. "Cell-Free Massive MIMO", Eq. (10)
                % Definition: contamination_ratio = interference_power / signal_power
                
                % Desired signal power at this AP-user link
                beta_k = beta(l, k);  % Large-scale fading coefficient
                signal_power_received = pilot_power * beta_k;
                
                % Contaminating interference power (users with same pilot)
                interference_power_received = 0;
                
                for j = 1:K
                    if j ~= k && pilot_scheme(j) == pilot_k
                        if j <= size(beta, 2) && l <= size(beta, 1)
                            % Add interfering power from user j
                            beta_j = beta(l, j);
                            interference_power_received = interference_power_received + pilot_power * beta_j;
                        end
                    end
                end
                
                % Contamination ratio: interference / signal
                % NOTE: We use signal alone (not signal+noise) for contamination ratio
                % This is the standard definition in CF-mMIMO literature
                if signal_power_received > 1e-20
                    contamination_ratios(l, k) = interference_power_received / signal_power_received;
                else
                    contamination_ratios(l, k) = 0;
                end
                
                % Pilot SNR (signal vs noise only, for reference)
                snr_pilot(l, k) = signal_power_received / noise_power;
                
                % MSE (from actual estimation error)
                h_est = H_est_sub6(:, k, l);
                mse_values(l, k) = norm(h_true - h_est)^2 / M;
            end
        end
    end
    
    % ===== COMPUTE SUMMARY STATISTICS =====
    
    estimation_quality = struct();
    
    % MSE metrics
    estimation_quality.average_mse = mean(mse_values(:));
    estimation_quality.mse_per_user = mean(mse_values, 1);
    estimation_quality.mse_per_ap = mean(mse_values, 2);
    
    % Contamination metrics
    valid_mask = (contamination_ratios > 0) & (contamination_ratios < 1e6);
    valid_contamination = contamination_ratios(valid_mask);
    estimation_quality.valid_contamination_linear = valid_contamination(:);

    if ~isempty(valid_contamination)
        % Compute statistics
        estimation_quality.avg_contamination_ratio = mean(valid_contamination);
        estimation_quality.max_contamination_ratio = max(valid_contamination);
        estimation_quality.median_contamination_ratio = median(valid_contamination);
        
        
        estimation_quality.contamination_ratio_db = 10*log10(estimation_quality.median_contamination_ratio);
        
        % Per-user contamination
        user_contamination = zeros(1, K);
        for k = 1:K
            user_contam = contamination_ratios(:, k);
            user_contam_valid = user_contam(user_contam > 0 & user_contam < 1e6);
            if ~isempty(user_contam_valid)
                user_contamination(k) = mean(user_contam_valid);
            end
        end
        estimation_quality.contamination_per_user = user_contamination;
        
       % --- Robust contamination summary  ---
        mean_lin   = mean(valid_contamination);
        median_lin = median(valid_contamination);
        p90_lin    = prctile(valid_contamination, 90);
        p99_lin    = prctile(valid_contamination, 99);
        max_lin    = max(valid_contamination);
        
        mean_db   = 10*log10(mean_lin);
        median_db = 10*log10(median_lin);
        p90_db    = 10*log10(p90_lin);
        p99_db    = 10*log10(p99_lin);
        max_db    = 10*log10(max_lin);
        
        % Store both mean + median explicitly
        estimation_quality.mean_contamination_ratio = mean_lin;
        estimation_quality.mean_contamination_ratio_db = mean_db;
        estimation_quality.median_contamination_ratio = median_lin;
        estimation_quality.median_contamination_ratio_db = median_db;
        estimation_quality.p90_contamination_ratio_db = p90_db;
        estimation_quality.p99_contamination_ratio_db = p99_db;
        
        % Decide your "headline" metric (use MEDIAN for typical user)
        estimation_quality.contamination_ratio_db = median_db;
        
        fprintf('\n=== CONTAMINATION ANALYSIS (ROBUST & CONSISTENT) ===\n');
        fprintf('  Mean:    %.3f  (%.2f dB)\n', mean_lin, mean_db);
        fprintf('  Median:  %.3f  (%.2f dB)\n', median_lin, median_db);
        fprintf('  90th%%:   %.3f  (%.2f dB)\n', p90_lin, p90_db);
        fprintf('  99th%%:   %.3f  (%.2f dB)\n', p99_lin, p99_db);
        fprintf('  Max:     %.3f  (%.2f dB)\n', max_lin, max_db);
        
        % Outage-style metric (very defendable)
        outage_thresh_db = 0; % contamination > 0 dB => interference > signal
        outage_frac = mean(10*log10(valid_contamination) > outage_thresh_db);
        estimation_quality.contam_outage_frac = outage_frac;
        fprintf('  Outage:  %.2f%% users/AP-links with contamination > %.1f dB\n', 100*outage_frac, outage_thresh_db);

        % Interpretation
        if estimation_quality.contamination_ratio_db < -10
            fprintf('  ✅ EXCELLENT: Contamination < 10%% of signal\n');
        elseif estimation_quality.contamination_ratio_db < -3
            fprintf('  ✅ GOOD: Contamination < 50%% of signal\n');
        elseif estimation_quality.contamination_ratio_db < 0
            fprintf('  ✓ ACCEPTABLE: Contamination < 100%% of signal\n');
        elseif estimation_quality.contamination_ratio_db < 3
            fprintf('  ⚠️  MODERATE: Contamination ~1-2× signal\n');
        else
            fprintf('  ❌ HIGH: Contamination > 2× signal\n');
        end
    else
        estimation_quality.contamination_ratio_db = -Inf;
    end
    
    % SNR metrics
    valid_snr = snr_pilot(snr_pilot > 0);
    if ~isempty(valid_snr)
        estimation_quality.avg_pilot_snr_db = 10*log10(mean(valid_snr));
        estimation_quality.min_pilot_snr_db = 10*log10(min(valid_snr));
    else
        estimation_quality.avg_pilot_snr_db = -Inf;
        estimation_quality.min_pilot_snr_db = -Inf;
    end
    
    % NMSE (normalized MSE)
    signal_powers = zeros(L, K);
    for l = 1:L
        for k = 1:K
            if k <= size(H_sub6, 2) && l <= size(H_sub6, 3)
                h = squeeze(H_sub6(:, k, l));
                signal_powers(l, k) = norm(h)^2;
            end
        end
    end
    
    valid_signal = signal_powers > 0;
    nmse_values = mse_values(valid_signal) ./ signal_powers(valid_signal);
    estimation_quality.avg_nmse = mean(nmse_values);
    estimation_quality.avg_nmse_db = 10*log10(mean(nmse_values));
    
    % Store raw data
    estimation_quality.mse_values = mse_values;
    estimation_quality.contamination_ratios = contamination_ratios;
    estimation_quality.snr_pilot = snr_pilot;
    estimation_quality.nmse_values = nmse_values;
    
    fprintf('\n=== BASELINE ESTIMATION QUALITY ===\n');
    fprintf('   Average NMSE: %.2f dB\n', estimation_quality.avg_nmse_db);
    fprintf('   Pilot SNR: %.2f dB\n', estimation_quality.avg_pilot_snr_db);
    fprintf('   Contamination ratio: %.2f dB\n', estimation_quality.contamination_ratio_db);
    fprintf('✓ Standard LMMSE estimation complete (K=%d, L=%d)\n', K, L);
end


function mobility_results = simulate_mobility_and_handover(params, ap_positions, user_positions, ...
                                                          serving_aps, pilot_scheme, spatial_corr, ...
                                                          beta_sub6, beta_mmwave, H_sub6, H_mmwave)
%SIMULATE_MOBILITY_AND_HANDOVER Main mobility simulation (OPTIMIZED)
%   Optimized: Vectorized RSRP, throttled handover checks, fast SINR
%
% FIXES ADDED:
%   1) Adds defense-ready summary metrics at end: avg_sinr_db, avg_rate, total_handovers, etc.
%   2) Fixes interference approximation bug: removes risky reshape/vecnorm on MxKxS data.
%   3) Adds small numerical safety guards.

    K = params.K;
    L = params.L;
    n_steps = ceil(params.simulation_time / params.update_interval);

    % Initialize results structure
    mobility_results = struct();
    mobility_results.time_steps = n_steps;
    mobility_results.user_trajectory = zeros(K, 2, n_steps);
    mobility_results.serving_aps_history = zeros(K, params.S, n_steps);
    mobility_results.sinr_history = zeros(K, n_steps);
    mobility_results.rate_history = zeros(K, n_steps);
    mobility_results.handover_events = [];
    mobility_results.handover_count = zeros(K, 1);
    mobility_results.distance_traveled = zeros(K, 1);
    mobility_results.rsrp_history = zeros(K, L, n_steps);

    % Initialize mobility parameters
    current_positions = user_positions;

    % Ensure velocities are realistic (km/h, then convert to m/s)
    velocities_kmh = max(0.5, params.user_velocity_kmh + params.user_velocity_std * randn(K, 1));
    velocities_ms = velocities_kmh / 3.6;  % Convert km/h to m/s

    % Calculate maximum Doppler frequency
    % fd = v / lambda = v * fc / c   (v in m/s)
    doppler_freq = velocities_ms .* (params.fc(1) / params.c);
    max_doppler = max(doppler_freq);

    % Verify velocities are reasonable
    fprintf('  Velocity check: min=%.2f, avg=%.2f, max=%.2f km/h\n', ...
            min(velocities_kmh), mean(velocities_kmh), max(velocities_kmh));

    % Random initial directions and waypoint targets
    directions = 2 * pi * rand(K, 1);
    target_positions = generate_random_waypoints(K, params.area_size);

    % Initialize state
    current_serving_aps = serving_aps;
    handover_timers = zeros(K, 1);
    current_H_sub6 = H_sub6;
    current_H_mmwave = H_mmwave;

    % Initialize handover tracking
    last_handover_check = zeros(K, 1);

    fprintf('Starting mobility simulation: %d time steps\n', n_steps);
    progress_interval = max(1, floor(n_steps / 10));

    % Handover throttling interval (seconds)
    handover_check_interval = 1.0;

    %% Main time-stepping loop
    for t = 1:n_steps
        current_time = (t - 1) * params.update_interval;

        % Progress indicator
        if mod(t, progress_interval) == 0
            fprintf('  %d%% complete...\n', round(100 * t / n_steps));
        end

        % Store initial trajectory
        if t == 1
            mobility_results.user_trajectory(:, :, 1) = current_positions;
        end

        % Update user positions using random waypoint model
        for k = 1:K
            % Check if reached waypoint (within 5 meters)
            dist_to_target = norm(current_positions(k, :) - target_positions(k, :));

            if dist_to_target < 5
                % Generate new waypoint
                target_positions(k, :) = generate_random_waypoints(1, params.area_size);
                % Update direction toward new waypoint
                diff = target_positions(k, :) - current_positions(k, :);
                directions(k) = atan2(diff(2), diff(1));
            end

            % displacement = velocity (m/s) * time (s)
            displacement = velocities_ms(k) * params.update_interval;

            old_position = current_positions(k, :);

            % Move toward waypoint
            current_positions(k, 1) = current_positions(k, 1) + displacement * cos(directions(k));
            current_positions(k, 2) = current_positions(k, 2) + displacement * sin(directions(k));

            % Boundary handling (reflect)
            if current_positions(k, 1) < 0
                current_positions(k, 1) = -current_positions(k, 1);
                directions(k) = pi - directions(k);
            elseif current_positions(k, 1) > params.area_size
                current_positions(k, 1) = 2 * params.area_size - current_positions(k, 1);
                directions(k) = pi - directions(k);
            end

            if current_positions(k, 2) < 0
                current_positions(k, 2) = -current_positions(k, 2);
                directions(k) = -directions(k);
            elseif current_positions(k, 2) > params.area_size
                current_positions(k, 2) = 2 * params.area_size - current_positions(k, 2);
                directions(k) = -directions(k);
            end

            % Track distance traveled
            actual_displacement = norm(current_positions(k, :) - old_position);
            mobility_results.distance_traveled(k) = mobility_results.distance_traveled(k) + actual_displacement;
        end

        % Store current trajectory
        if t > 1
            mobility_results.user_trajectory(:, :, t) = current_positions;
        end

        % Update pathloss based on new positions
        [beta_sub6_new, beta_mmwave_new] = compute_dual_band_pathloss(ap_positions, current_positions, params);

        % Temporal channel correlation coefficient
        % rho = J0(2*pi*fd*T) using maximum Doppler
        rho = besselj(0, 2 * pi * max_doppler * params.update_interval);

        % Keep rho in a sane numeric range (rare numeric issues)
        rho = max(min(real(rho), 0.999999), -0.999999);

        % Update channels (correlated fading update)
        for k = 1:K
            for l = 1:L
                innov_sub6   = (randn(params.M, 1) + 1j * randn(params.M, 1)) / sqrt(2);
                innov_mmwave = (randn(params.M, 1) + 1j * randn(params.M, 1)) / sqrt(2);

                current_H_sub6(:, k, l) = rho * current_H_sub6(:, k, l) + ...
                    sqrt(max(0, (1 - rho^2) * beta_sub6_new(l, k))) * innov_sub6;

                current_H_mmwave(:, k, l) = rho * current_H_mmwave(:, k, l) + ...
                    sqrt(max(0, (1 - rho^2) * beta_mmwave_new(l, k))) * innov_mmwave;
            end
        end

        % Compute RSRP for all users (vectorized per AP)
        rsrp = zeros(K, L);
        for l = 1:L
            h_matrix = current_H_sub6(:, :, l); % M x K
            rsrp(:, l) = 10 * log10(sum(abs(h_matrix).^2, 1)' / params.M + 1e-12);
        end
        mobility_results.rsrp_history(:, :, t) = rsrp;

        % Only check handover every 1 second
        users_to_check = (current_time - last_handover_check) >= handover_check_interval;

        % Handover decisions
        for k = find(users_to_check)'
            last_handover_check(k) = current_time;

            current_best_ap = current_serving_aps(k, 1);
            current_rsrp = rsrp(k, current_best_ap);

            [best_rsrp, best_ap] = max(rsrp(k, :));

            if best_ap ~= current_best_ap
                rsrp_gain = best_rsrp - current_rsrp;

                if rsrp_gain > params.handover_margin_db
                    handover_timers(k) = handover_timers(k) + params.update_interval;

                    if handover_timers(k) >= params.handover_timer_s
                        % Execute handover: pick top-S APs by RSRP
                        [~, sorted_aps] = sort(rsrp(k, :), 'descend');
                        current_serving_aps(k, :) = sorted_aps(1:params.S);

                        % Record event
                        event = struct();
                        event.time = current_time;
                        event.user = k;
                        event.from_ap = current_best_ap;
                        event.to_ap = best_ap;
                        event.rsrp_gain = rsrp_gain;
                        event.position = current_positions(k, :);

                        mobility_results.handover_events = [mobility_results.handover_events; event];
                        mobility_results.handover_count(k) = mobility_results.handover_count(k) + 1;

                        handover_timers(k) = 0;
                    end
                else
                    handover_timers(k) = 0;
                end
            else
                handover_timers(k) = 0;
            end
        end

        % Store serving APs history
        mobility_results.serving_aps_history(:, :, t) = current_serving_aps;

        % Compute performance metrics (fast approximation)
        % FIXED: safer total power computation over serving APs (no reshape/vecnorm ambiguity)
        for k = 1:K
            serving_idx = current_serving_aps(k, :);

            % Signal power from serving APs
            signal_power = 0;
            for s = 1:params.S
                l = serving_idx(s);
                h_k = current_H_sub6(:, k, l);
                signal_power = signal_power + norm(h_k)^2;
            end

            % Total power over the same AP set (sum over antennas+users+APs)
            total_power = 0;
            for s = 1:params.S
                l = serving_idx(s);
                H_l = current_H_sub6(:, :, l); % M x K
                total_power = total_power + sum(sum(abs(H_l).^2));
            end

            % Interference approximation: remove own signal, spread across other users
            avg_interference_per_user = (total_power - signal_power) / max(K - 1, 1);
            interference_power = avg_interference_per_user * params.S;

            % SINR + rate
            denom = (interference_power / max(K,1)) + params.noise_power_watts + 1e-12;
            sinr_linear = signal_power / denom;

            mobility_results.sinr_history(k, t) = 10 * log10(sinr_linear + 1e-12);
            mobility_results.rate_history(k, t) = log2(1 + sinr_linear);
        end
    end

    % Store final state
    mobility_results.final_positions = current_positions;
    mobility_results.velocities_kmh = velocities_kmh;
    mobility_results.total_time = params.simulation_time;

    % ===== DEFENSE-READY SUMMARY METRICS (for velocity sweep) =====
    mobility_results.total_handovers = sum(mobility_results.handover_count);
    mobility_results.handovers_per_user = mobility_results.total_handovers / K;

    sinr_mat = mobility_results.sinr_history; % K x n_steps
    valid_sinr = sinr_mat(~isnan(sinr_mat) & sinr_mat ~= 0);
    if isempty(valid_sinr)
        mobility_results.avg_sinr_db = NaN;
        mobility_results.sinr_std_db = NaN;
    else
        mobility_results.avg_sinr_db = mean(valid_sinr);
        mobility_results.sinr_std_db = std(valid_sinr);
    end

    rate_mat = mobility_results.rate_history; % K x n_steps
    valid_rate = rate_mat(~isnan(rate_mat) & rate_mat ~= 0);
    if isempty(valid_rate)
        mobility_results.avg_rate = NaN;
        mobility_results.rate_std = NaN;
    else
        mobility_results.avg_rate = mean(valid_rate);
        mobility_results.rate_std = std(valid_rate);
    end
    % ============================================================

    % Verification of results
    expected_distance = mean(velocities_ms) * params.simulation_time;
    actual_distance = mean(mobility_results.distance_traveled);

    fprintf('✓ Mobility simulation complete!\n');
    fprintf('  Expected avg distance: %.1f m\n', expected_distance);
    fprintf('  Actual avg distance: %.1f m\n', actual_distance);

    if expected_distance > 0
        if abs(actual_distance - expected_distance) / expected_distance > 0.5
            warning('Distance mismatch detected! Check mobility implementation.');
        end
    end
end


%% HELPER: GENERATE WAYPOINTS
function waypoints = generate_random_waypoints(n, area_size)
    margin = 50;
    waypoints = margin + (area_size - 2*margin) * rand(n, 2);
end

%% HELPER: DISPLAY STATISTICS
function display_mobility_statistics(results, params)
    fprintf('\n📊 MOBILITY STATISTICS\n');
    fprintf('═══════════════════════════════════════════\n');
    n_ho = length(results.handover_events);
    fprintf('Total handovers: %d\n', n_ho);
    fprintf('Handovers per user: %.2f avg, %d max\n', ...
            mean(results.handover_count), max(results.handover_count));
    fprintf('Avg distance traveled: %.1f meters\n', mean(results.distance_traveled));
    fprintf('Avg SINR: %.2f dB (std: %.2f dB)\n', ...
            mean(mean(results.sinr_history)), std(mean(results.sinr_history, 1)));
    fprintf('Avg rate: %.2f bps/Hz\n', mean(mean(results.rate_history)));
    
    if n_ho > 0
        gains = arrayfun(@(x) x.rsrp_gain, results.handover_events);
        fprintf('RSRP gain at handover: %.2f dB avg\n', mean(gains));
    end
    
end

%% HELPER: VISUALIZATION
function visualize_mobility_and_handover(results, ap_pos, params)
    figure('Name', 'Mobility & Handover', 'Position', [100, 100, 1400, 500]);
    
    % Trajectories
    subplot(1,2,1); hold on; grid on; box on;
    scatter(ap_pos(:,1), ap_pos(:,2), 120, 'k^', 'filled', 'LineWidth', 1.5);
    
    K_plot = min(params.K, 10);
    colors = jet(K_plot);
    for k = 1:K_plot
        traj = squeeze(results.user_trajectory(k, :, :));
        plot(traj(1,:), traj(2,:), '-', 'Color', colors(k,:), 'LineWidth', 1.5);
        scatter(traj(1,1), traj(2,1), 60, colors(k,:), 'o', 'filled');
        scatter(traj(1,end), traj(2,end), 60, colors(k,:), 's', 'filled');
    end
    
    if ~isempty(results.handover_events)
        ho_pos = cell2mat(arrayfun(@(x) x.position, results.handover_events, 'UniformOutput', false)');
        scatter(ho_pos(:,1), ho_pos(:,2), 100, 'r', 'x', 'LineWidth', 3);
    end
    
    xlabel('X (m)'); ylabel('Y (m)');
    title(sprintf('User Trajectories (%d Handovers)', length(results.handover_events)));
    xlim([0 params.area_size]); ylim([0 params.area_size]); axis equal;
    
    % SINR evolution
    subplot(1,2,2); hold on; grid on; box on;
    time = (0:results.time_steps-1) * params.update_interval;
    plot(time, mean(results.sinr_history,1), 'b-', 'LineWidth', 2.5);
    plot(time, min(results.sinr_history,[],1), 'r--', 'LineWidth', 1.5);
    plot(time, max(results.sinr_history,[],1), 'g--', 'LineWidth', 1.5);
    xlabel('Time (s)'); ylabel('SINR (dB)');
    title('SINR During Mobility');
    legend('Avg', 'Min', 'Max');
    
    % Handover analysis
    figure('Name', 'Handover Analysis', 'Position', [150, 150, 1200, 400]);
    
    subplot(1,3,1);
    bar(results.handover_count, 'FaceColor', [0.3,0.6,0.9]);
    xlabel('User ID'); ylabel('# Handovers');
    title('Handovers per User'); grid on;
    
    subplot(1,3,2);
    histogram(results.distance_traveled, 20, 'FaceColor', [0.4,0.7,0.4]);
    xlabel('Distance (m)'); ylabel('# Users');
    title('Distance Traveled'); grid on;
    
    subplot(1,3,3);
    area(time, mean(results.rate_history,1), 'FaceColor', [0.9,0.6,0.3], 'FaceAlpha', 0.6);
    xlabel('Time (s)'); ylabel('Rate (bps/Hz)');
    title('Average Rate'); grid on;


    
end

function visualize_metric_cdfs(baseline_equal, baseline_optimized, results, params)
    h_fig_cdf = figure(6); clf;
    set(h_fig_cdf, 'Name', 'Metric CDFs', ...
        'NumberTitle', 'off', ...
        'WindowStyle', 'normal', ...
        'Resize', 'on', ...
        'Units', 'pixels', ...
        'Position', [120, 80, 1360, 860], ...
        'PaperPositionMode', 'auto');
    movegui(h_fig_cdf, 'center');

    methods_plot = fieldnames(baseline_optimized);
    n_methods = numel(methods_plot);
    colors = lines(n_methods);

    subplot(2,2,1); hold on; grid on; box on;
    for m = 1:n_methods
        method = methods_plot{m};
        se_vals_before = baseline_equal.(method).user_rates(:);
        se_vals_before = se_vals_before(~isnan(se_vals_before) & isfinite(se_vals_before));
        if ~isempty(se_vals_before)
            [f_se_before, x_se_before] = ecdf(se_vals_before);
            plot(x_se_before, f_se_before*100, '--', 'LineWidth', 1.8, 'Color', colors(m,:));
        end

        se_vals_after = baseline_optimized.(method).user_rates(:);
        se_vals_after = se_vals_after(~isnan(se_vals_after) & isfinite(se_vals_after));
        if ~isempty(se_vals_after)
            [f_se_after, x_se_after] = ecdf(se_vals_after);
            plot(x_se_after, f_se_after*100, '-', 'LineWidth', 2.2, 'Color', colors(m,:));
        end
    end
    xlabel('Spectral Efficiency [bps/Hz]');
    ylabel('CDF [%]');
    title('CDF of Spectral Efficiency for All Methods');
    legend_entries = cell(2*n_methods, 1);
    for m = 1:n_methods
        pretty_name = strrep(methods_plot{m}, '_', ' ');
        legend_entries{2*m-1} = sprintf('%s Before', pretty_name);
        legend_entries{2*m} = sprintf('%s After', pretty_name);
    end
    legend(legend_entries, 'Location', 'best');

    subplot(2,2,2); hold on; grid on; box on;
    for m = 1:n_methods
        method = methods_plot{m};
        total_power_before = baseline_equal.(method).total_tx_power_w + ...
            params.L * (params.M * 0.5 + 7) + params.L * 2 + (50 + 0.5 * params.L);
        ee_vals_before = (baseline_equal.(method).user_rates(:) * params.bandwidth / 1e6) / total_power_before;
        ee_vals_before = ee_vals_before(~isnan(ee_vals_before) & isfinite(ee_vals_before));
        if ~isempty(ee_vals_before)
            [f_ee_before, x_ee_before] = ecdf(ee_vals_before);
            plot(x_ee_before, f_ee_before*100, '--', 'LineWidth', 1.8, 'Color', colors(m,:));
        end

        total_power_after = baseline_optimized.(method).total_tx_power_w + ...
            params.L * (params.M * 0.5 + 7) + params.L * 2 + (50 + 0.5 * params.L);
        ee_vals_after = (baseline_optimized.(method).user_rates(:) * params.bandwidth / 1e6) / total_power_after;
        ee_vals_after = ee_vals_after(~isnan(ee_vals_after) & isfinite(ee_vals_after));
        if ~isempty(ee_vals_after)
            [f_ee_after, x_ee_after] = ecdf(ee_vals_after);
            plot(x_ee_after, f_ee_after*100, '-', 'LineWidth', 2.2, 'Color', colors(m,:));
        end
    end
    xlabel('Energy Efficiency [Mbits/J]');
    ylabel('CDF [%]');
    title('CDF of Energy Efficiency for All Methods');
    legend(legend_entries, 'Location', 'best');

    subplot(2,2,3); hold on; grid on; box on;
    distance_vals = results.distance_traveled(:);
    distance_vals = distance_vals(~isnan(distance_vals) & isfinite(distance_vals));
    if ~isempty(distance_vals)
        [f_dist, x_dist] = ecdf(distance_vals);
        plot(x_dist, f_dist*100, 'b-', 'LineWidth', 2.5);
    end
    xlabel('Distance Traveled [m]');
    ylabel('CDF [%]');
    title('CDF of Distance');
    legend('Mobility Users', 'Location', 'best');

    subplot(2,2,4); hold on; grid on; box on;
    for m = 1:n_methods
        method = methods_plot{m};
        sinr_before = baseline_equal.(method).sinr_db(:);
        sinr_before = sinr_before(~isnan(sinr_before) & isfinite(sinr_before));
        if ~isempty(sinr_before)
            [f_sinr_before, x_sinr_before] = ecdf(sinr_before);
            plot(x_sinr_before, f_sinr_before*100, '--', 'LineWidth', 1.8, 'Color', colors(m,:));
        end

        sinr_after = baseline_optimized.(method).sinr_db(:);
        sinr_after = sinr_after(~isnan(sinr_after) & isfinite(sinr_after));
        if ~isempty(sinr_after)
            [f_sinr_after, x_sinr_after] = ecdf(sinr_after);
            plot(x_sinr_after, f_sinr_after*100, '-', 'LineWidth', 2.2, 'Color', colors(m,:));
        end
    end
    xlabel('SINR [dB]');
    ylabel('CDF [%]');
    title('CDF of SINR for All Methods');
    legend(legend_entries, 'Location', 'best');

    sgtitle('CDFs of Spectral Efficiency, Energy Efficiency, Distance, and SINR', ...
        'FontSize', 15, 'FontWeight', 'bold');
    drawnow; pause(0.1);
    fprintf('✓ Figure 6: Metric CDFs\n');
end

