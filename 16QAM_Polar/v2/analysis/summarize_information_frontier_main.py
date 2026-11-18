"""Channel-cluster summaries for the frozen finite-candidate experiment."""
import csv
import json
import sys
from pathlib import Path

import numpy as np


def read_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        return list(csv.DictReader(source))


def main(out):
    out = Path(out)
    rankings = read_rows(out / "analysis_rankings.csv")
    frontiers = read_rows(out / "analysis_frontiers.csv")
    cases = read_rows(out / "analysis_cases.csv")
    choices = read_rows(out / "analysis_choices.csv")
    expected = {(h, label) for h in range(1, 9) for label in (16, 20, 24, 28)}
    found = {(int(row["H"]), int(row["label"])) for row in rankings}
    if not expected.issubset(found):
        raise ValueError("Random-channel study is incomplete")

    generator = np.random.default_rng(2611121504)
    indices = generator.integers(0, 8, size=(10000, 8))

    def clustered(values):
        values = np.asarray(values, dtype=float)
        return {"mean": float(values.mean()),
                "channel_bootstrap_95": np.quantile(values[indices].mean(axis=1), [0.025, 0.975]).tolist()}

    result = {"random_channels": 8, "labels_per_channel": 4,
              "bootstrap_seed": 2611121504, "bootstrap_replicates": 10000,
              "uncertainty_unit": "whole channel, retaining all four noise conditions",
              "energy_note": "shared empirical noise-free waveform moments; not independent energy-model validation"}
    for method in (1, 2):
        rows = [r for r in rankings if int(r["H"]) <= 8 and int(r["method"]) == method]
        rank_h = [np.mean([int(r["disagree"]) / 7750 for r in rows if int(r["H"]) == h]) for h in range(1, 9)]
        resolved_h = [np.mean([int(r["resolved_disagree"]) / 7750 for r in rows if int(r["H"]) == h]) for h in range(1, 9)]
        result[f"method_{method}_point_reversal_fraction"] = clustered(rank_h)
        result[f"method_{method}_resolved_reversal_fraction"] = clustered(resolved_h)
        for axis in (1, 2, 3, 4):
            f = [r for r in frontiers if int(r["H"]) <= 8 and int(r["method"]) == method and int(r["energy_axis"]) == axis]
            loss_h = [np.mean([float(r["mean_regret"]) for r in f if int(r["H"]) == h]) for h in range(1, 9)]
            overlap_h = [np.mean([int(r["overlap_n"]) / int(r["actual_front_n"]) for r in f if int(r["H"]) == h]) for h in range(1, 9)]
            result[f"method_{method}_axis_{axis}_mean_loss"] = clustered(loss_h)
            result[f"method_{method}_axis_{axis}_front_recall"] = clustered(overlap_h)
            result[f"method_{method}_axis_{axis}_max_empirical_loss"] = max(float(r["max_regret"]) for r in f)

    random_cases = [r for r in cases if int(r["H"]) <= 8]
    result["candidate_cases"] = len(random_cases)
    result["waterfall_cases"] = sum(1e-4 <= float(r["BER"]) <= 1e-1 for r in random_cases)
    result["zero_error_cases"] = sum(int(r["errors"]) == 0 for r in random_cases)
    result["bits"] = sum(int(r["bits"]) for r in random_cases)
    result["errors"] = sum(int(r["errors"]) for r in random_cases)
    for axis in (1, 2):
        f = [r for r in frontiers if int(r["H"]) <= 8 and int(r["energy_axis"]) == axis]
        by_case = {(int(r["H"]), int(r["label"]), int(r["method"])): float(r["mean_regret"]) for r in f}
        result[f"axis_{axis}_SC_worse_conditions"] = sum(by_case[h, label, 2] > by_case[h, label, 1] + 1e-12 for h, label in expected)
        difference = [np.mean([by_case[h, label, 1] - by_case[h, label, 2] for label in (16, 20, 24, 28)]) for h in range(1, 9)]
        result[f"axis_{axis}_paired_mean_loss_reduction_SC"] = clustered(difference)
    rank_by_case = {(int(r["H"]), int(r["label"]), int(r["method"])): int(r["disagree"]) / 7750 for r in rankings if int(r["H"]) <= 8}
    rank_difference = [np.mean([rank_by_case[h, label, 1] - rank_by_case[h, label, 2] for label in (16, 20, 24, 28)]) for h in range(1, 9)]
    result["paired_point_reversal_reduction_SC"] = clustered(rank_difference)
    worst = max((r for r in choices if int(r["H"]) <= 8 and int(r["energy_axis"]) == 1), key=lambda r: float(r["sc_low"]))
    result["largest_conditional_SC_lower_bound_example"] = worst
    result["L4_L8_relative_max_condition_mean"] = max(float(r["L4_L8_m4_relative"]) for r in frontiers if int(r["H"]) <= 8)
    (out / "random_channel_summary.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main(sys.argv[1])
