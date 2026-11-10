function choice = p2_apply_csi_policy(policy,h)
%P2_APPLY_CSI_POLICY Select frozen exploratory candidate from estimated h.
    assert(strcmp(policy.status,'exploratory_not_formal') && isnumeric(h) && ...
        isvector(h) && ~isempty(h) && all(isfinite(h(:))), ...
        'csipolicy:InvalidInput','Finite channel taps and exploratory policy are required.');
    gain=mean(abs(fft(h,policy.n_sc)).^2);
    if gain<=policy.pivot, bin=1; else, bin=2; end
    selection=policy.selections{bin};
    choice=struct('gain',gain,'bin',bin,'status',selection.status,'selected_case',selection.selected_case);
end
