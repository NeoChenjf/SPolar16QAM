function rebuild_16qam_energy_tradeoff_figures(out)
% Rebuild only from saved CSV; mark raw nonpositive BER separately.
    t=readmatrix(fullfile(out,'point_summary.csv'));
    w=readmatrix(fullfile(out,'working_points.csv'));
    ps=sort(unique(t(:,1)),'descend'); snrs=unique(t(:,2)); palette=parula(256);
    colors=palette(round(linspace(1,205,numel(snrs))),:);
    positives=t(t(:,6)>0,6); floor_ber=1e-6;
    if ~isempty(positives),floor_ber=min(positives)/5;end
    cfg=load(fullfile(out,'params.mat'),'mode');
    names={'ber_snr','energy_p','ber_energy','goodput_energy_pareto'};
    f=figure('Visible','off','Color','w','Position',[40 40 1100 720]); hold on;
    for p=ps'
        rows=sortrows(t(t(:,1)==p,:),2); y=rows(:,6);
        positive=y>0;
        errorbar(rows(positive,2),y(positive),y(positive)-max(rows(positive,8),floor_ber), ...
            rows(positive,9)-y(positive),'-o','DisplayName',sprintf('p=%.1f',p));
        if any(~positive), plot(rows(~positive,2),repmat(floor_ber,sum(~positive),1),'v','DisplayName','zero errors (display floor)'); end
    end
    set(gca,'YScale','log'); xlabel('v2 SNR parameter (dB)'); ylabel('BER'); grid on; legend('Location','eastoutside');
    title(sprintf('%s: actual Es/N0 = label - 3.0103 dB; seed t CI',cfg.mode)); finish(f,names{1});
    f=figure('Visible','off','Color','w','Position',[40 40 1500 1100]);
    for j=1:numel(snrs)
        subplot(ceil(numel(snrs)/4),4,j); rows=sortrows(t(t(:,2)==snrs(j),:),1);
        errorbar(rows(:,1),rows(:,14),rows(:,14)-rows(:,16),rows(:,17)-rows(:,14),'-o');
        xlabel('p'); ylabel('Normalized RF energy'); title(sprintf('%s SNR=%g dB',cfg.mode,snrs(j))); grid on;
    end
    finish(f,names{2});
    for kind=3:4
        f=figure('Visible','off','Color','w','Position',[40 40 1100 720]); hold on;
        for j=1:numel(snrs)
            rows=sortrows(t(t(:,2)==snrs(j),:),1); col=6; if kind==4,col=10;end
            plot(rows(:,14),rows(:,col),'-o','Color',colors(j,:));
            if kind==4
                wp=w(w(:,2)==snrs(j) & w(:,3)==1,:);
                scatter(wp(:,18),wp(:,14),90,colors(j,:),'s','LineWidth',1.5);
            end
        end
        colormap(colors); caxis([min(snrs),max(snrs)]); cb=colorbar; cb.Label.String='v2 SNR parameter (dB)';
        xlabel('Normalized transmit RF energy (p=0.5 baseline=1)');
        if kind==3,ylabel('BER');else,ylabel('Goodput = R (1-BER)');end
        if kind==4, title(sprintf('%s: all SNR means; squares = per-SNR Pareto',cfg.mode));
        else,title(sprintf('%s: all SNR means',cfg.mode));end
        grid on; finish(f,names{kind});
    end
    fid=fopen(fullfile(out,'figure_manifest.txt'),'w'); if fid<0,error('energy:WriteFailed','manifest');end
    fprintf(fid,'Source: point_summary.csv, working_points.csv, params.mat; all saved rows.\n');
    fprintf(fid,'Mode=%s; 3 seeds; frames recorded in source. CI=t(df=2); raw intervals in CSV.\n',cfg.mode);
    fprintf(fid,'BER display floor=%.17g (1/5 smallest positive mean); lower CI clipped; zero errors marked with explicit legend.\nRF proxy, no rectification. Pareto descriptive, same SNR only.\n',floor_ber); fclose(fid);
    function finish(fig,name)
        cleanup=onCleanup(@() close(fig));
        savefig(fig,fullfile(out,'figures',[name,'.fig']));
        exportgraphics(fig,fullfile(out,'figures',[name,'.png']),'Resolution',160);
        exportgraphics(fig,fullfile(out,'figures',[name,'.pdf']),'ContentType','vector');
    end
end
