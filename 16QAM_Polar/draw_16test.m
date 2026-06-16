% clear all;
% clc; close all;
addpath('ShapedpolarS/');

SNR=-5:5:30;

[BER1,BLER1,energy1]=get_16test(0.5); % energy=1
[BER2, BLER2,energy2] = get_16test(0.3); % 第二路energy = 1.1
[BER3, BLER3,energy3] = get_16test(0.21); % 第三路 energy = 1.2
[BER4, BLER4,energy4] = get_16test(0.16); % 第四路 energy = 1.3
[BER5, BLER5,energy5] = get_16test(0.1); % 第五路 energy = 1.4


BE1 = (1-BER1)/2;
BE2 = (1-BER2)*1926/4096;
BE3 = (1-BER3)*1784/4096;
BE4 = (1-BER4)*1674/4096;
BE5 = (1-BER5)*1504/4096;

% 将 BE1..BE5（已命名为 BE1..BE5）与 SNR 保存到表格并导出
T = table(SNR(:), BE1(:), BE2(:), BE3(:), BE4(:), BE5(:), ...
	'VariableNames',{'SNR','BE1','BE2','BE3','BE4','BE5'});
save('BER_BE1_BE5.mat','T');
try
	writetable(T,'BER_BE1_BE5.csv');
catch
	warning('writetable failed — perhaps older MATLAB version; MAT file still saved.');
end

plot(SNR,BE1);
hold on
plot(SNR,BE2);
plot(SNR,BE3);
plot(SNR,BE4);
plot(SNR,BE5);
legend(' 均方为1',' 均方为1.1',' 均方为1.2',' 均方为1.3',' 均方为1.4');
xlabel('SNR');
ylabel('R_{eff}');

% semilogy(SNR,BER1);
% hold on
% semilogy(SNR,BER2);
% semilogy(SNR,BER3);
% semilogy(SNR,BER4);
% semilogy(SNR,BER5);
% hold off

% semilogy(SNR,smooth(BER1));
% hold on
% semilogy(-5:0.5:13,(smooth(BER5(1:length(-5:0.5:13)))));
% hold off

% legendStr1 = sprintf('energy = %.2f', energy1);
% legendStr2 = sprintf('energy = %.2f', energy2);
% legendStr3 = sprintf('energy = %.2f', energy3);
% legendStr4 = sprintf('energy = %.2f', energy4);
% legendStr5 = sprintf('energy = %.2f', energy5);
% 
% legend(legendStr1,legendStr2,legendStr3,legendStr4,legendStr5);
% legend('均方为1','均方为1.1','均方为1.2','均方为1.3','均方为1.4');
% xlabel('SNR');
% ylabel('BER');
% 
% % figure;
% MI = [
%  [0.044275, 0.127125, 0.314675, 0.60345,  0.89565,  0.997425, 1.0000, 1.0000];
%  [0.045600, 0.128375, 0.312400, 0.59425,  0.87295,  0.995075, 1.0000, 1.0000];
%  [0.046700, 0.132950, 0.313325, 0.58810,  0.85370,  0.993225, 1.0000, 1.0000];
%  [0.049800, 0.137950, 0.316900, 0.583075, 0.857475, 0.993025, 1.0000, 1.0000];
%  [0.056100, 0.148250, 0.328550, 0.578775, 0.841075, 0.989475, 1.0000, 1.0000]
% ];




