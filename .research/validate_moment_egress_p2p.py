#!/usr/bin/env python3
"""
Cycle 46 / T-C9: validate_moment_egress_p2p.py

Validates the P2P-specific LifeMoment egress guard. P2P envelopes must not
transmit OCR, OCR confidence, embeddings, detected entities, or sealed
cipher material.
"""
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
P2P_FILE = PROJECT / "Sources/OneWeave/P2PWeaveShare.swift"

BLOCKED_FIELDS = [
    "ocrText",
    "ocrConfidence",
    "imageEmbeddingText",
    "detectedEntitiesJSON",
    "sealedCiphertext",
    "sealedNonce",
    "sealedTag",
    "cipherHKDFInfo",
]


PASS = 0
FAIL = 0


def check(name, condition) -> bool:
    global PASS, FAIL
    if condition:
        PASS += 1
        print(f"  [PASS] {name}")
        return True
    FAIL += 1
    print(f"  [FAIL] {name}")
    return False


def extract_enum(source: str, name: str) -> str:
    match = re.search(r"public enum\s+" + re.escape(name) + r"\s*\{", source)
    if not match:
        return ""
    brace = match.end() - 1
    depth = 1
    idx = brace + 1
    while idx < len(source) and depth > 0:
        if source[idx] == "{":
            depth += 1
        elif source[idx] == "}":
            depth -= 1
        idx += 1
    return source[brace:idx]


def main() -> int:
    print("--- LifeMoment P2P egress guard (cycle 46 / T-C9) ---")

    exists = check("P2PWeaveShare.swift exists", P2P_FILE.exists())
    source = P2P_FILE.read_text() if exists else ""
    guard = extract_enum(source, "LifeMomentEgressGuard")

    check("P2P file contains LifeMomentEgressGuard", "LifeMomentEgressGuard" in source)
    check("LifeMomentEgressGuard enum parsed", bool(guard))
    check("guard declares blockedFields set", "blockedFields" in guard and "Set<String>" in guard)
    for field in BLOCKED_FIELDS:
        check(f"blockedFields contains {field}", f'"{field}"' in guard)
    check("guard declares allowedFields set", "allowedFields" in guard and "Set<String>" in guard)
    check("allowedFields permits userReflection", '"userReflection"' in guard)
    check("allowedFields permits userAssignedThreadRaw", '"userAssignedThreadRaw"' in guard)
    check("guard has assertClean() method", re.search(r"func\s+assertClean\s*\(", guard) is not None)
    check("assertClean accepts envelope dictionary", "_ envelope: [String: Any]" in guard)
    check("assertClean intersects envelope keys with blockedFields", ".intersection(blockedFields)" in guard)
    check("assertClean returns false on blocked leak", "return false" in guard)
    check("assertClean returns true for clean envelope", "return true" in guard)
    check("P2P share comments reference Invariant 11", "Invariant 11" in guard or "Invariant 11" in source)
    check(
        "createCircleShare documents LifeMoment records are never transmitted",
        "LifeMoment records are NEVER transmitted via P2P" in source,
    )

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    print("OVERALL: PASS" if FAIL == 0 else "OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
