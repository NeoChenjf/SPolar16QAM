function [training_dir,policy_file] = run_p2_v2_strategy_training(pmf_dir)
% Execute E2 training in the approved fixed-amplitude common environment.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    x=load(fullfile(pmf_dir,'params.mat'),'cfg'); c=x.cfg;
    c.mode='pilot'; c.purpose='strategy_training'; c.seed=8901; c.seed_roles.strategy_training=8901;
    c.future_split='strategy_train'; c.num_channels=20; c.num_frames=40; c.snr_grid=24;
    [x,y,z]=ndgrid([.1 .3 .5]); c.strategy_p=[x(:),y(:),z(:);.5 .3 .1];
    c.strategy_names=arrayfun(@(i) sprintf('combo_%02d',i),1:27,'UniformOutput',false);
    c.strategy_names=[c.strategy_names,{'bad_channel_energy_only'}];
    c.controls={'shaped'}; c.predict=false; c.diagnose=false; c.pmf_file=''; c.model_file=''; c.resume_dir='';
    training_dir=run_p2_v2_strategy_batch(c);
    T=readtable(fullfile(training_dir,'repetitions.csv'));
    u=find(all(bsxfun(@eq,c.strategy_p(1:27,:),[.5 .5 .5]),2)); uniform_id=sprintf('combo_%02d_shaped',u);
    ref=mean(T.rx_rf(strcmp(T.case_id,uniform_id))); assert(ref>0 && isfinite(ref));
    scale=sqrt(2*50*10^((-25-30)/10)/ref);
    beta2=.0034*scale^2/2; beta4=.3829*3*scale^4/8;
    gains=zeros(c.num_channels,1);
    for ch=1:c.num_channels
        a=load(fullfile(training_dir,sprintf('raw_c%d_s1_combo_01_shaped.mat',ch)),'artifact');
        gains(ch)=mean(abs(fft(a.artifact.h,c.n_sc)).^2);
    end
    pivot=median(gains); bins={find(gains<=pivot),find(gains>pivot)}; selections=cell(1,2);
    candidates=startsWith(T.case_id,'combo_');
    for b=1:2
        selections{b}=p2_select_training_tradeoff(T(candidates & ismember(T.channel,bins{b}),:),.2,.2,beta2,beta4);
    end
    full=p2_select_training_tradeoff(T(candidates,:),.2,.2,beta2,beta4);
    policy=struct('pivot',pivot,'gains',gains,'bins',{bins},'selections',{selections},'full',full, ...
        'scale_25dbm',scale,'reference_m2',ref,'k2',.0034,'k4',.3829,'resistance',50, ...
        'max_ber',.2,'min_goodput',.2,'training_dir',training_dir,'uniform_id',uniform_id);
    policy_file=fullfile(training_dir,'frozen_training_policy.mat'); save(policy_file,'policy');
    writetable(full.candidates,fullfile(training_dir,'training_pareto.csv'));
    f=figure('Visible','off'); C=full.candidates; scatter(C.mean_goodput,C.mean_proxy,35,double(C.pareto),'filled');
    hold on; E=T(strcmp(T.case_id,'bad_channel_energy_only_shaped'),:);
    energy_proxy=beta2*E.rx_envelope_m2_l4+beta4*E.rx_envelope_m4_l4;
    scatter(mean(E.goodput_cp),mean(energy_proxy),90,'kx','LineWidth',2);
    energy_baseline=table({'bad_channel_energy_only_shaped'},mean(E.ber),mean(E.goodput_cp),mean(energy_proxy),height(E), ...
        'VariableNames',{'case_id','mean_ber','mean_goodput','mean_proxy','channels'});
    writetable(energy_baseline,fullfile(training_dir,'training_energy_only_baseline.csv'));
    xlabel('Goodput including CP'); ylabel('Nonlinear current proxy (A)'); title('Training candidates, assumed -25 dBm reference'); grid on;
    legend('27 candidates','Pure energy, group 3 has no payload','Location','best');
    saveas(f,fullfile(training_dir,'training_pareto.png')); print(f,fullfile(training_dir,'training_pareto.pdf'),'-dpdf'); close(f);
    fprintf('E2_TRAINING=%s\nE2_POLICY=%s\n',training_dir,policy_file);
end


