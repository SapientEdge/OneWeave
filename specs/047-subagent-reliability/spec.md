# Cycle 47 — Sub-Agent Reliability Research (TD-5)

**Cycle:** 047-subagent-reliability
**Branch:** `047-subagent-reliability` (from master)
**Trigger:** Cycle 46 tech debt item TD-5 (the 5th sub-agent "hung vs done" incident)
**Goal:** Identify and mitigate the root causes of inconsistent sub-agent latency so every future cycle ships faster with higher confidence.

---

## Problem statement

Across cycles 45 + 46, **5 sub-agents appeared hung at 5+ minutes** but had actually completed + committed work. The cleanup notifications arrived 30s–10min AFTER the work was done. Cost: at least 2 unnecessary hybrid-salvage dispatches, 1 lost reliability report (cycle 46 TD-5), and ~30 min of false-alarm monitoring.

Latency distribution observed (n=14 sub-agents, cycles 45–46):

| Bucket | Count | % |
|---|---|---|
| < 2 min | 8 | 57% |
| 2–5 min | 2 | 14% |
| 5–10 min | 2 | 14% |
| > 10 min | 2 | 14% |

The 14% "long tail" is what hurts: those sub-agents tie up planning slots and force ambiguous salvage decisions.

## Hypothesized root causes (from cycle 46 TD-5 lost report)

1. **Codex CLI log buffering** — sub-agent prints no "Task complete" markers; the process looks idle even when doing final cleanup.
2. **Multi-file parallel writes** — sub-agents writing 3–5 files at once may block on disk I/O on slow VPS storage.
3. **Prompt size** — large sub-agent prompts (10KB+) take longer to parse, increasing cold-start.
4. **Network round-trips** — codex CLI may call home for license check / telemetry.
5. **Codex CLI wrapper** — the `codex exec` invocation may have buffering issues on this Linux VPS.

## Constraints

- Linux VPS, no Mac, no Swift toolchain. All validators must be Python.
- Must NOT regress cycle 46 work (57/57 suites must remain green).
- Skill `subagent-hung-vs-done-check` (TD-2) is the interim mitigation; cycle 47 aims to make it unnecessary.
- Sub-agents in this cycle are themselves the experimental subjects — measure everything.

## Success metrics

| Metric | Target |
|---|---|
| Sub-agents completing in < 2 min | ≥ 80% |
| Sub-agents appearing hung at 5 min | ≤ 5% |
| False salvages (killed but was actually done) | 0 |
| Lost cycle reports (timeout with no disk artifact) | 0 |
| Final validator suite | 57/57 green (no regression) |

---

## Out of scope

- Sub-agent prompt-template rewrites (cycle 48 if needed)
- Codex CLI upgrade (out of our control; this VPS pins it)
- Windows / Mac sub-agent behavior (Linux only)

---

## Phases (estimated ~12 tasks across 3 phases)

### Phase R1 — Measurement infrastructure (4 tasks)
- T-R1.1: Build a wrapper that records per-sub-agent start/end/wall-clock + exit code
- T-R1.2: Build a log-marker emitter that sub-agent prompts can call (`echo "CYCLE47_TASK_DONE <id>"`)
- T-R1.3: Build a "hung-detector" that fires when no log output for N seconds
- T-R1.4: Run baseline: dispatch 3 sub-agents with the current system, measure everything

### Phase R2 — Root cause isolation (4 tasks)
- T-R2.1: Test hypothesis 1 (log buffering) — add log markers, see if detection works
- T-R2.2: Test hypothesis 2 (multi-file writes) — single-file sub-agents vs multi-file
- T-R2.3: Test hypothesis 3 (prompt size) — small-prompt vs large-prompt sub-agents
- T-R2.4: Test hypothesis 5 (codex wrapper) — `codex exec` vs raw codex invocation

### Phase R3 — Mitigation + handoff (4 tasks)
- T-R3.1: Implement the best mitigation(s) found in Phase R2
- T-R3.2: Re-run baseline — confirm < 2 min completion rate improved
- T-R3.3: Update the `subagent-hung-vs-done-check` skill with new evidence
- T-R3.4: Write `CYCLE47_HANDBACK.md` with findings + recommendations

---

## Acceptance

- [ ] Phase R1 measurement infra running + producing structured data
- [ ] Phase R2 has at least 1 confirmed root cause (or null result documented)
- [ ] Phase R3 mitigation reduces < 2 min completion rate improvement by ≥ 20 percentage points
- [ ] Validator suite still 57/57 green
- [ ] Handoff doc + updated skill committed

---

## Related artifacts

- Cycle 46 sub-agent cleanup notifications (5 occurrences, all "exit code 0 after long quiet period")
- Skill: `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md`
- Cycle 46 handoff doc: `.specify/specs/046-lifemoment/cycle46_handoff.md`