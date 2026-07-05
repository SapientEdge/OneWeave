# Cycle 48 Handoff — D + E + G (codex profiling, 3-task batches, skill squad)

**Cycle:** 048-subagent-quality
**Branch:** `048-subagent-quality`
**Date:** 2026-07-05
**Outcome:** Mixed — useful work salvaged from blocked sub-agents, real new lesson captured.

---

## TL;DR

3 parallel sub-agents were dispatched to work on Q1 (codex CLI profiling), Q2 (3-task batches), Q3 (skill squad). All 3 hit the same **sandbox blocker**: codex's bash sandbox restricts writes to `workdir + /tmp`, so sub-agents cannot write to `~/.hermes/` (the Hermes-global location).

All 3 sub-agents were **honest** (Lesson 35.5): they did not fabricate. They built their work in `/tmp/` and explicitly reported the blocker.

Salvage plan executed:
- Q1 + Q2 artifacts copied to `scripts/cycle48/` (project-local, can be written by sub-agents)
- Q3 skills manually written to `~/.hermes/skills/` (this requires human, not sub-agent)
- New **Lesson 36** captured: "codex bash sandbox blocks writes to `~/.hermes/`. Sub-agents can only write to `workdir + /tmp`."

---

## Q1 — Codex CLI profiling

**Sub-agent:** Sub-agent 48-Q1 (deleg_xxx, exit code 0, 367s)
**Result:** INCONCLUSIVE in this sandbox, but produced a working profiler.

**Salvaged artifacts** (in `scripts/cycle48/`):
- `codex_profiler.py` (74 lines, stdlib only) — wraps `codex exec` and records per-phase timing
- `codex_baseline_runs.json` — failed-run measurements (network blocked)
- `codex_overhead_comparison.json` — LLM vs echo-only comparison
- `codex_cli_profile.md` — full report with timing breakdown
- `codex_profile.jsonl` — JSONL log of measurements

**Findings:**
- Codex CLI cold-start (workdir + banner): **~0.18s** consistently (5 prompts)
- First-content line (after "Reading prompt from stdin"): **~0.19s** consistently
- **All runs failed with `failed to initialize in-process app-server client: Read-only file system` or `Operation not permitted` (network)** — sandbox blocked real measurement

**Conclusion:** Cannot isolate codex CLI overhead from LLM round-trip in this sandbox. The cycle 47 baseline (5–40s) likely includes both. Valid measurement requires writable `~/.hermes/` + network access.

---

## Q2 — 3-task batch validation

**Sub-agent:** Sub-agent 48-Q2 (deleg_xxx, exit code 0, 219s)
**Result:** INCONCLUSIVE — same sandbox blocker, all 8 batches failed before task execution.

**Salvaged artifacts** (in `scripts/cycle48/`):
- `batch_prompt_template.txt` (655 bytes) — reusable template
- `three_task_batch_report.md` (3518 bytes) — full per-batch results table
- `batch_manifest.json` — 8 batch descriptors

**Findings:**
- 8/8 supervisor launches succeeded
- 0/8 reached task execution (codex exited before running)
- All 8 ran in ~0.1s (codex rejected immediately)
- Network blocked + read-only home

**Conclusion:** Cannot recommend updating Lesson 2/28 from "≤2 tasks" → "≤3 tasks" without a working sandbox. Re-test under writable `~/.hermes/`.

---

## Q3 — Sub-agent skill squad

**Sub-agent:** Sub-agent 48-Q3 (deleg_xxx, exit code 0, 54s)
**Result:** BLOCKED by sandbox; manually completed (this handoff) per salvage plan.

**What was done (manually, not by sub-agent):**
- 3 new skills written to `~/.hermes/skills/`:
  - `subagent-launcher/SKILL.md` — when/how to launch sub-agents
  - `subagent-batch-splitter/SKILL.md` — when to split work into 1/2/3-task batches (uses cycle 48 Q2 data when available)
  - `subagent-marker-discipline/SKILL.md` — where to put marker.py calls in prompts
- 1 existing skill patched:
  - `subagent-hung-vs-done-check/SKILL.md` — added "Squad context" + decision tree branches
- 1 squad index doc written:
  - `subagent-squad/README.md` — squad composition + workflow diagram

---

## New Lesson 36 — codex bash sandbox write restrictions

**Symptom:** Sub-agents can read but not write to `~/.hermes/`, `/opt/`, or any other system path. Writes only allowed to `workdir` (the project root) and `/tmp`.

**Cause:** codex CLI's bash sandbox (`sandbox: workspace-write [workdir, /tmp, $TMPDIR]`) restricts where shell commands can write. This is a security feature, not a bug.

**Implication for cycle 48+:**
- All sub-agent output that needs to be in Hermes-global (`~/.hermes/skills/`, `~/.hermes/scripts/`) MUST be:
  1. Written to project-local path first (e.g. `scripts/cycle48/`)
  2. Then manually copied to `~/.hermes/` by a human OR by a follow-up step outside the sandbox
- OR: run sub-agents outside the sandbox (no current method without bypassing codex CLI security)

**Workaround (cycle 48 used):**
1. Sub-agents write everything to `workdir` (project dir) or `/tmp/`
2. After sub-agent completes, human (or non-sandbox script) copies artifacts to `~/.hermes/`

**Alternative:** Build a wrapper script that runs AFTER sub-agent completion to do the `cp ~/.hermes/ <artifact>` step. This is the natural follow-up to cycle 48.

---

## What's salvageable vs what needs re-running

| Q | Salvageable as-is | Needs re-running under writable `~/.hermes` |
|---|---|---|
| Q1 | codex_profiler.py (working) + honest report | Yes — need real LLM timing measurements |
| Q2 | batch_prompt_template.txt (reusable) | Yes — need actual batch run data |
| Q3 | Manually written skills + index | No — skills are functional, just authored by human not sub-agent |

---

## Commits on `048-subagent-quality`

- `dbac5eb spec(cycle48): D+E+G — codex CLI profiling, 3-task batches, skill squad`

This handoff will be committed in a follow-up.

---

## Open questions for cycle 49

1. Should the supervisor script itself live in `~/.hermes/scripts/cycle47/` (current, can't be updated by sub-agents) OR project-local + copied to Hermes-global? Currently it's Hermes-global.
2. Should we add a "post-sub-agent" hook that auto-copies project-local artifacts to `~/.hermes/`?
3. How do we run cycle 48 Q1 + Q2 properly when the sandbox blocks writes to Hermes-global paths? Options:
   - Add `workdir` to sandbox whitelist (probably not possible without codex CLI change)
   - Re-run from a non-sandbox shell (security implications)
   - Accept that cycle 48 is "honest but inconclusive" and move on
4. Should Q3 skill squad be moved to project-local (`scripts/cycle48/skills/`) for sub-agent compatibility, then synced to `~/.hermes/`?