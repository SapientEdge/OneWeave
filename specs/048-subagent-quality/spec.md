# Cycle 48 — Sub-Agent Quality (D + E + G)

**Cycle:** 048-subagent-quality
**Branch:** `048-subagent-quality` (from master)
**Trigger:** Three open items after cycle 47 + tech debt cleanup.
**Goal:** Move from "sub-agents that work" to "sub-agents that scale and self-organize."

---

## Problem statement

Cycle 47 fixed the immediate "hung sub-agent" problem by adding the supervisor + markers. But three issues remain:

1. **D — Codebase performance is opaque:** Codex CLI latency was identified as INCONCLUSIVE in cycle 47 R2.4 (raw `codex` requires TTY, so we couldn't test if `codex exec` adds overhead). We don't know if our 5–40s baseline is near-optimal or if 50% of that is wasted on codex CLI overhead.

2. **E — Sub-agent batch size is conservative:** Cycle 46 successfully ran 3 tasks per sub-agent (T-D1+T-D2, T-D3+T-D4, T-D5). But our convention is "≤2 tasks per sub-agent" (Lesson 2/28). If 3-task batches reliably work, we could ship more work per dispatch.

3. **G — Sub-agent skills are fragmented:** We have `subagent-hung-vs-done-check` (in `~/.hermes/skills/`) and `subagent_supervisor.py` (in `~/.hermes/scripts/cycle47/`) but they don't compose into a coherent workflow. A "squad" pattern (5+ skills that work together) is missing.

---

## Constraints

- Linux VPS, no Mac, no Swift toolchain. Validators must be Python.
- Must NOT regress cycle 47: 57/57 suites green.
- All infra remains Hermes-global, not project-specific.
- Sub-agents themselves are the experimental subjects — measure everything.

## Success metrics

| Metric | Target |
|---|---|
| Codex CLI overhead quantified | <5s per invocation OR clearly identified larger source |
| 3-task batch success rate | ≥80% (≥6/8 batches complete cleanly with markers) |
| Sub-agent skill squad created | ≥4 skills in a coherent `subagent-squad/` group |
| Validator suite | 57/57 still green |
| Cycle 48 total commits | ≤8 |

---

## Out of scope

- Codex CLI upgrade (out of our control)
- Real iOS Swift work (Linux can't compile)
- Sub-agent prompt template redesign (cycle 49+)

---

## Phases (estimated ~12 tasks across 3 phases)

### Phase Q1 — Codex CLI profiling (4 tasks)
- T-Q1.1: Build timing wrapper around `codex exec` that measures CLI startup, stdin parse, LLM round-trip, stdout flush separately (via strace / timing markers in the codex output)
- T-Q1.2: Run 5 baseline codex invocations, log per-phase timings
- T-Q1.3: Compare timing against `echo "hello"` (no LLM) to isolate LLM round-trip from CLI overhead
- T-Q1.4: Write `~/.hermes/scripts/cycle47/data/codex_cli_profile.md` with findings

### Phase Q2 — 3-task batch validation (4 tasks)
- T-Q2.1: Define a 3-task sub-agent template (one prompt, three Task: T-XXX sections, each with markers)
- T-Q2.2: Run 8 sub-agents via supervisor with 3 tasks each (varying complexity: 3 trivial / 3 medium / 2 large)
- T-Q2.3: Measure: success rate, markers emitted (expect 6+ per agent: start+end per task + start+end overall), duration vs 1-task equivalent
- T-Q2.4: Write `~/.hermes/scripts/cycle47/data/three_task_batch_report.md`

### Phase Q3 — Sub-agent skill squad (4 tasks)
- T-Q3.1: Identify 4-6 skills that compose into a sub-agent workflow (existing: hung-vs-done-check; new: subagent-launcher, batch-splitter, marker-discipline, hung-recovery)
- T-Q3.2: Write each new skill (~80 lines each, structured per existing skill template)
- T-Q3.3: Update `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md` to reference the squad
- T-Q3.4: Write `~/.hermes/skills/subagent-squad/README.md` (squad index doc)

---

## Acceptance

- [ ] Phase Q1 quantifies codex CLI overhead (or confirms it's negligible)
- [ ] Phase Q2 demonstrates 3-task batches work ≥80% of the time
- [ ] Phase Q3 ships ≥4 skills in coherent squad
- [ ] Validator suite still 57/57 green
- [ ] All scripts/skills added to `~/.hermes/` (Hermes-global, not project-specific)
- [ ] Handoff doc committed

---

## Related artifacts

- Cycle 47 spec: `specs/047-subagent-reliability/spec.md`
- Cycle 47 handoff: `specs/047-subagent-reliability/cycle47_handoff.md`
- Supervisor: `~/.hermes/scripts/cycle47/subagent_supervisor.py`
- Skill: `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md`
- Benchmark: `~/.hermes/scripts/cycle47/benchmark.py`