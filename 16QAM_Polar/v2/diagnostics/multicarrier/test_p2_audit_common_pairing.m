function test_p2_audit_common_pairing()
% Construct isolated raw fixtures and verify missing/mismatched evidence fails.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    tmp=tempname; mkdir(tmp); cleanup=onCleanup(@() rmdir(tmp,'s')); %#ok<NASGU>
    cfg=struct('purpose','pilot','num_channels',1,'snr_grid',24,'num_frames',1); save(fullfile(tmp,'params.mat'),'cfg');
    cases=struct('id',{'a','b'}); save(fullfile(tmp,'cases.mat'),'cases');
    hashes=struct('noise',repmat('a',1,64),'payload',{{repmat('b',1,64)}}, ...
        'auxiliary',{{repmat('c',1,64)}},'donor',{{repmat('d',1,64)}});
    artifact=struct('h',1,'channel_hash',local_hash(1),'frame_hashes',hashes, ...
        'scale',1,'noise_complex_time_power',.01);
    save(fullfile(tmp,'raw_c1_s1_a.mat'),'artifact'); save(fullfile(tmp,'raw_c1_s1_b.mat'),'artifact');
    R=p2_audit_common_pairing(tmp); assert(height(R)==2 && all(R.paired_evidence_equal));
    cfg.purpose='power_calibration'; save(fullfile(tmp,'params.mat'),'cfg');
    fails(@() p2_audit_common_pairing(tmp),'pairaudit:InvalidRole');
    cfg.purpose='pilot'; save(fullfile(tmp,'params.mat'),'cfg');
    artifact.frame_hashes.noise=repmat('e',1,64); save(fullfile(tmp,'raw_c1_s1_b.mat'),'artifact');
    fails(@() p2_audit_common_pairing(tmp),'pairaudit:Mismatch');
    delete(fullfile(tmp,'raw_c1_s1_b.mat'));
    fails(@() p2_audit_common_pairing(tmp),'pairaudit:MissingRaw');
    artifact.h=2; save(fullfile(tmp,'raw_c1_s1_b.mat'),'artifact');
    fails(@() p2_audit_common_pairing(tmp),'pairaudit:ChannelHashMismatch');
end
function value=local_hash(x)
    bytes=typecast([real(double(x(:)));imag(double(x(:)))],'uint8');
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    value=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
