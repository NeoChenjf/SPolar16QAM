function u = GA(sigma, N)
% N=512;
% sigma=0.5;
u = zeros(1, N);
u(1) = 2/sigma^2;
% u(1) = 1/sigma^2;
% LLR=-(1-2*y)/(sigma^2);
for i = 1:log2(N)
    j = 2^(i - 1);
    for k = 1:j
        tmp = u(k);
        u(k) = phi_inverse(1 - (1 - phi(tmp))^2);
        u(k + j) = 2 * tmp;
    end
end
 u = bitrevorder(u);

%  scatter((1:N),u(1:N),'.b');
%  axis([0 1.1*N 0 4*N]);
%  xlabel('Channel index');
%  ylabel('E(LLRi)');
end
