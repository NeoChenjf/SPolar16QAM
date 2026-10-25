% Rebuild missing S/I/F provenance for completed B4b PMF/blocklength audits.
clearvars -except b4b_snapshot_overrides; clc;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root); setup_paths();
source_dirs = {};
if exist('b4b_snapshot_overrides','var') && ...
        isfield(b4b_snapshot_overrides,'source_dirs')
    source_dirs = b4b_snapshot_overrides.source_dirs;
end
out_dir = rebuild_b4b_partition_snapshot_supplement(source_dirs);
fprintf('Partition metadata supplement: %s\n',out_dir);
