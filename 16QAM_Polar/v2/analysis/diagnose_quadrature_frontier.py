"""Post-hoc local sensitivity; never replace the frozen independent forecast."""
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
    protocol = json.loads((out / "protocol.json").read_text(encoding="utf-8"))
    allocations = np.asarray(protocol["choices"], dtype=int)
    sensitivity = np.loadtxt(out / "numerical_sensitivity.csv", delimiter=",")
    cases = read_rows(out / "analysis_cases.csv")
    thresholds = read_rows(out / "analysis_choices.csv")
    pair_a, pair_b = np.triu_indices(125, 1)
    results = []
    for channel in (1, 8):
        for label in (16, 28):
            rows = sorted((r for r in cases if int(r["H"]) == channel and int(r["label"]) == label), key=lambda r: int(r["candidate"]))
            if len(rows) != 125:
                raise ValueError("Missing full candidate condition")
            frozen = np.array([float(r["sc_goodput"]) for r in rows])
            actual = np.array([float(r["goodput"]) for r in rows])
            energy = np.array([float(r["rf_W"]) for r in rows])
            altered = frozen.copy()
            for index in (1, 5):
                data = sensitivity[(sensitivity[:, 0] == channel) & (sensitivity[:, 1] == label) & (sensitivity[:, 3] == index)]
                if data.shape[0] != 1:
                    raise ValueError("Missing numerical diagnostic")
                uniform_candidate = 0 if index == 1 else 124
                group_bits = int(rows[uniform_candidate]["K"]) / 3
                altered[allocations[:, 2] == index] += group_bits * (data[0, 4] - data[0, 6]) / 15680
            before = np.sign(frozen[pair_a] - frozen[pair_b])
            after = np.sign(altered[pair_a] - altered[pair_b])
            truth = np.sign(actual[pair_a] - actual[pair_b])
            t = [r for r in thresholds if int(r["H"]) == channel and int(r["label"]) == label and int(r["energy_axis"]) == 1]
            old_losses, new_losses, changed = [], [], 0
            for threshold in t:
                eligible = np.flatnonzero(energy >= float(threshold["threshold"]))
                old_pick = eligible[np.argmax(frozen[eligible])]
                new_pick = eligible[np.argmax(altered[eligible])]
                best = np.max(actual[eligible])
                old_losses.append(best - actual[old_pick])
                new_losses.append(best - actual[new_pick])
                changed += int(old_pick != new_pick)
            results.append({"H": channel, "label": label, "changed_pair_relations": int(np.sum(before != after)),
                            "frozen_point_reversals": int(np.sum(before * truth < 0)),
                            "local_160_point_reversals": int(np.sum(after * truth < 0)),
                            "changed_selected_thresholds": changed, "thresholds": len(t),
                            "frozen_mean_loss": float(np.mean(old_losses)), "local_160_mean_loss": float(np.mean(new_losses)),
                            "interpretation": "post-hoc partial numerical sensitivity; not an independent replacement"})
    with (out / "quadrature_frontier_diagnostic.csv").open("w", encoding="utf-8", newline="") as target:
        writer = csv.DictWriter(target, fieldnames=list(results[0]))
        writer.writeheader()
        writer.writerows(results)
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main(sys.argv[1])
