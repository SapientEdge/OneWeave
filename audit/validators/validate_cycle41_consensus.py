#!/usr/bin/env python3
"""
validate_cycle41_consensus.py — verifies Cycle 41 multi-agent cross-CLI synthesis
was captured with all required sections.

Cycle 41 dispatched 5 CLIs (Claude, Codex, Grok, GLM 5.2, Nemotron 3 Super) in
parallel. This validator checks that:
  1. All 5 CLI output files exist and are non-empty
  2. The synthesis file exists with all required sections
  3. The MULTI_AGENT_SYNTHESIS_CYCLE_41.md methodology doc exists
  4. Consensus findings count is reasonable (≥ 3 items)
  5. Unified fix list has BLOCKERS, HIGH, MEDIUM, LOW tiers

Run: python3 audit/validators/validate_cycle41_consensus.py
"""
import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
CLI_DIR = PROJECT_ROOT / ".cli"
PROMPTS_DIR = CLI_DIR / "prompts"
OUTPUTS_DIR = CLI_DIR / "outputs"
SYNTHESIS_FILE = OUTPUTS_DIR / "round_6_synthesis.md"
METHODOLOGY_DOC = PROJECT_ROOT / "MULTI_AGENT_SYNTHESIS_CYCLE_41.md"

EXPECTED_CLIS = ["claude", "codex", "grok", "glm", "nemotron"]

def main() -> int:
    print("=== validate_cycle41_consensus.py ===")
    failures = []
    warnings = []

    # 1. All 5 CLI output files exist and are non-empty
    for cli in EXPECTED_CLIS:
        out_file = OUTPUTS_DIR / f"round_6_{cli}.md"
        prompt_file = PROMPTS_DIR / f"round_6_{cli}.md"
        if not prompt_file.exists():
            failures.append(f"missing prompt: {prompt_file.relative_to(PROJECT_ROOT)}")
        else:
            prompt_size = prompt_file.stat().st_size
            print(f"  prompt  {cli:10s} {prompt_size:>8d} bytes")
        if not out_file.exists():
            failures.append(f"missing output: {out_file.relative_to(PROJECT_ROOT)}")
            continue
        size = out_file.stat().st_size
        print(f"  output  {cli:10s} {size:>8d} bytes")
        if size == 0:
            failures.append(f"empty output: {out_file.relative_to(PROJECT_ROOT)}")
        # Grok is known to truncate on Linux — warn but don't fail
        if cli == "grok" and size < 1000:
            warnings.append(f"grok output truncated ({size} bytes) — expected behavior on Linux")

    # 2. Synthesis file exists with required sections
    if not SYNTHESIS_FILE.exists():
        failures.append(f"missing synthesis: {SYNTHESIS_FILE.relative_to(PROJECT_ROOT)}")
    else:
        text = SYNTHESIS_FILE.read_text()
        required_sections = [
            "Per-CLI Summary",
            "Consensus List",
            "Unique Findings",
            "Unified Fix List",
            "BLOCKER",
            "HIGH",
            "MEDIUM",
            "LOW",
            "Linux-fixable",
            "Mac-only",
        ]
        for section in required_sections:
            if section not in text:
                failures.append(f"synthesis missing section: '{section}'")
        synth_size = SYNTHESIS_FILE.stat().st_size
        print(f"  synthesis        {synth_size:>8d} bytes")

        # 3. Consensus findings count
        consensus_matches = re.findall(r"^\| \d+ \|", text, re.MULTILINE)
        print(f"  consensus items: {len(consensus_matches)}")
        if len(consensus_matches) < 3:
            failures.append(f"consensus list too short ({len(consensus_matches)} items)")

        # 4. Unique findings count
        unique_matches = re.findall(r"^\| U\d+ \|", text, re.MULTILINE)
        print(f"  unique items:    {len(unique_matches)}")
        if len(unique_matches) < 3:
            warnings.append(f"unique findings list thin ({len(unique_matches)} items)")

    # 5. Methodology doc exists
    if not METHODOLOGY_DOC.exists():
        failures.append(f"missing methodology: {METHODOLOGY_DOC.relative_to(PROJECT_ROOT)}")
    else:
        method_size = METHODOLOGY_DOC.stat().st_size
        print(f"  methodology      {method_size:>8d} bytes")
        method_text = METHODOLOGY_DOC.read_text()
        for section in ["TL;DR", "Dispatch Pattern", "Per-CLI Weighting", "Lessons Learned"]:
            if section not in method_text:
                failures.append(f"methodology missing section: '{section}'")

    # Summary
    print()
    if warnings:
        print(f"⚠ {len(warnings)} warning(s):")
        for w in warnings:
            print(f"  - {w}")
    if failures:
        print(f"✗ {len(failures)} failure(s):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("✓ PASS — Cycle 41 consensus captured with all required sections")
    return 0


if __name__ == "__main__":
    sys.exit(main())
