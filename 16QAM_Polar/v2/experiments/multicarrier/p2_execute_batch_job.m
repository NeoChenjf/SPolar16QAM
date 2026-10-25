function out = p2_execute_batch_job(protocol, approval, job_id, artifacts, marker)
%P2_EXECUTE_BATCH_JOB Resume the unique matching approved job and publish its path.
% Scheduling only: approved experiment source/parameters are not changed.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths();
    candidates=dir(fullfile(root,'results','*p2_formal_*')); matches={};
    for i=1:numel(candidates)
        path=fullfile(candidates(i).folder,candidates(i).name); params=fullfile(path,'params.mat');
        if ~isfile(params), continue; end
        data=load(params,'cfg'); cfg=data.cfg;
        if strcmp(cfg.job_id,job_id) && strcmp(cfg.frozen_test_manifest,protocol) && strcmp(cfg.approval_file,approval)
            matches{end+1}=path; %#ok<AGROW>
        end
    end
    assert(numel(matches)<=1,'Multiple matching jobs; do not guess a resume target.');
    if ~isempty(matches), artifacts.resume_dir=matches{1}; end
    out=run_p2_registered_job(protocol,approval,job_id,artifacts);
    fid=fopen(marker,'w','n','UTF-8'); assert(fid>=0); fprintf(fid,'%s',out); fclose(fid);
end
