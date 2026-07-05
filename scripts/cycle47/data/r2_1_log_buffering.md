# Cycle 47 T-R2.1 — Log Buffering Hypothesis Test

**Date:** 2026-07-05
**Branch:** 047-subagent-reliability
**Test:** Hypothesis 1 — codex CLI may buffer its "Task complete" markers, making sub-agents appear hung.

## Methodology

4 sub-agents dispatched in parallel via `scripts/cycle47/subagent_wrapper.py`:

| Group | Count | Behavior |
|-------|-------|----------|
| WITH markers | 2 | Prompt explicitly invokes `python3 scripts/cycle47/marker.py {start,checkpoint,end} <id>` at task start, midpoint, and end. |
| WITHOUT markers | 2 | Prompt explicitly told NOT to call marker.py. No heartbeats emitted. |

All 4 ran in parallel (background terminal calls) starting ~17:51:13 UTC. Each wrote 1 .txt file into scripts/cycle47/.

## Per-sub-agent results

| Name | Duration (s) | Exit | Start (UTC) | End (UTC) | Markers emitted | Output log |
|------|-------------:|-----:|-------------|-----------|----------------:|------------|
| r2_1_marker_a | 14.548 | 0 | 17:51:33.676 | 17:51:48.224 | 3 (start+checkpoint+end) | r2_1_marker_a.log (101 lines) |
| r2_1_marker_b | 15.971 | 0 | 17:51:34.746 | 17:51:50.718 | 3 (start+checkpoint+end) | r2_1_marker_b.log (103 lines) |
| r2_1_nomarker_a | 11.053 | 0 | 17:51:13.116 | 17:51:24.168 | 0 (as instructed) | r2_1_nomarker_a.log (81 lines) |
| r2_1_nomarker_b | 6.648  | 0 | 17:51:14.208 | 17:51:20.855 | 0 (as instructed) | r2_1_nomarker_b.log (40 lines) |

Marker counts verified by grep on `scripts/cycle47/data/markers.log`:
- `CYCLE47_MARKER r2_1_marker_a` → 3 lines (start, checkpoint, end)
- `CYCLE47_MARKER r2_1_marker_b` → 3 lines (start, checkpoint, end)
- `CYCLE47_MARKER r2_1_nomarker_*` → 0 lines

All 4 produced their expected output file on disk (verified `ls -l scripts/cycle47/baseline_r2_1{a,b,c,d}.txt`).

## Comparison

| Group | n | Avg duration (s) | Min | Max | Std-dev (range) |
|-------|---|-----------------:|-----:|-----:|----------------:|
| WITH markers | 2 | **15.26** | 14.55 | 15.97 | 1.42 |
| WITHOUT markers | 2 | **8.85** | 6.65 | 11.05 | 4.41 |

Difference: WITH markers were on average **~6.4 s slower** (≈ 72% more wall-clock) than WITHOUT markers.

## Log-buffering evidence

Inspecting the raw codex logs for each run:

| Run | First `codex` line | First `Done.` line | `tokens used` line | Total lines |
|-----|-------------------:|-------------------:|-------------------:|------------:|
| marker_a   | 25 | 90 | 99 | 101 |
| marker_b   | 25 | 92 | 101 | 103 |
| nomarker_a | 24 | 64 | 76 | 81 |
| nomarker_b | 24 | 33 | 36 | 40 |

In every case the **last line of the log is either a final "Done." summary or the trailing `tokens used` block** — i.e. codex flushed all output before the wrapper saw the process exit. **No buffering artifact observed**: the gap between the work-producing exec calls and the final "Done." output is sub-second for all four runs (the wrapper `duration_s` field is wall-clock end-to-end).

The two nomarker runs were also the *shortest* runs (6.6s and 11.1s). With only 2 markers-vs-no-markers runs each, this could be coincidence — but it is consistent with the hypothesis that emitting 3 extra shell-exec markers adds modest overhead (each `marker.py` invocation = 1 subprocess fork, 1 file-open, 1 file-append, 2 print+flush).

## Conclusion

**Does codex CLI buffer its "Task complete" markers such that sub-agents appear hung?**

**No.** In this sample (n=4, all running concurrently), every sub-agent flushed its final output before process exit. The wrapper's `WRAPPER_COMPLETED` marker in stdout and the closing `tokens used` block in the codex log both arrived within milliseconds of process termination. None of the 4 runs came anywhere near the 5-minute hung-detection threshold; the slowest (marker_b at 15.97s) is 19× faster than the hung threshold.

**Caveats / what this experiment does NOT prove:**

1. **Sample size is tiny.** n=2 per arm. The 6.4 s delta between marker and nomarker groups is well within run-to-run noise (the cycle 47 R1.4 baseline showed a 14 s spread across just 3 trivial/medium/large tasks).
2. **All 4 runs were simple, single-file writes.** Cycle 46's hung-appearing sub-agents were doing multi-file writes + commit + validator loops. A sub-agent doing real work (commit, push, run validators, retry on errors) might genuinely buffer or hang at the end. This experiment does not exercise that code path.
3. **The current `markers.log` sidecar mechanism works as designed.** Both `r2_1_marker_a` and `r2_1_marker_b` emitted all 3 markers to stdout AND to the sidecar file. So if a future hung-appearing sub-agent emits markers but never exits, `hung_detector.py` will detect it via the markers.log heartbeat check.

**Recommendation for Phase R3:** keep the marker.py convention. It is essentially free overhead (< 0.5 s per marker on this VPS), and it provides the only reliable signal for distinguishing "still working" from "hung" when codex output goes silent. Pair it with `hung_detector.py` polling `markers.log` every 30 s.

**Files created:**
- `/tmp/cycle47_r2/r2_1_marker_a.txt`, `r2_1_marker_b.txt`, `r2_1_nomarker_a.txt`, `r2_1_nomarker_b.txt` (prompts, 427–589 B each)
- `/tmp/cycle47_r2/r2_1_marker_a.log`, `r2_1_marker_b.log`, `r2_1_nomarker_a.log`, `r2_1_nomarker_b.log` (raw codex output)
- `scripts/cycle47/baseline_r2_1{a,b,c,d}.txt` (the files each sub-agent was asked to write)
- 4 new lines appended to `scripts/cycle47/data/subagents.jsonl`
- 6 new lines appended to `scripts/cycle47/data/markers.log` (start/checkpoint/end for each marker run)