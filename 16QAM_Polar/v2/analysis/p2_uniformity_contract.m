function proof = p2_uniformity_contract(state, free_set)
%P2_UNIFORMITY_CONTRACT Exact joint PMF for declared fair free inputs and F=0.
% At position j each stream is a GF(2) linear functional of independent bits.
% A nonzero functional is fair; a zero functional is identically zero.
% The four streams' messages are independent, so the per-POSITION joint law
% factors. Averaging these joint laws is essential: products of averaged
% marginals would be incorrect when fixed positions coincide.
    if nargin<2, free_set='I'; end
    assert(any(strcmp(free_set,{'I','I_union_S'})));
    if strcmp(free_set,'I'), assert(all(state.S_size==0),'Shaping must be absent.'); end
    G=get_GN(state.N); active=false(state.N,4);
    for b=1:4
        indices=state.I{b};
        if strcmp(free_set,'I_union_S'), indices=[indices;state.S{b}]; end
        active(:,b)=any(G(indices,:)~=0,1)';
    end
    labels=de2bi((0:15)',4,'left-msb'); conditional=zeros(16,state.N);
    for j=1:state.N
        allowed=all(labels(:,~active(j,:))==0,2);
        conditional(allowed,j)=2^(-sum(active(j,:)));
    end
    proof.position_pmf=conditional;
    proof.model_pmf=mean(conditional,2);
    proof.fixed_zero_fraction=mean(~active,1);
    proof.tv_from_uniform=.5*sum(abs(proof.model_pmf-1/16));
    proof.uniform_exact=proof.tv_from_uniform<1e-12;
    proof.assumptions=['Independent fair bits on ' free_set '; F=0; streams independent'];
end
