#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
rks_evaluate.py — Research Knowledge Score（科研完备度评分）

对标 hic-spec 的 kcs_evaluate.py，把"知识完备度"评分从业务代码场景迁移到科研项目场景。
纯 Python 标准库实现，无第三方依赖，可在本地 Mac 直接运行。

五维评分（加权总分，默认阈值 75）：
  1. method_coverage     (0.30) — L3 方法覆盖率：已建契约的 .m 函数 / 全部 .m 函数
  2. flow_coverage       (0.20) — L2 流程覆盖率：已建流程的 run_* 入口 / 全部 run_* 入口
  3. hypothesis_coverage (0.20) — L1 假设覆盖率：被某个 L2 validates 引用的假设比例
  4. cross_layer_integrity (0.15) — 跨层引用完整性：L2 的 l3_ref / validates 是否都能解析
  5. theory_guardrail    (0.15) — 理论护栏遵守率：含 pitfalls 的 L1 是否在关联 L2 的 acceptance 留痕

用法：
  python3 rks_evaluate.py --project-root /path/to/SPolar16QAM \
      --append-ledger --system-id spolar16qam
"""

import argparse
import os
import re
import sys
import datetime

KNOWLEDGE_REL = os.path.join("workbook", "knowledge")
CODE_REL = os.path.join("16QAM_Polar", "v2")

WEIGHTS = {
    "method_coverage": 0.30,
    "flow_coverage": 0.20,
    "hypothesis_coverage": 0.20,
    "cross_layer_integrity": 0.15,
    "theory_guardrail": 0.15,
}
THRESHOLD = 75.0

# v2 代码中应被 L3 覆盖的模块目录
L3_MODULES = ["core", "polar", "modulation", "analysis"]


def read_text(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


def list_m_functions(code_root):
    """枚举 v2 各模块下的 .m 文件（函数名 = 文件名 stem）。"""
    funcs = []
    for mod in L3_MODULES:
        d = os.path.join(code_root, mod)
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if name.endswith(".m"):
                funcs.append((mod, name[:-2]))  # (module, func_stem)
    return funcs


def list_run_entries(code_root):
    """枚举顶层 run_*.m 入口 + 已知的 experiments 入口。"""
    entries = []
    for name in sorted(os.listdir(code_root)):
        if name.startswith("run_") and name.endswith(".m"):
            entries.append(name[:-2])
    # 已纳入 L2 的 experiments 入口（手工登记，避免把所有实验脚本都算进分母）
    extra = [
        os.path.join("experiments", "sc_checks", "run_find_waterfall_and_refine"),
        os.path.join("experiments", "multicarrier", "run_ofdm_baseline"),
    ]
    for e in extra:
        if os.path.isfile(os.path.join(code_root, e + ".m")):
            entries.append(os.path.basename(e))
    return entries


def collect_layer_files(kb_root, layer):
    """收集某层所有 md 文件路径（L3 递归子目录）。"""
    base = os.path.join(kb_root, layer)
    out = []
    if not os.path.isdir(base):
        return out
    for dirpath, _, filenames in os.walk(base):
        for fn in filenames:
            if fn.endswith(".md"):
                out.append(os.path.join(dirpath, fn))
    return out


def parse_field_ids(text, pattern):
    return set(re.findall(pattern, text))


def score_method_coverage(kb_root, code_root):
    funcs = list_m_functions(code_root)
    total = len(funcs)
    if total == 0:
        return 100.0, "无 .m 函数，跳过", 0, 0
    l3_files = collect_layer_files(kb_root, "L3")
    have = set()
    for fp in l3_files:
        stem = os.path.basename(fp)
        if stem.startswith("l3_") and stem.endswith(".md"):
            have.add(stem[3:-3])  # method func stem
    covered = sum(1 for (_mod, fn) in funcs if fn in have)
    pct = 100.0 * covered / total
    return pct, "L3 契约 %d / .m 函数 %d" % (covered, total), covered, total


def score_flow_coverage(kb_root, code_root):
    entries = list_run_entries(code_root)
    total = len(entries)
    if total == 0:
        return 100.0, "无 run_* 入口", 0, 0
    l2_files = collect_layer_files(kb_root, "L2")
    l2_text = "\n".join(read_text(fp) for fp in l2_files)
    covered = sum(1 for e in entries if e in l2_text)
    pct = 100.0 * covered / total
    return pct, "L2 流程引用入口 %d / run_* 入口 %d" % (covered, total), covered, total


def score_hypothesis_coverage(kb_root):
    l1_files = collect_layer_files(kb_root, "L1")
    l2_files = collect_layer_files(kb_root, "L2")
    l2_text = "\n".join(read_text(fp) for fp in l2_files)
    # L1 里的假设标识：domain_id + #Hn
    total_h, covered_h = 0, 0
    for fp in l1_files:
        txt = read_text(fp)
        m = re.search(r"domain_id\**:\s*(l1_\w+)", txt)
        if not m:
            continue
        did = m.group(1)
        hs = set(re.findall(r"\b(H\d+)\s*:", txt))
        for h in hs:
            total_h += 1
            ref = "%s#%s" % (did, h)
            if ref in l2_text:
                covered_h += 1
    if total_h == 0:
        return 100.0, "无假设声明", 0, 0
    pct = 100.0 * covered_h / total_h
    return pct, "被 L2 validates 引用的假设 %d / %d" % (covered_h, total_h), covered_h, total_h


def score_cross_layer_integrity(kb_root):
    """L2 中引用的 l3_ref 与 validates 的 l1 domain 是否都能解析到文件。"""
    l3_ids = set()
    for fp in collect_layer_files(kb_root, "L3"):
        stem = os.path.basename(fp)
        if stem.startswith("l3_") and stem.endswith(".md"):
            l3_ids.add(stem[:-3])
    l1_ids = set()
    for fp in collect_layer_files(kb_root, "L1"):
        txt = read_text(fp)
        m = re.search(r"domain_id\**:\s*(l1_\w+)", txt)
        if m:
            l1_ids.add(m.group(1))

    # 保留词：schema/说明里出现的字面占位词，不计入引用
    RESERVED = {"l3_ref", "l3_xxx", "l3_yyy", "l3_bbb", "l1_xxx", "l1_zzz", "l1_domain"}

    total_refs, ok_refs = 0, 0
    broken = []
    for fp in collect_layer_files(kb_root, "L2"):
        txt = read_text(fp)
        for ref in re.findall(r"\b(l3_\w+)", txt):
            if ref in RESERVED:
                continue
            total_refs += 1
            if ref in l3_ids:
                ok_refs += 1
            else:
                broken.append((os.path.basename(fp), ref))
        for ref in re.findall(r"\b(l1_\w+)#", txt):
            if ref in RESERVED:
                continue
            total_refs += 1
            if ref in l1_ids:
                ok_refs += 1
            else:
                broken.append((os.path.basename(fp), ref))
    if total_refs == 0:
        return 100.0, "L2 无跨层引用", []
    pct = 100.0 * ok_refs / total_refs
    return pct, "跨层引用可解析 %d / %d" % (ok_refs, total_refs), broken


def score_theory_guardrail(kb_root):
    """含 pitfalls(⚠️) 的 L1，其关联 L2 的 acceptance 是否含护栏关键词留痕。"""
    guard_kw = ["瀑布", "码率上界", "needs_user_run", "基线", "口径", "护栏", "pitfalls"]
    l2_text = "\n".join(read_text(fp) for fp in collect_layer_files(kb_root, "L2"))
    l1_files = collect_layer_files(kb_root, "L1")
    total, ok = 0, 0
    for fp in l1_files:
        txt = read_text(fp)
        if "⚠️" not in txt:
            continue
        total += 1
        # 该 L1 至少有一条护栏关键词在 L2 集合中被呼应
        if any(kw in l2_text for kw in guard_kw):
            ok += 1
    if total == 0:
        return 100.0, "无含护栏的 L1", 0, 0
    pct = 100.0 * ok / total
    return pct, "护栏在 L2 acceptance 留痕 %d / %d" % (ok, total), ok, total


def main():
    ap = argparse.ArgumentParser(description="Research Knowledge Score 评分")
    ap.add_argument("--project-root", required=True)
    ap.add_argument("--system-id", default="spolar16qam")
    ap.add_argument("--append-ledger", action="store_true")
    ap.add_argument("--write-report", action="store_true",
                    help="把报告写入 workbook/knowledge/reports/")
    ap.add_argument("--now", default="",
                    help="时间戳（YYYYMMDD_HHMMSS）；不传则用当前本地时间")
    args = ap.parse_args()

    root = os.path.abspath(args.project_root)
    kb = os.path.join(root, KNOWLEDGE_REL)
    code = os.path.join(root, CODE_REL)

    if not os.path.isdir(kb):
        print("ERROR: 未找到知识库目录 %s" % kb, file=sys.stderr)
        return 2

    mc, mc_d, _, _ = score_method_coverage(kb, code)
    fc, fc_d, _, _ = score_flow_coverage(kb, code)
    hc, hc_d, _, _ = score_hypothesis_coverage(kb)
    ci, ci_d, broken = score_cross_layer_integrity(kb)
    tg, tg_d, _, _ = score_theory_guardrail(kb)

    dims = {
        "method_coverage": mc,
        "flow_coverage": fc,
        "hypothesis_coverage": hc,
        "cross_layer_integrity": ci,
        "theory_guardrail": tg,
    }
    total = sum(dims[k] * WEIGHTS[k] for k in WEIGHTS)
    verdict = "PASS" if total >= THRESHOLD else "BELOW THRESHOLD"

    ts = args.now or datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

    lines = []
    lines.append("=" * 52)
    lines.append("📊 RKS 科研完备度评分 — %s" % args.system_id)
    lines.append("时间: %s" % ts)
    lines.append("-" * 52)
    lines.append("  方法覆盖率 method_coverage     : %6.1f  (%s)" % (mc, mc_d))
    lines.append("  流程覆盖率 flow_coverage       : %6.1f  (%s)" % (fc, fc_d))
    lines.append("  假设覆盖率 hypothesis_coverage : %6.1f  (%s)" % (hc, hc_d))
    lines.append("  跨层完整性 cross_layer_integ.  : %6.1f  (%s)" % (ci, ci_d))
    lines.append("  理论护栏   theory_guardrail    : %6.1f  (%s)" % (tg, tg_d))
    lines.append("-" * 52)
    lines.append("  加权总分 RKS = %.1f  [阈值 %.0f] → %s" % (total, THRESHOLD, verdict))
    if broken:
        lines.append("  ⚠️ 断链引用:")
        for fn, ref in broken[:20]:
            lines.append("     - %s → %s" % (fn, ref))
    lines.append("=" * 52)
    report = "\n".join(lines)
    print(report)

    if args.write_report:
        rep_dir = os.path.join(kb, "reports")
        os.makedirs(rep_dir, exist_ok=True)
        rep_path = os.path.join(rep_dir, "rks-%s.md" % ts)
        with open(rep_path, "w", encoding="utf-8") as f:
            f.write("```\n" + report + "\n```\n")
        print("报告已写入: %s" % rep_path)

    if args.append_ledger:
        ledger = os.path.join(kb, "meta", "scan-ledger.tsv")
        os.makedirs(os.path.dirname(ledger), exist_ok=True)
        new = not os.path.isfile(ledger)
        with open(ledger, "a", encoding="utf-8") as f:
            if new:
                f.write("timestamp\tsystem_id\trks\tmethod\tflow\thypothesis\tintegrity\tguardrail\tverdict\n")
            f.write("%s\t%s\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%s\n" % (
                ts, args.system_id, total, mc, fc, hc, ci, tg, verdict))
        print("账本已追加: %s" % ledger)

    return 0 if total >= THRESHOLD else 1


if __name__ == "__main__":
    sys.exit(main())
