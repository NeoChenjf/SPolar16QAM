function report=verify_b4b_guardband_policy_test_analysis(result_dir)
% Audit the third-split guard-band policy analysis.
    result_dir=char(result_dir);
    V=readtable(fullfile(result_dir,'guardband_policy_test_summary.csv'));
    D=load(fullfile(result_dir,'guardband_policy_test_analysis.mat'));
    assert(height(V)==6 && isequal(V.snr_dB.',[20 24 28 32 36 40]));
    assert(all(strcmp(V.selected_strategy(1:2),'uniform_p05')));
    assert(all(strcmp(V.selected_strategy(3:end),'uniform_p01')));
    assert(all(V.point_pass) && D.overall_pass);
    assert(all(V.ber_upper95(3:end)<=D.ber_limit));
    assert(all(V.goodput_lower95(3:end)>=D.goodput_floor));
    assert(all(V.energy_gain_vs_p05(3:end)>0));
    for ext={'png','pdf','fig'}
        assert(exist(fullfile(result_dir,'figures',['b4b_guardband_policy_validation.' ext{1}]),'file')==2);
    end
    report=struct('status','PASS','overall_pass',D.overall_pass);
    fid=fopen(fullfile(result_dir,'audit.txt'),'w'); assert(fid>=0); c=onCleanup(@()fclose(fid));
    fprintf(fid,'B4b GUARDBAND POLICY THIRD-SPLIT AUDIT: PASS\noverall_pass=1\n');
    fprintf(fid,'Checks: frozen mapping, guard-band fallback, interval gates, energy direction, figures.\n');
end
