function audit_frontier_rectifier_diode(out)
% Exploratory replay: charge every regenerated signal frame to the same cap.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;addpath(fullfile(root,'..','v3','polar'));
z=load(fullfile(out,'frozen.mat'));p=z.protocol;assert(isfile(fullfile(out,'communication_complete.mat')),'Complete original data first');
budgetfile=fullfile(out,'budget.mat');b=load(budgetfile);charged=b.charged;actual=b.actual;
Hset=[1 4 8];Lset=[1 4];Cset=[1 23 63 103 125];reference=[-30 -25 -20];RL=10000;rows=[];vt=1.380649e-23*p.temperature_K/1.602176634e-19;vscale=p.diode_n*vt;
fid=fopen(fullfile(out,'diode_replay_plan.txt'),'w');fprintf(fid,'Exploratory fixed cases H=[1 4 8], labels=[16 28], candidates=[1 23 63 103 125], frame=1, 30 regenerated frames; RL=10kOhm assumed, Rs and Cj omitted, matched input and output smoothing idealized. Three global scales -30/-25/-20 dBm. Check full exponential vs fourth order. No fitting.\n');fclose(fid);
for hi=Hset
 for li=Lset
  file=fullfile(out,sprintf('communication_h%02d_l%02d.mat',hi,p.labels(li)));orig=load(file,'moments','errors','bits');h=z.channels(:,hi);
  fr=1;rng(p.frame_seed_base+hi*10000+li*100+fr,'twister');payload=randi([0 1],1024,4,3);noise=randn(80*49+numel(h)-1,1)+1i*randn(80*49+numel(h)-1,1);
  blocks=cell(3,5);for g=1:3,for j=1:5,blocks{g,j}=p2_transmit_block(z.states{li,j},payload(:,:,g));end,end
  for c=Cset
   assert(charged+1<=p.frame_cap && datetime('now')<datetime(p.communication_deadline),'Replay budget');
   charged=charged+1;save(budgetfile,'charged','actual');grid=zeros(64,49);
   for g=1:3,grid(z.locations{hi,g})=blocks{g,p.choices(c,g)}.symbols;end
   rx=ofdm_oversampled_channel(grid,h,16,8);m=rf_envelope_moments(rx);actual=actual+1;
   saved=reshape(orig.moments(fr,c,1:2),1,2);assert(max(abs(saved-[m.mean_abs2,m.mean_abs4]))<1e-10*(1+max(abs(saved))),'Replay waveform moment mismatch');
   verified=0;fourier_delta=nan;
   if c==1
    N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);phys=ofdm_common_noise_roundtrip(grid,h,N0,16,noise);sigma=repmat(phys.sigma_equalized,1,49);
    nw=reshape(noise(1:80*49),80,49);direct=bsxfun(@times,grid,fft(h,64))+sqrt(N0/2)*fft(nw(17:80,:),64,1);
    fourier_delta=max(abs(direct(:)-phys.rx_grid(:)))/(1+max(abs(direct(:))));assert(fourier_delta<1e-10);
    for g=1:3
     block=blocks{g,p.choices(c,g)};decoded=p2_decode_block(phys.rx_grid_equalized(z.locations{hi,g}),sigma(z.locations{hi,g}),1,block,false);
     assert(isequal(decoded.errors,reshape(orig.errors(fr,c,g,:),1,4)) && isequal(decoded.info_bits,reshape(orig.bits(fr,c,g,:),1,4)));
     for k=1:4
      state=block.state;frozen=true(1024,1);frozen([state.I{k};state.S{k}])=false;
      alternative=sc_decode_forced_full(decoded.channel_llr(:,k),frozen,zeros(1024,1));
      assert(sum(alternative(state.I{k})~=block.u(state.I{k},k))==decoded.errors(k),'Independent SC disagreement');
     end
    end
    verified=1;
   end
   for ref=reference
    v=p.volts_per_unit_primary*10^((ref+25)/20);x=v*abs(rx)/vscale;
    if any(x>600),full=nan;proxy=nan;power=nan;eff=nan;
    else
     average_bessel=mean(besseli(0,x,1).*exp(abs(x)));unloaded=p.diode_Is*(average_bessel-1);
     k2=p.diode_Is/(2*vscale^2);k4=p.diode_Is/(24*vscale^4);proxy=k2*v^2*m.mean_abs2/2+k4*3*v^4*m.mean_abs4/8;
     lower=0;upper=max(unloaded,0);
     for n=1:80
      middle=(lower+upper)/2;residual=middle-p.diode_Is*(average_bessel*exp(-RL*middle/vscale)-1);
      if residual>0,upper=middle;else,lower=middle;end
     end
     current=(lower+upper)/2;power=current^2*RL;rf=v^2*m.mean_abs2/(2*p.resistance_ohm);eff=power/rf;full=unloaded;
    end
    rows=[rows;hi p.labels(li) c fr ref m.mean_abs2 m.mean_abs4 max(x) proxy full power eff verified fourier_delta]; %#ok<AGROW>
   end
   save(budgetfile,'charged','actual');writematrix(rows,fullfile(out,'diode_replay.csv'));fprintf('DIODE_REPLAY H%d label%d c%d charged%d\n',hi,p.labels(li),c,charged);
  end
 end
end
end
