"""Run approved P2 jobs sequentially, with persisted state and fail-closed gates."""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from zoneinfo import ZoneInfo


def now():
    return dt.datetime.now(ZoneInfo('Asia/Shanghai')).isoformat(timespec='seconds')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def quote(text):
    return "'"+str(text).replace('\\','/').replace("'","''")+"'"


def cell(paths):
    return '{'+','.join(quote(p) for p in paths)+'}'


class Batch:
    def __init__(self, root, protocol, approval, output):
        self.root=root; self.protocol=protocol; self.approval=approval; self.out=output
        p=json.loads(protocol.read_text(encoding='utf-8-sig')); a=json.loads(approval.read_text(encoding='utf-8-sig'))
        assert a['approved'] and a['protocol_sha256']==sha(protocol), 'Approval mismatch'
        for source in p['source_files']:
            assert sha(root/source['path'])==source['sha256'],source['path']
        self.jobs={job['job_id']:job for job in p['jobs']}
        self.state_path=output/'status.json'
        self.state=json.loads(self.state_path.read_text(encoding='utf-8')) if self.state_path.exists() else dict(
            started_at=now(),protocol_sha256=sha(protocol),approval_sha256=sha(approval),completed_jobs={},operations={},status='starting')
        assert self.state['protocol_sha256']==sha(protocol) and self.state['approval_sha256']==sha(approval)
        self.save()

    def save(self):
        self.state['updated_at']=now()
        temp=self.out/'status.pending.json'; temp.write_text(json.dumps(self.state,ensure_ascii=False,indent=2),encoding='utf-8')
        temp.replace(self.state_path)

    def event(self, text):
        line=f'{now()} {text}'
        with (self.out/'events.log').open('a',encoding='utf-8') as f:f.write(line+'\n')
        print(line,flush=True)

    def call(self, operation, statement):
        self.state.update(status='running',current_operation=operation); self.save(); self.event('START '+operation)
        started=time.monotonic(); runner=self.root/'scripts/run_matlab_local.ps1'
        log=self.out/(operation+'.log')
        command=['powershell','-NoProfile','-ExecutionPolicy','Bypass','-File',str(runner),statement]
        with log.open('ab') as stream:
            process=subprocess.Popen(command,cwd=self.root,stdout=stream,stderr=subprocess.STDOUT,
                                     creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
            self.state['current_wrapper_pid']=process.pid; self.save()
            result=process.wait()
        if result:
            raise RuntimeError(f'{operation} failed with exit {result}; see {log}')
        self.event(f'DONE {operation} ({time.monotonic()-started:.1f}s)')

    def job(self, job_id, **artifacts):
        assert job_id in self.jobs
        if job_id in self.state['completed_jobs']:
            path=Path(self.state['completed_jobs'][job_id]); assert (path/'completed.mat').is_file()
            return path
        marker=self.out/(job_id+'.path.txt')
        args='struct('+','.join(part for key,value in artifacts.items() for part in (quote(key),quote(value)))+')'
        statement=f'p2_execute_batch_job({quote(self.protocol)},{quote(self.approval)},{quote(job_id)},{args},{quote(marker)})'
        self.call(job_id,statement)
        path=Path(marker.read_text(encoding='utf-8-sig').strip()); assert (path/'completed.mat').is_file()
        self.state['completed_jobs'][job_id]=str(path); self.save(); return path

    def operation(self, name, statement, marker, target=None):
        if name in self.state['operations']:
            path=Path(self.state['operations'][name]); assert path.exists(); return path
        # Operations producing frozen artifacts refuse overwrite. If a wrapper
        # completed before status was committed, recover only its declared output.
        if target is None or not Path(target).exists():
            self.call(name,statement)
        path=Path(marker); assert path.exists(),path
        self.state['operations'][name]=str(path); self.save(); return path

    def power_and_pmf(self, lane):
        calibration=[self.job(f'{lane}_power_calibration_{seed}') for seed in (8101,8102,8103)]
        directory=self.out/(lane+'_frozen_power'); frozen=directory/'frozen_power.mat'
        self.operation(lane+'_freeze_power',f'p2_freeze_power({cell(calibration)},{quote(directory)})',frozen,frozen)
        validation=[self.job(f'{lane}_power_validation_{seed}',power_file=frozen) for seed in (8201,8202,8203)]
        checkdir=self.out/(lane+'_power_check'); check=checkdir/'power_gate.json'
        self.operation(lane+'_power_check',f'p2_batch_power_check({cell(validation)},{quote(frozen)},{quote(checkdir)})',check,check)
        power_result=json.loads(check.read_text()); self.state[lane+'_power_gate']=power_result; self.save()
        if not power_result['power_pass']:
            raise GateFailure(f'{lane} frozen power gate failed; no automatic calibration expansion is authorized')
        pmf=[self.job(f'{lane}_pmf_{seed}',power_file=frozen) for seed in (8701,8702,8703)]
        gates_dir=self.out/(lane+'_gates'); gates=gates_dir/'gates.json'
        self.operation(lane+'_acceptance',f'p2_audit_acceptance({cell(validation)},{cell(pmf)},{quote(frozen)},\'\',{quote(gates_dir)})',gates,gates)
        result=json.loads(gates.read_text()); self.state[lane+'_gates']=result; self.save()
        if not (result['power_pass'] and result['pmf_pass'] and result['contract_pass']):
            raise GateFailure(f'{lane} acceptance failed; dependent communication jobs stopped')
        return frozen,gates,validation,pmf

    def run(self):
        power,gates,validation,pmf=self.power_and_pmf('ofdm')
        # Single-carrier bridge precedes the final OFDM holdouts; it is not used
        # to fit the two global parameters.
        sp,sg,_,_=self.power_and_pmf('single')
        single=self.job('single_singlecarrier_8801',power_file=sp,gate_file=sg)
        training=self.job('ofdm_model_calibration_8401',power_file=power,gate_file=gates)
        model_dir=self.out/'frozen_model'; model=model_dir/'frozen_model.mat'
        self.operation('freeze_model',f'p2_freeze_model({cell([training])},{quote(model_dir)})',model,model)
        final_dir=self.out/'ofdm_model_bound_gates'; final_gates=final_dir/'gates.json'
        self.operation('bind_model',f'p2_audit_acceptance({cell(validation)},{cell(pmf)},{quote(power)},{quote(model)},{quote(final_dir)})',final_gates,final_gates)
        seen=self.job('ofdm_test_seen_8501',power_file=power,gate_file=final_gates,model_file=model)
        unseen=self.job('ofdm_test_unseen_8601',power_file=power,gate_file=final_gates,model_file=model)
        diagnostic=self.job('ofdm_pilot_8301',power_file=power)
        analysis=self.out/'independent_analysis'
        self.operation('independent_analysis',f'analyze_p2_mechanism({cell([seen,unseen])},{quote(analysis)},2000)',analysis/'README.txt',analysis/'README.txt')
        single_analysis=self.out/'singlecarrier_analysis'
        self.operation('singlecarrier_analysis',f'analyze_p2_mechanism({cell([single])},{quote(single_analysis)},2000)',single_analysis/'README.txt',single_analysis/'README.txt')
        self.state.update(status='completed',finished_at=now(),analysis=str(analysis),diagnostic=str(diagnostic))
        self.save(); self.event('COMPLETED approved jobs; scientific model use gate is reported separately')


class GateFailure(RuntimeError):
    pass


def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--protocol',type=Path,required=True)
    parser.add_argument('--approval',type=Path,required=True); parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args(); root=Path(__file__).resolve().parents[1]
    output=args.output.resolve(); output.relative_to((root/'16QAM_Polar/v2/results').resolve()); output.mkdir(parents=True,exist_ok=True)
    lock=(output/'orchestrator.lock').open('a+b'); lock.seek(0)
    if lock.read(1)==b'':lock.write(b'0');lock.flush()
    lock.seek(0)
    if os.name=='nt':
        import msvcrt
        msvcrt.locking(lock.fileno(),msvcrt.LK_NBLCK,1)
    batch=None
    try:
        batch=Batch(root,args.protocol.resolve(),args.approval.resolve(),output)
        batch.run()
    except Exception as error:
        if batch:
            batch.state.update(status='gate_failed' if isinstance(error,GateFailure) else 'error',error=str(error))
            batch.save(); batch.event('STOP '+str(error))
        raise
    finally:
        lock.close()


if __name__=='__main__':
    main()
