"""Summarize frozen-policy evaluation and development sensitivity, no frames.

Optional dependencies: numpy/scipy/matplotlib. Raw data remain in timestamped
results. This script never changes the decision rules or original MAT files.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path

import numpy as np
from scipy.io import loadmat
from scipy.special import logsumexp


def write_csv(path, rows):
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def summarize(out):
    os.environ.setdefault("MPLCONFIGDIR", str(out / "matplotlib_cache"))
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    dev = out / "development_numerics" / "convergence_rows.csv"
    if dev.exists():
        with dev.open(encoding="utf-8") as f:
            num = list(csv.DictReader(f))
        means = []
        fig, axes = plt.subplots(1, 2, figsize=(10, 4), sharey=True)
        for ax, p_index in zip(axes, (1, 5)):
            for B, style in ((8192, "o-"), (16384, "s--")):
                vals = []
                for order in (80, 160):
                    v = [float(r["BER"]) for r in num if int(r["p_index"]) == p_index and int(r["B"]) == B and int(r["order"]) == order]
                    if not v:
                        continue
                    means.append(dict(p_index=p_index, B=B, order=order, repeats=len(v), mean_BER=float(np.mean(v)), min_BER=min(v), max_BER=max(v)))
                    vals.append((order, np.mean(v), min(v), max(v)))
                if vals:
                    v = np.array(vals)
                    ax.errorbar(v[:, 0], 100*v[:, 1], yerr=100*np.array([v[:, 1]-v[:, 2], v[:, 3]-v[:, 1]]), fmt=style, capsize=4, label=f"B={B}")
            ax.set(title=f"Old H8 / label28 / weak group / p={p_index/10:.1f}", xlabel="Quadrature order", xticks=[80, 160])
            ax.grid(alpha=.25)
            ax.legend()
        axes[0].set_ylabel("Group BER (%); bars = 3-seed range, not CI")
        fig.tight_layout()
        fig.savefig(out / "development_convergence.png", dpi=170)
        fig.savefig(out / "development_convergence.pdf")
        plt.close(fig)
        write_csv(out / "development_convergence_summary.csv", means)

    choices_path = out / "certified_choices.csv"
    if not choices_path.exists():
        return
    with choices_path.open(encoding="utf-8") as f:
        data = [{k: float(v) for k, v in r.items()} for r in csv.DictReader(f)]
    rng = np.random.default_rng(2611180402)
    rows = []
    for method in (1, 2, 3):
        for budget in (60, 180, 600):
            for axis in (1, 2):
                d = [r for r in data if r["diagnostic"] == 0 and r["method"] == method and r["budget_s"] == budget and r["axis"] == axis]
                if not d:
                    continue
                key = "RF_gain" if axis == 1 else "proxy_gain"
                hs = sorted({r["H"] for r in d})
                cluster = np.array([np.mean([r[key] for r in d if r["H"] == h]) for h in hs])
                boot = cluster[rng.integers(len(hs), size=(10000, len(hs)))].mean(axis=1)
                lo, hi = np.quantile(boot, [.025, .975]) if len(hs) > 1 else (float('nan'), float('nan'))
                rows.append(dict(method=method, budget_s=budget, axis=axis, random_H=len(hs), conditions=len(d), mean_energy_gain=float(cluster.mean()), H_bootstrap_low=float(lo), H_bootstrap_high=float(hi), max_point_goodput_loss=max(r["loss"] for r in d), point_loss_over5=sum(r["loss"]>.05 for r in d), baseline_fallbacks=sum(r["baseline_fallback"] for r in d), mean_certified_nonbaseline=float(np.mean([r["certified_nonbaseline"] for r in d]))))
    write_csv(out / "certified_summary.csv", rows)
    differences = []
    for budget in (60, 180, 600):
        for axis in (1, 2):
            key = "RF_gain" if axis == 1 else "proxy_gain"
            for m1, m2 in ((2, 1), (2, 3), (1, 3)):
                a = {(r["H"], r["label"]): r[key] for r in data if r["diagnostic"] == 0 and r["budget_s"] == budget and r["axis"] == axis and r["method"] == m1}
                b = {(r["H"], r["label"]): r[key] for r in data if r["diagnostic"] == 0 and r["budget_s"] == budget and r["axis"] == axis and r["method"] == m2}
                keys = sorted(a.keys() & b.keys())
                if not keys:
                    continue
                hs = sorted({k[0] for k in keys})
                vals = np.array([np.mean([a[k]-b[k] for k in keys if k[0] == h]) for h in hs])
                boot = vals[rng.integers(len(hs), size=(10000, len(hs)))].mean(axis=1)
                lo, hi = np.quantile(boot, [.025, .975]) if len(hs) > 1 else (float('nan'), float('nan'))
                differences.append(dict(budget_s=budget, axis=axis, method_a=m1, method_b=m2, random_H=len(hs), mean_gain_difference=float(vals.mean()), H_bootstrap_low=float(lo), H_bootstrap_high=float(hi)))
    write_csv(out / "certified_method_differences.csv", differences)
    with (out / "certified_cases.csv").open(encoding="utf-8") as f:
        cases = [{k: float(v) for k, v in r.items()} for r in csv.DictReader(f)]
    # Oracle uses evaluation point estimates only, never feeds decisions.
    # Its feasible set/front membership are themselves statistically uncertain.
    frontier_rows = []
    for d in data:
        cs = [r for r in cases if r["condition"] == d["condition"]]
        key = "RF_W" if d["axis"] == 1 else "proxy_A"
        feasible = [r for r in cs if r["loss_vs_uniform"] <= .05]
        best_energy = max(r[key] for r in feasible)
        chosen = next(r for r in cs if r["candidate"] == d["candidate"])
        frontier_rows.append(dict(condition=int(d["condition"]), diagnostic=int(d["diagnostic"]), method=int(d["method"]), budget_s=d["budget_s"], axis=int(d["axis"]), point_feasible_candidates=len(feasible), point_oracle_energy=best_energy, selected_energy=chosen[key], relative_energy_shortfall=(best_energy-chosen[key])/best_energy, caveat="evaluation-point oracle; not certified optimum"))
    write_csv(out / "certified_point_oracle_gap.csv", frontier_rows)
    audit = []
    prefix_diagnostic = []
    for file in sorted(out.glob("condition_*.mat")):
        a = loadmat(file, simplify_cells=True)
        G = a["eval_G"]
        K = np.asarray(a["K"], dtype=np.int64)
        errors = K-G*15680
        assert G.shape == (100, 125)
        assert np.all(errors >= -1e-9) and np.all(errors <= K+1e-9)
        assert np.max(np.abs(errors-np.round(errors))) < 1e-8
        for mi, method in enumerate(a["methods"], 1):
            for snap in method["snapshots"]:
                certified = np.atleast_1d(snap["certified"]).astype(int)
                assert 125 in certified
                assert np.all(snap["bounds"][certified[certified != 125]-1, 0] >= 0)
                assert set(np.atleast_1d(snap["selected"]).astype(int)) <= set(certified)
            # Posthoc arithmetic diagnostic only, not a replayed controller:
            # identify evidence available in recorded prefixes that the
            # coarse fixed-look schedule did not publish immediately.
            for c, samples in enumerate(method["G"]):
                g = np.asarray(samples, dtype=float).reshape(-1)
                if c == 124 or not len(g):
                    continue
                z = g-.95*np.asarray(method["G0"], dtype=float)[:len(g)]
                f = np.array([.1, .25, .5, .9])
                positive = logsumexp(np.cumsum(np.log1p(z[:, None]*f/(.95*K[124]/15680)), axis=0), axis=1)-np.log(4)
                negative = logsumexp(np.cumsum(np.log1p(-z[:, None]*f/(K[c]/15680)), axis=0), axis=1)-np.log(4)
                threshold = np.log(124*3*2/.05)
                crossing = np.flatnonzero(np.maximum(positive, negative) >= threshold)
                nfirst = int(crossing[0]+1) if len(crossing) else 0
                event = (1 if positive[nfirst-1] >= threshold else -1) if nfirst else 0
                prefix_diagnostic.append(dict(condition=int(a["ci"]), method=mi, candidate=c+1, recorded_frames=len(g), first_anytime_evidence_frame=nfirst, evidence_direction=event, frozen_final_state=int(method["state"][c]), caveat="posthoc recorded-prefix diagnostic; no controller rerun or timing guarantee"))
        audit.append(dict(condition=int(a["ci"]), evaluation_case_frames=int(G.size), evaluation_information_bits=int(K.sum()*100), errors=int(np.round(errors).sum()), zero_error_candidates=int(np.sum(np.round(errors).sum(axis=0)==0))))
    actual = int(loadmat(out / "ledger.mat", simplify_cells=True)["actual"])
    write_csv(out / "certified_prefix_diagnostic.csv", prefix_diagnostic)
    finished = (out / "completed.mat").exists()
    if finished:
        assert int(loadmat(out / "completed.mat", simplify_cells=True)["actual"]) == actual
    # The resumed run charges 999 frames to bound unrecorded work before interruption.
    reserve = 999 if (out / "resume_accounting.mat").is_file() else 0
    result = dict(completed_conditions=len(audit), batch_finished=finished,
                  actual_case_frames=actual if finished and not reserve else None,
                  charged_case_frames=actual,
                  interruption_reserve_frames=reserve,
                  saved_case_frames_lower_bound=actual-reserve,
                  conservative_case_frames_upper_bound=actual if finished else actual+999,
                  evaluation=audit, independent_uncoded_symbols=0,
                  result_bytes=sum(p.stat().st_size for p in out.rglob("*") if p.is_file()),
                  caveat="Exact total only for completed batch; otherwise checkpoint bounds. Few-H intervals descriptive, no cross-H safety or zero-risk claim.")
    (out / "summary_audit.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    manifest = {str(p.relative_to(out)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(out.rglob("*")) if p.is_file() and p.suffix in (".mat", ".csv", ".json", ".png", ".pdf") and p.name != "artifact_manifest.json"}
    (out / "artifact_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("out", type=Path)
    summarize(parser.parse_args().out)
