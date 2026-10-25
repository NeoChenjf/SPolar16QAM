function model_path = p2_freeze_model(calibration_dirs, out_dir)
%P2_FREEZE_MODEL Fit once on declared training rows, save provenance and freeze.
    T=table(); training_seeds=[]; training_modes=cell(1,numel(calibration_dirs)); power_hash='';
    for i=1:numel(calibration_dirs)
        p=load(fullfile(calibration_dirs{i},'params.mat'),'cfg');
        assert(strcmp(p.cfg.purpose,'model_calibration'));
        training_modes{i}=p.cfg.mode;
        current_hash=local_hash(p.cfg.power_file);
        if isempty(power_hash), power_hash=current_hash; else, assert(strcmp(power_hash,current_hash)); end
        assert(~any(ismember(p.cfg.strategy_p,p.cfg.heldout_p,'rows')));
        assert(~ismember(p.cfg.seed,training_seeds),'Repeated training seed.');
        training_seeds(end+1)=p.cfg.seed; %#ok<AGROW>
        R=readtable(fullfile(calibration_dirs{i},'repetitions.csv'));
        if isempty(T), T=R; else, T=[T;R]; end %#ok<AGROW>
    end
    model=p2_calibrate_model(T); model.calibration_dirs=calibration_dirs;
    model.training_seeds=training_seeds;
    model.training_modes=training_modes; model.power_sha256=power_hash;
    if ~isfolder(out_dir), mkdir(out_dir); end
    model_path=fullfile(out_dir,'frozen_model.mat');
    assert(~isfile(model_path),'Refusing to overwrite a frozen model.');
    save(model_path,'model'); writetable(T,fullfile(out_dir,'model_training_rows.csv'));
end

function value=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0); bytes=fread(fid,inf,'*uint8'); fclose(fid);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
