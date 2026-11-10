function p2_validate_future_checkpoint(run_dir,T,completed,raw_hashes)
%P2_VALIDATE_FUTURE_CHECKPOINT Fail closed on missing or orphan diagnostic raw.
    p=load(fullfile(run_dir,'params.mat'),'cfg'); cfg=p.cfg;
    q=load(fullfile(run_dir,'cases.mat'),'cases'); cases=q.cases;
    assert(istable(T) && iscell(completed) && all(cellfun(@ischar,completed)), ...
        'futurecheckpoint:Invalid','Invalid checkpoint table or completed keys.');
    assert(iscell(raw_hashes) && numel(raw_hashes)==numel(completed) && ...
        all(cellfun(@(x) ischar(x) && numel(x)==64,raw_hashes)), ...
        'futurecheckpoint:MissingHashes','A digest is required for every completed raw file.');
    files=dir(fullfile(run_dir,'raw_*.mat')); actual=sort({files.name});
    if isempty(completed)
        assert(isempty(T) && isempty(actual),'futurecheckpoint:Orphan','Uncommitted raw or rows found.');
        return;
    end
    assert(height(T)==numel(completed) && numel(unique(completed))==numel(completed) && ...
        all(ismember({'channel','snr_db','case_id'},T.Properties.VariableNames)), ...
        'futurecheckpoint:Invalid','Checkpoint rows and keys must be unique and complete.');
    keys=cell(height(T),1); names=keys;
    for i=1:height(T)
        ix=find(cfg.snr_grid==T.snr_db(i)); id=T.case_id{i}; ch=T.channel(i);
        assert(isscalar(ix) && ismember(id,{cases.id}) && isnumeric(ch) && isfinite(ch) && ...
            ch==fix(ch) && ch>=1 && ch<=cfg.num_channels, ...
            'futurecheckpoint:Invalid','Checkpoint refers to an unknown case or environment.');
        keys{i}=sprintf('%d/%d/%s',ch,ix,id);
        names{i}=sprintf('raw_c%d_s%d_%s.mat',ch,ix,id);
    end
    assert(isequal(sort(keys),sort(completed(:))) && ...
        isequal(sort(names),sort(actual(:))), ...
        'futurecheckpoint:Mismatch','Completed rows and raw files do not match.');
    for i=1:numel(keys)
        ix=find(strcmp(completed,keys{i}));
        assert(isscalar(ix) && strcmp(local_hash(fullfile(run_dir,names{i})),raw_hashes{ix}), ...
            'futurecheckpoint:HashMismatch','Saved raw differs from checkpoint digest.');
    end
    if ~any(strcmp(cfg.purpose,{'power_calibration','power_validation','pmf'}))
        p2_validate_common_raw_metrics(run_dir,T);
    else
        assert(all(ismember({'ber','error_count','frames','communication_measured'},T.Properties.VariableNames)) && ...
            all(isnan(T.ber)) && all(isnan(T.error_count)) && ...
            all(~T.communication_measured) && all(T.frames==cfg.num_frames), ...
            'futurecheckpoint:InvalidCounts','No-noise rows must retain missing communication metrics.');
        for i=1:height(T)
            x=load(fullfile(run_dir,names{i}),'artifact'); a=x.artifact;
            assert(isfield(a,'counts') && isfield(a,'scale') && isfield(a,'records') && ...
                numel(a.records)==cfg.num_frames && all(a.scale==1) && ...
                size(a.counts,1)==16 && size(a.counts,2)==numel(a.scale) && ...
                size(a.counts,3)==cfg.num_frames && all(isfinite(a.counts(:))) && ...
                all(a.counts(:)>=0) && all(a.counts(:)==fix(a.counts(:))), ...
                'futurecheckpoint:InvalidCounts','Invalid PMF raw dimensions or values.');
            totals=sum(a.counts,1);
            assert(all(totals(:)==cfg.N),'futurecheckpoint:InvalidCounts','PMF counts do not match per-frame resources.');
        end
    end
end


function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'futurecheckpoint:MissingRaw','Cannot read raw file.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
