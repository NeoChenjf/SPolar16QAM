%% RUN_OFDM_BASELINE_DENSE
% Stage B / B1: paper-facing dense AWGN OFDM baseline.
%
% This wrapper reuses run_ofdm_baseline.m with a 1 dB SNR grid.
% It is a Monte Carlo run; execute locally when ready.

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));

ofdm_baseline_overrides = struct();
ofdm_baseline_overrides.p_list = [0.5, 0.3, 0.1];
ofdm_baseline_overrides.snr_grid = 8:1:20;
ofdm_baseline_overrides.n_subcarriers = 64;
ofdm_baseline_overrides.cp_ratio = 1/4;
ofdm_baseline_overrides.channel_model = 'AWGN';
ofdm_baseline_overrides.num_frames = 100;
ofdm_baseline_overrides.seed = 42;
ofdm_baseline_overrides.result_tag = 'ofdm_baseline_dense';
ofdm_baseline_overrides.run_command = ...
    'cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/multicarrier/run_ofdm_baseline_dense.m'');';

run(fullfile(script_dir, 'run_ofdm_baseline.m'));
