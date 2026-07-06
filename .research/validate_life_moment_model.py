#!/usr/bin/env python3
"""
Cycle 46 / T-A6: validate_life_moment_model.py

Validates the LifeMoment @Model schema: all required fields, types, defaults,
relationships, and Claude review fixes (whitespace-trim isUserReflection,
plain sourceCaptureAsset not @Relationship, sealed ciphertext/nonce/tag fields).

Mirrors the static structure of Sources/OneWeave/LifeMoment.swift and verifies
it against the spec (CYCLE46_LIFEMOMENT_SPEC.md / 046-lifemoment/spec.md).
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
    print("--- LifeMoment @Model schema (cycle 46 / T-A6) ---")

    if not MODEL_FILE.exists():
        check("LifeMoment.swift exists", False, f"missing: {MODEL_FILE}")
        print("OVERALL: FAIL")
        return 1

    src = MODEL_FILE.read_text()

    # 1. @Model class definition
    check(
        "@Model class LifeMoment exists",
        bool(re.search(r"@Model\s*\npublic final class LifeMoment", src)),
    )

    # 2. Identity fields
    check("id: UUID unique",
          bool(re.search(r"@Attribute\(\.unique\)\s*public var id:\s*UUID", src)))
    check("createdAt: Date", "public var createdAt: Date" in src)
    check("modifiedAt: Date", "public var modifiedAt: Date" in src)

    # 3. User-authored fields (the ONLY ones that may cross entity boundary)
    check("userReflection: String?", "public var userReflection: String?" in src)
    check("momentKindRaw: String?", "public var momentKindRaw: String?" in src)
    check("userAssignedThreadRaw: String?", "public var userAssignedThreadRaw: String?" in src)

    # 4. Vision pipeline output fields (NEVER cross — Invariant 11)
    check("ocrText: String?", "public var ocrText: String?" in src)
    check("ocrConfidence: Double?", "public var ocrConfidence: Double?" in src)
    check("detectedEntitiesJSON: String?", "public var detectedEntitiesJSON: String?" in src)

    # 5. Claude SPEC-9 fix: imageEmbedding is OCR-text embed (not image)
    check(
        "imageEmbeddingText stored via @Attribute(.externalStorage)",
        bool(re.search(
            r"@Attribute\(\.externalStorage\)\s*public var imageEmbeddingText:\s*Data\?",
            src,
        )),
    )

    # 6. Claude SPEC-2 fix: sealed storage fields
    check("sealedCiphertext: Data?", "public var sealedCiphertext: Data?" in src)
    check("sealedNonce: Data?", "public var sealedNonce: Data?" in src)
    check("sealedTag: Data?", "public var sealedTag: Data?" in src)
    check("sealedAt: Date?", "public var sealedAt: Date?" in src)
    check("cipherHKDFInfo: String?", "public var cipherHKDFInfo: String?" in src)
    check('cipherHKDFInfo = "OneWeaveMoment.v1"', '"OneWeaveMoment.v1"' in src)

    # 7. isUserReflection privacy gate (Claude SPEC-12)
    check("isUserReflection: Bool", "public var isUserReflection: Bool" in src)
    check(
        "isNonEmptyReflection helper exists",
        bool(re.search(r"static func isNonEmptyReflection\s*\([^)]*\)\s*->\s*Bool", src)),
    )
    check(
        "isNonEmptyReflection uses trimmingCharacters(in: .whitespacesAndNewlines)",
        "trimmingCharacters(in: .whitespacesAndNewlines)" in src,
    )

    # 8. Claude SPEC-8 fix: sourceCaptureAsset is plain String?, NOT @Relationship
    # Check the exact field declaration (allows comment references elsewhere).
    src_field_match = re.search(
        r"^\s+public var sourceCaptureAsset:\s*String\?\s*$",
        src,
        re.MULTILINE,
    )
    check("sourceCaptureAsset: String? declaration exists", src_field_match is not None)
    if src_field_match is not None:
        # The line containing the declaration must NOT have @Relationship.
        line_start = src.rfind("\n", 0, src_field_match.start()) + 1
        line_end = src.find("\n", src_field_match.end())
        if line_end == -1:
            line_end = len(src)
        decl_block = src[line_start:line_end]
        check(
            "sourceCaptureAsset declaration has no @Relationship attribute",
            "@Relationship" not in decl_block,
        )

    # 9. linkedEntity IS a @Relationship
    check(
        "linkedEntity: LifeEntity? with @Relationship(.nullify)",
        bool(re.search(
            r"@Relationship\(deleteRule:\s*\.nullify\)\s*public var linkedEntity:\s*LifeEntity\?",
            src,
        )),
    )

    # 10. Typed errors enum exists
    check("LifeMomentError enum exists",
          "enum LifeMomentError" in src and "Error, LocalizedError" in src)
    check("LifeMomentError.photosDisabled case", "case photosDisabled" in src)
    check("LifeMomentError.imageTooLarge case", "case imageTooLarge" in src)
    check("LifeMomentError.emptyReflection case", "case emptyReflection" in src)
    check("LifeMomentError.cipherMissingKey case", "case cipherMissingKey" in src)

    # 11. MomentKind enum (taxonomy)
    check("MomentKind enum exists", "enum MomentKind" in src)
    for case in ["memory", "receipt", "inspiration", "reference", "unsorted"]:
        check(f"MomentKind.{case} case", f"case {case}" in src)

    # 12. MomentThreadAssignment enum (the 4 Threads)
    check("MomentThreadAssignment enum exists", "enum MomentThreadAssignment" in src)
    for case in ["basicSelf", "stewardship", "careKin", "meaning"]:
        check(f"MomentThreadAssignment.{case} case", f"case {case}" in src)

    # 13. Init default args
    check("init(userReflection: String? = nil)",
          "public init(userReflection: String? = nil)" in src)

    # 14. Helper methods exist
    check("isAttachedToThread computed prop", "var isAttachedToThread: Bool" in src)
    check("hasInferredContent computed prop", "var hasInferredContent: Bool" in src)
    check("setUserReflection(_:) method", "func setUserReflection(_ text: String?)" in src)

    # 15. Constitutional anchor in header comment
    check("File header references Principle 8", "Principle 8" in src)
    check("File header references Invariant 11", "Invariant 11" in src)

    print()
    print(f"Total: {PASS + FAIL} | PASSED: {PASS} | FAILED: {FAIL}")
    if FAIL == 0:
        print("OVERALL: PASS")
    else:
        print("OVERALL: FAIL")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())