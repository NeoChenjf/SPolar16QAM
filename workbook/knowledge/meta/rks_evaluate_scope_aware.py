#!/usr/bin/env python3
"""RKS structural audit with explicit research scope and fail-closed inputs.
The score reports metadata coverage only; it is never a scientific-validation result.
"""
import argparse, datetime, json, re, sys
from pathlib import Path
WEIGHTS={'method':.30,'flow':.20,'hypothesis':.20,'integrity':.15,'guardrail':.15}
EXCLUDED={'results','source_snapshot','archive','deprecated','.git'}
class AuditError(RuntimeError): pass
def read(path):
    try: return Path(path).read_text(encoding='utf-8')
    except Exception as e: raise AuditError(f'cannot read {path}: {e}')
def load(path):
    try: return json.loads(read(path))
    except AuditError: raise
    except Exception as e: raise AuditError(f'invalid JSON {path}: {e}')
def rel(root,path): return Path(path).resolve().relative_to(Path(root).resolve()).as_posix()
def files(root,paths,suffix):
    out={}
    for item in paths:
        p=(Path(root)/item).resolve()
        if not p.exists(): raise AuditError(f'missing scope path: {item}')
        candidates=[p] if p.is_file() else sorted(p.rglob('*'+suffix))
        for f in candidates:
            if f.is_file() and f.suffix.lower()==suffix and not any(x in EXCLUDED for x in f.parts): out[rel(root,f)]=f
    return sorted(out.items())
def excluded_files(root,paths,suffix):
    out=set()
    for item in paths:
        p=(Path(root)/item).resolve()
        candidates=[p] if p.is_file() else sorted(p.rglob('*'+suffix))
        for f in candidates:
            if f.is_file() and f.suffix.lower()==suffix and any(x in EXCLUDED for x in f.parts):
                out.add(rel(root,f))
    return sorted(out)
def require_nonempty_primary_scope(methods):
    if not methods: raise AuditError('empty primary code scope')
def layer(root,name):
    d=Path(root)/'workbook/knowledge'/name
    if not d.is_dir(): raise AuditError(f'missing knowledge layer {d}')
    return sorted(p for p in d.rglob('*.md') if not any(x in EXCLUDED for x in p.parts))
def current_revisions(root,index_path):
    obj=load(Path(root)/index_path)
    if not isinstance(obj,dict): raise AuditError('revision index root must be an object')
    entries=obj.get('documents')
    if not isinstance(entries,list) or not entries: raise AuditError('revision index is empty')
    seen=set(); current={}
    for e in entries:
        if not isinstance(e,dict): raise AuditError(f'invalid revision entry: {e}')
        rid,path,status=e.get('revision_id'),e.get('path'),e.get('status')
        if not rid or not path or rid in seen: raise AuditError(f'invalid/duplicate revision entry: {e}')
        if any(x not in seen for x in e.get('supersedes',[])): raise AuditError(f'unknown/non-prior supersedes link: {rid}')
        seen.add(rid)
        if status=='current':
            if path in current: raise AuditError(f'multiple current revisions: {path}')
            if not (Path(root)/path).is_file(): raise AuditError(f'current target missing: {path}')
            current[path]=rid
        elif status not in {'superseded','historical','planned'}: raise AuditError(f'invalid revision status: {rid}={status}')
    if not current: raise AuditError('no current revisions')
    return current
def current_revision_body(text,revision_id):
    """Return only the section governed by an indexed current revision marker."""
    marker=re.compile(r'^Revision metadata: revision_id='+re.escape(revision_id)+r'; current_status=current; supersedes=.*$',re.M)
    matches=list(marker.finditer(text))
    if not matches:
        if revision_id.startswith('baseline_'):
            return text
        raise AuditError(f'current revision marker missing from document: {revision_id}')
    if len(matches)!=1: raise AuditError(f'duplicate current revision marker: {revision_id}')
    end=matches[0].start()
    previous=list(re.finditer(r'^Revision metadata:.*$',text[:end],re.M))
    start=previous[-1].end() if previous else 0
    body=text[start:end].strip()
    if not body: raise AuditError(f'empty current revision body: {revision_id}')
    return body
def parse_claims(root):
    claims={}; declarations={}
    for f in layer(root,'L1'):
        txt=read(f); m=re.search(r'^\s*-\s*\*\*domain_id\*\*:\s*(l1_[\w]+)',txt,re.M)
        if not m: raise AuditError(f'malformed/missing domain_id: {rel(root,f)}')
        did=m.group(1)
        markers=list(re.finditer(r'^Revision metadata: revision_id=([^;]+);.*$',txt,re.M))
        for declaration in re.finditer(r'^\s*[-*]?\s*(H\d+)\s*(?:[:：（(])[^\n]*',txt,re.M):
            key=f'{did}#{declaration.group(1)}'; path=rel(root,f)
            boundary=re.search(r'\n(?=(?:[ \t]*\n)|(?:[ \t]*[-*]\s)|(?:[ \t]*#)|(?:Revision metadata:))',txt[declaration.end():])
            end=declaration.end()+boundary.start() if boundary else len(txt)
            following=next((m for m in markers if m.start()>=end),None)
            revision=following.group(1) if following else None
            signature=txt[declaration.start():end].strip()
            if key in claims:
                old_text,old_revision=declarations[key]
                if claims[key]!=path or old_text!=signature or not old_revision or old_revision==revision:
                    raise AuditError(f'duplicate/conflicting hypothesis {key}')
                # Only identical full declarations in an explicit registered
                # supersedes chain are historical copies, never extra claims.
                index_path='workbook/knowledge/meta/current-revisions.json'
                current_revisions(root,index_path)
                records={e['revision_id']:e for e in load(Path(root)/index_path)['documents'] if e['path']==path}
                if old_revision not in records or revision not in records:
                    raise AuditError(f'unregistered duplicate hypothesis {key}')
                ancestors=set(); pending=list(records[revision].get('supersedes',[]))
                while pending:
                    ancestor=pending.pop()
                    if ancestor in ancestors: continue
                    if ancestor not in records: raise AuditError(f'cross-document claim revision: {key}')
                    ancestors.add(ancestor); pending.extend(records[ancestor].get('supersedes',[]))
                if old_revision not in ancestors: raise AuditError(f'unrelated duplicate hypothesis {key}')
            claims[key]=path; declarations[key]=(signature,revision)
    if not claims: raise AuditError('zero parseable hypotheses; fail closed')
    return claims
def validate_evidence_registry(root,claims,index):
    if not isinstance(index,dict) or not isinstance(index.get('claims'),list): raise AuditError('research-claims registry must contain a claims list')
    if any(not isinstance(c,dict) for c in index['claims']): raise AuditError('malformed research claim entry')
    registered={c.get('claim_id'):c for c in index['claims']}
    if set(registered)!=set(claims): raise AuditError('research-claims registry does not exactly match current L1 claim IDs')
    allowed=set(index.get('allowed_evidence_states',[]))
    if not allowed: raise AuditError('research-claims registry has no allowed evidence states')
    counts={state:0 for state in allowed}
    for cid,c in registered.items():
        state=c.get('evidence_state')
        if state not in allowed: raise AuditError(f'invalid evidence state for {cid}: {state}')
        counts[state]+=1
        if not isinstance(c.get('supporting_evidence'),list): raise AuditError(f'evidence links must be a list: {cid}')
        if state in {'supporting','contradicting'} and not c['supporting_evidence']:
            raise AuditError(f'assessed claim lacks evidence records: {cid}')
        for evidence in c['supporting_evidence']:
            if not isinstance(evidence,dict) or not evidence.get('path'): raise AuditError(f'malformed evidence link: {cid}')
            if not (Path(root)/evidence['path']).exists(): raise AuditError(f'evidence target missing for {cid}: {evidence["path"]}')
            if state in {'supporting','contradicting'}:
                required={'experiment_id','construction_version','parameters','seed','source_hash','data_path','figure_path','acceptance_record_path'}
                if not required.issubset(evidence) or not evidence.get('experiment_id') or not evidence.get('construction_version') or not evidence.get('source_hash'):
                    raise AuditError(f'incomplete evidence record for assessed claim {cid}')
                for key in ('data_path','figure_path','acceptance_record_path'):
                    if not (Path(root)/evidence[key]).exists(): raise AuditError(f'evidence target missing for {cid}: {evidence[key]}')
    return counts
def validate_l2_claim_refs(l2_texts,claims):
    valid=set(); invalid=[]
    for l2,txt in l2_texts.items():
        for d,h in re.findall(r'\b(l1_[\w]+)#(H\d+)\b',txt):
            claim=f'{d}#{h}'
            if claim in claims: valid.add(claim)
            else: invalid.append((l2,claim))
    return valid,invalid
def method_contract_gaps(method_paths,l3_texts):
    exact={}
    for contract_path,txt in l3_texts.items():
        m=re.search(r'^\s*-\s*\*\*file_path\*\*:\s*(.+?)\s*$',txt,re.M)
        if m: exact.setdefault(m.group(1).replace('\\','/'),[]).append(contract_path)
    gaps=[]
    for src in method_paths:
        if len(exact.get(src,[]))==1: continue
        same_name=[cp for cp in l3_texts if Path(cp).stem==('l3_'+Path(src).stem)]
        same_source_name=[p for p in method_paths if Path(p).stem==Path(src).stem]
        if len(same_name)!=1 or len(same_source_name)!=1: gaps.append(src)
    return gaps
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--project-root',required=True); ap.add_argument('--system-id',default='spolar16qam'); ap.add_argument('--write-report',action='store_true'); ap.add_argument('--append-ledger',action='store_true'); ap.add_argument('--now',default=''); a=ap.parse_args(); root=Path(a.project_root).resolve()
    try:
        scope=load(root/'workbook/knowledge/meta/research-scope.json')
        if not isinstance(scope,dict): raise AuditError('research scope root must be an object')
        lanes=scope.get('lanes',{})
        if not isinstance(lanes,dict): raise AuditError('research scope lanes must be an object')
        mainline=lanes.get('mainline_16qam'); support=lanes.get('multi_qam_transferability')
        if not mainline or mainline.get('role')!='primary' or not support or support.get('role')!='supporting': raise AuditError('scope must define primary 16QAM and supporting multi-QAM')
        methods=files(root,mainline.get('method_paths',[]),'.m'); flows=files(root,mainline.get('flow_paths',[]),'.m'); supp=files(root,support.get('paths',[]),'.m')
        excluded=excluded_files(root,mainline.get('method_paths',[])+mainline.get('flow_paths',[]),'.m')
        require_nonempty_primary_scope(methods)
        revisions=current_revisions(root,scope['current_revision_index']); claims=parse_claims(root)
        evidence_index=load(root/'workbook/knowledge/meta/research-claims.json')
        evidence_counts=validate_evidence_registry(root,claims,evidence_index)
        l2={}; l3={}
        for name,target in [('L2',l2),('L3',l3)]:
            for f in layer(root,name):
                path=rel(root,f); full=read(f); rid=revisions.get(path)
                if not rid: raise AuditError(f'knowledge document missing from current-revision index: {path}')
                target[path]=current_revision_body(full,rid)
        method_missing=method_contract_gaps([src for src,_ in methods],l3)
        runs=[(p,t) for p,t in flows if Path(p).name.startswith('run_')]
        flow_missing=[]
        for src,_ in runs:
            matched=False
            for txt in l2.values():
                m=re.search(r'^\s*-\s*\*\*entry_script\*\*:\s*([^\s]+)',txt,re.M)
                if m and m.group(1).replace('\\','/')==src: matched=True; break
            if not matched: flow_missing.append(src)
        validated,bad_h=validate_l2_claim_refs(l2,claims); bad_l3=[]; guard=[]
        l3_ids={Path(p).stem for p in l3}
        for lp,txt in l2.items():
            for ref in set(re.findall(r'\b(l3_[\w]+)\b',txt))-{ 'l3_ref','l3_xxx','l3_yyy','l3_bbb' }:
                if ref not in l3_ids: bad_l3.append((lp,ref,'missing'))
        for claim,path in claims.items():
            rid=revisions.get(path)
            if not rid: raise AuditError(f'L1 claim document missing from current-revision index: {path}')
            l1_current=current_revision_body(read(root/path),rid)
            if '⚠️' not in l1_current: continue
            d,h=claim.split('#'); related=[]
            for lp,txt in l2.items():
                if f'{d}#{h}' not in txt: continue
                parts=re.split(r'^##\s+Acceptance\s*$',txt,flags=re.M)
                if len(parts)>1 and re.search(r'瀑布|码率上界|口径|needs_user_run|基线|功率|护栏',parts[-1],re.I): related.append(lp)
            guard.append((claim,related))
        vals={
          'method':(100*(len(methods)-len(method_missing))/len(methods),len(methods)-len(method_missing),len(methods)),
          'flow':(100*(len(runs)-len(flow_missing))/len(runs) if runs else 0,len(runs)-len(flow_missing),len(runs)),
          'hypothesis':(100*len(validated)/len(claims),len(validated),len(claims)),
          'integrity':(100*(len(l3_ids)-min(len(bad_l3),len(l3_ids)))/len(l3_ids) if l3_ids else 0,len(l3_ids)-min(len(bad_l3),len(l3_ids)),len(l3_ids)),
          'guardrail':(100*sum(bool(x[1]) for x in guard)/len(guard) if guard else 0,sum(bool(x[1]) for x in guard),len(guard))}
        score=sum(vals[k][0]*w for k,w in WEIGHTS.items()); ts=a.now or datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        lines=[f'RKS STRUCTURAL AUDIT — {a.system_id}',f'time: {ts}',f'scope: {scope.get("scope_id")}',f'current revision records: {len(revisions)}',f'primary 16QAM method files: {len(methods)}',f'primary flow/diagnostic files: {len(flows)}',f'supporting multi-QAM code files (separate): {len(supp)}',f'claim evidence states: {evidence_counts}']
        for k,(pct,ok,n) in vals.items(): lines.append(f'{k}: {ok}/{n} ({pct:.1f}%)')
        lines += [f'structural score: {score:.1f}/100; not scientific evidence.','INCLUDED PRIMARY FILES:']+[f'- {p}' for p,_ in methods+flows]
        lines += ['SUPPORTING FILES (not in primary denominator):']+[f'- {p}' for p,_ in supp]
        lines += ['EXCLUSION RULES:']+[f'- {x}' for x in sorted(EXCLUDED)]
        lines += ['EXCLUDED MATCHING FILES:']+[f'- {p}' for p in excluded] if excluded else ['EXCLUDED MATCHING FILES','- none under active primary paths']
        for title,items in [('METHOD CONTRACT GAPS',method_missing),('RUN ENTRY GAPS',flow_missing),('UNREFERENCED HYPOTHESES',sorted(set(claims)-validated)),('INVALID HYPOTHESIS REFERENCES',bad_h),('INVALID L3 REFERENCES',bad_l3)]:
            lines += [title]+([f'- {x}' for x in items] or ['- none'])
        lines += ['PER-CLAIM GUARDRAIL ACCEPTANCE:']+[f'- {c}: {", ".join(ps) if ps else "missing"}' for c,ps in guard]
        report='\n'.join(lines)+'\n'; print(report,end='')
        if a.write_report:
            out=root/'workbook/knowledge/reports'/f'rks-{ts}.md'; out.parent.mkdir(parents=True,exist_ok=True)
            if out.exists(): raise AuditError(f'refusing report overwrite: {out}')
            out.write_text(report,encoding='utf-8')
        if a.append_ledger:
            ledger=root/'workbook/knowledge/meta/scan-ledger.tsv'; ledger.parent.mkdir(parents=True,exist_ok=True)
            if not ledger.exists() or ledger.stat().st_size==0: ledger.write_text('timestamp\tsystem_id\trks_structural\tmethod\tflow\thypothesis\tintegrity\tguardrail\tverdict\n',encoding='utf-8')
            with ledger.open('a',encoding='utf-8') as f:f.write(ts+'\t'+a.system_id+'\t'+f'{score:.1f}'+'\t'+'\t'.join(f'{vals[k][0]:.1f}' for k in WEIGHTS)+'\tSTRUCTURE_ONLY\n')
        return 0
    except (AuditError,OSError,KeyError,TypeError,ValueError) as e: print(f'ERROR: {e}',file=sys.stderr); return 2
if __name__=='__main__': sys.exit(main())
