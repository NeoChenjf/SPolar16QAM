%% TEST_SOURCE_ENTROPY_PARTITION
% Deterministic contracts for explicit source-S / channel-GA-I/F construction.
script_dir=fileparts(mfilename('fullpath'));
v2_root=fileparts(script_dir); addpath(v2_root); setup_paths();
v3_root=fullfile(v2_root,'..','v3'); addpath(fullfile(v3_root,'polar'));
N=64; p_vec=[0.5,0.1,0.5,0.3]; sigma_design=10^(-20/20);
state=build_source_entropy_partition(N,p_vec,sigma_design,200,9001);
lambda_offset=2.^(0:log2(N));
llr_layer_vec=get_llr_layer(N); bit_layer_vec=get_bit_layer(N);
cases={'zeros','ones','random_seed_17','random_seed_29'};
records=cell(0,7);

for b=1:4
    sets=[state.S{b}(:);state.I{b}(:);state.F{b}(:)];
    assert(numel(unique(sets))==N && isequal(sort(sets),(1:N).'), ...
        'S/I/F must be mutually exclusive and complete.');
    assert(numel(state.I{b})==state.K(b) && numel(state.S{b})==state.S_size(b));
    for snr_db=[10,20,30]
        [~,order]=sort(GA(10^(-snr_db/20),N),'descend');
        remain=order(~ismember(order,state.S{b}));
        expected_I=sort(remain(1:state.K(b))); expected_I=expected_I(:);
        if snr_db==20
            assert(isequal(state.I{b},expected_I), ...
                'Stored design-sigma I must match GA top-K after removing S.');
        end
        assert(numel(expected_I)==state.K(b) && isempty(intersect(expected_I,state.S{b})));
    end
    for ic=1:numel(cases)
        switch cases{ic}
            case 'zeros', payload=zeros(state.K(b),1);
            case 'ones', payload=ones(state.K(b),1);
            otherwise
                seed=str2double(cases{ic}(13:end)); rng(seed,'twister');
                payload=randi([0,1],state.K(b),1);
        end
        stream=struct('p',p_vec(b),'S_size',state.S_size(b),'K',state.K(b), ...
            'F_size',state.F_size(b),'I',state.I{b},'S',state.S{b},'F',state.F{b});
        [u,x]=shape_stream_sc(payload,stream);
        assert(isequal(u(state.I{b}),payload) && all(u(state.F{b})==0));
        assert(numel(x)==N && all(x==0 | x==1));
        frozen=ones(N,1); frozen([state.S{b};state.I{b}])=0;
        llr=1e6*(1-2*x);
        decoded=SC_decoder(llr,state.K(b)+state.S_size(b),frozen, ...
            lambda_offset,llr_layer_vec,bit_layer_vec);
        uhat=zeros(N,1); uhat(sort([state.S{b};state.I{b}]))=decoded;
        assert(isequal(uhat(state.I{b}),payload), ...
            'Noiseless SC must recover every nonzero payload.');
        records(end+1,:)={b,cases{ic},sum(payload),state.K(b), ...
            state.S_size(b),numel(state.F{b}),state.fingerprint{b}}; %#ok<AGROW>
    end
end

% Exercise the actual per-SNR selection consumed by the full-chain function.
sim_p_vec=[0.5,0.1,0.5,0.1];
sim_state=build_source_entropy_partition(N,sim_p_vec,sigma_design,200,9001);
cfg=config(); cfg.N=N; cfg.p_fixed=[0.5,NaN,0.5,NaN]; cfg.num_frames=1;
cfg.decoder='SC'; cfg.partition_mode='source_entropy';
cfg.source_partition_state=sim_state; cfg.source_samples=200; cfg.source_seed=9001;
snr_grid=[10,20,30];
sim=sim_shaped_polar_16qam(0.1,snr_grid,cfg);
for is=1:numel(snr_grid)
    [~,order]=sort(GA(10^(-snr_grid(is)/20),N),'descend');
    for b=1:4
        remain=order(~ismember(order,sim_state.S{b}));
        expected_I=sort(remain(1:sim_state.K(b))); expected_I=expected_I(:);
        assert(isequal(sim.partition.I_by_snr{is,b},expected_I));
        assert(numel(sim.partition.F_by_snr{is,b})==sim_state.F_size(b));
    end
end

out_dir=fullfile(v2_root,'results',[datestr(now,'yyyymmdd_HHMMSS') ...
    '_source_entropy_partition_contract_test']);
if exist(out_dir,'dir'),error('Refusing to overwrite %s.',out_dir);end
mkdir(out_dir); copyfile([mfilename('fullpath'),'.m'],out_dir);
T=cell2table(records,'VariableNames',{'stream','payload_case','payload_ones', ...
    'K','S_size','F_size','partition_fingerprint'});
writetable(T,fullfile(out_dir,'contract_cases.csv'));
save(fullfile(out_dir,'contract_test.mat'),'state','T','N','p_vec','sigma_design');
fid=fopen(fullfile(out_dir,'README.txt'),'w'); assert(fid>=0);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'PASS: S/I/F disjoint complete; counts correct; S excluded before GA top-K I selection at 10/20/30 dB; zero/one/two seeded payloads preserve I/F and noiseless SC recovery.\n');
fprintf(fid,'N=%d; p_vec=%s; sigma_design=%.12g; source samples=200; construction seed=9001.\n',N,mat2str(p_vec),sigma_design);
fprintf(fid,'This deterministic contract does not establish noisy BER accuracy or asymptotic PMF convergence.\n');
clear cleanup;
fprintf('PASS source-entropy partition contract: %s\n',out_dir);
