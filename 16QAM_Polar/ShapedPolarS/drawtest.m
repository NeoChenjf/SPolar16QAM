function drawtest(p1,p2)

SNR=-5:0.5:18;

[BER1,BLER1]=gettest(p1);
% semilogy(SNR,BER1,'r-o');
[BER2,BLER2]=gettest(p2);
[BER3,BLER3]=uncode;
[BER4,BLER4]=getSCL(p1);
[BER5,BLER5]=getSCL(p2);
[BER6,BLER6]=SCL_CRC(p1);
[BER7,BLER7]=SCL_CRC(p2);

for i=1:5

    BER1=smooth(BER1);
    BER2=smooth(BER2);
    BER3=smooth(BER3);
    BER4=smooth(BER4);
    BER5=smooth(BER5);
    BER6=smooth(BER6);
    BER7=smooth(BER7);
    
    BLER1=smooth(BLER1);
    BLER2=smooth(BLER2);
    BLER3=smooth(BLER3);
    BLER4=smooth(BLER4);
    BLER5=smooth(BLER5);
    BLER6=smooth(BLER6);
    BLER7=smooth(BLER7);
    
end

figure(1)
semilogy(SNR,BER1,'r-o');
hold on
semilogy(SNR,BER2,'b-o');
hold on
semilogy(SNR,BER3,'g-o');
hold on
semilogy(SNR,BER4,'r-x');
hold on
semilogy(SNR,BER5,'b-x');
hold on
semilogy(SNR,BER6,'r-d');
hold on
semilogy(SNR,BER7,'b-d');
xlabel('SNR (dB)');
ylabel('BER');
legend('SC p=0.5','SC p=0.75','uncode','SCL p=0.5','SCL p=0.75','SCLcrc p=0.5','SCLcrc p=0.75');
% legend('SC p=0.5','SC p=0.75','uncode');
% legend('p_1=0.9','p_1=0.5','p_1=0.1');


figure(2)
semilogy(SNR,BLER1,'r-o');
hold on
semilogy(SNR,BLER2,'b-o');
hold on
semilogy(SNR,BLER3,'g-o');
hold on
semilogy(SNR,BLER4,'r-x');
hold on
semilogy(SNR,BLER5,'b-x');
hold on
semilogy(SNR,BLER6,'r-d');
hold on
semilogy(SNR,BLER7,'b-d');
xlabel('SNR (dB)');
ylabel('BLER');
legend('SC p=0.5','SC p=0.75','uncode','SCL p=0.5','SCL p=0.75','SCLcrc p=0.5','SCLcrc p=0.75');
% legend('SC p=0.5','SC p=0.75','uncode');
% legend('p_1=0.9','p_1=0.5','p_1=0.1');
%%plot
%figure(1)
%semilogy(SNR,BER,'r-x');
%figure(2)
%semilogy(SNR,BLER,'r-o');