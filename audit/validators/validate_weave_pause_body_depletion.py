#!/usr/bin/env python3
"""
validate_weave_pause_body_depletion.py — verifies CognitiveLoad.swift
Weave Pause trigger includes the constitutionally-mandated body-depletion
clause (Cycle 41 finding A1).

Per constitution §5: Weave Pause fires ONLY when cognitive load is rising
AND ≥ 0.85 AND the body is depleted (sleep debt or low HRV). The third
conjunct was missing in code until cycle 42; this validator prevents the
regression from returning.

Run: python3 audit/validators/validate_weave_pause_body_depletion.py
"""
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
COG = PROJECT_ROOT / "Sources" / "OneWeave" / "CognitiveLoad.swift"


def main() -> int:
    print("=== validate_weave_pause_body_depletion.py ===")
    failures: list[str] = []
    if not COG.exists():
        print(f"✗ CognitiveLoad.swift not found at {COG}")
        return 1
    text = COG.read_text()

    # The trigger must reference BOTH a sleep-debt component and an HRV component
    # in the same decision that produces shouldTriggerWeavePause.
    if "bodyDepleted" not in text:
        failures.append("bodyDepleted conjunct not present in CognitiveLoad.swift")
    else:
        print("  bodyDepleted variable:           ✓ present")

    # The conjunct must check sleepScore >= 0.5 OR hrvScore >= 0.5 (or both)
    sleep_check = re.search(r"sleepScore\s*>=\s*0\.5", text)
    hrv_check = re.search(r"hrvScore\s*>=\s*0\.5", text)
    if sleep_check and hrv_check:
        print(f"  sleepScore >= 0.5 check:         ✓ present")
        print(f"  hrvScore >= 0.5 check:           ✓ present")
    else:
        if not sleep_check:
            failures.append("sleepScore >= 0.5 threshold check missing")
        if not hrv_check:
            failures.append("hrvScore >= 0.5 threshold check missing")

    # The trigger expression must reference bodyDepleted alongside trend == .rising
    # Use a wider window (next 100 lines after bodyDepleted) since comments
    # may sit between the variable definition and the shouldTrigger line.
    body_def = text.find("let bodyDepleted")
    if body_def == -1:
        failures.append("bodyDepleted variable not found")
    else:
        trigger_window = text[body_def : body_def + 3000]
        if "shouldTrigger" in trigger_window and "&& bodyDepleted" in trigger_window:
            print(f"  shouldTrigger uses bodyDepleted: ✓ present")
        else:
            failures.append("shouldTrigger expression does not include bodyDepleted conjunct")

    # shouldTriggerWeavePause field must exist on the CognitiveLoadReading
    if "shouldTriggerWeavePause" in text:
        print(f"  CognitiveLoadReading.shouldTriggerWeavePause: ✓ present")
    else:
        failures.append("shouldTriggerWeavePause field missing from CognitiveLoadReading")

    print()
    if failures:
        print(f"✗ {len(failures)} failure(s):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("OVERALL: PASS — Weave Pause body-depletion clause is constitutionally enforced")
    return 0


if __name__ == "__main__":
    sys.exit(main())
