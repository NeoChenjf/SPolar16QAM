function write_energy_csv(path, headers, data)
% Checked numeric CSV writer, retaining double precision.
    if size(data,2)~=numel(headers), error('energy:Schema','Column count mismatch.'); end
    fid=fopen(path,'w');
    if fid<0, error('energy:WriteFailed','Cannot open %s',path); end
    cleanup=onCleanup(@() fclose(fid));
    fprintf(fid,'%s\n',strjoin(headers,','));
    format=[repmat('%.17g,',1,size(data,2)-1),'%.17g\n'];
    fprintf(fid,format,data');
    [message,number]=ferror(fid);
    if number~=0, error('energy:WriteFailed','%s',message); end
end
