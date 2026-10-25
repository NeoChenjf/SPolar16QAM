function out = run_16qam_energy_tradeoff(mode, resume_source)
% Default smoke; formal requires an explicit caller choice and user approval.
    if nargin==0, mode='smoke'; end
    if nargin<2, resume_source=''; end
    if ~ismember(mode,{'smoke','formal'}), error('energy:Mode','Use smoke or formal.'); end
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    cfg=config(); cfg.decoder='SC'; cfg.snr_mode='fixed_esn0';
    cfg.collect_energy_frames=true; cfg.llr_use_legacy_noisevar=false;
    cfg.partition_mode='source_entropy'; cfg.source_samples=200; cfg.source_seed=9001;
    cfg.sigma_design=10^(-20/20);
    ps=[.5,.4,.3,.2,.1]; seeds=[42,43,44]; snrs=8:20;
    cfg.num_frames=300;
    if strcmp(mode,'smoke'), snrs=[8,14,20]; cfg.num_frames=2; end
    recovered=cell(numel(seeds),numel(ps));
    if ~isempty(resume_source)
        old=load(fullfile(resume_source,'partial','completed_blocks.mat'));
        if ~strcmp(old.mode,mode) || ~isequal(old.ps,ps) || ~isequal(old.seeds,seeds) || ...
                ~isequal(old.snrs,snrs) || ~isequaln(rmfield(old.cfg,'timestamp'),rmfield(cfg,'timestamp'))
            error('energy:ResumeMismatch','Checkpoint parameters differ.');
        end
        recovered=old.blocks;
        previous_engine=load(fullfile(resume_source,'params.mat'),'engine');
        if ~strcmp(previous_engine.engine,version),error('energy:ResumeMismatch','Engine changed.');end
        current_sources=[dir(fullfile(root,'core','*.m'));dir(fullfile(root,'polar','*.m'));dir(fullfile(root,'modulation','*.m'))];
        for ii=1:numel(current_sources)
            entry=current_sources(ii); [~,subdir]=fileparts(entry.folder);
            snapshot=fullfile(resume_source,'source_snapshot',subdir,entry.name);
            if ~exist(snapshot,'file') || ~strcmp(fileread(snapshot),fileread(fullfile(entry.folder,entry.name)))
                error('energy:ResumeMismatch','Simulation source changed.');
            end
        end
    end
    out=fullfile(cfg.output_dir,[datestr(now,'yyyymmdd_HHMMSS'),'_16qam_energy_tradeoff_',mode]);
    if exist(out,'dir'), error('energy:OutputExists','Refuse overwrite.'); end
    mkdir(out); mkdir(fullfile(out,'partial')); mkdir(fullfile(out,'figures'));
    diary(fullfile(out,'run_log.txt')); cleanup=onCleanup(@() diary('off'));
    started=tic; engine=version; protocol='2026-10-09-source-entropy-S-per-SNR-GA-IF';
    save(fullfile(out,'params.mat'),'cfg','ps','seeds','snrs','engine','protocol','mode');
    % Source snapshot gives exact reproducibility even in an uncommitted tree.
    source_dir=fullfile(out,'source_snapshot'); mkdir(source_dir);
    source_dirs={'core','polar','modulation','analysis','compat'};
    for k=1:numel(source_dirs), copyfile(fullfile(root,source_dirs{k}),fullfile(source_dir,source_dirs{k})); end
    copyfile(mfilename('fullpath') + ".m",fullfile(source_dir,'run_16qam_energy_tradeoff.m'));
    copyfile(fullfile(root,'config.m'),source_dir); copyfile(fullfile(root,'setup_paths.m'),source_dir);
    v3polar=fullfile(root,'..','v3','polar'); v3snapshot=fullfile(source_dir,'v3_polar'); mkdir(v3snapshot);
    v3files={'build_stream_partition_source_mc_ga.m','shape_stream_sc.m','sc_decode_forced_full.m'};
    for vi=1:numel(v3files),copyfile(fullfile(v3polar,v3files{vi}),v3snapshot);end
    source_files={fullfile(root,'experiments','rectifier','run_16qam_energy_tradeoff.m'), ...
        fullfile(root,'core','sim_shaped_polar_16qam.m'), ...
        fullfile(root,'core','estimate_ber_hat_sc_dual.m'), ...
        fullfile(root,'polar','build_source_entropy_partition.m'), ...
        fullfile(v3polar,'build_stream_partition_source_mc_ga.m'), ...
        fullfile(v3polar,'shape_stream_sc.m'),fullfile(v3polar,'sc_decode_forced_full.m')};
    hashfid=fopen(fullfile(out,'source_sha256_manifest.txt'),'w'); if hashfid<0,error('energy:WriteFailed','source hashes');end
    hashcleanup=onCleanup(@()fclose(hashfid));
    for vi=1:numel(source_files)
        sf=fopen(source_files{vi},'rb'); bytes=fread(sf,Inf,'*uint8'); fclose(sf);
        md=java.security.MessageDigest.getInstance('SHA-256');md.update(bytes);
        digest=typecast(md.digest(),'uint8');hex=lower(reshape(dec2hex(digest,2)',1,[]));
        fprintf(hashfid,'%s  %s\n',hex,source_files{vi});
    end
    clear hashcleanup;
    fprintf('mode=%s N=%d frames=%d output=%s\n',mode,cfg.N,cfg.num_frames,out);
    source_partitions=cell(size(ps));
    for ip=1:numel(ps)
        p_vec=cfg.p_fixed; p_vec(isnan(p_vec))=ps(ip);
        source_partitions{ip}=build_source_entropy_partition( ...
            cfg.N,p_vec,cfg.sigma_design,cfg.source_samples,cfg.source_seed);
    end
    blocks=cell(numel(seeds),numel(ps)); rep=[]; frames=[];
    frame_headers={'seed','p','snr_label_dB','esn0_actual_dB','frame_id','symbols','sum_abs2','sum_abs4','N0', ...
        'errors1','errors2','errors3','errors4','block_errors1','block_errors2','block_errors3','block_errors4', ...
        'K1','K2','K3','K4','S1','S2','S3','S4'};
    for s=1:numel(seeds)
        for ip=1:numel(ps)
            cfg_run=cfg; cfg_run.seed=seeds(s);
            cfg_run.source_partition_state=source_partitions{ip};
            cfg_run.energy_checkpoint=@checkpoint;
            if isempty(recovered{s,ip})
                result=sim_shaped_polar_16qam(ps(ip),snrs,cfg_run);
                result.cfg=rmfield(result.cfg,'energy_checkpoint');
            else
                result=recovered{s,ip}; fprintf('Recovered seed=%d p=%g\n',seeds(s),ps(ip));
                for jj=1:numel(snrs),checkpoint(jj,result.energy_frames(:,:,jj),result.K,result.S_size);end
            end
            blocks{s,ip}=result;
            for j=1:numel(snrs)
                f=result.energy_frames(:,:,j); nf=size(f,1); K=result.K;
                errs=sum(sum(f(:,6:9))); bits=nf*sum(K);
                rep(end+1,:)=[seeds(s),ps(ip),snrs(j),nf,sum(f(:,2)),sum(f(:,3)),errs,bits,result.BLER(j),result.R_total]; %#ok<AGROW>
                frames=[frames;repmat([seeds(s),ps(ip),snrs(j),snrs(j)-10*log10(2)],nf,1),f, ...
                    repmat([K,result.S_size],nf,1)]; %#ok<AGROW>
            end
            save(fullfile(out,'partial','completed_blocks.mat'),'blocks','rep','frames','cfg','ps','seeds','snrs','mode');
        end
    end
    raw_rep=rep; [rep,summary,points]=compute_energy_tradeoff_stats(raw_rep);
    rep_headers={'seed','p','snr_label_dB','frames','symbols','sum_abs2','errors','info_bits','BLER_weighted','R_total', ...
        'P_mean','baseline_P_mean','E_unit','BER','Goodput'};
    summary_headers={'p','snr_label_dB','n','frames','errors','BER_mean','BER_sd','BER_lo','BER_hi', ...
        'Goodput_mean','Goodput_sd','Goodput_lo','Goodput_hi','E_mean','E_sd','E_lo','E_hi'};
    point_headers={'p','snr_label_dB','pareto','communication','energy','compromise','G_scaled','E_scaled','distance'};
    write_energy_csv(fullfile(out,'frame_results.csv'),frame_headers,frames);
    write_energy_csv(fullfile(out,'repetition_results.csv'),rep_headers,rep);
    write_energy_csv(fullfile(out,'point_summary.csv'),summary_headers,summary);
    [~,order]=ismember(points(:,1:2),summary(:,1:2),'rows');
    write_energy_csv(fullfile(out,'working_points.csv'),[point_headers,summary_headers(6:end)],[points,summary(order,6:end)]);
    elapsed=toc(started);
    save(fullfile(out,'results.mat'),'raw_rep','rep','summary','points','frames','blocks','elapsed','cfg','ps','snrs','seeds','mode');
    fid=fopen(fullfile(out,'README.txt'),'w'); if fid<0,error('energy:WriteFailed','README');end
    fprintf(fid,'16QAM energy tradeoff %s\nEngine: %s\nN=%d frames=%d seeds=[42 43 44]\n',mode,engine,cfg.N,cfg.num_frames);
    fprintf(fid,'Construction: fixed K and |S|; source conditional entropy selects S; remaining positions are GA-ranked for I/F at each SNR; every frame conditions S on its current payload with F=0.\n');
    fprintf(fid,'Fixed constellation scaling; empirical paired p=0.5 baseline=1. RF proxy, no RF-DC efficiency.\n');
    fprintf(fid,'v2 SNR parameter: actual Es/N0 = label - 3.01029995664 dB.\nGoodput=R*(1-BER), not packet throughput.\n');
    fprintf(fid,'CI: three-seed Student t, df=2, 95%%; limited precision. Pareto is descriptive within SNR.\n');
    fprintf(fid,'Elapsed simulation/statistics: %.3f seconds.\nResume source: %s\nCheckpoint: completed blocks reused in NEW directory; unfinished block reruns entire SNR vector.\n',elapsed,resume_source);
    fprintf(fid,'Rebuild: rebuild_16qam_energy_tradeoff_figures(result_directory).\n'); fclose(fid);
    rebuild_16qam_energy_tradeoff_figures(out);
    verify_energy_tradeoff_results(out);
    inputs={'frame_results.csv','repetition_results.csv','point_summary.csv','working_points.csv','params.mat','results.mat'};
    fid=fopen(fullfile(out,'sha256_manifest.txt'),'w'); if fid<0,error('energy:WriteFailed','hash manifest');end
    hash_cleanup=onCleanup(@()fclose(fid));
    for k=1:numel(inputs)
        stream=fopen(fullfile(out,inputs{k}),'rb'); if stream<0,error('energy:ReadFailed','hash input');end
        bytes=fread(stream,Inf,'*uint8'); fclose(stream);
        md=java.security.MessageDigest.getInstance('SHA-256');md.update(bytes);
        digest=typecast(md.digest(),'uint8'); hex=lower(reshape(dec2hex(digest,2)',1,[]));
        fprintf(fid,'%s  %s\n',hex,inputs{k});
    end
    clear hash_cleanup;
    fprintf('DONE %.3f seconds\n',toc(started));

    function checkpoint(j,f,K,S)
        path=fullfile(out,'partial',sprintf('seed%d_p%02d_snr%02d.csv',seeds(s),round(100*ps(ip)),snrs(j)));
        data=[repmat([seeds(s),ps(ip),snrs(j),snrs(j)-10*log10(2)],size(f,1),1),f,repmat([K,S],size(f,1),1)];
        write_energy_csv(path,frame_headers,data);
    end
end
