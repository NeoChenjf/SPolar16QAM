function model_path = p2_common_freeze_model(training_dir)
%P2_COMMON_FREEZE_MODEL Freeze exploratory calibration, never formal evidence.
    loaded=load(fullfile(training_dir,'params.mat'),'cfg'); cfg=loaded.cfg;
    assert(strcmp(cfg.purpose,'model_calibration') && ~strcmp(cfg.mode,'formal') && ...
        cfg.predict && isfile(cfg.pmf_file), ...
        'commonmodel:InvalidRole','Only exploratory model_calibration runs can train.');
    rows=readtable(fullfile(training_dir,'repetitions.csv'));
    assert(all(strcmp(rows.purpose,'model_calibration')) && all(rows.seed==cfg.seed), ...
        'commonmodel:InvalidRows','Training rows have an unexpected role or seed.');
    model=p2_calibrate_model(rows);
    model.training_cfg=cfg; model.training_dir=training_dir;
    model.pmf_sha256=local_hash(cfg.pmf_file);
    model.asset_status='exploratory_not_formal';
    model_path=fullfile(training_dir,'frozen_exploratory_model.mat');
    assert(~isfile(model_path),'commonmodel:Exists','Refusing to overwrite frozen model.');
    save(model_path,'model');
end
function value=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'commonmodel:MissingPMF','Missing training PMF.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
