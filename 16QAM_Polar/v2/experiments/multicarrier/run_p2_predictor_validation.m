function out = run_p2_predictor_validation(asset_file, cfg_local)
%RUN_P2_PREDICTOR_VALIDATION Frozen cheap predictor against independent SC data.
% New run only: never resumes or overwrites historical E1 observations.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths; addpath(fullfile(root,'..','v3','polar'));
    cfg=cfg_local;
    assert(isfield(cfg,'approved') && cfg.approved,'validation:Budget','Explicit run budget required.');
    assert(cfg.channels>=1 && cfg.channels<=20 && cfg.frames>=1 && cfg.frames<=40);
    assert(cfg.max_seconds>0 && cfg.max_seconds<=3600 && cfg.max_case_frames<=14400);
    assert(any(strcmp(cfg.role,{'smoke','independent'})));
    budget_clock=tic; load_clock=tic; B=load(asset_file);
    asset_load_seconds=toc(load_clock);
    assert(strcmp(B.model.kind,'cheap') && numel(B.entries)==18);
    out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_prediction_validation_' cfg.role]);
    assert(~isfolder(out));mkdir(out);save(fullfile(out,'params.mat'),'cfg','asset_file','asset_load_seconds');
    copyfile(asset_file,fullfile(out,'frozen_predictor.mat'));
    copyfile([mfilename('fullpath') '.m'],fullfile(out,'validation_source.m'));
    copyfile(fullfile(root,'analysis','p2_predict_cheap.m'),fullfile(out,'predictor_source.m'));
    T=table();completed_frames=0;stop=false;
    for si=1:2
      split_names={'seen_retest','unseen_retest'};
      for channel=1:cfg.channels
        if strcmp(cfg.role,'smoke'), split='diagnostic_b';else, split=split_names{si};end
        rng(p2_future_seed(split,channel,0,0,0,'channel'),'twister');
        h=(randn(16,1)+1i*randn(16,1))/sqrt(32);H=fft(h,64);
        [~,order]=sort(abs(H).^2,'descend');groups=ones(64,1)*3;
        groups(order(1:22))=1;groups(order(23:43))=2;
        locations=cell(1,3);symbols=49;
        for g=1:3,idx=find(repmat(groups==g,1,symbols));locations{g}=idx(1:1024);end
        for sn=1:3
          reference=[20 24 28];N0=(3*1024/(64^2*symbols))*10^(-reference(sn)/10);
          for ct=1:3
            controls={'shaped','random_s','donor_s'};cases={'seen','unseen'};
            key=sprintf('%d/%d/%s_%s',si,sn,cases{si},controls{ct});
            clock=tic;hit=find(strcmp({B.entries.key},key));assert(isscalar(hit));
            states=B.entries(hit).states;
            P=p2_predict_cheap(H,N0,64,states,locations,B.model);online_seconds=toc(clock);
            assert(abs(B.entries(hit).construction_snr_db+10*log10(64*N0))<1e-10);
            errors=zeros(3,4);bits=errors;block_errors=0;frames=0;
            sim_clock=tic;
            for frame=1:cfg.frames
              if toc(budget_clock)>cfg.max_seconds || completed_frames>=cfg.max_case_frames
                stop=true;break;
              end
              grid=zeros(64,symbols);blocks=cell(1,3);
              for g=1:3
                rng(p2_future_seed(split,channel,sn,frame,g,'payload'),'twister');payload=randi([0 1],1024,4);
                rng(p2_future_seed(split,channel,sn,frame,g,'auxiliary'),'twister');aux=randi([0 1],1024,4);
                rng(p2_future_seed(split,channel,sn,frame,g,'donor'),'twister');donor=randi([0 1],1024,4);
                blocks{g}=p2_transmit_block(states{g},payload,aux,donor);
                grid(locations{g})=blocks{g}.symbols;
              end
              rng(p2_future_seed(split,channel,sn,frame,0,'noise'),'twister');
              n=randn(80*symbols+15,1)+1i*randn(80*symbols+15,1);
              noise=N0;if strcmp(cfg.role,'smoke'),noise=1e-20;end
              phys=ofdm_common_noise_roundtrip(grid,h,noise,16,n);
              sig=repmat(phys.sigma_equalized,1,symbols);
              for g=1:3
                decoded=p2_decode_block(phys.rx_grid_equalized(locations{g}),sig(locations{g}),1,blocks{g},false);
                errors(g,:)=errors(g,:)+decoded.errors;bits(g,:)=bits(g,:)+states{g}.K;
                block_errors=block_errors+decoded.block_error;
              end
              frames=frames+1;completed_frames=completed_frames+1;
            end
            sim_seconds=toc(sim_clock);
            if frames==0,stop=true;break;end
            ber=sum(errors(:))/sum(bits(:));rate=sum(bits(:))/frames/(4*80*symbols);
            artifact=struct('h',h,'H',H,'locations',{locations},'states',{states}, ...
                'errors',errors,'bits',bits,'prediction',P,'N0',N0,'split',split,'channel',channel, ...
                'reference_index',sn,'frames',frames,'control',controls{ct});
            save(fullfile(out,sprintf('raw_%d_%d_%d_%d.mat',si,channel,sn,ct)),'artifact');
            row=table(si,channel,reference(sn),{controls{ct}},frames,sum(errors(:)),sum(bits(:)),ber, ...
                P.ber,rate,rate*(1-ber),online_seconds,sim_seconds,block_errors, ...
                'VariableNames',{'split','channel','reference_db','control','frames','errors','bits', ...
                'ber','predicted','rate_cp','goodput_cp','online_seconds','simulation_seconds','block_errors'});
            if isempty(T),T=row;else,T=[T;row];end %#ok<AGROW>
            writetable(T,fullfile(out,'validation.csv'));
            stored=dir(fullfile(out,'*'));if sum([stored.bytes])>=2*1024^3,stop=true;end
            fprintf('VALIDATED split=%d channel=%d reference=%d control=%s frames=%d BER=%.5g prediction=%.5g\n',si,channel,reference(sn),controls{ct},frames,ber,P.ber);
            if stop,break;end
          end
          if stop,break;end
        end
        if stop,break;end
      end
      if stop,break;end
    end
    elapsed=toc(budget_clock);save(fullfile(out,'completed.mat'),'T','elapsed','completed_frames','stop');
    fid=fopen(fullfile(out,'README.txt'),'w');
    fprintf(fid,'Frozen fixed-amplitude N1024 16QAM/min-sum SC, 64 carriers CP16 taps16. Independent seeds: seen_retest/unseen_retest; smoke diagnostic_b near-noiseless, NOT acceptance. No model adaptation. Asset loaded once; online includes entry lookup + channel features + inference; simulation includes input RNG, TX, channel and decoder, excludes raw file writes. Source entropy and model training offline. Frames=%d elapsed=%.6f stopped=%d.\n',completed_frames,elapsed,stop);fclose(fid);
    if strcmp(cfg.role,'smoke'),assert(all(T.errors==0),'validation:Loopback','Near-noiseless loopback failed.');end
    fprintf('VALIDATION_DIR=%s\n',out);
end
