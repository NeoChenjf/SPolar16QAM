%% RUN_B4B_GUARDBAND_POLICY_TEST_ANALYSIS
% Analyze the preregistered 28 dB guard-band policy on a third data split.

clear; clc; close all;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..'); addpath(v2_root); setup_paths();
cfg = config();
test_dir = fullfile(cfg.output_dir, '20260917_223848_b4b_guardband_policy_test');
S = readtable(fullfile(test_dir, 'b4b_strategy_summary.csv'));
snr_grid = [20 24 28 32 36 40];
selected = {'uniform_p05','uniform_p05','uniform_p01','uniform_p01','uniform_p01','uniform_p01'};
ber_limit = 0.1; goodput_floor = 0.25;
rows = cell(6, 13);
for i = 1:6
    x = S(strcmp(S.strategy, selected{i}) & S.snr_dB == snr_grid(i), :);
    p05 = S(strcmp(S.strategy, 'uniform_p05') & S.snr_dB == snr_grid(i), :);
    ber_upper = x.ber_mean + x.ber_ci95;
    goodput_lower = x.goodput_cp_mean - x.goodput_cp_ci95;
    gate_required = snr_grid(i) >= 28;
    if gate_required
        point_pass = ber_upper <= ber_limit && goodput_lower >= goodput_floor;
        reason = 'feasible_max_energy';
    else
        same_snr = S.snr_dB == snr_grid(i);
        point_pass = abs(x.goodput_cp_mean - max(S.goodput_cp_mean(same_snr))) < 1e-12;
        reason = 'guardband_max_goodput';
    end
    rows(i,:) = {snr_grid(i), selected{i}, reason, x.ber_mean, x.ber_ci95, ...
        ber_upper, x.goodput_cp_mean, x.goodput_cp_ci95, goodput_lower, ...
        x.rx_signal_power_mean, x.rx_signal_power_ci95, ...
        x.rx_signal_power_mean-p05.rx_signal_power_mean, point_pass};
end
V = cell2table(rows, 'VariableNames', {'snr_dB','selected_strategy', ...
    'reason','ber_mean','ber_ci95','ber_upper95','goodput_mean', ...
    'goodput_ci95','goodput_lower95','energy_mean','energy_ci95', ...
    'energy_gain_vs_p05','point_pass'});
overall_pass = all(V.point_pass);
out_dir = fullfile(cfg.output_dir, [datestr(now,'yyyymmdd_HHMMSS') ...
    '_b4b_guardband_policy_test_analysis']);
fig_dir = fullfile(out_dir,'figures'); mkdir(out_dir); mkdir(fig_dir);
writetable(V, fullfile(out_dir,'guardband_policy_test_summary.csv'));
save(fullfile(out_dir,'guardband_policy_test_analysis.mat'),'V','S','test_dir', ...
    'selected','snr_grid','ber_limit','goodput_floor','overall_pass');

fig=figure('Color','w','Position',[80 80 1000 760]);
subplot(3,1,1); plot(V.snr_dB,V.ber_upper95,'-o'); hold on; yline(ber_limit,'--r'); grid on; ylabel('BER upper 95%'); title('Third-split guard-band policy validation');
subplot(3,1,2); plot(V.snr_dB,V.goodput_lower95,'-o'); hold on; yline(goodput_floor,'--r'); grid on; ylabel('Goodput lower 95%');
subplot(3,1,3); bar(V.snr_dB,V.energy_gain_vs_p05); grid on; ylabel('Energy gain vs p05'); xlabel('Average SNR (dB)');
savefig(fig,fullfile(fig_dir,'b4b_guardband_policy_validation.fig'));
exportgraphics(fig,fullfile(fig_dir,'b4b_guardband_policy_validation.png'),'Resolution',300);
exportgraphics(fig,fullfile(fig_dir,'b4b_guardband_policy_validation.pdf'),'ContentType','vector'); close(fig);

fid=fopen(fullfile(out_dir,'README.txt'),'w'); assert(fid>=0); c=onCleanup(@()fclose(fid));
fprintf(fid,'B4b 28 dB GUARDBAND POLICY THIRD-SPLIT TEST\n\n');
fprintf(fid,'Source: %s\nSeed: 2042\nPolicy: p05 at 20/24 dB; p01 at 28-40 dB.\n',test_dir);
fprintf(fid,'No policy tuning used this third split.\nOverall pass: %d\n',overall_pass);
fprintf('Guard-band policy analysis: %s | pass=%d\n',out_dir,overall_pass);
