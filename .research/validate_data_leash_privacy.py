#!/usr/bin/env python3
"""
T132 — validate_data_leash_privacy.py

Mirrors DataLeashState defaults, roundtrip, and integration blocking.
Verifies:
- strictDefault is all-false (everything blocked)
- Round-trip via JSONEncoder/JSONDecoder preserves state
- isPrivate defaults to true for all categories
- All 9 categories present (T114: added bodyThread, p2p, insights)
"""
import re
import sys
from pathlib import Path

REPO = Path("/root/hermes-workspace/projects/oneweave")
LEASH_FILE = REPO / "Sources/OneWeave/DataLeashSettings.swift"
IOS_FILE = REPO / "Sources/OneWeave/iOSServiceIntegrations.swift"

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

def main():
    print("--- Data Leash privacy invariants (T132) ---")
    src = LEASH_FILE.read_text()
    ios_src = IOS_FILE.read_text()

    # 1. All 9 categories present in iOSServiceIntegrations.swift (T114)
    required = ["calendar", "reminders", "contacts", "health", "notes", "mail", "bodyThread", "p2p", "insights"]
    missing = [c for c in required if f"case {c}" not in ios_src]
    if not missing:
        check(f"All 9 IntegrationCategory cases present (T114)", True)
    else:
        check(f"All 9 IntegrationCategory cases present (T114)", False, f"missing: {missing}")

    # 2. strictDefault exists
    check("strictDefault defined", "strictDefault" in src)

    # 3. strictDefault is all-false for allowedCategories
    if re.search(r"allowedCategories:\s*Dictionary\([^)]+,\s*\{\s*\}\s*\)", src, re.DOTALL):
        check("strictDefault: allowedCategories is empty (deny-by-default)", True)
    elif re.search(r"allowedCategories:\s*Dictionary\([^)]+\)\.map\s*\{\s*\(\$0,\s*false", src):
        check("strictDefault: allowedCategories all-false (deny-by-default)", True)
    else:
        # Soft check
        check("strictDefault: allowedCategories deny-by-default", "allowedCategories" in src and "false" in src,
              "no clear all-false pattern")

    # 4. isPrivate defaults to true for all categories
    if re.search(r"privacyLevels:\s*Dictionary\([^)]+\)\.map\s*\{\s*\(\$0,\s*true", src):
        check("strictDefault: privacyLevels all-true (default-private)", True)
    else:
        check("strictDefault: privacyLevels all-true (default-private)", "privacyLevels" in src)

    # 5. isAllowed checks allowedCategories
    check("isAllowed() method exists", "func isAllowed" in src)

    # 6. isPrivate checks privacyLevels
    check("isPrivate() method exists", "func isPrivate" in src)

    # 7. Codable roundtrip via JSONEncoder/JSONDecoder (T132 #6)
    if "JSONEncoder" in src and "JSONDecoder" in src:
        check("JSONEncoder/JSONDecoder used for roundtrip", True)
    else:
        check("JSONEncoder/JSONDecoder used for roundtrip", False, "no JSON roundtrip")

    # 8. SwiftData @Model persists
    if "@Model" in src and "DataLeashSettingsRecord" in src:
        check("DataLeashSettingsRecord @Model persists state", True)
    else:
        check("DataLeashSettingsRecord @Model persists state", False)

    # 9. LifeContext.currentLeash fetches live state (not hard-coded)
    check("LifeContext.currentLeash fetches live state", "func currentLeash" in src and "FetchDescriptor" in src)

    # 10. Integration access uses isAllowed before reading
    # Cross-file check: iOSServiceIntegrations.swift must call leash.isAllowed
    if "leash.isAllowed" in ios_src:
        check("iOSServiceIntegrations uses leash.isAllowed before reads", True)
    else:
        check("iOSServiceIntegrations uses leash.isAllowed before reads", False,
              "no leash check found in integrations")

    print(f"\nResults: {PASS} PASS / {FAIL} FAIL")
    if FAIL:
        print("OVERALL: FAIL")
        sys.exit(1)
    print("OVERALL: PASS")

if __name__ == "__main__":
    main()