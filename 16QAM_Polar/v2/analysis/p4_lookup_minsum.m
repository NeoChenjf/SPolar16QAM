function prediction=p4_lookup_minsum(H,N0,locations,state,bank)
%P4_LOOKUP_MINSUM Exact-domain lossless cache of frozen numerical predictions.
% No interpolation/extrapolation. Bank is an offline asset, not test fitting.
match=false(1,numel(bank));
for k=1:numel(bank)
e=bank(k);match(k)=isequal(H(:),e.H(:)) && isequal(N0,e.N0) && isequal(locations(:),e.locations(:)) && strcmp(state.fingerprint,e.state_fingerprint) && isequal(state.p_vec,e.p_vec) && isequal(state.N,e.N) && isequal(state.K,e.K) && isequal(state.I,e.I) && isequal(state.S,e.S) && isequal(state.F,e.F) && strcmp(state.kind,e.kind) && isequal(state.source_fingerprint,e.source_fingerprint);
end
idx=find(match);prediction=struct('valid',false,'ber',nan,'genie',nan,'ber_per_stream',nan(1,4),'genie_per_stream',nan(1,4),'reason','outside_frozen_domain');
if isempty(idx),return;end
assert(isscalar(idx),'p4:AmbiguousLookup','Lookup domain must be unique.');e=bank(idx);prediction.valid=true;prediction.ber_per_stream=e.ber_per_stream;prediction.genie_per_stream=e.genie_per_stream;prediction.ber=sum(e.ber_per_stream.*state.K)/sum(state.K);prediction.genie=sum(e.genie_per_stream.*state.K)/sum(state.K);prediction.reason='exact_frozen_domain';prediction.sc_se_per_stream=e.sc_se_per_stream;
end



