function prediction = p2_predict_cheap(H, N0, n_sc, states, locations, model)
%P2_PREDICT_CHEAP Development surrogate; known channel and fixed code states.
% Includes channel features, no PMF quadrature or GA. No independent acceptance.
    assert(strcmp(model.kind,'cheap'),'cheap:Model','Expected cheap model.');
    assert(isvector(H) && numel(H)==n_sc && all(isfinite(H)));
    validateattributes(N0,{'numeric'},{'scalar','real','finite','positive'});
    count=numel(states); x=zeros(count,9); weights=zeros(count,1);
    for g=1:count
        sub=unique(mod(locations{g}-1,n_sc)+1);
        gains=abs(H(sub)).^2;
        sigma=sqrt(n_sc*N0/2)./max(abs(H(sub)),1e-8);
        s=log(mean(sigma)); state=states{g};
        random=strcmp(state.kind,'random_s'); donor=strcmp(state.kind,'donor_s');
        if sum(state.S_size)==0, random=false; donor=false; end
        weights(g)=sum(state.K);
        x(g,:)=[s,s*s,mean(log(max(gains,1e-12))), ...
            log(max(min(gains),1e-12)),state.p_vec(2),weights(g)/4096, ...
            sum(state.S_size)/4096,random,donor];
    end
    mean_x=model.mean(:)'; scale=model.scale(:)'; c=model.coefficients(:);
    assert(numel(mean_x)==9 && numel(scale)==9 && all(scale>0) && numel(c)==10);
    z=[ones(count,1),bsxfun(@rdivide,bsxfun(@minus,x,mean_x),scale)]*c;
    prediction.per_group=1./(1+exp(-max(-40,min(40,z))));
    assert(sum(weights)>0);
    prediction.ber=sum(prediction.per_group.*weights)/sum(weights);
    prediction.features=x;
end
