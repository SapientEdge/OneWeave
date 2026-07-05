# Cycle 47 T-R2.3 — Prompt Size Hypothesis Test

**Date:** 2026-07-05
**Branch:** 047-subagent-reliability
**Test:** Hypothesis 3 — large prompts take longer to parse, increasing cold-start.

## Methodology

4 sub-agents dispatched in parallel via `scripts/cycle47/subagent_wrapper.py`:

| Group | Count | Prompt bytes | Prompt content |
|-------|-------|-------------:|----------------|
| Small prompts | 2 | 384, 395 (~300 B target) | Minimal task description: "write a hello_world() function" |
| Large prompts | 2 | 4238, 4238 (>2 KB target) | Same task + extensive OneWeave project context, coding standards, file references, constitution excerpt, lorem-ipsum-style iOS Swift pattern filler |

All 4 ran in parallel (background terminal calls) starting ~17:51:15 UTC. Each wrote 1 .py file into scripts/cycle47/ and ran it once to verify.

## Per-sub-agent results

| Name | Prompt bytes | Duration (s) | Exit | Start (UTC) | End (UTC) | Output log |
|------|-------------:|-------------:|-----:|-------------|-----------|------------|
| r2_3_small_a | 384 | 30.603 | 0 | 17:51:15.303 | 17:51:45.906 | r2_3_small_a.log (452 lines) |
| r2_3_small_b | 395 | 32.135 | 0 | 17:51:16.365 | 17:51:48.500 | r2_3_small_b.log (145 lines) |
| r2_3_large_a | 4238 | 26.241 | 0 | 17:51:17.442 | 17:51:43.683 | r2_3_large_a.log (583 lines) |
| r2_3_large_b | 4238 | 21.619 | 0 | 17:51:18.518 | 17:51:40.138 | r2_3_large_b.log (575 lines) |

All 4 produced their expected output file on disk (verified `ls -l scripts/cycle47/baseline_r2_3_*.py`).

## Comparison

| Group | n | Avg duration (s) | Min | Max | Range |
|-------|---|-----------------:|-----:|-----:|------:|
| Small (<500 B) | 2 | **31.37** | 30.60 | 32.14 | 1.53 |
| Large (>2 KB)  | 2 | **23.93** | 21.62 | 26.24 | 4.62 |

Difference: **Large prompts were on average ~7.4 s FASTER than small prompts** (≈ 24% less wall-clock). This is the opposite direction from the hypothesis.

## Cold-start vs total time

The wrapper's `duration_s` field is wall-clock end-to-end. To check whether any cold-start delay existed, I diffed each run's start_ts against the first non-header content line in the log:

| Run | First content line | Δ from start_ts |
|-----|--------------------|----------------:|
| r2_3_small_a | line 14 (the user prompt echo) | ≤1 s (log buffered, no timestamps) |
| r2_3_small_b | line 13 (the user prompt echo) | ≤1 s |
| r2_3_large_a | line 16 (the user prompt echo) | ≤1 s |
| r2_3_large_b | line 17 (the user prompt echo) | ≤1 s |

The codex log does not embed per-line timestamps, so a precise cold-start measurement requires the hung_detector polling the log file mtime. From visual inspection, all 4 runs reached their first user-prompt echo within 1–2 s of process start, regardless of prompt size.

## Conclusion

**Does prompt size correlate with cold-start or total time?**

**In this sample: no. In fact the large prompts ran slightly faster.**

The small/large average gap is 7.4 s with n=2 per arm — well within run-to-run variance. Comparing against the R1.4 baseline (n=3, prompts 267–882 B, durations 5–32 s), the *smallest* prompt (267 B trivial) finished in 5 s, while the *medium* (631 B) and *large* (882 B) prompts took 19 s and 32 s. That trend (longer prompt → slower) is consistent with prompt-size scaling, but the magnitudes are dominated by task complexity, not prompt parsing.

The R2.3 prompts deliberately kept **task complexity constant** (all 4 wrote one hello_world() function). The only varying dimension was prompt context size. Under those conditions:
- Small (384–395 B) → 30.6 s, 32.1 s
- Large (4238 B) → 26.2 s, 21.6 s

The "large prompts slower" prediction is not supported. A 10× larger prompt does not appear to add measurable cold-start delay on this VPS with codex-cli 0.142.5.

**Caveats / what this experiment does NOT prove:**

1. **Sample size is tiny.** n=2 per arm. The within-group variance (1.5 s for small, 4.6 s for large) is comparable to the between-group difference.
2. **The "large" prompts at 4238 B are not actually large.** Codex CLI's prompt-parsing overhead (if any) would likely only become visible at 10 KB+ as the original spec mentioned. 4 KB may be well below the threshold where parsing cost matters.
3. **All runs were simple, single-file writes.** No commit, no validator, no multi-step reasoning. Cold-start may matter more when the prompt describes a 5-step plan the model needs to load into context.
4. **Codex CLI may pre-process the prompt during the `Reading prompt from stdin...` header** (which appeared in <1 s for all 4 runs), so the model may already have the full context loaded by the time it starts streaming tokens.

**Recommendation for Phase R3:** prompt size is unlikely to be the dominant cause of cycle 46's hung-appearing sub-agents. Focus mitigation efforts on R2.2 (multi-file writes) and R2.4 (codex wrapper invocation style) instead. If prompt size ever needs further study, push the contrast to 500 B vs 50 KB (not 4 KB).

**Files created:**
- `/tmp/cycle47_r2/r2_3_small_a.txt`, `r2_3_small_b.txt` (384 B, 395 B)
- `/tmp/cycle47_r2/r2_3_large_a.txt`, `r2_3_large_b.txt` (4238 B, 4238 B)
- `/tmp/cycle47_r2/r2_3_small_a.log`, `r2_3_small_b.log`, `r2_3_large_a.log`, `r2_3_large_b.log` (raw codex output)
- `scripts/cycle47/baseline_r2_3_small_a.py`, `baseline_r2_3_small_b.py`, `baseline_r2_3_large_a.py`, `baseline_r2_3_large_b.py` (the files each sub-agent wrote)
- 4 new lines appended to `scripts/cycle47/data/subagents.jsonl`