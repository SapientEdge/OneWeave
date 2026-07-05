# Cycle 47 T-R1.4 — Baseline Sub-Agent Timing Report

**Date:** 2026-07-05
**Branch:** 047-subagent-reliability
**Sub-agents:** 3 (trivial / medium / large)
**Measurement infra:** `scripts/cycle47/subagent_wrapper.py` v1

## Test methodology

All 3 sub-agents launched in **parallel** at 2026-07-05T17:45:23–25 UTC. Each invoked via:
```
python3 scripts/cycle47/subagent_wrapper.py <prompt.txt> <log> -- bash -c "cat <prompt> | codex exec --skip-git-repo-check"
```

Each was given a discrete, well-scoped task (write 1, 2, or 3 files to scripts/cycle47/).

## Raw results (from `data/subagents.jsonl`)

| # | Tier | Prompt (B) | Files written | Total output (B) | **Duration** | Exit | Codex session |
|---|---|---|---|---|---|---|---|
| 1 | Trivial | 267 | 1 (.txt) | 30 | **5.04s** | 0 | 019f3362-89e3-7bb0-... |
| 2 | Medium | 631 | 1 (.py) | 2793 | **19.09s** | 0 | (in log) |
| 3 | Large | 882 | 3 (.py) | 4850 | **32.55s** | 0 | (in log) |

## Comparison to cycle 46 historical data

| Metric | Cycle 46 (n=14) | Cycle 47 R1.4 baseline (n=3) |
|---|---|---|
| % < 2 min | 57% | **100%** (all under 60s) |
| % > 10 min | 14% | **0%** |
| Median duration | ~90s (est) | **19s** |
| Max duration | >10 min | **32.55s** |
| Hung at 5min | 5 occurrences | **0** |

## Surprising result

Cycle 47 sub-agents are **dramatically faster** than cycle 46. Possible reasons (to be validated in Phase R2):

1. **No graphify overhead** — cycle 46 phases triggered `graphify update .` for many commits
2. **Simpler prompts** — focused single-task descriptions vs multi-task complex specs
3. **No commit + test cycle** — sub-agents just wrote files, didn't run validators
4. **Codex CLI health** — could be transient (network, provider load, time of day)
5. **No retry/iteration loops** — cycle 46 sub-agents often had to fix errors and retry

## What this baseline does NOT measure

- Sub-agents that run validators
- Sub-agents that commit + push
- Sub-agents that read + analyze code
- Sub-agents that iterate after errors
- Sub-agents operating on the actual iOS Swift code (vs Python)

Cycle 47 phase R2 will test these more realistic conditions.

## Files created (real, on disk)

- `scripts/cycle47/baseline_trivial.txt` (30 B)
- `scripts/cycle47/baseline_medium.py` (2793 B)
- `scripts/cycle47/baseline_large_a.py` (1942 B)
- `scripts/cycle47/baseline_large_b.py` (1702 B)
- `scripts/cycle47/baseline_large_c.py` (1206 B)

All are in scripts/cycle47/ but NOT committed (will be gitignored or cleaned at end of cycle).

## Verdict

Baseline infra works. Phase R2 hypothesis tests will now use this same wrapper to compare timing across controlled conditions.

## Next steps

1. Commit T-R1.1, T-R1.2, T-R1.3, T-R1.4 deliverables
2. Begin Phase R2 (root cause isolation) — 4 hypothesis tests
3. Apply best mitigation in R3
4. Re-baseline with mitigation to confirm improvement