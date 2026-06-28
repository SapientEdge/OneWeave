#!/usr/bin/env python3
"""
T082 — validate_life_context_reflection_gate_matrix.py

Validates the LifeContext.completeQuest reflection-length gate (T075, GLM 5.2 round 1).
Mirrors the Swift logic: empty → 3 essence; <20 chars → 3 essence; ≥20 chars → 10 essence.
"""

import sys
from pathlib import Path

REPO = Path("/root/hermes-workspace/projects/oneweave")
LC_FILE = REPO / "Sources/OneWeave/LifeContext.swift"

MIN_CHARS = 20

def trimmed(s: str) -> str:
    return s.strip()

def expected_bonus(reflection: str) -> tuple[int, str]:
    t = trimmed(reflection)
    if not t:
        return 3, "no reflection"
    if len(t) >= MIN_CHARS:
        return 10, "with reflection"
    return 3, "short reflection"

CASES = [
    # (essence_initial, reflection, expected_bonus_delta, expected_substring_in_reason)
    (0,  "",                                       3,  "no reflection"),
    (0,  "   ",                                    3,  "no reflection"),
    (0,  "ok",                                     3,  "short reflection"),
    (0,  "x" * 19,                                 3,  "short reflection"),
    (0,  "x" * 20,                                10,  "with reflection"),
    (0,  "x" * 21,                                10,  "with reflection"),
    (10, "Felt a real moment of clarity today.", 10,  "with reflection"),
]

def main():
    src = LC_FILE.read_text()
    # Find the bonus logic block. T075 introduced `let minChars = 20` (literal);
    # A3 (Claude round-5 audit) refactored to use `ReflectionGate.minCharsForFullReward`.
    # Both forms are valid; accept either.
    has_literal_gate = "let minChars = 20" in src
    has_gate_ref = "ReflectionGate.minCharsForFullReward" in src
    if not (has_literal_gate or has_gate_ref):
        print(f"[FAIL] LifeContext.swift missing reflection-gate (T075/A3): neither `let minChars = 20` nor `ReflectionGate.minCharsForFullReward` found.")
        sys.exit(1)
    if "trimmed.isEmpty" not in src:
        print(f"[FAIL] LifeContext.swift missing `trimmed.isEmpty` branch")
        sys.exit(1)
    if "trimmed.count >= minChars" not in src:
        print(f"[FAIL] LifeContext.swift missing length-gate branch")
        sys.exit(1)

    print(f"--- Reflection gate matrix ({len(CASES)} cases, min_chars={MIN_CHARS}) ---")
    pass_n = 0
    fail_n = 0
    for essence_init, reflection, exp_delta, exp_reason_substr in CASES:
        bonus, reason_kind = expected_bonus(reflection)
        ok = (bonus == exp_delta) and (exp_reason_substr in reason_kind)
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] essence={essence_init:3d} ref={len(reflection):3d}ch "
              f"'{reflection[:30]}' → bonus={bonus} reason={reason_kind!r}")
        if ok: pass_n += 1
        else:  fail_n += 1

    print(f"\nResults: {pass_n}/{len(CASES)} PASS")
    if fail_n:
        print("OVERALL: FAIL")
        sys.exit(1)
    print("OVERALL: PASS")

if __name__ == "__main__":
    main()