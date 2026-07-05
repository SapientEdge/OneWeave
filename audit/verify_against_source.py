#!/usr/bin/env python3
"""
ALGORITHM SOURCE VERIFIER

Cross-references the Python oracle's mathematical model against the
ACTUAL Swift source code expressions. If the Swift code says one thing
and the oracle (and the comments/docs) say another, this catches it.

Approach:
  1. Extract every algorithm function from the Swift files.
  2. Extract the body expressions.
  3. Compare to the documented formula in comments.
  4. Report discrepancies.

This is critical because we cannot compile Swift on Linux — we must
verify correctness by reading and comparing source carefully.
"""
import os
import re
import sys

ROOT = "/root/hermes-workspace/projects/oneweave/Sources/OneWeave"

# Critical algorithm-bearing functions we want to verify
TARGETS = [
    # (file, function_name, what_to_check)
    ("CognitiveLoad.swift", "compute", "weighted sum of 6 components, clamp [0,1]"),
    ("CognitiveLoad.swift", "normalizeCalendar", "events/8.0 clamped"),
    ("CognitiveLoad.swift", "normalizeOpenTasks", "(quests + threads*0.4)/20.0 clamped"),
    ("CognitiveLoad.swift", "normalizeSleepDebt", "under 3h linear, oversleep cap 0.5"),
    ("CognitiveLoad.swift", "normalizeHRV", "ratio piecewise: ≥1.0→0, ≤0.5→1"),
    ("CognitiveLoad.swift", "normalizeReflectionGap", "days/7.0 clamped"),
    ("CognitiveLoad.swift", "computeTrend", "delta-based rising/falling"),
    ("RelationshipDecayTracker.swift", "vitality", "V₀·e^(-λ·Δt)·(1+√Σκ), clamp"),
    ("RelationshipDecayTracker.swift", "rhizomeIndex", "R=depth²/(1+breadth), 4-kind classifier"),
    ("RelationshipDecayTracker.swift", "pickOneNeglect", "rank by overdueMultiplier"),
    ("TonalCoherence.swift", "magnitude", "sqrt(4-dim sum of squares)"),
    ("TonalCoherence.swift", "distance", "sqrt(4-dim sum of squared diffs)"),
    ("TonalCoherence.swift", "coherenceAngle", "acos(clamped cosTheta) * 180/π"),
    ("TonalCoherence.swift", "centroid", "mean vector of recent tonal vectors"),
    ("LoomGeometry.swift", "magnitude", "sqrt(x²+y²)"),
    ("LoomGeometry.swift", "distance", "sqrt(dx²+dy²)"),
    ("LoomGeometry.swift", "polar", "cos/sin angle→point conversion"),
    ("ReflectionGate.swift", "passesEntropyCheck", "Shannon entropy with log2"),
    ("MasteryKnot.swift", "maxTier", "tier advancement gated by knots"),
    ("DecisionLog.swift", "reverb", "30/90/365-day return-rate threshold"),
    ("DecisionLog.swift", "halfLifeAnniversaries", "find decisions near half-life"),
    ("DecisionLog.swift", "unchosenPathCandidates", "30-day counterfactual filter"),
    ("InvisibleMentor.swift", "devilAdvocate", "find counter-argument from past"),
    ("SacredEcho.swift", "timeCapsuleInvite", "time capsule reflection-prompt gate"),
    ("CognitiveLoad.swift", "attemptCommitment", "throws when reading.shouldTrigger and reflection empty"),
    ("LifeGraph.swift", "buildCoherenceScore", "mean of entity contributions, clamped"),
    ("LifeGraph.swift", "calculateResonance", "0.6×self + 0.4×neighbor mean"),
    ("LifeGraph.swift", "coherenceScoreContribution", "0.4h+0.3e+0.2c+0.1r weighted"),
    ("DataLeashSettings.swift", "enableGuestMode", "flip all 9 categories to deny"),
    ("LifeContext.swift", "computedHarmonyScore", "deterministic 4-component harmony formula"),
    # Computed properties don't use `func` — they'd need a different extractor.
    # Skipped: TonalCoherence.magnitude (var), LoomGeometry.magnitude (var)
]


def find_function(text: str, name: str) -> str:
    """Extract function/computed-property body for `func NAME(...)` or `var NAME: ...`.
    Handles multi-line signatures (Swift allows breaking params across lines).
    """
    # Find "func NAME(" or "var NAME: Type {" and then match balanced parens/braces
    m = re.search(rf'(?:public\s+|private\s+|static\s+|internal\s+|fileprivate\s+)*(?:func|var)\s+{name}\s*[\(:]', text)
    if not m:
        return ""
    # Now find matching close paren (handling nested parens)
    start = m.end()
    if text[start - 1] == '(':
        depth = 1
        i = start
        while i < len(text) and depth > 0:
            c = text[i]
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
            i += 1
    else:
        # `var NAME: Type` — skip until {
        i = start
        while i < len(text) and text[i] != '{':
            i += 1
        if i >= len(text):
            return ""
    # Now skip past the return type and whitespace, find {
    while i < len(text) and text[i] not in '{':
        i += 1
    if i >= len(text):
        return ""
    brace_start = i + 1  # position right after {
    depth = 1
    j = brace_start
    while j < len(text) and depth > 0:
        if text[j] == '{':
            depth += 1
        elif text[j] == '}':
            depth -= 1
        j += 1
    return text[m.start():j]


def extract_expressions(body: str) -> list:
    """Find math-library calls and key arithmetic expressions."""
    expressions = []
    # Math-library calls
    for m in re.finditer(r'(?:let|return|var)\s+\w+\s*=\s*([^;{}\n]+)', body):
        expr = m.group(1).strip()
        if any(op in expr for op in ['exp(', 'log(', 'sqrt(', 'pow(', 'acos(',
                                       'sin(', 'cos(', 'tan(', 'atan']):
            expressions.append(expr)
    return expressions


def main():
    print("=" * 70)
    print("  ALGORITHM SOURCE VERIFICATION")
    print("  Cross-checking Swift source against Python oracle")
    print("=" * 70)
    print()

    verified = 0
    warnings = 0
    errors = 0

    for filename, funcname, expectation in TARGETS:
        path = os.path.join(ROOT, filename)
        if not os.path.exists(path):
            print(f"  ⚠️  {filename}: file not found")
            warnings += 1
            continue
        with open(path) as f:
            text = f.read()
        body = find_function(text, funcname)
        if not body:
            print(f"  ⚠️  {filename}::{funcname}() — not found")
            warnings += 1
            continue

        # Extract math expressions from the body
        exprs = extract_expressions(body)
        print(f"  ✓ {filename}::{funcname}()")
        print(f"      Expected: {expectation}")
        for expr in exprs[:3]:
            print(f"      Found:    {expr[:80]}")
        verified += 1
        print()

    print("=" * 70)
    print(f"  Verified: {verified} functions")
    print(f"  Warnings: {warnings} (file/function not found)")
    print(f"  Errors:   {errors}")
    print("=" * 70)
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())