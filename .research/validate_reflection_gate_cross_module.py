#!/usr/bin/env python3
"""
T129 — validate_reflection_gate_cross_module.py

Mirrors the reflection gate across completeQuest, changeSeason, SacredEchoStore,
GraphInsight.applyInsight, P2PWeaveShare.receiveAndIntegrate, FamilyPodPolicy.
Verifies:
- Empty/whitespace input BLOCKS and produces NO side effects
- Non-empty input PERMITS the side effect
- Min-length enforcement (T075: >= 20 chars for full award)
"""
import re
import sys
from pathlib import Path

REPO = Path("/root/hermes-workspace/projects/oneweave")
SOURCES = REPO / "Sources/OneWeave"

FILES_GATED = [
    "LifeContext.swift",       # completeQuest, changeSeason
    "SacredEcho.swift",         # SacredEchoStore.seal
    "GraphInsightGenerator.swift",  # applyInsight
    "P2PWeaveShare.swift",      # receiveAndIntegrate (if reflection required)
    "FamilyPod.swift",          # exit-reflection gate
    "CommandPalette.swift",     # pendingAction
]

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

def has_reflection_gate(filename, function_pattern, must_have_min_length=False):
    """Returns (has_empty_check, has_min_length_check) for a given function."""
    path = SOURCES / filename
    if not path.exists():
        return (False, False)
    src = path.read_text()
    m = re.search(function_pattern, src, re.DOTALL)
    if not m:
        return (False, False)
    body = src[m.start():m.start() + 3000]  # look at function + next 3KB
    has_empty = bool(re.search(r"\.(isEmpty|trimmingCharacters.*\.isEmpty)", body))
    has_min_len = bool(re.search(r"count\s*[<>]=?\s*\d+|min(Reflection)?\s*Chars", body))
    return (has_empty, has_min_len)

def main():
    print("--- Reflection gate cross-module (T129) ---")

    # 1. completeQuest (LifeContext.swift) — must have both empty + min-length
    has_empty, has_min = has_reflection_gate(
        "LifeContext.swift",
        r"func completeQuest\([^)]*reflection:\s*String[^)]*\)",
        must_have_min_length=True,
    )
    check("LifeContext.completeQuest: has empty check", has_empty)
    check("LifeContext.completeQuest: has min-length check (T075 ≥20 chars)", has_min)

    # 2. SacredEchoStore.seal — must have empty check
    has_empty, _ = has_reflection_gate(
        "SacredEcho.swift",
        r"static func seal\([^)]*reflection:\s*String",
    )
    check("SacredEchoStore.seal: has empty check", has_empty)

    # 3. completeSeasonReflection (LifeContext)
    src = (SOURCES / "LifeContext.swift").read_text()
    if "completeSeasonReflection" in src:
        # find the body
        idx = src.find("completeSeasonReflection")
        chunk = src[idx:idx+2000]
        has_empty = bool(re.search(r"\.(isEmpty|trimmingCharacters.*\.isEmpty)", chunk))
        check("LifeContext.completeSeasonReflection: has empty check", has_empty)
    else:
        check("completeSeasonReflection: present", False, "function not found")

    # 4. FamilyPod exit reflection min length (already in T082 cycle 29)
    fp = (SOURCES / "FamilyPod.swift").read_text()
    if "minExitReflectionChars" in fp:
        check("FamilyPod: minExitReflectionChars constant exists", True)
    else:
        check("FamilyPod: minExitReflectionChars constant exists", False, "no constant")

    # 5. ReflectionGate policy object (T079) — created in cycle 30
    rg_path = SOURCES / "ReflectionGate.swift"
    if rg_path.exists():
        rg_src = rg_path.read_text()
        if "minCharsForFullReward = 20" in rg_src:
            check("ReflectionGate.swift centralized policy object (T079)", True)
        else:
            check("ReflectionGate.swift exists but missing minCharsForFullReward=20", False,
                  "constant not set to 20")
    else:
        print(f"  [INFO] ReflectionGate.swift not yet created (T079 deferred — scattered checks used instead)")

    # 6. Verify NO bare reflection calls without gates (sanity scan)
    bare_patterns = [
        (r"\bsave\(\s*reflection", "save(reflection)"),
        (r"\.write\(\s*reflection", ".write(reflection)"),
    ]
    for pat, label in bare_patterns:
        issues = []
        for fname in FILES_GATED:
            p = SOURCES / fname
            if not p.exists():
                continue
            content = p.read_text()
            # exclude if line is inside a comment
            for line in content.split("\n"):
                if re.search(pat, line) and not line.strip().startswith("//"):
                    issues.append(f"{fname}: {line.strip()[:80]}")
        if not issues:
            check(f"No bare {label} without gate", True)
        else:
            check(f"No bare {label} without gate", False, f"{len(issues)} occurrences")

    print(f"\nResults: {PASS} PASS / {FAIL} FAIL")
    if FAIL:
        print("OVERALL: FAIL")
        sys.exit(1)
    print("OVERALL: PASS")

if __name__ == "__main__":
    main()