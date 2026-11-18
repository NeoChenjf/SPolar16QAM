"""Frozen descriptive post-analysis. No communication or model selection.

Usage: python analyze_certified_uncertainty.py RESULT_DIRECTORY
Requires numpy/scipy; fixed paired-frame bootstrap seed 2611181901.
Intervals are pointwise fixed-policy diagnostics, not simultaneous certificates.
"""
import argparse
import csv
import json
from pathlib import Path
import numpy as np
from scipy.io import loadmat


def write(path, rows):
    if not rows:
        return
    with path.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def analyze(out):
    out = Path(out)
    frozen = loadmat(out / 'frozen.mat', simplify_cells=True)
    p = frozen['protocol']
    rng = np.random.default_rng(2611181901)
    adjacent, summaries, near, selected, runtime = [], [], [], [], []
    cases = {}
    with (out / 'certified_cases.csv').open(encoding='utf-8') as f:
        for row in csv.DictReader(f):
            cases[(int(row['condition']), int(row['candidate']))] = row
    for file in sorted(out.glob('condition_*.mat')):
        a = loadmat(file, simplify_cells=True)
        ci, hi, li = int(a['ci']), int(a['hi']), int(a['li'])
        group = 'known_diagnostic' if hi == 5 else 'new_random'
        g = np.asarray(a['eval_G']); n, nc = g.shape
        assert nc == 125 and n == int(p['evaluation_frames'])
        assert np.isfinite(g).all() and (g >= 0).all()
        k = np.asarray(a['K']).reshape(1, -1)
        assert k.shape == (1, 125) and (g <= k / 15680 + 1e-14).all()
        mean = g.mean(axis=0)
        ix = rng.integers(n, size=(2000, n))
        weights = np.stack([np.bincount(x, minlength=n) / n for x in ix])
        bg = weights @ g
        assert (bg[:, 124] > 0).all(), 'Ratio diagnostic requires positive baseline'
        losses = 1 - bg / bg[:, [124]]
        loss_ci = np.quantile(losses, [.025, .975], axis=0)
        methods = a['methods']
        base = dict(condition=ci, H=hi, label=int(np.asarray(p['labels'])[li-1]), channel_role=group)
        for mi, method in enumerate(methods, 1):
            refinement = np.asarray(method['refinement'])
            runtime.append(dict(**base, method=mi, forecast_seconds=float(method['forecast_seconds']),
                                total_seconds=float(method['total_seconds']), catalog_seconds=float(method['catalog_seconds']),
                                refinement_rows=0 if refinement.size == 0 else int(refinement.reshape(-1, 5).shape[0])))
            if mi <= 2:
                score = np.asarray(method['score']).reshape(-1)
                assert score.shape == (125,) and np.isfinite(score).all()
                order = np.argsort(-score, kind='stable')
                predicted_delta = score[order[:-1]] - score[order[1:]]
                strict = predicted_delta > 0
                delta = bg[:, order[:-1]] - bg[:, order[1:]]
                bounds = np.quantile(delta, [.025, .975], axis=0)
                points = mean[order[:-1]] - mean[order[1:]]
                for j in range(124):
                    adjacent.append(dict(**base, method=mi, rank=j+1, first=int(order[j]+1), second=int(order[j+1]+1),
                                         predicted_delta=float(score[order[j]]-score[order[j+1]]), actual_delta=float(points[j]),
                                         CI_low=float(bounds[0,j]), CI_high=float(bounds[1,j]), point_reversal=int(points[j]<0 and strict[j]),
                                         predicted_exact_tie=int(not strict[j]),
                                         interval_crosses_zero=int(bounds[0,j]<=0<=bounds[1,j])))
                changed = 0
                if mi == 2:
                    raw = np.array([float(cases[(ci,c)]['raw_SC_goodput']) for c in range(1,126)])
                    pairs = np.triu_indices(125, 1)
                    changed = int(np.sum(np.sign((score[:,None]-score)[pairs]) != np.sign((raw[:,None]-raw)[pairs])))
                summaries.append(dict(**base, method=mi, adjacent_pairs=124, point_reversed=int(sum((points<0)&strict)),
                                      predicted_exact_ties=int(sum(~strict)),
                                      CI_cross_zero=int(sum((bounds[0]<=0)&(bounds[1]>=0))), supported_reverse=int(sum((bounds[1]<0)&strict)),
                                      supported_correct=int(sum((bounds[0]>0)&strict)), raw_ensemble_pair_changes=changed,
                                      refinement_performed=int(refinement.size>0)))
                # Simple score is not calibrated Goodput: proximity is rank-only.
                if mi == 2:
                    predloss=1-score/score[124]
                    for c in np.argsort(abs(predloss-.05), kind='stable')[:10]:
                        near.append(dict(**base, method=mi,candidate=int(c+1), predicted_loss=float(predloss[c]),
                                         actual_loss=float(1-mean[c]/mean[124]), loss_error=float(predloss[c]-(1-mean[c]/mean[124])),
                                         actual_CI_low=float(loss_ci[0,c]),actual_CI_high=float(loss_ci[1,c])))
            for snap in method['snapshots']:
                for axis, c0 in enumerate(np.asarray(snap['selected']).reshape(-1)):
                    c=int(c0)-1
                    energykey='RF_W' if axis==0 else 'proxy_A'
                    en=np.array([float(cases[(ci,j)][energykey]) for j in range(1,126)])
                    assert np.isfinite(en).all() and en[124] > 0
                    feasible=mean>=.95*mean[124]
                    oracle=float(en[feasible].max())
                    dominating=(mean>=mean[c])&(en>=en[c])&((mean>mean[c])|(en>en[c]))
                    selected.append(dict(**base,method=mi,budget=float(snap['budget']),axis=axis+1,candidate=c+1,
                                         actual_loss=float(1-mean[c]/mean[124]), energy_gain=float(en[c]/en[124]-1),
                                         selected_point_feasible=int(feasible[c]),
                                         point_feasible_oracle_energy_gap=float((oracle-en[c])/en[124]),
                                         point_front_dominator_count=int(sum(dominating)),
                                         point_front_goodput_gap_at_energy=float(mean[en>=en[c]].max()-mean[c])))
    for name, rows in [('adjacent_uncertainty',adjacent),('adjacent_summary',summaries),('near5_uncertainty',near),
                       ('selected_front_diagnostic',selected),('decision_runtime',runtime)]:
        write(out/(name+'.csv'),rows)
    if summaries:
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt
        fig, axes=plt.subplots(1,2,figsize=(11,4),constrained_layout=True)
        for ax, role in zip(axes,['new_random','known_diagnostic']):
            data=[r for r in summaries if r['channel_role']==role]
            for method, marker, label in [(1,'o','Simple'),(2,'s','Numerical SC')]:
                subset=[r for r in data if r['method']==method]
                ax.scatter([r['CI_cross_zero']/124 for r in subset],
                           [r['point_reversed']/124 for r in subset],marker=marker,label=label)
            ax.set(title=role.replace('_',' '),xlabel='Fraction adjacent CIs crossing zero',ylabel='Point reversal fraction')
            ax.legend();ax.grid(alpha=.3)
        fig.savefig(out/'adjacent_uncertainty.png',dpi=170);fig.savefig(out/'adjacent_uncertainty.pdf');plt.close(fig)
    (out/'uncertainty_analysis_metadata.json').write_text(json.dumps(dict(seed=2611181901,repeats=2000,
        complete_conditions=len(list(out.glob('condition_*.mat'))),near5_rule='10 nearest SC loss predictions',
        interval_role='pointwise descriptive paired independent evaluation; no simultaneous claim',
        simple_near5='not evaluated: simple score has no absolute Goodput scale',
        oracle_role='posthoc evaluation diagnostic only; never policy input; negative energy gap retained when selected point is infeasible',
        dependence='Adjacent pairs share candidates; counts are descriptive, not independent Bernoulli trials',
        independence='Evaluation separation is a runner/protocol property; MAT shapes cannot prove independence',
        ties='Exact predicted ties excluded from reversed/correct counts; all124 remain interval denominator'),indent=2),encoding='utf-8')


if __name__ == '__main__':
    parser=argparse.ArgumentParser();parser.add_argument('out');analyze(parser.parse_args().out)
