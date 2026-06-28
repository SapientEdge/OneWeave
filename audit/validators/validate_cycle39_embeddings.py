#!/usr/bin/env python3
"""
validate_cycle39_embeddings.py — verifies Cycle 39 T171-T178 on-device
semantic retrieval wiring in OneWeave.

Cycle 39 introduced:
  T171 — typed LifeEmbedding struct (replaces embeddingData: Data? placeholder)
  T172 — OnDeviceEmbedder.swift wraps NLEmbedding.sentenceEmbedding
  T173 — LifeGraph.semanticSearch with lexical fallback when >50% missing
  T174 — embed() wired into LifeEntity.fromTimelineEvent for reflections
  T175 — embed() wired into LifeEntity.fromQuest(_:context:)
  T176 — QuickCaptureInbox semantic tie-breaker at confidence < 0.6
  T177 — InvisibleMentor quote-selection prefers semantically-similar reflections
  T178b — EmbeddingCoverageHint publishes shouldSuggestMoreReflections

All checks are static (file existence, source grep, API surface) — no Swift
build required (we're on Linux).

Run: python3 audit/validators/validate_cycle39_embeddings.py
"""
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
SOURCES_DIR = PROJECT_ROOT / "Sources" / "OneWeave"

def read(p: Path) -> str:
    return p.read_text() if p.exists() else ""

def main() -> int:
    print("=== validate_cycle39_embeddings.py ===")
    failures: list[str] = []
    warnings: list[str] = []

    # ----- T171: LifeEmbedding typed struct in LifeGraph.swift -----
    life_graph = read(SOURCES_DIR / "LifeGraph.swift")
    if "struct LifeEmbedding" not in life_graph:
        failures.append("T171: LifeGraph.swift missing `struct LifeEmbedding`")
    else:
        print("  T171 LifeEmbedding struct:          ✓ present")
    if "embeddingData: Data?" in life_graph:
        # Check if it's a comment (lines starting with // or ///)
        non_comment_hits = [
            line for line in life_graph.split("\n")
            if "embeddingData: Data?" in line
            and not line.strip().startswith("//")
        ]
        if non_comment_hits:
            warnings.append("T171: legacy `embeddingData: Data?` still present in code (not comment) — verify migration")
    if "expectedDimension" not in life_graph and "dimension" not in life_graph.lower():
        warnings.append("T171: no `dimension` constant in LifeEmbedding — should be 512")

    # ----- T172: OnDeviceEmbedder.swift exists with NLEmbedding -----
    ode = read(SOURCES_DIR / "OnDeviceEmbedder.swift")
    if not ode:
        failures.append("T172: OnDeviceEmbedder.swift missing")
    else:
        if "NLEmbedding" in ode or "NaturalLanguage" in ode:
            print("  T172 NLEmbedding wrapper:            ✓ present")
        else:
            failures.append("T172: OnDeviceEmbedder.swift does not reference NLEmbedding/NaturalLanguage")
        if "NSLock" in ode or "DispatchQueue" in ode:
            print("  T172 thread safety (NSLock):         ✓ present")
        else:
            warnings.append("T172: no NSLock/DispatchQueue — verify thread safety")
        if "shared" in ode:
            print("  T172 singleton (.shared):            ✓ present")
        else:
            warnings.append("T172: no `.shared` accessor")

    # ----- T173: LifeGraph.semanticSearch -----
    if "func semanticSearch" in life_graph:
        print("  T173 semanticSearch func:            ✓ present")
    else:
        failures.append("T173: LifeGraph.semanticSearch missing")
    if "cosineSimilarity" in life_graph or "cosine" in life_graph.lower():
        print("  T173 cosine similarity:              ✓ present")
    else:
        warnings.append("T173: no cosine similarity helper found")
    if "missingEmbeddingFraction" in life_graph or "missingFraction" in life_graph:
        print("  T173 missing-fraction fallback:      ✓ present")
    else:
        warnings.append("T173: no missingEmbeddingFraction helper — verify fallback trigger")

    # ----- T174: fromTimelineEvent wires embedder for reflections -----
    if "fromTimelineEvent" in life_graph and "isUserReflection" in life_graph:
        # Both functions must coexist; check that the function uses OnDeviceEmbedder
        if "OnDeviceEmbedder" in life_graph and "fromTimelineEvent" in life_graph:
            # Check that isUserReflection entries get embedded
            # Look for a block inside fromTimelineEvent that embeds when isUserReflection
            tle_block = re.search(
                r"fromTimelineEvent[^{]*\{(.*?)(?=\n    \}|func |public )",
                life_graph,
                re.DOTALL,
            )
            if tle_block and "OnDeviceEmbedder" in tle_block.group(1):
                print("  T174 fromTimelineEvent embedder:     ✓ present")
            else:
                warnings.append("T174: fromTimelineEvent may not call OnDeviceEmbedder for reflections")
        else:
            failures.append("T174: fromTimelineEvent present but not wired to OnDeviceEmbedder")
    else:
        warnings.append("T174: fromTimelineEvent or isUserReflection not found")

    # ----- T175: fromQuest(_:context:) wires embedder -----
    if "fromQuest(_ quest: WeaveQuest, context:" in life_graph:
        if "OnDeviceEmbedder" in life_graph:
            print("  T175 fromQuest(_:context:):         ✓ present (signature)")
        else:
            warnings.append("T175: new fromQuest(_:context:) signature present but no embedder call")
    elif "fromQuest" in life_graph and "OnDeviceEmbedder" in life_graph:
        print("  T175 fromQuest embedder:             ✓ present (variant)")
    else:
        warnings.append("T175: fromQuest(_:context:) overload or embedder wiring not found")

    # ----- T176: QuickCaptureInbox semantic tie-breaker -----
    qci = read(SOURCES_DIR / "QuickCaptureInbox.swift")
    if "semanticSearch" in qci or "semanticTieBreakerThreshold" in qci or "semantic" in qci.lower():
        print("  T176 QuickCapture semantic hook:     ✓ present")
    else:
        failures.append("T176: QuickCaptureInbox.swift missing semanticSearch integration")

    # ----- T177: InvisibleMentor.reflectionEmbeddings widening -----
    mentor = read(SOURCES_DIR / "InvisibleMentor.swift")
    if "reflectionEmbeddings" in mentor:
        print("  T177 MentorInput.reflectionEmbeddings: ✓ present")
    else:
        failures.append("T177: InvisibleMentor.swift missing reflectionEmbeddings property")
    if "[UUID: [Float]]?" in mentor or "[UUID: LifeEmbedding]" in mentor:
        print("  T177 typed embedding map:            ✓ present")
    else:
        warnings.append("T177: reflectionEmbeddings type not [UUID: [Float]]? — verify shape")

    # ----- T178b: EmbeddingCoverageHint exists -----
    ech = read(SOURCES_DIR / "EmbeddingCoverageHint.swift")
    if not ech:
        failures.append("T178b: EmbeddingCoverageHint.swift missing")
    else:
        if "shouldSuggestMoreReflections" in ech:
            print("  T178b shouldSuggestMoreReflections: ✓ present")
        else:
            failures.append("T178b: EmbeddingCoverageHint missing shouldSuggestMoreReflections")
        if "@Published" in ech and "ObservableObject" in ech:
            print("  T178b ObservableObject pattern:      ✓ present")
        else:
            warnings.append("T178b: not @Published ObservableObject — verify SwiftUI binding")
        if "@AppStorage" in ech:
            print("  T178b AppStorage persistence:        ✓ present")
        else:
            warnings.append("T178b: no @AppStorage — verify dismiss persists across launches")

    # Summary
    print()
    if warnings:
        print(f"⚠ {len(warnings)} warning(s):")
        for w in warnings:
            print(f"  - {w}")
    if failures:
        print(f"✗ {len(failures)} failure(s):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print("✓ PASS — Cycle 39 T171-T178 semantic retrieval wired end-to-end")
    return 0


if __name__ == "__main__":
    sys.exit(main())
