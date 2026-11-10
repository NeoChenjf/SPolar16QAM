function test_rf_envelope_moments()
% Deterministic behavioral checks: inputs define the sampled window.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    z=rf_envelope_moments(zeros(1,5));
    assert(z.mean_abs2==0 && z.mean_abs4==0 && z.sample_count==5);
    z=rf_envelope_moments([1,1i,-1,-1i]);
    assert(abs(z.mean_abs2-1)<1e-12 && abs(z.mean_abs4-1)<1e-12);
    z=rf_envelope_moments([0,sqrt(2)]);
    assert(abs(z.mean_abs2-1)<1e-12 && abs(z.mean_abs4-2)<1e-12);
    for L=[1,2,4]
        t=(0:64*L-1)'/(64*L); z=rf_envelope_moments(1+exp(-2i*pi*32*t));
        if L==1, expected=8; else, expected=6; end
        assert(abs(z.mean_abs2-2)<1e-12 && abs(z.mean_abs4-expected)<1e-11);
    end
    fails(@() rf_envelope_moments([]),'rfmoments:InvalidEnvelope');
    fails(@() rf_envelope_moments([1,NaN]),'rfmoments:InvalidEnvelope');
    fails(@() rf_envelope_moments(ones(2,2)),'rfmoments:InvalidEnvelope');
    fails(@() rf_envelope_moments(realmax),'rfmoments:Overflow');
end
function fails(f,id)
    caught=false;
    try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
