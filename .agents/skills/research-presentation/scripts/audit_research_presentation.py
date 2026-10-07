#!/usr/bin/env python3
"""Audit structural alignment between a PPTX and a Markdown speaking script."""

from __future__ import annotations

import argparse
import json
import re
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
}
PLACEHOLDER_RE = re.compile(r"(?:\[object Object\]|lorem|ipsum|xxxx)", re.I)
PAGE_HEADING_RE = re.compile(r"^#{1,6}\s*第\s*(\d+)\s*页", re.M)
SWITCH_RE = re.compile(r"切换至第\s*(\d+)\s*页")


def natural_number(path: str) -> int:
    match = re.search(r"(\d+)", path)
    return int(match.group(1)) if match else 0


def xml_text(data: bytes) -> str:
    root = ET.fromstring(data)
    return "".join(node.text or "" for node in root.findall(".//a:t", NS)).strip()


def inspect_pptx(path: Path) -> dict:
    with zipfile.ZipFile(path) as archive:
        names = set(archive.namelist())
        slide_names = sorted(
            (n for n in names if re.fullmatch(r"ppt/slides/slide\d+\.xml", n)),
            key=natural_number,
        )
        note_names = sorted(
            (n for n in names if re.fullmatch(r"ppt/notesSlides/notesSlide\d+\.xml", n)),
            key=natural_number,
        )
        chart_names = [
            n
            for n in names
            if re.fullmatch(r"ppt/(?:slides/)?charts/chart\d+\.xml", n)
        ]
        workbook_names = [n for n in names if n.startswith("ppt/embeddings/")]
        slide_texts = [xml_text(archive.read(n)) for n in slide_names]
        note_texts = [xml_text(archive.read(n)) for n in note_names]
    return {
        "slide_count": len(slide_names),
        "notes_count": len(note_names),
        "chart_count": len(chart_names),
        "embedded_workbook_count": len(workbook_names),
        "empty_notes": [i + 1 for i, value in enumerate(note_texts) if not value],
        "placeholder_slides": [i + 1 for i, value in enumerate(slide_texts) if PLACEHOLDER_RE.search(value)],
        "placeholder_notes": [i + 1 for i, value in enumerate(note_texts) if PLACEHOLDER_RE.search(value)],
        "_note_texts": note_texts,
    }


def inspect_script(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    headings = [int(x) for x in PAGE_HEADING_RE.findall(text)]
    switches = [int(x) for x in SWITCH_RE.findall(text)]
    formal_match = re.search(r"^##\s*正式讲稿\s*$([\s\S]*?)(?=^##\s+|\Z)", text, flags=re.M)
    spoken = formal_match.group(1) if formal_match else text
    spoken = re.sub(r"^>.*$", "", spoken, flags=re.M)
    spoken = re.sub(r"^#{1,6}.*$", "", spoken, flags=re.M)
    spoken = re.sub(r"\[[^\]]*\]", "", spoken)
    spoken = re.sub(r"\s+", "", spoken)
    section_matches = list(
        re.finditer(
            r"^###\s*第\s*(\d+)\s*页[^\n]*\n([\s\S]*?)(?=^###\s*第\s*\d+\s*页|^##\s+|\Z)",
            text,
            flags=re.M,
        )
    )
    narrations = []
    for match in section_matches:
        body = re.sub(r"^>.*$", "", match.group(2), flags=re.M)
        body = re.sub(r"\s+", "", body)
        narrations.append({"page": int(match.group(1)), "text": body})
    return {
        "page_heading_count": len(headings),
        "page_headings": headings,
        "switch_count": len(switches),
        "switch_targets": switches,
        "spoken_character_count_estimate": len(spoken),
        "placeholder_found": bool(PLACEHOLDER_RE.search(text)),
        "_narrations": narrations,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pptx", type=Path)
    parser.add_argument("script", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    pptx = inspect_pptx(args.pptx)
    script = inspect_script(args.script)
    note_texts = pptx.pop("_note_texts")
    narrations = script.pop("_narrations")
    failures: list[str] = []
    warnings: list[str] = []

    if pptx["slide_count"] != script["page_heading_count"]:
        failures.append("slide count does not match Markdown page-heading count")
    if script["switch_count"] != max(pptx["slide_count"] - 1, 0):
        failures.append("switch-cue count must equal slide count minus one")
    if script["page_headings"] != list(range(1, pptx["slide_count"] + 1)):
        failures.append("Markdown page headings are not consecutive from 1")
    if script["switch_targets"] != list(range(2, pptx["slide_count"] + 1)):
        failures.append("Markdown switch targets are not consecutive from 2")
    if pptx["notes_count"] != pptx["slide_count"]:
        warnings.append("not every slide has a notes part")
    if pptx["empty_notes"]:
        warnings.append(f"empty speaker notes on slides {pptx['empty_notes']}")
    if pptx["placeholder_slides"] or pptx["placeholder_notes"] or script["placeholder_found"]:
        failures.append("placeholder or serialization artifact found")
    if pptx["chart_count"] and not pptx["embedded_workbook_count"]:
        warnings.append("native charts exist but no embedded workbook was found")
    mismatches = []
    for item in narrations:
        page = item["page"]
        note = re.sub(r"\s+", "", note_texts[page - 1]) if page <= len(note_texts) else ""
        if item["text"] and item["text"] not in note:
            mismatches.append(page)
    pptx["notes_script_mismatches"] = mismatches
    if mismatches:
        failures.append(f"speaker notes do not contain the Markdown narration on slides {mismatches}")

    report = {"pptx": pptx, "script": script, "failures": failures, "warnings": warnings}
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"slides={pptx['slide_count']} notes={pptx['notes_count']} charts={pptx['chart_count']}")
        print(f"script_pages={script['page_heading_count']} switches={script['switch_count']}")
        print(f"spoken_characters_estimate={script['spoken_character_count_estimate']}")
        for item in warnings:
            print(f"WARNING: {item}")
        for item in failures:
            print(f"FAIL: {item}")
        print("PASS" if not failures else "FAILED")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
