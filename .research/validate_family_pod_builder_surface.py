#!/usr/bin/env python3
"""
T083 — validate_family_pod_builder_surface.py

Validates T076 (GLM 5.2 round 1, cross-verified): FamilyPod.swift:330/335/338
must NOT reference non-existent LifeContext members. Asserts that the three
required computed-property shims exist on LifeContext.
"""

import re
import sys
from pathlib import Path

REPO = Path("/root/hermes-workspace/projects/oneweave")
LC_FILE = REPO / "Sources/OneWeave/LifeContext.swift"
FP_FILE = REPO / "Sources/OneWeave/FamilyPod.swift"

# Required computed properties on LifeContext (the shims that fix the compile errors)
REQUIRED_SHIMS = ["threads", "currentSeasonName", "activeAmplifierName"]

# Reference sites in FamilyPod.swift that depend on the shims
EXPECTED_FP_REFS = [
    "context.threads",
    "context.currentSeasonName",
    "context.activeAmplifierName",
]

def main():
    pass_n = 0
    fail_n = 0
    print("--- FamilyPod builder surface validator (T076) ---")

    # 1. Verify each shim exists on LifeContext
    lc_src = LC_FILE.read_text()
    for shim in REQUIRED_SHIMS:
        pattern = rf"\bvar\s+{shim}\s*[:?]"
        if re.search(pattern, lc_src):
            print(f"  [PASS] LifeContext exposes `var {shim}`")
            pass_n += 1
        else:
            print(f"  [FAIL] LifeContext missing `var {shim}`")
            fail_n += 1

    # 1b. T114: IntegrationCategory has all 9 cases (was 6)
    ios_src = (REPO / "Sources/OneWeave/iOSServiceIntegrations.swift").read_text()
    required_cases = ["calendar", "reminders", "contacts", "health", "notes", "mail",
                      "bodyThread", "p2p", "insights"]
    missing = [c for c in required_cases if f"case {c}" not in ios_src]
    if not missing:
        print(f"  [PASS] IntegrationCategory has all 9 cases (T114)")
        pass_n += 1
    else:
        print(f"  [FAIL] IntegrationCategory missing cases: {missing}")
        fail_n += 1

    # 2. Verify FamilyPod actually references those shims (so the shims are load-bearing)
    fp_src = FP_FILE.read_text()
    for ref in EXPECTED_FP_REFS:
        if ref in fp_src:
            print(f"  [PASS] FamilyPod references `{ref}`")
            pass_n += 1
        else:
            print(f"  [FAIL] FamilyPod missing reference `{ref}`")
            fail_n += 1

    # 3. Verify displayName is `var` (T077 — mutability for sanitizer)
    if re.search(r"\bvar\s+displayName\s*:\s*String", fp_src):
        print(f"  [PASS] FamilyPodMember.displayName is `var` (T077)")
        pass_n += 1
    else:
        print(f"  [FAIL] FamilyPodMember.displayName is still `let` (T077 not applied)")
        fail_n += 1

    # 4. Negative test: ensure no references to ghost members like `activeAmplifier` (without Name)
    # The shim is `activeAmplifierName`; a typo'd `activeAmplifier` would still be a ghost.
    if re.search(r"\.activeAmplifier\b(?!\w)", fp_src):
        # Find context
        for line_no, line in enumerate(fp_src.splitlines(), 1):
            if re.search(r"\.activeAmplifier\b(?!\w)", line):
                print(f"  [WARN] FamilyPod.swift:{line_no} references `.activeAmplifier` (no 'Name') — verify this is intentional")

    print(f"\nResults: {pass_n} PASS / {fail_n} FAIL")
    if fail_n:
        print("OVERALL: FAIL")
        sys.exit(1)
    print("OVERALL: PASS")

if __name__ == "__main__":
    main()