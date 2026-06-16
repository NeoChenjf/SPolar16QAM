function setup_paths()
% SETUP_PATHS - 添加 v2 项目所有子目录到 MATLAB 路径
%
% 用法：在任何脚本开头调用 setup_paths();
%       或在 MATLAB 命令行运行一次。

    project_root = fileparts(mfilename('fullpath'));
    addpath(project_root);
    addpath(fullfile(project_root, 'core'));
    addpath(fullfile(project_root, 'polar'));
    addpath(fullfile(project_root, 'modulation'));
    addpath(fullfile(project_root, 'analysis'));
    local_add_subtree(project_root, 'diagnostics');
    local_add_subtree(project_root, 'experiments');

    fprintf('[setup_paths] 已添加 v2 项目路径: %s\n', project_root);
end

function local_add_subtree(project_root, subdir_name)
% 将整理后的辅助脚本目录递归加入 MATLAB 路径，避免顶层重新变杂乱。
    subdir_path = fullfile(project_root, subdir_name);
    if exist(subdir_path, 'dir')
        addpath(genpath(subdir_path));
    end
end
