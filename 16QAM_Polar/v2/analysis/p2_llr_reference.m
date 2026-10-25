function ref = p2_llr_reference(pmf, sigma, scale, order)
%P2_LLR_REFERENCE Gaussian quadrature of actual joint PMF under CURRENT LLR.
% No shaping priors are added. Coordinates use the MATLAB Gray labels.
% Evaluates every distinct sigma (subcarrier), never a single averaged SNR.
    if nargin<4, order=10; end
    pmf=pmf(:); sigma=sigma(:);
    validateattributes(pmf,{'numeric'},{'numel',16,'real','finite','nonnegative'});
    assert(abs(sum(pmf)-1)<1e-10);
    validateattributes(sigma,{'numeric'},{'real','finite','positive'});
    validateattributes(scale,{'numeric'},{'scalar','real','finite','positive'});
    validateattributes(order,{'numeric'},{'scalar','integer','>=',4});
    off=sqrt((1:order-1)/2); J=diag(off,1)+diag(off,-1);
    [V,D]=eig(J); [nodes,idx]=sort(diag(D)); weights=V(1,idx).^2;
    [ni,nq]=ndgrid(sqrt(2)*nodes,sqrt(2)*nodes);
    noise=ni(:)+1i*nq(:); W=weights(:)*weights(:)'; W=W(:);
    symbols=qammod((0:15)',16,'gray','UnitAveragePower',true);
    labels=de2bi((0:15)',4,'left-msb');
    ref.mean=zeros(numel(sigma),4); ref.variance=ref.mean;
    ref.raw_ber=ref.mean; ref.mean_given_0=ref.mean; ref.mean_given_1=ref.mean;
    ref.skewness=ref.mean;
    for k=1:numel(sigma)
        Y=scale*symbols.'+sigma(k)*noise;
        % Vectorized exact likelihood, checked against production LLR by tests.
        d=abs(bsxfun(@minus,Y(:),scale*symbols.')).^2/(2*sigma(k)^2);
        L=zeros(numel(Y),4);
        for b=1:4
            L(:,b)=local_lse(-d(:,labels(:,b)==0))-local_lse(-d(:,labels(:,b)==1));
        end
        prob=reshape(W*pmf.',[],1);
        bits=kron(labels,ones(numel(noise),1));
        signed=(1-2*bits).*L;
        mu=sum(bsxfun(@times,signed,prob),1);
        var_z=sum(bsxfun(@times,bsxfun(@minus,signed,mu).^2,prob),1);
        ref.mean(k,:)=mu; ref.variance(k,:)=var_z;
        ref.raw_ber(k,:)=sum(bsxfun(@times,(L<0)~=bits,prob),1);
        ref.skewness(k,:)=sum(bsxfun(@times,bsxfun(@minus,signed,mu).^3,prob),1)./max(var_z,eps).^(3/2);
        for b=1:4
            for bit=0:1
                mask=bits(:,b)==bit; mass=sum(prob(mask));
                value=sum(prob(mask).*signed(mask,b))/max(mass,eps);
                if bit==0, ref.mean_given_0(k,b)=value; else, ref.mean_given_1(k,b)=value; end
            end
        end
    end
    % Moment projection is a candidate approximation, NOT a matched density theorem.
    ref.ga_mean=2*max(ref.mean,0).^2./max(ref.variance,eps);
    ref.invalid_projection=ref.mean<=0 | ~isfinite(ref.ga_mean);
    ref.ga_mean(ref.invalid_projection)=0;
    ref.consistency_ratio=ref.variance./max(2*ref.mean,eps);
    ref.order=order; ref.pmf=pmf; ref.sigma=sigma; ref.scale=scale;
end

function out=local_lse(x)
    m=max(x,[],2); out=m+log(sum(exp(bsxfun(@minus,x,m)),2));
end
