function out_dir = rebuild_phaseA_figures_from_energy_results(source_dir)
% Rebuild Phase A display figures from the verified energy-tradeoff run.
% This is post-processing only; it does not start or alter Monte Carlo data.
    source_dir=char(source_dir);
    summary_path=fullfile(source_dir,'point_summary.csv');
    if exist(summary_path,'file')~=2
        error('phaseA:MissingSummary','Missing point_summary.csv: %s',summary_path);
    end
    t=readmatrix(summary_path);
    required_cols=17;
    if size(t,2)<required_cols || any(~isfinite(t(:,1:17)),'all')
        error('phaseA:BadSummary','Summary must contain finite verified statistics.');
    end
    root=fileparts(fileparts(mfilename('fullpath')));
    out_dir=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_phaseA_figures_from_energy_tradeoff']);
    if exist(out_dir,'dir'),error('phaseA:OutputExists','Refuse overwrite.');end
    fig_dir=fullfile(out_dir,'figures');mkdir(out_dir);mkdir(fig_dir);
    copyfile(summary_path,out_dir);
    copyfile(fullfile(source_dir,'README.txt'),out_dir);
    pvals=sort(unique(t(:,1)),'descend');

    % F04: full-chain BER/SNR with the common run's seed-based confidence intervals.
    f=figure('Visible','off','Color','w','Position',[50 50 1100 720]);hold on;
    for p=pvals'
        r=sortrows(t(t(:,1)==p,:),2); y=r(:,6); keep=y>0;
        errorbar(r(keep,2),y(keep),max(y(keep)-r(keep,8),0),max(r(keep,9)-y(keep),0),'-o', ...
            'DisplayName',sprintf('p=%.1f',p));
        if any(~keep),plot(r(~keep,2),ones(sum(~keep),1)*1e-6,'v','DisplayName',sprintf('p=%.1f zero errors',p));end
    end
    set(gca,'YScale','log');xlabel('v2 SNR parameter (dB)');ylabel('BER');grid on;
    title('Stage A full-chain BER (source-entropy S, GA I/F)');legend('Location','eastoutside');
    savefig(f,fullfile(fig_dir,'F04_phaseA_fullchain_ber.fig'));
    exportgraphics(f,fullfile(fig_dir,'F04_phaseA_fullchain_ber.png'),'Resolution',160);
    exportgraphics(f,fullfile(fig_dir,'F04_phaseA_fullchain_ber.pdf'),'ContentType','vector');close(f);

    % F05: cross-SNR goodput/energy view; square-free figure keeps all tested points visible.
    f=figure('Visible','off','Color','w','Position',[50 50 1100 720]);hold on;
    snrs=unique(t(:,2)); colors=parula(max(numel(snrs),2));
    for j=1:numel(snrs)
        r=sortrows(t(t(:,2)==snrs(j),:),1);
        plot(r(:,14),r(:,10),'-o','Color',colors(j,:), ...
            'DisplayName',sprintf('SNR label=%g dB',snrs(j)));
    end
    xlabel('Normalized transmit RF energy (p=0.5 baseline=1)');
    ylabel('Goodput = R(1-BER)');grid on;
    title('Stage A goodput-energy tradeoff; color denotes SNR');
    colormap(colors);caxis([min(snrs),max(snrs)]);cb=colorbar;cb.Label.String='v2 SNR parameter (dB)';
    savefig(f,fullfile(fig_dir,'F05_phaseA_goodput_energy.fig'));
    exportgraphics(f,fullfile(fig_dir,'F05_phaseA_goodput_energy.png'),'Resolution',160);
    exportgraphics(f,fullfile(fig_dir,'F05_phaseA_goodput_energy.pdf'),'ContentType','vector');close(f);

    % F07 focused display: retain only label=14 dB, including uncertainty bars.
    r=t(t(:,2)==14,:);
    if isempty(r),error('phaseA:Missing14dB','The source run has no label=14 dB points.');end
    r=sortrows(r,1);
    f=figure('Visible','off','Color','w','Position',[50 50 900 600]);
    errorbar(r(:,1),r(:,14),r(:,14)-r(:,16),r(:,17)-r(:,14),'-o','LineWidth',1.5);
    xlabel('Shaping parameter p');ylabel('Normalized transmit RF energy');
    title('Energy versus p at v2 SNR label=14 dB');grid on;
    savefig(f,fullfile(fig_dir,'F07_energy_p_label14db.fig'));
    exportgraphics(f,fullfile(fig_dir,'F07_energy_p_label14db.png'),'Resolution',160);
    exportgraphics(f,fullfile(fig_dir,'F07_energy_p_label14db.pdf'),'ContentType','vector');close(f);

    % Preserve a precise link to the data and post-processing source.
    source_script=[mfilename('fullpath'),'.m'];
    copyfile(source_script,out_dir);
    fid=fopen(fullfile(out_dir,'README.txt'),'w');
    if fid<0,error('phaseA:WriteFailed','Cannot write README.');end
    c=onCleanup(@()fclose(fid));
    fprintf(fid,'Post-processing only; no Monte Carlo was run.\nSource result: %s\n',source_dir);
    fprintf(fid,'Source data: point_summary.csv, copied into this directory.\n');
    fprintf(fid,'F04 uses BER mean and seed t confidence intervals; F05 uses Goodput_mean versus E_mean; F07 isolates SNR label 14 dB.\n');
    fprintf(fid,'The SNR label is not actual Es/N0: the source README defines actual Es/N0 = label - 3.0103 dB. Energy is an RF proxy, not rectified DC.\n');
    clear c;
    input_bytes=read_bytes(summary_path); source_bytes=read_bytes(source_script);
    write_hashes(fullfile(out_dir,'sha256_manifest.txt'),summary_path,input_bytes,source_script,source_bytes);
end

function b=read_bytes(path)
    f=fopen(path,'rb');if f<0,error('phaseA:ReadFailed','Cannot read %s',path);end
    c=onCleanup(@()fclose(f));b=fread(f,Inf,'*uint8');clear c;
end

function write_hashes(path,input_path,input_bytes,source_path,source_bytes)
    f=fopen(path,'w');if f<0,error('phaseA:WriteFailed','Cannot write hash manifest.');end
    c=onCleanup(@()fclose(f));
    fprintf(f,'%s  %s\n',sha256(input_bytes),input_path);
    fprintf(f,'%s  %s\n',sha256(source_bytes),source_path);
end

function h=sha256(bytes)
    md=java.security.MessageDigest.getInstance('SHA-256');md.update(bytes);
    d=typecast(md.digest(),'uint8');h=lower(reshape(dec2hex(d,2)',1,[]));
end
