function [rep, summary, points] = compute_energy_tradeoff_stats(rep)
% Pair seed/SNR baseline powers, then summarize exactly three repetitions.
% Numeric schema: seed,p,SNR,frames,symbols,sum_abs2,errors,info_bits,BLER,R.
    validateattributes(rep, {'double'}, {'2d','nonempty','finite','real'});
    if size(rep,2) ~= 10 || any(rep(:,4:8) < 0, 'all') || ...
            any(rep(:,4:6) <= 0, 'all') || any(rep(:,8) <= 0) || ...
            any(rep(:,7)>rep(:,8)) || any(rep(:,9:10)<0,'all') || any(rep(:,9:10)>1,'all')
        error('energy:InvalidData','Invalid repetition data.');
    end
    if size(unique(rep(:,1:3),'rows'),1) ~= size(rep,1)
        error('energy:DuplicateKey','Duplicate seed/p/SNR.');
    end
    if any(rep(:,2)<=0 | rep(:,2)>0.5) || any(rep(:,[1,4,5,7,8])~=fix(rep(:,[1,4,5,7,8])),'all')
        error('energy:InvalidData','Invalid probability or noninteger count.');
    end
    expected_seeds=sort(unique(rep(:,1)));
    if numel(expected_seeds)~=3,error('energy:SeedCount','Exactly three seeds required.');end
    power = rep(:,6)./rep(:,5);
    energy = zeros(size(power)); baseline = energy;
    for i=1:size(rep,1)
        idx=find(rep(:,1)==rep(i,1) & rep(:,2)==0.5 & rep(:,3)==rep(i,3));
        if numel(idx)~=1, error('energy:MissingBaseline','Missing paired baseline.'); end
        baseline(i)=power(idx); energy(i)=power(i)/baseline(i);
    end
    ber=rep(:,7)./rep(:,8); goodput=rep(:,10).*(1-ber);
    rep=[rep,power,baseline,energy,ber,goodput];
    keys=unique(rep(:,2:3),'rows'); summary=[];
    for i=1:size(keys,1)
        rows=rep(rep(:,2)==keys(i,1) & rep(:,3)==keys(i,2),:);
        if size(rows,1)~=3, error('energy:SeedCount','Exactly three seeds required.'); end
        vals=rows(:,[14,15,13]); mu=mean(vals,1); sd=std(vals,0,1);
        half=4.302652729911275*sd/sqrt(3);
        % p,SNR,n,frames,errors, BER(mean,sd,lo,hi),G(...),E(...)
        metrics=[mu;sd;mu-half;mu+half];
        summary(end+1,:)=[keys(i,:),3,sum(rows(:,4)),sum(rows(:,7)),metrics(:)']; %#ok<AGROW>
    end
    points=[];
    for snr=unique(summary(:,2))'
        ix=find(summary(:,2)==snr); vals=summary(ix,[10,14]);
        [front,roles,z,d]=energy_tradeoff_points(vals);
        points=[points;summary(ix,1:2),front,roles,z,d]; %#ok<AGROW>
    end
end
