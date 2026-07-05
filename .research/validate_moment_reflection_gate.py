#!/usr/bin/env python3
"""
Cycle 46 / T-C8: validate_moment_reflection_gate.py

Validates that LifeMoment promotion to WeaveQuest requires a user-authored,
non-empty reflection. OCR text must not satisfy the reflection gate.
"""
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
SERVICE_FILE = PROJECT / "Sources/OneWeave/LifeMomentService.swift"
MODEL_FILE = PROJECT / "Sources/OneWeave/LifeMoment.swift"


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


def extract_function(source: str, name: str) -> str:
    match = re.search(r"(?:public\s+)?(?:static\s+)?func\s+" + re.escape(name) + r"\s*\(", source)
    if not match:
        return ""
    brace = source.find("{", match.end())
    if brace == -1:
        return ""
    depth = 1
    idx = brace + 1
    while idx < len(source) and depth > 0:
        if source[idx] == "{":
            depth += 1
        elif source[idx] == "}":
            depth -= 1
        idx += 1
    return source[match.start():idx]


def main() -> int:
    print("--- LifeMoment reflection gate (cycle 46 / T-C8) ---")

    service_exists = check("LifeMomentService.swift exists", SERVICE_FILE.exists())
    model_exists = check("LifeMoment.swift exists", MODEL_FILE.exists())
    service = SERVICE_FILE.read_text() if service_exists else ""
    model = MODEL_FILE.read_text() if model_exists else ""
    promote = extract_function(service, "promoteToQuest")
    init_match = re.search(r"public init\(userReflection:[\s\S]*?\n    \}", model)
    init_body = init_match.group(0) if init_match else ""

    check("service uses trimmingCharacters", service.count("trimmingCharacters") >= 1)
    check("service throws emptyReflection", service.count("emptyReflection") >= 1)
    check("promoteToQuest function exists", bool(promote))
    check("promoteToQuest trims userReflection", "moment.userReflection" in promote and "trimmingCharacters" in promote)
    check("promoteToQuest checks trimmed reflection is non-empty", "reflectionTrimmed.isEmpty" in promote)
    check("promoteToQuest throws LifeMomentError.emptyReflection", "throw LifeMomentError.emptyReflection" in promote)
    check("emptyReflection guard runs before WeaveQuest creation", promote.find("emptyReflection") != -1 and promote.find("WeaveQuest(") != -1 and promote.find("emptyReflection") < promote.find("WeaveQuest("))
    check("quest description uses trimmed userReflection", "description: reflectionTrimmed" in promote)
    check("quest reflectionNote uses trimmed userReflection", "quest.reflectionNote = reflectionTrimmed" in promote)
    check("OCR text is not used by promoteToQuest", "ocrText" not in promote)
    is_reflection_line = re.search(r"self\.isUserReflection\s*=\s*(.+)", init_body)
    check(
        "isUserReflection is computed only from userReflection in init",
        is_reflection_line is not None
        and "Self.isNonEmptyReflection(userReflection)" in is_reflection_line.group(0)
        and "ocrText" not in is_reflection_line.group(0),
    )
    check("model helper trims whitespace for user reflection", "isNonEmptyReflection" in model and "trimmingCharacters(in: .whitespacesAndNewlines)" in model)
    check("model documents OCR does not count as reflection", "OCR text does NOT count" in model)

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    print("OVERALL: PASS" if FAIL == 0 else "OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
