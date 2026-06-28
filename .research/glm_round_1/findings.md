# GLM 5.2 Round 1 — Operational Findings

## Problem

`ollama run glm-5.2:cloud` is a **pure chat endpoint**, not an agent. It has no tool/file access. When prompted to "read the files", it enters an infinite "I'll start by reading..." loop until the 5-min timeout. Total output: ~2.3 MB of repeated intro phrases, zero actual review.

**This is a fundamental CLI constraint, not a GLM 5.2 capability gap.**

## Workaround

For grounding, I must:
1. Read all relevant files myself (terminal/read_file)
2. Pass extracted content as inline prompt to GLM
3. Ask GLM to analyze the inline content (chat-completion mode)

## Output Files
- `prompt_v2.txt` — the failed prompt
- `review_v2_raw.txt` — 2.3 MB of garbage output (delete)
- `focused_review.md` — leftover from earlier attempt

## Next Step
Build a `glm_context_bundle.md` with: file list (56 Swift files with LOC), top 10 file contents, constitution, handoff doc. Then ask GLM for a one-shot review of the inline bundle.