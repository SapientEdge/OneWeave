# Cycle 48 Q2 Three-Task Batch Report

## Environment Note

The requested global Hermes directory was read-only in this sandbox. `marker.py start T-Q2` printed to stdout but could not append to `~/.hermes/scripts/cycle47/data/markers.log`.

All 8 supervisor invocations were still run with `--marker-required --hung-threshold 600`. They were redirected to `/tmp/cycle48_q2/data` for supervisor JSONL capture. Each Codex child exited before executing any task because Codex could not initialize its in-process app-server client under the read-only home path.

A follow-up probe using `HOME=/tmp/codex_home` got past that initialization but failed on network access to `api.openai.com` with `Operation not permitted`, so live sub-agent execution was blocked by the environment rather than by 3-task prompt structure.

## Per-Batch Results

| Batch ID | Complexity | Duration (s) | Markers Expected | Markers Actual | Task End Markers | Exit | Status |
|---|---:|---:|---:|---:|---:|---:|---|
| T-batch-Q2-01 | trivial | 0.115 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-02 | trivial | 0.111 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-03 | trivial | 0.116 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-04 | medium | 0.121 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-05 | medium | 0.113 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-06 | medium | 0.124 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-07 | large | 0.118 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |
| T-batch-Q2-08 | large | 0.133 | 8 | supervisor=0, log=0 | 0/3 | 1 | infra-failed: codex home read-only |

## Success Rate

- Successful batches: 0/8 (0.0%)
- Partial batches: 0/8
- Failed batches: 8/8 before task execution
- Interpretable product result: inconclusive. The experiment did not reach task execution.

## Cycle 47 Baseline Comparison

| Complexity | Cycle 47 single-task supervisor baseline (s) | 3x single-task equivalent (s) | Observed batch durations | Interpretation |
|---|---:|---:|---:|---|
| trivial | 10.38 | 31.14 | 0.115, 0.111, 0.116 | Not comparable; Codex exited before work. |
| medium | 18.74 | 56.22 | 0.121, 0.113, 0.124 | Not comparable; Codex exited before work. |
| large | 40.56 | 121.68 | 0.118, 0.133 | Not comparable; Codex exited before work. |

## Recommendation

Do not update Lesson 2/28 to "<=3 tasks" from this run. The observed 0/8 success rate is an infrastructure failure, not evidence against 3-task batching.

Failure modes observed:
- `~/.hermes/scripts/cycle47/` and its data directory were read-only, so the template, report, markers log, and requested global JSONL writes could not be produced at the required paths.
- Codex with the default home failed immediately: `failed to initialize in-process app-server client: Read-only file system`.
- Codex with a writable temporary home then failed API access: `Operation not permitted` connecting to `api.openai.com`.
- Supervisor marker counts stayed at 0 because marker sidecar writes require the read-only global Hermes data directory.

Recommended rerun conditions: writable `~/.hermes/scripts/cycle47/data`, writable Codex home/state, and network access for `codex exec`. Reuse the prompts in `/tmp/cycle48_q2/batch_01.txt` through `/tmp/cycle48_q2/batch_08.txt`.
