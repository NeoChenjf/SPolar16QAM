function [front,roles,z,d] = energy_tradeoff_points(values)
% Maximize Goodput and RF energy; roles: communication,energy,compromise.
    validateattributes(values,{'double'},{'2d','nonempty','finite','real','ncols',2});
    tol=1e-12*max(1,max(abs(values),[],1)); n=size(values,1); front=true(n,1);
    for i=1:n
        delta=bsxfun(@minus,values,values(i,:));
        front(i)=~any(all(bsxfun(@ge,delta,-tol),2) & any(bsxfun(@gt,delta,tol),2));
    end
    lo=min(values,[],1); hi=max(values,[],1); span=hi-lo; z=ones(n,2);
    for k=1:2
        if span(k)>tol(k), z(:,k)=(values(:,k)-lo(k))/span(k); end
    end
    d=sqrt(sum((1-z).^2,2)); best=min(d(front));
    roles=[abs(values(:,1)-hi(1))<=tol(1),abs(values(:,2)-hi(2))<=tol(2), ...
        front & abs(d-best)<=1e-12];
end
