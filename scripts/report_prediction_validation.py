"""Report fixed-gate independent predictor validation; never fits a model."""
import argparse
from pathlib import Path
import numpy as np
import pandas as pd


def evaluate(t):
    rows = []
    for split, g in t.groupby('split'):
        e = g[(g.errors >= 20) & g.ber.between(1e-4, .1)]
        factor = np.maximum(e.predicted/e.ber, e.ber/e.predicted)
        mae = np.mean(g.rate_cp*abs(g.predicted-g.ber))
        speed = np.sum(g.simulation_seconds/g.frames)/g.online_seconds.sum()
        sufficient = e.channel.nunique() >= 10
        # Match MATLAB prctile used by the original frozen acceptance gate.
        med, p90 = np.quantile(factor, [.5, .9], method='hazen') if len(e) else [np.nan, np.nan]
        rows.append(dict(split=int(split), cells=len(g), case_frames=int(g.frames.sum()),
                         channels=g.channel.nunique(), eligible_cells=len(e),
                         eligible_channels=e.channel.nunique(), errors=int(g.errors.sum()),
                         bits=int(g.bits.sum()), median_factor=med, p90_factor=p90,
                         goodput_mae=mae, online_speedup=speed,
                         simulation_seconds=g.simulation_seconds.sum(),
                         prediction_seconds=g.online_seconds.sum(),
                         pass_gate=bool(sufficient and med <= 2 and p90 <= 5 and
                                        mae <= .02 and speed >= 10)))
    return pd.DataFrame(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    t = pd.read_csv(args.directory/'validation.csv')
    assert np.isfinite(t[['ber', 'predicted', 'online_seconds', 'simulation_seconds']]).all().all()
    assert (t.online_seconds > 0).all() and (t.simulation_seconds > 0).all()
    assert np.allclose(t.ber, t.errors/t.bits, atol=1e-14)
    assert np.allclose(t.goodput_cp, t.rate_cp*(1-t.ber), atol=1e-14)
    report = evaluate(t)
    report.to_csv(args.directory/'independent_evaluation.csv', index=False)
    t['goodput_error'] = t.rate_cp*(t.ber-t.predicted)
    t['factor'] = np.maximum(t.predicted/np.maximum(t.ber, 1e-12), t.ber/t.predicted)
    t.to_csv(args.directory/'evaluation_cells.csv', index=False)
    by = t.groupby(['split', 'reference_db', 'control']).agg(
        mean_observed=('ber', 'mean'), mean_predicted=('predicted', 'mean'),
        mean_goodput_error=('goodput_error', 'mean'),
        errors=('errors', 'sum'), bits=('bits', 'sum'))
    by.to_csv(args.directory/'by_reference_and_control.csv')
    print(report.to_string(index=False))


if __name__ == '__main__':
    main()
