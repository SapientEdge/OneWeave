#!/usr/bin/env python3
"""
Cycle 46 / T-C8: validate_moment_graph_integration.py

Validates that LifeMoment can link to a graph entity, and promotion to a
quest explicitly nullifies that link so inferred moment content does not
silently become graph structure.
"""
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
MODEL_FILE = PROJECT / "Sources/OneWeave/LifeMoment.swift"
SERVICE_FILE = PROJECT / "Sources/OneWeave/LifeMomentService.swift"


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


def model_body(source: str) -> str:
    match = re.search(r"@Model\s+public final class LifeMoment\s*\{", source)
    if not match:
        return ""
    start = match.end()
    depth = 1
    idx = start
    while idx < len(source) and depth > 0:
        if source[idx] == "{":
            depth += 1
        elif source[idx] == "}":
            depth -= 1
        idx += 1
    return source[start:idx - 1]


def property_block(source: str, property_name: str) -> str:
    lines = source.splitlines()
    for idx, line in enumerate(lines):
        if re.search(r"\bvar\s+" + re.escape(property_name) + r"\b", line):
            start = max(0, idx - 4)
            return "\n".join(lines[start:idx + 1])
    return ""


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
    print("--- LifeMoment graph integration (cycle 46 / T-C8) ---")

    model_exists = check("LifeMoment.swift exists", MODEL_FILE.exists())
    service_exists = check("LifeMomentService.swift exists", SERVICE_FILE.exists())
    model = MODEL_FILE.read_text() if model_exists else ""
    service = SERVICE_FILE.read_text() if service_exists else ""
    body = model_body(model)
    linked_block = property_block(body, "linkedEntity")
    promote = extract_function(service, "promoteToQuest")

    check("LifeMoment @Model body parsed", bool(body))
    check("linkedEntity property block parsed", bool(linked_block))
    check(
        "linkedEntity is optional LifeEntity relationship",
        re.search(r"public var linkedEntity:\s*LifeEntity\?", linked_block) is not None,
    )
    check(
        "linkedEntity uses @Relationship",
        "@Relationship" in linked_block,
    )
    check(
        "linkedEntity delete rule is nullify",
        ".nullify" in linked_block,
    )
    check(
        "linkedEntity initialized to nil",
        "self.linkedEntity = nil" in body,
    )
    check(
        "promoteToQuest function exists",
        bool(promote),
    )
    check(
        "promoteToQuest explicitly nullifies linkedEntity",
        "moment.linkedEntity = nil" in promote,
    )
    check(
        "linkedEntity nullify happens before save",
        promote.find("moment.linkedEntity = nil") != -1
        and promote.find("modelContext.save") != -1
        and promote.find("moment.linkedEntity = nil") < promote.find("modelContext.save"),
    )
    check(
        "LifeMoment does not relate directly to WeaveQuest",
        "WeaveQuest" not in body,
    )
    check(
        "model documents optional LifeEntity link",
        "Optional link to a corresponding LifeEntity" in body,
    )

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    print("OVERALL: PASS" if FAIL == 0 else "OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
