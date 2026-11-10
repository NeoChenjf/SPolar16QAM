function test_rectifier_proxy_from_moments()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    z=[0;1;1i;2]; m=rf_envelope_moments(z);
    a=rectifier_moment_proxy(z,2,50,.0034,.3829,[0 1]);
    b=rectifier_proxy_from_moments(m.mean_abs2,m.mean_abs4,2,50,.0034,.3829,[0 1]);
    assert(abs(a.current_proxy_a-b.current_proxy_a)<1e-12 && ...
        a.rf_input_power_w==b.rf_input_power_w && strcmp(a.status,b.status));
    a=rectifier_moment_proxy(z,2,50,.0034,.3829,[0 .001]);
    b=rectifier_proxy_from_moments(m.mean_abs2,m.mean_abs4,2,50,.0034,.3829,[0 .001]);
    assert(strcmp(a.status,'out_of_range') && strcmp(b.status,'out_of_range') && isnan(b.current_proxy_a));
    caught=false; try, rectifier_proxy_from_moments(2,1,1,50,1,1,[0 1]);
    catch e, caught=strcmp(e.identifier,'rectmoments:InvalidMoments'); end; assert(caught);
    z=ones(16,1); w=[zeros(8,1);sqrt(2)*ones(8,1)];
    a=rectifier_proxy_from_moments(mean(abs(z).^2),mean(abs(z).^4),1,50,1,1,[0 1]);
    b=rectifier_proxy_from_moments(mean(abs(w).^2),mean(abs(w).^4),1,50,1,1,[0 1]);
    assert(abs(a.rf_input_power_w-b.rf_input_power_w)<1e-12 && b.current_proxy_a>a.current_proxy_a);
end

