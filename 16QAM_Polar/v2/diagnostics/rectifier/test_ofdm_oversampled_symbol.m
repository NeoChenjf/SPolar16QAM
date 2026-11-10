function test_ofdm_oversampled_symbol()
% Behavioral checks for IFFT convention and negative Nyquist representation.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    N=64; grid=zeros(N,2); grid([1,4,33,64],1)=[2;1i;3;-1]; grid(12,2)=2;
    original=ifft(grid,[],1); cp=16;
    for L=[1,2,4]
        w=ofdm_oversampled_symbol(grid,cp,L);
        expected=[original(end-cp+1:end,:);original];
        assert(isequal(size(w),[(N+cp)*L,2]));
        assert(max(abs(reshape(w(1:L:end,:)-expected,[],1)))<1e-12);
        assert(max(abs(reshape(w(1:cp*L,:)-w(end-cp*L+1:end,:),[],1)))<1e-12);
    end
    two=zeros(N,1); two([1,33])=64; a=rf_envelope_moments(ofdm_oversampled_symbol(two,0,1));
    b=rf_envelope_moments(ofdm_oversampled_symbol(two,0,4));
    assert(abs(a.mean_abs4-8)<1e-11 && abs(b.mean_abs4-6)<1e-11);
    fails(@() ofdm_oversampled_symbol(zeros(3,1),0,1),'ofdmoversample:InvalidGrid');
    fails(@() ofdm_oversampled_symbol(zeros(4,1),4,1),'ofdmoversample:InvalidCP');
    fails(@() ofdm_oversampled_symbol(zeros(4,1),0,1.5),'ofdmoversample:InvalidFactor');
end
function fails(f,id)
    caught=false;
    try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
