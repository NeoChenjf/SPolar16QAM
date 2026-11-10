function verify_a0_saved()
root=fileparts(fileparts(mfilename('fullpath'))); out=fullfile(root,'results','20261110_144834_A0_production');files=dir(fullfile(out,'frame_*.mat'));assert(numel(files)==120);rows=[];
for j=1:numel(files)
 d=load(fullfile(out,files(j).name));assert(isequal(size(d.noise),[3935 1]));
 for g=1:3
  r=d.records{g};for b=1:4
   target=[.5 .3]; assert(isequal(d.state.p_vec,[.5 target(1+mod(j+1,2)) .5 target(1+mod(j+1,2))])); I=d.state.I{b};S=d.state.S{b};assert(all(isfinite(r.L(:))));assert(sum(r.decoded(I,b)~=r.u(I,b))==r.counts(b,1));assert(sum(r.decoded(S,b)~=r.u(S,b))==r.counts(b,3));assert(numel(I)==r.counts(b,2));assert(numel(S)==r.counts(b,4)); free=sort([I;S]); k=find(r.decoded(free,b)~=r.u(free,b),1); if isempty(k), assert(all(isnan(r.first(b,:)))); else, assert(isequal(r.first(b,:),[free(k) ismember(free(k),S)])); end;
  end
  K=sum(r.counts(:,2));errors=sum(r.counts(:,1));rate=K/(4*64*49)*64/80;rows=[rows;j g errors K rate*(1-errors/K)]; %#ok<AGROW>
 end
end
f=figure('Visible','off'); subplot(1,2,1); plot(rows(:,3)./rows(:,4),'.'); ylabel('Information BER per group frame'); xlabel('Saved group frame'); subplot(1,2,2); plot(rows(:,5),'.'); ylabel('Goodput incl CP'); xlabel('Saved group frame'); saveas(f,fullfile(out,'diagnostic.png')); close(f); writematrix(rows,fullfile(out,'audited_goodput.csv'));fprintf('AUDIT: 120 frames, 360 groups, counters exact; actual p .5/.3 verified\n');
end
