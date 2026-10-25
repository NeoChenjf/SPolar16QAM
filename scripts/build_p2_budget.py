"""Freeze an UNAPPROVED P2 job proposal using measured short-run timings."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import statistics
from pathlib import Path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--pilot', type=Path, required=True)
    parser.add_argument('--calibration', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    v2 = root / '16QAM_Polar/v2'
    seen_names = ['uniform_p05', 'uniform_p03', 'uniform_p01',
                  'good_channel_information', 'good_channel_energy_shaping']
    seen_p = [[.5,.5,.5],[.3,.3,.3],[.1,.1,.1],[.5,.3,.1],[.1,.3,.5]]
    unseen_names = ['heldout_1','heldout_2','heldout_3']
    unseen_p = [[.3,.1,.5],[.3,.5,.1],[.5,.1,.3]]
    controls = ['shaped','random_s','donor_s','native']
    snr = [20,24,28,32,36,40]
    jobs = []

    def add(lane, purpose, seed, channels, frames, names, ps, grid, kinds, predict=False, diagnose=False):
        job = dict(job_id=f'{lane}_{purpose}_{seed}', purpose=purpose, seed=seed,
                   num_channels=channels, num_frames=frames, strategy_names=names,
                   strategy_p=ps, controls=kinds, snr_grid=grid, N=1024,
                   n_sc=64 if lane=='ofdm' else 1, cp=16 if lane=='ofdm' else 0,
                   taps=16 if lane=='ofdm' else 1, source_seed=9001, source_samples=200,
                   quadrature_order=10, predict=predict, diagnose=diagnose)
        jobs.append(job)

    for purpose, seeds in [('power_calibration',[8101,8102,8103]),
                           ('power_validation',[8201,8202,8203]), ('pmf',[8701,8702,8703])]:
        for seed in seeds:
            add('ofdm',purpose,seed,1,80,seen_names+unseen_names,seen_p+unseen_p,snr,controls)
    add('ofdm','model_calibration',8401,10,20,seen_names,seen_p,snr,controls,True)
    add('ofdm','test_seen',8501,30,50,seen_names,seen_p,snr,controls,True)
    add('ofdm','test_unseen',8601,30,50,unseen_names,unseen_p,snr,controls,True)
    add('ofdm','pilot',8301,3,2,seen_names,seen_p,[24,28,32],controls,False,True)
    for purpose, seeds in [('power_calibration',[8101,8102,8103]),
                           ('power_validation',[8201,8202,8203]), ('pmf',[8701,8702,8703])]:
        for seed in seeds:
            add('single',purpose,seed,1,80,seen_names[:3],seen_p[:3],[16,18,20],['shaped'])
    add('single','singlecarrier',8801,1,100,seen_names[:3],seen_p[:3],[16,18,20],['shaped'],True)

    def read(path):
        with path.open(encoding='utf-8-sig') as f:
            return list(csv.DictReader(f))

    pilot = read(args.pilot); calibration = read(args.calibration)
    comm = {kind:statistics.median(float(r['elapsed_seconds'])/int(r['frames'])
                                  for r in pilot if r['control']==kind) for kind in controls}
    raw = {kind:statistics.median(float(r['elapsed_seconds'])/int(r['frames'])
                                 for r in calibration if r['control']==kind) for kind in controls}
    prediction = statistics.median(float(r['online_seconds'])+float(r['offline_seconds']) for r in pilot)
    timing_rows = []
    for job in jobs:
        by_kind = {kind:0 for kind in job['controls']}
        for ps in job['strategy_p']:
            for i,kind in enumerate(job['controls']):
                if all(p==.5 for p in ps) and i>0:
                    continue
                by_kind[kind] += 1
        cells = job['num_channels']*len(job['snr_grid'])*sum(by_kind.values())
        frames = cells*job['num_frames']
        per_frame = raw if job['purpose'] in ('power_calibration','power_validation','pmf') else comm
        seconds = job['num_channels']*len(job['snr_grid'])*job['num_frames']*sum(
            count*per_frame[kind] for kind,count in by_kind.items())
        if job['n_sc']==1:
            seconds = frames*.08 # conservative measured single-carrier bridge estimate
        if job['predict']:
            seconds += cells*prediction*(1 if job['n_sc']==64 else 1/3)
        timing_rows.append(dict(job_id=job['job_id'],purpose=job['purpose'],lane='ofdm' if job['n_sc']==64 else 'single',
                                configurations=sum(by_kind.values()),channels=job['num_channels'],
                                snr_points=len(job['snr_grid']),frames_per_cell=job['num_frames'],
                                total_frames=frames,estimated_seconds=seconds))

    sources = []
    for directory in ['core','analysis','experiments/multicarrier','diagnostics/multicarrier']:
        sources.extend(p for p in (v2/directory).glob('*.m') if 'p2' in p.stem.lower())
    shared = ['setup_paths.m','core/ofdm_channel_roundtrip.m','polar/GA.m','polar/phi.m',
              'polar/phi_inverse.m','polar/derivative_phi.m','polar/get_GN.m',
              'polar/get_llr_layer.m','polar/get_bit_layer.m','polar/polar_encoder.m','polar/SC_decoder.m',
              'polar/build_source_entropy_partition.m','modulation/llr_16qam_gray_LSE.m',
              'modulation/parallel_to_serial_bits.m']
    sources.extend(v2/p for p in shared)
    sources.extend(root/'16QAM_Polar/v3'/p for p in ['polar/shape_stream_sc.m',
        'polar/sc_decode_forced_full.m','polar/build_stream_partition_source_mc_ga.m',
        'analysis/cluster_bootstrap_tv.m'])
    sources.extend([Path(__file__).resolve(),root/'scripts/audit_p2_materials.py'])
    template = v2/'results/20261010_220806_b4_equal_power_p1_formal/b4b_strict_ofdm_rayleigh.mat'
    protocol = dict(schema_version=1, status='UNAPPROVED_PROPOSAL',
        boundary='16QAM; fixed receiver; no 27-combination optimization or DC/USRP',
        templates=dict(path=template.relative_to(root).as_posix(),sha256=digest(template)),
        source_files=[dict(path=p.relative_to(root).as_posix(),sha256=digest(p)) for p in sorted(set(sources))],
        jobs=jobs, performance_gate=dict(median_BER_factor=2,p90_BER_factor=5,goodput_MAE=.02,
                                        online_speedup=10,min_errors=20,min_independent_channels=10),
        failure_policy='Stop dependent communication jobs if power/PMF fail. Larger calibration budgets require a new approval.')
    args.output.mkdir(parents=True,exist_ok=False)
    protocol_path=args.output/'protocol_proposal.json'
    protocol_path.write_text(json.dumps(protocol,ensure_ascii=False,indent=2),encoding='utf-8')
    (args.output/'approval_request.json').write_text(json.dumps(dict(approved=False,
        protocol_sha256=digest(protocol_path),reason='User requested explicit post-pilot budget confirmation'),indent=2),encoding='utf-8')
    with (args.output/'budget.csv').open('w',newline='',encoding='utf-8-sig') as f:
        w=csv.DictWriter(f,fieldnames=list(timing_rows[0])); w.writeheader(); w.writerows(timing_rows)
    base=sum(row['estimated_seconds'] for row in timing_rows)/3600
    summary=dict(approved=False,jobs=len(jobs),total_frames=sum(row['total_frames'] for row in timing_rows),
                 measured_comm_sec_per_frame=comm,measured_raw_sec_per_frame=raw,
                 point_estimate_hours=base,planning_range_hours=[base*1.2,base*1.6],
                 caveat='First 80-frame calibration attempt only; no guaranteed error counts or gate success; recalibration not auto-authorized')
    (args.output/'budget_summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    print(json.dumps(summary,indent=2))


if __name__=='__main__':
    main()
