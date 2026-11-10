function rx = ofdm_oversampled_channel(grid, h, cp_len, factor)
%OFDM_OVERSAMPLED_CHANNEL Ideal per-symbol interpolation and tapped channel.
% Tap delays remain integer original-sample periods. CP blocks are joined
% without an analog pulse-shaping filter; the linear-convolution tail is
% truncated to the transmitted-window length as in ofdm_channel_roundtrip.
    if ~(isnumeric(h) && isvector(h) && ~isempty(h) && all(isfinite(h(:))))
        error('ofdmoversample:InvalidChannel','Channel must be a finite nonempty vector.');
    end
    if ~(isnumeric(cp_len) && isscalar(cp_len) && isreal(cp_len) && isfinite(cp_len) && cp_len>=numel(h)-1)
        error('ofdmoversample:ChannelExceedsCP','CP must cover channel taps.');
    end
    wave=ofdm_oversampled_symbol(grid,cp_len,factor);
    h_up=complex(zeros((numel(h)-1)*factor+1,1));
    h_up(1:factor:end)=h(:);
    full=conv(wave(:),h_up);
    rx=full(1:numel(wave));
end
