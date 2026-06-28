#!/usr/bin/env python3
"""
validate_mastery_cap_all_sites.py — verifies every mastery-tier mutation
site respects the ApprenticeKnot cap (Cycle 41 finding A2).

Cycle 37 added `MasteryKnotEngine.maxTier(...)` and applied it to ONE site
(LifeContext.swift updateMasteryFromEvent). Claude's cycle 41 audit found
THREE additional bypass sites. Cycle 42 patched all of them; this validator
prevents new bypasses from regressing.

The validator scans every `masteryTiers[<key>] = min(4, ...+1)` write and
asserts a `MasteryKnotEngine.maxTier(...)` check precedes it (or the
surrounding `if` includes a `cap` variable in its condition).

Run: python3 audit/validators/validate_mastery_cap_all_sites.py
"""
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
SOURCES = PROJECT_ROOT / "Sources" / "OneWeave"


def main() -> int:
    print("=== validate_mastery_cap_all_sites.py ===")
    failures: list[str] = []
    sites = []

    # Find every file that contains a masteryTiers write
    for swift_file in SOURCES.glob("*.swift"):
        text = swift_file.read_text()
        # Pattern: masteryTiers[<key>] = min(4, ...+1) — increment writes
        matches = re.finditer(
            r"masteryTiers\[(\w+)\]\s*=\s*min\(4,\s*\w+\s*\+\s*\d+\)",
            text,
        )
        for m in matches:
            site_line = text[: m.start()].count("\n") + 1
            # Look back ~30 lines for a MasteryKnotEngine.maxTier reference
            window_start = max(0, m.start() - 2000)
            window = text[window_start : m.start()]
            has_cap = "MasteryKnotEngine.maxTier" in window
            has_cap_check = re.search(r"cap\s*[!=<>]+\s*(Int\.max|cap|tier)", window)
            sites.append((swift_file.name, site_line, m.group(0), has_cap and has_cap_check))

    if not sites:
        print("  (no masteryTiers increment writes found — nothing to validate)")
        return 0

    for name, line, snippet, ok in sites:
        marker = "✓" if ok else "✗"
        print(f"  {marker} {name}:{line}  {snippet}")
        if not ok:
            failures.append(f"{name}:{line} — masteryTiers increment WITHOUT ApprenticeKnot cap check")

    print()
    if failures:
        print(f"✗ {len(failures)} bypass site(s):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"✓ PASS — all {len(sites)} mastery-tier mutation sites respect ApprenticeKnot cap")
    return 0


if __name__ == "__main__":
    sys.exit(main())
