function check_env()
% CHECK_ENV - SPolar16QAM 运行环境分级自检（Octave / MATLAB 通用）
%
% agent 的第一道关：在跑任何仿真前确认环境与工具箱口径。
% 分级检查，逐项打印 PASS/FAIL，并在末尾给总结与建议。
% 通过 scripts/run_matlab.sh check_env 调用（已自动 setup_paths + load package）。

    fprintf('\n==================== check_env ====================\n');
    nfail = 0;
    is_octave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

    %% (a) 运行环境
    if is_octave
        fprintf('[env] GNU Octave %s\n', OCTAVE_VERSION);
        try
            l = pkg('list');
            names = {};
            for i = 1:numel(l), names{end+1} = l{i}.name; end %#ok<AGROW>
            fprintf('[env] 已安装 package: %s\n', strjoin(names, ', '));
        catch
            fprintf('[env] 无法列出 package\n');
        end
    else
        v = ver('MATLAB');
        fprintf('[env] MATLAB %s\n', v(1).Version);
    end

    %% (b) 标准函数可用性
    fprintf('\n-- (b) 标准函数 --\n');
    std_fns = {'randi','randn','erfc','fft','mod','sort'};
    for i = 1:numel(std_fns)
        ok = exist(std_fns{i}) > 0; %#ok<EXIST>
        nfail = nfail + report(std_fns{i}, ok);
    end

    %% (c) 工具箱函数存在性（Communications Toolbox / communications package）
    fprintf('\n-- (c) 通信工具箱函数 --\n');
    comm_fns = {'qammod','qamdemod','de2bi','bi2de','bitrevorder'};
    comm_missing = 0;
    for i = 1:numel(comm_fns)
        ok = exist(comm_fns{i}) > 0; %#ok<EXIST>
        if ~ok, comm_missing = comm_missing + 1; end
        nfail = nfail + report(comm_fns{i}, ok);
    end
    if comm_missing > 0
        fprintf('   ⚠️ 缺 %d 个通信函数。Octave 下请: pkg install -forge communications\n', comm_missing);
    end

    %% (d) 口径校验
    fprintf('\n-- (d) 16QAM Gray 口径校验 --\n');

    % d1: qammod 平均功率归一化（UnitAveragePower=true 应使 E[|s|^2]=1）
    qammod_ok = false;
    if exist('qammod') > 0 %#ok<EXIST>
        try
            const = qammod((0:15).', 16, 'gray', 'UnitAveragePower', true);
            mean_pow = mean(abs(const).^2);
            qammod_ok = abs(mean_pow - 1) < 1e-6;
            fprintf('   qammod UnitAveragePower: E[|s|^2]=%.6f (期望 1) ... %s\n', ...
                    mean_pow, ynstr(qammod_ok));
        catch err
            fprintf('   qammod 调用失败: %s\n', err.message);
        end
    else
        fprintf('   qammod 不存在，跳过\n');
    end
    nfail = nfail + (~qammod_ok);

    % d2: 项目自带纯数学 LLR（跨环境一致）的符号正确性
    %     发送 bit 全 0 的符号，无噪声 → 各 bit LLR 应为正（bit=0）
    llr_ok = false;
    if exist('llr_16qam_gray_LSE') > 0 %#ok<EXIST>
        try
            % bit=[0 0 0 0] 对应符号索引 0 的星座点
            const0 = qammod((0:15).', 16, 'gray', 'UnitAveragePower', true);
            y0 = const0(1);                      % 符号索引 0，bits=0000 (left-msb)
            sigma = 1e-3;                        % 近无噪声，每实维 std
            L = llr_16qam_gray_LSE(y0, sigma);   % 4x1
            % bit=0 → LLR>0（约定 LLR=log P(b=0)/P(b=1)）
            llr_ok = all(L > 0);
            fprintf('   llr_16qam_gray_LSE(bits=0000) = [%.1f %.1f %.1f %.1f], 期望全正 ... %s\n', ...
                    L(1), L(2), L(3), L(4), ynstr(llr_ok));
        catch err
            fprintf('   llr_16qam_gray_LSE 调用失败: %s\n', err.message);
        end
    else
        fprintf('   llr_16qam_gray_LSE 不在路径，跳过（检查 setup_paths）\n');
    end
    nfail = nfail + (~llr_ok);

    % d3: qamdemod LLR 口径（与项目纯数学 LLR 符号一致性，仅提示不计 fail）
    if exist('qamdemod') > 0 && exist('qammod') > 0 %#ok<EXIST>
        try
            const0 = qammod((0:15).', 16, 'gray', 'UnitAveragePower', true);
            y0 = const0(1);
            Lq = qamdemod(y0, 16, 'gray', 'OutputType', 'llr', ...
                          'UnitAveragePower', true, 'NoiseVariance', 2*(1e-3)^2);
            same_sign = all(sign(Lq(:)) == 1);
            fprintf('   qamdemod LLR(bits=0000) 符号全正? %s（参考项目纯数学 LLR）\n', ynstr(same_sign));
            if ~same_sign
                fprintf('   ⚠️ qamdemod LLR 口径与项目预期不一致 → 仿真改用 llr_16qam_gray_LSE（见 environment-setup.md 第5步）\n');
            end
        catch err
            fprintf('   qamdemod LLR 调用失败: %s（可改用 llr_16qam_gray_LSE）\n', err.message);
        end
    end

    %% 总结
    fprintf('\n==================== 结论 ====================\n');
    if nfail == 0
        fprintf('✅ 环境自检通过：可运行 v2 仿真。\n');
    else
        fprintf('❌ 有 %d 项关键检查未通过，请先按上面提示修复再跑仿真。\n', nfail);
    end
    fprintf('==============================================\n\n');

    % 非交互模式下用退出码反馈（agent 可感知）
    if is_octave && nfail > 0
        % 仅在以 --eval 跑时退出；交互式不强退
        if ~isguirunning_safe()
            exit(1);
        end
    end
end

function f = report(name, ok)
    fprintf('   %-14s ... %s\n', name, ynstr(ok));
    f = double(~ok);
end

function s = ynstr(ok)
    if ok, s = 'PASS'; else, s = 'FAIL'; end
end

function tf = isguirunning_safe()
    tf = false;  % --eval/批处理场景默认非 GUI
end
