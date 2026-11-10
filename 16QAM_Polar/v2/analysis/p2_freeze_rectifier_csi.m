function digest = p2_freeze_rectifier_csi(training_asset,output_file,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)
%P2_FREEZE_RECTIFIER_CSI Save exploratory CSI rule with training asset hash.
% Caller must preserve returned digest separately before collecting test data.
    assert(~isfile(output_file),'rectfreeze:Exists','Refusing to overwrite an asset.');
    a=load(training_asset,'asset'); a=a.asset; d=a.training_dir;
    assert(strcmp(a.status,'exploratory_not_formal'),'rectfreeze:InvalidAsset','Exploratory training asset required.');
    assert(strcmp(local_hash(fullfile(d,'params.mat')),a.params_sha256) && ...
        strcmp(local_hash(fullfile(d,'repetitions.csv')),a.rows_sha256) && ...
        strcmp(local_hash(fullfile(d,'cases.mat')),a.cases_sha256) && ...
        strcmp(local_hash(fullfile(d,'source_sha256.tsv')),a.source_snapshot_sha256), ...
        'rectfreeze:TrainingChanged','Training files differ from the frozen asset.');
    names=sort({dir(fullfile(d,'raw_*.mat')).name});
    assert(isequal(names,a.raw_names) && numel(names)==numel(a.raw_sha256), ...
        'rectfreeze:TrainingChanged','Training raw file set changed.');
    for k=1:numel(names)
        assert(strcmp(local_hash(fullfile(d,names{k})),a.raw_sha256{k}), ...
            'rectfreeze:TrainingChanged','Training raw content changed.');
    end
    policy=p2_train_rectifier_csi_policy(d,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w);
    frozen=struct('status','exploratory_not_formal','training_asset',training_asset, ...
        'training_asset_sha256',local_hash(training_asset),'policy',policy);
    save(output_file,'frozen'); digest=local_hash(output_file);
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'rectfreeze:MissingFile','Cannot read file.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
