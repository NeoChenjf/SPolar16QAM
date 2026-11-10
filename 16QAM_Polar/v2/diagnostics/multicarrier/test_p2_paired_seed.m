function test_p2_paired_seed()
% Verify role separation, repeatability and inherited range checks.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    values=[]; roles={'payload','auxiliary','donor'};
    for g=1:3
        for j=1:numel(roles)
            x=p2_paired_seed('pilot',8301,1,2,3,g,roles{j});
            assert(x==p2_paired_seed('pilot',8301,1,2,3,g,roles{j}));
            values(end+1)=x; %#ok<AGROW>
        end
    end
    values(end+1)=p2_paired_seed('pilot',8301,1,2,3,0,'noise');
    values(end+1)=p2_paired_seed('pilot',8301,1,0,0,0,'channel');
    assert(numel(unique(values))==numel(values));
    assert(p2_paired_seed('test_seen',8501,31,15,8191,3,'donor')<=2^32-1);
    a=p2_paired_seed('strategy_training',9211,1,2,3,1,'payload');
    b=p2_paired_seed('strategy_test',9212,1,2,3,1,'payload'); assert(a~=b);
    fails(@() p2_paired_seed('power_validation',8211,1,2,3,1,'payload'),'pairedseed:ReservedSeed');
    fails(@() p2_paired_seed('pilot',8301,1,2,3,0,'donor'),'pairedseed:InvalidKey');
    fails(@() p2_paired_seed('pilot',8301,1,2,0,0,'noise'),'pairedseed:InvalidKey');
    fails(@() p2_paired_seed('pilot',8301,1,2,3,1,'unknown'),'pairedseed:InvalidRole');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
