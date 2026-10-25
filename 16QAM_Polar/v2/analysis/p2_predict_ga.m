function prediction = p2_predict_ga(leaf_means, state, calibration)
%P2_PREDICT_GA Non-identical Gaussian leaves, read ACTUAL information indices.
% Offline quadrature supplies leaves. Correlated/asymmetric LLRs remain a limitation.
    if nargin<3, calibration=[0,1]; end
    validateattributes(leaf_means,{'numeric'},{'real','finite','nonnegative'});
    assert(isequal(size(leaf_means),[state.N,4]));
    assert(state.N>=2 && mod(log2(state.N),1)==0);
    assert(numel(calibration)==2 && all(isfinite(calibration)) && calibration(2)>=0);
    ber=zeros(1,4); prediction.reliability=cell(1,4);
    all_reliabilities=local_ga(leaf_means);
    for b=1:4
        m=all_reliabilities(:,b);
        idx=state.I{b}; assert(numel(idx)==state.K(b));
        ber(b)=mean(.5*erfc(sqrt(max(m(idx),0)/4)));
        prediction.reliability{b}=m;
    end
    prediction.ber_per_stream=ber;
    prediction.ber_raw=sum(ber.*state.K)/sum(state.K);
    prediction.numerical_floor_applied=prediction.ber_raw<1e-12;
    prediction.ber_raw=max(1e-12,prediction.ber_raw);
    x=min(1-1e-12,max(1e-12,prediction.ber_raw));
    z=calibration(1)+calibration(2)*log(x/(1-x));
    prediction.ber=1/(1+exp(-max(-700,min(700,z))));
    prediction.model_version='p2_moment_nonidentical_ga_v1';
    prediction.I=state.I;
end

function output=local_ga(input)
    [N,streams]=size(input); output=input;
    % Evaluate all nodes of a tree depth together, preserving the recursive
    % minus/plus ordering. This avoids N separate inverse-function loops.
    for depth=1:log2(N)
        half=N/2^depth; layer=reshape(output,2*half,[]);
        a=layer(1:half,:); b=layer(half+1:end,:);
        fa=local_phi(a); fb=local_phi(b);
        v=min(1,max(0,1-(1-fa).*(1-fb)));
        lo=zeros(size(v)); hi=ones(size(v))*1e5;
        for iteration=1:32
            mid=(lo+hi)/2; above=local_phi(mid)>v;
            lo(above)=mid(above); hi(~above)=mid(~above);
        end
        minus=(lo+hi)/2; minus(v>=1)=0;
        output=reshape([minus;a+b],N,streams);
    end
end

function y=local_phi(x)
    y=zeros(size(x)); small=x<=10;
    y(small)=exp(-.4527*x(small).^.859+.0218);
    z=x(~small); y(~small)=sqrt(pi./z).*exp(-z/4).*(1-10./(7*z));
    y=min(1,max(0,y)); y(x==0)=1;
end
