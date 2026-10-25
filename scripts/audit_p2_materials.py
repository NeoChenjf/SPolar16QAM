"""Read every learning Markdown and register P2 impact without rewriting history."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path


def audit(root: Path) -> list[dict]:
    records = []
    for path in sorted((root / "学习文档").rglob("*.md")):
        content = path.read_text(encoding="utf-8-sig")
        rel = path.relative_to(root).as_posix()
        if "通用GrayQAM" in rel:
            status = "supporting_only"
            reason = "Multi-QAM transferability; retain evidence, no OFDM/Goodput expansion"
        elif "shaped_polar" in rel:
            status = "mechanism_retained"
            reason = "Construction/PMF remain evidence; correctness does not imply equal-power advantage"
        elif any(term in content for term in ("能量", "Goodput", "等功率", "码本", "RF")):
            status = "append_scope_correction"
            reason = "Differentiate fixed-amplitude history, completed P1, and pending P2 mechanism evidence"
        else:
            status = "retained_no_material_change"
            reason = "No power/performance claim requiring this round's revision"
        figures = re.findall(r"!\[[^\]]*\]\(([^)]+)\)", content)
        records.append({
            "path": rel,
            "sha256_before": hashlib.sha256(path.read_bytes()).hexdigest(),
            "status": status,
            "reason": reason,
            "figure_references": figures,
            "current_figure_audit": "pending_semantic_review" if figures else "none",
        })
    return records


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = args.project_root.resolve()
    records = audit(root)
    args.output.mkdir(parents=True, exist_ok=False)
    (args.output / "material_impact.json").write_text(
        json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    with (args.output / "material_impact.csv").open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=["path", "sha256_before", "status", "reason", "figure_count"])
        writer.writeheader()
        for row in records:
            writer.writerow({k: row[k] for k in writer.fieldnames if k != "figure_count"}
                            | {"figure_count": len(row["figure_references"])})
    print(f"Read {len(records)} learning documents; individual records written to {args.output}")


if __name__ == "__main__":
    main()
