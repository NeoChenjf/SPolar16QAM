function partition = build_source_entropy_partition(N, p_vec, sigma_design, n_samples, seed)
%BUILD_SOURCE_ENTROPY_PARTITION Fixed-K source-S and channel-GA I/F construction.
% Source entropy estimates use exact sum-product SC from the v3 audited helper.
    if nargin < 4 || isempty(n_samples), n_samples = 200; end
    if nargin < 5 || isempty(seed), seed = 9001; end
    validateattributes(N, {'numeric'}, {'scalar','integer','positive'});
    assert(abs(log2(N)-round(log2(N)))<eps, 'N must be a power of two.');
    validateattributes(p_vec, {'numeric'}, {'vector','real','finite','>',0,'<',1,'numel',4});
    validateattributes(sigma_design, {'numeric'}, {'scalar','real','finite','positive'});
    validateattributes(n_samples, {'numeric'}, {'scalar','integer','positive'});
    validateattributes(seed, {'numeric'}, {'scalar','integer','nonnegative'});
    v2_root=fileparts(fileparts(mfilename('fullpath')));
    v3_root=fullfile(v2_root,'..','v3');
    addpath(fullfile(v3_root,'polar'));
    ga=GA(sigma_design,N); [~,ga_order]=sort(ga(:),'descend');
    S=cell(1,4); I=cell(1,4); F=cell(1,4); K=zeros(1,4); S_size=zeros(1,4);
    entropy=cell(1,4); h2=zeros(1,4); fingerprint=cell(1,4);
    for b=1:4
        p=p_vec(b); h2(b)=-p*log2(p)-(1-p)*log2(1-p);
        S_size(b)=ceil(N*(1-h2(b))); K(b)=ceil((N-S_size(b))/2);
        if S_size(b)==0
            H=ones(N,1); S{b}=zeros(0,1);
        else
            source=build_stream_partition_source_mc_ga(N,p,sigma_design,n_samples,seed+104729*b,struct('exact',true));
            H=source.source_entropy; [~,order]=sort(H,'ascend'); S{b}=sort(order(1:S_size(b))).'; S{b}=S{b}(:);
        end
        remain=ga_order(~ismember(ga_order,S{b}));
        I{b}=sort(remain(1:K(b))); I{b}=I{b}(:);
        F{b}=sort(remain(K(b)+1:end)); F{b}=F{b}(:);
        assert(isempty(intersect(S{b},I{b}))&&isempty(intersect(S{b},F{b}))&&isempty(intersect(I{b},F{b})));
        assert(numel(unique([S{b};I{b};F{b}]))==N && numel(I{b})==K(b));
        entropy{b}=H; fingerprint{b}=local_fingerprint(S{b},I{b},F{b});
    end
    partition=struct('method','source_entropy_S_GA_IF','N',N,'p_vec',p_vec(:).', ...
        'sigma_design',sigma_design,'source_samples',n_samples,'source_seed',seed, ...
        'S_size',S_size,'K',K,'F_size',N-S_size-K,'S',{S},'I',{I},'F',{F}, ...
        'source_entropy',{entropy},'target_entropy',h2,'fingerprint',{fingerprint});
end

function value=local_fingerprint(S,I,F)
    indices=[S(:);I(:);F(:)]; classes=[ones(numel(S),1);2*ones(numel(I),1);3*ones(numel(F),1)];
    value=sprintf('%08X',mod(sum(double(indices).*double(classes)*2654435761),2^32));
end
