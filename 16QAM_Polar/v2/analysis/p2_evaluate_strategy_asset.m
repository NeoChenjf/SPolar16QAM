function summary = p2_evaluate_strategy_asset(asset_file, test_dir, baseline_ids)
%P2_EVALUATE_STRATEGY_ASSET Validate frozen training provenance before testing.
    loaded=load(asset_file,'asset'); asset=loaded.asset;
    assert(strcmp(asset.status,'exploratory_not_formal'), ...
        'strategyasset:InvalidStatus','Only an exploratory frozen asset is supported.');
    d=asset.training_dir;
    assert(strcmp(local_hash(fullfile(d,'params.mat')),asset.params_sha256) && ...
        strcmp(local_hash(fullfile(d,'repetitions.csv')),asset.rows_sha256) && ...
        strcmp(local_hash(fullfile(d,'cases.mat')),asset.cases_sha256) && ...
        strcmp(local_hash(fullfile(d,'source_sha256.tsv')),asset.source_snapshot_sha256), ...
        'strategyasset:TrainingChanged','Frozen training inputs have changed.');
    names=sort({dir(fullfile(d,'raw_*.mat')).name});
    assert(isequal(names,asset.raw_names) && numel(names)==numel(asset.raw_sha256), ...
        'strategyasset:TrainingChanged','Frozen training raw file set changed.');
    for i=1:numel(names)
        assert(strcmp(local_hash(fullfile(d,names{i})),asset.raw_sha256{i}), ...
            'strategyasset:TrainingChanged','Frozen training raw content changed.');
    end
    p=load(fullfile(d,'params.mat'),'cfg'); assert(strcmp(p.cfg.purpose,'strategy_training'), ...
        'strategyasset:InvalidRole','Frozen source is not strategy training.');
    p2_verify_common_snapshot(d);
    p2_verify_common_snapshot(test_dir);
    summary=p2_evaluate_frozen_run(asset.selection,test_dir,baseline_ids);
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'strategyasset:MissingFile','Cannot read asset input.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
