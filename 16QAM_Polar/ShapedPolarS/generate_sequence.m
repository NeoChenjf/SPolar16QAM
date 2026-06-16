function result=generate_sequence(L,P_source)
% result=zeros(1,L);
% state=0;
% for i=1:L
%     label=find(Pc(state+1,:)~=0);
%     if length(label)==1
%         if label~=1
%             result(i)=1;
%             state=state+1;
%             continue;
%         else
%             result(i)=0;
%             state=0;
%             continue;
%         end
%     else
%         if label(1)==1
%             to0=label(1);
%             to1=label(2);
%         else
%             to1=label(1);
%             to0=label(2);
%         end
%         temp=rand(1);
%         if temp<Pc(state+1,to0)
%             result(i)=0;
%             state=0;
%             continue;
%         else
%             result(i)=1;
%             state=state+1;
%             continue;
%         end
%     end
% end
result=[];
for l=1:L
    temp=rand(1);
    k=1;
    while(temp-P_source(k)>0)
        temp=temp-P_source(k);
        k=k+1;
    end
    code=[ones(1,k-1) 0];
    result=[result code];
end