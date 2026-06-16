%% ANALYZE_SYMBOL_PRIOR_ALIGNMENT
% 目的：
% 1) 统计仿真里 16 个符号的经验概率
% 2) 对比理论符号先验概率
% 3) 输出每个符号的误差表（csv）
% 4) 输出 5 张概率对比图（symbol index vs probability, theory vs sim）
%
% 说明：
% - 本脚本只做“无编码调制层”概率一致性诊断
% - 不经过极化编码/译码

clear; clc; close all;

setup_paths();
cfg = config();

%% ===== 可调参数 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
nSym = 2e5;                 % 每个 p 统计符号数
seed = 20260412;

rng(seed, 'twister');

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_symbol_prior_alignment']);
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
fig_dir = fullfile(out_dir, 'figures');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

%% ===== 预计算映射标签 =====
M = cfg.M;
labels = de2bi((0:M-1).', 4, 'left-msb');   % 与 qammod/qamdemod 一致

% 总表（长表）
rows_total = numel(p_list) * M;
T = table('Size', [rows_total, 11], ...
          'VariableTypes', {'double','double','double','double','double','double','double','double','double','double','double'}, ...
          'VariableNames', {'p','symbol_index','b1','b2','b3','b4','p_theory','p_empirical','abs_error','rel_error','count_empirical'});

row_ptr = 1;

fprintf('===== Symbol Prior Alignment =====\n');
fprintf('nSym per p = %d\n', nSym);

for ip = 1:numel(p_list)
    p = p_list(ip);

    % bit1/bit3 固定 0.5，bit2/bit4 由 p 控制
    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;

    % 生成 bit 流（每行一个符号的4个bit）
    b1 = rand(nSym, 1) < p_vec(1);
    b2 = rand(nSym, 1) < p_vec(2);
    b3 = rand(nSym, 1) < p_vec(3);
    b4 = rand(nSym, 1) < p_vec(4);
    tx_bits = double([b1, b2, b3, b4]);

    % 直接按 left-msb 将 bit 映射到符号索引（0~15）
    sym_idx = bi2de(tx_bits, 'left-msb');

    % 经验概率
    cnt = accumarray(sym_idx + 1, 1, [M, 1]);
    p_emp = cnt / sum(cnt);

    % 理论概率
    p_th = local_build_symbol_prior(p_vec, labels);

    abs_err = abs(p_emp - p_th);
    rel_err = abs_err ./ max(p_th, eps);

    fprintf('\np = %.2f | max_abs_err = %.3e | mean_abs_err = %.3e\n', ...
        p, max(abs_err), mean(abs_err));

    % 写入总表
    for m = 1:M
        T.p(row_ptr) = p;
        T.symbol_index(row_ptr) = m - 1;
        T.b1(row_ptr) = labels(m,1);
        T.b2(row_ptr) = labels(m,2);
        T.b3(row_ptr) = labels(m,3);
        T.b4(row_ptr) = labels(m,4);
        T.p_theory(row_ptr) = p_th(m);
        T.p_empirical(row_ptr) = p_emp(m);
        T.abs_error(row_ptr) = abs_err(m);
        T.rel_error(row_ptr) = rel_err(m);
        T.count_empirical(row_ptr) = cnt(m);
        row_ptr = row_ptr + 1;
    end

    % 单 p 详细表
    Tp = table((0:M-1).', labels(:,1), labels(:,2), labels(:,3), labels(:,4), ...
               p_th, p_emp, abs_err, rel_err, cnt, ...
               'VariableNames', {'symbol_index','b1','b2','b3','b4','p_theory','p_empirical','abs_error','rel_error','count_empirical'});

    fname = fullfile(out_dir, sprintf('symbol_prior_alignment_p_%0.2f.csv', p));
    writetable(Tp, fname);

    % 单 p 可视化：只保留 theory vs sim 的概率对比图
    fig = figure('Position', [140 140 860 460], 'Visible', 'off');
    hold on;
    bar(0:M-1, p_th, 0.75, 'FaceAlpha', 0.55, 'DisplayName', 'theory');
    plot(0:M-1, p_emp, 'o-', 'LineWidth', 1.6, 'MarkerSize', 4, 'DisplayName', 'sim');
    hold off;
    grid on;
    xlabel('symbol index');
    ylabel('probability');
    title(sprintf('Symbol Prior: Theory vs Sim (p=%.2f)', p));
    legend('Location', 'best');

    exportgraphics(fig, fullfile(fig_dir, sprintf('symbol_prior_alignment_p_%0.2f.png', p)), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, sprintf('symbol_prior_alignment_p_%0.2f.pdf', p)), 'ContentType', 'vector');
    close(fig);
end

% 导出总表
writetable(T, fullfile(out_dir, 'symbol_prior_alignment_all_p.csv'));

% 汇总表
Ts = groupsummary(T, 'p', {'max','mean'}, {'abs_error','rel_error'});
writetable(Ts, fullfile(out_dir, 'symbol_prior_alignment_summary.csv'));

% README
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
fprintf(fid, 'Symbol prior alignment (modulation-only, no polar coding)\n');
fprintf(fid, 'p_list = [0.5, 0.4, 0.3, 0.2, 0.1]\n');
fprintf(fid, 'nSym per p = %d\n', nSym);
fprintf(fid, 'seed = %d\n', seed);
fprintf(fid, '\nOutputs:\n');
fprintf(fid, '- symbol_prior_alignment_all_p.csv\n');
fprintf(fid, '- symbol_prior_alignment_summary.csv\n');
fprintf(fid, '- symbol_prior_alignment_p_*.csv\n');
fprintf(fid, '- figures/symbol_prior_alignment_p_*.png/pdf (theory vs sim only)\n');
fclose(fid);

fprintf('\n===== 完成 =====\n');
fprintf('结果目录: %s\n', out_dir);


function psym = local_build_symbol_prior(p_vec, labels)
% 根据各 bit 的先验 P(bit=1) 计算 16 个符号的理论先验。

    M = size(labels, 1);
    psym = zeros(M, 1);

    for m = 1:M
        pm = 1;
        for b = 1:4
            if labels(m, b) == 1
                pm = pm * p_vec(b);
            else
                pm = pm * (1 - p_vec(b));
            end
        end
        psym(m) = pm;
    end

    psym = psym / sum(psym);
end
