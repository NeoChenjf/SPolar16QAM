% TEST260127 Theoretical goodput and constellation energy vs shaping p (16QAM Gray)
% Usage:
%   test260127
%
% Notes:
% - Matches the bit-level shaping pattern used in get_16test.m:
%   p1 = 0.5, p2 = p, p3 = 0.5, p4 = p
% - Goodput here is the ideal rate (BER=0) for theory-only comparison.
% - Constellation energy is computed using qammod with UnitAveragePower=true,
%   then weighted by the non-uniform bit probabilities.

clear; clc;

%% Parameters
N = 1024;

% 使用离散 p 网格（与其他脚本保持一致）
p_ber = [0.1, 0.16, 0.21, 0.3, 0.5];
p_candidates = p_ber; % 兼容旧变量名

p1 = 0.5;
p3 = 0.5;

% Ensure ShapedPolarS is on MATLAB path for get_16test dependencies
addpath(fullfile(pwd, 'ShapedPolarS'));

%% Sweep p and compute theory metrics
numP = numel(p_candidates);
K1_vec = zeros(numP,1);
K2_vec = zeros(numP,1);
K3_vec = zeros(numP,1);
K4_vec = zeros(numP,1);
R_total = zeros(numP,1);
Goodput_ideal = zeros(numP,1);
E_sym = zeros(numP,1);

for idx = 1:numP
    p = p_candidates(idx);
    p2 = p;
    p4 = p;

    [K1, ~] = polar_info_count(N, p1);
    [K2, ~] = polar_info_count(N, p2);
    [K3, ~] = polar_info_count(N, p3);
    [K4, ~] = polar_info_count(N, p4);

    K1_vec(idx) = K1;
    K2_vec(idx) = K2;
    K3_vec(idx) = K3;
    K4_vec(idx) = K4;

    K_total = K1 + K2 + K3 + K4;
    R_total(idx) = K_total / (4 * N);

    % Ideal Goodput (BER = 0)
    Goodput_ideal(idx) = R_total(idx);

    % Expected symbol energy under non-uniform bits
    E_sym(idx) = expected_symbol_energy([p1, p2, p3, p4]);
end

%% Weighted-sum objective (normalized) with alpha sweep
% Uses BER(p,SNR) to compute G(p) = R_total*(1-BER), then normalizes G and E
% to [0,1] before applying the weighted sum.
%
% NOTE: BER is estimated by running get_16test on a coarse p grid
% covering all target SNRs, then interpolating over p as needed.

% Use same SNR grid as test260127cost
snr_targets = 4:2:16;
alpha_grid = 0:0.1:1;
alpha_single = 0.8;
use_ideal_high_snr = true;  % set true to ignore BER at sufficiently high SNR
snr_high = 15;              % threshold where BER is assumed negligible

% Coarse p grid for BER simulation (matches existing study points)
% p_ber already defined above

% Load or build BER cache (exact SNR targets)
outDir = fullfile('results');
if ~exist(outDir,'dir')
    mkdir(outDir);
end
cacheFile = fullfile(outDir, 'ber_cache_pcoarse.mat');

rebuild_cache = true;
if exist(cacheFile, 'file')
    s = load(cacheFile);
    if isfield(s, 'snr_vec') && isfield(s, 'p_ber') && isfield(s, 'ber_cache')
        if isequal(s.snr_vec(:).', snr_targets) && isequal(s.p_ber(:).', p_ber)
            ber_cache = s.ber_cache;
            snr_vec = s.snr_vec;
            rebuild_cache = false;
        end
    end
end

if rebuild_cache
    ber_cache = zeros(numel(p_ber), numel(snr_targets));
    snr_vec = snr_targets;
    for ip = 1:numel(p_ber)
        % 使用项目内原始接口 get_16test（支持向量 SNR）
        [BER, ~, ~] = get_16test(p_ber(ip), snr_targets);
        ber_cache(ip, :) = BER;
    end
    % 固定 spow 与 p_ber 一一对应（从小到大），最后一个对应 p=0.5
    spow = [1.4, 1.3, 1.2, 1.1, 1.0];
    save(cacheFile, 'ber_cache', 'snr_vec', 'p_ber', 'spow');
end

% 为平滑绘图准备 p_fine
p_fine = linspace(min(p_candidates), max(p_candidates), 200);

% For each target SNR, build objective curves (single figure with subplots)
figure('Name', 'Weighted objective vs p (multiple SNRs)', 'NumberTitle', 'off');
numS = numel(snr_targets);
cols = 3;                 % desired columns
rows = ceil(numS / cols); % compute rows to fit all subplots

for si = 1:numel(snr_targets)
    snr0 = snr_targets(si);
    [~, snr_idx] = min(abs(snr_vec - snr0));

    % Interpolate BER to dense p grid
    ber_p = interp1(p_ber, ber_cache(:, snr_idx), p_candidates, 'pchip', 'extrap');
    ber_p = max(min(ber_p, 1), 0); % clamp to [0,1]

    if use_ideal_high_snr && snr0 >= snr_high
        G = R_total(:);
    else
        G = R_total(:) .* (1 - ber_p(:));
    end
    E = E_sym(:);

    % Normalize to [0,1]
    G_norm = (G - min(G)) / (max(G) - min(G) + eps);
    E_norm = (E - min(E)) / (max(E) - min(E) + eps);

    subplot(rows, cols, si);
    hold on
    % only plot alpha = 0 and alpha = 1 for the first figure
    alpha_plot = [0, 1];
    styles = lines(numel(alpha_plot));
    for ai = 1:numel(alpha_plot)
        a = alpha_plot(ai);
        J = a * G_norm + (1 - a) * E_norm;
        % interpolate J over p_fine for smooth curve
        J_fine = interp1(p_candidates, J, p_fine, 'spline');
        plot(p_fine, J_fine, 'LineWidth', 1.6, 'Color', styles(ai, :));
    end
    hold off
    xlabel('p');
    ylabel('J(p) = \alpha * G_{tilde}(p) + (1-\alpha) * E_{tilde}(p)');
    title(sprintf('SNR = %.1f dB', snr0));
    if si == 1
        legend(arrayfun(@(a) sprintf('\\alpha=%.0f', a), alpha_plot, 'UniformOutput', false), ...
               'Location', 'best');
    end
    grid on
end

% Second figure: alpha fixed at 0.5
figure('Name', sprintf('Weighted objective vs p (alpha = %.1f)', alpha_single), 'NumberTitle', 'off');
for si = 1:numel(snr_targets)
    snr0 = snr_targets(si);
    [~, snr_idx] = min(abs(snr_vec - snr0));

    ber_p = interp1(p_ber, ber_cache(:, snr_idx), p_candidates, 'pchip', 'extrap');
    ber_p = max(min(ber_p, 1), 0);

    if use_ideal_high_snr && snr0 >= snr_high
        G = R_total(:);
    else
        G = R_total(:) .* (1 - ber_p(:));
    end
    E = E_sym(:);

    G_norm = (G - min(G)) / (max(G) - min(G) + eps);
    E_norm = (E - min(E)) / (max(E) - min(E) + eps);

    J = alpha_single * G_norm + (1 - alpha_single) * E_norm;

    subplot(rows, cols, si);
    % smooth J over p_fine
    J_fine_single = interp1(p_candidates, J, p_fine, 'spline');
    plot(p_fine, J_fine_single, 'LineWidth', 1.6);
    xlabel('p');
    ylabel(sprintf('J(p) = %.1f * G_{tilde}(p) + %.1f * E_{tilde}(p)', alpha_single, 1 - alpha_single));
    title(sprintf('SNR = %.1f dB', snr0));
    grid on
end

%% Table output (kept for reference; uncomment if needed)
% T = table(p_candidates(:), K1_vec, K2_vec, K3_vec, K4_vec, R_total, Goodput_ideal, E_sym, ...
%     'VariableNames', {'p','K1','K2','K3','K4','R_total','Goodput_ideal','E_sym'});
% disp(T);
%
% %% Optional save
% timestamp = datestr(now, 'yyyymmdd_HHMMSS');
% baseName = ['theory_p_sweep_' timestamp];
% matFile = fullfile(outDir, [baseName '.mat']);
% csvFile = fullfile(outDir, [baseName '.csv']);
% save(matFile, 'T');
% try
%     writetable(T, csvFile);
% catch
%     warning('writetable failed; MAT file saved at %s', matFile);
% end


%% Local functions
function [K, S_size] = polar_info_count(N, p)
%POLAR_INFO_COUNT Compute shaping size S and information bits K for one bit level.
    H = binary_entropy(p);
    S_size = ceil(N * (1 - H));
    K = ceil((N - S_size) / 2);
end

function H = binary_entropy(p)
%BINARY_ENTROPY Binary entropy H(p) in bits, with edge handling.
    if p <= 0 || p >= 1
        H = 0;
        return;
    end
    H = -p * log2(p) - (1 - p) * log2(1 - p);
end

function E = expected_symbol_energy(p_vec)
%EXPECTED_SYMBOL_ENERGY Expected |s|^2 for 16QAM Gray with non-uniform bits.
    M = 16;
    bits = dec2bin(0:M-1, 4) - '0'; % 16x4
    sym = qammod(bits, M, 'gray', 'InputType', 'bit', 'UnitAveragePower', true);
    prob = prod(bits .* p_vec + (1 - bits) .* (1 - p_vec), 2);
    sym = sym(:);
    prob = prob(:);
    E = sum(prob .* (abs(sym).^2));
end
