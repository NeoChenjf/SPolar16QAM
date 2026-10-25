function analyze_b4_equal_power_p1(p1_root)
% Analyze the frozen, equal-time-power B4 P1 formal run.
if nargin < 1 || isempty(p1_root), error('Pass the P1 orchestration directory.'); end
p1_root=char(p1_root);
formal_dir=strtrim(fileread(fullfile(p1_root,'FORMAL_RESULT_PATH.txt')));
T=readtable(fullfile(formal_dir,'b4b_repetition_results.csv'));
if height(T)~=30*numel(unique(T.snr_dB))*6, error('Unexpected/incomplete formal row count.'); end
if height(unique(T(:,{'strategy','realization','snr_dB'}),'rows'))~=height(T), error('Duplicate strategy/channel/SNR keys.'); end
if any(T.frames~=50), error('P1 formal repetitions must contain exactly 50 frames.'); end
for it=1:numel(unique(T.strategy))
    st=unique(T.strategy,'stable'); Q=T(strcmp(T.strategy,st{it}),:);
    if abs(mean(Q.tx_ofdm_time_power)-1)>0.01, error('Mean formal transmit power exceeds the 1%% frozen-power gate for %s.',st{it}); end
end
assert(all(strcmp(T.power_mode,'equal_time_power')),'Formal rows have inconsistent power mode.');
snrs=unique(T.snr_dB); strategies=unique(T.strategy,'stable');
summary=cell(numel(snrs)*numel(strategies),16); r=0;
paired=cell(numel(snrs)*(numel(strategies)-1)*4,9); pr=0;
gate=cell(numel(snrs)*numel(strategies),12); gr=0;
pareto=cell(numel(snrs)*numel(strategies),5); qr=0;
rng(90210,'twister'); B=2000;
for is=1:numel(snrs)
    s=snrs(is); base=T(strcmp(T.strategy,'uniform_p05') & T.snr_dB==s,:);
    for it=1:numel(strategies)
        st=strategies{it}; Ti=T(strcmp(T.strategy,st)&T.snr_dB==s,:);
        [~,ord]=sort(Ti.realization); Ti=Ti(ord,:);
        r=r+1;
        total_errors=sum(Ti.error_count); total_info_bits=sum(Ti.info_bits);
        zero_error_upper95=nan;
        if total_errors==0, zero_error_upper95=-log(0.05)/total_info_bits; end
        info_blocks_per_frame=3; if strcmp(st,'bad_channel_energy_only'), info_blocks_per_frame=2; end
        zero_bler_upper95=nan;
        if sum(Ti.bler)==0, zero_bler_upper95=-log(0.05)/(sum(Ti.frames)*info_blocks_per_frame); end
        summary(r,:)={st,s,height(Ti),mean(Ti.ber),ci_t(Ti.ber),mean(Ti.bler),ci_t(Ti.bler), ...
            mean(Ti.goodput_cp_corrected),ci_t(Ti.goodput_cp_corrected), ...
            mean(Ti.rx_signal_power_pre_noise),ci_t(Ti.rx_signal_power_pre_noise),mean(Ti.tx_ofdm_time_power), ...
            total_errors,total_info_bits,zero_error_upper95,zero_bler_upper95};
        ber_bad=Ti.ber>0.1; gp_bad=Ti.goodput_cp_corrected<0.25; both=~ber_bad&~gp_bad;
        gr=gr+1; [blo,bhi]=wilson(sum(ber_bad),height(Ti)); [glo,ghi]=wilson(sum(gp_bad),height(Ti)); [jlo,jhi]=wilson(sum(both),height(Ti));
        gate(gr,:)={st,s,height(Ti),sum(ber_bad),blo,bhi,sum(gp_bad),glo,ghi,sum(both),jlo,jhi};
        qr=qr+1; pareto(qr,:)={st,s,mean(Ti.goodput_cp_corrected),mean(Ti.rx_signal_power_pre_noise),false};
        if ~strcmp(st,'uniform_p05')
            [~,bi]=ismember(Ti.realization,base.realization); b=base(bi,:);
            metrics={'ber','bler','goodput_cp_corrected','rx_signal_power_pre_noise'};
            for im=1:numel(metrics)
                x=Ti.(metrics{im})-b.(metrics{im}); boot=zeros(B,1); n=numel(x);
                for ib=1:B, ix=randi(n,n,1); boot(ib)=mean(x(ix)); end
                pr=pr+1; paired(pr,:)={st,s,metrics{im},mean(x),prctile(boot,2.5),prctile(boot,97.5),n,B,'paired by realization'};
            end
        end
    end
    ids=find(cell2mat(pareto(1:qr,2))==s); % current SNR only
    for a=ids(:)'
        dominated=false;
        for b=ids(:)'
            if a~=b && pareto{b,3}>=pareto{a,3} && pareto{b,4}>=pareto{a,4} && ...
                    (pareto{b,3}>pareto{a,3} || pareto{b,4}>pareto{a,4}), dominated=true; break; end
        end
        pareto{a,5}=~dominated;
    end
end
Ts=cell2table(summary,'VariableNames',{'strategy','snr_dB','n_channels','ber_mean','ber_ci95_halfwidth','bler_mean','bler_ci95_halfwidth','goodput_mean','goodput_ci95_halfwidth','rx_rf_mean','rx_rf_ci95_halfwidth','tx_power_mean','total_error_bits','total_info_bits','ber_zero_error_upper95','bler_zero_error_upper95'});
Tp=cell2table(paired,'VariableNames',{'strategy','snr_dB','metric','paired_difference_mean','bootstrap_ci95_low','bootstrap_ci95_high','n_channel_pairs','bootstrap_replicates','pairing'});
Tg=cell2table(gate,'VariableNames',{'strategy','snr_dB','n_channels','ber_violations','ber_wilson_low','ber_wilson_high','goodput_violations','goodput_wilson_low','goodput_wilson_high','joint_satisfy','joint_wilson_low','joint_wilson_high'});
Tq=cell2table(pareto,'VariableNames',{'strategy','snr_dB','goodput_mean','rx_rf_mean','nondominated'});
writetable(Ts,fullfile(p1_root,'formal_summary.csv')); writetable(Tp,fullfile(p1_root,'paired_differences_bootstrap.csv'));
writetable(Tg,fullfile(p1_root,'channel_gate_counts.csv')); writetable(Tq,fullfile(p1_root,'pareto_points.csv'));
% Historical values are shown only as a non-paired scope comparison: the old run
% used legacy unequal transmit powers and a prior construction snapshot.
v2_root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
historical_file=fullfile(v2_root,'results','20260917_210504_b4_strict_ofdm_rayleigh_formal','b4b_repetition_results.csv');
if ~exist(historical_file,'file'), error('Pinned historical comparison data are missing: %s',historical_file); end
H=readtable(historical_file); common_snr=intersect(snrs,unique(H.snr_dB));
hist_compare=cell(numel(common_snr)*numel(strategies),12); hr=0;
for is=1:numel(common_snr)
    for it=1:numel(strategies)
        st=strategies{it}; s=common_snr(is); old=H(strcmp(H.strategy,st)&H.snr_dB==s,:); now=Ts(strcmp(Ts.strategy,st)&Ts.snr_dB==s,:);
        if isempty(old)||isempty(now), continue; end
        old_ber_upper=nan; if sum(old.error_count)==0, old_ber_upper=-log(0.05)/sum(old.info_bits); end
        hr=hr+1; hist_compare(hr,:)={st,s,height(old),mean(old.ber),mean(old.goodput_cp_corrected), ...
            mean(old.rx_signal_power_pre_noise),mean(old.tx_ofdm_time_power),now.ber_mean(1), ...
            now.goodput_mean(1),now.rx_rf_mean(1),old_ber_upper,now.ber_zero_error_upper95(1)};
    end
end
Th=cell2table(hist_compare(1:hr,:),'VariableNames',{'strategy','snr_dB','historical_channels','historical_ber','historical_goodput','historical_rx_rf_mean','historical_tx_time_power','p1_ber','p1_goodput','p1_rx_rf_mean','historical_ber_zero_error_upper95','p1_ber_zero_error_upper95'});
writetable(Th,fullfile(p1_root,'historical_scope_comparison.csv'));
figdir=fullfile(p1_root,'figures'); if ~exist(figdir,'dir'),mkdir(figdir);end
power=readtable(fullfile(p1_root,'power_calibration_validation.csv'));
final_attempt=max(power.attempt); power=power(power.attempt==final_attempt,:);
fig=figure('Color','w','Position',[100 100 1250 560]); tiledlayout(1,2);
names=unique(power.strategy,'stable'); x=1:numel(names); cal=zeros(size(x)); val=zeros(size(x));
for k=1:numel(names)
    Q=power(strcmp(power.strategy,names{k}),:); cal(k)=mean(Q.mean_time_power(strcmp(Q.stage,'calibration')));
    val(k)=mean(Q.mean_time_power(strcmp(Q.stage,'validation')));
end
nexttile; bar(x,cal,0.6); grid on; box on; xticks(x); xticklabels(strrep(names,'_',' ')); xtickangle(25);
ylabel('Unscaled mean time-domain power'); title('Calibration samples before applying the frozen scale');
nexttile; bar(x,val,0.6); hold on; grid on; box on;
yline(1,'k--','Target','HandleVisibility','off'); yline(0.99,'r:','HandleVisibility','off'); yline(1.01,'r:','HandleVisibility','off');
xticks(x); xticklabels(strrep(names,'_',' ')); xtickangle(25); ylim([0.97 1.02]);
ylabel('Mean transmit time-domain power'); title('Independent validation after frozen scale');
sgtitle('Power calibration and independent validation');
savefig(fig,fullfile(figdir,'power_calibration_validation.fig')); exportgraphics(fig,fullfile(figdir,'power_calibration_validation.png'),'Resolution',200); exportgraphics(fig,fullfile(figdir,'power_calibration_validation.pdf'),'ContentType','vector'); close(fig);
plot_curves(Ts,strategies,'ber_mean','ber_ci95_halfwidth','BER','BER','semilogy',figdir,'ber');
plot_curves(Ts,strategies,'bler_mean','bler_ci95_halfwidth','BLER','Information-block error rate','semilogy',figdir,'bler');
plot_curves(Ts,strategies,'goodput_mean','goodput_ci95_halfwidth','Goodput','CP and padding corrected Goodput','plot',figdir,'goodput');
plot_curves(Ts,strategies,'rx_rf_mean','rx_rf_ci95_halfwidth','Received RF proxy','Pre-noise received time-domain mean-square','plot',figdir,'rx_rf');
fig=figure('Color','w','Position',[100 100 1150 680]); tiledlayout(2,2);
metrics={'ber','bler','goodput_cp_corrected','rx_signal_power_pre_noise'};
for im=1:4
    nexttile; hold on; grid on; box on;
    P=Tp(strcmp(Tp.metric,metrics{im}),:);
    for it=1:numel(strategies)-1
        Q=P(strcmp(P.strategy,strategies{it+1}),:); errorbar(Q.snr_dB,Q.paired_difference_mean, ...
            Q.paired_difference_mean-Q.bootstrap_ci95_low,Q.bootstrap_ci95_high-Q.paired_difference_mean,'-o','DisplayName',strrep(strategies{it+1},'_',' '));
    end
    yline(0,'k:','HandleVisibility','off'); xlabel('SNR (dB)');
    metric_labels={'BER','Information-block BLER','Goodput','Received RF mean-square'};
    ylabel(['Paired difference in ' metric_labels{im}],'Interpreter','none'); title(metric_labels{im},'Interpreter','none');
    if im==1||im==2, set(gca,'YScale','linear'); end
end
legend('Location','bestoutside'); savefig(fig,fullfile(figdir,'paired_differences.fig')); exportgraphics(fig,fullfile(figdir,'paired_differences.png'),'Resolution',200); exportgraphics(fig,fullfile(figdir,'paired_differences.pdf'),'ContentType','vector'); close(fig);
fig=figure('Color','w','Position',[70 70 1600 850]); tiledlayout(2,4,'TileSpacing','compact','Padding','compact');
pareto_colors=lines(numel(strategies));
for is=1:numel(snrs)
    nexttile; hold on; grid on; box on;
    Q=Tq(Tq.snr_dB==snrs(is),:);
    for it=1:numel(strategies)
        R=Q(strcmp(Q.strategy,strategies{it}),:);
        marker_size=42+38*double(R.nondominated);
        if R.nondominated
            scatter(R.rx_rf_mean,R.goodput_mean,marker_size,pareto_colors(it,:),'filled','MarkerEdgeColor','k','LineWidth',1.2);
        else
            scatter(R.rx_rf_mean,R.goodput_mean,marker_size,pareto_colors(it,:),'filled');
        end
    end
    xlabel('Received RF mean-square'); ylabel('Goodput'); title(sprintf('%g dB',snrs(is)));
end
nexttile; axis off; hold on;
for it=1:numel(strategies)
    plot(nan,nan,'o','MarkerFaceColor',pareto_colors(it,:),'MarkerEdgeColor','k','DisplayName',strrep(strategies{it},'_',' '));
end
legend('Location','northwest','Interpreter','none');
text(0.02,0.18,'Larger black-edged points are nondominated within the six candidates.','Units','normalized','Interpreter','none','FontSize',9);
sgtitle('Equal-power candidate Pareto points by SNR');
savefig(fig,fullfile(figdir,'pareto_by_snr.fig')); exportgraphics(fig,fullfile(figdir,'pareto_by_snr.png'),'Resolution',200); exportgraphics(fig,fullfile(figdir,'pareto_by_snr.pdf'),'ContentType','vector'); close(fig);
fig=figure('Color','w','Position',[80 100 1250 520]); tiledlayout(1,2);
for panel=1:2
    nexttile; hold on; grid on; box on;
    if panel==1, oldmetric='historical_ber'; newmetric='p1_ber'; set(gca,'YScale','log'); ylabel('BER'); title('Historical vs equal-power P1 BER');
    else, oldmetric='historical_rx_rf_mean'; newmetric='p1_rx_rf_mean'; ylabel('Pre-noise received RF mean-square'); title('Historical vs equal-power P1 RF proxy'); end
    for it=1:numel(strategies)
        Q=Th(strcmp(Th.strategy,strategies{it}),:); if isempty(Q), continue; end
        old_y=Q.(oldmetric); new_y=Q.(newmetric);
        if panel==1
            old_zero=old_y==0; new_zero=new_y==0;
            old_y(old_zero)=Q.historical_ber_zero_error_upper95(old_zero);
            new_y(new_zero)=Q.p1_ber_zero_error_upper95(new_zero);
        end
        plot(Q.snr_dB,old_y,'--o','DisplayName',[strrep(strategies{it},'_',' ') ' historical']);
        plot(Q.snr_dB,new_y,'-s','DisplayName',[strrep(strategies{it},'_',' ') ' equal-power']);
    end
    xlabel('SNR label (dB)');
end
legend('Location','bestoutside'); savefig(fig,fullfile(figdir,'historical_scope_comparison.fig')); exportgraphics(fig,fullfile(figdir,'historical_scope_comparison.png'),'Resolution',200); exportgraphics(fig,fullfile(figdir,'historical_scope_comparison.pdf'),'ContentType','vector'); close(fig);
fig=figure('Color','w','Position',[70 100 1450 600]); tiledlayout(1,3);
nexttile; hold on; grid on; box on; for it=1:numel(strategies), Q=Tg(strcmp(Tg.strategy,strategies{it}),:); y=Q.ber_violations./Q.n_channels; errorbar(Q.snr_dB,y,y-Q.ber_wilson_low,Q.ber_wilson_high-y,'-o','DisplayName',strrep(strategies{it},'_',' ')); end; yline(0.1,'k:'); xlabel('SNR (dB)'); ylabel('Per-channel BER violation fraction'); title('BER > 0.1');
nexttile; hold on; grid on; box on; for it=1:numel(strategies), Q=Tg(strcmp(Tg.strategy,strategies{it}),:); y=Q.goodput_violations./Q.n_channels; errorbar(Q.snr_dB,y,y-Q.goodput_wilson_low,Q.goodput_wilson_high-y,'-o','DisplayName',strrep(strategies{it},'_',' ')); end; xlabel('SNR (dB)'); ylabel('Per-channel Goodput violation fraction'); title('Goodput < 0.25');
nexttile; hold on; grid on; box on; for it=1:numel(strategies), Q=Tg(strcmp(Tg.strategy,strategies{it}),:); y=Q.joint_satisfy./Q.n_channels; errorbar(Q.snr_dB,y,y-Q.joint_wilson_low,Q.joint_wilson_high-y,'-o','DisplayName',strrep(strategies{it},'_',' ')); end; xlabel('SNR (dB)'); ylabel('Joint satisfaction fraction'); title('Both constraints met');
legend('Location','bestoutside');
savefig(fig,fullfile(figdir,'channel_constraints.fig')); exportgraphics(fig,fullfile(figdir,'channel_constraints.png'),'Resolution',200); exportgraphics(fig,fullfile(figdir,'channel_constraints.pdf'),'ContentType','vector'); close(fig);
end

function h=ci_t(x), h=1.96*std(x,0)/sqrt(numel(x)); end
function [lo,hi]=wilson(k,n), z=1.95996398454005; p=k/n; d=1+z^2/n; c=(p+z^2/(2*n))/d; h=z*sqrt(p*(1-p)/n+z^2/(4*n^2))/d; lo=c-h; hi=c+h; end
function plot_curves(T,strategies,y,ci,titleText,yLabel,plotMethod,figdir,name)
fig=figure('Color','w','Position',[100 100 950 650]); hold on; grid on; box on;
for it=1:numel(strategies)
    Q=T(strcmp(T.strategy,strategies{it}),:);
    if strcmp(plotMethod,'semilogy')
        yy=Q.(y); ci_half=Q.(ci);
        if strcmp(name,'ber')
            zero=yy==0; yy(zero)=Q.ber_zero_error_upper95(zero); ci_half(zero)=0;
        elseif strcmp(name,'bler')
            zero=yy==0; yy(zero)=Q.bler_zero_error_upper95(zero); ci_half(zero)=0;
        end
        lo=max(yy-ci_half,realmin); hi=yy+ci_half;
        errorbar(Q.snr_dB,yy,yy-lo,hi-yy,'-o','DisplayName',strrep(strategies{it},'_',' ')); set(gca,'YScale','log');
    else
        errorbar(Q.snr_dB,Q.(y),Q.(ci),'-o','DisplayName',strrep(strategies{it},'_',' '));
    end
end
xlabel('SNR = target time power / complex noise power (dB)','Interpreter','none'); ylabel(yLabel,'Interpreter','none');
if strcmp(name,'ber')||strcmp(name,'bler'), title([titleText ' (zero-error points shown at 95% upper bound)'],'Interpreter','none'); else, title(titleText,'Interpreter','none'); end
legend('Location','bestoutside');
savefig(fig,fullfile(figdir,[name '.fig'])); exportgraphics(fig,fullfile(figdir,[name '.png']),'Resolution',200); exportgraphics(fig,fullfile(figdir,[name '.pdf']),'ContentType','vector'); close(fig);
end
