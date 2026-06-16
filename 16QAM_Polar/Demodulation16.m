function [rxdata] = Demodulation16(rxSig)
% 输入16QAM实部和虚部 输出二进制序列
rxdata = zeros(1,4*length(rxSig));
for i=1:length(rxSig)
    if real(rxSig(i))>=0
        rxdata(4*i-3)=1;
        if imag(rxSig(i))>=0
            rxdata(4*i-2)=1;
            if real(rxSig(i))>=2
            rxdata(4*i-1)=1;
                if imag(rxSig(i))>=2
                    rxdata(4*i)=1;
                end
            else
                if imag(rxSig(i))>=2
                    rxdata(4*i)=1;
                end
            end
        else
            if real(rxSig(i))>=2
            rxdata(4*i-1)=1;
                if imag(rxSig(i))>=-2
                    rxdata(4*i)=1;
                end
            else
                if imag(rxSig(i))>=-2
                    rxdata(4*i)=1;
                end
            end 
        end
    else
        if imag(rxSig(i))>=0
            rxdata(4*i-2)=1;
            if real(rxSig(i))>=-2
            rxdata(4*i-1)=1;
                if imag(rxSig(i))>=2
                    rxdata(4*i)=1;
                end
            else
                if imag(rxSig(i))>=2
                    rxdata(4*i)=1;
                end
            end
        else
            if real(rxSig(i))>=-2
            rxdata(4*i-1)=1;
                if imag(rxSig(i))>=-2
                    rxdata(4*i)=1;
                end
            else
                if imag(rxSig(i))>=-2
                    rxdata(4*i)=1;
                end
            end 
        end
    end
end


end

