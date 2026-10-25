function out = analyze_p2_auxiliary(preflight_dir, out)
%ANALYZE_P2_AUXILIARY Focused pooled PMF and S diagnostics, pilot evidence only.
    run=load(fullfile(preflight_dir,'preflight.mat'),'pmf_dirs');
    assert(~isfolder(out)); mkdir(out);
    kinds={'shaped','random_s','donor_s','native'}; ps=[.3,.1]; labels=de2bi((0:15)',4,'left-msb');
    points=qammod((0:15)',16,'gray','UnitAveragePower',true);
    rows={}; marginals={}; joint=cell(2,4); probabilities=cell(2,4); correlations=cell(2,3); source_H=cell(2,1);
    for ip=1:2
        base=sprintf('uniform_p%02d',round(10*ps(ip)));
        target=prod(bsxfun(@power,[.5,ps(ip),.5,ps(ip)],labels).* ...
            bsxfun(@power,[.5,1-ps(ip),.5,1-ps(ip)],1-labels),2);
        for ik=1:4
            counts=zeros(16,1); frames=0; sums=[]; cross=[]; probe=[]; indices=[];
            for d=1:numel(run.pmf_dirs)
                path=fullfile(run.pmf_dirs{d},['raw_c1_s1_' base '_' kinds{ik} '.mat']);
                raw=load(path,'artifact'); a=raw.artifact;
                % One reliability group only: no accidental pooling of common samples across strategies.
                counts=counts+sum(a.counts(:,1,:),3); f=size(a.counts,3); frames=frames+f;
                st=a.states{1};
                if ik<4
                    if isempty(sums), sums=zeros(st.N,4); end
                    sums=sums+a.u_ones{1}; indices=st.S{2};
                    probe=a.s_probe{1,2};
                    if isempty(cross), cross=zeros(numel(probe)); end
                    cross=cross+a.s_cross{1,2}; source_H{ip}=st.source_entropy{2}(indices);
                end
            end
            empirical=counts/sum(counts); joint{ip,ik}=empirical;
            rows(end+1,:)={ps(ip),kinds{ik},frames,.5*sum(abs(empirical-1/16)), ...
                .5*sum(abs(empirical-target)),sum(abs(points).^2.*empirical), ...
                '3 seeds x 8 codewords; exploratory, not formal PMF acceptance'}; %#ok<AGROW>
            if ik<4
                q=sums(indices,2)/frames; probabilities{ip,ik}=q;
                entropy=zeros(size(q)); ok=q>0&q<1;
                entropy(ok)=-q(ok).*log2(q(ok))-(1-q(ok)).*log2(1-q(ok));
                for j=1:numel(indices)
                    marginals(end+1,:)={ps(ip),kinds{ik},indices(j),frames,q(j),entropy(j),source_H{ip}(j)}; %#ok<AGROW>
                end
                mu=sums(probe,2)/frames; covariance=cross/frames-mu*mu';
                variance=mu.*(1-mu); denominator=sqrt(variance*variance');
                corr=covariance./denominator; corr(denominator==0)=nan; correlations{ip,ik}=corr;
            end
        end
    end
    T=cell2table(rows,'VariableNames',{'source_p','control','codewords','tv_uniform','tv_shaping_target','symbol_energy','scope'});
    S=cell2table(marginals,'VariableNames',{'source_p','control','S_index','codewords','p_one','marginal_entropy','source_MC_conditional_entropy'});
    writetable(T,fullfile(out,'auxiliary_distribution_summary.csv'));
    writetable(S,fullfile(out,'S_statistics_pooled_24_codewords.csv'));
    save(fullfile(out,'diagnostic.mat'),'T','S','joint','probabilities','correlations','source_H');
    f=figure('Visible','off','Position',[60,60,1300,500]);
    for ip=1:2
        subplot(1,2,ip); bar(0:15,[joint{ip,1},joint{ip,2},joint{ip,3}]); hold on;
        yline(1/16,'k--','Uniform','HandleVisibility','off'); xlabel('MATLAB Gray label (integer)');
        ylabel('Empirical symbol probability'); title(sprintf('Source p = %.1f; 24 codewords',ps(ip)));
        legend({'Message-conditioned S','Independent fair S','Independent donor S'},'Location','northoutside'); grid on;
    end
    local_save(f,out,'auxiliary_pmf');
    f=figure('Visible','off','Position',[60,60,1300,500]);
    for ip=1:2
        subplot(1,2,ip); histogram(probabilities{ip,1},0:.05:1,'Normalization','probability'); hold on;
        histogram(probabilities{ip,2},0:.05:1,'Normalization','probability');
        histogram(probabilities{ip,3},0:.05:1,'Normalization','probability');
        xlabel('Observed P(S_i = 1), 24 messages'); ylabel('Fraction of S positions');
        title(sprintf('p = %.1f, stream 2; marginal statistics only',ps(ip)));
        legend({'Message-conditioned','Independent fair','Independent donor'},'Location','northoutside');
    end
    local_save(f,out,'S_marginals');
    f=figure('Visible','off','Position',[60,60,1250,800]);
    for ip=1:2
        for ik=1:3
            subplot(2,3,(ip-1)*3+ik); image=imagesc(correlations{ip,ik},[-1,1]);
            set(image,'AlphaData',isfinite(correlations{ip,ik})); set(gca,'Color',[.85,.85,.85]);
            axis square; colorbar;
            title(sprintf('p=%.1f %s',ps(ip),strrep(kinds{ik},'_',' ')));
            xlabel('S probe index'); ylabel('S probe index');
        end
    end
    local_save(f,out,'S_probe_correlations');
    fid=fopen(fullfile(out,'README.txt'),'w'); cleaner=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'Exploratory 3 seeds x 8 independent codewords per configuration, group 1 only.\n');
    fprintf(fid,'Random-S coverage has a separate exact generator proof. Empirical charts are NOT 3x80 PMF acceptance.\n');
    fprintf(fid,'S marginal entropy is a biased finite-sample estimate, not source conditional entropy or joint entropy.\n');
    fprintf(fid,'Pairwise correlations do not establish independence or characterize the full S-message relationship; gray is undefined (zero sample variance).\n');
    fprintf(fid,'Donor S retains an independently generated S vector, not guaranteed uniform QAM.\n');
    fprintf(fid,'PDF exported as image to avoid vector font-cache restriction; FIG retained.\n');
    disp(T); fprintf('P2_AUXILIARY_ANALYSIS: %s\n',out);
end

function local_save(f,out,name)
    exportgraphics(f,fullfile(out,[name '.png']),'Resolution',180);
    exportgraphics(f,fullfile(out,[name '.pdf']),'ContentType','image','Resolution',200);
    savefig(f,fullfile(out,[name '.fig'])); close(f);
end
