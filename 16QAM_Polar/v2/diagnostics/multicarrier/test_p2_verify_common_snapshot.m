function test_p2_verify_common_snapshot()
% Isolated source and external corruption checks.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    tmp=tempname; mkdir(tmp); mkdir(fullfile(tmp,'source_snapshot'));
    cleanup=onCleanup(@() rmdir(tmp,'s')); %#ok<NASGU>
    src=fullfile(tmp,'source_snapshot','001_example.m'); ext=fullfile(tmp,'external.bin');
    writebytes(src,'source'); writebytes(ext,'external');
    fid=fopen(fullfile(tmp,'source_sha256.tsv'),'w');
    fprintf(fid,'core/example.m\t%s\n@external:%s\t%s\n',local_hash(src),ext,local_hash(ext)); fclose(fid);
    x=p2_verify_common_snapshot(tmp); assert(x.pass && x.source_files==1 && x.external_files==1);
    writebytes(src,'altered'); fails(@() p2_verify_common_snapshot(tmp),'snapshot:HashMismatch');
    writebytes(src,'source'); writebytes(ext,'altered'); fails(@() p2_verify_common_snapshot(tmp),'snapshot:HashMismatch');
    writebytes(ext,'external'); delete(src); fails(@() p2_verify_common_snapshot(tmp),'snapshot:MissingCopy');
end
function writebytes(path,data)
    fid=fopen(path,'wb'); assert(fid>=0); fwrite(fid,uint8(data),'uint8'); fclose(fid);
end
function h=local_hash(path)
    fid=fopen(path,'rb'); bytes=fread(fid,inf,'*uint8'); fclose(fid);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
