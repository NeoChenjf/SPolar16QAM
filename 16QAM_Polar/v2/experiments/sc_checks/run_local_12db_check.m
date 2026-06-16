%% RUN_LOCAL_12DB_CHECK
% 目的：在“编码侧口径”下验证 12 dB 局部偏差（GA理论 vs BPSK+SC仿真）
% 输出：统一保存到 results/时间戳目录（csv + fig + png + pdf + README）

clear; clc; close all;
setup_paths();

cfg = config();

%% ===== 实验配置（与 run_sc_theory_vs_sim 同口径） =====
p = 0.5;
snr_grid = 11:0.5:13;      % 覆盖12dB附近
n_rep = 3;                 % 重复次数（误差条）

num_frames_min = 200;
num_frames_max = 1200;
min_total_bit_errors = 100;

cfg.decoder = 'SC';

opts = struct();
opts.disable_geom = true;  % 编码侧口径，和 run_sc_theory_vs_sim 一致
opts.pe_floor = 1e-12;
opts.alpha_rel = 1.0;
opts.code_high_eta = 0.8;
opts.code_high_mid_db = 14.0;
opts.code_high_slope_db = 2.0;

%% ===== 输出目录 =====
run_tag = [datestr(now, 'yyyymmdd_HHMMSS') '_local_12db_check'];
out_dir = fullfile(cfg.output_dir, run_tag);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

fprintf('\n[local_12db_check] 输出目录: %s\n', out_dir);

%% ===== 理论曲线（编码侧） =====
model = estimate_ber_hat_sc_dual(p, snr_grid, cfg, opts);
ber_theory = model.BER_hat(:);

%% ===== 仿真曲线（编码侧：BPSK+SC） =====
nS = numel(snr_grid);
ber_sim_rep = zeros(nS, n_rep);

N = cfg.N;
lambda_offset = 2.^(0:log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);

for ir = 1:n_rep
    rng(20260421 + 100 * ir, 'twister');
    fprintf('\n[Rep %d/%d]\n', ir, n_rep);

    for is = 1:nS
        snr_db = snr_grid(is);
        sigma = 10^(-snr_db / 20);

        channels = GA(sigma, N);
        [~, channels_ordered] = sort(channels, 'descend');

        % p=0.5 时四路一致（保留通用写法）
        p_vec_cur = cfg.p_fixed;
        p_vec_cur(isnan(p_vec_cur)) = p;

        K_vec = zeros(1, 4);
        S_vec = zeros(1, 4);
        SI_set = cell(1, 4);
        I_set = cell(1, 4);
        S_set = cell(1, 4);
        frozen_bits_dec = zeros(N, 4);
        shaped_bits = cell(1, 4);

        for b = 1:4
            pb = p_vec_cur(b);
            if pb > 0 && pb < 1
                hb = -pb * log2(pb) - (1 - pb) * log2(1 - pb);
            else
                hb = 0;
            end

            S_vec(b) = ceil(N * (1 - hb));
            K_vec(b) = ceil((N - S_vec(b)) / 2);

            I_pos = channels_ordered(S_vec(b) + 1 : S_vec(b) + K_vec(b));
            S_pos = channels_ordered(1 : S_vec(b));

            I_set{b} = sort(I_pos);
            S_set{b} = sort(S_pos);
            SI_set{b} = sort(channels_ordered(1 : S_vec(b) + K_vec(b)));

            frozen_bits_dec(:, b) = ones(N, 1);
            frozen_bits_dec(SI_set{b}, b) = 0;
            shaped_bits{b} = randsrc(S_vec(b), 1, [0 1; 0.5 0.5]);
        end

        bit_err_acc = zeros(4, 1);
        total_frames = 0;

        while true
            total_frames = total_frames + 1;

            for b = 1:4
                info = randi([0, 1], K_vec(b), 1);
                u = zeros(N, 1);
                u(I_set{b}) = info;
                u(S_set{b}) = shaped_bits{b};

                x = polar_encoder(u);
                tx = 1 - 2 * x;
                y = tx + sigma * randn(N, 1);
                llr = 2 * y / max(sigma^2, eps);

                decoded = SC_decoder(llr, K_vec(b) + S_vec(b), frozen_bits_dec(:, b), ...
                    lambda_offset, llr_layer_vec, bit_layer_vec);

                u_hat = zeros(N, 1);
                u_hat(SI_set{b}) = decoded;
                info_hat = u_hat(I_set{b});

                bit_err_acc(b) = bit_err_acc(b) + sum(info_hat ~= info);
            end

            total_err_now = sum(bit_err_acc);
            if (total_frames >= num_frames_min && total_err_now >= min_total_bit_errors) || ...
                    (total_frames >= num_frames_max)
                break;
            end
        end

        ber_per_bit = zeros(4, 1);
        for b = 1:4
            ber_per_bit(b) = bit_err_acc(b) / max(K_vec(b) * total_frames, 1);
        end
        ber_sim_rep(is, ir) = sum(K_vec(:) .* ber_per_bit(:)) / max(sum(K_vec), 1);

        fprintf('  SNR=%+5.1f dB | BER_sim=%.3e | BER_theory=%.3e | frames=%d\n', ...
            snr_db, ber_sim_rep(is, ir), ber_theory(is), total_frames);
    end
end

ber_sim_mean = mean(ber_sim_rep, 2);
ber_sim_std = std(ber_sim_rep, 0, 2);
ci95_half = 1.96 * ber_sim_std / sqrt(n_rep);
ci95_low = max(1e-12, ber_sim_mean - ci95_half);
ci95_high = min(0.5, ber_sim_mean + ci95_half);
gap = ber_sim_mean - ber_theory;

%% ===== 12 dB 点统计 =====
[~, i12] = min(abs(snr_grid - 12));
snr_12 = snr_grid(i12);
theory_12 = ber_theory(i12);
sim_12 = ber_sim_mean(i12);
std_12 = ber_sim_std(i12);
ci_12 = ci95_half(i12);

if std_12 > 0
    z_12 = (sim_12 - theory_12) / (std_12 / sqrt(n_rep));
else
    z_12 = NaN;
end

%% ===== 表格 =====
T = table(snr_grid(:), ber_theory, ber_sim_mean, ber_sim_std, ci95_low, ci95_high, gap, ...
    'VariableNames', {'snr_dB','ber_theory','ber_sim_mean','ber_sim_std','ci95_low','ci95_high','gap_sim_minus_theory'});
writetable(T, fullfile(out_dir, 'local_12db_curve.csv'));

Trep = array2table(ber_sim_rep, 'VariableNames', ...
    arrayfun(@(k) sprintf('rep_%d', k), 1:n_rep, 'UniformOutput', false));
Trep = addvars(Trep, snr_grid(:), 'Before', 1, 'NewVariableNames', 'snr_dB');
writetable(Trep, fullfile(out_dir, 'local_12db_repetitions.csv'));

%% ===== 绘图 =====
f = figure('Color', 'w', 'Position', [100 100 980 620]);
hold on; grid on; box on;

semilogy(snr_grid, ber_theory, 'k--', 'LineWidth', 2.0, 'DisplayName', 'Theory (GA, code-side)');
errorbar(snr_grid, ber_sim_mean, ci95_half, 'o-', 'LineWidth', 1.8, 'MarkerSize', 6, ...
    'DisplayName', 'Simulation mean ±95% CI');

xline(12, ':', '12 dB', 'LabelVerticalAlignment', 'bottom', 'Color', [0.3 0.3 0.3]);
plot(snr_12, sim_12, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Sim @12 dB');
plot(snr_12, theory_12, 'ks', 'MarkerFaceColor', 'k', 'DisplayName', 'Theory @12 dB');

xlabel('SNR (dB)');
ylabel('BER');
title(sprintf('Local 12 dB Check (Code-side, p=%.1f, reps=%d)', p, n_rep));
legend('Location', 'best');
set(f, 'PaperPositionMode', 'auto');

savefig(f, fullfile(fig_dir, 'local_12db_curve.fig'));
saveas(f, fullfile(fig_dir, 'local_12db_curve.png'));
print(f, fullfile(fig_dir, 'local_12db_curve.pdf'), '-dpdf', '-bestfit');

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
fprintf(fid, 'run_tag: %s\n', run_tag);
fprintf(fid, '口径: code-side only (GA disable_geom vs BPSK+SC MC)\n');
fprintf(fid, 'p: %.3f\n', p);
fprintf(fid, 'snr_grid: [%s]\n', num2str(snr_grid));
fprintf(fid, 'n_rep: %d\n', n_rep);
fprintf(fid, 'num_frames_min=%d, num_frames_max=%d, min_total_bit_errors=%d\n\n', ...
    num_frames_min, num_frames_max, min_total_bit_errors);

fprintf(fid, '12 dB point summary:\n');
fprintf(fid, 'snr_12 = %.2f dB\n', snr_12);
fprintf(fid, 'theory_12 = %.6e\n', theory_12);
fprintf(fid, 'sim_12_mean = %.6e\n', sim_12);
fprintf(fid, 'sim_12_std = %.6e\n', std_12);
fprintf(fid, 'sim_12_ci95_half = %.6e\n', ci_12);
fprintf(fid, 'gap(sim-theory) = %.6e\n', sim_12 - theory_12);
fprintf(fid, 'z_score = %.6f\n', z_12);
fclose(fid);

fprintf('\n========== Local 12 dB Summary ==========' );
fprintf('\nTheory @12 dB: %.3e', theory_12);
fprintf('\nSimMean@12 dB: %.3e (std=%.3e, CI95=±%.3e)', sim_12, std_12, ci_12);
fprintf('\nGap(sim-theory): %.3e', sim_12 - theory_12);
fprintf('\nZ-score: %.3f\n', z_12);
fprintf('Saved to: %s\n', out_dir);
