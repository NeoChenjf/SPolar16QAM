function [pmf, role, required] = p2_distribution_reference(state, independent_model)
%P2_DISTRIBUTION_REFERENCE Target versus diagnostic model must stay distinct.
    if nargin<2, independent_model=[]; end
    required=true;
    switch state.kind
        case 'shaped'
            labels=de2bi((0:15)',4,'left-msb'); p=state.p_vec;
            pmf=prod(bsxfun(@power,p,labels).*bsxfun(@power,1-p,1-labels),2);
            role='shaping_target';
        case {'native','random_s'}
            pmf=ones(16,1)/16; role='uniform_target';
            if strcmp(state.kind,'random_s')
                proof=p2_uniformity_contract(state,'I_union_S');
            else
                proof=p2_uniformity_contract(state);
            end
            assert(proof.uniform_exact,'Requested uniform control fails generator coverage.');
        case 'same_k_i'
            proof=p2_uniformity_contract(state); pmf=proof.model_pmf;
            role='exact_frozen_set_model'; required=false;
        case 'donor_s'
            pmf=independent_model;
            role='independent_donor_model_not_uniform_target'; required=false;
            if isempty(pmf), pmf=nan(16,1); end
        otherwise
            error('Unknown distribution reference role.');
    end
end
