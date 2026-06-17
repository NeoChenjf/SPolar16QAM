function h = sgtitle(varargin)
%SGTITLE  (Octave compat) MATLAB sgtitle 的轻量替代
%
% Octave 无 sgtitle（MATLAB R2018b+ 的多子图总标题）。本兼容版尽力而为：
% 在当前 figure 顶部用 annotation 放一个居中标题；任何绘图异常都不致命
% （headless/无显示环境下静默跳过），以免绘图收尾打断已算完的仿真。
%
% 只在 Octave 下被加入路径（见 setup_paths.m）。MATLAB 下用原生 sgtitle。

    h = [];
    txt = '';
    if ~isempty(varargin) && ischar(varargin{end})
        txt = varargin{end};
    elseif numel(varargin) >= 2 && ischar(varargin{2})
        txt = varargin{2};
    end
    try
        f = get(0, 'CurrentFigure');
        if isempty(f)
            return;   % 无 figure，跳过
        end
        h = annotation(f, 'textbox', [0 0.94 1 0.06], ...
                       'String', txt, 'EdgeColor', 'none', ...
                       'HorizontalAlignment', 'center', ...
                       'FontWeight', 'bold', 'Interpreter', 'none');
    catch
        % headless 或不支持 annotation：静默跳过，不影响数值结果
        h = [];
    end
end
