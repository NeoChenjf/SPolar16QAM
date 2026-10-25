function result = p2_decode_block(y, sigma, scale, block, diagnose)
%P2_DECODE_BLOCK Production SC unchanged; forced-prefix trace is analysis only.
    if nargin<5, diagnose=false; end
    N=block.state.N; state=block.state;
    result.diagnostic_seconds=0;
    L=reshape(llr_16qam_gray_LSE(y,sigma,scale),4,[])';
    result.errors=zeros(1,4); result.bit_errors=cell(1,4);
    result.oracle_errors=zeros(1,4); result.oracle_llr=cell(1,4);
    result.channel_llr=L;
    for b=1:4
        free=sort([state.I{b};state.S{b}]); frozen=ones(N,1); frozen(free)=0;
        recovered=SC_decoder(L(:,b),numel(free),frozen,2.^(0:log2(N)), ...
            get_llr_layer(N),get_bit_layer(N));
        u=zeros(N,1); u(free)=recovered;
        result.bit_errors{b}=u(state.I{b})~=block.payload{b};
        result.errors(b)=sum(result.bit_errors{b});
        if diagnose
            diagnostic_clock=tic;
            [forced, trace]=sc_decode_forced_full(L(:,b),true(N,1),block.u(:,b));
            assert(isequal(forced,block.u(:,b)));
            truth=block.u(state.I{b},b); raw=trace(state.I{b});
            result.oracle_errors(b)=sum((raw<0)~=truth);
            result.oracle_llr{b}=(1-2*truth).*raw;
            % Same min-sum decisions with F only forced must reproduce production SC.
            [trace_u,~]=sc_decode_forced_full(L(:,b),logical(frozen),zeros(N,1));
            assert(isequal(trace_u(state.I{b}),u(state.I{b})), ...
                'Trace decoder differs from production SC.');
            result.diagnostic_seconds=result.diagnostic_seconds+toc(diagnostic_clock);
        end
    end
    result.info_bits=state.K;
    result.block_error=any(result.errors>0); % B4 convention: one four-stream group block
end
