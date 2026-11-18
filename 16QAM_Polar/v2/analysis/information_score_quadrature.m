function value=information_score_quadrature(p,sigma,order)
persistent cached_order noise weights C bits
if isempty(C),C=qammod((0:15)',16,'gray','UnitAveragePower',true);bits=de2bi((0:15)',4,'left-msb');end
if isempty(cached_order)||cached_order~=order
 v=sqrt((1:order-1)/2);[V,D]=eig(diag(v,1)+diag(v,-1));[nodes,ix]=sort(diag(D));w=V(1,ix).^2;[a,b]=ndgrid(sqrt(2)*nodes,sqrt(2)*nodes);noise=a(:)+1i*b(:);weights=reshape(w(:)*w(:)',[],1);cached_order=order;
end
value=0;
for x=1:16
 if p(x)==0,continue,end
 y=C(x)+sigma*noise;d=-abs(y-C.').^2/(2*sigma^2);q=zeros(size(d));
 for k=1:4
  for b=0:1
   mask=bits(:,k)==b;z=d(:,mask);m=max(z,[],2);ls=m+log(sum(exp(z-m),2));q(:,mask)=q(:,mask)+ls;
  end
 end
 m=max(q,[],2);ld=m+log(exp(q-m)*p);value=value+p(x)*sum(weights.*(q(:,x)-ld))/log(2);
end
end
