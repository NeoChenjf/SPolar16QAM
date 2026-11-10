function policy = p2_train_rectifier_csi_policy(run_dir,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)
%P2_TRAIN_RECTIFIER_CSI_POLICY Exploratory two-bin policy using current proxy.
% Assumed parameters/range are not actual rectifier calibration.
    base=p2_train_csi_policy(run_dir,max_ber,min_goodput,1,0);
    choices=cell(1,2);
    for b=1:2
        if isempty(base.bins{b})
            choices{b}=struct('status','no_training_coverage','selected_case','');
        else
            choices{b}=p2_select_rectifier_tradeoff(run_dir,max_ber,min_goodput, ...
                volts_per_unit,resistance_ohm,k2,k4,valid_power_w,base.bins{b});
        end
    end
    policy=struct('status','exploratory_not_formal','feature',base.feature, ...
        'pivot',base.pivot,'n_sc',base.n_sc,'training_dir',base.training_dir, ...
        'training_seed',base.training_seed,'reference_snr_db',base.reference_snr_db, ...
        'training_gains',base.training_gains,'bins',{base.bins},'selections',{choices}, ...
        'energy_semantics','current_proxy_not_dc');
end
