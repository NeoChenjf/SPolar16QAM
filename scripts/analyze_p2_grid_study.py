"""Frozen-choice comparison; never select a policy on confirmation data."""
import argparse
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.io import loadmat


def paired_bands(g3, g5, b3, b5, e3, e5, replicates=20000):
    """Resample whole channels jointly for all demands and metrics."""
    arrays = [np.asarray(a, dtype=float) for a in (g3, g5, b3, b5, e3, e5)]
    assert len({a.shape for a in arrays}) == 1 and arrays[0].ndim == 2
    assert all(np.isfinite(a).all() for a in arrays) and (arrays[4] > 0).all()
    n = arrays[0].shape[0]
    means = [a.mean(axis=0) for a in arrays]
    center = np.concatenate(means[:4] + [(means[5] - means[4]) / means[4]])
    rng = np.random.default_rng(20261109)
    samples = []
    for start in range(0, replicates, 500):
        ix = rng.integers(0, n, size=(min(500, replicates-start), n))
        bs = [a[ix].mean(axis=1) for a in arrays]
        samples.append(np.concatenate(bs[:4] + [(bs[5]-bs[4])/bs[4]], axis=1))
    samples = np.concatenate(samples)
    se = samples.std(axis=0, ddof=1)
    varying = se > 1e-12
    z = np.zeros_like(samples)
    z[:, varying] = np.abs(samples[:, varying]-center[varying])/se[varying]
    critical = np.quantile(z.max(axis=1), .95)
    return center, center-critical*se, center+critical*se, critical


def summarize_candidates(table, beta2, beta4):
    table = table.copy()
    table['proxy'] = beta2*table.rx_envelope_m2_l4 + beta4*table.rx_envelope_m4_l4
    return table, table.groupby('case_id').agg(
        goodput=('goodput_cp', 'mean'), proxy=('proxy', 'mean'),
        ber=('ber', 'mean'), tx_power=('tx_power', 'mean'),
        rx_rf=('rx_rf', 'mean'), rate_cp=('rate_cp', 'mean'))


def analyze(study):
    study = Path(study)
    complete = loadmat(study/'data_complete.mat', simplify_cells=True)
    frozen = loadmat(study/'frozen_policy.mat', simplify_cells=True)
    choices = pd.read_csv(study/'frozen_choices.csv')
    protocol = json.loads((study/'inference_protocol.json').read_text())
    dev, ds = summarize_candidates(pd.read_csv(study/'development_candidates.csv'), frozen['beta2'], frozen['beta4'])
    test, ts = summarize_candidates(pd.read_csv(Path(complete['test_dir'])/'repetitions.csv'), frozen['beta2'], frozen['beta4'])
    assert len(dev) == len(test) == 2500
    assert test.groupby('case_id').channel.nunique().eq(20).all()
    assert not test.duplicated(['channel','case_id']).any()
    assert test.frames.eq(40).all() and test.communication_measured.eq(1).all()
    assert np.allclose(test.goodput_cp, test.rate_cp*(1-test.ber))
    assert np.allclose(test.ber, test.error_count/test.info_bits)
    assert np.all(test.goodput_cp <= test.rate_cp+1e-12)
    # Verify frozen selection against development only.
    for row in choices.itertuples():
        for column, subset in [('selected3', ds[ds.index.str.startswith('combo_')]), ('selected5', ds)]:
            eligible = subset[(subset.goodput>=row.requirements) & (subset.ber<=.2)]
            expected = eligible.sort_values(['proxy','goodput','ber'], ascending=[False,False,True]).index[0]
            assert getattr(row, column) == expected
    arrays = []
    for metric in ['goodput_cp', 'ber', 'proxy']:
        pivot = test.pivot(index='channel', columns='case_id', values=metric).sort_index()
        arrays.extend([pivot[choices.selected3].to_numpy(), pivot[choices.selected5].to_numpy()])
    center, low, high, critical = paired_bands(*arrays)
    result = choices.copy()
    design = loadmat(study/'protocol.mat', simplify_cells=True)
    p_by_id = {str(name)+'_shaped': p for name,p in zip(design['names'], design['P'])}
    for level, column in [('3', 'selected3'), ('5', 'selected5')]:
        for group, label in enumerate(['good','middle','bad']):
            result['p'+level+'_'+label] = [p_by_id[c][group] for c in result[column]]
        for metric in ['proxy','tx_power','rx_rf','rate_cp']:
            result[metric+level] = ts.loc[result[column],metric].to_numpy()
    m = len(choices)
    for j, name in enumerate(['g3','g5','ber3','ber5','relative_proxy_gain']):
        result[name] = center[j*m:(j+1)*m]
        result[name+'_low'] = low[j*m:(j+1)*m]
        result[name+'_high'] = high[j*m:(j+1)*m]
    result['three_feasible'] = (result.g3_low>=result.requirements) & (result.ber3_high<=.2)
    result['five_feasible'] = (result.g5_low>=result.requirements) & (result.ber5_high<=.2)
    result['five_worth_adding'] = result.three_feasible & result.five_feasible & (result.relative_proxy_gain_low>.05)
    result['three_sufficient_here'] = result.three_feasible & result.five_feasible & (result.relative_proxy_gain_high<=.05)
    result['tx_power_gain'] = result.tx_power5/result.tx_power3-1
    result['rx_rf_gain'] = result.rx_rf5/result.rx_rf3-1
    result.to_csv(study/'confirmation_comparison.csv', index=False)
    ds.to_csv(study/'development_summary.csv'); ts.to_csv(study/'confirmation_summary.csv')
    if result.five_worth_adding.any():
        verdict = 'five_levels_have_practical_gain_at_some_frozen_demands'
    elif result.three_sufficient_here.all():
        verdict = 'three_levels_sufficient_on_frozen_demand_grid'
    else:
        verdict = 'inconclusive_or_demand_specific'
    summary = dict(verdict=verdict, channels=20, demands=m, critical=float(critical),
        worth_adding_demands=result.loc[result.five_worth_adding,'requirements'].tolist(),
        three_sufficient_demands=result.loc[result.three_sufficient_here,'requirements'].tolist(),
        new_case_frames=78400+100000+125, protocol=protocol,
        limits=['20 channels; bootstrap intervals approximate', 'fixed amplitude and true-H sorted groups',
                'finite five-level comparator, not continuous optimum', 'mathematical proxy, not DC or efficiency',
                'mean requirements, no per-channel service guarantee'])
    (study/'analysis_summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    fig, ax = plt.subplots(1,2, figsize=(12,4.5))
    for table, label in [(ds,'Development'),(ts,'Independent confirmation')]:
        a=ax[0 if label=='Development' else 1]
        coarse=table.index.str.startswith('combo_')
        a.scatter(table.goodput, table.proxy*1e6, s=15, label='Five-level candidates')
        a.scatter(table.loc[coarse,'goodput'], table.loc[coarse,'proxy']*1e6, s=40, facecolors='none', edgecolors='black', label='Original three levels')
        a.set(xlabel='Mean Goodput including CP', ylabel='Current proxy (uA)', title=label)
        a.grid(alpha=.25); a.legend()
    fig.tight_layout(); fig.savefig(study/'grid_tradeoffs.png', dpi=180); fig.savefig(study/'grid_tradeoffs.pdf'); plt.close(fig)
    fig, ax=plt.subplots(1,2, figsize=(12,4.5))
    q=result.requirements.to_numpy()
    ax[0].plot(q,result.relative_proxy_gain*100,'o-')
    ax[0].fill_between(q,result.relative_proxy_gain_low.to_numpy()*100,result.relative_proxy_gain_high.to_numpy()*100,alpha=.2)
    ax[0].axhline(5,color='red',linestyle='--'); ax[0].set(xlabel='Required mean Goodput',ylabel='Five vs three proxy gain (%)',title='Frozen choices; simultaneous paired bands')
    for name in ['g3','g5']:
        ax[1].plot(q,result[name],label=name)
        ax[1].fill_between(q,result[name+'_low'].to_numpy(),result[name+'_high'].to_numpy(),alpha=.15)
    ax[1].plot(q,q,'k--',label='Requirement'); ax[1].set(xlabel='Required mean Goodput',ylabel='Confirmation mean Goodput'); ax[1].legend()
    for a in ax:a.grid(alpha=.25)
    fig.tight_layout(); fig.savefig(study/'requirement_comparison.png',dpi=180); fig.savefig(study/'requirement_comparison.pdf'); plt.close(fig)
    print(json.dumps({k:v for k,v in summary.items() if k!='protocol'},indent=2))


if __name__ == '__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('study'); args=parser.parse_args()
    analyze(args.study)
