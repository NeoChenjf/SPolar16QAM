function p2_validate_common_references(run_dir)
%P2_VALIDATE_COMMON_REFERENCES Recompute references from saved PMF and channel.
% Internal consistency only; this does not establish PMF provenance or accuracy.
    p=load(fullfile(run_dir,'params.mat'),'cfg'); c=p.cfg;
    assert(c.predict && isfile(c.pmf_file),'refcheck:MissingPMF','Prediction PMF is required.');
    q=load(c.pmf_file,'pmf_asset'); entries=q.pmf_asset.entries;
    T=readtable(fullfile(run_dir,'repetitions.csv'));
    for i=1:height(T)
        si=find(c.snr_grid==T.snr_db(i));
        ei=find(strcmp({entries.case_id},T.case_id{i}) & [entries.snr_db]==T.snr_db(i));
        assert(isscalar(si) && isscalar(ei),'refcheck:Ambiguous','Expected unique SNR and PMF.');
        a=load(fullfile(run_dir,sprintf('raw_c%d_s%d_%s.mat',T.channel(i),si,T.case_id{i})),'artifact'); a=a.artifact;
        H=fft(a.h,c.n_sc);
        assert(isequal(H,a.H),'refcheck:ChannelMismatch','Saved frequency channel does not match taps.');
        for g=1:numel(a.states)
            sub=mod(a.layout.locations{g}-1,c.n_sc)+1;
            sigma=sqrt(c.n_sc*a.noise_complex_time_power/2)./max(abs(H(unique(sub))),1e-8);
            ref=p2_llr_reference(entries(ei).pmf(:,g),sigma,a.scale(g),c.quadrature_order);
            actual=a.refs{g}.ga_mean; expected=ref.ga_mean;
            assert(isequal(size(actual),size(expected)) && all(isfinite(actual(:))) && ...
                all(abs(actual(:)-expected(:))<=1e-10*max(1,abs(expected(:)))), ...
                'refcheck:Mismatch','Saved GA reference differs from recomputed reference.');
        end
    end
end
