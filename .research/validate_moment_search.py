#!/usr/bin/env python3
"""validate_moment_search.py - Phase D T-D5 validator"""
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent


def check(name, condition):
    status = "PASS" if condition else "FAIL"
    print(f"  [{status}] {name}")
    return condition


def extract_search_body(src):
    match = re.search(r"public\s+static\s+func\s+search\s*\(", src)
    if not match:
        return ""
    brace_start = src.find("{", match.end())
    if brace_start == -1:
        return ""
    depth = 0
    for index in range(brace_start, len(src)):
        if src[index] == "{":
            depth += 1
        elif src[index] == "}":
            depth -= 1
            if depth == 0:
                return src[brace_start + 1:index]
    return ""


def search_python(query, moments, limit=20):
    """Mirror LifeMomentService.search() substring + Jaccard scoring."""
    trimmed = query.strip()
    if not trimmed:
        return []

    query_lower = trimmed.lower()
    query_words = set(query_lower.split(" "))
    scored = []

    for moment in moments:
        if moment.get("isSealed"):
            haystacks = [moment.get("reflection", "")]
        else:
            haystacks = [moment.get("ocr", ""), moment.get("reflection", "")]
            haystacks = [text for text in haystacks if text]

        combined = "\n".join(haystacks).lower()
        if not combined:
            continue

        if query_lower in combined:
            scored.append((moment["id"], 1.0))
            continue

        haystack_words = set(combined.split(" "))
        union = query_words | haystack_words
        jaccard = 0.0 if not union else len(query_words & haystack_words) / len(union)
        if jaccard > 0.1:
            scored.append((moment["id"], jaccard))

    scored.sort(key=lambda item: item[1], reverse=True)
    return scored[:limit]


def main():
    passed = 0
    failed = 0
    total = 0

    def t(name, cond):
        nonlocal passed, failed, total
        total += 1
        if check(name, cond):
            passed += 1
        else:
            failed += 1

    src_path = PROJECT / "Sources" / "OneWeave" / "LifeMomentService.swift"
    src = src_path.read_text() if src_path.exists() else ""
    body = extract_search_body(src)

    print("--- LifeMomentService.search() validator (T-D5) ---")

    t("search() is public static func", re.search(r"public\s+static\s+func\s+search\s*\(", src) is not None)
    t("search() takes query + modelContext + limit",
      re.search(r"search\s*\(\s*query:\s*String,\s*modelContext:\s*ModelContext,\s*limit:\s*Int\s*=\s*20", re.sub(r"\s+", " ", src)) is not None)
    t("search() returns [LifeMoment]", re.search(r"throws\s+->\s*\[LifeMoment\]\s*\{", src) is not None)
    t("search() uses FetchDescriptor<LifeMoment>", "FetchDescriptor<LifeMoment>" in body)
    t("search() checks moment.isSealed", re.search(r"if\s+moment\.isSealed\s*\{", body) is not None)
    t("search() uses .lowercased()", ".lowercased()" in body)
    t("search() trims whitespace on query", "trimmingCharacters(in: .whitespacesAndNewlines)" in body)
    t("search() sorts by score descending", ".sort { $0.1 > $1.1 }" in body)
    t("search() returns Array(scored.prefix(limit).map",
      "Array(scored.prefix(limit).map { $0.0 })" in body)
    t("search() NEVER references TimelineEvent", "TimelineEvent" not in body)
    t("search() NEVER references TimelineService", "TimelineService" not in body)
    t("search() NEVER references LifeGraph", "LifeGraph" not in body)
    t("search() returns [] for empty query",
      re.search(r"guard\s+!trimmedQuery\.isEmpty\s+else\s*\{\s*return\s*\[\]\s*\}", body) is not None)

    t("source has sealed-only reflection branch", re.search(r"if\s+moment\.isSealed\s*\{[^{}]*userReflection[^{}]*\}", body, re.DOTALL) is not None)
    t("source has unsealed OCR + reflection branch", re.search(r"else\s*\{[^{}]*ocrText[^{}]*userReflection", body, re.DOTALL) is not None)

    moments = [
        {"id": "a", "ocr": "Park walk coffee break", "reflection": "Beautiful afternoon", "isSealed": False},
        {"id": "b", "ocr": "Coffee shop notes", "reflection": "Met Sarah for coffee", "isSealed": False},
        {"id": "c", "ocr": "secret OCR text", "reflection": "Encrypted thoughts", "isSealed": True},
        {"id": "d", "ocr": "alpha beta gamma delta epsilon zeta", "reflection": "", "isSealed": False},
    ]

    t("Substring match returns score 1.0", search_python("park", moments) == [("a", 1.0)])
    t("Jaccard threshold filters unrelated matches", search_python("galaxy nebula", moments) == [])
    t("Jaccard match returns score > 0.1", 0.1 < search_python("alpha beta omega", moments)[0][1] < 1.0)
    t("Empty query returns empty list", search_python("", moments) == [])
    t("Whitespace-only query returns empty list", search_python("   \n\t", moments) == [])
    sortable = [
        {"id": "exact", "ocr": "park coffee", "reflection": "", "isSealed": False},
        {"id": "partial", "ocr": "park trail tree", "reflection": "", "isSealed": False},
    ]
    t("Multiple matches sorted by score descending",
      [item[0] for item in search_python("park coffee", sortable)] == ["exact", "partial"])
    many_moments = [{"id": str(i), "ocr": f"common text {i}", "reflection": "", "isSealed": False} for i in range(50)]
    t("limit parameter caps results", len(search_python("common", many_moments, limit=5)) == 5)
    t("Sealed moment: OCR not searchable", search_python("secret", moments) == [])
    t("Sealed moment: reflection searchable", search_python("encrypted", moments) == [("c", 1.0)])
    t("Unsealed moment: OCR searchable", search_python("park", moments) == [("a", 1.0)])
    t("Unsealed moment: reflection searchable", search_python("sarah", moments) == [("b", 1.0)])

    print(f"\nTotal: {total}  |  PASSED: {passed}  |  FAILED: {failed}")
    print("OVERALL: " + ("PASS" if failed == 0 else "FAIL"))
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
