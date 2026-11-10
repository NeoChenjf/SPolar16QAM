function manifest = p2_model_training_manifest(run_dir, expected)
%P2_MODEL_TRAINING_MANIFEST Capture/compare exploratory training provenance.
% A trusted external freeze of the returned value is required; not a formal gate.
    p=load(fullfile(run_dir,'params.mat'),'cfg'); c=p.cfg;
    assert(strcmp(c.purpose,'model_calibration') && ~strcmp(c.mode,'formal') && ...
        c.predict && isfile(c.pmf_file),'modelmanifest:InvalidRole', ...
        'Exploratory model calibration and its PMF are required.');
    p2_verify_common_snapshot(run_dir);
    p2_audit_common_pairing(run_dir);
    T=readtable(fullfile(run_dir,'repetitions.csv'));
    q=load(fullfile(run_dir,'cases.mat'),'cases'); cases=q.cases;
    assert(height(T)==c.num_channels*numel(c.snr_grid)*numel(cases) && ...
        height(unique(T(:,{'channel','snr_db','case_id'}),'rows'))==height(T), ...
        'modelmanifest:InvalidRows','Training rows missing or duplicated.');
    p2_validate_common_raw_metrics(run_dir,T);
    p2_validate_common_predictions(run_dir);
    names=sort({dir(fullfile(run_dir,'raw_*.mat')).name});
    assert(numel(names)==height(T),'modelmanifest:InvalidRawSet','Unexpected raw file set.');
    hashes=cell(size(names));
    for k=1:numel(names), hashes{k}=local_hash(fullfile(run_dir,names{k})); end
    manifest=struct('status','exploratory_not_formal','run_dir',run_dir, ...
        'params_sha256',local_hash(fullfile(run_dir,'params.mat')), ...
        'rows_sha256',local_hash(fullfile(run_dir,'repetitions.csv')), ...
        'cases_sha256',local_hash(fullfile(run_dir,'cases.mat')), ...
        'sources_sha256',local_hash(fullfile(run_dir,'source_sha256.tsv')), ...
        'pmf_sha256',local_hash(c.pmf_file),'raw_names',{names},'raw_sha256',{hashes});
    if nargin>1
        assert(isequal(manifest,expected),'modelmanifest:Changed','Training manifest differs from frozen copy.');
    end
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'modelmanifest:MissingFile','Cannot read input.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end

