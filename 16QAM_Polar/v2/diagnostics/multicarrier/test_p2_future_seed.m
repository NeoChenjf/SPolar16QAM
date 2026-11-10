function test_p2_future_seed()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    splits={'pmf_train','model_train','seen_first','unseen_first','seen_retest','unseen_retest','strategy_train','strategy_test','diagnostic_a','diagnostic_b','seen_first_v2','unseen_first_v2','strategy_test_v2'};
    roles={'payload','auxiliary','donor'}; keys=[];
    for s=1:numel(splits)
        for ch=[1,31]
            keys(end+1)=p2_future_seed(splits{s},ch,0,0,0,'channel'); %#ok<AGROW>
            for snr=[1,15]
                for frame=[1,8191]
                    keys(end+1)=p2_future_seed(splits{s},ch,snr,frame,0,'noise'); %#ok<AGROW>
                    for r=1:numel(roles)
                        for g=1:3
                            keys(end+1)=p2_future_seed(splits{s},ch,snr,frame,g,roles{r}); %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
    oldmax=2*(11*134217728-1)+1;
    assert(numel(unique(keys))==numel(keys) && min(keys)>oldmax && max(keys)<=2^32-1);
    caught=false; try,p2_future_seed('seen_first',1,1,1,0,'payload');catch e,caught=strcmp(e.identifier,'futureseed:InvalidKey');end; assert(caught);
    caught=false; try,p2_future_seed('unregistered',1,0,0,0,'channel');catch e,caught=strcmp(e.identifier,'futureseed:InvalidSplit');end; assert(caught);
    assert(p2_future_seed('seen_first',1,1,1,1,'payload')==p2_future_seed('seen_first',1,1,1,1,'payload'));
    saved=rng; cleanup=onCleanup(@() rng(saved)); %#ok<NASGU>
    hi=p2_future_seed('strategy_test',31,15,8191,3,'donor');
    rng(hi,'twister'); v=randn(1,16); rng(hi,'twister'); w=randn(1,16);
    assert(isequal(v,w),'High uint32 key did not reproduce samples.');
    rng(p2_future_seed('strategy_test',31,15,8191,3,'payload'),'twister');
    assert(~isequal(v,randn(1,16)),'Distinct roles unexpectedly matched in smoke.');
    fprintf('%d boundary keys distinct; old max %.0f; new min %.0f\n',numel(keys),oldmax,min(keys));
end




