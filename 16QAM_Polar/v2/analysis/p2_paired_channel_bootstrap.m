function result = p2_paired_channel_bootstrap(delta, n_boot, seed)
%P2_PAIRED_CHANNEL_BOOTSTRAP Resample whole paired independent-channel deltas.
% The caller establishes pairing and independent channel provenance. A small
% channel count yields a descriptive interval, not a scientific acceptance.
    if ~(isnumeric(delta) && isreal(delta) && isvector(delta) && ~isempty(delta) && all(isfinite(delta(:))))
        error('pairedci:InvalidDelta','Delta must be a finite nonempty real vector.');
    end
    if ~(isnumeric(n_boot) && isreal(n_boot) && isscalar(n_boot) && isfinite(n_boot) && ...
            n_boot==fix(n_boot) && n_boot>=100 && n_boot<=100000)
        error('pairedci:InvalidBootstrap','n_boot must be an integer between 100 and 100000.');
    end
    if ~(isnumeric(seed) && isreal(seed) && isscalar(seed) && isfinite(seed) && ...
            seed==fix(seed) && seed>=0 && seed<=2^32-1)
        error('pairedci:InvalidSeed','Seed must be a valid twister seed.');
    end
    delta=double(delta(:)); n=numel(delta);
    result=struct('channels',n,'mean',mean(delta),'lower95',nan,'upper95',nan, ...
        'status','insufficient_channels','n_boot',n_boot,'seed',seed);
    if n<2, return; end
    previous=rng; restore=onCleanup(@() rng(previous)); %#ok<NASGU>
    rng(seed,'twister'); draws=randi(n,n,n_boot);
    means=mean(delta(draws),1); interval=prctile(means,[2.5,97.5]);
    result.lower95=interval(1); result.upper95=interval(2);
    result.status='descriptive_interval_not_acceptance';
end
