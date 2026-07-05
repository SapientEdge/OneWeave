# Sub-Agent Workflow Policy (Cycle 47+)

> **⚠️ DEPRECATION NOTICE:** This OneWeave-local copy of cycle 47's sub-agent infrastructure is **historical**. The canonical, maintained copy lives at `~/.hermes/scripts/cycle47/` and is **Hermes-global** (works for any project).
>
> Going forward, all sub-agents should reference the global path. This file is preserved so OneWeave's git history shows the origin.

## Canonical location

`~/.hermes/scripts/cycle47/` contains:
- `subagent_supervisor.py` (canonical)
- `subagent_wrapper.py` (canonical)
- `hung_detector.py` (canonical)
- `marker.py` (canonical)
- `README.md` (canonical policy doc)

## Background

Cycle 46 had 5 sub-agents that **appeared hung** at 5+ minutes but had actually completed + committed their work. Cycle 47 diagnosed this and built infrastructure to prevent it from happening again.

This document originally defined **how to launch sub-agents correctly** for OneWeave. It is now superseded by the global README — see `~/.hermes/scripts/cycle47/README.md` for the maintained version.

## Quick reference (for OneWeave specifically)

Same as the global policy, with paths translated:

- **Sub-agents <10s expected:** `~/.hermes/scripts/cycle47/subagent_wrapper.py`
- **Sub-agents ≥10s expected:** `~/.hermes/scripts/cycle47/subagent_supervisor.py --marker-required --hung-threshold 600`
- **NEVER:** raw `codex exec` without wrapping

For per-project data isolation in OneWeave:
```bash
export HERMES_SUBAGENT_DATA=/root/hermes-workspace/projects/oneweave/.hermes-subagent-data
```

## When to use which wrapper

| Tool | Use when | Adds overhead |
|---|---|---|
| `scripts/cycle47/subagent_wrapper.py` | Trivial work (write 1 file, <10s expected runtime) | <0.1s |
| `scripts/cycle47/subagent_supervisor.py` | Medium/large work (multi-file, multi-step, >10s expected) | 2-3s |
| Direct `codex exec --skip-git-repo-check` | NEVER. Always wrap. | n/a |

### Decision rule

- **Sub-agent expected to finish in <10 seconds?** → `subagent_wrapper.py` directly.
- **Sub-agent expected to take ≥10 seconds, OR has multiple steps (commit + push + test, multi-file write, etc.)?** → `subagent_supervisor.py --marker-required --hung-threshold 600`.

Default hung threshold: **600 seconds (10 minutes)**. Tasks that legitimately run longer should use `--hung-threshold 900` (15 minutes) and the supervisor will still record hung events in the JSONL for review.

## Sub-agent prompt requirements

Every sub-agent prompt **MUST** include:

1. **Task ID at start**: `Task: T-XXXX` (e.g. `Task: T-R2.1`)
2. **Marker calls**: At task start, midpoint (if applicable), and end:
   ```
   python3 scripts/cycle47/marker.py start T-XXXX
   # ... actual work ...
   python3 scripts/cycle47/marker.py checkpoint T-XXXX    # optional
   # ... more work ...
   python3 scripts/cycle47/marker.py end T-XXXX
   ```
3. **Explicit "Task complete" line**: Print a clear `T-XXXX COMPLETE` line at the end so the supervisor can grep for it.

If any of these are missing, the supervisor's pre-flight check (`--marker-required`) will reject the prompt with exit 2.

## Hung-detection behavior

The supervisor runs `hung_detector.py` against the log file in parallel with the sub-agent. It emits:
- `HUNG_OK <pid> <elapsed>s` every poll cycle (default 2s) when sub-agent is making progress
- `HUNG_DETECTED <pid> <silence>s <byte_offset>` when no log activity for `--hung-threshold` seconds

**Important:** `HUNG_DETECTED` does NOT auto-kill the sub-agent. It only records to JSONL. Humans still apply Lesson 35.5/35.6 (check files + git log before killing). This is by design — auto-killing risks losing work.

## Verification protocol

After every sub-agent invocation, the supervisor appends one JSONL line to `scripts/cycle47/data/subagents.jsonl` with these fields:

```json
{
  "prompt_file": "/tmp/cycle47_xxx/prompt.txt",
  "log_file": "/tmp/cycle47_xxx/run.log",
  "command": ["bash", "-c", "..."],
  "start_ts": "2026-07-05T18:05:20Z",
  "end_ts": "2026-07-05T18:05:30Z",
  "duration_s": 10.38,
  "exit_code": 0,
  "preflight_passed": true,
  "hung_during_run": false,
  "hung_max_elapsed_s": 4,
  "markers_emitted": 4,
  "hung_threshold_s": 120
}
```

Inspect this file periodically:
- `preflight_passed: false` → sub-agent prompt was malformed. Rewrite and re-dispatch.
- `hung_during_run: true` → sub-agent appeared hung during the run. Use Lesson 35.5 to verify if it was actually hung.
- `markers_emitted: 0` (with `--marker-required`) → sub-agent didn't emit markers despite prompt requesting them. Bug in sub-agent or prompt.

## Example invocation

```bash
# Setup
mkdir -p /tmp/cycle48_xxx
cat > /tmp/cycle48_xxx/prompt.txt << 'EOF'
Task: T-001
python3 scripts/cycle47/marker.py start T-001
Write /root/hermes-workspace/projects/oneweave/scripts/foo.py with hello_world().
python3 scripts/cycle47/marker.py end T-001
T-001 COMPLETE
EOF

# Launch with supervisor
python3 scripts/cycle47/subagent_supervisor.py \
  /tmp/cycle48_xxx/prompt.txt \
  /tmp/cycle48_xxx/run.log \
  --marker-required \
  --hung-threshold 600 \
  -- bash -c "cat /tmp/cycle48_xxx/prompt.txt | /root/.local/bin/codex exec --skip-git-repo-check"

# Check result
tail -1 scripts/cycle47/data/subagents.jsonl | python3 -m json.tool
```

## Anti-patterns (DO NOT DO)

❌ **NEVER** launch `codex exec --skip-git-repo-check` directly without wrapping.
❌ **NEVER** write a sub-agent prompt without `marker.py` calls (unless the task is <10s AND a single shell command).
❌ **NEVER** kill a sub-agent that appears hung without first checking `git log` + `ls` (Lesson 35.5).
❌ **NEVER** set `--hung-threshold` below 300 (5 minutes) for non-trivial work — false positives waste time.

## Related

- Skill: `~/.hermes/skills/subagent-hung-vs-done-check/SKILL.md` (Lesson 35.5/35.6)
- Cycle 47 spec: `specs/047-subagent-reliability/spec.md`
- Cycle 47 handoff: `specs/047-subagent-reliability/cycle47_handoff.md`
- Supervisor source: `scripts/cycle47/subagent_supervisor.py`
- Wrapper source: `scripts/cycle47/subagent_wrapper.py`
- Hung detector source: `scripts/cycle47/hung_detector.py`
- Marker source: `scripts/cycle47/marker.py`