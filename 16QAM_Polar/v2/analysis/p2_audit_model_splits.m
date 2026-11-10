function result = p2_audit_model_splits(model_file,test_dir)
%P2_AUDIT_MODEL_SPLITS Check exploratory model/test roles and channel identity.
% Distinct deterministic keys and realized channels do not prove PRNG independence.
    m=load(model_file,'model'); m=m.model;
    p=load(fullfile(test_dir,'params.mat'),'cfg'); t=p.cfg;
    assert(any(strcmp(t.purpose,{'test_seen','test_unseen'})) && t.predict && ...
        t.seed~=m.training_cfg.seed,'splitaudit:InvalidRole','Independent test role and seed required.');
    assert(isfile(t.model_file) && strcmp(local_hash(t.model_file),local_hash(model_file)), ...
        'splitaudit:ModelMismatch','Test did not use the supplied model.');
    assert(isfile(t.pmf_file) && strcmp(local_hash(t.pmf_file),m.pmf_sha256), ...
        'splitaudit:PMFMismatch','Test PMF differs from training PMF.');
    fields={'N','n_sc','cp','taps','source_seed','source_samples','snr_grid','controls'};
    for k=1:numel(fields)
        assert(isequal(t.(fields{k}),m.training_cfg.(fields{k})), ...
            'splitaudit:ConfigMismatch','Core model and test configuration differs.');
    end
    if strcmp(t.purpose,'test_seen')
        assert(isequal(t.strategy_p,m.training_cfg.strategy_p) && ...
            isequal(t.strategy_names,m.training_cfg.strategy_names), ...
            'splitaudit:ConfigMismatch','Seen configurations differ.');
    else
        assert(~any(ismember(t.strategy_p,m.training_cfg.strategy_p,'rows')), ...
            'splitaudit:ConfigMismatch','Unseen configurations overlap training.');
    end
    p2_validate_common_model(model_file);
    p2_verify_common_snapshot(test_dir); p2_audit_common_pairing(test_dir);
    T=readtable(fullfile(test_dir,'repetitions.csv')); p2_validate_common_raw_metrics(test_dir,T);
    p2_validate_common_references(test_dir); p2_validate_common_predictions(test_dir);
    [train_hash,train_seeds]=local_channels(m.training_dir,m.training_cfg);
    [test_hash,test_seeds]=local_channels(test_dir,t);
    assert(isempty(intersect(train_hash,test_hash)) && isempty(intersect(train_seeds,test_seeds)), ...
        'splitaudit:ChannelOverlap','Training and test channel or seed overlap.');
    result=struct('training_channels',numel(train_hash),'test_channels',numel(test_hash), ...
        'test_purpose',t.purpose,'scope','exploratory_not_blind_or_formal');
end
function [hashes,seeds]=local_channels(d,c)
    q=load(fullfile(d,'cases.mat'),'cases'); hashes=cell(c.num_channels,1); seeds=zeros(c.num_channels,1);
    old=rng; restore=onCleanup(@() rng(old)); %#ok<NASGU>
    for i=1:c.num_channels
        a=load(fullfile(d,sprintf('raw_c%d_s1_%s.mat',i,q.cases(1).id)),'artifact'); a=a.artifact;
        seeds(i)=p2_paired_seed(c.purpose,c.seed,i,0,0,0,'channel');
        rng(seeds(i),'twister'); h=(randn(c.taps,1)+1i*randn(c.taps,1))/sqrt(2*c.taps);
        if c.n_sc==1, h=1; end
        assert(a.channel_seed==seeds(i) && isequal(a.h,h),'splitaudit:ChannelMismatch','Channel not reproduced from key.');
        hashes{i}=a.channel_hash;
    end
    assert(numel(unique(hashes))==numel(hashes) && numel(unique(seeds))==numel(seeds), ...
        'splitaudit:DuplicateChannel','Duplicate channels or channel keys.');
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'splitaudit:MissingFile','Cannot read file.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
