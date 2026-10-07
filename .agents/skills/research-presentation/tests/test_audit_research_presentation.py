from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "audit_research_presentation.py"
XML = '<a:r xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:t>{}</a:t></a:r>'


def write_pptx(path: Path, notes: list[str], with_workbook: bool = True) -> None:
    with zipfile.ZipFile(path, "w") as archive:
        for page, note in enumerate(notes, start=1):
            archive.writestr(f"ppt/slides/slide{page}.xml", XML.format(f"Slide {page}"))
            archive.writestr(f"ppt/notesSlides/notesSlide{page}.xml", XML.format(note))
        archive.writestr("ppt/slides/charts/chart1.xml", XML.format("chart"))
        if with_workbook:
            archive.writestr("ppt/embeddings/chart-data.xlsx", b"workbook")


def run_audit(pptx: Path, script: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCRIPT), str(pptx), str(script), "--json"],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


class AuditResearchPresentationTests(unittest.TestCase):
    def test_accepts_aligned_deck_notes_and_script(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pptx = root / "deck.pptx"
            script = root / "script.md"
            write_pptx(pptx, ["第一页讲稿。", "第二页讲稿。"])
            script.write_text(
                "## 正式讲稿\n\n### 第 1 页\n\n第一页讲稿。\n\n> 【切换至第 2 页】\n\n### 第 2 页\n\n第二页讲稿。\n",
                encoding="utf-8",
            )

            result = run_audit(pptx, script)
            report = json.loads(result.stdout)

            self.assertEqual(result.returncode, 0)
            self.assertEqual(report["failures"], [])
            self.assertEqual(report["pptx"]["chart_count"], 1)
            self.assertEqual(report["pptx"]["notes_script_mismatches"], [])

    def test_rejects_missing_switch_and_note_drift(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pptx = root / "deck.pptx"
            script = root / "script.md"
            write_pptx(pptx, ["第一页讲稿。", "旧的第二页讲稿。"])
            script.write_text(
                "## 正式讲稿\n\n### 第 1 页\n\n第一页讲稿。\n\n### 第 2 页\n\n新的第二页讲稿。\n",
                encoding="utf-8",
            )

            result = run_audit(pptx, script)
            report = json.loads(result.stdout)

            self.assertEqual(result.returncode, 1)
            self.assertTrue(any("switch-cue count" in item for item in report["failures"]))
            self.assertEqual(report["pptx"]["notes_script_mismatches"], [2])

    def test_warns_when_chart_has_no_embedded_workbook(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            pptx = root / "deck.pptx"
            script = root / "script.md"
            write_pptx(pptx, ["讲稿。"], with_workbook=False)
            script.write_text("## 正式讲稿\n\n### 第 1 页\n\n讲稿。\n", encoding="utf-8")

            result = run_audit(pptx, script)
            report = json.loads(result.stdout)

            self.assertEqual(result.returncode, 0)
            self.assertTrue(any("no embedded workbook" in item for item in report["warnings"]))


if __name__ == "__main__":
    unittest.main()
