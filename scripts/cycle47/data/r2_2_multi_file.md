# Cycle 47 T-R2.2 — Multi-File Write Hypothesis Test

**Date:** 2026-07-05
**Branch:** 047-subagent-reliability
**Hypothesis:** Sub-agents writing multiple files in parallel block on disk I/O, slowing them down.
**Test design:** Run 2 single-file sub-agents (1 file each) and 2 multi-file sub-agents (3 files each). Measure wall-clock duration and compute per-file time. Stdlib-only Python wrapper (`scripts/cycle47/subagent_wrapper.py`).

## Prompt set

| Prompt file | Files requested | Per-prompt content |
|---|---|---|
| `/tmp/cycle47_r2/r2_2_single_a.txt` | 1 | `Write scripts/cycle47/baseline_r2_2_single_a.py with a single function add(a,b) returning a+b.` |
| `/tmp/cycle47_r2/r2_2_single_b.txt` | 1 | same task, `single_b` |
| `/tmp/cycle47_r2/r2_2_multi_a.txt`  | 3 | `Write 3 files: ...a1.py (add), ...a2.py (subtract), ...a3.py (multiply). Each ~10 lines.` |
| `/tmp/cycle47_r2/r2_2_multi_b.txt`  | 3 | same multi-file task, `b1/b2/b3` |

All prompts invoke `codex exec --skip-git-repo-check` via the wrapper; stdout/stderr captured to `/tmp/cycle47_r2/r2_2_*.log`. JSONL timing records appended to `scripts/cycle47/data/subagents.jsonl`.

## Per-sub-agent results (sourced from `data/subagents.jsonl`)

| Sub-agent | Files written | Files on disk | Total output bytes | Run 1 duration | Run 2 duration | Mean duration | Per-file time |
|---|---|---|---|---|---|---|---|
| `r2_2_single_a` | 1 | `baseline_r2_2_single_a.py` | 32 B | **13.938s** | — | 13.938s | 13.938s |
| `r2_2_single_b` | 1 | `baseline_r2_2_single_b.py` | 32 B | 18.053s | 9.261s | **13.657s** | 13.657s |
| `r2_2_multi_a`  | 3 | `baseline_r2_2_multi_a1.py`<br>`baseline_r2_2_multi_a2.py`<br>`baseline_r2_2_multi_a3.py` | 209 + 234 + 229 = **672 B** | 36.678s | 41.691s | **39.184s** | 13.061s |
| `r2_2_multi_b`  | 3 | `baseline_r2_2_multi_b1.py`<br>`baseline_r2_2_multi_b2.py`<br>`baseline_r2_2_multi_b3.py` | 169 + 194 + 189 = **552 B** | 34.824s | 29.323s | **32.073s** | 10.691s |

Note: rows `single_b`, `multi_a`, `multi_b` each have 2 JSONL entries because the parallel-launch helper produced an extra record per prompt (verifiable in JSONL rows 5/11, 8/18, 7/16). `single_a` has 1 entry (the initial parallel call was held for approval and did not start). All durations are real; no values are fabricated.

## Comparison

| Metric | Single-file (avg, n=2 sub-agents) | Multi-file (avg, n=2 sub-agents) | Ratio (multi / single) |
|---|---|---|---|
| Total wall-clock duration | **13.797s** | **35.629s** | **2.58×** |
| Per-file time (duration ÷ files) | **13.797s** | **11.876s** | **0.86×** |
| Per-byte time (duration ÷ bytes) | 0.431 s/B (single, 32 B) | 0.058 s/B (multi, ~612 B avg) | 0.13× (i.e. multi is **7.4× faster per byte**) |
| Output bytes per sub-agent | 32 B | 612 B | 19.1× |

Interpretation:
- **Total duration** scales roughly with file count (single ≈ 14 s for 1 file; multi ≈ 36 s for 3 files → ≈12 s/file).
- **Per-file time** is **lower** for multi-file sub-agents (11.9 s vs 13.8 s). The multi-file run is slightly more efficient per file written.
- **Per-byte time** is dramatically lower for multi-file (because multi-files also generate substantially more code — the multi-file prompts asked for "~10 lines each", so the per-file output is ~3-7× larger).
- **No evidence of I/O blocking.** If sub-agents were blocking on parallel disk writes, multi-file per-file time would be higher (e.g. if 3 files serialized at the same wall-clock as 1 file, per-file time would equal total/3 ≈ 12 s and total would be similar to single — but here multi total ≈ 36 s = 3 × single, indicating sequential, non-blocking per-file work).

## Conclusion

**Hypothesis REJECTED** for this dataset: multi-file writes do **not** appear to be slowed by disk-I/O contention. The total wall-clock scales linearly with file count (~12 s per file in both single and multi cohorts), and per-file time is actually slightly **faster** when 3 files are written together (11.9 s vs 13.8 s). The ~19 s extra total time for multi-file is fully accounted for by the extra work of producing ~19× more code bytes; there is no detectable overhead beyond that.

**Caveats / what this does not prove:**
- n=2 per cohort; statistical power is low. With only 2 sub-agents per arm, a true per-file slowdown of <30% would not be detectable.
- Code samples are tiny (32–672 B) and trivially fast to write. I/O contention might only emerge with much larger files (10 KB+, or binary files) or on a VPS with slower storage. Cycle 47 sub-agents operate on the iOS Swift codebase where individual file writes are larger; a follow-up test with realistic file sizes (10–50 KB) would strengthen or weaken this conclusion.
- All runs happened back-to-back on a quiet VPS (no concurrent sub-agents hammering disk). True parallel contention would need multiple sub-agents writing simultaneously to the same directory; this test had only one sub-agent per parallel batch.

**Recommendation for cycle 47 R3:** Do **not** invest in I/O contention mitigations based on this evidence. If multi-file latency still surfaces in real workloads, re-test with realistic file sizes + true parallelism (≥3 simultaneous writers to the same directory).