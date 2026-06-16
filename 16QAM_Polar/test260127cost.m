% TEST260127COST - Energy-Information cost function simulation
% Usage:
%   test260127cost
%
% Notes:
% - Uses cost(p) = -(G(p)-G(p0)) / (E(p)-E(p0)), E(p) > E(p0)
% - G(p) = R_total(p) * (1 - BER(p, SNR))
% - BER is simulated on a coarse p grid using get_16test_customSNR
%   and interpolated over dense p_candidates.

clear; clc;

%% Parameters
N = 1024;

% 使用的 p 网格：不再使用 dense p_candidates，改为直接使用 coarse p_ber
% 后面会对 p 方向进行样条插值得到平滑曲线（p_fine）
p1 = 0.5;
p3 = 0.5;

% Ensure ShapedPolarS is on MATLAB path for get_16test_customSNR dependencies
addpath(fullfile(pwd, 'ShapedPolarS'));

snr_targets = 4:2:16;
use_ideal_high_snr = true;  % set true to ignore BER at sufficiently high SNR
snr_high = 15;              % threshold where BER is assumed negligible

% Coarse p grid for BER simulation（作为唯一的 p 集合）
p_ber = [0.1, 0.16, 0.21, 0.3, 0.5];

% 为兼容早期代码，保留 p_candidates 但让它等于 p_ber（不再有密集候选集合）
p_candidates = p_ber;

%% Compute theory metrics over p_ber (coarse grid)
numP = numel(p_candidates);
R_total = zeros(numP,1);
E_sym = zeros(numP,1);

for idx = 1:numP
    p = p_candidates(idx);
    p2 = p;
    p4 = p;

    K1 = polar_info_count(N, p1);
    K2 = polar_info_count(N, p2);
    K3 = polar_info_count(N, p3);
    K4 = polar_info_count(N, p4);

    K_total = K1 + K2 + K3 + K4;
    R_total(idx) = K_total / (4 * N);
    E_sym(idx) = expected_symbol_energy([p1, p2, p3, p4]);
end

% 构造平滑 p 网格用于绘图（样条插值）
p_fine = linspace(min(p_candidates), max(p_candidates), 200);
R_total_fine = interp1(p_candidates, R_total, p_fine, 'spline');
E_sym_fine = interp1(p_candidates, E_sym, p_fine, 'spline');

%% Load or build BER cache (exact SNR targets)
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
            % 如果缓存中含有 spow，则加载；否则稍后用默认值覆盖
            if isfield(s, 'spow')
                spow = s.spow;
            end
            rebuild_cache = false;
        end
    end
end

if rebuild_cache
    ber_cache = zeros(numel(p_ber), numel(snr_targets));
    snr_vec = snr_targets;
    for ip = 1:numel(p_ber)
        [BER, ~, ~] = get_16test_customSNR(p_ber(ip), snr_targets);
        ber_cache(ip, :) = BER;
    end
    
    % 定义固定的 spow，对应于 p_ber（从小到大，最后一个对应 p=0.5）
    spow = [1.4, 1.3, 1.2, 1.1, 1.0];
    save(cacheFile, 'ber_cache', 'snr_vec', 'p_ber', 'spow');
end

%% Plot cost curves (single figure with subplots)
figure('Name', 'Cost function vs p (SNR = 6:2:12 dB)', 'NumberTitle', 'off');
cols = 5;
rows = ceil(numel(snr_targets) / cols);

p0 = 0.5;
% baseline 在平滑网格上定位
idx0 = find(abs(p_fine - p0) < 1e-9, 1);
if isempty(idx0)
    error('Baseline p0=0.5 not found in p_fine');
end

for si = 1:numel(snr_targets)
    snr0 = snr_targets(si);
    [~, snr_idx] = min(abs(snr_vec - snr0));

    % 在平滑 p 网格上对 BER 进行样条插值
    ber_p = interp1(p_ber, ber_cache(:, snr_idx), p_fine, 'spline', 'extrap');
    ber_p = max(min(ber_p, 1), 0);

    if use_ideal_high_snr && snr0 >= snr_high
        % High-SNR approximation: BER ~ 0, Goodput dominated by rate loss
        G = R_total_fine(:);
    else
        G = R_total_fine(:) .* (1 - ber_p(:));
    end
    E = E_sym_fine(:);

    G0 = G(idx0);
    E0 = E(idx0);

    cost = nan(size(p_fine));
    denom = (E - E0);
    valid = denom > 0;
    cost(valid) = -(G(valid) - G0) ./ denom(valid);

    subplot(rows, cols, si);
    plot(p_fine, cost, 'LineWidth', 1.6);
    xlabel('p');
    ylabel('cost(p)');
    title(sprintf('SNR = %.1f dB', snr0));
    grid on
end

%% Plot BER and Goodput vs SNR for different p values
figure('Name', 'BER and Goodput vs SNR', 'NumberTitle', 'off');

% Select representative p values to plot
p_plot = [0.1, 0.16, 0.21, 0.3, 0.5];
colors = lines(numel(p_plot));

% Subplot 1: BER vs SNR
subplot(1, 2, 1);
hold on;
snr_fine = linspace(min(snr_vec), max(snr_vec), 200);
for ip = 1:numel(p_plot)
    p = p_plot(ip);
    % spline interpolation over SNR for smooth BER curves
    ber_interp = interp1(snr_vec, ber_cache(ip, :), snr_fine, 'spline');
    ber_interp = max(min(ber_interp, 1), 0);
    plot(snr_fine, ber_interp, '-', 'LineWidth', 1.8, 'Color', colors(ip, :), ...
         'DisplayName', sprintf('p = %.2f', p));
    % overlay original samples as markers for reference
    plot(snr_vec, ber_cache(ip, :), 'o', 'Color', colors(ip, :), 'MarkerFaceColor', colors(ip, :));
end
hold off;
set(gca, 'YScale', 'log');
xlabel('SNR (dB)', 'FontSize', 11);
ylabel('BER', 'FontSize', 11);
title('BER vs SNR for Different p', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('Location', 'best');

% Subplot 2: Goodput vs SNR
subplot(1, 2, 2);
hold on;
snr_fine = linspace(min(snr_vec), max(snr_vec), 200);  % Fine SNR grid for smooth curves

for ip = 1:numel(p_plot)
    p = p_plot(ip);
    [~, idx_p] = min(abs(p_candidates - p));
    
    % Interpolate BER for smooth curve
    ber_interp = interp1(snr_vec, ber_cache(ip, :), snr_fine, 'spline');
    ber_interp = max(min(ber_interp, 1), 0);  % Clamp to [0,1]
    
    % Compute goodput on fine SNR grid
    goodput_fine = zeros(1, numel(snr_fine));
    R_p = R_total(idx_p);
    
    for si = 1:numel(snr_fine)
        snr0 = snr_fine(si);
        ber0 = ber_interp(si);
        
        if use_ideal_high_snr && snr0 >= snr_high
            goodput_fine(si) = R_p;
        else
            goodput_fine(si) = R_p * (1 - ber0);
        end
    end
    
    plot(snr_fine, goodput_fine, '-', 'LineWidth', 2, 'Color', colors(ip, :), ...
         'DisplayName', sprintf('p = %.2f', p));
end
hold off;
xlabel('SNR (dB)', 'FontSize', 11);
ylabel('Goodput (bits/symbol)', 'FontSize', 11);
title('Goodput vs SNR for Different p', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('Location', 'best');


%% Local functions
function K = polar_info_count(N, p)
%POLAR_INFO_COUNT Compute information bits K for one bit level.
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
    bits = dec2bin(0:M-1, 4) - '0';
    sym = qammod(bits, M, 'gray', 'InputType', 'bit', 'UnitAveragePower', true);
    prob = prod(bits .* p_vec + (1 - bits) .* (1 - p_vec), 2);
    sym = sym(:);
    prob = prob(:);
    E = sum(prob .* (abs(sym).^2));
end
