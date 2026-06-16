function result=bit_to_symbol(bits)
result=0;
l=length(bits);
for i=1:l
    result=result+bits(i)*2^(l-i);
end
result=result+1;