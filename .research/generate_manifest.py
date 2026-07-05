#!/usr/bin/env python3
"""
generate_manifest.py — Regenerate MANIFEST.md from current sources.

Run: python3 .research/generate_manifest.py
"""
import os
import re
import sys
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent


def extract_swift_purpose(path: Path) -> str:
    """Extract the description from a Swift file.

    Strategy: walk the first 25 lines; gather any `//` comment lines
    plus the first non-comment, non-blank, non-import, non-brace line
    (which is often the type declaration, e.g. 'public final class X').
    """
    try:
        text = path.read_text()
    except Exception:
        return ""
    comment_lines = []
    for raw in text.splitlines()[:30]:
        s = raw.strip()
        if s.startswith("//"):
            stripped = s.lstrip("/").strip()
            if stripped and not stripped.startswith("!"):
                comment_lines.append(stripped)
            if len(comment_lines) >= 3:
                break
        elif s.startswith("import "):
            continue
        elif s.startswith("@") or s.startswith("public ") or s.startswith("internal ") or s.startswith("private "):
            # Type declaration line — include if it's descriptive.
            comment_lines.append(s)
            break
        elif s == "":
            continue
        else:
            break
    desc = " ".join(comment_lines).strip()
    # Strip the filename prefix if it's just the bare filename.
    desc = re.sub(r"^[A-Z][A-Za-z]+\.swift\s*", "", desc)
    desc = desc.replace("|", "\\|").replace("`", "\\`")
    return desc[:200]


def extract_python_purpose(path: Path) -> str:
    """Extract the first docstring line from a Python file."""
    try:
        text = path.read_text()
    except Exception:
        return ""
    match = re.search(r'^\s*"""(.*?)"""', text, re.DOTALL)
    if match:
        first_line = match.group(1).strip().split("\n")[0].strip()
        first_line = first_line.lstrip("#").strip()
        first_line = first_line.replace("|", "\\|").replace("`", "\\`")
        return first_line[:200]
    return ""


def extract_md_purpose(path: Path) -> str:
    """Extract the title from a Markdown file."""
    try:
        text = path.read_text()
    except Exception:
        return ""
    for raw in text.splitlines():
        if raw.startswith("# "):
            return raw.lstrip("# ").strip()[:200]
    return ""


def main() -> int:
    swift_files = sorted((ROOT / "Sources").rglob("*.swift"))
    py_files = sorted((ROOT / ".research").glob("*.py"))
    md_files = sorted((ROOT / ".research").glob("*.md"))
    top_files = ["README.md", "ARCHITECTURE.md", "PRIVACY.md",
                 "CONTRIBUTING.md", "CLAUDE_COWORK_BRIEF.md",
                 "LICENSE", ".gitignore"]

    out = []
    out.append("# OneWeave MANIFEST")
    out.append("")
    out.append("Every file in this repository, with line count and one-line purpose.")
    out.append("Generated automatically; do not edit by hand. Regenerate with:")
    out.append("")
    out.append("```bash")
    out.append("python3 .research/generate_manifest.py")
    out.append("```")
    out.append("")
    out.append("## Sources/OneWeave/ (Swift, the app module)")
    out.append("")
    out.append("| File | Lines | Purpose |")
    out.append("|------|------:|---------|")
    for f in swift_files:
        rel = f.relative_to(ROOT)
        lines = sum(1 for _ in f.open())
        purpose = extract_swift_purpose(f)
        out.append(f"| `{rel}` | {lines} | {purpose} |")

    out.append("")
    out.append("## .research/ (validation harness + design docs)")
    out.append("")
    out.append("| File | Lines | Purpose |")
    out.append("|------|------:|---------|")
    for f in py_files:
        rel = f.relative_to(ROOT)
        lines = sum(1 for _ in f.open())
        purpose = extract_python_purpose(f)
        out.append(f"| `{rel}` | {lines} | {purpose} |")
    for f in md_files:
        rel = f.relative_to(ROOT)
        lines = sum(1 for _ in f.open())
        purpose = extract_md_purpose(f)
        out.append(f"| `{rel}` | {lines} | {purpose} |")

    out.append("")
    out.append("## Top-level docs")
    out.append("")
    out.append("| File | Lines | Purpose |")
    out.append("|------|------:|---------|")
    for fname in top_files:
        f = ROOT / fname
        if f.exists():
            rel = f.relative_to(ROOT)
            lines = sum(1 for _ in f.open())
            purpose = extract_md_purpose(f) if fname.endswith(".md") else "(license / config)"
            out.append(f"| `{rel}` | {lines} | {purpose} |")

    out.append("")
    out.append("## Stats")
    out.append("")
    total_swift = sum(sum(1 for _ in f.open()) for f in swift_files)
    total_python = sum(sum(1 for _ in f.open()) for f in py_files)
    out.append(f"- **Swift total:** {total_swift:,} lines across {len(swift_files)} files")
    out.append(f"- **Python validation:** {total_python:,} lines across {len(py_files)} suites")
    out.append("")
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    out.append(f"Last regenerated: {now}")

    target = ROOT / "MANIFEST.md"
    target.write_text("\n".join(out) + "\n")
    print(f"Wrote MANIFEST.md ({sum(1 for _ in target.open())} lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())