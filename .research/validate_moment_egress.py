#!/usr/bin/env python3
"""
Cycle 46 / T-C9: validate_moment_egress.py

Validates the LifeMoment egress boundary across P2P, FamilyPod,
PortableExport, and widget snapshot channels. Inferred moment content must
never leave the LifeMoment sandbox.
"""
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
FILES = {
    "P2PWeaveShare.swift": PROJECT / "Sources/OneWeave/P2PWeaveShare.swift",
    "FamilyPod.swift": PROJECT / "Sources/OneWeave/FamilyPod.swift",
    "PortableExport.swift": PROJECT / "Sources/OneWeave/PortableExport.swift",
    "OneWeaveSnapshotStore.swift": PROJECT / "Sources/OneWeave/OneWeaveSnapshotStore.swift",
}

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
    return extract_balanced(source, match.end() - 1)


def extract_struct(source: str, name: str) -> str:
    match = re.search(r"struct\s+" + re.escape(name) + r"[\s\S]*?\{", source)
    if not match:
        return ""
    return extract_balanced(source, match.end() - 1)


def extract_balanced(source: str, brace: int) -> str:
    depth = 1
    idx = brace + 1
    while idx < len(source) and depth > 0:
        if source[idx] == "{":
            depth += 1
        elif source[idx] == "}":
            depth -= 1
        idx += 1
    return source[brace:idx]


def extract_function(source: str, name: str) -> str:
    match = re.search(r"func\s+" + re.escape(name) + r"\s*\(", source)
    if not match:
        return ""
    brace = source.find("{", match.end())
    if brace == -1:
        return ""
    return extract_balanced(source, brace)


def contains_all_fields(text: str) -> bool:
    return all(f'"{field}"' in text for field in BLOCKED_FIELDS)


def main() -> int:
    print("--- LifeMoment egress boundary (cycle 46 / T-C9) ---")

    sources = {}
    for name, path in FILES.items():
        exists = check(f"{name} exists", path.exists())
        sources[name] = path.read_text() if exists else ""
        check(
            f"{name} references blockedFields or blockedMomentFields",
            "blockedFields" in sources[name] or "blockedMomentFields" in sources[name],
        )

    p2p_guard = extract_enum(sources["P2PWeaveShare.swift"], "LifeMomentEgressGuard")
    family_guard = extract_enum(sources["FamilyPod.swift"], "FamilyPodEgressGuard")
    export_guard = extract_enum(sources["PortableExport.swift"], "PortableExportEgressGuard")
    snapshot_struct = extract_struct(sources["OneWeaveSnapshotStore.swift"], "OneWeaveSnapshot")
    exportable_dict = extract_function(sources["PortableExport.swift"], "exportableDict")

    check("P2P LifeMomentEgressGuard exists", bool(p2p_guard))
    check("FamilyPodEgressGuard exists", bool(family_guard))
    check("PortableExportEgressGuard exists", bool(export_guard))
    check("OneWeaveSnapshot struct parsed", bool(snapshot_struct))
    check("P2P guard contains every blocked field", contains_all_fields(p2p_guard))
    check("FamilyPod guard contains every blocked field", contains_all_fields(family_guard))
    check("PortableExport guard contains every blocked field", contains_all_fields(export_guard))
    check(
        "OneWeaveSnapshot struct contains no blocked moment field",
        all(field not in snapshot_struct for field in BLOCKED_FIELDS),
    )
    check(
        "snapshot file has explicit blockedMomentFieldsInSnapshot audit set",
        "blockedMomentFieldsInSnapshot" in sources["OneWeaveSnapshotStore.swift"]
        and contains_all_fields(sources["OneWeaveSnapshotStore.swift"]),
    )
    check("PortableExport exportableDict exists", bool(exportable_dict))
    check(
        "PortableExport exportableDict omits blocked fields",
        all(f'"{field}"' not in exportable_dict for field in BLOCKED_FIELDS),
    )
    check(
        "PortableExport fullBundle documented as still excluding moment inferred fields",
        ".fullBundle" in sources["PortableExport.swift"]
        and "even .fullBundle exports MUST NOT include OCR/embeddings" in sources["PortableExport.swift"],
    )
    check(
        "PortableExport exportableDict only emits user-authored safe moment fields",
        all(token in exportable_dict for token in [
            '"userReflection"',
            '"userAssignedThread"',
            '"momentKind"',
            '"isSealed"',
        ]),
    )
    check(
        "FamilyPod strip removes blocked moment fields",
        "func strip" in family_guard and "clean.removeValue(forKey: key)" in family_guard,
    )

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    print("OVERALL: PASS" if FAIL == 0 else "OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
