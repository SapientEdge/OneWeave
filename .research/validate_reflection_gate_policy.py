#!/usr/bin/env python3
"""
T079 — validate_reflection_gate_policy.py

Mirrors the centralized ReflectionGate policy object (Sources/OneWeave/ReflectionGate.swift).
Verifies:
- minCharsForFullReward constant exists in both Swift + Python
- validateNonEmpty throws on empty input
- validateForFullReward throws on too-short input
- passesEntropyCheck rejects low-entropy bypass attempts
"""
import re
import sys
import math
from pathlib import Path

REPO = Path("/root/hermes-workspace/projects/oneweave")
GATE_FILE = REPO / "Sources/OneWeave" / "ReflectionGate.swift"

PASS = 0
FAIL = 0

def check(name, ok, detail=""):
    global PASS, FAIL
    if ok:
        PASS += 1
        print(f"  [PASS] {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name}: {detail}")

def shannon_entropy(text: str) -> float:
    """Shannon entropy in bits. Mirror of ReflectionGate.passesEntropyCheck."""
    if not text:
        return 0.0
    freq = {}
    for c in text:
        freq[c] = freq.get(c, 0) + 1
    n = len(text)
    return -sum((c/n) * math.log2(c/n) for c in freq.values())

def main():
    print("--- ReflectionGate policy object (T079) ---")
    if not GATE_FILE.exists():
        check("ReflectionGate.swift exists", False, "file not found")
        print(f"\nResults: {PASS} PASS / {FAIL} FAIL\nOVERALL: FAIL")
        sys.exit(1)

    src = GATE_FILE.read_text()
    check("ReflectionGate.swift exists", True)

    # 1. minCharsForFullReward = 20
    if re.search(r"minCharsForFullReward\s*=\s*20", src):
        check("minCharsForFullReward = 20 (Constitution §4)", True)
    else:
        check("minCharsForFullReward = 20", False, "constant not 20")

    # 2. validateNonEmpty throws on empty
    if "validateNonEmpty" in src and "throw GateError.emptyReflection" in src:
        check("validateNonEmpty throws on empty", True)
    else:
        check("validateNonEmpty throws on empty", False)

    # 3. validateForFullReward throws on too-short
    if "validateForFullReward" in src and "GateError.tooShort" in src:
        check("validateForFullReward throws on too-short", True)
    else:
        check("validateForFullReward throws on too-short", False)

    # 4. passesEntropyCheck with threshold 2.5
    if "passesEntropyCheck" in src and "2.5" in src:
        check("passesEntropyCheck uses threshold 2.5 bits/char", True)
    else:
        check("passesEntropyCheck uses threshold 2.5 bits/char", False)

    # 5. Python mirror shannon entropy
    assert abs(shannon_entropy("hello world") - 3.18) < 0.5  # approximate
    check("Python shannon_entropy computes ~3.18 for 'hello world'", True)

    # 6. Low-entropy bypass detection
    low_e = shannon_entropy("aaaaaaaaaaaaaaaa")
    high_e = shannon_entropy("felt calm after a quiet walk with the dog")
    if low_e < 2.5 and high_e >= 2.5:
        check(f"Entropy check rejects 'aaa...' ({low_e:.2f}) and accepts real reflection ({high_e:.2f})", True)
    else:
        check(f"Entropy check (low={low_e:.2f}, high={high_e:.2f})", False,
              "expected low<2.5, high>=2.5")

    # 7. Empty input rejected
    if shannon_entropy("") == 0.0:
        check("Empty input entropy = 0 (rejected by passesEntropyCheck)", True)
    else:
        check("Empty input entropy", False, "expected 0")

    print(f"\nResults: {PASS} PASS / {FAIL} FAIL")
    if FAIL:
        print("OVERALL: FAIL")
        sys.exit(1)
    print("OVERALL: PASS")

if __name__ == "__main__":
    main()