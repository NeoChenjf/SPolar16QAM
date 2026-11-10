function summary = p2_verify_common_snapshot(run_dir)
%P2_VERIFY_COMMON_SNAPSHOT Verify all numbered source snapshots and externals.
% This verifies files against a manifest, not the authenticity of the manifest.
    manifest=fullfile(run_dir,'source_sha256.tsv'); assert(isfile(manifest), ...
        'snapshot:MissingManifest','Source manifest missing.');
    lines=splitlines(string(fileread(manifest))); copy_index=0; external_count=0;
    for i=1:numel(lines)
        if strlength(lines(i))==0, continue; end
        pair=split(lines(i),sprintf('\t'));
        assert(numel(pair)==2 && strlength(pair(2))==64, ...
            'snapshot:InvalidManifest','Invalid source hash entry.');
        source=char(pair(1)); expected=char(pair(2));
        if startsWith(source,'@external:')
            path=extractAfter(source,'@external:'); external_count=external_count+1;
        else
            copy_index=copy_index+1;
            candidates=dir(fullfile(run_dir,'source_snapshot',sprintf('%03d_*',copy_index)));
            assert(numel(candidates)==1 && ~candidates.isdir, ...
                'snapshot:MissingCopy','Expected numbered source copy is missing or ambiguous.');
            [~,base,ext]=fileparts(source);
            assert(strcmp(candidates.name,sprintf('%03d_%s%s',copy_index,base,ext)), ...
                'snapshot:NameMismatch','Snapshot name does not match manifest.');
            path=fullfile(candidates.folder,candidates.name);
        end
        assert(isfile(path),'snapshot:MissingFile','Referenced source or external artifact missing.');
        assert(strcmp(local_hash(path),expected),'snapshot:HashMismatch','Source or artifact hash differs.');
    end
    copies=dir(fullfile(run_dir,'source_snapshot','*.m'));
    assert(copy_index>0 && numel(copies)==copy_index,'snapshot:ExtraCopies','Unexpected source snapshot files.');
    summary=struct('source_files',copy_index,'external_files',external_count,'pass',true);
end
function h=local_hash(path)
    fid=fopen(path,'rb'); assert(fid>=0,'snapshot:MissingFile','Cannot read file.');
    cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
    bytes=fread(fid,inf,'*uint8'); md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
