function test_rectifier_moment_proxy()
% Test explicit peak-envelope conversion, range and invalid data.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    x=rectifier_moment_proxy([1,-1],2,50,1,1,[0,.1]);
    assert(abs(x.rf_input_power_w-.04)<1e-12 && abs(x.rf_voltage_second_v2-2)<1e-12);
    assert(abs(x.rf_voltage_fourth_v4-6)<1e-12 && abs(x.current_proxy_a-8)<1e-12 && ~x.is_dc_power);
    y=rectifier_moment_proxy([0,sqrt(2)],2,50,1,1,[0,.1]);
    assert(abs(y.rf_input_power_w-x.rf_input_power_w)<1e-12 && y.current_proxy_a>x.current_proxy_a);
    z=rectifier_moment_proxy(0,1,50,1,1,[0,.1]); assert(z.current_proxy_a==0);
    z=rectifier_moment_proxy([1,-1],2,50,1,1,[0,.01]);
    assert(strcmp(z.status,'out_of_range') && isnan(z.current_proxy_a));
    fails(@() rectifier_moment_proxy(1,0,50,1,1,[0,1]),'rectproxy:InvalidScale');
    fails(@() rectifier_moment_proxy(1,1,50,-1,1,[0,1]),'rectproxy:InvalidCoefficients');
    fails(@() rectifier_moment_proxy(1,1,50,1,1,[1,0]),'rectproxy:InvalidRange');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
