function report = p2_audit_common_pairing(run_dir)
%P2_AUDIT_COMMON_PAIRING Check saved paired inputs, not statistical independence.
    loaded=load(fullfile(run_dir,'params.mat'),'cfg'); cfg=loaded.cfg;
    assert(isfield(cfg,'purpose') && any(strcmp(cfg.purpose,{'pilot','model_calibration','test_seen','test_unseen','strategy_training','strategy_test'})), ...
        'pairaudit:InvalidRole','Only runs with communication noise enabled can be audited.');
    loaded=load(fullfile(run_dir,'cases.mat'),'cases'); cases=loaded.cases;
    assert(~isempty(cases) && numel(unique({cases.id}))==numel(cases), ...
        'pairaudit:InvalidCases','Case IDs must be unique and nonempty.');
    rows=cell(cfg.num_channels*numel(cfg.snr_grid)*numel(cases),5); row=0;
    for ir=1:cfg.num_channels
        for j=1:numel(cfg.snr_grid)
            reference=[];
            for k=1:numel(cases)
                path=fullfile(run_dir,sprintf('raw_c%d_s%d_%s.mat',ir,j,cases(k).id));
                assert(isfile(path),'pairaudit:MissingRaw','Expected paired raw file is missing.');
                loaded=load(path,'artifact'); a=loaded.artifact;
                needed={'h','channel_hash','frame_hashes','scale','noise_complex_time_power'};
                assert(all(isfield(a,needed)) && numel(a.frame_hashes)==cfg.num_frames, ...
                    'pairaudit:MissingEvidence','Raw lacks the required pairing evidence.');
                assert(strcmp(a.channel_hash,local_numeric_hash(a.h)), ...
                    'pairaudit:ChannelHashMismatch','Channel fingerprint does not match channel.');
                assert(all(a.scale==1) && isfinite(a.noise_complex_time_power) && a.noise_complex_time_power>0, ...
                    'pairaudit:InvalidEnvironment','Fixed amplitude and positive noise power required.');
                for frame=1:cfg.num_frames
                    x=a.frame_hashes(frame);
                    assert(all(isfield(x,{'noise','payload','auxiliary','donor'})) && ...
                        ischar(x.noise) && numel(x.noise)==64 && ...
                        iscell(x.payload) && iscell(x.auxiliary) && iscell(x.donor) && ...
                        numel(x.payload)==numel(a.scale) && numel(x.auxiliary)==numel(a.scale) && ...
                        numel(x.donor)==numel(a.scale), ...
                        'pairaudit:MissingEvidence','Per-frame hashes are incomplete.');
                end
                is_energy=isfield(a,'energy_only_group3') && a.energy_only_group3;
                assert(is_energy==strcmp(cases(k).id,'bad_channel_energy_only_shaped'), ...
                    'pairaudit:EnergyOnlyContract','Pure-energy case and raw role disagree.');
                if is_energy
                    assert(strcmp(cases(k).id,'bad_channel_energy_only_shaped') && numel(a.scale)==3, ...
                        'pairaudit:EnergyOnlyContract','Unexpected pure-energy role.');
                    for frame=1:cfg.num_frames
                        assert(strcmp(a.frame_hashes(frame).payload{3},local_numeric_hash(zeros(cfg.N,4))), ...
                            'pairaudit:EnergyOnlyPayload','Pure-energy payload is not all zero.');
                    end
                end
                if isempty(reference)
                    reference=a;
                else
                    assert(isequal(a.h,reference.h) && strcmp(a.channel_hash,reference.channel_hash) && ...
                        isequal(a.noise_complex_time_power,reference.noise_complex_time_power), ...
                        'pairaudit:Mismatch','Candidates have different channel or noise power.');
                    ref_energy=isfield(reference,'energy_only_group3') && reference.energy_only_group3;
                    for frame=1:cfg.num_frames
                        x=a.frame_hashes(frame); y=reference.frame_hashes(frame);
                        assert(strcmp(x.noise,y.noise) && isequal(x.auxiliary,y.auxiliary) && ...
                            isequal(x.donor,y.donor) && numel(x.payload)==numel(y.payload), ...
                            'pairaudit:Mismatch','Candidates have different paired noise or auxiliary inputs.');
                        for group=1:numel(x.payload)
                            if group==3 && (is_energy || ref_energy), continue; end
                            assert(strcmp(x.payload{group},y.payload{group}), ...
                                'pairaudit:Mismatch','Information payloads do not match.');
                        end
                    end
                end
                row=row+1; rows(row,:)={ir,cfg.snr_grid(j),cases(k).id,cfg.num_frames,true};
            end
        end
    end
    report=cell2table(rows,'VariableNames',{'channel','snr_db','case_id','frames','paired_evidence_equal'});
end
function value=local_numeric_hash(x)
    bytes=typecast([real(double(x(:)));imag(double(x(:)))],'uint8');
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
