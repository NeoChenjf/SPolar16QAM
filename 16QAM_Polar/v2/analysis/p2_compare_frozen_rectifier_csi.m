function output = p2_compare_frozen_rectifier_csi(frozen_file,expected_sha256,test_dir,baseline_ids)
%P2_COMPARE_FROZEN_RECTIFIER_CSI Check separately held digest before test.
% This does not establish when the digest was created or whether test is blind.
    assert(ischar(expected_sha256) && numel(expected_sha256)==64 && ...
        strcmp(local_hash(frozen_file),expected_sha256),'rectfreeze:DigestMismatch','Policy digest mismatch.');
    x=load(frozen_file,'frozen'); f=x.frozen;
    assert(strcmp(f.status,'exploratory_not_formal') && ...
        strcmp(local_hash(f.training_asset),f.training_asset_sha256), ...
        'rectfreeze:TrainingChanged','Frozen training asset changed.');
    output=p2_compare_rectifier_csi_asset(f.policy,f.training_asset,test_dir,baseline_ids);
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'rectfreeze:MissingFile','Cannot read file.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
