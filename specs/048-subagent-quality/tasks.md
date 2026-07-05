# Cycle 48 — Sub-Agent Quality Tasks

**Cycle:** 048-subagent-quality
**Total tasks:** 12 across 3 phases (Q1, Q2, Q3)
**Pattern:** Each task ≤ 2 hours, mostly self-contained
**Order:** Q1 first (foundation), Q2 second (validation), Q3 last (skill squad)

---

## Phase Q1 — Codex CLI profiling (4 tasks)

### T-Q1.1: Per-phase timing wrapper
- **Files:** `~/.hermes/scripts/cycle47/codex_profiler.py` (new, ≤80 lines)
- **Acceptance:** Wraps `codex exec` invocation. Uses `time` module + `PYTHONUNBUFFERED=1` to capture: (1) cold-start time before first output, (2) LLM round-trip from prompt submit to first token, (3) total wall-clock. Outputs JSON line per invocation to `data/codex_profile.jsonl`.
- **Complexity:** S

### T-Q1.2: Run 5 baseline codex invocations
- **Files:** `data/codex_baseline_runs.json` (new)
- **Acceptance:** Run 5 different codex prompts via the profiler (varying complexity). Record per-phase timings for each.
- **Dependencies:** T-Q1.1
- **Complexity:** S

### T-Q1.3: Compare against no-LLM baseline
- **Files:** `data/codex_overhead_comparison.json` (new)
- **Acceptance:** Run 3 invocations with `--no-llm` flag (if available) OR with a prompt that returns immediately. If `--no-llm` doesn't exist, use a prompt that asks for "echo only" and measure. Document the difference.
- **Dependencies:** T-Q1.2
- **Complexity:** M

### T-Q1.4: Profile report
- **Files:** `data/codex_cli_profile.md` (new)
- **Acceptance:** Markdown report with per-phase timing breakdown. Conclusion: is codex CLI overhead a significant portion of cycle 47 baseline (5-40s)?
- **Dependencies:** T-Q1.3
- **Complexity:** S

---

## Phase Q2 — 3-task batch validation (4 tasks)

### T-Q2.1: 3-task prompt template
- **Files:** `~/.hermes/scripts/cycle47/batch_prompt_template.txt` (new)
- **Acceptance:** Template showing how to write a single prompt containing 3 tasks. Each task has: Task: T-XXX header, marker start, instructions, marker end. Plus overall Task: T-batch header + end markers.
- **Complexity:** S

### T-Q2.2: Run 8 sub-agents with 3 tasks each
- **Files:** `data/three_task_runs.jsonl` (new, produced by supervisor)
- **Acceptance:** 8 sub-agent invocations, each via supervisor with a 3-task prompt. Mix: 3 trivial/3 medium/2 large. Use the wrapper.
- **Dependencies:** T-Q2.1
- **Complexity:** M

### T-Q2.3: Success rate measurement
- **Files:** `data/three_task_success_rate.md` (new)
- **Acceptance:** Parse JSONL, count: (a) successful batches (all 3 tasks marked end), (b) partial batches (1-2 marked), (c) failed (0 marked). Calculate success rate. Compare duration vs sum of 3 single-task equivalents.
- **Dependencies:** T-Q2.2
- **Complexity:** S

### T-Q2.4: 3-task batch report
- **Files:** `data/three_task_batch_report.md` (new)
- **Acceptance:** Markdown report with findings. Recommendation: should we update Lesson 2/28 from "≤2 tasks" to "≤3 tasks"?
- **Dependencies:** T-Q2.3
- **Complexity:** S

---

## Phase Q3 — Sub-agent skill squad (4 tasks)

### T-Q3.1: Identify squad skills
- **Files:** `~/.hermes/skills/subagent-squad/README.md` (new, squad index)
- **Acceptance:** Decide on 4-6 skills that compose into a sub-agent workflow. Suggested: `subagent-launcher`, `batch-splitter`, `marker-discipline`, `hung-recovery`. Plus existing `subagent-hung-vs-done-check`.
- **Complexity:** S

### T-Q3.2: Write 3 new skills
- **Files:** `~/.hermes/skills/subagent-launcher/SKILL.md` + 2 others (each ≤100 lines)
- **Acceptance:** Each skill has: trigger condition, numbered steps with exact commands, pitfalls section. Skills must be coherent with each other (cross-references).
- **Dependencies:** T-Q3.1
- **Complexity:** M

### T-Q3.3: Update hung-vs-done-check skill
- **Files:** `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md` (patch)
- **Acceptance:** Add references to other squad skills. Update decision tree to recommend skill composition.
- **Dependencies:** T-Q3.2
- **Complexity:** S

### T-Q3.4: Squad index doc
- **Files:** `~/.hermes/skills/subagent-squad/README.md` (finalize)
- **Acceptance:** Complete squad index listing all 4-6 skills, their triggers, and how they compose. Mermaid diagram optional.
- **Dependencies:** T-Q3.1, T-Q3.2, T-Q3.3
- **Complexity:** S

---

## Completion criteria

- All 12 tasks committed
- Validator suite 57/57 green
- Squad ≥4 skills + index doc
- Handoff doc committed
- Branch merged to master + deleted