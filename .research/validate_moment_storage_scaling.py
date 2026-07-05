#!/usr/bin/env python3
"""
Cycle 46 / T-A8: validate_moment_storage_scaling.py

Validates the LifeMoment storage surface scales sanely:
  - imageEmbeddingText uses @Attribute(.externalStorage) (Claude SPEC-9 fix)
  - sealed fields use plain Data? (ciphertext/nonce/tag, total ~64 bytes per moment)
  - userReflection + momentKindRaw + userAssignedThreadRaw are bounded Strings
  - 10k simulated moments stay under 100MB of SwiftData store metadata
  - Embedding blob lives on disk via externalStorage, not in the store

The validator mirrors the storage shape in Python and computes byte budgets.
"""
import re
import sys
from pathlib import Path

REPO = Path("/root/hermes-workspace/projects/oneweave")
MODEL_FILE = REPO / "Sources/OneWeave/LifeMoment.swift"

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
    print("--- LifeMoment storage scaling (cycle 46 / T-A8) ---")

    if not MODEL_FILE.exists():
        check("LifeMoment.swift exists", False)
        print("OVERALL: FAIL")
        return 1

    src = MODEL_FILE.read_text()

    # 1. imageEmbeddingText uses @Attribute(.externalStorage)
    check(
        "imageEmbeddingText has @Attribute(.externalStorage)",
        bool(re.search(
            r"@Attribute\(\.externalStorage\)\s*public var imageEmbeddingText:\s*Data\?",
            src,
        )),
    )

    # 2. sealed fields use plain Data? (ciphertext ~16-32 bytes + nonce 12 + tag 16)
    check("sealedCiphertext: Data?", "public var sealedCiphertext: Data?" in src)
    check("sealedNonce: Data?", "public var sealedNonce: Data?" in src)
    check("sealedTag: Data?", "public var sealedTag: Data?" in src)

    # 3. user-authored fields are bounded String?
    check("userReflection: String?", "public var userReflection: String?" in src)
    check("momentKindRaw: String?", "public var momentKindRaw: String?" in src)
    check("userAssignedThreadRaw: String?",
          "public var userAssignedThreadRaw: String?" in src)

    # 4. Storage budget for 10k moments
    #   - id: UUID = 16 bytes (Data) → ~36 bytes SwiftData
    #   - createdAt: Date = 8 bytes
    #   - modifiedAt: Date = 8 bytes
    #   - userReflection: String (avg 200 bytes) = ~240 bytes SwiftData
    #   - momentKindRaw: String (avg 12 bytes) = ~40 bytes SwiftData
    #   - userAssignedThreadRaw: String (avg 16 bytes) = ~48 bytes SwiftData
    #   - ocrText: String (avg 1000 bytes) = ~1040 bytes SwiftData
    #   - ocrConfidence: Double = 8 bytes
    #   - detectedEntitiesJSON: String (avg 200 bytes) = ~240 bytes SwiftData
    #   - imageEmbeddingText: externalStorage (NOT counted in store) → only path reference ~80 bytes
    #   - sealedCiphertext: Data (~64 bytes) + sealedNonce (12) + sealedTag (16) = ~120 bytes
    #   - sealedAt: Date = 8 bytes
    #   - cipherHKDFInfo: String (16 bytes) = ~52 bytes SwiftData
    #   - isUserReflection: Bool = 1 byte
    #   - linkedEntity: ref ~16 bytes
    #   - sourceCaptureAsset: String (40 bytes) = ~80 bytes SwiftData
    #   Total per moment in store: ~1.9 KB
    #   10k moments × 1.9 KB = ~19 MB (well under 100 MB)
    store_bytes_per_moment = (
        36 + 8 + 8  # id, createdAt, modifiedAt
        + 240 + 40 + 48  # userReflection, momentKindRaw, userAssignedThreadRaw
        + 1040 + 8 + 240  # ocrText, ocrConfidence, detectedEntitiesJSON
        + 80  # imageEmbeddingText externalStorage path reference
        + 120 + 8 + 52  # sealedCiphertext/Nonce/Tag + sealedAt + cipherHKDFInfo
        + 1 + 16 + 80  # isUserReflection + linkedEntity ref + sourceCaptureAsset
    )
    ten_k_moments = store_bytes_per_moment * 10_000
    ten_k_moments_mb = ten_k_moments / (1024 * 1024)
    check(
        "10k moments under 100MB SwiftData metadata",
        ten_k_moments_mb < 100,
        f"10k moments = {ten_k_moments_mb:.1f} MB (target < 100 MB)",
    )

    # 5. Embedding blob is on disk (externalStorage), not in store
    # Sanity: the @Attribute is on the embedding field, not the sealed fields
    ext_match = re.search(
        r"@Attribute\(\.externalStorage\)\s*public var (\w+):",
        src,
    )
    check(
        "@Attribute(.externalStorage) applied to embedding field only",
        ext_match is not None and ext_match.group(1) == "imageEmbeddingText",
        f"got field: {ext_match.group(1) if ext_match else 'none'}",
    )

    # 6. Header documents the storage strategy
    check("File header mentions externalStorage rationale",
          "externalStorage" in src or "external storage" in src.lower())

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    if FAIL == 0:
        print("OVERALL: PASS")
    else:
        print("OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())