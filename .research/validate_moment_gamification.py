#!/usr/bin/env python3
"""
Cycle 46 / T-C8: validate_moment_gamification.py

Validates that LifeMoment capture and promotion stay quiet:
  - no TimelineEvent.emit / TimelineService.emit calls
  - no essence award/spend mutations
  - no level/mastery progression mutation
  - LifeMoment has no WeaveQuest relationship at creation time
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


def grep_count(pattern: str, text: str) -> int:
    return len(re.findall(pattern, text))


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


def main() -> int:
    print("--- LifeMoment gamification silence (cycle 46 / T-C8) ---")

    service_exists = check("LifeMomentService.swift exists", SERVICE_FILE.exists())
    model_exists = check("LifeMoment.swift exists", MODEL_FILE.exists())
    service = SERVICE_FILE.read_text() if service_exists else ""
    model = MODEL_FILE.read_text() if model_exists else ""
    body = model_body(model)

    check(
        "no TimelineEvent.emit or TimelineService.emit calls",
        grep_count(r"TimelineEvent\.emit|TimelineService\.emit", service) == 0,
    )
    check(
        "no weaveEssence / awardEssence / spendEssence references",
        grep_count(r"weaveEssence|awardEssence|spendEssence", service) == 0,
    )
    check(
        "no level / masteryTier progression references",
        grep_count(r"\blevel\b|masteryTier", service) == 0,
    )
    check(
        "capture() persists LifeMoment directly",
        "modelContext.insert(moment)" in service and "LifeMoment(userReflection:" in service,
    )
    check(
        "capture() returns LifeMoment without timeline side effect",
        re.search(r"public static func capture\([\s\S]*?\)\s+async throws -> LifeMoment", service) is not None,
    )
    check(
        "attachToThread does not emit timeline events",
        "Silent: user already chose the thread" in service
        and "TimelineEvent.emit" not in service,
    )
    check(
        "promoteToQuest uses baseEssence zero",
        re.search(r"baseEssence\s*:\s*0", service) is not None,
    )
    check(
        "LifeMoment model has no WeaveQuest property",
        "WeaveQuest" not in body,
    )
    check(
        "LifeMoment @Relationship declarations do not target WeaveQuest",
        not re.search(r"@Relationship[\s\S]{0,160}WeaveQuest", body),
    )
    check(
        "promotion to quest happens only in service promoteToQuest",
        "promoteToQuest" in service and "WeaveQuest(" in service and "WeaveQuest" not in body,
    )

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    print("OVERALL: PASS" if FAIL == 0 else "OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
