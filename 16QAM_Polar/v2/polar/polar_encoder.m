function x = polar_encoder(u)
%encoding: x = u * Fn.
N = length(u);
GN=get_GN(N); 
Y=u'*GN;
x=mod(Y',2);
end