function block = p2_transmit_block(state, base_payload, auxiliary_bits, donor_payload)
%P2_TRANSMIT_BLOCK Reuse message-conditioned v3 shaping, including S-empty controls.
    assert(isequal(size(base_payload),[state.N,4]));
    kind=state.kind;
    if any(strcmp(kind,{'random_s','donor_s'}))
        assert(nargin>=4,'Independent auxiliary/donor arrays are required.');
        assert(isequal(size(auxiliary_bits),[state.N,4]) && isequal(size(donor_payload),[state.N,4]));
        assert(all(ismember(auxiliary_bits(:),[0,1])) && all(ismember(donor_payload(:),[0,1])));
    end
    block.state=state; block.u=zeros(state.N,4); block.x=block.u;
    block.payload=cell(1,4);
    for b=1:4
        stream=struct('p',state.p_vec(b),'S_size',state.S_size(b), ...
            'K',state.K(b),'F_size',state.F_size(b), ...
            'S',state.S{b},'I',state.I{b},'F',state.F{b});
        block.payload{b}=base_payload(1:state.K(b),b);
        if any(strcmp(kind,{'random_s','donor_s'}))
            u=zeros(state.N,1); u(stream.I)=block.payload{b};
            if strcmp(kind,'random_s')
                u(stream.S)=auxiliary_bits(stream.S,b);
            else
                [donor_u,~]=shape_stream_sc(donor_payload(1:stream.K,b),stream);
                u(stream.S)=donor_u(stream.S);
            end
            block.u(:,b)=u; block.x(:,b)=polar_encoder(u);
        else
            [block.u(:,b),block.x(:,b)]=shape_stream_sc(block.payload{b},stream);
        end
        assert(isequal(block.u(stream.I,b),block.payload{b}) && all(block.u(stream.F,b)==0));
    end
    bits=parallel_to_serial_bits(block.x(:,1),block.x(:,2),block.x(:,3),block.x(:,4));
    block.symbols=qammod(bits,16,'gray','InputType','bit','UnitAveragePower',true);
    labels=bi2de(block.x,'left-msb');
    block.counts=accumarray(labels+1,1,[16,1]);
end
