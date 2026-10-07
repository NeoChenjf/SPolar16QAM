function out=benchmark_energy_tradeoff()
% Short 120-frame timing probe; does not change the formal grid.
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);setup_paths;
    cfg=config();cfg.num_frames=20;cfg.collect_energy_frames=true;cfg.seed=42;
    ps=[.5,.1];snrs=[8,14,20];
    out=fullfile(cfg.output_dir,[datestr(now,'yyyymmdd_HHMMSS'),'_energy_timing_diagnostic']);
    if exist(out,'dir'),error('energy:OutputExists','Refuse overwrite');end
    mkdir(out);diary(fullfile(out,'run_log.txt'));cleanup=onCleanup(@()diary('off'));
    results=cell(1,2); seconds=zeros(1,2);
    for i=1:2,t=tic;results{i}=sim_shaped_polar_16qam(ps(i),snrs,cfg);seconds(i)=toc(t);end
    save(fullfile(out,'results.mat'),'cfg','ps','snrs','results','seconds');
    write_energy_csv(fullfile(out,'timing.csv'),{'p','frames','seconds'},[ps',repmat(60,2,1),seconds']);
    fid=fopen(fullfile(out,'README.txt'),'w');assert(fid>=0);
    fprintf(fid,'Timing diagnostic only: N=1024, 2p x 3SNR x 20frames = 120 frames. No formal inference.\n');
    fprintf(fid,'Seconds: %s\n58500 frame linear estimate: %.1f seconds; add IO and safety margin.\n',mat2str(seconds),sum(seconds)/120*58500);fclose(fid);
end
