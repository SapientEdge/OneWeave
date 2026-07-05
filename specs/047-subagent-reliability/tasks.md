# Cycle 47 — Sub-Agent Reliability Tasks

**Cycle:** 047-subagent-reliability
**Total tasks:** 12 across 3 phases (R1, R2, R3)
**Pattern:** Each task ≤ 2 hours, mostly self-contained Python + sub-agent experiments
**Order:** R1 first (build infra), R2 second (test hypotheses), R3 last (mitigate + handoff)

---

## Phase R1 — Measurement infrastructure (4 tasks)

### T-R1.1: Sub-agent timing wrapper script
- **Files:** `scripts/cycle47/subagent_wrapper.py` (new)
- **Acceptance:** Script that wraps `codex exec --skip-git-repo-check` invocation, records:
  - start timestamp
  - end timestamp + wall-clock duration
  - exit code
  - prompt file path
  - log file path
  - output JSON line per sub-agent to `scripts/cycle47/data/subagents.jsonl`
- **Complexity:** S

### T-R1.2: Log-marker emitter convention
- **Files:** `scripts/cycle47/marker.py` (new) + SKILL.md update
- **Acceptance:** Tiny Python module that emits `CYCLE47_MARKER <task_id> <status>` to stdout + a sidecar file `markers.log`. Each sub-agent prompt includes `python3 scripts/cycle47/marker.py start T-R1.1` and `... end T-R1.1` calls.
- **Complexity:** S

### T-R1.3: Hung-detector script
- **Files:** `scripts/cycle47/hung_detector.py` (new)
- **Acceptance:** Polls a log file every 5s. If no new output AND no markers AND process alive for ≥ threshold, prints `HUNG_DETECTED <process_id>` to a separate log + writes a JSON event.
- **Complexity:** S

### T-R1.4: Baseline run (3 sub-agents)
- **Files:** `scripts/cycle47/baseline_run.py` (new) + 3 log outputs
- **Acceptance:** Dispatch 3 sub-agents (1 trivial, 1 medium, 1 large) with the wrapper + markers. Capture all timing data. Produce baseline report `scripts/cycle47/data/baseline_report.md`.
- **Dependencies:** T-R1.1, T-R1.2, T-R1.3
- **Complexity:** M

---

## Phase R2 — Root cause isolation (4 tasks)

### T-R2.1: Test hypothesis 1 (log buffering)
- **Files:** `scripts/cycle47/h1_log_buffering.py` (new) + run log
- **Acceptance:** Run 2 sub-agents WITH markers, 2 WITHOUT markers. Compare "time to first 'Task complete' visible" and "time to exit". Report whether markers reduce false-hung detection.
- **Complexity:** S

### T-R2.2: Test hypothesis 2 (multi-file writes)
- **Files:** `scripts/cycle47/h2_multi_file.py` (new) + run log
- **Acceptance:** Run 2 single-file sub-agents + 2 multi-file sub-agents. Compare wall-clock time per file written. Report p-value or effect size.
- **Complexity:** M

### T-R2.3: Test hypothesis 3 (prompt size)
- **Files:** `scripts/cycle47/h3_prompt_size.py` (new) + run log
- **Acceptance:** Run 2 sub-agents with small prompts (< 2KB), 2 with large prompts (> 10KB). Measure cold-start time (first 10s of execution). Report correlation.
- **Complexity:** S

### T-R2.4: Test hypothesis 5 (codex wrapper)
- **Files:** `scripts/cycle47/h5_codex_wrapper.py` (new) + run log
- **Acceptance:** Run 2 sub-agents via `codex exec` + 2 via raw `codex` invocation. Compare timing. Document the difference.
- **Complexity:** S

---

## Phase R3 — Mitigation + handoff (4 tasks)

### T-R3.1: Implement best mitigation(s)
- **Files:** depends on Phase R2 findings (likely `scripts/cycle47/wrapper_v2.py` or similar)
- **Acceptance:** Apply the top 1-2 mitigations discovered in R2. Production-ready.
- **Dependencies:** T-R2.*
- **Complexity:** M

### T-R3.2: Re-run baseline
- **Files:** `scripts/cycle47/data/post_mitigation_report.md`
- **Acceptance:** Run same 3 baseline sub-agents from R1.4, with mitigation. Compare to original baseline. Report % improvement.
- **Dependencies:** T-R3.1
- **Complexity:** S

### T-R3.3: Update subagent-hung-vs-done-check skill
- **Files:** `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md` (update)
- **Acceptance:** Skill updated with cycle 47 evidence. Real occurrences list expanded to 10+. Decision tree refined if needed.
- **Dependencies:** T-R3.2
- **Complexity:** S

### T-R3.4: Cycle 47 handoff doc
- **Files:** `specs/047-subagent-reliability/cycle47_handoff.md`
- **Acceptance:** Full findings report: root causes, mitigations, future work, recommendations for cycle 48. ≥ 200 lines.
- **Dependencies:** T-R3.1, T-R3.2, T-R3.3
- **Complexity:** M

---

## Completion criteria

- All 12 tasks committed
- Validator suite 57/57 green
- Handoff doc reviewed
- Branch merged to master + deleted