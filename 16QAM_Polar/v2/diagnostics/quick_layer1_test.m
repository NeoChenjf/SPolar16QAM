%% 快速单点测试 Layer1修复
% 测试几个 (p, SNR) 点，验证理论与仿真的趋势

clear; clc;
setup_paths();
cfg = config();

% 测试参数
p_list = [0.5, 0.3, 0.1];
snr_list = [0, 10, 20];
mode = 'fixed_n0';

fprintf('=== Layer1 修复快速验证 ===\n');
fprintf('模式：%s | 样本数：10k符号/点\n\n', mode);

for p = p_list
    fprintf('\n--- p = %.2f ---\n', p);
    for snr_db = snr_list
        % 仿真
        nSym = 1e4;
        b1 = rand(nSym, 1) < 0.5;
        b2 = rand(nSym, 1) < p;
        b3 = rand(nSym, 1) < 0.5;
        b4 = rand(nSym, 1) < p;
        tx_bits = double([b1, b2, b3, b4]);
        
        tx_sym = qammod(tx_bits, cfg.M, cfg.mapping, 'InputType', 'bit', 'UnitAveragePower', cfg.unit_avg_power);
        tx_sym = tx_sym(:);
        
        sigma = 10^(-snr_db / 20);
        switch mode
            case 'fixed_n0'
                sigma_noise = sqrt(cfg.snr_ref_power) * sigma;
            otherwise
                sigma_noise = sqrt(mean(abs(tx_sym).^2)) * sigma;
        end
        
        noise = sigma_noise .* (randn(nSym, 1) + 1j * randn(nSym, 1));
        rx_sym = tx_sym + noise;
        rx_bits = qamdemod(rx_sym, cfg.M, cfg.mapping, 'OutputType', 'bit', 'UnitAveragePower', cfg.unit_avg_power);
        
        ber_sim = sum(rx_bits(:) ~= tx_bits(:)) / numel(tx_bits);
        
        % 理论（新公式）
        Es_theory = (18 - 16 * p) / 10;
        snr_lin = 10^(snr_db / 10);
        switch mode
            case 'fixed_n0'
                gamma_eff = Es_theory * snr_lin / (2 * cfg.snr_ref_power);
            otherwise
                gamma_eff = snr_lin / 2;
        end
        q_arg = sqrt(0.8 * gamma_eff);
        ber_theory = min(0.5, max(1e-12, (2 + 2*p) * qfunc(q_arg)));
        
        err = abs(ber_sim - ber_theory);
        fprintf('  SNR=%+3d dB | BER_sim=%.4e | BER_th=%.4e | 差异=%.4e\n', snr_db, ber_sim, ber_theory, err);
    end
end

fprintf('\n✓ 验证完成\n');
