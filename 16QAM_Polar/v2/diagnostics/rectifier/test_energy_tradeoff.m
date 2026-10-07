function test_energy_tradeoff()
% Deterministic numeric and real-chain assertions, without long simulation.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    previous=rng; cleanup=onCleanup(@() rng(previous));
    [front,roles,z,d]=energy_tradeoff_points([.45,1;.40,1.16;.42,1.32;.35,1.48]);
    assert(isequal(front,[true;false;true;true])); assert(roles(1,1)&&roles(4,2));
    assert(all(d>=0) && all(z(:)>=0) && all(z(:)<=1));
    [front,roles,z,d]=energy_tradeoff_points(ones(3,2));
    assert(all(front) && all(roles(:)) && all(z(:)==1) && all(d==0));
    rep=[];
    for seed=42:44
        rep=[rep;seed,.5,8,2,8,8,2,8,.5,.5;seed,.3,8,2,8,12,1,8,.25,.4]; %#ok<AGROW>
    end
    [r,t,~]=compute_energy_tradeoff_stats(rep);
    assert(all(r(r(:,2)==.5,13)==1)); assert(all(r(r(:,2)==.3,13)==1.5));
    assert(all(abs(r(r(:,2)==.3,15)-.35)<1e-14)); assert(all(t(:,3)==3));
    fails(@() compute_energy_tradeoff_stats([rep;rep(1,:)]),'energy:DuplicateKey');
    fails(@() compute_energy_tradeoff_stats(rep(rep(:,2)~=.5,:)),'energy:MissingBaseline');
    broken=rep; broken(1,6)=0; fails(@() compute_energy_tradeoff_stats(broken),'energy:InvalidData');
    varied=rep; varied([2,4,6],6)=[8;12;16];
    [~,tv,~]=compute_energy_tradeoff_stats(varied);
    row=tv(tv(:,1)==.3,:); half=4.302652729911275*.5/sqrt(3);
    assert(abs(row(14)-1.5)<1e-14 && abs(row(16)-(1.5-half))<1e-14);
    [~,shuffled,~]=compute_energy_tradeoff_stats(varied([6,3,1,5,2,4],:)); assert(isequal(tv,shuffled));
    fails(@() compute_energy_tradeoff_stats(rep(1:4,:)),'energy:SeedCount');
    tmp=tempname; mkdir(tmp); file=fullfile(tmp,'test.csv');
    write_energy_csv(file,{'x','y'},[1,2;3,4]); assert(isequal(readmatrix(file),[1,2;3,4]));
    fails(@() write_energy_csv(fullfile(tmp,'absent','file.csv'),{'x'},1),'energy:WriteFailed');
    delete(file); rmdir(tmp);
    cfg=config(); cfg.N=32; cfg.num_frames=2; cfg.seed=42;
    a=sim_shaped_polar_16qam(.3,[8,14],cfg); state_a=rng;
    cfg.collect_energy_frames=true; b=sim_shaped_polar_16qam(.3,[8,14],cfg); state_b=rng;
    assert(isequal(a.BER,b.BER) && isequal(a.spow,b.spow) && isequal(state_a,state_b));
    for j=1:2
        f=b.energy_frames(:,:,j);
        assert(abs(sum(f(:,3))/sum(f(:,2))-b.spow(j))<1e-14);
        assert(abs(sum(sum(f(:,6:9)))/(sum(b.K)*cfg.num_frames)-b.BER(j))<1e-14);
        assert(max(abs(f(:,5)-2*f(:,3)./f(:,2)*10^(-b.snr_dB(j)/10)))<1e-14);
    end
    cfg.energy_checkpoint=@(~,~,~,~) rand(3,1);
    c=sim_shaped_polar_16qam(.3,[8,14],cfg); assert(isequal(c.BER,b.BER)&&isequal(rng,state_b));
    cfg=rmfield(cfg,'energy_checkpoint'); cfg.seed=43;
    sim_shaped_polar_16qam(.3,[8,14],cfg); assert(~isequal(rng,state_b));
    fprintf('PASS: Pareto, ties, normalization, invalid data, RNG, BER counts, N0.\n');
end
function fails(fn,id)
    try
        fn();
    catch err
        assert(strcmp(err.identifier,id));return;
    end
    error('test:ExpectedFailure','Expected %s',id);
end
