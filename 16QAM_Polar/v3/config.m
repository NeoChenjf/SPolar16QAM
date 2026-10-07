function cfg = config()
%CONFIG Default configuration for the generic Cartesian Gray-QAM v3 core.
    cfg.N = 1024;
    cfg.num_frames = 20;
    cfg.seed = 42;
    cfg.decoder = 'SC';
    cfg.snr_mode = 'fixed_n0';
    cfg.output_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
    cfg.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
end
