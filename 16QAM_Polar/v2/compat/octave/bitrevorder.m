function [y, idx] = bitrevorder(x)
%BITREVORDER  (Octave compat) 位反转重排，等价 MATLAB/signal 的 bitrevorder
%
% 把长度 N=2^k 的向量按其索引(0..N-1)的 k-bit 位反转顺序重排。
% 只在 Octave 下被加入路径（见 setup_paths.m）。MATLAB/signal 下用原生实现。

    x = x(:);
    N = numel(x);
    k = log2(N);
    if mod(k,1) ~= 0
        error('bitrevorder(compat): 输入长度必须是 2 的幂');
    end
    n = (0:N-1).';
    r = zeros(N,1);
    for b = 0:k-1
        r = r + bitshift(double(bitget(n, b+1)), k-1-b);  % 第 b 位 -> 第 k-1-b 位
    end
    idx = r + 1;            % 1-based
    y = x(idx);
    % 输出形状跟随输入行/列
    if isrow(x), y = y.'; end
end
