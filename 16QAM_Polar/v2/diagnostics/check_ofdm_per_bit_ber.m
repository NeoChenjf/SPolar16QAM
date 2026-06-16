%% CHECK_OFDM_PER_BIT_BER
% 从 OFDM baseline MAT 文件提取逐 bit layer 的 BER/K/MI 用于诊断

clear; clc;

mat_path = fullfile(fileparts(mfilename('fullpath')), '..', 'results', ...
    '20260522_174039_ofdm_baseline', 'ofdm_baseline.mat');
load(mat_path);

fprintf('========== Per-bit-layer BER ==========\n\n');
fprintf('p_list: %s\n', mat2str(p_list));
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('decoder: %s\n\n', cfg_local.decoder);

for ip = 1:length(p_list)
    r = all_results{ip};
    p = p_list(ip);
    fprintf('--- p=%.2f | K=[%d %d %d %d] | R_total=%.4f | R_cp=%.4f | E_norm=%.2f ---\n', ...
        p, r.K, r.R_total, r.R_total_cp_corrected, r.E_theory / 10);

    for is = 1:length(snr_grid)
        snr = snr_grid(is);
        fprintf('  SNR=%+5.1f dB | ', snr);
        for b = 1:4
            fprintf('BER%d=%.2e ', b, r.BER_per_bit(b, is));
        end
        fprintf('| BER_w=%.2e\n', r.BER(is));
    end
    fprintf('\n');
end

fprintf('\n========== Per-bit-layer MI ==========\n\n');
for ip = 1:length(p_list)
    r = all_results{ip};
    p = p_list(ip);
    fprintf('--- p=%.2f ---\n', p);
    for is = 1:length(snr_grid)
        snr = snr_grid(is);
        fprintf('  SNR=%+5.1f dB | MI=[%.3f %.3f %.3f %.3f] | MI_tot=%.3f\n', ...
            snr, r.MI(:,is), r.MI_total(is));
    end
    fprintf('\n');
end

fprintf('\n========== R / K breakdown ==========\n\n');
for ip = 1:length(p_list)
    r = all_results{ip};
    p = p_list(ip);
    fprintf('p=%.2f: K=[%d %d %d %d] S=[%d %d %d %d] R_total=%.4f\n', ...
        p, r.K, r.S_size, r.R_total);
end

fprintf('\n========== spow / E comparison ==========\n\n');
fprintf('p=0.50: E_theory=%.1f, E_norm=%.2f, spow=[%s]\n', ...
    all_results{1}.E_theory, all_results{1}.E_theory/10, ...
    join(string(arrayfun(@(x) sprintf('%.4f',x), all_results{1}.spow, 'UniformOutput',false)), ', '));
fprintf('p=0.30: E_theory=%.1f, E_norm=%.2f, spow=[%s]\n', ...
    all_results{2}.E_theory, all_results{2}.E_theory/10, ...
    join(string(arrayfun(@(x) sprintf('%.4f',x), all_results{2}.spow, 'UniformOutput',false)), ', '));
fprintf('p=0.10: E_theory=%.1f, E_norm=%.2f, spow=[%s]\n', ...
    all_results{3}.E_theory, all_results{3}.E_theory/10, ...
    join(string(arrayfun(@(x) sprintf('%.4f',x), all_results{3}.spow, 'UniformOutput',false)), ', '));
