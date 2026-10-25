function out = run_p2_uniformity_audit()
%RUN_P2_UNIFORMITY_AUDIT Exact, non-Monte-Carlo audit of proposed uniform controls.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths();
    source=fullfile(root,'results','20261010_220806_b4_equal_power_p1_formal','b4b_strict_ofdm_rayleigh.mat');
    data=load(source,'source_templates'); probabilities=[.5,.3,.1]; snr=[16,20,24,28,32,36,40];
    out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p2_uniformity_exact']);
    assert(~isfolder(out)); mkdir(out); rows=cell(21,11); proofs=cell(3,7); random_proofs=cell(3,7); k=0;
    params=struct('N',1024,'p',probabilities,'snr_grid',snr,'source_seed',9001,'source_samples',200);
    save(fullfile(out,'params.mat'),'params');
    snapshot=fullfile(out,'source_snapshot'); mkdir(snapshot);
    files={mfilename('fullpath'),fullfile(root,'core','p2_prepare_state'), ...
        fullfile(root,'analysis','p2_uniformity_contract'),fullfile(root,'polar','get_GN'), ...
        fullfile(root,'polar','GA'),fullfile(root,'polar','phi'), ...
        fullfile(root,'polar','phi_inverse'),fullfile(root,'polar','derivative_phi')};
    fid=fopen(fullfile(out,'source_sha256.tsv'),'w');
    for i=1:numel(files)
        path=[files{i} '.m']; [~,name]=fileparts(path); copyfile(path,fullfile(snapshot,[name '.m']));
        fprintf(fid,'%s\t%s\n',path,local_hash(path));
    end
    fprintf(fid,'%s\t%s\n',source,local_hash(source)); fclose(fid);
    constellation=qammod((0:15)',16,'gray','UnitAveragePower',true);
    for ip=1:3
        for is=1:numel(snr)
            state=p2_prepare_state(data.source_templates{ip},snr(is),'shaped');
            same=p2_prepare_state(data.source_templates{ip},snr(is),'same_k_i',state);
            proof=p2_uniformity_contract(same); proofs{ip,is}=proof;
            randomized=p2_uniformity_contract(state,'I_union_S');
            random_proofs{ip,is}=randomized;
            k=k+1; rows(k,:)={probabilities(ip),snr(is),proof.tv_from_uniform, ...
                proof.fixed_zero_fraction(1),proof.fixed_zero_fraction(2), ...
                proof.fixed_zero_fraction(3),proof.fixed_zero_fraction(4), ...
                sum(abs(constellation).^2.*proof.model_pmf),proof.uniform_exact, ...
                randomized.tv_from_uniform,randomized.uniform_exact};
        end
    end
    T=cell2table(rows,'VariableNames',{'source_p','snr_db','tv_from_uniform', ...
        'fixed_zero_b1','fixed_zero_b2','fixed_zero_b3','fixed_zero_b4','model_symbol_energy','uniform_exact', ...
        'random_S_tv_uniform','random_S_uniform_exact'});
    writetable(T,fullfile(out,'exact_uniformity.csv')); save(fullfile(out,'proofs.mat'),'proofs','random_proofs','T','source');
    fid=fopen(fullfile(out,'README.txt'),'w'); fprintf(fid, ...
        ['Deterministic GF(2) generator-row audit, not Monte Carlo.\n' ...
        'S empty, F=0, actual I retained, independent fair payloads per stream.\n' ...
        'A zero generator column restricted to I fixes that output bit to zero.\n' ...
        'Products apply only to independent streams at a fixed position; joint laws are then averaged over positions.\n' ...
        'Nonzero TV is a structural bias and does not vanish by increasing frame count.\n' ...
        'Same-K/I controls with TV>0.05 cannot pass the uniform-PMF gate.\n' ...
        'Independent fair I_union_S separately checked for every p and construction SNR.\n']); fclose(fid);
    f=figure('Visible','off','Position',[50,50,1050,450]);
    subplot(1,2,1); hold on;
    styles={'-o','--s',':^'};
    for ip=1:3
        part=T(T.source_p==probabilities(ip),:);
        plot(part.snr_db,part.tv_from_uniform,styles{ip},'DisplayName',sprintf('source p = %.1f',probabilities(ip)));
    end
    yline(.05,'k-.','Uniform gate','HandleVisibility','off'); ylim([-.01,.47]);
    xlabel('Construction SNR (dB)'); ylabel('Exact TV from uniform'); legend('Location','best'); grid on;
    subplot(1,2,2); hold on;
    for ip=1:3
        part=T(T.source_p==probabilities(ip),:);
        plot(part.snr_db,part.model_symbol_energy,styles{ip},'DisplayName',sprintf('source p = %.1f',probabilities(ip)));
    end
    yline(1,'k-.','Uniform symbol energy','HandleVisibility','off'); ylim([.98,1.5]);
    xlabel('Construction SNR (dB)'); ylabel('Exact unscaled symbol mean square'); grid on;
    exportgraphics(f,fullfile(out,'uniformity_exact.png'),'Resolution',180);
    exportgraphics(f,fullfile(out,'uniformity_exact.pdf'),'ContentType','image','Resolution',200);
    savefig(f,fullfile(out,'uniformity_exact.fig')); close(f);
    fprintf('P2_UNIFORMITY: %s\n',out); disp(T);
end

function value=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0); bytes=fread(fid,inf,'*uint8'); fclose(fid);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
