function gate_path = p2_audit_acceptance(power_dirs, pmf_dirs, power_file, model_file, out_dir)
%P2_AUDIT_ACCEPTANCE Evidence-based frozen gates, never inferred from file existence.
% Requires 3 independent seeds, >=80 frames per PMF seed/case/SNR/group.
    assert(~isfolder(out_dir)); mkdir(out_dir);
    frozen=load(power_file,'power'); power=frozen.power;
    validation_seeds=[]; power_rows={}; pmf_rows={};
    for d=1:numel(power_dirs)
        p=load(fullfile(power_dirs{d},'params.mat'),'cfg'); cfg=p.cfg;
        assert(strcmp(cfg.purpose,'power_validation'));
        assert(~ismember(cfg.seed,power(1).calibration_seeds));
        assert(~ismember(cfg.seed,validation_seeds)); validation_seeds(end+1)=cfg.seed; %#ok<AGROW>
        files=dir(fullfile(power_dirs{d},'raw_*.mat'));
        assert(numel(files)==numel(power)*cfg.num_channels*numel(cfg.snr_grid),'Power coverage incomplete.');
        for f=1:numel(files)
            token=regexp(files(f).name,'^raw_c(\d+)_s(\d+)_(.+)\.mat$','tokens','once');
            id=token{3}; c=find(strcmp({power.case_id},id)); assert(isscalar(c));
            raw=load(fullfile(files(f).folder,files(f).name),'artifact'); a=raw.artifact;
            assert(isequal(a.scale,power(c).scale));
            records=[a.records{:}]; groups=vertcat(records.group_tx);
            total=mean([records.tx]); relative=abs(mean(groups,1)./power(c).target_group_power-1);
            power_rows(end+1,:)={cfg.seed,str2double(token{1}),cfg.snr_grid(str2double(token{2})), ...
                id,total,abs(total-1),max(relative),abs(total-1)<=.01&&all(relative<=.01)}; %#ok<AGROW>
        end
        ids=unique(power_rows(cell2mat(power_rows(:,1))==cfg.seed,4));
        assert(numel(ids)==numel(power),'Incomplete power validation case set.');
    end
    pmf_seeds=[];
    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'..','v3','analysis'));
    for d=1:numel(pmf_dirs)
        p=load(fullfile(pmf_dirs{d},'params.mat'),'cfg'); cfg=p.cfg;
        assert(strcmp(cfg.purpose,'pmf') && ~ismember(cfg.seed,pmf_seeds));
        pmf_seeds(end+1)=cfg.seed; %#ok<AGROW>
        files=dir(fullfile(pmf_dirs{d},'raw_*.mat'));
        assert(numel(files)==numel(power)*cfg.num_channels*numel(cfg.snr_grid),'PMF coverage incomplete.');
        for f=1:numel(files)
            token=regexp(files(f).name,'^raw_c(\d+)_s(\d+)_(.+)\.mat$','tokens','once');
            raw=load(fullfile(files(f).folder,files(f).name),'artifact'); a=raw.artifact;
            c=find(strcmp({power.case_id},token{3})); assert(isscalar(c));
            for g=1:numel(a.states)
                [target,role,required]=p2_distribution_reference(a.states{g},power(c).pmf(:,g));
                psym=reshape(a.counts(:,g,:),16,[])/cfg.N;
                assert(size(psym,2)>=80,'PMF cluster budget below 80 frames.');
                stats=cluster_bootstrap_tv(psym,target,2000,19701+g);
                pmf_rows(end+1,:)={cfg.seed,str2double(token{1}),cfg.snr_grid(str2double(token{2})), ...
                    token{3},g,stats.n_frames,stats.tv_point,stats.tv_upper95,stats.tv_upper95<=.05,role,required}; %#ok<AGROW>
            end
        end
    end
    P=cell2table(power_rows,'VariableNames',{'seed','channel','snr_db','case_id','tx_power', ...
        'total_relative_error','max_group_relative_error','pass'});
    Q=cell2table(pmf_rows,'VariableNames',{'seed','channel','snr_db','case_id','group','frames', ...
        'tv_point','tv_upper95','pass','reference_role','required_target'});
    assert(~isempty(P)&&~isempty(Q),'Missing gate observations.');
    assert(numel(validation_seeds)>=3 && numel(pmf_seeds)>=3,'Three independent seeds per gate required.');
    assert(isempty(intersect(pmf_seeds,power(1).calibration_seeds)));
    assert(isempty(intersect(pmf_seeds,validation_seeds)));
    % Fail closed if any seed has incomplete PMF coverage of its power cases.
    for seed=pmf_seeds
        S=Q(Q.seed==seed,:); assert(numel(unique(S.case_id))==numel(power));
    end
    test_p2_mechanism();
    model_hash=''; if ~isempty(model_file), model_hash=local_hash(model_file); end
    assert(any(Q.required_target),'Empty mandatory PMF scope.');
    gates=struct('power_pass',all(P.pass),'pmf_pass',all(Q.pass(Q.required_target)), ...
        'diagnostic_model_pass',all(Q.pass(~Q.required_target)),'contract_pass',true, ...
        'power_sha256',local_hash(power_file),'model_sha256',model_hash, ...
        'scope','Acceptance of artifacts only; not model accuracy or RF/DC evidence');
    writetable(P,fullfile(out_dir,'power_gate.csv')); writetable(Q,fullfile(out_dir,'pmf_gate.csv'));
    gate_path=fullfile(out_dir,'gates.json'); fid=fopen(gate_path,'w');
    fprintf(fid,'%s',jsonencode(gates)); fclose(fid);
end

function value=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'Missing artifact.'); bytes=fread(fid,inf,'*uint8'); fclose(fid);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
