import pathlib,csv,math,statistics
from collections import defaultdict
out=pathlib.Path('16QAM_Polar/v2/results/20261110_170520_stratified_loss');r=[list(map(float,x)) for x in csv.reader((out/'streams.csv').open())];result=[]
for width in [256,64,1]:
 for norm in [0,1]:
  for h in [1,2,3]:
   for p in [1,2]:
    for source,target in [(20,28),(28,20)]:
     a=[x for x in r if x[:3]==[h,p,source]];b=[x for x in r if x[:3]==[h,p,target]];t=defaultdict(list)
     def key(x):return (x[4],x[5],math.ceil(x[6]/width))
     for x in a:
      if x[8]>0:t[key(x)].append(x[11]/max(1,x[12]) if norm else x[11])
     supported=events=0;err=weight=0;lb=ub=den=actual=0
     for x in b:
      den+=x[10];actual+=x[9]
      if x[8]==0:continue
      events+=1;v=t.get(key(x),[]);first=int(x[7]==0)
      if len(v)>=10:
       supported+=1;loss=statistics.mean(v)*(x[12] if norm else 1);est=first+min(x[12],loss);err+=est-x[9];weight+=x[10];lb+=est;ub+=est
      else:lb+=first;ub+=first+x[12]
     result.append([width,norm,h,p,source,target,supported/max(1,events),err/max(1,weight),lb/den,ub/den,actual/den,supported,events])
with (out/'sensitivity.csv').open('w',newline='') as f:csv.writer(f).writerows(result)
for width in [256,64,1]:
 for norm in [0,1]:
  a=[x for x in result if x[:2]==[width,norm]];print(width,norm,'coverage',min(x[6] for x in a),max(x[6] for x in a),'abs supported bias',statistics.mean(abs(x[7]) for x in a),'full interval misses',sum(not x[8]<=x[10]<=x[9] for x in a))
