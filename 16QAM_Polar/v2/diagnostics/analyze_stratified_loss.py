import csv,pathlib,statistics,math,random,json
from collections import defaultdict
out=pathlib.Path('16QAM_Polar/v2/results/20261110_170520_stratified_loss');rows=[[float(x) for x in r] for r in csv.reader((out/'streams.csv').open())]
# H,p,label,frame,group,stream,first,type,bin,Ierr,Ibits,after,n_after
assert len(rows)==14400
for x in rows:assert x[9]==x[11]+int(not math.isnan(x[6]) and x[7]==0)
summary=[];details=[];rng=random.Random(11011705)
def table(a):
 t=defaultdict(list)
 for x in a:
  if x[8]>0:t[(int(x[4]),int(x[5]),int(x[8]))].append(x[11])
 return {k:(len(v),statistics.mean(v)) for k,v in t.items()}
for h in (1,2,3):
 for p in (1,2):
  for source,target in ((20,28),(28,20)):
   a=[x for x in rows if x[:3]==[h,p,source]];b=[x for x in rows if x[:3]==[h,p,target]];t=table(a);frames=defaultdict(lambda:[0.,0.,0.,0.,0.,0.]);supported=events=0
   for x in b:
    v=frames[int(x[3])];v[0]+=x[9];v[1]+=x[10]
    if x[8]==0:continue
    events+=1;k=(int(x[4]),int(x[5]),int(x[8]));n,loss=t.get(k,(0,0));first=int(x[7]==0)
    if n>=10:
     supported+=1;est=first+min(x[12],loss);v[2]+=est-x[9];v[3]+=x[10];v[4]+=est;v[5]+=est
    else:
     v[4]+=first;v[5]+=first+x[12]
    details.append([h,p,source,target,*k,n,x[3],x[6],x[11],x[12],n>=10])
   f=list(frames.values());den=sum(x[1] for x in f);bias=sum(x[2] for x in f)/max(1,sum(x[3] for x in f));lo=sum(x[4] for x in f)/den;hi=sum(x[5] for x in f)/den;actual=sum(x[0] for x in f)/den
   # two-sample frame bootstrap; no re-selection of support rule in repetitions
   af={i:[x for x in a if x[3]==i] for i in range(1,101)};bf={i:[x for x in b if x[3]==i] for i in range(1,101)};boot=[]
   keys={k for k,(n,l) in t.items() if n>=10}
   for rep in range(200):
    bt=table([x for _ in range(100) for x in af[rng.randint(1,100)]]);err=weight=0
    for _ in range(100):
     for x in bf[rng.randint(1,100)]:
      k=(int(x[4]),int(x[5]),int(x[8]))
      if x[8]>0 and k in keys and k in bt:err+=int(x[7]==0)+min(x[12],bt[k][1])-x[9];weight+=x[10]
    if weight:boot.append(err/weight)
   boot.sort();ci=[boot[int(.025*(len(boot)-1))],boot[int(.975*(len(boot)-1))]] if boot else [float('nan')]*2
   summary.append([h,p,source,target,events,supported,supported/max(1,events),actual,bias,*ci,lo,hi,len(keys),len(t)])
with (out/'transfer.csv').open('w',newline='') as f:
 w=csv.writer(f);w.writerow(['H','p_index','source_label','target_label','target_first_events','supported_events','event_coverage','actual_BER','supported_bias','bootstrap_lo','bootstrap_hi','all_frame_prediction_lo','all_frame_prediction_hi','eligible_strata','observed_source_strata']);w.writerows(summary)
with (out/'coverage.csv').open('w',newline='') as f:csv.writer(f).writerows(details)
print(json.dumps(summary));(out/'analysis_parameters.json').write_text(json.dumps({'bins':[1,256,512,768,1024],'minimum_source_events':10,'bootstrap_reps':200,'seed':11011705,'oracle':'target first position/type and n_after observed','uncertainty':'independent frame resampling of source and target; fixed observed support set; pointwise exploratory percentile intervals','new_communication_frames':0},indent=2))
