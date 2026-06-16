function prob=get_symbol_prob_sim(sequence,M,N)
L=length(sequence);
total_num=L/N;
symbol_num=zeros(M,1);
for i=1:total_num
    slice=sequence((i-1)*N+1:i*N);
    symbol_num(bit_to_symbol(slice))=symbol_num(bit_to_symbol(slice))+1;
end
prob=symbol_num/total_num;