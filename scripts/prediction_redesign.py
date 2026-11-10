"""Channel-held-out development comparison on saved E1 group observations."""
import argparse
import json
from pathlib import Path
from time import perf_counter
from datetime import datetime
import shutil

import numpy as np
import pandas as pd


def features(t, kind):
    if kind != 'cheap':
        q = np.log(np.clip(t.q.to_numpy(), 1e-12, 1-1e-12) /
                   (1-np.clip(t.q.to_numpy(), 1e-12, 1-1e-12)))
    if kind == 'shared_q':
        return q[:, None]
    condition = np.column_stack([t.p, t.K / 4096, t.S_count / 4096,
                                 t.control.eq('random_s'), t.control.eq('donor_s')])
    if kind == 'conditional_q':
        return np.column_stack([q, condition])
    # Equalized noise includes the physical noise scale and current channel.
    # No group index, reference label, observed errors or test-derived features.
    s = np.log(t.sigma_mean.to_numpy())
    cheap = np.column_stack([s, s*s, t.gain_log_mean,
                            np.log(np.maximum(t.gain_min, 1e-12)), condition])
    if kind == 'cheap':
        return cheap
    return np.column_stack([q, cheap])


def fit(t, kind, ridge):
    x = features(t, kind)
    mean, scale = x.mean(0), x.std(0)
    scale[scale < 1e-10] = 1
    z = np.column_stack([np.ones(len(t)), (x-mean)/scale])
    y = (t.errors.to_numpy()+.5)/(t.bits.to_numpy()+1)
    penalty = np.eye(z.shape[1])*ridge
    penalty[0, 0] = 0
    coef = np.zeros(z.shape[1])
    coef[0] = np.log(y.mean()/(1-y.mean()))
    def loss(c):
        v = z@c
        return np.mean(np.logaddexp(0, v)-y*v) + .5*c@penalty@c/len(y)
    for _ in range(80):
        p = 1/(1+np.exp(-np.clip(z@coef, -40, 40)))
        w = np.maximum(p*(1-p), 1e-8)
        step = np.linalg.solve(z.T@(w[:, None]*z)+penalty+np.eye(z.shape[1])*1e-9,
                               z.T@(p-y)+penalty@coef)
        old = loss(coef)
        fraction = 1.
        while fraction > 1e-7:
            candidate = coef-fraction*step
            if kind != 'cheap':
                candidate[1] = max(0., candidate[1])
            if loss(candidate) <= old:
                break
            fraction *= .5
        if fraction <= 1e-7:
            break
        delta = np.max(abs(candidate-coef))
        coef = candidate
        if delta < 1e-7:
            break
    return dict(kind=kind, ridge=ridge, mean=mean.tolist(), scale=scale.tolist(),
                coefficients=coef.tolist())


def predict(t, model):
    x = features(t, model['kind'])
    z = np.column_stack([np.ones(len(t)),
                         (x-np.array(model['mean']))/np.array(model['scale'])])
    return 1/(1+np.exp(-np.clip(z@np.array(model['coefficients']), -40, 40)))


def totals(t, p):
    d = t.assign(predicted_errors=p*t.bits)
    g = d.groupby(['split', 'channel', 'reference_db', 'case_id'], sort=False)
    a = g[['errors', 'bits', 'predicted_errors']].sum()
    a['observed'] = a.errors/a.bits
    a['predicted'] = a.predicted_errors/a.bits
    a['rate'] = g.rate_cp.first()
    return a.reset_index()


def metrics(a):
    eligible = (a.errors >= 20) & a.observed.between(1e-4, .1)
    e = a[eligible]
    factor = np.maximum(e.predicted/e.observed,
                        e.observed/np.maximum(e.predicted, 1e-12))
    return dict(cells=len(a), eligible=int(eligible.sum()),
                median_factor=float(np.median(factor)),
                p90_factor=float(np.quantile(factor, .9)),
                goodput_mae=float(np.mean(a.rate*abs(a.predicted-a.observed))))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    t = pd.read_csv(args.directory/'group_development.csv')
    source = args.directory
    args.directory = source.parent / (datetime.now().strftime('%Y%m%d_%H%M%S') + '_prediction_group_loss_development')
    args.directory.mkdir(exist_ok=False)
    shutil.copy2(__file__, args.directory/'prediction_redesign_source.py')
    (args.directory/'README.txt').write_text(
        'Development only, no new simulation. Source: '+str(source)+
        '\nRegularization selected by channel-held-out group cross entropy. '
        'Selected OOF metrics are tuning evidence, not unbiased nested validation. '
        'Observed seen/unseen are development evidence. Timings exclude feature provenance.\n')
    train = t[t.split.eq(1)].copy()
    reports, models, prediction_tables = [], {}, []
    kinds = ['shared_q', 'conditional_q', 'cheap', 'hybrid']
    for kind in kinds:
        choices = []
        for ridge in [.1, 1., 10., 100.]:
            oof = np.empty(len(train))
            for channel in sorted(train.channel.unique()):
                hold = train.channel.eq(channel).to_numpy()
                model = fit(train.loc[~hold], kind, ridge)
                oof[hold] = predict(train.loc[hold], model)
            score = metrics(totals(train, oof))
            response = (train.errors.to_numpy()+.5)/(train.bits.to_numpy()+1)
            prob = np.clip(oof, 1e-12, 1-1e-12)
            group_loss = -np.mean(response*np.log(prob)+(1-response)*np.log1p(-prob))
            choices.append((group_loss, ridge, oof, score))
        _, ridge, oof, score = min(choices, key=lambda x: x[0])
        reports.append(dict(model=kind, evaluation='calibration_channel_oof', **score))
        model = fit(train, kind, ridge)
        models[kind] = model
        p = predict(t, model)
        table = totals(t, p)
        table['model'] = kind
        prediction_tables.append(table)
        for split in [2, 3]:
            reports.append(dict(model=kind, evaluation=f'observed_development_{split}',
                                **metrics(table[table.split.eq(split)])))
        # End-to-end feature assembly + model inference, across 180 groups.
        sample = t[t.split.eq(2)].copy()
        samples = []
        for _ in range(30):
            start = perf_counter()
            predict(sample, model)
            samples.append((perf_counter()-start)/(len(sample)/3))
        model['batch_amortized_seconds_per_cell'] = float(np.median(samples))
        t[f'prediction_{kind}'] = p
    pd.DataFrame(reports).to_csv(args.directory/'development_metrics.csv', index=False)
    pd.concat(prediction_tables).to_csv(args.directory/'total_predictions.csv', index=False)
    t.to_csv(args.directory/'group_predictions.csv', index=False)
    (args.directory/'development_models.json').write_text(json.dumps(models, indent=2))
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="660" viewBox="0 0 1280 660"><rect width="1280" height="660" fill="white"/>']
    for col, kind in enumerate(kinds):
        for row, split in enumerate([2, 3]):
            a = prediction_tables[col]
            a = a[a.split.eq(split)]
            x0, y0 = 45+col*320, 45+row*330
            svg.append(f'<g transform="translate({x0},{y0})"><text y="-15" font-size="14">{kind}: development split {split}</text><path d="M0 0 V240 H240" fill="none" stroke="black"/><path d="M0 240 L240 0" stroke="gray" stroke-dasharray="5 5"/>')
            for x, y in zip(a.observed, a.predicted):
                svg.append(f'<circle cx="{1200*x:.3f}" cy="{240-1200*y:.3f}" r="2" fill="#126b9a" opacity=".65"/>')
            svg.append('<text x="75" y="265" font-size="12">Observed BER [0, .2]</text><text x="0" y="285" font-size="12">Vertical: predicted BER [0, .2]</text></g>')
    svg.append('</svg>')
    (args.directory/'development_prediction.svg').write_text(''.join(svg))
    print(pd.DataFrame(reports).to_string(index=False))
    print('OUTPUT_DIRECTORY='+str(args.directory))


if __name__ == '__main__':
    main()
