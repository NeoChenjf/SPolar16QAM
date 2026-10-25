function out = run_p2_registered_job(protocol_file, approval_file, job_id, artifacts)
%RUN_P2_REGISTERED_JOB Execute one approved, source-bound job; checkpoint per job.
% This function does not create approval records or auto-start subsequent jobs.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    project=fileparts(fileparts(root)); addpath(root); setup_paths();
    if nargin<4, artifacts=struct(); end
    protocol=jsondecode(fileread(protocol_file)); approval=jsondecode(fileread(approval_file));
    assert(approval.approved && strcmp(approval.protocol_sha256,local_hash(protocol_file)), ...
        'No approval bound to this protocol.');
    for i=1:numel(protocol.source_files)
        file=protocol.source_files(i);
        assert(strcmp(file.sha256,local_hash(fullfile(project,file.path))), ...
            'Source changed after protocol freeze: %s',file.path);
    end
    index=find(strcmp({protocol.jobs.job_id},job_id)); assert(isscalar(index),'Unknown or duplicate job.');
    job=protocol.jobs(index); cfg=p2_default_config();
    names=fieldnames(job);
    for i=1:numel(names)
        if isfield(cfg,names{i}), cfg.(names{i})=job.(names{i}); end
    end
    cfg.controls=cellstr(string(job.controls(:)))';
    cfg.strategy_names=cellstr(string(job.strategy_names(:)))'; cfg.snr_grid=job.snr_grid(:)';
    cfg.mode='formal'; cfg.budget_approved=true; cfg.approval_file=approval_file;
    cfg.frozen_test_manifest=protocol_file;
    cfg.templates_file=fullfile(project,protocol.templates.path);
    assert(strcmp(local_hash(cfg.templates_file),protocol.templates.sha256),'Template artifact changed.');
    fields=fieldnames(artifacts); allowed={'power_file','gate_file','model_file','resume_dir'};
    assert(all(ismember(fields,allowed)),'Unexpected runtime artifact override.');
    for i=1:numel(fields), cfg.(fields{i})=artifacts.(fields{i}); end
    out=run_p2_mechanism(cfg);
end

function value=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'Missing artifact.'); bytes=fread(fid,inf,'*uint8'); fclose(fid);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
