function path = p2_freeze_exploratory_strategy(run_dir, max_ber, min_goodput, beta2, beta4)
%P2_FREEZE_EXPLORATORY_STRATEGY Freeze only audited exploratory training data.
    p=load(fullfile(run_dir,'params.mat'),'cfg'); cfg=p.cfg;
    assert(strcmp(cfg.purpose,'strategy_training') && ~strcmp(cfg.mode,'formal'), ...
        'strategyasset:InvalidRole','Only exploratory strategy training is supported.');
    p2_verify_common_snapshot(run_dir);
    p2_audit_common_pairing(run_dir);
    T=readtable(fullfile(run_dir,'repetitions.csv'));
    T=T(strcmp(T.control,'shaped'),:); p2_validate_common_raw_metrics(run_dir,T);
    selection=p2_select_training_tradeoff(T,max_ber,min_goodput,beta2,beta4);
    assert(strcmp(selection.status,'selected'),'strategyasset:NoFeasible','No training candidate meets the thresholds.');
    files=dir(fullfile(run_dir,'raw_*.mat')); names=sort({files.name}); hashes=cell(size(names));
    for i=1:numel(names), hashes{i}=local_hash(fullfile(run_dir,names{i})); end
    asset=struct('status','exploratory_not_formal','selection',selection,'training_dir',run_dir, ...
        'params_sha256',local_hash(fullfile(run_dir,'params.mat')), ...
        'rows_sha256',local_hash(fullfile(run_dir,'repetitions.csv')), ...
        'cases_sha256',local_hash(fullfile(run_dir,'cases.mat')), ...
        'source_snapshot_sha256',local_hash(fullfile(run_dir,'source_sha256.tsv')), ...
        'raw_names',{names},'raw_sha256',{hashes});
    path=fullfile(run_dir,'frozen_exploratory_strategy.mat');
    assert(~isfile(path),'strategyasset:Exists','Refusing to overwrite frozen strategy.');
    save(path,'asset');
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'strategyasset:MissingFile','Cannot read asset input.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
