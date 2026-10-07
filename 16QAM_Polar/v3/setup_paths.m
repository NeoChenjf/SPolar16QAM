function setup_paths()
%SETUP_PATHS Initialize v3 paths while reusing vetted v2 polar primitives.
    v3_root = fileparts(mfilename('fullpath'));
    qam_root = fileparts(v3_root);
    addpath(v3_root);
    addpath(fullfile(v3_root, 'core'));
    addpath(fullfile(v3_root, 'analysis'));
    addpath(fullfile(v3_root, 'modulation'));
    addpath(fullfile(v3_root, 'polar'));
    addpath(fullfile(v3_root, 'diagnostics'));
    addpath(fullfile(qam_root, 'v2', 'polar'));
    fprintf('[v3 setup_paths] v3 initialized: %s\n', v3_root);
end
