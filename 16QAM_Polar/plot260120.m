function plot260120(dataFile)
% PLOT260120 绘制 energy_goodput_table 中不同 E 下 cost 随 SNR 的变化
% 用法：
%   plot260120()                     % 自动读取 ../周报/energy_goodput_table.xlsx
%   plot260120('path/to/file.xlsx')  % 指定文件，支持 .xlsx 或 .mat

if nargin<1 || isempty(dataFile)
    dataFile = fullfile('..','周报','energy_goodput_table.xlsx');
end

if ~exist(dataFile,'file')
    error('数据文件不存在：%s', dataFile);
end

[~,~,ext] = fileparts(dataFile);
switch lower(ext)
    case '.xlsx'
        T = readtable(dataFile);
    case '.mat'
        s = load(dataFile);
        % 尝试找到第一个 table 或数值矩阵
        fn = fieldnames(s);
        T = [];
        for i=1:numel(fn)
            v = s.(fn{i});
            if istable(v)
                T = v; break;
            elseif isnumeric(v) && size(v,2)>=2
                T = array2table(v);
                break;
            end
        end
        if isempty(T)
            error('MAT 文件中未找到可用表格或矩阵');
        end
    otherwise
        error('不支持的文件类型：%s', ext);
end

% 识别 SNR、E、cost 列并按行筛选（表格每行包含 SNR, E, cost）
varnames = T.Properties.VariableNames;
snrIdx = find(contains(lower(varnames),'snr'),1);
eIdx = find(contains(lower(varnames),'e') | contains(lower(varnames),'energy'),1);
% 优先选择名为 'cost' 的列；若无则回退到 'goodput'
costIdx = find(contains(lower(varnames),'cost'),1);
if isempty(costIdx)
    costIdx = find(contains(lower(varnames),'goodput'),1);
end

% 辅助：把表列转换为数值列（向量），支持 cell、char、numeric
    function v = col2num(col)
        if isnumeric(col)
            v = col(:); return
        end
        if iscell(col)
            n = numel(col); v = nan(n,1);
            for ii=1:n
                el = col{ii};
                if isnumeric(el) && isscalar(el)
                    v(ii) = el;
                elseif ischar(el) || isstring(el)
                    tmp = str2double(el);
                    if ~isnan(tmp)
                        v(ii) = tmp;
                    else
                        tmp2 = sscanf(el, '%f');
                        if ~isempty(tmp2)
                            v(ii) = tmp2(1);
                        end
                    end
                elseif iscell(el) && ~isempty(el)
                    a = el{1};
                    if isnumeric(a) && isscalar(a)
                        v(ii) = a;
                    elseif ischar(a) || isstring(a)
                        v(ii) = str2double(a);
                    end
                end
            end
            return
        end
        try v = double(col(:)); catch, v = nan(numel(col),1); end
    end

% 如果没识别出关键列，尝试默认列位置
if isempty(snrIdx)
    snrIdx = 1;
end
if isempty(eIdx)
    % 尝试包含 'E' 或在第二列
    eIdx = find(contains(varnames,'E') | contains(varnames,'e'),1);
    if isempty(eIdx) && width(T)>=3
        eIdx = 2;
    end
end
if isempty(costIdx)
    % 尝试最后一列或第三列
    if width(T)>=3
        costIdx = width(T);
    else
        costIdx = 3;
    end
end

SNR_col = col2num(T{:,snrIdx});
E_col = col2num(T{:,eIdx});
Cost_col = col2num(T{:,costIdx});

% 目标 E 值（按用户要求）
E_list = [1,1.1,1.2,1.3,1.4];
tol = 1e-3;

% 横坐标 SNR 值集合（按用户给定范围 -5:5:30，如果表里有不同值则使用表中唯一排序后的）
defaultSNR = (-5:5:30)';
uniqueSNR = unique(SNR_col(~isnan(SNR_col)));
if isempty(uniqueSNR)
    xvals = defaultSNR;
else
    % 若 uniqueSNR 等于 defaultSNR 的子集，则使用 defaultSNR 来对齐；否则使用表中唯一值
    if all(ismember(defaultSNR, uniqueSNR))
        xvals = defaultSNR;
    else
        xvals = sort(uniqueSNR);
    end
end

Y = nan(numel(xvals), numel(E_list));
for ei = 1:numel(E_list)
    Etarget = E_list(ei);
    maskE = ~isnan(E_col) & (abs(E_col - Etarget) <= tol);
    if ~any(maskE)
        % 可能表中 E 值用字符串 'E=1.4'，col2num 已尝试解析；如果仍无匹配，尝试按字符串匹配
        %（已在 col2num 处理过，若无匹配则跳过）
        continue
    end
    % 对每个 SNR 值取对应的 cost 的均值（可能有多条记录）
    for xi = 1:numel(xvals)
        s = xvals(xi);
        rows = maskE & ~isnan(SNR_col) & (abs(SNR_col - s) < 1e-6);
        if any(rows)
            vals = Cost_col(rows);
            Y(xi,ei) = mean(vals(~isnan(vals)));
        else
            Y(xi,ei) = NaN;
        end
    end
end

% labels
labels = arrayfun(@(e)sprintf('E=%.3g',e), E_list, 'UniformOutput', false);

% 使用 xvals, Y 进行绘图
x = xvals;
y = Y;

% 准备 labels：如果列名可解析为数字则格式化为 E=...
for k=1:numel(labels)
    ln = labels{k};
    num = sscanf(ln,'E=%f');
    if isempty(num)
        num = sscanf(ln,'E%f');
    end
    if isempty(num)
        num = str2double(ln);
    end
    if ~isempty(num) && ~isnan(num)
        labels{k} = sprintf('E=%.3g',num);
    end
end

% 绘图
figure('Name','提升能量性能带来的信息代价','NumberTitle','off');
hold on
styles = {'-o','-s','-d','-^','-v','-x','-+','-p'};
cols = lines(size(y,2));
for k=1:size(y,2)
    style = styles{mod(k-1,numel(styles))+1};
    plot(x, y(:,k), style, 'Color', cols(mod(k-1,size(cols,1))+1,:), 'LineWidth',1.4);
end
hold off
xlabel('SNR');
ylabel('loss');
legend(labels,'Location','best');
title('提升能量性能带来的信息代价');
grid on

% 可选：保存图片（取消注释以启用）
% saveas(gcf, '提升能量性能带来的信息代价.png');
end
