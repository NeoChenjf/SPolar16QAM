function out_dir = rebuild_b4b_partition_snapshot_supplement(source_dirs)
% Rebuild auditable S/I/F metadata without rerunning the PMF simulations.
    script_dir = fileparts(mfilename('fullpath'));
    v2_root = fileparts(script_dir);
    addpath(v2_root); setup_paths();
    cfg = config();
    if nargin < 1 || isempty(source_dirs)
        source_dirs = { ...
            fullfile(cfg.output_dir, '20261009_175322_b4b_shaping_audit_formal_source_N1024_source_MC_GA'), ...
            fullfile(cfg.output_dir, '20261009_180522_b4b_shaping_audit_blocklength_N256_source_MC_GA'), ...
            fullfile(cfg.output_dir, '20261009_180551_b4b_shaping_audit_blocklength_N1024_source_MC_GA')};
    end
    assert(iscell(source_dirs) && ~isempty(source_dirs));
    for i = 1:numel(source_dirs)
        source_dirs{i} = char(source_dirs{i});
        assert(exist(fullfile(source_dirs{i}, 'b4b_shaping_audit.mat'), 'file') == 2, ...
            'Missing audit MAT file in %s.', source_dirs{i});
    end

    out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') ...
        '_b4b_partition_snapshot_supplement']);
    if exist(out_dir, 'dir'), error('Refusing to overwrite %s.', out_dir); end
    mkdir(out_dir); snapshot_dir = fullfile(out_dir, 'source_snapshot'); mkdir(snapshot_dir);
    index_rows = {}; summary_rows = {}; entropy_rows = {};
    audit_settings = cell(numel(source_dirs),1);
    for isource = 1:numel(source_dirs)
        source_dir = source_dirs{isource};
        saved = load(fullfile(source_dir, 'b4b_shaping_audit.mat'), ...
            'cfg_local', 'p_values', 'mode');
        audit_cfg = saved.cfg_local;
        audit_settings{isource} = struct('source_result_dir',source_dir, ...
            'N',audit_cfg.N,'p_values',saved.p_values,'mode',saved.mode, ...
            'source_samples',audit_cfg.source_samples, ...
            'source_seed',audit_cfg.source_seed,'sigma_design',10^(-20/20));
        for ip = 1:numel(saved.p_values)
            p = saved.p_values(ip); p_vec = [0.5, p, 0.5, p];
            state = build_source_entropy_partition(audit_cfg.N, p_vec, ...
                10^(-20/20), audit_cfg.source_samples, audit_cfg.source_seed);
            for b = 1:4
                sets = {state.S{b}, state.I{b}, state.F{b}};
                labels = {'S','I','F'};
                for iset = 1:3
                    for idx = sets{iset}(:).'
                        index_rows(end+1,:) = {source_dir,audit_cfg.N,p,b,labels{iset},idx}; %#ok<AGROW>
                    end
                end
                H = state.source_entropy{b};
                for idx = 1:audit_cfg.N
                    entropy_rows(end+1,:) = {source_dir,audit_cfg.N,p,b,idx,H(idx)}; %#ok<AGROW>
                end
                summary_rows(end+1,:) = {source_dir,audit_cfg.N,p,b,state.K(b), ...
                    state.S_size(b),state.F_size(b),state.fingerprint{b}}; %#ok<AGROW>
            end
        end
    end
    index_table = cell2table(index_rows,'VariableNames', ...
        {'source_result_dir','N','p','bit_stream','set_name','source_index'});
    index_table.N=cell2mat(index_rows(:,2)); index_table.p=cell2mat(index_rows(:,3));
    index_table.bit_stream=cell2mat(index_rows(:,4));
    index_table.source_index=cell2mat(index_rows(:,6));
    summary_table = cell2table(summary_rows,'VariableNames', ...
        {'source_result_dir','N','p','bit_stream','K','S_size','F_size','fingerprint'});
    summary_table.N=cell2mat(summary_rows(:,2));
    summary_table.p=cell2mat(summary_rows(:,3));
    summary_table.bit_stream=cell2mat(summary_rows(:,4));
    summary_table.K=cell2mat(summary_rows(:,5));
    summary_table.S_size=cell2mat(summary_rows(:,6));
    summary_table.F_size=cell2mat(summary_rows(:,7));
    entropy_table = cell2table(entropy_rows,'VariableNames', ...
        {'source_result_dir','N','p','bit_stream','source_index','source_entropy'});
    entropy_table.N=cell2mat(entropy_rows(:,2));
    entropy_table.p=cell2mat(entropy_rows(:,3));
    entropy_table.bit_stream=cell2mat(entropy_rows(:,4));
    entropy_table.source_index=cell2mat(entropy_rows(:,5));
    entropy_table.source_entropy=cell2mat(entropy_rows(:,6));
    writetable(index_table,fullfile(out_dir,'partition_indices.csv'));
    writetable(summary_table,fullfile(out_dir,'partition_summary.csv'));
    writetable(entropy_table,fullfile(out_dir,'source_entropy_by_index.csv'));
    save(fullfile(out_dir,'partition_snapshot_supplement.mat'), ...
        'source_dirs','index_table','summary_table','entropy_table');
    save(fullfile(out_dir,'params.mat'),'source_dirs','audit_settings');

    source_files = { ...
        fullfile(v2_root,'experiments','multicarrier', ...
            'run_b4b_partition_snapshot_supplement.m'), ...
        fullfile(v2_root,'analysis','rebuild_b4b_partition_snapshot_supplement.m'), ...
        fullfile(v2_root,'polar','build_source_entropy_partition.m'), ...
        fullfile(v2_root,'polar','GA.m'), fullfile(v2_root,'polar','polar_encoder.m'), ...
        fullfile(v2_root,'..','v3','polar','build_stream_partition_source_mc_ga.m'), ...
        fullfile(v2_root,'..','v3','polar','sc_decode_forced_full.m')};
    hash_fid=fopen(fullfile(out_dir,'source_sha256_manifest.txt'),'w');
    assert(hash_fid>=0,'Cannot create source hash manifest.');
    cleanup=onCleanup(@()fclose(hash_fid)); %#ok<NASGU>
    for i=1:numel(source_files)
        source_file=source_files{i}; [~,name,ext]=fileparts(source_file);
        copyfile(source_file,fullfile(snapshot_dir,[name ext]));
        bytes=read_bytes(source_file);
        digest=java.security.MessageDigest.getInstance('SHA-256'); digest.update(bytes);
        hex=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
        fprintf(hash_fid,'%s  %s\n',hex,source_file);
    end
    fid=fopen(fullfile(out_dir,'README.txt'),'w');
    assert(fid>=0,'Cannot create supplement README.');
    close_fid=onCleanup(@()fclose(fid)); %#ok<NASGU>
    fprintf(fid,'B4b partition metadata reconstruction supplement\n\n');
    fprintf(fid,'Source audit directories:\n');
    for i=1:numel(source_dirs), fprintf(fid,'- %s\n',source_dirs{i}); end
    fprintf(fid,['Reconstructs S/I/F indices, fingerprints, and source entropy with recorded ' ...
        'N, p, source sample count, seed, and fixed design sigma. No payload/PMF Monte Carlo ' ...
        'was rerun. Original directories remain unchanged. Compare each audit README and ' ...
        'source manifest before treating this as paired metadata.\n']);
end

function bytes=read_bytes(path)
    fid=fopen(path,'rb'); assert(fid>=0,'Cannot read %s.',path);
    cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,Inf,'*uint8');
end
