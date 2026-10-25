function out_dir = run_p2_mechanism(cfg_local)
%RUN_P2_MECHANISM Isolated fixed-power mechanism controls, pilot, and formal path.
% No formal jobs run without approved budget, frozen artifacts and gate record.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths();
    addpath(fullfile(root,'..','v3','polar'));
    if nargin<1, cfg_local=p2_default_config(); end
    cfg=cfg_local; local_validate(cfg);
    if isempty(cfg.resume_dir)
        run_id=char(java.util.UUID.randomUUID());
        out_dir=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p2_' cfg.mode '_' cfg.purpose '_' run_id(1:8)]);
        assert(~isfolder(out_dir),'Refusing overwrite.'); mkdir(out_dir);
    else
        out_dir=cfg.resume_dir;
        old=load(fullfile(out_dir,'params.mat'),'cfg');
        compare=cfg; compare.resume_dir=''; previous=old.cfg; previous.resume_dir='';
        assert(isequaln(compare,previous),'Resume configuration mismatch.');
        local_verify_snapshot(out_dir,root);
    end
    if ~isfile(fullfile(out_dir,'params.mat'))
        save(fullfile(out_dir,'params.mat'),'cfg'); local_snapshot(out_dir,root);
    end
    diary(fullfile(out_dir,'run_log.txt')); cleanup=onCleanup(@() diary('off')); %#ok<NASGU>
    fprintf('Output: %s\n',out_dir);
    templates=local_templates(cfg); save(fullfile(out_dir,'templates.mat'),'templates');
    cases=local_cases(cfg); save(fullfile(out_dir,'cases.mat'),'cases');
    powers=[];
    if ~isempty(cfg.power_file)
        power=load(cfg.power_file,'power'); powers=power.power;
        power_contract_data=load(cfg.power_file);
        if isfield(power_contract_data,'power_contract')
            contract=power_contract_data.power_contract; fields=fieldnames(contract);
            for field_index=1:numel(fields)
                assert(isequal(cfg.(fields{field_index}),contract.(fields{field_index})), ...
                    'Frozen power resource/construction contract differs.');
            end
        else
            assert(~strcmp(cfg.mode,'formal'),'Formal power file has no resource contract.');
        end
        [found,order]=ismember({cases.id},{powers.case_id});
        assert(all(found) && numel(unique({powers.case_id}))==numel(powers),'Power case identities differ.');
        powers=powers(order);
        details=load(cfg.power_file,'cases');
        if isfield(details,'cases')
            [~,order]=ismember({cases.id},{details.cases.id});
            assert(isequal(cases,details.cases(order)),'Power source configuration differs.');
        end
        assert(all([powers.frozen]),'Power coefficients must be frozen.');
    end
    if ~isempty(cfg.model_file)
        frozen=load(cfg.model_file,'model'); cfg.calibration=frozen.model.parameters;
        if strcmp(cfg.mode,'formal')
            assert(all(strcmp(frozen.model.training_modes,'formal')), 'Pilot fit cannot be promoted to formal model.');
            assert(strcmp(frozen.model.power_sha256,local_hash(cfg.power_file)), 'Model fitted under different power coefficients.');
        end
    end
    checkpoint=fullfile(out_dir,'checkpoint.mat'); T=table(); completed={};
    if isfile(checkpoint)
        saved=load(checkpoint,'T','completed'); T=saved.T; completed=saved.completed;
    end
    total_clock=tic;
    for ir=1:cfg.num_channels
        rng(p2_seed(cfg.purpose,cfg.seed,ir,0,0,0),'twister');
        h=(randn(cfg.taps,1)+1i*randn(cfg.taps,1))/sqrt(2*cfg.taps);
        if cfg.n_sc==1, h=1; end % dedicated single-carrier AWGN bridge
        H=fft(h,cfg.n_sc); layout=local_layout(H,cfg.N);
        for isnr=1:numel(cfg.snr_grid)
            snr=cfg.snr_grid(isnr); N0=10^(-snr/10);
            for ic=1:numel(cases)
                c=cases(ic); key=sprintf('%d/%d/%s',ir,isnr,c.id);
                if ismember(key,completed), continue; end
                started=tic; states=cell(1,numel(c.p));
                for g=1:numel(c.p)
                    src=templates{find(abs([.5,.3,.1]-c.p(g))<1e-10,1)};
                    ref=p2_prepare_state(src,snr,'shaped');
                    if strcmp(c.kind,'native'), src=templates{1}; end
                    states{g}=p2_prepare_state(src,snr,c.kind,ref);
                end
                scale=ones(1,numel(c.p)); pmf=repmat(ones(16,1)/16,1,numel(c.p));
                if ~isempty(powers)
                    scale=powers(ic).scale; pmf=powers(ic).pmf;
                end
                records=cell(cfg.num_frames,1); profile=zeros(cfg.n_sc,3);
                counts=zeros(16,numel(c.p),cfg.num_frames);
                stream_errors=zeros(numel(c.p),4); info_counts=stream_errors;
                oracle_errors=stream_errors; bit_errors=cell(size(states)); block_errors=0; diagnostic_seconds=0;
                oracle_sum=cell(size(states)); oracle_square=cell(size(states)); input_sum=cell(size(states)); input_square=cell(size(states));
                s_ones=cell(size(states)); s_probe=cell(numel(states),4); s_cross=cell(numel(states),4);
                for g=1:numel(states)
                    bit_errors{g}=zeros(cfg.N,4); oracle_sum{g}=zeros(cfg.N,4);
                    oracle_square{g}=zeros(cfg.N,4); input_sum{g}=zeros(cfg.N,4); input_square{g}=zeros(cfg.N,4);
                    s_ones{g}=zeros(cfg.N,4);
                    for b=1:4
                        indices=states{g}.S{b};
                        if isempty(indices), probe=[];
                        else, probe=indices(unique(round(linspace(1,numel(indices),min(32,numel(indices)))))); end
                        s_probe{g,b}=probe; s_cross{g,b}=zeros(numel(probe));
                    end
                end
                for frame=1:cfg.num_frames
                    grid=zeros(cfg.n_sc,layout.n_symbols); blocks=cell(size(states));
                    for g=1:numel(states)
                        rng(p2_seed(cfg.purpose,cfg.seed,ir,isnr,frame,g),'twister');
                        base_payload=randi([0,1],cfg.N,4);
                        rng(p2_seed(cfg.purpose,cfg.seed,ir,isnr,frame,g+3),'twister');
                        auxiliary=randi([0,1],cfg.N,4); donor=randi([0,1],cfg.N,4);
                        blocks{g}=p2_transmit_block(states{g},base_payload,auxiliary,donor);
                        s_ones{g}=s_ones{g}+blocks{g}.u;
                        for b=1:4
                            probe=s_probe{g,b}; bits=blocks{g}.u(probe,b);
                            s_cross{g,b}=s_cross{g,b}+bits*bits';
                        end
                        counts(:,g,frame)=blocks{g}.counts;
                        grid(layout.locations{g})=scale(g)*blocks{g}.symbols;
                    end
                    len=(cfg.n_sc+cfg.cp)*layout.n_symbols+numel(h)-1;
                    rng(p2_seed(cfg.purpose,cfg.seed,ir,isnr,frame,0),'twister');
                    unit_noise=randn(len,1)+1i*randn(len,1);
                    sigma=sqrt(cfg.n_sc*N0/2);
                    if any(strcmp(cfg.purpose,{'power_calibration','power_validation','pmf'})), sigma=0; end
                    phys=ofdm_channel_roundtrip(grid,h,sigma,cfg.cp,struct('noise_unit',unit_noise));
                    group_power=zeros(1,numel(states));
                    for g=1:numel(states)
                        component=zeros(size(grid)); component(layout.locations{g})=grid(layout.locations{g});
                        wave=ifft(component,cfg.n_sc,1);
                        if cfg.cp>0, wave=[wave(end-cfg.cp+1:end,:);wave]; end %#ok<AGROW>
                        group_power(g)=mean(abs(wave(:)).^2);
                        if sigma>0
                            sigma_grid=repmat(phys.sigma_equalized,1,layout.n_symbols);
                            decoded=p2_decode_block(phys.rx_grid_equalized(layout.locations{g}), ...
                                sigma_grid(layout.locations{g}),scale(g),blocks{g},cfg.diagnose);
                            block_errors=block_errors+decoded.block_error;
                            diagnostic_seconds=diagnostic_seconds+decoded.diagnostic_seconds;
                            stream_errors(g,:)=stream_errors(g,:)+decoded.errors;
                            oracle_errors(g,:)=oracle_errors(g,:)+decoded.oracle_errors;
                            for b=1:4
                                idx=states{g}.I{b};
                                bit_errors{g}(idx,b)=bit_errors{g}(idx,b)+decoded.bit_errors{b};
                                if cfg.diagnose
                                    signed=decoded.oracle_llr{b};
                                    oracle_sum{g}(idx,b)=oracle_sum{g}(idx,b)+signed;
                                    oracle_square{g}(idx,b)=oracle_square{g}(idx,b)+signed.^2;
                                end
                            end
                            signed_input=(1-2*blocks{g}.x).*decoded.channel_llr;
                            input_sum{g}=input_sum{g}+signed_input;
                            input_square{g}=input_square{g}+signed_input.^2;
                        end
                        info_counts(g,:)=info_counts(g,:)+states{g}.K;
                    end
                    freq_tx=mean(abs(grid).^2,2);
                    freq_rx=abs(H).^2.*freq_tx/cfg.n_sc;
                    profile=profile+[freq_tx,abs(H).^2,freq_rx];
                    reference_rf=sum(freq_rx)/cfg.n_sc;
                    records{frame}=struct('tx',phys.tx_time_power,'group_tx',group_power, ...
                        'rx_rf',phys.rx_signal_power,'rx_freq',reference_rf, ...
                        'residual',phys.rx_signal_power-reference_rf);
                end
                simulation_seconds=toc(started)-diagnostic_seconds;
                prediction=nan; model_seconds=nan; offline_seconds=nan; refs=cell(size(states));
                if cfg.predict && ~isempty(powers)
                    pt=tic; pred=zeros(1,numel(states)); weights=pred;
                    for g=1:numel(states)
                        idx=layout.locations{g}; sub=mod(idx-1,cfg.n_sc)+1;
                        unique_sub=unique(sub); sigma_k=sqrt(cfg.n_sc*N0/2)./max(abs(H(unique_sub)),1e-8);
                        refs{g}=p2_llr_reference(pmf(:,g),sigma_k,scale(g),cfg.quadrature_order);
                        [~,map]=ismember(sub,unique_sub);
                        leaves=refs{g}.ga_mean(map,:);
                        if g==1, offline_seconds=0; model_seconds=0; end
                        % Quadrature timing is outside online GA timing.
                        online=tic; estimate=p2_predict_ga(leaves,states{g},cfg.calibration);
                        model_seconds=model_seconds+toc(online);
                        pred(g)=estimate.ber_raw; weights(g)=sum(states{g}.K);
                    end
                    prediction=sum(pred.*weights)/sum(weights);
                    offline_seconds=toc(pt)-model_seconds;
                end
                err=sum(stream_errors(:)); bits=sum(info_counts(:)); ber=err/max(bits,1);
                if sigma==0
                    err=nan; ber=nan; block_errors=nan; stream_errors(:)=nan;
                end
                if ~cfg.diagnose || sigma==0, oracle_errors(:)=nan; end
                k=sum(cellfun(@(s) sum(s.K),states));
                rate=k/(4*cfg.n_sc*layout.n_symbols)*cfg.n_sc/(cfg.n_sc+cfg.cp);
                rec=[records{:}];
                corrected=nan;
                if isfinite(prediction)
                    clipped=min(1-1e-12,max(1e-12,prediction));
                    z=cfg.calibration(1)+cfg.calibration(2)*log(clipped/(1-clipped));
                    corrected=1/(1+exp(-max(-700,min(700,z))));
                end
                row=table({cfg.purpose},cfg.seed,ir,snr,{c.id},{c.kind},cfg.num_frames, ...
                    err,bits,ber,block_errors,cfg.num_frames*numel(states), ...
                    block_errors/(cfg.num_frames*numel(states)),rate,rate*(1-ber),mean([rec.tx]),mean([rec.rx_rf]), ...
                    mean([rec.rx_freq]),mean([rec.residual]),prediction,corrected, ...
                    simulation_seconds,diagnostic_seconds,model_seconds,offline_seconds,sigma>0, ...
                    'VariableNames',{'purpose','seed','channel','snr_db','case_id','control', ...
                    'frames','error_count','info_bits','ber','block_errors','info_blocks','bler', ...
                    'rate_cp','goodput_cp','tx_power', ...
                    'rx_rf','rx_frequency_reference','rf_residual','ber_raw','ber_predicted', ...
                    'elapsed_seconds','diagnostic_seconds','online_seconds','offline_seconds','communication_measured'});
                if isempty(T), T=row; else, T=[T;row]; end %#ok<AGROW>
                artifact=struct('states',{states},'h',h,'H',H,'layout',layout,'records',{records}, ...
                    'counts',counts,'profile',profile/cfg.num_frames,'stream_errors',stream_errors, ...
                    'info_counts',info_counts,'oracle_errors',oracle_errors,'bit_errors',{bit_errors}, ...
                    'oracle_signed_sum',{oracle_sum},'oracle_signed_square',{oracle_square}, ...
                    'input_signed_sum',{input_sum},'input_signed_square',{input_square}, ...
                    'u_ones',{s_ones},'s_probe',{s_probe},'s_cross',{s_cross}, ...
                    'refs',{refs},'scale',scale);
                save(fullfile(out_dir,sprintf('raw_c%d_s%d_%s.mat',ir,isnr,c.id)),'artifact','-v7.3');
                completed{end+1}=key; %#ok<AGROW>
                pending=fullfile(out_dir,'checkpoint.pending.mat');
                save(pending,'T','completed','-v7.3'); movefile(pending,checkpoint,'f');
                writetable(T,fullfile(out_dir,'repetitions.csv'));
                fprintf('DONE %s BER %.4g RF %.4g TX %.4g %.2fs\n',key,ber,row.rx_rf,row.tx_power,row.elapsed_seconds);
            end
        end
    end
    writetable(T,fullfile(out_dir,'repetitions.csv')); % rebuild even when every row was skipped
    elapsed=toc(total_clock); save(fullfile(out_dir,'completed.mat'),'elapsed','T');
    fid=fopen(fullfile(out_dir,'README.txt'),'w'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'P2 %s / %s; seed %d; elapsed %.3f sec.\n',cfg.mode,cfg.purpose,cfg.seed,elapsed);
    fprintf(fid,'Pilot is NOT formal evidence. No approved formal budget is implied.\n');
    fprintf(fid,'N0=10^(-SNR/10), time complex noise; RF before noise, normalized units, not DC.\n');
    fprintf(fid,'Power group components exclude cross terms; total-minus-components is audited separately.\n');
    fprintf(fid,'Prediction ber_raw uses uncalibrated approximation; model fit and independent evaluation are separate.\n');
    fprintf('Saved to: %s\n',out_dir);
end

function local_validate(c)
    assert(any(strcmp(c.mode,{'smoke','pilot','formal'})));
    assert(isfield(c.seed_roles,c.purpose) && ismember(c.seed,c.seed_roles.(c.purpose)), ...
        'Seed must belong to its declared purpose.');
    validateattributes(c.N,{'numeric'},{'scalar','integer','positive'});
    assert(c.N>=4 && mod(log2(c.N),1)==0);
    assert(size(c.strategy_p,1)==numel(c.strategy_names));
    assert(all(ismember(c.strategy_p(:),[.1,.3,.5])));
    assert(all(ismember(c.controls,{'shaped','same_k_i','native','random_s','donor_s'})));
    assert(c.cp>=c.taps-1 && c.cp<c.n_sc);
    validateattributes(c.num_frames,{'numeric'},{'scalar','integer','>=',1,'<=',8191});
    validateattributes(c.num_channels,{'numeric'},{'scalar','integer','>=',1,'<=',31});
    validateattributes(c.snr_grid,{'numeric'},{'vector','real','finite','nonempty'});
    assert(numel(c.snr_grid)<=15 && numel(unique(c.snr_grid))==numel(c.snr_grid));
    if ~strcmp(c.mode,'formal')
        assert(c.num_frames<=8 && c.num_channels<=3 && numel(c.snr_grid)<=3, ...
            'Short run budget exceeded. Request formal budget approval.');
    else
        assert(c.budget_approved && isfile(c.approval_file),'Formal budget approval record required.');
        approval=jsondecode(fileread(c.approval_file));
        assert(isfield(approval,'approved') && approval.approved && isfield(approval,'protocol_sha256'));
        assert(strcmp(approval.protocol_sha256,local_hash(c.frozen_test_manifest)), ...
            'Approval must bind the frozen protocol bytes.');
        protocol=jsondecode(fileread(c.frozen_test_manifest));
        v2=fileparts(fileparts(fileparts(mfilename('fullpath')))); project=fileparts(fileparts(v2));
        for i=1:numel(protocol.source_files)
            item=protocol.source_files(i);
            assert(strcmp(item.sha256,local_hash(fullfile(project,item.path))), ...
                'Source changed after protocol freeze.');
        end
        job_index=find(strcmp({protocol.jobs.job_id},c.job_id));
        assert(isscalar(job_index),'Job not uniquely registered in approved budget.');
        job=protocol.jobs(job_index);
        fields={'purpose','seed','num_frames','num_channels','N','n_sc','cp','taps', ...
            'source_seed','source_samples','quadrature_order','diagnose','predict'};
        for i=1:numel(fields), assert(isequal(c.(fields{i}),job.(fields{i})),'Job differs from approved protocol.'); end
        assert(isequal(c.snr_grid(:),job.snr_grid(:)) && isequal(c.strategy_p,job.strategy_p));
        assert(isequal(string(c.controls(:)),string(job.controls(:))));
        assert(isequal(string(c.strategy_names(:)),string(job.strategy_names(:))));
        if startsWith(c.purpose,'test_') || any(strcmp(c.purpose,{'model_calibration','singlecarrier'}))
            assert(isfile(c.gate_file) && isfile(c.power_file));
            gates=jsondecode(fileread(c.gate_file));
            assert(gates.power_pass && gates.pmf_pass && gates.contract_pass);
            assert(strcmp(gates.power_sha256,local_hash(c.power_file)));
            if startsWith(c.purpose,'test_')
                assert(isfile(c.model_file) && strcmp(gates.model_sha256,local_hash(c.model_file)));
            end
        end
    end
    if strcmp(c.purpose,'test_unseen')
        assert(isequal(c.strategy_p,c.heldout_p),'Unseen combinations were preregistered.');
    end
    if strcmp(c.purpose,'model_calibration')
        assert(~any(ismember(c.strategy_p,c.heldout_p,'rows')),'Held-out p leaked into fitting.');
    end
end

function templates=local_templates(cfg)
    probabilities=[.5,.3,.1];
    if ~isempty(cfg.templates_file)
        t=load(cfg.templates_file);
        if isfield(t,'templates'), templates=t.templates;
        else, templates=t.source_templates; end
    else
        templates=cell(1,3); p=[.5,.3,.1];
        for j=1:3
            templates{j}=build_source_entropy_partition(cfg.N,[.5,p(j),.5,p(j)],.1,cfg.source_samples,cfg.source_seed);
        end
    end
    for j=1:3
        assert(templates{j}.N==cfg.N && templates{j}.source_samples==cfg.source_samples ...
            && templates{j}.source_seed==cfg.source_seed);
        assert(isequal(templates{j}.p_vec,[.5,probabilities(j),.5,probabilities(j)]));
    end
end

function cases=local_cases(cfg)
    cases=struct('id',{},'p',{},'kind',{});
    for i=1:size(cfg.strategy_p,1)
        for j=1:numel(cfg.controls)
            if all(cfg.strategy_p(i,:)==.5) && j>1, continue; end
            entry=struct('id',[cfg.strategy_names{i} '_' cfg.controls{j}], ...
                'p',cfg.strategy_p(i,:),'kind',cfg.controls{j});
            if cfg.n_sc==1, entry.p=entry.p(1); end
            cases(end+1)=entry; %#ok<AGROW>
        end
    end
end

function layout=local_layout(H,N)
    n=numel(H); [~,order]=sort(abs(H).^2,'descend');
    if n==1
        layout=struct('locations',{{(1:N)'}},'n_symbols',N,'groups',1); return;
    end
    groups=zeros(n,1); cut=[ceil(n/3),floor(n/3)];
    groups(order(1:cut(1)))=1; groups(order(cut(1)+1:sum(cut)))=2;
    groups(groups==0)=3; slots=ceil(N./accumarray(groups,1)); count=max(slots);
    locations=cell(1,3);
    for g=1:3
        indices=find(repmat(groups==g,1,count)); locations{g}=indices(1:N);
    end
    layout=struct('locations',{locations},'n_symbols',count,'groups',groups);
end

function local_snapshot(out,root)
    dest=fullfile(out,'source_snapshot'); mkdir(dest);
    paths=[dir(fullfile(root,'core','p2_*.m'));dir(fullfile(root,'analysis','*p2*.m')); ...
        dir(fullfile(root,'experiments','multicarrier','*p2*.m'))];
    fid=fopen(fullfile(out,'source_sha256.tsv'),'w'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
    extra={fullfile(root,'polar','GA.m'),fullfile(root,'polar','phi.m'), ...
        fullfile(root,'polar','get_GN.m'),fullfile(root,'polar','get_bit_layer.m'), ...
        fullfile(root,'polar','get_llr_layer.m'),fullfile(root,'polar','SC_decoder.m'), ...
        fullfile(root,'polar','polar_encoder.m'),fullfile(root,'polar','build_source_entropy_partition.m'), ...
        fullfile(root,'core','ofdm_channel_roundtrip.m'),fullfile(root,'modulation','llr_16qam_gray_LSE.m'), ...
        fullfile(root,'modulation','parallel_to_serial_bits.m'), ...
        fullfile(root,'..','v3','polar','shape_stream_sc.m'), ...
        fullfile(root,'..','v3','polar','sc_decode_forced_full.m'), ...
        fullfile(root,'..','v3','polar','build_stream_partition_source_mc_ga.m')};
    for k=1:numel(paths), extra{end+1}=fullfile(paths(k).folder,paths(k).name); end
    extra=unique(extra);
    for k=1:numel(extra)
        path=extra{k}; relative=strrep(path,[root filesep],'');
        target=fullfile(dest,sprintf('%03d_%s',k,local_name(path)));
        copyfile(path,target); fprintf(fid,'%s\t%s\n',relative,local_hash(path));
    end
    artifacts={'power_file','model_file','templates_file','approval_file','gate_file','frozen_test_manifest'};
    p=load(fullfile(out,'params.mat'),'cfg');
    for j=1:numel(artifacts)
        path=p.cfg.(artifacts{j});
        if ~isempty(path), fprintf(fid,'@external:%s\t%s\n',path,local_hash(path)); end
    end
end

function local_verify_snapshot(out,root)
    lines=splitlines(string(fileread(fullfile(out,'source_sha256.tsv'))));
    for i=1:numel(lines)
        if strlength(lines(i))==0, continue; end
        pair=split(lines(i),sprintf('\t')); path=char(pair(1));
        if startsWith(path,'@external:'), path=extractAfter(path,'@external:');
        else, path=fullfile(root,path); end
        assert(strcmp(local_hash(path),pair(2)),'Resume source/artifact changed.');
    end
end

function name=local_name(path)
    [~,base,ext]=fileparts(path); name=[base ext];
end

function value=local_hash(path)
    assert(isfile(path),'Missing artifact: %s',path);
    fid=fopen(path,'rb'); bytes=fread(fid,inf,'*uint8'); fclose(fid);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
