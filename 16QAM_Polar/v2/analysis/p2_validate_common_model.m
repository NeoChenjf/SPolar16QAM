function manifest = p2_validate_common_model(model_file)
%P2_VALIDATE_COMMON_MODEL Audit exploratory model against its current sources.
% Current consistency is not historical authenticity or formal acceptance.
    a=load(model_file,'model'); m=a.model; d=m.training_dir;
    assert(strcmp(m.asset_status,'exploratory_not_formal'), ...
        'modelcheck:InvalidStatus','Only exploratory models are supported.');
    p=load(fullfile(d,'params.mat'),'cfg'); cfg=p.cfg;
    assert(isequaln(cfg,m.training_cfg),'modelcheck:ConfigMismatch','Training config differs.');
    p2_validate_common_pmf(cfg.pmf_file);
    manifest=p2_model_training_manifest(d);
    assert(strcmp(manifest.pmf_sha256,m.pmf_sha256), ...
        'modelcheck:PMFChanged','Model PMF hash differs from current PMF.');
    p2_validate_common_references(d);
    T=readtable(fullfile(d,'repetitions.csv')); fresh=p2_calibrate_model(T);
    assert(strcmp(fresh.fit_status,m.fit_status) && strcmp(fresh.version,m.version) && ...
        fresh.input_rows==m.input_rows && fresh.training_rows==m.training_rows && ...
        isequal(size(fresh.parameters),size(m.parameters)) && ...
        all(abs(fresh.parameters-m.parameters)<=1e-10*max(1,abs(fresh.parameters))), ...
        'modelcheck:Mismatch','Model does not match reconstructed fit.');
end
