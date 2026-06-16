N=1024;
R=1/2;
%R=3/4;
K=N*R;
info=randsrc(K,1,[0 1;0.4 0.6]); 
%info=randsrc(K,1,[0 1;0.8 0.2]);  %test
SNR=1;
sigma = 1/sqrt(2 * R) * 10^(-SNR/20);

channels= GA(sigma, N);
[~, channel_ordered] = sort(channels, 'descend');  
info_bits = sort(channel_ordered(1 : K), 'ascend'); 
frozen_bits = ones(N , 1); 
frozen_bits(info_bits) = 0; 
logic=mod(frozen_bits + 1, 2); 
info_bits_logical = logical(logic); 
u = zeros(N, 1);
%u_frozen=find(info_bits_logical==0);
%u_frozen=zeros(N-K,1);
%for i=1:N-K-1
%    u_frozen(i+1)=mod(u_frozen(i)+1,2);
%    i=i+1;
%end
u(info_bits_logical==0)=u_frozen;
u(info_bits_logical) = info; 
x = polar_encoder(u); 

info_ratio=sum(info==1)/K;
x_ratio=sum(x==1)/N;

%info=randsrc(1024,1,[0 1;0.5 0.5]); 

nz = bsc(info,1); % Binary symmetric channel
ratio=sum(info==1)/1024;
na_ratio=sum(nz==1)/1024;
