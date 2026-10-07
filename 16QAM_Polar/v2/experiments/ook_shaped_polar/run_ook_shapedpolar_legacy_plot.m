%% RUN_OOK_SHAPEDPOLAR_LEGACY_PLOT
% Thin, reproducible v2 wrapper around the historical ShapedPolarS/gettest
% chain.  It deliberately preserves its single-GA set selection, SC
% precoding/decoding, and spow-normalized OOK channel so its BER/BLER plots
% can be visually audited before any corrected implementation is introduced.

clearvars; clc; close all;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fileparts(fileparts(script_dir));
addpath(v2_root);
setup_paths;
legacy_dir = fullfile(v2_root, '..', 'ShapedPolarS');
addpath(legacy_dir);

cfg_local = struct();
cfg_local.p_list = [0.5 0.7 0.9];
cfg_local.snr_grid = -5:0.5:18; % gettest.m fixed grid
cfg_local.num_frames = 1000;    % gettest.m fixed frame count
cfg_local.seed = 42;

rng(cfg_local.seed, 'twister');
out_dir = fullfile(v2_root, 'results', [datestr(now,'yyyymmdd_HHMMSS') '_ook_shapedpolar_legacy_plot']);
fig_dir = fullfile(out_dir, 'figures');
mkdir(out_dir); mkdir(fig_dir);
diary(fullfile(out_dir, 'run_log.txt')); diary on;
cleanup_obj = onCleanup(@() diary('off')); %#ok<NASGU>

BER = zeros(numel(cfg_local.p_list), numel(cfg_local.snr_grid));
BLER = BER;
for ip = 1:numel(cfg_local.p_list)
    [BER(ip,:), BLER(ip,:)] = gettest(cfg_local.p_list(ip));
end

T = table(cfg_local.p_list(:), BER, BLER, 'VariableNames', {'p','ber','bler'});
save(fullfile(out_dir, 'legacy_curves.mat'), 'cfg_local', 'BER', 'BLER', 'T');
writetable(T, fullfile(out_dir, 'legacy_curves.csv'));

local_plot(cfg_local.snr_grid, cfg_local.p_list, BER, 'BER', fullfile(fig_dir,'ook_legacy_ber'));
local_plot(cfg_local.snr_grid, cfg_local.p_list, BLER, 'BLER', fullfile(fig_dir,'ook_legacy_bler'));
fid = fopen(fullfile(out_dir,'README.txt'),'w');
fprintf(fid, 'Exact-wrapper audit of ShapedPolarS/gettest.m.\n');
fprintf(fid, 'The legacy function rebuilds GA sets at every SNR and uses 1000 noise trials.\n');
fprintf(fid, 'This is a legacy audit curve, not a paper-consistent BSC+GA construction.\n');
fclose(fid);

function local_plot(snr, p_list, values, ylab, stem)
fig = figure('Color','w'); hold on; grid on; box on;
for k = 1:numel(p_list)
    y = values(k,:); y(y==0) = 1e-5;
    semilogy(snr, y, '-o', 'LineWidth',1.2, 'DisplayName',sprintf('SC p=%.1f',p_list(k)));
end
xlabel('SNR (dB)'); ylabel(ylab); title(['Legacy shaped polar OOK ' ylab]);
legend('Location','best'); ylim([1e-5 1]);
savefig(fig,[stem '.fig']); exportgraphics(fig,[stem '.png'],'Resolution',300); exportgraphics(fig,[stem '.pdf'],'ContentType','vector'); close(fig);
end
