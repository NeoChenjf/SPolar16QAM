function verify_energy_tradeoff_results(out)
% Audit numerical provenance from frames through summaries and working points.
    data=load(fullfile(out,'results.mat'));
    f=readmatrix(fullfile(out,'frame_results.csv'));
    r=readmatrix(fullfile(out,'repetition_results.csv'));
    t=readmatrix(fullfile(out,'point_summary.csv'));
    w=readmatrix(fullfile(out,'working_points.csv'));
    assert(isequal(f,data.frames) && isequal(r,data.rep) && isequal(t,data.summary),'CSV/MAT mismatch');
    expected=numel(data.ps)*numel(data.seeds)*numel(data.snrs);
    assert(size(r,1)==expected && size(f,1)==expected*data.cfg.num_frames);
    assert(size(unique(f(:,[1,2,3,5]),'rows'),1)==size(f,1),'Duplicate frames');
    for i=1:size(r,1)
        rows=f(f(:,1)==r(i,1)&f(:,2)==r(i,2)&f(:,3)==r(i,3),:);
        assert(size(rows,1)==r(i,4));
        assert(sum(rows(:,6))==r(i,5)); assert(abs(sum(rows(:,7))-r(i,6))<1e-10);
        assert(sum(sum(rows(:,10:13)))==r(i,7));
        assert(sum(sum(rows(:,18:21)))==r(i,8));
        K=rows(1,18:21);
        bler=sum(sum(rows(:,14:17),1).*K)/(size(rows,1)*sum(K));
        assert(abs(bler-r(i,9))<1e-12,'Weighted BLER mismatch');
    end
    [rr,tt,pp]=compute_energy_tradeoff_stats(r(:,1:10));
    assert(isequal(rr,r)&&isequal(tt,t));
    [found,order]=ismember(pp(:,1:2),t(:,1:2),'rows'); assert(all(found));
    assert(isequal(w,[pp,t(order,6:end)]),'Working-point join mismatch');
    names={'ber_snr','energy_p','ber_energy','goodput_energy_pareto'};
    for i=1:4
        for ext={'.png','.pdf','.fig'}
            file=dir(fullfile(out,'figures',[names{i},ext{1}])); assert(~isempty(file)&&file.bytes>0);
        end
    end
    fid=fopen(fullfile(out,'audit.txt'),'w'); if fid<0,error('energy:WriteFailed','audit');end
    fprintf(fid,'PASS frame counts, unique keys, CSV/MAT equality, energy/error/BLER denominators, paired normalization, CI, working-point join, figure files.\n');
    fprintf(fid,'Visual review is separate. Mode=%s; %d repetitions; %d frames.\n',data.mode,size(r,1),size(f,1)); fclose(fid);
    fprintf('PASS result audit: %d repetitions, %d frames.\n',size(r,1),size(f,1));
end
