function wave = ofdm_oversampled_symbol(grid, cp_len, factor)
%OFDM_OVERSAMPLED_SYMBOL Interpolate OFDM symbols with a negative Nyquist bin.
% Matches MATLAB ifft(grid) at original sample instants; CP is interpolated
% within each symbol. No channel, analog filter, or physical scaling implied.
    if ~(isnumeric(grid) && ismatrix(grid) && ~isempty(grid) && ...
            all(isfinite(grid(:))) && size(grid,1)>=2 && mod(size(grid,1),2)==0)
        error('ofdmoversample:InvalidGrid','Grid must be finite with an even number of rows.');
    end
    N=size(grid,1);
    if ~(isnumeric(cp_len) && isscalar(cp_len) && isreal(cp_len) && ...
            isfinite(cp_len) && cp_len==fix(cp_len) && cp_len>=0 && cp_len<N)
        error('ofdmoversample:InvalidCP','CP must be an integer in [0,N).');
    end
    if ~(isnumeric(factor) && isscalar(factor) && isreal(factor) && ...
            isfinite(factor) && factor==fix(factor) && factor>=1 && factor<=64)
        error('ofdmoversample:InvalidFactor','Factor must be an integer between 1 and 64.');
    end
    padded=complex(zeros(N*factor,size(grid,2)));
    padded(1:N/2,:)=grid(1:N/2,:);
    padded(end-N/2+1:end,:)=grid(N/2+1:end,:);
    useful=ifft(padded,[],1)*factor;
    if cp_len>0
        wave=[useful(end-factor*cp_len+1:end,:);useful];
    else
        wave=useful;
    end
    if any(~isfinite(wave(:)))
        error('ofdmoversample:Overflow','Interpolated samples are not finite.');
    end
end
