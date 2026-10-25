function path = p2_batch_power_check(dirs, power_file, out_dir)
%P2_BATCH_POWER_CHECK Stop before dependent jobs if the frozen 1% gate fails.
% Same per-seed/channel/SNR/case total and component definition as final audit.
    assert(~isfolder(out_dir)); mkdir(out_dir); loaded=load(power_file,'power'); power=loaded.power;
    rows=cell(0,8); seeds=[];
    for d=1:numel(dirs)
        params=load(fullfile(dirs{d},'params.mat'),'cfg'); cfg=params.cfg;
        assert(strcmp(cfg.mode,'formal') && strcmp(cfg.purpose,'power_validation'));
        assert(~ismember(cfg.seed,seeds) && ~ismember(cfg.seed,power(1).calibration_seeds));
        seeds(end+1)=cfg.seed; %#ok<AGROW>
        files=dir(fullfile(dirs{d},'raw_*.mat'));
        assert(numel(files)==numel(power)*cfg.num_channels*numel(cfg.snr_grid));
        for i=1:numel(files)
            token=regexp(files(i).name,'^raw_c(\d+)_s(\d+)_(.+)\.mat$','tokens','once');
            c=find(strcmp({power.case_id},token{3})); assert(isscalar(c));
            raw=load(fullfile(files(i).folder,files(i).name),'artifact'); a=raw.artifact;
            assert(isequal(a.scale,power(c).scale)); records=[a.records{:}];
            component=vertcat(records.group_tx); total_error=abs(mean([records.tx])-1);
            group_error=max(abs(mean(component,1)./power(c).target_group_power-1));
            rows(end+1,:)={cfg.seed,str2double(token{1}),cfg.snr_grid(str2double(token{2})), ...
                token{3},total_error,group_error,total_error<=.01&&group_error<=.01,numel(records)}; %#ok<AGROW>
        end
    end
    assert(numel(seeds)==3 && ~isempty(rows));
    T=cell2table(rows,'VariableNames',{'seed','channel','snr_db','case_id','total_relative_error', ...
        'max_group_relative_error','pass','frames'});
    writetable(T,fullfile(out_dir,'power_gate.csv'));
    gate=struct('power_pass',all(T.pass),'failed_cells',sum(~T.pass), ...
        'max_total_relative_error',max(T.total_relative_error),'max_group_relative_error',max(T.max_group_relative_error), ...
        'scope','Frozen 1% power gate; no PMF or model gate is implied.');
    path=fullfile(out_dir,'power_gate.json'); fid=fopen(path,'w'); fprintf(fid,'%s',jsonencode(gate)); fclose(fid);
end
